#!/bin/bash

# Detect if we're going to run an upgrade
if [ -e "/CMS_FLAG" ]
then
  if [ -e "/var/www/xibo/web/settings.php" ]
  then
    # Backup the settings.php file
    mv /var/www/xibo/web/settings.php /tmp/settings.php
    
    # Run a database backup
    # TODO: Run an automatic database backup here
    
    # Delete the old install EXCEPT the library directory
    find /var/www/xibo ! -name library -type d -exec rm -rf {};
    find /var/www/xibo -type f --max-depth=1 -exec rm -f {};

    # Replace settings
    mv /tmp/settings.php /var/www/xibo/web/settings.php
  fi
  
  tar -zxf --strip=1 /var/www/xibo-cms-1.8.0-alpha3.tar.gz -C /var/www/xibo
  chown www-data.www-data -R /var/www/xibo/web
  
  if [! -e "/var/www/xibo/web/settings.php" ]
  then
    # This is a fresh install so bootstrap the whole
    # system
    
    # Write settings.php

    # Set LIBRARY_LOCATION

    # Set admin username/password (passed in)

    # Set XMR public/private address
    
    # Configure MySQL Backup
  
  fi
  rm /CMS_FLAG
fi

/usr/local/bin/httpd-foreground