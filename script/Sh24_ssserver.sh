#!/bin/sh
#copyright by hiboy
source /etc/storage/script/init.sh
ssserver_port=`nvram get ssserver_port`
ssserver_enable=`nvram get ssserver_enable`
[ -z $ssserver_enable ] && ssserver_enable=0 && nvram set ssserver_enable=0
if [ "$ssserver_enable" != "0" ] ; then
#nvramshow=`nvram showall | grep '=' | grep ssserver | awk '{print gensub(/'"'"'/,"'"'"'\"'"'"'\"'"'"'","g",$0);}'| awk '{print gensub(/=/,"='\''",1,$0)"'\'';";}'` && eval $nvramshow

ssserver_method=`nvram get ssserver_method`
ssserver_password=`nvram get ssserver_password`
ssserver_time=`nvram get ssserver_time`
ssserver_udp=`nvram get ssserver_udp`
ssserver_usage=" `nvram get ssserver_usage` "

[ -z $ssserver_password ] && ssserver_password="m" && nvram set ssserver_password=$ssserver_password
[ -z $ssserver_time ] && ssserver_time=120 && nvram set ssserver_time=$ssserver_time
[ -z $ssserver_port ] && ssserver_port=8388 && nvram set ssserver_port=$ssserver_port
[ -z $ssserver_method ] && ssserver_method="aes-256-cfb" && nvram set ssserver_method="aes-256-cfb"
fi
if [ ! -z "$(echo $scriptfilepath | grep -v "/tmp/script/" | grep ssserver)" ]  && [ ! -s /tmp/script/_ssserver ]; then
	mkdir -p /tmp/script
	{ echo '#!/bin/sh' ; echo $scriptfilepath '"$@"' '&' ; } > /tmp/script/_ssserver
	chmod 777 /tmp/script/_ssserver
fi

ssserver_restart () {

relock="/var/lock/ssserver_restart.lock"
if [ "$1" = "o" ] ; then
	nvram set ssserver_renum="0"
	[ -f $relock ] && rm -f $relock
	return 0
fi
if [ "$1" = "x" ] ; then
	if [ -f $relock ] ; then
		logger -t "【ssserver】" "多次尝试启动失败，等待【"`cat $relock`"分钟】后自动尝试重新启动"
		exit 0
	fi
	ssserver_renum=${ssserver_renum:-"0"}
	ssserver_renum=`expr $ssserver_renum + 1`
	nvram set ssserver_renum="$ssserver_renum"
	if [ "$ssserver_renum" -gt "2" ] ; then
		I=19
		echo $I > $relock
		logger -t "【ssserver】" "多次尝试启动失败，等待【"`cat $relock`"分钟】后自动尝试重新启动"
		while [ $I -gt 0 ]; do
			I=$(($I - 1))
			echo $I > $relock
			sleep 60
			[ "$(nvram get ssserver_renum)" = "0" ] && exit 0
			[ $I -lt 0 ] && break
		done
		nvram set ssserver_renum="0"
	fi
	[ -f $relock ] && rm -f $relock
fi
nvram set ssserver_status=0
eval "$scriptfilepath &"
exit 0
}

ssserver_get_status () {

A_restart=`nvram get ssserver_status`
B_restart="$ssserver_enable$ssserver_method$ssserver_password$ssserver_port$ssserver_time$ssserver_udp$ssserver_ota$ssserver_usage"
B_restart=`echo -n "$B_restart" | md5sum | sed s/[[:space:]]//g | sed s/-//g`
if [ "$A_restart" != "$B_restart" ] ; then
	nvram set ssserver_status=$B_restart
	needed_restart=1
else
	needed_restart=0
fi
}

ssserver_check () {

ssserver_get_status
if [ "$ssserver_enable" != "1" ] && [ "$needed_restart" = "1" ] ; then
	[ ! -z "`pidof ss-server`" ] && logger -t "【SS_server】" "停止 ss-server" && ssserver_close
	{ kill_ps "$scriptname" exit0; exit 0; }
fi
if [ "$ssserver_enable" = "1" ] ; then
	if [ "$needed_restart" = "1" ] ; then
		ssserver_close
		ssserver_start
	else
		[ -z "`pidof ss-server`" ] && ssserver_restart
		ssserver_port_dpt
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
		ssserver_restart
	fi
sleep 224
done
}

ssserver_close () {

sed -Ei '/【SS_server】|^$/d' /tmp/script/_opt_script_check
iptables -t filter -D INPUT -p tcp --dport $ssserver_port -j ACCEPT
iptables -t filter -D INPUT -p udp --dport $ssserver_port -j ACCEPT
killall ss-server obfs-server
killall -9 ss-server obfs-server
kill_ps "/tmp/script/_ssserver"
kill_ps "_ssserver.sh"
kill_ps "$scriptname"
}

ssserver_start () {

SVC_PATH=/usr/sbin/ss-server
if [ ! -s "$SVC_PATH" ] ; then
	SVC_PATH="/opt/bin/ss-server"
fi
chmod 777 "$SVC_PATH"
[[ "$(ss-server -h 2>&1 | wc -l)" -lt 2 ]] && rm -rf /opt/bin/ss-server
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
	logger -t "【SS_server】" "启动失败, 10 秒后自动尝试重新启动" && sleep 10 && ssserver_restart x
fi
if [ ! -z "echo $ssserver_usage | grep plugin" ] ; then
	if [ ! -s "/opt/bin/obfs-server" ] ; then
		logger -t "【SS_server】" "找不到 /opt/bin/obfs-server，安装 opt 程序"
		/tmp/script/_mountopt start
		initopt
	fi
	if [ ! -s "/opt/bin/obfs-server" ] ; then
		logger -t "【SS_server】" "找不到 /opt/bin/obfs-server 下载程序"
		wgetcurl.sh /opt/bin/obfs-server "$hiboyfile/obfs-server" "$hiboyfile2/obfs-server"
		chmod 755 "/opt/bin/obfs-server"
	else
		logger -t "【SS_server】" "找到 /opt/bin/obfs-server"
	fi
fi
logger -t "【SS_server】" "启动 ss-server 服务"
if [ "$ssserver_udp" == "1" ] ; then
	ss-server -s 0.0.0.0 -p $ssserver_port -k $ssserver_password -m $ssserver_method -t $ssserver_time -u $ssserver_usage  -f /tmp/ssserver.pid
else
	ss-server -s 0.0.0.0 -p $ssserver_port -k $ssserver_password -m $ssserver_method -t $ssserver_time $ssserver_usage -f /tmp/ssserver.pid
fi

sleep 2
[ ! -z "`pidof ss-server`" ] && logger -t "【SS_server】" "启动成功" && ssserver_restart o
[ -z "`pidof ss-server`" ] && logger -t "【SS_server】" "启动失败, 注意检查端口是否有冲突,程序是否下载完整, 10 秒后自动尝试重新启动" && sleep 10 && ssserver_restart x
logger -t "【SS_server】" "`ps -w | grep ss-server | grep -v grep`"
ssserver_port_dpt
#ssserver_get_status
eval "$scriptfilepath keep &"

}

initopt () {
optPath=`grep ' /opt ' /proc/mounts | grep tmpfs`
[ ! -z "$optPath" ] && return
if [ ! -z "$(echo $scriptfilepath | grep -v "/opt/etc/init")" ] && [ -s "/opt/etc/init.d/rc.func" ] ; then
	{ echo '#!/bin/sh' ; echo $scriptfilepath '"$@"' '&' ; } > /opt/etc/init.d/$scriptname && chmod 777  /opt/etc/init.d/$scriptname
fi

}

initconfig () {

SSRconfig_script="/etc/storage/SSRconfig_script.sh"
if [ ! -f "$SSRconfig_script" ] || [ ! -s "$SSRconfig_script" ] ; then
	cat > "$SSRconfig_script" <<-\EEE
{
    "server": "0.0.0.0",
    "server_ipv6": "::",
    "server_port": 8388,
    "local_address": "127.0.0.1",
    "local_port": 1080,

    "password": "m",
    "timeout": 120,
    "udp_timeout": 60,
    "method": "aes-128-ctr",
    "protocol": "auth_aes128_md5",
    "protocol_param": "",
    "obfs": "tls1.2_ticket_auth_compatible",
    "obfs_param": "",
    "speed_limit_per_con": 0,
    "speed_limit_per_user": 0,

    "dns_ipv6": false,
    "connect_verbose_info": 0,
    "redirect": "",
    "fast_open": false
}
EEE
	chmod 755 "$SSRconfig_script"
fi

}

initconfig

ssserver_port_dpt () {

ssserver_enable=`nvram get ssserver_enable`
if [ "$ssserver_enable" = "1" ] ; then
	ssserver_port=`nvram get ssserver_port`
		echo "ssserver_port:$ssserver_port"
	port=$(iptables -t filter -L INPUT -v -n --line-numbers | grep dpt:$ssserver_port | cut -d " " -f 1 | sort -nr | wc -l)
	if [ "$port" = 0 ] ; then
		logger -t "【SS_server】" "允许 $ssserver_port 端口通过防火墙"
		iptables -t filter -I INPUT -p tcp --dport $ssserver_port -j ACCEPT
		iptables -t filter -I INPUT -p udp --dport $ssserver_port -j ACCEPT
	fi
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
	#ssserver_check
	ssserver_keep
	;;
*)
	ssserver_check
	;;
esac


