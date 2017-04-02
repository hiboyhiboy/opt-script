#!/bin/sh
#copyright by hiboy
source /etc/storage/script/init.sh
nvramshow=`nvram showall | grep shellinabox | awk '{print gensub(/'"'"'/,"'"'"'\"'"'"'\"'"'"'","g",$0);}'| awk '{print gensub(/=/,"='\''",1,$0)"'\'';";}'` && eval $nvramshow

if [ ! -z "$(echo $scriptfilepath | grep -v "/tmp/script/" | grep shellina_box)" ]  && [ ! -s /tmp/script/_shellina_box ]; then
	mkdir -p /tmp/script
	ln -sf $scriptfilepath /tmp/script/_shellina_box
	chmod 777 /tmp/script/_shellina_box
fi

[ -z $shellinabox_enable ] && shellinabox_enable=0 && nvram set shellinabox_enable=$shellinabox_enable
[ -z $shellinabox_port ] && shellinabox_port="4200" && nvram set shellinabox_port=$shellinabox_port
[ -z $shellinabox_css ] && shellinabox_css="white-on-black" && nvram set shellinabox_css=$shellinabox_css

shellinabox_check () {

A_restart=`nvram get shellinabox_status`
B_restart="$shellinabox_enable$shellinabox_port$shellinabox_css$shellinabox_options$shellinabox_wan"
B_restart=`echo -n "$B_restart" | md5sum | sed s/[[:space:]]//g | sed s/-//g`
if [ "$A_restart" != "$B_restart" ] ; then
	nvram set shellinabox_status=$B_restart
	needed_restart=1
else
	needed_restart=0
fi
if [ "$shellinabox_enable" != "1" ] && [ "$needed_restart" = "1" ] ; then
	[ ! -z "`pidof shellinaboxd`" ] && logger -t "【shellinabox】" "停止 shellinaboxd" && shellinabox_close
	{ eval $(ps - w | grep "$scriptname" | grep -v grep | awk '{print "kill "$1;}'); exit 0; }
fi
if [ "$shellinabox_enable" = "1" ] ; then
	if [ "$needed_restart" = "1" ] ; then
		shellinabox_close
		shellinabox_start
	else
		[ -z "`pidof shellinaboxd`" ] || [ ! -s "`which shellinaboxd`" ] && nvram set shellinabox_status=00 && { eval "$scriptfilepath start &"; exit 0; }
		port=$(iptables -t filter -L INPUT -v -n --line-numbers | grep dpt:$shellinabox_port | cut -d " " -f 1 | sort -nr | wc -l)
		if [ "$port" = 0 ] ; then
			logger -t "【shellinabox】" "检测:找不到 ss-server 端口:$shellinabox_port 规则, 重新添加"
			iptables -t filter -I INPUT -p tcp --dport $shellinabox_port -j ACCEPT &
		fi
	fi
fi
}

shellinabox_keep () {

logger -t "【shellinabox】" "守护进程启动"
while true; do
	if [ -z "`pidof shellinaboxd`" ] || [ ! -s "`which shellinaboxd`" ] ; then
		logger -t "【shellinabox】" "重新启动"
		{ eval "$scriptfilepath &" ; exit 0; }
	fi
sleep 262
done
}

shellinabox_close () {

iptables -D INPUT -p tcp --dport $shellinabox_port -j ACCEPT
killall shellinaboxd
killall -9 shellinaboxd
eval $(ps - w | grep "$scriptname keep" | grep -v grep | awk '{print "kill "$1;}')
}

shellinabox_start () {
SVC_PATH="/opt/sbin/shellinaboxd"
hash shellinaboxd 2>/dev/null || rm -rf /opt/bin/shellinaboxd
if [ ! -s "$SVC_PATH" ] ; then
	logger -t "【shellinabox】" "找不到 $SVC_PATH，安装 opt 程序"
	/tmp/script/_mountopt optwget
fi
if [ ! -s "$SVC_PATH" ] ; then
	logger -t "【shellinabox】" "找不到 $SVC_PATH ，需要手动安装 $SVC_PATH"
	logger -t "【shellinabox】" "启动失败, 10 秒后自动尝试重新启动" && sleep 10 && { nvram set shellinabox_status=00; eval "$scriptfilepath &"; exit 0; }
fi
logger -t "【shellinaboxd】" "运行 shellinaboxd"
/opt/etc/init.d/S88shellinaboxd restart
sleep 5
[ ! -z "`pidof shellinaboxd`" ] && logger -t "【shellinabox】" "启动成功"
[ -z "`pidof shellinaboxd`" ] && logger -t "【shellinabox】" "启动失败, 注意检查端口是否有冲突,程序是否下载完整,10 秒后自动尝试重新启动" && sleep 10 && { nvram set shellinabox_status=00; eval "$scriptfilepath &"; exit 0; }
iptables -I INPUT -p tcp --dport $shellinabox_port -j ACCEPT
initopt
eval "$scriptfilepath keep &"
}

initopt () {
optPath=`grep ' /opt ' /proc/mounts | grep tmpfs`
[ ! -z "$optPath" ] && return
if [ -s "/opt/etc/init.d/rc.func" ] ; then
	ln -sf "$scriptfilepath" "/opt/etc/init.d/$scriptname"
fi

}

case $ACTION in
start)
	shellinabox_close
	shellinabox_check
	;;
check)
	shellinabox_check
	;;
stop)
	shellinabox_close
	;;
keep)
	shellinabox_check
	shellinabox_keep
	;;
*)
	shellinabox_check
	;;
esac

