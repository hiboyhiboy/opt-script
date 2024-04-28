#!/bin/bash
#copyright by hiboy
source /etc/storage/script/init.sh
mproxyport=`nvram get mproxyport`
mproxy_enable=`nvram get mproxy_enable`
[ -z $mproxy_enable ] && mproxy_enable=0 && nvram set mproxy_enable=0
if [ "$mproxy_enable" != "0" ] ; then
mproxy_port=`nvram get mproxy_port`
mproxy_renum=`nvram get mproxy_renum`
mproxy_renum=${mproxy_renum:-"0"}
cmd_log_enable=`nvram get cmd_log_enable`
cmd_name="mproxy"
cmd_log=""
if [ "$cmd_log_enable" = "1" ] || [ "$mproxy_renum" -gt "0" ] ; then
	cmd_log="$cmd_log2"
fi
fi

if [ ! -z "$(echo $scriptfilepath | grep -v "/tmp/script/" | grep mproxy)" ] && [ ! -s /tmp/script/_mproxy ] ; then
	mkdir -p /tmp/script
	{ echo '#!/bin/bash' ; echo $scriptfilepath '"$@"' '&' ; } > /tmp/script/_mproxy
	chmod 777 /tmp/script/_mproxy
fi

mproxy_restart () {
i_app_restart "$@" -name="mproxy"
}

mproxy_get_status () {

B_restart="$mproxy_enable$mproxy_port$(cat /etc/storage/mproxy_script.sh | grep -v '^#' | grep -v '^$')"

i_app_get_status -name="mproxy" -valb="$B_restart"
}

mproxy_check () {

mproxy_get_status
if [ "$mproxy_enable" != "1" ] && [ "$needed_restart" = "1" ] ; then
	[ ! -z "`pidof mproxy`" ] && logger -t "【mproxy】" "停止 mproxy" && mproxy_close
	{ kill_ps "$scriptname" exit0; exit 0; }
fi
if [ "$mproxy_enable" = "1" ] ; then
	if [ "$needed_restart" = "1" ] ; then
		mproxy_close
		mproxy_start
	else
		[ -z "`pidof mproxy`" ] && mproxy_restart
		mproxy_port_dpt
	fi
fi
}

mproxy_keep () {
i_app_keep -name="mproxy" -pidof="mproxy" &
}

mproxy_close () {

kill_ps "$scriptname keep"
sed -Ei '/【mproxy】|^$/d' /tmp/script/_opt_script_check
mproxyport=$(echo `cat /etc/storage/mproxy_script.sh | grep -v '^#' | grep "mproxy_port=" | sed 's/mproxy_port=//'`)
[ ! -z "$mproxyport" ] && iptables -t filter -D INPUT -p tcp --dport $mproxyport -j ACCEPT
killall mproxy mproxy_script.sh
kill_ps "/tmp/script/_mproxy"
kill_ps "_mproxy.sh"
kill_ps "$scriptname"
}

mproxy_start () {
check_webui_yes
i_app_get_cmd_file -name="mproxy" -cmd="mproxy" -cpath="/opt/bin/mproxy" -down1="$hiboyfile/mproxy" -down2="$hiboyfile2/mproxy"
logger -t "【mproxy】" "运行 mproxy_script"
eval "/etc/storage/mproxy_script.sh $cmd_log" &
restart_on_dhcpd
sleep 4
i_app_keep -t -name="mproxy" -pidof="mproxy"
mproxy_port_dpt
#mproxy_get_status
eval "$scriptfilepath keep &"
exit 0
}

initconfig () {

config_mproxy="/etc/storage/mproxy_script.sh"
if [ ! -f "$config_mproxy" ] || [ ! -s "$config_mproxy" ] ; then
		cat > "$config_mproxy" <<-\END
#!/bin/bash
killall mproxy
logger -t "【mproxy】" "运行 mproxy"
# 使用方法：https://github.com/examplecode/mproxy
# 本地监听端口
mproxy_port=8000

# 删除（#）启用指定选项
# 默认作为普通的代理服务器。
mproxy -l $mproxy_port -d 2>&1 &



# 在远程服务器启动mproxy作为远程代理
# 在远程作为加密代传输方式理服务器
# mproxy  -l 8081 -D -d 2>&1 &


# 本地启动 mproxy 作为本地代理，并指定传输方式加密。
# 在本地启动一个mporxy 并指定目上一步在远程部署的服务器地址和端口号。
# mproxy  -l 8080 -h xxx.xxx.xxx.xxx:8081 -E 2>&1 &


END
fi
chmod 777 "$config_mproxy"

}

initconfig

mproxy_port_dpt () {

if [ "$mproxy_port" = "1" ] ; then
	mproxyport=$(echo `cat /etc/storage/mproxy_script.sh | grep -v '^#' | grep "mproxy_port=" | sed 's/mproxy_port=//'`)
	[ ! -z "$mproxyport" ] && port=$(iptables -t filter -L INPUT -v -n --line-numbers | grep dpt:$mproxyport | cut -d " " -f 1 | sort -nr | wc -l)
	if [ ! -z "$mproxyport" ] && [ "$port" = 0 ] ; then
		[ ! -z "$mproxyport" ] && logger -t "【mproxy】" "允许 $mproxyport 端口通过防火墙"
		[ ! -z "$mproxyport" ] && iptables -t filter -I INPUT -p tcp --dport $mproxyport -j ACCEPT
	fi
fi

}

case $ACTION in
start)
	mproxy_close
	mproxy_check
	;;
check)
	mproxy_check
	;;
stop)
	mproxy_close
	;;
keep)
	#mproxy_check
	mproxy_keep
	;;
*)
	mproxy_check
	;;
esac

