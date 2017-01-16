FROM nginx
MAINTAINER Opsrobot X Automation Logic "george@opsrobot.co.uk"

COPY start.sh /
COPY nginx.conf /etc/nginx/
COPY nginx-secure.conf /etc/nginx/

COPY dhparams.pem /etc/ssl/private/
CMD /start.sh
