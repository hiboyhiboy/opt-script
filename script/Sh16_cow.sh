#!/bin/sh
#copyright by hiboy
source /etc/storage/script/init.sh
cow_enable=`nvram get cow_enable`
[ -z $cow_enable ] && cow_enable=0 && nvram set cow_enable=0
cow_path=`nvram get cow_path`
cow_path=${cow_path:-"/opt/bin/cow"}
if [ "$cow_enable" != "0" ] ; then
nvramshow=`nvram showall | grep ss | awk '{print gensub(/'"'"'/,"'"'"'\"'"'"'\"'"'"'","g",$0);}'| awk '{print gensub(/=/,"='\''",1,$0)"'\'';";}'` && eval $nvramshow
nvramshow=`nvram showall | grep cow | awk '{print gensub(/'"'"'/,"'"'"'\"'"'"'\"'"'"'","g",$0);}'| awk '{print gensub(/=/,"='\''",1,$0)"'\'';";}'` && eval $nvramshow
ss_mode_x=${ss_mode_x:-"0"}
kcptun2_enable=${kcptun2_enable:-"0"}
kcptun2_enable2=${kcptun2_enable2:-"0"}
[ "$kcptun2_enable" = "2" ] && ss_rdd_server=""
ss_s1_local_port=${ss_s1_local_port:-"1081"}
ss_s2_local_port=${ss_s2_local_port:-"1082"}
fi


if [ ! -z "$(echo $scriptfilepath | grep -v "/tmp/script/" | grep cow)" ]  && [ ! -s /tmp/script/_cow ]; then
	mkdir -p /tmp/script
	ln -sf $scriptfilepath /tmp/script/_cow
	chmod 777 /tmp/script/_cow
fi

cow_check () {
lan_ipaddr=`nvram get lan_ipaddr`
A_restart=`nvram get cow_status`
B_restart="$cow_enable$cow_path$lan_ipaddr$ss_s1_local_port$ss_s2_local_port$ss_mode_x$ss_rdd_server$(cat /etc/storage/cow_script.sh /etc/storage/cow_config_script.sh | grep -v '^#' | grep -v "^$")"
B_restart=`echo -n "$B_restart" | md5sum | sed s/[[:space:]]//g | sed s/-//g`
if [ "$A_restart" != "$B_restart" ] ; then
	nvram set cow_status=$B_restart
	needed_restart=1
else
	needed_restart=0
fi
if [ "$cow_enable" != "1" ] && [ "$needed_restart" = "1" ] ; then
	[ ! -z "$(ps -w | grep "$cow_path" | grep -v grep )" ] && logger -t "【cow】" "停止 cow" && cow_close
	{ eval $(ps -w | grep "$scriptname" | grep -v grep | awk '{print "kill "$1";";}'); exit 0; }
fi
if [ "$cow_enable" = "1" ] ; then
	if [ "$needed_restart" = "1" ] ; then
		cow_close
		cow_start
	else
		[ -z "$(ps -w | grep "$cow_path" | grep -v grep )" ] && nvram set cow_status=00 && { eval "$scriptfilepath start &"; exit 0; }
	fi
fi
}

cow_keep () {
logger -t "【cow】" "守护进程启动"
if [ -s /tmp/script/_opt_script_check ]; then
sed -Ei '/【cow】|^$/d' /tmp/script/_opt_script_check
cat >> "/tmp/script/_opt_script_check" <<-OSC
	NUM=\`grep "$cow_path" /tmp/ps | grep -v grep |wc -l\` # 【cow】
	if [ "\$NUM" -lt "1" ] || [ ! -s "$cow_path" ] ; then # 【cow】
		logger -t "【cow】" "重新启动\$NUM" # 【cow】
		nvram set cow_status=00 && eval "$scriptfilepath &" && sed -Ei '/【cow】|^$/d' /tmp/script/_opt_script_check # 【cow】
	fi # 【cow】
OSC
return
fi

while true; do
	NUM=`ps -w | grep "$cow_path" | grep -v grep |wc -l`
	if [ "$NUM" -lt "1" ] || [ ! -s "$cow_path" ] ; then
		logger -t "【cow】" "重新启动$NUM"
		{ nvram set cow_status=00 && eval "$scriptfilepath &" ; exit 0; }
	fi
sleep 216
done
}

cow_close () {
sed -Ei '/【cow】|^$/d' /tmp/script/_opt_script_check
[ ! -z "$cow_path" ] && eval $(ps -w | grep "$cow_path" | grep -v grep | awk '{print "kill "$1";";}')
killall cow cow_script.sh
killall -9 cow cow_script.sh
eval $(ps -w | grep "_cow keep" | grep -v grep | awk '{print "kill "$1";";}')
eval $(ps -w | grep "_cow.sh keep" | grep -v grep | awk '{print "kill "$1";";}')
eval $(ps -w | grep "$scriptname keep" | grep -v grep | awk '{print "kill "$1";";}')
}

cow_start () {
SVC_PATH="$cow_path"
if [ ! -s "$SVC_PATH" ] ; then
	SVC_PATH="/opt/bin/cow"
fi
hash cow 2>/dev/null || rm -rf /opt/bin/cow
if [ ! -s "$SVC_PATH" ] ; then
	logger -t "【cow】" "找不到 $SVC_PATH，安装 opt 程序"
	/tmp/script/_mountopt start
fi
if [ ! -s "$SVC_PATH" ] ; then
	logger -t "【cow】" "找不到 $SVC_PATH 下载程序"
	wgetcurl.sh /opt/bin/cow "$hiboyfile/cow" "$hiboyfile2/cow"
	chmod 755 "/opt/bin/cow"
else
	logger -t "【cow】" "找到 $SVC_PATH"
fi
if [ ! -s "$SVC_PATH" ] ; then
	logger -t "【cow】" "找不到 $SVC_PATH ，需要手动安装 $SVC_PATH"
	logger -t "【cow】" "启动失败, 10 秒后自动尝试重新启动" && sleep 10 && { nvram set cow_status=00; eval "$scriptfilepath &"; exit 0; }
fi
if [ -s "$SVC_PATH" ] ; then
	nvram set cow_path="$SVC_PATH"
fi
cow_path="$SVC_PATH"

logger -t "【cow】" "运行 cow_script"
/etc/storage/cow_script.sh
$cow_path -rc /etc/storage/cow_config_script.sh &
restart_dhcpd
B_restart="$cow_enable$cow_path$lan_ipaddr$ss_s1_local_port$ss_s2_local_port$ss_mode_x$ss_rdd_server$(cat /etc/storage/cow_script.sh /etc/storage/cow_config_script.sh | grep -v '^#' | grep -v "^$")"
B_restart=`echo -n "$B_restart" | md5sum | sed s/[[:space:]]//g | sed s/-//g`
[ "$A_restart" != "$B_restart" ] && nvram set cow_status=$B_restart
sleep 2
[ ! -z "$(ps -w | grep "$cow_path" | grep -v grep )" ] && logger -t "【cow】" "启动成功"
[ -z "$(ps -w | grep "$cow_path" | grep -v grep )" ] && logger -t "【cow】" "启动失败, 注意检查端口是否有冲突,程序是否下载完整,10 秒后自动尝试重新启动" && sleep 10 && { nvram set cow_status=00; eval "$scriptfilepath &"; exit 0; }
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
	cow_close
	cow_check
	;;
check)
	cow_check
	;;
stop)
	cow_close
	;;
keep)
	cow_check
	cow_keep
	;;
*)
	cow_check
	;;
esac

