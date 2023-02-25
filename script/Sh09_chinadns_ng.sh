#!/bin/bash
#copyright by hiboy
source /etc/storage/script/init.sh

chinadns_ng_enable="`nvram get app_102`"
[ -z $chinadns_ng_enable ] && chinadns_ng_enable=0 && nvram set app_102=0
chinadns_enable=`nvram get app_1`
[ -z $chinadns_enable ] && chinadns_enable=0 && nvram set app_1=0
smartdns_enable="`nvram get app_106`"
[ -z $smartdns_enable ] && smartdns_enable=0 && nvram set app_106=0
#if [ "$chinadns_ng_enable" != "0" ] ; then
#nvramshow=`nvram showall | grep '=' | grep chinadns_ng | awk '{print gensub(/'"'"'/,"'"'"'\"'"'"'\"'"'"'","g",$0);}'| awk '{print gensub(/=/,"='\''",1,$0)"'\'';";}'` && eval $nvramshow
#fi
if [ "$chinadns_ng_enable" == "0" ] && [ "$smartdns_enable" == "1" ] ; then
logger -t "【chinadns_ng】" "由于开启 smartdns 时需要 ChinaDNS-NG ，自动开启 ChinaDNS-NG！！！"
chinadns_ng_enable="1"
nvram set app_102="1"
fi
if [ "$chinadns_ng_enable" == "1" ] && [ "$chinadns_enable" == "1" ] ; then
if [ "$chinadns_enable" == "1" ] ; then
logger -t "【chinadns_ng】" "由于已经开启 ChinaDNS-NG、smartdns ，自动关闭 ChinaDNS！！！"
chinadns_enable="0"
nvram set app_1="0"
fi
fi

chinadns_ng_usage=`nvram get app_103`
[ -z "$chinadns_ng_usage" ] && chinadns_ng_usage=' -n -b 0.0.0.0 -c 223.5.5.5 -t 127.0.0.1#55353 --chnlist-first -m /opt/app/chinadns_ng/chnlist.txt -g /opt/app/chinadns_ng/gfwlist.txt ' && nvram set app_103="$chinadns_ng_usage"
smartdns_usage=`nvram get app_107`
[ -z "$smartdns_usage" ] && smartdns_usage=' -n -b 0.0.0.0 -c 127.0.0.1#8051 -t 127.0.0.1#8052 --chnlist-first -m /opt/app/chinadns_ng/chnlist.txt -g /opt/app/chinadns_ng/gfwlist.txt ' && nvram set app_107="$smartdns_usage"

chinadns_ng_port=`nvram get app_6`
[ -z $chinadns_ng_port ] && chinadns_ng_port=8053 && nvram set app_6=8053

chinadns_ng_renum=`nvram get chinadns_ng_renum`
chinadns_ng_renum=${chinadns_ng_renum:-"0"}
cmd_log_enable=`nvram get cmd_log_enable`
cmd_name="chinadns_ng"
cmd_log=""
if [ "$cmd_log_enable" = "1" ] || [ "$chinadns_ng_renum" -gt "0" ] ; then
	cmd_log="$cmd_log2"
fi


if [ ! -z "$(echo $scriptfilepath | grep -v "/tmp/script/" | grep chinadns_ng)" ]  && [ ! -s /tmp/script/_app19 ]; then
	mkdir -p /tmp/script
	{ echo '#!/bin/bash' ; echo $scriptfilepath '"$@"' '&' ; } > /tmp/script/_app19
	chmod 777 /tmp/script/_app19
fi

chinadns_ng_restart () {

relock="/var/lock/chinadns_ng_restart.lock"
if [ "$1" = "o" ] ; then
	nvram set chinadns_ng_renum="0"
	[ -f $relock ] && rm -f $relock
	return 0
fi
if [ "$1" = "x" ] ; then
	if [ -f $relock ] ; then
		logger -t "【chinadns_ng】" "多次尝试启动失败，等待【"`cat $relock`"分钟】后自动尝试重新启动"
		exit 0
	fi
	chinadns_ng_renum=${chinadns_ng_renum:-"0"}
	chinadns_ng_renum=`expr $chinadns_ng_renum + 1`
	nvram set chinadns_ng_renum="$chinadns_ng_renum"
	if [ "$chinadns_ng_renum" -gt "3" ] ; then
		I=19
		echo $I > $relock
		logger -t "【chinadns_ng】" "多次尝试启动失败，等待【"`cat $relock`"分钟】后自动尝试重新启动"
		while [ $I -gt 0 ]; do
			I=$(($I - 1))
			echo $I > $relock
			sleep 60
			[ "$(nvram get chinadns_ng_renum)" = "0" ] && exit 0
			[ $I -lt 0 ] && break
		done
		nvram set chinadns_ng_renum="1"
	fi
	[ -f $relock ] && rm -f $relock
fi
nvram set chinadns_ng_status=0
eval "$scriptfilepath &"
exit 0
}

chinadns_ng_get_status () {

#lan_ipaddr=`nvram get lan_ipaddr`
A_restart=`nvram get chinadns_ng_status`
B_restart="$chinadns_ng_enable$chinadns_ng_usage$smartdns_enable$smartdns_usage$(cat /etc/storage/app_23.sh | grep -v '^#' | grep -v "^$")"
B_restart=`echo -n "$B_restart" | md5sum | sed s/[[:space:]]//g | sed s/-//g`
cut_B_re
if [ "$A_restart" != "$B_restart" ] ; then
	nvram set chinadns_ng_status=$B_restart
	needed_restart=1
else
	needed_restart=0
fi
}

chinadns_ng_check () {

chinadns_ng_get_status
if [ "$chinadns_ng_enable" != "1" ] && [ "$needed_restart" = "1" ] ; then
	[ ! -z "$(ps -w | grep "/opt/bin/chinadns_ng" | grep -v grep )" ] && logger -t "【chinadns_ng】" "停止 chinadns_ng" && chinadns_ng_close
	{ kill_ps "$scriptname" exit0; exit 0; }
fi
if [ "$chinadns_ng_enable" = "1" ] ; then
	if [ "$needed_restart" = "1" ] ; then
		chinadns_ng_close
		chinadns_ng_start
	else
		[ -z "$(ps -w | grep "/opt/bin/chinadns_ng" | grep -v grep )" ] && chinadns_ng_restart
		port=$(grep "server=127.0.0.1#$chinadns_ng_port"  /etc/storage/dnsmasq/dnsmasq.conf | wc -l)
		if [ "$port" = 0 ] ; then
			sleep 10
			port=$(grep "server=127.0.0.1#$chinadns_ng_port"  /etc/storage/dnsmasq/dnsmasq.conf | wc -l)
		fi
		if [ "$port" = 0 ] ; then
			logger -t "【chinadns_ng】" "检测:找不到 dnsmasq 转发规则, 重新添加"
			# 写入dnsmasq配置
			sed -Ei '/no-resolv|server=127.0.0.1|dns-forward-max=1000|min-cache-ttl=1800|chinadns_ng/d' /etc/storage/dnsmasq/dnsmasq.conf
			sed ":a;N;s/\n\n\n/\n\n/g;ba" -i  /etc/storage/dnsmasq/dnsmasq.conf
			cat >> "/etc/storage/dnsmasq/dnsmasq.conf" <<-EOF
no-resolv #chinadns_ng
server=127.0.0.1#$chinadns_ng_port #chinadns_ng
dns-forward-max=1000 #chinadns_ng
min-cache-ttl=1800 #chinadns_ng
domain-needed #chinadns_ng
EOF
			restart_on_dhcpd
		fi
	fi
fi
}

chinadns_ng_keep () {
logger -t "【chinadns_ng】" "守护进程启动"
if [ -s /tmp/script/_opt_script_check ]; then
sed -Ei '/【chinadns_ng】|^$/d' /tmp/script/_opt_script_check
if [ "$smartdns_enable" == "1" ] ; then
cat >> "/tmp/script/_opt_script_check" <<-OSC
	NUM=\`grep "/opt/bin/smartdns" /tmp/ps | grep -v grep |wc -l\` # 【chinadns_ng】
	if [ "\$NUM" -lt "1" ] || [ ! -s "/opt/bin/smartdns" ] ; then # 【chinadns_ng】
		logger -t "【chinadns_ng】" "smartdns重新启动\$NUM" # 【chinadns_ng】
		nvram set chinadns_ng_status=00 && eval "$scriptfilepath &" && sed -Ei '/【chinadns_ng】|^$/d' /tmp/script/_opt_script_check # 【chinadns_ng】
	fi # 【chinadns_ng】
	NUM=\`grep "/opt/bin/chinadns_ng" /tmp/ps | grep -v grep |wc -l\` # 【chinadns_ng】
	if [ "\$NUM" -lt "1" ] || [ ! -s "/opt/bin/chinadns_ng" ] ; then # 【chinadns_ng】
		logger -t "【chinadns_ng】" "chinadns_ng重新启动\$NUM" # 【chinadns_ng】
		nvram set chinadns_ng_status=00 && eval "$scriptfilepath &" && sed -Ei '/【chinadns_ng】|^$/d' /tmp/script/_opt_script_check # 【chinadns_ng】
	fi # 【chinadns_ng】
OSC
else
cat >> "/tmp/script/_opt_script_check" <<-OSC
	NUM=\`grep "/opt/bin/dns2tcp" /tmp/ps | grep -v grep |wc -l\` # 【chinadns_ng】
	if [ "\$NUM" -lt "1" ] || [ ! -s "/opt/bin/dns2tcp" ] ; then # 【chinadns_ng】
		logger -t "【chinadns_ng】" "dns2tcp重新启动\$NUM" # 【chinadns_ng】
		nvram set chinadns_ng_status=00 && eval "$scriptfilepath &" && sed -Ei '/【chinadns_ng】|^$/d' /tmp/script/_opt_script_check # 【chinadns_ng】
	fi # 【chinadns_ng】
	NUM=\`grep "/opt/bin/chinadns_ng" /tmp/ps | grep -v grep |wc -l\` # 【chinadns_ng】
	if [ "\$NUM" -lt "1" ] || [ ! -s "/opt/bin/chinadns_ng" ] ; then # 【chinadns_ng】
		logger -t "【chinadns_ng】" "chinadns_ng重新启动\$NUM" # 【chinadns_ng】
		nvram set chinadns_ng_status=00 && eval "$scriptfilepath &" && sed -Ei '/【chinadns_ng】|^$/d' /tmp/script/_opt_script_check # 【chinadns_ng】
	fi # 【chinadns_ng】
OSC
fi
#return
fi
sleep 60
chinadns_ng_enable=`nvram get app_102` #chinadns_ng_enable
while [ "$chinadns_ng_enable" = "1" ]; do
	NUM=`ps -w | grep "/opt/bin/chinadns_ng" | grep -v grep |wc -l`
	if [ "$NUM" -lt "1" ] || [ ! -s "/opt/bin/chinadns_ng" ] ; then
		logger -t "【chinadns_ng】" "重新启动$NUM"
		chinadns_ng_restart
	fi
	port=$(grep "server=127.0.0.1#$chinadns_ng_port"  /etc/storage/dnsmasq/dnsmasq.conf | wc -l)
	if [ "$port" = 0 ] ; then
		sleep 10
		port=$(grep "server=127.0.0.1#$chinadns_ng_port"  /etc/storage/dnsmasq/dnsmasq.conf | wc -l)
	fi
	if [ "$port" = 0 ] ; then
		logger -t "【chinadns_ng】" "检测:找不到 dnsmasq 转发规则, 重新添加"
		# 写入dnsmasq配置
		sed -Ei '/no-resolv|server=127.0.0.1|dns-forward-max=1000|min-cache-ttl=1800|chinadns_ng/d' /etc/storage/dnsmasq/dnsmasq.conf
		sed ":a;N;s/\n\n\n/\n\n/g;ba" -i  /etc/storage/dnsmasq/dnsmasq.conf
		cat >> "/etc/storage/dnsmasq/dnsmasq.conf" <<-EOF
no-resolv #chinadns_ng
server=127.0.0.1#$chinadns_ng_port #chinadns_ng
dns-forward-max=1000 #chinadns_ng
min-cache-ttl=1800 #chinadns_ng
domain-needed #chinadns_ng
EOF
		restart_on_dhcpd
	fi
sleep 69
chinadns_ng_enable=`nvram get app_102` #chinadns_ng_enable
done
}

chinadns_ng_close () {
kill_ps "$scriptname keep"
sed -Ei '/【chinadns_ng】|^$/d' /tmp/script/_opt_script_check
sed -Ei '/no-resolv|server=127.0.0.1|dns-forward-max=1000|min-cache-ttl=1800|chinadns_ng/d' /etc/storage/dnsmasq/dnsmasq.conf
sed ":a;N;s/\n\n\n/\n\n/g;ba" -i  /etc/storage/dnsmasq/dnsmasq.conf
restart_on_dhcpd
killall  chinadns_ng dns2tcp smartdns
killall -9  chinadns_ng dns2tcp smartdns
kill_ps "/tmp/script/_app19"
kill_ps "_chinadns_ng.sh"
kill_ps "$scriptname"
}

chinadns_ng_start () {
check_webui_yes
SVC_PATH="$(which chinadns_ng)"
[ ! -s "$SVC_PATH" ] && SVC_PATH="/opt/bin/chinadns_ng"
[[ "$("$SVC_PATH" -h | wc -l)" -lt 2 ]] && rm -rf "$SVC_PATH"
if [ ! -s "$SVC_PATH" ] ; then
	logger -t "【chinadns_ng】" "找不到 $SVC_PATH，安装 opt 程序"
	/etc/storage/script/Sh01_mountopt.sh start
fi
for h_i in $(seq 1 2) ; do
[[ "$(chinadns_ng -h 2>&1 | wc -l)" -lt 2 ]] && rm -rf /opt/bin/chinadns_ng
wgetcurl_file "$SVC_PATH" "$hiboyfile/chinadns_ng" "$hiboyfile2/chinadns_ng"
done
if [ ! -s "$SVC_PATH" ] ; then
	logger -t "【chinadns_ng】" "找不到 $SVC_PATH ，需要手动安装 $SVC_PATH"
	logger -t "【chinadns_ng】" "启动失败, 10 秒后自动尝试重新启动" && sleep 10 && chinadns_ng_restart x
else
ln -sf /opt/bin/chinadns_ng /opt/bin/chinadns-ng
fi

if [ "$smartdns_enable" == "1" ] ; then
for h_i in $(seq 1 2) ; do
[[ "$(smartdns -h 2>&1 | wc -l)" -lt 2 ]] && rm -rf /opt/bin/smartdns
#检查  libssl.so.1.0.0
[ -f /lib/libssl.so.1.0.0 ] && libssl_so="libssl.so.1.0.0"
[ -f /lib/libssl.so.1.1 ] && libssl_so="libssl.so.1.1"
wgetcurl_file /opt/bin/smartdns "$hiboyfile/$libssl_so/smartdns" "$hiboyfile2/$libssl_so/smartdns"
done
if [ ! -s "/opt/bin/smartdns" ] ; then
	logger -t "【chinadns_ng】" "找不到 /opt/bin/smartdns ，需要手动安装 /opt/bin/smartdns"
	logger -t "【chinadns_ng】" "启动失败, 10 秒后自动尝试重新启动" && sleep 10 && chinadns_ng_restart x
fi
logger -t "【chinadns_ng】" "运行 /opt/bin/smartdns"
smartdns_v=`smartdns -v`
nvram set smartdns_v="$smartdns_v"
eval "/opt/bin/smartdns -c /etc/storage/app_23.sh" &
else
for h_i in $(seq 1 2) ; do
[[ "$(dns2tcp -h 2>&1 | wc -l)" -lt 2 ]] && rm -rf /opt/bin/dns2tcp
wgetcurl_file /opt/bin/dns2tcp "$hiboyfile/dns2tcp" "$hiboyfile2/dns2tcp"
done
if [ ! -s "/opt/bin/dns2tcp" ] ; then
	logger -t "【chinadns_ng】" "找不到 /opt/bin/dns2tcp ，需要手动安装 /opt/bin/dns2tcp"
	logger -t "【chinadns_ng】" "启动失败, 10 秒后自动尝试重新启动" && sleep 10 && chinadns_ng_restart x
fi
logger -t "【chinadns_ng】" "运行 /opt/bin/dns2tcp"
cmd_name="dns2tcp"
eval "/opt/bin/dns2tcp -L0.0.0.0#55353 -R8.8.8.8#53 $cmd_log" &
fi
# 配置参数 '/opt/bin/chinadns_ng -l 8053  -n -b 0.0.0.0 -c 223.5.5.5 -t 127.0.0.1#55353 -g /opt/app/chinadns_ng/gfwlist.txt  '
usage=" -l $chinadns_ng_port "
if [ "$smartdns_enable" == "1" ] ; then
usage="$usage $smartdns_usage "
else
usage="$usage $chinadns_ng_usage "
fi
update_app
chinadns_ng_v=`chinadns_ng -V | awk -F ' ' '{print $2;}'`
nvram set chinadns_ng_v="$chinadns_ng_v"

[ ! -f /opt/app/chinadns_ng/gfwlist.txt ] && update_gfwlist
[ ! -f /opt/app/chinadns_ng/chnlist.txt ] && update_chnlist
chnroute_Number=$(ipset list chnroute -t | awk -F: '/Number/{print $2}' | sed -e s/\ //g)
[ "$chnroute_Number" == "0" ] || [ -z "$chnroute_Number" ] && update_chnroute
chnroute6_Number=$(ipset list chnroute6 -t | awk -F: '/Number/{print $2}' | sed -e s/\ //g)
[ "$chnroute6_Number" == "0" ] || [ -z "$chnroute6_Number" ] && update_chnroute6


killall dnsproxy && killall -9 dnsproxy 2>/dev/null
killall pdnsd && killall -9 pdnsd 2>/dev/null
killall chinadns && killall -9 chinadns 2>/dev/null
logger -t "【chinadns_ng】" "运行 $SVC_PATH"
cmd_name="chinadns_ng"
eval "/opt/bin/chinadns_ng $usage $cmd_log" &
sleep 2
if [ "$smartdns_enable" == "1" ] ; then
[ ! -z "$(ps -w | grep "/opt/bin/chinadns_ng" | grep -v grep )" ] && [ ! -z "$(ps -w | grep "/opt/bin/smartdns" | grep -v grep )" ] && logger -t "【chinadns_ng】" "启动成功 $chinadns_ng_v " && chinadns_ng_restart o
[ -z "$(ps -w | grep "/opt/bin/chinadns_ng" | grep -v grep )" ] && logger -t "【chinadns_ng】" "/opt/bin/chinadns_ng 启动失败, 注意检查端口是否有冲突,程序是否下载完整,10 秒后自动尝试重新启动" && sleep 10 && chinadns_ng_restart x
[ -z "$(ps -w | grep "/opt/bin/smartdns" | grep -v grep )" ] && logger -t "【chinadns_ng】" "/opt/bin/smartdns 启动失败, 注意检查端口是否有冲突,程序是否下载完整,10 秒后自动尝试重新启动" && sleep 10 && chinadns_ng_restart x
else
[ ! -z "$(ps -w | grep "/opt/bin/chinadns_ng" | grep -v grep )" ] && [ ! -z "$(ps -w | grep "/opt/bin/dns2tcp" | grep -v grep )" ] && logger -t "【chinadns_ng】" "启动成功 $chinadns_ng_v " && chinadns_ng_restart o
[ -z "$(ps -w | grep "/opt/bin/chinadns_ng" | grep -v grep )" ] && logger -t "【chinadns_ng】" "/opt/bin/chinadns_ng 启动失败, 注意检查端口是否有冲突,程序是否下载完整,10 秒后自动尝试重新启动" && sleep 10 && chinadns_ng_restart x
[ -z "$(ps -w | grep "/opt/bin/dns2tcp" | grep -v grep )" ] && logger -t "【chinadns_ng】" "/opt/bin/dns2tcp 启动失败, 注意检查端口是否有冲突,程序是否下载完整,10 秒后自动尝试重新启动" && sleep 10 && chinadns_ng_restart x
fi
initopt

# 写入dnsmasq配置
sed -Ei '/no-resolv|server=127.0.0.1|dns-forward-max=1000|min-cache-ttl=1800|chinadns_ng/d' /etc/storage/dnsmasq/dnsmasq.conf
sed ":a;N;s/\n\n\n/\n\n/g;ba" -i  /etc/storage/dnsmasq/dnsmasq.conf
	cat >> "/etc/storage/dnsmasq/dnsmasq.conf" <<-EOF
no-resolv #chinadns_ng
server=127.0.0.1#$chinadns_ng_port #chinadns_ng
dns-forward-max=1000 #chinadns_ng
min-cache-ttl=1800 #chinadns_ng
domain-needed #chinadns_ng
EOF

restart_on_dhcpd

chinadns_ng_get_status
eval "$scriptfilepath keep &"
exit 0
}

update_chnlist () {
nvram set app_111=4 && Sh99_ss_tproxy.sh
cat /opt/app/ss_tproxy/rule/chnlist.txt | grep -v '^#' | sed -e 's@^cn$@com.cn@g' | sort -u | grep -v "^$" > /opt/app/chinadns_ng/chnlist.txt

}

update_gfwlist () {
nvram set app_111=3 && Sh99_ss_tproxy.sh
cat /etc/storage/basedomain.txt | grep -v '^#' | sort -u | grep -v "^$" > /opt/app/chinadns_ng/gfwlist.txt

}

update_chnroute () {
nvram set app_111=2 && Sh99_ss_tproxy.sh
ipset -! -N chnroute hash:net family inet
ipset -! create chnroute hash:net family inet
cat /etc/storage/china_ip_list.txt | grep -v '^#' | sort -u | grep -v "^$" | grep -E -o '([0-9]+\.){3}[0-9/]+' | sed -e "s/^/-A chnroute &/g" | ipset -! restore


}

update_chnroute6 () {
nvram set app_111=26 && Sh99_ss_tproxy.sh
ipset -! -N chnroute6 hash:net family inet6
ipset -! create chnroute6 hash:net family inet6
/opt/app/ss_tproxy/rule/chnroute6.txt | grep -v '^#' | sort -u | grep -v "^$" | sed -e "s/^/-A chnroute6 &/g" | ipset -! restore

}

initopt () {
mkdir -p /opt/app/chinadns_ng
optPath=`grep ' /opt ' /proc/mounts | grep tmpfs`
[ ! -z "$optPath" ] && return
if [ ! -z "$(echo $scriptfilepath | grep -v "/opt/etc/init")" ] && [ -s "/opt/etc/init.d/rc.func" ] ; then
	{ echo '#!/bin/bash' ; echo $scriptfilepath '"$@"' '&' ; } > /opt/etc/init.d/$scriptname && chmod 777  /opt/etc/init.d/$scriptname
fi

}

initconfig () {

app_23="/etc/storage/app_23.sh"
if [ ! -f "$app_23" ] || [ ! -s "$app_23" ] ; then
	cat > "$app_23" <<-\EEE
# DNS服务器名称, defaut is host name
server-name smartdns

# 附加配置文件
# conf-file [file]
# conf-file /etc/storage/smartdns.more.conf

# dns服务器绑定ip和端口，默认dns服务器端口为53，支持绑定多个ip和端口
# bind udp server
#   bind [IP]:[port] [-group [group]] [-no-rule-addr] [-no-rule-nameserver] [-no-rule-ipset] [-no-speed-check] [-no-cache] [-no-rule-soa] [-no-dualstack-selection]
# bind tcp server
#   bind-tcp [IP]:[port] [-group [group]] [-no-rule-addr] [-no-rule-nameserver] [-no-rule-ipset] [-no-speed-check] [-no-cache] [-no-rule-soa] [-no-dualstack-selection]
# option:
#   -group: 请求时使用的DNS服务器组。
#   -no-rule-addr: 跳过address规则。
#   -no-rule-nameserver: 跳过Nameserver规则。
#   -no-rule-ipset: 跳过Ipset规则。
#   -no-speed-check: 停用测速。
#   -no-cache: 停止缓存。
#   -no-rule-soa: 跳过SOA(#)规则。
#   -no-dualstack-selection: 停用双栈测速。
# example: 
#  IPV4: 
#    bind :53
#    bind :6053 -group office -no-speed-check
#  IPV6:
#    bind [::]:53
#    bind-tcp [::]:53
bind 0.0.0.0:8051 -group china
bind 0.0.0.0:8052 -group office

# china 服务器
server 119.29.29.29 -group china
server 114.114.114.114 -group china
server 223.5.5.5 -group china
server 1.2.4.8 -group china
#server 240c::6666 -group china
#server 240c::6644 -group china

# office 服务器 https://kb.adguard.com/en/general/dns-providers
# Google DNS
server 8.8.8.8 -group office
#server 2001:4860:4860::8888 -group office
server-https https://dns.google/dns-query -group office
server-tcp 8.8.8.8 -group office
server-tls 8.8.8.8 -group office
# Cloudflare DNS
server 1.1.1.1 -group office
#server 2606:4700:4700::1111 -group office
server-https https://dns.cloudflare.com/dns-query -group office
server-tls 1.1.1.1 -group office
# adguard
#server 176.103.130.130 -group office
#server 2a00:5a60::ad1:0ff -group office
#server-https https://dns.adguard.com/dns-query -group office
# OpenDNS
server 208.67.222.222 -group office
server-tcp 208.67.222.222:443 -group office
#server 2620:119:35::35 -group office
# Yandex
#server 77.88.8.8 -group office
#server 2a02:6b8::feed:0ff -group office
# Neustar Recursive
#server 156.154.70.1 -group office
#server 2610:a1:1018::1 -group office
# verisign
#server 64.6.64.6 -group office
#server 2620:74:1b::1:1 -group office
# Quad101
#server 101.101.101.101 -group office
#server 2001:de4::101 -group office
# safedns
#server 195.46.39.39 -group office

# TCP链接空闲超时时间
# tcp-idle-time [second]
#tcp-idle-time 120

# 域名结果缓存个数
# cache-size [number]
#   0: for no cache
cache-size 512

# 域名预先获取功能
# prefetch-domain [yes|no]
prefetch-domain yes

# 假冒IP地址过滤
# bogus-nxdomain [ip/subnet]

# 黑名单IP地址
# blacklist-ip [ip/subnet]

# 白名单IP地址
# whitelist-ip [ip/subnet]

# 忽略IP地址
# ignore-ip [ip/subnet]

# 测速模式选择
# speed-check-mode [ping|tcp:port|none|,]
# example:
#   speed-check-mode ping,tcp:80
#   speed-check-mode tcp:443,ping
#   speed-check-mode none

# 强制AAAA地址返回SOA
# force-AAAA-SOA [yes|no]

# 启用IPV4，IPV6双栈IP优化选择策略
# dualstack-ip-selection-threshold [num] (0~1000)
# dualstack-ip-selection [yes|no]
# dualstack-ip-selection yes

# edns客户端子网
# edns-client-subnet [ip/subnet]
# edns-client-subnet 192.168.1.1/24
# edns-client-subnet [8::8]/56

# ttl用于所有资源记录
# rr-ttl: 所有记录的ttl
# rr-ttl-min: 资源记录的最小ttl
# rr-ttl-max: 资源记录的最大ttl
# example:
# rr-ttl 300
rr-ttl-min 300
# rr-ttl-max 86400

# 设置日志级别
# log-level: [level], level=fatal, error, warn, notice, info, debug
# log-file: 日志文件的文件路径。
# log-size: log-size：每个日志文件的大小，支持k，m，g
# log-num: number of logs
#log-level warn
#log-file /tmp/syslog.log
# log-size 128k
# log-num 2

# DNS审核
# audit-enable [yes|no]: 启用或禁用审核。
# audit-enable yes
# audit-SOA [yes|no]: 启用或禁用日志soa结果。
# 每个审核文件的audit-size大小，支持k，m，g
# audit-file /var/log/smartdns-audit.log
# audit-size 128k
# audit-num 2

# 远程udp dns服务器列表
# server [IP]:[PORT] [-blacklist-ip] [-whitelist-ip] [-check-edns] [-group [group] ...] [-exclude-default-group]
# 默认端口为53
#   -blacklist-ip: 使用黑名单ip过滤结果
#   -whitelist-ip: 过滤白名单ip的结果，白名单ip的结果将被接受。
#   -check-edns: 结果必须存在edns RR，或丢弃结果。
#   -group [group]: set server to group, use with nameserver /domain/group.
#   -exclude-default-group: 将此服务器从默认组中排除。
# server 8.8.8.8 -blacklist-ip -check-edns -group g1 -group g2

# 远程tcp dns服务器列表
# server-tcp [IP]:[PORT] [-blacklist-ip] [-whitelist-ip] [-group [group] ...] [-exclude-default-group]
# 默认端口为53
# server-tcp 8.8.8.8

# 远程tls dns服务器列表
# server-tls [IP]:[PORT] [-blacklist-ip] [-whitelist-ip] [-spki-pin [sha256-pin]] [-group [group] ...] [-exclude-default-group]
#   -spki-pin: TLS spki pin to verify.
#   -tls-host-check: cert hostname to verify.
#   -hostname: TLS sni hostname.
# Get SPKI with this command:
#    echo | openssl s_client -connect '[ip]:853' | openssl x509 -pubkey -noout | openssl pkey -pubin -outform der | openssl dgst -sha256 -binary | openssl enc -base64
# default port is 853
# server-tls 8.8.8.8
# server-tls 1.0.0.1

# 远程https dns服务器列表
# server-https https://[host]:[port]/path [-blacklist-ip] [-whitelist-ip] [-spki-pin [sha256-pin]] [-group [group] ...] [-exclude-default-group]
#   -spki-pin: TLS spki pin to verify.
#   -tls-host-check: cert hostname to verify.
#   -hostname: TLS sni hostname.
#   -http-host: http host.
# default port is 443
# server-https https://cloudflare-dns.com/dns-query

# 指定域名使用server组解析
# nameserver /domain/[group|-]
# nameserver /www.example.com/office, Set the domain name to use the appropriate server group.
# nameserver /www.example.com/-, ignore this domain
nameserver /opt.cn2qq.com/office

# 指定域名IP地址
# address /domain/[ip|-|-4|-6|#|#4|#6]
# address /www.example.com/1.2.3.4, return ip 1.2.3.4 to client
# address /www.example.com/-, ignore address, query from upstream, suffix 4, for ipv4, 6 for ipv6, none for all
# address /www.example.com/#, return SOA to client, suffix 4, for ipv4, 6 for ipv6, none for all

# 设置IPSET超时功能启用
# ipset-timeout yes

# 指定 ipset 使用域名
# ipset /domain/[ipset|-]
# ipset /www.example.com/block, set ipset with ipset name of block 
# ipset /www.example.com/-, ignore this domain

EEE
	chmod 755 "$app_23"
fi

}

initconfig


update_app () {
if [ "$1" = "update_asp" ] ; then
	rm -rf /opt/app/chinadns_ng/Advanced_Extensions_chinadns_ng.asp
fi
if [ "$1" = "del" ] ; then
	rm -rf /opt/bin/dns2tcp /opt/opt_backup/bin/dns2tcp /opt/bin/smartdns /opt/opt_backup/bin/smartdns /opt/bin/chinadns_ng /opt/opt_backup/bin/chinadns_ng /opt/app/chinadns_ng/Advanced_Extensions_chinadns_ng.asp /opt/app/chinadns_ng/gfwlist.txt /opt/app/chinadns_ng/chnroute6.ipset /opt/app/chinadns_ng/chnroute.ipset
fi
# 加载程序配置页面
mkdir -p /opt/app/chinadns_ng
if [ ! -f "/opt/app/chinadns_ng/Advanced_Extensions_chinadns_ng.asp" ] || [ ! -s "/opt/app/chinadns_ng/Advanced_Extensions_chinadns_ng.asp" ] ; then
	wgetcurl.sh /opt/app/chinadns_ng/Advanced_Extensions_chinadns_ng.asp "$hiboyfile/Advanced_Extensions_chinadns_ngasp" "$hiboyfile2/Advanced_Extensions_chinadns_ngasp"
fi
umount /www/Advanced_Extensions_app19.asp
mount --bind /opt/app/chinadns_ng/Advanced_Extensions_chinadns_ng.asp /www/Advanced_Extensions_app19.asp
# 更新程序启动脚本
[ "$1" = "del" ] && /etc/storage/www_sh/chinadns_ng del &
}

case $ACTION in
start)
	chinadns_ng_close
	chinadns_ng_check
	;;
check)
	chinadns_ng_check
	;;
stop)
	chinadns_ng_close
	;;
keep)
	#chinadns_ng_check
	chinadns_ng_keep
	;;
updateapp19)
	chinadns_ng_restart o
	[ "$chinadns_ng_enable" = "1" ] && nvram set chinadns_ng_status="updatechinadns_ng" && logger -t "【chinadns_ng】" "更新规则" && { update_chnlist; update_gfwlist; update_chnroute; update_chnroute6; chinadns_ng_restart; }
	[ "$chinadns_ng_enable" != "1" ] && nvram set chinadns_ng_v="" && logger -t "【chinadns_ng】" "更新" && update_app del
	;;
update_app)
	update_app
	;;
update_asp)
	update_app update_asp
	;;
*)
	chinadns_ng_check
	;;
esac

