#!/bin/sh
#copyright by hiboy
source /etc/storage/script/init.sh
caddy_enable=`nvram get app_139`
[ -z $caddy_enable ] && caddy_enable=0 && nvram set app_139=0

if [ "$caddy_enable" != "0" ] ; then
#nvramshow=`nvram showall | grep '=' | grep caddy | awk '{print gensub(/'"'"'/,"'"'"'\"'"'"'\"'"'"'","g",$0);}'| awk '{print gensub(/=/,"='\''",1,$0)"'\'';";}'` && eval $nvramshow

caddy_renum=`nvram get caddy_renum`
caddy_renum=${caddy_renum:-"0"}

cmd_log_enable=`nvram get cmd_log_enable`
cmd_name="caddy"
cmd_log=""
if [ "$cmd_log_enable" = "1" ] || [ "$caddy_renum" -gt "0" ] ; then
	cmd_log="$cmd_log2"
fi

fi

if [ ! -z "$(echo $scriptfilepath | grep -v "/tmp/script/" | grep cad_dy)" ]  && [ ! -s /tmp/script/_app26 ]; then
	mkdir -p /tmp/script
	{ echo '#!/bin/sh' ; echo $scriptfilepath '"$@"' '&' ; } > /tmp/script/_app26
	chmod 777 /tmp/script/_app26
fi

caddy_restart () {

relock="/var/lock/caddy_restart.lock"
if [ "$1" = "o" ] ; then
	nvram set caddy_renum="0"
	[ -f $relock ] && rm -f $relock
	return 0
fi
if [ "$1" = "x" ] ; then
	if [ -f $relock ] ; then
		logger -t "【caddy】" "多次尝试启动失败，等待【"`cat $relock`"分钟】后自动尝试重新启动"
		exit 0
	fi
	caddy_renum=${caddy_renum:-"0"}
	caddy_renum=`expr $caddy_renum + 1`
	nvram set caddy_renum="$caddy_renum"
	if [ "$caddy_renum" -gt "2" ] ; then
		I=19
		echo $I > $relock
		logger -t "【caddy】" "多次尝试启动失败，等待【"`cat $relock`"分钟】后自动尝试重新启动"
		while [ $I -gt 0 ]; do
			I=$(($I - 1))
			echo $I > $relock
			sleep 60
			[ "$(nvram get caddy_renum)" = "0" ] && exit 0
			[ $I -lt 0 ] && break
		done
		nvram set caddy_renum="0"
	fi
	[ -f $relock ] && rm -f $relock
fi
nvram set caddy_status=0
eval "$scriptfilepath &"
exit 0
}

caddy_get_status () {

A_restart=`nvram get caddy_status`
B_restart="$caddy_enable$(cat /etc/storage/app_11.sh | grep -v '^#' | grep -v '^$')"
B_restart=`echo -n "$B_restart" | md5sum | sed s/[[:space:]]//g | sed s/-//g`
cut_B_re
if [ "$A_restart" != "$B_restart" ] ; then
	nvram set caddy_status=$B_restart
	needed_restart=1
else
	needed_restart=0
fi
}

caddy_check () {

caddy_get_status
if [ "$caddy_enable" != "1" ] && [ "$needed_restart" = "1" ] ; then
	[ ! -z "`pidof caddy`" ] && logger -t "【caddy】" "停止 caddy" && caddy_close
	{ kill_ps "$scriptname" exit0; exit 0; }
fi
if [ "$caddy_enable" = "1" ] ; then
	if [ "$needed_restart" = "1" ] ; then
		caddy_close
		caddy_start
	else
		[ "$caddy_enable" = "1" ] && [ -z "`pidof caddy`" ] && caddy_restart
	fi
fi
}

caddy_keep () {
logger -t "【caddy】" "守护进程启动"
if [ -s /tmp/script/_opt_script_check ]; then
sed -Ei '/【caddy】|^$/d' /tmp/script/_opt_script_check
if [ "$caddy_enable" = "1" ] ; then
cat >> "/tmp/script/_opt_script_check" <<-OSC
	[ -z "\`pidof caddy\`" ] || [ ! -s "/opt/caddy/caddy" ] && nvram set caddy_status=00 && logger -t "【caddy】" "重新启动" && eval "$scriptfilepath &" && sed -Ei '/【caddy】|^$/d' /tmp/script/_opt_script_check # 【caddy】
OSC
fi
return
fi

while true; do
if [ "$caddy_enable" = "1" ] ; then
	if [ -z "`pidof caddy`" ] || [ ! -s "/opt/caddy/caddy" ] ; then
		logger -t "【caddy】" "caddy重新启动"
		caddy_restart
	fi
fi
	sleep 230
done
}

caddy_close () {
sed -Ei '/【caddy】|^$/d' /tmp/script/_opt_script_check
killall caddy
killall -9 caddy
kill_ps "/tmp/script/_app26"
kill_ps "_cad_dy.sh"
kill_ps "$scriptname"
}

caddy_start () {
check_webui_yes
SVC_PATH="/opt/caddy/caddy"
chmod 777 "$SVC_PATH"
if [ ! -s "$SVC_PATH" ] ; then
	logger -t "【caddy】" "找不到 caddy，安装 opt 程序"
	/etc/storage/script/Sh01_mountopt.sh start
	initopt
fi
mkdir -p "/opt/caddy/www/"
wgetcurl_file "$SVC_PATH" "$hiboyfile/caddy2" "$hiboyfile2/caddy2"
[[ "$(/opt/caddy/caddy help 2>&1 | wc -l)" -lt 2 ]] && rm -rf "$SVC_PATH"
wgetcurl_file "$SVC_PATH" "$hiboyfile/caddy2" "$hiboyfile2/caddy2"
if [ ! -s "$SVC_PATH" ] ; then
	logger -t "【caddy】" "找不到 $SVC_PATH ，需要手动安装 $SVC_PATH"
	logger -t "【caddy】" "启动失败, 10 秒后自动尝试重新启动" && sleep 10 && caddy_restart x
fi
caddy_v=`/opt/caddy/caddy version | awk -F ' ' '{print $1;}'`
nvram set caddy_v="$caddy_v"
chmod 777 "$SVC_PATH"
rm -f /opt/caddy/Caddyfile
cat /etc/storage/app_11.sh >> /opt/caddy/Caddyfile
echo "" >> /opt/caddy/Caddyfile
logger -t "【caddy】" "运行 $SVC_PATH"
eval "/opt/caddy/caddy run --config /opt/caddy/Caddyfile --adapter caddyfile $cmd_log" &
sleep 3
[ ! -z "`pidof caddy`" ] && logger -t "【caddy】" "启动成功" && caddy_restart o
[ -z "`pidof caddy`" ] && logger -t "【caddy】" "启动失败, 注意检查端口是否有冲突,程序是否下载完整,10 秒后自动尝试重新启动" && sleep 10 && caddy_restart x

#caddy_get_status
eval "$scriptfilepath keep &"
exit 0
}

initopt () {
optPath=`grep ' /opt ' /proc/mounts | grep tmpfs`
[ ! -z "$optPath" ] && return
if [ ! -z "$(echo $scriptfilepath | grep -v "/opt/etc/init")" ] && [ -s "/opt/etc/init.d/rc.func" ] ; then
	{ echo '#!/bin/sh' ; echo $scriptfilepath '"$@"' '&' ; } > /opt/etc/init.d/$scriptname && chmod 777  /opt/etc/init.d/$scriptname
fi

}

initconfig () {

app_11="/etc/storage/app_11.sh"
if [ -z "$(cat "$app_11" | grep /etc/storage/app_11.sh)" ] ; then
	rm -f "$app_11"
fi
if [ ! -f "$app_11" ] || [ ! -s "$app_11" ] ; then
	cat > "$app_11" <<-\EEE
# 此脚本路径：/etc/storage/app_11.sh
{ # 全局配置
order cgi before respond # 启动 cgi 模块 # 全局配置
order webdav before file_server # 启动 webdav 模块 # 全局配置
admin off # 关闭 API 端口 # 全局配置
} # 全局配置

:12321 {
 root * /opt/caddy/www
 file_server
 log {
  output file /opt/caddy/requests.log {
   roll_size     1MiB
   roll_local_time
   roll_keep     5
   roll_keep_for 120h
  }
 }
}

# :12322 {
 # webdav * {
  # root /opt/caddy/www
 # }
# }

EEE
	chmod 755 "$app_11"
fi

}

initconfig

update_app () {

mkdir -p /opt/app/caddy
if [ "$1" = "del" ] ; then
	rm -rf /opt/app/caddy/Advanced_Extensions_caddy.asp
	rm -rf /opt/caddy/caddy
fi

initconfig

# 加载程序配置页面
if [ ! -f "/opt/app/caddy/Advanced_Extensions_caddy.asp" ] || [ ! -s "/opt/app/caddy/Advanced_Extensions_caddy.asp" ] ; then
	wgetcurl.sh /opt/app/caddy/Advanced_Extensions_caddy.asp "$hiboyfile/Advanced_Extensions_caddyasp" "$hiboyfile2/Advanced_Extensions_caddyasp"
fi
umount /www/Advanced_Extensions_app26.asp
mount --bind /opt/app/caddy/Advanced_Extensions_caddy.asp /www/Advanced_Extensions_app26.asp
# 更新程序启动脚本

[ "$1" = "del" ] && /etc/storage/www_sh/caddy del &
}

case $ACTION in
start)
	caddy_close
	caddy_check
	;;
check)
	caddy_check
	;;
stop)
	caddy_close
	;;
updateapp26)
	caddy_restart o
	[ "$caddy_enable" = "1" ] && nvram set caddy_status="updatecaddy" && logger -t "【caddy】" "重启" && caddy_restart
	[ "$caddy_enable" != "1" ] && nvram set caddy_v="" && logger -t "【caddy】" "更新" && update_app del
	;;
update_app)
	update_app
	;;
keep)
	#caddy_check
	caddy_keep
	;;
*)
	caddy_check
	;;
esac

