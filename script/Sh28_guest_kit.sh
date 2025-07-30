#!/bin/bash
#copyright by hiboy
source /etc/storage/script/init.sh
guestkit_enable=`nvram get app_26`
[ -z $guestkit_enable ] && guestkit_enable=0 && nvram set app_26=0

guestkit_renum=`nvram get guestkit_renum`
guestkit_renum=${guestkit_renum:-"0"}
cmd_log_enable=`nvram get cmd_log_enable`
cmd_name="guestkit"
cmd_log=""
if [ "$cmd_log_enable" = "1" ] || [ "$guestkit_renum" -gt "0" ] ; then
	cmd_log="$cmd_log2"
fi
if [ ! -z "$(echo $scriptfilepath | grep -v "/tmp/script/" | grep guest_kit)" ] && [ ! -s /tmp/script/_app9 ] ; then
	mkdir -p /tmp/script
	{ echo '#!/bin/bash' ; echo $scriptfilepath '"$@"' '&' ; } > /tmp/script/_app9
	chmod 777 /tmp/script/_app9
fi

guestkit_restart () {
i_app_restart "$@" -name="guestkit"
}

guestkit_get_status () {

B_restart="$guestkit_enable$(cat /etc/storage/app_28.sh | grep -v '^#' | grep -v '^$')"

i_app_get_status -name="guestkit" -valb="$B_restart"
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
i_app_keep -name="guestkit" -pidof="guestkit" &
}

guestkit_close () {

kill_ps "$scriptname keep"
sed -Ei '/【guestkit】|^$/d' /tmp/script/_opt_script_check
iptables -t filter -D INPUT -p tcp --dport 7575 -j ACCEPT
killall guestkit
kill_ps "/tmp/script/_app9"
kill_ps "_guest_kit.sh"
kill_ps "$scriptname"
}

guestkit_start () {

check_webui_yes
i_app_get_cmd_file -name="guestkit" -cmd="guestkit" -cpath="/opt/bin/guestkit" -down1="$hiboyfile/guestkit" -down2="$hiboyfile2/guestkit"
guestkit_v=$(guestkit -h | grep guestkit | sed -n '1p')
nvram set guestkit_v="$guestkit_v"
logger -t "【guestkit】" "运行 guestkit"

#运行/opt/bin/guestkit
cd $(dirname `which guestkit`)
eval "guestkit $cmd_log" &
sleep 7
i_app_keep -t -name="guestkit" -pidof="guestkit"
#guestkit_get_status
eval "$scriptfilepath keep &"
exit 0
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
if [ "$POST_DATA" = "1" ] ; then
  radio2_guest_enable
  radio5_guest_enable
  REPLY_DATA="打开网络"
fi

if [ "$POST_DATA" = "2" ] ; then
  radio2_guest_disable
  radio5_guest_disable
  REPLY_DATA="停用网络"
fi

if [ "$POST_DATA" = "3" ] ; then
  # 下面的00:00:00:00:00:00改为电脑网卡地址即可唤醒
  ether-wake -b -i br0 00:00:00:00:00:00
  REPLY_DATA="打开电脑"
fi

if [ "$POST_DATA" = "4" ] ; then
  nvram set ss_status=0
  nvram set ss_enable=1
  nvram commit
  /tmp/script/Sh15_ss.sh &
  REPLY_DATA="打开代理"
fi

if [ "$POST_DATA" = "5" ] ; then
  nvram set ss_status=1
  nvram set ss_enable=0
  nvram commit
  /tmp/script/Sh15_ss.sh &
  REPLY_DATA="关闭代理"
fi

if [ "$POST_DATA" = "6" ] ; then
  nvram commit
  /sbin/mtd_storage.sh save
  sync;echo 3 > /proc/sys/vm/drop_caches
  /bin/mtd_write -r unlock mtd1 #reboot
  REPLY_DATA="重启路由"
fi

if [ "$POST_DATA" = "7" ] ; then
  nvram set app_117=1
  nvram commit
  /etc/storage/script/Sh63_t_mall.sh &
  REPLY_DATA="打开路由"
fi

if [ "$POST_DATA" = "8" ] ; then
  nvram set app_117=0
  nvram commit
  /etc/storage/script/Sh63_t_mall.sh &
  REPLY_DATA="关闭路由"
fi

if [ "$POST_DATA" = "9" ] ; then
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

