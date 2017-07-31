#!/bin/sh
#copyright by hiboy
source /etc/storage/script/init.sh
serverchan_enable=`nvram get serverchan_enable`
[ -z $serverchan_enable ] && serverchan_enable=0 && nvram set serverchan_enable=0
if [ "$serverchan_enable" != "0" ] ; then
nvramshow=`nvram showall | grep '=' | grep serverchan | awk '{print gensub(/'"'"'/,"'"'"'\"'"'"'\"'"'"'","g",$0);}'| awk '{print gensub(/=/,"='\''",1,$0)"'\'';";}'` && eval $nvramshow
fi

if [ ! -z "$(echo $scriptfilepath | grep -v "/tmp/script/" | grep server_chan)" ]  && [ ! -s /tmp/script/_server_chan ]; then
	mkdir -p /tmp/script
	{ echo '#!/bin/sh' ; echo $scriptfilepath '"$@"' '&' ; } > /tmp/script/_server_chan
	chmod 777 /tmp/script/_server_chan
fi

serverchan_restart () {

relock="/var/lock/serverchan_restart.lock"
if [ "$1" = "o" ] ; then
	nvram set serverchan_renum="0"
	[ -f $relock ] && rm -f $relock
	return 0
fi
if [ "$1" = "x" ] ; then
	if [ -f $relock ] ; then
		logger -t "【serverchan】" "多次尝试启动失败，等待【"`cat $relock`"分钟】后自动尝试重新启动"
		exit 0
	fi
	serverchan_renum=${serverchan_renum:-"0"}
	serverchan_renum=`expr $serverchan_renum + 1`
	nvram set serverchan_renum="$serverchan_renum"
	if [ "$serverchan_renum" -gt "2" ] ; then
		I=19
		echo $I > $relock
		logger -t "【serverchan】" "多次尝试启动失败，等待【"`cat $relock`"分钟】后自动尝试重新启动"
		while [ $I -gt 0 ]; do
			I=$(($I - 1))
			echo $I > $relock
			sleep 60
			[ "$(nvram get serverchan_renum)" = "0" ] && exit 0
			[ $I -lt 0 ] && break
		done
		nvram set serverchan_renum="0"
	fi
	[ -f $relock ] && rm -f $relock
fi
nvram set serverchan_status=0
eval "$scriptfilepath &"
exit 0
}

serverchan_get_status () {

A_restart=`nvram get serverchan_status`
B_restart="$serverchan_enable$serverchan_sckey$serverchan_notify_1$serverchan_notify_2$serverchan_notify_3$serverchan_notify_4$(cat /etc/storage/serverchan_script.sh | grep -v '^#' | grep -v "^$")"
B_restart=`echo -n "$B_restart" | md5sum | sed s/[[:space:]]//g | sed s/-//g`
if [ "$A_restart" != "$B_restart" ] ; then
	nvram set serverchan_status=$B_restart
	needed_restart=1
else
	needed_restart=0
fi
}

serverchan_check () {

serverchan_get_status
if [ "$serverchan_enable" != "1" ] && [ "$needed_restart" = "1" ] ; then
	[ ! -z "$(ps -w | grep "serverchan_scri" | grep -v grep )" ] && logger -t "【微信推送】" "停止 serverchan" && serverchan_close
	{ eval $(ps -w | grep "$scriptname" | grep -v grep | awk '{print "kill "$1";";}'); exit 0; }
fi
if [ "$serverchan_enable" = "1" ] ; then
	if [ "$needed_restart" = "1" ] ; then
		serverchan_close
		serverchan_start
	else
		[ -z "$(ps -w | grep "serverchan_scri" | grep -v grep )" ] || [ ! -s "`which curl`" ] && serverchan_restart
	fi
fi
}

serverchan_keep () {
logger -t "【微信推送】" "守护进程启动"
if [ -s /tmp/script/_opt_script_check ]; then
sed -Ei '/【微信推送】|^$/d' /tmp/script/_opt_script_check
cat >> "/tmp/script/_opt_script_check" <<-OSC
	NUM=\`grep "/etc/storage/serverchan_script.sh" /tmp/ps | grep -v grep |wc -l\` # 【微信推送】
	if [ "\$NUM" -lt "1" ] || [ ! -s "/etc/storage/serverchan_script.sh" ] || [ ! -s "`which curl`" ] ; then # 【微信推送】
		logger -t "【微信推送】" "重新启动\$NUM" # 【微信推送】
		nvram set serverchan_status=04 && eval "$scriptfilepath &" && sed -Ei '/【微信推送】|^$/d' /tmp/script/_opt_script_check # 【微信推送】
	fi # 【微信推送】
OSC
#return
fi

while true; do
	[ ! -s "`which curl`" ] && { logger -t "【微信推送】" "重新启动"; serverchan_restart ; }
	if [ -z "$(ps -w | grep "serverchan_scri" | grep -v grep )" ] ; then
		logger -t "【微信推送】" "重新启动"
		serverchan_restart
	fi
	
sleep 3600
killall serverchan_script.sh
killall -9 serverchan_script.sh
/etc/storage/serverchan_script.sh &
done
}

serverchan_close () {
sed -Ei '/【微信推送】|^$/d' /tmp/script/_opt_script_check
killall serverchan_script.sh
killall -9 serverchan_script.sh
eval $(ps -w | grep "_server_chan keep" | grep -v grep | awk '{print "kill "$1";";}')
eval $(ps -w | grep "_server_chan.sh keep" | grep -v grep | awk '{print "kill "$1";";}')
eval $(ps -w | grep "$scriptname keep" | grep -v grep | awk '{print "kill "$1";";}')
}

serverchan_start () {
curltest=`which curl`
if [ -z "$curltest" ] || [ ! -s "`which curl`" ] ; then
	logger -t "【微信推送】" "找不到 curl ，安装 opt 程序"
	/tmp/script/_mountopt optwget
	#initopt
	curltest=`which curl`
	if [ -z "$curltest" ] || [ ! -s "`which curl`" ] ; then
		logger -t "【微信推送】" "找不到 curl ，需要手动安装 opt 后输入[opkg install curl]安装"
		logger -t "【微信推送】" "启动失败, 10 秒后自动尝试重新启动" && sleep 10 && serverchan_restart x
	fi
fi
logger -t "【微信推送】" "运行 /etc/storage/serverchan_script.sh"
/etc/storage/serverchan_script.sh &
sleep 3
[ ! -z "$(ps -w | grep "serverchan_scri" | grep -v grep )" ] && logger -t "【微信推送】" "启动成功" && serverchan_restart o
[ -z "$(ps -w | grep "serverchan_scri" | grep -v grep )" ] && logger -t "【微信推送】" "启动失败, 注意检查端口是否有冲突,程序是否下载完整,10 秒后自动尝试重新启动" && sleep 10 && serverchan_restart x
#serverchan_get_status
eval "$scriptfilepath keep &"
}

initopt () {
optPath=`grep ' /opt ' /proc/mounts | grep tmpfs`
[ ! -z "$optPath" ] && return
if [ -z "$(echo $scriptfilepath | grep "/tmp/script/")" ] && [ -s "/opt/etc/init.d/rc.func" ] ; then
	cp -Hf "$scriptfilepath" "/opt/etc/init.d/$scriptname"
fi

}

case $ACTION in
start)
	serverchan_close
	serverchan_check
	;;
check)
	serverchan_check
	;;
stop)
	serverchan_close
	;;
keep)
	#serverchan_check
	serverchan_keep
	;;
*)
	serverchan_check
	;;
esac

