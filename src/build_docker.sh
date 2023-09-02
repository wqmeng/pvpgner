#!/bin/sh
# wget -O - https://raw.githubusercontent.com/wqmeng/pvpgner/main/src/setup.sh | sh

if  [ "$1" == "" ]; then
  D2VERSION=1.13c
else
  D2VERSION=$1
fi

dnf -yq install podman podman-docker podman-compose
wget -qO - https://raw.githubusercontent.com/wqmeng/pvpgner/main/src/build_image.sh | sh -s ${D2VERSION}