#!/bin/sh
#copyright by hiboy
source /etc/storage/script/init.sh
filemanager_wan_port=`nvram get app_14`
[ -z $filemanager_wan_port ] && filemanager_wan_port=888 && nvram set app_14=$filemanager_wan_port
filemanager_enable=`nvram get app_15`
[ -z $filemanager_enable ] && filemanager_enable=0 && nvram set app_15=0
filemanager_wan=`nvram get app_16`
[ -z $filemanager_wan ] && filemanager_wan=0 && nvram set app_16=0
filemanager_upanPath=`nvram get filemanager_upanPath`
#if [ "$filemanager_enable" != "0" ] ; then
#nvramshow=`nvram showall | grep '=' | grep filemanager | awk '{print gensub(/'"'"'/,"'"'"'\"'"'"'\"'"'"'","g",$0);}'| awk '{print gensub(/=/,"='\''",1,$0)"'\'';";}'` && eval $nvramshow
#fi

if [ ! -z "$(echo $scriptfilepath | grep -v "/tmp/script/" | grep file_manager)" ]  && [ ! -s /tmp/script/_app5 ]; then
	mkdir -p /tmp/script
	{ echo '#!/bin/sh' ; echo $scriptfilepath '"$@"' '&' ; } > /tmp/script/_app5
	chmod 777 /tmp/script/_app5
fi

upanPath=""

filemanager_restart () {

relock="/var/lock/filemanager_restart.lock"
if [ "$1" = "o" ] ; then
	nvram set filemanager_renum="0"
	[ -f $relock ] && rm -f $relock
	return 0
fi
if [ "$1" = "x" ] ; then
	if [ -f $relock ] ; then
		logger -t "【filemanager】" "多次尝试启动失败，等待【"`cat $relock`"分钟】后自动尝试重新启动"
		exit 0
	fi
	filemanager_renum=${filemanager_renum:-"0"}
	filemanager_renum=`expr $filemanager_renum + 1`
	nvram set filemanager_renum="$filemanager_renum"
	if [ "$filemanager_renum" -gt "2" ] ; then
		I=19
		echo $I > $relock
		logger -t "【filemanager】" "多次尝试启动失败，等待【"`cat $relock`"分钟】后自动尝试重新启动"
		while [ $I -gt 0 ]; do
			I=$(($I - 1))
			echo $I > $relock
			sleep 60
			[ "$(nvram get filemanager_renum)" = "0" ] && exit 0
			[ $I -lt 0 ] && break
		done
		nvram set filemanager_renum="0"
	fi
	[ -f $relock ] && rm -f $relock
fi
nvram set filemanager_status=0
eval "$scriptfilepath &"
exit 0
}

filemanager_get_status () {

A_restart=`nvram get filemanager_status`
B_restart="$filemanager_enable$filemanager_wan$filemanager_wan_port$(cat /etc/storage/app_5.sh | grep -v "^#" | grep -v "^$")"
B_restart=`echo -n "$B_restart" | md5sum | sed s/[[:space:]]//g | sed s/-//g`
if [ "$A_restart" != "$B_restart" ] ; then
	nvram set filemanager_status=$B_restart
	needed_restart=1
else
	needed_restart=0
fi
}

filemanager_check () {

filemanager_get_status
if [ "$filemanager_enable" != "1" ] && [ "$needed_restart" = "1" ] ; then
	[ ! -z "`pidof filemanager`" ] && logger -t "【filemanager】" "停止 filemanager" && filemanager_close
	{ kill_ps "$scriptname" exit0; exit 0; }
fi
if [ "$filemanager_enable" = "1" ] ; then
	if [ "$needed_restart" = "1" ] ; then
		filemanager_close
		filemanager_start
	else
		[ -z "`pidof filemanager`" ] && filemanager_restart
		filemanager_port_dpt
	fi
fi
}

filemanager_keep () {
logger -t "【filemanager】" "守护进程启动"
if [ -s /tmp/script/_opt_script_check ]; then
sed -Ei '/【filemanager】|^$/d' /tmp/script/_opt_script_check
cat >> "/tmp/script/_opt_script_check" <<-OSC
[ -z "\`pidof filemanager\`" ] || [ ! -s "$filemanager_upanPath/filemanager/filemanager" ] && nvram set filemanager_status=00 && logger -t "【filemanager】" "重新启动" && eval "$scriptfilepath &" && sed -Ei '/【filemanager】|^$/d' /tmp/script/_opt_script_check # 【filemanager】
OSC
return
fi

while true; do
	if [ -z "`pidof filemanager`" ] || [ ! -s "$filemanager_upanPath/filemanager/filemanager" ] ; then
		logger -t "【filemanager】" "重新启动"
		filemanager_restart
	fi
sleep 252
done
}

filemanager_close () {

sed -Ei '/【filemanager】|^$/d' /tmp/script/_opt_script_check
iptables -t filter -D INPUT -p tcp --dport $filemanager_wan_port -j ACCEPT
killall filemanager
killall -9 filemanager
kill_ps "/tmp/script/_app5"
kill_ps "_file_manager.sh"
kill_ps "$scriptname"
}

filemanager_start () {

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
	logger -t "【filemanager】" "未挂载储存设备, 请重新检查配置、目录，10 秒后自动尝试重新启动"
	sleep 10
	filemanager_restart x
	exit 0
fi
SVC_PATH="$upanPath/filemanager/filemanager"
mkdir -p "$upanPath/filemanager/"
if [ ! -s "$SVC_PATH" ] && [ -d "$upanPath/filemanager" ] ; then
	logger -t "【filemanager】" "找不到 $SVC_PATH ，安装 filemanager 程序"
	logger -t "【filemanager】" "开始下载 filemanager"
	wgetcurl.sh "$upanPath/filemanager/filemanager" "$hiboyfile/filemanager" "$hiboyfile2/filemanager"
fi
chmod 777 "$SVC_PATH"
[[ "$($SVC_PATH -h 2>&1 | wc -l)" -lt 2 ]] && rm -rf $SVC_PATH
if [ ! -s "$SVC_PATH" ] ; then
	logger -t "【filemanager】" "找不到 $SVC_PATH ，需要手动安装 $SVC_PATH"
	logger -t "【filemanager】" "启动失败, 10 秒后自动尝试重新启动" && sleep 10 && filemanager_restart x
fi
chmod 777 "$SVC_PATH"
filemanager_v=$($SVC_PATH -v | grep version | awk -F 'version' '{print $2;}')
nvram set filemanager_v="$filemanager_v"
logger -t "【filemanager】" "运行 filemanager"

filemanager_wan_port=`cat /etc/storage/app_5.sh | grep -Eo '"port": [0-9]+' | cut -d':' -f2 | tr -d ' ' | sed -n '1p'`
nvram set app_14=$filemanager_wan_port
iptables -t filter -D INPUT -p tcp --dport $filemanager_wan_port -j ACCEPT

filemanager_upanPath="$upanPath"
nvram set filemanager_upanPath="$upanPath"
ln -sf /etc/storage/app_5.sh /tmp/filemanager.json
"$upanPath/filemanager/filemanager" -c "/tmp/filemanager.json" &

sleep 2
[ ! -z "$(ps -w | grep "filemanager" | grep -v grep )" ] && logger -t "【filemanager】" "启动成功" && filemanager_restart o
[ -z "$(ps -w | grep "filemanager" | grep -v grep )" ] && logger -t "【filemanager】" "启动失败, 注意检查端口是否有冲突,程序是否下载完整,10 秒后自动尝试重新启动" && sleep 10 && filemanager_restart x
initopt
filemanager_port_dpt
#filemanager_get_status
eval "$scriptfilepath keep &"
}

initopt () {
optPath=`grep ' /opt ' /proc/mounts | grep tmpfs`
[ ! -z "$optPath" ] && return
if [ ! -z "$(echo $scriptfilepath | grep -v "/opt/etc/init")" ] && [ -s "/opt/etc/init.d/rc.func" ] ; then
	{ echo '#!/bin/sh' ; echo $scriptfilepath '"$@"' '&' ; } > /opt/etc/init.d/$scriptname && chmod 777  /opt/etc/init.d/$scriptname
fi

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
if [ "$1" = "del" ] ; then
	rm -rf /opt/app/filemanager/Advanced_Extensions_filemanager.asp
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

