FROM ubuntu:12.04
MAINTAINER Dan Garner <dan@springsignage.com>

RUN apt-get update && apt-get install -y \
  software-properties-common

# Install apache, PHP, and supplementary programs.
RUN apt-get update && apt-get install -y \
  apache2 \
  libapache2-mod-php5 \
  mysql-client \
  php5-mysql \
  php5-gd \
  php5-curl \
  php5-cli \
  curl \
  php5-mcrypt \
  ssmtp \
  wget \
  anacron

# Update the PHP.ini file
RUN sed -i "s/error_reporting = .*$/error_reporting = E_ERROR | E_WARNING | E_PARSE/" /etc/php5/apache2/php.ini
RUN sed -i "s/post_max_size = .*$/post_max_size = 810M/" /etc/php5/apache2/php.ini
RUN sed -i "s/upload_max_filesize = .*$/upload_max_filesize = 800M/" /etc/php5/apache2/php.ini
RUN sed -i "s/max_execution_time = .*$/max_execution_time = 300/" /etc/php5/apache2/php.ini
RUN sed -i "s/session.gc_probability = .*$/session.gc_probability = 1/" /etc/php5/apache2/php.ini
RUN sed -i "s/session.gc_divisor = .*$/session.gc_divisor = 100/" /etc/php5/apache2/php.ini

# Disable cron sending emails to root
RUN awk '/PATH=/ { print; print "MAILTO=\"\""; next}1' /etc/crontab > /tmp/crontab && mv /tmp/crontab /etc/crontab
RUN awk '/LOGNAME=root/ { print; print "MAILTO=\"\""; next}1' /etc/anacrontab > /tmp/anacrontab && mv /tmp/anacrontab /etc/anacrontab

# Setup persistent environment variables
ENV XIBO_VERSION=1.7.7
ENV XIBO_SMTP_SERVER=smtp.gmail.com:587 XIBO_SMTP_USERNAME=none XIBO_SMTP_PASSWORD=none XIBO_SMTP_USE_TLS=YES XIBO_SMTP_USE_STARTTLS=YES XIBO_SMTP_REWRITE_DOMAIN=gmail.com XIBO_SMTP_HOSTNAME=none XIBO_SMTP_FROM_LINE_OVERRIDE=YES

# Expose port 80
EXPOSE 80

# Pull in the release archive for the environment
ADD https://github.com/xibosignage/xibo-cms/archive/${XIBO_VERSION}.tar.gz /var/www/xibo-cms.tar.gz
ADD https://raw.githubusercontent.com/vishnubob/wait-for-it/master/wait-for-it.sh  /usr/local/bin/wait-for-it.sh
ADD settings.php-template /tmp/settings.php-template
ADD ssmtp.conf /etc/ssmtp/ssmtp.conf

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
RUN chmod +x /entrypoint.sh /usr/local/bin/httpd-foreground /usr/local/bin/wait-for-it.sh

# Create a flag file which the bootstrapping process will delete
# This tells us if we're doing a new install/upgrade on run
RUN touch /CMS-FLAG

CMD ["/entrypoint.sh"]
