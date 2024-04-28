#!/bin/bash
#copyright by hiboy
source /etc/storage/script/init.sh
softether_enable=`nvram get softether_enable`
[ -z $softether_enable ] && softether_enable=0 && nvram set softether_enable=0
softether_path=`nvram get softether_path`
[ -z $softether_path ] && softether_path="/opt/softether/vpnserver" && nvram set softether_path=$softether_path
softether_renum=`nvram get softether_renum`
softether_renum=${softether_renum:-"0"}
cmd_log_enable=`nvram get cmd_log_enable`
cmd_name="softether"
cmd_log=""
if [ "$cmd_log_enable" = "1" ] || [ "$softether_renum" -gt "0" ] ; then
	cmd_log="$cmd_log2"
fi

if [ ! -z "$(echo $scriptfilepath | grep -v "/tmp/script/" | grep softether)" ] && [ ! -s /tmp/script/_softether ] ; then
	mkdir -p /tmp/script
	{ echo '#!/bin/bash' ; echo $scriptfilepath '"$@"' '&' ; } > /tmp/script/_softether
	chmod 777 /tmp/script/_softether
fi

softether_restart () {
i_app_restart "$@" -name="softether"
}

softether_get_status () {

B_restart="$softether_enable$softether_path$(cat /etc/storage/softether_script.sh | grep -v '^#' | grep -v '^$')"

i_app_get_status -name="softether" -valb="$B_restart"
}

softether_check () {

softether_get_status
if [ "$softether_enable" != "1" ] && [ "$needed_restart" = "1" ] ; then
	[ ! -z "$(ps -w | grep "$softether_path" | grep -v grep )" ] && logger -t "【softether】" "停止 softether" && softether_close
	{ kill_ps "$scriptname" exit0; exit 0; }
fi
if [ "$softether_enable" = "1" ] ; then
	if [ "$needed_restart" = "1" ] ; then
		softether_close
		softether_start
	else
		[ -z "$(ps -w | grep "$softether_path" | grep -v grep )" ] && softether_restart
		softether_port_dpt
	fi
fi
}

softether_keep () {
i_app_keep -name="softether" -pidof="$(basename $softether_path)" -cpath="$softether_path" &
}

softether_close () {

kill_ps "$scriptname keep"
sed -Ei '/【softether】|^$/d' /tmp/script/_opt_script_check
iptables -t filter -D INPUT -p udp --destination-port 500 -j ACCEPT
iptables -t filter -D INPUT -p udp --destination-port 4500 -j ACCEPT
iptables -t filter -D INPUT -p udp --destination-port 1701 -j ACCEPT
[ ! -z "$softether_path" ] && $softether_path stop
[ ! -z "$softether_path" ] && kill_ps "$softether_path"
killall vpnserver softether_script.sh
rm -f /etc/storage/dnsmasq/dnsmasq.d/softether.conf
restart_on_dhcpd
kill_ps "/tmp/script/_softether"
kill_ps "_softether.sh"
kill_ps "$scriptname"
}

softether_start () {
check_webui_yes
i_app_get_cmd_file -name="softether" -cmd="$softether_path" -cpath="/opt/softether/vpnserver" -down1="$hiboyfile/vpnserver" -down2="$hiboyfile2/vpnserver"
softether_path="$SVC_PATH"
[ -s "$SVC_PATH" ] && [ "$(nvram get softether_path)" != "$SVC_PATH" ] && nvram set softether_path="$SVC_PATH"
i_app_get_cmd_file -name="softether" -cmd="$(dirname $softether_path)/vpncmd" -cpath="/opt/softether/vpncmd" -down1="$hiboyfile/vpncmd" -down2="$hiboyfile2/vpncmd" -runh="x"
if [ ! -s "$(dirname $softether_path)/hamcore.se2" ] ; then
wgetcurl_checkmd5 "$(dirname $softether_path)/hamcore.se2" "$hiboyfile/hamcore.se2" "$hiboyfile2/hamcore.se2" N
fi
logger -t "【softether】" "运行 softether_script"
$softether_path stop
eval "/etc/storage/softether_script.sh $cmd_log" &
sleep 4
i_app_keep -t -name="softether" -pidof="$(basename $softether_path)" -cpath="$softether_path"

softether_port_dpt
softether_get_status
eval "$scriptfilepath keep &"
exit 0
}

initconfig () {

	if [ ! -f "/etc/storage/softether_script.sh" ] || [ ! -s "/etc/storage/softether_script.sh" ] ; then
cat > "/etc/storage/softether_script.sh" <<-\FOF
#!/bin/bash
export PATH='/opt/softether:/etc/storage/bin:/tmp/script:/etc/storage/script:/opt/usr/sbin:/opt/usr/bin:/opt/sbin:/opt/bin:/usr/local/sbin:/usr/sbin:/usr/bin:/sbin:/bin'
export LD_LIBRARY_PATH=/lib:/opt/lib
source /etc/storage/script/init.sh
softether_path=`nvram get softether_path`
[ -z $softether_path ] && softether_path=`which vpnserver` && nvram set softether_path=$softether_path
SVC_PATH=$softether_path
[ -f /opt/softether/vpn_server.config ] && [ ! -f /etc/storage/vpn_server.config ] && cp -f /opt/softether/vpn_server.config /etc/storage/vpn_server.config
[ ! -f /etc/storage/vpn_server.config ] && touch /etc/storage/vpn_server.config
ln -sf /etc/storage/vpn_server.config /opt/softether/vpn_server.config
[ ! -s /opt/softether/vpn_server.config ] && cp -f /etc/storage/vpn_server.config /opt/softether/vpn_server.config
$SVC_PATH start 2>&1 &
tap=""
until [ ! -z "$tap" ]
do
    tap=`ifconfig | grep tap_ | awk '{print $1}'`
    sleep 2
done
logger -t "【softether】" "正确启动 vpnserver!"
brctl addif br0 $tap
echo interface=$tap > /etc/storage/dnsmasq/dnsmasq.d/softether.conf
restart_dhcpd
mtd_storage.sh save &
FOF
chmod 777 "/etc/storage/softether_script.sh"
	fi

}

initconfig

softether_port_dpt () {

port=$(iptables -t filter -L INPUT -v -n --line-numbers | grep dpt:500 | cut -d " " -f 1 | sort -nr | wc -l)
if [ "$port" = 0 ] ; then
	logger -t "【softether】" "允许 500、4500、1701 udp端口通过防火墙"
	iptables -t filter -I INPUT -p udp --destination-port 500 -j ACCEPT
	iptables -t filter -I INPUT -p udp --destination-port 4500 -j ACCEPT
	iptables -t filter -I INPUT -p udp --destination-port 1701 -j ACCEPT
fi

}

case $ACTION in
start)
	softether_close
	softether_check
	;;
check)
	softether_check
	;;
stop)
	softether_close
	;;
keep)
	#softether_check
	softether_keep
	;;
*)
	softether_check
	;;
esac

