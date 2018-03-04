#!/bin/sh
#copyright by hiboy
source /etc/storage/script/init.sh
verysync_enable=`nvram get app_20`
[ -z $verysync_enable ] && verysync_enable=0 && nvram set app_20=0
verysync_wan_port=`nvram get app_21`
[ -z $verysync_wan_port ] && verysync_wan_port=8886 && nvram set app_21=$verysync_wan_port
verysync_wan=`nvram get app_22`
[ -z $verysync_wan ] && verysync_wan=0 && nvram set app_22=0
verysync_upanPath=`nvram get verysync_upanPath`
#if [ "$verysync_enable" != "0" ] ; then
#nvramshow=`nvram showall | grep '=' | grep verysync | awk '{print gensub(/'"'"'/,"'"'"'\"'"'"'\"'"'"'","g",$0);}'| awk '{print gensub(/=/,"='\''",1,$0)"'\'';";}'` && eval $nvramshow
#fi

if [ ! -z "$(echo $scriptfilepath | grep -v "/tmp/script/" | grep very_sync)" ]  && [ ! -s /tmp/script/_app6 ]; then
	mkdir -p /tmp/script
	{ echo '#!/bin/sh' ; echo $scriptfilepath '"$@"' '&' ; } > /tmp/script/_app6
	chmod 777 /tmp/script/_app6
fi

upanPath=""

verysync_restart () {

relock="/var/lock/verysync_restart.lock"
if [ "$1" = "o" ] ; then
	nvram set verysync_renum="0"
	[ -f $relock ] && rm -f $relock
	return 0
fi
if [ "$1" = "x" ] ; then
	if [ -f $relock ] ; then
		logger -t "【verysync】" "多次尝试启动失败，等待【"`cat $relock`"分钟】后自动尝试重新启动"
		exit 0
	fi
	verysync_renum=${verysync_renum:-"0"}
	verysync_renum=`expr $verysync_renum + 1`
	nvram set verysync_renum="$verysync_renum"
	if [ "$verysync_renum" -gt "2" ] ; then
		I=19
		echo $I > $relock
		logger -t "【verysync】" "多次尝试启动失败，等待【"`cat $relock`"分钟】后自动尝试重新启动"
		while [ $I -gt 0 ]; do
			I=$(($I - 1))
			echo $I > $relock
			sleep 60
			[ "$(nvram get verysync_renum)" = "0" ] && exit 0
			[ $I -lt 0 ] && break
		done
		nvram set verysync_renum="0"
	fi
	[ -f $relock ] && rm -f $relock
fi
nvram set verysync_status=0
eval "$scriptfilepath &"
exit 0
}

verysync_get_status () {

A_restart=`nvram get verysync_status`
B_restart="$verysync_enable$verysync_wan$verysync_wan_port"
B_restart=`echo -n "$B_restart" | md5sum | sed s/[[:space:]]//g | sed s/-//g`
if [ "$A_restart" != "$B_restart" ] ; then
	nvram set verysync_status=$B_restart
	needed_restart=1
else
	needed_restart=0
fi
}

verysync_check () {

verysync_get_status
if [ "$verysync_enable" != "1" ] && [ "$needed_restart" = "1" ] ; then
	[ ! -z "`pidof verysync`" ] && logger -t "【verysync】" "停止 verysync" && verysync_close
	{ kill_ps "$scriptname" exit0; exit 0; }
fi
if [ "$verysync_enable" = "1" ] ; then
	if [ "$needed_restart" = "1" ] ; then
		verysync_close
		verysync_start
	else
		[ -z "`pidof verysync`" ] && verysync_restart
		verysync_port_dpt
	fi
fi
}

verysync_keep () {
logger -t "【verysync】" "守护进程启动"
if [ -s /tmp/script/_opt_script_check ]; then
sed -Ei '/【verysync】|^$/d' /tmp/script/_opt_script_check
cat >> "/tmp/script/_opt_script_check" <<-OSC
[ -z "\`pidof verysync\`" ] || [ ! -s "$verysync_upanPath/verysync/verysync" ] && nvram set verysync_status=00 && logger -t "【verysync】" "重新启动" && eval "$scriptfilepath &" && sed -Ei '/【verysync】|^$/d' /tmp/script/_opt_script_check # 【verysync】
OSC
return
fi

while true; do
	if [ -z "`pidof verysync`" ] || [ ! -s "$verysync_upanPath/verysync/verysync" ] ; then
		logger -t "【verysync】" "重新启动"
		verysync_restart
	fi
sleep 252
done
}

verysync_close () {

sed -Ei '/【verysync】|^$/d' /tmp/script/_opt_script_check
iptables -t filter -D INPUT -p tcp --dport 22330 -j ACCEPT
iptables -t filter -D INPUT -p udp --dport 22331 -j ACCEPT
iptables -t filter -D INPUT -p tcp --dport $verysync_wan_port -j ACCEPT
killall verysync
killall -9 verysync
kill_ps "/tmp/script/_app6"
kill_ps "_very_sync.sh"
kill_ps "$scriptname"
}

verysync_start () {

ss_opt_x=`nvram get ss_opt_x`
upanPath=""
[ "$ss_opt_x" = "3" ] && upanPath="`df -m | grep /dev/mmcb | grep "/media" | awk '{print $NF}' | sort -u | awk 'NR==1' `"
[ "$ss_opt_x" = "4" ] && upanPath="`df -m | grep "/dev/sd" | grep "/media" | awk '{print $NF}' | sort -u | awk 'NR==1' `"
[ -z "$upanPath" ] && [ "$ss_opt_x" = "1" ] && upanPath="`df -m | grep /dev/mmcb | grep "/media" | awk '{print $NF}' | sort -u | awk 'NR==1' `"
[ -z "$upanPath" ] && [ "$ss_opt_x" = "1" ] && upanPath="`df -m | grep "/dev/sd" | grep "/media" | awk '{print $NF}' | sort -u | awk 'NR==1' `"
if [ "$ss_opt_x" = "5" ] ; then
	# 指定目录
	opt_cifs_dir=`nvram get opt_cifs_dir`
	if [ -d $opt_cifs_dir ] ; then
		upanPath="$opt_cifs_dir"
	else
		logger -t "【opt】" "错误！未找到指定目录 $opt_cifs_dir"
		upanPath=""
		[ -z "$upanPath" ] && upanPath="`df -m | grep /dev/mmcb | grep "/media" | awk '{print $NF}' | sort -u | awk 'NR==1' `"
		[ -z "$upanPath" ] && upanPath="`df -m | grep "/dev/sd" | grep "/media" | awk '{print $NF}' | sort -u | awk 'NR==1' `"
	fi
fi
echo "$upanPath"
if [ -z "$upanPath" ] ; then 
	logger -t "【verysync】" "未挂载储存设备, 请重新检查配置、目录，10 秒后自动尝试重新启动"
	sleep 10
	verysync_restart x
	exit 0
fi
SVC_PATH="$upanPath/verysync/verysync"
mkdir -p "$upanPath/verysync/.config"
if [ ! -s "$SVC_PATH" ] && [ -d "$upanPath/verysync" ] ; then
	logger -t "【verysync】" "找不到 $SVC_PATH ，安装 verysync 程序"
	logger -t "【verysync】" "开始下载 verysync"
	wgetcurl.sh "$upanPath/verysync/verysync" "$hiboyfile/verysync" "$hiboyfile2/verysync"
fi
chmod 777 "$SVC_PATH"
[[ "$($SVC_PATH -h 2>&1 | wc -l)" -lt 2 ]] && rm -rf $SVC_PATH
if [ ! -s "$SVC_PATH" ] ; then
	logger -t "【verysync】" "找不到 $SVC_PATH ，需要手动安装 $SVC_PATH"
	logger -t "【verysync】" "启动失败, 10 秒后自动尝试重新启动" && sleep 10 && verysync_restart x
fi
chmod 777 "$SVC_PATH"
verysync_v=$($SVC_PATH -version | grep verysync | awk -F ' ' '{print $2;}')
nvram set verysync_v="$verysync_v"
logger -t "【verysync】" "运行 verysync"

verysync_wan_port_tmp="$(nvram get verysync_wan_port_tmp)"
iptables -t filter -D INPUT -p tcp --dport $verysync_wan_port_tmp -j ACCEPT
nvram set verysync_wan_port_tmp="$verysync_wan_port"

verysync_upanPath="$upanPath"
nvram set verysync_upanPath="$upanPath"

"$upanPath/verysync/verysync" -home "$upanPath/verysync/.config" -gui-address "0.0.0.0:$verysync_wan_port" &

sleep 2
[ ! -z "$(ps -w | grep "verysync" | grep -v grep )" ] && logger -t "【verysync】" "启动成功" && verysync_restart o
[ -z "$(ps -w | grep "verysync" | grep -v grep )" ] && logger -t "【verysync】" "启动失败, 注意检查端口是否有冲突,程序是否下载完整,10 秒后自动尝试重新启动" && sleep 10 && verysync_restart x
initopt
verysync_port_dpt

#verysync_get_status
eval "$scriptfilepath keep &"
}

initopt () {
optPath=`grep ' /opt ' /proc/mounts | grep tmpfs`
[ ! -z "$optPath" ] && return
if [ ! -z "$(echo $scriptfilepath | grep -v "/opt/etc/init")" ] && [ -s "/opt/etc/init.d/rc.func" ] ; then
	{ echo '#!/bin/sh' ; echo $scriptfilepath '"$@"' '&' ; } > /opt/etc/init.d/$scriptname && chmod 777  /opt/etc/init.d/$scriptname
fi

}

verysync_port_dpt () {

port=$(iptables -t filter -L INPUT -v -n --line-numbers | grep dpt:22330 | cut -d " " -f 1 | sort -nr | wc -l)
if [ "$port" = 0 ] ; then
	logger -t "【verysync】" "允许 22330、22331 tcp端口通过防火墙"
	iptables -t filter -I INPUT -p tcp --dport 22330 -j ACCEPT
	iptables -t filter -I INPUT -p udp --dport 22331 -j ACCEPT
fi
if [ "$verysync_wan" = "1" ] ; then
	port=$(iptables -t filter -L INPUT -v -n --line-numbers | grep dpt:verysync_wan_port | cut -d " " -f 1 | sort -nr | wc -l)
	if [ "$port" = 0 ] ; then
		logger -t "【verysync】" "WebGUI 允许 $verysync_wan_port tcp端口通过防火墙"
		iptables -t filter -I INPUT -p tcp --dport $verysync_wan_port -j ACCEPT
	fi
fi
}

update_app () {

mkdir -p /opt/app/verysync
if [ "$1" = "del" ] ; then
	rm -rf /opt/app/verysync/Advanced_Extensions_verysync.asp
	[ -f $verysync_upanPath/verysync/verysync ] && rm -f $verysync_upanPath/verysync/verysync
fi

# 加载程序配置页面
if [ ! -f "/opt/app/verysync/Advanced_Extensions_verysync.asp" ] || [ ! -s "/opt/app/verysync/Advanced_Extensions_verysync.asp" ] ; then
	wgetcurl.sh /opt/app/verysync/Advanced_Extensions_verysync.asp "$hiboyfile/Advanced_Extensions_verysyncasp" "$hiboyfile2/Advanced_Extensions_verysyncasp"
fi
umount /www/Advanced_Extensions_app06.asp
mount --bind /opt/app/verysync/Advanced_Extensions_verysync.asp /www/Advanced_Extensions_app06.asp
# 更新程序启动脚本

[ "$1" = "del" ] && /etc/storage/www_sh/verysync del &
}

case $ACTION in
start)
	verysync_close
	verysync_check
	;;
check)
	verysync_check
	;;
stop)
	verysync_close
	;;
updateapp6)
	verysync_restart o
	[ "$verysync_enable" = "1" ] && nvram set verysync_status="updateverysync" && logger -t "【verysync】" "重启" && verysync_restart
	[ "$verysync_enable" != "1" ] && nvram set verysync_v="" && logger -t "【verysync】" "更新" && update_app del
	;;
update_app)
	update_app
	;;
keep)
	#verysync_check
	verysync_keep
	;;
*)
	verysync_check
	;;
esac

