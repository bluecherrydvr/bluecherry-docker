#!/bin/bash

# Bash "strict mode", to help catch problems and bugs in the shell
# script. Every bash script you write should include this. See
# http://redsymbol.net/articles/unofficial-bash-strict-mode/ for
# details.
set -euo pipefail

# Tell apt-get we're never going to be able to give manual
# feedback:
export DEBIAN_FRONTEND=noninteractive

# Update the package listing, so we know what package exist:
wget -q https://dl.bluecherrydvr.com/key/bluecherry.asc -O- | apt-key add -
wget --output-document=/etc/apt/sources.list.d/bluecherry-bionic.list https://dl.bluecherrydvr.com/sources.list.d/bluecherry-bionic.list

apt-get update

# Install security updates:
apt-get -y upgrade

# Install a new package, without unnecessary recommended packages:
apt-get -y install --no-install-recommends bluecherry-client

# Delete cached files we don't need anymore:
apt-get clean
rm -rf /var/lib/apt/lists/*
