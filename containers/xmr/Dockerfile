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
RUN mkdir -p /root/xmr && mkdir -p /opt/xmr

# Download and extract XMR into a convenient folder
ADD https://github.com/xibosignage/xibo-xmr/archive/0.1.tar.gz /root/xmr
RUN tar --strip=2 -xzf /root/xmr/0.1.tar.gz -C /opt/xmr --wildcards \*/bin/xmr.phar

RUN chown -R nobody /opt/xmr && chmod 700 /root/init

# Start XMR
CMD /root/init
