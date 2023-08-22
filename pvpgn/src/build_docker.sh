#!/bin/sh
# setup
# wget -O - http://10.0.0.10/docker/pvpgn/setup.sh | sh

if  [ "$1" == "" ]; then
  VERSION=1.13c
else
  VERSION=$1
fi

dnf -yq clean all
dnf -yq update
# dnf -yq --refresh install wine
dnf -yq install podman podman-docker podman-compose
rm /etc/containers/nodocker -rf
echo >> /etc/containers/nodocker
systemctl enable --now podman
# podman run hello-world
#podman-compose up -d
#podman-compose down

#mkdir -p /home/src
#cd /home/src

wget -qO - http://10.0.0.10/docker/pvpgn/build_image.sh | sh -s ${VERSION}

#wget -O - http://10.0.0.10/docker/pvpgn/build_d2_113c.sh | sh