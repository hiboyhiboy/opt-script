#!/bin/bash
#copyright by hiboy
source /etc/storage/script/init.sh
zoraxy_enable=`nvram get app_149`
[ -z $zoraxy_enable ] && zoraxy_enable=0 && nvram set app_149=0
zoraxy_usage="$(nvram get app_4)"
[ -z "$(echo $zoraxy_usage | grep '\-port=')" ] && zoraxy_usage=""
[ -z "$zoraxy_usage" ] && zoraxy_usage="-port=:8688" && nvram set app_4="$zoraxy_usage"

if [ "$zoraxy_enable" != "0" ] ; then

zoraxy_renum=`nvram get zoraxy_renum`
zoraxy_renum=${zoraxy_renum:-"0"}

cmd_log_enable=`nvram get cmd_log_enable`
cmd_name="zoraxy"
cmd_log=""
if [ "$cmd_log_enable" = "1" ] || [ "$zoraxy_renum" -gt "0" ] ; then
	cmd_log="$cmd_log2"
fi

fi

if [ ! -z "$(echo $scriptfilepath | grep -v "/tmp/script/" | grep zoraxy)" ] && [ ! -s /tmp/script/_app31 ] ; then
	mkdir -p /tmp/script
	{ echo '#!/bin/bash' ; echo $scriptfilepath '"$@"' '&' ; } > /tmp/script/_app31
	chmod 777 /tmp/script/_app31
fi

zoraxy_restart () {
i_app_restart "$@" -name="zoraxy"
}

zoraxy_get_status () {

B_restart="$zoraxy_enable$zoraxy_usage"

i_app_get_status -name="zoraxy" -valb="$B_restart"
}

zoraxy_check () {

zoraxy_get_status
if [ "$zoraxy_enable" != "1" ] && [ "$needed_restart" = "1" ] ; then
	[ ! -z "`pidof zoraxy`" ] && logger -t "【zoraxy】" "停止 zoraxy" && zoraxy_close
	{ kill_ps "$scriptname" exit0; exit 0; }
fi
if [ "$zoraxy_enable" = "1" ] ; then
	if [ "$needed_restart" = "1" ] ; then
		zoraxy_close
		zoraxy_start
	else
		[ "$zoraxy_enable" = "1" ] && [ -z "`pidof zoraxy`" ] && zoraxy_restart
	fi
fi
}

zoraxy_keep () {
i_app_keep -name="zoraxy" -pidof="zoraxy" &

}

zoraxy_close () {
sed -Ei '/【zoraxy】|^$/d' /tmp/script/_opt_script_check
killall zoraxy
sleep 2
kill_ps "/tmp/script/_app31"
kill_ps "_zoraxy.sh"
kill_ps "$scriptname"
}

zoraxy_start () {
check_webui_yes

SVC_PATH="/tmp/AiDisk_00/zoraxy/zoraxy"
if [ ! -f $SVC_PATH ] ; then
	logger -t "【clash】" "找不到 $SVC_PATH ，安装 opt 程序"
	/etc/storage/script/Sh01_mountopt.sh start
	mkdir -p /tmp/AiDisk_00/zoraxy
fi
mkdir -p /tmp/AiDisk_00/zoraxy
block=$(check_disk_size /tmp/AiDisk_00/zoraxy)
[ -z "$block" ] && block="0"
[ "$block" != "0" ] && logger -t "【zoraxy】" "路径 /tmp/AiDisk_00/zoraxy 剩余空间：$block M"
if [ "$block" != "0" ] && [ ! -z "$block" ] && [ "$block" -lt "150" ] && [ ! -f "/tmp/AiDisk_00/zoraxy/zoraxy" ] ; then
	[ "$block" = "0" ] && logger -t "【zoraxy】" "错误！！！剩余空间少于 150M zoraxy 启动失败"
	nvram set app_149=0
	eval "$scriptfilepath &"
	exit 0
fi
if [ ! -s "$SVC_PATH" ] ; then
	logger -t "【zoraxy】" "找不到 $SVC_PATH ，安装 zoraxy 程序"
	curltest=`which curl`
	if [ -z "$curltest" ] || [ ! -s "`which curl`" ] ; then
		tag="$( wget -T 5 -t 3 --user-agent "$user_agent" --max-redirect=0 --output-document=-  https://api.github.com/repos/tobychui/zoraxy/releases/latest  2>&1 | grep 'tag_name' | cut -d\" -f4 )"
		[ -z "$tag" ] && tag="$( wget -T 5 -t 3 --user-agent "$user_agent" --quiet --output-document=-  https://api.github.com/repos/tobychui/zoraxy/releases/latest  2>&1 | grep 'tag_name' | cut -d\" -f4 )"
	else
		tag="$( curl --connect-timeout 3 --user-agent "$user_agent"  https://api.github.com/repos/tobychui/zoraxy/releases/latest  2>&1 | grep 'tag_name' | cut -d\" -f4 )"
		[ -z "$tag" ] && tag="$( curl -L --connect-timeout 3 --user-agent "$user_agent" -s  https://api.github.com/repos/tobychui/zoraxy/releases/latest  2>&1 | grep 'tag_name' | cut -d\" -f4 )"
	fi
	[ -f /tmp/AiDisk_00/zoraxy/zoraxy_linux_mipsle ] && mv -f /tmp/AiDisk_00/zoraxy/zoraxy_linux_mipsle $SVC_PATH
	if [ ! -z "$tag" ] && [ ! -s "$SVC_PATH" ] ; then
		logger -t "【zoraxy】" "自动下载最新版本 zoraxy_linux_mipsle $tag "
		wgetcurl.sh "$SVC_PATH" "https://github.com/tobychui/zoraxy/releases/download/$tag/zoraxy_linux_mipsle"
	fi
	if [ ! -s "$SVC_PATH" ] ; then
		logger -t "【zoraxy】" "最新版本获取失败！！！"
		logger -t "【zoraxy】" "请打开 https://github.com/tobychui/zoraxy/releases"
		logger -t "【zoraxy】" "手动下载 zoraxy_linux_mipsle 文件。"
		logger -t "【zoraxy】" "文件文件放到 /tmp/AiDisk_00/zoraxy 文件夹里面。"
	fi
fi
chmod 777 "$SVC_PATH"
cd /tmp/AiDisk_00/zoraxy
zoraxy_v="$($SVC_PATH -version | head -n1)"
nvram set zoraxy_v="$zoraxy_v"
logger -t "【zoraxy】" "运行 $SVC_PATH"
su_cmd="eval"
su_cmd2="$SVC_PATH $zoraxy_usage"
eval "$su_cmd" '"cmd_name=zoraxy ; '"$su_cmd2"' $cmd_log2"' &
sleep 3
i_app_keep -t -name="zoraxy" -pidof="zoraxy"
#zoraxy_get_status
eval "$scriptfilepath keep &"
exit 0
}


# initconfig

update_app () {

mkdir -p /opt/app/zoraxy
if [ "$1" = "del" ] ; then
	rm -rf /opt/app/zoraxy/Advanced_Extensions_zoraxy.asp
	rm -rf /tmp/AiDisk_00/zoraxy/zoraxy
fi

# initconfig

# 加载程序配置页面
if [ ! -f "/opt/app/zoraxy/Advanced_Extensions_zoraxy.asp" ] || [ ! -s "/opt/app/zoraxy/Advanced_Extensions_zoraxy.asp" ] ; then
	wgetcurl.sh /opt/app/zoraxy/Advanced_Extensions_zoraxy.asp "$hiboyfile/Advanced_Extensions_zoraxyasp" "$hiboyfile2/Advanced_Extensions_zoraxyasp"
fi
umount /www/Advanced_Extensions_app31.asp
mount --bind /opt/app/zoraxy/Advanced_Extensions_zoraxy.asp /www/Advanced_Extensions_app31.asp
# 更新程序启动脚本

[ "$1" = "del" ] && /etc/storage/www_sh/Zoraxy del &
}

case $ACTION in
start)
	zoraxy_close
	zoraxy_check
	;;
check)
	zoraxy_check
	;;
stop)
	zoraxy_close
	;;
updateapp31)
	zoraxy_restart o
	[ "$zoraxy_enable" = "1" ] && nvram set zoraxy_status="updatezoraxy" && logger -t "【zoraxy】" "重启" && zoraxy_restart
	[ "$zoraxy_enable" != "1" ] && nvram set zoraxy_v="" && logger -t "【zoraxy】" "更新" && update_app del
	;;
update_app)
	update_app
	;;
keep)
	#zoraxy_check
	zoraxy_keep
	;;
*)
	zoraxy_check
	;;
esac

