#!/bin/bash
#copyright by hiboy
source /etc/storage/script/init.sh
verysync_enable=`nvram get app_20`
[ -z $verysync_enable ] && verysync_enable=0 && nvram set app_20=0
verysync_wan_port=`nvram get app_21`
[ -z $verysync_wan_port ] && verysync_wan_port=8886 && nvram set app_21=$verysync_wan_port
verysync_wan=`nvram get app_22`
[ -z $verysync_wan ] && verysync_wan=0 && nvram set app_22=0
verysync_upanPath=`nvram get verysync_upanPath`

verysync_renum=`nvram get verysync_renum`
verysync_renum=${verysync_renum:-"0"}
cmd_log_enable=`nvram get cmd_log_enable`
cmd_name="verysync"
cmd_log=""
if [ "$cmd_log_enable" = "1" ] || [ "$verysync_renum" -gt "0" ] ; then
	cmd_log="$cmd_log2"
fi
if [ ! -z "$(echo $scriptfilepath | grep -v "/tmp/script/" | grep very_sync)" ] && [ ! -s /tmp/script/_app6 ] ; then
	mkdir -p /tmp/script
	{ echo '#!/bin/bash' ; echo $scriptfilepath '"$@"' '&' ; } > /tmp/script/_app6
	chmod 777 /tmp/script/_app6
fi

upanPath=""

verysync_restart () {
i_app_restart "$@" -name="verysync"
}

verysync_get_status () {

B_restart="$verysync_enable$verysync_wan$verysync_wan_port"

i_app_get_status -name="verysync" -valb="$B_restart"
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
i_app_keep -name="verysync" -pidof="verysync" -cpath="${verysync_upanPath}/verysync/verysync" &
}

verysync_close () {

kill_ps "$scriptname keep"
sed -Ei '/【verysync】|^$/d' /tmp/script/_opt_script_check
iptables -t filter -D INPUT -p tcp --dport 22330 -j ACCEPT
iptables -t filter -D INPUT -p udp --dport 22331 -j ACCEPT
iptables -t filter -D INPUT -p tcp --dport $verysync_wan_port -j ACCEPT
killall verysync
sync;echo 3 > /proc/sys/vm/drop_caches
kill_ps "/tmp/script/_app6"
kill_ps "_very_sync.sh"
kill_ps "$scriptname"
}

verysync_start () {

check_webui_yes
ss_opt_x=`nvram get ss_opt_x`
upanPath=""
[ "$ss_opt_x" = "3" ] && upanPath="`df -m | grep /dev/mmcb | grep -E "$(echo $(/usr/bin/find /dev/ -name 'mmcb*') | sed -e 's@/dev/ /dev/@/dev/@g' | sed -e 's@ @|@g')" | grep "/media" | awk '{print $NF}' | sort -u | awk 'NR==1' `"
[ "$ss_opt_x" = "4" ] && upanPath="`df -m | grep /dev/sd | grep -E "$(echo $(/usr/bin/find /dev/ -name 'sd*') | sed -e 's@/dev/ /dev/@/dev/@g' | sed -e 's@ @|@g')" | grep "/media" | awk '{print $NF}' | sort -u | awk 'NR==1' `"
[ -z "$upanPath" ] && [ "$ss_opt_x" = "1" ] && upanPath="`df -m | grep /dev/mmcb | grep -E "$(echo $(/usr/bin/find /dev/ -name 'mmcb*') | sed -e 's@/dev/ /dev/@/dev/@g' | sed -e 's@ @|@g')" | grep "/media" | awk '{print $NF}' | sort -u | awk 'NR==1' `"
[ -z "$upanPath" ] && [ "$ss_opt_x" = "1" ] && upanPath="`df -m | grep /dev/sd | grep -E "$(echo $(/usr/bin/find /dev/ -name 'sd*') | sed -e 's@/dev/ /dev/@/dev/@g' | sed -e 's@ @|@g')" | grep "/media" | awk '{print $NF}' | sort -u | awk 'NR==1' `"
if [ "$ss_opt_x" = "5" ] ; then
	# 指定目录
	opt_cifs_dir=`nvram get opt_cifs_dir`
	if [ -d $opt_cifs_dir ] ; then
		upanPath="$opt_cifs_dir"
	else
		logger -t "【opt】" "错误！未找到指定目录 $opt_cifs_dir"
	fi
fi
if [ "$ss_opt_x" = "6" ] ; then
	opt_cifs_2_dir=`nvram get opt_cifs_2_dir`
	# 远程共享
	if mountpoint -q "$opt_cifs_2_dir" && [ -d "$opt_cifs_2_dir" ] ; then
		upanPath="$opt_cifs_2_dir"
	else
		logger -t "【opt】" "错误！未找到指定远程共享目录 $opt_cifs_2_dir"
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
chmod 777 "$SVC_PATH"
[[ "$($SVC_PATH -h 2>&1 | wc -l)" -lt 2 ]] && rm -rf $SVC_PATH
if [ ! -s "$SVC_PATH" ] ; then
# 获取最新版本
curltest=`which curl`
if [ -z "$curltest" ] || [ ! -s "`which curl`" ] ; then
	verysync_tag="$( wget -T 5 -t 3 --user-agent "$user_agent" --max-redirect=0 --output-document=-  http://www.verysync.com/shell/latest )"
	[ -z "$verysync_tag" ] && verysync_tag="$( wget -T 5 -t 3 --user-agent "$user_agent" --quiet --output-document=-  http://www.verysync.com/shell/latest )"
else
	verysync_tag="$( curl --connect-timeout 3 --user-agent "$user_agent"  http://www.verysync.com/shell/latest )"
	[ -z "$verysync_tag" ] && verysync_tag="$( curl -L --connect-timeout 3 --user-agent "$user_agent" -s  http://www.verysync.com/shell/latest )"
fi
[ -z "$verysync_tag" ] && logger -t "【verysync】" "最新版本获取失败！！！"
[ ! -z "$verysync_tag" ] && logger -t "【verysync】" "最新版本 $verysync_tag"
[ -z "$verysync_tag" ] && verysync_tag="$verysync_version_2" && logger -t "【verysync】" "使用：$hiboyfile/verysync" && verysync_tag=""
verysync_tag="$(echo "$verysync_tag" | tr -d 'v' | tr -d ' ')"
if [ ! -z "$verysync_tag" ] ; then
	# http://www.verysync.com 下载最新版本
	wgetcurl.sh "$upanPath/verysync/verysync-linux-mipsle.tar.gz" "http://releases-cdn.verysync.com/releases/v""$verysync_tag""/verysync-linux-mipsle-v""$verysync_tag"".tar.gz"
	tar -xzvf "$upanPath/verysync/verysync-linux-mipsle.tar.gz" -C $upanPath/verysync ; cd $upanPath/verysync
	rm -f "$upanPath/verysync/verysync-linux-mipsle.tar.gz"
	mv -f $upanPath/verysync/verysync-linux-mipsle-v* $upanPath/verysync/verysync-linux-mipsle
	mv -f $upanPath/verysync/verysync-linux-mipsle/verysync $SVC_PATH
	rm -rf $upanPath/verysync/verysync-linux-mipsle
	chmod 777 "$SVC_PATH"
fi
wgetcurl_file "$SVC_PATH" "$hiboyfile/verysync" "$hiboyfile2/verysync"
[[ "$($SVC_PATH -h 2>&1 | wc -l)" -lt 2 ]] && rm -rf $SVC_PATH
if [ ! -s "$SVC_PATH" ] ; then
	logger -t "【verysync】" "找不到 $SVC_PATH ，需要手动安装 $SVC_PATH"
	logger -t "【verysync】" "启动失败, 10 秒后自动尝试重新启动" && sleep 10 && verysync_restart x
fi
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

eval "$upanPath/verysync/verysync -no-restart -home $upanPath/verysync/.config -gui-address 0.0.0.0:$verysync_wan_port $cmd_log" &

sleep 4
i_app_keep -t -name="verysync" -pidof="verysync" -cpath="${verysync_upanPath}/verysync/verysync"
verysync_port_dpt

#verysync_get_status
eval "$scriptfilepath keep &"
exit 0
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
if [ "$1" = "update_asp" ] ; then
	rm -rf /opt/app/verysync/Advanced_Extensions_verysync.asp
fi
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
update_asp)
	update_app update_asp
	;;
keep)
	#verysync_check
	verysync_keep
	;;
*)
	verysync_check
	;;
esac

