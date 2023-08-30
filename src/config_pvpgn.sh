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

ReadYaml() {
    # readarray ARRREALMS < <(yq e -o=j -I=0 '.pvpgn.realms[] | select(.cid == "'$HOSTNAME'")' /home/pvpgn/pvpgn.yaml)
    readarray ARRREALMS < <(yq e -o=j -I=0 '.pvpgn.realms[]' /home/pvpgn/pvpgn.yaml)
    readarray ARRD2GSS < <(yq e -o=j -I=0 '.pvpgn.realms[].d2gs[]' /home/pvpgn/pvpgn.yaml)
    PVPGN_PATH=/home/pvpgn_$(yq e '.pvpgn.path' /home/pvpgn/pvpgn.yaml)/
    # REALM_PATH=/home/pvpgn_$(yq e '.pvpgn.realms[] | select(.name == "'$REALM_NAME'").path' /home/pvpgn/pvpgn.yaml)/
    # D2GS_PATH=/home/pvpgn_$(yq e '.pvpgn.d2gs[] | select(.cid == "'$HOSTNAME'").path' /home/pvpgn/pvpgn.yaml)
    D2GS_PATH=/home/d2gs/

    # for realm in "${ARRREALMS[@]}"; do
    #     # identity mapping is a yaml snippet representing a single entry
    #     CID=$(echo "$realm" | yq e '.cid' -)
    #     echo "CID: $CID"
    #     port=$(echo "$realm" | yq e '.port' -)
    #     echo "PORT: $port"
    # done
}

Setup_bnetd() {
#   if [ "$1" == "" ]; then
#     CONF_PATH=/home/pvpgn
#   else
#     CONF_PATH=$1
#   fi
    echo "Setup_bnetd PVPGN_PATH: $PVPGN_PATH"
    sed -i 's/^# storage_path = file:mode=plain/storage_path = file:mode=plain/' ${PVPGN_PATH}conf/bnetd.conf
    sed -i 's/^storage_path = sql/# storage_path = sql/' ${PVPGN_PATH}conf/bnetd.conf 
}

Setup_realm() {
#   if [ "$1" == "" ]; then
#     CONF_PATH=/home/pvpgn
#   else
#     CONF_PATH=$1
#   fi
    REALM_NAME=$2
    REALM_DES=$3
    REALM_IP=$4
    REALM_PORT=$5

    for realm in "${ARRREALMS[@]}"; do
        # identity mapping is a yaml snippet representing a single entry
        CID=$(echo "$realm" | yq e '.cid' -)
        echo "CID: $CID"
        D2CS_PORT=$(echo "$realm" | yq e '.port' -)
        echo "Setup_realm PORT: $D2CS_PORT"
        REALM_NAME=$(echo "$realm" | yq e '.name' -)
        echo "REALM_NAME: $REALM_NAME"
        REALM_DES=$(echo "$realm" | yq e '.desc' -)
        # path=$(echo "$realm" | yq e '.path' -)
        # echo "PORT: $path"
        REALM_PATH=/home/pvpgn_$(echo "$realm" | yq e '.path' -)/
        echo "Setup_d2dbs REALM_PATH: $REALM_PATH"
        D2GS_IP=$(yq e '.pvpgn.d2gs[].realms[] | select(.name == "'$REALM_NAME'").d2csIP' /home/pvpgn/pvpgn.yaml)

        echo "Setup_realm PVPGN_PATH: $REALM_PATH"

        cd /home
        wget -t 3 https://raw.githubusercontent.com/wqmeng/pvpgner/main/pvpgn/pvpgn1.99.8.0.0-rc1-PRO.7z
        7za x -y pvpgn1.99.8.0.0-rc1-PRO.7z >/dev/null 2>&1
        mv -n /home/pvpgn1.99.8.0.0-rc1-PRO/* $REALM_PATH/
        rm pvpgn1.99.8.0.0-rc1-PRO* -rf

        sed -i '/^"'${REALM_NAME}'"/d' ${PVPGN_PATH}conf/realm.conf
        sed -i '$a "'${REALM_NAME}'"                 "'"${REALM_DES}"'"            '${BBBB}':'${D2CS_PORT} ${PVPGN_PATH}conf/realm.conf
    done

    # echo "Setup_realm PVPGN_PATH: $PVPGN_PATH"

    # cd /home
    # wget https://github.com/wqmeng/pvpgner/raw/main/pvpgn/pvpgn1.99.8.0.0-rc1-PRO.7z
    # 7za x -y pvpgn1.99.8.0.0-rc1-PRO.7z >/dev/null 2>&1
    # mv -n /home/pvpgn1.99.8.0.0-rc1-PRO/* $PVPGN_PATH/
    # rm pvpgn1.99.8.0.0-rc1-PRO* -rf

    # sed -i '/^"'${REALM_NAME}'"/d' ${PVPGN_PATH}conf/realm.conf
    # sed -i '$a "'${REALM_NAME}'"                 "'"${REALM_DES}"'"            '${REALM_IP}':'${REALM_PORT} ${PVPGN_PATH}conf/realm.conf
}

Setup_d2cs() {
    # if [ "$1" == "" ]; then
    #     CONF_PATH=/home/pvpgn
    # else
    #     CONF_PATH=$1
    # fi
    REALM_NAME=$2
    D2GS_IP=$3
    D2CS_PORT=$4
    BNETD_IP=$5
    GSLIST=""
    echo "--------------------"
    echo "Setup_d2cs PVPGN_PATH: $PVPGN_PATH"
    for realm in "${ARRREALMS[@]}"; do
        # identity mapping is a yaml snippet representing a single entry
        CID=$(echo "$realm" | yq e '.cid' -)
        echo "CID: $CID"
        D2CS_PORT=$(echo "$realm" | yq e '.port' -)
        D2DBS_PORT=$(($D2CS_PORT + 1))
        echo "Setup_d2cs PORT: $D2CS_PORT"
        REALM_NAME=$(echo "$realm" | yq e '.name' -)
        echo "name: $REALM_NAME"
        # path=$(echo "$realm" | yq e '.path' -)
        # echo "PORT: $path"
        REALM_PATH=/home/pvpgn_$(echo "$realm" | yq e '.path' -)/
        echo "Setup_d2cs REALM_PATH: $REALM_PATH"
        D2GS_IP=$(echo "$realm" | yq e '.d2gs[].innerIP')
        echo $D2GS_IP
        GSLIST=$(echo $D2GS_IP | tr -s ' ' ',')
        sed -i '/^realmname/c realmname               =       "'${REALM_NAME}'"' ${REALM_PATH}conf/d2cs.conf
        #sed -i '/^servaddrs/c servaddrs            =       '${IP}':6113' /home/pvpgn/conf/d2cs.conf
        sed -i '/^servaddrs/c servaddrs            =       0.0.0.0:'${D2CS_PORT} ${REALM_PATH}conf/d2cs.conf
        #gameservlist            =       198.15.136.155 (d.d.d.d), 198.15.136.156 (d.d.d.d)-2
        # GSLIST="$GSLIST""$D2GS_IP"','
        #sed -i '/^gameservlist/c gameservlist            =       198.15.136.155,198.15.136.156' ${CONF_PATH}conf/d2cs.conf
        # D2GSIPS=$(sed -n '/^gameservlist/p' ${REALM_PATH}conf/d2cs.conf | grep -Po '=\s*.*' | grep -Po '(25[0-5]|2[0-4][0-9]|[0-1]{1}[0-9]{2}|[1-9]{1}[0-9]{1}|[1-9])\.(25[0-5]|2[0-4][0-9]|[0-1]{1}[0-9]{2}|[1-9]{1}[0-9]{1}|[1-9]|0)\.(25[0-5]|2[0-4][0-9]|[0-1]{1}[0-9]{2}|[1-9]{1}[0-9]{1}|[1-9]|0)\.(25[0-5]|2[0-4][0-9]|[0-1]{1}[0-9]{2}|[1-9]{1}[0-9]{1}|[0-9]).*')

        # if [ "${D2GSIPS}" != "" ]; then
        #     if [[ "${D2GSIPS}" != *"$D2GS_IP"* ]]; then
        #         D2GS_IP=${D2GSIPS}','${D2GS_IP}
        #     fi
        # fi

        # sed -i '/^gameservlist/c gameservlist            =       '${D2GS_IP} ${REALM_PATH}conf/d2cs.conf

        #sed -n '/^gameservlist/p' ${CONF_PATH}conf/d2cs.conf

        #sed -i '/^servaddrs/c servaddrs            =       '${IP}':6113' ${CONF_PATH}conf/d2cs.conf
        #sed -n '/^gameservlist/p' /home/pvpgn/conf/d2cs.conf

        #bnetdaddr               =       198.15.136.155 (a.a.a.a):6112
        #sed -i '/^bnetdaddr/c bnetdaddr               =       198.15.136.155:6112' /home/pvpgn/conf/d2cs.conf
        sed -i '/^bnetdaddr/c bnetdaddr               =       '${BNETD_IP}':6112' ${REALM_PATH}conf/d2cs.conf
        #sed -n '/^bnetdaddr/p' /home/pvpgn/conf/d2cs.conf
        sed -i '/^gameservlist/c gameservlist            =       '${GSLIST} ${REALM_PATH}conf/d2cs.conf
    done


    # readarray realms < <(yq e -o=j -I=0 '.pvpgn.realms[] | select(.cid == "'$HOSTNAME'")' /home/pvpgn/pvpgn.yaml)

    # for realm in "${realms[@]}"; do
    #     # identity mapping is a yaml snippet representing a single entry
    #     CID=$(echo "$realm" | yq e '.cid' -)
    #     # echo "CID: $CID"
    #     port=$(echo "$realm" | yq e '.port' -)
    #     # echo "PORT: $port"
    #     name=$(echo "$realm" | yq e '.name' -)
    #     name=$(echo "$realm" | yq e '.name' -)
    # done

    # echo "Setup_d2dbs REALM_PATH: $REALM_PATH"
    # sed -i '/^realmname/c realmname               =       "'${REALM_NAME}'"' ${REALM_PATH}conf/d2cs.conf

    # #sed -i '/^servaddrs/c servaddrs            =       '${IP}':6113' /home/pvpgn/conf/d2cs.conf
    # sed -i '/^servaddrs/c servaddrs            =       0.0.0.0:'${D2CS_PORT} ${REALM_PATH}conf/d2cs.conf

    # #gameservlist            =       198.15.136.155 (d.d.d.d), 198.15.136.156 (d.d.d.d)-2

    # #sed -i '/^gameservlist/c gameservlist            =       198.15.136.155,198.15.136.156' ${CONF_PATH}conf/d2cs.conf
    # D2GSIPS=$(sed -n '/^gameservlist/p' ${REALM_PATH}conf/d2cs.conf | grep -Po '=\s*.*' | grep -Po '(25[0-5]|2[0-4][0-9]|[0-1]{1}[0-9]{2}|[1-9]{1}[0-9]{1}|[1-9])\.(25[0-5]|2[0-4][0-9]|[0-1]{1}[0-9]{2}|[1-9]{1}[0-9]{1}|[1-9]|0)\.(25[0-5]|2[0-4][0-9]|[0-1]{1}[0-9]{2}|[1-9]{1}[0-9]{1}|[1-9]|0)\.(25[0-5]|2[0-4][0-9]|[0-1]{1}[0-9]{2}|[1-9]{1}[0-9]{1}|[0-9]).*')

    # if [ "${D2GSIPS}" != "" ]; then
    #     D2GS_IP=${D2GSIPS}','${D2GS_IP}
    # fi

    # sed -i '/^gameservlist/c gameservlist            =       '${D2GS_IP} ${REALM_PATH}conf/d2cs.conf

    # #sed -n '/^gameservlist/p' ${CONF_PATH}conf/d2cs.conf

    # #sed -i '/^servaddrs/c servaddrs            =       '${IP}':6113' ${CONF_PATH}conf/d2cs.conf
    # #sed -n '/^gameservlist/p' /home/pvpgn/conf/d2cs.conf

    # #bnetdaddr               =       198.15.136.155 (a.a.a.a):6112
    # #sed -i '/^bnetdaddr/c bnetdaddr               =       198.15.136.155:6112' /home/pvpgn/conf/d2cs.conf
    # sed -i '/^bnetdaddr/c bnetdaddr               =       '${BNETD_IP}':6112' ${REALM_PATH}conf/d2cs.conf
    # #sed -n '/^bnetdaddr/p' /home/pvpgn/conf/d2cs.conf
}

Setup_d2dbs() {
    # if [ "$1" == "" ]; then
    #     CONF_PATH=/home/pvpgn
    # else
    #     CONF_PATH=$1
    # fi

    for realm in "${ARRREALMS[@]}"; do
        REALM_NAME=$(echo "$realm" | yq e '.name' -)
        echo "name: $REALM_NAME"
        # path=$(echo "$realm" | yq e '.path' -)
        # echo "PORT: $path"
        REALM_PATH=/home/pvpgn_$(echo "$realm" | yq e '.path' -)/
        echo "Setup_d2cs REALM_PATH: $REALM_PATH"

        D2CS_PORT=$(echo "$realm" | yq e '.port' -)
        D2DBS_PORT=$(($D2CS_PORT + 1))

        D2GS_IP=$(echo "$realm" | yq e '.d2gs[].innerIP')
        echo $D2GS_IP
        GSLIST=$(echo $D2GS_IP | tr -s ' ' ',')
        sed -i '/^servaddrs/c servaddrs            =       0.0.0.0:'${D2DBS_PORT} ${REALM_PATH}conf/d2dbs.conf
        sed -i '/^gameservlist/c gameservlist            =       '${GSLIST} ${REALM_PATH}conf/d2dbs.conf
    done

    # GSLIST=""
    # for d2gs in "${ARRD2GSS[@]}"; do
    #     d2gstemp=$(echo $d2gs | yq e 'select(.d2dbsIP == "'$CCCC'") ')
    #     if [ "$d2gstemp" != "" ]; then
    #         D2DBS_IP=$(echo $d2gs | yq e '.innerIP')
    #         GSLIST="$GSLIST""$D2DBS_IP"','
    #     fi
    # done
    
    # sed -i '/^gameservlist/c gameservlist            =       '${GSLIST} ${PVPGN_PATH}conf/d2dbs.conf


    # D2GS_IP=$2

    # #sed -i '/^servaddrs/c servaddrs            =       '${IP}':6114' /home/pvpgn/conf/d2dbs.conf

    # #sed -i '/^gameservlist/c gameservlist            =       198.15.136.155,198.15.136.156' /home/pvpgn/conf/d2dbs.conf
    # echo "Setup_d2dbs PVPGN_PATH: $PVPGN_PATH"

    # D2GSIPS=$(sed -n '/^gameservlist/p' ${PVPGN_PATH}conf/d2dbs.conf | grep -Po '=\s*.*' | grep -Po '(25[0-5]|2[0-4][0-9]|[0-1]{1}[0-9]{2}|[1-9]{1}[0-9]{1}|[1-9])\.(25[0-5]|2[0-4][0-9]|[0-1]{1}[0-9]{2}|[1-9]{1}[0-9]{1}|[1-9]|0)\.(25[0-5]|2[0-4][0-9]|[0-1]{1}[0-9]{2}|[1-9]{1}[0-9]{1}|[1-9]|0)\.(25[0-5]|2[0-4][0-9]|[0-1]{1}[0-9]{2}|[1-9]{1}[0-9]{1}|[0-9]).*')

    # if [ "${D2GSIPS}" != "" ]; then
    #     D2GS_IP=${D2GSIPS}','${D2GS_IP}
    # fi

    # sed -i '/^gameservlist/c gameservlist            =       '${D2GS_IP} ${PVPGN_PATH}conf/d2dbs.conf
    #sed -n '/^gameservlist/p' /home/pvpgn/conf/d2dbs.conf
}

Setup_address_translation() {
    # if [ "$1" == "" ]; then
    #     CONF_PATH=/home/pvpgn
    # else
    #     CONF_PATH=$1
    # fi
    D2CS_IP_input=$2
    D2CS_IP_output=$3
    D2CS_PORT=$4
    D2GS_IP_input=$5
    D2GS_IP_output=$6

    D2CS_IP_output=$(yq e '.pvpgn.IP' /home/pvpgn/pvpgn.yaml)
    for realm in "${ARRREALMS[@]}"; do
        # identity mapping is a yaml snippet representing a single entry
        CID=$(echo "$realm" | yq e '.cid' -)
        echo "CID: $CID"
        D2CS_PORT=$(echo "$realm" | yq e '.port' -)
        echo "Setup_address_translation PORT: $D2CS_PORT"
        REALM_NAME=$(echo "$realm" | yq e '.name' -)
        REALM_PATH=/home/pvpgn_$(echo "$realm" | yq e '.path' -)/
        echo "Setup_address_translation REALM_NAME: $REALM_NAME"

        # sed -i '/^\d.*:'${D2CS_PORT}'/d' ${PVPGN_PATH}conf/address_translation.conf
        sed -i "/^[1-9]\+.*:${D2CS_PORT}/d" ${PVPGN_PATH}conf/address_translation.conf
        sed -i '/1.2.3.4:6113/a '${D2CS_IP_input}':'${D2CS_PORT}'   '${D2CS_IP_output}':'${D2CS_PORT}'          10.88.0.0/16         ANY' ${PVPGN_PATH}conf/address_translation.conf
        sed -i "/^[1-9]\+.*:${D2CS_PORT}/d" ${REALM_PATH}conf/address_translation.conf
        sed -i '/1.2.3.4:6113/a '${D2CS_IP_input}':'${D2CS_PORT}'   '${D2CS_IP_output}':'${D2CS_PORT}'          10.88.0.0/16         ANY' ${REALM_PATH}conf/address_translation.conf
    done

    for d2gs in "${ARRD2GSS[@]}"; do
        # d2gstemp=$(echo $d2gs | yq e 'select(.cid == "'$HOSTNAME'") ')
        # if [ "$d2gstemp" != "" ]; then
            D2GS_IP_input=$(echo "$d2gs" | yq e '.innerIP' -)
            D2GS_IP_output=$(echo "$d2gs" | yq e '.outIP' -)
        # fi

        REALM_PATH=/home/pvpgn_$(echo "$d2gs" | yq e '.path' -)/

        echo "Setup_address_translation  D2GS_IP_input: $D2GS_IP_input   D2GS_IP_output: $D2GS_IP_output"

        # sed -i '/'${D2GS_IP_output}:4000'/d' ${PVPGN_PATH}conf/address_translation.conf
        sed -i '/'${D2GS_IP_output}':4000/d' ${PVPGN_PATH}conf/address_translation.conf
        sed -i '/1.2.3.4:4000/a '${D2GS_IP_input}':4000   '${D2GS_IP_output}':4000          10.88.0.0/16         ANY' ${PVPGN_PATH}conf/address_translation.conf
        sed -i '/'${D2GS_IP_output}':4000/d' ${REALM_PATH}conf/address_translation.conf
        sed -i '/1.2.3.4:4000/a '${D2GS_IP_input}':4000   '${D2GS_IP_output}':4000          10.88.0.0/16         ANY' ${REALM_PATH}conf/address_translation.conf
    done

    # echo "Setup_address_translation PVPGN_PATH: $PVPGN_PATH"

    # sed -i '/^'${D2CS_IP_input}'/d' ${PVPGN_PATH}conf/address_translation.conf
    # sed -i '/1.2.3.4:6113/a '${D2CS_IP_input}':'${D2CS_PORT}'   '${D2CS_IP_output}':'${D2CS_PORT}'          10.88.0.0/16         ANY' ${PVPGN_PATH}conf/address_translation.conf

    # # sed -i '/^'${D2GS_IP_input}'/d' ${PVPGN_PATH}conf/address_translation.conf
    # sed -i '/1.2.3.4:4000/a '${D2GS_IP_input}':4000   '${D2GS_IP_output}':4000          10.88.0.0/16         ANY' ${PVPGN_PATH}conf/address_translation.conf
    # #LOCAL IP ADDRESS:6113    EXTERNAL IP ADDRESS:6113        192.168.1.0/24            ANY
}

Setup_d2gs() {
    # VERSION=$5
    # mkdir -p /home/d2gs
    # CONF_PATH=/home/d2gs
    D2GS_PATH=/home/d2gs/
    echo "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
    echo "Setup_d2gs   HOSTNAME:   $HOSTNAME"
    for realm in "${ARRREALMS[@]}"; do
        echo "realm: is =========================="
        echo $realm

        d2gs=$(echo $realm | yq e '.d2gs[] | select(.cid == "'$HOSTNAME'") ')

        if [ "$d2gs" != "" ]; then

            echo "find a d2gs: "      
            D2CS_IP=$(echo "$d2gs" | yq e '.d2csIP' -)
            D2DBS_IP=$(echo "$d2gs" | yq e '.d2dbsIP' -)
            D2GS_PASSWD=$(echo "$d2gs" | yq e '.AdminPwd' -)

            VERSION=$(echo "$realm" | yq e '.version' -)
            D2CS_PORT=$(echo "$realm" | yq e '.port' -)
            echo "Setup_d2gs D2CS_PORT Realm PORT: $D2CS_PORT"
            cd ${D2GS_PATH}    
            # wget -q http://10.0.0.10/docker/d2gs/D2GS_Base.7z
            # wget -q https://ia801809.us.archive.org/29/items/d2gs-base.-7z/D2GS_Base.7z
            wget -q https://github.com/wqmeng/pvpgner/raw/main/d2gs/D2GS_${VERSION}.7z

            # create all files soft link in lnsrc to lntest .
            # ln -s -t ./lntest ./lnsrc/*
            # 7za x -y D2GS_Base.7z >/dev/null 2>&1
            # mv D2GS_Base/* .
            # rm D2GS_Base -rf
            # rm D2GS_Base.7z -rf
            7za x -y D2GS_${VERSION}.7z >/dev/null 2>&1
            mv D2GS_${VERSION}/* .
            rm D2GS_${VERSION} -rf
            ln -s -t /home/d2gs/ /home/d2gs_base/*
            touch d2_${VERSION}

            # D2CS_IP=$1
            # D2CS_PORT=$2
            # D2DBS_IP=$3
            # D2GS_PASSWD=$4

            # REMLM_NAME=$(yq e '.pvpgn.d2gs[] | select(.innerIP == "'$DDDD'") | .realm[].name ' /home/pvpgn/pvpgn.yaml)

            sed -i '/^EnableWarden/c EnableWarden=0' ${D2GS_PATH}d2server.ini
            sed -i '/^EnableEthSocketBugFix/c EnableEthSocketBugFix=0' ${D2GS_PATH}d2server.ini
            sed -i '/^DisableBugMF/c DisableBugMF=0' ${D2GS_PATH}d2server.ini

            sed -i '/^"D2CSIP"/c "D2CSIP"="'${D2CS_IP}'"' ${D2GS_PATH}d2gs.reg

            if [ "$D2CS_PORT" != "6113" ]; then
                REALM_DSPORTX=$(echo "${D2CS_PORT}" | awk '{printf "%08x\n",$0}')
                REALM_DBSPORTX=$(echo "$((${D2CS_PORT} + 1))" | awk '{printf "%08x\n",$0}')
            else
                REALM_DSPORTX="000017e1"
                REALM_DBSPORTX="000017e2"
            fi

            sed -i '/^"D2CSPort"/c "D2CSPort"=dword:'${REALM_DSPORTX} ${D2GS_PATH}d2gs.reg
            sed -i '/^"D2DBSIP"/c "D2DBSIP"="'${D2DBS_IP}'"' ${D2GS_PATH}d2gs.reg
            sed -i '/^"D2DBSPort"/c "D2DBSPort"=dword:'${REALM_DBSPORTX} ${D2GS_PATH}d2gs.reg

            # 4096 MaxGames
            sed -i '/^"MaxGames"/c "MaxGames"=dword:00001000' ${D2GS_PATH}d2gs.reg
            # telnet 8888 password: abcd123
            sed -i '/^"AdminPassword"/c "AdminPassword"="'$D2GS_PASSWD'"' ${D2GS_PATH}d2gs.reg
            # [HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\D2Server\D2GS]  // 64bit Win
            # [HKEY_LOCAL_MACHINE\SOFTWARE\D2Server\D2GS] // 32bit Win
            \cp ${D2GS_PATH}d2gs.reg ${D2GS_PATH}d2gs_x64.reg

            sed -i 's/Wow6432Node\\//' ${D2GS_PATH}d2gs.reg
            #cat ${D2GS_PATH}d2gs.reg
            cd ${D2GS_PATH}
            wine regedit ${D2GS_PATH}d2gs.reg
        fi
    done
}

Setup_Pvpgn() {
    Setup_realm '/home/pvpgn' $REALM_NAME "$REALM_NAME for $VERSION" ${BBBB} ${D2CS_PORT}
    Setup_bnetd '/home/pvpgn'
    Setup_d2cs '/home/pvpgn' $REALM_NAME ${DDDD} ${D2CS_PORT} ${AAAA}
    Setup_d2gs ${BBBB} ${D2CS_PORT} ${CCCC} '9e75a42100e1b9e0b5d3873045084fae699adcb0' $VERSION
    Setup_d2dbs '/home/pvpgn' ${DDDD}
    Setup_address_translation '/home/pvpgn' ${BBBB} ${EXTIP} ${D2CS_PORT} ${DDDD} ${EXTIP}
    rm -rf /home/pvpgn/inner_ip
    touch /home/pvpgn/inner_ip
    echo ${BBBB} >> /home/pvpgn/inner_ip
}

Update_InnerIP() {
    # //
    OLDIP=$(cat /home/pvpgn/inner_ip)
    echo "Update_InnerIP PVPGN_PATH: $PVPGN_PATH"
    echo "Update_InnerIP D2GS_PATH: $D2GS_PATH"
    # sed -i 's/Wow6432Node\\//' ${CONF_PATH}/d2gs.reg
    # // OLDIP
    # // NEWIP
    echo "Update_InnerIP  OLDIP: $OLDIP  IP: $IP  PVPGN_PATH: $PVPGN_PATH  REALM_PATH: $REALM_PATH  D2GS_PATH: $D2GS_PATH"
    if [ "$IP" != "$OLDIP" ]; then
        sed -i 's/'$OLDIP'/'$IP'/' $PVPGN_PATH/conf/realm.conf
        sed -i 's/'$OLDIP'/'$IP'/' $PVPGN_PATH/conf/d2cs.conf
        sed -i 's/'$OLDIP'/'$IP'/' $PVPGN_PATH/conf/d2dbs.conf
        sed -i 's/'$OLDIP'/'$IP'/' $PVPGN_PATH/conf/address_translation.conf

        sed -i 's/'$OLDIP'/'$IP'/' $D2GS_PATH/d2gs.reg
        sed -i 's/'$OLDIP'/'$IP'/' $D2GS_PATH/d2gs_x64.reg

        rm -rf /home/pvpgn/inner_ip
        touch /home/pvpgn/inner_ip
        echo ${IP} >> /home/pvpgn/inner_ip    
    fi
    
}

Start_Pvpgn() {
    # if [ "$1" == "" ]; then
    #     CONF_PATH=/home/pvpgn
    # else
    #     CONF_PATH=$1
    # fi

    # Update_InnerIP

    pkill -f 'PvPGNConsole'

    cd ${PVPGN_PATH}
    echo "Start_Pvpgn PVPGN_PATH: $PVPGN_PATH"
    # wine PvPGNConsole.exe >& /dev/null &
    nohup bash -c "wine ${PVPGN_PATH}PvPGNConsole.exe &" </dev/null &>/dev/null &
    sleep 1
}

Start_d2cs() {
    # if [ "$1" == "" ]; then
    #     CONF_PATH=/home/pvpgn
    # else
    #     CONF_PATH=$1
    # fi

    for realm in "${ARRREALMS[@]}"; do
        # identity mapping is a yaml snippet representing a single entry
        CID=$(echo "$realm" | yq e '.cid' -)
        echo "Start_d2cs CID: $CID"
        # D2CS_PATH=$(echo "$realm" | yq e '.path' -)
        REALM_PATH=/home/pvpgn_$(echo "$realm" | yq e '.path' -)'/'
        # echo "Start_d2cs Realm PORT: $REALM_PATH"
        # REALM_NAME=$(echo "$realm" | yq e '.name' -)
        # echo "PORT: $name"

        echo "Start_d2cs REALM_PATH: $REALM_PATH"
        pkill -f $REALM_PATH'D2CSConsole'
        cd ${REALM_PATH}
        # wine D2CSConsole.exe >& /dev/null &
        nohup bash -c "wine ${REALM_PATH}D2CSConsole.exe &" </dev/null &>/dev/null &
        sleep 1

    done
}

Start_d2dbs() {
    # if [ "$1" == "" ]; then
    #     CONF_PATH=/home/pvpgn
    # else
    #     CONF_PATH=$1
    # fi
    # pkill -f 'D2DBSConsole'

    for realm in "${ARRREALMS[@]}"; do
        # identity mapping is a yaml snippet representing a single entry
        CID=$(echo "$realm" | yq e '.cid' -)
        echo "Start_d2dbs CID: $CID"
        # D2CS_PATH=$(echo "$realm" | yq e '.path' -)
        REALM_PATH=/home/pvpgn_$(echo "$realm" | yq e '.path' -)'/'
        # echo "Start_d2dbs Realm PORT: $REALM_PATH"
        # REALM_NAME=$(echo "$realm" | yq e '.name' -)
        # echo "PORT: $name"

        echo "Start_d2dbs REALM_PATH: $REALM_PATH"
        pkill -f $REALM_PATH'D2DBSConsole'
        cd ${REALM_PATH}
        # wine D2CSConsole.exe >& /dev/null &
        nohup bash -c "wine ${REALM_PATH}D2DBSConsole.exe &" </dev/null &>/dev/null &
        sleep 1
    done

    # echo "Start_d2dbs PVPGN_PATH: $PVPGN_PATH"
    # cd ${PVPGN_PATH}
    # # wine D2DBSConsole.exe >& /dev/null &
    # nohup bash -c "wine D2DBSConsole.exe &" </dev/null &>/dev/null &
    # sleep 1
}

Start_d2gs() {
    # if [ "$1" == "" ]; then
    #     CONF_PATH=/home/d2gs
    # else
    #     CONF_PATH=$1
    # fi
    pkill -f 'D2GS'

    cd ${D2GS_PATH}
    # wine D2GS.exe >& /dev/null &
    # nohup bash -c "wine D2GS.exe &" </dev/null &>/dev/null &
    echo ${D2GS_PATH}
    # wine D2GS.exe
    # nohup bash -c "wine D2GS.exe >& /dev/null &" </dev/null &>/dev/null &
    # wine D2GS.exe 2>&1 | tee /home/output
    # nohup bash '(wine D2GS.exe) |& tee out.log'
    nohup bash -c "wine D2GS.exe &" </dev/null &>/dev/null &
    sleep 3
}

Add_realm() {
    # if [ "$1" == "" ]; then
    #     CONF_PATH=/home/pvpgn_$1
    # else
    #     CONF_PATH=$1
    # fi
    
    REALM_NAME=$1
    echo 'Add a new realm: '${REALM_NAME}
    echo "Add_realm REALM_PATH: $REALM_PATH"

    # CONF_PATH=/home/pvpgn_${REALM_NAME}

    # rm -rf ${REALM_PATH}
    # mkdir -p ${REALM_PATH}

    # NEW_REAL_IP=$2
    REALM_PORT=$2
    BNETD_IP=$3
    VERSIONP=$4

    Setup_realm ${REALM_PATH} ${REALM_NAME} "$REALM_NAME for $VERSION" ${BBBB} ${REALM_PORT}
    #Setup_bnetd ${CONF_PATH}
    # Setup_d2cs ${CONF_PATH} ${REALM_NAME} ${BBBB} ${REALM_PORT} ${BNETD_IP}
    # Setup_d2dbs '/home/pvpgn' ${DDDD}

    # d2gs can not create in the same pvpgn docker container, as it already has one d2gs takes the port 4000.
    # Setup_d2gs ${NEW_REALM_IP} ${CCCC} '9e75a42100e1b9e0b5d3873045084fae699adcb0' $VERSION

    # When we add a new realm, we should create a new gameserver to it.

    Start_Pvpgn '/home/pvpgn'
    # Start_d2cs '/home/pvpgn'
    Start_d2cs ${REALM_PATH}
    Start_d2dbs '/home/pvpgn'
    Start_d2gs '/home/d2gs'
    sleep 1
}

Add_d2gs() {
    # REALM_NAME=$1
    # d2cs ip
    BBBB=$1
    D2CS_PORT=$2
    # d2dbs ip
    CCCC=$3
    # d2gs input ip
    # DDDD=$3
    # d2gs output
    VERSION=$4

    Setup_d2gs ${BBBB} ${D2CS_PORT} ${CCCC} '9e75a42100e1b9e0b5d3873045084fae699adcb0' $VERSION
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


# wget -q https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O /usr/bin/yq
# chmod +x /usr/bin/yq
# ln -s /usr/bin/yq /usr/local/bin/yq

ReadYaml

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
AAAA=${IP}          # pvpgn binding at 6112,  one pvpgn can serve different d2cs.
BBBB=${IP}          # d2cs  binding at 6113 different version of d2 could use different port to serve. Such as 1.09 use  6109, 
REALM_NAME=$4
D2CS_PORT=$5        # d2cs  binding at 6113 different version of d2 could use different port to serve. 
                    # Such as 1.09 use  6109, 113 use 6113,  110 use 6210,  114 use 6214
CCCC=${IP}          # d2dbs binding at 6114
D2DBS_PORT=6114     # d2cs  binding at 6113 different version of d2 could use different port to serve. Such as 1.09 use  6109, 
DDDD=${IP}          # d2gs  binding at 4000, this port can not change.
# VERSION=$6

# REALM_PATH=/home/pvpgn_$(yq e '.pvpgn.realms[] | select(.cid == "'$HOSTNAME'").path' /home/pvpgn/pvpgn.yaml)
# PVPGN_PATH=/home/pvpgn_$(yq e '.pvpgn.path' /home/pvpgn/pvpgn.yaml)/
# REALM_PATH=/home/pvpgn_$(yq e '.pvpgn.realms[] | select(.name == "'$REALM_NAME'").path' /home/pvpgn/pvpgn.yaml)/
# # D2GS_PATH=/home/pvpgn_$(yq e '.pvpgn.d2gs[] | select(.cid == "'$HOSTNAME'").path' /home/pvpgn/pvpgn.yaml)
# D2GS_PATH=/home/d2gs/

echo '------'
echo 'IP:          '$IP
echo 'PUB IP:      '$EXTIP
echo 'a.a.a.a:     '$AAAA
echo 'b.b.b.b:     '$BBBB
echo 'd2cs port:   '$D2CS_PORT
echo 'c.c.c.c:     '$CCCC
echo 'd2dbs port:  '$D2DBS_PORT
echo 'd.d.d.d:     '$DDDD
echo 'PVPGN_PATH:     '$PVPGN_PATH
echo 'REALM_PATH:     '$REALM_PATH
echo 'D2GS_PATH:     '$D2GS_PATH
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

#Setup_d2gs ${BBBB} ${D2CS_PORT} ${CCCC} '9e75a42100e1b9e0b5d3873045084fae699adcb0' $VERSION

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
                VERSION=$6
                Setup_Pvpgn
            ;;
            d2cs)
                DDDD=$3
                Setup_d2cs '/home/pvpgn'_$REALM_NAME $REALM_NAME ${DDDD} ${D2CS_PORT} ${AAAA}
            ;;
            d2dbs)
                DDDD=$3
                Setup_d2dbs '/home/pvpgn' $REALM_NAME ${DDDD} ${D2CS_PORT} ${AAAA}
            ;;
            address_translation)
                EXTIP=$3
                Setup_address_translation '/home/pvpgn' ${BBBB} ${EXTIP} ${D2CS_PORT} ${DDDD} ${EXTIP}
                # Setup_address_translation '/home/pvpgn' ${BBBB} ${EXTIP} ${D2CS_PORT} ${DDDD} ${EXTIP}
            ;;
            d2gs)
                DDDD=$3
                echo "Act setup, Task d2gs oooooooooooooooooooooooooooo "
                Setup_d2gs '/home/pvpgn'_$REALM_NAME $REALM_NAME ${DDDD} ${D2CS_PORT} ${AAAA}
            ;;
            # d2cs)
            #     Setup_D2cs
            # ;;
        esac
        # LNMP_Stack 2>&1 | tee /root/pvpgn-install.log
        ;;
    start|restart)
        # Dispaly_Selection
        case "${TASK}" in
            pvpgn)
                REALM_NAME=$3
                REALM_PATH=/home/pvpgn_$(yq e '.pvpgn.realms[] | select(.name == "'$REALM_NAME'").path' /home/pvpgn/pvpgn.yaml)/
                Start_Pvpgn '/home/pvpgn'
            ;;
            d2cs)
                if [ "$3" = "" ]; then
                    Start_d2cs '/home/pvpgn'
                else
                    REALM_NAME=$3
                    REALM_PATH=/home/pvpgn_$(yq e '.pvpgn.realms[] | select(.name == "'$REALM_NAME'").path' /home/pvpgn/pvpgn.yaml)/
                    Start_d2cs '/home/pvpgn_'$REALM_NAME
                fi
            ;;
            d2dbs)
                Start_d2dbs '/home/pvpgn'
            ;;
            d2gs)
                Start_d2gs '/home/d2gs'
            ;;
            *)
                # Dispaly_Selection
                REALM_NAME=$2
                REALM_PATH=/home/pvpgn_$(yq e '.pvpgn.realms[] | select(.name == "'$REALM_NAME'").path' /home/pvpgn/pvpgn.yaml)/
                echo "Start \* REALM_NAME: $REALM_NAME  REALM_PATH: $REALM_PATH"
                Start_Pvpgn '/home/pvpgn'
                Start_d2cs '/home/pvpgn'
                Start_d2dbs '/home/pvpgn'
                Start_d2gs '/home/d2gs'
                # Echo_Red "Usage: $0 {pvpgn|realm|d2gs}"
                ;;
        esac
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
        REALM_PATH=/home/pvpgn_$(yq e '.pvpgn.realms[] | select(.name == "'$REALM_NAME'").path' /home/pvpgn/pvpgn.yaml)
        Add_realm $REALM_NAME $REALM_PORT $AAAA $VERSION
        # Add_d2gs $BBBB $CCCC $VERSION
        # LAMP_Stack 2>&1 | tee /root/add-d2gs.log
        ;;
    d2gs)
        # Dispaly_Selection
        # REALM_NAME=$2
        BBBB=$2
        REALM_PORT=$3
        CCCC=$4
        # DDDD=$5
        # EXTIP=$6
        VERSION=$5
        #  d2gs $REALM_NAME $BBBB $CCCC $DDDD $EXTIP $D2Select
        # Add_realm
        REALM_PATH=/home/pvpgn_$(yq e '.pvpgn.realms[] | select(.name == "'$REALM_NAME'").path' /home/pvpgn/pvpgn.yaml)
        Add_d2gs $BBBB $REALM_PORT $CCCC $VERSION
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
