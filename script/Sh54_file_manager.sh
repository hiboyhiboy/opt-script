#!/bin/bash
#copyright by hiboy
source /etc/storage/script/init.sh
filemanager_wan_port=`nvram get app_14`
[ -z $filemanager_wan_port ] && filemanager_wan_port=888 && nvram set app_14=$filemanager_wan_port
filemanager_enable=`nvram get app_15`
[ -z $filemanager_enable ] && filemanager_enable=0 && nvram set app_15=0
filemanager_wan=`nvram get app_16`
[ -z $filemanager_wan ] && filemanager_wan=0 && nvram set app_16=0
enable_version=`nvram get app_54`
[ -z $enable_version ] && enable_version=2 && nvram set app_54=2
[ "$enable_version" = "2" ] && filemanager_exe="filebrowser"
[ "$enable_version" = "0" ] && filemanager_exe="filemanager"
if [ "$enable_version" = "1" ] ; then
	logger -t "【filemanager】" "取消 filemanager_v1_caddy 版本启动，请重新选择启动版本后尝试重新启动"
	filemanager_enable=0 && nvram set app_15=0
fi
filebrowser_usage=`nvram get app_80`
[ -z "$(echo "$filebrowser_usage" | grep filebrowser)" ] && filebrowser_usage="filebrowser -a 0.0.0.0 --disable-preview-resize --disable-type-detection-by-header" && nvram set app_80="$filebrowser_usage"

filemanager_upanPath=`nvram get filemanager_upanPath`

filemanager_renum=`nvram get filemanager_renum`
filemanager_renum=${filemanager_renum:-"0"}
cmd_log_enable=`nvram get cmd_log_enable`
cmd_name="$filemanager_exe"
cmd_log=""
if [ "$cmd_log_enable" = "1" ] || [ "$filemanager_renum" -gt "0" ] ; then
	cmd_log="$cmd_log2"
fi
if [ ! -z "$(echo $scriptfilepath | grep -v "/tmp/script/" | grep file_manager)" ] && [ ! -s /tmp/script/_app5 ] ; then
	mkdir -p /tmp/script
	{ echo '#!/bin/bash' ; echo $scriptfilepath '"$@"' '&' ; } > /tmp/script/_app5
	chmod 777 /tmp/script/_app5
fi

upanPath=""

filemanager_restart () {
i_app_restart "$@" -name="filemanager"
}

filemanager_get_status () {

B_restart="$filemanager_enable$enable_version$filemanager_wan$filemanager_wan_port$(cat /etc/storage/app_5.sh | grep -v '^#' | grep -v '^$')"

i_app_get_status -name="filemanager" -valb="$B_restart"
}

filemanager_check () {

filemanager_get_status
if [ "$filemanager_enable" != "1" ] && [ "$needed_restart" = "1" ] ; then
	[ ! -z "`pidof caddy_filebrowser`" ] && logger -t "【filemanager】" "停止 caddy_filebrowser" && filemanager_close
	[ ! -z "`pidof filemanager`" ] && logger -t "【filemanager】" "停止 filemanager" && filemanager_close
	[ ! -z "`pidof filebrowser`" ] && logger -t "【filemanager】" "停止 filebrowser" && filemanager_close
	{ kill_ps "$scriptname" exit0; exit 0; }
fi
if [ "$filemanager_enable" = "1" ] ; then
	if [ "$needed_restart" = "1" ] ; then
		filemanager_close
		filemanager_start
	else
		[ -z "`pidof $filemanager_exe`" ] && filemanager_restart
		filemanager_port_dpt
	fi
fi
}

filemanager_keep () {
i_app_keep -name="filemanager" -pidof="$filemanager_exe" &
}

filemanager_close () {

kill_ps "$scriptname keep"
sed -Ei '/【filemanager】|^$/d' /tmp/script/_opt_script_check
iptables -t filter -D INPUT -p tcp --dport $filemanager_wan_port -j ACCEPT
killall filemanager caddy_filebrowser filebrowser
kill_ps "/tmp/script/_app5"
kill_ps "_file_manager.sh"
kill_ps "$scriptname"
}

filemanager_start () {

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
	logger -t "【filemanager】" "未挂载储存设备, 请重新检查配置、目录，10 秒后自动尝试重新启动"
	sleep 10
	filemanager_restart x
	exit 0
fi
if [ "$enable_version" = "2" ] ; then
mkdir -p "$upanPath/filebrowser/"
i_app_get_cmd_file -name="filemanager" -cmd="filebrowser" -cpath="/opt/bin/filebrowser" -down1="$hiboyfile/filebrowser" -down2="$hiboyfile2/filebrowser" -runh="help"
fi
if [ "$enable_version" = "0" ] ; then
i_app_get_cmd_file -name="filemanager" -cmd="$upanPath/filemanager/$filemanager_exe" -cpath="$upanPath/filemanager/$filemanager_exe" -down1="$hiboyfile/filemanager" -down2="$hiboyfile2/filemanager" -runh="help"
mkdir -p "$upanPath/filemanager/"
wgetcurl_file "$SVC_PATH" "$hiboyfile/filemanager" "$hiboyfile2/filemanager"
[[ "$($SVC_PATH -h 2>&1 | wc -l)" -lt 2 ]] && rm -rf $SVC_PATH
fi
if [ "$enable_version" = "2" ] ; then
	filebrowser2_start
fi
if [ "$enable_version" = "0" ] ; then
	filebrowser_start
fi
sleep 7
i_app_keep -t -name="filemanager" -pidof="$filemanager_exe"
filemanager_port_dpt
#filemanager_get_status
eval "$scriptfilepath keep &"
exit 0
}

filebrowser2_start () {

filemanager_v=$($SVC_PATH version | grep Browser | awk -F '-' '{print $1;}' | awk -F ' ' '{print $3;}' | tr -d 'v')
nvram set filemanager_v="$filemanager_v"
logger -t "【filemanager】" "运行 filebrowser $filemanager_v"
iptables -t filter -D INPUT -p tcp --dport $filemanager_wan_port -j ACCEPT

eval "cd $upanPath/filebrowser ; $filebrowser_usage -p $filemanager_wan_port -d $upanPath/filebrowser/filebrowser.db -r $upanPath $cmd_log" &

}

filebrowser_start () {

filemanager_v=$($SVC_PATH -v | grep version | awk -F 'version' '{print $2;}')
nvram set filemanager_v="$filemanager_v"
logger -t "【filemanager】" "运行 filemanager $filemanager_v"

filemanager_wan_port=`cat /etc/storage/app_5.sh | grep -Eo '"port": [0-9]+' | cut -d':' -f2 | tr -d ' ' | sed -n '1p'`
nvram set app_14=$filemanager_wan_port
iptables -t filter -D INPUT -p tcp --dport $filemanager_wan_port -j ACCEPT

filemanager_upanPath="$upanPath"
nvram set filemanager_upanPath="$upanPath"
rm -f /tmp/filemanager.json
ln -sf /etc/storage/app_5.sh /tmp/filemanager.json
eval "$upanPath/filemanager/filemanager -c /tmp/filemanager.json $cmd_log" &

}

initconfig () {

# 初始配置脚本
if [ ! -f "/etc/storage/app_5.sh" ] || [ ! -s "/etc/storage/app_5.sh" ] ; then
	cat >> "/etc/storage/app_5.sh" <<-\EOF
{
  "port": 888,
  "noAuth": false,
  "baseURL": "",
  "address": "",
  "reCaptchaKey": "",
  "reCaptchaSecret": "",
  "database": "/etc/storage/database.db",
  "log": "",
  "plugin": "",
  "scope": "/tmp/AiDisk_00",
  "allowCommands": true,
  "allowEdit": true,
  "allowNew": true,
  "commands": [
    "git",
    "svn"
  ]
}
EOF
fi

chmod 777 /etc/storage/app_5.sh

}

initconfig

filemanager_port_dpt () {

if [ "$filemanager_wan" = "1" ] ; then
	port=$(iptables -t filter -L INPUT -v -n --line-numbers | grep dpt:$filemanager_wan_port | cut -d " " -f 1 | sort -nr | wc -l)
	if [ "$port" = 0 ] ; then
		logger -t "【filemanager】" "WebGUI 允许 $filemanager_wan_port tcp端口通过防火墙"
		iptables -t filter -I INPUT -p tcp --dport $filemanager_wan_port -j ACCEPT
	fi
fi

}

update_app () {
mkdir -p /opt/app/filemanager
if [ "$1" = "update_asp" ] ; then
	rm -rf /opt/app/filemanager/Advanced_Extensions_filemanager.asp
fi
if [ "$1" = "del" ] ; then
	rm -rf /opt/app/filemanager/Advanced_Extensions_filemanager.asp
	[ -f "$filemanager_upanPath/filemanager/filemanager" ] && rm -f $filemanager_upanPath/filemanager/filemanager
	[ -f "$filemanager_upanPath/filemanager/caddy_filebrowser" ] && rm -f $filemanager_upanPath/filemanager/caddy_filebrowser
	[ -f "/opt/bin/filebrowser" ] && rm -f /opt/bin/filebrowser /opt/opt_backup/bin/filebrowser
fi

initconfig

# 加载程序配置页面
if [ ! -f "/opt/app/filemanager/Advanced_Extensions_filemanager.asp" ] || [ ! -s "/opt/app/filemanager/Advanced_Extensions_filemanager.asp" ] ; then
	wgetcurl.sh /opt/app/filemanager/Advanced_Extensions_filemanager.asp "$hiboyfile/Advanced_Extensions_filemanagerasp" "$hiboyfile2/Advanced_Extensions_filemanagerasp"
fi
umount /www/Advanced_Extensions_app05.asp
mount --bind /opt/app/filemanager/Advanced_Extensions_filemanager.asp /www/Advanced_Extensions_app05.asp
# 更新程序启动脚本

[ "$1" = "del" ] && /etc/storage/www_sh/filemanager del &
}

case $ACTION in
start)
	filemanager_close
	filemanager_check
	;;
check)
	filemanager_check
	;;
stop)
	filemanager_close
	;;
updateapp5)
	filemanager_restart o
	[ "$filemanager_enable" = "1" ] && nvram set filemanager_status="updatefilemanager" && logger -t "【filemanager】" "重启" && filemanager_restart
	[ "$filemanager_enable" != "1" ] && nvram set filemanager_v="" && logger -t "【filemanager】" "更新" && update_app del
	;;
update_app)
	update_app
	;;
update_asp)
	update_app update_asp
	;;
initconfig)
	initconfig
	;;
keep)
	#filemanager_check
	filemanager_keep
	;;
*)
	filemanager_check
	;;
esac

