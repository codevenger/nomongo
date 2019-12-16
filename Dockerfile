FROM ubuntu:16.04

RUN \
    DEBIAN_FRONTEND=noninteractive && \
    apt-get update && \
    apt-get install -y \
        build-essential \
        apt-utils \
        ssl-cert \
        apache2 \
        apache2-utils \
        libapache2-mod-perl2 \
        libcgi-pm-perl \
        liblocal-lib-perl \
        cpanminus \
        libexpat1-dev \
        libutf8-all-perl \
        libjson-perl \
        zip \
	wget \
        libdbd-pg-perl

RUN \
    echo 'deb http://apt.postgresql.org/pub/repos/apt/ xenial-pgdg main' >> /etc/apt/sources.list.d/pgdg.list && \
    wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - && \
    apt-get update && \
    apt-get install -y postgresql-10 && \
    a2enmod cgid && \
    a2enmod rewrite && \
    a2enmod headers && \
    a2dissite 000-default && \
    apt-get update -y && \
    apt-get upgrade -y && \
    apt-get -y clean

COPY backend/nomongo.conf /etc/apache2/sites-avaliable/nomongo.conf

RUN \
    cd /etc/apache2/sites-enabled && \
    ln -s ../sites-avaliable/nomongo.conf .

VOLUME ["/var/www/nomongo"]

RUN service postgresql start

EXPOSE 80

EXPOSE 5432

