#!/bin/bash
echo "> chown bluecherry:bluecherry /var/lib/bluecherry/recordings"
chown bluecherry:bluecherry /var/lib/bluecherry/recordings

# echo "> exec /usr/bin/supervisord"
# exec /usr/bin/supervisord

echo "> /usr/sbin/rsyslogd"
/usr/sbin/rsyslogd
status=$?
if [ $status -ne 0 ]; then
  echo "Failed to start apache2 web server: $status"
  exit $status
fi


# Start the first process
echo "> /usr/sbin/apache2"
source /etc/apache2/envvars
/usr/sbin/apache2
status=$?
if [ $status -ne 0 ]; then
  echo "Failed to start apache2 web server: $status"
  exit $status
fi


# Start the second process
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
# if it detects that either of the processes has exited.
# Otherwise it loops forever, waking up every 60 seconds

# exit_script() {
#     echo "Received signal to exit..."
#     trap - SIGINT SIGTERM # clear the trap
#     kill -- -$$ # Sends SIGTERM to child/sub processes
#     killall apache2
#     killall rsyslogd
#     killall bc-server
#     killall -g entrypoint.sh
# }
# 
# trap exit_script SIGINT SIGTERM

while sleep 30; do
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
