#!/bin/sh
#copyright by hiboy
source /etc/storage/script/init.sh
virtualhere_enable=`nvram get app_24`
[ -z $virtualhere_enable ] && virtualhere_enable=0 && nvram set app_24=0
virtualhere_wan=`nvram get app_25`
[ -z $virtualhere_wan ] && virtualhere_wan=0 && nvram set app_25=0
#if [ "$virtualhere_enable" != "0" ] ; then
#nvramshow=`nvram showall | grep '=' | grep virtualhere | awk '{print gensub(/'"'"'/,"'"'"'\"'"'"'\"'"'"'","g",$0);}'| awk '{print gensub(/=/,"='\''",1,$0)"'\'';";}'` && eval $nvramshow
#fi

if [ ! -z "$(echo $scriptfilepath | grep -v "/tmp/script/" | grep virtual_here)" ]  && [ ! -s /tmp/script/_app8 ]; then
	mkdir -p /tmp/script
	{ echo '#!/bin/sh' ; echo $scriptfilepath '"$@"' '&' ; } > /tmp/script/_app8
	chmod 777 /tmp/script/_app8
fi

virtualhere_restart () {

relock="/var/lock/virtualhere_restart.lock"
if [ "$1" = "o" ] ; then
	nvram set virtualhere_renum="0"
	[ -f $relock ] && rm -f $relock
	return 0
fi
if [ "$1" = "x" ] ; then
	if [ -f $relock ] ; then
		logger -t "【virtualhere】" "多次尝试启动失败，等待【"`cat $relock`"分钟】后自动尝试重新启动"
		exit 0
	fi
	virtualhere_renum=${virtualhere_renum:-"0"}
	virtualhere_renum=`expr $virtualhere_renum + 1`
	nvram set virtualhere_renum="$virtualhere_renum"
	if [ "$virtualhere_renum" -gt "2" ] ; then
		I=19
		echo $I > $relock
		logger -t "【virtualhere】" "多次尝试启动失败，等待【"`cat $relock`"分钟】后自动尝试重新启动"
		while [ $I -gt 0 ]; do
			I=$(($I - 1))
			echo $I > $relock
			sleep 60
			[ "$(nvram get virtualhere_renum)" = "0" ] && exit 0
			[ $I -lt 0 ] && break
		done
		nvram set virtualhere_renum="0"
	fi
	[ -f $relock ] && rm -f $relock
fi
nvram set virtualhere_status=0
eval "$scriptfilepath &"
exit 0
}

virtualhere_get_status () {

A_restart=`nvram get virtualhere_status`
B_restart="$virtualhere_enable$virtualhere_wan$(cat /etc/storage/app_8.sh | grep -v "^#" | grep -v "^$")"
B_restart=`echo -n "$B_restart" | md5sum | sed s/[[:space:]]//g | sed s/-//g`
if [ "$A_restart" != "$B_restart" ] ; then
	nvram set virtualhere_status=$B_restart
	needed_restart=1
else
	needed_restart=0
fi
}

virtualhere_check () {

virtualhere_get_status
if [ "$virtualhere_enable" != "1" ] && [ "$needed_restart" = "1" ] ; then
	[ ! -z "`pidof virtualhere`" ] && logger -t "【virtualhere】" "停止 virtualhere" && virtualhere_close
	{ kill_ps "$scriptname" exit0; exit 0; }
fi
if [ "$virtualhere_enable" = "1" ] ; then
	if [ "$needed_restart" = "1" ] ; then
		virtualhere_close
		virtualhere_start
	else
		[ -z "`pidof virtualhere`" ] && virtualhere_restart
		virtualhere_port_dpt
	fi
fi
}

virtualhere_keep () {
logger -t "【virtualhere】" "守护进程启动"
if [ -s /tmp/script/_opt_script_check ]; then
sed -Ei '/【virtualhere】|^$/d' /tmp/script/_opt_script_check
cat >> "/tmp/script/_opt_script_check" <<-OSC
[ -z "\`pidof virtualhere\`" ] && nvram set virtualhere_status=00 && logger -t "【virtualhere】" "重新启动" && eval "$scriptfilepath &" && sed -Ei '/【virtualhere】|^$/d' /tmp/script/_opt_script_check # 【virtualhere】
OSC
return
fi

while true; do
	if [ -z "`pidof virtualhere`" ] ; then
		logger -t "【virtualhere】" "重新启动"
		virtualhere_restart
	fi
sleep 252
done
}

virtualhere_close () {

iptables -t filter -D INPUT -p tcp --dport 7575 -j ACCEPT
sed -Ei '/【virtualhere】|^$/d' /tmp/script/_opt_script_check
killall virtualhere
killall -9 virtualhere
kill_ps "/tmp/script/_app8"
kill_ps "_virtual_here.sh"
kill_ps "$scriptname"
}

virtualhere_start () {

SVC_PATH="/opt/bin/virtualhere"
if [ ! -s "$SVC_PATH" ] ; then
	logger -t "【virtualhere】" "找不到 $SVC_PATH，安装 opt 程序"
	/tmp/script/_mountopt start
fi
if [ ! -s "$SVC_PATH" ] ; then
	logger -t "【virtualhere】" "找不到 $SVC_PATH ，安装 virtualhere 程序"
	logger -t "【virtualhere】" "开始下载 virtualhere"
	wgetcurl.sh "/opt/bin/virtualhere" "$hiboyfile/virtualhere" "$hiboyfile2/virtualhere"
fi
chmod 777 "$SVC_PATH"

[[ "$(virtualhere -h 2>&1 | wc -l)" -lt 2 ]] && rm -rf /opt/bin/virtualhere
if [ ! -s "$SVC_PATH" ] ; then
	logger -t "【virtualhere】" "找不到 $SVC_PATH ，需要手动安装 $SVC_PATH"
	logger -t "【virtualhere】" "启动失败, 10 秒后自动尝试重新启动" && sleep 10 && virtualhere_restart x
fi
chmod 777 "$SVC_PATH"
virtualhere_v=$(virtualhere -h | grep virtualhere | sed -n '1p')
nvram set virtualhere_v="$virtualhere_v"
logger -t "【virtualhere】" "运行 virtualhere"

#运行脚本启动/opt/bin/virtualhere
cd $(dirname `which virtualhere`)
killall -9 virtualhere
ln -sf /etc/storage/app_8.sh ~/config.ini
./virtualhere -b

sleep 2
[ ! -z "$(ps -w | grep "virtualhere" | grep -v grep )" ] && logger -t "【virtualhere】" "启动成功" && virtualhere_restart o
[ -z "$(ps -w | grep "virtualhere" | grep -v grep )" ] && logger -t "【virtualhere】" "启动失败, 注意检查端口是否有冲突,程序是否下载完整,10 秒后自动尝试重新启动" && sleep 10 && virtualhere_restart x
initopt
virtualhere_port_dpt
#virtualhere_get_status
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
	if [ ! -f "/etc/storage/app_8.sh" ] || [ ! -s "/etc/storage/app_8.sh" ] ; then
cat > "/etc/storage/app_8.sh" <<-\VVR
ServerName=$HOSTNAME$

VVR
	fi

ln -sf /etc/storage/app_8.sh ~/config.ini

}

initconfig

virtualhere_port_dpt () {

if [ "$virtualhere_wan" = "1" ] ; then
	port=$(iptables -t filter -L INPUT -v -n --line-numbers | grep dpt:7575 | cut -d " " -f 1 | sort -nr | wc -l)
	if [ "$port" = 0 ] ; then
		logger -t "【virtualhere】" "允许 7575 tcp端口通过防火墙"
		iptables -t filter -I INPUT -p tcp --dport 7575 -j ACCEPT
		iptables -t filter -I INPUT -p udp --dport 7575 -j ACCEPT
	fi
fi
}

update_app () {

mkdir -p /opt/app/virtualhere
if [ "$1" = "del" ] ; then
	rm -rf /opt/app/virtualhere/Advanced_Extensions_virtualhere.asp
	[ -f /opt/bin/virtualhere ] && rm -f /opt/bin/virtualhere
fi

initconfig

# 加载程序配置页面
if [ ! -f "/opt/app/virtualhere/Advanced_Extensions_virtualhere.asp" ] || [ ! -s "/opt/app/virtualhere/Advanced_Extensions_virtualhere.asp" ] ; then
	wgetcurl.sh /opt/app/virtualhere/Advanced_Extensions_virtualhere.asp "$hiboyfile/Advanced_Extensions_virtualhereasp" "$hiboyfile2/Advanced_Extensions_virtualhereasp"
fi
umount /www/Advanced_Extensions_app08.asp
mount --bind /opt/app/virtualhere/Advanced_Extensions_virtualhere.asp /www/Advanced_Extensions_app08.asp
# 更新程序启动脚本

[ "$1" = "del" ] && /etc/storage/www_sh/virtualhere del &
}

case $ACTION in
start)
	virtualhere_close
	virtualhere_check
	;;
check)
	virtualhere_check
	;;
stop)
	virtualhere_close
	;;
updateapp8)
	virtualhere_restart o
	[ "$virtualhere_enable" = "1" ] && nvram set virtualhere_status="updatevirtualhere" && logger -t "【virtualhere】" "重启" && virtualhere_restart
	[ "$virtualhere_enable" != "1" ] && nvram set virtualhere_v="" && logger -t "【virtualhere】" "更新" && update_app del
	;;
update_app)
	update_app
	;;
keep)
	#virtualhere_check
	virtualhere_keep
	;;
initconfig)
	initconfig
	;;
*)
	virtualhere_check
	;;
esac

