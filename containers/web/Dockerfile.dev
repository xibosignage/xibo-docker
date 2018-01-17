FROM ubuntu:14.04
MAINTAINER Dan Garner <dan@springsignage.com>

RUN apt-get update && apt-get install -y \
  software-properties-common

RUN LC_ALL=C.UTF-8 DEBIAN_FRONTEND=noninteractive add-apt-repository ppa:ondrej/php
RUN LC_ALL=C.UTF-8 DEBIAN_FRONTEND=noninteractive add-apt-repository ppa:ondrej/apache2

# Install apache, PHP, and supplimentary programs.
RUN apt-get update && apt-get install -y \
  apache2 \
  libapache2-mod-php5.6 \
  libapache2-mod-xsendfile \
  mysql-client \
  php5.6-mysql \
  php5.6-gd \
  php5.6-curl \
  php5.6-cli \
  curl \
  php5.6-mcrypt \
  php5.6-zmq \
  php5.6-xml \
  php5.6-memcached \
  php5.6-soap \
  php5.6-zip \
  php5.6-mbstring \
  ssmtp \
  wget \
  anacron

# Enable apache mods and PHP extensions
RUN a2enmod php5.6 && a2enmod rewrite && a2enmod env && phpenmod mcrypt && a2enmod xsendfile && a2dismod mpm_event && a2enmod mpm_prefork

# Configure mpm_prefork
ADD mpm_prefork.conf /etc/apache2/mods-available/mpm_prefork.conf

# Disable cron sending emails to root
RUN awk '/PATH=/ { print; print "MAILTO=\"\""; next}1' /etc/crontab > /tmp/crontab && mv /tmp/crontab /etc/crontab
RUN awk '/LOGNAME=root/ { print; print "MAILTO=\"\""; next}1' /etc/anacrontab > /tmp/anacrontab && mv /tmp/anacrontab /etc/anacrontab

# Setup persistent environment variables
ENV CMS_VERSION=1.8.4 XMR_HOST=xmr CMS_DB_VERSION=135 CMS_SERVER_NAME=localhost
ENV MYSQL_HOST=mysql MYSQL_USER=cms MYSQL_PASSWORD=none MYSQL_PORT=3306 MYSQL_DATABASE=cms
ENV CMS_SMTP_SERVER=smtp.gmail.com:587 CMS_SMTP_USERNAME=none CMS_SMTP_PASSWORD=none CMS_SMTP_USE_TLS=YES CMS_SMTP_USE_STARTTLS=YES CMS_SMTP_REWRITE_DOMAIN=gmail.com CMS_SMTP_HOSTNAME=none CMS_SMTP_FROM_LINE_OVERRIDE=YES
ENV CMS_ALIAS=none CMS_PHP_SESSION_GC_MAXLIFETIME=1440
ENV CMS_PHP_POST_MAX_SIZE=2G CMS_PHP_UPLOAD_MAX_FILESIZE=2G
ENV CMS_PHP_MAX_EXECUTION_TIME=300
ENV CMS_APACHE_START_SERVERS=2 CMS_APACHE_MIN_SPARE_SERVERS=5
ENV CMS_APACHE_MAX_SPARE_SERVERS=10 CMS_APACHE_MAX_REQUEST_WORKERS=60
ENV CMS_APACHE_MAX_CONNECTIONS_PER_CHILD=300


# Update the PHP.ini file
RUN sed -i "s/error_reporting = .*$/error_reporting = E_ERROR | E_WARNING | E_PARSE/" /etc/php/5.6/apache2/php.ini
RUN sed -i "s/session.gc_probability = .*$/session.gc_probability = 1/" /etc/php/5.6/apache2/php.ini
RUN sed -i "s/session.gc_divisor = .*$/session.gc_divisor = 100/" /etc/php/5.6/apache2/php.ini

# Expose port 80
EXPOSE 80

# Pull in the release archive for the environment
RUN mkdir -p /var/www/cms && curl -o cms.tar.gz -SL https://github.com/xibosignage/xibo-cms/releases/download/${CMS_VERSION}/xibo-cms-${CMS_VERSION}.tar.gz \
	&& tar --strip=1 -xzf cms.tar.gz -C /var/www/cms \
	&& rm cms.tar.gz && rm /var/www/cms/web/install/index.php

# https://github.com/vishnubob/wait-for-it - MIT Licence
ADD wait-for-it.sh  /usr/local/bin/wait-for-it.sh
ADD settings.php-template /var/www/cms/web/settings.php
ADD settings.php-template /tmp/settings.php-template
ADD ssmtp.conf /etc/ssmtp/ssmtp.conf
ADD settings-custom.php /tmp/settings-custom.php

# Map a volumes to this folder.
# Our CMS files, library, cache and backups will be in here.
RUN mkdir -p /var/www/cms/library/temp && mkdir -p /var/www/backup && mkdir -p /var/www/cms/cache && mkdir -p /var/www/cms/web/userscripts && chown -R www-data:www-data /var/www/cms

# Update the default apache site with the config we created.
COPY apache-config.conf /etc/apache2/sites-enabled/000-default.conf

# Copy up the various provisioning scripting
COPY entrypoint.sh /entrypoint.sh
COPY httpd-foreground /usr/local/bin/httpd-foreground
COPY anacron /etc/cron.d/anacron
RUN chmod +x /entrypoint.sh /usr/local/bin/httpd-foreground /usr/local/bin/wait-for-it.sh

# Create a flag file which the bootstrapping process will delete
# This tells us if it's the first run of a new container
RUN touch /CMS-FLAG

# Add a group for SSMTP
RUN /usr/sbin/groupadd ssmtp

CMD ["/entrypoint.sh"]
