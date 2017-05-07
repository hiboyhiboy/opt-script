#!/bin/sh
#copyright by hiboy
source /etc/storage/script/init.sh
mproxyport=`nvram get mproxyport`
mproxy_enable=`nvram get mproxy_enable`
[ -z $mproxy_enable ] && mproxy_enable=0 && nvram set mproxy_enable=0
if [ "$mproxy_enable" != "0" ] ; then
nvramshow=`nvram showall | grep mproxy | awk '{print gensub(/'"'"'/,"'"'"'\"'"'"'\"'"'"'","g",$0);}'| awk '{print gensub(/=/,"='\''",1,$0)"'\'';";}'` && eval $nvramshow
fi

if [ ! -z "$(echo $scriptfilepath | grep -v "/tmp/script/" | grep mproxy)" ]  && [ ! -s /tmp/script/_mproxy ]; then
	mkdir -p /tmp/script
	ln -sf $scriptfilepath /tmp/script/_mproxy
	chmod 777 /tmp/script/_mproxy
fi

mproxy_check () {
A_restart=`nvram get mproxy_status`
B_restart="$mproxy_enable$mproxy_port$(cat /etc/storage/mproxy_script.sh | grep -v '^#' | grep -v "^$")"
B_restart=`echo -n "$B_restart" | md5sum | sed s/[[:space:]]//g | sed s/-//g`
if [ "$A_restart" != "$B_restart" ] ; then
	nvram set mproxy_status=$B_restart
	needed_restart=1
else
	needed_restart=0
fi
if [ "$mproxy_enable" != "1" ] && [ "$needed_restart" = "1" ] ; then
	[ ! -z "`pidof mproxy`" ] && logger -t "【mproxy】" "停止 mproxy" && mproxy_close
	{ eval $(ps -w | grep "$scriptname" | grep -v grep | awk '{print "kill "$1";";}'); exit 0; }
fi
if [ "$mproxy_enable" = "1" ] ; then
	if [ "$needed_restart" = "1" ] ; then
		mproxy_close
		mproxy_start
	else
		[ -z "`pidof mproxy`" ] && nvram set mproxy_status=00 && { eval "$scriptfilepath start &"; exit 0; }
		mproxyport=$(echo `cat /etc/storage/mproxy_script.sh | grep -v "^#" | grep "mproxy_port=" | sed 's/mproxy_port=//'`)
		[ ! -z "$mproxyport" ] && port=$(iptables -t filter -L INPUT -v -n --line-numbers | grep dpt:$mproxyport | cut -d " " -f 1 | sort -nr | wc -l)
		if [ ! -z "$mproxyport" ] && [ "$port" = 0 ] ; then
			[ ! -z "$mproxyport" ] && logger -t "【mproxy】" "允许 $mproxyport 端口通过防火墙"
			[ ! -z "$mproxyport" ] && iptables -I INPUT -p tcp --dport $mproxyport -j ACCEPT
		fi
	fi
fi
}

mproxy_keep () {
logger -t "【mproxy】" "守护进程启动"
if [ -s /tmp/script/_opt_script_check ]; then
sed -Ei '/【mproxy】|^$/d' /tmp/script/_opt_script_check
cat >> "/tmp/script/_opt_script_check" <<-OSC
[ -z "\`pidof mproxy\`" ] || [ ! -s "`which mproxy`" ] && nvram set mproxy_status=00 && logger -t "【mproxy】" "重新启动" && eval "$scriptfilepath &" && sed -Ei '/【mproxy】|^$/d' /tmp/script/_opt_script_check # 【mproxy】
OSC
return
fi
while true; do
	if [ -z "`pidof mproxy`" ] || [ ! -s "`which mproxy`" ] ; then
		logger -t "【mproxy】" "重新启动"
		{ nvram set mproxy_status=00 && eval "$scriptfilepath &" ; exit 0; }
	fi
sleep 221
done
}

mproxy_close () {

sed -Ei '/【mproxy】|^$/d' /tmp/script/_opt_script_check
mproxyport=$(echo `cat /etc/storage/mproxy_script.sh | grep -v "^#" | grep "mproxy_port=" | sed 's/mproxy_port=//'`)
[ ! -z "$mproxyport" ] && iptables -D INPUT -p tcp --dport $mproxyport -j ACCEPT
killall mproxy mproxy_script.sh
killall -9 mproxy mproxy_script.sh
eval $(ps -w | grep "_mproxy keep" | grep -v grep | awk '{print "kill "$1";";}')
eval $(ps -w | grep "_mproxy.sh keep" | grep -v grep | awk '{print "kill "$1";";}')
eval $(ps -w | grep "$scriptname keep" | grep -v grep | awk '{print "kill "$1";";}')
}

mproxy_start () {
SVC_PATH="/usr/sbin/mproxy"
if [ ! -s "$SVC_PATH" ] ; then
	SVC_PATH="/etc/storage/bin/mproxy"
fi
if [ ! -s "$SVC_PATH" ] ; then
	SVC_PATH="/usr/sbin/mproxy"
fi
if [ ! -s "$SVC_PATH" ] ; then
	SVC_PATH="/opt/bin/mproxy"
fi
hash mproxy 2>/dev/null || rm -rf /opt/bin/mproxy
if [ ! -s "$SVC_PATH" ] ; then
	logger -t "【mproxy】" "找不到 mproxy，安装 opt 程序"
	/tmp/script/_mountopt start
	initopt
fi
if [ ! -s "$SVC_PATH" ] ; then
	logger -t "【mproxy】" "找不到 $SVC_PATH 下载程序"
	wgetcurl.sh /opt/bin/mproxy "$hiboyfile/mproxy" "$hiboyfile2/mproxy"
	chmod 755 "/opt/bin/mproxy"
else
	logger -t "【mproxy】" "找到 $SVC_PATH"
fi
if [ ! -s "$SVC_PATH" ] ; then
	logger -t "【mproxy】" "找不到 $SVC_PATH ，需要手动安装 $SVC_PATH"
	logger -t "【mproxy】" "启动失败, 10 秒后自动尝试重新启动" && sleep 10 && { nvram set mproxy_status=00; eval "$scriptfilepath &"; exit 0; }
fi
logger -t "【mproxy】" "运行 mproxy_script"
/etc/storage/mproxy_script.sh &
restart_dhcpd
sleep 2
[ ! -z "`pidof mproxy`" ] && logger -t "【mproxy】" "启动成功"
[ -z "`pidof mproxy`" ] && logger -t "【mproxy】" "启动失败, 注意检查端口是否有冲突,程序是否下载完整, 10 秒后自动尝试重新启动" && sleep 10 && { nvram set mproxy_status=00; eval "$scriptfilepath &"; exit 0; }
if [ "$mproxy_port" = "1" ] ; then
	mproxyport=$(echo `cat /etc/storage/mproxy_script.sh | grep -v "^#" | grep "mproxy_port=" | sed 's/mproxy_port=//'`)
	echo "mproxyport:$mproxyport"
	[ ! -z "$mproxyport" ] && logger -t "【mproxy】" "允许 $mproxyport 端口通过防火墙"
	[ ! -z "$mproxyport" ] && iptables -I INPUT -p tcp --dport $mproxyport -j ACCEPT
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
	mproxy_close
	mproxy_check
	;;
check)
	mproxy_check
	;;
stop)
	mproxy_close
	;;
keep)
	mproxy_check
	mproxy_keep
	;;
*)
	mproxy_check
	;;
esac

