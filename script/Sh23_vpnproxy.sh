#!/bin/sh
#copyright by hiboy
source /etc/storage/script/init.sh
vpnproxy_wan_port=`nvram get vpnproxy_wan_port`
vpnproxy_enable=`nvram get vpnproxy_enable`
[ -z $vpnproxy_enable ] && vpnproxy_enable=0 && nvram set vpnproxy_enable=0
if [ "$vpnproxy_enable" != "0" ] ; then
#nvramshow=`nvram showall | grep '=' | grep vpnproxy | awk '{print gensub(/'"'"'/,"'"'"'\"'"'"'\"'"'"'","g",$0);}'| awk '{print gensub(/=/,"='\''",1,$0)"'\'';";}'` && eval $nvramshow
vpnproxy_vpn_port=`nvram get vpnproxy_vpn_port`
fi

if [ ! -z "$(echo $scriptfilepath | grep -v "/tmp/script/" | grep vpnproxy)" ]  && [ ! -s /tmp/script/_vpnproxy ]; then
	mkdir -p /tmp/script
	{ echo '#!/bin/sh' ; echo $scriptfilepath '"$@"' '&' ; } > /tmp/script/_vpnproxy
	chmod 777 /tmp/script/_vpnproxy
fi

vpnproxy_restart () {

relock="/var/lock/vpnproxy_restart.lock"
if [ "$1" = "o" ] ; then
	nvram set vpnproxy_renum="0"
	[ -f $relock ] && rm -f $relock
	return 0
fi
if [ "$1" = "x" ] ; then
	if [ -f $relock ] ; then
		logger -t "【vpnproxy】" "多次尝试启动失败，等待【"`cat $relock`"分钟】后自动尝试重新启动"
		exit 0
	fi
	vpnproxy_renum=${vpnproxy_renum:-"0"}
	vpnproxy_renum=`expr $vpnproxy_renum + 1`
	nvram set vpnproxy_renum="$vpnproxy_renum"
	if [ "$vpnproxy_renum" -gt "2" ] ; then
		I=19
		echo $I > $relock
		logger -t "【vpnproxy】" "多次尝试启动失败，等待【"`cat $relock`"分钟】后自动尝试重新启动"
		while [ $I -gt 0 ]; do
			I=$(($I - 1))
			echo $I > $relock
			sleep 60
			[ "$(nvram get vpnproxy_renum)" = "0" ] && exit 0
			[ $I -lt 0 ] && break
		done
		nvram set vpnproxy_renum="0"
	fi
	[ -f $relock ] && rm -f $relock
fi
nvram set vpnproxy_status=0
eval "$scriptfilepath &"
exit 0
}

vpnproxy_get_status () {

[ -z $vpnproxy_wan_port ] && vpnproxy_wan_port=8888 && nvram set vpnproxy_wan_port=$vpnproxy_wan_port
[ -z $vpnproxy_vpn_port ] && vpnproxy_vpn_port=1194 && nvram set vpnproxy_vpn_port=$vpnproxy_vpn_port
A_restart=`nvram get vpnproxy_status`
B_restart="$vpnproxy_enable$vpnproxy_wan_port$vpnproxy_vpn_port"
B_restart=`echo -n "$B_restart" | md5sum | sed s/[[:space:]]//g | sed s/-//g`
if [ "$A_restart" != "$B_restart" ] ; then
	nvram set vpnproxy_status=$B_restart
	needed_restart=1
else
	needed_restart=0
fi
}

vpnproxy_check () {

vpnproxy_get_status
if [ "$vpnproxy_enable" != "1" ] && [ "$needed_restart" = "1" ] ; then
	[ ! -z "`pidof nvpproxy`" ] && logger -t "【vpnproxy】" "停止 nvpproxy" && vpnproxy_close
	{ kill_ps "$scriptname" exit0; exit 0; }
fi
if [ "$vpnproxy_enable" = "1" ] ; then
	if [ "$needed_restart" = "1" ] ; then
		vpnproxy_close
		vpnproxy_start
	else
		[ -z "`pidof nvpproxy`" ] && vpnproxy_restart
		vpnproxy_port_dpt
	fi
fi
}

vpnproxy_keep () {
logger -t "【vpnproxy】" "守护进程启动"
if [ -s /tmp/script/_opt_script_check ]; then
sed -Ei '/【vpnproxy】|^$/d' /tmp/script/_opt_script_check
cat >> "/tmp/script/_opt_script_check" <<-OSC
[ -z "\`pidof nvpproxy\`" ] || [ ! -s "`which nvpproxy`" ] && nvram set vpnproxy_status=00 && logger -t "【vpnproxy】" "重新启动" && eval "$scriptfilepath &" && sed -Ei '/【vpnproxy】|^$/d' /tmp/script/_opt_script_check # 【vpnproxy】
OSC
return
fi
while true; do
	if [ -z "`pidof nvpproxy`" ] || [ ! -s "`which nvpproxy`" ] ; then
		logger -t "【vpnproxy】" "重新启动"
		vpnproxy_restart
	fi
sleep 223
done
}

vpnproxy_close () {

sed -Ei '/【vpnproxy】|^$/d' /tmp/script/_opt_script_check
iptables -t filter -D INPUT -p tcp --dport $vpnproxy_wan_port -j ACCEPT
killall nvpproxy
killall -9 nvpproxy
kill_ps "/tmp/script/_vpnproxy"
kill_ps "_vpnproxy.sh"
kill_ps "$scriptname"
}

vpnproxy_start () {
SVC_PATH="/opt/bin/nvpproxy"
chmod 777 "$SVC_PATH"
[[ "$(nvpproxy -h 2>&1 | wc -l)" -lt 2 ]] && rm -rf /opt/bin/nvpproxy
if [ ! -s "$SVC_PATH" ] ; then
	logger -t "【vpnproxy】" "找不到 nvpproxy，安装 opt 程序"
	/tmp/script/_mountopt start
fi
if [ ! -s "$SVC_PATH" ] ; then
	logger -t "【vpnproxy】" "找不到 $SVC_PATH 下载程序"
	wgetcurl.sh /opt/bin/nvpproxy "$hiboyfile/nvpproxy" "$hiboyfile2/nvpproxy"
	chmod 755 "/opt/bin/nvpproxy"
else
	logger -t "【vpnproxy】" "找到 $SVC_PATH"
fi
if [ ! -s "$SVC_PATH" ] ; then
	logger -t "【vpnproxy】" "找不到 $SVC_PATH ，需要手动安装 $SVC_PATH"
	logger -t "【vpnproxy】" "启动失败, 10 秒后自动尝试重新启动" && sleep 10 && vpnproxy_restart x
fi
chmod 777 "$SVC_PATH"
logger -t "【vpnproxy】" "运行 $SVC_PATH"
$SVC_PATH -port=$vpnproxy_wan_port -proxy=127.0.0.1:$vpnproxy_vpn_port &
restart_dhcpd
sleep 2
[ ! -z "`pidof nvpproxy`" ] && logger -t "【vpnproxy】" "启动成功" && vpnproxy_restart o
[ -z "`pidof nvpproxy`" ] && logger -t "【vpnproxy】" "启动失败, 注意检查端口【netstat -anp | grep LISTEN】是否有冲突,程序是否下载完整, 10 秒后自动尝试重新启动" && sleep 10 && vpnproxy_restart x
vpnproxy_port_dpt
initopt
#vpnproxy_get_status
eval "$scriptfilepath keep &"
}

initopt () {
optPath=`grep ' /opt ' /proc/mounts | grep tmpfs`
[ ! -z "$optPath" ] && return
if [ ! -z "$(echo $scriptfilepath | grep -v "/opt/etc/init")" ] && [ -s "/opt/etc/init.d/rc.func" ] ; then
	{ echo '#!/bin/sh' ; echo $scriptfilepath '"$@"' '&' ; } > /opt/etc/init.d/$scriptname && chmod 777  /opt/etc/init.d/$scriptname
fi

}


vpnproxy_port_dpt () {

port=$(iptables -t filter -L INPUT -v -n --line-numbers | grep dpt:$vpnproxy_wan_port | cut -d " " -f 1 | sort -nr | wc -l)
if [ "$port" = 0 ] ; then
	logger -t "【vpnproxy】" "允许 $vpnproxy_wan_port 端口通过防火墙"
	iptables -t filter -I INPUT -p tcp --dport $vpnproxy_wan_port -j ACCEPT
fi

}

case $ACTION in
start)
	vpnproxy_close
	vpnproxy_check
	;;
check)
	vpnproxy_check
	;;
stop)
	vpnproxy_close
	;;
keep)
	#vpnproxy_check
	vpnproxy_keep
	;;
*)
	vpnproxy_check
	;;
esac

