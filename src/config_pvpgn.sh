#!/bin/sh
# https://forums.pvpgn.pro/viewtopic.php?id=2045
# D2客户端登录过程与各个端口的对应关系
# 1 连接服务器  6112
# 2 存取你的账户和检查版本  6112
# 3 显示国度            6112,  这里如果客户端连不上6113,但是在服务器内部通信正常 pvpgn(bnetd 6112) 能 和 (d2cs 6113)通信, 依然可以顺利的在右侧显示国度列表.
# 4 连接国度            6113,  客户端连接国度的时候, 需要访问的是6113端口. 需要6113端口开放外网IP和连接. 不然就出现下面的错误提示, 见图片 开启6112端口错误 和 5 错误描述.
# 5 显示国度账号里的人物6113, !!!如果这里失败, 会在国度左侧的人物列表位置提示无法连接 6112 端口, 或者 6112 端口被防火墙挡住.
# 6 建立房间进红门游戏, 4000. 对应的服务是gs
# 7 之后的游戏和国度,保存账号状态, 都会访问 6113 和 4000,  端口6112已经不再使用, 完成了使命.
# docker 准备
#
# 错误排除指导说明:
# 1 无法访问连上服务器, 游戏服务器的外网IP 6112 端口被防火墙挡住 或者 服务器没有正常启动.
# 2 连上服务器提示没有国度, 服务器上面 d2cs 没有启动, 或者 d2cs 无法 和 pvpgn 正常通信, 或者 realm 里面没有配置好 国度列表, 或者 d2cs 配置的国度名称和realm里面的国度列表的名称不对应.
# 3 连上服务器显示了国度列表, 但是在左侧不能显示玩家账号里面的角色人物列表, 提示6112端口没有打开.  检查服务器上面是否防火墙开启了 6113 端口. 如果防火墙开启6113, 检查d2cs是否正常启动提供服务.  如果使用了内网, 是否做了内网6113端口和外网6113端口的正常映射和通信.
# 4 玩家角色无法创建房间或者等待创建房间排队,  检查 服务器 4000 端口是否开放,  d2gs 是否顺利启动 通信和服务.  d2gs设置的最大房间数是否大于 0.

Setup_bnetd() {
  if [ "$1" == "" ]; then
    CONF_PATH=/home/pvpgn
  else
    CONF_PATH=$1
  fi
  sed -i 's/^# storage_path = file:mode=plain/storage_path = file:mode=plain/' ${CONF_PATH}/conf/bnetd.conf
  sed -i 's/^storage_path = sql/# storage_path = sql/' ${CONF_PATH}/conf/bnetd.conf 
}

Setup_realm() {
  if [ "$1" == "" ]; then
    CONF_PATH=/home/pvpgn
  else
    CONF_PATH=$1
  fi
  REALM_NAME=$2
  REALM_DES=$3
  REALM_IP=$4
  REALM_PORT=$5
  sed -i '/^"'${REALM_NAME}'"/d' ${CONF_PATH}/conf/realm.conf
  sed -i '$a "'${REALM_NAME}'"                 "'"${REALM_DES}"'"            '${REALM_IP}':'${REALM_PORT} ${CONF_PATH}/conf/realm.conf
}

Setup_d2cs() {
    if [ "$1" == "" ]; then
        CONF_PATH=/home/pvpgn
    else
        CONF_PATH=$1
    fi
    REALM_NAME=$2
    D2GS_IP=$3
    D2CS_PORT=$4
    BNETD_IP=$5

    sed -i '/^realmname/c realmname               =       "'${REALM_NAME}'"' ${CONF_PATH}/conf/d2cs.conf

    #sed -i '/^servaddrs/c servaddrs            =       '${IP}':6113' /home/pvpgn/conf/d2cs.conf
    sed -i '/^servaddrs/c servaddrs            =       0.0.0.0:'${D2CS_PORT} ${CONF_PATH}/conf/d2cs.conf

    #gameservlist            =       198.15.136.155 (d.d.d.d), 198.15.136.156 (d.d.d.d)-2

    #sed -i '/^gameservlist/c gameservlist            =       198.15.136.155,198.15.136.156' ${CONF_PATH}/conf/d2cs.conf
    D2GSIPS=$(sed -n '/^gameservlist/p' ${CONF_PATH}/conf/d2cs.conf | grep -Po '=\s*.*' | grep -Po '(25[0-5]|2[0-4][0-9]|[0-1]{1}[0-9]{2}|[1-9]{1}[0-9]{1}|[1-9])\.(25[0-5]|2[0-4][0-9]|[0-1]{1}[0-9]{2}|[1-9]{1}[0-9]{1}|[1-9]|0)\.(25[0-5]|2[0-4][0-9]|[0-1]{1}[0-9]{2}|[1-9]{1}[0-9]{1}|[1-9]|0)\.(25[0-5]|2[0-4][0-9]|[0-1]{1}[0-9]{2}|[1-9]{1}[0-9]{1}|[0-9]).*')

    if [ "${D2GSIPS}" != "" ]; then
        D2GS_IP=${D2GSIPS}','${D2GS_IP}
    fi

    sed -i '/^gameservlist/c gameservlist            =       '${D2GS_IP} ${CONF_PATH}/conf/d2cs.conf

    #sed -n '/^gameservlist/p' ${CONF_PATH}/conf/d2cs.conf

    #sed -i '/^servaddrs/c servaddrs            =       '${IP}':6113' ${CONF_PATH}/conf/d2cs.conf
    #sed -n '/^gameservlist/p' /home/pvpgn/conf/d2cs.conf

    #bnetdaddr               =       198.15.136.155 (a.a.a.a):6112
    #sed -i '/^bnetdaddr/c bnetdaddr               =       198.15.136.155:6112' /home/pvpgn/conf/d2cs.conf
    sed -i '/^bnetdaddr/c bnetdaddr               =       '${BNETD_IP}':6112' ${CONF_PATH}/conf/d2cs.conf
    #sed -n '/^bnetdaddr/p' /home/pvpgn/conf/d2cs.conf
}

Setup_d2dbs() {
    if [ "$1" == "" ]; then
        CONF_PATH=/home/pvpgn
    else
        CONF_PATH=$1
    fi
    D2GS_IP=$2

    #sed -i '/^servaddrs/c servaddrs            =       '${IP}':6114' /home/pvpgn/conf/d2dbs.conf

    #sed -i '/^gameservlist/c gameservlist            =       198.15.136.155,198.15.136.156' /home/pvpgn/conf/d2dbs.conf


    D2GSIPS=$(sed -n '/^gameservlist/p' ${CONF_PATH}/conf/d2dbs.conf | grep -Po '=\s*.*' | grep -Po '(25[0-5]|2[0-4][0-9]|[0-1]{1}[0-9]{2}|[1-9]{1}[0-9]{1}|[1-9])\.(25[0-5]|2[0-4][0-9]|[0-1]{1}[0-9]{2}|[1-9]{1}[0-9]{1}|[1-9]|0)\.(25[0-5]|2[0-4][0-9]|[0-1]{1}[0-9]{2}|[1-9]{1}[0-9]{1}|[1-9]|0)\.(25[0-5]|2[0-4][0-9]|[0-1]{1}[0-9]{2}|[1-9]{1}[0-9]{1}|[0-9]).*')

    if [ "${D2GSIPS}" != "" ]; then
        D2GS_IP=${D2GSIPS}','${D2GS_IP}
    fi

    sed -i '/^gameservlist/c gameservlist            =       '${D2GS_IP} ${CONF_PATH}/conf/d2dbs.conf
    #sed -n '/^gameservlist/p' /home/pvpgn/conf/d2dbs.conf
}

Setup_address_translation() {
    if [ "$1" == "" ]; then
        CONF_PATH=/home/pvpgn
    else
        CONF_PATH=$1
    fi
    D2CS_IP_input=$2
    D2CS_IP_output=$3
    D2CS_PORT=$4
    D2GS_IP_input=$5
    D2GS_IP_output=$6

    sed -i '/^'${D2CS_IP_input}'/d' ${CONF_PATH}/conf/address_translation.conf
    sed -i '/1.2.3.4:6113/a '${D2CS_IP_input}':'${D2CS_PORT}'   '${D2CS_IP_output}':'${D2CS_PORT}'          10.88.0.0/16         ANY' ${CONF_PATH}/conf/address_translation.conf

    # sed -i '/^'${D2GS_IP_input}'/d' ${CONF_PATH}/conf/address_translation.conf
    sed -i '/1.2.3.4:4000/a '${D2GS_IP_input}':4000   '${D2GS_IP_output}':4000          10.88.0.0/16         ANY' ${CONF_PATH}/conf/address_translation.conf
    #LOCAL IP ADDRESS:6113    EXTERNAL IP ADDRESS:6113        192.168.1.0/24            ANY
}

Setup_d2gs() {
    if [ "$1" == "" ]; then
        CONF_PATH=/home/d2gs
    else
        CONF_PATH=$1
    fi


    mkdir -p /home/d2gs
    cd /home/d2gs    
    # wget -q http://10.0.0.10/docker/d2gs/D2GS_Base.7z
    # wget -q https://ia801809.us.archive.org/29/items/d2gs-base.-7z/D2GS_Base.7z
    wget -q https://github.com/wqmeng/pvpgner/raw/main/d2gs/D2GS_${VERSION}.7z

    # create all files soft link in lnsrc to lntest .
    # ln -s -t ./lntest ./lnsrc/*
    # 7za x -y D2GS_Base.7z
    # mv D2GS_Base/* .
    # rm D2GS_Base -rf
    # rm D2GS_Base.7z -rf
    7za x -y D2GS_${VERSION}.7z
    mv D2GS_${VERSION}/* .
    rm D2GS_${VERSION} -rf
    ln -s -t /home/d2gs/ /home/d2gs_base/*
    touch d2_${VERSION}

    D2CS_IP=$2
    D2DBS_IP=$3
    D2GS_PASSWD=$4
    sed -i '/^EnableWarden/c EnableWarden=0' ${CONF_PATH}/d2server.ini
    sed -i '/^EnableEthSocketBugFix/c EnableEthSocketBugFix=0' ${CONF_PATH}/d2server.ini
    sed -i '/^DisableBugMF/c DisableBugMF=0' ${CONF_PATH}/d2server.ini

    sed -i '/^"D2CSIP"/c "D2CSIP"="'${D2CS_IP}'"' ${CONF_PATH}/d2gs.reg
    sed -i '/^"D2DBSIP"/c "D2DBSIP"="'${D2DBS_IP}'"' ${CONF_PATH}/d2gs.reg
    # 4096 MaxGames
    sed -i '/^"MaxGames"/c "MaxGames"=dword:00001000' ${CONF_PATH}/d2gs.reg
    # telnet 8888 password: abcd123
    sed -i '/^"AdminPassword"/c "AdminPassword"="9e75a42100e1b9e0b5d3873045084fae699adcb0"' ${CONF_PATH}/d2gs.reg
    # [HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\D2Server\D2GS]  // 64bit Win
    # [HKEY_LOCAL_MACHINE\SOFTWARE\D2Server\D2GS] // 32bit Win
    \cp ${CONF_PATH}/d2gs.reg ${CONF_PATH}/d2gs_x64.reg

    sed -i 's/Wow6432Node\\//' ${CONF_PATH}/d2gs.reg
    #cat ${CONF_PATH}/d2gs.reg
    cd ${CONF_PATH}
    wine regedit ${CONF_PATH}/d2gs.reg
}

Setup_Pvpgn() {
    Setup_realm '/home/pvpgn' $REALM_NAME "$REALM_NAME for $VERSION" ${BBBB} ${D2CS_PORT}
    Setup_bnetd '/home/pvpgn'
    Setup_d2cs '/home/pvpgn' $REALM_NAME ${DDDD} ${D2CS_PORT} ${AAAA}
    Setup_d2gs '/home/d2gs' ${BBBB} ${CCCC} '9e75a42100e1b9e0b5d3873045084fae699adcb0'
    Setup_d2dbs '/home/pvpgn' ${DDDD}
    Setup_address_translation '/home/pvpgn' ${BBBB} ${EXTIP} ${D2CS_PORT} ${DDDD} ${EXTIP}
    rm -rf /home/pvpgn/inner_ip
    touch /home/pvpgn/inner_ip
    echo ${BBBB} >> /home/pvpgn/inner_ip
}

Update_InnerIP() {
    # //
    OLDIP=$(cat /home/pvpgn/inner_ip)

    # sed -i 's/Wow6432Node\\//' ${CONF_PATH}/d2gs.reg
    # // OLDIP
    # // NEWIP
    if [ "$IP" != "$OLDIP" ]; then
        sed -i 's/'$OLDIP'/'$IP'/' /home/pvpgn/conf/realm.conf
        sed -i 's/'$OLDIP'/'$IP'/' /home/pvpgn/conf/d2cs.conf
        sed -i 's/'$OLDIP'/'$IP'/' /home/pvpgn/conf/d2dbs.conf
        sed -i 's/'$OLDIP'/'$IP'/' /home/pvpgn/conf/address_translation.conf

        sed -i 's/'$OLDIP'/'$IP'/' /home/d2gs/d2gs.reg
        sed -i 's/'$OLDIP'/'$IP'/' /home/d2gs/d2gs_x64.reg

        rm -rf /home/pvpgn/inner_ip
        touch /home/pvpgn/inner_ip
        echo ${IP} >> /home/pvpgn/inner_ip    
    fi
    
}

Start_Pvpgn() {
    if [ "$1" == "" ]; then
        CONF_PATH=/home/pvpgn
    else
        CONF_PATH=$1
    fi

    Update_InnerIP

    pkill -f 'PvPGNConsole'

    cd ${CONF_PATH}
    # wine PvPGNConsole.exe >& /dev/null &
    nohup bash -c "wine PvPGNConsole.exe &" </dev/null &>/dev/null &
    sleep 1
}

Start_d2cs() {
    if [ "$1" == "" ]; then
        CONF_PATH=/home/pvpgn
    else
        CONF_PATH=$1
    fi

    pkill -f 'D2CSConsole'

    cd ${CONF_PATH}
    # wine D2CSConsole.exe >& /dev/null &
    nohup bash -c "wine D2CSConsole.exe &" </dev/null &>/dev/null &
    sleep 1
}

Start_d2dbs() {
    if [ "$1" == "" ]; then
        CONF_PATH=/home/pvpgn
    else
        CONF_PATH=$1
    fi
    pkill -f 'D2DBSConsole'

    cd ${CONF_PATH}
    # wine D2DBSConsole.exe >& /dev/null &
    nohup bash -c "wine D2DBSConsole.exe &" </dev/null &>/dev/null &
    sleep 1
}

Start_d2gs() {
    if [ "$1" == "" ]; then
        CONF_PATH=/home/d2gs
    else
        CONF_PATH=$1
    fi
    pkill -f 'D2GS'

    cd ${CONF_PATH}
    # wine D2GS.exe >& /dev/null &
    # nohup bash -c "wine D2GS.exe &" </dev/null &>/dev/null &
    echo ${CONF_PATH}
    # wine D2GS.exe
    # nohup bash -c "wine D2GS.exe >& /dev/null &" </dev/null &>/dev/null &
    # wine D2GS.exe 2>&1 | tee /home/output
    # nohup bash '(wine D2GS.exe) |& tee out.log'
    nohup bash -c "wine D2GS.exe &" </dev/null &>/dev/null &
    sleep 1
}

Add_realm() {
    # if [ "$1" == "" ]; then
    #     CONF_PATH=/home/pvpgn_$1
    # else
    #     CONF_PATH=$1
    # fi
    
    REALM_NAME=$1
    echo 'Add a new realm: '${REALM_NAME}

    CONF_PATH=/home/pvpgn_${REALM_NAME}
    rm -rf ${CONF_PATH}
    mkdir -p ${CONF_PATH}
    \cp -r /home/pvpgn/* ${CONF_PATH}

    cd ${CONF_PATH}
    # NEW_REAL_IP=$2
    REALM_PORT=$2
    BNETD_IP=$3

    Setup_realm ${CONF_PATH} ${REALM_NAME} '"PvPGN '${REALM_NAME}' Realm"' ${BBBB} ${REALM_PORT}
    #Setup_bnetd ${CONF_PATH}
    # Setup_d2cs ${CONF_PATH} ${REALM_NAME} ${BBBB} ${REALM_PORT} ${BNETD_IP}
    # Setup_d2dbs '/home/pvpgn' ${DDDD}

    # d2gs can not create in the same pvpgn docker container, as it already has one d2gs takes the port 4000.
    # Setup_d2gs '/home/d2gs' ${NEW_REALM_IP} ${CCCC} '9e75a42100e1b9e0b5d3873045084fae699adcb0'

    # When we add a new realm, we should create a new gameserver to it.

    Start_Pvpgn '/home/pvpgn'
    Start_d2cs '/home/pvpgn'
    Start_d2cs ${CONF_PATH}
    Start_d2dbs '/home/pvpgn'
    Start_d2gs '/home/d2gs'
    sleep 1
}

Add_d2gs() {
    REALM_NAME=$1
    # d2cs ip
    BBBB=$2
    # d2dbs ip
    CCCC=$3
    # d2gs input ip
    DDDD=$4
    # d2gs output
    EXTIP=$5

    Setup_d2gs '/home/d2gs' ${BBBB} ${CCCC} '9e75a42100e1b9e0b5d3873045084fae699adcb0'
    # address translation should be correct on the pvpgn container, not here?
    # Setup_address_translation '/home/pvpgn' ${BBBB} ${EXTIP} ${D2CS_PORT} ${DDDD} ${EXTIP}
}

Check_DB()
{
    if [[ -s /usr/local/mariadb/bin/mysql && -s /usr/local/mariadb/bin/mysqld_safe && -s /etc/my.cnf ]]; then
        MySQL_Bin="/usr/local/mariadb/bin/mysql"
        MySQL_Config="/usr/local/mariadb/bin/mysql_config"
        MySQL_Dir="/usr/local/mariadb"
        Is_MySQL="n"
        DB_Name="mariadb"
    else
        MySQL_Bin="/usr/local/mysql/bin/mysql"
        MySQL_Config="/usr/local/mysql/bin/mysql_config"
        MySQL_Dir="/usr/local/mysql"
        Is_MySQL="y"
        DB_Name="mysql"
    fi
}

cd /home/pvpgn

# IP=$(ip a | grep -v 'inet6' | grep 'inet' | grep -v 'host lo' | cut -d'/' -f1 | grep -o '[0-9].*')

# docker ps
# docker stop pvpgn
# docker ps
# docker rm pvpgn
# docker ps -a
# # 后台创建
# docker run -dt --name pvpgn -p 198.15.136.155:6112:6112 -p 198.15.136.155:6112:6112/udp -p 198.15.136.155:6113:6113 -p 198.15.136.155:4000:4000 wqmeng:pvpgn /bin/bash
# # 登录容器修改配置
# docker exec -it pvpgn /bin/bash
# ps aux
# IP 准备
# ip a

ACT=$1
IP=$(ip a | grep -v 'inet6' | grep 'inet' | grep -v 'host lo' | cut -d'/' -f1 | grep -o '[0-9].*')

TASK=$2

EXTIP=$3
#
AAAA=${IP} # pvpgn binding at 6112,  one pvpgn can serve different d2cs.
BBBB=${IP}    # d2cs  binding at 6113 different version of d2 could use different port to serve. Such as 1.09 use  6109, 
REALM_NAME=$4
D2CS_PORT=$5    # d2cs  binding at 6113 different version of d2 could use different port to serve. 
                  # Such as 1.09 use  6109, 113 use 6113,  110 use 6210,  114 use 6214
CCCC=${IP}    # d2dbs binding at 6114
D2DBS_PORT=6114    # d2cs  binding at 6113 different version of d2 could use different port to serve. Such as 1.09 use  6109, 
DDDD=${IP}    # d2gs  binding at 4000, this port can not change.
VERSION=$6


echo '------'
echo 'IP:          '$IP
echo 'PUB IP:      '$EXTIP
echo 'a.a.a.a:     '$AAAA
echo 'b.b.b.b:     '$BBBB
echo 'd2cs port:   '$D2CS_PORT
echo 'c.c.c.c:     '$CCCC
echo 'd2dbs port:  '$D2DBS_PORT
echo 'd.d.d.d:     '$DDDD
echo '------'
#docker 第一个容器里面: 内网IP是  10.88.0.19, 对应的外网IP 198.15.136.155
#启动服务
#PvPGNConsole.exe 分配外网IP 198.15.136.155 (a.a.a.a): 6112

# 1 realm.conf
#"D2_113c"                 "PvPGN 1.13c Realm"            10.88.0.19:6113

#sed -i '/^"D2_113c"/d' /home/pvpgn/conf/realm.conf
#sed -i '$a "D2_113c"                 "PvPGN 1.13c Realm"            '${BBBB}':'${D2CS_PORT} /home/pvpgn/conf/realm.conf

#Setup_realm '/home/pvpgn' 'D2_113c' 'PvPGN 1.13c Realm' ${BBBB} ${D2CS_PORT}

# 检查结果
#sed -n '/^"D2_113c"/p' /home/pvpgn/conf/realm.conf
#sed -n '/6113/p' /home/pvpgn/conf/realm.conf

# 2 bnetd.conf
# 修改storage

#sed -i 's/^# storage_path = file:mode=plain/storage_path = file:mode=plain/' /home/pvpgn/conf/bnetd.conf
#sed -i 's/^storage_path = sql/# storage_path = sql/' /home/pvpgn/conf/bnetd.conf

#Setup_bnetd '/home/pvpgn'

# 检查结果
#sed -n '/^storage_path/p' /home/pvpgn/conf/bnetd.conf

#sed -i 's/^servaddrs =/# storage_path = sql/' /home/pvpgn/conf/bnetd.conf
#sed -i '/^servaddrs =/c servaddrs = "'${IP}':6112"' /home/pvpgn/conf/bnetd.conf
#sed -n '/^servaddrs/p' /home/pvpgn/conf/bnetd.conf

## -----
#D2CSConsole.exe  分配内网IP 10.88.0.19 (b.b.b.b) : 6113
# 3 d2cs.conf

#sed -i '/^realmname/c realmname               =       "D2_113c"' /home/pvpgn/conf/d2cs.conf

#sed -i '/^servaddrs/c servaddrs            =       '${IP}':6113' /home/pvpgn/conf/d2cs.conf
#sed -i '/^servaddrs/c servaddrs            =       0.0.0.0:'${D2CS_PORT} /home/pvpgn/conf/d2cs.conf

#gameservlist            =       198.15.136.155 (d.d.d.d), 198.15.136.156 (d.d.d.d)-2

#sed -i '/^gameservlist/c gameservlist            =       198.15.136.155,198.15.136.156' /home/pvpgn/conf/d2cs.conf
#sed -i '/^gameservlist/c gameservlist            =       '${DDDD} /home/pvpgn/conf/d2cs.conf
#sed -n '/^gameservlist/p' /home/pvpgn/conf/d2cs.conf

#sed -i '/^servaddrs/c servaddrs            =       '${IP}':6113' /home/pvpgn/conf/d2cs.conf
#sed -n '/^gameservlist/p' /home/pvpgn/conf/d2cs.conf

#bnetdaddr               =       198.15.136.155 (a.a.a.a):6112
#sed -i '/^bnetdaddr/c bnetdaddr               =       198.15.136.155:6112' /home/pvpgn/conf/d2cs.conf
#sed -i '/^bnetdaddr/c bnetdaddr               =       '${AAAA}':6112' /home/pvpgn/conf/d2cs.conf
#sed -n '/^bnetdaddr/p' /home/pvpgn/conf/d2cs.conf

#Setup_d2cs '/home/pvpgn' 'D2_113c' ${DDDD} ${D2CS_PORT} ${AAAA}

## -----
# D2GS.exe         分配内网IP 10.88.0.19 : 4000   映射 外网 198.15.136.155 (d.d.d.d) : 4000
#d2gs.reg
#"D2CSIP"="198.15.136.155"         10.88.0.19 (b.b.b.b) ?
#"D2DBSIP"="198.15.136.155"        10.88.0.19 (c.c.c.c) ?

#cd /home/d2gs/

#sed -i '/^"D2CSIP"/c "D2CSIP"="'${BBBB}'"' /home/d2gs/d2gs.reg
#sed -i '/^"D2DBSIP"/c "D2DBSIP"="'${CCCC}'"' /home/d2gs/d2gs.reg
# [HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\D2Server\D2GS]  // 64bit Win
# [HKEY_LOCAL_MACHINE\SOFTWARE\D2Server\D2GS] // 32bit Win
#\cp /home/d2gs/d2gs.reg /home/d2gs/d2gs_x64.reg

#sed -i 's/Wow6432Node\\//' /home/d2gs/d2gs.reg
#cat /home/d2gs/d2gs.reg

#wine regedit /home/d2gs/d2gs.reg

#Setup_d2gs '/home/d2gs' ${BBBB} ${CCCC} '9e75a42100e1b9e0b5d3873045084fae699adcb0'

## -----
#D2DBSConsole.exe          分配内网IP 10.88.0.19 (c.c.c.c) : 6114
# 4 d2dbs.conf
#gameservlist            =       198.15.136.155 (d.d.d.d), 198.15.136.156 (d.d.d.d)-2


#sed -i '/^servaddrs/c servaddrs            =       '${IP}':6114' /home/pvpgn/conf/d2dbs.conf

#sed -i '/^gameservlist/c gameservlist            =       198.15.136.155,198.15.136.156' /home/pvpgn/conf/d2dbs.conf
#sed -i '/^gameservlist/c gameservlist            =       '${DDDD} /home/pvpgn/conf/d2dbs.conf
#sed -n '/^gameservlist/p' /home/pvpgn/conf/d2dbs.conf

#Setup_d2dbs '/home/pvpgn' ${DDDD}

##------
# 5 address_translation.conf

#sed -i '/^'${IP}'/d' /home/pvpgn/conf/address_translation.conf
#sed -i '/1.2.3.4:6113/a '${IP}':'${D2CS_PORT}'   '${EXTIP}':'${D2CS_PORT}'          10.88.0.0/16         ANY' /home/pvpgn/conf/address_translation.conf

#sed -i '/1.2.3.4:4000/a '${IP}':4000   '${EXTIP}':4000          10.88.0.0/16         ANY' /home/pvpgn/conf/address_translation.conf
#LOCAL IP ADDRESS:6113    EXTERNAL IP ADDRESS:6113        192.168.1.0/24            ANY

#Setup_address_translation '/home/pvpgn' ${BBBB} ${EXTIP} ${D2CS_PORT} ${DDDD} ${EXTIP}


# 重启所有服务
# pkill -f 'PvPGNConsole'
# pkill -f 'D2CSConsole'
# pkill -f 'D2DBSConsole'
# pkill -f 'D2GS'

# cd /home/pvpgn
# wine PvPGNConsole.exe >& /dev/null &
# wine D2CSConsole.exe >& /dev/null &
# wine D2DBSConsole.exe >& /dev/null &

# cd /home/d2gs
# wine D2GS.exe >& /dev/null &

# Setup_Pvpgn

# Start_Pvpgn '/home/pvpgn'
# Start_d2cs '/home/pvpgn'
# Start_d2dbs '/home/pvpgn'
# Start_d2gs '/home/d2gs'

# ps aux

# 查看日志
# tail /home/pvpgn/var/bnetd.log -n 30
# tail /home/pvpgn/var/d2cs.log -n 30
# tail /home/pvpgn/var/d2dbs.log -n 30

# tail /home/d2gs/d2gs.log -n 30

case "${ACT}" in
    setup)
        # Dispaly_Selection
        case "${TASK}" in
            pvpgn)
                Setup_Pvpgn
            ;;
            d2cs)
                Setup_d2cs '/home/pvpgn'_$REALM_NAME $REALM_NAME ${DDDD} ${D2CS_PORT} ${AAAA}
            ;;
            d2dbs)
                Setup_d2cs '/home/pvpgn' $REALM_NAME ${DDDD} ${D2CS_PORT} ${AAAA}
            ;;
            # d2cs)
            #     Setup_D2cs
            # ;;
        esac
        # LNMP_Stack 2>&1 | tee /root/pvpgn-install.log
        ;;
    start|restart)
        # Dispaly_Selection
        Start_Pvpgn '/home/pvpgn'
        Start_d2cs '/home/pvpgn'
        Start_d2dbs '/home/pvpgn'
        # Start_d2gs '/home/d2gs' 
        # Setup_Pvpgn
        # LNMP_Stack 2>&1 | tee /root/pvpgn-install.log
        ;;
    stop)
        pkill -f 'PvPGNConsole'
        pkill -f 'D2CSConsole'
        pkill -f 'D2DBSConsole'
        pkill -f 'D2GS'
        ;;
    realm)
        # Dispaly_Selection
        echo 'realm in config_pvpgn.sh'
        REALM_NAME=$2
        REALM_PORT=$3
        VERSION=$4
        EXTIP=$5
        echo 'realm '$REALM_NAME' '$REALM_PORT' '$AAAA
        Add_realm $REALM_NAME $REALM_PORT $AAAA
        # Add_d2gs $REALM_NAME $BBBB $CCCC $DDDD $EXTIP
        # LAMP_Stack 2>&1 | tee /root/add-d2gs.log
        ;;
    d2gs)
        # Dispaly_Selection
        REALM_NAME=$2
        # Add_realm
        Add_d2gs $REALM_NAME $BBBB $CCCC $DDDD $EXTIP
        # LAMP_Stack 2>&1 | tee /root/add-d2gs.log
        ;;
    delete)
        # Dispaly_Selection
        Echo_Red "Usage: $0 {pvpgn|realm|d2gs}"
        echo "Storage: plain cdb mysql mariaDB pgsql sqlite3"
        echo "Diablo2: 1.13d 1.13c 1.11b 1.09d"
        Echo_Red "$0 pvpgn plain realm_name 1.13c"
        Echo_Red "$0 realm realm_name 1.11b"
        Echo_Red "$0 d2gs exist_realm # will detect a new output IP for new d2gs"
        ;;
    *)
        # Dispaly_Selection
        echo "Not supported action"
        # Echo_Red "Usage: $0 {pvpgn|realm|d2gs}"
        ;;
esac
