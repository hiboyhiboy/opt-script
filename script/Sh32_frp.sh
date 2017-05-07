#!/bin/sh
#copyright by hiboy
source /etc/storage/script/init.sh
frp_enable=`nvram get frp_enable`
[ -z $frp_enable ] && frp_enable=0 && nvram set frp_enable=0
if [ "$frp_enable" != "0" ] ; then
nvramshow=`nvram showall | grep frp | awk '{print gensub(/'"'"'/,"'"'"'\"'"'"'\"'"'"'","g",$0);}'| awk '{print gensub(/=/,"='\''",1,$0)"'\'';";}'` && eval $nvramshow
fi

if [ ! -z "$(echo $scriptfilepath | grep -v "/tmp/script/" | grep frp)" ]  && [ ! -s /tmp/script/_frp ]; then
	mkdir -p /tmp/script
	ln -sf $scriptfilepath /tmp/script/_frp
	chmod 777 /tmp/script/_frp
fi

frp_check () {
A_restart=`nvram get frp_status`
B_restart="$frp_enable$frpc_enable$frps_enable$(cat /etc/storage/frp_script.sh | grep -v '^#' | grep -v "^$")"
B_restart=`echo -n "$B_restart" | md5sum | sed s/[[:space:]]//g | sed s/-//g`
if [ "$A_restart" != "$B_restart" ] ; then
nvram set frp_status=$B_restart
needed_restart=1
else
needed_restart=0
fi
if [ "$frp_enable" != "1" ] && [ "$needed_restart" = "1" ] ; then
	[ ! -z "`pidof frpc`" ] && logger -t "【frp】" "停止 frpc" && frp_close
	[ ! -z "`pidof frps`" ] && logger -t "【frp】" "停止 frps" && frp_close
	{ eval $(ps -w | grep "$scriptname" | grep -v grep | awk '{print "kill "$1";";}'); exit 0; }
fi
if [ "$frp_enable" = "1" ] ; then
	if [ "$needed_restart" = "1" ] ; then
		frp_close
		frp_start
	else
		[ "$frps_enable" = "1" ] && [ -z "`pidof frpc`" ] && nvram set frp_status=00 && { eval "$scriptfilepath start &"; exit 0; }
		[ "$frps_enable" = "1" ] && [ -z "`pidof frps`" ] && nvram set frp_status=00 && { eval "$scriptfilepath start &"; exit 0; }
	fi
fi
}

frp_keep () {

logger -t "【frp】" "守护进程启动"
if [ -s /tmp/script/_opt_script_check ]; then
sed -Ei '/【frp】|^$/d' /tmp/script/_opt_script_check
if [ "$frpc_enable" = "1" ] ; then
cat >> "/tmp/script/_opt_script_check" <<-OSC
[ -z "\`pidof frpc\`" ] || [ ! -s "`which frpc`" ] && nvram set frp_status=00 && logger -t "【frp】" "重新启动frpc" && eval "$scriptfilepath &" && sed -Ei '/【frp】|^$/d' /tmp/script/_opt_script_check # 【frp】
OSC
fi
if [ "$frps_enable" = "1" ] ; then
cat >> "/tmp/script/_opt_script_check" <<-OSC
[ -z "\`pidof frps\`" ] || [ ! -s "`which frps`" ] && nvram set frp_status=00 && logger -t "【frp】" "重新启动frps" && eval "$scriptfilepath &" && sed -Ei '/【frp】|^$/d' /tmp/script/_opt_script_check # 【frp】
OSC
fi
return
fi

while true; do
if [ "$frpc_enable" = "1" ] ; then
	if [ -z "`pidof frpc`" ] || [ ! -s "`which frpc`" ] ; then
		logger -t "【frp】" "frpc重新启动"
		{ nvram set frp_status=00 && eval "$scriptfilepath &" ; exit 0; }
	fi
fi
if [ "$frps_enable" = "1" ] ; then
	if [ -z "`pidof frps`" ] || [ ! -s "`which frps`" ] ; then
		logger -t "【frp】" "frps重新启动"
		{ nvram set frp_status=00 && eval "$scriptfilepath &" ; exit 0; }
	fi
fi
	sleep 232
done
}

frp_close () {
sed -Ei '/【frp】|^$/d' /tmp/script/_opt_script_check
killall frpc frps frp_script.sh
killall -9 frpc frps frp_script.sh
eval $(ps -w | grep "_frp keep" | grep -v grep | awk '{print "kill "$1";";}')
eval $(ps -w | grep "_frp.sh keep" | grep -v grep | awk '{print "kill "$1";";}')
eval $(ps -w | grep "$scriptname keep" | grep -v grep | awk '{print "kill "$1";";}')
}

frp_start () {
action_for=""
[ "$frpc_enable" = "1" ] && action_for="frpc"
[ "$frps_enable" = "1" ] && action_for=$action_for" frps"
for action_frp in $action_for
do
	SVC_PATH="/opt/bin/$action_frp"
	hash $action_frp 2>/dev/null || rm -rf /opt/bin/$action_frp
	if [ ! -s "$SVC_PATH" ] ; then
		logger -t "【frp】" "找不到 $SVC_PATH ，安装 opt 程序"
		/tmp/script/_mountopt start
		initopt
	fi
	if [ ! -s "$SVC_PATH" ] ; then
		logger -t "【frp】" "找不到 $SVC_PATH 下载程序"
		wgetcurl.sh /opt/bin/$action_frp "$hiboyfile/$action_frp" "$hiboyfile2/$action_frp"
		chmod 755 "/opt/bin/$action_frp"
	else
		logger -t "【frp】" "找到 $SVC_PATH"
	fi
	if [ ! -s "$SVC_PATH" ] ; then
		logger -t "【frp】" "找不到 $SVC_PATH ，需要手动安装 $SVC_PATH"
		logger -t "【frp】" "启动失败, 10 秒后自动尝试重新启动" && sleep 10 && { nvram set frp_status=00; eval "$scriptfilepath &"; exit 0; }
	fi
done

logger -t "【frp】" "运行 frp_script"
/etc/storage/frp_script.sh
restart_dhcpd
sleep 2
if [ "$frpc_enable" = "1" ] ; then
	frpc_v="`/opt/bin/frpc --version`"
	nvram set frpc_v=$frpc_v
	logger -t "【frp】" "frpc-version: $frpc_v"
	[ ! -z "`pidof frpc`" ] && logger -t "【frp】" "frpc启动成功"
	[ -z "`pidof frpc`" ] && logger -t "【frp】" "frpc启动失败, 注意检查端口是否有冲突,程序是否下载完整,10 秒后自动尝试重新启动" && sleep 10 && { nvram set frp_status=00; eval "$scriptfilepath &"; exit 0; }
fi
if [ "$frps_enable" = "1" ] ; then
	frps_v="`/opt/bin/frps --version`"
	nvram set frps_v=$frps_v
	logger -t "【frp】" "frps-version: $frps_v"
	[ ! -z "`pidof frps`" ] && logger -t "【frp】" "frps启动成功"
	[ -z "`pidof frps`" ] && logger -t "【frp】" "frps启动失败, 注意检查端口是否有冲突,程序是否下载完整,10 秒后自动尝试重新启动" && sleep 10 && { nvram set frp_status=00; eval "$scriptfilepath &"; exit 0; }
fi
eval "$scriptfilepath keep &"
}

initopt () {
optPath=`grep ' /opt ' /proc/mounts | grep tmpfs`
[ ! -z "$optPath" ] && return
if [ -s "/opt/etc/init.d/rc.func" ] ; then
	cp -Hf "$scriptfilepath" "/opt/etc/init.d/$scriptname"
fi

}

case $ACTION in
start)
	frp_close
	frp_check
	;;
check)
	frp_check
	;;
stop)
	frp_close
	;;
keep)
	frp_check
	frp_keep
	;;
updatefrp)
	[ "$frp_enable" = "1" ] && nvram set frp_status="updatefrp" && logger -t "【frp】" "重启" && { nvram set frp_status=00 && eval "$scriptfilepath start &"; exit 0; }
	[ "$frp_enable" != "1" ] && nvram set frpc_v="" && nvram set frps_v="" && logger -t "【frp】" "frpc、frps更新" && rm -rf /opt/bin/frpc /opt/bin/frps
	;;
*)
	frp_check
	;;
esac

