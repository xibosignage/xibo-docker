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
  
  tar --strip=1 -zxf /var/www/xibo-cms.tar.gz -C /var/www/xibo --exclude=settings.php
  chown www-data.www-data -R /var/www/xibo/web
  chown www-data.www-data -R /var/www/xibo/install
  mkdir /var/www/xibo/cache
  chown www-data.www-data -R /var/www/xibo/cache
  
  if [! -e "/var/www/xibo/web/settings.php" ]
  then
    # This is a fresh install so bootstrap the whole
    # system
    echo "New install"
    # Write settings.php

    # Set LIBRARY_LOCATION

    # Set admin username/password (passed in)

    # Set XMR public/private address
    
    # Configure MySQL Backup
  
  fi
  rm /CMS-FLAG
fi

/usr/local/bin/httpd-foreground