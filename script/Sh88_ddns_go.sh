#!/bin/sh
#copyright by hiboy
source /etc/storage/script/init.sh
ddnsgo_enable=`nvram get app_45`
[ -z $ddnsgo_enable ] && ddnsgo_enable=0 && nvram set app_45=0
ddnsgo_usage="$(nvram get app_138)"
[ -z $ddnsgo_usage ] && ddnsgo_usage="-l :9877 -f 600 -c /etc/storage/app_35.sh -skipVerify" && nvram set app_138="$ddnsgo_usage"
if [ "$ddnsgo_enable" != "0" ] ; then
#nvramshow=`nvram showall | grep '=' | grep ddnsgo | awk '{print gensub(/'"'"'/,"'"'"'\"'"'"'\"'"'"'","g",$0);}'| awk '{print gensub(/=/,"='\''",1,$0)"'\'';";}'` && eval $nvramshow

ddnsgo_renum=`nvram get ddnsgo_renum`
ddnsgo_renum=${ddnsgo_renum:-"0"}

cmd_log_enable=`nvram get cmd_log_enable`
cmd_name="ddnsgo"
cmd_log=""
if [ "$cmd_log_enable" = "1" ] || [ "$ddnsgo_renum" -gt "0" ] ; then
	cmd_log="$cmd_log2"
fi

fi

if [ ! -z "$(echo $scriptfilepath | grep -v "/tmp/script/" | grep ddns_go)" ]  && [ ! -s /tmp/script/_app25 ]; then
	mkdir -p /tmp/script
	{ echo '#!/bin/sh' ; echo $scriptfilepath '"$@"' '&' ; } > /tmp/script/_app25
	chmod 777 /tmp/script/_app25
fi

ddnsgo_restart () {

relock="/var/lock/ddnsgo_restart.lock"
if [ "$1" = "o" ] ; then
	nvram set ddnsgo_renum="0"
	[ -f $relock ] && rm -f $relock
	return 0
fi
if [ "$1" = "x" ] ; then
	if [ -f $relock ] ; then
		logger -t "【ddnsgo】" "多次尝试启动失败，等待【"`cat $relock`"分钟】后自动尝试重新启动"
		exit 0
	fi
	ddnsgo_renum=${ddnsgo_renum:-"0"}
	ddnsgo_renum=`expr $ddnsgo_renum + 1`
	nvram set ddnsgo_renum="$ddnsgo_renum"
	if [ "$ddnsgo_renum" -gt "2" ] ; then
		I=19
		echo $I > $relock
		logger -t "【ddnsgo】" "多次尝试启动失败，等待【"`cat $relock`"分钟】后自动尝试重新启动"
		while [ $I -gt 0 ]; do
			I=$(($I - 1))
			echo $I > $relock
			sleep 60
			[ "$(nvram get ddnsgo_renum)" = "0" ] && exit 0
			[ $I -lt 0 ] && break
		done
		nvram set ddnsgo_renum="0"
	fi
	[ -f $relock ] && rm -f $relock
fi
nvram set ddnsgo_status=0
eval "$scriptfilepath &"
exit 0
}

ddnsgo_get_status () {

A_restart=`nvram get ddnsgo_status`
B_restart="$ddnsgo_enable$ddnsgo_usage"
B_restart=`echo -n "$B_restart" | md5sum | sed s/[[:space:]]//g | sed s/-//g`
cut_B_re
if [ "$A_restart" != "$B_restart" ] ; then
	nvram set ddnsgo_status=$B_restart
	needed_restart=1
else
	needed_restart=0
fi
}

ddnsgo_check () {

ddnsgo_get_status
if [ "$ddnsgo_enable" != "1" ] && [ "$needed_restart" = "1" ] ; then
	[ ! -z "$(ps -w | grep "ddnsgo" | grep -v grep )" ] && logger -t "【ddnsgo】" "停止 ddnsgo" && ddnsgo_close
	{ kill_ps "$scriptname" exit0; exit 0; }
fi
if [ "$ddnsgo_enable" = "1" ] ; then
	if [ "$needed_restart" = "1" ] ; then
		ddnsgo_close
		ddnsgo_start
	else
		[ "$ddnsgo_enable" = "1" ] && [ -z "$(ps -w | grep "ddnsgo" | grep -v grep )" ] && ddnsgo_restart
	fi
fi
}

ddnsgo_keep () {
logger -t "【ddnsgo】" "守护进程启动"
if [ -s /tmp/script/_opt_script_check ]; then
sed -Ei '/【ddnsgo】|^$/d' /tmp/script/_opt_script_check
if [ "$ddnsgo_enable" = "1" ] ; then
cat >> "/tmp/script/_opt_script_check" <<-OSC
	[ -z "\`pidof ddnsgo\`" ] || [ ! -s "/opt/bin/ddnsgo" ] && nvram set ddnsgo_status=00 && logger -t "【ddnsgo】" "重新启动" && eval "$scriptfilepath &" && sed -Ei '/【ddnsgo】|^$/d' /tmp/script/_opt_script_check # 【ddnsgo】
OSC
fi
return
fi

while true; do
if [ "$ddnsgo_enable" = "1" ] ; then
	if [ -z "`pidof ddnsgo`" ] || [ ! -s "`which ddnsgo`" ] ; then
		logger -t "【ddnsgo】" "ddnsgo重新启动"
		ddnsgo_restart
	fi
fi
	sleep 230
done
}

ddnsgo_close () {
sed -Ei '/【ddnsgo】|^$/d' /tmp/script/_opt_script_check
killall ddnsgo
killall -9 ddnsgo
kill_ps "/tmp/script/_app25"
kill_ps "_ddns_go.sh"
kill_ps "$scriptname"
}

ddnsgo_start () {
check_webui_yes
SVC_PATH="$(which ddnsgo)"
[ ! -s "$SVC_PATH" ] && SVC_PATH="/opt/bin/ddnsgo"
chmod 777 "$SVC_PATH"
[[ "$(ddnsgo -h 2>&1 | wc -l)" -lt 2 ]] && rm -rf /opt/bin/ddnsgo
if [ ! -s "$SVC_PATH" ] ; then
	logger -t "【ddnsgo】" "找不到 ddnsgo，安装 opt 程序"
	/etc/storage/script/Sh01_mountopt.sh start
	initopt
fi
for h_i in $(seq 1 2) ; do
[[ "$(ddnsgo -h 2>&1 | wc -l)" -lt 2 ]] && rm -rf /opt/bin/ddnsgo
wgetcurl_file "$SVC_PATH" "$hiboyfile/ddnsgo" "$hiboyfile2/ddnsgo"
done
if [ ! -s "$SVC_PATH" ] ; then
	logger -t "【ddnsgo】" "找不到 $SVC_PATH ，需要手动安装 $SVC_PATH"
	logger -t "【ddnsgo】" "启动失败, 10 秒后自动尝试重新启动" && sleep 10 && ddnsgo_restart x
fi
chmod 777 "$SVC_PATH"
logger -t "【ddnsgo】" "运行 $SVC_PATH"
eval "$SVC_PATH $ddnsgo_usage $cmd_log" &
sleep 4
[ ! -z "`pidof ddnsgo`" ] && logger -t "【ddnsgo】" "启动成功" && ddnsgo_restart o
[ -z "`pidof ddnsgo`" ] && logger -t "【ddnsgo】" "启动失败, 注意检查端口是否有冲突,程序是否下载完整,10 秒后自动尝试重新启动" && sleep 10 && ddnsgo_restart x

#ddnsgo_get_status
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

app_35="/etc/storage/app_35.sh"
if [ ! -f "$app_35" ] || [ ! -s "$app_35" ] ; then
	cat > "$app_35" <<-\EEE
notallowwanaccess: true

EEE
	chmod 755 "$app_35"
fi

}

initconfig

update_app () {

mkdir -p /opt/app/ddnsgo
if [ "$1" = "del" ] ; then
	rm -rf /opt/app/ddnsgo/Advanced_Extensions_ddnsgo.asp
	rm -rf /opt/bin/ddnsgo /opt/opt_backup/bin/ddnsgo 
fi

initconfig

# 加载程序配置页面
if [ ! -f "/opt/app/ddnsgo/Advanced_Extensions_ddnsgo.asp" ] || [ ! -s "/opt/app/ddnsgo/Advanced_Extensions_ddnsgo.asp" ] ; then
	wgetcurl.sh /opt/app/ddnsgo/Advanced_Extensions_ddnsgo.asp "$hiboyfile/Advanced_Extensions_ddnsgoasp" "$hiboyfile2/Advanced_Extensions_ddnsgoasp"
fi
umount /www/Advanced_Extensions_app25.asp
mount --bind /opt/app/ddnsgo/Advanced_Extensions_ddnsgo.asp /www/Advanced_Extensions_app25.asp
# 更新程序启动脚本

[ "$1" = "del" ] && /etc/storage/www_sh/ddnsgo del &
}

case $ACTION in
start)
	ddnsgo_close
	ddnsgo_check
	;;
check)
	ddnsgo_check
	;;
stop)
	ddnsgo_close
	;;
updateapp25)
	ddnsgo_restart o
	[ "$ddnsgo_enable" = "1" ] && nvram set ddnsgo_status="updateddnsgo" && logger -t "【ddnsgo】" "重启" && ddnsgo_restart
	[ "$ddnsgo_enable" != "1" ] && nvram set ddnsgo_v="" && logger -t "【ddnsgo】" "更新" && update_app del
	;;
update_app)
	update_app
	;;
keep)
	#ddnsgo_check
	ddnsgo_keep
	;;
*)
	ddnsgo_check
	;;
esac

