#!/bin/bash
# wget -qO - https://raw.githubusercontent.com/wqmeng/pvpgner/main/src/install.sh | sh -s help
# wget -qO - https://raw.githubusercontent.com/wqmeng/pvpgner/main/src/install.sh | sh <(cat) </dev/tty
# dnf -yq install tmux; tmux new-session -ds pvpgn; tmux send-keys -t pvpgn 'wget -qO - https://raw.githubusercontent.com/wqmeng/pvpgner/main/src/install.sh | sh <(cat) </dev/tty' ENTER; tmux a -t pvpgn;

Color_Text()
{
  echo -e " \e[0;$2m$1\e[0m"
}

Echo_Red()
{
  echo $(Color_Text "$1" "31")
}

Echo_Green()
{
  echo $(Color_Text "$1" "32")
}

Echo_Yellow()
{
  echo $(Color_Text "$1" "33")
}

Echo_Blue()
{
  echo $(Color_Text "$1" "34")
}

Dispaly_Selection()
{

#select install a new pvpgn or add realm or add gs
    echo "==========================="

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
    esac

    if [[ "${ACTSelect}" = "1" ]]; then

    #which MySQL Version do you want to install?
        echo "==========================="

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
        esac

        if [[ "${DBSelect}" = "3" || "${DBSelect}" = "4" || "${DBSelect}" = "5" ]] && [ `free -m | grep Mem | awk '{print  $2}'` -le 1024 ]; then
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
            echo "==========================="

            InstallInnodb="y"
            Echo_Yellow "Do you want to enable or disable the InnoDB Storage Engine?"
            read -p "Default enable,Enter your choice [Y/n]: " InstallInnodb

            case "${InstallInnodb}" in
            [yY][eE][sS]|[yY])
                echo "You will enable the InnoDB Storage Engine"
                InstallInnodb="y"
                ;;
            [nN][oO]|[nN])
                echo "You will disable the InnoDB Storage Engine!"
                InstallInnodb="n"
                ;;
            *)
                echo "No input,The InnoDB Storage Engine will enable."
                InstallInnodb="y"
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

    if  [[ "${ACTSelect}" = "1" || "${ACTSelect}" = "2" ]]; then
        #set realm name and port

        if [ "${ACTSelect}" = "2" ]; then
            REALM_NAME="Realm_Port"
        else
            REALM_NAME="Realm"
        fi

        Echo_Yellow "Please setup Realm name, default is: "$REALM_NAME
        read -p "Please enter: " READ_REALM_NAME
        if [[ "${READ_REALM_NAME}" != "" ]]; then
            REALM_NAME=${READ_REALM_NAME}
        fi
        echo "Your Realm name: ${REALM_NAME}"

        if [ "${ACTSelect}" = "2" ]; then
        # add realm
            USEDPORTS=$(netstat -ntl | grep 'tcp' | grep -v 'tcp6' | cut -d ':' -f2 | cut -d ' ' -f1)

            ARRPORTS=(`echo $USEDPORTS | tr ' ' ' '`)

            REALM_PORT=6113
            
            while [ $REALM_PORT -le 60000 ]
            do
                REALM_PORT=$(expr $REALM_PORT + 100)

                PORTUSED=false

                for i in "${!ARRPORTS[@]}"; do
                    echo "$i: ${ARRPORTS[i]}"
                    if [ "$REALM_PORT" = "${ARRPORTS[i]}" ]; then 
                      PORTUSED=true
                      break
                    fi
                done

                if [ "$PORTUSED" = false ]; then                
                  break
                fi
            done

            # echo $REALM_PORT

        else
            REALM_PORT="6113"
        fi

        Echo_Yellow "Please setup Realm port, default is: "$REALM_PORT
        read -p "Please enter: " READ_REALM_PORT
        if [[ "${READ_REALM_PORT}" != "" ]]; then
            REALM_PORT=${READ_REALM_PORT}
        fi
        if [ "${REALM_NAME}" = "Realm_Port" ]; then
            REALM_NAME="Realm_"${REALM_PORT}
        fi
        echo "Your Realm port: ${REALM_PORT}"
        echo "Your Realm name: ${REALM_NAME}"

        #which D2 Version do you want to install?
        echo "==========================="

        D2Select="2"
        Echo_Yellow "You have 4 options for your Diablo2 GS install."
        echo "1: Install Diablo2 1.13d"
        echo "2: Install Diablo2 1.13c (default)"
        echo "3: Install Diablo2 1.11b"
        echo "4: Install Diablo2 1.09d"
        # echo "5: Install Diablo2 1.10"
        # echo "6: Install Diablo2 1.12a"
        read -p "Enter your choice (1, 2, 3 or 4): " D2Select

        case "${D2Select}" in
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
        # 5)
        #     echo "You will install PHP 5.6.20"
        #     ;;
        # 6)
        #     echo "You will install PHP 7.0.5"
        #     ;;
        *)
            echo "No input,You will install Diablo2 1.13c"
            D2Select=1.13c
        esac
    fi

    if [ "${ACTSelect}" = "3" ]; then
        # We should get all the realm names from a conf file, such as ylmp
        REALM_NAME="Realm"
        Echo_Yellow "Please select which Realm will you add the D2GS to, default is: Realm"
        read -p "Please enter: " REALM_NAME
        if [ "${REALM_NAME}" = "" ]; then
            REALM_NAME="Realm"
        fi
        echo "Your Realm name: ${REALM_NAME}"        
    fi

    if [ "${ACTSelect}" = "1" ]; then
        EXTIP=$(ip a | grep -v 'inet6' | grep 'inet' | grep -v 'host lo' | cut -d'/' -f1 | grep -o '[0-9].*' | grep -v '10.88' | sed -n '1p')

        Echo_Yellow "Please setup Output IP, default is: $EXTIP"
        read -p "Please enter: " READ_EXTIP
        if [ "${READ_EXTIP}" != "" ]; then
            EXTIP=${READ_EXTIP}
        fi
        DDDD=$EXTIP
        echo "Your Output IP: ${EXTIP}"
    else
        EXTIP=$(ip a | grep -v 'inet6' | grep 'inet' | grep -v 'host lo' | cut -d'/' -f1 | grep -o '[0-9].*' | grep -v '10.88' | sed -n '1p')
        ALL_EXTIPS=$(ip a | grep -v 'inet6' | grep 'inet' | grep -v 'host lo' | cut -d'/' -f1 | grep -o '[0-9].*' | grep -v '10.88')
        ALL_USEDIPS=$(netstat -ntl | grep 'tcp' | grep -v 'tcp6' | grep '4000' | cut -d ':' -f1 | tr -s ' ' | cut -d ' ' -f4)

        ARR_ALL_EXTIPS=(`echo $ALL_EXTIPS | tr ' ' ' '`)
        ARR_ALL_USEDIPS=(`echo $ALL_USEDIPS | tr ' ' ' '`)

        for i in "${!ARR_ALL_EXTIPS[@]}"; do
            echo "i: $i: ${ARR_ALL_EXTIPS[i]}"
            IPUSED=false
            for j in "${!ARR_ALL_USEDIPS[@]}"; do
                echo "j: $j: ${ARR_ALL_USEDIPS[j]}"
                if [ "${ARR_ALL_EXTIPS[i]}" = "${ARR_ALL_USEDIPS[j]}" ]; then 
                    IPUSED=true
                    break
                fi
            done

            if [ "${IPUSED}" = false ]; then
                DDDD=${ARR_ALL_EXTIPS[i]}
                break
            fi
        done

        # echo $EXTIP
        Echo_Yellow "Please setup D2GS Output IP, default is: $DDDD"
        read -p "Please enter: " READ_EXTIP
        if [ "${READ_EXTIP}" != "" ]; then
            DDDD=${READ_EXTIP}
        fi
        echo "Your pvpgn IP: ${EXTIP}"
        echo "Your D2GS IP: ${DDDD}"
    fi

    # 
    # str="ONE,TWO,THREE,FOUR"
    # array=(`echo $str | tr ',' ' '`)
    # for i in "${!array[@]}"; do
    #     echo "$i：${array[i]}"
    # done

}

Print_Sucess_Info()
{
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
    echo "|  Default directory: /home/pvpgn                                        |"
    echo "+------------------------------------------------------------------------+"
    echo "|  MySQL/MariaDB root password: ${DB_Root_Password}                      |"
    echo "+------------------------------------------------------------------------+"
    pvngn status
    netstat -ntl
    Echo_Green "Install pvpgn V${EXTIP} completed! enjoy it."
}

PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

# Check if user is root
if [ $(id -u) != "0" ]; then
    echo "Error: You must be root to run this script, please use root to install pvpgn"
    exit 1
fi

cur_dir=$(pwd)

# stack=$1
# if [ "${stack}" = "" ]; then
#     stack=""
# else
#     stack=$1
# fi

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
        # Dispaly_Selection
        ACT="pvpgn"
        DBSelect=$2
        D2Select=$4
        # LNMP_Stack 2>&1 | tee /root/pvpgn-install.log
        ;;
    realm)
        # Dispaly_Selection
        ACT="realm"
        REALM_NAME=$2
        DDDD=$3
        REALM_PORT=$4
        D2Select=$5
        # LNMPA_Stack 2>&1 | tee /root/add-realm.log
        ;;
    d2gs)
        # Dispaly_Selection
        ACT="d2gs"
        REALM_NAME=$2
        # LAMP_Stack 2>&1 | tee /root/add-d2gs.log
        ;;
    help|-h|-help)
        # Dispaly_Selection
        Echo_Red "Usage: $0 {pvpgn|realm|d2gs}"
        echo "Storage: plain cdb mysql mariaDB pgsql sqlite3"
        echo "Diablo2: 1.13d 1.13c 1.11b 1.09d"
        Echo_Red "$0 pvpgn plain realm_name 1.13c"
        Echo_Red "$0 realm realm_name 6213 1.11b"
        Echo_Red "$0 d2gs exist_realm # will detect a new output IP for new d2gs"
        ;;
    *)
        Dispaly_Selection
        # Echo_Red "Usage: $0 {pvpgn|realm|d2gs}"
        ;;
esac

case "${ACT}" in
    pvpgn)
        # Dispaly_Selection
        echo "Pvpgn install is starting ..."
        dnf -yq clean all
        dnf -yq update
        dnf -yq install wget tmux podman
        dnf -yq install --assumeyes epel-release
        dnf -yq install --assumeyes p7zip
        dnf -yq install shyaml
        touch /etc/containers/nodocker
        systemctl enable --now podman
        mkdir -p /home/pvpgn/
        cd /home
        wget -q https://github.com/wqmeng/pvpgner/raw/main/pvpgn/pvpgn1.99.8.0.0-rc1-PRO.7z
        7za x -y pvpgn1.99.8.0.0-rc1-PRO.7z
        \cp -r /home/pvpgn1.99.8.0.0-rc1-PRO/var /home/pvpgn
        rm pvpgn1.99.8.0.0-rc1-PRO* -rf

        if [ ! -f "/home/d2gs_base/d2data.mpq" ]; then
            mkdir -p /home/d2gs_base
            cd /home/d2gs_base
            wget -q https://ia801809.us.archive.org/29/items/d2gs-base.-7z/D2GS_Base.7z
            7za x -y D2GS_Base.7z
            mv D2GS_Base/* .
            rm D2GS_Base -rf
            rm D2GS_Base.7z -rf
        fi

        wget -qO - https://raw.githubusercontent.com/wqmeng/pvpgner/main/src/build_docker.sh | sh

        docker ps
        docker stop pvpgn
        docker ps
        docker rm pvpgn
        docker ps -a
        # 后台创建

        if [ -z ${EXTIP} ]; then
          EXTIP=$(ip a | grep -v 'inet6' | grep 'inet' | grep -v 'host lo' | cut -d'/' -f1 | grep -o '[0-9].*' | sed -n '1p')
        fi
        docker run -dt --privileged=true -v /home/pvpgn/var:/home/pvpgn/var -v /home/d2gs_base:/home/d2gs_base --name pvpgn -p $EXTIP:6112:6112 -p $EXTIP:6112:6112/udp -p $EXTIP:6113:6113 -p $EXTIP:4000:4000 wqmeng:pvpgn /bin/bash
        # 登录容器修改配置
        # Start pvpgn
        docker exec -it pvpgn rm -rf /home/pvpgn/config_pvpgn.sh
        docker exec -it pvpgn wget -q https://raw.githubusercontent.com/wqmeng/pvpgner/main/src/config_pvpgn.sh -O/home/pvpgn/config_pvpgn.sh
        docker exec -it pvpgn chmod +x /home/pvpgn/config_pvpgn.sh
        docker exec -it pvpgn /bin/bash /home/pvpgn/config_pvpgn.sh setup pvpgn $EXTIP $REALM_NAME 6113 $D2Select
        docker exec -it -w /home/pvpgn pvpgn /bin/bash /home/pvpgn/config_pvpgn.sh start

        # Start D2GS
        # docker exec -it pvpgn pkill -f 'D2GS'
        # docker exec -d -w /home/d2gs pvpgn wine D2GS.exe # Not sure why D2GS.exe can not start up and running as PvPGNConsole from config_pvpgn.sh start command. 
        # docker exec -it pvpgn tmux new -s pvpgn /home/pvpgn/config_pvpgn.sh start

        # LNMP_Stack 2>&1 | tee /root/pvpgn-install.log

        firewall-cmd --permanent --zone=public --add-port=6112/tcp
        firewall-cmd --permanent --zone=public --add-port=6112/udp
        firewall-cmd --permanent --zone=public --add-port=6113/tcp
        firewall-cmd --permanent --zone=public --add-port=6114/tcp

        firewall-cmd --permanent --zone=public --add-port=4000/tcp

        firewall-cmd --reload
        # firewall-cmd --query-port=6112/tcp

        firewall-cmd --list-all
        # firewall-cmd --list-all-zones

        ;;
    realm)
        # Add realm to pvpgn
        # docker run -dt --name pvpgn -p $DDDD:$REALM_PORT:$REALM_PORT wqmeng:pvpgn /bin/bash

        echo 'Add realm to pvpgn'

        docker exec -it pvpgn /bin/bash /home/pvpgn/config_pvpgn.sh realm $REALM_NAME ${REALM_PORT} $D2Select $DDDD
        
        # Create a new d2gs container for the new realm and point the 4000 port.
        docker run -dt --privileged=true -v /home/d2gs_base:/home/d2gs_base --name pvpgn-$REALM_NAME -p $DDDD:$REALM_PORT:$REALM_PORT -p $DDDD:4000:4000 wqmeng:pvpgn /bin/bash
        # 登录容器修改配置
        # Create a new container, and run d2gs for the new realm.

        # Setup_d2cs '/home/pvpgn' $REALM_NAME ${DDDD} ${D2CS_PORT} ${AAAA}
        # Setup_d2dbs '/home/pvpgn' ${DDDD}
        # docker exec -it pvpgn /bin/bash /home/pvpgn/config_pvpgn.sh setup d2cs $EXTIP $REALM_NAME ${REALM_PORT} $D2Select
        REALM_INNERIP=$(docker inspect pvpgn-$REALM_NAME | grep IPAddress | sed -n '1p' | cut -d '"' -f 4)

        docker exec -it pvpgn /bin/bash /home/pvpgn/config_pvpgn.sh setup d2cs $REALM_INNERIP $REALM_NAME ${REALM_PORT} $D2Select
        docker exec -it pvpgn /bin/bash /home/pvpgn/config_pvpgn.sh setup d2dbs $REALM_INNERIP $REALM_NAME 6114 $D2Select

        docker exec -it pvpgn-$REALM_NAME /bin/bash /home/pvpgn/config_pvpgn.sh d2gs $D2Select

        # docker exec -it pvpgn /bin/bash /home/pvpgn/config_pvpgn.sh setup d2dbs $EXTIP $REALM_NAME 6114 $D2Select
        # docker exec -it pvpgn /bin/bash /home/pvpgn/config_pvpgn.sh d2gs $D2Select

        # LNMPA_Stack 2>&1 | tee /root/add-realm.log
        ;;
    d2gs)
        # Dispaly_Selection
        docker run -dt --privileged=true -v /home/d2gs_base:/home/d2gs_base --name pvpgn-$REALM_NAME -p $DDDD:$REALM_PORT:$REALM_PORT -p $DDDD:4000:4000 wqmeng:pvpgn /bin/bash

        REALM_INNERIP=$(docker inspect pvpgn-$REALM_NAME | grep IPAddress | sed -n '1p' | cut -d '"' -f 4)
        
        docker exec -it pvpgn /bin/bash /home/pvpgn/config_pvpgn.sh setup d2cs $REALM_INNERIP $REALM_NAME ${REALM_PORT} $D2Select
        docker exec -it pvpgn /bin/bash /home/pvpgn/config_pvpgn.sh setup d2dbs $REALM_INNERIP $REALM_NAME 6114 $D2Select

        docker exec -it pvpgn-$REALM_NAME /bin/bash /home/pvpgn/config_pvpgn.sh d2gs $D2Select
        # LAMP_Stack 2>&1 | tee /root/add-d2gs.log
        ;;
    help|-h|-help)
        # Dispaly_Selection
        Echo_Red "Usage: $0 {pvpgn|realm|d2gs}"
        echo "Storage: plain cdb mysql mariaDB pgsql sqlite3"
        echo "Diablo2: 1.13d 1.13c 1.11b 1.09d"
        Echo_Red "$0 pvpgn plain realm_name 1.13c"
        Echo_Red "$0 realm realm_name 1.11b"
        Echo_Red "$0 d2gs exist_realm # will detect a new output IP for new d2gs"
        ;;
    *)
        Dispaly_Selection
        # Echo_Red "Usage: $0 {pvpgn|realm|d2gs}"
        ;;
esac

Print_Sucess_Info