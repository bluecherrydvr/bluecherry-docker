#!/bin/bash

set -e

# Wait for MySQL to be ready
echo "> Waiting for MySQL at $BLUECHERRY_DB_HOST:3306..."
until mysql -h"$BLUECHERRY_DB_HOST" -u"$MYSQL_ADMIN_LOGIN" -p"$MYSQL_ADMIN_PASSWORD" -e "SELECT 1" &>/dev/null; do
  echo "MySQL not reachable - sleeping 5s"
  sleep 5
done
echo "> MySQL is up"

# Create or upgrade the Bluecherry database
echo "> Creating or upgrading Bluecherry database"
if ! echo "exit" | mysql -h"$BLUECHERRY_DB_HOST" -u"$BLUECHERRY_DB_USER" -p"$BLUECHERRY_DB_PASSWORD" "$BLUECHERRY_DB_NAME" &>/dev/null; then
  echo "> Database does not exist or credentials invalid, creating..."
  /bin/bc-database-create || { echo "Database creation failed"; exit 1; }
else
  echo "> Database exists, upgrading if needed..."
  /bin/bc-database-upgrade || { echo "Database upgrade failed"; exit 1; }
fi

# -- Original entrypoint logic --

echo "> Update MySQL's my.cnf from environment variables passed in from docker"
echo "> Writing /root/.my.cnf"
{
    echo "[client]"
    echo "user=$MYSQL_ADMIN_LOGIN"
    echo "password=$MYSQL_ADMIN_PASSWORD"
    echo "[mysql]"
    echo "user=$MYSQL_ADMIN_LOGIN"
    echo "password=$MYSQL_ADMIN_PASSWORD"
    echo "[mysqldump]"
    echo "user=$MYSQL_ADMIN_LOGIN"
    echo "password=$MYSQL_ADMIN_PASSWORD"
    echo "[mysqldiff]"
    echo "user=$MYSQL_ADMIN_LOGIN"
    echo "password=$MYSQL_ADMIN_PASSWORD"
} > /root/.my.cnf

echo "> Update bluecherry server's bluecherry.conf from environment variables passed in from docker"
echo "> Writing /etc/bluecherry.conf"
{
  echo "# Bluecherry configuration file"
  echo "# Used to be sure we don't use configurations not suitable for us"
  echo "version = \"1.0\";"
  echo "bluecherry:"
  echo "{"
  echo "    db:"
  echo "    {"
  echo "        # 0 = sqlite, 1 = pgsql, 2 = mysql"
  echo "        type = 2;"
  echo "        dbname = \"$BLUECHERRY_DB_NAME\";"
  echo "        user = \"$BLUECHERRY_DB_USER\";"
  echo "        password = \"$BLUECHERRY_DB_PASSWORD\";"
  echo "        host = \"$BLUECHERRY_DB_HOST\";"
  echo "        userhost = \"$BLUECHERRY_DB_ACCESS_HOST\";"
  echo "    };"
  echo "};"
} > /etc/bluecherry.conf

echo "> chown bluecherry:bluecherry /var/lib/bluecherry/recordings"
chown bluecherry:bluecherry /var/lib/bluecherry/recordings
chmod ug+rwx /var/lib/bluecherry/recordings

echo "> Starting rsyslogd"
chmod 777 /proc/self/fd/1
/usr/sbin/rsyslogd

echo "> Starting Apache2"
source /etc/apache2/envvars
/usr/sbin/apache2 -DFOREGROUND &

echo "> Starting Bluecherry server"
/usr/sbin/bc-server -u bluecherry -g bluecherry
status=$?
if [ $status -ne 0 ]; then
  echo "Failed to start bluecherry bc-server: $status"
  exit $status
fi

# Monitor essential services
while sleep 15; do
  ps aux | grep -q "[r]syslogd"
  STATUS1=$?
  ps aux | grep -q "[a]pache2"
  STATUS2=$?
  ps aux | grep -q "[b]c-server"
  STATUS3=$?
  if [ $STATUS1 -ne 0 ] || [ $STATUS2 -ne 0 ] || [ $STATUS3 -ne 0 ]; then
    echo "One of the processes has exited unexpectedly. Stopping container."
    exit 1
  fi
done
