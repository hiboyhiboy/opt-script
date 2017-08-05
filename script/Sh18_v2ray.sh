#!/bin/sh
#copyright by hiboy
source /etc/storage/script/init.sh
v2ray_enable=`nvram get v2ray_enable`
[ -z $v2ray_enable ] && v2ray_enable=0 && nvram set v2ray_enable=0
v2ray_path=`nvram get v2ray_path`
[ -z $v2ray_path ] && v2ray_path="/opt/bin/v2ray" && nvram set v2ray_path=$v2ray_path
v2ray_door=`nvram get v2ray_door`
[ -z $v2ray_door ] && v2ray_door=1099 && nvram set v2ray_door=1099
v2ray_port=`nvram get v2ray_port`
[ -z $v2ray_port ] && v2ray_port=1088 && nvram set v2ray_port=1088

if [ "$v2ray_enable" != "0" ] ; then
nvramshow=`nvram showall | grep '=' | grep v2ray | awk '{print gensub(/'"'"'/,"'"'"'\"'"'"'\"'"'"'","g",$0);}'| awk '{print gensub(/=/,"='\''",1,$0)"'\'';";}'` && eval $nvramshow
server_addresses=$(cat /etc/storage/v2ray_script.sh | tr -d ' ' | grep -Eo '"address":"[0-9\.]*"' | cut -d':' -f2 | tr -d '"')

fi


if [ ! -z "$(echo $scriptfilepath | grep -v "/tmp/script/" | grep v2ray)" ]  && [ ! -s /tmp/script/_v2ray ]; then
	mkdir -p /tmp/script
	{ echo '#!/bin/sh' ; echo $scriptfilepath '"$@"' '&' ; } > /tmp/script/_v2ray
	chmod 777 /tmp/script/_v2ray
fi

v2ray_restart () {

relock="/var/lock/v2ray_restart.lock"
if [ "$1" = "o" ] ; then
	nvram set v2ray_renum="0"
	[ -f $relock ] && rm -f $relock
	return 0
fi
if [ "$1" = "x" ] ; then
	if [ -f $relock ] ; then
		logger -t "【v2ray】" "多次尝试启动失败，等待【"`cat $relock`"分钟】后自动尝试重新启动"
		exit 0
	fi
	v2ray_renum=${v2ray_renum:-"0"}
	v2ray_renum=`expr $v2ray_renum + 1`
	nvram set v2ray_renum="$v2ray_renum"
	if [ "$v2ray_renum" -gt "2" ] ; then
		I=19
		echo $I > $relock
		logger -t "【v2ray】" "多次尝试启动失败，等待【"`cat $relock`"分钟】后自动尝试重新启动"
		while [ $I -gt 0 ]; do
			I=$(($I - 1))
			echo $I > $relock
			sleep 60
			[ "$(nvram get v2ray_renum)" = "0" ] && exit 0
			[ $I -lt 0 ] && break
		done
		nvram set v2ray_renum="0"
	fi
	[ -f $relock ] && rm -f $relock
fi
nvram set v2ray_status=0
eval "$scriptfilepath &"
exit 0
}

v2ray_get_status () {

lan_ipaddr=`nvram get lan_ipaddr`
A_restart=`nvram get v2ray_status`
B_restart="$v2ray_enable$v2ray_path$v2ray_follow$lan_ipaddr$v2ray_door$v2ray_optput$(cat /etc/storage/v2ray_script.sh /etc/storage/v2ray_config_script.sh | grep -v "^$")"
B_restart=`echo -n "$B_restart" | md5sum | sed s/[[:space:]]//g | sed s/-//g`
if [ "$A_restart" != "$B_restart" ] ; then
	nvram set v2ray_status=$B_restart
	needed_restart=1
else
	needed_restart=0
fi
}

v2ray_check () {

v2ray_get_status
if [ "$v2ray_enable" != "1" ] && [ "$needed_restart" = "1" ] ; then
	[ ! -z "$(ps -w | grep "$v2ray_path" | grep -v grep )" ] && logger -t "【v2ray】" "停止 v2ray" && v2ray_close
	{ eval $(ps -w | grep "$scriptname" | grep -v grep | awk '{print "kill "$1";";}'); exit 0; }
fi
if [ "$v2ray_enable" = "1" ] ; then
	if [ "$needed_restart" = "1" ] ; then
		v2ray_close
		v2ray_start
	else
		[ -z "$(ps -w | grep "$v2ray_path" | grep -v grep )" ] && v2ray_restart
		if [ "$v2ray_follow" = "1" ] ; then
		port=$(iptables -t nat -L | grep 'SS_SPEC' | wc -l)
		if [ "$port" = 0 ] ; then
			logger -t "【v2ray】" "检测:找不到 SS_SPEC 转发规则, 重新添加"
			v2ray_restart
		fi
		fi
	fi
fi
}

v2ray_keep () {
logger -t "【v2ray】" "守护进程启动"
if [ -s /tmp/script/_opt_script_check ]; then
sed -Ei '/【v2ray】|^$/d' /tmp/script/_opt_script_check
cat >> "/tmp/script/_opt_script_check" <<-OSC
	NUM=\`grep "$v2ray_path" /tmp/ps | grep -v grep |wc -l\` # 【v2ray】
	if [ "\$NUM" -lt "1" ] || [ ! -s "$v2ray_path" ] ; then # 【v2ray】
		logger -t "【v2ray】" "重新启动\$NUM" # 【v2ray】
		nvram set v2ray_status=00 && eval "$scriptfilepath &" && sed -Ei '/【v2ray】|^$/d' /tmp/script/_opt_script_check # 【v2ray】
	fi # 【v2ray】
OSC
#return
fi

v2ray_enable=`nvram get v2ray_enable`
while [ "$v2ray_enable" = "1" ]; do
	NUM=`ps -w | grep "$v2ray_path" | grep -v grep |wc -l`
	if [ "$NUM" -lt "1" ] || [ ! -s "$v2ray_path" ] ; then
		logger -t "【v2ray】" "重新启动$NUM"
		v2ray_restart
	fi
	v2ray_follow=`nvram get v2ray_follow`
	if [ "$v2ray_follow" = "1" ] ; then
	port=$(iptables -t nat -L | grep 'SS_SPEC' | wc -l)
	if [ "$port" = 0 ] ; then
		logger -t "【v2ray】" "检测:找不到 SS_SPEC 转发规则, 重新添加"
		v2ray_restart
	fi
	fi
sleep 218
v2ray_enable=`nvram get v2ray_enable`
done
}

v2ray_close () {
flush_r
sed -Ei '/【v2ray】|^$/d' /tmp/script/_opt_script_check
[ ! -z "$v2ray_path" ] && eval $(ps -w | grep "$v2ray_path" | grep -v grep | awk '{print "kill "$1";";}')
killall v2ray v2ray_script.sh
killall -9 v2ray v2ray_script.sh
eval $(ps -w | grep "_v2ray keep" | grep -v grep | awk '{print "kill "$1";";}')
eval $(ps -w | grep "_v2ray.sh keep" | grep -v grep | awk '{print "kill "$1";";}')
eval $(ps -w | grep "$scriptname keep" | grep -v grep | awk '{print "kill "$1";";}')
}

v2ray_start () {
initconfig
SVC_PATH="$v2ray_path"
if [ ! -s "$SVC_PATH" ] ; then
	SVC_PATH="/opt/bin/v2ray"
fi
hash v2ray 2>/dev/null || rm -rf /opt/bin/v2ray
if [ ! -s "$SVC_PATH" ] ; then
	logger -t "【v2ray】" "找不到 $SVC_PATH，安装 opt 程序"
	/tmp/script/_mountopt start
fi
if [ ! -s "$SVC_PATH" ] ; then
	logger -t "【v2ray】" "找不到 $SVC_PATH 下载程序"
	wgetcurl.sh /opt/bin/v2ray "$hiboyfile/v2ray" "$hiboyfile2/v2ray"
	chmod 755 "/opt/bin/v2ray"
else
	logger -t "【v2ray】" "找到 $SVC_PATH"
fi
if [ ! -s "$SVC_PATH" ] ; then
	logger -t "【v2ray】" "找不到 $SVC_PATH ，需要手动安装 $SVC_PATH"
	logger -t "【v2ray】" "启动失败, 10 秒后自动尝试重新启动" && sleep 10 && v2ray_restart x
fi
if [ -s "$SVC_PATH" ] ; then
	nvram set v2ray_path="$SVC_PATH"
fi
v2ray_path="$SVC_PATH"

logger -t "【v2ray】" "运行 v2ray_script"
/etc/storage/v2ray_script.sh
$v2ray_path  -config /etc/storage/v2ray_config_script.sh &
restart_dhcpd
v2ray_v=`v2ray -version | grep V2Ray`
nvram set v2ray_v="$v2ray_v"
sleep 2
if [ ! -f "/etc/storage/v2ray_config_script.sh" ] || [ ! -s "/etc/storage/v2ray_config_script.sh" ] ; then
logger -t "【v2ray】" "启动失败, v2ray 配置文件 内容为空"
logger -t "【v2ray】" "请在服务端运行一键安装脚本："
logger -t "【v2ray】" "bash <(curl -L -s http://opt.cn2qq.com/opt-script/v2ray.sh)"
sleep 10 && v2ray_restart x
fi
[ ! -z "$(ps -w | grep "$v2ray_path" | grep -v grep )" ] && logger -t "【v2ray】" "启动成功 $v2ray_v " && v2ray_restart o
[ -z "$(ps -w | grep "$v2ray_path" | grep -v grep )" ] && logger -t "【v2ray】" "启动失败, 注意检查端口是否有冲突,程序是否下载完整,10 秒后自动尝试重新启动" && sleep 10 && v2ray_restart x

initopt


if [ "$v2ray_follow" = "1" ] ; then
flush_r

# 透明代理
logger -t "【v2ray】" "启动 透明代理"
logger -t "【v2ray】" "启动 dnsproxy 防止域名污染"
pidof dnsproxy >/dev/null 2>&1 && killall dnsproxy && killall -9 dnsproxy 2>/dev/null
pidof pdnsd >/dev/null 2>&1 && killall pdnsd && killall -9 pdnsd 2>/dev/null
if [ -s /sbin/dnsproxy ] ; then
	/sbin/dnsproxy -d
else
	dnsproxy -d
fi

#防火墙转发规则加载
sed -Ei '/no-resolv|server=|server=127.0.0.1|dns-forward-max=1000|min-cache-ttl=1800/d' /etc/storage/dnsmasq/dnsmasq.conf
cat >> "/etc/storage/dnsmasq/dnsmasq.conf" <<-\EOF
no-resolv
server=127.0.0.1#8053
dns-forward-max=1000
min-cache-ttl=1800
EOF

restart_dhcpd

#载入iptables模块
for module in ip_set ip_set_bitmap_ip ip_set_bitmap_ipmac ip_set_bitmap_port ip_set_hash_ip ip_set_hash_ipport ip_set_hash_ipportip ip_set_hash_ipportnet ip_set_hash_net ip_set_hash_netport ip_set_list_set xt_set xt_TPROXY
do
	modprobe $module
done 

# rules规则
ipset -! restore <<-EOF 
create ss_spec_dst_sp hash:net hashsize 64
$(gen_special_purpose_ip | sed -e "s/^/add ss_spec_dst_sp /")
EOF

# 加载 nat 规则
include_ac_rules nat
iptables -t nat -A SS_SPEC_WAN_FW -p tcp -j REDIRECT --to-ports $v2ray_door
get_wifidognx
gen_prerouting_rules nat tcp $wifidognx
# iptables -t nat -I OUTPUT -p tcp -j SS_SPEC_V2RAY_LAN_DG
# iptables -t nat -D OUTPUT -p tcp -j SS_SPEC_V2RAY_LAN_DG


# 加载 mangle 规则
ip rule add fwmark 1 lookup 100
ip route add local default dev lo table 100
include_ac_rules mangle
iptables -t mangle -A SS_SPEC_WAN_FW -p udp -j TPROXY --on-port $v2ray_door --tproxy-mark 0x01/0x01
get_wifidognx_mangle
gen_prerouting_rules mangle udp $wifidognx

iptables -t nat -I OUTPUT -p tcp -d 8.8.8.8,8.8.4.4 --dport 53 -j REDIRECT --to-port 1099
iptables -t nat -I OUTPUT -p tcp -d 208.67.222.222,208.67.220.220 --dport 443 -j REDIRECT --to-port 1099

# 同时将代理规则应用到 OUTPUT 链, 让路由自身流量走透明代理
NUM=`iptables -m owner -h 2>&1 | grep owner | wc -l`
hash su 2>/dev/null && su_x="1"
hash su 2>/dev/null || su_x="0"
if [ "$NUM" -ge "3" ] && [ "$v2ray_optput" = 1 ] && [ "$su_x" = "1" ] ; then
logger -t "【v2ray】" "同时将透明代理规则应用到 OUTPUT 链, 让路由自身流量走透明代理"
	useradd -u 777 v2
	killall v2ray
	iptables -t nat -D OUTPUT -m owner ! --uid-owner 777 -p tcp -j SS_SPEC_V2RAY_LAN_DG
	su v2 -c "$v2ray_path -config /etc/storage/v2ray_config_script.sh &" &
	iptables -t nat -A OUTPUT -m owner ! --uid-owner 777 -p tcp -j SS_SPEC_V2RAY_LAN_DG
fi


# 透明代理
fi

v2ray_get_status
eval "$scriptfilepath keep &"
}

gen_prerouting_rules() {
	iptables -t $1 -I PREROUTING $3 -p $2 -j SS_SPEC_V2RAY_LAN_DG
}

flush_r() {
	iptables-save -c | sed  "s/webstr--url/webstr --url/g" | grep -v "SS_SPEC" | iptables-restore -c
	ip rule del fwmark 1 lookup 100 2>/dev/null
	ip route del local default dev lo table 100 2>/dev/null
	for setname in $(ipset -n list | grep -i "SS_SPEC"); do
		ipset destroy $setname 2>/dev/null
	done
	iptables -t nat -D OUTPUT -p tcp -d 8.8.8.8,8.8.4.4 --dport 53 -j REDIRECT --to-port 1099
	iptables -t nat -D OUTPUT -p tcp -d 208.67.222.222,208.67.220.220 --dport 443 -j REDIRECT --to-port 1099
	iptables -t nat -D OUTPUT -p tcp -d 8.8.8.8,8.8.4.4 --dport 53 -j REDIRECT --to-port 1090
	iptables -t nat -D OUTPUT -p tcp -d 208.67.222.222,208.67.220.220 --dport 443 -j REDIRECT --to-port 1090
	iptables -t nat -D OUTPUT -p tcp -d 8.8.8.8,8.8.4.4 --dport 53 -j REDIRECT --to-port 1091
	iptables -t nat -D OUTPUT -p tcp -d 208.67.222.222,208.67.220.220 --dport 443 -j REDIRECT --to-port 1091
	iptables -t nat -D OUTPUT -p tcp -d 8.8.8.8,8.8.4.4 --dport 53 -j RETURN
	iptables -t nat -D OUTPUT -p tcp -d 208.67.222.222,208.67.220.220 --dport 443 -j RETURN
	sed -Ei '/no-resolv|server=|server=127.0.0.1|server=208.67.222.222|dns-forward-max=1000|min-cache-ttl=1800|github/d' /etc/storage/dnsmasq/dnsmasq.conf
	restart_dhcpd
	return 0
}

gen_special_purpose_ip() {
cat <<-EOF | grep -E "^([0-9]{1,3}\.){3}[0-9]{1,3}"
0.0.0.0/8
10.0.0.0/8
100.64.0.0/10
127.0.0.0/8
169.254.0.0/16
172.16.0.0/12
192.0.0.0/24
192.0.2.0/24
192.25.61.0/24
192.31.196.0/24
192.52.193.0/24
192.88.99.0/24
192.168.0.0/16
192.175.48.0/24
198.18.0.0/15
198.51.100.0/24
203.0.113.0/24
224.0.0.0/4
240.0.0.0/4
255.255.255.255
100.100.100.100
188.188.188.188
110.110.110.110
104.160.185.171
$lan_ipaddr
$server_addresses
EOF
}

#-A SS_SPEC_V2RAY_LAN_DG -p tcp -m multiport --dports 8118,3000,18309 -j RETURN

include_ac_rules() {
	iptables-restore -n <<-EOF
*$1
:SS_SPEC_V2RAY_LAN_DG - [0:0]
:SS_SPEC_WAN_FW - [0:0]
-A SS_SPEC_V2RAY_LAN_DG -m set --match-set ss_spec_dst_sp dst -j RETURN
-A SS_SPEC_V2RAY_LAN_DG -j SS_SPEC_WAN_FW
COMMIT
EOF

}


get_wifidognx() {
	wifidognx=""
	#wifidogn=`iptables -t nat -L PREROUTING --line-number | grep AD_BYBY | awk '{print $1}' | awk 'END{print $1}'`  ## AD_BYBY
	#if [ -z "$wifidogn" ] ; then
		wifidogn=`iptables -t nat -L PREROUTING --line-number | grep Outgoing | awk '{print $1}' | awk 'END{print $1}'`  ## Outgoing
		if [ -z "$wifidogn" ] ; then
			wifidogn=`iptables -t nat -L PREROUTING --line-number | grep vserver | awk '{print $1}' | awk 'END{print $1}'`  ## vserver
			if [ -z "$wifidogn" ] ; then
				wifidognx=1
			else
				wifidognx=`expr $wifidogn + 1`
			fi
		else
			wifidognx=`expr $wifidogn + 1`
		fi
	#else
	#	wifidognx=`expr $wifidogn + 1`
	#fi
	wifidognx=$wifidognx
}

get_wifidognx_mangle() {
	wifidognx=""
	wifidogn=`iptables -t mangle -L PREROUTING --line-number | grep Outgoing | awk '{print $1}' | awk 'END{print $1}'`  ## Outgoing
		if [ -z "$wifidogn" ] ; then
			wifidogn=`iptables -t mangle -L PREROUTING --line-number | grep UP | awk '{print $1}' | awk 'END{print $1}'`  ## UP
			if [ -z "$wifidogn" ] ; then
				wifidognx=1
			else
				wifidognx=`expr $wifidogn + 1`
			fi
		else
			wifidognx=`expr $wifidogn + 1`
		fi
	wifidognx=$wifidognx
}

initopt () {
optPath=`grep ' /opt ' /proc/mounts | grep tmpfs`
[ ! -z "$optPath" ] && return
if [ -z "$(echo $scriptfilepath | grep "/tmp/script/")" ] && [ -s "/opt/etc/init.d/rc.func" ] ; then
	cp -Hf "$scriptfilepath" "/opt/etc/init.d/$scriptname"
fi

}

initconfig () {
    if [ ! -f "/etc/storage/v2ray_script.sh" ] || [ ! -s "/etc/storage/v2ray_script.sh" ] ; then
cat > "/etc/storage/v2ray_script.sh" <<-\VVR
#!/bin/sh
# 启动前运行的脚本
export PATH='/etc/storage/bin:/tmp/script:/etc/storage/script:/opt/usr/sbin:/opt/usr/bin:/opt/sbin:/opt/bin:/usr/local/sbin:/usr/sbin:/usr/bin:/sbin:/bin'
export LD_LIBRARY_PATH=/lib:/opt/lib
server_addresses=$(cat /etc/storage/v2ray_script.sh | tr -d ' ' | grep -Eo '"address":"[0-9\.]*"' | cut -d':' -f2 | tr -d '"')
v2ray_door=`nvram get v2ray_door`
[ -z $v2ray_door ] && v2ray_door=1099 && nvram set v2ray_door=1099
lan_ipaddr=`nvram get lan_ipaddr`


VVR
fi
    if [ ! -f "/etc/storage/v2ray_config_script.sh" ] || [ ! -s "/etc/storage/v2ray_config_script.sh" ] ; then
cat > "/etc/storage/v2ray_config_script.sh" <<-\VVRCON
VVRCON
fi

}

case $ACTION in
start)
	v2ray_close
	v2ray_check
	;;
check)
	v2ray_check
	;;
stop)
	v2ray_close
	;;
keep)
	#v2ray_check
	v2ray_keep
	;;
updatev2ray)
	v2ray_restart o
	[ "$v2ray_enable" = "1" ] && nvram set v2ray_status="updatev2ray" && logger -t "【v2ray】" "重启" && v2ray_restart
	[ "$v2ray_enable" != "1" ] && [ -f "$v2ray_path" ] && nvram set v2ray_v="" && logger -t "【v2ray】" "更新" && rm -rf $v2ray_path
	;;
*)
	v2ray_check
	;;
esac

