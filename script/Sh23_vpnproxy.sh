#!/bin/bash
#copyright by hiboy
source /etc/storage/script/init.sh
vpnproxy_wan_port=`nvram get vpnproxy_wan_port`
vpnproxy_enable=`nvram get vpnproxy_enable`
[ -z $vpnproxy_enable ] && vpnproxy_enable=0 && nvram set vpnproxy_enable=0
if [ "$vpnproxy_enable" != "0" ] ; then
vpnproxy_vpn_port=`nvram get vpnproxy_vpn_port`
vpnproxy_renum=`nvram get vpnproxy_renum`
vpnproxy_renum=${vpnproxy_renum:-"0"}
cmd_log_enable=`nvram get cmd_log_enable`
cmd_name="vpnproxy"
cmd_log=""
if [ "$cmd_log_enable" = "1" ] || [ "$vpnproxy_renum" -gt "0" ] ; then
	cmd_log="$cmd_log2"
fi
fi

if [ ! -z "$(echo $scriptfilepath | grep -v "/tmp/script/" | grep vpnproxy)" ] && [ ! -s /tmp/script/_vpnproxy ] ; then
	mkdir -p /tmp/script
	{ echo '#!/bin/bash' ; echo $scriptfilepath '"$@"' '&' ; } > /tmp/script/_vpnproxy
	chmod 777 /tmp/script/_vpnproxy
fi

vpnproxy_restart () {
i_app_restart "$@" -name="vpnproxy"
}

vpnproxy_get_status () {

[ -z $vpnproxy_wan_port ] && vpnproxy_wan_port=8888 && nvram set vpnproxy_wan_port=$vpnproxy_wan_port
[ -z $vpnproxy_vpn_port ] && vpnproxy_vpn_port=1194 && nvram set vpnproxy_vpn_port=$vpnproxy_vpn_port
B_restart="$vpnproxy_enable$vpnproxy_wan_port$vpnproxy_vpn_port"

i_app_get_status -name="vpnproxy" -valb="$B_restart"
}

vpnproxy_check () {

vpnproxy_get_status
if [ "$vpnproxy_enable" != "1" ] && [ "$needed_restart" = "1" ] ; then
	[ ! -z "`pidof nvpproxy`" ] && logger -t "【vpnproxy】" "停止 nvpproxy" && vpnproxy_close
	{ kill_ps "$scriptname" exit0; exit 0; }
fi
if [ "$vpnproxy_enable" = "1" ] ; then
	if [ "$needed_restart" = "1" ] ; then
		vpnproxy_close
		vpnproxy_start
	else
		[ -z "`pidof nvpproxy`" ] && vpnproxy_restart
		vpnproxy_port_dpt
	fi
fi
}

vpnproxy_keep () {
i_app_keep -name="vpnproxy" -pidof="nvpproxy" &
}

vpnproxy_close () {

kill_ps "$scriptname keep"
sed -Ei '/【vpnproxy】|^$/d' /tmp/script/_opt_script_check
iptables -t filter -D INPUT -p tcp --dport $vpnproxy_wan_port -j ACCEPT
killall nvpproxy
kill_ps "/tmp/script/_vpnproxy"
kill_ps "_vpnproxy.sh"
kill_ps "$scriptname"
}

vpnproxy_start () {
check_webui_yes
i_app_get_cmd_file -name="vpnproxy" -cmd="nvpproxy" -cpath="/opt/bin/nvpproxy" -down1="$hiboyfile/nvpproxy" -down2="$hiboyfile2/nvpproxy"
logger -t "【vpnproxy】" "运行 $SVC_PATH"
eval "nvpproxy -port=$vpnproxy_wan_port -proxy=127.0.0.1:$vpnproxy_vpn_port $cmd_log" &
restart_on_dhcpd
sleep 4
i_app_keep -t -name="vpnproxy" -pidof="nvpproxy"
vpnproxy_port_dpt
#vpnproxy_get_status
eval "$scriptfilepath keep &"
exit 0
}

vpnproxy_port_dpt () {

port=$(iptables -t filter -L INPUT -v -n --line-numbers | grep dpt:$vpnproxy_wan_port | cut -d " " -f 1 | sort -nr | wc -l)
if [ "$port" = 0 ] ; then
	logger -t "【vpnproxy】" "允许 $vpnproxy_wan_port 端口通过防火墙"
	iptables -t filter -I INPUT -p tcp --dport $vpnproxy_wan_port -j ACCEPT
fi

}

case $ACTION in
start)
	vpnproxy_close
	vpnproxy_check
	;;
check)
	vpnproxy_check
	;;
stop)
	vpnproxy_close
	;;
keep)
	#vpnproxy_check
	vpnproxy_keep
	;;
*)
	vpnproxy_check
	;;
esac

