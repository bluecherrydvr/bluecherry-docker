# Bluecherry Server Docker Source

This repository contains the files required to build a docker image for the Bluecherry NVR Server (https://www.bluecherrydvr.com). Work in this repository is based off work by rayzorben (https://github.com/rayzorben/bluecherry-docker) and Sicada Co. (https://github.com/sicada/bluecherry-docker/).

## Versions

The included Dockerfile generates an image based on an **Ubuntu 20.04** docker image. The latest tagged version of the **Bluecherry Server v3.x.x** from the source repository at https://github.com/bluecherrydvr/bluecherry-apps. The included docker-compose file uses **MySQL version 8.x.x** to host the bluecherry database. 

The current version of this docker code intends to build a bluecherry docker image that is as small as possible, and which does *not* bake in any configuration into the image (since docker images are intended to be ephemeral).

Instead, needed configuration parameters such as database and server passwords are passed into the docker container via environment variables. Environment variables are defined and passed using typical methods with `docker` or `docker-compose` commands.

## Install / Usage

For most use cases, rebuilding of the docker image is not necessary. Instead, you may pull a prebuilt image from the dockerhub repo at https://hub.docker.com/repository/docker/sicadaco/bluecherry-server/ . 
**Note:** The prebuilt image is currently about 1 GB in size.

This repo includes a docker-compose.yml file, which makes it easier to manage and run both the bluecherry-server and mysql database containers. The process to "pull and run" the bluecherry server would then one of the following:

### Installation / Running with a new (no existing) database
1. Clone this repo: `git clone https://github.com/sicada/bluecherry-docker/`
2. Change into the repo's directory: `cd bluecherry-docker`
3. Pull the images from dockerhub: `sudo docker-compose pull`
4. Add a .env file that contains the necessary passwords/config info. You can use the file named **dotenv** as a template, but must rename it to the literal name **.env** in the same directory. **WARNING:** It is recommended to change at least the password values for use in a production environment!
5. Start the mysql container and let it initialize: `sudo docker-compose up mysql`
6. After the mysql setup is done, stop the container by pressing CTRL+C
7. Start the mysql container in the background: `sudo docker-compose up -d mysql`
8. Run the bluecherry-server container with a special command to setup the database: `sudo docker-compose run bluecherry bc-database-create`
9. Run the bluecherry-server normally: `sudo docker-compose up -d bc-server`
10. You should now be able to access the bluecherry web interface at https://localhost:7001/

### Running with an existing database
1. Clone this repo: `git clone https://github.com/sicada/bluecherry-docker/`
2. Change into the repo's directory: `cd bluecherry-docker`
3. Pull the images from dockerhub: `sudo docker-compose pull`
4. Add a .env file that contains the necessary passwords/config info. You can use the file named **dotenv** as a template, but must rename it to the literal name **.env** in the same directory. **WARNING:** It is recommended to change at least the password values for use in a production environment!
5. Start the mysql container in the background: `sudo docker-compose up -d mysql`
6. Run the bluecherry-server container with a special command to upgrade the database: `sudo docker-compose run bluecherry bc-database-upgrade`
7. Run the bluecherry-server normally: `sudo docker-compose up -d bc-server`
8. You should now be able to access the bluecherry web interface at https://localhost:7001/

## Enable GPU transcoding

If your host environment supports VAAPI (https://wiki.libav.org/Hardware/vaapi) AND you have a /dev/dri entry on the host machine (for Linux) you can enable GPU transcoding in docker-compose.yml by uncommenting this section:

    #devices:
    #  - /dev/dri:/dev/dri

## Debugging

To view logs from the Bluecherry server, you **can't** use the typical `docker logs` or ` docker-compose logs` facilities, since bluecherry's main server process uses rsyslog to handle its logs. Most bluecherry server logs are placed in the container in /var/log/bluecherry.log . 

### Reading the Bluecherry Log File
To view the bluecherry.log file, you can run a `tail` command inside the running bluecherry docker container like so: 

`sudo docker exec -it bc-server /bin/bash -c "tail -f /var/log/bluecherry.log"`

An example log output from a bluecherry server that started up successfully is shown below:

```
May  7 13:50:14 93036b43197e bc-server[14]: I(): Status reports are served at /tmp/bluecherry_status
May  7 13:50:14 93036b43197e bc-server[14]: I(): Status reports are served at /tmp/bluecherry_trigger
May  7 13:50:14 93036b43197e bc-server[14]: I(): Started bc-server 3.0.5 (toolchain 9.3.0) 69a7f17 heads/master
May  7 13:50:14 93036b43197e bc-server[14]: I(): SQL database connection opened
```

### Check for running processes in the bluecherry container

You can check the status of the processes running inside the container. There should be processes for apache2, rsyslog, and bc-server at the very least. An example command to check the container's running processes is: 

`sudo docker exec -it bc-server /bin/bash -c "ps ax"`

An example process list (ps) output from a running bluecherry docker container is shown below:

```
  PID TTY      STAT   TIME COMMAND
    1 ?        Ss     0:00 /bin/sh -c "/entrypoint.sh"
    7 ?        S      0:00 /bin/bash /entrypoint.sh
   10 ?        Ssl    0:00 /usr/sbin/rsyslogd
   13 ?        Ss     0:00 /usr/sbin/apache2
   15 ?        S      0:00 /usr/sbin/apache2
   16 ?        S      0:00 /usr/sbin/apache2
   17 ?        S      0:00 /usr/sbin/apache2
   18 ?        S      0:00 /usr/sbin/apache2
   19 ?        S      0:00 /usr/sbin/apache2
   20 ?        Ssl    0:00 /usr/sbin/bc-server -u bluecherry -g bluecherry
  221 ?        S      0:00 sleep 15
  230 pts/0    Rs+    0:00 ps ax
```

## More Info

Bluecherry server documentation can be found at https://bluecherry-apps.readthedocs.io/en/latest/setup-configuration.html
