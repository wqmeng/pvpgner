#!/bin/bash
# wget -qO - https://raw.githubusercontent.com/wqmeng/pvpgner/main/src/install.sh | sh -s help
# wget -qO - https://raw.githubusercontent.com/wqmeng/pvpgner/main/src/install.sh | sh <(cat) </dev/tty
# wget -qO - http://10.0.0.10/docker/pvpgn/install.sh | sh <(cat) </dev/tty
# dnf -yq install tmux; tmux new-session -ds pvpgn; tmux send-keys -t pvpgn 'wget -qO - https://raw.githubusercontent.com/wqmeng/pvpgner/main/src/install.sh | sh <(cat) </dev/tty' ENTER; tmux a -t pvpgn;
DEBUG_MODE=true
if [ "$DEBUG_MODE" != "true" ]; then
    PVPGN_URI=https://raw.githubusercontent.com/wqmeng/pvpgner/main/src/
else
    PVPGN_URI=http://10.0.0.10/docker/pvpgn/
fi

Color_Text() {
    echo -e " \e[0;$2m$1\e[0m"
}

Echo_Red() {
    echo $(Color_Text "$1" "31")
}

Echo_Green() {
    echo $(Color_Text "$1" "32")
}

Echo_Yellow() {
    echo $(Color_Text "$1" "33")
}

Echo_Blue() {
    echo $(Color_Text "$1" "34")
}

Dispaly_Selection() {

    #select install a new pvpgn or add realm or add gs
    ACTSelect="1"
    Echo_Yellow "You have 3 options for your Diablo2 pvpgn install."
    echo "1: Install new pvpgn (default)"
    echo "2: Add realm to a pvpgn"
    echo "3: Add d2gs to a realm"
    # echo "4: Start pvpgn"
    # echo "5: Stop pvpgn"
    # echo "6: Restart pvpgn"
    # echo "4: Install Diablo2 1.09d"
    # echo "5: Install Diablo2 1.10"
    # echo "6: Install Diablo2 1.12a"
    read -p "Enter your choice (1, 2 or 3): " ACTSelect

    case "${ACTSelect}" in
    1)
        echo "You will install new pvpgn (default)"
        ACT=pvpgn
        ;;
    2)
        echo "You will Add a realm to pvpgn"
        ACT=realm
        ;;
    3)
        echo "You will Add a d2gs to a realm"
        ACT=d2gs
        ;;
    # 4)
    #     echo "You will install Diablo2 1.09d"
    #     ;;
    # 5)
    #     echo "You will install PHP 5.6.20"
    #     ;;
    # 6)
    #     echo "You will install PHP 7.0.5"
    #     ;;
    *)
        echo "No input,You will install new pvpgn"
        ACTSelect="1"
        ACT=pvpgn
        ;;
    esac

    if [[ "${ACTSelect}" = "1" ]]; then

        #which MySQL Version do you want to install?
        DBSelect="1"
        STORAGE='plain'
        Echo_Yellow "You have 6 options for your Database install."
        echo "1: Install plain NO database (default)"
        echo "2: Install cdb"
        echo "3: Install mysql"
        echo "4: Install mariaDB"
        echo "5: Install pgsql"
        echo "6: Install sqlite3"
        read -p "Enter your choice (1, 2, 3, 4, 5 or 6): " DBSelect

        case "${DBSelect}" in
        1)
            echo "You will install plain NO database"
            STORAGE=plain
            ;;
        2)
            echo "You will install cdb"
            STORAGE=cdb
            ;;
        3)
            echo "You will Install mysql"
            STORAGE=mysql
            ;;
        4)
            echo "You will install mariaDB"
            STORAGE=mysql
            ;;
        5)
            echo "You will install pgsql 10.0.23"
            STORAGE=pgsql
            ;;
        6)
            echo "You will install sqlite3"
            STORAGE=sqlite3
            ;;
        *)
            echo "No input,You will install plain NO database"
            STORAGE=plain
            ;;
        esac

        if [[ "${DBSelect}" = "3" || "${DBSelect}" = "4" || "${DBSelect}" = "5" ]] && [ $(free -m | grep Mem | awk '{print  $2}') -le 1024 ]; then
            echo "Memory less than 1GB, can't install MySQL 5.6, 5.7 or MairaDB 10!"
            exit 1
        fi

        if [[ "${DBSelect}" = "4" ]]; then
            MySQL_Bin="/usr/local/mariadb/bin/mysql"
            MySQL_Config="/usr/local/mariadb/bin/mysql_config"
            MySQL_Dir="/usr/local/mariadb"
        else
            MySQL_Bin="/usr/local/mysql/bin/mysql"
            MySQL_Config="/usr/local/mysql/bin/mysql_config"
            MySQL_Dir="/usr/local/mysql"
        fi

        if [[ "${DBSelect}" = "2" || "${DBSelect}" = "3" || "${DBSelect}" = "4" || "${DBSelect}" = "5" || "${DBSelect}" = "6" ]]; then
            #set mysql root password
            DB_Root_Password="root"
            Echo_Yellow "Please setup root password of MySQL.(Default password: root)"
            read -p "Please enter: " DB_Root_Password
            if [ "${DB_Root_Password}" = "" ]; then
                DB_Root_Password="root"
            fi
            echo "MySQL root password: ${DB_Root_Password}"
        fi

        if [[ "${DBSelect}" = "3" || "${DBSelect}" = "4" ]]; then
            #do you want to enable or disable the InnoDB Storage Engine?
            InstallInnodb="y"
            Echo_Yellow "Do you want to enable or disable the InnoDB Storage Engine?"
            read -p "Default enable,Enter your choice [Y/n]: " InstallInnodb

            case "${InstallInnodb}" in
            [yY][eE][sS] | [yY])
                echo "You will enable the InnoDB Storage Engine"
                InstallInnodb="y"
                ;;
            [nN][oO] | [nN])
                echo "You will disable the InnoDB Storage Engine!"
                InstallInnodb="n"
                ;;
            *)
                echo "No input,The InnoDB Storage Engine will enable."
                InstallInnodb="y"
                ;;
            esac
        fi

        #which PHP Version do you want to install?
        # echo "==========================="

        # PHPSelect="3"
        # Echo_Yellow "You have 6 options for your PHP install."
        # echo "1: Install PHP 5.2.17"
        # echo "2: Install PHP 5.3.29"
        # echo "3: Install PHP 5.4.45 (Default)"
        # echo "4: Install PHP 5.5.33"
        # echo "5: Install PHP 5.6.19"
        # echo "6: Install PHP 7.0.4"
        # read -p "Enter your choice (1, 2, 3, 4, 5 or 6): " PHPSelect

        # case "${PHPSelect}" in
        # 1)
        #     echo "You will install PHP 5.2.17"
        #     ;;
        # 2)
        #     echo "You will install PHP 5.3.29"
        #     ;;
        # 3)
        #     echo "You will Install PHP 5.4.45"
        #     ;;
        # 4)
        #     echo "You will install PHP 5.5.34"
        #     ;;
        # 5)
        #     echo "You will install PHP 5.6.20"
        #     ;;
        # 6)
        #     echo "You will install PHP 7.0.5"
        #     ;;
        # *)
        #     echo "No input,You will install PHP 5.4.45"
        #     PHPSelect="3"
        # esac

        #which Memory Allocator do you want to install?
        # echo "==========================="

        # SelectMalloc="1"
        # Echo_Yellow "You have 3 options for your Memory Allocator install."
        # echo "1: Don't install Memory Allocator. (Default)"
        # echo "2: Install Jemalloc"
        # echo "3: Install TCMalloc"
        # read -p "Enter your choice (1, 2 or 3): " SelectMalloc

        # case "${SelectMalloc}" in
        # 1)
        #     echo "You will install not install Memory Allocator."
        #     ;;
        # 2)
        #     echo "You will install JeMalloc"
        #     ;;
        # 3)
        #     echo "You will Install TCMalloc"
        #     ;;
        # *)
        #     echo "No input,You will not install Memory Allocator."
        #     SelectMalloc="1"
        # esac

        # if [ "${SelectMalloc}" =  "1" ]; then
        #     MySQL51MAOpt=''
        #     MySQL55MAOpt=''
        #     NginxMAOpt=''
        # elif [ "${SelectMalloc}" =  "2" ]; then
        #     MySQL51MAOpt='--with-mysqld-ldflags=-ljemalloc'
        #     MySQL55MAOpt="-DCMAKE_EXE_LINKER_FLAGS='-ljemalloc' -DWITH_SAFEMALLOC=OFF"
        #     MariaDBMAOpt=''
        #     NginxMAOpt="--with-ld-opt='-ljemalloc'"
        # elif [ "${SelectMalloc}" =  "3" ]; then
        #     MySQL51MAOpt='--with-mysqld-ldflags=-ltcmalloc'
        #     MySQL55MAOpt="-DCMAKE_EXE_LINKER_FLAGS='-ltcmalloc' -DWITH_SAFEMALLOC=OFF"
        #     MariaDBMAOpt="-DCMAKE_EXE_LINKER_FLAGS='-ltcmalloc' -DWITH_SAFEMALLOC=OFF"
        #     NginxMAOpt='--with-google_perftools_module'
        # fi

    fi

    if [[ "${ACTSelect}" = "1" || "${ACTSelect}" = "2" ]]; then
        #set realm name and port
        REALM_NAME="Rm_D2Version"

        Echo_Yellow "Please setup Realm name, default is: "$REALM_NAME
        read -p "Please enter: " READ_REALM_NAME
        if [[ "${READ_REALM_NAME}" != "" ]]; then
            REALM_NAME=${READ_REALM_NAME}
            echo "Your Realm name: ${REALM_NAME}"
        else
            echo "No input, your Realm name will be correct after you choose the D2 version: ${REALM_NAME}"
        fi

        if [ "${ACTSelect}" = "2" ]; then
            # add realm
            USEDPORTS=$(netstat -ntl | grep 'tcp' | grep -v 'tcp6' | cut -d ':' -f2 | cut -d ' ' -f1)
            ARRPORTS=($(echo $USEDPORTS | tr -s ' ' ' '))
            REALM_PORT=6113

            while [ $REALM_PORT -le 60000 ]; do
                REALM_PORT=$(expr $REALM_PORT + 100)
                PORTUSED=false
                for i in "${!ARRPORTS[@]}"; do
                    if [ "$REALM_PORT" = "${ARRPORTS[i]}" ]; then
                        PORTUSED=true
                        break
                    fi
                done
                if [ "$PORTUSED" = false ]; then
                    break
                fi
            done
        else
            REALM_PORT="6113"
        fi

        Echo_Yellow "Please setup Realm port, default is: "$REALM_PORT
        read -p "Please enter: " READ_REALM_PORT
        if [[ "${READ_REALM_PORT}" != "" ]]; then
            REALM_PORT=${READ_REALM_PORT}
        fi
        echo "Your Realm port: ${REALM_PORT}"

        #which D2 Version do you want to install?
        D2Select="2"
        Echo_Yellow "You have 4 options for your Diablo2 GS install."
        echo "0: Install Diablo2 1.13d_VIP"
        echo "1: Install Diablo2 1.13d"
        echo "2: Install Diablo2 1.13c (default)"
        echo "3: Install Diablo2 1.11b"
        echo "4: Install Diablo2 1.09d"
        # echo "5: Install Diablo2 1.10"
        # echo "6: Install Diablo2 1.12a"
        read -p "Enter your choice (1, 2, 3 or 4): " D2Select

        case "${D2Select}" in
        0)
            echo "You will install Diablo2 GS 1.13d_VIP"
            D2Select=1.13d_VIP
            ;;
        1)
            echo "You will install Diablo2 GS 1.13d"
            D2Select=1.13d
            ;;
        2)
            echo "You will install Diablo2 GS 1.13c"
            D2Select=1.13c
            ;;
        3)
            echo "You will Install Diablo2 GS 1.11b"
            D2Select=1.11b
            ;;
        4)
            echo "You will install Diablo2 GS 1.09d"
            D2Select=1.09d
            ;;
        *)
            echo "No input,You will install Diablo2 1.13c"
            D2Select=1.13c
            ;;
        esac

        if [[ "${REALM_NAME}" = "Rm_D2Version" || "${REALM_NAME}" = "Realm" ]]; then
            REALM_NAME="Rm_"${D2Select}
        fi
    fi

    if [ "${ACTSelect}" = "3" ]; then
        # We should get all the realm names from a conf file, such as ylmp
        REALM_NAME="Realm"

        ALL_REALM_NAMES=($(yq '.pvpgn.realms[].name' ${PVPGN_YAML}))
        SELECT_REALM=''
        for i in "${!ALL_REALM_NAMES[@]}"; do
            echo "$i: ${ALL_REALM_NAMES[i]}"
            SELECT_REALM=${SELECT_REALM}$i', '
        done

        if [[ "$SELECT_REALM" = *", " ]]; then
            SELECT_REALM=$(echo ${SELECT_REALM%, *})
        #    echo "${SELECT_REALM/%', '/' or '}"
        fi

        Echo_Yellow "Please select which Realm will you add the D2GS to, default is: 0 ${ALL_REALM_NAMES[0]}"
        read -p "Enter your choice ($SELECT_REALM): " READ_REALM_NAME
        if [ "${READ_REALM_NAME}" = "" ]; then
            REALM_NAME="${ALL_REALM_NAMES[0]}"
        else
            REALM_NAME=${ALL_REALM_NAMES[${READ_REALM_NAME}]}
        fi
    fi
    echo "Your Realm name: ${REALM_NAME}"
    if [ "${ACTSelect}" = "1" ]; then
        # ip a | grep -v 'inet6' | grep 'inet' | grep -v 'host lo' | cut -d'/' -f1 | grep -o '[0-9].*' | grep -v '10.88'
        EXTIP=$(ip a | grep -v 'inet6' | grep 'inet' | grep -v 'host lo' | cut -d'/' -f1 | grep -o '[0-9].*' | grep -v '10.88' | sed -n '1p')
        ALL_EXTIPS=$(ip a | grep -v 'inet6' | grep 'inet' | grep -v 'host lo' | cut -d'/' -f1 | grep -o '[0-9].*' | grep -v '10.88')

        ARR_ALL_EXTIPS=($(echo $ALL_EXTIPS | tr -s ' ' ' '))
        for i in "${!ARR_ALL_EXTIPS[@]}"; do
            echo "$i: ${ARR_ALL_EXTIPS[i]}"
        done

        Echo_Yellow "Please select Output IP, default is: 0 ("${ARR_ALL_EXTIPS[0]}")"
        read -p "Please enter: " READ_EXTIP
        if [ "${READ_EXTIP}" != "" ]; then
            EXTIP=${ARR_ALL_EXTIPS[${READ_EXTIP}]}
            # EXTIP=${READ_EXTIP}
            if [ "${EXTIP}" != "" ]; then
                echo "You select: "${READ_EXTIP}", IP: "$EXTIP
            else
                EXTIP=$(ip a | grep -v 'inet6' | grep 'inet' | grep -v 'host lo' | cut -d'/' -f1 | grep -o '[0-9].*' | grep -v '10.88' | sed -n '1p')
            fi
        fi
        DDDD=$EXTIP
        echo "Your Output IP: ${EXTIP}"
    else
        EXTIP=$(ip a | grep -v 'inet6' | grep 'inet' | grep -v 'host lo' | cut -d'/' -f1 | grep -o '[0-9].*' | grep -v '10.88' | sed -n '1p')
        ALL_EXTIPS=$(ip a | grep -v 'inet6' | grep 'inet' | grep -v 'host lo' | cut -d'/' -f1 | grep -o '[0-9].*' | grep -v '10.88')
        ALL_USEDIPS=$(netstat -ntl | grep 'tcp' | grep -v 'tcp6' | grep '4000' | cut -d ':' -f1 | tr -s ' ' | cut -d ' ' -f4)

        ARR_ALL_EXTIPS=($(echo $ALL_EXTIPS | tr -s ' ' ' '))
        ARR_ALL_USEDIPS=($(echo $ALL_USEDIPS | tr -s ' ' ' '))
        ARR_AV_IPS=()
        for i in "${!ARR_ALL_EXTIPS[@]}"; do
            IPUSED=false
            for j in "${!ARR_ALL_USEDIPS[@]}"; do
                if [ "${ARR_ALL_EXTIPS[i]}" = "${ARR_ALL_USEDIPS[j]}" ]; then
                    IPUSED=true
                    break
                fi
            done

            if [ "${IPUSED}" = false ]; then
                ARR_AV_IPS+=("${ARR_ALL_EXTIPS[i]}")
            fi
        done

        SELECT_D2GS_IPS=""
        for j in "${!ARR_AV_IPS[@]}"; do
            echo "$j: ${ARR_AV_IPS[j]}"
            if [ "$j" -lt $((${#ARR_AV_IPS[@]} - 1)) ]; then
                if [ "$j" = $((${#ARR_AV_IPS[@]} - 2)) ]; then
                    SELECT_D2GS_IPS=${SELECT_D2GS_IPS}$j' or '
                else
                    SELECT_D2GS_IPS=${SELECT_D2GS_IPS}$j', '
                fi
            else
                SELECT_D2GS_IPS=${SELECT_D2GS_IPS}$j
            fi
        done
        DDDD=${ARR_AV_IPS[0]}

        Echo_Yellow "Please select D2GS Output IP, default is 0, IP: $DDDD"
        read -p "Enter your choice ($SELECT_D2GS_IPS): " READ_EXTIP
        if [ "${READ_EXTIP}" != "" ]; then
            DDDD=${ARR_AV_IPS[${READ_EXTIP}]}
            if [ "${DDDD}" != "" ]; then
                echo "You select: "${READ_EXTIP}", IP: "$DDDD
            fi
        fi
        REALM_OUTIP=$EXTIP
        D2GS_OUTIP=$DDDD
        echo "Your pvpgn IP: ${EXTIP}"
        echo "Your D2GS IP: ${DDDD}"
    fi
}

Print_Sucess_Info() {
    # Clean_Src_Dir
    echo "+------------------------------------------------------------------------+"
    echo "|        Pvpgn Closed Realm installer on docker Written by wqmeng        |"
    echo "+------------------------------------------------------------------------+"
    echo "|  For more information please visit https://github.com/wqmeng/pvpgner   |"
    echo "+------------------------------------------------------------------------+"
    echo "|   pvpgn status manage: pvpgn {start|stop|reload|restart|kill|status}   |"
    echo "+------------------------------------------------------------------------+"
    echo "|  pvpgn:                                                                |"
    echo "|         ${EXTIP}                                                       |"
    echo "|  realm:                                                                |"
    echo "|         ${REALM_NAME} ${EXTIP}:${REALM_PORT}                           |"
    echo "|  d2gs:                                                                 |"
    echo "|         ${EXTIP}:4000    admin password: abcd123    Port: 8888         |"
    echo "+------------------------------------------------------------------------+"
    echo "|  Add realm: pvpgn realm add                                            |"
    echo "|  Add d2gs: pvpgn d2gs add                                              |"
    echo "+------------------------------------------------------------------------+"
    echo "|  Default config file: /home/pvpgn/pvpgn.yaml                           |"
    echo "+------------------------------------------------------------------------+"
    echo "|  MySQL/MariaDB root password: ${DB_Root_Password}                      |"
    echo "+------------------------------------------------------------------------+"
    # pvngn status
    netstat -ntl
    firewall-cmd --list-all | grep 'ports: ' | grep '6112'
    Echo_Green "Install pvpgn ${EXTIP} completed! enjoy it."
}

Restart_GSs() {
    Echo_Red "Restart_GSs"
    ARR_GSPATHS=($(yq '.pvpgn.realms[].d2gs[].path' $PVPGN_YAML))
    PVPBN_PATH=$(yq '.pvpgn.path' ${PVPGN_YAML})
    for i in "${!ARR_GSPATHS[@]}"; do
        GSPATH=${ARR_GSPATHS[i]}
        Echo_Red "GSPATH $GSPATH"
        if [[ "$GSPATH" != "$PVPBN_PATH" ]]; then
            Echo_Red "Restart $GSPATH"
            docker exec -it pvpgn-$GSPATH /bin/bash /home/pvpgn/config_pvpgn.sh restart d2gs
        fi
    done
}

PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

# Check if user is root
if [ $(id -u) != "0" ]; then
    echo "Error: You must be root to run this script, please use root to install pvpgn"
    exit 1
fi

cur_dir=$(pwd)
PVPGN_YAML=/home/pvpgn/pvpgn.yaml
AdminPwd="9e75a42100e1b9e0b5d3873045084fae699adcb0" #abcd123

clear
echo "+------------------------------------------------------------------------+"
echo "|        Pvpgn Closed Realm installer on docker Written by wqmeng        |"
echo "+------------------------------------------------------------------------+"
echo "|      A tool to auto-compile & install pvpgn closed realm on Linux      |"
echo "+------------------------------------------------------------------------+"
echo "|   For more information please visit https://github.com/wqmeng/pvpgner  |"
echo "+------------------------------------------------------------------------+"

# If we have a argument, then we do not select.
case "$1" in
pvpgn)
    ACT="pvpgn"
    DBSelect=$2
    D2Select=$4
    ;;
realm)
    ACT="realm"
    REALM_NAME=$2
    DDDD=$3
    REALM_PORT=$4
    D2Select=$5
    ;;
d2gs)
    ACT="d2gs"
    REALM_NAME=$2
    ;;
help | -h | -help)
    Echo_Red "Usage: $0 {pvpgn|realm|d2gs}"
    echo "Storage: plain cdb mysql mariaDB pgsql sqlite3"
    echo "Diablo2: 1.13d 1.13c 1.11b 1.09d"
    Echo_Red "$0 pvpgn plain realm_name 1.13c"
    Echo_Red "$0 realm realm_name 6213 1.11b"
    Echo_Red "$0 d2gs exist_realm # will detect a new output IP for new d2gs"
    ;;
*)
    Dispaly_Selection
    ;;
esac

case "${ACT}" in
pvpgn)
    echo "Pvpgn installation is starting ..."
    dnf -yq clean all
    dnf -yq install --assumeyes epel-release
    dnf -yq update
    dnf -yq install wget tmux podman
    dnf -yq install --assumeyes p7zip
    wget -q https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O /usr/bin/yq
    chmod +x /usr/bin/yq
    touch /etc/containers/nodocker
    systemctl enable --now podman
    mkdir -p /home/pvpgn/

    if [ ! -f "/home/D2GS_BASE/d2data.mpq" ]; then
        mkdir -p /home/D2GS_BASE
        cd /home/D2GS_BASE
        wget -q https://ia801809.us.archive.org/29/items/d2gs-base.-7z/D2GS_Base.7z
        7za x -y D2GS_Base.7z >/dev/null 2>&1
        mv D2GS_Base/* .
        rm D2GS_Base -rf
        rm D2GS_Base.7z -rf
    fi

    wget -qO - ${PVPGN_URI}build_docker.sh | sh

    CID=$(docker ps -a | grep pvpgn | grep -v 'pvpgn-' | cut -d ' ' -f 1)
    if [ "$CID" != "" ]; then
        docker stop -i $CID >/dev/null 2>&1
        docker rm -fi $CID >/dev/null 2>&1
    fi
    # 后台创建

    if [ -z ${EXTIP} ]; then
        EXTIP=$(ip a | grep -v 'inet6' | grep 'inet' | grep -v 'host lo' | cut -d'/' -f1 | grep -o '[0-9].*' | sed -n '1p')
    fi

    STRDATE=$(date +%y%m%d_%H%M%S)
    mkdir -p /home/pvpgn_$STRDATE/var
    mkdir -p /home/pvpgn_$STRDATE/conf
    mkdir -p /home/d2gs_$STRDATE

    docker run -dt --privileged=true -v /home/pvpgn_$STRDATE/conf:/home/pvpgn_$STRDATE/conf -v /home/pvpgn_$STRDATE/var:/home/pvpgn_$STRDATE/var -v /home/d2gs_$STRDATE:/home/d2gs -v /home/pvpgn:/home/pvpgn -v /home/D2GS_BASE:/home/D2GS_BASE --name pvpgn -p $EXTIP:6112:6112 -p $EXTIP:6112:6112/udp -p $EXTIP:$REALM_PORT:$REALM_PORT -p $EXTIP:4000:4000 wqmeng:pvpgn /bin/bash
    # update config_pvpgn.sh
    docker exec -it pvpgn rm -rf /home/pvpgn/config_pvpgn.sh
    docker exec -it pvpgn wget -q ${PVPGN_URI}config_pvpgn.sh -O/home/pvpgn/config_pvpgn.sh
    docker exec -it pvpgn chmod +x /home/pvpgn/config_pvpgn.sh

    CID=$(docker ps -a | grep pvpgn | grep -v 'pvpgn-' | cut -d ' ' -f 1)
    # create a yaml conf file.
    # PVPGN
    rm -rf ${PVPGN_YAML}
    echo 'pvpgn:' >>${PVPGN_YAML}
    echo "  cid: $CID" >>${PVPGN_YAML}
    echo "  name: pvpgn" >>${PVPGN_YAML}
    echo "  IP: $EXTIP" >>${PVPGN_YAML}
    echo "  path: $STRDATE" >>${PVPGN_YAML}
    PVPBN_INNERIP=$(docker inspect pvpgn | grep IPAddress | sed -n '1p' | cut -d '"' -f 4)
    echo "  innerIP: $PVPBN_INNERIP" >>${PVPGN_YAML}

    #  Realm
    REALM_DESC="$REALM_NAME for $D2Select"
    yq e -i '.pvpgn.realms += [{"cid":"'$CID'","name":"'$REALM_NAME'","desc":"'"$REALM_DESC"'","port":'$REALM_PORT',"version":"'$D2Select'","path":"'$STRDATE'"}]' ${PVPGN_YAML}

    #  d2gs
    yq e -i '.pvpgn.realms[] |= select(.name == "'$REALM_NAME'").d2gs += [{"cid":"'$CID'","innerIP":"'$PVPBN_INNERIP'","outIP":"'$EXTIP'","port":4000,"d2csIP":"'$PVPBN_INNERIP'","d2dbsIP":"'$PVPBN_INNERIP'","path":"'$STRDATE'","AdminPwd":"'$AdminPwd'"}]' $PVPGN_YAML

    # Start D2GS
    # Echo_Red "docker pvpgn setup pvpgn"
    # docker exec -it pvpgn /bin/bash /home/pvpgn/config_pvpgn.sh setup pvpgn $EXTIP $REALM_NAME $REALM_PORT $D2Select
    Echo_Red "docker pvpgn start pvpgn"
    # docker exec -it -w /home/pvpgn pvpgn /bin/bash /home/pvpgn/config_pvpgn.sh start $REALM_NAME
    docker exec -it pvpgn /bin/bash /home/pvpgn/config_pvpgn.sh start

    firewall-cmd --permanent --zone=public --add-port=6112/tcp
    firewall-cmd --permanent --zone=public --add-port=6112/udp
    firewall-cmd --permanent --zone=public --add-port=$REALM_PORT/tcp
    firewall-cmd --permanent --zone=public --add-port=4000/tcp
    firewall-cmd --reload

    ;;
realm)
    # Add realm to pvpgn
    echo 'Add realm to pvpgn'
    ALL_REALM_PORTS=$(yq '.pvpgn.realms[].port' ${PVPGN_YAML})
    ALL_REALM_PATHS=$(yq '.pvpgn.realms[].path' ${PVPGN_YAML})
    ARRREALM_PORTS=($(echo $ALL_REALM_PORTS | tr -s ' ' ' '))
    ARRREALM_PATHS=($(echo $ALL_REALM_PATHS | tr -s ' ' ' '))
    PVPBN_PATH=$(yq '.pvpgn.path' ${PVPGN_YAML})
    P_PORTS=""
    V_PATHS=""
    for i in "${!ARRREALM_PORTS[@]}"; do
        if [[ "$P_PORTS" != *":${ARRREALM_PORTS[i]}:"* ]]; then
            P_PORTS=${P_PORTS}'-p '${EXTIP}':'${ARRREALM_PORTS[i]}':'${ARRREALM_PORTS[i]}' '
            V_PATHS=${V_PATHS}'-v /home/pvpgn_'${ARRREALM_PATHS[i]}/conf':/home/pvpgn_'${ARRREALM_PATHS[i]}/conf' ''-v /home/pvpgn_'${ARRREALM_PATHS[i]}/var':/home/pvpgn_'${ARRREALM_PATHS[i]}/var' '
        fi
    done
    CID=$(docker ps -a | grep pvpgn | grep -v 'pvpgn-' | cut -d ' ' -f 1)
    PVPBN_INNERIP=$(docker inspect pvpgn | grep IPAddress | sed -n '1p' | cut -d '"' -f 4)
    if [ "$CID" != "" ]; then
        docker stop -i $CID >/dev/null 2>&1
        docker rm -fi $CID >/dev/null 2>&1
    fi
    STRDATE=$(date +%y%m%d_%H%M%S)
    mkdir -p /home/pvpgn_$STRDATE/var
    mkdir -p /home/pvpgn_$STRDATE/conf
    mkdir -p /home/d2gs_$STRDATE

    docker run -dt --privileged=true $V_PATHS -v /home/pvpgn_$STRDATE/conf:/home/pvpgn_$STRDATE/conf -v /home/pvpgn_$STRDATE/var:/home/pvpgn_$STRDATE/var -v /home/pvpgn:/home/pvpgn -v /home/d2gs_$PVPBN_PATH:/home/d2gs -v /home/D2GS_BASE:/home/D2GS_BASE --name pvpgn -p $EXTIP:6112:6112 -p $EXTIP:6112:6112/udp $P_PORTS -p $EXTIP:$REALM_PORT:$REALM_PORT -p $EXTIP:4000:4000 wqmeng:pvpgn /bin/bash
    docker exec -it pvpgn rm -rf /home/pvpgn/config_pvpgn.sh
    docker exec -it pvpgn wget -q ${PVPGN_URI}config_pvpgn.sh -O/home/pvpgn/config_pvpgn.sh
    docker exec -it pvpgn chmod +x /home/pvpgn/config_pvpgn.sh

    OLDCID=$CID
    CID=$(docker ps -a | grep pvpgn | grep -v 'pvpgn-' | cut -d ' ' -f 1)
    OLDPVPBN_INNERIP=$PVPBN_INNERIP
    PVPBN_INNERIP=$(docker inspect pvpgn | grep IPAddress | sed -n '1p' | cut -d '"' -f 4)
    sed -i 's/'$OLDCID'/'$CID'/' ${PVPGN_YAML}
    sed -i 's/'$OLDPVPBN_INNERIP'/'$PVPBN_INNERIP'/' ${PVPGN_YAML}

    CID=$(docker ps -a | grep pvpgn-$STRDATE | cut -d ' ' -f 1)
    if [ "$CID" != "" ]; then
        docker stop -i $CID >/dev/null 2>&1
        docker rm -fi $CID >/dev/null 2>&1
    fi

    Echo_Red "docker pvpgn d2gs"
    # Create a new d2gs container for the new realm and point the 4000 port.
    docker run -dt --privileged=true -v /home/pvpgn:/home/pvpgn -v /home/d2gs_$STRDATE:/home/d2gs -v /home/D2GS_BASE:/home/D2GS_BASE --name pvpgn-$STRDATE -p $D2GS_OUTIP:4000:4000 wqmeng:pvpgn /bin/bash
    docker exec -it pvpgn-$STRDATE rm -rf /home/pvpgn/config_pvpgn.sh
    docker exec -it pvpgn-$STRDATE wget -q ${PVPGN_URI}config_pvpgn.sh -O/home/pvpgn/config_pvpgn.sh
    docker exec -it pvpgn-$STRDATE chmod +x /home/pvpgn/config_pvpgn.sh

    D2GS_INNERIP=$(docker inspect pvpgn-$STRDATE | grep IPAddress | sed -n '1p' | cut -d '"' -f 4)
    CID=$(docker ps -a | grep pvpgn | grep -v 'pvpgn-' | cut -d ' ' -f 1)
    REALM_DESC="$REALM_NAME for $D2Select"
    yq e -i '.pvpgn.realms += [{"cid":"'$CID'","name":"'$REALM_NAME'","desc":"'"$REALM_DESC"'","port":'$REALM_PORT',"version":"'$D2Select'","path":"'$STRDATE'"}]' ${PVPGN_YAML}

    #  d2gs
    CID=$(docker ps -a | grep pvpgn-$STRDATE | cut -d ' ' -f 1)
    yq e -i '.pvpgn.realms[] |= select(.name == "'$REALM_NAME'").d2gs += [{"cid":"'$CID'","innerIP":"'$D2GS_INNERIP'","outIP":"'$D2GS_OUTIP'","port":4000,"d2csIP":"'$PVPBN_INNERIP'","d2dbsIP":"'$PVPBN_INNERIP'","path":"'$STRDATE'","AdminPwd":"'$AdminPwd'"}]' $PVPGN_YAML
    # Echo_Red "docker pvpgn setup pvpgn"
    # docker exec -it pvpgn /bin/bash /home/pvpgn/config_pvpgn.sh setup pvpgn
    # Echo_Red "docker pvpgn-$STRDATE setup d2gs"
    # docker exec -it pvpgn-$STRDATE /bin/bash /home/pvpgn/config_pvpgn.sh setup d2gs
    Echo_Red "Docker pvpgn-$STRDATE start d2gs"
    docker exec -it pvpgn-$STRDATE /bin/bash /home/pvpgn/config_pvpgn.sh start d2gs

    Echo_Red "Docker pvpgn start"
    docker exec -it pvpgn /bin/bash /home/pvpgn/config_pvpgn.sh start

    Echo_Red "Docker Restart_GSs"
    Restart_GSs

    firewall-cmd --permanent --zone=public --add-port=$REALM_PORT/tcp
    firewall-cmd --reload

    ;;
d2gs)

    STRDATE=$(date +%y%m%d_%H%M%S)
    mkdir /home/pvpgn_$STRDATE
    mkdir /home/d2gs_$STRDATE

    docker run -dt --privileged=true -v /home/pvpgn:/home/pvpgn -v /home/d2gs_$STRDATE:/home/d2gs -v /home/D2GS_BASE:/home/D2GS_BASE --name pvpgn-$STRDATE -p $D2GS_OUTIP:4000:4000 wqmeng:pvpgn /bin/bash
    # Update config_pvpgn.sh file
    docker exec -it pvpgn-$STRDATE rm -rf /home/pvpgn/config_pvpgn.sh
    docker exec -it pvpgn-$STRDATE wget -q ${PVPGN_URI}config_pvpgn.sh -O/home/pvpgn/config_pvpgn.sh
    docker exec -it pvpgn-$STRDATE chmod +x /home/pvpgn/config_pvpgn.sh

    PVPBN_INNERIP=$(docker inspect pvpgn | grep IPAddress | sed -n '1p' | cut -d '"' -f 4)
    D2GS_INNERIP=$(docker inspect pvpgn-$STRDATE | grep IPAddress | sed -n '1p' | cut -d '"' -f 4)
    CID=$(docker ps -a | grep pvpgn-$STRDATE | cut -d ' ' -f 1)
    yq e -i '.pvpgn.realms[] |= select(.name == "'$REALM_NAME'").d2gs += [{"cid":"'$CID'","innerIP":"'$D2GS_INNERIP'","outIP":"'$D2GS_OUTIP'","port":4000,"d2csIP":"'$PVPBN_INNERIP'","d2dbsIP":"'$PVPBN_INNERIP'","path":"'$STRDATE'","AdminPwd":"'$AdminPwd'"}]' $PVPGN_YAML

    # Echo_Red "Docker pvpgn setup pvpgn"
    # docker exec -it pvpgn /bin/bash /home/pvpgn/config_pvpgn.sh setup pvpgn
    Echo_Red "docker pvpgn-$STRDATE setup d2gs"
    docker exec -it pvpgn-$STRDATE /bin/bash /home/pvpgn/config_pvpgn.sh setup d2gs
    Echo_Red "docker pvpgn start"
    docker exec -it pvpgn /bin/bash /home/pvpgn/config_pvpgn.sh start
    # Echo_Red "docker pvpgn-$STRDATE start d2gs"
    # docker exec -it pvpgn-$STRDATE /bin/bash /home/pvpgn/config_pvpgn.sh start d2gs

    Restart_GSs

    ;;
help | -h | -help)
    Echo_Red "Usage: $0 {pvpgn|realm|d2gs}"
    echo "Storage: plain cdb mysql mariaDB pgsql sqlite3"
    echo "Diablo2: 1.13d 1.13c 1.11b 1.09d"
    Echo_Red "$0 pvpgn plain realm_name 1.13c"
    Echo_Red "$0 realm realm_name 1.11b"
    Echo_Red "$0 d2gs exist_realm # will detect a new output IP for new d2gs"

    ;;
*)
    Dispaly_Selection
    ;;
esac

Print_Sucess_Info
