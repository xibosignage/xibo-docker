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
  php5-mysql \
  php5-gd \
  php-pear \
  php-apc \
  php5-curl \
  curl \
  php5-mcrypt \
  php5-zmq

# Enable apache mods.
RUN a2enmod php5
RUN a2enmod rewrite

# Update the PHP.ini file
RUN sed -i "s/error_reporting = .*$/error_reporting = E_ERROR | E_WARNING | E_PARSE/" /etc/php5/apache2/php.ini

# Manually set up the apache environment variables
ENV APACHE_RUN_USER www-data
ENV APACHE_RUN_GROUP www-data
ENV APACHE_LOG_DIR /var/log/apache2
ENV APACHE_LOCK_DIR /var/lock/apache2
ENV APACHE_PID_FILE /var/run/apache2.pid

# Setup the Xibo version
ENV XIBO_VERSION 1.8.0-alpha3

# Expose port 80
EXPOSE 80

# Pull in the release archive for the environment
ADD https://github.com/xibosignage/xibo-cms/releases/download/1.8.0-alpha3/xibo-cms-1.8.0-alpha3.tar.gz /var/www/xibo-cms-1.8.0-alpha3.tar.gz

# Map a volume to this folder.
# Our CMS files, library and cache will be in here.
VOLUME /var/www/xibo

# Make backup folder
RUN mkdir /var/www/backup
VOLUME /var/www/backup

# Update the default apache site with the config we created.
COPY apache-config.conf /etc/apache2/sites-enabled/000-default.conf

# Copy up the various provisioning scripting
COPY init /root/init
COPY env /root/env
COPY config_backup /root/config_backup

COPY httpd-foreground /usr/local/bin/httpd-foreground
RUN chmod +x /usr/local/bin/httpd-foreground

# By default, simply start apache.
CMD ["/usr/local/bin/httpd-foreground"]
