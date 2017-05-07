#!/bin/sh
#copyright by hiboy
source /etc/storage/script/init.sh
tinyproxyport=`nvram get tinyproxyport`
tinyproxy_enable=`nvram get tinyproxy_enable`
[ -z $tinyproxy_enable ] && tinyproxy_enable=0 && nvram set tinyproxy_enable=0
tinyproxy_path=`nvram get tinyproxy_path`
[ -z $tinyproxy_path ] && tinyproxy_path=`which tinyproxy` && nvram set tinyproxy_path="$tinyproxy_path"
if [ "$tinyproxy_enable" != "0" ] ; then
nvramshow=`nvram showall | grep tinyproxy | awk '{print gensub(/'"'"'/,"'"'"'\"'"'"'\"'"'"'","g",$0);}'| awk '{print gensub(/=/,"='\''",1,$0)"'\'';";}'` && eval $nvramshow
fi

if [ ! -z "$(echo $scriptfilepath | grep -v "/tmp/script/" | grep tinyproxy)" ]  && [ ! -s /tmp/script/_tinyproxy ]; then
	mkdir -p /tmp/script
	ln -sf $scriptfilepath /tmp/script/_tinyproxy
	chmod 777 /tmp/script/_tinyproxy
fi

tinyproxy_check () {
A_restart=`nvram get tinyproxy_status`
B_restart="$tinyproxy_enable$tinyproxy_path$tinyproxy_port$(cat /etc/storage/tinyproxy_script.sh | grep -v '^#' | grep -v "^$")"
B_restart=`echo -n "$B_restart" | md5sum | sed s/[[:space:]]//g | sed s/-//g`
if [ "$A_restart" != "$B_restart" ] ; then
	nvram set tinyproxy_status=$B_restart
	needed_restart=1
else
	needed_restart=0
fi
if [ "$tinyproxy_enable" != "1" ] && [ "$needed_restart" = "1" ] ; then
	[ ! -z "$(ps -w | grep "$tinyproxy_path" | grep -v grep )" ] && logger -t "【tinyproxy】" "停止 $tinyproxy_path" && tinyproxy_close
	{ eval $(ps -w | grep "$scriptname" | grep -v grep | awk '{print "kill "$1";";}'); exit 0; }
fi
if [ "$tinyproxy_enable" = "1" ] ; then
	if [ "$needed_restart" = "1" ] ; then
		tinyproxy_close
		tinyproxy_start
	else
		[ -z "$(ps -w | grep "$tinyproxy_path" | grep -v grep )" ] && nvram set tinyproxy_status=00 && { eval "$scriptfilepath start &"; exit 0; }
		tinyproxyport=$(echo `cat /etc/storage/tinyproxy_script.sh | grep -v "^#" | grep -v "ConnectPort" | grep "Port" | sed 's/Port//'`)
		[ ! -z "$tinyproxyport" ] && port=$(iptables -t filter -L INPUT -v -n --line-numbers | grep dpt:$tinyproxyport | cut -d " " -f 1 | sort -nr | wc -l)
		if [ ! -z "$tinyproxyport" ] && [ "$port" = 0 ] ; then
			[ ! -z "$tinyproxyport" ] && logger -t "【tinyproxy】" "允许 $tinyproxyport 端口通过防火墙"
			[ ! -z "$tinyproxyport" ] && iptables -I INPUT -p tcp --dport $tinyproxyport -j ACCEPT
		fi
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
		{ nvram set tinyproxy_status=00 && eval "$scriptfilepath &" ; exit 0; }
	fi
sleep 222
done
}

tinyproxy_close () {

sed -Ei '/【tinyproxy】|^$/d' /tmp/script/_opt_script_check
tinyproxyport=$(echo `cat /etc/storage/tinyproxy_script.sh | grep -v "^#" | grep -v "ConnectPort" | grep "Port" | sed 's/Port//'`)
[ ! -z "$tinyproxyport" ] && iptables -D INPUT -p tcp --dport $tinyproxyport -j ACCEPT
killall tinyproxy tinyproxy_script.sh
killall -9 tinyproxy tinyproxy_script.sh
[ ! -z "$tinyproxy_path" ] && eval $(ps -w | grep "$tinyproxy_path" | grep -v grep | awk '{print "kill "$1";";}')
eval $(ps -w | grep "_tinyproxy keep" | grep -v grep | awk '{print "kill "$1";";}')
eval $(ps -w | grep "_tinyproxy.sh keep" | grep -v grep | awk '{print "kill "$1";";}')
eval $(ps -w | grep "$scriptname keep" | grep -v grep | awk '{print "kill "$1";";}')
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
hash tinyproxy 2>/dev/null || rm -rf /opt/bin/tinyproxy
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
	logger -t "【tinyproxy】" "启动失败, 10 秒后自动尝试重新启动" && sleep 10 && { nvram set tinyproxy_status=00; eval "$scriptfilepath &"; exit 0; }
fi
if [ -s "$SVC_PATH" ] ; then
	nvram set tinyproxy_path="$SVC_PATH"
fi
tinyproxy_path="$SVC_PATH"
logger -t "【tinyproxy】" "运行 $tinyproxy_path"
$tinyproxy_path -c /etc/storage/tinyproxy_script.sh &
restart_dhcpd
B_restart="$tinyproxy_enable$tinyproxy_path$tinyproxy_port$(cat /etc/storage/tinyproxy_script.sh | grep -v '^#' | grep -v "^$")"
B_restart=`echo -n "$B_restart" | md5sum | sed s/[[:space:]]//g | sed s/-//g`
[ "$A_restart" != "$B_restart" ] && nvram set tinyproxy_status=$B_restart
sleep 2
[ ! -z "$(ps -w | grep "$tinyproxy_path" | grep -v grep )" ] && logger -t "【tinyproxy】" "启动成功"
[ -z "$(ps -w | grep "$tinyproxy_path" | grep -v grep )" ] && logger -t "【tinyproxy】" "启动失败, 注意检查端口是否有冲突,程序是否下载完整,10 秒后自动尝试重新启动" && sleep 10 && { nvram set tinyproxy_status=00; eval "$scriptfilepath &"; exit 0; }
if [ "$tinyproxy_port" = "1" ] ; then
	tinyproxyport=$(echo `cat /etc/storage/tinyproxy_script.sh | grep -v "^#" | grep -v "ConnectPort" | grep "Port" | sed 's/Port//'`)
	echo "tinyproxyport:$tinyproxyport"
	[ ! -z "$tinyproxyport" ] && logger -t "【tinyproxy】" "允许 $tinyproxyport 端口通过防火墙"
	[ ! -z "$tinyproxyport" ] && iptables -I INPUT -p tcp --dport $tinyproxyport -j ACCEPT
fi
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
	tinyproxy_check
	tinyproxy_keep
	;;
*)
	tinyproxy_check
	;;
esac

