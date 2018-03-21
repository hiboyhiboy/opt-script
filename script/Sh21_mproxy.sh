#!/bin/sh
#copyright by hiboy
source /etc/storage/script/init.sh
mproxyport=`nvram get mproxyport`
mproxy_enable=`nvram get mproxy_enable`
[ -z $mproxy_enable ] && mproxy_enable=0 && nvram set mproxy_enable=0
if [ "$mproxy_enable" != "0" ] ; then
#nvramshow=`nvram showall | grep '=' | grep mproxy | awk '{print gensub(/'"'"'/,"'"'"'\"'"'"'\"'"'"'","g",$0);}'| awk '{print gensub(/=/,"='\''",1,$0)"'\'';";}'` && eval $nvramshow
mproxy_port=`nvram get mproxy_port`
fi

if [ ! -z "$(echo $scriptfilepath | grep -v "/tmp/script/" | grep mproxy)" ]  && [ ! -s /tmp/script/_mproxy ]; then
	mkdir -p /tmp/script
	{ echo '#!/bin/sh' ; echo $scriptfilepath '"$@"' '&' ; } > /tmp/script/_mproxy
	chmod 777 /tmp/script/_mproxy
fi

mproxy_restart () {

relock="/var/lock/mproxy_restart.lock"
if [ "$1" = "o" ] ; then
	nvram set mproxy_renum="0"
	[ -f $relock ] && rm -f $relock
	return 0
fi
if [ "$1" = "x" ] ; then
	if [ -f $relock ] ; then
		logger -t "【mproxy】" "多次尝试启动失败，等待【"`cat $relock`"分钟】后自动尝试重新启动"
		exit 0
	fi
	mproxy_renum=${mproxy_renum:-"0"}
	mproxy_renum=`expr $mproxy_renum + 1`
	nvram set mproxy_renum="$mproxy_renum"
	if [ "$mproxy_renum" -gt "2" ] ; then
		I=19
		echo $I > $relock
		logger -t "【mproxy】" "多次尝试启动失败，等待【"`cat $relock`"分钟】后自动尝试重新启动"
		while [ $I -gt 0 ]; do
			I=$(($I - 1))
			echo $I > $relock
			sleep 60
			[ "$(nvram get mproxy_renum)" = "0" ] && exit 0
			[ $I -lt 0 ] && break
		done
		nvram set mproxy_renum="0"
	fi
	[ -f $relock ] && rm -f $relock
fi
nvram set mproxy_status=0
eval "$scriptfilepath &"
exit 0
}

mproxy_get_status () {

A_restart=`nvram get mproxy_status`
B_restart="$mproxy_enable$mproxy_port$(cat /etc/storage/mproxy_script.sh | grep -v '^#' | grep -v "^$")"
B_restart=`echo -n "$B_restart" | md5sum | sed s/[[:space:]]//g | sed s/-//g`
if [ "$A_restart" != "$B_restart" ] ; then
	nvram set mproxy_status=$B_restart
	needed_restart=1
else
	needed_restart=0
fi
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
logger -t "【mproxy】" "守护进程启动"
if [ -s /tmp/script/_opt_script_check ]; then
sed -Ei '/【mproxy】|^$/d' /tmp/script/_opt_script_check
cat >> "/tmp/script/_opt_script_check" <<-OSC
[ -z "\`pidof mproxy\`" ] || [ ! -s "`which mproxy`" ] && nvram set mproxy_status=00 && logger -t "【mproxy】" "重新启动" && eval "$scriptfilepath &" && sed -Ei '/【mproxy】|^$/d' /tmp/script/_opt_script_check # 【mproxy】
OSC
return
fi
while true; do
	if [ -z "`pidof mproxy`" ] || [ ! -s "`which mproxy`" ] ; then
		logger -t "【mproxy】" "重新启动"
		mproxy_restart
	fi
sleep 221
done
}

mproxy_close () {

sed -Ei '/【mproxy】|^$/d' /tmp/script/_opt_script_check
mproxyport=$(echo `cat /etc/storage/mproxy_script.sh | grep -v "^#" | grep "mproxy_port=" | sed 's/mproxy_port=//'`)
[ ! -z "$mproxyport" ] && iptables -t filter -D INPUT -p tcp --dport $mproxyport -j ACCEPT
killall mproxy mproxy_script.sh
killall -9 mproxy mproxy_script.sh
kill_ps "/tmp/script/_mproxy"
kill_ps "_mproxy.sh"
kill_ps "$scriptname"
}

mproxy_start () {
SVC_PATH="/usr/sbin/mproxy"
if [ ! -s "$SVC_PATH" ] ; then
	SVC_PATH="/etc/storage/bin/mproxy"
fi
if [ ! -s "$SVC_PATH" ] ; then
	SVC_PATH="/usr/sbin/mproxy"
fi
if [ ! -s "$SVC_PATH" ] ; then
	SVC_PATH="/opt/bin/mproxy"
fi
chmod 777 "$SVC_PATH"
[[ "$(mproxy -h | wc -l)" -lt 2 ]] && rm -rf /opt/bin/mproxy
if [ ! -s "$SVC_PATH" ] ; then
	logger -t "【mproxy】" "找不到 mproxy，安装 opt 程序"
	/tmp/script/_mountopt start
	initopt
fi
if [ ! -s "$SVC_PATH" ] ; then
	logger -t "【mproxy】" "找不到 $SVC_PATH 下载程序"
	wgetcurl.sh /opt/bin/mproxy "$hiboyfile/mproxy" "$hiboyfile2/mproxy"
	chmod 755 "/opt/bin/mproxy"
else
	logger -t "【mproxy】" "找到 $SVC_PATH"
fi
if [ ! -s "$SVC_PATH" ] ; then
	logger -t "【mproxy】" "找不到 $SVC_PATH ，需要手动安装 $SVC_PATH"
	logger -t "【mproxy】" "启动失败, 10 秒后自动尝试重新启动" && sleep 10 && mproxy_restart x
fi
logger -t "【mproxy】" "运行 mproxy_script"
/etc/storage/mproxy_script.sh &
restart_dhcpd
sleep 2
[ ! -z "`pidof mproxy`" ] && logger -t "【mproxy】" "启动成功" && mproxy_restart o
[ -z "`pidof mproxy`" ] && logger -t "【mproxy】" "启动失败, 注意检查端口是否有冲突,程序是否下载完整, 10 秒后自动尝试重新启动" && sleep 10 && mproxy_restart x
mproxy_port_dpt
#mproxy_get_status
eval "$scriptfilepath keep &"
}

initopt () {
optPath=`grep ' /opt ' /proc/mounts | grep tmpfs`
[ ! -z "$optPath" ] && return
if [ ! -z "$(echo $scriptfilepath | grep -v "/opt/etc/init")" ] && [ -s "/opt/etc/init.d/rc.func" ] ; then
	{ echo '#!/bin/sh' ; echo $scriptfilepath '"$@"' '&' ; } > /opt/etc/init.d/$scriptname && chmod 777  /opt/etc/init.d/$scriptname
fi

}

initconfig () {

config_mproxy="/etc/storage/mproxy_script.sh"
if [ ! -f "$config_mproxy" ] || [ ! -s "$config_mproxy" ] ; then
		cat > "$config_mproxy" <<-\END
#!/bin/sh
killall -9 mproxy
logger -t "【mproxy】" "运行 mproxy"
# 使用方法：https://github.com/examplecode/mproxy
# 本地监听端口
mproxy_port=8000

# 删除（#）启用指定选项
# 默认作为普通的代理服务器。
mproxy -l $mproxy_port -d &



# 在远程服务器启动mproxy作为远程代理
# 在远程作为加密代传输方式理服务器
# mproxy  -l 8081 -D -d &


# 本地启动 mproxy 作为本地代理，并指定传输方式加密。
# 在本地启动一个mporxy 并指定目上一步在远程部署的服务器地址和端口号。
# mproxy  -l 8080 -h xxx.xxx.xxx.xxx:8081 -E &


END
fi
chmod 777 "$config_mproxy"

}

initconfig

mproxy_port_dpt () {

if [ "$mproxy_port" = "1" ] ; then
	mproxyport=$(echo `cat /etc/storage/mproxy_script.sh | grep -v "^#" | grep "mproxy_port=" | sed 's/mproxy_port=//'`)
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

