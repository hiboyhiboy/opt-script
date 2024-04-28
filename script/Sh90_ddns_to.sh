#!/bin/bash
#copyright by hiboy
source /etc/storage/script/init.sh
ddnsto_enable=`nvram get app_64`
[ -z $ddnsto_enable ] && ddnsto_enable=0 && nvram set app_64=0
ddnsto_token=`nvram get app_65`
if [ "$ddnsto_enable" != "0" ] ; then

ddnsto_renum=`nvram get ddnsto_renum`
ddnsto_renum=${ddnsto_renum:-"0"}

upPassword=""

cmd_log_enable=`nvram get cmd_log_enable`
cmd_name="ddnsto"
cmd_log=""
if [ "$cmd_log_enable" = "1" ] || [ "$ddnsto_renum" -gt "0" ] ; then
	cmd_log="$cmd_log2"
fi

fi

if [ ! -z "$(echo $scriptfilepath | grep -v "/tmp/script/" | grep ddns_to)" ] && [ ! -s /tmp/script/_app16 ] ; then
	mkdir -p /tmp/script
	{ echo '#!/bin/bash' ; echo $scriptfilepath '"$@"' '&' ; } > /tmp/script/_app16
	chmod 777 /tmp/script/_app16
fi

ddnsto_restart () {
i_app_restart "$@" -name="ddnsto"
}

ddnsto_get_status () {

B_restart="$ddnsto_enable$ddnsto_token"

i_app_get_status -name="ddnsto" -valb="$B_restart"
}

ddnsto_check () {

ddnsto_get_status
if [ "$ddnsto_enable" != "1" ] && [ "$needed_restart" = "1" ] ; then
	[ ! -z "$(ps -w | grep "ddnsto" | grep -v grep )" ] && logger -t "【ddnsto】" "停止 ddnsto" && ddnsto_close
	{ kill_ps "$scriptname" exit0; exit 0; }
fi
if [ "$ddnsto_enable" = "1" ] ; then
	if [ "$needed_restart" = "1" ] ; then
		ddnsto_close
		ddnsto_start
	else
		[ "$ddnsto_enable" = "1" ] && [ -z "$(ps -w | grep "ddnsto" | grep -v grep )" ] && ddnsto_restart
	fi
fi
}

ddnsto_keep () {
i_app_keep -name="ddnsto" -pidof="ddnsto" &
}

ddnsto_close () {
kill_ps "$scriptname keep"
sed -Ei '/【ddnsto】|^$/d' /tmp/script/_opt_script_check
killall ddnsto
kill_ps "/tmp/script/_app16"
kill_ps "_ddns_to.sh"
kill_ps "$scriptname"
}

ddnsto_start () {

check_webui_yes
i_app_get_cmd_file -name="ddnsto" -cmd="ddnsto" -cpath="/opt/bin/ddnsto" -down1="$hiboyfile/ddnsto" -down2="$hiboyfile2/ddnsto"
[ ! -s "$SVC_PATH" ] && wgetcurl_file "$SVC_PATH" "https://fw0.koolcenter.com/binary/ddnsto/linux/mipsel/ddnsto"
ddnsto_route_id=$(ddnsto -w | awk '{print $2}')
nvram set ddnsto_route_id="$ddnsto_route_id"
[ ! -z $ddnsto_route_id ] && logger -t "【ddnsto】" "路由器ID：【$ddnsto_route_id】；管理控制台 https://www.ddnsto.com/"
ddnsto_version=$(ddnsto -v)
nvram set ddnsto_version="$ddnsto_version"
[ -z $ddnsto_token ] && logger -t "【ddnsto】" "【ddnsto_token】不能为空,启动失败, 10 秒后自动尝试重新启动" && sleep 10 && ddnsto_restart x
logger -t "【ddnsto】" "运行 ddnsto 版本：$ddnsto_version"
eval "ddnsto -u $ddnsto_token -d $cmd_log" &
sleep 3
i_app_keep -t -name="ddnsto" -pidof="ddnsto"
sleep 2
ddnsto_route_id=$(ddnsto -w | awk '{print $2}')
nvram set ddnsto_route_id="$ddnsto_route_id"
[ ! -z $ddnsto_route_id ] && logger -t "【ddnsto】" "路由器ID：【$ddnsto_route_id】；管理控制台 https://www.ddnsto.com/"
[ -z $ddnsto_route_id ] && logger -t "【ddnsto】" "路由器ID：【$ddnsto_route_id】不能为空,启动失败, 10 秒后自动尝试重新启动" && sleep 10 && ddnsto_restart x
eval "$scriptfilepath keep &"
exit 0

}

initconfig () {

echo "ddnsto initconfig"
}

initconfig

update_app () {
mkdir -p /opt/app/ddnsto
if [ "$1" = "update_asp" ] ; then
	rm -rf /opt/app/ddnsto/Advanced_Extensions_ddnsto.asp
fi
if [ "$1" = "del" ] ; then
	rm -rf /opt/app/ddnsto/Advanced_Extensions_ddnsto.asp
	[ -f /opt/bin/ddnsto ] && rm -f /opt/bin/ddnsto /opt/opt_backup/bin/ddnsto
	[ -f /etc_ro/ddnsto ] && touch /tmp/ddnsto_ro
fi

initconfig

# 加载程序配置页面
if [ ! -f "/opt/app/ddnsto/Advanced_Extensions_ddnsto.asp" ] || [ ! -s "/opt/app/ddnsto/Advanced_Extensions_ddnsto.asp" ] ; then
	wgetcurl.sh /opt/app/ddnsto/Advanced_Extensions_ddnsto.asp "$hiboyfile/Advanced_Extensions_ddnstoasp" "$hiboyfile2/Advanced_Extensions_ddnstoasp"
fi
umount /www/Advanced_Extensions_app16.asp
mount --bind /opt/app/ddnsto/Advanced_Extensions_ddnsto.asp /www/Advanced_Extensions_app16.asp
# 更新程序启动脚本

[ "$1" = "del" ] && /etc/storage/www_sh/ddnsto del &
}

case $ACTION in
start)
	ddnsto_close
	ddnsto_check
	;;
check)
	ddnsto_check
	;;
stop)
	ddnsto_close
	;;
updateapp16)
	ddnsto_restart o
	[ "$ddnsto_enable" = "1" ] && nvram set ddnsto_status="updateddnsto" && logger -t "【ddnsto】" "重启" && ddnsto_restart
	[ "$ddnsto_enable" != "1" ] && nvram set ddnsto_version="" && logger -t "【ddnsto】" "更新" && update_app del
	;;
update_app)
	update_app
	;;
update_asp)
	update_app update_asp
	;;
keep)
	#ddnsto_check
	ddnsto_keep
	;;
*)
	ddnsto_check
	;;
esac

