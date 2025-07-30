#!/bin/bash
#copyright by hiboy
source /etc/storage/script/init.sh
ddnsgo_enable=`nvram get app_45`
[ -z $ddnsgo_enable ] && ddnsgo_enable=0 && nvram set app_45=0
ddnsgo_usage="$(nvram get app_138)"
[ -z "$ddnsgo_usage" ] && ddnsgo_usage="-l :9877 -f 600 -c /etc/storage/app_35.sh -skipVerify" && nvram set app_138="$ddnsgo_usage"
if [ "$ddnsgo_enable" != "0" ] ; then

ddnsgo_renum=`nvram get ddnsgo_renum`
ddnsgo_renum=${ddnsgo_renum:-"0"}

cmd_log_enable=`nvram get cmd_log_enable`
cmd_name="ddnsgo"
cmd_log=""
if [ "$cmd_log_enable" = "1" ] || [ "$ddnsgo_renum" -gt "0" ] ; then
	cmd_log="$cmd_log2"
fi

fi

if [ ! -z "$(echo $scriptfilepath | grep -v "/tmp/script/" | grep ddns_go)" ] && [ ! -s /tmp/script/_app25 ] ; then
	mkdir -p /tmp/script
	{ echo '#!/bin/bash' ; echo $scriptfilepath '"$@"' '&' ; } > /tmp/script/_app25
	chmod 777 /tmp/script/_app25
fi

ddnsgo_restart () {
i_app_restart "$@" -name="ddnsgo"
}

ddnsgo_get_status () {

B_restart="$ddnsgo_enable$ddnsgo_usage"

i_app_get_status -name="ddnsgo" -valb="$B_restart"
}

ddnsgo_check () {

ddnsgo_get_status
if [ "$ddnsgo_enable" != "1" ] && [ "$needed_restart" = "1" ] ; then
	[ ! -z "$(ps -w | grep "ddnsgo" | grep -v grep )" ] && logger -t "【ddnsgo】" "停止 ddnsgo" && ddnsgo_close
	{ kill_ps "$scriptname" exit0; exit 0; }
fi
if [ "$ddnsgo_enable" = "1" ] ; then
	if [ "$needed_restart" = "1" ] ; then
		ddnsgo_close
		ddnsgo_start
	else
		[ "$ddnsgo_enable" = "1" ] && [ -z "$(ps -w | grep "ddnsgo" | grep -v grep )" ] && ddnsgo_restart
	fi
fi
}

ddnsgo_keep () {
i_app_keep -name="ddnsgo" -pidof="ddnsgo" &
}

ddnsgo_close () {
sed -Ei '/【ddnsgo】|^$/d' /tmp/script/_opt_script_check
killall ddnsgo
kill_ps "/tmp/script/_app25"
kill_ps "_ddns_go.sh"
kill_ps "$scriptname"
}

ddnsgo_start () {
check_webui_yes
i_app_get_cmd_file -name="ddnsgo" -cmd="ddnsgo" -cpath="/opt/bin/ddnsgo" -down1="$hiboyfile/ddnsgo" -down2="$hiboyfile2/ddnsgo"
logger -t "【ddnsgo】" "运行 $SVC_PATH"
eval "$SVC_PATH $ddnsgo_usage $cmd_log" &
sleep 4
i_app_keep -t -name="ddnsgo" -pidof="ddnsgo"

#ddnsgo_get_status
eval "$scriptfilepath keep &"
exit 0
}

initconfig () {

app_35="/etc/storage/app_35.sh"
if [ ! -f "$app_35" ] || [ ! -s "$app_35" ] ; then
	cat > "$app_35" <<-\EEE
notallowwanaccess: true

EEE
	chmod 755 "$app_35"
fi

}

initconfig

update_app () {

mkdir -p /opt/app/ddnsgo
if [ "$1" = "del" ] ; then
	rm -rf /opt/app/ddnsgo/Advanced_Extensions_ddnsgo.asp
	rm -rf /opt/bin/ddnsgo /opt/opt_backup/bin/ddnsgo 
fi

initconfig

# 加载程序配置页面
if [ ! -f "/opt/app/ddnsgo/Advanced_Extensions_ddnsgo.asp" ] || [ ! -s "/opt/app/ddnsgo/Advanced_Extensions_ddnsgo.asp" ] ; then
	wgetcurl.sh /opt/app/ddnsgo/Advanced_Extensions_ddnsgo.asp "$hiboyfile/Advanced_Extensions_ddnsgoasp" "$hiboyfile2/Advanced_Extensions_ddnsgoasp"
fi
umount /www/Advanced_Extensions_app25.asp
mount --bind /opt/app/ddnsgo/Advanced_Extensions_ddnsgo.asp /www/Advanced_Extensions_app25.asp
# 更新程序启动脚本

[ "$1" = "del" ] && /etc/storage/www_sh/ddnsgo del &
}

case $ACTION in
start)
	ddnsgo_close
	ddnsgo_check
	;;
check)
	ddnsgo_check
	;;
stop)
	ddnsgo_close
	;;
updateapp25)
	ddnsgo_restart o
	[ "$ddnsgo_enable" = "1" ] && nvram set ddnsgo_status="updateddnsgo" && logger -t "【ddnsgo】" "重启" && ddnsgo_restart
	[ "$ddnsgo_enable" != "1" ] && nvram set ddnsgo_v="" && logger -t "【ddnsgo】" "更新" && update_app del
	;;
update_app)
	update_app
	;;
keep)
	#ddnsgo_check
	ddnsgo_keep
	;;
*)
	ddnsgo_check
	;;
esac

