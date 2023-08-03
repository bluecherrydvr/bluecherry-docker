#!/bin/bash

set -e

echo "> Update MySQL's my.cnf from environment variables passed in from docker"
echo "> Writing /root/.my.cnf"
{
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
} > /root/.my.cnf

echo "> Update bluecherry server's bluecherry.conf from environment variables passed in from docker"
echo "> Writing /etc/bluecherry.conf"
{
  echo "# Bluecherry configuration file"; \
  echo "# Used to be sure we don't use configurations not suitable for us";\
  echo "version = \"1.0\";"; \
  echo "bluecherry:"; \
  echo "{"; \
  echo "    db:"; \
  echo "    {"; \
  echo "        # 0 = sqlite, 1 = pgsql, 2 = mysql"; \
  echo "        type = 2;"; \
  echo "        dbname = \"$BLUECHERRY_DB_NAME\";"; \
  echo "        user = \"$BLUECHERRY_DB_USER\";"; \
  echo "        password = \"$BLUECHERRY_DB_PASSWORD\";"; \
  echo "        host = \"$BLUECHERRY_DB_HOST\";"; \
  echo "        userhost = \"$BLUECHERRY_DB_ACCESS_HOST\";"; \
  echo "    };"; \
  echo "};"; \
} > /etc/bluecherry.conf

echo "> chown bluecherry:bluecherry /var/lib/bluecherry/recordings"
chown bluecherry:bluecherry /var/lib/bluecherry/recordings


# The bluecherry container's Dockerfile sets rsyslog to route the bluecherry
# server's main log file to STDOUT for process #1, which then gets picked up
# by docker (so its messages get routed out through docker logs, etc.), but
# the location permissions have to be reset on every start of the container:
chmod 777 /proc/self/fd/1


echo "> /usr/sbin/rsyslogd"
/usr/sbin/rsyslogd
status=$?
if [ $status -ne 0 ]; then
  echo "Failed to start rsyslog: $status"
  exit $status
fi

entrypoint_log() {
    if [ -z "${NGINX_ENTRYPOINT_QUIET_LOGS:-}" ]; then
        echo "$@"
    fi
}

if [ "$1" = "nginx" ] || [ "$1" = "nginx-debug" ]; then
    if /usr/bin/find "/docker-entrypoint.d/" -mindepth 1 -maxdepth 1 -type f -print -quit 2>/dev/null | read v; then
        entrypoint_log "$0: /docker-entrypoint.d/ is not empty, will attempt to perform configuration"

        entrypoint_log "$0: Looking for shell scripts in /docker-entrypoint.d/"
        find "/docker-entrypoint.d/" -follow -type f -print | sort -V | while read -r f; do
            case "$f" in
                *.envsh)
                    if [ -x "$f" ]; then
                        entrypoint_log "$0: Sourcing $f";
                        . "$f"
                    else
                        # warn on shell scripts without exec bit
                        entrypoint_log "$0: Ignoring $f, not executable";
                    fi
                    ;;
                *.sh)
                    if [ -x "$f" ]; then
                        entrypoint_log "$0: Launching $f";
                        "$f"
                    else
                        # warn on shell scripts without exec bit
                        entrypoint_log "$0: Ignoring $f, not executable";
                    fi
                    ;;
                *) entrypoint_log "$0: Ignoring $f";;
            esac
        done

        entrypoint_log "$0: Configuration complete; ready for start up"
    else
        entrypoint_log "$0: No files found in /docker-entrypoint.d/, skipping configuration"
    fi
fi

exec "$@"

#echo "> /usr/sbin/nginx"
#source /etc/apache2/envvars
#/usr/sbin/apache2
#status=$?
#if [ $status -ne 0 ]; then
#  echo "Failed to start apache2 web server: $status"
#  exit $status
#fi


echo "> /usr/sbin/bc-server -u bluecherry -g bluecherry"
export LD_LIBRARY_PATH=/usr/lib/bluecherry
/usr/sbin/bc-server -u bluecherry -g bluecherry
status=$?
if [ $status -ne 0 ]; then
  echo "Failed to start bluecherry bc-server: $status"
  exit $status
fi


# Naive check runs checks once a minute to see if either of the processes exited.
# This illustrates part of the heavy lifting you need to do if you want to run
# more than one service in a container. The container exits with an error
# if it detects that any of the processes has exited.
# Otherwise it loops forever, waking up every 15 seconds
while sleep 15; do
  ps aux |grep rsyslog |grep -q -v grep
  PROCESS_1_STATUS=$?
  ps aux |grep nginx |grep -q -v grep
  PROCESS_2_STATUS=$?
  ps aux |grep bc-server |grep -q -v grep
  PROCESS_3_STATUS=$?
  
  # If the greps above find anything, they exit with 0 status
  # If they are not both 0, then something is wrong
  if [ $PROCESS_1_STATUS -ne 0 -o $PROCESS_2_STATUS -ne 0 -o $PROCESS_3_STATUS -ne 0 ]; then
    echo "One of the processes has already exited."
    exit 1
  fi
done
