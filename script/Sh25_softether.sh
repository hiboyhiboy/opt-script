#!/bin/sh
#copyright by hiboy
source /etc/storage/script/init.sh
softether_enable=`nvram get softether_enable`
[ -z $softether_enable ] && softether_enable=0 && nvram set softether_enable=0
softether_path=`nvram get softether_path`
softether_path=${softether_path:-"/opt/softether/vpnserver"}
if [ "$softether_enable" != "0" ] ; then
nvramshow=`nvram showall | grep softether | awk '{print gensub(/'"'"'/,"'"'"'\"'"'"'\"'"'"'","g",$0);}'| awk '{print gensub(/=/,"='\''",1,$0)"'\'';";}'` && eval $nvramshow
fi

if [ ! -z "$(echo $scriptfilepath | grep -v "/tmp/script/" | grep softether)" ]  && [ ! -s /tmp/script/_softether ]; then
	mkdir -p /tmp/script
	ln -sf $scriptfilepath /tmp/script/_softether
	chmod 777 /tmp/script/_softether
fi

softether_check () {
SVC_PATH="$softether_path"
A_restart=`nvram get softether_status`
B_restart="$softether_enable$softether_path$(cat /etc/storage/softether_script.sh | grep -v '^#' | grep -v "^$")"
B_restart=`echo -n "$B_restart" | md5sum | sed s/[[:space:]]//g | sed s/-//g`
if [ "$A_restart" != "$B_restart" ] ; then
	nvram set softether_status=$B_restart
	needed_restart=1
else
	needed_restart=0
fi
if [ "$softether_enable" != "1" ] && [ "$needed_restart" = "1" ] ; then
	[ ! -z "$(ps -w | grep "$softether_path" | grep -v grep )" ] && logger -t "【softether】" "停止 softether" && softether_close
	{ eval $(ps -w | grep "$scriptname" | grep -v grep | awk '{print "kill "$1";";}'); exit 0; }
fi
if [ "$softether_enable" = "1" ] ; then
	if [ "$needed_restart" = "1" ] ; then
		softether_close
		softether_start
	else
		[ -z "$(ps -w | grep "$softether_path" | grep -v grep )" ] && nvram set softether_status=00 && { eval "$scriptfilepath start &"; exit 0; }
		port=$(iptables -t filter -L INPUT -v -n --line-numbers | grep dpt:500 | cut -d " " -f 1 | sort -nr | wc -l)
		if [ "$port" = 0 ] ; then
		logger -t "【softether】" "允许 500、4500、1701 udp端口通过防火墙"
		iptables -I INPUT -p udp --destination-port 500 -j ACCEPT
		iptables -I INPUT -p udp --destination-port 4500 -j ACCEPT
		iptables -I INPUT -p udp --destination-port 1701 -j ACCEPT
		fi
	fi
fi
}

softether_keep () {
logger -t "【softether】" "守护进程启动"
if [ -s /tmp/script/_opt_script_check ]; then
sed -Ei '/【softether】|^$/d' /tmp/script/_opt_script_check
cat >> "/tmp/script/_opt_script_check" <<-OSC
	NUM=\`grep "$softether_path" /tmp/ps | grep -v grep |wc -l\` # 【softether】
	if [ "\$NUM" -lt "1" ] || [ ! -s "$softether_path" ] ; then # 【softether】
		logger -t "【softether】" "重新启动\$NUM" # 【softether】
		nvram set softether_status=00 && eval "$scriptfilepath &" && sed -Ei '/【softether】|^$/d' /tmp/script/_opt_script_check # 【softether】
	fi # 【softether】
OSC
return
fi

while true; do
	NUM=`ps -w | grep "$softether_path" | grep -v grep |wc -l`
	if [ "$NUM" -lt "1" ] || [ ! -s "$softether_path" ] ; then
		logger -t "【softether】" "重新启动$NUM"
		{ nvram set softether_status=00 && eval "$scriptfilepath &" ; exit 0; }
	fi
sleep 225
done
}

softether_close () {

sed -Ei '/【softether】|^$/d' /tmp/script/_opt_script_check
iptables -D INPUT -p udp --destination-port 500 -j ACCEPT
iptables -D INPUT -p udp --destination-port 4500 -j ACCEPT
iptables -D INPUT -p udp --destination-port 1701 -j ACCEPT
[ ! -z "$softether_path" ] && $softether_path stop
[ ! -z "$softether_path" ] && eval $(ps -w | grep "$softether_path" | grep -v grep | awk '{print "kill "$1";";}')
killall vpnserver softether_script.sh
killall -9 vpnserver softether_script.sh
eval $(ps -w | grep "_softether keep" | grep -v grep | awk '{print "kill "$1";";}')
eval $(ps -w | grep "_softether.sh keep" | grep -v grep | awk '{print "kill "$1";";}')
eval $(ps -w | grep "$scriptname keep" | grep -v grep | awk '{print "kill "$1";";}')
}

softether_start () {
SVC_PATH="$softether_path"
if [ ! -s "$SVC_PATH" ] ; then
	SVC_PATH="/opt/softether/vpnserver"
fi
if [ ! -s "$SVC_PATH" ] ; then
	logger -t "【softether】" "找不到 $SVC_PATH，安装 opt 程序"
	/tmp/script/_mountopt start
fi
mkdir -p /opt/softether
if [ ! -s "$SVC_PATH" ] ; then
	logger -t "【softether】" "找不到 $SVC_PATH 下载程序"
	wgetcurl.sh /opt/softether/vpnserver "$hiboyfile/vpnserver" "$hiboyfile2/vpnserver"
	chmod 755 "/opt/softether/vpnserver"
	wgetcurl.sh /opt/softether/vpncmd "$hiboyfile/vpncmd" "$hiboyfile2/vpncmd"
	chmod 755 "/opt/softether/vpncmd"
	wgetcurl.sh /opt/softether/hamcore.se2 "$hiboyfile/hamcore.se2" "$hiboyfile2/hamcore.se2"
	chmod 755 "/opt/softether/hamcore.se2"
else
	logger -t "【softether】" "找到 $SVC_PATH"
fi
if [ ! -s "$SVC_PATH" ] ; then
	logger -t "【softether】" "找不到 $SVC_PATH ，需要手动安装 $SVC_PATH"
	logger -t "【softether】" "启动失败, 10 秒后自动尝试重新启动" && sleep 10 && { nvram set softether_status=00; eval "$scriptfilepath &"; exit 0; }
fi
if [ -s "$SVC_PATH" ] ; then
	nvram set softether_path="$SVC_PATH"
	B_restart="$softether_enable$softether_path$(cat /etc/storage/softether_script.sh | grep -v '^#' | grep -v "^$")"
	B_restart=`echo -n "$B_restart" | md5sum | sed s/[[:space:]]//g | sed s/-//g`
	[ "$A_restart" != "$B_restart" ] && nvram set softether_status=$B_restart
fi
softether_path="$SVC_PATH"
logger -t "【softether】" "运行 softether_script"
$softether_path stop
/etc/storage/softether_script.sh &
sleep 3
[ ! -z "`pidof vpnserver`" ] && logger -t "【softether】" "启动成功"
[ -z "`pidof vpnserver`" ] && logger -t "【softether】" "启动失败, 注意检查hamcore.se2、vpncmd、vpnserver是否下载完整,10 秒后自动尝试重新启动" && sleep 10 && { rm -f $softether_path ; nvram set softether_status=00; eval "$scriptfilepath &"; exit 0; }

logger -t "【softether】" "允许 500、4500、1701 udp端口通过防火墙"
iptables -I INPUT -p udp --destination-port 500 -j ACCEPT
iptables -I INPUT -p udp --destination-port 4500 -j ACCEPT
iptables -I INPUT -p udp --destination-port 1701 -j ACCEPT

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
	softether_close
	softether_check
	;;
check)
	softether_check
	;;
stop)
	softether_close
	;;
keep)
	softether_check
	softether_keep
	;;
*)
	softether_check
	;;
esac

