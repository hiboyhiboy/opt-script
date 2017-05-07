#!/bin/sh
#copyright by hiboy
source /etc/storage/script/init.sh
ssrserver_enable=`nvram get ssrserver_enable`
[ -z $ssrserver_enable ] && ssrserver_enable=0 && nvram set ssrserver_enable=0
if [ "$ssrserver_enable" != "0" ] ; then
nvramshow=`nvram showall | grep ssrserver | awk '{print gensub(/'"'"'/,"'"'"'\"'"'"'\"'"'"'","g",$0);}'| awk '{print gensub(/=/,"='\''",1,$0)"'\'';";}'` && eval $nvramshow
fi

if [ ! -z "$(echo $scriptfilepath | grep -v "/tmp/script/" | grep ssrserver)" ]  && [ ! -s /tmp/script/_ssrserver ]; then
	mkdir -p /tmp/script
	ln -sf $scriptfilepath /tmp/script/_ssrserver
	chmod 777 /tmp/script/_ssrserver
fi

ssrserver_check () {
A_restart=`nvram get ssrserver_status`
B_restart="$ssrserver_enable$ssrserver_update$(cat /etc/storage/SSRconfig_script.sh | grep -v "^$")"
B_restart=`echo -n "$B_restart" | md5sum | sed s/[[:space:]]//g | sed s/-//g`
if [ "$A_restart" != "$B_restart" ] ; then
	nvram set ssrserver_status=$B_restart
	needed_restart=1
else
	needed_restart=0
fi
if [ "$ssrserver_enable" != "1" ] && [ "$needed_restart" = "1" ] ; then
	[ ! -z "`ps -w | grep manyuser/shadowsocks/server | grep -v grep `" ] && logger -t "【SSR_server】" "停止 ssrserver" && ssrserver_close
	{ eval $(ps -w | grep "$scriptname" | grep -v grep | awk '{print "kill "$1";";}'); exit 0; }
fi
if [ "$ssrserver_enable" = "1" ] ; then
	if [ "$needed_restart" = "1" ] ; then
		ssrserver_close
		ssrserver_start
	else
		[ -z "`ps -w | grep manyuser/shadowsocks/server | grep -v grep `" ] || [ ! -s "`which python`" ] && nvram set ssrserver_status=00 && { eval "$scriptfilepath start &"; exit 0; }
	fi
fi
}

ssrserver_keep () {
logger -t "【SSR_server】" "守护进程启动"
if [ -s /tmp/script/_opt_script_check ]; then
sed -Ei '/【SSR_server】|^$/d' /tmp/script/_opt_script_check
cat >> "/tmp/script/_opt_script_check" <<-OSC
	NUM=\`grep "manyuser/shadowsocks/server" /tmp/ps | grep -v grep |wc -l\` # 【SSR_server】
	if [ "\$NUM" -lt "1" ] || [ ! -s "`which python`" ] ; then # 【SSR_server】
		logger -t "【SSR_server】" "重新启动\$NUM" # 【SSR_server】
		nvram set ssrserver_status=00 && eval "$scriptfilepath &" && sed -Ei '/【SSR_server】|^$/d' /tmp/script/_opt_script_check # 【SSR_server】
	fi # 【SSR_server】
OSC
return
fi

while true; do
	NUM=`ps -w | grep "manyuser/shadowsocks/server" | grep -v grep |wc -l`
	if [ "$NUM" -lt "1" ] || [ "$NUM" -gt "1" ] || [ ! -s "`which python`" ] ; then
		logger -t "【SSR_server】" "重新启动$NUM"
		{ nvram set ssrserver_status=00 && eval "$scriptfilepath &" ; exit 0; }
	fi
sleep 247
done
}

ssrserver_close () {
sed -Ei '/【SSR_server】|^$/d' /tmp/script/_opt_script_check
eval $(ps -w | grep "manyuser/shadowsocks/server" | grep -v grep | awk '{print "kill "$1";";}')
eval $(ps -w | grep "_ssrserver keep" | grep -v grep | awk '{print "kill "$1";";}')
eval $(ps -w | grep "_ssrserver.sh keep" | grep -v grep | awk '{print "kill "$1";";}')
eval $(ps -w | grep "$scriptname keep" | grep -v grep | awk '{print "kill "$1";";}')
}

ssrserver_start () {
ss_opt_x=`nvram get ss_opt_x`
upanPath=""
[ "$ss_opt_x" = "3" ] && upanPath="`df -m | grep /dev/mmcb | grep "/media" | awk '{print $NF}' | awk 'NR==1' `"
[ "$ss_opt_x" = "4" ] && upanPath="`df -m | grep "/dev/sd" | grep "/media" | awk '{print $NF}' | awk 'NR==1' `"
[ -z "$upanPath" ] && [ "$ss_opt_x" = "1" ] && upanPath="`df -m | grep /dev/mmcb | grep "/media" | awk '{print $NF}' | awk 'NR==1' `"
[ -z "$upanPath" ] && [ "$ss_opt_x" = "1" ] && upanPath="`df -m | grep "/dev/sd" | grep "/media" | awk '{print $NF}' | awk 'NR==1' `"
echo "$upanPath"
if [ -z "$upanPath" ] ; then 
	logger -t "【SSR_server】" "未挂载储存设备, 请重新检查配置、目录，10 秒后自动尝试重新启动"
	sleep 10
	nvram set ssrserver_status=00 && eval "$scriptfilepath &"
	exit 0
fi

SVC_PATH=/opt/bin/python
hash python 2>/dev/null || rm -rf /opt/bin/python /opt/opti.txt
if [ ! -s "$SVC_PATH" ] ; then
	logger -t "【SSR_server】" "找不到 $SVC_PATH，安装 opt 程序"
	/tmp/script/_mountopt optwget
fi
if [ -s "$SVC_PATH" ] ; then
	logger -t "【SSR_server】" "找到 $SVC_PATH"
else
	logger -t "【SSR_server】" "找不到 $SVC_PATH ，需要手动安装 $SVC_PATH"
	logger -t "【SSR_server】" "启动失败, 10 秒后自动尝试重新启动" && sleep 10 && { nvram set ssrserver_status=00; eval "$scriptfilepath &"; exit 0; }
fi
hash python 2>/dev/null || {  logger -t "【SSR_server】" "无法运行 python 程序，请检查系统，10 秒后自动尝试重新启动" ; sleep 10 ; nvram set ssrserver_status=00 ; eval "$scriptfilepath &" ; exit 1; }
mv -f /opt/shadowsocks-manyuser /opt/shadowsocksr-manyuser
if [ "$ssrserver_update" != "0" ] ; then
logger -t "【SSR_server】" "SSR_server 检测更新"
	rm -rf /opt/shadowsocksr-manyuser/shadowsocks/crypto/utilb
	wgetcurl.sh /opt/shadowsocksr-manyuser/shadowsocks/crypto/utilb "$hiboyfile/util.py" "$hiboyfile2/util.py"
	wgetcurl.sh /opt/shadowsocksr-manyuser/shadowsocks/crypto/utilc "$hiboyfile/util_code.py" "$hiboyfile2/util_code.py"
	A_util=`cat /opt/shadowsocksr-manyuser/shadowsocks/crypto/util.py`
	B_util=`cat /opt/shadowsocksr-manyuser/shadowsocks/crypto/utilb`
	C_util=`cat /opt/shadowsocksr-manyuser/shadowsocks/crypto/utilc`
	A_util=`echo -n "$A_util" | md5sum | sed s/[[:space:]]//g | sed s/-//g`
	B_util=`echo -n "$B_util" | md5sum | sed s/[[:space:]]//g | sed s/-//g`
	C_util=`echo -n "$C_util" | md5sum | sed s/[[:space:]]//g | sed s/-//g`
	if [ "$A_util" != "$B_util" ] && [ "$ssrserver_update" = "1" ] ; then
		logger -t "【SSR_server】" "SSR_server github.com需要更新"
		logger -t "【SSR_server】" "下载:https://github.com/breakwa11/shadowsocks/archive/manyuser.zip"
		rm -rf /opt/manyuser.zip
		wgetcurl.sh /opt/manyuser.zip https://github.com/breakwa11/shadowsocks/archive/manyuser.zip
		unzip -o /opt/manyuser.zip  -d /opt/
		rm -rf /opt/shadowsocksr-manyuser/shadowsocks/crypto/util.py
		cp -a /opt/shadowsocksr-manyuser/shadowsocks/crypto/utilb /opt/shadowsocksr-manyuser/shadowsocks/crypto/util.py
		logger -t "【SSR_server】" "SSR_server github.com更新完成"
	else
		logger -t "【SSR_server】" "SSR_server github.com暂时没更新"
	fi
	if [ "$A_util" != "$C_util" ] && [ "$ssrserver_update" = "2" ] ; then
		logger -t "【SSR_server】" "SSR_server code需要更新"
		logger -t "【SSR_server】" "下载:$hiboyfile/manyuser.zip"
		rm -rf /opt/manyuser.zip
		wgetcurl.sh /opt/manyuser.zip "$hiboyfile/manyuser.zip" "$hiboyfile2/manyuser.zip"
		unzip -o /opt/manyuser.zip  -d /opt/
		rm -rf /opt/shadowsocksr-manyuser/shadowsocks/crypto/util.py
		cp -a /opt/shadowsocksr-manyuser/shadowsocks/crypto/utilc /opt/shadowsocksr-manyuser/shadowsocks/crypto/util.py
		logger -t "【SSR_server】" "SSR_server code更新完成"
	else
		logger -t "【SSR_server】" "SSR_server code暂时没更新"
	fi
fi
logger -t "【SSR_server】" "启动 SSR_server 服务"
rm -rf /opt/shadowsocksr-manyuser/user-config.json
cp -a /etc/storage/SSRconfig_script.sh /opt/shadowsocksr-manyuser/user-config.json
if [ -s "/opt/shadowsocksr-manyuser/user-config.json" ] ; then
	chmod 777 -R /opt/shadowsocksr-manyuser
	cd /opt/shadowsocksr-manyuser/shadowsocks/
	python /opt/shadowsocksr-manyuser/shadowsocks/server.py a >> /tmp/syslog.log 2>&1 &
	logger -t "【SSR_server】" "请手动配置【外部网络 - 端口转发 - 启用手动端口映射】来开启WAN访问."
else
	logger -t "【SSR_server】" "/etc/storage/SSRconfig_script.sh 配置写入/opt/shadowsocksr-manyuser/user-config.json 失败，10 秒后自动尝试重新启动" && sleep 10 && { nvram set ssrserver_status=00; eval "$scriptfilepath &"; exit 0; }
	
fi
sleep 2
[ ! -z "$(ps -w | grep manyuser/shadowsocks/server | grep -v grep )" ] && logger -t "【SSR_server】" "启动成功"
[ -z "$(ps -w | grep manyuser/shadowsocks/server | grep -v grep )" ] && logger -t "【SSR_server】" "启动失败, 注意检查端口是否有冲突,程序是否下载完整,10 秒后自动尝试重新启动" && sleep 10 && { nvram set ssrserver_status=00; eval "$scriptfilepath &"; exit 0; }
initopt
eval "$scriptfilepath keep &"
}

initopt () {
optPath=`grep ' /opt ' /proc/mounts | grep tmpfs`
[ ! -z "$optPath" ] && return
optw_enable=`nvram get optw_enable`
if [ "$optw_enable" != "2" ] ; then
	nvram set optw_enable=2
fi
if [ -s "/opt/etc/init.d/rc.func" ] ; then
	cp -Hf "$scriptfilepath" "/opt/etc/init.d/$scriptname"
fi

}

case $ACTION in
start)
	ssrserver_close
	ssrserver_check
	;;
check)
	ssrserver_check
	;;
stop)
	ssrserver_close
	;;
keep)
	ssrserver_check
	ssrserver_keep
	;;
*)
	ssrserver_check
	;;
esac






