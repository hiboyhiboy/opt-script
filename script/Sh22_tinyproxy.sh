#!/bin/sh
#copyright by hiboy
source /etc/storage/script/init.sh
tinyproxy_enable=`nvram get tinyproxy_enable`
[ -z $tinyproxy_enable ] && tinyproxy_enable=0 && nvram set tinyproxy_enable=0
tinyproxy_path=`nvram get tinyproxy_path`
[ -z $tinyproxy_path ] && tinyproxy_path=`which tinyproxy` && nvram set tinyproxy_path="/usr/sbin/tinyproxy"
if [ "$tinyproxy_enable" != "0" ] ; then
#nvramshow=`nvram showall | grep '=' | grep tinyproxy | awk '{print gensub(/'"'"'/,"'"'"'\"'"'"'\"'"'"'","g",$0);}'| awk '{print gensub(/=/,"='\''",1,$0)"'\'';";}'` && eval $nvramshow
tinyproxy_port=`nvram get tinyproxy_port`
fi

if [ ! -z "$(echo $scriptfilepath | grep -v "/tmp/script/" | grep tinyproxy)" ]  && [ ! -s /tmp/script/_tinyproxy ]; then
	mkdir -p /tmp/script
	{ echo '#!/bin/sh' ; echo $scriptfilepath '"$@"' '&' ; } > /tmp/script/_tinyproxy
	chmod 777 /tmp/script/_tinyproxy
fi

tinyproxy_restart () {

relock="/var/lock/tinyproxy_restart.lock"
if [ "$1" = "o" ] ; then
	nvram set tinyproxy_renum="0"
	[ -f $relock ] && rm -f $relock
	return 0
fi
if [ "$1" = "x" ] ; then
	if [ -f $relock ] ; then
		logger -t "【tinyproxy】" "多次尝试启动失败，等待【"`cat $relock`"分钟】后自动尝试重新启动"
		exit 0
	fi
	tinyproxy_renum=${tinyproxy_renum:-"0"}
	tinyproxy_renum=`expr $tinyproxy_renum + 1`
	nvram set tinyproxy_renum="$tinyproxy_renum"
	if [ "$tinyproxy_renum" -gt "2" ] ; then
		I=19
		echo $I > $relock
		logger -t "【tinyproxy】" "多次尝试启动失败，等待【"`cat $relock`"分钟】后自动尝试重新启动"
		while [ $I -gt 0 ]; do
			I=$(($I - 1))
			echo $I > $relock
			sleep 60
			[ "$(nvram get tinyproxy_renum)" = "0" ] && exit 0
			[ $I -lt 0 ] && break
		done
		nvram set tinyproxy_renum="0"
	fi
	[ -f $relock ] && rm -f $relock
fi
nvram set tinyproxy_status=0
eval "$scriptfilepath &"
exit 0
}

tinyproxy_get_status () {

A_restart=`nvram get tinyproxy_status`
B_restart="$tinyproxy_enable$tinyproxy_path$tinyproxy_port$(cat /etc/storage/tinyproxy_script.sh | grep -v '^#' | grep -v "^$")"
B_restart=`echo -n "$B_restart" | md5sum | sed s/[[:space:]]//g | sed s/-//g`
if [ "$A_restart" != "$B_restart" ] ; then
	nvram set tinyproxy_status=$B_restart
	needed_restart=1
else
	needed_restart=0
fi
}

tinyproxy_check () {

tinyproxy_get_status
if [ "$tinyproxy_enable" != "1" ] && [ "$needed_restart" = "1" ] ; then
	[ ! -z "$(ps -w | grep "$tinyproxy_path" | grep -v grep )" ] && logger -t "【tinyproxy】" "停止 $tinyproxy_path" && tinyproxy_close
	{ kill_ps "$scriptname" exit0; exit 0; }
fi
if [ "$tinyproxy_enable" = "1" ] ; then
	if [ "$needed_restart" = "1" ] ; then
		tinyproxy_close
		tinyproxy_start
	else
		[ -z "$(ps -w | grep "$tinyproxy_path" | grep -v grep )" ] && tinyproxy_restart
		tinyproxy_port_dpt
	fi
fi
}

tinyproxy_keep () {
logger -t "【tinyproxy】" "守护进程启动"
if [ -s /tmp/script/_opt_script_check ]; then
sed -Ei '/【tinyproxy】|^$/d' /tmp/script/_opt_script_check
cat >> "/tmp/script/_opt_script_check" <<-OSC
	NUM=\`grep "$tinyproxy_path" /tmp/ps | grep -v grep |wc -l\` # 【tinyproxy】
	if [ "\$NUM" -lt "1" ] || [ ! -s "$tinyproxy_path" ] ; then # 【tinyproxy】
		logger -t "【tinyproxy】" "重新启动\$NUM" # 【tinyproxy】
		nvram set tinyproxy_status=00 && eval "$scriptfilepath &" && sed -Ei '/【tinyproxy】|^$/d' /tmp/script/_opt_script_check # 【tinyproxy】
	fi # 【tinyproxy】
OSC
return
fi

while true; do
	if [ -z "$(ps -w | grep "$tinyproxy_path" | grep -v grep )" ] || [ ! -s "$tinyproxy_path" ] ; then
		logger -t "【tinyproxy】" "重新启动"
		tinyproxy_restart
	fi
sleep 222
done
}

tinyproxy_close () {

sed -Ei '/【tinyproxy】|^$/d' /tmp/script/_opt_script_check
tinyproxyport=$(echo `cat /etc/storage/tinyproxy_script.sh | grep -v "^#" | grep -v "ConnectPort" | grep "Port" | sed 's/Port//'`)
[ ! -z "$tinyproxyport" ] && iptables -t filter -D INPUT -p tcp --dport $tinyproxyport -j ACCEPT
killall tinyproxy tinyproxy_script.sh
killall -9 tinyproxy tinyproxy_script.sh
[ ! -z "$tinyproxy_path" ] && kill_ps "$tinyproxy_path"
kill_ps "/tmp/script/_tinyproxy"
kill_ps "_tinyproxy.sh"
kill_ps "$scriptname"
}

tinyproxy_start () {
SVC_PATH="$tinyproxy_path"
if [ ! -s "$SVC_PATH" ] ; then
	SVC_PATH="/etc/storage/bin/tinyproxy"
fi
if [ ! -s "$SVC_PATH" ] ; then
	SVC_PATH="/usr/sbin/tinyproxy"
fi
if [ ! -s "$SVC_PATH" ] ; then
	SVC_PATH="/opt/bin/tinyproxy"
fi
chmod 777 "$SVC_PATH"
[[ "$(tinyproxy -h | wc -l)" -lt 2 ]] && rm -rf /opt/bin/tinyproxy
if [ ! -s "$SVC_PATH" ] ; then
	logger -t "【tinyproxy】" "找不到 tinyproxy，安装 opt 程序"
	/tmp/script/_mountopt start
	initopt
fi
if [ ! -s "$SVC_PATH" ] ; then
	logger -t "【tinyproxy】" "找不到 $SVC_PATH 下载程序"
	wgetcurl.sh /opt/bin/tinyproxy "$hiboyfile/tinyproxy" "$hiboyfile2/tinyproxy"
	chmod 755 "/opt/bin/tinyproxy"
else
	logger -t "【tinyproxy】" "找到 $SVC_PATH"
fi
if [ ! -s "$SVC_PATH" ] ; then
	logger -t "【tinyproxy】" "找不到 $SVC_PATH ，需要手动安装 $SVC_PATH"
	logger -t "【tinyproxy】" "启动失败, 10 秒后自动尝试重新启动" && sleep 10 && tinyproxy_restart x
fi
if [ -s "$SVC_PATH" ] ; then
	nvram set tinyproxy_path="$SVC_PATH"
fi
tinyproxy_path="$SVC_PATH"
logger -t "【tinyproxy】" "运行 $tinyproxy_path"
$tinyproxy_path -c /etc/storage/tinyproxy_script.sh &
restart_dhcpd
sleep 2
[ ! -z "$(ps -w | grep "$tinyproxy_path" | grep -v grep )" ] && logger -t "【tinyproxy】" "启动成功" && tinyproxy_restart o
[ -z "$(ps -w | grep "$tinyproxy_path" | grep -v grep )" ] && logger -t "【tinyproxy】" "启动失败, 注意检查端口是否有冲突,程序是否下载完整,10 秒后自动尝试重新启动" && sleep 10 && tinyproxy_restart x
tinyproxy_port_dpt
tinyproxy_get_status
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

config_tinyproxy="/etc/storage/tinyproxy_script.sh"
if [ ! -f "$config_tinyproxy" ] || [ ! -s "$config_tinyproxy" ] ; then
		cat > "$config_tinyproxy" <<-\END
## tinyproxy.conf -- tinyproxy daemon configuration file
## https://github.com/tinyproxy/tinyproxy/blob/master/etc/tinyproxy.conf.in
#User nobody
#Group nobody
Port 9999
#Listen 192.168.0.1 #注释之后可以侦听所有网卡的请求
#Bind 192.168.0.1
Timeout 600
# DefaultErrorFile "/usr/local/share/tinyproxy/default.html"
# StatFile "/usr/local/share/tinyproxy/stats.html"
Logfile "/tmp/syslog.log"
LogLevel Info
PidFile "/var/run/tinyproxy.pid"
MaxClients 100
MinSpareServers 5
MaxSpareServers 20
StartServers 10
MaxRequestsPerChild 0
# Allow 127.0.0.1
ViaProxyName "tinyproxy"
# This is a list of ports allowed by tinyproxy when the CONNECT method
# is used.  To disable the CONNECT method altogether, set the value to 0.
# If no ConnectPort line is found, all ports are allowed (which is not
# very secure.)
#
# The following two ports are used by SSL.
#
ConnectPort 443
ConnectPort 563

END
fi

}

initconfig


tinyproxy_port_dpt () {

if [ "$tinyproxy_port" = "1" ] ; then
	tinyproxyport=$(echo `cat /etc/storage/tinyproxy_script.sh | grep -v "^#" | grep -v "ConnectPort" | grep "Port" | sed 's/Port//'`)
	[ ! -z "$tinyproxyport" ] && port=$(iptables -t filter -L INPUT -v -n --line-numbers | grep dpt:$tinyproxyport | cut -d " " -f 1 | sort -nr | wc -l)
	if [ ! -z "$tinyproxyport" ] && [ "$port" = 0 ] ; then
		[ ! -z "$tinyproxyport" ] && logger -t "【tinyproxy】" "允许 $tinyproxyport 端口通过防火墙"
		[ ! -z "$tinyproxyport" ] && iptables -t filter -I INPUT -p tcp --dport $tinyproxyport -j ACCEPT
	fi
fi

}

case $ACTION in
start)
	tinyproxy_close
	tinyproxy_check
	;;
check)
	tinyproxy_check
	;;
stop)
	tinyproxy_close
	;;
keep)
	#tinyproxy_check
	tinyproxy_keep
	;;
*)
	tinyproxy_check
	;;
esac

