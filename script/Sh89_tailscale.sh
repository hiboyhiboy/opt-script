#!/bin/bash
#copyright by hiboy
source /etc/storage/script/init.sh
tailscale_enable=`nvram get app_82`
if [ "$tailscale_enable" != "0" ] && [ "$tailscale_enable" != "1" ] && [ "$tailscale_enable" != "2" ] && [ "$tailscale_enable" != "3" ] && [ "$tailscale_enable" != "4" ] ; then
	tailscale_enable=""
fi
[ -z $tailscale_enable ] && tailscale_enable=0 && nvram set app_82=0
tailscale_cmd=`nvram get app_44`
if [ -z "$(echo $tailscale_cmd | grep tailscale)" ] ; then
	tailscale_cmd=""
fi
[ -z $tailscale_cmd ] && tailscale_cmd="tailscale up" && nvram set app_44="$tailscale_cmd"
tailscale_renum=`nvram get tailscale_renum`

if [ ! -z "$(echo $scriptfilepath | grep -v "/tmp/script/" | grep tailscale)" ]  && [ ! -s /tmp/script/_app11 ]; then
	mkdir -p /tmp/script
	{ echo '#!/bin/bash' ; echo $scriptfilepath '"$@"' '&' ; } > /tmp/script/_app11
	chmod 777 /tmp/script/_app11
fi

tailscale_restart () {

relock="/var/lock/tailscale_restart.lock"
if [ "$1" = "o" ] ; then
	nvram set tailscale_renum="0"
	[ -f $relock ] && rm -f $relock
	return 0
fi
if [ "$1" = "x" ] ; then
	if [ -f $relock ] ; then
		logger -t "【tailscale】" "多次尝试启动失败，等待【"`cat $relock`"分钟】后自动尝试重新启动"
		exit 0
	fi
	tailscale_renum=${tailscale_renum:-"0"}
	tailscale_renum=`expr $tailscale_renum + 1`
	nvram set tailscale_renum="$tailscale_renum"
	if [ "$tailscale_renum" -gt "3" ] ; then
		I=19
		echo $I > $relock
		logger -t "【tailscale】" "多次尝试启动失败，等待【"`cat $relock`"分钟】后自动尝试重新启动"
		while [ $I -gt 0 ]; do
			I=$(($I - 1))
			echo $I > $relock
			sleep 60
			[ "$(nvram get tailscale_renum)" = "0" ] && exit 0
			[ $I -lt 0 ] && break
		done
		nvram set tailscale_renum="1"
	fi
	[ -f $relock ] && rm -f $relock
fi
nvram set tailscale_status=0
eval "$scriptfilepath &"
exit 0
}

tailscale_get_status () {

if [ "$tailscale_enable" = "3" ] ; then
logger -t "【tailscale】" "配置恢复初始化"
iptables -D INPUT -i tailscale0 -j ACCEPT
killall tailscaled tailscale
killall -9 tailscaled tailscale
rm -rf /opt/app/tailscale/lib/*
rm -rf /etc/storage/tailscale/lib/*
tailscale_enable=0 && nvram set app_82=0
fi
A_restart=`nvram get tailscale_status`
if [ "$tailscale_enable" = "1" ] || [ "$tailscale_enable" = "2" ] || [ "$tailscale_enable" = "4" ] ; then
B_restart="1"
fi
B_restart="$B_restart$tailscale_cmd"
#B_restart=`echo -n "$B_restart" | md5sum | sed s/[[:space:]]//g | sed s/-//g`
cut_B_re
if [ "$A_restart" != "$B_restart" ] ; then
	nvram set tailscale_status=$B_restart
	needed_restart=1
else
	needed_restart=0
fi
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
logger -t "【tailscale】" "守护进程启动"
if [ -s /tmp/script/_opt_script_check ]; then
SVC_PATH="/opt/bin/tailscaled"
sed -Ei '/【tailscale】|^$/d' /tmp/script/_opt_script_check
cat >> "/tmp/script/_opt_script_check" <<-OSC
	[ -z "\`pidof tailscaled\`" ] || [ ! -s "$SVC_PATH" ] && nvram set tailscale_status=00 && logger -t "【tailscale】" "重新启动" && eval "$scriptfilepath &" && sed -Ei '/【tailscale】|^$/d' /tmp/script/_opt_script_check # 【tailscale】
OSC
#return
fi
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
killall -9 tailscaled tailscale
tailscale_backup
umount /opt/app/tailscale/lib/tailscaled.state
umount /opt/app/tailscale/lib/cmd.log.conf
kill_ps "/tmp/script/_app11"
kill_ps "_tailscale.sh"
kill_ps "$scriptname"
}

tailscale_start () {
check_webui_yes
SVC_PATH="$(which tailscaled)"
[ ! -s "$SVC_PATH" ] && SVC_PATH="/opt/bin/tailscaled"
SVC_PATH2="$(which tailscale)"
[ ! -s "$SVC_PATH2" ] && SVC_PATH2="/opt/bin/tailscale"
if [ ! -s "$SVC_PATH" ] ; then
	logger -t "【tailscale】" "找不到 $SVC_PATH，安装 opt 程序"
	/etc/storage/script/Sh01_mountopt.sh start
	initopt
fi
mkdir -p /etc/storage/tailscale/lib
mkdir -p /opt/app/tailscale/lib
tailscale_backup rebackup
for h_i in $(seq 1 2) ; do
[[ "$($SVC_PATH -h 2>&1 | wc -l)" -lt 2 ]] && [ ! -z $SVC_PATH ] && rm -rf $SVC_PATH
wgetcurl_file "$SVC_PATH" "$hiboyfile/tailscaled" "$hiboyfile2/tailscaled"
[[ "$($SVC_PATH2 -h 2>&1 | wc -l)" -lt 2 ]] && [ ! -z $SVC_PATH2 ] && rm -rf $SVC_PATH2
[ ! -f "$SVC_PATH2" ] && ln -sf "$SVC_PATH" "$SVC_PATH2" 
done
tailscale_v=$($SVC_PATH -version | sed -n '1p')
nvram set tailscale_v="$tailscale_v"
if [ ! -s "$SVC_PATH" ] ; then
	logger -t "【tailscale】" "找不到 $SVC_PATH ，需要手动安装 $SVC_PATH"
	logger -t "【tailscale】" "启动失败, 10 秒后自动尝试重新启动" && sleep 10 && tailscale_restart x
fi
cd "$(dirname "$SVC_PATH")"
su_cmd2="$SVC_PATH --state=/opt/app/tailscale/lib/tailscaled.state --socket=/var/run/tailscaled.sock"
logger -t "【tailscaled】" "运行主程序 $su_cmd2"
eval "$su_cmd2" &
sleep 4
[ ! -z "`pidof tailscaled`" ] && logger -t "【tailscaled】" "主程序启动成功" && tailscale_restart o
[ -z "`pidof tailscaled`" ] && logger -t "【tailscaled】" "主程序启动失败, 注意检tailscale是否下载完整,10 秒后自动尝试重新启动" && sleep 10 && tailscale_restart x
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

initopt () {
optPath=`grep ' /opt ' /proc/mounts | grep tmpfs`
[ ! -z "$optPath" ] && return
if [ ! -z "$(echo $scriptfilepath | grep -v "/opt/etc/init")" ] && [ -s "/opt/etc/init.d/rc.func" ] ; then
	{ echo '#!/bin/bash' ; echo $scriptfilepath '"$@"' '&' ; } > /opt/etc/init.d/$scriptname && chmod 777  /opt/etc/init.d/$scriptname
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

