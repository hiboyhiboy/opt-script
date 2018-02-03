#!/bin/bash

# This file is accessible as https://install.direct/go.sh
# Original source is located at github.com/v2ray/v2ray-core/release/install-release.sh

CUR_VER=""
NEW_VER=""
ARCH=""
VDIS="64"
ZIPFILE="/tmp/v2ray/v2ray.zip"
V2RAY_RUNNING=0

CMD_INSTALL=""
CMD_UPDATE=""
SOFTWARE_UPDATED=0

CHECK=""
FORCE=""
HELP=""

#######color code########
RED="31m"
GREEN="32m"
YELLOW="33m"
BLUE="36m"


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
colorEcho(){
    COLOR=$1
    echo -e "\033[${COLOR}${@:2}\033[0m"
}

sysArch(){
    ARCH=$(uname -m)
    if [[ "$ARCH" == "i686" ]] || [[ "$ARCH" == "i386" ]]; then
        VDIS="32"
    elif [[ "$ARCH" == *"armv7"* ]] || [[ "$ARCH" == "armv6l" ]]; then
        VDIS="arm"
    elif [[ "$ARCH" == *"armv8"* ]] || [[ "$ARCH" == "aarch64" ]]; then
        VDIS="arm64"
    elif [[ "$ARCH" == *"mips64le"* ]]; then
        VDIS="mips64le"
    elif [[ "$ARCH" == *"mips64"* ]]; then
        VDIS="mips64"
    elif [[ "$ARCH" == *"mipsle"* ]]; then
        VDIS="mipsle"
    elif [[ "$ARCH" == *"mips"* ]]; then
        VDIS="mips"
    elif [[ "$ARCH" == *"s390x"* ]]; then
        VDIS="s390x"
    fi
    return 0
}

downloadV2Ray(){
    rm -rf /tmp/v2ray
    mkdir -p /tmp/v2ray
    colorEcho ${BLUE} "Downloading V2Ray."
    DOWNLOAD_LINK="https://github.com/v2ray/v2ray-core/releases/download/${NEW_VER}/v2ray-linux-${VDIS}.zip"
    curl ${PROXY} -L -H "Cache-Control: no-cache" -o ${ZIPFILE} ${DOWNLOAD_LINK}
    if [ $? != 0 ];then
        colorEcho ${RED} "Failed to download! Please check your network or try again."
        exit 1
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
        colorEcho $YELLOW "The system package manager tool isn't APT or YUM, please install ${COMPONENT} manually."
        exit 
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
	    else
	        colorEcho ${RED} "Install ${COMPONENT} fail, please install it manually."
	        exit
	    fi
    fi
    return 0
}

# return 1: not apt or yum
getPMT(){
    if [[ -n `command -v apt-get` ]];then
        CMD_INSTALL="apt-get -y -qq install"
        CMD_UPDATE="apt-get -qq update"
    elif [[ -n `command -v yum` ]]; then
        CMD_INSTALL="yum -y -q install"
        CMD_UPDATE="yum -q makecache"
    else
        return 1
    fi
    return 0
}


extract(){
    colorEcho ${BLUE}"Extracting V2Ray package to /tmp/v2ray."
    mkdir -p /tmp/v2ray
    unzip $1 -d "/tmp/v2ray/"
    if [[ $? -ne 0 ]]; then
        colorEcho ${RED} "Extracting V2Ray faile!"
        exit
    fi
    return 0
}


# 1: new V2Ray. 0: no
getVersion(){
    if [[ -n "$VERSION" ]]; then
        NEW_VER="$VERSION"
        return 1
    else
        CUR_VER=`/usr/bin/v2ray/v2ray -version 2>/dev/null | head -n 1 | cut -d " " -f2`
        TAG_URL="https://api.github.com/repos/v2ray/v2ray-core/releases/latest"
        NEW_VER=`curl ${PROXY} -s ${TAG_URL} --connect-timeout 10| grep 'tag_name' | cut -d\" -f4`

        if [[ $? -ne 0 ]] || [[ $NEW_VER == "" ]]; then
            colorEcho ${RED} "Network error! Please check your network or try again."
            exit
        elif [[ "$NEW_VER" != "$CUR_VER" ]];then
                return 1
        fi
        return 0
    fi
}

stopV2ray(){
    SYSTEMCTL_CMD=$(command -v systemctl)
    SERVICE_CMD=$(command -v service)

    colorEcho ${BLUE} "Shutting down V2Ray service."
    if [[ -n "${SYSTEMCTL_CMD}" ]] || [[ -f "/lib/systemd/system/v2ray.service" ]] || [[ -f "/etc/systemd/system/v2ray.service" ]]; then
        ${SYSTEMCTL_CMD} stop v2ray
    elif [[ -n "${SERVICE_CMD}" ]] || [[ -f "/etc/init.d/v2ray" ]]; then
        ${SERVICE_CMD} v2ray stop
    fi
    return 0
}

startV2ray(){
    SYSTEMCTL_CMD=$(command -v systemctl)
    SERVICE_CMD=$(command -v service)

    if [ -n "${SYSTEMCTL_CMD}" ] && [ -f "/lib/systemd/system/v2ray.service" ]; then
        ${SYSTEMCTL_CMD} start v2ray
    elif [ -n "${SYSTEMCTL_CMD}" ] && [ -f "/etc/systemd/system/v2ray.service" ]; then
        ${SYSTEMCTL_CMD} start v2ray
    elif [ -n "${SERVICE_CMD}" ] && [ -f "/etc/init.d/v2ray" ]; then
        ${SERVICE_CMD} v2ray start
    fi
    return 0
}

copyFile() {
    NAME=$1
    MANDATE=$2
    ERROR=`cp "/tmp/v2ray/v2ray-${NEW_VER}-linux-${VDIS}/${NAME}" "/usr/bin/v2ray/${NAME}"`
    if [[ $? -ne 0 ]]; then
        colorEcho ${YELLOW} "${ERROR}"
        if [ "$MANDATE" = true ]; then
            exit
        fi
    fi
}

makeExecutable() {
    chmod +x "/usr/bin/v2ray/$1"
}

installV2Ray(){
    # Install V2Ray binary to /usr/bin/v2ray
    mkdir -p /usr/bin/v2ray
    copyFile v2ray true
    makeExecutable v2ray
    copyFile v2ctl false
    makeExecutable v2ctl
    copyFile geoip.dat false
    copyFile geosite.dat false

    # Install V2Ray server config to /etc/v2ray
    mkdir -p /etc/v2ray
    if [[ ! -f "/etc/v2ray/config.json" ]]; then
      cp "/tmp/v2ray/v2ray-${NEW_VER}-linux-${VDIS}/vpoint_vmess_freedom.json" "/etc/v2ray/config.json"
      if [[ $? -ne 0 ]]; then
          colorEcho ${YELLOW} "Create V2Ray configuration file error, pleases create it manually."
          return 1
      fi
      let PORT=$RANDOM+10000
      UUID=$(cat /proc/sys/kernel/random/uuid)

      sed -i "s/10086/${PORT}/g" "/etc/v2ray/config.json"
      sed -i "s/23ad6b10-8d1a-40f7-8ad0-e3e35cd38297/${UUID}/g" "/etc/v2ray/config.json"

      colorEcho ${GREEN} "PORT:${PORT}"
      colorEcho ${GREEN} "UUID:${UUID}"
      mkdir -p /var/log/v2ray
    fi
    return 0
}


installInitScrip(){
    SYSTEMCTL_CMD=$(command -v systemctl)
    SERVICE_CMD=$(command -v service)

    if [[ -n "${SYSTEMCTL_CMD}" ]];then
        if [[ ! -f "/etc/systemd/system/v2ray.service" ]]; then
            if [[ ! -f "/lib/systemd/system/v2ray.service" ]]; then
                cp "/tmp/v2ray/v2ray-${NEW_VER}-linux-${VDIS}/systemd/v2ray.service" "/etc/systemd/system/"
                systemctl enable v2ray.service
            fi
        fi
        return
    elif [[ -n "${SERVICE_CMD}" ]] && [[ ! -f "/etc/init.d/v2ray" ]]; then
        installSoftware "daemon"
	daemon_x=0
	hash start-stop-daemon 2>/dev/null || daemon_x=1
	if [ "$daemon_x" = "1" ] ; then
		rm -f /etc/init.d/v2ray
		check_daemon
	else
	        cp "/tmp/v2ray/v2ray-${NEW_VER}-linux-${VDIS}/systemv/v2ray" "/etc/init.d/v2ray"
	        chmod +x "/etc/init.d/v2ray"
	        update-rc.d v2ray defaults
	fi
    fi
    return
}

function check_daemon(){
hash start-stop-daemon 2>/dev/null || daemon_x=1
echo $daemon_x
if [ ! -f "/etc/init.d/v2ray" ] || [ "$daemon_x" = "1" ] ; then
rm -f /root/keey.sh /etc/init.d/v2ray
cat > "/etc/init.d/v2ray" <<-\VVRinit
#!/bin/sh
### BEGIN INIT INFO
# Provides:          v2ray
# Required-Start:    $network $local_fs $remote_fs
# Required-Stop:     $remote_fs
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: V2Ray proxy services
# Description:       V2Ray proxy services
### END INIT INFO

# Acknowledgements: Isulew Li <netcookies@gmail.com>

DESC=v2ray
NAME=v2ray
DAEMON=/usr/bin/v2ray/v2ray
PIDFILE=/var/run/$NAME.pid
SCRIPTNAME=/etc/init.d/$NAME

DAEMON_OPTS="-config /etc/v2ray/config.json"

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
        cd /usr/bin/v2ray/
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
        killall v2ray
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
#/usr/bin/v2ray/v2ray
sleep 60
service v2ray start
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


VVRinit

chmod 755 /etc/init.d/v2ray

fi


}

Help(){
    echo "./install-release.sh [-h] [-c] [-p proxy] [-f] [--version vx.y.z] [-l file]"
    echo "  -h, --help            Show help"
    echo "  -p, --proxy           To download through a proxy server, use -p socks5://127.0.0.1:1080 or -p http://127.0.0.1:3128 etc"
    echo "  -f, --force           Force install"
    echo "      --version         Install a particular version"
    echo "  -l, --local           Install from a local file"
    echo "      --remove          Remove installed V2Ray"
    echo "  -c, --check           Check for update"
    exit  
}

remove(){
    SYSTEMCTL_CMD=$(command -v systemctl)
    SERVICE_CMD=$(command -v service)
    if [[ -n "${SYSTEMCTL_CMD}" ]] && [[ -f "/etc/systemd/system/v2ray.service" ]];then
        if pgrep "v2ray" > /dev/null ; then
            stopV2ray
        fi
        systemctl disable v2ray.service
        rm -rf "/usr/bin/v2ray" "/etc/systemd/system/v2ray.service"
        if [[ $? -ne 0 ]]; then
            colorEcho ${RED} "Failed to remove V2Ray."
            exit
        else
            colorEcho ${GREEN} "Removed V2Ray successfully."
            colorEcho ${GREEN} "If necessary, please remove configuration file and log file manually."
            exit
        fi
    elif [[ -n "${SYSTEMCTL_CMD}" ]] && [[ -f "/lib/systemd/system/v2ray.service" ]];then
        if pgrep "v2ray" > /dev/null ; then
            stopV2ray
        fi
        systemctl disable v2ray.service
        rm -rf "/usr/bin/v2ray" "/lib/systemd/system/v2ray.service"
        if [[ $? -ne 0 ]]; then
            colorEcho ${RED} "Failed to remove V2Ray."
            exit
        else
            colorEcho ${GREEN} "Removed V2Ray successfully."
            colorEcho ${GREEN} "If necessary, please remove configuration file and log file manually."
            exit
        fi
    elif [[ -n "${SERVICE_CMD}" ]] && [[ -f "/etc/init.d/v2ray" ]]; then
        if pgrep "v2ray" > /dev/null ; then
            stopV2ray
        fi
        rm -rf "/usr/bin/v2ray" "/etc/init.d/v2ray"
        if [[ $? -ne 0 ]]; then
            colorEcho ${RED} "Failed to remove V2Ray."
            exit
        else
            colorEcho ${GREEN} "Removed V2Ray successfully."
            colorEcho ${GREEN} "If necessary, please remove configuration file and log file manually."
            exit
        fi       
    else
        colorEcho ${GREEN} "V2Ray not found."
        exit
    fi
}

checkUpdate(){
        echo "Checking for update."
        getVersion
        if [[ $? -eq 1 ]]; then
            colorEcho ${GREEN} "Found new version ${NEW_VER} for V2Ray."
            exit 
        else 
            colorEcho ${GREEN} "No new version."
            exit
        fi
}

main(){
    #helping information
    [[ "$HELP" == "1" ]] && Help
    [[ "$REMOVE" == "1" ]] && remove
    [[ "$CHECK" == "1" ]] && checkUpdate
    
    sysArch
    # extract local file
    if [[ $LOCAL_INSTALL -eq 1 ]]; then
        echo "Install V2Ray via local file"
        installSoftware unzip
        rm -rf /tmp/v2ray
        extract $LOCAL
        FILEVDIS=`ls /tmp/v2ray |grep v2ray-v |cut -d "-" -f4`
        SYSTEM=`ls /tmp/v2ray |grep v2ray-v |cut -d "-" -f3`
        if [[ ${SYSTEM} != "linux" ]]; then
            colorEcho $RED "The local V2Ray can not be installed in linux."
            exit
        elif [[ ${FILEVDIS} != ${VDIS} ]]; then
            colorEcho $RED "The local V2Ray can not be installed in ${ARCH} system."
            exit
        else
            NEW_VER=`ls /tmp/v2ray |grep v2ray-v |cut -d "-" -f2`
        fi
    else
        # dowload via network and extract
        installSoftware "curl"
        getVersion
        if [[ $? == 0 ]] && [[ "$FORCE" != "1" ]]; then
            colorEcho ${GREEN} "Lastest version ${NEW_VER} is already installed."
            exit
        else
            colorEcho ${BLUE} "Installing V2Ray ${NEW_VER} on ${ARCH}"
            downloadV2Ray
            installSoftware unzip
            extract ${ZIPFILE}
        fi
    fi 
    if pgrep "v2ray" > /dev/null ; then
        V2RAY_RUNNING=1
        stopV2ray
    fi
    installV2Ray
    installInitScrip
    if [[ ${V2RAY_RUNNING} -eq 1 ]];then
        colorEcho ${BLUE} "Restarting V2Ray service."
        startV2ray

    fi
    colorEcho ${GREEN} "V2Ray ${NEW_VER} is installed."
    rm -rf /tmp/v2ray
    return 0
}

main
