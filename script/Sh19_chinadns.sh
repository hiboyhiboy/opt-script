#!/bin/sh
#copyright by hiboy
source /etc/storage/script/init.sh

chinadns_enable=`nvram get app_1`
[ -z $chinadns_enable ] && chinadns_enable=0 && nvram set app_1=0
#if [ "$chinadns_enable" != "0" ] ; then
#nvramshow=`nvram showall | grep '=' | grep chinadns | awk '{print gensub(/'"'"'/,"'"'"'\"'"'"'\"'"'"'","g",$0);}'| awk '{print gensub(/=/,"='\''",1,$0)"'\'';";}'` && eval $nvramshow
#fi
chinadns_enable=`nvram get app_1`
[ -z $chinadns_enable ] && chinadns_enable=0 && nvram set app_1=0
chinadns_d=`nvram get app_2`
[ -z $chinadns_d ] && chinadns_d=0 && nvram set app_2=0
chinadns_m=`nvram get app_3`
[ -z $chinadns_m ] && chinadns_m=0 && nvram set app_3=0
chinadns_path=`nvram get app_4`
[ -z $chinadns_path ] && chinadns_path="/opt/bin/chinadns" && nvram set app_4=$chinadns_path
chinadns_dnss=`nvram get app_5`
[ -z $chinadns_dnss ] && chinadns_dnss='223.5.5.5,208.67.222.222:443,8.8.8.8' && nvram set app_5=$chinadns_dnss
chinadns_port=`nvram get app_6`
[ -z $chinadns_port ] && chinadns_port=8053 && nvram set app_6=8053



if [ ! -z "$(echo $scriptfilepath | grep -v "/tmp/script/" | grep chinadns)" ]  && [ ! -s /tmp/script/_app1 ]; then
	mkdir -p /tmp/script
	{ echo '#!/bin/sh' ; echo $scriptfilepath '"$@"' '&' ; } > /tmp/script/_app1
	chmod 777 /tmp/script/_app1
fi

chinadns_restart () {

chinadns_renum=`nvram get chinadns_renum`
relock="/var/lock/chinadns_restart.lock"
if [ "$1" = "o" ] ; then
	nvram set chinadns_renum="0"
	[ -f $relock ] && rm -f $relock
	return 0
fi
if [ "$1" = "x" ] ; then
	if [ -f $relock ] ; then
		logger -t "【chinadns】" "多次尝试启动失败，等待【"`cat $relock`"分钟】后自动尝试重新启动"
		exit 0
	fi
	chinadns_renum=${chinadns_renum:-"0"}
	chinadns_renum=`expr $chinadns_renum + 1`
	nvram set chinadns_renum="$chinadns_renum"
	if [ "$chinadns_renum" -gt "2" ] ; then
		I=19
		echo $I > $relock
		logger -t "【chinadns】" "多次尝试启动失败，等待【"`cat $relock`"分钟】后自动尝试重新启动"
		while [ $I -gt 0 ]; do
			I=$(($I - 1))
			echo $I > $relock
			sleep 60
			[ "$(nvram get chinadns_renum)" = "0" ] && exit 0
			[ $I -lt 0 ] && break
		done
		nvram set chinadns_renum="0"
	fi
	[ -f $relock ] && rm -f $relock
fi
nvram set chinadns_status=0
eval "$scriptfilepath &"
exit 0
}

chinadns_get_status () {

#lan_ipaddr=`nvram get lan_ipaddr`
A_restart=`nvram get chinadns_status`
B_restart="$chinadns_enable$chinadns_path$chinadns_m$chinadns_d$chinadns_dnss"
B_restart=`echo -n "$B_restart" | md5sum | sed s/[[:space:]]//g | sed s/-//g`
if [ "$A_restart" != "$B_restart" ] ; then
	nvram set chinadns_status=$B_restart
	needed_restart=1
else
	needed_restart=0
fi
}

chinadns_check () {

chinadns_get_status
if [ "$chinadns_enable" != "1" ] && [ "$needed_restart" = "1" ] ; then
	[ ! -z "$(ps -w | grep "$chinadns_path" | grep -v grep )" ] && logger -t "【chinadns】" "停止 chinadns" && chinadns_close
	{ kill_ps "$scriptname" exit0; exit 0; }
fi
if [ "$chinadns_enable" = "1" ] ; then
	if [ "$needed_restart" = "1" ] ; then
		chinadns_close
		chinadns_start
	else
		[ -z "$(ps -w | grep "$chinadns_path" | grep -v grep )" ] && chinadns_restart
		port=$(grep "server=127.0.0.1#$chinadns_port"  /etc/storage/dnsmasq/dnsmasq.conf | wc -l)
		if [ "$port" = 0 ] ; then
			logger -t "【chinadns】" "检测:找不到 dnsmasq 转发规则, 重新添加"
			# 写入dnsmasq配置
			sed -Ei '/no-resolv|server=|server=127.0.0.1|dns-forward-max=1000|min-cache-ttl=1800/d' /etc/storage/dnsmasq/dnsmasq.conf
			cat >> "/etc/storage/dnsmasq/dnsmasq.conf" <<-EOF
no-resolv
server=127.0.0.1#$chinadns_port
dns-forward-max=1000
min-cache-ttl=1800
EOF
			restart_dhcpd
		fi
	fi
fi
}

chinadns_keep () {
logger -t "【chinadns】" "守护进程启动"
if [ -s /tmp/script/_opt_script_check ]; then
sed -Ei '/【chinadns】|^$/d' /tmp/script/_opt_script_check
cat >> "/tmp/script/_opt_script_check" <<-OSC
	NUM=\`grep "$chinadns_path" /tmp/ps | grep -v grep |wc -l\` # 【chinadns】
	if [ "\$NUM" -lt "1" ] || [ ! -s "$chinadns_path" ] ; then # 【chinadns】
		logger -t "【chinadns】" "重新启动\$NUM" # 【chinadns】
		nvram set chinadns_status=00 && eval "$scriptfilepath &" && sed -Ei '/【chinadns】|^$/d' /tmp/script/_opt_script_check # 【chinadns】
	fi # 【chinadns】
OSC
#return
fi
sleep 60
chinadns_enable=`nvram get app_1` #chinadns_enable
while [ "$chinadns_enable" = "1" ]; do
	NUM=`ps -w | grep "$chinadns_path" | grep -v grep |wc -l`
	if [ "$NUM" -lt "1" ] || [ ! -s "$chinadns_path" ] ; then
		logger -t "【chinadns】" "重新启动$NUM"
		chinadns_restart
	fi
	port=$(grep "server=127.0.0.1#$chinadns_port"  /etc/storage/dnsmasq/dnsmasq.conf | wc -l)
	if [ "$port" = 0 ] ; then
		logger -t "【chinadns】" "检测:找不到 dnsmasq 转发规则, 重新添加"
		# 写入dnsmasq配置
		sed -Ei '/no-resolv|server=|server=127.0.0.1|dns-forward-max=1000|min-cache-ttl=1800/d' /etc/storage/dnsmasq/dnsmasq.conf
		cat >> "/etc/storage/dnsmasq/dnsmasq.conf" <<-EOF
no-resolv
server=127.0.0.1#$chinadns_port
dns-forward-max=1000
min-cache-ttl=1800
EOF
		restart_dhcpd
	fi
sleep 69
chinadns_enable=`nvram get app_1` #chinadns_enable
done
}

chinadns_close () {
sed -Ei '/【chinadns】|^$/d' /tmp/script/_opt_script_check
sed -Ei '/no-resolv|server=|server=127.0.0.1|dns-forward-max=1000|min-cache-ttl=1800/d' /etc/storage/dnsmasq/dnsmasq.conf
restart_dhcpd
[ ! -z "$chinadns_path" ] && eval $(ps -w | grep "$chinadns_path" | grep -v grep | awk '{print "kill "$1";";}')
killall chinadns
killall -9 chinadns
kill_ps "/tmp/script/_app1"
kill_ps "_chinadns.sh"
kill_ps "$scriptname"
}

chinadns_start () {
SVC_PATH="$chinadns_path"
if [ ! -s "$SVC_PATH" ] ; then
	SVC_PATH="/opt/bin/chinadns"
fi
chmod 777 "$SVC_PATH"
[[ "$(chinadns -h | wc -l)" -lt 2 ]] && rm -rf /opt/bin/chinadns
if [ ! -s "$SVC_PATH" ] ; then
	logger -t "【chinadns】" "找不到 $SVC_PATH，安装 opt 程序"
	/tmp/script/_mountopt optwget
fi
if [ ! -s "$SVC_PATH" ] ; then
	logger -t "【chinadns】" "找不到 $SVC_PATH 下载程序"
	wgetcurl.sh /opt/bin/chinadns "$hiboyfile/chinadns" "$hiboyfile2/chinadns"
	chmod 755 "/opt/bin/chinadns"
else
	logger -t "【chinadns】" "找到 $SVC_PATH"
fi
if [ ! -s "$SVC_PATH" ] ; then
	logger -t "【chinadns】" "找不到 $SVC_PATH ，需要手动安装 $SVC_PATH"
	logger -t "【chinadns】" "启动失败, 10 秒后自动尝试重新启动" && sleep 10 && chinadns_restart x
fi
if [ -s "$SVC_PATH" ] ; then
	nvram set app_4="$SVC_PATH" #chinadns_path
fi
chinadns_path="$SVC_PATH"

if [ ! -f "/opt/opti.txt" ] ; then
	logger -t "【opt】" "安装 opt 环境"
	/tmp/script/_mountopt optwget
fi
# 配置参数
usage=""
if [ "$chinadns_m" = "1" ] ; then
usage=$usage" -m "
fi
if [ "$chinadns_d" = "1" ] ; then
usage=$usage" -d "
fi
[ ! -f /etc/storage/china_ip_list.txt ] && tar -xzvf /etc_ro/china_ip_list.tgz -C /tmp && ln -sf /tmp/china_ip_list.txt /etc/storage/china_ip_list.txt
update_app
chmod 755 "/opt/bin/chinadns"
chinadns_v=`chinadns -V | grep ChinaDNS`
nvram set chinadns_v="$chinadns_v"

killall dnsproxy && killall -9 dnsproxy 2>/dev/null
killall pdnsd && killall -9 pdnsd 2>/dev/null
logger -t "【chinadns】" "运行 $SVC_PATH"
$chinadns_path -p $chinadns_port -s $chinadns_dnss -l /opt/app/chinadns/chinadns_iplist.txt -c /etc/storage/china_ip_list.txt $usage &
sleep 2
[ ! -z "$(ps -w | grep "$chinadns_path" | grep -v grep )" ] && logger -t "【chinadns】" "启动成功 $chinadns_v " && chinadns_restart o
[ -z "$(ps -w | grep "$chinadns_path" | grep -v grep )" ] && logger -t "【chinadns】" "启动失败, 注意检查端口是否有冲突,程序是否下载完整,10 秒后自动尝试重新启动" && sleep 10 && chinadns_restart x

initopt

# 写入dnsmasq配置
sed -Ei '/no-resolv|server=|server=127.0.0.1|dns-forward-max=1000|min-cache-ttl=1800/d' /etc/storage/dnsmasq/dnsmasq.conf
	cat >> "/etc/storage/dnsmasq/dnsmasq.conf" <<-EOF
no-resolv
server=127.0.0.1#$chinadns_port
dns-forward-max=1000
min-cache-ttl=1800
EOF

restart_dhcpd

chinadns_get_status
eval "$scriptfilepath keep &"
}

initopt () {
optPath=`grep ' /opt ' /proc/mounts | grep tmpfs`
[ ! -z "$optPath" ] && return
if [ ! -z "$(echo $scriptfilepath | grep -v "/opt/etc/init")" ] && [ -s "/opt/etc/init.d/rc.func" ] ; then
	{ echo '#!/bin/sh' ; echo $scriptfilepath '"$@"' '&' ; } > /opt/etc/init.d/$scriptname && chmod 777  /opt/etc/init.d/$scriptname
fi

}

update_app () {
if [ "$1" = "del" ] ; then
	rm -rf $chinadns_path /opt/app/chinadns/Advanced_Extensions_chinadns.asp /opt/app/chinadns/chinadns_iplist.txt
fi
# 加载程序配置页面
mkdir -p /opt/app/chinadns
if [ ! -f "/opt/app/chinadns/chinadns_iplist.txt" ] || [ ! -s "/opt/app/chinadns/chinadns_iplist.txt" ] ; then
	wgetcurl.sh /opt/app/chinadns/chinadns_iplist.txt "$hiboyfile/chinadns_iplist.txt" "$hiboyfile2/chinadns_iplist.txt"
fi
if [ ! -f "/opt/app/chinadns/Advanced_Extensions_chinadns.asp" ] || [ ! -s "/opt/app/chinadns/Advanced_Extensions_chinadns.asp" ] ; then
	wgetcurl.sh /opt/app/chinadns/Advanced_Extensions_chinadns.asp "$hiboyfile/Advanced_Extensions_chinadnsasp" "$hiboyfile2/Advanced_Extensions_chinadnsasp"
fi
umount /www/Advanced_Extensions_app01.asp
mount --bind /opt/app/chinadns/Advanced_Extensions_chinadns.asp /www/Advanced_Extensions_app01.asp
# 更新程序启动脚本
[ "$1" = "del" ] && /etc/storage/www_sh/chinadns del &
}

case $ACTION in
start)
	chinadns_close
	chinadns_check
	;;
check)
	chinadns_check
	;;
stop)
	chinadns_close
	;;
keep)
	#chinadns_check
	chinadns_keep
	;;
updateapp1)
	chinadns_restart o
	[ "$chinadns_enable" = "1" ] && nvram set chinadns_status="updatechinadns" && logger -t "【chinadns】" "重启" && chinadns_restart
	[ "$chinadns_enable" != "1" ] && nvram set chinadns_v="" && logger -t "【chinadns】" "更新" && update_app del
	;;
update_app)
	update_app
	;;
*)
	chinadns_check
	;;
esac

