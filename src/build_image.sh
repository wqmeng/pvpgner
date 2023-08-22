#!/bin/sh
# wget -O - https://raw.githubusercontent.com/wqmeng/pvpgner/main/pvpgn/src/build_image.sh | sh -s 1.13c
GAMENAME=diablo2
GAMESHORT=d2
VERSION=$1
MAINTAINER=wqmeng@gmail.com
# dnf -qy clean all
# dnf -qy update
# dnf -qy install podman podman-docker
# echo >> /etc/containers/nodocker

# systemctl enable --now podman

# podman run hello-world

# dnf -qy install podman-compose

# podman-compose up -d

# podman-compose down

# dnf -qy clean all
# dnf -qy update
# dnf -qy --refresh install wine

# cd /home
mkdir -p /home/src/${GAMESHORT}_$VERSION
cd /home/src/${GAMESHORT}_$VERSION

rm /home/src/${GAMESHORT}_$VERSION/Dockerfile -rf

cat >>/home/src/${GAMESHORT}_$VERSION/Dockerfile<<EOF
FROM dokken/centos-stream-9
LABEL game.name="$GAMENAME" game.version="$VERSION" image.maintainer="$MAINTAINER" image.description="A Docker container for pvpgn $GAMENAME $VERSION Server for Closed Battle.Net on centos-stream-9"
RUN wget -O - https://raw.githubusercontent.com/wqmeng/pvpgner/main/pvpgn/src/build_wine.sh | sh -s $VERSION
EOF

#docker build -t centos:pvpgn .
docker build -t wqmeng:pvpgn .

exit

docker images
docker ps
# 配置端口和网络
# 启动容器
#docker run -it wqmeng:pvpgn /bin/bash
#docker run -d wqmeng:pvpgn /bin/bash
#docker run wqmeng:pvpgn wine regedit /C "c:\diablo2_bnet\PVPGN185+D2GS113C\D2GS113C\d2gs.reg"
#docker run -d --name ${GAMESHORT}_$VERSION wqmeng:pvpgn wine regedit /home/d2gs/d2gs.reg

#docker run -dit --name pvpgn wqmeng:pvpgn /bin/bash # 启动后台运行
#docker run -it --name pvpgn wqmeng:pvpgn /bin/bash

#docker start pvpgn3
#docker stop pvpgn5

#docker exec -it pvpgn3 /bin/bash
#docker exec -it pvpgn3 /bin/bash
#docker attach pvpgn3



#docker run -dt --name pvpgn4 wqmeng:pvpgn /bin/bash # 启动后台运行

docker run -dt --name pvpgn -p $EXTIP:4000:4000 -p $EXTIP:6112:6112 -p $EXTIP:6112:6112/udp -p $EXTIP:6113:6113 -p $EXTIP:6114:6114 wqmeng:pvpgn /bin/bash

docker ps

# 进入docker 操作
docker exec -it pvpgn /bin/bash

pwd
cd /home/pvpgn
# 修改sql. 地址
# storage_path = file:mode=plain;dir=var\users;clan=var\clans;team=var\teams\;default=conf\bnetd_default_user.plain

sed -i 's/^# storage_path = file:mode=plain/storage_path = file:mode=plain/' /home/pvpgn/conf/bnetd.conf
sed -i 's/^storage_path = sql/# storage_path = sql/' /home/pvpgn/conf/bnetd.conf

wine PvPGNConsole.exe >& /dev/null &
#cd /home/pvpgn && wine /home/pvpgn/PvPGNConsole.exe >& /dev/null &
#exit

# 启动国度
sed -i '$a "D2_113c"                 "PvPGN 1.13c Realm"            10.88.0.1:6113' /home/pvpgn/conf/realm.conf

# d2cs.conf
# realmname               =       D2CS
sed -i '/^realmname/c realmname               =       D2_113c' /home/pvpgn/conf/d2cs.conf
# gameservlist            =       <d2gs-IP>,<another-d2gs-IP>
sed -i '/^gameservlist/c gameservlist            =       $EXTIP,198.15.136.156' /home/pvpgn/conf/d2cs.conf
# bnetdaddr               =       <bnetd-IP>:6112
sed -i '/^bnetdaddr/c bnetdaddr               =       $EXTIP:6112' /home/pvpgn/conf/d2cs.conf

# d2dbs.conf
# gameservlist            =       <d2gs-IP>,<another-d2gs-IP>
sed -i '/^gameservlist/c gameservlist            =       $EXTIP,198.15.136.156' /home/pvpgn/conf/d2dbs.conf

wine D2CSConsole.exe >& /dev/null &
wine D2DBSConsole.exe >& /dev/null &

# D2GS
cd /home/d2gs

#cat /home/d2gs/d2gs.reg

sed -i '/^"D2CSIP"="192.168.1.1"/c "D2CSIP"="$EXTIP"' /home/d2gs/d2gs.reg
sed -i '/^"D2DBSIP"="192.168.1.1"/c "D2DBSIP"="$EXTIP"' /home/d2gs/d2gs.reg
# [HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\D2Server\D2GS]  // 64bit Win
# [HKEY_LOCAL_MACHINE\SOFTWARE\D2Server\D2GS] // 32bit Win
\cp /home/d2gs/d2gs.reg /home/d2gs/d2gs_x64.reg

sed -i 's/Wow6432Node\\//' /home/d2gs/d2gs.reg
cat /home/d2gs/d2gs.reg

wine regedit /home/d2gs/d2gs.reg


pkill -f 'PvPGNConsole'
pkill -f 'D2CSConsole'
pkill -f 'D2DBSConsole'
pkill -f 'D2GS'

cd /home/pvpgn
wine PvPGNConsole.exe >& /dev/null &
wine D2CSConsole.exe >& /dev/null &
wine D2DBSConsole.exe >& /dev/null &

cd /home/d2gs
wine D2GS.exe >& /dev/null &

tail /home/pvpgn/var/bnetd.log -n 30
tail /home/pvpgn/var/d2cs.log -n 30
tail /home/pvpgn/var/d2dbs.log -n 30

tail /home/d2gs/d2gs.log -n 30


#docker run -p $EXTIP:6112:6112 wqmeng:pvpgn pvpgn3

#docker container run --expose 6112 -p $EXTIP:6112:6112 pvpgn3

#  查看容器的端口映射情况，在容器外执行：
docker port pvpgn3

docker port 95a7d96e6179

# 绑定 端口 6112 

docker run -d --name d2gs1 wqmeng:pvpgn /bin/bash
docker run -d --name pvpgn3 wqmeng:pvpgn wine regedit /home/d2gs/d2gs.reg



docker start pvpgn1

docker run --name pvpgn2 -d wqmeng:pvpgn bash

# 获取一个未使用的闲置IP地址

#docker run wqmeng:pvpgn cd /root/.wine/drive_c/diablo2_bnet/PVPGN185+D2GS113C/PVPGN
docker run wqmeng:pvpgn cd /home/pvpgn



# 第一个docker需要启动pvpgn
#docker run -dt --name pvpgn -p $EXTIP:4000:4000 -p $EXTIP:6112:6112 -p $EXTIP:6112:6112/udp -p $EXTIP:6113:6113 -p $EXTIP:6114:6114 wqmeng:pvpgn /bin/bash

docker stop pvpgn
docker rm pvpgn

docker ps -a

docker run -dt --name pvpgn -p $EXTIP:4000:4000 -p $EXTIP:6112:6112 -p $EXTIP:6112:6112/udp wqmeng:pvpgn /bin/bash

docker exec -it pvpgn /bin/bash



docker exec -it pvpgn-gs156 /bin/bash

#docker run -p $EXTIP:6112:6112 wqmeng:pvpgn wine /home/pvpgn/PvPGNConsole.exe >& /dev/null &
#docker run -p $EXTIP:6113:6113 wqmeng:pvpgn wine /home/pvpgn/D2CSConsole.exe >& /dev/null &
#docker run -p $EXTIP:6114:6114 wqmeng:pvpgn wine /home/pvpgn/D2DBSConsole.exe >& /dev/null &

#docker container run --expose [容器端口] -p [宿主机端口]:[容器端口] [容器 ID 或名称]
#docker container run --expose 6112 -p $EXTIP:6112:6112 pvpgn3

firewall-cmd --permanent --zone=public --add-port=6112/tcp
firewall-cmd --permanent --zone=public --add-port=6112/udp
firewall-cmd --permanent --zone=public --add-port=6113/tcp
firewall-cmd --permanent --zone=public --add-port=6114/tcp

firewall-cmd --permanent --zone=public --add-port=4000/tcp

firewall-cmd --reload
firewall-cmd --query-port=6112/tcp

firewall-cmd --list-all
firewall-cmd --list-all-zones

/sbin/iptables -L -n
/sbin/iptables -I INPUT -p tcp --dport 6112 -j ACCEPT
/sbin/iptables -I INPUT -p udp --dport 6112 -j ACCEPT
/sbin/iptables -I INPUT -p tcp --dport 4000 -j ACCEPT

/sbin/iptables --save


iptables --list
iptables -t nat -nvL

# Note: D2GS.exe will exit immediately if D2CS or D2DBSDotNet is not running.
docker run -p $IP:4000:4000 wqmeng:pvpgn wine /home/d2gs/D2GS.exe >& /dev/null &
docker run -p $EXTIP:4000:4000 wqmeng:pvpgn wine /home/d2gs/D2GS.exe >& /dev/null &

# 只运行GS的Docker.  和 $EXTIP 使用一个 cs 
docker run -dt --name pvpgn-gs156 -p 198.15.136.156:4000:4000 wqmeng:pvpgn /bin/bash
docker exec -it pvpgn-gs156 /bin/bash

# D2GS
cd /home/d2gs

#cat /home/d2gs/d2gs.reg

sed -i '/^"D2CSIP"="/c "D2CSIP"="$EXTIP"' /home/d2gs/d2gs.reg
sed -i '/^"D2DBSIP"="/c "D2DBSIP"="$EXTIP"' /home/d2gs/d2gs.reg
# [HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\D2Server\D2GS]  // 64bit Win
# [HKEY_LOCAL_MACHINE\SOFTWARE\D2Server\D2GS] // 32bit Win
\cp /home/d2gs/d2gs.reg /home/d2gs/d2gs_x64.reg

sed -i 's/Wow6432Node\\//' /home/d2gs/d2gs.reg
cat /home/d2gs/d2gs.reg

wine regedit /home/d2gs/d2gs.reg

wine D2GS.exe >& /dev/null &


docker cp pvpgn:/home/d2gs/d2gs.reg .
docker cp pvpgn:/home/pvpgn/conf/bnetd.conf .
docker cp pvpgn:/home/pvpgn/conf/realm.conf .
docker cp pvpgn:/home/pvpgn/conf/d2cs.conf .
docker cp pvpgn:/home/pvpgn/conf/d2dbs.conf .
docker cp pvpgn:/home/pvpgn/conf/address_translation.conf .
docker cp pvpgn:/home/pvpgn/conf/versioncheck.json .