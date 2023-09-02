#!/bin/sh
# https://forums.pvpgn.pro/viewtopic.php?id=2045
# docker prepare
ReadYaml() {
    PVPGN_YAML=/home/pvpgn/pvpgn.yaml
    readarray ARRREALMS < <(yq e -o=j -I=0 '.pvpgn.realms[]' $PVPGN_YAML)
    readarray ARRD2GSS < <(yq e -o=j -I=0 '.pvpgn.realms[].d2gs[]' $PVPGN_YAML)
    PVPGN_PATH=/home/pvpgn_$(yq e '.pvpgn.path' $PVPGN_YAML)/
    D2GS_PATH=/home/d2gs/
    BNETD_IP=$(yq e '.pvpgn.innerIP' $PVPGN_YAML)
}

Setup_bnetd() {
    CID=$(yq e '.pvpgn.cid' $PVPGN_YAML)
    if [ "$CID" = "$HOSTNAME" ]; then
        sed -i 's/^# storage_path = file:mode=plain/storage_path = file:mode=plain/' ${PVPGN_PATH}conf/bnetd.conf
        sed -i 's/^storage_path = sql/# storage_path = sql/' ${PVPGN_PATH}conf/bnetd.conf 
    fi
}

Setup_realm() {
    for realm in "${ARRREALMS[@]}"; do
        D2CS_PORT=$(echo "$realm" | yq e '.port' -)
        REALM_NAME=$(echo "$realm" | yq e '.name' -)
        REALM_DES=$(echo "$realm" | yq e '.desc' -)
        REALM_PATH=/home/pvpgn_$(echo "$realm" | yq e '.path' -)/
        D2VERSION=$(echo "$realm" | yq e '.version' -)
        cd /home
        if [ "$D2VERSION" = "1.13d_VIP" ]; then
            wget -q -t3 https://raw.githubusercontent.com/wqmeng/pvpgner/main/pvpgn/pvpgn1.99.8.0.0-rc1-PRO_VIP.7z
            7za x -y pvpgn1.99.8.0.0-rc1-PRO_VIP.7z >/dev/null 2>&1
            mv -n /home/pvpgn1.99.8.0.0-rc1-PRO_VIP/* $REALM_PATH/
            mv -n /home/pvpgn1.99.8.0.0-rc1-PRO_VIP/conf/* $REALM_PATH/conf/
            mv -n /home/pvpgn1.99.8.0.0-rc1-PRO_VIP/var/* $REALM_PATH/var/
        else
            wget -q -t3 https://raw.githubusercontent.com/wqmeng/pvpgner/main/pvpgn/pvpgn1.99.8.0.0-rc1-PRO.7z
            7za x -y pvpgn1.99.8.0.0-rc1-PRO.7z >/dev/null 2>&1
            mv -n /home/pvpgn1.99.8.0.0-rc1-PRO/* $REALM_PATH/
            mv -n /home/pvpgn1.99.8.0.0-rc1-PRO/conf/* $REALM_PATH/conf/
            mv -n /home/pvpgn1.99.8.0.0-rc1-PRO/var/* $REALM_PATH/var/
        fi
        rm pvpgn1.99.8.0.0-rc1-PRO* -rf

        sed -i '/^"'${REALM_NAME}'"/d' ${PVPGN_PATH}conf/realm.conf
        sed -i '$a "'${REALM_NAME}'"                 "'"${REALM_DES}"'"            '${BBBB}':'${D2CS_PORT} ${PVPGN_PATH}conf/realm.conf
    done
}

Setup_d2cs() {
    for realm in "${ARRREALMS[@]}"; do
        D2CS_PORT=$(echo "$realm" | yq e '.port' -)
        REALM_NAME=$(echo "$realm" | yq e '.name' -)
        REALM_PATH=/home/pvpgn_$(echo "$realm" | yq e '.path' -)/
        D2GS_IP=$(echo "$realm" | yq e '.d2gs[].innerIP')
        GSLIST=$(echo $D2GS_IP | tr -s ' ' ',')
        D2VERSION=$(echo "$realm" | yq e '.version' -)
        if [ "$D2VERSION" = "1.13d_VIP" ]; then
            sed -i '/^realmname/c realmname               =       "'${REALM_NAME}'"' ${REALM_PATH}conf/d2cs_VIP.conf
            sed -i '/^servaddrs/c servaddrs            =       0.0.0.0:'${D2CS_PORT} ${REALM_PATH}conf/d2cs_VIP.conf
            sed -i '/^bnetdaddr/c bnetdaddr               =       '${BNETD_IP}':6112' ${REALM_PATH}conf/d2cs_VIP.conf
            sed -i '/^gameservlist/c gameservlist            =       '${GSLIST} ${REALM_PATH}conf/d2cs_VIP.conf
        else
            sed -i '/^realmname/c realmname               =       "'${REALM_NAME}'"' ${REALM_PATH}conf/d2cs.conf
            sed -i '/^servaddrs/c servaddrs            =       0.0.0.0:'${D2CS_PORT} ${REALM_PATH}conf/d2cs.conf
            sed -i '/^bnetdaddr/c bnetdaddr               =       '${BNETD_IP}':6112' ${REALM_PATH}conf/d2cs.conf
            sed -i '/^gameservlist/c gameservlist            =       '${GSLIST} ${REALM_PATH}conf/d2cs.conf
        fi
    done
}

Setup_d2dbs() {
    for realm in "${ARRREALMS[@]}"; do
        REALM_PATH=/home/pvpgn_$(echo "$realm" | yq e '.path' -)/
        D2CS_PORT=$(echo "$realm" | yq e '.port' -)
        D2DBS_PORT=$(($D2CS_PORT + 1))
        D2GS_IP=$(echo "$realm" | yq e '.d2gs[].innerIP')
        GSLIST=$(echo $D2GS_IP | tr -s ' ' ',')
        sed -i '/^servaddrs/c servaddrs            =       0.0.0.0:'${D2DBS_PORT} ${REALM_PATH}conf/d2dbs.conf
        sed -i '/^gameservlist/c gameservlist            =       '${GSLIST} ${REALM_PATH}conf/d2dbs.conf
    done
}

Setup_address_translation() {
    D2CS_IP_input=$(yq e '.pvpgn.innerIP' $PVPGN_YAML)
    D2CS_IP_output=$(yq e '.pvpgn.IP' $PVPGN_YAML)
    for realm in "${ARRREALMS[@]}"; do
        D2CS_PORT=$(echo "$realm" | yq e '.port' -)
        REALM_NAME=$(echo "$realm" | yq e '.name' -)
        REALM_PATH=/home/pvpgn_$(echo "$realm" | yq e '.path' -)/
        sed -i "/^[1-9]\+.*:${D2CS_PORT}/d" ${PVPGN_PATH}conf/address_translation.conf
        sed -i '/1.2.3.4:6113/a '${D2CS_IP_input}':'${D2CS_PORT}'   '${D2CS_IP_output}':'${D2CS_PORT}'          10.88.0.0/16         ANY' ${PVPGN_PATH}conf/address_translation.conf
        sed -i "/^[1-9]\+.*:${D2CS_PORT}/d" ${REALM_PATH}conf/address_translation.conf
        sed -i '/1.2.3.4:6113/a '${D2CS_IP_input}':'${D2CS_PORT}'   '${D2CS_IP_output}':'${D2CS_PORT}'          10.88.0.0/16         ANY' ${REALM_PATH}conf/address_translation.conf
        readarray ARR_D2GSS < <(echo "$realm" | yq e -o=j -I=0 '.d2gs[]' -)

        for d2gs in "${ARR_D2GSS[@]}"; do
            D2GS_IP_input=$(echo "$d2gs" | yq e '.innerIP' -)
            D2GS_IP_output=$(echo "$d2gs" | yq e '.outIP' -)
            REALM_PATH=/home/pvpgn_$(echo "$realm" | yq e '.path' -)/
            sed -i '/'${D2GS_IP_output}':4000/d' ${REALM_PATH}conf/address_translation.conf
            sed -i '/1.2.3.4:4000/a '${D2GS_IP_input}':4000   '${D2GS_IP_output}':4000          10.88.0.0/16         ANY' ${REALM_PATH}conf/address_translation.conf
        done
    done
}

Setup_d2gs() {
    D2GS_PATH=/home/d2gs/
    for realm in "${ARRREALMS[@]}"; do
        readarray ARR_D2GSS < <(echo "$realm" | yq e -o=j -I=0 '.d2gs[]' -)

        for d2gs in "${ARR_D2GSS[@]}"; do
            CID=$(echo "$d2gs" | yq e '.cid' -)
            if [ "$CID" = "$HOSTNAME" ]; then
                D2CS_IP=$(echo "$d2gs" | yq e '.d2csIP' -)
                D2DBS_IP=$(echo "$d2gs" | yq e '.d2dbsIP' -)
                D2GS_PASSWD=$(echo "$d2gs" | yq e '.AdminPwd' -)
                D2VERSION=$(echo "$realm" | yq e '.version' -)
                D2CS_PORT=$(echo "$realm" | yq e '.port' -)
                cd ${D2GS_PATH}
                wget -q https://github.com/wqmeng/pvpgner/raw/main/d2gs/D2GS_${D2VERSION}.7z

                7za x -y D2GS_${D2VERSION}.7z >/dev/null 2>&1
                mv D2GS_${D2VERSION}/* .
                rm D2GS_${D2VERSION} -rf
                ln -s -t /home/d2gs/ /home/D2GS_BASE/* >/dev/null 2>&1
                touch d2_${D2VERSION}

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
                wine regedit ${D2GS_PATH}d2gs.reg
            fi
        done
    done
}

Setup_Pvpgn() {
    Setup_realm
    Setup_bnetd
    Setup_d2cs
    Setup_d2dbs
    Setup_address_translation
    Setup_d2gs
}

Start_Pvpgn() {
    pkill -f 'PvPGNConsole'
    cd ${PVPGN_PATH}
    nohup bash -c "wine ${PVPGN_PATH}PvPGNConsole.exe &" </dev/null &>/dev/null &
    sleep 1
}

Start_d2cs() {
    for realm in "${ARRREALMS[@]}"; do
        REALM_PATH=/home/pvpgn_$(echo "$realm" | yq e '.path' -)'/'
        pkill -if $REALM_PATH'D2CSConsole'
        cd ${REALM_PATH}
        D2VERSION=$(echo "$realm" | yq e '.version' -)
        if [ "$D2VERSION" = "1.13d_VIP" ]; then
            nohup bash -c "wine ${REALM_PATH}d2csConsole_VIP.exe &" </dev/null &>/dev/null &
        else
            nohup bash -c "wine ${REALM_PATH}D2CSConsole.exe &" </dev/null &>/dev/null &
        fi
        sleep 1
    done
}

Start_d2dbs() {
    for realm in "${ARRREALMS[@]}"; do
        REALM_PATH=/home/pvpgn_$(echo "$realm" | yq e '.path' -)'/'
        pkill -f $REALM_PATH'D2DBSConsole'
        cd ${REALM_PATH}
        nohup bash -c "wine ${REALM_PATH}D2DBSConsole.exe &" </dev/null &>/dev/null &
        sleep 1
    done
}

Start_d2gs() {
    pkill -f 'D2GS'
    cd ${D2GS_PATH}
    nohup bash -c "wine D2GS.exe &" </dev/null &>/dev/null &
    sleep 3
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

ReadYaml

cd /home/pvpgn

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

case "${ACT}" in
    setup)
        case "${TASK}" in
            pvpgn)
                Setup_Pvpgn
            ;;
            d2cs)
                Setup_d2cs
            ;;
            d2dbs)
                Setup_d2dbs
            ;;
            address_translation)
                Setup_address_translation
            ;;
            d2gs)
                Setup_d2gs
            ;;
        esac
        ;;
    start|restart)
        case "${TASK}" in
            pvpgn)
                Setup_Pvpgn
                Start_Pvpgn
            ;;
            d2cs)
                Setup_d2cs
                Start_d2cs
            ;;
            d2dbs)
                Setup_d2dbs
                Start_d2dbs
            ;;
            d2gs)
                Setup_d2gs
                Start_d2gs
            ;;
            *)
                Setup_Pvpgn
                Start_Pvpgn
                Start_d2cs
                Start_d2dbs
                Start_d2gs
            ;;
        esac
        ;;
    stop)
        pkill -f 'PvPGNConsole'
        pkill -f 'D2CSConsole'
        pkill -f 'D2DBSConsole'
        pkill -f 'D2GS'
        ;;
    delete)
        echo "$0 delete pvpgn path"
        echo "$0 delete realm path"
        echo "$0 delete d2gs path"
        ;;
    help)
        echo "$0 setup pvpgn"
        echo "$0 setup d2cs"
        echo "$0 setup d2dbs"
        echo "$0 setup address_translation"
        echo "$0 setup Setup_d2gs"

        echo "$0 start/restart pvpgn"
        echo "$0 start/restart d2cs"
        echo "$0 start/restart d2dbs"
        echo "$0 start/restart d2gs"
        
        echo "$0 stop"

        echo "$0 delete pvpgn path"
        echo "$0 delete realm path"
        echo "$0 delete d2gs path"

        echo "$0 setup d2gs exist_realm # will detect a new output IP for new d2gs"
        ;;
    *)
        echo "Not supported action"
        ;;
esac
