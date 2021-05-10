# Bluecherry Server Docker Source

This repository contains the files required to build a docker image for the [Bluecherry Network Video Recorder](https://www.bluecherrydvr.com) Server Application and its immediate dependencies. Work in this repository is based off work by:
- [Bluecherry](https://github.com/bluecherrydvr/)
- [rayzorben](https://github.com/rayzorben/bluecherry-docker)
- [Sicada Co.](https://github.com/sicada/bluecherry-docker/)

## Versions

The included Dockerfile generates an image based on an **Ubuntu 20.04** docker image. The latest tagged version of the **Bluecherry Server v3.x.x** from the [bluecherry-apps](https://github.com/bluecherrydvr/bluecherry-apps) source repository. The included docker-compose file uses **MySQL version 8.x.x** to host the bluecherry database. 

The current version of this docker code intends to build a bluecherry docker image that is as small as possible, and which does *not* bake in any configuration into the image (since docker images are intended to be ephemeral).

Instead, needed configuration parameters such as database and server passwords are passed into the docker container via environment variables. Environment variables are defined and passed using typical methods with `docker` or `docker-compose` commands.

## Initialization and Usage

### Building vs Pre-Built Image
For most use cases, rebuilding of the bluecherry-server docker image is **not** necessary. Instead, you may pull a prebuilt image from the dockerhub repo at [sicadaco/bluecherry-server:latest](https://hub.docker.com/repository/docker/sicadaco/bluecherry-server/). 

The prebuilt image is currently about 1 GB in size. If you choose to build your own docker image, be aware that it is a disk space and time intensive process. A full build will take on the order of 15 to 45 minutes and use up to about 10 GB of disk space.

This repository includes a docker-compose.yml file, which makes it easier to manage and run both the bluecherry-server and mysql database containers by using **docker-compose** to manage the containers. However, the containers can of course be used directly with **docker** as well, though this is more difficult and therefore not recommended.

### Prerequisites / First Steps

_Note: These steps are intended to work in a command line terminal of a Linux or macOS system._

1. Ensure `docker` and optionally `docker-compose` are installed on the host system.
2. Clone this repo:  `git clone https://github.com/sicada/bluecherry-docker/`
3. Change into the repo's directory:  `cd bluecherry-docker`
4. Pull the images from dockerhub
    1. Using docker-compose (pulls both bluecherry and mysql):  `sudo docker-compose pull`
    2. Using docker (pull bluecherry):  `sudo docker pull sicadaco/bluecherry-server:latest`
    3. Using docker (pull mysql):  `sudo docker pull mysql:latest`
5. Add a .env file that contains the necessary config info. You can use the included file named **dotenv** as a template:
    1. Copy the template:  `cp dotenv .env`
    2. Edit the values as needed using a graphical text editor or e.g.:  `nano .env`
    3. Save the .env file and don't share your login credentials with the Internet!
    4. **_WARNING: Change the default password values for use in a production environment!_**


### Running For the First Time

1. Start the mysql container and let it initialize: `sudo docker-compose up mysql`
2. After the mysql setup is done, stop the container by pressing CTRL+C
3. Start the mysql container in the background: `sudo docker-compose up -d mysql`
4. Run the bluecherry-server container with a special command to setup the database: `sudo docker-compose run bluecherry bc-database-create`
5. Run the bluecherry-server normally: `sudo docker-compose up -d bluecherry`
6. You should now be able to access the bluecherry web interface at https://localhost:7001/

### Running with an existing database

1. Start the mysql container in the background: `sudo docker-compose up -d mysql`
2. Run the bluecherry-server container with a special command to upgrade the database:
    1. `sudo docker-compose run bluecherry bc-database-upgrade`
    2. _Note: This only needs to be done once- whenever you begin using a new version of bluecherry-server with an existing database._
3. Run the bluecherry-server normally: `sudo docker-compose up -d bluecherry`
4. You should now be able to access the bluecherry web interface at https://localhost:7001/

## Advanced Usage

### Enable GPU transcoding

If your host environment supports VAAPI (https://wiki.libav.org/Hardware/vaapi) AND you have a /dev/dri entry on the host machine (for Linux) you can enable GPU transcoding in docker-compose.yml by uncommenting this section:

    #devices:
    #  - /dev/dri:/dev/dri

## Debugging

### Log Files

To view logs from the Bluecherry server, you can use the typical `docker logs` or `docker-compose logs` facilities from the host machine. However, it may be useful to inspect the server logs directly from within the container... the subsections below show one method to do so.

#### Reading the Bluecherry Log File
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
