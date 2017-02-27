FROM ubuntu:14.04
MAINTAINER Dan Garner <dan@springsignage.com>

ENV XMR_VERSION 0.3
ENV XMR_DEBUG false
ENV XMR_IPV6RESPSUPPORT false
ENV XMR_IPV6PUBSUPPORT false

RUN apt-get update && apt-get install -y \
  software-properties-common

RUN DEBIAN_FRONTEND=noninteractive add-apt-repository ppa:chris-lea/zeromq
RUN DEBIAN_FRONTEND=noninteractive add-apt-repository ppa:alexharrington/php-zmq

# Install apache, PHP, and supplimentary programs.
RUN apt-get update && apt-get install -y \
  curl \
  php5-cli \
  php5-zmq

EXPOSE 9505 50001

# Copy up the various provisioning scripting
COPY entrypoint.sh /entrypoint.sh
RUN mkdir -p /root/xmr && mkdir -p /opt/xmr

# Download and extract XMR into a convenient folder
ADD https://github.com/xibosignage/xibo-xmr/archive/${XMR_VERSION}.tar.gz /root/xmr
RUN tar --strip=2 -xzf /root/xmr/${XMR_VERSION}.tar.gz -C /opt/xmr --wildcards \*/bin/xmr.phar

RUN chown -R nobody /opt/xmr && chmod 700 /entrypoint.sh

# Start XMR
CMD ["/entrypoint.sh"]
