#!/bin/sh
# wget -O - https://raw.githubusercontent.com/wqmeng/pvpgner/main/src/build_image.sh | sh -s 1.13c
GAMENAME=diablo2
GAMESHORT=d2
VERSION=$1
MAINTAINER=wqmeng@gmail.com

mkdir -p /home/src/${GAMESHORT}_$VERSION
cd /home/src/${GAMESHORT}_$VERSION
rm /home/src/${GAMESHORT}_$VERSION/Dockerfile -rf

cat >>/home/src/${GAMESHORT}_$VERSION/Dockerfile<<EOF
FROM docker.io/dokken/centos-stream-9:latest
LABEL game.name="$GAMENAME" game.version="$VERSION" image.maintainer="$MAINTAINER" image.description="A Docker container for pvpgn $GAMENAME $VERSION Server for Closed Battle.Net on centos-stream-9"
RUN wget -qO - https://raw.githubusercontent.com/wqmeng/pvpgner/main/src/build_wine.sh | sh -s $VERSION
EOF
docker build -t wqmeng:pvpgn .