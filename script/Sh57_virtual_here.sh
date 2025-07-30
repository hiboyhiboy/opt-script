#!/bin/bash
#copyright by hiboy
source /etc/storage/script/init.sh
virtualhere_enable=`nvram get app_24`
[ -z $virtualhere_enable ] && virtualhere_enable=0 && nvram set app_24=0
virtualhere_wan=`nvram get app_25`
[ -z $virtualhere_wan ] && virtualhere_wan=0 && nvram set app_25=0

virtualhere_renum=`nvram get virtualhere_renum`
virtualhere_renum=${virtualhere_renum:-"0"}
cmd_log_enable=`nvram get cmd_log_enable`
cmd_name="virtualhere"
cmd_log=""
if [ "$cmd_log_enable" = "1" ] || [ "$virtualhere_renum" -gt "0" ] ; then
	cmd_log="$cmd_log2"
fi
if [ ! -z "$(echo $scriptfilepath | grep -v "/tmp/script/" | grep virtual_here)" ] && [ ! -s /tmp/script/_app8 ] ; then
	mkdir -p /tmp/script
	{ echo '#!/bin/bash' ; echo $scriptfilepath '"$@"' '&' ; } > /tmp/script/_app8
	chmod 777 /tmp/script/_app8
fi

virtualhere_restart () {
i_app_restart "$@" -name="virtualhere"
}

virtualhere_get_status () {

B_restart="$virtualhere_enable$virtualhere_wan$(cat /etc/storage/app_8.sh | grep -v '^#' | grep -v '^$')"
i_app_get_status -name="virtualhere" -valb="$B_restart"
}

virtualhere_check () {

virtualhere_get_status
if [ "$virtualhere_enable" != "1" ] && [ "$needed_restart" = "1" ] ; then
	[ ! -z "`pidof virtualhere`" ] && logger -t "【virtualhere】" "停止 virtualhere" && virtualhere_close
	{ kill_ps "$scriptname" exit0; exit 0; }
fi
if [ "$virtualhere_enable" = "1" ] ; then
	if [ "$needed_restart" = "1" ] ; then
		virtualhere_close
		virtualhere_start
	else
		[ -z "`pidof virtualhere`" ] && virtualhere_restart
		virtualhere_port_dpt
	fi
fi
}

virtualhere_keep () {
i_app_keep -name="virtualhere" -pidof="virtualhere" &
}

virtualhere_close () {

kill_ps "$scriptname keep"
sed -Ei '/【virtualhere】|^$/d' /tmp/script/_opt_script_check
iptables -t filter -D INPUT -p tcp --dport 7575 -j ACCEPT
killall virtualhere
kill_ps "/tmp/script/_app8"
kill_ps "_virtual_here.sh"
kill_ps "$scriptname"
}

virtualhere_start () {

check_webui_yes
i_app_get_cmd_file -name="virtualhere" -cmd="virtualhere" -cpath="/opt/bin/virtualhere" -down1="$hiboyfile/virtualhere" -down2="$hiboyfile2/virtualhere"
virtualhere_v=$(virtualhere -h | grep virtualhere | sed -n '1p')
[ "$(nvram get virtualhere_v)" != "$virtualhere_v" ] && nvram set virtualhere_v="$virtualhere_v"
logger -t "【virtualhere】" "运行 virtualhere"

#运行脚本启动/opt/bin/virtualhere
cd $(dirname `which virtualhere`)
ln -sf /etc/storage/app_8.sh ~/config.ini
eval "virtualhere -b $cmd_log" &

sleep 4
i_app_keep -t -name="virtualhere" -pidof="virtualhere"
virtualhere_port_dpt
#virtualhere_get_status
eval "$scriptfilepath keep &"
exit 0
}

initconfig () {
	if [ ! -f "/etc/storage/app_8.sh" ] || [ ! -s "/etc/storage/app_8.sh" ] ; then
cat > "/etc/storage/app_8.sh" <<-\VVR
ServerName=$HOSTNAME$

VVR
	fi

ln -sf /etc/storage/app_8.sh ~/config.ini

}

initconfig

virtualhere_port_dpt () {

if [ "$virtualhere_wan" = "1" ] ; then
	port=$(iptables -t filter -L INPUT -v -n --line-numbers | grep dpt:7575 | cut -d " " -f 1 | sort -nr | wc -l)
	if [ "$port" = 0 ] ; then
		logger -t "【virtualhere】" "允许 7575 tcp端口通过防火墙"
		iptables -t filter -I INPUT -p tcp --dport 7575 -j ACCEPT
		iptables -t filter -I INPUT -p udp --dport 7575 -j ACCEPT
	fi
fi
}

update_app () {
mkdir -p /opt/app/virtualhere
if [ "$1" = "update_asp" ] ; then
	rm -rf /opt/app/virtualhere/Advanced_Extensions_virtualhere.asp
fi
if [ "$1" = "del" ] ; then
	rm -rf /opt/app/virtualhere/Advanced_Extensions_virtualhere.asp
	[ -f /opt/bin/virtualhere ] && rm -f /opt/bin/virtualhere /opt/opt_backup/bin/virtualhere
fi

initconfig

# 加载程序配置页面
if [ ! -f "/opt/app/virtualhere/Advanced_Extensions_virtualhere.asp" ] || [ ! -s "/opt/app/virtualhere/Advanced_Extensions_virtualhere.asp" ] ; then
	wgetcurl.sh /opt/app/virtualhere/Advanced_Extensions_virtualhere.asp "$hiboyfile/Advanced_Extensions_virtualhereasp" "$hiboyfile2/Advanced_Extensions_virtualhereasp"
fi
umount /www/Advanced_Extensions_app08.asp
mount --bind /opt/app/virtualhere/Advanced_Extensions_virtualhere.asp /www/Advanced_Extensions_app08.asp
# 更新程序启动脚本

[ "$1" = "del" ] && /etc/storage/www_sh/virtualhere del &
}

case $ACTION in
start)
	virtualhere_close
	virtualhere_check
	;;
check)
	virtualhere_check
	;;
stop)
	virtualhere_close
	;;
updateapp8)
	virtualhere_restart o
	[ "$virtualhere_enable" = "1" ] && nvram set virtualhere_status="updatevirtualhere" && logger -t "【virtualhere】" "重启" && virtualhere_restart
	[ "$virtualhere_enable" != "1" ] && nvram set virtualhere_v="" && logger -t "【virtualhere】" "更新" && update_app del
	;;
update_app)
	update_app
	;;
update_asp)
	update_app update_asp
	;;
keep)
	#virtualhere_check
	virtualhere_keep
	;;
initconfig)
	initconfig
	;;
*)
	virtualhere_check
	;;
esac

