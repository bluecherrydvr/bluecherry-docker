#######################################################
# set a base image with environment to build from
#######################################################
FROM ubuntu:20.04 AS scratch
ARG MYSQL_HOST
ARG MYSQL_ADMIN_LOGIN
ARG MYSQL_ADMIN_PASSWORD
ARG BLUECHERRY_DB_USER
ARG BLUECHERRY_DB_PASSWORD
ARG BLUECHERRY_DB_NAME
ARG BLUECHERRY_USERHOST
ARG BLUECHERRY_GROUP_ID
ARG BLUECHERRY_USER_ID

ENV DEBIAN_FRONTEND=noninteractive
ENV MYSQL_ADMIN_LOGIN=$MYSQL_ADMIN_LOGIN
ENV MYSQL_ADMIN_PASSWORD=$MYSQL_ADMIN_PASSWORD
ENV dbname=$BLUECHERRY_DB_NAME
ENV host=$MYSQL_HOST
ENV userhost=$BLUECHERRY_USERHOST
ENV user=$BLUECHERRY_DB_USER
ENV password=$BLUECHERRY_DB_PASSWORD
ENV BLUECHERRY_GROUP_ID=${BLUECHERRY_GROUP_ID:-1001}
ENV BLUECHERRY_USER_ID=${BLUECHERRY_USER_ID:-1001}

#######################################################
# build the application from github
#######################################################

FROM scratch AS build

WORKDIR /root
RUN \
    apt-get update && \
    apt-get install -y sudo supervisor

#######################################################
# create a container to host the bluecherry service
#######################################################

FROM scratch AS bluecherry
MAINTAINER chall@corp.bluecherry.net
WORKDIR /root

ENV DEBIAN_FRONTEND=noninteractive

COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

RUN /usr/sbin/groupadd -r -f -g $BLUECHERRY_GROUP_ID bluecherry && \
    useradd -c "Bluecherry DVR" -d /var/lib/bluecherry -g bluecherry -G audio,video -r -m bluecherry -u $BLUECHERRY_USER_ID && \
    { \
        echo "[client]";                        \
        echo "user=$MYSQL_ADMIN_LOGIN";         \
        echo "password=$MYSQL_ADMIN_PASSWORD";  \
        echo "[mysql]";                         \
        echo "user=$MYSQL_ADMIN_LOGIN";         \
        echo "password=$MYSQL_ADMIN_PASSWORD";  \
        echo "[mysqldump]";                     \
        echo "user=$MYSQL_ADMIN_LOGIN";         \
        echo "password=$MYSQL_ADMIN_PASSWORD";  \
        echo "[mysqldiff]";                     \
        echo "user=$MYSQL_ADMIN_LOGIN";         \
        echo "password=$MYSQL_ADMIN_PASSWORD";  \
    } > /root/.my.cnf                           && \
    apt-get update                              && \
    { \
        echo bluecherry bluecherry/mysql_admin_login password $MYSQL_ADMIN_LOGIN;       \
        echo bluecherry bluecherry/mysql_admin_password password $MYSQL_ADMIN_PASSWORD; \
        echo bluecherry bluecherry/db_host string $host;                                \
        echo bluecherry bluecherry/db_userhost string $userhost;                        \
        echo bluecherry bluecherry/db_name string $dbname;                              \
        echo bluecherry bluecherry/db_user string $user;                                \
        echo bluecherry bluecherry/db_password password $password;                      \
    } | debconf-set-selections  && \
        apt -y install wget gnupg supervisor && \
    wget -q https://dl.bluecherrydvr.com/key/bluecherry.asc && \
    apt-key add bluecherry.asc && \
    wget --no-check-certificate --output-document=/etc/apt/sources.list.d/bluecherry-bionic.list https://dl.bluecherrydvr.com/sources.list.d/bluecherry-bionic-unstable.list && \
    apt-get update && \
    apt --no-install-recommends -y install rsyslog mysql-client bluecherry

COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
    RUN mkdir -p /var/lib/bluecherry/recordings && \
	chmod 770 /var/lib/bluecherry/recordings && \
        chown bluecherry.bluecherry /var/lib/bluecherry/recordings 

CMD ["/usr/bin/supervisord"]
