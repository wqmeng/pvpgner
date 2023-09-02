#!/bin/sh
# wget -O - https://raw.githubusercontent.com/wqmeng/pvpgner/main/src/build_image.sh | sh -s 1.13c
GAMENAME=diablo2
GAMESHORT=d2
D2VERSION=$1
MAINTAINER=wqmeng@gmail.com

mkdir -p /home/src/${GAMESHORT}_$D2VERSION
cd /home/src/${GAMESHORT}_$D2VERSION
rm /home/src/${GAMESHORT}_$D2VERSION/Dockerfile -rf

cat >>/home/src/${GAMESHORT}_$D2VERSION/Dockerfile<<EOF
FROM docker.io/dokken/centos-stream-9:latest
LABEL game.name="$GAMENAME" game.version="$D2VERSION" image.maintainer="$MAINTAINER" image.description="A Docker container for pvpgn $GAMENAME $D2VERSION Server for Closed Battle.Net on centos-stream-9"
RUN wget -qO - https://raw.githubusercontent.com/wqmeng/pvpgner/main/src/build_wine.sh | sh -s $D2VERSION
EOF
docker build -t wqmeng:pvpgn .