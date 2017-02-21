#!/bin/bash

if [ "$XIBO_DEV_MODE" == "true" ]
then
  # Print MySQL connection details
  echo "MySQL Connection Details:"
  echo "Username: root"
  echo "Password: $MYSQL_ENV_MYSQL_ROOT_PASSWORD"
  echo "Host: mysql"
  echo ""
  echo "XMR Connection Details:"
  echo "Host: $XMR_HOST"
  echo "CMS Port: 50001"
  echo "Player Port: 9505"
  echo ""
  echo "Starting Webserver"
  /usr/local/bin/httpd-foreground
  exit $?
fi

# Sleep for a few seconds to give MySQL time to initialise
echo "Waiting for MySQL to start - max 300 seconds"
/usr/local/bin/wait-for-it.sh -q -t 300 $CMS_DATABASE_HOST:$CMS_DATABASE_PORT

if [ ! "$?" == 0 ]
then
  echo "MySQL didn't start in the allocated time" > /var/www/backup/LOG
fi

# Safety sleep to give MySQL a moment to settle after coming up
echo "MySQL started"
sleep 1

# Check if there's a database file to import
if [ -f "/var/www/backup/import.sql" ]
then
  echo "Attempting to import database"
  
  if [ "$CMS_SKIP_DB_CREATE" == "true" ]
  then
    mysql -u root -p$MYSQL_ROOT_PASSWORD -h $CMS_DATABASE_HOST -P $CMS_DATABASE_PORT -e "CREATE DATABASE $CMS_DATABASE_NAME"  # Populate the database
    mysql -u root -p$MYSQL_ROOT_PASSWORD -h $CMS_DATABASE_HOST -P $CMS_DATABASE_PORT -e "GRANT ALL PRIVILEGES ON `$CMS_DATABASE_NAME`.* TO '$CMS_DATABASE_USERNAME'@'%' IDENTIFIED BY '$CMS_DATABASE_PASSWORD'; FLUSH PRIVILEGES;"
  fi
  
  mysql -D $CMS_DATABASE_NAME -u $CMS_DATABASE_USERNAME -p$CMS_DATABASE_PASSWORD -h $CMS_DATABASE_HOST -P $CMS_DATABASE_PORT -e "SOURCE /var/www/backup/import.sql"

  echo "Configuring Database Settings"
  # Set LIBRARY_LOCATION
  mysql -D $CMS_DATABASE_NAME -u $CMS_DATABASE_USERNAME -p$CMS_DATABASE_PASSWORD -h $CMS_DATABASE_HOST -P $CMS_DATABASE_PORT -e "UPDATE \`setting\` SET \`value\`='/var/www/cms/library/', \`userChange\`=0, \`userSee\`=0 WHERE \`setting\`='LIBRARY_LOCATION' LIMIT 1"
  mysql -D $CMS_DATABASE_NAME -u $CMS_DATABASE_USERNAME -p$CMS_DATABASE_PASSWORD -h $CMS_DATABASE_HOST -P $CMS_DATABASE_PORT -e "UPDATE \`setting\` SET \`value\`='Apache', \`userChange\`=0, \`userSee\`=0 WHERE \`setting\`='SENDFILE_MODE' LIMIT 1"

  # Set XMR public/private address
  mysql -D $CMS_DATABASE_NAME -u $CMS_DATABASE_USERNAME -p$CMS_DATABASE_PASSWORD -h $CMS_DATABASE_HOST -P $CMS_DATABASE_PORT -e "UPDATE \`setting\` SET \`value\`='tcp://$XMR_HOST:50001', \`userChange\`=0, \`userSee\`=0 WHERE \`setting\`='XMR_ADDRESS' LIMIT 1"
  mysql -D $CMS_DATABASE_NAME -u $CMS_DATABASE_USERNAME -p$CMS_DATABASE_PASSWORD -h $CMS_DATABASE_HOST -P $CMS_DATABASE_PORT -e "UPDATE \`setting\` SET \`value\`='tcp://yourserver:9505' WHERE \`setting\`='XMR_PUB_ADDRESS' LIMIT 1"

  # Set CMS Key
  mysql -D $CMS_DATABASE_NAME -u $CMS_DATABASE_USERNAME -p$CMS_DATABASE_PASSWORD -h $CMS_DATABASE_HOST -P $CMS_DATABASE_PORT -e "UPDATE \`setting\` SET \`value\`='$CMS_KEY' WHERE \`setting\`='SERVER_KEY' LIMIT 1"

  # Configure Maintenance
  echo "Setting up Maintenance"
  mysql -D $CMS_DATABASE_NAME -u $CMS_DATABASE_USERNAME -p$CMS_DATABASE_PASSWORD -h $CMS_DATABASE_HOST -P $CMS_DATABASE_PORT -e "UPDATE \`setting\` SET \`value\`='Protected' WHERE \`setting\`='MAINTENANCE_ENABLED' LIMIT 1"

  MAINTENANCE_KEY=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 16)
  mysql -D $CMS_DATABASE_NAME -u $CMS_DATABASE_USERNAME -p$CMS_DATABASE_PASSWORD -h $CMS_DATABASE_HOST -P $CMS_DATABASE_PORT -e "UPDATE \`setting\` SET \`value\`='$MAINTENANCE_KEY' WHERE \`setting\`='MAINTENANCE_KEY' LIMIT 1"

  mv /var/www/backup/import.sql /var/www/backup/import.sql.done
fi

DB_EXISTS=0
# Check if the database exists already
if mysql -D $CMS_DATABASE_NAME -u $CMS_DATABASE_USERNAME -p$CMS_DATABASE_PASSWORD -h $CMS_DATABASE_HOST -P $CMS_DATABASE_PORT -e "SELECT DBVersion from version"
then
  # Database exists.
  DB_EXISTS=1
fi

# Check if we need to run an upgrade
# if DB_EXISTS then see if the version installed matches
if [ "$DB_EXISTS" == "1" ]
then
  # Get the currently installed schema version number
  CURRENT_DB_VERSION=$(mysql -D $CMS_DATABASE_NAME -u $CMS_DATABASE_USERNAME -p$CMS_DATABASE_PASSWORD -h $CMS_DATABASE_HOST -P $CMS_DATABASE_PORT -se 'SELECT DBVersion from version')

  if [ ! "$CURRENT_DB_VERSION"  == "$CMS_DB_VERSION" ]
  then
    # We're going to run an upgrade. Make a database backup
    mysqldump -h $CMS_DATABASE_HOST -P $CMS_DATABASE_PORT -u $CMS_DATABASE_USERNAME -p$CMS_DATABASE_PASSWORD $CMS_DATABASE_NAME | gzip > /var/www/backup/db-$(date +"%Y-%m-%d_%H-%M-%S").sql.gz

    # Drop app cache on upgrade
    rm -rf /var/www/cms/cache/*
  fi
fi

if [ "$DB_EXISTS" == "0" ]
then
  # This is a fresh install so bootstrap the whole
  # system
  echo "New install"

  if [ "$CMS_SKIP_DB_CREATE" == "true" ]
  then
    mysql -u root -p$MYSQL_ROOT_PASSWORD -h $CMS_DATABASE_HOST -P $CMS_DATABASE_PORT -e "CREATE DATABASE $CMS_DATABASE_NAME"
    mysql -u root -p$MYSQL_ROOT_PASSWORD -h $CMS_DATABASE_HOST -P $CMS_DATABASE_PORT -e "GRANT ALL PRIVILEGES ON `$CMS_DATABASE_NAME`.* TO '$CMS_DATABASE_USERNAME'@'%' IDENTIFIED BY '$CMS_DATABASE_PASSWORD'; FLUSH PRIVILEGES;"
  fi
  
  echo "Provisioning Database"
  # Populate the database
  mysql -D $CMS_DATABASE_NAME -u $CMS_DATABASE_USERNAME -p$CMS_DATABASE_PASSWORD -h $CMS_DATABASE_HOST -P $CMS_DATABASE_PORT -e "SOURCE /var/www/cms/install/master/structure.sql"
  mysql -D $CMS_DATABASE_NAME -u $CMS_DATABASE_USERNAME -p$CMS_DATABASE_PASSWORD -h $CMS_DATABASE_HOST -P $CMS_DATABASE_PORT -e "SOURCE /var/www/cms/install/master/data.sql"
  mysql -D $CMS_DATABASE_NAME -u $CMS_DATABASE_USERNAME -p$CMS_DATABASE_PASSWORD -h $CMS_DATABASE_HOST -P $CMS_DATABASE_PORT -e "SOURCE /var/www/cms/install/master/constraints.sql"

  CMS_KEY=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 8)

  echo "Configuring Database Settings"
  # Set LIBRARY_LOCATION
  mysql -D $CMS_DATABASE_NAME -u $CMS_DATABASE_USERNAME -p$CMS_DATABASE_PASSWORD -h $CMS_DATABASE_HOST -P $CMS_DATABASE_PORT -e "UPDATE \`setting\` SET \`value\`='/var/www/cms/library/', \`userChange\`=0, \`userSee\`=0 WHERE \`setting\`='LIBRARY_LOCATION' LIMIT 1"
  mysql -D $CMS_DATABASE_NAME -u $CMS_DATABASE_USERNAME -p$CMS_DATABASE_PASSWORD -h $CMS_DATABASE_HOST -P $CMS_DATABASE_PORT -e "UPDATE \`setting\` SET \`value\`='Apache', \`userChange\`=0, \`userSee\`=0 WHERE \`setting\`='SENDFILE_MODE' LIMIT 1"

  # Set admin username/password
  mysql -D $CMS_DATABASE_NAME -u $CMS_DATABASE_USERNAME -p$CMS_DATABASE_PASSWORD -h $CMS_DATABASE_HOST -P $CMS_DATABASE_PORT -e "UPDATE \`user\` SET \`UserName\`='xibo_admin', \`UserPassword\`='5f4dcc3b5aa765d61d8327deb882cf99' WHERE \`UserID\` = 1 LIMIT 1"

  # Set XMR public/private address
  mysql -D $CMS_DATABASE_NAME -u $CMS_DATABASE_USERNAME -p$CMS_DATABASE_PASSWORD -h $CMS_DATABASE_HOST -P $CMS_DATABASE_PORT -e "UPDATE \`setting\` SET \`value\`='tcp://$XMR_HOST:50001', \`userChange\`=0, \`userSee\`=0 WHERE \`setting\`='XMR_ADDRESS' LIMIT 1"
  mysql -D $CMS_DATABASE_NAME -u $CMS_DATABASE_USERNAME -p$CMS_DATABASE_PASSWORD -h $CMS_DATABASE_HOST -P $CMS_DATABASE_PORT -e "UPDATE \`setting\` SET \`value\`='tcp://yourserver:9505' WHERE \`setting\`='XMR_PUB_ADDRESS' LIMIT 1"

  # Set CMS Key
  mysql -D $CMS_DATABASE_NAME -u $CMS_DATABASE_USERNAME -p$CMS_DATABASE_PASSWORD -h $CMS_DATABASE_HOST -P $CMS_DATABASE_PORT -e "UPDATE \`setting\` SET \`value\`='$CMS_KEY' WHERE \`setting\`='SERVER_KEY' LIMIT 1"

  # Configure Maintenance
  echo "Setting up Maintenance"
  mysql -D $CMS_DATABASE_NAME -u $CMS_DATABASE_USERNAME -p$CMS_DATABASE_PASSWORD -h $CMS_DATABASE_HOST -P $CMS_DATABASE_PORT -e "UPDATE \`setting\` SET \`value\`='Protected' WHERE \`setting\`='MAINTENANCE_ENABLED' LIMIT 1"

  MAINTENANCE_KEY=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 16)
  mysql -D $CMS_DATABASE_NAME -u $CMS_DATABASE_USERNAME -p$CMS_DATABASE_PASSWORD -h $CMS_DATABASE_HOST -P $CMS_DATABASE_PORT -e "UPDATE \`setting\` SET \`value\`='$MAINTENANCE_KEY' WHERE \`setting\`='MAINTENANCE_KEY' LIMIT 1"
fi

if [ -e /CMS-FLAG ]
then
  # Remove the CMS-FLAG so we don't run this block time we're started
  rm /CMS-FLAG

  # Write settings.php
  echo "Updating settings.php"
  SECRET_KEY=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 8)

  if [ "$XIBO_DEV_MODE" == "ci" ]
  then
     # We won't have a settings.php in place, so we'll need to copy one in
     cp /tmp/settings.php-template /var/www/cms/web/settings.php
     chown www-data.www-data -R /var/www/cms

     # Unprotect maintenance in CI mode
     mysql -D $CMS_DATABASE_NAME -u $CMS_DATABASE_USERNAME -p$CMS_DATABASE_PASSWORD -h $CMS_DATABASE_HOST -P $CMS_DATABASE_PORT -e "UPDATE \`setting\` SET \`value\`='On' WHERE \`setting\`='MAINTENANCE_ENABLED' LIMIT 1"
  fi

  /bin/sed -i "s/define('SECRET_KEY','');/define('SECRET_KEY','$SECRET_KEY');/" /var/www/cms/web/settings.php
fi

# Configure MySQL Backup
echo "Configuring Backups"
echo "#!/bin/bash" > /etc/cron.daily/cms-db-backup
echo "" >> /etc/cron.daily/cms-db-backup
echo "/bin/mkdir -p /var/www/backup/db" >> /etc/cron.daily/cms-db-backup
echo "/usr/bin/mysqldump --single-transaction -u $CMS_DATABASE_USERNAME -p$CMS_DATABASE_PASSWORD -h $CMS_DATABASE_HOST -P $CMS_DATABASE_PORT $CMS_DATABASE_NAME | gzip > /var/www/backup/db/latest.sql.gz" >> /etc/cron.daily/cms-db-backup
/bin/chmod 700 /etc/cron.daily/cms-db-backup

# Update /var/www/maintenance with current environment (for cron)
echo "Configuring Maintenance"
echo "#!/bin/bash" > /var/www/maintenance.sh
echo "" >> /var/www/maintenance.sh
/usr/bin/env | sed 's/^\(.*\)$/export \1/g' | grep -E "^export CMS_DATABASE" >> /var/www/maintenance.sh
echo "cd /var/www/cms && /usr/bin/php bin/xtr.php" >> /var/www/maintenance.sh
chmod 755 /var/www/maintenance.sh

echo "* * * * *   www-data  /var/www/maintenance.sh > /dev/null 2>&1 " > /etc/cron.d/cms-maintenance

# Configure SSMTP to send emails if required
/bin/sed -i "s/mailhub=.*$/mailhub=$CMS_SMTP_SERVER/" /etc/ssmtp/ssmtp.conf
/bin/sed -i "s/AuthUser=.*$/AuthUser=$CMS_SMTP_USERNAME/" /etc/ssmtp/ssmtp.conf
/bin/sed -i "s/AuthPass=.*$/AuthPass=$CMS_SMTP_PASSWORD/" /etc/ssmtp/ssmtp.conf
/bin/sed -i "s/UseTLS=.*$/UseTLS=$CMS_SMTP_USE_TLS/" /etc/ssmtp/ssmtp.conf
/bin/sed -i "s/UseSTARTTLS=.*$/UseSTARTTLS=$CMS_SMTP_USE_STARTTLS/" /etc/ssmtp/ssmtp.conf
/bin/sed -i "s/rewriteDomain=.*$/rewriteDomain=$CMS_SMTP_REWRITE_DOMAIN/" /etc/ssmtp/ssmtp.conf
/bin/sed -i "s/hostname=.*$/hostname=$CMS_SMTP_HOSTNAME/" /etc/ssmtp/ssmtp.conf
/bin/sed -i "s/FromLineOverride=.*$/FromLineOverride=$CMS_SMTP_FROM_LINE_OVERRIDE/" /etc/ssmtp/ssmtp.conf

# Secure SSMTP files
# Following recommendations here:
# https://wiki.archlinux.org/index.php/SSMTP#Security
/bin/chgrp ssmtp /etc/ssmtp/ssmtp.conf
/bin/chgrp ssmtp /usr/sbin/ssmtp
/bin/chmod 640 /etc/ssmtp/ssmtp.conf
/bin/chmod g+s /usr/sbin/ssmtp

mkdir -p /var/www/cms/library/temp
chown www-data.www-data -R /var/www/cms

if [ ! -e /var/www/cms/custom/settings-custom.php ]
then
    /bin/cp /tmp/settings-custom.php /var/www/cms/custom
fi

echo "Running maintenance"
cd /var/www/cms
/usr/bin/php bin/run.php 1

echo "Starting cron"
/usr/sbin/cron
/usr/sbin/anacron

echo "Starting webserver"
/usr/local/bin/httpd-foreground
