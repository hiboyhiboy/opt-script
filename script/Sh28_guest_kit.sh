#!/bin/sh
#copyright by hiboy
source /etc/storage/script/init.sh
guestkit_enable=`nvram get app_26`
[ -z $guestkit_enable ] && guestkit_enable=0 && nvram set app_26=0
#if [ "$guestkit_enable" != "0" ] ; then
#nvramshow=`nvram showall | grep '=' | grep guestkit | awk '{print gensub(/'"'"'/,"'"'"'\"'"'"'\"'"'"'","g",$0);}'| awk '{print gensub(/=/,"='\''",1,$0)"'\'';";}'` && eval $nvramshow
#fi

if [ ! -z "$(echo $scriptfilepath | grep -v "/tmp/script/" | grep guest_kit)" ]  && [ ! -s /tmp/script/_app9 ]; then
	mkdir -p /tmp/script
	{ echo '#!/bin/sh' ; echo $scriptfilepath '"$@"' '&' ; } > /tmp/script/_app9
	chmod 777 /tmp/script/_app9
fi

guestkit_restart () {

relock="/var/lock/guestkit_restart.lock"
if [ "$1" = "o" ] ; then
	nvram set guestkit_renum="0"
	[ -f $relock ] && rm -f $relock
	return 0
fi
if [ "$1" = "x" ] ; then
	if [ -f $relock ] ; then
		logger -t "【guestkit】" "多次尝试启动失败，等待【"`cat $relock`"分钟】后自动尝试重新启动"
		exit 0
	fi
	guestkit_renum=${guestkit_renum:-"0"}
	guestkit_renum=`expr $guestkit_renum + 1`
	nvram set guestkit_renum="$guestkit_renum"
	if [ "$guestkit_renum" -gt "2" ] ; then
		I=19
		echo $I > $relock
		logger -t "【guestkit】" "多次尝试启动失败，等待【"`cat $relock`"分钟】后自动尝试重新启动"
		while [ $I -gt 0 ]; do
			I=$(($I - 1))
			echo $I > $relock
			sleep 60
			[ "$(nvram get guestkit_renum)" = "0" ] && exit 0
			[ $I -lt 0 ] && break
		done
		nvram set guestkit_renum="0"
	fi
	[ -f $relock ] && rm -f $relock
fi
nvram set guestkit_status=0
eval "$scriptfilepath &"
exit 0
}

guestkit_get_status () {

A_restart=`nvram get guestkit_status`
B_restart="$guestkit_enable"
B_restart=`echo -n "$B_restart" | md5sum | sed s/[[:space:]]//g | sed s/-//g`
if [ "$A_restart" != "$B_restart" ] ; then
	nvram set guestkit_status=$B_restart
	needed_restart=1
else
	needed_restart=0
fi
}

guestkit_check () {

guestkit_get_status
if [ "$guestkit_enable" != "1" ] && [ "$needed_restart" = "1" ] ; then
	[ ! -z "`pidof guestkit`" ] && logger -t "【guestkit】" "停止 guestkit" && guestkit_close
	{ kill_ps "$scriptname" exit0; exit 0; }
fi
if [ "$guestkit_enable" = "1" ] ; then
	if [ "$needed_restart" = "1" ] ; then
		guestkit_close
		guestkit_start
	else
		[ -z "`pidof guestkit`" ] && guestkit_restart
		guestkit_port_dpt
	fi
fi
}

guestkit_keep () {
logger -t "【guestkit】" "守护进程启动"
if [ -s /tmp/script/_opt_script_check ]; then
sed -Ei '/【guestkit】|^$/d' /tmp/script/_opt_script_check
cat >> "/tmp/script/_opt_script_check" <<-OSC
[ -z "\`pidof guestkit\`" ] && nvram set guestkit_status=00 && logger -t "【guestkit】" "重新启动" && eval "$scriptfilepath &" && sed -Ei '/【guestkit】|^$/d' /tmp/script/_opt_script_check # 【guestkit】
OSC
return
fi

while true; do
	if [ -z "`pidof guestkit`" ] ; then
		logger -t "【guestkit】" "重新启动"
		guestkit_restart
	fi
sleep 252
done
}

guestkit_close () {

iptables -t filter -D INPUT -p tcp --dport 7575 -j ACCEPT
sed -Ei '/【guestkit】|^$/d' /tmp/script/_opt_script_check
killall guestkit
killall -9 guestkit
kill_ps "/tmp/script/_app9"
kill_ps "_guest_kit.sh"
kill_ps "$scriptname"
}

guestkit_start () {

SVC_PATH="/opt/bin/guestkit"
if [ ! -s "$SVC_PATH" ] ; then
	logger -t "【guestkit】" "找不到 $SVC_PATH，安装 opt 程序"
	/tmp/script/_mountopt start
fi
if [ ! -s "$SVC_PATH" ] ; then
	logger -t "【guestkit】" "找不到 $SVC_PATH ，安装 guestkit 程序"
	logger -t "【guestkit】" "开始下载 guestkit"
	wgetcurl.sh "/opt/bin/guestkit" "$hiboyfile/guestkit" "$hiboyfile2/guestkit"
fi
chmod 777 "$SVC_PATH"

[[ "$(guestkit -h 2>&1 | wc -l)" -lt 2 ]] && rm -rf /opt/bin/guestkit
if [ ! -s "$SVC_PATH" ] ; then
	logger -t "【guestkit】" "找不到 $SVC_PATH ，需要手动安装 $SVC_PATH"
	logger -t "【guestkit】" "启动失败, 10 秒后自动尝试重新启动" && sleep 10 && guestkit_restart x
fi
chmod 777 "$SVC_PATH"
guestkit_v=$(guestkit -h | grep guestkit | sed -n '1p')
nvram set guestkit_v="$guestkit_v"
logger -t "【guestkit】" "运行 guestkit"

#运行/opt/bin/guestkit
cd $(dirname `which guestkit`)
killall -9 guestkit
./guestkit &
sleep 5
[ ! -z "$(ps -w | grep "guestkit" | grep -v grep )" ] && logger -t "【guestkit】" "启动成功" && guestkit_restart o
[ -z "$(ps -w | grep "guestkit" | grep -v grep )" ] && logger -t "【guestkit】" "启动失败, 注意检查32121端口是否有冲突,程序是否下载完整,10 秒后自动尝试重新启动" && sleep 10 && guestkit_restart x
initopt
#guestkit_get_status
eval "$scriptfilepath keep &"
exit 0
}

initopt () {
optPath=`grep ' /opt ' /proc/mounts | grep tmpfs`
[ ! -z "$optPath" ] && return
if [ ! -z "$(echo $scriptfilepath | grep -v "/opt/etc/init")" ] && [ -s "/opt/etc/init.d/rc.func" ] ; then
	{ echo '#!/bin/sh' ; echo $scriptfilepath '"$@"' '&' ; } > /opt/etc/init.d/$scriptname && chmod 777  /opt/etc/init.d/$scriptname
fi

}

initconfig () {
echo "initconfig"
}

initconfig

update_app () {

mkdir -p /opt/app/guestkit
if [ "$1" = "del" ] ; then
	rm -rf /opt/app/guestkit/Advanced_Extensions_guestkit.asp
	[ -f /opt/bin/guestkit ] && rm -f /opt/bin/guestkit
	rm -f /etc/storage/guestkit_db/*
fi

initconfig

# 加载程序配置页面
if [ ! -f "/opt/app/guestkit/Advanced_Extensions_guestkit.asp" ] || [ ! -s "/opt/app/guestkit/Advanced_Extensions_guestkit.asp" ] ; then
	wgetcurl.sh /opt/app/guestkit/Advanced_Extensions_guestkit.asp "$hiboyfile/Advanced_Extensions_guestkitasp" "$hiboyfile2/Advanced_Extensions_guestkitasp"
fi
umount /www/Advanced_Extensions_app09.asp
mount --bind /opt/app/guestkit/Advanced_Extensions_guestkit.asp /www/Advanced_Extensions_app09.asp
# 更新程序启动脚本

[ "$1" = "del" ] && /etc/storage/www_sh/guestkit del &
}

case $ACTION in
start)
	guestkit_close
	guestkit_check
	;;
check)
	guestkit_check
	;;
stop)
	guestkit_close
	;;
updateapp9)
	guestkit_restart o
	[ "$guestkit_enable" = "1" ] && nvram set guestkit_status="updateguestkit" && logger -t "【guestkit】" "重启" && guestkit_restart
	[ "$guestkit_enable" != "1" ] && nvram set guestkit_v="" && logger -t "【guestkit】" "更新" && update_app del
	;;
update_app)
	update_app
	;;
keep)
	#guestkit_check
	guestkit_keep
	;;
initconfig)
	initconfig
	;;
*)
	guestkit_check
	;;
esac

