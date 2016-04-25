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

# Detect if we're going to run an upgrade
if [ -e "/CMS-FLAG" ]
then
  if [ -e "/var/www/xibo/web/settings.php" ]
  then
    # Run a database backup
    dbuser=$(awk -F "'" '/\$dbuser/ {print $2}' /tmp/settings.php)
    dbpass=$(awk -F "'" '/\$dbpass/ {print $2}' /tmp/settings.php)
    dbname=$(awk -F "'" '/\$dbpass/ {print $2}' /tmp/settings.php)
    
    mysqldump -h mysql -u $dbuser -p$dbpass $dbname | gzip > /var/www/backup/$(date +"%Y-%m-%d_%H-%M-%S").sql.gz

    # Backup the settings.php file
    mv /var/www/xibo/web/settings.php /tmp/settings.php
    
    # Delete the old install EXCEPT the library directory
    find /var/www/xibo ! -name library -type d -exec rm -rf {};
    find /var/www/xibo -type f --max-depth=1 -exec rm -f {};

    # Replace settings
    mv /tmp/settings.php /var/www/xibo/web/settings.php
  else
    # When the mysql container is re-bootstrapped, it's password
    # remains the same so cache a copy in this file so we know what
    # it is if we ever need it in the future.
    echo $MYSQL_ENV_MYSQL_ROOT_PASSWORD > /var/www/backup/.mysql-root-password
    chmod 400 /var/www/backup/.mysql-root-password
  fi
  
  # Drop the CMS cache (if it exists)
  if [ -d /var/www/xibo/cache ]
  then
    rm -r /var/www/xibo/cache
  fi

  # If we're not in CI mode (for Jenkins) then extract the CMS source
  if [ "$XIBO_DEV_MODE" != "ci" ]
  then  
    tar --strip=1 -zxf /var/www/xibo-cms.tar.gz -C /var/www/xibo --exclude=settings.php
  fi
  
  chown www-data.www-data -R /var/www/xibo/web
  chown www-data.www-data -R /var/www/xibo/install

  mkdir /var/www/xibo/cache
  mkdir -p /var/www/xibo/library/temp
  chown www-data.www-data -R /var/www/xibo/cache /var/www/xibo/library
  
  if [ ! -e "/var/www/xibo/web/settings.php" ]
  then
    # This is a fresh install so bootstrap the whole
    # system
    echo "New install"
    
    # Sleep for a few seconds to give MySQL time to initialise
    echo "Waiting for MySQL to start - max 300 seconds"
    /usr/local/bin/wait-for-it.sh -q -t 300 mysql:3306
    
    if [ ! "$?" == 0 ]
    then
      echo "MySQL didn't start in the allocated time" > /var/www/backup/LOG
    fi
    
    # Safety sleep to give MySQL a moment to settle after coming up
    echo "MySQL started"
    sleep 1
    
    echo "Provisioning Database"
    # Create database
    MYSQL_USER_PASSWORD=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 16)
    mysql -u root -p$MYSQL_ENV_MYSQL_ROOT_PASSWORD -h mysql -e "CREATE DATABASE cms"
    mysql -D cms -u root -p$MYSQL_ENV_MYSQL_ROOT_PASSWORD -h mysql -e "SOURCE /var/www/xibo/install/master/structure.sql"
    mysql -D cms -u root -p$MYSQL_ENV_MYSQL_ROOT_PASSWORD -h mysql -e "SOURCE /var/www/xibo/install/master/data.sql"
    mysql -D cms -u root -p$MYSQL_ENV_MYSQL_ROOT_PASSWORD -h mysql -e "SOURCE /var/www/xibo/install/master/constraints.sql"
    
    mysql -u root -p$MYSQL_ENV_MYSQL_ROOT_PASSWORD -h mysql -e "GRANT ALL PRIVILEGES ON cms.* TO 'cms_user'@'%' IDENTIFIED BY '$MYSQL_USER_PASSWORD'; FLUSH PRIVILEGES;"
    echo $MYSQL_USER_PASSWORD > /var/www/backup/.mysql-user-password
    chmod 400 /var/www/backup/.mysql-user-password    
    
    # Write settings.php
    echo "Writing settings.php"
    SECRET_KEY=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 8)
    CMS_KEY=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 8)
    cp /tmp/settings.php-template /var/www/xibo/web/settings.php
    sed -i "s/\$dbpass = .*$/\$dbpass = '$MYSQL_USER_PASSWORD';/" /var/www/xibo/web/settings.php
    sed -i "s/define('SECRET_KEY','');/define('SECRET_KEY','$SECRET_KEY');/" /var/www/xibo/web/settings.php

    echo "Configuring Database Settings"
    # Set LIBRARY_LOCATION
    mysql -D cms -u root -p$MYSQL_ENV_MYSQL_ROOT_PASSWORD -h mysql -e "UPDATE \`setting\` SET \`value\`='/var/www/xibo/library/', \`userChange\`=0, \`userSee\`=0 WHERE \`setting\`='LIBRARY_LOCATION' LIMIT 1"

    # Set admin username/password
    mysql -D cms -u root -p$MYSQL_ENV_MYSQL_ROOT_PASSWORD -h mysql -e "UPDATE \`user\` SET \`UserName\`='xibo_admin', \`UserPassword\`='5f4dcc3b5aa765d61d8327deb882cf99' WHERE \`UserID\` = 1 LIMIT 1"

    # Set XMR public/private address
    mysql -D cms -u root -p$MYSQL_ENV_MYSQL_ROOT_PASSWORD -h mysql -e "UPDATE \`setting\` SET \`value\`='tcp://$XMR_HOST:50001', \`userChange\`=0, \`userSee\`=0 WHERE \`setting\`='XMR_ADDRESS' LIMIT 1"
    mysql -D cms -u root -p$MYSQL_ENV_MYSQL_ROOT_PASSWORD -h mysql -e "UPDATE \`setting\` SET \`value\`='tcp://yourserver:9505' WHERE \`setting\`='XMR_PUB_ADDRESS' LIMIT 1"

    # Set CMS Key
    mysql -D cms -u root -p$MYSQL_ENV_MYSQL_ROOT_PASSWORD -h mysql -e "UPDATE \`setting\` SET \`value\`='$CMS_KEY' WHERE \`setting\`='SERVER_KEY' LIMIT 1"
    
    # Configure Maintenance
    echo "Setting up Maintenance"
    mysql -D cms -u root -p$MYSQL_ENV_MYSQL_ROOT_PASSWORD -h mysql -e "UPDATE \`setting\` SET \`value\`='Protected' WHERE \`setting\`='MAINTENANCE_ENABLED' LIMIT 1"

    if [ "$XIBO_DEV_MODE" == "ci" ]
    then
      # Unprotect maintenance in ci mode
      mysql -D cms -u root -p$MYSQL_ENV_MYSQL_ROOT_PASSWORD -h mysql -e "UPDATE \`setting\` SET \`value\`='On' WHERE \`setting\`='MAINTENANCE_ENABLED' LIMIT 1"
    fi

    MAINTENANCE_KEY=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 16)
    mysql -D cms -u root -p$MYSQL_ENV_MYSQL_ROOT_PASSWORD -h mysql -e "UPDATE \`setting\` SET \`value\`='$MAINTENANCE_KEY' WHERE \`setting\`='MAINTENANCE_KEY' LIMIT 1"

    mkdir -p /var/www/backup/cron
    echo "*/5 * * * *   root  /usr/bin/wget -O /dev/null -o /dev/null http://localhost/maint/?key=$MAINTENANCE_KEY" > /var/www/backup/cron/cms-maintenance
    
    # Configure MySQL Backup
    echo "Configuring Backups"
    echo "#!/bin/bash" > /var/www/backup/cron/cms-db-backup
    echo "" >> /var/www/backup/cron/cms-db-backup
    echo "/bin/mkdir -p /var/www/backup/db" >> /var/www/backup/cron/cms-db-backup
    echo "/usr/bin/mysqldump -u root -p$MYSQL_ENV_MYSQL_ROOT_PASSWORD -h mysql cms | gzip > /var/www/backup/db/latest.sql.gz" >> /var/www/backup/cron/cms-db-backup
    
    # Remove the installer
    echo "Removing the installer"
    rm /var/www/xibo/web/install/index.php
  fi
  
  # Remove the flag so we don't try and bootstrap in future
  rm /CMS-FLAG

  # Ensure there's a group for ssmtp
  /usr/sbin/groupadd ssmtp
  
  # Ensure there's a crontab for maintenance
  cp /var/www/backup/cron/cms-maintenance /etc/cron.d/cms-maintenance
  
  # Ensure there's a crontab for backups
  # Use anacron for this so we get backups even if
  # the box isn't on 24/7
  cp /var/www/backup/cron/cms-db-backup /etc/cron.daily/cms-db-backup
  /bin/chmod 700 /etc/cron.daily/cms-db-backup
fi

# Configure SSMTP to send emails if required
/bin/sed -i "s/mailhub=.*$/mailhub=$XIBO_SMTP_SERVER/" /etc/ssmtp/ssmtp.conf
/bin/sed -i "s/AuthUser=.*$/AuthUser=$XIBO_SMTP_USERNAME/" /etc/ssmtp/ssmtp.conf
/bin/sed -i "s/AuthPass=.*$/AuthPass=$XIBO_SMTP_PASSWORD/" /etc/ssmtp/ssmtp.conf
/bin/sed -i "s/UseTLS=.*$/UseTLS=$XIBO_SMTP_USE_TLS/" /etc/ssmtp/ssmtp.conf
/bin/sed -i "s/UseSTARTTLS=.*$/UseSTARTTLS=$XIBO_SMTP_USE_STARTTLS/" /etc/ssmtp/ssmtp.conf
/bin/sed -i "s/rewriteDomain=.*$/rewriteDomain=$XIBO_SMTP_REWRITE_DOMAIN/" /etc/ssmtp/ssmtp.conf
/bin/sed -i "s/hostname=.*$/hostname=$XIBO_SMTP_HOSTNAME/" /etc/ssmtp/ssmtp.conf
/bin/sed -i "s/FromLineOverride=.*$/FromLineOverride=$XIBO_SMTP_FROM_LINE_OVERRIDE/" /etc/ssmtp/ssmtp.conf

# Secure SSMTP files
# Following recommendations here:
# https://wiki.archlinux.org/index.php/SSMTP#Security
/bin/chgrp ssmtp /etc/ssmtp/ssmtp.conf
/bin/chgrp ssmtp /usr/sbin/ssmtp
/bin/chmod 640 /etc/ssmtp/ssmtp.conf
/bin/chmod g+s /usr/sbin/ssmtp

echo "Starting cron"
/usr/sbin/cron
/usr/sbin/anacron

echo "Starting webserver"
/usr/local/bin/httpd-foreground