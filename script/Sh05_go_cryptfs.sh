#!/bin/bash
#copyright by hiboy
source /etc/storage/script/init.sh
gocryptfs_enable=`nvram get app_133`
[ -z $gocryptfs_enable ] && gocryptfs_enable=0 && nvram set app_133=0
gocryptfs_key_enable=`nvram get app_134`
[ -z $gocryptfs_key_enable ] && gocryptfs_key_enable=0 && nvram set app_134=0
gocryptfs_pass=`nvram get app_135`
gocryptfs_update_id=`nvram get gocryptfs_update_id`
update_id=$gocryptfs_update_id
if [ "$gocryptfs_key_enable" != "1" ] && [ ! -z "$gocryptfs_pass" ] ; then
	logger -t "【gocryptfs】" "使用手动输入密码，删除本地密码记录！"
	nvram set app_135=""
fi
if [ "$gocryptfs_enable" != "0" ] ; then

gocryptfs_renum=`nvram get gocryptfs_renum`
gocryptfs_renum=${gocryptfs_renum:-"0"}

upPassword=""

cmd_log_enable=`nvram get cmd_log_enable`
cmd_name="gocryptfs"
cmd_log=""
if [ "$cmd_log_enable" = "1" ] || [ "$gocryptfs_renum" -gt "0" ] ; then
	cmd_log="$cmd_log2"
fi

fi

if [ ! -z "$(echo $scriptfilepath | grep -v "/tmp/script/" | grep go_cryptfs)" ] && [ ! -s /tmp/script/_app23 ] ; then
	mkdir -p /tmp/script
	{ echo '#!/bin/bash' ; echo $scriptfilepath '"$@"' '&' ; } > /tmp/script/_app23
	chmod 777 /tmp/script/_app23
fi

gocryptfs_restart () {
i_app_restart "$@" -name="gocryptfs"
}

gocryptfs_get_status () {

B_restart="$gocryptfs_enable$gocryptfs_key_enable$gocryptfs_pass$(cat /etc/storage/app_17.sh /etc/storage/app_32.sh | grep -v '^#' | grep -v '^$')"

i_app_get_status -name="gocryptfs" -valb="$B_restart"
}

gocryptfs_check () {

gocryptfs_get_status
if [ "$gocryptfs_enable" != "1" ] && [ "$needed_restart" = "1" ] ; then
	nvram set gocryptfs_update_id=""
	[ ! -z "`pidof gocryptfs`" ] && logger -t "【gocryptfs】" "停止 gocryptfs" && gocryptfs_close
	{ kill_ps "$scriptname" exit0; exit 0; }
fi
if [ "$gocryptfs_enable" = "1" ] ; then
	if [ "$needed_restart" = "1" ] ; then
		gocryptfs_close
		gocryptfs_start
	else
		[ "$gocryptfs_enable" = "1" ] && [ -z "`pidof gocryptfs`" ] && gocryptfs_restart
	fi
fi
}

gocryptfs_keep () {
i_app_keep -t -name="gocryptfs" -pidof="gocryptfs"
[ "$gocryptfs_key_enable" != "1" ] && gocryptfs_pass=`nvram get app_135` && gocryptfs_get_status
set_app_list_on
i_app_keep -name="gocryptfs" -pidof="gocryptfs" &
}

gocryptfs_close () {
kill_ps "$scriptname keep"
sed -Ei '/【gocryptfs】|^$/d' /tmp/script/_opt_script_check
set_app_list_stop
killall gocryptfs app_32.sh
sleep 3
sync;echo 3 > /proc/sys/vm/drop_caches
kill_ps "/tmp/script/_app23"
kill_ps "_go_cryptfs.sh"
kill_ps "$scriptname"
}

gocryptfs_start () {

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
	logger -t "【gocryptfs】" "未挂载储存设备, 请重新检查配置、目录，10 秒后自动尝试重新启动"
	sleep 10
	gocryptfs_restart x
	exit 0
fi
set_app_list_off
i_app_get_cmd_file -name="gocryptfs" -cmd="gocryptfs" -cpath="/opt/bin/gocryptfs" -down1="$hiboyfile/gocryptfs" -down2="$hiboyfile2/gocryptfs"
if [ ! -s "/opt/bin/fusermount" ] ; then
	logger -t "【gocryptfs】" "找不到 /opt/bin/fusermount ，安装 opt mini 程序"
	/etc/storage/script/Sh01_mountopt.sh opt_mini_wget
fi
if [ ! -s "/opt/bin/fusermount" ] ; then
	logger -t "【gocryptfs】" "找不到 /opt/bin/fusermount，正在尝试[opkg update; opkg install fuse-utils]安装"
	opkg update
	opkg install fuse-utils
	if [ ! -s "/opt/bin/fusermount" ] ; then
		logger -t "【gocryptfs】" "找不到 /opt/bin/fusermount，安装 opt full 程序"
		/etc/storage/script/Sh01_mountopt.sh opt_full_wget
	fi
fi
if [ ! -s "/opt/bin/fusermount" ] ; then
	logger -t "【gocryptfs】" "找不到 /opt/bin/fusermount，需要手动安装 opt 后输入[opkg update; opkg install fuse-utils]安装"
	logger -t "【gocryptfs】" "启动失败, 10 秒后自动尝试重新启动" && sleep 10 && gocryptfs_restart x
fi
get_tg_pass
if [ "$gocryptfs_key_enable" = "1" ] ; then
	logger -t "【gocryptfs】" "使用本地保存密码，有信息泄露的风险！"
fi
if [ "$gocryptfs_key_enable" != "1" ] && [ ! -z "$gocryptfs_pass" ] ; then
	logger -t "【gocryptfs】" "使用手动输入密码，删除本地密码记录！"
	nvram set app_135=""
fi
if [ -z "$gocryptfs_pass" ] ; then
	logger -t "【gocryptfs】" "找不到密码 ，需要手动输入密码"
	logger -t "【gocryptfs】" "启动失败, 30 秒后自动尝试重新启动" && sleep 30 && gocryptfs_restart x
else
	nvram set gocryptfs_update_id=""
fi
logger -t "【gocryptfs】" "运行 /etc/storage/app_32.sh"
eval "/etc/storage/app_32.sh $gocryptfs_pass $cmd_log"
sleep 4
eval "$scriptfilepath keep &"
exit 0

}

initconfig () {

app_17="/etc/storage/app_17.sh"
if [ ! -f "$app_17" ] || [ ! -s "$app_17" ] ; then
	cat > "$app_17" <<-\EEE
# 待 cryfs、gocryptfs 正常启动后开始运行的脚本；可选项：删除前面的#可生效
/etc/storage/script/Sh52_sync_thing.sh
#/etc/storage/script/Sh54_file_manager.sh
/etc/storage/script/Sh55_very_sync.sh
#/etc/storage/script/Sh61_lnmp.sh
EEE
	chmod 755 "$app_17"
fi

app_32="/etc/storage/app_32.sh"
if [ ! -f "$app_32" ] || [ ! -s "$app_32" ] ; then
	cat > "$app_32" <<-\EEE
#!/bin/bash
export PATH='/etc/storage/bin:/tmp/script:/etc/storage/script:/opt/usr/sbin:/opt/usr/bin:/opt/sbin:/opt/bin:/usr/local/sbin:/usr/sbin:/usr/bin:/sbin:/bin'
export LD_LIBRARY_PATH=/lib:/opt/lib
mkdir -p /tmp/AiDisk_00/lockdir_gocryptfs /tmp/AiDisk_00/lockdir_gocryptfsdata
# 加密数据存储在 /tmp/AiDisk_00/lockdir_gocryptfsdata 路径中
# 启动 gocryptfs 后可以使用 /tmp/AiDisk_00/lockdir_gocryptfs 路径防止硬盘盗窃导致的数据泄露
# 注意事项: 启动前需加密使用的文件夹要为空；启动前需手动在ssh终端运行命令初始化配置。
[ "$1" == "all_777" ] && { chmod 777 -R /tmp/AiDisk_00/lockdir_gocryptfsdata ; return ; }
[ "$1" == "all_600" ] && { chmod 600 -R /tmp/AiDisk_00/lockdir_gocryptfsdata ; return ; }
if [ ! -f "/tmp/AiDisk_00/lockdir_gocryptfsdata/gocryptfs.conf" ] ; then
  logger -t "【gocryptfs】" "启动前需手动在ssh终端运行命令初始化配置（若要加密文件名删除 -plaintextnames 参数）"
  logger -t "【gocryptfs】" "gocryptfs -init -scryptn 10 -plaintextnames /tmp/AiDisk_00/lockdir_gocryptfsdata"
  sleep 120
fi
killall gocryptfs ; chmod 777 /opt/bin/fusermount
modprobe fuse
gocryptfs_pass=$1
fusermount -u /tmp/AiDisk_00/lockdir_gocryptfs
echo $gocryptfs_pass | gocryptfs -allow_other -suid -badname '*' /tmp/AiDisk_00/lockdir_gocryptfsdata /tmp/AiDisk_00/lockdir_gocryptfs


EEE

fi

cat /etc/storage/app_17.sh | grep -v '^#' | sort -u | grep -v '^$' | sed s/！/!/g > /tmp/gocryptfs_app_list.txt

}

initconfig

set_app_list_off () {

# 待 gocryptfs 正常启动后开始运行的脚本
while read line
do
logger -t "【gocryptfs】" "停止启动：$line"
[ -f "$line" ] && sed -e 's/^#copyright by hiboy/exit #copyright by hiboy/g' -i $line # 停止启动
done < /tmp/gocryptfs_app_list.txt

}

set_app_list_on () {

# 待 gocryptfs 正常启动后开始运行的脚本
gocryptfs_renum=`nvram get gocryptfs_renum`
while read line
do
logger -t "【gocryptfs】" "恢复启动：$line"
[ -f "$line" ] && sed -e 's/^exit #copyright by hiboy/#copyright by hiboy/g' -i $line # 恢复启动
[ -f "$line" ] && [ "$gocryptfs_renum" -gt "0" ] && { logger -t "【gocryptfs】" "启动脚本：$line" ; eval $line ; }
done < /tmp/gocryptfs_app_list.txt

}

set_app_list_stop () {

# 在 gocryptfs 正常停止前需要停止的脚本
gocryptfs_renum=`nvram get gocryptfs_renum`
while read line
do
logger -t "【gocryptfs】" "停止脚本：$line"
[ -f "$line" ] && eval $line stop
[ -f "$line" ] && [ "$gocryptfs_renum" -gt "0" ] && { logger -t "【gocryptfs】" "停止脚本：$line" ; eval $line ; }
done < /tmp/gocryptfs_app_list.txt

}

get_tg_pass () {

tgbot_sckey=`nvram get app_48`
tgbot_id=`nvram get app_47`
tgbot_api=`nvram get app_87`
if [ "$gocryptfs_key_enable" = "2" ] && [ -z "$gocryptfs_pass" ] && [ ! -z "$tgbot_api" ] && [ ! -z "$tgbot_id" ] && [ ! -z "$tgbot_sckey" ] ; then
	logger -t "【gocryptfs】" "使用 tgbot 获取密码"
	[ -z $tgbot_api ] && tgbot_api="https://api.telegram.org" && nvram set app_87="$tgbot_api"
	# 获取上次输入命令 update_id
	getUpdates="$(curl -L -s $tgbot_api/bot$tgbot_sckey/getUpdates)"
	if [ ! -z "$getUpdates" ] ; then
	LOGTIME=$(date "+%Y-%m-%d %H:%M:%S")
	if [ -z "$gocryptfs_update_id" ] ; then
		update_id="$(echo $getUpdates| sed -e "s/update_id/"' \n '"update_id/g" | grep \"id\":$tgbot_id.*\"text\":\".*\" | grep -Eo update_id\":[0-9]* | grep -Eo [0-9]* | tail -n1)"
		if [ ! -z "$update_id" ] ; then
			update_id=`expr $update_id + 1`
			nvram set gocryptfs_update_id=$update_id
		else
			nvram set gocryptfs_update_id=0
		fi
		# 发送信息
		logger -t "【gocryptfs】" "请在打开 Telegram 在 bot 回复输入密码：仅支持[a-zA-B0-9]范围的字符"
		curl -L -s "$tgbot_api/bot$tgbot_sckey/sendMessage?chat_id=$tgbot_id" --data-binary "&text=$LOGTIME【gocryptfs】输入密码：仅支持[a-zA-B0-9]范围的字符""`echo -e " \n "`""Password:"
	else
		update_id=$gocryptfs_update_id
	fi
	reup=1
	upPassword=""
	while [ -z "$upPassword" ] && [ "$reup" -lt "7" ];
	do
	logger -t "【gocryptfs】" "等待 tgbot 密码返回"
	sleep 30 ; reup=`expr $reup + 1`
	getUpdates="$(curl -L -s $tgbot_api/bot$tgbot_sckey/getUpdates?offset=$update_id)"
	upPassword="$(echo $getUpdates| sed -e "s/message_id/"' \n '"/g" | grep -Eo \"id\":$tgbot_id.*\"text\":\".*\" | grep -Eo \"text\":\"[a-zbA-Z0-9]*\" | cut -d':' -f2 | tr -d '"'| tail -n1)"
	done
	if [ ! -z "$upPassword" ] ; then
		logger -t "【gocryptfs】" "使用 tgbot 获取密码成功！"
		gocryptfs_pass="$upPassword"
		nvram set app_135=$gocryptfs_pass
		# 删除 bot 的密码记录
		getUpdates="$(curl -L -s $tgbot_api/bot$tgbot_sckey/getUpdates)"
		message_id="$(echo $getUpdates| sed -e "s/update_id/"' \n '"update_id/g" | grep \"id\":$tgbot_id.*\"text\":\".*\" | grep $upPassword | grep -Eo \"message_id\":[0-9]* | grep -Eo [0-9]*)" #| tail -n1
		for message_id_i in $message_id
		do
			curl -L -s "$tgbot_api/bot$tgbot_sckey/deleteMessage?chat_id=$tgbot_id" --data-binary "&message_id=$message_id_i"
		done
		# 发送信息
		curl -L -s "$tgbot_api/bot$tgbot_sckey/sendMessage?chat_id=$tgbot_id" --data-binary "&text=【gocryptfs】获取密码成功！"
	else
		logger -t "【gocryptfs】" "使用 tgbot 获取密码失败！"
	fi
		
	fi
fi

}

all_777 () {
logger -t "【gocryptfs】" "/tmp/AiDisk_00/lockdir_gocryptfs/* 文件权限修改为 777（可读可写可执行）"
chmod 777 -R /tmp/AiDisk_00/lockdir_gocryptfsdata
/etc/storage/app_32.sh all_777
}
all_600 () {
logger -t "【gocryptfs】" "/tmp/AiDisk_00/lockdir_gocryptfs/* 文件权限修改为 600（可读可写可执行）"
chmod 600 -R /tmp/AiDisk_00/lockdir_gocryptfsdata
/etc/storage/app_32.sh all_600
}
update_app () {
mkdir -p /opt/app/gocryptfs
if [ "$1" = "update_asp" ] ; then
	rm -rf /opt/app/gocryptfs/Advanced_Extensions_gocryptfs.asp
fi
if [ "$1" = "del" ] ; then
	rm -rf /opt/app/gocryptfs/Advanced_Extensions_gocryptfs.asp
	rm -rf /opt/bin/gocryptfs /opt/opt_backup/bin/gocryptfs
fi

initconfig

# 加载程序配置页面
if [ ! -f "/opt/app/gocryptfs/Advanced_Extensions_gocryptfs.asp" ] || [ ! -s "/opt/app/gocryptfs/Advanced_Extensions_gocryptfs.asp" ] ; then
	wgetcurl.sh /opt/app/gocryptfs/Advanced_Extensions_gocryptfs.asp "$hiboyfile/Advanced_Extensions_gocryptfsasp" "$hiboyfile2/Advanced_Extensions_gocryptfsasp"
fi
umount /www/Advanced_Extensions_app23.asp
mount --bind /opt/app/gocryptfs/Advanced_Extensions_gocryptfs.asp /www/Advanced_Extensions_app23.asp
# 更新程序启动脚本

[ "$1" = "del" ] && /etc/storage/www_sh/gocryptfs del &
}

case $ACTION in
start)
	gocryptfs_close
	gocryptfs_check
	;;
check)
	gocryptfs_check
	;;
stop)
	gocryptfs_close
	;;
updateapp23)
	gocryptfs_restart o
	[ "$gocryptfs_enable" = "1" ] && nvram set gocryptfs_status="updategocryptfs" && nvram set gocryptfs_update_id="" && logger -t "【gocryptfs】" "重启" && gocryptfs_restart
	[ "$gocryptfs_enable" != "1" ] && nvram set gocryptfs_v="" && logger -t "【gocryptfs】" "更新" && update_app del
	;;
update_app)
	update_app
	;;
update_asp)
	update_app update_asp
	;;
all_777)
	all_777
	;;
all_600)
	all_600
	;;
keep)
	#gocryptfs_check
	gocryptfs_keep
	;;
*)
	gocryptfs_check
	;;
esac

