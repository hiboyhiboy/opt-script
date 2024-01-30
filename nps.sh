#!/bin/bash
#NEW_VER_version="v0.27.01"
# https://github.com/yisier/nps

# If not specify, default meaning of return value:
# 0: Success
# 1: System error
# 2: Application error
# 3: Network error

CUR_VER=""
NEW_VER=""
ARCH=""
VDIS="64"
ZIPFILE="/tmp/nps/nps.tar.gz"
nps_RUNNING=0
VSRC_ROOT="/tmp/nps"
EXTRACT_ONLY=0

CMD_INSTALL=""
CMD_UPDATE=""
SOFTWARE_UPDATED=0

SYSTEMCTL_CMD=$(command -v systemctl 2>/dev/null)
SERVICE_CMD=$(command -v service 2>/dev/null)

CHECK=""
FORCE=""
HELP=""

#######color code########
RED="31m"      # Error message
GREEN="32m"    # Success message
YELLOW="33m"   # Warning message
BLUE="36m"     # Info message
magenta="35m"

colorEcho(){
    COLOR=$1
    echo -e "\033[${COLOR}${@:2}\033[0m"
}


#########################
while [[ $# > 0 ]];do
    key="$1"
    case $key in
        -p|--proxy)
        PROXY="-x ${2}"
        shift # past argument
        ;;
        -h|--help)
        HELP="1"
        ;;
        -f|--force)
        FORCE="1"
        ;;
        -c|--check)
        CHECK="1"
        ;;
        --remove)
        REMOVE="1"
        ;;
        --version)
        VERSION="$2"
        shift
        ;;
        --extract)
        VSRC_ROOT="$2"
        shift
        ;;
        --extractonly)
        EXTRACT_ONLY="1"
        ;;
        -l|--local)
        LOCAL="$2"
        LOCAL_INSTALL="1"
        shift
        ;;
        *)
                # unknown option
        ;;
    esac
    shift # past argument or value
done

###############################

[ ! -z "$( alias | grep 'alias cp=')" ] &&  unalias cp
[ ! -z "$( alias | grep 'alias mv=')" ] &&  unalias mv
[ ! -z "$( alias | grep 'alias rm=')" ] &&  unalias rm
#set -x
if [[ $# = 0 ]]; then
    # Get Public IP address
    ipc=$(ip addr | egrep -o '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | egrep -v "^192\.168|^172\.1[6-9]\.|^172\.2[0-9]\.|^172\.3[0-2]\.|^10\.|^127\.|^255\.|^0\." | head -n 1)
    if [[ "$IP" = "" ]]; then
        ipc=$(wget -qO- -t1 -T2 ipv4.icanhazip.com)
    fi
    colorEcho ${BLUE} 'nps 输入数字继续一键安装'
    while :; do echo
        colorEcho ${BLUE} "【最新安装 + 重新生成配置】请输入1"
        colorEcho ${BLUE} "【重新生成配置】请输入2"
        colorEcho ${BLUE} "【更新nps】请输入0"
        colorEcho ${BLUE} "【删除nps】请输入3"
        read -p "$(colorEcho ${BLUE} "输入数字继续:")" up_vv
        if [[ ! $up_vv =~ ^[0-2]$ ]]; then
            if [[ $up_vv == 3 ]]; then
                REMOVE="1"
                break
            fi
            colorEcho ${RED} "${CWARNING}输入错误! 请输入正确的数字!${CEND}"
        else
            SEED=`tr -cd a-b0-9 </dev/urandom | head -c 8`
            read -p "$(colorEcho ${BLUE} "输入web管理界面 username（默认：$SEED ）:")" web_user
            [ -z "$web_user" ] && web_user=$SEED
            SEED=`tr -cd a-b0-9 </dev/urandom | head -c 8`
            read -p "$(colorEcho ${BLUE} "输入web管理界面 password（默认：$SEED ）:")" web_pass
            [ -z "$web_pass" ] && web_pass=$SEED
            SEED=`tr -cd 0-9 </dev/urandom | head -c 8`
            web_port_x=`echo $SEED 40000 50000|awk '{srand($1);printf "%d",rand()*10000%($3-$2)+$2}'`
            read -p "$(colorEcho ${BLUE} "输入web管理界面 web port（默认：$web_port_x ）:")" web_port
            [ -z "$web_port" ] && web_port=$web_port_x
            SEED=`tr -cd 0-9 </dev/urandom | head -c 8`
            bridge_port_x=`echo $SEED 50001 60000|awk '{srand($1);printf "%d",rand()*10000%($3-$2)+$2}'`
            read -p "$(colorEcho ${BLUE} "输入网桥端口，用于客户端与服务器通信 bridge port（默认：$bridge_port_x ）:")" bridge_port
            [ -z "$bridge_port" ] && bridge_port=$bridge_port_x
            colorEcho ${BLUE} '服务端配置文件在 /root/nps/conf/nps.conf'
            colorEcho ${BLUE} '客户端配置文件在 /usr/bin/nps/npc.txt'
            colorEcho ${BLUE} "#网桥端口 bridge_port= $bridge_port"
            colorEcho ${BLUE} "#web管理界面 username= $web_user"
            colorEcho ${BLUE} "#web管理界面 password= $web_pass"
            colorEcho ${BLUE} "#web管理界面 web port= $web_port"
            colorEcho ${BLUE} "#web管理界面      $ipc:$web_port"
            colorEcho ${BLUE} "#有时需要手动设置外网访问端口"
            colorEcho ${magenta} "iptables -I INPUT -p tcp --dport $web_port -j ACCEPT"
            [ ! -z "$bridge_port" ] && colorEcho ${magenta} "iptables -I INPUT -p tcp --dport $bridge_port -j ACCEPT"
            break
        fi
    done
    echo ''
    if [[ $up_vv == '0' ]];then
		FORCE="1"
    fi
    if [[ $up_vv == '1' ]] || [[ $up_vv == '2' ]];then
		nps_RUNNING=1
		REMOVE=2
		if [[ -d "/usr/bin/nps/conf" ]]; then
			colorEcho ${YELLOW} "检测到旧配置！！！"
			colorEcho ${YELLOW} "【备份旧配置到/root/nps_back/conf】请输入1"
			colorEcho ${YELLOW} "【放弃旧配置】请输入2"
			read -p "$(colorEcho ${BLUE} "输入数字继续（默认1）:")" up_vvv
			[ -z "$up_vvv" ] && up_vvv='1'
			if [[ $up_vvv != '2' ]];then
				TIME=$(date "+%Y-%m-%d_%H-%M-%S")
				colorEcho ${GREEN} '备份旧配置到/root/nps_back/conf'
				rm -rf /root/nps_back/conf_$TIME/*
				mkdir -p /root/nps_back/conf_$TIME
				cp -r -f -a /root/nps/conf/* /root/nps_back/conf_$TIME
			else
				colorEcho ${GREEN} '放弃旧配置'
			fi
		fi
    fi
fi
###############################
sysArch(){
    ARCH=$(uname -m)
    if [[ "$ARCH" == "i686" ]] || [[ "$ARCH" == "i386" ]]; then
        VDIS="linux_386_server.tar.gz"
    elif [[ "$ARCH" == *"armv7"* ]] || [[ "$ARCH" == "armv6l" ]]; then
        VDIS="linux_arm_server.tar.gz"
    elif [[ "$ARCH" == *"armv8"* ]] || [[ "$ARCH" == "aarch64" ]]; then
        VDIS="linux_arm64_server.tar.gz"
    elif [[ "$ARCH" == *"mips64le"* ]]; then
        VDIS="linux_mips64le_server.tar.gz"
    elif [[ "$ARCH" == *"mips64"* ]]; then
        VDIS="linux_mips64_server.tar.gz"
    elif [[ "$ARCH" == *"mipsle"* ]]; then
        VDIS="linux_mipsle_server.tar.gz"
    elif [[ "$ARCH" == *"mips"* ]]; then
        VDIS="linux_mips_server.tar.gz"
    elif [[ "$ARCH" == *"s390x"* ]]; then
        VDIS="s390x"
    elif [[ "$ARCH" == *"x86_64"* ]]; then
        VDIS="linux_amd64_server.tar.gz"
    fi
    return 0
}

downloadnps(){
    rm -rf /tmp/nps
    mkdir -p /tmp/nps
    colorEcho ${BLUE} "Downloading nps."
    DOWNLOAD_LINK="https://github.com/yisier/nps/releases/download/${NEW_VER}/${VDIS}"
    rm -f $ZIPFILE
    curl ${PROXY} -L -H "Cache-Control: no-cache" -o ${ZIPFILE} ${DOWNLOAD_LINK}
    if [ $? != 0 ];then
        if [ ! -s "$ZIPFILE" ] ; then
            rm -f $ZIPFILE
            wget -O $ZIPFILE $DOWNLOAD_LINK
        fi
        if [ $? != 0 ];then
            colorEcho ${RED} "Failed to download! Please check your network or try again."
            rm -f $ZIPFILE
            return 3
        fi
    fi
    return 0
}

installSoftware(){
    COMPONENT=$1
    if [[ -n `command -v $COMPONENT` ]]; then
        return 0
    fi

    getPMT
    if [[ $? -eq 1 ]]; then
        colorEcho ${RED} "The system package manager tool isn't APT or YUM, please install ${COMPONENT} manually."
        return 1 
    fi
    colorEcho $GREEN "Installing $COMPONENT" 
    if [[ $SOFTWARE_UPDATED -eq 0 ]]; then
        colorEcho ${BLUE} "Updating software repo"
        $CMD_UPDATE      
        SOFTWARE_UPDATED=1
    fi

    colorEcho ${BLUE} "Installing ${COMPONENT}"
    $CMD_INSTALL $COMPONENT
    if [[ $? -ne 0 ]]; then
        if [[ "$COMPONENT" == "daemon" ]]; then
            colorEcho ${YELLOW} "Install ${COMPONENT} fail, install /root/keey.sh"
        return 0
        else
            colorEcho ${RED} "Failed to install ${COMPONENT}. Please install it manually."
            return 1
        fi
    fi
    return 0
}

# return 1: not apt, yum, or zypper
getPMT(){
    if [[ -n `command -v apt-get` ]];then
        CMD_INSTALL="apt-get -y -qq install"
        CMD_UPDATE="apt-get -qq update"
    elif [[ -n `command -v yum` ]]; then
        CMD_INSTALL="yum -y -q install"
        CMD_UPDATE="yum -q makecache"
    elif [[ -n `command -v zypper` ]]; then
        CMD_INSTALL="zypper -y install"
        CMD_UPDATE="zypper ref"
    else
        return 1
    fi
    return 0
}


extract(){
    colorEcho ${BLUE}"Extracting nps package to /tmp/nps."
    mkdir -p /tmp/nps
    tar -xz -C ${VSRC_ROOT} -f $1
    if [[ $? -ne 0 ]]; then
        colorEcho ${RED} "Failed to extract nps."
        return 2
    fi
    if [[ -d "/tmp/nps/nps" ]]; then
      VSRC_ROOT="/tmp/nps/nps"
    fi
    return 0
}


# 1: new nps. 0: no. 2: not installed. 3: check failed. 4: don't check.
getVersion(){
    if [[ -n "$VERSION" ]]; then
        NEW_VER="$VERSION"
        if [[ ${NEW_VER} != v* ]]; then
          NEW_VER=v${NEW_VER}
        fi
        return 4
    else
        rm -f /tmp/nps_v.txt
        if [[ -f "/usr/bin/nps/nps" ]]; then
            /usr/bin/nps/nps 2>&1 > /tmp/nps_v.txt &
            sleep 2
            killall nps
        fi
        VER="$(cat /tmp/nps_v.txt | grep version | awk -F ',' '{print $1}'  | awk -F ' ' '{print $NF}')"
        CUR_VER=v"$VER"
        TAG_URL="https://api.github.com/repos/yisier/nps/releases/latest "
        NEW_VER=`curl ${PROXY} -s ${TAG_URL} --connect-timeout 10| grep 'tag_name' | cut -d\" -f4`
        if [[ $NEW_VER == "" ]];then
            NEW_VER="$NEW_VER_version"
        fi
        if [[ $? -ne 0 ]] || [[ $NEW_VER == "" ]]; then
            colorEcho ${RED} "Failed to fetch release information. Please check your network or try again."
            return 3
        elif [[ $VER == "" ]];then
            return 2
        elif [[ "$NEW_VER" != "$CUR_VER" ]];then
            return 1
        fi
        return 0
    fi
}

stopnps(){
    colorEcho ${BLUE} "Shutting down nps service."
    if [[ -n "${SYSTEMCTL_CMD}" ]] || [[ -f "/lib/systemd/system/nps.service" ]] || [[ -f "/etc/systemd/system/nps.service" ]]; then
        ${SYSTEMCTL_CMD} stop nps
    RETVAL1="$?"
    fi
    if [[ -n "${SERVICE_CMD}" ]] || [[ -f "/etc/init.d/nps" ]]; then
        ${SERVICE_CMD} nps stop
    RETVAL2="$?"
    fi
    if [[ $RETVAL1 -ne 0 ]] && [[ $RETVAL2 -ne 0 ]]; then
        colorEcho ${YELLOW} "Failed to shutdown nps service."
        return 2
    fi
    return 0
}

startnps(){
    if [ -n "${SYSTEMCTL_CMD}" ] && [ -f "/lib/systemd/system/nps.service" ]; then
        ${SYSTEMCTL_CMD} start nps
    elif [ -n "${SYSTEMCTL_CMD}" ] && [ -f "/etc/systemd/system/nps.service" ]; then
        ${SYSTEMCTL_CMD} start nps
    elif [ -n "${SERVICE_CMD}" ] && [ -f "/etc/init.d/nps" ]; then
        ${SERVICE_CMD} nps start
    fi
    if [[ $? -ne 0 ]]; then
        colorEcho ${YELLOW} "Failed to start nps service."
        return 2
    fi
    return 0
}

copyFile() {
    NAME=$1
    ERROR=`cp "${VSRC_ROOT}/${NAME}" "/usr/bin/nps/${NAME}" 2>&1`
    if [[ $? -ne 0 ]]; then
        colorEcho ${YELLOW} "${ERROR}"
        return 1
    fi
    return 0
}

makeExecutable() {
    chmod +x "/usr/bin/nps/$1"
}

installnps(){

    # Install nps binary to /usr/bin/nps
    mkdir -p /usr/bin/nps
    rm -rf /root/nps
    ln -sf /usr/bin/nps /root/nps
    copyFile nps
    if [[ $? -ne 0 ]]; then
        colorEcho ${RED} "Failed to copy nps binary and resources."
        return 1
    fi
    makeExecutable nps
    rm -rf "/usr/bin/nps/web"
    cp -rf "${VSRC_ROOT}/web" "/usr/bin/nps/"
    # Install nps server config to /etc/nps
    if [[ ! -f "/usr/bin/nps/conf/nps.conf" ]]; then
        mkdir -p /usr/bin/nps/conf
        cp -rf "${VSRC_ROOT}/conf" "/usr/bin/nps/"

    cat > "/usr/bin/nps/conf/nps.conf" <<-\EEE
#web管理界面
web_host=
web_username=admin
web_password=123
web_port=8123
web_ip=0.0.0.0

##服务端客户端通信
bridge_type=tcp
bridge_port=8284
bridge_ip=0.0.0.0

appname = nps
#Boot mode(dev|pro)
runmode = dev

#HTTP(S) proxy port, no startup if empty
#http_proxy_ip=0.0.0.0
#http_proxy_port=80
#https_proxy_port=443
#https_just_proxy=true
#default https certificate setting
#https_default_cert_file=conf/server.pem
#https_default_key_file=conf/server.key

# Public password, which clients can use to connect to the server
# After the connection, the server will be able to open relevant ports and parse related domain names according to its own configuration file.
public_vkey=

#Traffic data persistence interval(minute)
#Ignorance means no persistence
#flow_store_interval=1
# log level LevelEmergency->0  LevelAlert->1 LevelCritical->2 LevelError->3 LevelWarning->4 LevelNotice->5 LevelInformational->6 LevelDebug->7
log_level=7
log_path=/tmp/syslog.log

#Whether to restrict IP access, true or false or ignore
#ip_limit=true

#p2p
#p2p_ip=127.0.0.1
#p2p_port=6000

#web
#web_base_url=
#web_open_ssl=false
#web_cert_file=conf/server.pem
#web_key_file=conf/server.key
# if web under proxy use sub path. like http://host/nps need this.
#web_base_url=/nps

#Web API unauthenticated IP address(the len of auth_crypt_key must be 16)
#Remove comments if needed
#auth_key=test
#auth_crypt_key =1234567812345678

#allow_ports=9001-9009,10001,11000-12000

#Web management multi-user login
allow_user_login=false
allow_user_register=false
allow_user_change_username=false


#extension
allow_flow_limit=false
allow_rate_limit=false
allow_tunnel_num_limit=false
allow_local_proxy=false
allow_connection_num_limit=false
allow_multi_ip=false
system_info_display=true

#cache
http_cache=false
http_cache_length=100

#get origin ip
http_add_origin_header=false

#pprof debug options
#pprof_ip=0.0.0.0
#pprof_port=9999

#client disconnect timeout
disconnect_timeout=60

EEE
    chmod 755 "/usr/bin/nps/conf/nps.conf"
    fi

    return 0
}


installInitScript(){

    cat > "/usr/bin/nps/npc.txt" <<-\EEE
[common]
server_addr=1.1.1.1:8284
conn_type=tcp
vkey=web界面中显示的密钥
auto_reconnection=true

EEE
    chmod 755 "/usr/bin/nps/npc.txt"

    sed -e "s|^\(web_port.*\)=[^=]*$|\1=$web_port|" -i /usr/bin/nps/conf/nps.conf
    sed -e "s|^\(web_username.*\)=[^=]*$|\1=$web_user|" -i /usr/bin/nps/conf/nps.conf
    sed -e "s|^\(web_password.*\)=[^=]*$|\1=$web_pass|" -i /usr/bin/nps/conf/nps.conf
    sed -e "s|^\(bridge_port.*\)=[^=]*$|\1=$bridge_port|" -i /usr/bin/nps/conf/nps.conf

    bridge_port="$(cat /usr/bin/nps/conf/nps.conf | grep bridge_port | awk -F '=' '{print $2}')"
    [ ! -z "$bridge_port" ] && sed -e "s|^\(server_addr.*\)=[^=]*$|\1=$ipc:$bridge_port|" -i /usr/bin/nps/npc.txt

    if [[ -n "${SYSTEMCTL_CMD}" ]];then
        if [[ ! -f "/etc/systemd/system/nps.service" ]]; then
            if [[ ! -f "/lib/systemd/system/nps.service" ]]; then
                check_systemd
                systemctl enable nps.service
            fi
        fi
        return
    elif [[ -n "${SERVICE_CMD}" ]] && [[ ! -f "/etc/init.d/nps" ]]; then
        check_daemon
        chmod +x "/etc/init.d/nps"
        update-rc.d nps defaults
    fi
    return
}


function check_systemd(){

if [ ! -f "/etc/systemd/system/nps.service" ]  ; then
cat > "/etc/systemd/system/nps.service" <<-\NPSinit
[Unit]
Description=nps Service
After=network.target
Wants=network.target

[Service]
Type=simple
PIDFile=/run/nps.pid
ExecStart=/usr/bin/nps/nps
Restart=on-failure
# Don't restart in the case of configuration error
RestartPreventExitStatus=23

[Install]
WantedBy=multi-user.target


NPSinit
chmod 755 /etc/systemd/system/nps.service
fi
}

function check_daemon(){

if [ ! -f "/etc/init.d/nps" ] ; then
rm -f /root/keey.sh /etc/init.d/nps
cat > "/etc/init.d/nps" <<-\NPSinit
#!/bin/sh
### BEGIN INIT INFO
# Provides:          nps
# Required-Start:    $network $local_fs $remote_fs
# Required-Stop:     $remote_fs
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: nps proxy services
# Description:       nps proxy services
### END INIT INFO

# Acknowledgements: Isulew Li <netcookies@gmail.com>

DESC=nps
NAME=nps
DAEMON=/usr/bin/nps/nps
PIDFILE=/var/run/$NAME.pid
SCRIPTNAME=/etc/init.d/$NAME

DAEMON_OPTS=""

# Exit if the package is not installed
[ -x $DAEMON ] || exit 0

RETVAL=0

check_running(){
    PID=`ps -ef | grep -v grep | grep -i "${DAEMON}" | awk '{print $2}'`
    if [ ! -z $PID ]; then
        return 0
    else
        return 1
    fi
}

do_start(){
    check_running
    if [ $? -eq 0 ]; then
        echo "$NAME (pid $PID) is already running..."
        keep
        exit 0
    else
        cd /usr/bin/nps/
        ntpdate us.pool.ntp.org
        $DAEMON $DAEMON_OPTS &
        RETVAL=$?
        if [ $RETVAL -eq 0 ]; then
            echo "Starting $NAME success"
            keep
        else
            echo "Starting $NAME failed"
        fi
    fi
}

do_stop(){
    check_running
    if [ $? -eq 0 ]; then
        killall keey.sh
        killall nps
        RETVAL=$?
        if [ $RETVAL -eq 0 ]; then
            echo "Stopping $NAME success"
        else
            echo "Stopping $NAME failed"
        fi
    else
        echo "$NAME is stopped"
        RETVAL=1
    fi
}

do_status(){
    check_running
    if [ $? -eq 0 ]; then
        echo "$NAME (pid $PID) is running..."
    else
        echo "$NAME is stopped"
        RETVAL=1
    fi
}

do_restart(){
    do_stop
    do_start
}

keep () {
if [ ! -f "/root/keey.sh" ]; then
cat > "/root/keey.sh" <<-\SSMK
#!/bin/sh
#/usr/bin/nps/nps
sleep 60
service nps start
SSMK
chmod +x "/root/keey.sh"
fi
killall keey.sh
/root/keey.sh &

}


case "$1" in
    start|stop|restart|status)
    do_$1
    ;;
    *)
    echo "Usage: $0 { start | stop | restart | status }"
    RETVAL=1
    ;;
esac

exit $RETVAL


NPSinit
chmod 755 /etc/init.d/nps
fi
}

Help(){
    echo "./install-release.sh [-h] [-c] [--remove] [-p proxy] [-f] [--version vx.y.z] [-l file]"
    echo "  -h, --help            Show help"
    echo "  -p, --proxy           To download through a proxy server, use -p socks5://127.0.0.1:1080 or -p http://127.0.0.1:3128 etc"
    echo "  -f, --force           Force install"
    echo "      --version         Install a particular version, use --version v3.15"
    echo "  -l, --local           Install from a local file"
    echo "      --remove          Remove installed nps"
    echo "  -c, --check           Check for update"
    return 0
}

remove(){
    if [[ -n "${SYSTEMCTL_CMD}" ]] && [[ -f "/etc/systemd/system/nps.service" ]];then
        if pgrep "nps" > /dev/null ; then
            stopnps
        fi
        systemctl disable nps.service
        rm -rf "/usr/bin/nps" "/etc/systemd/system/nps.service"
        if [[ $? -ne 0 ]]; then
            colorEcho ${RED} "Failed to remove nps."
            return 0
        else
            colorEcho ${GREEN} "Removed nps successfully."
            colorEcho ${BLUE} "If necessary, please remove configuration file and log file manually."
            return 0
        fi
    elif [[ -n "${SYSTEMCTL_CMD}" ]] && [[ -f "/lib/systemd/system/nps.service" ]];then
        if pgrep "nps" > /dev/null ; then
            stopnps
        fi
        systemctl disable nps.service
        rm -rf "/usr/bin/nps" "/lib/systemd/system/nps.service"
        if [[ $? -ne 0 ]]; then
            colorEcho ${RED} "Failed to remove nps."
            return 0
        else
            colorEcho ${GREEN} "Removed nps successfully."
            colorEcho ${BLUE} "If necessary, please remove configuration file and log file manually."
            return 0
        fi
    elif [[ -n "${SERVICE_CMD}" ]] && [[ -f "/etc/init.d/nps" ]]; then
        if pgrep "nps" > /dev/null ; then
            stopnps
        fi
        rm -rf "/usr/bin/nps" "/etc/init.d/nps"
        if [[ $? -ne 0 ]]; then
            colorEcho ${RED} "Failed to remove nps."
            return 0
        else
            colorEcho ${GREEN} "Removed nps successfully."
            colorEcho ${BLUE} "If necessary, please remove configuration file and log file manually."
            return 0
        fi       
    else
        colorEcho ${YELLOW} "nps not found."
        return 0
    fi
}

checkUpdate(){
    echo "Checking for update."
    VERSION=""
    getVersion
    RETVAL="$?"
    if [[ $RETVAL -eq 1 ]]; then
        colorEcho ${BLUE} "Found new version ${NEW_VER} for nps.(Current version:$CUR_VER)"
    elif [[ $RETVAL -eq 0 ]]; then
        colorEcho ${BLUE} "No new version. Current version is ${NEW_VER}."
    elif [[ $RETVAL -eq 2 ]]; then
        colorEcho ${YELLOW} "No nps installed."
        colorEcho ${BLUE} "The newest version for nps is ${NEW_VER}."
    fi
    return 0
}

main(){
    #helping information
    [[ "$HELP" == "1" ]] && Help && return
    [[ "$CHECK" == "1" ]] && checkUpdate && return

    if [[ $up_vv != '2' ]]; then

    [[ "$REMOVE" == "1" ]] && remove && return
    [[ "$REMOVE" == "2" ]] && remove

    sysArch
    # extract local file
    if [[ $LOCAL_INSTALL -eq 1 ]]; then
        colorEcho ${YELLOW} "Installing nps via local file. Please make sure the file is a valid nps package, as we are not able to determine that."
        NEW_VER=local
        installSoftware unzip || return $?
        rm -rf /tmp/nps
        extract $LOCAL || return $?
        #FILEVDIS=`ls /tmp/nps |grep nps-v |cut -d "-" -f4`
        #SYSTEM=`ls /tmp/nps |grep nps-v |cut -d "-" -f3`
        #if [[ ${SYSTEM} != "linux" ]]; then
        #    colorEcho ${RED} "The local nps can not be installed in linux."
        #    return 1
        #elif [[ ${FILEVDIS} != ${VDIS} ]]; then
        #    colorEcho ${RED} "The local nps can not be installed in ${ARCH} system."
        #    return 1
        #else
        #    NEW_VER=`ls /tmp/nps |grep nps-v |cut -d "-" -f2`
        #fi
    else
        # download via network and extract
        installSoftware "curl" || return $?
        getVersion
        RETVAL="$?"
        if [[ $RETVAL == 0 ]] && [[ "$FORCE" != "1" ]]; then
            colorEcho ${BLUE} "Latest version ${NEW_VER} is already installed."
            return
        elif [[ $RETVAL == 3 ]]; then
            return 3
        else
            colorEcho ${BLUE} "Installing nps ${NEW_VER} on ${ARCH}"
            downloadnps || return $?
            installSoftware unzip || return $?
            extract ${ZIPFILE} || return $?
        fi
    fi 
    
    if [[ "${EXTRACT_ONLY}" == "1" ]]; then
        colorEcho ${GREEN} "nps extracted to ${VSRC_ROOT}, and exiting..."
        return 0
    fi

    if pgrep "nps" > /dev/null ; then
        nps_RUNNING=1
        stopnps
    fi
    installnps || return $?

    fi

    if pgrep "nps" > /dev/null ; then
        nps_RUNNING=1
        stopnps
    fi
    installInitScript || return $?
    if [[ ${nps_RUNNING} -eq 1 ]];then
        colorEcho ${BLUE} "Restarting nps service."
        startnps
    fi
    colorEcho ${GREEN} "nps ${NEW_VER} is installed."
    rm -rf /tmp/nps
    colorEcho ${BLUE} '配置完成，服务端配置文件在 /root/nps/conf/nps.conf'
    colorEcho ${BLUE} '配置完成，客户端配置文件在 /usr/bin/nps/npc.txt'
    cat /usr/bin/nps/npc.txt
    bridge_port="$(cat /usr/bin/nps/conf/nps.conf | grep bridge_port | awk -F '=' '{print $2}')"
    web_port="$(cat /usr/bin/nps/conf/nps.conf | grep web_port | awk -F '=' '{print $2}')"
    colorEcho ${BLUE} "#网桥端口 bridge_port= $bridge_port"
    colorEcho ${BLUE} "#web管理界面 username= $web_user"
    colorEcho ${BLUE} "#web管理界面 password= $web_pass"
    colorEcho ${BLUE} "#web管理界面 web port= $web_port"
    colorEcho ${BLUE} "#web管理界面      $ipc:$web_port"
    colorEcho ${BLUE} "#有时需要手动设置外网访问端口"
    colorEcho ${magenta} "iptables -I INPUT -p tcp --dport $web_port -j ACCEPT"
    [ ! -z "$bridge_port" ] && colorEcho ${magenta} "iptables -I INPUT -p tcp --dport $bridge_port -j ACCEPT"
    return 0
}

main
