#!/bin/bash
#copyright by hiboy
source /etc/storage/script/init.sh
shellinabox_port=`nvram get shellinabox_port`
shellinabox_enable=`nvram get shellinabox_enable`
[ -z $shellinabox_enable ] && shellinabox_enable=0 && nvram set shellinabox_enable=$shellinabox_enable
if [ "$shellinabox_enable" != "0" ] ; then
#nvramshow=`nvram showall | grep '=' | grep shellinabox | awk '{print gensub(/'"'"'/,"'"'"'\"'"'"'\"'"'"'","g",$0);}'| awk '{print gensub(/=/,"='\''",1,$0)"'\'';";}'` && eval $nvramshow

shellinabox_css=`nvram get shellinabox_css`
shellinabox_wan=`nvram get shellinabox_wan`
shellinabox_options_ttyd=`nvram get shellinabox_options_ttyd`

[ -z $shellinabox_port ] && shellinabox_port="4200" && nvram set shellinabox_port=$shellinabox_port
[ -z $shellinabox_css ] && shellinabox_css="white-on-black" && nvram set shellinabox_css=$shellinabox_css

[ -z $shellinabox_options_ttyd ] && shellinabox_options_ttyd="login" && nvram set shellinabox_options_ttyd=$shellinabox_options_ttyd

shellinabox_renum=`nvram get shellinabox_renum`
shellinabox_renum=${shellinabox_renum:-"0"}
cmd_log_enable=`nvram get cmd_log_enable`
cmd_name="shellinabox"
cmd_log=""
if [ "$cmd_log_enable" = "1" ] || [ "$shellinabox_renum" -gt "0" ] ; then
	cmd_log="$cmd_log2"
fi
fi
shell_log="【shellinabox】"
[ "$shellinabox_enable" = "2" ] && shell_log="【ttyd】"

if [ ! -z "$(echo $scriptfilepath | grep -v "/tmp/script/" | grep shellina_box)" ]  && [ ! -s /tmp/script/_shellina_box ]; then
	mkdir -p /tmp/script
	{ echo '#!/bin/bash' ; echo $scriptfilepath '"$@"' '&' ; } > /tmp/script/_shellina_box
	chmod 777 /tmp/script/_shellina_box
fi

shellinabox_restart () {

relock="/var/lock/shellinabox_restart.lock"
if [ "$1" = "o" ] ; then
	nvram set shellinabox_renum="0"
	[ -f $relock ] && rm -f $relock
	return 0
fi
if [ "$1" = "x" ] ; then
	if [ -f $relock ] ; then
		logger -t "$shell_log" "多次尝试启动失败，等待【"`cat $relock`"分钟】后自动尝试重新启动"
		exit 0
	fi
	shellinabox_renum=${shellinabox_renum:-"0"}
	shellinabox_renum=`expr $shellinabox_renum + 1`
	nvram set shellinabox_renum="$shellinabox_renum"
	if [ "$shellinabox_renum" -gt "3" ] ; then
		I=19
		echo $I > $relock
		logger -t "$shell_log" "多次尝试启动失败，等待【"`cat $relock`"分钟】后自动尝试重新启动"
		while [ $I -gt 0 ]; do
			I=$(($I - 1))
			echo $I > $relock
			sleep 60
			[ "$(nvram get shellinabox_renum)" = "0" ] && exit 0
			[ $I -lt 0 ] && break
		done
		nvram set shellinabox_renum="1"
	fi
	[ -f $relock ] && rm -f $relock
fi
nvram set shellinabox_status=0
eval "$scriptfilepath &"
exit 0
}

shellinabox_get_status () {

A_restart=`nvram get shellinabox_status`
B_restart="$shellinabox_enable$shellinabox_port$shellinabox_css$shellinabox_options$shellinabox_wan$shellinabox_options_ttyd"
B_restart=`echo -n "$B_restart" | md5sum | sed s/[[:space:]]//g | sed s/-//g`
cut_B_re
if [ "$A_restart" != "$B_restart" ] ; then
	nvram set shellinabox_status=$B_restart
	needed_restart=1
else
	needed_restart=0
fi
}

shellinabox_check () {

shellinabox_get_status
if [ "$shellinabox_enable" = "0" ] && [ "$needed_restart" = "1" ] ; then
	[ ! -z "`pidof shellinaboxd`" ] && logger -t "$shell_log" "停止 shellinaboxd" && shellinabox_close
	[ ! -z "`pidof ttyd`" ] && logger -t "【ttyd】" "停止 ttyd" && shellinabox_close
	{ kill_ps "$scriptname" exit0; exit 0; }
fi
if [ "$shellinabox_enable" = "1" ] || [ "$shellinabox_enable" = "2" ] ; then
	if [ "$needed_restart" = "1" ] ; then
		shellinabox_close
		shellinabox_start
	else
		[ "$shellinabox_enable" = "1" ] && [ -z "`pidof shellinaboxd`" ] && shellinabox_restart
		[ "$shellinabox_enable" = "2" ] && [ -z "`pidof ttyd`" ] && shellinabox_restart
		shellinabox_port_dpt
	fi
fi
}

shellinabox_keep () {

logger -t "$shell_log" "守护进程启动"
if [ "$shellinabox_enable" = "1" ] ; then
if [ -s /tmp/script/_opt_script_check ]; then
sed -Ei '/【shellinabox】|^$/d' /tmp/script/_opt_script_check
cat >> "/tmp/script/_opt_script_check" <<-OSC
[ -z "\`pidof shellinaboxd\`" ] || [ ! -s "`which shellinaboxd`" ] && nvram set shellinabox_status=00 && logger -t "【shellinabox】" "重新启动" && eval "$scriptfilepath &" && sed -Ei '/【shellinabox】|^$/d' /tmp/script/_opt_script_check # 【shellinabox】
OSC
return
fi
while true; do
	if [ -z "`pidof shellinaboxd`" ] || [ ! -s "`which shellinaboxd`" ] ; then
		logger -t "【shellinabox】" "重新启动"
		shellinabox_restart
	fi
sleep 262
done
fi
if [ "$shellinabox_enable" = "2" ] ; then
if [ -s /tmp/script/_opt_script_check ]; then
sed -Ei '/【ttyd】|^$/d' /tmp/script/_opt_script_check
cat >> "/tmp/script/_opt_script_check" <<-OSC
[ -z "\`pidof ttyd\`" ] || [ ! -s "`which ttyd`" ] && nvram set shellinabox_status=00 && logger -t "【ttyd】" "重新启动" && eval "$scriptfilepath &" && sed -Ei '/【ttyd】|^$/d' /tmp/script/_opt_script_check # 【ttyd】
OSC
return
fi
while true; do
	if [ -z "`pidof ttyd`" ] || [ ! -s "`which ttyd`" ] ; then
		logger -t "【ttyd】" "重新启动"
		shellinabox_restart
	fi
sleep 262
done
fi
}

shellinabox_close () {

kill_ps "$scriptname keep"
sed -Ei '/【shellinabox】|^$/d' /tmp/script/_opt_script_check
sed -Ei '/【ttyd】|^$/d' /tmp/script/_opt_script_check
iptables -t filter -D INPUT -p tcp --dport $shellinabox_port -j ACCEPT
killall shellinaboxd ttyd
killall -9 shellinaboxd ttyd
kill_ps "/tmp/script/_shellina_box"
kill_ps "_shellina_box.sh"
kill_ps "$scriptname"
}

shellinabox_start () {
check_webui_yes
if [ "$shellinabox_enable" = "2" ] ; then
cmd_name="ttyd"
SVC_PATH="$(which ttyd)"
[ ! -s "$SVC_PATH" ] && SVC_PATH="/opt/bin/ttyd"
if [ ! -s "$SVC_PATH" ] ; then
	logger -t "【ttyd】" "找不到 $SVC_PATH，安装 opt 程序"
	/etc/storage/script/Sh01_mountopt.sh start
fi
wgetcurl_file "$SVC_PATH" "$hiboyfile/ttyd" "$hiboyfile2/ttyd"
chmod 777 "$SVC_PATH"
[[ "$($SVC_PATH -h 2>&1 | wc -l)" -lt 2 ]] && rm -rf "$SVC_PATH"
[ ! -s "$SVC_PATH" ] && SVC_PATH="$(which ttyd)"
[ ! -s "$SVC_PATH" ] && SVC_PATH="/opt/bin/ttyd"
hash ttyd 2>/dev/null || { logger -t "$shell_log" "找不到 ttyd，尝试启动shellinaboxd"; nvram set shellinabox_enable=1; shellinabox_restart ; }
eval "$SVC_PATH --port $shellinabox_port $shellinabox_options_ttyd $cmd_log" &
sleep 5
[ ! -z "`pidof ttyd`" ] && logger -t "$shell_log" "启动成功" && shellinabox_restart o
[ -z "`pidof ttyd`" ] && logger -t "$shell_log" "启动失败, 注意检查端口是否有冲突,程序是否下载完整,10 秒后自动尝试重新启动" && sleep 10 && shellinabox_restart x

fi
if [ "$shellinabox_enable" = "1" ] ; then
cmd_name="shellinabox"
SVC_PATH="/opt/sbin/shellinaboxd"
chmod 777 "$SVC_PATH"
if [ ! -s "$SVC_PATH" ] ; then
	logger -t "$shell_log" "找不到 $SVC_PATH，安装 opt mini 程序"
	/etc/storage/script/Sh01_mountopt.sh opt_mini_wget
fi
[[ "$(shellinaboxd -h 2>&1 | wc -l)" -lt 2 ]] && /etc/storage/script/Sh01_mountopt.sh libmd5_check
if [ ! -s "$SVC_PATH" ] ; then
	logger -t "$shell_log" "找不到 $SVC_PATH ，需要手动安装 $SVC_PATH"
	logger -t "$shell_log" "启动失败, 10 秒后自动尝试重新启动" && sleep 10 && shellinabox_restart x
fi
logger -t "【shellinaboxd】" "运行 shellinaboxd"
/opt/etc/init.d/S88shellinaboxd stop
sleep 5
eval "/opt/etc/init.d/S88shellinaboxd start  $cmd_log" &
sleep 5
[ ! -z "`pidof shellinaboxd`" ] && logger -t "$shell_log" "启动成功" && shellinabox_restart o
[ -z "`pidof shellinaboxd`" ] && logger -t "$shell_log" "启动失败, 注意检查端口是否有冲突,程序是否下载完整,10 秒后自动尝试重新启动" && sleep 10 && shellinabox_restart x
initopt
fi
shellinabox_port_dpt
#shellinabox_get_status
eval "$scriptfilepath keep &"
exit 0
}

initopt () {
optPath=`grep ' /opt ' /proc/mounts | grep tmpfs`
[ ! -z "$optPath" ] && return
optw_enable=`nvram get optw_enable`
if [ "$optw_enable" != "2" ] && [ "$shellinabox_wan" = "1" ] ; then
	nvram set optw_enable=2
fi
if [ ! -z "$(echo $scriptfilepath | grep -v "/opt/etc/init")" ] && [ -s "/opt/etc/init.d/rc.func" ] ; then
	{ echo '#!/bin/bash' ; echo $scriptfilepath '"$@"' '&' ; } > /opt/etc/init.d/$scriptname && chmod 777  /opt/etc/init.d/$scriptname
fi

}

update_app () {
SVC_PATH="/opt/bin/ttyd"
rm -rf "$SVC_PATH" /opt/opt_backup/bin/ttyd
/etc/storage/script/Sh01_mountopt.sh start
wgetcurl_file "$SVC_PATH" "$hiboyfile/ttyd" "$hiboyfile2/ttyd"
chmod 777 "$SVC_PATH"
}

shellinabox_port_dpt () {

if [ "$shellinabox_wan" = "1" ] ; then
	port=$(iptables -t filter -L INPUT -v -n --line-numbers | grep dpt:$shellinabox_port | cut -d " " -f 1 | sort -nr | wc -l)
	if [ "$port" = 0 ] ; then
		logger -t "$shell_log" "检测:找不到 ss-server 端口:$shellinabox_port 规则, 重新添加"
		iptables -t filter -I INPUT -p tcp --dport $shellinabox_port -j ACCEPT
	fi
fi

}

case $ACTION in
start)
	shellinabox_close
	shellinabox_check
	;;
check)
	shellinabox_check
	;;
stop)
	shellinabox_close
	;;
update_app)
	update_app
	;;
keep)
	#shellinabox_check
	shellinabox_keep
	;;
*)
	shellinabox_check
	;;
esac

