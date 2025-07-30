#!/bin/bash
#copyright by hiboy
source /etc/storage/script/init.sh
arozos_enable=`nvram get app_148`
[ -z $arozos_enable ] && arozos_enable=0 && nvram set app_148=0
arozos_usage="$(nvram get app_3)"
[ -z "$(echo $arozos_usage | grep max_upload_size)" ] && arozos_usage=""
[ -z "$arozos_usage" ] && arozos_usage="-port 8680 -max_upload_size 8192 -bufffile_size 25 -buffpool_size 25 -enable_buffpool=true -enable_pwman=false -iobuf 25 -tmp_time 60 -upload_buf 25" && nvram set app_3="$arozos_usage"

if [ "$arozos_enable" != "0" ] ; then

arozos_renum=`nvram get arozos_renum`
arozos_renum=${arozos_renum:-"0"}

cmd_log_enable=`nvram get cmd_log_enable`
cmd_name="arozos"
cmd_log=""
if [ "$cmd_log_enable" = "1" ] || [ "$arozos_renum" -gt "0" ] ; then
	cmd_log="$cmd_log2"
fi

fi

if [ ! -z "$(echo $scriptfilepath | grep -v "/tmp/script/" | grep arozos)" ] && [ ! -s /tmp/script/_app30 ] ; then
	mkdir -p /tmp/script
	{ echo '#!/bin/bash' ; echo $scriptfilepath '"$@"' '&' ; } > /tmp/script/_app30
	chmod 777 /tmp/script/_app30
fi

arozos_restart () {
i_app_restart "$@" -name="arozos"
}

arozos_get_status () {

B_restart="$arozos_enable$arozos_usage"

i_app_get_status -name="arozos" -valb="$B_restart"
}

arozos_check () {

arozos_get_status
if [ "$arozos_enable" != "1" ] && [ "$needed_restart" = "1" ] ; then
	[ ! -z "`pidof arozos`" ] && logger -t "【arozos】" "停止 arozos" && arozos_close
	{ kill_ps "$scriptname" exit0; exit 0; }
fi
if [ "$arozos_enable" = "1" ] ; then
	if [ "$needed_restart" = "1" ] ; then
		arozos_close
		arozos_start
	else
		[ "$arozos_enable" = "1" ] && [ -z "`pidof arozos`" ] && arozos_restart
	fi
fi
}

arozos_keep () {
i_app_keep -name="arozos" -pidof="arozos" &

}

arozos_close () {
sed -Ei '/【arozos】|^$/d' /tmp/script/_opt_script_check
killall arozos
sleep 2
kill_ps "/tmp/script/_app30"
kill_ps "_arozos.sh"
kill_ps "$scriptname"
}

arozos_start () {
check_webui_yes

SVC_PATH="/tmp/AiDisk_00/arozos/arozos"
if [ ! -f $SVC_PATH ] ; then
	logger -t "【clash】" "找不到 $SVC_PATH ，安装 opt 程序"
	/etc/storage/script/Sh01_mountopt.sh start
	mkdir -p /tmp/AiDisk_00/arozos
fi
mkdir -p /tmp/AiDisk_00/arozos
block=$(check_disk_size /tmp/AiDisk_00/arozos)
[ -z "$block" ] && block="0"
[ "$block" != "0" ] && logger -t "【arozos】" "路径 /tmp/AiDisk_00/arozos 剩余空间：$block M"
if [ "$block" != "0" ] && [ ! -z "$block" ] && [ "$block" -lt "1500" ] && [ ! -d "/tmp/AiDisk_00/arozos/web" ] ; then
	[ "$block" = "0" ] && logger -t "【arozos】" "错误！！！剩余空间少于 1500M arozos 启动失败"
	nvram set app_148=0
	eval "$scriptfilepath &"
	exit 0
fi
if [ ! -s "$SVC_PATH" ] || [ ! -d "/tmp/AiDisk_00/arozos/web" ] ; then
	logger -t "【arozos】" "找不到 $SVC_PATH ，安装 arozos 程序"
	curltest=`which curl`
	if [ -z "$curltest" ] || [ ! -s "`which curl`" ] ; then
		tag="$( wget -T 5 -t 3 --user-agent "$user_agent" --max-redirect=0 --output-document=-  https://api.github.com/repos/tobychui/arozos/releases/latest  2>&1 | grep 'tag_name' | cut -d\" -f4 )"
		[ -z "$tag" ] && tag="$( wget -T 5 -t 3 --user-agent "$user_agent" --quiet --output-document=-  https://api.github.com/repos/tobychui/arozos/releases/latest  2>&1 | grep 'tag_name' | cut -d\" -f4 )"
	else
		tag="$( curl --connect-timeout 3 --user-agent "$user_agent"  https://api.github.com/repos/tobychui/arozos/releases/latest  2>&1 | grep 'tag_name' | cut -d\" -f4 )"
		[ -z "$tag" ] && tag="$( curl -L --connect-timeout 3 --user-agent "$user_agent" -s  https://api.github.com/repos/tobychui/arozos/releases/latest  2>&1 | grep 'tag_name' | cut -d\" -f4 )"
	fi
	[ -f /tmp/AiDisk_00/arozos/arozos_linux_mipsle ] && mv -f /tmp/AiDisk_00/arozos/arozos_linux_mipsle $SVC_PATH
	if [ ! -z "$tag" ] && [ ! -s "$SVC_PATH" ] ; then
		logger -t "【arozos】" "自动下载最新版本 arozos_linux_mipsle $tag "
		wgetcurl.sh "$SVC_PATH" "https://github.com/tobychui/arozos/releases/download/$tag/arozos_linux_mipsle"
	fi
	if [ ! -z "$tag" ] && [ ! -d "/tmp/AiDisk_00/arozos/web" ] ; then
		logger -t "【arozos】" "自动下载最新版本 web.tar.gz $tag"
		[ ! -f /tmp/AiDisk_00/arozos/web.tar.gz ] && wgetcurl.sh "/tmp/AiDisk_00/arozos/web.tar.gz" "https://github.com/tobychui/arozos/releases/download/$tag/web.tar.gz"
	fi
	if [ ! -s "$SVC_PATH" ] && [ ! -d "/tmp/AiDisk_00/arozos/web" ] ; then
		logger -t "【arozos】" "最新版本获取失败！！！"
		logger -t "【arozos】" "请打开 https://github.com/tobychui/arozos/releases"
		logger -t "【arozos】" "手动下载 arozos_linux_mipsle 和 web.tar.gz 文件。"
		logger -t "【arozos】" "2个文件文件放到 /tmp/AiDisk_00/arozos 文件夹里面。"
	fi
fi
chmod 777 "$SVC_PATH"
cd /tmp/AiDisk_00/arozos
arozos_v="$($SVC_PATH -version | head -n1)"
nvram set arozos_v="$arozos_v"
logger -t "【arozos】" "运行 $SVC_PATH"
[ -f /tmp/AiDisk_00/arozos/web.tar.gz ] && logger -t "【arozos】" "首次运行，解压资源需等待 10-20 分钟"
su_cmd="eval"
su_cmd2="$SVC_PATH $arozos_usage"
eval "$su_cmd" '"cmd_name=arozos ; '"$su_cmd2"' $cmd_log2"' &
sleep 3
i_app_keep -t -name="arozos" -pidof="arozos"
#arozos_get_status
eval "$scriptfilepath keep &"
exit 0
}


# initconfig

update_app () {

mkdir -p /opt/app/arozos
if [ "$1" = "del" ] ; then
	rm -rf /opt/app/arozos/Advanced_Extensions_arozos.asp
	rm -rf /tmp/AiDisk_00/arozos/web
	rm -rf /tmp/AiDisk_00/arozos/system
	rm -rf /tmp/AiDisk_00/arozos/web.tar.gz
	rm -rf /tmp/AiDisk_00/arozos/arozos
fi

# initconfig

# 加载程序配置页面
if [ ! -f "/opt/app/arozos/Advanced_Extensions_arozos.asp" ] || [ ! -s "/opt/app/arozos/Advanced_Extensions_arozos.asp" ] ; then
	wgetcurl.sh /opt/app/arozos/Advanced_Extensions_arozos.asp "$hiboyfile/Advanced_Extensions_arozosasp" "$hiboyfile2/Advanced_Extensions_arozosasp"
fi
umount /www/Advanced_Extensions_app30.asp
mount --bind /opt/app/arozos/Advanced_Extensions_arozos.asp /www/Advanced_Extensions_app30.asp
# 更新程序启动脚本

[ "$1" = "del" ] && /etc/storage/www_sh/ArozOS del &
}

case $ACTION in
start)
	arozos_close
	arozos_check
	;;
check)
	arozos_check
	;;
stop)
	arozos_close
	;;
updateapp30)
	arozos_restart o
	[ "$arozos_enable" = "1" ] && nvram set arozos_status="updatearozos" && logger -t "【arozos】" "重启" && arozos_restart
	[ "$arozos_enable" != "1" ] && nvram set arozos_v="" && logger -t "【arozos】" "更新" && update_app del
	;;
update_app)
	update_app
	;;
keep)
	#arozos_check
	arozos_keep
	;;
*)
	arozos_check
	;;
esac

