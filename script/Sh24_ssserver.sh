#!/bin/sh
#copyright by hiboy
source /etc/storage/script/init.sh
ssserver_port=`nvram get ssserver_port`
ssserver_enable=`nvram get ssserver_enable`
[ -z $ssserver_enable ] && ssserver_enable=0 && nvram set ssserver_enable=0
if [ "$ssserver_enable" != "0" ] ; then
#nvramshow=`nvram showall | grep '=' | grep ssserver | awk '{print gensub(/'"'"'/,"'"'"'\"'"'"'\"'"'"'","g",$0);}'| awk '{print gensub(/=/,"='\''",1,$0)"'\'';";}'` && eval $nvramshow

ssserver_method=`nvram get ssserver_method`
ssserver_password=`nvram get ssserver_password`
ssserver_time=`nvram get ssserver_time`
ssserver_udp=`nvram get ssserver_udp`
ssserver_usage=" `nvram get ssserver_usage` "

[ -z $ssserver_password ] && ssserver_password="m" && nvram set ssserver_password=$ssserver_password
[ -z $ssserver_time ] && ssserver_time=120 && nvram set ssserver_time=$ssserver_time
[ -z $ssserver_port ] && ssserver_port=8388 && nvram set ssserver_port=$ssserver_port
[ -z $ssserver_method ] && ssserver_method="aes-256-cfb" && nvram set ssserver_method="aes-256-cfb"
ssserver_renum=`nvram get ssserver_renum`
ssserver_renum=${ssserver_renum:-"0"}
cmd_log_enable=`nvram get cmd_log_enable`
cmd_name="SS_server"
cmd_log=""
if [ "$cmd_log_enable" = "1" ] || [ "$ssserver_renum" -gt "0" ] ; then
	cmd_log="$cmd_log2"
fi
#检查  libsodium.so.23
[ -f /lib/libsodium.so.23 ] && libsodium_so=libsodium.so.23
[ -f /lib/libsodium.so.18 ] && libsodium_so=libsodium.so.18

fi
if [ ! -z "$(echo $scriptfilepath | grep -v "/tmp/script/" | grep ssserver)" ]  && [ ! -s /tmp/script/_ssserver ]; then
	mkdir -p /tmp/script
	{ echo '#!/bin/sh' ; echo $scriptfilepath '"$@"' '&' ; } > /tmp/script/_ssserver
	chmod 777 /tmp/script/_ssserver
fi

ssserver_restart () {

relock="/var/lock/ssserver_restart.lock"
if [ "$1" = "o" ] ; then
	nvram set ssserver_renum="0"
	[ -f $relock ] && rm -f $relock
	return 0
fi
if [ "$1" = "x" ] ; then
	if [ -f $relock ] ; then
		logger -t "【SS_server】" "多次尝试启动失败，等待【"`cat $relock`"分钟】后自动尝试重新启动"
		exit 0
	fi
	ssserver_renum=${ssserver_renum:-"0"}
	ssserver_renum=`expr $ssserver_renum + 1`
	nvram set ssserver_renum="$ssserver_renum"
	if [ "$ssserver_renum" -gt "2" ] ; then
		I=19
		echo $I > $relock
		logger -t "【SS_server】" "多次尝试启动失败，等待【"`cat $relock`"分钟】后自动尝试重新启动"
		while [ $I -gt 0 ]; do
			I=$(($I - 1))
			echo $I > $relock
			sleep 60
			[ "$(nvram get ssserver_renum)" = "0" ] && exit 0
			[ $I -lt 0 ] && break
		done
		nvram set ssserver_renum="0"
	fi
	[ -f $relock ] && rm -f $relock
fi
nvram set ssserver_status=0
eval "$scriptfilepath &"
exit 0
}

ssserver_get_status () {

A_restart=`nvram get ssserver_status`
B_restart="$ssserver_enable$ssserver_method$ssserver_password$ssserver_port$ssserver_time$ssserver_udp$ssserver_ota$ssserver_usage"
B_restart=`echo -n "$B_restart" | md5sum | sed s/[[:space:]]//g | sed s/-//g`
if [ "$A_restart" != "$B_restart" ] ; then
	nvram set ssserver_status=$B_restart
	needed_restart=1
else
	needed_restart=0
fi
}

ssserver_check () {

ssserver_get_status
if [ "$ssserver_enable" != "1" ] && [ "$needed_restart" = "1" ] ; then
	[ ! -z "`pidof ss-server`" ] && logger -t "【SS_server】" "停止 ss-server" && ssserver_close
	{ kill_ps "$scriptname" exit0; exit 0; }
fi
if [ "$ssserver_enable" = "1" ] ; then
	if [ "$needed_restart" = "1" ] ; then
		ssserver_close
		ssserver_start
	else
		[ -z "`pidof ss-server`" ] && ssserver_restart
		ssserver_port_dpt
	fi
fi
}

ssserver_keep () {
logger -t "【SS_server】" "守护进程启动"
if [ -s /tmp/script/_opt_script_check ]; then
sed -Ei '/【SS_server】|^$/d' /tmp/script/_opt_script_check
cat >> "/tmp/script/_opt_script_check" <<-OSC
[ -z "\`pidof ss-server\`" ] || [ ! -s "`which ss-server`" ] && nvram set ssserver_status=00 && logger -t "【SS_server】" "重新启动" && eval "$scriptfilepath &" && sed -Ei '/【SS_server】|^$/d' /tmp/script/_opt_script_check # 【SS_server】
OSC
return
fi
while true; do
	if [ -z "`pidof ss-server`" ] || [ ! -s "`which ss-server`" ] ; then
		logger -t "【SS_server】" "重新启动"
		ssserver_restart
	fi
sleep 224
done
}

ssserver_close () {

kill_ps "$scriptname keep"
sed -Ei '/【SS_server】|^$/d' /tmp/script/_opt_script_check
iptables -t filter -D INPUT -p tcp --dport $ssserver_port -j ACCEPT
iptables -t filter -D INPUT -p udp --dport $ssserver_port -j ACCEPT
ip6tables -t filter -D INPUT -p tcp --dport $ssserver_port -j ACCEPT
ip6tables -t filter -D INPUT -p udp --dport $ssserver_port -j ACCEPT
killall ss-server obfs-server gq-server
killall -9 ss-server obfs-server gq-server
ss_plugin_server_name="$(nvram get ss_plugin_server_name)"
[ ! -z "$ss_plugin_server_name" ] && { kill_ps "$ss_plugin_server_name" ; ss_plugin_server_name="" ; nvram set ss_plugin_server_name="" ; }
kill_ps "/tmp/script/_ssserver"
kill_ps "_ssserver.sh"
kill_ps "$scriptname"
}

ssserver_start () {

check_webui_yes
SVC_PATH="$(which ss-server)"
[ ! -s "$SVC_PATH" ] && SVC_PATH=/usr/sbin/ss-server
if [ ! -s "$SVC_PATH" ] ; then
	SVC_PATH="/opt/bin/ss-server"
fi
chmod 777 "$SVC_PATH"
[[ "$(ss-server -h 2>&1 | wc -l)" -lt 2 ]] && rm -rf /opt/bin/ss-server
if [ ! -s "$SVC_PATH" ] ; then
	logger -t "【SS_server】" "找不到 $SVC_PATH，安装 opt 程序"
	/etc/storage/script/Sh01_mountopt.sh start
	initopt
fi
wgetcurl_file "$SVC_PATH" "$hiboyfile/$libsodium_so/ss-server" "$hiboyfile2/$libsodium_so/ss-server"
if [ ! -s "$SVC_PATH" ] ; then
	logger -t "【SS_server】" "找不到 $SVC_PATH ，需要手动安装 $SVC_PATH"
	logger -t "【SS_server】" "启动失败, 10 秒后自动尝试重新启动" && sleep 10 && ssserver_restart x
fi

ss_plugin_server_name="$(nvram get ss_plugin_server_name)"
[ ! -z "$ss_plugin_server_name" ] && { kill_ps "$ss_plugin_server_name" ; ss_plugin_server_name="" ; nvram set ss_plugin_server_name="" ; }

# 高级启动参数分割
ssserver_usage="$(usage_switch "$ssserver_usage")"

# 插件名称
ssserver_usage_custom="$(echo "$ssserver_usage" | grep -Eo '\-\-plugin[ ]+[^丨]+')"
if [ ! -z "$ssserver_usage_custom" ] ; then
	ss_plugin_name="$(echo $ssserver_usage_custom | sed -e "s@^--plugin@@g" | sed -e "s@ @@g")"
	logger -t "【SS_server】" "高级启动参数选项内容含有 --plugin $ss_plugin_name ，优先使用此 插件名称"
fi

# 插件参数
ssserver_usage_custom="$(echo "$ssserver_usage" | grep -Eo '\-\-plugin\-opts[ ]+[^丨]+')"
if [ ! -z "$ssserver_usage_custom" ] ; then 
	ss_plugin_config="$(echo $ssserver_usage_custom | sed -e "s@^--plugin-opts@@g" | sed -e "s@ @@g")"
	ss_plugin_config="$(echo $ss_plugin_config | sed -e 's@^"@@g' | sed -e 's@"$@@g')"
	logger -t "【SS_server】" "高级启动参数选项内容含有 --plugin-opts $ss_plugin_config ，优先使用此 插件参数"
fi

# 插件名称 插件参数 调整名称
[ ! -z "$(echo "$ss_plugin_name" | grep "simple-obfs")" ] && ss_plugin_name="obfs-server"
[ ! -z "$(echo "$ss_plugin_config" | grep "obfs-host")" ] && ss_plugin_name="obfs-server"
[ ! -z "$(echo "$ss_plugin_config" | grep "obfs=tls")" ] && ss_plugin_name="obfs-server"
[ ! -z "$(echo "$ss_plugin_config" | grep "obfs=http")" ] && ss_plugin_name="obfs-server"
[ ! -z "$(echo "$ss_plugin_name" | grep "GoQuiet")" ] && ss_plugin_name="gq-server"
[ ! -z "$(echo "$ss_plugin_name" | grep "goquiet")" ] && ss_plugin_name="gq-server"
[ ! -z "$(echo "$ss_plugin_name" | grep "kcptun")" ] && ss_plugin_name="ss_server_kcptun"
[ ! -z "$(echo "$ss_plugin_name" | grep "server_linux_mipsle")" ] && ss_plugin_name="ss_server_kcptun"
[ ! -z "$(echo "$ss_plugin_name" | grep "Cloak")" ] && ss_plugin_name="ck-server"
[ ! -z "$(echo "$ss_plugin_name" | grep "cloak")" ] && ss_plugin_name="ck-server"
[ ! -z "$(echo "$ss_plugin_name" | grep "v2ray")" ] && ss_plugin_name="v2ray-plugin"
[ ! -z "$(echo "$ss_plugin_name" | grep "V2ray")" ] && ss_plugin_name="v2ray-plugin"
[ ! -z "$ss_plugin_name" ] && { ss_plugin_server_name="$ss_plugin_name" ; nvram set ss_plugin_server_name="$ss_plugin_server_name" ; }
[ ! -z "$ss_plugin_server_name" ] && kill_ps "$ss_plugin_server_name"

# 删除混淆、协议、分割符号
options1="$(echo "$ssserver_usage" | sed -r 's/\ --plugin-opts[ ]+[^丨]+//g' | sed -r 's/\ --plugin[ ]+[^丨]+//g' | sed -e "s@丨@@g" | sed -e "s@  @ @g" | sed -e "s@  @ @g")"
# 高级启动参数分割完成
if [ ! -z "$ss_plugin_name" ] ; then
options1="$options1 --plugin $ss_plugin_name "
fi
if [ ! -z "$ss_plugin_config" ] ; then
options1="$options1 --plugin-opts $ss_plugin_config "
fi
options1="$(echo "$options1" | sed -e "s@  @ @g" | sed -e "s@  @ @g")"


optssredir="0"
if [ ! -z "$ss_plugin_name" ] ; then
	[ ! -z "$ss_plugin_name" ] && { hash $ss_plugin_name 2>/dev/null || optssredir="4" ; }
	if [ "$optssredir" != "0" ] ; then
		logger -t "【SS_server】" "找不到 /opt/bin/$ss_plugin_name，安装 opt 程序"
		/etc/storage/script/Sh01_mountopt.sh start
		initopt
	fi
	wgetcurl_file /opt/bin/$ss_plugin_name "$hiboyfile/$ss_plugin_name" "$hiboyfile2/$ss_plugin_name"
fi
logger -t "【SS_server】" "启动 ss-server 服务"
if [ "$ssserver_udp" == "1" ] ; then
	ssserver_udp_u="-u"
	logger -t "【SS_server】" "UDP转发可能会导致连接失败，如果连接失败，请关闭UDP转发再测试"
else
	ssserver_udp_u=""
fi
eval "ss-server -s 0.0.0.0 -s ::0 -p $ssserver_port -k $ssserver_password -m $ssserver_method -t $ssserver_time $ssserver_udp_u $options1 $cmd_log" &


sleep 4
[ ! -z "`pidof ss-server`" ] && logger -t "【SS_server】" "启动成功" && ssserver_restart o
[ -z "`pidof ss-server`" ] && logger -t "【SS_server】" "启动失败, 注意检查端口是否有冲突,程序是否下载完整, 10 秒后自动尝试重新启动" && sleep 10 && ssserver_restart x
logger -t "【SS_server】" "PID: `ps -w | grep ss-server | grep -v grep`"
logger -t "【SS_server】" "如果连接失败，请关闭UDP转发再测试"
ssserver_port_dpt
#ssserver_get_status
eval "$scriptfilepath keep &"
exit 0
}

usage_switch()
{

# 高级启动参数分割
echo -n "$1" \
 | sed -e 's@ -s @ 丨 -s @g' \
 | sed -e 's@ -p @ 丨 -p @g' \
 | sed -e 's@ -l @ 丨 -l @g' \
 | sed -e 's@ -k @ 丨 -k @g' \
 | sed -e 's@ -m @ 丨 -m @g' \
 | sed -e 's@ -a @ 丨 -a @g' \
 | sed -e 's@ -f @ 丨 -f @g' \
 | sed -e 's@ -t @ 丨 -t @g' \
 | sed -e 's@ -c @ 丨 -c @g' \
 | sed -e 's@ -n @ 丨 -n @g' \
 | sed -e 's@ -i @ 丨 -i @g' \
 | sed -e 's@ -b @ 丨 -b @g' \
 | sed -e 's@ -u @ 丨 -u @g' \
 | sed -e 's@ -U @ 丨 -U @g' \
 | sed -e 's@ -6 @ 丨 -6 @g' \
 | sed -e 's@ -d @ 丨 -d @g' \
 | sed -e 's@ --reuse-port @ 丨 --reuse-port @g' \
 | sed -e 's@ --fast-open @ 丨 --fast-open @g' \
 | sed -e 's@ --acl @ 丨 --acl @g' \
 | sed -e 's@ --mtu @ 丨 --mtu @g' \
 | sed -e 's@ --mptcp @ 丨 --mptcp @g' \
 | sed -e 's@ --no-delay @ 丨 --no-delay @g' \
 | sed -e 's@ --key @ 丨 --key @g' \
 | sed -e 's@ --plugin @ 丨 --plugin  @g' \
 | sed -e 's@ --plugin-opts @ 丨 --plugin-opts  @g' \
 | sed -e 's@ -v @@g' \
 | sed -e 's@ -h @@g' \
 | sed -e 's@ --help @@g' \
 | sed -e 's@ -o @ 丨 -o  @g' \
 | sed -e 's@ -O @ 丨 -O  @g' \
 | sed -e 's@ -g @ 丨 -g  @g' \
 | sed -e 's@ -G @ 丨 -G  @g'
 
}

initopt () {
optPath=`grep ' /opt ' /proc/mounts | grep tmpfs`
[ ! -z "$optPath" ] && return
if [ ! -z "$(echo $scriptfilepath | grep -v "/opt/etc/init")" ] && [ -s "/opt/etc/init.d/rc.func" ] ; then
	{ echo '#!/bin/sh' ; echo $scriptfilepath '"$@"' '&' ; } > /opt/etc/init.d/$scriptname && chmod 777  /opt/etc/init.d/$scriptname
fi

}

ssserver_port_dpt () {

ssserver_enable=`nvram get ssserver_enable`
if [ "$ssserver_enable" = "1" ] ; then
	ssserver_port=`nvram get ssserver_port`
		echo "ssserver_port:$ssserver_port"
	port=$(iptables -t filter -L INPUT -v -n --line-numbers | grep dpt:$ssserver_port | cut -d " " -f 1 | sort -nr | wc -l)
	if [ "$port" = 0 ] ; then
		logger -t "【SS_server】" "允许 $ssserver_port 端口通过防火墙"
		iptables -t filter -I INPUT -p tcp --dport $ssserver_port -j ACCEPT
		iptables -t filter -I INPUT -p udp --dport $ssserver_port -j ACCEPT
		ip6tables -t filter -I INPUT -p tcp --dport $ssserver_port -j ACCEPT
		ip6tables -t filter -I INPUT -p udp --dport $ssserver_port -j ACCEPT
	fi
fi

}

case $ACTION in
start)
	ssserver_close
	ssserver_check
	;;
check)
	ssserver_check
	;;
stop)
	ssserver_close
	;;
keep)
	#ssserver_check
	ssserver_keep
	;;
*)
	ssserver_check
	;;
esac


