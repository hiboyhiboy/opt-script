#!/bin/sh
#copyright by hiboy
source /etc/storage/script/init.sh
ngrok_enable=`nvram get ngrok_enable`
[ -z $ngrok_enable ] && ngrok_enable=0 && nvram set ngrok_enable=0
if [ "$ngrok_enable" != "0" ] ; then
nvramshow=`nvram showall | grep '=' | grep ngrok | awk '{print gensub(/'"'"'/,"'"'"'\"'"'"'\"'"'"'","g",$0);}'| awk '{print gensub(/=/,"='\''",1,$0)"'\'';";}'` && eval $nvramshow
fi

if [ ! -z "$(echo $scriptfilepath | grep -v "/tmp/script/" | grep ngrok)" ]  && [ ! -s /tmp/script/_ngrok ]; then
	mkdir -p /tmp/script
	{ echo '#!/bin/sh' ; echo $scriptfilepath '"$@"' '&' ; } > /tmp/script/_ngrok
	chmod 777 /tmp/script/_ngrok
fi

ngrok_restart () {

relock="/var/lock/ngrok_restart.lock"
if [ "$1" = "o" ] ; then
	nvram set ngrok_renum="0"
	[ -f $relock ] && rm -f $relock
	return 0
fi
if [ "$1" = "x" ] ; then
	if [ -f $relock ] ; then
		logger -t "【ngrok】" "多次尝试启动失败，等待【"`cat $relock`"分钟】后自动尝试重新启动"
		exit 0
	fi
	ngrok_renum=${ngrok_renum:-"0"}
	ngrok_renum=`expr $ngrok_renum + 1`
	nvram set ngrok_renum="$ngrok_renum"
	if [ "$ngrok_renum" -gt "2" ] ; then
		I=19
		echo $I > $relock
		logger -t "【ngrok】" "多次尝试启动失败，等待【"`cat $relock`"分钟】后自动尝试重新启动"
		while [ $I -gt 0 ]; do
			I=$(($I - 1))
			echo $I > $relock
			sleep 60
			[ "$(nvram get ngrok_renum)" = "0" ] && exit 0
			[ $I -lt 0 ] && break
		done
		nvram set ngrok_renum="0"
	fi
	[ -f $relock ] && rm -f $relock
fi
nvram set ngrok_status=0
eval "$scriptfilepath &"
exit 0
}

ngrok_get_status () {

A_restart=`nvram get ngrok_status`
B_restart="$ngrok_enable$ngrok_server$ngrok_port$ngrok_token$ngrok_domain$ngrok_domain_type$ngrok_domain_lhost$ngrok_domain_lport$ngrok_domain_sdname$ngrok_tcp$ngrok_tcp_type$ngrok_tcp_lhost$ngrok_tcp_lport$ngrok_tcp_rport$ngrok_custom$ngrok_custom_type$ngrok_custom_lhost$ngrok_custom_lport$ngrok_custom_hostname$(cat /etc/storage/ngrok_script.sh | grep -v '^#' | grep -v "^$")"
B_restart=`echo -n "$B_restart" | md5sum | sed s/[[:space:]]//g | sed s/-//g`
if [ "$A_restart" != "$B_restart" ] ; then
	nvram set ngrok_status=$B_restart
	needed_restart=1
else
	needed_restart=0
fi
}

ngrok_check () {

ngrok_get_status
if [ "$ngrok_enable" != "1" ] && [ "$needed_restart" = "1" ] ; then
	[ ! -z "`pidof ngrokc`" ] && logger -t "【ngrok】" "停止 ngrok" && ngrok_close
	{ eval $(ps -w | grep "$scriptname" | grep -v grep | awk '{print "kill "$1";";}'); exit 0; }
fi
if [ "$ngrok_enable" = "1" ] ; then
	if [ "$needed_restart" = "1" ] ; then
		ngrok_close
		ngrok_start
	else
		[ -z "`pidof ngrokc`" ] && ngrok_restart
	fi
fi
}

ngrok_keep () {

logger -t "【ngrok】" "守护进程启动"
if [ -s /tmp/script/_opt_script_check ]; then
sed -Ei '/【ngrok】|^$/d' /tmp/script/_opt_script_check
cat >> "/tmp/script/_opt_script_check" <<-OSC
[ -z "\`pidof ngrokc\`" ] || [ ! -s "`which ngrokc`" ] && nvram set ngrok_status=00 && logger -t "【ngrok】" "重新启动" && eval "$scriptfilepath &" && sed -Ei '/【ngrok】|^$/d' /tmp/script/_opt_script_check # 【ngrok】
OSC
return
fi
while true; do
	if [ -z "`pidof ngrokc`" ] || [ ! -s "`which ngrokc`" ] ; then
		logger -t "【ngrok】" "重新启动"
		ngrok_restart
	fi
sleep 233
done
}

ngrok_close () {
sed -Ei '/【ngrok】|^$/d' /tmp/script/_opt_script_check
killall ngrokc ngrok_script.sh
killall -9 ngrokc ngrok_script.sh
eval $(ps -w | grep "_ngrok keep" | grep -v grep | awk '{print "kill "$1";";}')
eval $(ps -w | grep "_ngrok.sh keep" | grep -v grep | awk '{print "kill "$1";";}')
eval $(ps -w | grep "$scriptname keep" | grep -v grep | awk '{print "kill "$1";";}')
}

ngrok_start () {
SVC_PATH="/usr/bin/ngrokc"
if [ ! -s "$SVC_PATH" ] ; then
	SVC_PATH="/opt/bin/ngrokc"
fi
hash ngrokc 2>/dev/null || rm -rf /opt/bin/ngrokc
if [ ! -s "$SVC_PATH" ] ; then
	logger -t "【ngrok】" "找不到 $SVC_PATH，安装 opt 程序"
	/tmp/script/_mountopt start
	initopt
fi
if [ ! -s "$SVC_PATH" ] ; then
	logger -t "【ngrok】" "找不到 $SVC_PATH 下载程序"
	wgetcurl.sh /opt/bin/ngrokc "$hiboyfile/ngrokc" "$hiboyfile2/ngrokc"
	chmod 755 "/opt/bin/ngrokc"
else
	logger -t "【ngrok】" "找到 $SVC_PATH"
fi
if [ ! -s "$SVC_PATH" ] ; then
	logger -t "【ngrok】" "找不到 $SVC_PATH ，需要手动安装 $SVC_PATH"
	logger -t "【ngrok】" "启动失败, 10 秒后自动尝试重新启动" && sleep 10 && ngrok_restart x
fi
logger -t "【ngrokc】" "运行 ngrok_script"
sed -Ei '/UI设置自动生成/d' /etc/storage/ngrok_script.sh
sed -Ei '/^$/d' /etc/storage/ngrok_script.sh
# 系统分配域名
if [ "$ngrok_domain" = "1" ] ; then
cat >> "/etc/storage/ngrok_script.sh" <<-EUI
ngrokc -SER[Shost:$ngrok_server,Sport:$ngrok_port,Atoken:$ngrok_token] -AddTun[Type:$ngrok_domain_type,Lhost:$ngrok_domain_lhost,Lport:$ngrok_domain_lport,Sdname:$ngrok_domain_sdname] & #UI设置自动生成
EUI
fi
# TCP端口转发
if [ "$ngrok_tcp" = "1" ] ; then
cat >> "/etc/storage/ngrok_script.sh" <<-EUI
ngrokc -SER[Shost:$ngrok_server,Sport:$ngrok_port,Atoken:$ngrok_token] -AddTun[Type:$ngrok_tcp_type,Lhost:$ngrok_tcp_lhost,Lport:$ngrok_tcp_lport,Rport:$ngrok_tcp_rport] & #UI设置自动生成
EUI
fi
# 自定义域名
if [ "$ngrok_custom" = "1" ] ; then
cat >> "/etc/storage/ngrok_script.sh" <<-EUI
ngrokc -SER[Shost:$ngrok_server,Sport:$ngrok_port,Atoken:$ngrok_token] -AddTun[Type:$ngrok_custom_type,Lhost:$ngrok_custom_lhost,Lport:$ngrok_custom_lport,Hostname:$ngrok_custom_hostname] & #UI设置自动生成
EUI
fi
/etc/storage/ngrok_script.sh
restart_dhcpd
sleep 2
[ ! -z "`pidof ngrokc`" ] && logger -t "【ngrok】" "启动成功" && ngrok_restart o
[ -z "`pidof ngrokc`" ] && logger -t "【ngrok】" "启动失败, 注意检查端口是否有冲突,程序是否下载完整,10 秒后自动尝试重新启动" && sleep 10 && ngrok_restart x
ngrok_get_status
eval "$scriptfilepath keep &"
}

initopt () {
optPath=`grep ' /opt ' /proc/mounts | grep tmpfs`
[ ! -z "$optPath" ] && return
if [ -z "$(echo $scriptfilepath | grep "/tmp/script/")" ] && [ -s "/opt/etc/init.d/rc.func" ] ; then
	cp -Hf "$scriptfilepath" "/opt/etc/init.d/$scriptname"
fi

}

case $ACTION in
start)
	ngrok_close
	ngrok_check
	;;
check)
	ngrok_check
	;;
stop)
	ngrok_close
	;;
keep)
	#ngrok_check
	ngrok_keep
	;;
*)
	ngrok_check
	;;
esac

