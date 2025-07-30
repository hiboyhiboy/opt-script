#!/bin/bash
#copyright by hiboy
source /etc/storage/script/init.sh
caddy_enable=`nvram get app_139`
[ -z $caddy_enable ] && caddy_enable=0 && nvram set app_139=0

if [ "$caddy_enable" != "0" ] ; then

caddy_renum=`nvram get caddy_renum`
caddy_renum=${caddy_renum:-"0"}

cmd_log_enable=`nvram get cmd_log_enable`
cmd_name="caddy"
cmd_log=""
if [ "$cmd_log_enable" = "1" ] || [ "$caddy_renum" -gt "0" ] ; then
	cmd_log="$cmd_log2"
fi

fi

if [ ! -z "$(echo $scriptfilepath | grep -v "/tmp/script/" | grep cad_dy)" ] && [ ! -s /tmp/script/_app26 ] ; then
	mkdir -p /tmp/script
	{ echo '#!/bin/bash' ; echo $scriptfilepath '"$@"' '&' ; } > /tmp/script/_app26
	chmod 777 /tmp/script/_app26
fi

caddy_restart () {
i_app_restart "$@" -name="caddy"
}

caddy_get_status () {

B_restart="$caddy_enable$(cat /etc/storage/app_11.sh | grep -v '^#' | grep -v '^$')"

i_app_get_status -name="caddy" -valb="$B_restart"
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
i_app_keep -name="caddy" -pidof="caddy" -cpath="/opt/caddy/caddy" &
}

caddy_close () {
sed -Ei '/【caddy】|^$/d' /tmp/script/_opt_script_check
killall caddy
kill_ps "/tmp/script/_app26"
kill_ps "_cad_dy.sh"
kill_ps "$scriptname"
}

caddy_start () {
check_webui_yes
i_app_get_cmd_file -name="caddy" -cmd="/opt/caddy/caddy" -cpath="/opt/caddy/caddy" -down1="$hiboyfile/caddy2" -down2="$hiboyfile2/caddy2" -runh="help"
caddy_v=`/opt/caddy/caddy version | awk -F ' ' '{print $1;}'`
[ "$(nvram get caddy_v)" != "$caddy_v" ] && nvram set caddy_v="$caddy_v"
rm -f /opt/caddy/Caddyfile
cat /etc/storage/app_11.sh >> /opt/caddy/Caddyfile
echo "" >> /opt/caddy/Caddyfile
logger -t "【caddy】" "运行 $SVC_PATH"
eval "/opt/caddy/caddy run --config /opt/caddy/Caddyfile --adapter caddyfile $cmd_log" &
sleep 3
i_app_keep -t -name="caddy" -pidof="caddy" -cpath="/opt/caddy/caddy"

#caddy_get_status
eval "$scriptfilepath keep &"
exit 0
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

