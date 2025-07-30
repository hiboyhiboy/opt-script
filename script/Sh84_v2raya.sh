#!/bin/bash
#copyright by hiboy
source /etc/storage/script/init.sh
v2raya_enable=`nvram get app_146`
[ -z $v2raya_enable ] && v2raya_enable=0 && nvram set app_146=0
v2raya_usage="$(nvram get app_147)"
[ -z "$v2raya_usage" ] && v2raya_usage="-a 0.0.0.0:2017" && nvram set app_147="$v2raya_usage"
v2ray_path=`nvram get v2ray_path`
[ -z $v2ray_path ] && v2ray_path="/opt/bin/v2ray" && nvram set v2ray_path=$v2ray_path

if [ "$v2raya_enable" != "0" ] ; then

ss_udp_enable=`nvram get ss_udp_enable` #udp转发  0、停用；1、启动
[ -z $ss_udp_enable ] && ss_udp_enable=0 && nvram set ss_udp_enable=0
app_114=`nvram get app_114` #0:代理本机流量; 1:跳过代理本机流量
[ -z $app_114 ] && app_114=0 && nvram set app_114=0
ss_ip46=`nvram get ss_ip46`
[ -z $ss_ip46 ] && ss_ip46=0 && nvram set ss_ip46=0
LAN_AC_IP=`nvram get LAN_AC_IP`
[ -z $LAN_AC_IP ] && LAN_AC_IP=0 && nvram set LAN_AC_IP=$LAN_AC_IP
ss_DNS_Redirect=`nvram get ss_DNS_Redirect`
ss_DNS_Redirect_IP=`nvram get ss_DNS_Redirect_IP`
[ -z "$ss_DNS_Redirect_IP" ] && ss_DNS_Redirect_IP=$lan_ipaddr
tTYPE=""

v2raya_renum=`nvram get v2raya_renum`
v2raya_renum=${v2raya_renum:-"0"}

cmd_log_enable=`nvram get cmd_log_enable`
cmd_name="v2rayA"
cmd_log=""
if [ "$cmd_log_enable" = "1" ] || [ "$v2raya_renum" -gt "0" ] ; then
	cmd_log="$cmd_log2"
fi

fi

if [ ! -z "$(echo $scriptfilepath | grep -v "/tmp/script/" | grep v2raya)" ] && [ ! -s /tmp/script/_app29 ] ; then
	mkdir -p /tmp/script
	{ echo '#!/bin/bash' ; echo $scriptfilepath '"$@"' '&' ; } > /tmp/script/_app29
	chmod 777 /tmp/script/_app29
fi

v2raya_restart () {
i_app_restart "$@" -name="v2raya"
}

v2raya_get_status () {

B_restart="$v2raya_enable$v2raya_usage$v2ray_path"

i_app_get_status -name="v2raya" -valb="$B_restart"
}

v2raya_check () {

v2raya_get_status
if [ "$v2raya_enable" != "1" ] && [ "$needed_restart" = "1" ] ; then
	[ ! -z "`pidof v2raya`" ] && logger -t "【v2rayA】" "停止 v2raya" && v2raya_close
	{ kill_ps "$scriptname" exit0; exit 0; }
fi
if [ "$v2raya_enable" = "1" ] ; then
	if [ "$needed_restart" = "1" ] ; then
		v2raya_close
		v2raya_start
	else
		[ "$v2raya_enable" = "1" ] && [ -z "`pidof v2raya`" ] && v2raya_restart
	fi
fi
}

v2raya_keep () {
/etc/storage/script/sh_ezscript.sh 3 & #更新按钮状态
i_app_keep -name="v2raya" -pidof="v2raya" &

nvram set app_86=0
while true; do
	app_86="$(nvram get app_86)"
	[ -z "$app_86" ] && app_86=0
	if [ "$app_86" != 0 ] ; then
	if [ "$app_86" = "v2raya_t0" ] ; then
		nvram set app_86=0
		eval "$scriptfilepath transparent_disable &"
	fi
	if [ "$app_86" = "v2raya_t1_redirect" ] ; then
		tTYPE="redirect"
		nvram set app_86=0
		eval "$scriptfilepath transparent_enable &"
	fi
	if [ "$app_86" = "v2raya_t1_tproxy" ] ; then
		tTYPE="tproxy"
		nvram set app_86=0
		eval "$scriptfilepath transparent_enable &"
	fi
	fi
	sleep 10
done
}

v2raya_close () {
sed -Ei '/【v2raya】|^$/d' /tmp/script/_opt_script_check
Sh99_ss_tproxy.sh off_stop "Sh84_v2raya.sh"
killall v2raya v2core tproxyhook.sh corehook.sh
sleep 2
/etc/storage/script/sh_ezscript.sh 3 & #更新按钮状态
kill_ps "/tmp/script/_app29"
kill_ps "_v2raya.sh"
kill_ps "$scriptname"
}

v2raya_start () {
check_webui_yes
i_app_get_cmd_file -name="v2raya" -cmd="v2raya" -cpath="/opt/bin/v2raya" -down1="$hiboyfile/v2raya" -down2="$hiboyfile2/v2raya" -runh="--help"
v2raya_path="$SVC_PATH"

mkdir -p /opt/app/v2raya/core
mkdir -p /opt/app/v2raya/v2rayconfdir
optPath="`grep ' /opt ' /proc/mounts | grep tmpfs`"
Mem_total="$(free | sed -n '2p' | awk '{print $2;}')"
[ "$Mem_total" -lt 1024 ] && Mem_total="1024" || { [ "$Mem_total" -ge 1024 ] || Mem_total="1024" ; }
Mem_M=$(($Mem_total / 1024 ))
if [ ! -z "$optPath" ] || [ "$Mem_M" -lt "100" ] ; then
	[ ! -z "$optPath" ] && logger -t "【v2rayA】" " /opt/ 在内存储存"
	if [ "$Mem_M" -lt "200" ] ; then
		logger -t "【v2rayA】" "内存不足256M ，v2raya 可能无法正常运行！！！"
	fi
fi

[ ! -s /opt/app/v2raya/geoip.dat ] && wgetcurl_checkmd5 /opt/app/v2raya/geoip.dat "https://testingcf.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@release/geoip.dat" "$hiboyfile/geoip_s.dat" N
[ ! -s /opt/app/v2raya/geosite.dat ] && wgetcurl_checkmd5 /opt/app/v2raya/geosite.dat "https://testingcf.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@release/geosite.dat" "$hiboyfile/geosite_s.dat" N
[ -s /opt/app/v2raya/geosite.dat ] && ln -sf /opt/app/v2raya/geosite.dat /opt/app/v2raya/LoyalsoldierSite.dat

if [ ! -s "/etc/ssl/certs/ca-certificates.crt" ] ; then
	mkdir -p /opt/app/ipk/
	mkdir -p /opt/etc/ssl/certs
	rm -f /etc/ssl/certs
	ln -sf /opt/etc/ssl/certs  /etc/ssl/certs
	if [ ! -s "/etc/ssl/certs/ca-certificates.crt" ] && [ -s /etc_ro/certs.tgz ] ; then
		tar -xzvf /etc_ro/certs.tgz -C /opt/etc/ssl/ ; cd /opt
	fi
	if [ ! -s "/etc/ssl/certs/ca-certificates.crt" ] ; then
		logger -t "【opt】" "已挂载,找不到ca-certificates证书"
		logger -t "【opt】" "下载证书"
		wgetcurl.sh /opt/app/ipk/certs.tgz "$hiboyfile/certs.tgz" "$hiboyfile2/certs.tgz"
		[ -s /opt/app/ipk/certs.tgz ] && tar -xzvf /opt/app/ipk/certs.tgz -C /opt/etc/ssl/ ; cd /opt
		if [ ! -s "/etc/ssl/certs/ca-certificates.crt" ] ; then
			wgetcurl.sh /opt/app/ipk/certs.tgz "http://opt.cn2qq.com/opt-file/certs.tgz"
			[ -s /opt/app/ipk/certs.tgz ] && tar -xzvf /opt/app/ipk/certs.tgz -C /opt/etc/ssl/ ; cd /opt
		fi
		if [ ! -s "/etc/ssl/certs/ca-certificates.crt" ] ; then
			wgetcurl.sh /opt/app/ipk/certs.tgz "$(echo -n "$hiboyfile/certs.tgz" | sed -e "s/https:/http:/g")" "$(echo -n "$hiboyfile2/certs.tgz" | sed -e "s/https:/http:/g")"
		fi
		logger -t "【opt】" "安装证书"
		tar -xzvf /opt/app/ipk/certs.tgz -C /opt/etc/ssl/ ; cd /opt
		rm -f /opt/app/ipk/certs.tgz
	fi
	chmod 644 /etc/ssl/certs -R
	chmod 777 /etc/ssl/certs
	chmod 644 /opt/etc/ssl/certs -R
	chmod 777 /opt/etc/ssl/certs
fi
Available_A=$(df -m | grep "% /opt" | awk 'NR==1' | awk -F' ' '{print $4}')
size_tmpfs=`nvram get size_tmpfs`
if [ "$size_tmpfs" = "0" ] && [[ "$Available_A" -lt 15 ]] ; then
mount -o remount,size=60% tmpfs /tmp
Available_B=$(df -m | grep "% /opt" | awk 'NR==1' | awk -F' ' '{print $4}')
logger -t "【v2rayA】" "调整 /tmp 挂载分区的大小， /opt 可用空间： $Available_A → $Available_B M"
fi

v2ray_get_releases
if [ "$app_74" == "5" ] || [ "$app_74" == "6" ] ; then
	[[ "$($v2ray_path help 2>&1 | wc -l)" -lt 2 ]] && [ ! -z $v2ray_path ] && rm -rf $v2ray_path
	[ ! -s "$v2ray_path" ] && logger -t "【v2rayA】" "自动下载 V2ray-core v5 主程序"
	[ "$app_74" != "6" ] && nvram set app_74="6" && app_74="6"
	i_app_get_cmd_file -name="v2raya" -cmd="$v2ray_path" -cpath="/opt/bin/v2ray" -down1="$hiboyfile/v2ray-v2ray5" -down2="$hiboyfile2/v2ray-v2ray5" -runh="help"
else
	[[ "$($v2ray_path help 2>&1 | wc -l)" -lt 2 ]] && [ ! -z $v2ray_path ] && rm -rf $v2ray_path
	[ ! -s "$v2ray_path" ] && logger -t "【v2rayA】" "自动下载 Xray-core 主程序"
	[ "$app_74" != "4" ] && nvram set app_74="4" && app_74="4"
	i_app_get_cmd_file -name="v2raya" -cmd="$v2ray_path" -cpath="/opt/bin/v2ray" -down1="$hiboyfile/v2ray" -down2="$hiboyfile2/v2ray" -runh="help"
fi
if [ -s "$v2ray_path" ] ; then
	logger -t "【v2rayA】" "找到 $v2ray_path"
	chmod 777 "$(dirname "$v2ray_path")"
	chmod 777 $v2ray_path
fi
echo $($v2ray_path version 2>&1) > /opt/app/v2raya/core/v2core.version
v2raya_v=`$v2raya_path --version | head -n1`
nvram set v2raya_v="$v2raya_v"" 丨 ""$(cat /opt/app/v2raya/core/v2core.version | grep -Eo "^[^(]+" | sed -n '1p')"
logger -t "【v2rayA】" "设置 v2ray core 文件"
rm -f /opt/app/v2raya/core/v2core
ln -sf "$v2ray_path" /opt/app/v2raya/core/v2core
initconfig
logger -t "【v2rayA】" "运行 $v2raya_path"
su_cmd="eval"
gid_owner="0"
NUM=`iptables -m owner -h 2>&1 | grep owner | wc -l`
hash su 2>/dev/null && su_x="1"
hash su 2>/dev/null || su_x="0"
if [ "$NUM" -ge "3" ] && [ "$su_x" = "1" ] ; then
	addgroup -g 1321 ‍✈️
	adduser -G ‍✈️ -u 1321 ‍✈️ -D -S -H -s /bin/false
	sed -Ei s/1321:1321/0:1321/g /etc/passwd
	su_cmd="su ‍✈️ -s /bin/sh -c "
else
	ss_udp_enable=0
	nvram set ss_udp_enable=0
fi
nvram set app_86=0
cd /opt/app/v2raya
su_cmd2="$v2raya_path --v2ray-confdir /opt/app/v2raya/v2rayconfdir -c /opt/app/v2raya/config --v2ray-assetsdir /opt/app/v2raya  --log-file /opt/app/v2raya/log/v2raya.log --transparent-hook /opt/app/v2raya/core/tproxyhook.sh --core-hook /opt/app/v2raya/core/corehook.sh --v2ray-bin /opt/app/v2raya/core/v2run.sh --passcheckroot $v2raya_usage"
eval "$su_cmd" '"cmd_name=v2rayA ; '"$su_cmd2"' $cmd_log2"' &
sleep 3
i_app_keep -t -name="v2raya" -pidof="v2raya"
[ "$(nvram get ss_internet)" != "2" ] && nvram set ss_internet="2"
#v2raya_get_status
eval "$scriptfilepath keep &"
exit 0
}

ss_tproxy_set() {
ss_tproxy_auser=`nvram get ss_tproxy_auser`
if [ "$1" != "$ss_tproxy_auser" ] ; then
	logger -t "【v2rayA】" "脚本 [Sh99_ss_tproxy.sh] 当前使用者: $auser_b ，跳过 $auser_a 的运行命令"
	logger -t "【v2rayA】" "需要停用 $auser_b 后才能使用 $auser_a 运行 [Sh99_ss_tproxy.sh] 脚本"
	exit 1
fi
lan_ipaddr=`nvram get lan_ipaddr`
ss_tproxy_mode_x=`nvram get app_110`
[ -z $ss_tproxy_mode_x ] && ss_tproxy_mode_x=0 && nvram set app_110=0
[ "$ss_tproxy_mode_x" = "0" ] && logger -t "【v2rayA】" "【自动】设置 ss_tproxy 配置文件，配置导入中..."
[ "$ss_tproxy_mode_x" = "1" ] && logger -t "【v2rayA】" "【手动】设置 ss_tproxy 配置文件，跳过配置导入" && return
 # /etc/storage/app_27.sh
sstp_set mode='global'
[ "$ss_ip46" = "0" ] && { sstp_set ipv4='true' ; sstp_set ipv6='false' ; }
[ "$ss_ip46" = "1" ] && { sstp_set ipv4='false' ; sstp_set ipv6='true' ; }
[ "$ss_ip46" = "2" ] && { sstp_set ipv4='true' ; sstp_set ipv6='true' ; }
[ "$ss_ip46" = "0" ] && sstp_set tproxy='false' # true:TPROXY+TPROXY; false:REDIRECT+TPROXY
[ "$ss_ip46" != "0" ] && sstp_set tproxy='true'
[ "$tTYPE" = "redirect" ] && sstp_set tproxy='false' # true:TPROXY+TPROXY; false:REDIRECT+TPROXY
[ "$tTYPE" = "tproxy" ] && sstp_set tproxy='true'
[ "$tTYPE" = "redirect" ] && sstp_set ipv6='false'
tcponly='true'
NUM=`iptables -m owner -h 2>&1 | grep owner | wc -l`
hash su 2>/dev/null && su_x="1"
hash su 2>/dev/null || su_x="0"
if [ "$NUM" -ge "3" ] && [ "$su_x" = "1" ] ; then
	tcponly='false'
fi
sstp_set tcponly="$tcponly" # true:仅代理TCP流量; false:代理TCP和UDP流量
sstp_set selfonly='false'  # true:仅代理本机流量; false:代理本机及"内网"流量
nvram set app_112="0"      #app_112 0:自动开启第三方 DNS 程序(dnsproxy) ; 1:跳过自动开启第三方 DNS 程序但是继续把DNS绑定到 8053 端口的程序
#nvram set app_113="0"      #app_113 0:使用 8053 端口查询全部 DNS 时进行 China 域名加速 ; 1:不进行 China 域名加速
sstp_set uid_owner='0'          # 非 0 时进行用户ID匹配跳过代理本机流量
gid_owner="$(nvram get gid_owner)"
sstp_set gid_owner="$gid_owner" # 非 0 时进行组ID匹配跳过代理本机流量
## proxy
sstp_set proxy_all_svraddr="/opt/app/ss_tproxy/conf/proxy_all_svraddr.conf"
sstp_set proxy_svrport='1:65535'
sstp_set proxy_tcpport="52345"
sstp_set proxy_udpport="52345"
sstp_set proxy_startcmd='date'
sstp_set proxy_stopcmd='date'
## dns
wan_dnsenable_x="$(nvram get wan_dnsenable_x)"
[ "$wan_dnsenable_x" == "1" ] && DNS_china=`nvram get wan0_dns |cut -d ' ' -f1`
[ "$wan_dnsenable_x" != "1" ] && DNS_china=`nvram get wan_dns1_x |cut -d ' ' -f1`
[ -z "$DNS_china" ] && DNS_china="223.5.5.5"
sstp_set dns_direct="$DNS_china"
sstp_set dns_direct6='240C::6666'
sstp_set dns_remote='8.8.8.8#53'
sstp_set dns_remote6='::1#8053'
sstp_set dns_bind_port='8053'
## dnsmasq
sstp_set dnsmasq_bind_port='53'
sstp_set dnsmasq_conf_dir="/tmp/ss_tproxy/dnsmasq.d"
sstp_set dnsmasq_conf_file="/opt/app/ss_tproxy/dnsmasq_conf_file.txt"
sstp_set dnsmasq_conf_string="/opt/app/ss_tproxy/conf/dnsmasq_conf_string.conf"
## ipts
sstp_set lan_ipv4_ipaddr='127.0.0.1'
sstp_set ipts_set_snat='false'
sstp_set ipts_set_snat6='false'
sstp_set ipts_reddns_onstop='false'
[ "$ss_DNS_Redirect" == "1" ] && sstp_set ipts_reddns_onstart='true' # ss-tproxy start 后，是否将其它主机发至本机的 DNS 重定向至自定义 IPv4 地址
[ "$ss_DNS_Redirect" != "1" ] && sstp_set ipts_reddns_onstart='false'
sstp_set ipts_reddns_ip="$ss_DNS_Redirect_IP" # 自定义 DNS 重定向地址(只支持 IPv4 )
sstp_set ipts_proxy_dst_port_tcp="1:65535"
sstp_set ipts_proxy_dst_port_udp="1:65535"
sstp_set LAN_AC_IP="$LAN_AC_IP"
## opts
sstp_set opts_overwrite_resolv='false'
sstp_set opts_ip_for_check_net=''
## file
sstp_set file_gfwlist_txt='/opt/app/ss_tproxy/rule/gfwlist.txt'
sstp_set file_gfwlist_ext='/opt/app/ss_tproxy/gfwlist.ext'
sstp_set file_ignlist_ext='/opt/app/ss_tproxy/ignlist.ext'
sstp_set file_lanlist_ext='/etc/storage/shadowsocks_ss_spec_lan.sh'
sstp_set file_wanlist_ext='/etc/storage/shadowsocks_ss_spec_wan.sh'
sstp_set file_chnroute_txt='/opt/app/ss_tproxy/rule/chnroute.txt'
sstp_set file_chnroute6_txt='/opt/app/ss_tproxy/rule/chnroute6.txt'
sstp_set file_chnroute_set='/opt/app/ss_tproxy/chnroute.set'
sstp_set file_chnroute6_set='/opt/app/ss_tproxy/chnroute6.set'
sstp_set file_dnsserver_pid='/opt/app/ss_tproxy/.dnsserver.pid'

Sh99_ss_tproxy.sh initconfig

# 写入服务器地址
echo "" > /opt/app/ss_tproxy/conf/proxy_svraddr4.conf
echo "" > /opt/app/ss_tproxy/conf/proxy_svraddr6.conf
# SS
ss_server=`nvram get ss_server`
echo "$ss_server" > /opt/app/ss_tproxy/conf/proxy_all_svraddr.conf
# v2ray
#server_addresses=$(cat /etc/storage/v2ray_config_script.sh | tr -d ' ' | grep -Eo '"address":.+' | grep -v 8.8.8.8 | grep -v google.com | grep -v 114.114.114.114 | grep -v 119.29.29.29 | grep -v 223.5.5.5 | sed -n '1p' | cut -d':' -f2 | cut -d'"' -f2)
#echo "$server_addresses" >> /opt/app/ss_tproxy/conf/proxy_all_svraddr.conf
# clash
#grep '^  server: ' /etc/storage/app_20.sh | tr -d ' ' | sed -e 's/server://g' | sed -e 's/"\|'"'"'\| //g' | grep -v 8.8.8.8 | grep -v google.com | grep -v 114.114.114.114 | grep -v 119.29.29.29 | grep -v 223.5.5.5 >> /opt/app/ss_tproxy/conf/proxy_all_svraddr.conf
#cat /etc/storage/app_20.sh | tr -d ' ' | grep -E -o \"server\":\"\[\^\"\]+ | sed -e 's/server\|://g' | sed -e 's/"\|'"'"'\| //g' | grep -v 8.8.8.8 | grep -v google.com | grep -v 114.114.114.114 | grep -v 119.29.29.29 | grep -v 223.5.5.5 >> /opt/app/ss_tproxy/conf/proxy_all_svraddr.conf
kcptun_server=`nvram get kcptun_server`
echo "$kcptun_server" >> /opt/app/ss_tproxy/conf/proxy_all_svraddr.conf

# 链接配置文件
rm -f /opt/app/ss_tproxy/wanlist.ext
rm -f /opt/app/ss_tproxy/lanlist.ext
ln -sf /etc/storage/shadowsocks_ss_spec_wan.sh /opt/app/ss_tproxy/wanlist.ext
ln -sf /etc/storage/shadowsocks_ss_spec_lan.sh /opt/app/ss_tproxy/lanlist.ext
[ ! -s /opt/app/ss_tproxy/wanlist.ext ] && cp -f /etc/storage/shadowsocks_ss_spec_wan.sh /opt/app/ss_tproxy/wanlist.ext
[ ! -s /opt/app/ss_tproxy/lanlist.ext ] && cp -f /etc/storage/shadowsocks_ss_spec_lan.sh /opt/app/ss_tproxy/lanlist.ext
logger -t "【v2rayA】" "【自动】设置 ss_tproxy 配置文件，完成配置导入"
}

transparent_disable () {
	Sh99_ss_tproxy.sh off_stop "Sh84_v2raya.sh"
}

transparent_enable () {
# 透明代理
logger -t "【v2ray】" "启动 透明代理"
[ "$ss_udp_enable" = "0" ] && logger -t "【v2rayA】" "仅代理 TCP 流量"
[ "$ss_udp_enable" = "1" ] && logger -t "【v2rayA】" "代理 TCP 和 UDP 流量"
[ "$app_114" = "0" ] && logger -t "【v2rayA】" "启动路由自身流量走透明代理"
[ "$app_114" = "1" ] && logger -t "【v2rayA】" "停止路由自身流量走透明代理"


Sh99_ss_tproxy.sh auser_check "Sh84_v2raya.sh"
ss_tproxy_set "Sh84_v2raya.sh"
Sh99_ss_tproxy.sh on_start "Sh84_v2raya.sh"
#restart_on_dhcpd

logger -t "【v2rayA】" "载入 透明代理 转发规则设置"

# 同时将代理规则应用到 OUTPUT 链, 让路由自身流量走透明代理
if [ "$app_114" = 0 ] ; then
logger -t "【v2rayA】" "同时将透明代理规则应用到 OUTPUT 链, 让路由自身流量走透明代理"
fi
logger -t "【v2rayA】" "完成 透明代理 转发规则设置"
logger -t "【v2rayA】" "启动后若发现一些网站打不开, 估计是 DNS 被污染了. 解决 DNS 被污染方法："
logger -t "【v2rayA】" "①电脑设置 DNS 自动获取路由 ip。检查 hosts 是否有错误规则。"
logger -t "【v2rayA】" "②电脑运行 cmd 输入【ipconfig /flushdns】, 清理浏览器缓存。"
# 透明代理
[ "$(nvram get ss_internet)" != "1" ] && nvram set ss_internet="1"

}

initconfig () {

v2run="/opt/app/v2raya/core/v2run.sh"
if [ -z "$(cat "$v2run" | grep "版本：2024-04-29")" ] ; then
	rm -f "$v2run"
fi
if [ ! -f "$v2run" ] || [ ! -s "$v2run" ] ; then
	cat > "$v2run" <<-\EEE
#!/bin/sh
# 此脚本路径：/opt/app/v2raya/core/v2run.sh
# 版本：2024-04-29
# logger -t "【v2rayA】" "v2run，启动参数： $@"
# cd /opt/app/v2raya
if [ "$1" = "version" ] ; then
	cat /opt/app/v2raya/core/v2core.version | head -n1
	exit 0
else
	eval $(ps -w | grep "v2core" | grep -v $$ | grep -v grep | awk '{print "kill "$1";";}')
	sleep 2
	export V2RAY_CONF_GEOLOADER=memconservative
	/opt/app/v2raya/core/v2core "$@"
fi

EEE
	chmod 777 "$v2run"
fi

tproxyhook="/opt/app/v2raya/core/tproxyhook.sh"
if [ -z "$(cat "$tproxyhook" | grep "版本：2024-04-13")" ] ; then
	rm -f "$tproxyhook"
fi
if [ ! -f "$tproxyhook" ] || [ ! -s "$tproxyhook" ] ; then
	cat > "$tproxyhook" <<-\EEE
#!/bin/bash
# 此脚本路径：/opt/app/v2raya/core/tproxyhook.sh
# 版本：2024-04-13
# parse the arguments
for i in "$@"; do
  case $i in
    --transparent-type=*)
      tTYPE="${i#*=}"
      shift
      ;;
    --stage=*)
      STAGE="${i#*=}"
      shift
      ;;
    --v2raya-confdir=*)
      V2CONFIDR="${i#*=}"
      shift
      ;;
    -*|--*)
      echo "Unknown option $i"
      shift
      ;;
    *)
      ;;
  esac
done

# pre-start, post-start, pre-stop, post-stop
# 启动前、启动后、停止前、停止后
case "$STAGE" in
post-start)
  # 启动后
if [ "$tTYPE" = "tproxy" ] ; then
	logger -t "【v2rayA】" "tproxy-hook 启动后， $tTYPE"
elif [ "$tTYPE" = "redirect" ] ; then
	logger -t "【v2rayA】" "tproxy-hook 启动后， $tTYPE"

else
	logger -t "【v2rayA】" "tproxy-hook 启动后， $tTYPE"
	logger -t "【v2rayA】" "无效的透明代理类型， $tTYPE"
	exit 1
fi
	nvram set app_86="v2raya_t1_$tTYPE"
exit 0
  ;;
post-stop)
  # 停止后
if [ "$tTYPE" = "tproxy" ] ; then
	logger -t "【v2rayA】" "tproxy-hook 停止后， $tTYPE"
elif [ "$tTYPE" = "redirect" ] ; then
	logger -t "【v2rayA】" "tproxy-hook 停止后， $tTYPE"
else
	logger -t "【v2rayA】" "tproxy-hook 停止后， $tTYPE"
	logger -t "【v2rayA】" "无效的透明代理类型， $tTYPE"
	exit 1
fi
	nvram set app_86="v2raya_t0"
exit 0
  ;;
*)
  ;;
esac

exit 0

EEE
	chmod 777 "$tproxyhook"
fi

corehook="/opt/app/v2raya/core/corehook.sh"
if [ -z "$(cat "$corehook" | grep "版本：2024-04-13")" ] ; then
	rm -f "$corehook"
fi

if [ ! -f "$corehook" ] || [ ! -s "$corehook" ] ; then
	cat > "$corehook" <<-\EEE
#!/bin/bash
# 此脚本路径：/opt/app/v2raya/core/corehook.sh
# 版本：2024-04-13
# parse the arguments
for i in "$@"; do
  case $i in
    --stage=*)
      STAGE="${i#*=}"
      shift
      ;;
    --v2raya-confdir=*)
      V2CONFIDR="${i#*=}"
      shift
      ;;
    -*|--*)
      echo "Unknown option $i"
      shift
      ;;
    *)
      ;;
  esac
done

# pre-start, post-start, pre-stop, post-stop
# 启动前、启动后、停止前、停止后
case "$STAGE" in
pre-start)
  # 启动前
	chmod 777 /opt/app/v2raya -R
	exit 0
  ;;
post-start)
  # 启动后
	[ "$(nvram get ss_internet)" != "1" ] && nvram set ss_internet="1"
	exit 0
  ;;
pre-stop)
  # 停止前
	nvram set app_86="v2raya_t0"
	exit 0
  ;;
post-stop)
  # 停止后
	eval $(ps -w | grep "v2core" | grep -v $$ | grep -v grep | awk '{print "kill "$1";";}')
	[ "$(nvram get ss_internet)" != "0" ] && nvram set ss_internet="0"
	exit 0
  ;;
*)
  ;;
esac

exit 0

EEE
	chmod 777 "$corehook"
fi

}

# initconfig

update_app () {

mkdir -p /opt/app/v2raya
if [ "$1" = "del" ] ; then
	rm -rf /opt/app/v2raya/Advanced_Extensions_v2raya.asp
	rm -rf /opt/bin/v2raya /opt/opt_backup/bin/v2raya
fi

# initconfig

# 加载程序配置页面
if [ ! -f "/opt/app/v2raya/Advanced_Extensions_v2raya.asp" ] || [ ! -s "/opt/app/v2raya/Advanced_Extensions_v2raya.asp" ] ; then
	wgetcurl.sh /opt/app/v2raya/Advanced_Extensions_v2raya.asp "$hiboyfile/Advanced_Extensions_v2rayaasp" "$hiboyfile2/Advanced_Extensions_v2rayaasp"
fi
umount /www/Advanced_Extensions_app29.asp
mount --bind /opt/app/v2raya/Advanced_Extensions_v2raya.asp /www/Advanced_Extensions_app29.asp
# 更新程序启动脚本

[ "$1" = "del" ] && /etc/storage/www_sh/v2raya del &
}

v2ray_get_releases(){
app_74="$(nvram get app_74)"
link_get=""
if [ "$app_74" == "0" ] ; then
echo "不检测主程序版本"
fi
if [ "$app_74" == "2" ] ; then
nvram set app_74="4" ; app_74="4"
link_get="v2ray"
logger -t "【v2rayA】" "自动下载 Xray-core 主程序"
fi
if [ "$app_74" == "5" ] ; then
nvram set app_74="6" ; app_74="6"
link_get="v2ray-v2ray5"
logger -t "【v2rayA】" "自动下载 Xray-core v5 主程序"
fi
if [ ! -z "$link_get" ] ; then
wgetcurl_file "$v2ray_path""_file" "$hiboyfile/""$link_get" "$hiboyfile2/""$link_get"
sed -Ei '/【v2raya】|^$/d' /tmp/script/_opt_script_check
killall v2ray v2ray_script.sh
rm -rf $v2ray_path
mv -f "$v2ray_path""_file" "$v2ray_path"
fi

}

case $ACTION in
start)
	v2raya_close
	v2raya_check
	;;
check)
	v2raya_check
	;;
stop)
	v2raya_close
	;;
updateapp29)
	v2raya_restart o
	[ "$v2raya_enable" = "1" ] && nvram set v2raya_status="updatev2raya" && logger -t "【v2rayA】" "重启" && v2raya_restart
	[ "$v2raya_enable" != "1" ] && nvram set v2raya_v="" && logger -t "【v2rayA】" "更新" && update_app del
	;;
update_app)
	update_app
	;;
keep)
	#v2raya_check
	v2raya_keep
	;;
transparent_disable)
	transparent_disable
	;;
transparent_enable)
	transparent_enable
	;;
*)
	v2raya_check
	;;
esac

