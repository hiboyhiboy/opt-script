#!/bin/sh
#copyright by hiboy
source /etc/storage/script/init.sh
ssserver_port=`nvram get ssserver_port`
ssserver_enable=`nvram get ssserver_enable`
[ -z $ssserver_enable ] && ssserver_enable=0 && nvram set ssserver_enable=0
if [ "$ssserver_enable" != "0" ] ; then
nvramshow=`nvram showall | grep ssserver | awk '{print gensub(/'"'"'/,"'"'"'\"'"'"'\"'"'"'","g",$0);}'| awk '{print gensub(/=/,"='\''",1,$0)"'\'';";}'` && eval $nvramshow

ssserver_password=${ssserver_password:-"m"}
ssserver_time=${ssserver_time:-"120"}
ssserver_port=${ssserver_port:-"8388"}
[ -z $ssserver_method ] && ssserver_method="aes-256-cfb" && nvram set ssserver_method="aes-256-cfb"
fi
if [ ! -z "$(echo $scriptfilepath | grep -v "/tmp/script/" | grep ssserver)" ]  && [ ! -s /tmp/script/_ssserver ]; then
	mkdir -p /tmp/script
	ln -sf $scriptfilepath /tmp/script/_ssserver
	chmod 777 /tmp/script/_ssserver
fi

ssserver_check () {

A_restart=`nvram get ssserver_status`
B_restart="$ssserver_enable$ssserver_method$ssserver_password$ssserver_port$ssserver_time$ssserver_udp$ssserver_ota$ssserver_usage"
B_restart=`echo -n "$B_restart" | md5sum | sed s/[[:space:]]//g | sed s/-//g`
if [ "$A_restart" != "$B_restart" ] ; then
	nvram set ssserver_status=$B_restart
	needed_restart=1
else
	needed_restart=0
fi
if [ "$ssserver_enable" != "1" ] && [ "$needed_restart" = "1" ] ; then
	[ ! -z "`pidof ss-server`" ] && logger -t "【SS_server】" "停止 ss-server" && ssserver_close
	{ eval $(ps -w | grep "$scriptname" | grep -v grep | awk '{print "kill "$1";";}'); exit 0; }
fi
if [ "$ssserver_enable" = "1" ] ; then
	if [ "$needed_restart" = "1" ] ; then
		ssserver_close
		ssserver_start
	else
		[ -z "`pidof ss-server`" ] && nvram set ssserver_status=00 && { eval "$scriptfilepath start &"; exit 0; }
		if [ -n "`pidof ss-server`" ] && [ "$ssserver_enable" = "1" ] ; then
			port=$(iptables -t filter -L INPUT -v -n --line-numbers | grep dpt:$ssserver_port | cut -d " " -f 1 | sort -nr | wc -l)
			if [ "$port" = 0 ] ; then
				logger -t "【SS_server】" "检测$port:找不到 ss-server 端口:$ssserver_port 规则, 重新添加"
				iptables -t filter -I INPUT -p tcp --dport $ssserver_port -j ACCEPT &
				iptables -t filter -I INPUT -p udp --dport $ssserver_port -j ACCEPT &
			fi
		fi
	fi
fi
}

ssserver_keep () {
logger -t "【SS_server】" "守护进程启动"
if [ -s /tmp/script/_opt_script_check ]; then
sed -Ei '/【SS_server】|^$/d' /tmp/script/_opt_script_check
cat >> "/tmp/script/_opt_script_check" <<-OSC
[ -z "\`pidof ss-server\`" ] || [ ! -s "`which ss-server`" ] && nvram set ssserver_status=00 && logger -t "【SS_server】" "重新启动" && eval "$scriptfilepath &" && sed -Ei '/【SS_server】|^$/d' /tmp/script/_opt_script_check # 【SS_server】
OSC
return
fi
while true; do
	if [ -z "`pidof ss-server`" ] || [ ! -s "`which ss-server`" ] ; then
		logger -t "【SS_server】" "重新启动"
		{ nvram set ssserver_status=00 && eval "$scriptfilepath &" ; exit 0; }
	fi
sleep 224
done
}

ssserver_close () {

sed -Ei '/【SS_server】|^$/d' /tmp/script/_opt_script_check
iptables -t filter -D INPUT -p tcp --dport $ssserver_port -j ACCEPT &
iptables -t filter -D INPUT -p udp --dport $ssserver_port -j ACCEPT &
killall ss-server obfs-server >/dev/null 2>&1
killall -9 ss-server obfs-server >/dev/null 2>&1
eval $(ps -w | grep "_ssserver keep" | grep -v grep | awk '{print "kill "$1";";}')
eval $(ps -w | grep "_ssserver.sh keep" | grep -v grep | awk '{print "kill "$1";";}')
eval $(ps -w | grep "$scriptname keep" | grep -v grep | awk '{print "kill "$1";";}')
}

ssserver_start () {

SVC_PATH=/usr/sbin/ss-server
if [ ! -s "$SVC_PATH" ] ; then
	SVC_PATH="/opt/bin/ss-server"
fi
hash ss-server 2>/dev/null || rm -rf /opt/bin/ss-server
if [ ! -s "$SVC_PATH" ] ; then
	logger -t "【SS_server】" "找不到 $SVC_PATH，安装 opt 程序"
	/tmp/script/_mountopt start
	initopt
fi
if [ ! -s "$SVC_PATH" ] ; then
	logger -t "【SS_server】" "找不到 $SVC_PATH 下载程序"
	wgetcurl.sh /opt/bin/ss-server "$hiboyfile/ss-server" "$hiboyfile2/ss-server"
	chmod 755 "/opt/bin/ss-server"
else
	logger -t "【SS_server】" "找到 $SVC_PATH"
fi
if [ ! -s "$SVC_PATH" ] ; then
	logger -t "【SS_server】" "找不到 $SVC_PATH ，需要手动安装 $SVC_PATH"
	logger -t "【SS_server】" "启动失败, 10 秒后自动尝试重新启动" && sleep 10 && { nvram set ssserver_status=00; eval "$scriptfilepath &"; exit 0; }
fi
logger -t "【SS_server】" "启动 ss-server 服务"
key_password=""
[ ! -z "$ssserver_password" ] && key_password="-k $ssserver_password" || key_password=""
if [ "$ssserver_udp" == "1" ] ; then
	ss-server -s 0.0.0.0 -p $ssserver_port $key_password -m $ssserver_method -t $ssserver_time -u $ssserver_usage  -f /tmp/ssserver.pid
else
	ss-server -s 0.0.0.0 -p $ssserver_port $key_password -m $ssserver_method -t $ssserver_time $ssserver_usage -f /tmp/ssserver.pid
fi

sleep 2
[ ! -z "`pidof ss-server`" ] && logger -t "【SS_server】" "启动成功"
[ -z "`pidof ss-server`" ] && logger -t "【SS_server】" "启动失败, 注意检查端口是否有冲突,程序是否下载完整, 10 秒后自动尝试重新启动" && sleep 10 && { nvram set ssserver_status=00; eval "$scriptfilepath &"; exit 0; }
logger -t "【SS_server】" "`ps -w | grep ss-server | grep -v grep`"
iptables -t filter -I INPUT -p tcp --dport $ssserver_port -j ACCEPT &
iptables -t filter -I INPUT -p udp --dport $ssserver_port -j ACCEPT &
eval "$scriptfilepath keep &"

}

initopt () {
optPath=`grep ' /opt ' /proc/mounts | grep tmpfs`
[ ! -z "$optPath" ] && return
if [ -s "/opt/etc/init.d/rc.func" ] ; then
	cp -Hf "$scriptfilepath" "/opt/etc/init.d/$scriptname"
fi

}

case $ACTION in
start)
	ssserver_close
	ssserver_check
	;;
check)
	ssserver_check
	;;
stop)
	ssserver_close
	;;
keep)
	ssserver_check
	ssserver_keep
	;;
*)
	ssserver_check
	;;
esac

















