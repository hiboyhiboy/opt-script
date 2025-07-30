#!/bin/bash
#copyright by hiboy
source /etc/storage/script/init.sh
tinyproxy_enable=`nvram get tinyproxy_enable`
[ -z $tinyproxy_enable ] && tinyproxy_enable=0 && nvram set tinyproxy_enable=0
tinyproxy_path=`nvram get tinyproxy_path`
[ -z $tinyproxy_path ] && tinyproxy_path=`which tinyproxy` && nvram set tinyproxy_path="$tinyproxy_path"
[ ! -s "$tinyproxy_path" ] && tinyproxy_path="/usr/sbin/tinyproxy" && nvram set tinyproxy_path="/usr/sbin/tinyproxy"
if [ "$tinyproxy_enable" != "0" ] ; then
tinyproxy_port=`nvram get tinyproxy_port`
tinyproxy_renum=`nvram get tinyproxy_renum`
tinyproxy_renum=${tinyproxy_renum:-"0"}
cmd_log_enable=`nvram get cmd_log_enable`
cmd_name="tinyproxy"
cmd_log=""
if [ "$cmd_log_enable" = "1" ] || [ "$tinyproxy_renum" -gt "0" ] ; then
	cmd_log="$cmd_log2"
fi
fi

if [ ! -z "$(echo $scriptfilepath | grep -v "/tmp/script/" | grep tinyproxy)" ] && [ ! -s /tmp/script/_tinyproxy ] ; then
	mkdir -p /tmp/script
	{ echo '#!/bin/bash' ; echo $scriptfilepath '"$@"' '&' ; } > /tmp/script/_tinyproxy
	chmod 777 /tmp/script/_tinyproxy
fi

tinyproxy_restart () {
i_app_restart "$@" -name="tinyproxy"
}

tinyproxy_get_status () {

B_restart="$tinyproxy_enable$tinyproxy_path$tinyproxy_port$(cat /etc/storage/tinyproxy_script.sh | grep -v '^#' | grep -v '^$')"

i_app_get_status -name="tinyproxy" -valb="$B_restart"
}

tinyproxy_check () {

tinyproxy_get_status
if [ "$tinyproxy_enable" != "1" ] && [ "$needed_restart" = "1" ] ; then
	[ ! -z "$(ps -w | grep "$tinyproxy_path" | grep -v grep )" ] && logger -t "【tinyproxy】" "停止 $tinyproxy_path" && tinyproxy_close
	{ kill_ps "$scriptname" exit0; exit 0; }
fi
if [ "$tinyproxy_enable" = "1" ] ; then
	if [ "$needed_restart" = "1" ] ; then
		tinyproxy_close
		tinyproxy_start
	else
		[ -z "$(ps -w | grep "$tinyproxy_path" | grep -v grep )" ] && tinyproxy_restart
		tinyproxy_port_dpt
	fi
fi
}

tinyproxy_keep () {
i_app_keep -name="tinyproxy" -pidof="$(basename $tinyproxy_path)" -cpath="$tinyproxy_path" &
}

tinyproxy_close () {

kill_ps "$scriptname keep"
sed -Ei '/【tinyproxy】|^$/d' /tmp/script/_opt_script_check
tinyproxyport=$(echo `cat /etc/storage/tinyproxy_script.sh | grep -v '^#' | grep -v "ConnectPort" | grep "Port" | sed 's/Port//'`)
[ ! -z "$tinyproxyport" ] && iptables -t filter -D INPUT -p tcp --dport $tinyproxyport -j ACCEPT
killall tinyproxy tinyproxy_script.sh
[ ! -z "$tinyproxy_path" ] && kill_ps "$tinyproxy_path"
kill_ps "/tmp/script/_tinyproxy"
kill_ps "_tinyproxy.sh"
kill_ps "$scriptname"
}

tinyproxy_start () {
check_webui_yes
i_app_get_cmd_file -name="tinyproxy" -cmd="$tinyproxy_path" -cpath="/opt/bin/tinyproxy" -down1="$hiboyfile/tinyproxy" -down2="$hiboyfile2/tinyproxy"
[ -s "$SVC_PATH" ] && [ "$(nvram get tinyproxy_path)" != "$SVC_PATH" ] && nvram set tinyproxy_path="$SVC_PATH"
tinyproxy_path="$SVC_PATH"
logger -t "【tinyproxy】" "运行 $tinyproxy_path"
eval "$tinyproxy_path -c /etc/storage/tinyproxy_script.sh $cmd_log" &
restart_on_dhcpd
sleep 4
i_app_keep -t -name="tinyproxy" -pidof="$(basename $tinyproxy_path)" -cpath="$tinyproxy_path"
tinyproxy_port_dpt
tinyproxy_get_status
eval "$scriptfilepath keep &"
exit 0
}

initconfig () {

config_tinyproxy="/etc/storage/tinyproxy_script.sh"
if [ ! -f "$config_tinyproxy" ] || [ ! -s "$config_tinyproxy" ] ; then
		cat > "$config_tinyproxy" <<-\END
## tinyproxy.conf -- tinyproxy daemon configuration file
## https://github.com/tinyproxy/tinyproxy/blob/master/etc/tinyproxy.conf.in
#User nobody
#Group nobody
Port 9999
#Listen 192.168.0.1 #注释之后可以侦听所有网卡的请求
#Bind 192.168.0.1
Timeout 600
# DefaultErrorFile "/usr/local/share/tinyproxy/default.html"
# StatFile "/usr/local/share/tinyproxy/stats.html"
Logfile "/tmp/syslog.log"
LogLevel Info
PidFile "/var/run/tinyproxy.pid"
MaxClients 100
MinSpareServers 5
MaxSpareServers 20
StartServers 10
MaxRequestsPerChild 0
# Allow 127.0.0.1
ViaProxyName "tinyproxy"
# This is a list of ports allowed by tinyproxy when the CONNECT method
# is used.  To disable the CONNECT method altogether, set the value to 0.
# If no ConnectPort line is found, all ports are allowed (which is not
# very secure.)
#
# The following two ports are used by SSL.
#
ConnectPort 443
ConnectPort 563

END
fi

}

initconfig


tinyproxy_port_dpt () {

if [ "$tinyproxy_port" = "1" ] ; then
	tinyproxyport=$(echo `cat /etc/storage/tinyproxy_script.sh | grep -v '^#' | grep -v "ConnectPort" | grep "Port" | sed 's/Port//'`)
	[ ! -z "$tinyproxyport" ] && port=$(iptables -t filter -L INPUT -v -n --line-numbers | grep dpt:$tinyproxyport | cut -d " " -f 1 | sort -nr | wc -l)
	if [ ! -z "$tinyproxyport" ] && [ "$port" = 0 ] ; then
		[ ! -z "$tinyproxyport" ] && logger -t "【tinyproxy】" "允许 $tinyproxyport 端口通过防火墙"
		[ ! -z "$tinyproxyport" ] && iptables -t filter -I INPUT -p tcp --dport $tinyproxyport -j ACCEPT
	fi
fi

}

case $ACTION in
start)
	tinyproxy_close
	tinyproxy_check
	;;
check)
	tinyproxy_check
	;;
stop)
	tinyproxy_close
	;;
keep)
	#tinyproxy_check
	tinyproxy_keep
	;;
*)
	tinyproxy_check
	;;
esac

