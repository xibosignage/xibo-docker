FROM ubuntu:14.04
MAINTAINER Dan Garner <dan@springsignage.com>

RUN apt-get update && apt-get install -y \
  software-properties-common

RUN DEBIAN_FRONTEND=noninteractive add-apt-repository ppa:chris-lea/zeromq
RUN DEBIAN_FRONTEND=noninteractive add-apt-repository ppa:alexharrington/php-zmq

# Install apache, PHP, and supplimentary programs.
RUN apt-get update && apt-get install -y \
  apache2 \
  libapache2-mod-php5 \
  mysql-client \
  php5-mysql \
  php5-gd \
  php-pear \
  php-apc \
  php5-curl \
  curl \
  php5-mcrypt \
  php5-zmq

# Enable apache mods and PHP extensions
RUN a2enmod php5 && a2enmod rewrite && php5enmod mcrypt

# Update the PHP.ini file
RUN sed -i "s/error_reporting = .*$/error_reporting = E_ERROR | E_WARNING | E_PARSE/" /etc/php5/apache2/php.ini
RUN sed -i "s/post_max_size = .*$/post_max_size = 810M/" /etc/php5/apache2/php.ini
RUN sed -i "s/upload_max_filesize = .*$/upload_max_filesize = 800M/" /etc/php5/apache2/php.ini
RUN sed -i "s/max_execution_time = .*$/max_execution_time = 300/" /etc/php5/apache2/php.ini

# Setup persistent environment variables
ENV XIBO_VERSION=1.8.0-alpha3 XMR_HOST=xibo-cms-xmr

# Expose port 80
EXPOSE 80

# Pull in the release archive for the environment
ADD https://github.com/xibosignage/xibo-cms/releases/download/${XIBO_VERSION}/xibo-cms-${XIBO_VERSION}.tar.gz /var/www/xibo-cms.tar.gz

# Map a volumes to this folder.
# Our CMS files, library, cache and backups will be in here.
RUN mkdir -p /var/www/xibo && mkdir -p /var/www/backup
VOLUME /var/www/xibo
VOLUME /var/www/backup

# Update the default apache site with the config we created.
COPY apache-config.conf /etc/apache2/sites-enabled/000-default.conf

# Copy up the various provisioning scripting
COPY entrypoint.sh /entrypoint.sh
COPY httpd-foreground /usr/local/bin/httpd-foreground
RUN chmod +x /entrypoint.sh /usr/local/bin/httpd-foreground

# Create a flag file which the bootstrapping process will delete
# This tells us if we're doing a new install/upgrade on run
RUN touch /CMS-FLAG

CMD ["/entrypoint.sh"]
