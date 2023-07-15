#!/bin/sh
set -e
export PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin


# Make sure we are root or we sudo'd!

[ $(id -u) != "0" ] && { echo "Error: You must be root to run this script"; exit 1; }


# set the current path so we aren't confused when moving directories.  Always assuming $workingpath/bluecherry-docker for all Bluecherry scripts
workingpath=$(pwd)


check_docker_process() {
    local process_name=$1
    if docker ps --format '{{.Names}}' | grep -q "$process_name"; then
        echo "Docker process '$process_name' is running."
        return 0
    else
        echo "Docker process '$process_name' is not running."
        return 1
    fi
}


docker_compose_init() {
# Make sure we are still in the bluecherry-docker directory

#uptimekuma


echo "\n\nDownloading latest Bluecherry and related images...this may take a while...\n\n"

cd "$workingpath/bluecherry-docker"

# Init the mailenv config

cp $workingpath/bluecherry-docker/mailenv-example $workingpath/bluecherry-docker/.mailenv

docker compose pull
docker compose up bc-mysql -d

echo "Sleeping 45 seconds to make sure the database is initialized correctly..."
echo "\n\n"
sleep 45
docker compose stop bc-mysql
docker compose up -d bc-mysql

echo "Sleeping another 15 seconds to run the database creation scripts..."
echo "\n\n"

sleep 15
docker compose run bluecherry bc-database-create
docker compose down
#for i in {1..50}; do
#    if docker compose pull; then
#        if docker compose up -d; then
#            break
#        fi
#    fi
    sleep 10
docker compose up -d
#done
}


configure_env() {

echo "\n\n******************************************************************\n\n"
echo "You will be asked the following to configure the docker container:

Time Zone (formatted like this - See https://en.wikipedia.org/wiki/List_of_tz_database_time_zones)
Create a password for the mysql admin
Create a password for the mysql bluecherry user
"

echo "Time Zone (i.e. - America/Chicago): "
read timezone

#read -p "Time Zone (i.e. - America/Chicago)：" timezone
#timezoneset="${timezone:=American/Chicago}"
read -p "Please provide a mysql admin password：" mysqladminpass
read -p "Please provide a mysql bluecherry password：" mysqlbluecherrypass


# Install variables
echo "
# Set to your desired timezone. See https://en.wikipedia.org/wiki/List_of_tz_database_time_zones
TZ=$timezoneset

# Used by bluecherry to login to the MYSQL server
MYSQL_ADMIN_LOGIN=root

# Used by bluecherry as the password for the root account to create databases
MYSQL_ADMIN_PASSWORD=$mysqladminpass

# Name of the MYSQL host. This is usually the name of the service in docker-compose.yml
MYSQL_HOST=bc-mysql

BLUECHERRY_DB_HOST=bc-mysql

# Creates a user used by bluecherry and grants permission to the database.
BLUECHERRY_DB_USER=bluecherry

# Password for above user.
BLUECHERRY_DB_PASSWORD=$mysqlbluecherrypass

# Database name for the bluecherry database. Will delete if it exists.
BLUECHERRY_DB_NAME=bluecherry

# Grants access to the bluecherry user at this hostmask. This should be the IP of your bluecherry
# container. Examples:
#   192.168.0.% - allows access from any IP on the 192.168.0.xxx range
#   %.example.com - allows access to anyone from the example.com domain
#   192.168.1.0/255.255.255.0 - allows from any IP in 192.168.1.xxx range
BLUECHERRY_USERHOST=%

# UID/GID to run bluecherry user as. If you want to access recordings from the host, it is
# recommended to set them the same as a user/group that you want access to read it.
# run `id $(whoami)` to find the UID/GID of your user
BLUECHERRY_GROUP_ID=1000
BLUECHERRY_USER_ID=1000

" > bluecherry-docker/.env
}


configure_smtp() {

echo "Configure SMTP"

read -p "Please provide the SMTP server: " smtpserver
read -p "Please provide the SMTP username: " smtplogin
read -p "Please provide the SMTP password: " smtppassword
read -p "Please provide the SMTP port: " smtpport
#read -p "Please provide the SMTP username: " smtplogin

#read -p "Please provide the NFS mount point for the NFS export" nfsmountpoint

echo "

SMTP_USERNAME=$smtplogin
SMTP_PASSWORD=$smtppassword
SMTP_SERVER=$smtpserver
SMTP_PORT=$smtpport
SERVER_HOSTNAME=$smtpserver
ALWAYS_ADD_MISSING_HEADERS=yes

" > $workingpath/bluecherry-docker/.mailenv

}

check_process() {
  process_name=$1
  status=$(docker ps --filter "name=$process_name" --format '{{.Names}}' | grep -w "$process_name")

  if [ -n "$status" ]; then
    echo "\e[32m$process_name is running\e[0m"  # Green color for running process

#exit 1
  else
    echo "\e[31m$process_name is not running\e[0m"  # Red color for not running process
  fi
#exit 1

}


check_docker_processes() {
  if docker ps --format '{{.Names}}' | grep -q -w 'bc-server' && docker ps --format '{{.Names}}' | grep -q -w 'bc-mysql'; then
    echo "**********************************************************************"
    echo
    echo "Installation finished, you can access the Bluecherry server here below"
    echo "The default login is Admin and the default password is bluecherry"
    echo
    echo "https://$IP:7001"
    echo
    echo "**********************************************************************"
  else
    echo -e "\n\n\e[31mWARNING: Either bc-server or bc-mysql process is not running in Docker.  Below is a listing of the current bc-server and bc-mysql processes\e[0m\n\n"
    echo -e "If you are unable to resolve this issue please visit the Bluecherry community at https://forums.bluecherrydvr.com\n\n"
    echo -e "Below are statuses of the 'bc-server' and 'bc-mysql' containers:\n\n"
check_process "bc-server"
check_process "bc-mysql"
    echo -e "\n\n"

  fi
}



configure_nfs() {

echo "installing nfs"

read -p "Please provide the IP address of the NFS server: " nfsserver
read -p "Please provide the NFS server export path: " nfsexport
#read -p "Please provide the NFS mount point for the NFS export" nfsmountpoint

echo "

version: '3.8'
services:

 bluecherry:
    volumes:
#      - ./recordings:/var/lib/bluecherry/recordings
      - videos:/media/bluecherry/nfs

volumes:
  videos:
    driver_opts:
      type: "nfs"
      o: "addr=$nfsserver,nolock,soft"
      device: ":$nfsexport"
" > $workingpath/bluecherry-docker/docker-compose.override.yml

}


clone_bluecherrydocker() {

 local directory=$pwd/bluecherry-docker
    if [ -d "$directory" ]; then
        echo "Directory $directory exists...skipping...."
     return 0
else

echo "Directory $directory...proceeding with cloning"

cd "$workingpath"
#mkdir bluecherry-server
#cd bluecherry-server
git clone https://github.com/bluecherrydvr/bluecherry-docker.git

#return 1
fi

}

# TODO: Add more installation functions for other distributions as needed.  This should cover the basics.

install_bluecherry() {

echo -e "\n\nInstalling Bluecherry.......\n\n"

distribution=$(detect_distribution)

case $distribution in
  "debian" | "ubuntu")
    install_debian_packages
    ;;
  "centos" | "rhel" | "fedora")
    install_redhat_packages
    ;;
  "sles" | "opensuse" | "suse")
    install_suse_packages
    ;;
  "arch")
    install_arch_packages
    ;;
  "fedora")
    install_fedora_packages
    ;;
  # Add cases for other distributions and call the appropriate installation functions
  *)
    echo "Unsupported distribution, please contact Bluecherry for support in adding your distribution.  Please provide output of /etc/os-release and /etc/lsb_release"
    exit 1
    ;;
esac
}
# Function to detect the Linux distribution
detect_distribution() {
  if [ -f "/etc/os-release" ]; then
    . /etc/os-release
    echo "$ID"
  else
    echo "Unsupported distribution"
    exit 1
  fi
}

# Function to install packages on Debian-based distributions
install_debian_packages() {
  apt-get update
  apt-get install -y git
}

# Function to install packages on Red Hat-based distributions
install_redhat_packages() {
  yum update
  yum install -y git
  install_docker
}

# Function to install packages on SUSE-based distributions
install_suse_packages() {
  zypper refresh
  zypper install -y git
  install_docker
}

# Function to install packages on Arch Linux
install_arch_packages() {
  pacman -Syu --noconfirm git
  install_docker
}

# Function to install packages on Fedora
install_fedora_packages() {
  dnf update
  dnf install -y git
  install_docker
}

install_docker() {

    if command -v docker > /dev/null 2>&1; then
        echo -e "\n\nDocker is installed....skipping!\n\n"
        return 0

    else


 curl -fsSL https://get.docker.com -o /tmp/install-docker.sh
  sh /tmp/install-docker.sh
  systemctl start docker
  systemctl enable docker
    fi

}

uptimekuma() {

echo -e "Installing Uptime Kuma for monitoring of Bluecherry services\n\n"

	DOWNLOAD_URL='https://github.com/louislam/uptime-kuma/releases/download/1.21.3/dist.tar.gz'

	cd "$workingpath/bluecherry-docker" || exit 1

		wget "${DOWNLOAD_URL}"
		tar -zxf "$workingpath/dist.tar.gz" -C "$workingpath"



echo -e "Installing Uptime Kuma for monitoring of Bluecherry services\n\n"

cd bluecherry-docker
wget https://github.com/louislam/uptime-kuma/releases/download/1.21.3/dist.tar.gz
tar -xvf dist.tar.gz
}

read -p "Do you want to install docker and setup Bluecherry server? [y/n]: " answer

# Execute the appropriate function based on the answer
case $answer in
    y)
       install_docker
       install_bluecherry
#	   configure_env
       #clone_bluecherrydocker
        ;;
    n)
        ;;
    *)
        echo "Invalid answer"
        ;;
esac

read -p "Do you want to download and configure the Bluecherry docker images?  If this is the first run of the script then select 'y' [y/n]: " clonedocker

case $clonedocker in
    y)
clone_bluecherrydocker
configure_env
docker_compose_init
        ;;
    n)
#        exit
        ;;
    *)
        echo "Invalid answer"
esac


read -p "Do you want to configure SMTP settings?? [y/n]: " smtp

case $smtp in
    y)
        configure_smtp
        ;;
    n)
#        exit
        ;;
    *)
        echo "Invalid answer"
esac

echo -e "\nNote: NFS is typically recommended for external storage.  Read the Bluecherry docs for information on adding CIFS (smb) shares\n\n"


read -p "Do you want to add a NFS mount? [y/n]: " add_nfs

case $add_nfs in
    y)
        configure_nfs
;;
    n)
#        exit
        ;;
    *)
        echo "Invalid answer"
        ;;
esac


configure_nfs() {

echo "installing nfs"

read -p "Please provide the IP address of the NFS server: " nfsserver
read -p "Please provide the NFS server export path: " nfsexport

echo "

version: '3.8'
services:

 bluecherry:
    volumes:
#      - ./recordings:/var/lib/bluecherry/recordings
      - videos:/media/bluecherry/nfs

volumes:
  videos:
    driver_opts:
      type: "nfs"
      o: "addr=$nfsserver,nolock,soft"
      device: ":$nfsexport"
" > $workingpath/bluecherry-docker/docker-compose.override.yml

}
# Let the user know how to access to Bluecherry web UI

IP=$(ip route get 8.8.8.8 | sed -n '/src/{s/.*src *\([^ ]*\).*/\1/p;q}')
check_docker_processes

# And we hope everything worked...
