#!/bin/sh
#copyright by hiboy
source /etc/storage/script/init.sh
vpnproxy_wan_port=`nvram get vpnproxy_wan_port`
vpnproxy_enable=`nvram get vpnproxy_enable`
[ -z $vpnproxy_enable ] && vpnproxy_enable=0 && nvram set vpnproxy_enable=0
if [ "$vpnproxy_enable" != "0" ] ; then
nvramshow=`nvram showall | grep vpnproxy | awk '{print gensub(/'"'"'/,"'"'"'\"'"'"'\"'"'"'","g",$0);}'| awk '{print gensub(/=/,"='\''",1,$0)"'\'';";}'` && eval $nvramshow
fi

if [ ! -z "$(echo $scriptfilepath | grep -v "/tmp/script/" | grep vpnproxy)" ]  && [ ! -s /tmp/script/_vpnproxy ]; then
	mkdir -p /tmp/script
	ln -sf $scriptfilepath /tmp/script/_vpnproxy
	chmod 777 /tmp/script/_vpnproxy
fi

vpnproxy_check () {
vpnproxy_wan_port=${vpnproxy_wan_port:-"8888"}
vpnproxy_vpn_port=${vpnproxy_vpn_port:-"1194"}
A_restart=`nvram get vpnproxy_status`
B_restart="$vpnproxy_enable$vpnproxy_wan_port$vpnproxy_vpn_port"
B_restart=`echo -n "$B_restart" | md5sum | sed s/[[:space:]]//g | sed s/-//g`
if [ "$A_restart" != "$B_restart" ] ; then
	nvram set vpnproxy_status=$B_restart
	needed_restart=1
else
	needed_restart=0
fi
if [ "$vpnproxy_enable" != "1" ] && [ "$needed_restart" = "1" ] ; then
	[ ! -z "`pidof nvpproxy`" ] && logger -t "【vpnproxy】" "停止 nvpproxy" && vpnproxy_close
	{ eval $(ps -w | grep "$scriptname" | grep -v grep | awk '{print "kill "$1";";}'); exit 0; }
fi
if [ "$vpnproxy_enable" = "1" ] ; then
	if [ "$needed_restart" = "1" ] ; then
		vpnproxy_close
		vpnproxy_start
	else
		[ -z "`pidof nvpproxy`" ] && nvram set vpnproxy_status=00 && { eval "$scriptfilepath start &"; exit 0; }
		port=$(iptables -t filter -L INPUT -v -n --line-numbers | grep dpt:$vpnproxy_wan_port | cut -d " " -f 1 | sort -nr | wc -l)
		if [ "$port" = 0 ] ; then
		logger -t "【vpnproxy】" "允许 $vpnproxy_wan_port 端口通过防火墙"
		iptables -I INPUT -p tcp --dport $vpnproxy_wan_port -j ACCEPT
		fi
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
		{ nvram set vpnproxy_status=00 && eval "$scriptfilepath &" ; exit 0; }
	fi
sleep 223
done
}

vpnproxy_close () {

sed -Ei '/【vpnproxy】|^$/d' /tmp/script/_opt_script_check
iptables -D INPUT -p tcp --dport $vpnproxy_wan_port -j ACCEPT
killall nvpproxy
killall -9 nvpproxy
eval $(ps -w | grep "_vpnproxy keep" | grep -v grep | awk '{print "kill "$1";";}')
eval $(ps -w | grep "_vpnproxy.sh keep" | grep -v grep | awk '{print "kill "$1";";}')
eval $(ps -w | grep "$scriptname keep" | grep -v grep | awk '{print "kill "$1";";}')
}

vpnproxy_start () {
SVC_PATH="/opt/bin/nvpproxy"
hash nvpproxy 2>/dev/null || rm -rf /opt/bin/nvpproxy
if [ ! -s "$SVC_PATH" ] ; then
	logger -t "【vpnproxy】" "找不到 nvpproxy，安装 opt 程序"
	/tmp/script/_mountopt start
fi
if [ ! -s "$SVC_PATH" ] ; then
	logger -t "【vpnproxy】" "找不到 $SVC_PATH 下载程序"
	wgetcurl.sh /opt/bin/nvpproxy.tar.gz "$hiboyfile/nvpproxy.tar.gz" "$hiboyfile2/nvpproxy.tar.gz"
	tar -xzvf /opt/bin/nvpproxy.tar.gz -C /opt/bin/
	if [ ! -s "$SVC_PATH" ] ; then
		logger -t "【vpnproxy】" "解压不正常:/opt/bin/nvpproxy"
	else
		chmod 755 "/opt/bin/nvpproxy"
		rm -rf /opt/bin/nvpproxy.tar.gz
	fi
else
	logger -t "【vpnproxy】" "找到 $SVC_PATH"
fi
if [ ! -s "$SVC_PATH" ] ; then
	logger -t "【vpnproxy】" "找不到 $SVC_PATH ，需要手动安装 $SVC_PATH"
	logger -t "【vpnproxy】" "启动失败, 10 秒后自动尝试重新启动" && sleep 10 && { nvram set vpnproxy_status=00; eval "$scriptfilepath &"; exit 0; }
fi
logger -t "【vpnproxy】" "运行 $SVC_PATH"
$SVC_PATH -port=$vpnproxy_wan_port -proxy=127.0.0.1:$vpnproxy_vpn_port &
restart_dhcpd
sleep 2
[ ! -z "`pidof nvpproxy`" ] && logger -t "【vpnproxy】" "启动成功"
[ -z "`pidof nvpproxy`" ] && logger -t "【vpnproxy】" "启动失败, 注意检查端口是否有冲突,程序是否下载完整, 10 秒后自动尝试重新启动" && sleep 10 && { nvram set vpnproxy_status=00; eval "$scriptfilepath &"; exit 0; }
logger -t "【vpnproxy】" "允许 $vpnproxy_wan_port 端口通过防火墙"
iptables -I INPUT -p tcp --dport $vpnproxy_wan_port -j ACCEPT
initopt
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
	vpnproxy_check
	vpnproxy_keep
	;;
*)
	vpnproxy_check
	;;
esac

