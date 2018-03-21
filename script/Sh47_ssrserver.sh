#!/bin/sh
#copyright by hiboy
source /etc/storage/script/init.sh
ssrserver_enable=`nvram get ssrserver_enable`
[ -z $ssrserver_enable ] && ssrserver_enable=0 && nvram set ssrserver_enable=0
if [ "$ssrserver_enable" != "0" ] ; then
#nvramshow=`nvram showall | grep '=' | grep ssrserver | awk '{print gensub(/'"'"'/,"'"'"'\"'"'"'\"'"'"'","g",$0);}'| awk '{print gensub(/=/,"='\''",1,$0)"'\'';";}'` && eval $nvramshow

ssrserver_update=`nvram get ssrserver_update`

fi

if [ ! -z "$(echo $scriptfilepath | grep -v "/tmp/script/" | grep ssrserver)" ]  && [ ! -s /tmp/script/_ssrserver ]; then
	mkdir -p /tmp/script
	{ echo '#!/bin/sh' ; echo $scriptfilepath '"$@"' '&' ; } > /tmp/script/_ssrserver
	chmod 777 /tmp/script/_ssrserver
fi

ssrserver_restart () {

relock="/var/lock/ssrserver_restart.lock"
if [ "$1" = "o" ] ; then
	nvram set ssrserver_renum="0"
	[ -f $relock ] && rm -f $relock
	return 0
fi
if [ "$1" = "x" ] ; then
	if [ -f $relock ] ; then
		logger -t "【ssrserver】" "多次尝试启动失败，等待【"`cat $relock`"分钟】后自动尝试重新启动"
		exit 0
	fi
	ssrserver_renum=${ssrserver_renum:-"0"}
	ssrserver_renum=`expr $ssrserver_renum + 1`
	nvram set ssrserver_renum="$ssrserver_renum"
	if [ "$ssrserver_renum" -gt "2" ] ; then
		I=19
		echo $I > $relock
		logger -t "【ssrserver】" "多次尝试启动失败，等待【"`cat $relock`"分钟】后自动尝试重新启动"
		while [ $I -gt 0 ]; do
			I=$(($I - 1))
			echo $I > $relock
			sleep 60
			[ "$(nvram get ssrserver_renum)" = "0" ] && exit 0
			[ $I -lt 0 ] && break
		done
		nvram set ssrserver_renum="0"
	fi
	[ -f $relock ] && rm -f $relock
fi
nvram set ssrserver_status=0
eval "$scriptfilepath &"
exit 0
}

ssrserver_get_status () {

A_restart=`nvram get ssrserver_status`
B_restart="$ssrserver_enable$ssrserver_update$(cat /etc/storage/SSRconfig_script.sh | grep -v "^#" | grep -v "^$")"
B_restart=`echo -n "$B_restart" | md5sum | sed s/[[:space:]]//g | sed s/-//g`
if [ "$A_restart" != "$B_restart" ] ; then
	nvram set ssrserver_status=$B_restart
	needed_restart=1
else
	needed_restart=0
fi
}

ssrserver_check () {

ssrserver_get_status
if [ "$ssrserver_enable" != "1" ] && [ "$needed_restart" = "1" ] ; then
	[ ! -z "`ps -w | grep manyuser/shadowsocks/server | grep -v grep `" ] && logger -t "【SSR_server】" "停止 ssrserver" && ssrserver_close
	{ kill_ps "$scriptname" exit0; exit 0; }
fi
if [ "$ssrserver_enable" = "1" ] ; then
	if [ "$needed_restart" = "1" ] ; then
		ssrserver_close
		ssrserver_start
	else
		[ -z "`ps -w | grep manyuser/shadowsocks/server | grep -v grep `" ] || [ ! -s "`which python`" ] && ssrserver_restart
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
		ssrserver_restart
	fi
sleep 247
done
}

ssrserver_close () {
sed -Ei '/【SSR_server】|^$/d' /tmp/script/_opt_script_check
iptables -t filter -D INPUT -p tcp --dport $ssserver_port -j ACCEPT
iptables -t filter -D INPUT -p udp --dport $ssserver_port -j ACCEPT
kill_ps "manyuser/shadowsocks/server"
kill_ps "/tmp/script/_ssrserver"
kill_ps "_ssrserver.sh"
kill_ps "$scriptname"
}

ssrserver_start () {
ss_opt_x=`nvram get ss_opt_x`
upanPath=""
[ "$ss_opt_x" = "3" ] && upanPath="`df -m | grep /dev/mmcb | grep "/media" | awk '{print $NF}' | sort -u | awk 'NR==1' `"
[ "$ss_opt_x" = "4" ] && upanPath="`df -m | grep "/dev/sd" | grep "/media" | awk '{print $NF}' | sort -u | awk 'NR==1' `"
[ -z "$upanPath" ] && [ "$ss_opt_x" = "1" ] && upanPath="`df -m | grep /dev/mmcb | grep "/media" | awk '{print $NF}' | sort -u | awk 'NR==1' `"
[ -z "$upanPath" ] && [ "$ss_opt_x" = "1" ] && upanPath="`df -m | grep "/dev/sd" | grep "/media" | awk '{print $NF}' | sort -u | awk 'NR==1' `"
if [ "$ss_opt_x" = "5" ] ; then
	# 指定目录
	opt_cifs_dir=`nvram get opt_cifs_dir`
	if [ -d $opt_cifs_dir ] ; then
		upanPath="$opt_cifs_dir"
	else
		logger -t "【opt】" "错误！未找到指定目录 $opt_cifs_dir"
		upanPath=""
		[ -z "$upanPath" ] && upanPath="`df -m | grep /dev/mmcb | grep "/media" | awk '{print $NF}' | sort -u | awk 'NR==1' `"
		[ -z "$upanPath" ] && upanPath="`df -m | grep "/dev/sd" | grep "/media" | awk '{print $NF}' | sort -u | awk 'NR==1' `"
	fi
fi
echo "$upanPath"
if [ -z "$upanPath" ] ; then 
	logger -t "【SSR_server】" "未挂载储存设备, 请重新检查配置、目录，10 秒后自动尝试重新启动"
	sleep 10
	ssrserver_restart x
	exit 0
fi

SVC_PATH=/opt/bin/python
chmod 777 "$SVC_PATH"
[[ "$(python -h 2>&1 | wc -l)" -lt 2 ]] && rm -rf /opt/bin/python /opt/opti.txt
if [ ! -s "$SVC_PATH" ] ; then
	logger -t "【SSR_server】" "找不到 $SVC_PATH，安装 opt 程序"
	/tmp/script/_mountopt optwget
fi
if [ -s "$SVC_PATH" ] ; then
	logger -t "【SSR_server】" "找到 $SVC_PATH"
else
	logger -t "【SSR_server】" "找不到 $SVC_PATH ，需要手动安装 $SVC_PATH"
	logger -t "【SSR_server】" "启动失败, 10 秒后自动尝试重新启动" && sleep 10 && ssrserver_restart x
fi
hash python 2>/dev/null || {  logger -t "【SSR_server】" "无法运行 python 程序，请检查系统，10 秒后自动尝试重新启动" ; sleep 10 ; ssrserver_restart x ; }
[ -d /opt/shadowsocks-manyuser ] && [ ! -d /opt/shadowsocksr-manyuser ] && { mkdir -p /opt/shadowsocksr-manyuser ; cp -r -f -a /opt/shadowsocks-manyuser/* /opt/shadowsocksr-manyuser ; }
[ -d /opt/shadowsocks-manyuser ] && rm -rf /opt/shadowsocks-manyuser
mkdir -p /opt/shadowsocksr-manyuser/shadowsocks/crypto/
if [ ! -f /opt/shadowsocksr-manyuser/shadowsocks/server.py ] ; then
	logger -t "【SSR_server】" "找不到 shadowsocks/server.py"
	[ "$ssrserver_update" == "0" ] && ssrserver_update=2
	echo "" > /opt/shadowsocksr-manyuser/shadowsocks/crypto/util.py
fi
if [ "$ssrserver_update" != "0" ] ; then
logger -t "【SSR_server】" "SSR_server 检测更新"
	rm -rf /opt/shadowsocksr-manyuser/shadowsocks/crypto/utilb
	A_util=`cat /opt/shadowsocksr-manyuser/shadowsocks/crypto/util.py`
	A_util=`echo -n "$A_util" | md5sum | sed s/[[:space:]]//g | sed s/-//g`
	if [ "$ssrserver_update" = "1" ] ; then
	wgetcurl.sh /opt/shadowsocksr-manyuser/shadowsocks/crypto/utilb "$hiboyfile/util.py" "$hiboyfile2/util.py"
	B_util=`cat /opt/shadowsocksr-manyuser/shadowsocks/crypto/utilb`
	B_util=`echo -n "$B_util" | md5sum | sed s/[[:space:]]//g | sed s/-//g`
	if [ "$A_util" != "$B_util" ] ; then
		logger -t "【SSR_server】" "SSR_server github.com需要更新"
		logger -t "【SSR_server】" "下载:https://github.com/esdeathlove/shadowsocks/archive/ssr_origin.zip"
		rm -rf /opt/manyuser.zip
		wgetcurl.sh /opt/manyuser.zip https://github.com/esdeathlove/shadowsocks/archive/ssr_origin.zip https://github.com/esdeathlove/shadowsocks/archive/ssr_origin.zip N
		unzip -o /opt/manyuser.zip  -d /opt/
		mkdir -p /opt/shadowsocksr-manyuser
		cp -r -f -a /opt/shadowsocks-ssr_origin/* /opt/shadowsocksr-manyuser
		rm -rf /opt/shadowsocks-ssr_origin/
		rm -rf /opt/shadowsocksr-manyuser/shadowsocks/crypto/util.py
		cp -af /opt/shadowsocksr-manyuser/shadowsocks/crypto/utilb /opt/shadowsocksr-manyuser/shadowsocks/crypto/util.py
		logger -t "【SSR_server】" "SSR_server github.com更新完成"
	else
		logger -t "【SSR_server】" "SSR_server github.com暂时没更新"
	fi
	fi
	if [ "$ssrserver_update" = "2" ] ; then
	wgetcurl.sh /opt/shadowsocksr-manyuser/shadowsocks/crypto/utilc "$hiboyfile/util_code.py" "$hiboyfile2/util_code.py"
	C_util=`cat /opt/shadowsocksr-manyuser/shadowsocks/crypto/utilc`
	C_util=`echo -n "$C_util" | md5sum | sed s/[[:space:]]//g | sed s/-//g`
	if [ "$A_util" != "$C_util" ] ; then
		logger -t "【SSR_server】" "SSR_server code需要更新"
		logger -t "【SSR_server】" "下载:$hiboyfile/manyuser.zip"
		rm -rf /opt/manyuser.zip
		wgetcurl.sh /opt/manyuser.zip "$hiboyfile/manyuser.zip" "$hiboyfile2/manyuser.zip"
		unzip -o /opt/manyuser.zip  -d /opt/
		rm -rf /opt/shadowsocksr-manyuser/shadowsocks/crypto/util.py
		cp -af /opt/shadowsocksr-manyuser/shadowsocks/crypto/utilc /opt/shadowsocksr-manyuser/shadowsocks/crypto/util.py
		logger -t "【SSR_server】" "SSR_server code更新完成"
	else
		logger -t "【SSR_server】" "SSR_server code暂时没更新"
	fi
	fi
	if [ "$ssrserver_update" = "3" ] ; then
	wgetcurl.sh /opt/shadowsocksr-manyuser/shadowsocks/crypto/utild "$hiboyfile/util_ssrr.py" "$hiboyfile2/util_ssrr.py"
	D_util=`cat /opt/shadowsocksr-manyuser/shadowsocks/crypto/utild`
	D_util=`echo -n "$D_util" | md5sum | sed s/[[:space:]]//g | sed s/-//g`
	if [ "$A_util" != "$D_util" ] ; then
		logger -t "【SSR_server】" "SSRR需要更新"
		logger -t "【SSR_server】" "下载:https://github.com/shadowsocksrr/shadowsocksr/archive/akkariiin/dev.zip"
		rm -rf /opt/manyuser.zip
		wgetcurl.sh /opt/manyuser.zip "https://github.com/shadowsocksrr/shadowsocksr/archive/akkariiin/dev.zip" "https://github.com/shadowsocksrr/shadowsocksr/archive/akkariiin/dev.zip"
		unzip -o /opt/manyuser.zip  -d /opt/
		mkdir -p /opt/shadowsocksr-manyuser
		cp -r -f -a /opt/shadowsocksr-akkariiin-dev/* /opt/shadowsocksr-manyuser
		rm -rf /opt/shadowsocksr-akkariiin-dev/
		rm -rf /opt/shadowsocksr-manyuser/shadowsocks/crypto/util.py
		cp -af /opt/shadowsocksr-manyuser/shadowsocks/crypto/utild /opt/shadowsocksr-manyuser/shadowsocks/crypto/util.py
		logger -t "【SSR_server】" "SSRR code更新完成"
	else
		logger -t "【SSR_server】" "SSRR code暂时没更新"
	fi
	fi
fi
logger -t "【SSR_server】" "启动 SSR_server 服务"
rm -rf /opt/shadowsocksr-manyuser/user-config.json
cp -af /etc/storage/SSRconfig_script.sh /opt/shadowsocksr-manyuser/user-config.json
if [ -s "/opt/shadowsocksr-manyuser/user-config.json" ] ; then
	chmod 777 -R /opt/shadowsocksr-manyuser
	cd /opt/shadowsocksr-manyuser/shadowsocks/
	python /opt/shadowsocksr-manyuser/shadowsocks/server.py a >> /tmp/syslog.log 2>&1 &
	logger -t "【SSR_server】" "请手动配置【外部网络 - 端口转发 - 启用手动端口映射】来开启WAN访问."
else
	logger -t "【SSR_server】" "/etc/storage/SSRconfig_script.sh 配置写入/opt/shadowsocksr-manyuser/user-config.json 失败，10 秒后自动尝试重新启动" && sleep 10 && ssrserver_restart x
	
fi
sleep 2
[ ! -z "$(ps -w | grep manyuser/shadowsocks/server | grep -v grep )" ] && logger -t "【SSR_server】" "启动成功" && ssrserver_restart o
[ -z "$(ps -w | grep manyuser/shadowsocks/server | grep -v grep )" ] && logger -t "【SSR_server】" "启动失败, 注意检查端口是否有冲突,程序是否下载完整,10 秒后自动尝试重新启动" && sleep 10 && ssrserver_restart x
initopt
ssrserver_get_status
eval "$scriptfilepath keep &"
}

initopt () {
optPath=`grep ' /opt ' /proc/mounts | grep tmpfs`
[ ! -z "$optPath" ] && return
optw_enable=`nvram get optw_enable`
if [ "$optw_enable" != "2" ] ; then
	nvram set optw_enable=2
fi
if [ ! -z "$(echo $scriptfilepath | grep -v "/opt/etc/init")" ] && [ -s "/opt/etc/init.d/rc.func" ] ; then
	{ echo '#!/bin/sh' ; echo $scriptfilepath '"$@"' '&' ; } > /opt/etc/init.d/$scriptname && chmod 777  /opt/etc/init.d/$scriptname
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
	#ssrserver_check
	ssrserver_keep
	;;
*)
	ssrserver_check
	;;
esac






