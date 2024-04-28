#!/bin/bash
#copyright by hiboy
source /etc/storage/script/init.sh
cryfs_enable=`nvram get app_61`
[ -z $cryfs_enable ] && cryfs_enable=0 && nvram set app_61=0
cryfs_key_enable=`nvram get app_62`
[ -z $cryfs_key_enable ] && cryfs_key_enable=0 && nvram set app_62=0
cryfs_pass=`nvram get app_63`
cryfs_update_id=`nvram get cryfs_update_id`
update_id=$cryfs_update_id
if [ "$cryfs_key_enable" != "1" ] && [ ! -z "$cryfs_pass" ] ; then
	logger -t "【cryfs】" "使用手动输入密码，删除本地密码记录！"
	nvram set app_63=""
fi
if [ "$cryfs_enable" != "0" ] ; then

cryfs_renum=`nvram get cryfs_renum`
cryfs_renum=${cryfs_renum:-"0"}

upPassword=""

cmd_log_enable=`nvram get cmd_log_enable`
cmd_name="cryfs"
cmd_log=""
if [ "$cmd_log_enable" = "1" ] || [ "$cryfs_renum" -gt "0" ] ; then
	cmd_log="$cmd_log2"
fi

fi

if [ ! -z "$(echo $scriptfilepath | grep -v "/tmp/script/" | grep cry_fs)" ] && [ ! -s /tmp/script/_app15 ] ; then
	mkdir -p /tmp/script
	{ echo '#!/bin/bash' ; echo $scriptfilepath '"$@"' '&' ; } > /tmp/script/_app15
	chmod 777 /tmp/script/_app15
fi

cryfs_restart () {
i_app_restart "$@" -name="cryfs"
}

cryfs_get_status () {

B_restart="$cryfs_enable$cryfs_key_enable$cryfs_pass$(cat /etc/storage/app_17.sh /etc/storage/app_18.sh | grep -v '^#' | grep -v '^$')"

i_app_get_status -name="cryfs" -valb="$B_restart"
}

cryfs_check () {

cryfs_get_status
if [ "$cryfs_enable" != "1" ] && [ "$needed_restart" = "1" ] ; then
	nvram set cryfs_update_id=""
	[ ! -z "`pidof cryfs`" ] && logger -t "【cryfs】" "停止 cryfs" && cryfs_close
	{ kill_ps "$scriptname" exit0; exit 0; }
fi
if [ "$cryfs_enable" = "1" ] ; then
	if [ "$needed_restart" = "1" ] ; then
		cryfs_close
		cryfs_start
	else
		[ "$cryfs_enable" = "1" ] && [ -z "`pidof cryfs`" ] && cryfs_restart
	fi
fi
}

cryfs_keep () {
i_app_keep -name="cryfs" -pidof="cryfs" &
}

cryfs_close () {
kill_ps "$scriptname keep"
sed -Ei '/【cryfs】|^$/d' /tmp/script/_opt_script_check
set_app_list_stop
killall cryfs app_18.sh
sync;echo 3 > /proc/sys/vm/drop_caches
kill_ps "/tmp/script/_app15"
kill_ps "_cry_fs.sh"
kill_ps "$scriptname"
}

cryfs_start () {

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
	logger -t "【cryfs】" "未挂载储存设备, 请重新检查配置、目录，10 秒后自动尝试重新启动"
	sleep 10
	cryfs_restart x
	exit 0
fi
set_app_list_off
SVC_PATH=/opt/bin/cryfs
chmod 777 "$SVC_PATH"
if [ ! -s "$SVC_PATH" ] ; then
	logger -t "【cryfs】" "找不到 $SVC_PATH，安装 opt mini 程序"
	/etc/storage/script/Sh01_mountopt.sh opt_mini_wget
	initopt
fi
if [ ! -s "$SVC_PATH" ] ; then
	logger -t "【cryfs】" "找不到 $SVC_PATH，正在尝试[opkg update; opkg install cryfs]安装"
	opkg update
	opkg install cryfs
	if [ ! -s "$SVC_PATH" ] ; then
		logger -t "【cryfs】" "找不到 $SVC_PATH，安装 opt full 程序"
		/etc/storage/script/Sh01_mountopt.sh opt_full_wget
	fi
	if [ ! -s "$SVC_PATH" ] ; then
		logger -t "【cryfs】" "找不到 $SVC_PATH，需要手动安装 opt 后输入[opkg update; opkg install cryfs]安装"
		logger -t "【cryfs】" "启动失败, 30 秒后自动尝试重新启动" && sleep 30 && cryfs_restart x
	else
		logger -t "【cryfs】" "找到 $SVC_PATH"
		logger -t "【cryfs】" "由于 opt 文件有更新，需进行 libmd5_备份（耗时15分钟）"
		/tmp/script/_mountop libmd5_backup
	fi
else
	logger -t "【cryfs】" "找到 $SVC_PATH"
	chmod 755 $SVC_PATH
fi
get_tg_pass
if [ "$cryfs_key_enable" = "1" ] ; then
	logger -t "【cryfs】" "使用本地保存密码，有信息泄露的风险！"
fi
if [ "$cryfs_key_enable" != "1" ] && [ ! -z "$cryfs_pass" ] ; then
	logger -t "【cryfs】" "使用手动输入密码，删除本地密码记录！"
	nvram set app_63=""
fi
if [ -z "$cryfs_pass" ] ; then
	logger -t "【cryfs】" "找不到密码 ，需要手动输入密码"
	logger -t "【cryfs】" "启动失败, 30 秒后自动尝试重新启动" && sleep 30 && cryfs_restart x
else
	nvram set cryfs_update_id=""
fi
logger -t "【cryfs】" "运行 /etc/storage/app_18.sh"
eval "/etc/storage/app_18.sh $cryfs_pass $cmd_log"
sleep 4
i_app_keep -t -name="cryfs" -pidof="cryfs"
set_app_list_on
[ "$cryfs_key_enable" != "1" ] && cryfs_pass=`nvram get app_63` && cryfs_get_status
eval "$scriptfilepath keep &"
exit 0

}

initconfig () {

app_17="/etc/storage/app_17.sh"
if [ ! -f "$app_17" ] || [ ! -s "$app_17" ] ; then
	cat > "$app_17" <<-\EEE
# 待 cryfs 正常启动后开始运行的脚本；可选项：删除前面的#可生效
/etc/storage/script/Sh52_sync_thing.sh
#/etc/storage/script/Sh54_file_manager.sh
/etc/storage/script/Sh55_very_sync.sh
#/etc/storage/script/Sh61_lnmp.sh
EEE
	chmod 755 "$app_17"
fi

app_18="/etc/storage/app_18.sh"
if [ ! -f "$app_18" ] || [ ! -s "$app_18" ] ; then
	cat > "$app_18" <<-\EEE
#!/bin/bash
export PATH='/etc/storage/bin:/tmp/script:/etc/storage/script:/opt/usr/sbin:/opt/usr/bin:/opt/sbin:/opt/bin:/usr/local/sbin:/usr/sbin:/usr/bin:/sbin:/bin'
export LD_LIBRARY_PATH=/lib:/opt/lib
# 加密数据存储在 /tmp/AiDisk_00/lockdir_cryfsdata 路径中
# 启动 cryfs 后可以使用 /tmp/AiDisk_00/lockdir 路径防止硬盘盗窃导致的数据泄露
# 注意事项: 启动前需加密使用的文件夹要为空；启动前需手动在ssh终端运行命令初始化配置。
if [ ! -f "/tmp/AiDisk_00/lockdir_cryfsdata/cryfs.config" ] ; then
    logger -t "【cryfs】" "启动前需手动在ssh终端运行命令初始化配置 cryfs /tmp/AiDisk_00/lockdir_cryfsdata /tmp/AiDisk_00/lockdir" ; sleep 120 ;
fi
killall cryfs
modprobe fuse
CRYFS_NO_UPDATE_CHECK=true
CRYFS_LOCAL_STATE_DIR=/opt/bin/cryfs
CRYFS_FRONTEND=noninteractive
cryfs_pass=$1
fusermount -u /tmp/AiDisk_00/lockdir
echo $cryfs_pass | cryfs /tmp/AiDisk_00/lockdir_cryfsdata /tmp/AiDisk_00/lockdir


EEE

fi

cat /etc/storage/app_17.sh | grep -v '^#' | sort -u | grep -v '^$' | sed s/！/!/g > /tmp/cryfs_app_list.txt

}

initconfig

set_app_list_off () {

# 待 cryfs 正常启动后开始运行的脚本
while read line
do
logger -t "【cryfs】" "停止启动：$line"
[ -f "$line" ] && sed -e 's/^#copyright by hiboy/exit #copyright by hiboy/g' -i $line # 停止启动
done < /tmp/cryfs_app_list.txt

}

set_app_list_on () {

# 待 cryfs 正常启动后开始运行的脚本
cryfs_renum=`nvram get cryfs_renum`
while read line
do
logger -t "【cryfs】" "恢复启动：$line"
[ -f "$line" ] && sed -e 's/^exit #copyright by hiboy/#copyright by hiboy/g' -i $line # 恢复启动
[ -f "$line" ] && [ "$cryfs_renum" -gt "0" ] && { logger -t "【cryfs】" "启动脚本：$line" ; eval $line ; }
done < /tmp/cryfs_app_list.txt

}

set_app_list_stop () {

# 在 cryfs 正常停止前需要停止的脚本
cryfs_renum=`nvram get cryfs_renum`
while read line
do
logger -t "【cryfs】" "停止脚本：$line"
[ -f "$line" ] && eval $line stop
[ -f "$line" ] && [ "$cryfs_renum" -gt "0" ] && { logger -t "【cryfs】" "停止脚本：$line" ; eval $line ; }
done < /tmp/cryfs_app_list.txt

}

get_tg_pass () {

if [ "$cryfs_key_enable" = "2" ] && [ -z "$cryfs_pass" ] ; then
	logger -t "【cryfs】" "使用 tgbot 获取密码"
	tgbot_sckey=`nvram get app_48`
	tgbot_id=`nvram get app_47`
	tgbot_api=`nvram get app_87`
	[ -z $tgbot_api ] && tgbot_api="https://api.telegram.org" && nvram set app_87="$tgbot_api"
	# 获取上次输入命令 update_id
	getUpdates="$(curl -L -s $tgbot_api/bot$tgbot_sckey/getUpdates)"
	if [ ! -z "$getUpdates" ] ; then
	LOGTIME=$(date "+%Y-%m-%d %H:%M:%S")
	if [ -z "$cryfs_update_id" ] ; then
		update_id="$(echo $getUpdates| sed -e "s/update_id/"' \n '"update_id/g" | grep \"id\":$tgbot_id.*\"text\":\".*\" | grep -Eo update_id\":[0-9]* | grep -Eo [0-9]* | tail -n1)"
		if [ ! -z "$update_id" ] ; then
			update_id=`expr $update_id + 1`
			nvram set cryfs_update_id=$update_id
		else
			nvram set cryfs_update_id=0
		fi
		# 发送信息
		logger -t "【cryfs】" "请在打开 Telegram 在 bot 回复输入密码：仅支持[a-zA-B0-9]范围的字符"
		curl -L -s "$tgbot_api/bot$tgbot_sckey/sendMessage?chat_id=$tgbot_id" --data-binary "&text=$LOGTIME【cryfs】输入密码：仅支持[a-zA-B0-9]范围的字符""`echo -e " \n "`""Password:"
	else
		update_id=$cryfs_update_id
	fi
	reup=1
	upPassword=""
	while [ -z "$upPassword" ] && [ "$reup" -lt "7" ];
	do
	logger -t "【cryfs】" "等待 tgbot 密码返回"
	sleep 30 ; reup=`expr $reup + 1`
	getUpdates="$(curl -L -s $tgbot_api/bot$tgbot_sckey/getUpdates?offset=$update_id)"
	upPassword="$(echo $getUpdates| sed -e "s/message_id/"' \n '"/g" | grep -Eo \"id\":$tgbot_id.*\"text\":\".*\" | grep -Eo \"text\":\"[a-zbA-Z0-9]*\" | cut -d':' -f2 | tr -d '"'| tail -n1)"
	done
	if [ ! -z "$upPassword" ] ; then
		logger -t "【cryfs】" "使用 tgbot 获取密码成功！"
		cryfs_pass="$upPassword"
		nvram set app_63=$cryfs_pass
		# 删除 bot 的密码记录
		getUpdates="$(curl -L -s $tgbot_api/bot$tgbot_sckey/getUpdates)"
		message_id="$(echo $getUpdates| sed -e "s/update_id/"' \n '"update_id/g" | grep \"id\":$tgbot_id.*\"text\":\".*\" | grep $upPassword | grep -Eo \"message_id\":[0-9]* | grep -Eo [0-9]*)" #| tail -n1
		for message_id_i in $message_id
		do
			curl -L -s "$tgbot_api/bot$tgbot_sckey/deleteMessage?chat_id=$tgbot_id" --data-binary "&message_id=$message_id_i"
		done
		# 发送信息
		curl -L -s "$tgbot_api/bot$tgbot_sckey/sendMessage?chat_id=$tgbot_id" --data-binary "&text=【cryfs】获取密码成功！"
	else
		logger -t "【cryfs】" "使用 tgbot 获取密码失败！"
	fi
		
	fi
fi

}

update_app () {
mkdir -p /opt/app/cryfs
if [ "$1" = "update_asp" ] ; then
	rm -rf /opt/app/cryfs/Advanced_Extensions_cryfs.asp
fi
if [ "$1" = "del" ] ; then
	rm -rf /opt/app/cryfs/Advanced_Extensions_cryfs.asp
	opkg update
	opkg install cryfs
	logger -t "【cryfs】" "由于 opt 文件有更新，需进行 libmd5_备份（耗时15分钟）"
	/tmp/script/_mountop libmd5_backup
fi

initconfig

# 加载程序配置页面
if [ ! -f "/opt/app/cryfs/Advanced_Extensions_cryfs.asp" ] || [ ! -s "/opt/app/cryfs/Advanced_Extensions_cryfs.asp" ] ; then
	wgetcurl.sh /opt/app/cryfs/Advanced_Extensions_cryfs.asp "$hiboyfile/Advanced_Extensions_cryfsasp" "$hiboyfile2/Advanced_Extensions_cryfsasp"
fi
umount /www/Advanced_Extensions_app15.asp
mount --bind /opt/app/cryfs/Advanced_Extensions_cryfs.asp /www/Advanced_Extensions_app15.asp
# 更新程序启动脚本

[ "$1" = "del" ] && /etc/storage/www_sh/cryfs del &
}

case $ACTION in
start)
	cryfs_close
	cryfs_check
	;;
check)
	cryfs_check
	;;
stop)
	cryfs_close
	;;
updateapp15)
	cryfs_restart o
	[ "$cryfs_enable" = "1" ] && nvram set cryfs_status="updatecryfs" && nvram set cryfs_update_id="" && logger -t "【cryfs】" "重启" && cryfs_restart
	[ "$cryfs_enable" != "1" ] && nvram set cryfs_v="" && logger -t "【cryfs】" "更新" && update_app del
	;;
update_app)
	update_app
	;;
update_asp)
	update_app update_asp
	;;
keep)
	#cryfs_check
	cryfs_keep
	;;
*)
	cryfs_check
	;;
esac

