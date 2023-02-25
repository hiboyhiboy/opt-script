#!/bin/bash
#copyright by hiboy
source /etc/storage/script/init.sh
guestkit_enable=`nvram get app_26`
[ -z $guestkit_enable ] && guestkit_enable=0 && nvram set app_26=0
#if [ "$guestkit_enable" != "0" ] ; then
#nvramshow=`nvram showall | grep '=' | grep guestkit | awk '{print gensub(/'"'"'/,"'"'"'\"'"'"'\"'"'"'","g",$0);}'| awk '{print gensub(/=/,"='\''",1,$0)"'\'';";}'` && eval $nvramshow
#fi

guestkit_renum=`nvram get guestkit_renum`
guestkit_renum=${guestkit_renum:-"0"}
cmd_log_enable=`nvram get cmd_log_enable`
cmd_name="guestkit"
cmd_log=""
if [ "$cmd_log_enable" = "1" ] || [ "$guestkit_renum" -gt "0" ] ; then
	cmd_log="$cmd_log2"
fi
if [ ! -z "$(echo $scriptfilepath | grep -v "/tmp/script/" | grep guest_kit)" ]  && [ ! -s /tmp/script/_app9 ]; then
	mkdir -p /tmp/script
	{ echo '#!/bin/bash' ; echo $scriptfilepath '"$@"' '&' ; } > /tmp/script/_app9
	chmod 777 /tmp/script/_app9
fi

guestkit_restart () {

relock="/var/lock/guestkit_restart.lock"
if [ "$1" = "o" ] ; then
	nvram set guestkit_renum="0"
	[ -f $relock ] && rm -f $relock
	return 0
fi
if [ "$1" = "x" ] ; then
	if [ -f $relock ] ; then
		logger -t "【guestkit】" "多次尝试启动失败，等待【"`cat $relock`"分钟】后自动尝试重新启动"
		exit 0
	fi
	guestkit_renum=${guestkit_renum:-"0"}
	guestkit_renum=`expr $guestkit_renum + 1`
	nvram set guestkit_renum="$guestkit_renum"
	if [ "$guestkit_renum" -gt "3" ] ; then
		I=19
		echo $I > $relock
		logger -t "【guestkit】" "多次尝试启动失败，等待【"`cat $relock`"分钟】后自动尝试重新启动"
		while [ $I -gt 0 ]; do
			I=$(($I - 1))
			echo $I > $relock
			sleep 60
			[ "$(nvram get guestkit_renum)" = "0" ] && exit 0
			[ $I -lt 0 ] && break
		done
		nvram set guestkit_renum="1"
	fi
	[ -f $relock ] && rm -f $relock
fi
nvram set guestkit_status=0
eval "$scriptfilepath &"
exit 0
}

guestkit_get_status () {

A_restart=`nvram get guestkit_status`
B_restart="$guestkit_enable$(cat /etc/storage/app_28.sh | grep -v '^#' | grep -v "^$")"
B_restart=`echo -n "$B_restart" | md5sum | sed s/[[:space:]]//g | sed s/-//g`
cut_B_re
if [ "$A_restart" != "$B_restart" ] ; then
	nvram set guestkit_status=$B_restart
	needed_restart=1
else
	needed_restart=0
fi
}

guestkit_check () {

guestkit_get_status
if [ "$guestkit_enable" != "1" ] && [ "$needed_restart" = "1" ] ; then
	[ ! -z "`pidof guestkit`" ] && logger -t "【guestkit】" "停止 guestkit" && guestkit_close
	{ kill_ps "$scriptname" exit0; exit 0; }
fi
if [ "$guestkit_enable" = "1" ] ; then
	if [ "$needed_restart" = "1" ] ; then
		guestkit_close
		guestkit_start
	else
		[ -z "`pidof guestkit`" ] && guestkit_restart
		guestkit_port_dpt
	fi
fi
}

guestkit_keep () {
logger -t "【guestkit】" "守护进程启动"
if [ -s /tmp/script/_opt_script_check ]; then
sed -Ei '/【guestkit】|^$/d' /tmp/script/_opt_script_check
cat >> "/tmp/script/_opt_script_check" <<-OSC
[ -z "\`pidof guestkit\`" ] && nvram set guestkit_status=00 && logger -t "【guestkit】" "重新启动" && eval "$scriptfilepath &" && sed -Ei '/【guestkit】|^$/d' /tmp/script/_opt_script_check # 【guestkit】
OSC
return
fi

while true; do
	if [ -z "`pidof guestkit`" ] ; then
		logger -t "【guestkit】" "重新启动"
		guestkit_restart
	fi
sleep 252
done
}

guestkit_close () {

kill_ps "$scriptname keep"
sed -Ei '/【guestkit】|^$/d' /tmp/script/_opt_script_check
iptables -t filter -D INPUT -p tcp --dport 7575 -j ACCEPT
killall guestkit
killall -9 guestkit
kill_ps "/tmp/script/_app9"
kill_ps "_guest_kit.sh"
kill_ps "$scriptname"
}

guestkit_start () {

check_webui_yes
SVC_PATH="$(which guestkit)"
[ ! -s "$SVC_PATH" ] && SVC_PATH="/opt/bin/guestkit"
if [ ! -s "$SVC_PATH" ] ; then
	logger -t "【guestkit】" "找不到 $SVC_PATH，安装 opt 程序"
	/etc/storage/script/Sh01_mountopt.sh start
fi
for h_i in $(seq 1 2) ; do
[[ "$(guestkit -h 2>&1 | wc -l)" -lt 2 ]] && rm -rf /opt/bin/guestkit
wgetcurl_file "$SVC_PATH" "$hiboyfile/guestkit" "$hiboyfile2/guestkit"
done
if [ ! -s "$SVC_PATH" ] ; then
	logger -t "【guestkit】" "找不到 $SVC_PATH ，需要手动安装 $SVC_PATH"
	logger -t "【guestkit】" "启动失败, 10 秒后自动尝试重新启动" && sleep 10 && guestkit_restart x
fi
chmod 777 "$SVC_PATH"
guestkit_v=$(guestkit -h | grep guestkit | sed -n '1p')
nvram set guestkit_v="$guestkit_v"
logger -t "【guestkit】" "运行 guestkit"

#运行/opt/bin/guestkit
cd $(dirname `which guestkit`)
killall -9 guestkit
eval "guestkit $cmd_log" &
sleep 7
[ ! -z "$(ps -w | grep "guestkit" | grep -v grep )" ] && logger -t "【guestkit】" "启动成功" && guestkit_restart o
[ -z "$(ps -w | grep "guestkit" | grep -v grep )" ] && logger -t "【guestkit】" "启动失败, 注意检查32121端口是否有冲突,程序是否下载完整,10 秒后自动尝试重新启动" && sleep 10 && guestkit_restart x
initopt
#guestkit_get_status
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

app_28="/etc/storage/app_28.sh"
if [ ! -f "$app_28" ] || [ ! -s "$app_28" ] ; then
	cat > "$app_28" <<-\EEE
#!/bin/bash
# 此脚本路径：/etc/storage/app_28.sh
POST_DATA=`nvram get app_28_post`
# 更多自定义命令请自行参考添加修改
# "1" 数字是亮度值，当设定值匹配时运行代码，1-100可用
if [ "$POST_DATA" = "1" ]; then
  radio2_guest_enable
  radio5_guest_enable
  REPLY_DATA="打开网络"
fi

if [ "$POST_DATA" = "2" ]; then
  radio2_guest_disable
  radio5_guest_disable
  REPLY_DATA="停用网络"
fi

if [ "$POST_DATA" = "3" ]; then
  # 下面的00:00:00:00:00:00改为电脑网卡地址即可唤醒
  ether-wake -b -i br0 00:00:00:00:00:00
  REPLY_DATA="打开电脑"
fi

if [ "$POST_DATA" = "4" ]; then
  nvram set ss_status=0
  nvram set ss_enable=1
  nvram commit
  /tmp/script/Sh15_ss.sh &
  REPLY_DATA="打开代理"
fi

if [ "$POST_DATA" = "5" ]; then
  nvram set ss_status=1
  nvram set ss_enable=0
  nvram commit
  /tmp/script/Sh15_ss.sh &
  REPLY_DATA="关闭代理"
fi

if [ "$POST_DATA" = "6" ]; then
  nvram commit
  /sbin/mtd_storage.sh save
  sync;echo 3 > /proc/sys/vm/drop_caches
  /bin/mtd_write -r unlock mtd1 #reboot
  REPLY_DATA="重启路由"
fi

if [ "$POST_DATA" = "7" ]; then
  nvram set app_117=1
  nvram commit
  /etc/storage/script/Sh63_t_mall.sh &
  REPLY_DATA="打开路由"
fi

if [ "$POST_DATA" = "8" ]; then
  nvram set app_117=0
  nvram commit
  /etc/storage/script/Sh63_t_mall.sh &
  REPLY_DATA="关闭路由"
fi

if [ "$POST_DATA" = "9" ]; then
  /sbin/mtd_storage.sh reset
  nvram set restore_defaults=1
  nvram commit
  /sbin/mtd_storage.sh save
  sync;echo 3 > /proc/sys/vm/drop_caches
  /bin/mtd_write -r unlock mtd1 #reboot
  REPLY_DATA="重置路由"
fi

logger -t "【guestkit】" "运行 $POST_DATA $REPLY_DATA"

EEE
	chmod 755 "$app_28"
fi

}

initconfig

update_app () {
mkdir -p /opt/app/guestkit
if [ "$1" = "update_asp" ] ; then
	rm -rf /opt/app/guestkit/Advanced_Extensions_guestkit.asp
fi
if [ "$1" = "del" ] ; then
	rm -rf /opt/app/guestkit/Advanced_Extensions_guestkit.asp
	[ -f /opt/bin/guestkit ] && rm -f /opt/bin/guestkit /opt/opt_backup/bin/guestkit
	rm -f /etc/storage/guestkit_db/*
fi

initconfig

# 加载程序配置页面
if [ ! -f "/opt/app/guestkit/Advanced_Extensions_guestkit.asp" ] || [ ! -s "/opt/app/guestkit/Advanced_Extensions_guestkit.asp" ] ; then
	wgetcurl.sh /opt/app/guestkit/Advanced_Extensions_guestkit.asp "$hiboyfile/Advanced_Extensions_guestkitasp" "$hiboyfile2/Advanced_Extensions_guestkitasp"
fi
umount /www/Advanced_Extensions_app09.asp
mount --bind /opt/app/guestkit/Advanced_Extensions_guestkit.asp /www/Advanced_Extensions_app09.asp
# 更新程序启动脚本

[ "$1" = "del" ] && /etc/storage/www_sh/guestkit del &
}

case $ACTION in
start)
	guestkit_close
	guestkit_check
	;;
check)
	guestkit_check
	;;
stop)
	guestkit_close
	;;
updateapp9)
	guestkit_restart o
	[ "$guestkit_enable" = "1" ] && nvram set guestkit_status="updateguestkit" && logger -t "【guestkit】" "重启" && guestkit_restart
	[ "$guestkit_enable" != "1" ] && nvram set guestkit_v="" && logger -t "【guestkit】" "更新" && update_app del
	;;
update_app)
	update_app
	;;
update_asp)
	update_app update_asp
	;;
keep)
	#guestkit_check
	guestkit_keep
	;;
initconfig)
	initconfig
	;;
*)
	guestkit_check
	;;
esac

