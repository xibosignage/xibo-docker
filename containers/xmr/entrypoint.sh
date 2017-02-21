#!/bin/bash

# Get our running IP address
ip=$(ip -f inet -o addr show eth0|cut -d\  -f 7 | cut -d/ -f 1)

# Write config.json
echo '{' > /opt/xmr/config.json
echo '  "listenOn": "tcp://'$ip':50001",' >> /opt/xmr/config.json
echo '  "pubOn": ["tcp://'$ip':9505"],' >> /opt/xmr/config.json
echo '  "debug": '$DEBUG >> /opt/xmr/config.json
echo '  "ipv6RespSupport": '$IPV6RESPSUPPORT >> /opt/xmr/config.json
echo '  "ipv6PubSupport": '$IPV6PUBSUPPORT >> /opt/xmr/config.json
echo '}' >> /opt/xmr/config.json

/bin/su -s /bin/bash nobody -c '/usr/bin/php /opt/xmr/xmr.phar'
