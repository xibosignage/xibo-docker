FROM ubuntu:14.04
MAINTAINER Dan Garner <dan@springsignage.com>

RUN apt-get update && apt-get install -y \
  software-properties-common

RUN DEBIAN_FRONTEND=noninteractive add-apt-repository ppa:chris-lea/zeromq
RUN DEBIAN_FRONTEND=noninteractive add-apt-repository ppa:alexharrington/php-zmq

# Install apache, PHP, and supplimentary programs.
RUN apt-get update && apt-get install -y \
  curl \
  php5-cli \
  php5-zmq

EXPOSE 50001

# Copy up the various provisioning scripting
COPY init /root/init

# Download and extract XMR into a convenient folder
ADD https://github.com/xibosignage/xibo-xmr/archive/0.1.tar.gz /root/xmr
RUN tar -xzf /root/xmr/0.1.tar.gz -C /root/xmr && mv /root/xmr/bin/xmr.phar /opt/xmr

# Start XMR
CMD /usr/bin/php /opt/xmr/xmr.phar -s /bin/sh nobody
