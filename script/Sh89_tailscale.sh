#!/bin/bash
#copyright by hiboy
source /etc/storage/script/init.sh
tailscale_enable=`nvram get app_82`
if [ "$tailscale_enable" != "0" ] && [ "$tailscale_enable" != "1" ] && [ "$tailscale_enable" != "2" ] && [ "$tailscale_enable" != "3" ] && [ "$tailscale_enable" != "4" ] ; then
	tailscale_enable=""
fi
[ -z $tailscale_enable ] && tailscale_enable=0 && nvram set app_82=0
tailscale_cmd="$(nvram get app_44)"
if [ -z "$(echo $tailscale_cmd | grep tailscale)" ] ; then
	tailscale_cmd=""
fi
[ -z "$tailscale_cmd" ] && tailscale_cmd="tailscale up" && nvram set app_44="$tailscale_cmd"
tailscale_renum=`nvram get tailscale_renum`

if [ ! -z "$(echo $scriptfilepath | grep -v "/tmp/script/" | grep tailscale)" ] && [ ! -s /tmp/script/_app11 ] ; then
	mkdir -p /tmp/script
	{ echo '#!/bin/bash' ; echo $scriptfilepath '"$@"' '&' ; } > /tmp/script/_app11
	chmod 777 /tmp/script/_app11
fi

tailscale_restart () {
i_app_restart "$@" -name="tailscale"
}

tailscale_get_status () {

if [ "$tailscale_enable" = "3" ] ; then
logger -t "【tailscale】" "配置恢复初始化"
iptables -D INPUT -i tailscale0 -j ACCEPT
killall tailscaled tailscale
rm -rf /opt/app/tailscale/lib/*
rm -rf /etc/storage/tailscale/lib/*
tailscale_enable=0 && nvram set app_82=0
fi
if [ "$tailscale_enable" = "1" ] || [ "$tailscale_enable" = "2" ] || [ "$tailscale_enable" = "4" ] ; then
B_restart="1"
fi
B_restart="$B_restart$tailscale_cmd"

i_app_get_status -name="tailscale" -valb="$B_restart"
}

tailscale_check () {

tailscale_get_status
if [ "$tailscale_enable" = "0" ] && [ "$needed_restart" = "1" ] ; then
	[ ! -z "`pidof tailscaled`" ] && logger -t "【tailscale】" "停止 tailscale" && tailscale_close
	{ kill_ps "$scriptname" exit0; exit 0; }
fi
if [ "$tailscale_enable" = "1" ] || [ "$tailscale_enable" = "2" ] || [ "$tailscale_enable" = "4" ] ; then
	if [ "$needed_restart" = "1" ] ; then
		tailscale_close
		tailscale_start
	else
		[ -z "`pidof tailscaled`" ] && tailscale_restart
		if [ "$tailscale_enable" = "2" ] && [ -z "`pidof tailscale`" ] ; then
			SVC_PATH2="$(which tailscale)"
			[ ! -s "$SVC_PATH2" ] && SVC_PATH2="/opt/bin/tailscale"
			su_cmd2="$SVC_PATH2 web --listen `nvram get lan_ipaddr`:8989"
			logger -t "【tailscale】" "运行本机管理界面 $su_cmd2"
			eval "$su_cmd2" &
		fi
		iptables -C INPUT -i tailscale0 -j ACCEPT
		if [ "$?" != 0 ] ; then
			iptables -A INPUT -i tailscale0 -j ACCEPT
		fi
	fi
fi
}

tailscale_keep () {
i_app_keep -name="tailscale" -pidof="tailscaled" &
tailscale_enable=`nvram get app_82`
offweb=1
while [ "$tailscale_enable" = "1" ] || [ "$tailscale_enable" = "2" ] || [ "$tailscale_enable" = "4" ] ; do
iptables -C INPUT -i tailscale0 -j ACCEPT
if [ "$?" != 0 ] ; then
	iptables -A INPUT -i tailscale0 -j ACCEPT
fi
tailscale_backup
sleep 100
if [ "$tailscale_enable" = "2" ] || [ "$tailscale_enable" = "4" ] ; then
if [ "$offweb" -gt "3" ] ; then
offweb=1
[ "$tailscale_enable" = "2" ] && logger -t "【tailscale】" "本机管理界面 (自动关闭)"
[ "$tailscale_enable" = "4" ] && logger -t "【tailscale】" "自定义参数启动 (自动关闭)"
tailscale_enable=1 && nvram set app_82=1
killall tailscale
fi
offweb=`expr $offweb + 1`
fi
tailscale_enable=`nvram get app_82`
done
}

tailscale_close () {
kill_ps "$scriptname keep"
sed -Ei '/【tailscale】|^$/d' /tmp/script/_opt_script_check
iptables -D INPUT -i tailscale0 -j ACCEPT
killall tailscaled tailscale
tailscale_backup
umount /opt/app/tailscale/lib/tailscaled.state
umount /opt/app/tailscale/lib/cmd.log.conf
kill_ps "/tmp/script/_app11"
kill_ps "_tailscale.sh"
kill_ps "$scriptname"
}

tailscale_start () {
check_webui_yes
i_app_get_cmd_file -name="tailscale" -cmd="tailscaled" -cpath="/opt/bin/tailscaled" -down1="$hiboyfile/tailscaled" -down2="$hiboyfile2/tailscaled"
SVC_PATH2="$(which tailscale)"
[ ! -s "$SVC_PATH2" ] && SVC_PATH2="/opt/bin/tailscale"
mkdir -p /etc/storage/tailscale/lib
mkdir -p /opt/app/tailscale/lib
tailscale_backup rebackup
[[ "$($SVC_PATH2 -h 2>&1 | wc -l)" -lt 2 ]] && [ ! -z $SVC_PATH2 ] && rm -rf $SVC_PATH2
[ ! -f "$SVC_PATH2" ] && ln -sf "$SVC_PATH" "$SVC_PATH2" 
tailscale_v=$($SVC_PATH -version | sed -n '1p')
[ "$(nvram get tailscale_v)" != "$tailscale_v" ] && nvram set tailscale_v="$tailscale_v"
if [ ! -s "$SVC_PATH" ] ; then
	logger -t "【tailscale】" "找不到 $SVC_PATH ，需要手动安装 $SVC_PATH"
	logger -t "【tailscale】" "启动失败, 10 秒后自动尝试重新启动" && sleep 10 && tailscale_restart x
fi
cd "$(dirname "$SVC_PATH")"
su_cmd2="$SVC_PATH --state=/opt/app/tailscale/lib/tailscaled.state --socket=/var/run/tailscaled.sock"
logger -t "【tailscaled】" "运行主程序 $su_cmd2"
eval "$su_cmd2" &
sleep 4
i_app_keep -t -name="tailscale" -pidof="tailscaled"
iptables -C INPUT -i tailscale0 -j ACCEPT
if [ "$?" != 0 ] ; then
	iptables -A INPUT -i tailscale0 -j ACCEPT
fi

if [ "$tailscale_enable" = "4" ] ; then
tailscale_cmd
logger -t "【tailscale】" "自定义参数启动 $su_cmd2"
cmd_name="tailscale_cmd"
$tailscale_cmd 2>&1 | awk '{cmd="logger -t '"'"'【'$cmd_name'】'"' ' "'"$0"'"' "';";system(cmd)}' &

sleep 4
fi
if [ "$tailscale_enable" = "2" ] ; then
su_cmd2="$SVC_PATH2 web --listen `nvram get lan_ipaddr`:8989"
logger -t "【tailscale】" "运行本机管理界面 $su_cmd2"
eval "$su_cmd2" &
sleep 4
[ ! -z "`pidof tailscale`" ] && logger -t "【tailscale】" "本机管理界面 启动成功" && tailscale_restart o
[ -z "`pidof tailscale`" ] && logger -t "【tailscale】" "本机管理界面 启动失败, 注意检tailscale是否下载完整,10 秒后自动尝试重新启动" && sleep 10 && tailscale_restart x
logger -t "【tailscale】" "本机管理界面 (5分钟自动关闭)"
fi
tailscale_backup
eval "$scriptfilepath keep &"

exit 0
}


tailscale_backup () {
rebackup=$1
if [ -z "$rebackup" ] ; then
for t_paths in /opt/app/tailscale/lib/*
do
	t_conf="$(basename "$(echo $t_paths | grep -v .txt)")"
	if [ ! -z $t_conf ] ; then
		MD5_backup="$(md5sum /opt/app/tailscale/lib/$t_conf | awk '{print $1;}')"
		MD5_storage="$(md5sum /etc/storage/tailscale/lib/$t_conf | awk '{print $1;}')"
		if [ "$MD5_backup"x != "$MD5_storage"x ] ; then
			cp -f /opt/app/tailscale/lib/$t_conf /etc/storage/tailscale/lib/$t_conf
			logger -t "【tailscale】" "备份配置文件 $t_conf 到路由内部储存"
		fi
	fi
done
else
for t_paths in /etc/storage/tailscale/lib/*
do
	t_conf="$(basename "$(echo $t_paths | grep -v .txt)")"
	if [ ! -z $t_conf ] ; then
		MD5_backup="$(md5sum /opt/app/tailscale/lib/$t_conf | awk '{print $1;}')"
		MD5_storage="$(md5sum /etc/storage/tailscale/lib/$t_conf | awk '{print $1;}')"
		if [ "$MD5_backup"x != "$MD5_storage"x ] ; then
			cp -f /etc/storage/tailscale/lib/$t_conf /opt/app/tailscale/lib/$t_conf
			logger -t "【tailscale】" "从路由内部储存恢复配置文件 $t_conf"
		fi
	fi
done
fi
}

update_app () {
mkdir -p /opt/app/tailscale
if [ "$1" = "update_asp" ] ; then
	rm -rf /opt/app/tailscale/Advanced_Extensions_tailscale.asp
fi
if [ "$1" = "del" ] ; then
	rm -rf /opt/app/tailscale/Advanced_Extensions_tailscale.asp /opt/bin/tailscale /opt/bin/tailscaled /opt/opt_backup/bin/tailscale /opt/opt_backup/bin/tailscaled
fi

initconfig

# 加载程序配置页面
if [ ! -f "/opt/app/tailscale/Advanced_Extensions_tailscale.asp" ] || [ ! -s "/opt/app/tailscale/Advanced_Extensions_tailscale.asp" ] ; then
	wgetcurl.sh /opt/app/tailscale/Advanced_Extensions_tailscale.asp "$hiboyfile/Advanced_Extensions_tailscaleasp" "$hiboyfile2/Advanced_Extensions_tailscaleasp"
fi
umount /www/Advanced_Extensions_app11.asp
mount --bind /opt/app/tailscale/Advanced_Extensions_tailscale.asp /www/Advanced_Extensions_app11.asp
# 更新程序启动脚本

[ "$1" = "del" ] && /etc/storage/www_sh/tailscale del &
}

case $ACTION in
start)
	tailscale_close
	tailscale_check
	;;
check)
	tailscale_check
	;;
stop)
	tailscale_close
	;;
updateapp11)
	tailscale_restart o
	if [ "$tailscale_enable" = "1" ] || [ "$tailscale_enable" = "2" ] || [ "$tailscale_enable" = "4" ] ; then
		nvram set tailscale_status="updatetailscale"
		logger -t "【tailscale】" "重启"
		tailscale_restart
	fi
	[ "$tailscale_enable" = "0" ] && nvram set tailscale_v="" && logger -t "【tailscale】" "更新" && update_app del
	;;
update_app)
	update_app
	;;
update_asp)
	update_app update_asp
	;;
keep)
	#tailscale_check
	tailscale_keep
	;;
*)
	tailscale_check
	;;
esac

