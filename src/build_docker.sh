#!/bin/sh
# setup
# wget -O - https://raw.githubusercontent.com/wqmeng/pvpgner/main/src/setup.sh | sh

if  [ "$1" == "" ]; then
  VERSION=1.13c
else
  VERSION=$1
fi

# dnf -yq --refresh install wine
dnf -yq install podman podman-docker podman-compose
# touch /etc/containers/nodocker
# systemctl enable --now podman
# podman run hello-world
#podman-compose up -d
#podman-compose down

#mkdir -p /home/src
#cd /home/src

wget -qO - https://raw.githubusercontent.com/wqmeng/pvpgner/main/src/build_image.sh | sh -s ${VERSION}

#wget -O - https://raw.githubusercontent.com/wqmeng/pvpgner/main/src/build_d2_113c.sh | sh