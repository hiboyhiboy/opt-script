#!/bin/sh
#copyright by hiboy
source /etc/storage/script/init.sh
meow_enable=`nvram get meow_enable`
[ -z $meow_enable ] && meow_enable=0 && nvram set meow_enable=0
meow_path=`nvram get meow_path`
meow_path=${meow_path:-"/opt/bin/meow"}
if [ "$meow_enable" != "0" ] ; then
nvramshow=`nvram showall | grep ss | awk '{print gensub(/'"'"'/,"'"'"'\"'"'"'\"'"'"'","g",$0);}'| awk '{print gensub(/=/,"='\''",1,$0)"'\'';";}'` && eval $nvramshow
nvramshow=`nvram showall | grep meow | awk '{print gensub(/'"'"'/,"'"'"'\"'"'"'\"'"'"'","g",$0);}'| awk '{print gensub(/=/,"='\''",1,$0)"'\'';";}'` && eval $nvramshow
ss_mode_x=${ss_mode_x:-"0"}
kcptun2_enable=${kcptun2_enable:-"0"}
kcptun2_enable2=${kcptun2_enable2:-"0"}
[ "$kcptun2_enable" = "2" ] && ss_rdd_server=""
ss_s1_local_port=${ss_s1_local_port:-"1081"}
ss_s2_local_port=${ss_s2_local_port:-"1082"}
fi

if [ ! -z "$(echo $scriptfilepath | grep -v "/tmp/script/" | grep meow)" ]  && [ ! -s /tmp/script/_meow ]; then
	mkdir -p /tmp/script
	ln -sf $scriptfilepath /tmp/script/_meow
	chmod 777 /tmp/script/_meow
fi

meow_check () {
lan_ipaddr=`nvram get lan_ipaddr`
A_restart=`nvram get meow_status`
B_restart="$meow_enable$meow_path$lan_ipaddr$ss_s1_local_port$ss_s2_local_port$ss_mode_x$ss_rdd_server$(cat /etc/storage/meow_script.sh /etc/storage/meow_config_script.sh | grep -v '^#' | grep -v "^$")"
B_restart=`echo -n "$B_restart" | md5sum | sed s/[[:space:]]//g | sed s/-//g`
if [ "$A_restart" != "$B_restart" ] ; then
	nvram set meow_status=$B_restart
	needed_restart=1
else
	needed_restart=0
fi
if [ "$meow_enable" != "1" ] && [ "$needed_restart" = "1" ] ; then
	[ ! -z "$(ps -w | grep "$meow_path" | grep -v grep )" ] && logger -t "【meow】" "停止 meow" && meow_close
	{ eval $(ps -w | grep "$scriptname" | grep -v grep | awk '{print "kill "$1";";}'); exit 0; }
fi
if [ "$meow_enable" = "1" ] ; then
	if [ "$needed_restart" = "1" ] ; then
		meow_close
		meow_start
	else
		[ -z "$(ps -w | grep "$meow_path" | grep -v grep )" ] && nvram set meow_status=00 && { eval "$scriptfilepath start &"; exit 0; }
	fi
fi
}

meow_keep () {
logger -t "【meow】" "守护进程启动"
if [ -s /tmp/script/_opt_script_check ]; then
sed -Ei '/【meow】|^$/d' /tmp/script/_opt_script_check
cat >> "/tmp/script/_opt_script_check" <<-OSC
	NUM=\`grep "$meow_path" /tmp/ps | grep -v grep |wc -l\` # 【meow】
	if [ "\$NUM" -lt "1" ] || [ ! -s "$meow_path" ] ; then # 【meow】
		logger -t "【meow】" "重新启动\$NUM" # 【meow】
		nvram set meow_status=00 && eval "$scriptfilepath &" && sed -Ei '/【meow】|^$/d' /tmp/script/_opt_script_check # 【meow】
	fi # 【meow】
OSC
return
fi

while true; do
	NUM=`ps -w | grep "$meow_path" | grep -v grep |wc -l`
	if [ "$NUM" -lt "1" ] || [ ! -s "$meow_path" ] ; then
		logger -t "【meow】" "重新启动$NUM"
		{ nvram set meow_status=00 && eval "$scriptfilepath &" ; exit 0; }
	fi
sleep 217
done
}

meow_close () {
sed -Ei '/【meow】|^$/d' /tmp/script/_opt_script_check
[ ! -z "$meow_path" ] && eval $(ps -w | grep "$meow_path" | grep -v grep | awk '{print "kill "$1";";}')
killall meow meow_script.sh
killall -9 meow meow_script.sh
eval $(ps -w | grep "_meow keep" | grep -v grep | awk '{print "kill "$1";";}')
eval $(ps -w | grep "_meow.sh keep" | grep -v grep | awk '{print "kill "$1";";}')
eval $(ps -w | grep "$scriptname keep" | grep -v grep | awk '{print "kill "$1";";}')
}

meow_start () {
SVC_PATH="$meow_path"
if [ ! -s "$SVC_PATH" ] ; then
	SVC_PATH="/opt/bin/meow"
fi
hash meow 2>/dev/null || rm -rf /opt/bin/meow
if [ ! -s "$SVC_PATH" ] ; then
	logger -t "【meow】" "找不到 $SVC_PATH，安装 opt 程序"
	/tmp/script/_mountopt start
fi
if [ ! -s "$SVC_PATH" ] ; then
	logger -t "【meow】" "找不到 $SVC_PATH 下载程序"
	wgetcurl.sh /opt/bin/meow "$hiboyfile/meow" "$hiboyfile2/meow"
	chmod 755 "/opt/bin/meow"
else
	logger -t "【meow】" "找到 $SVC_PATH"
fi
if [ ! -s "$SVC_PATH" ] ; then
	logger -t "【meow】" "找不到 $SVC_PATH ，需要手动安装 $SVC_PATH"
	logger -t "【meow】" "启动失败, 10 秒后自动尝试重新启动" && sleep 10 && { nvram set meow_status=00; eval "$scriptfilepath &"; exit 0; }
fi
if [ -s "$SVC_PATH" ] ; then
	nvram set meow_path="$SVC_PATH"
fi
meow_path="$SVC_PATH"

logger -t "【meow】" "运行 meow_script"
/etc/storage/meow_script.sh
$meow_path -rc /etc/storage/meow_config_script.sh &
restart_dhcpd
B_restart="$meow_enable$meow_path$lan_ipaddr$ss_s1_local_port$ss_s2_local_port$ss_mode_x$ss_rdd_server$(cat /etc/storage/meow_script.sh /etc/storage/meow_config_script.sh | grep -v '^#' | grep -v "^$")"
B_restart=`echo -n "$B_restart" | md5sum | sed s/[[:space:]]//g | sed s/-//g`
[ "$A_restart" != "$B_restart" ] && nvram set meow_status=$B_restart
sleep 2
[ ! -z "$(ps -w | grep "$meow_path" | grep -v grep )" ] && logger -t "【meow】" "启动成功"
[ -z "$(ps -w | grep "$meow_path" | grep -v grep )" ] && logger -t "【meow】" "启动失败, 注意检查端口是否有冲突,程序是否下载完整,10 秒后自动尝试重新启动" && sleep 10 && { nvram set meow_status=00; eval "$scriptfilepath &"; exit 0; }
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
	meow_close
	meow_check
	;;
check)
	meow_check
	;;
stop)
	meow_close
	;;
keep)
	meow_check
	meow_keep
	;;
*)
	meow_check
	;;
esac

