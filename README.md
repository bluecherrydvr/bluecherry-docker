# Bluecherry Server Docker

## Installation

The most convenient way to install the Bluecherry docker image is to use this script below.  This does the following:

- Installs git and docker based on your distribution
- Clones this GitHub project, copies mailenv.example to .mailenv (for SMTP configuration)
- Prompts the user for credentials for a SMTP server, login, password, SMTP port (not required, but useful)
- Prompts the user for NFS server (again not required, but useful)

  Once installed you can configure Bluecherry to use the hotname 'bc-mail' to send emails, if you want to do this make sure you configure the SMTP server

```sudo bash -c "$(curl -s https://raw.githubusercontent.com/bluecherrydvr/bluecherry-docker/master/scripts/install.sh)"```


## Versions

The included Dockerfile generates an image based on an **Ubuntu 20.04** docker image. The latest tagged version of the **Bluecherry Server v3.x.x** from the [bluecherry-apps](https://github.com/bluecherrydvr/bluecherry-apps) source repository. The included docker-compose file uses **MySQL version 8.x.x** to host the bluecherry database. 

The current version of this docker code intends to build a bluecherry docker image that is as small as possible, and which does *not* bake in any configuration into the image (since docker images are intended to be ephemeral).

Instead, needed configuration parameters such as database and server passwords are passed into the docker container via environment variables. Environment variables are defined and passed using typical methods with `docker` or `docker-compose` commands.

## Initialization and Usage

### Using Docker Compose

This repository includes a docker-compose.yml file, which makes it easier to manage and run both the bluecherry-server and mysql database containers by using **docker compose** to manage the containers. 

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

Bluecherry server documentation can be found at https://docs.bluecherrydvr.com
