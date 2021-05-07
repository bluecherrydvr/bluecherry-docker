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
  echo "        dbname = \"bluecherry\";"; \
  echo "        user = \"bluecherry\";"; \
  echo "        password = \"rohche6PieWi\";"; \
  echo "        host = \"mysql\";"; \
  echo "        userhost = \"%\";"; \
  echo "    };"; \
  echo "};"; \
} > /etc/bluecherry.conf

echo "> chown bluecherry:bluecherry /var/lib/bluecherry/recordings"
chown bluecherry:bluecherry /var/lib/bluecherry/recordings


echo "> /usr/sbin/rsyslogd"
/usr/sbin/rsyslogd
status=$?
if [ $status -ne 0 ]; then
  echo "Failed to start apache2 web server: $status"
  exit $status
fi


echo "> /usr/sbin/apache2"
source /etc/apache2/envvars
/usr/sbin/apache2
status=$?
if [ $status -ne 0 ]; then
  echo "Failed to start apache2 web server: $status"
  exit $status
fi


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
  ps aux |grep apache2 |grep -q -v grep
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
