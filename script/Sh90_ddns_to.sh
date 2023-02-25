#!/bin/bash
#copyright by hiboy
source /etc/storage/script/init.sh
ddnsto_enable=`nvram get app_64`
[ -z $ddnsto_enable ] && ddnsto_enable=0 && nvram set app_64=0
ddnsto_token=`nvram get app_65`
if [ "$ddnsto_enable" != "0" ] ; then
#nvramshow=`nvram showall | grep '=' | grep ddnsto | awk '{print gensub(/'"'"'/,"'"'"'\"'"'"'\"'"'"'","g",$0);}'| awk '{print gensub(/=/,"='\''",1,$0)"'\'';";}'` && eval $nvramshow

ddnsto_renum=`nvram get ddnsto_renum`
ddnsto_renum=${ddnsto_renum:-"0"}

upPassword=""

cmd_log_enable=`nvram get cmd_log_enable`
cmd_name="ddnsto"
cmd_log=""
if [ "$cmd_log_enable" = "1" ] || [ "$ddnsto_renum" -gt "0" ] ; then
	cmd_log="$cmd_log2"
fi

fi

if [ ! -z "$(echo $scriptfilepath | grep -v "/tmp/script/" | grep ddns_to)" ]  && [ ! -s /tmp/script/_app16 ]; then
	mkdir -p /tmp/script
	{ echo '#!/bin/bash' ; echo $scriptfilepath '"$@"' '&' ; } > /tmp/script/_app16
	chmod 777 /tmp/script/_app16
fi

ddnsto_restart () {

relock="/var/lock/ddnsto_restart.lock"
if [ "$1" = "o" ] ; then
	nvram set ddnsto_renum="0"
	[ -f $relock ] && rm -f $relock
	return 0
fi
if [ "$1" = "x" ] ; then
	if [ -f $relock ] ; then
		logger -t "【ddnsto】" "多次尝试启动失败，等待【"`cat $relock`"分钟】后自动尝试重新启动"
		exit 0
	fi
	ddnsto_renum=${ddnsto_renum:-"0"}
	ddnsto_renum=`expr $ddnsto_renum + 1`
	nvram set ddnsto_renum="$ddnsto_renum"
	if [ "$ddnsto_renum" -gt "3" ] ; then
		I=19
		echo $I > $relock
		logger -t "【ddnsto】" "多次尝试启动失败，等待【"`cat $relock`"分钟】后自动尝试重新启动"
		while [ $I -gt 0 ]; do
			I=$(($I - 1))
			echo $I > $relock
			sleep 60
			[ "$(nvram get ddnsto_renum)" = "0" ] && exit 0
			[ $I -lt 0 ] && break
		done
		nvram set ddnsto_renum="1"
	fi
	[ -f $relock ] && rm -f $relock
fi
nvram set ddnsto_status=0
eval "$scriptfilepath &"
exit 0
}

ddnsto_get_status () {

A_restart=`nvram get ddnsto_status`
B_restart="$ddnsto_enable$ddnsto_token"
B_restart=`echo -n "$B_restart" | md5sum | sed s/[[:space:]]//g | sed s/-//g`
cut_B_re
if [ "$A_restart" != "$B_restart" ] ; then
	nvram set ddnsto_status=$B_restart
	needed_restart=1
else
	needed_restart=0
fi
}

ddnsto_check () {

ddnsto_get_status
if [ "$ddnsto_enable" != "1" ] && [ "$needed_restart" = "1" ] ; then
	[ ! -z "$(ps -w | grep "ddnsto" | grep -v grep )" ] && logger -t "【ddnsto】" "停止 ddnsto" && ddnsto_close
	{ kill_ps "$scriptname" exit0; exit 0; }
fi
if [ "$ddnsto_enable" = "1" ] ; then
	if [ "$needed_restart" = "1" ] ; then
		ddnsto_close
		ddnsto_start
	else
		[ "$ddnsto_enable" = "1" ] && [ -z "$(ps -w | grep "ddnsto" | grep -v grep )" ] && ddnsto_restart
	fi
fi
}

ddnsto_keep () {
logger -t "【ddnsto】" "守护进程启动"
if [ -s /tmp/script/_opt_script_check ]; then
sed -Ei '/【ddnsto】|^$/d' /tmp/script/_opt_script_check
if [ "$ddnsto_enable" = "1" ] ; then
cat >> "/tmp/script/_opt_script_check" <<-OSC
	[ -z "\`pidof ddnsto\`" ] || [ ! -s "/opt/bin/ddnsto" ] && nvram set ddnsto_status=00 && logger -t "【ddnsto】" "重新启动" && eval "$scriptfilepath &" && sed -Ei '/【ddnsto】|^$/d' /tmp/script/_opt_script_check # 【ddnsto】
OSC
fi
return
fi

while true; do
if [ "$ddnsto_enable" = "1" ] ; then
	if [ -z "`pidof ddnsto`" ] || [ ! -s "`which ddnsto`" ] ; then
		logger -t "【ddnsto】" "ddnsto重新启动"
		ddnsto_restart
	fi
fi
	sleep 205
done
}

ddnsto_close () {
kill_ps "$scriptname keep"
sed -Ei '/【ddnsto】|^$/d' /tmp/script/_opt_script_check
killall ddnsto
killall -9 ddnsto
kill_ps "/tmp/script/_app16"
kill_ps "_ddns_to.sh"
kill_ps "$scriptname"
}

ddnsto_start () {

check_webui_yes
SVC_PATH="$(which ddnsto)"
[ ! -s "$SVC_PATH" ] && SVC_PATH=/opt/bin/ddnsto
if [ ! -s "$SVC_PATH" ] ; then
	logger -t "【ddnsto】" "找不到 $SVC_PATH，安装 opt 程序"
	/etc/storage/script/Sh01_mountopt.sh start
	initopt
fi
if [ -f /etc_ro/ddnsto ] && [ ! -s "$SVC_PATH" ] && [ ! -f /tmp/ddnsto_ro ] ; then
	cp -f /etc_ro/ddnsto /opt/bin/ddnsto
fi
for h_i in $(seq 1 2) ; do
[[ "$(ddnsto -h 2>&1 | wc -l)" -lt 2 ]] && rm -rf /opt/bin/ddnsto
wgetcurl_file "$SVC_PATH" "$hiboyfile/ddnsto" "$hiboyfile2/ddnsto"
done
if [ ! -s "$SVC_PATH" ] ; then
	logger -t "【ddnsto】" "找不到 $SVC_PATH ，需要手动安装 $SVC_PATH"
	logger -t "【ddnsto】" "启动失败, 10 秒后自动尝试重新启动" && sleep 10 && ddnsto_restart x
else
	logger -t "【ddnsto】" "找到 $SVC_PATH"
	chmod 755 "$SVC_PATH"
fi
ddnsto_route_id=$(ddnsto -w | awk '{print $2}')
nvram set ddnsto_route_id="$ddnsto_route_id"
[ ! -z $ddnsto_route_id ] && logger -t "【ddnsto】" "路由器ID：【$ddnsto_route_id】；管理控制台 https://www.ddnsto.com/"
ddnsto_version=$(ddnsto -v)
nvram set ddnsto_version="$ddnsto_version"
[ -z $ddnsto_token ] && logger -t "【ddnsto】" "【ddnsto_token】不能为空,启动失败, 10 秒后自动尝试重新启动" && sleep 10 && ddnsto_restart x
logger -t "【ddnsto】" "运行 ddnsto 版本：$ddnsto_version"
eval "ddnsto -u $ddnsto_token -d $cmd_log" &
sleep 3
[ -z "`pidof ddnsto`" ] && logger -t "【ddnsto】" "启动失败, 注意检查密码是否有错误,程序是否下载完整,10 秒后自动尝试重新启动" && sleep 10 && ddnsto_restart x
[ ! -z "`pidof ddnsto`" ] && logger -t "【ddnsto】" "启动成功" && ddnsto_restart o
sleep 2
ddnsto_route_id=$(ddnsto -w | awk '{print $2}')
nvram set ddnsto_route_id="$ddnsto_route_id"
[ ! -z $ddnsto_route_id ] && logger -t "【ddnsto】" "路由器ID：【$ddnsto_route_id】；管理控制台 https://www.ddnsto.com/"
[ -z $ddnsto_route_id ] && logger -t "【ddnsto】" "路由器ID：【$ddnsto_route_id】不能为空,启动失败, 10 秒后自动尝试重新启动" && sleep 10 && ddnsto_restart x
eval "$scriptfilepath keep &"
exit 0

}

initopt () {
optPath=`grep ' /opt ' /proc/mounts | grep tmpfs`
[ ! -z "$optPath" ] && return
if [ ! -z "$(echo $scriptfilepath | grep -v "/opt/etc/init")" ] && [ -s "/opt/etc/init.d/rc.func" ] ; then
	{ echo '#!/bin/bash' ; echo $scriptfilepath '"$@"' '&' ; } > /opt/etc/init.d/$scriptname && chmod 777  /opt/etc/init.d/$scriptname
fi

}

initconfig () {

echo "ddnsto initconfig"
}

initconfig

update_app () {
mkdir -p /opt/app/ddnsto
if [ "$1" = "update_asp" ] ; then
	rm -rf /opt/app/ddnsto/Advanced_Extensions_ddnsto.asp
fi
if [ "$1" = "del" ] ; then
	rm -rf /opt/app/ddnsto/Advanced_Extensions_ddnsto.asp
	[ -f /opt/bin/ddnsto ] && rm -f /opt/bin/ddnsto /opt/opt_backup/bin/ddnsto
	[ -f /etc_ro/ddnsto ] && touch /tmp/ddnsto_ro
fi

initconfig

# 加载程序配置页面
if [ ! -f "/opt/app/ddnsto/Advanced_Extensions_ddnsto.asp" ] || [ ! -s "/opt/app/ddnsto/Advanced_Extensions_ddnsto.asp" ] ; then
	wgetcurl.sh /opt/app/ddnsto/Advanced_Extensions_ddnsto.asp "$hiboyfile/Advanced_Extensions_ddnstoasp" "$hiboyfile2/Advanced_Extensions_ddnstoasp"
fi
umount /www/Advanced_Extensions_app16.asp
mount --bind /opt/app/ddnsto/Advanced_Extensions_ddnsto.asp /www/Advanced_Extensions_app16.asp
# 更新程序启动脚本

[ "$1" = "del" ] && /etc/storage/www_sh/ddnsto del &
}

case $ACTION in
start)
	ddnsto_close
	ddnsto_check
	;;
check)
	ddnsto_check
	;;
stop)
	ddnsto_close
	;;
updateapp16)
	ddnsto_restart o
	[ "$ddnsto_enable" = "1" ] && nvram set ddnsto_status="updateddnsto" && logger -t "【ddnsto】" "重启" && ddnsto_restart
	[ "$ddnsto_enable" != "1" ] && nvram set ddnsto_version="" && logger -t "【ddnsto】" "更新" && update_app del
	;;
update_app)
	update_app
	;;
update_asp)
	update_app update_asp
	;;
keep)
	#ddnsto_check
	ddnsto_keep
	;;
*)
	ddnsto_check
	;;
esac

