FROM ubuntu:16.04

# Install packages
ADD provision.sh /provision.sh
ADD serve.sh /serve.sh

ADD supervisor.conf /etc/supervisor/conf.d/supervisor.conf

RUN chmod +x /*.sh

RUN ./provision.sh

EXPOSE 80 22 35729 9876 8000 3000
CMD ["/usr/bin/supervisord"]
