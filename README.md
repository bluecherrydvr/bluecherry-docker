# Bluecherry server docker 
Docker build scripts for Bluecherry NVR (https://www.bluecherrydvr.com)

Based off the initial work by rayzorben (https://github.com/rayzorben/bluecherry-docker)

This installs the latest beta of Bluecherry server using a Ubuntu 18.04 docker image.

1. Clone the repository with `git clone https://github.com/bluecherrydvr/bluecherry-docker`
2. Default passwords for mysql are in `.env`.  It is recommended to change atleast MYSQL_ADMIN_PASSWORD for a production environment
3. Start mysql image with `docker-compose up -d mysql` (Follow this step by step guide if you do not have docker-compose - https://docs.docker.com/compose/install/)
4. Build the bluecherry image with `docker-compose build`
5. Start bluecherry with `docker-compose up -d bluecherry`

# Enable GPU transcoding:

If your host environment supports VAAPI (https://wiki.libav.org/Hardware/vaapi) AND you have /dev/dri you can enable GPU transcoding in docker-compose.yml by uncommenting this section:

    #devices:
    #  - /dev/dri:/dev/dri

You should be able to access the bluecherry server interface on https://localhost:7001

Bluecherry server documentation can be found at https://bluecherry-apps.readthedocs.io/en/latest/setup-configuration.html
