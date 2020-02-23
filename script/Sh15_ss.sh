#!/bin/sh
#copyright by hiboy
source /etc/storage/script/init.sh
ss_enable=`nvram get ss_enable`
[ -z $ss_enable ] && ss_enable=0 && nvram set ss_enable=0
v2ray_enable=`nvram get v2ray_enable`
[ -z $v2ray_enable ] && v2ray_enable=0 && nvram set v2ray_enable=0
ipt2socks_enable=`nvram get app_104`
[ -z $ipt2socks_enable ] && ipt2socks_enable=0 && nvram set app_104=0
v2ray_follow=`nvram get v2ray_follow`
[ -z $v2ray_follow ] && v2ray_follow=0 && nvram set v2ray_follow=0
app_95="$(nvram get app_95)"
ss_matching_enable="$(nvram get ss_matching_enable)"
[ -z $ss_matching_enable ] && ss_matching_enable=0 && nvram set ss_matching_enable=0
[ "$ss_matching_enable" == "0" ] && [ -z "$app_95" ] && app_95="." && nvram set app_95="."
[ "$ss_matching_enable" == "1" ] && [ ! -z "$app_95" ] && app_95="" && nvram set app_95=""
ss_ip46=`nvram get ss_ip46`
[ -z $ss_ip46 ] && ss_ip46=0 && nvram set ss_ip46=0
ss_mode_x=`nvram get ss_mode_x` #ss模式，0 为chnroute, 1 为 gfwlist, 2 为全局, 3为ss-local 建立本地 SOCKS 代理
[ -z $ss_mode_x ] && ss_mode_x=0 && nvram set ss_mode_x=$ss_mode_x
if [ "$ss_enable" != "0" ] ; then
if [ "$ss_mode_x" != 3 ] ; then
ss_tproxy_auser=`nvram get ss_tproxy_auser`
	if [ "Sh15_ss.sh" != "$ss_tproxy_auser" ] && [ "" != "$ss_tproxy_auser" ] ; then
		logger -t "【SS】" "错误！！！由于已启用 $ss_tproxy_auser 透明代理，停止启用 SS 透明代理！"
		ss_mode_x=3 && nvram set ss_mode_x=3
	fi
fi
#nvramshow=`nvram showall | grep '=' | grep kcptun | awk '{print gensub(/'"'"'/,"'"'"'\"'"'"'\"'"'"'","g",$0);}'| awk '{print gensub(/=/,"='\''",1,$0)"'\'';";}'` && eval $nvramshow
#nvramshow=`nvram showall | grep '=' | grep ss | awk '{print gensub(/'"'"'/,"'"'"'\"'"'"'\"'"'"'","g",$0);}'| awk '{print gensub(/=/,"='\''",1,$0)"'\'';";}'` && eval $nvramshow

# 多线程
ss_threads=`nvram get ss_threads`
[ -z $ss_threads ] && ss_threads=0 && nvram set ss_threads=0
if [ "$ss_threads" != 0 ] ; then
threads=$(cat /proc/cpuinfo | grep 'processor' | wc -l)
[ -z $threads ] && threads=1
if [ "$threads" = "1" ] ;then
	logger -t "【SS】" "检测到单核CPU，多线程启动失败"
	nvram set ss_threads=0
	ss_threads=0
fi
if [ "$ss_threads" != "1" ] ;then
	if [ "$ss_threads" -ge "threads" ] ; then
	nvram set ss_threads=1
	else
	threads="$ss_threads"
	fi
fi
Mem_total="$(free | sed -n '2p' | awk '{print $2;}')"
Mem_lt=100000
if [ "$Mem_total" -lt "$Mem_lt" ] ; then
	logger -t "【SS】" "检测到内存不足100M，多线程启动失败"
	nvram set ss_threads=0
	ss_threads=0
fi
fi
v2ray_path=`nvram get v2ray_path`
[ -z $v2ray_path ] && v2ray_path="/opt/bin/v2ray" && nvram set v2ray_path=$v2ray_path

koolproxy_enable=`nvram get koolproxy_enable`
ss_dnsproxy_x=`nvram get ss_dnsproxy_x`
ss_link_2=`nvram get ss_link_2`
ss_update=`nvram get ss_update`
ss_update_hour=`nvram get ss_update_hour`
ss_update_min=`nvram get ss_update_min`

ss_keep_check=`nvram get ss_keep_check`
[ -z $ss_keep_check ] && ss_keep_check=1 && nvram set ss_keep_check=$ss_keep_check
#================华丽的分割线====================================
#set -x
#初始化开始
FWI="/tmp/firewall.shadowsocks.pdcn" # firewall include file

ss_type=`nvram get ss_type`
[ -z $ss_type ] && ss_type=0 && nvram set ss_type=$ss_type
ss_run_ss_local=`nvram get ss_run_ss_local`

kcptun_enable=`nvram get kcptun_enable`
[ -z $kcptun_enable ] && kcptun_enable=0 && nvram set kcptun_enable=$kcptun_enable
[ "$kcptun_enable" = "0" ] && kcptun_server=""

server_addresses=$(cat /etc/storage/v2ray_config_script.sh | tr -d ' ' | grep -Eo '"address":.+' | grep -v 8.8.8.8 | grep -v google.com | grep -v 114.114.114.114 | sed -n '1p' | cut -d':' -f2 | cut -d'"' -f2)

ss_server=`nvram get ss_server`
ss_server_port=`nvram get ss_server_port`
ss_key=`nvram get ss_key`
ss_method=`nvram get ss_method | tr 'A-Z' 'a-z'`

ss_s1_local_address=`nvram get ss_s1_local_address`
ss_s1_local_port=`nvram get ss_s1_local_port`

ss_pdnsd_wo_redir=`nvram get ss_pdnsd_wo_redir` #pdnsd  0、走代理；1、直连
[ -z $ss_pdnsd_wo_redir ] && ss_pdnsd_wo_redir=0 && nvram set ss_pdnsd_wo_redir=$ss_pdnsd_wo_redir
ss_mode_x=`nvram get ss_mode_x` #ss模式，0 为chnroute, 1 为 gfwlist, 2 为全局, 3为ss-local 建立本地 SOCKS 代理
[ -z $ss_mode_x ] && ss_mode_x=0 && nvram set ss_mode_x=$ss_mode_x
ss_working_port=`nvram get ss_working_port` #working port 
[ "$ss_enable" != "0" ] && [ $ss_working_port != 1090 ] && ss_working_port=1090 && nvram set ss_working_port=$ss_working_port
ss_multiport=`nvram get ss_multiport`
[ -z "$ss_multiport" ] && ss_multiport="22,80,443" && nvram set ss_multiport=$ss_multiport
[ -n "$ss_multiport" ] || ss_multiport="22,80,443" # 处理多端口设定
# 严重警告，如果走chnrouter 和全局模式，又不限制端口，下载流量都会通过你的ss服务器往外走，随时导致你的ss服务器被封或ss服务商封你帐号，设置连累你的SS服务商被封

# DNS 端口，用于防止域名污染用的PDNSD
DNS_Server=127.0.0.1#8053

ss_3p_enable=`nvram get ss_3p_enable`
ss_3p_gfwlist=`nvram get ss_3p_gfwlist`
ss_3p_kool=`nvram get ss_3p_kool`


ss_sub1=`nvram get ss_sub1`
ss_sub2=`nvram get ss_sub2`
ss_sub3=`nvram get ss_sub3`
ss_sub4=`nvram get ss_sub4`
ss_sub5=`nvram get ss_sub5`
ss_sub6=`nvram get ss_sub6`
ss_sub7=`nvram get ss_sub7`
ss_sub8=`nvram get ss_sub8`

ss_tochina_enable=`nvram get ss_tochina_enable`
[ -z $ss_tochina_enable ] && ss_tochina_enable=0 && nvram set ss_tochina_enable=$ss_tochina_enable
ss_udp_enable=`nvram get ss_udp_enable` #udp转发  0、停用；1、启动
[ -z $ss_udp_enable ] && ss_udp_enable=0 && nvram set ss_udp_enable=$ss_udp_enable
ss_upd_rules=`nvram get ss_upd_rules`
[ -n "$ss_upd_rules" ] || ss_upd_rules="1:65535" # 处理多端口设定
# ss_upd_rules UDP参数用法，暂时不考虑字符安全过滤的问题，单用户系统输入，并且全root开放的平台，你愿意注入自己的路由器随意吧。
# 范例 
# 单机全部 192.168.123.10 
# 多台单机 192.168.123.10,192.168.123.12
# 子网段  192.168.123.16/28  不知道怎么设置自己找在线子网掩码工具计算
# 单机但限定目的端口  192.168.123.10 --dport 3000:30010
# 如果需要更加细节的设置，可以让用户自己修改一个iptables 文件来处理。

ss_usage=" `nvram get ss_usage`"

LAN_AC_IP=`nvram get LAN_AC_IP`
[ -z $LAN_AC_IP ] && LAN_AC_IP=0 && nvram set LAN_AC_IP=$LAN_AC_IP

lan_ipaddr=`nvram get lan_ipaddr`
ss_DNS_Redirect=`nvram get ss_DNS_Redirect`
ss_DNS_Redirect_IP=`nvram get ss_DNS_Redirect_IP`
[ -z "$ss_DNS_Redirect_IP" ] && ss_DNS_Redirect_IP=$lan_ipaddr

ss_check=`nvram get ss_check`
ss_updatess=`nvram get ss_updatess`
[ -z $ss_updatess ] && ss_updatess=0 && nvram set ss_updatess=$ss_updatess
[ -z $ss_link_2 ] && ss_link_2="www.google.com.hk" && nvram set ss_link_2="www.google.com.hk"

[ -z $ss_dnsproxy_x ] && ss_dnsproxy_x=0 && nvram set ss_dnsproxy_x=0
chinadns_enable=`nvram get app_1`
[ -z $chinadns_enable ] && chinadns_enable=0 && nvram set app_1=0
chinadns_port=`nvram get app_6`
[ -z $chinadns_port ] && chinadns_port=8053 && nvram set app_6=8053
if [ "$chinadns_enable" != "0" ] ; then
	if [ "$chinadns_port" = "8053" ] ; then
	ss_dnsproxy_x=2
	else
	[ "$ss_dnsproxy_x" = "2" ] && ss_dnsproxy_x=0
	fi
fi

ss_rebss_n=`nvram get ss_rebss_n`
[ -z $ss_rebss_n ] && ss_rebss_n=0 && nvram set ss_rebss_n=$ss_rebss_n
ss_rebss_a=`nvram get ss_rebss_a`
[ -z $ss_rebss_a ] && ss_rebss_a=0 && nvram set ss_rebss_a=$ss_rebss_a
app_97="$(nvram get app_97)"

ss_renum=`nvram get ss_renum`
ss_renum=${ss_renum:-"0"}
cmd_log_enable=`nvram get cmd_log_enable`
cmd_name="SS"
cmd_log=""
if [ "$cmd_log_enable" = "1" ] || [ "$ss_renum" -gt "0" ] ; then
	cmd_log="$cmd_log2"
fi
fi

if [ "$ss_enable" != "0" ] ; then
	kcptun_server=`nvram get kcptun_server`
	if [ "$kcptun_enable" != "0" ] ; then
		if [ -z $(echo $kcptun_server | grep : | grep -v "\.") ] ; then 
		resolveip=`ping -4 -n -q -c1 -w1 -W1 $kcptun_server | head -n1 | sed -r 's/\(|\)/|/g' | awk -F'|' '{print $2}'`
		[ -z "$resolveip" ] && resolveip=`ping -6 -n -q -c1 -w1 -W1 $kcptun_server | head -n1 | sed -r 's/\(|\)/|/g' | awk -F'|' '{print $2}'`
		[ -z "$resolveip" ] && resolveip=`arNslookup $kcptun_server | sed -n '1p'` 
		[ -z "$resolveip" ] && resolveip=`arNslookup6 $kcptun_server | sed -n '1p'` 
		kcptun_server=$resolveip
		else
		# IPv6
		kcptun_server=$kcptun_server
		fi
	else
		kcptun_server=""
	fi
fi

#检查 dnsmasq 目录参数
#confdir=`grep "/tmp/ss/dnsmasq.d" /etc/storage/dnsmasq/dnsmasq.conf | sed 's/.*\=//g'`
#if [ -z "$confdir" ] ; then 
	confdir="/tmp/ss/dnsmasq.d"
#fi
confdir_x="$(echo -e $confdir | sed -e "s/\//"'\\'"\//g")"
[ ! -d "$confdir" ] && mkdir -p $confdir

if [ ! -z "$(echo $scriptfilepath | grep -v "/tmp/script/" | grep ss)" ]  && [ ! -s /tmp/script/_ss ]; then
	mkdir -p /tmp/script
	{ echo '#!/bin/sh' ; echo $scriptfilepath '"$@"' '&' ; } > /tmp/script/_ss
	chmod 777 /tmp/script/_ss
fi

ss_tproxy_set() {
ss_tproxy_auser=`nvram get ss_tproxy_auser`
if [ "$1" != "$ss_tproxy_auser" ] ; then
	logger -t "【SS】" "脚本 [Sh99_ss_tproxy.sh] 当前使用者: $auser_b ，跳过 $auser_a 的运行命令"
	logger -t "【SS】" "需要停用 $auser_b 后才能使用 $auser_a 运行 [Sh99_ss_tproxy.sh] 脚本"
	return
fi
lan_ipaddr=`nvram get lan_ipaddr`
ss_tproxy_mode_x=`nvram get app_110`
[ -z $ss_tproxy_mode_x ] && ss_tproxy_mode_x=0 && nvram set app_110=0
[ "$ss_tproxy_mode_x" = "0" ] && logger -t "【SS】" "【自动】设置 ss_tproxy 配置文件，配置导入中..."
[ "$ss_tproxy_mode_x" = "1" ] && logger -t "【SS】" "【手动】设置 ss_tproxy 配置文件，跳过配置导入" && return
 # /etc/storage/app_27.sh
[ "$ss_mode_x" = "1" ] && sstp_set mode='gfwlist'
[ "$ss_mode_x" = "0" ] && sstp_set mode='chnroute'
[ "$ss_mode_x" = "2" ] && sstp_set mode='global'
[ "$ss_tochina_enable" != "0" ] && sstp_set mode='chnlist'
[ "$ss_ip46" = "0" ] && { sstp_set ipv4='true' ; sstp_set ipv6='false' ; }
[ "$ss_ip46" = "1" ] && { sstp_set ipv4='false' ; sstp_set ipv6='true' ; }
[ "$ss_ip46" = "2" ] && { sstp_set ipv4='true' ; sstp_set ipv6='true' ; }
sstp_set tproxy='false' # true:TPROXY+TPROXY; false:REDIRECT+TPROXY
[ "$ss_udp_enable" == 1 ] && sstp_set tcponly='false' # true:仅代理TCP流量; false:代理TCP和UDP流量
[ "$ss_udp_enable" != 1 ] && sstp_set tcponly='true' # true:仅代理TCP流量; false:代理TCP和UDP流量
sstp_set selfonly='false'  # true:仅代理本机流量; false:代理本机及"内网"流量
nvram set app_112="0"      #app_112 0:自动开启第三方 DNS 程序(dnsproxy) ; 1:跳过自动开启第三方 DNS 程序但是继续把DNS绑定到 8053 端口的程序
nvram set app_113="0"      #app_113 0:使用 8053 端口查询全部 DNS 时进行 China 域名加速 ; 1:不进行 China 域名加速
nvram set app_114="0" # 0:代理本机流量; 1:跳过代理本机流量
sstp_set uid_owner='0' # 非 0 时进行用户ID匹配跳过代理本机流量
## proxy
sstp_set proxy_all_svraddr="/opt/app/ss_tproxy/conf/proxy_all_svraddr.conf"
sstp_set proxy_svrport='1:65535'
sstp_set proxy_tcpport='1090'
[ "$ss_threads" == 0 ] && sstp_set proxy_udpport='1090'
[ "$ss_threads" != 0 ] && sstp_set proxy_udpport='1092'
sstp_set proxy_startcmd='date'
sstp_set proxy_stopcmd='date'
## dns
DNS_china=`nvram get wan0_dns |cut -d ' ' -f1`
[ -z "$DNS_china" ] && DNS_china="114.114.114.114"
sstp_set dns_direct="$DNS_china"
[ "$ss_tochina_enable" == "0" ] && sstp_set dns_direct='114.114.114.114'
[ "$ss_tochina_enable" == "0" ] && sstp_set dns_direct6='240C::6666'
[ "$ss_tochina_enable" == "0" ] && sstp_set dns_remote='8.8.8.8#53'
[ "$ss_tochina_enable" == "0" ] && sstp_set dns_remote6='2001:4860:4860::8888#53'
[ "$ss_tochina_enable" != "0" ] && sstp_set dns_direct='8.8.8.8' # 回国模式
[ "$ss_tochina_enable" != "0" ] && sstp_set dns_direct6='2001:4860:4860::8888' # 回国模式
[ "$ss_tochina_enable" != "0" ] && sstp_set dns_remote='114.114.114.114#53' # 回国模式
[ "$ss_tochina_enable" != "0" ] && sstp_set dns_remote6='240C::6666#53' # 回国模式
sstp_set dns_bind_port='8053'
## dnsmasq
sstp_set dnsmasq_bind_port='53'
sstp_set dnsmasq_conf_dir="/opt/app/ss_tproxy/dnsmasq.d"
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
sstp_set ipts_proxy_dst_port_tcp="$ss_multiport"
sstp_set ipts_proxy_dst_port_udp="$ss_upd_rules"
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
server_addresses=$(cat /etc/storage/v2ray_config_script.sh | tr -d ' ' | grep -Eo '"address":.+' | grep -v 8.8.8.8 | grep -v google.com | grep -v 114.114.114.114 | sed -n '1p' | cut -d':' -f2 | cut -d'"' -f2)
echo "$server_addresses" >> /opt/app/ss_tproxy/conf/proxy_all_svraddr.conf
# clash
grep '^  server: ' /etc/storage/app_20.sh | sed -e 's/server://g' | sed -e 's/"\|'"'"'\| //g' | grep -v 8.8.8.8 | grep -v google.com | grep -v 114.114.114.114 >> /opt/app/ss_tproxy/conf/proxy_all_svraddr.conf
kcptun_server=`nvram get kcptun_server`
echo "$kcptun_server" >> /opt/app/ss_tproxy/conf/proxy_all_svraddr.conf

# 链接配置文件
rm -f /opt/app/ss_tproxy/wanlist.ext
rm -f /opt/app/ss_tproxy/lanlist.ext
ln -sf /etc/storage/shadowsocks_ss_spec_wan.sh /opt/app/ss_tproxy/wanlist.ext
ln -sf /etc/storage/shadowsocks_ss_spec_lan.sh /opt/app/ss_tproxy/lanlist.ext
logger -t "【SS】" "【自动】设置 ss_tproxy 配置文件，完成配置导入"
}

sstp_set() {
sstp_conf='/etc/storage/app_27.sh'
sstp_set_a="$(echo "$1" | awk -F '=' '{print $1}')"
sstp_set_b="$(echo "$1" | awk -F '=' '{for(i=2;i<=NF;++i) { if(i==2){sum=$i}else{sum=sum"="$i}}}END{print sum}')"
if [ ! -z "$(grep -Eo $sstp_set_a=.\+\(\ #\) $sstp_conf)" ] ; then
sed -e "s@^$sstp_set_a=.\+\(\ #\)@$sstp_set_a='$sstp_set_b' #@g" -i $sstp_conf
else
sed -e "s@^$sstp_set_a=.\+@$sstp_set_a='$sstp_set_b' #@g" -i $sstp_conf
fi
if [ -z "$(cat $sstp_conf | grep "$sstp_set_a=""'""$sstp_set_b""'"" #")" ] ; then
echo "$sstp_set_a=""'""$sstp_set_b""'"" #" >> $sstp_conf
fi
}

SSJSON_sh()
{

config_file="$1"
if [ "$2" == "1" ]; then
server_json="$ss_server"
server_por_jsont="$ss_server_port"
if [ "$3" == "r" ]; then
local_address_json="0.0.0.0"
local_port_json="$ss_s1_redir_port"
fi
if [ "$3" == "l" ]; then
local_address_json="$ss_s1_local_address"
local_port_json="$ss_s1_local_port"
fi
if [ "$3" == "c" ]; then
local_address_json="$4"
local_port_json="$5"
fi
password_json="$(nvram get ss_key)"
method_json="$(nvram get ss_method | tr 'A-Z' 'a-z')"
protocol_json="$ssr_protocol"
protocol_param_json="$ssr_type_protocol_custom"
obfs_json="$ssr_obfs"
obfs_param_json="$ssr_type_obfs_custom"
plugin_json="$ss_plugin_name"
obfs_plugin_json="$ss_plugin_config"
fi

cat > "$config_file" <<-SSJSON
{
"server": "$server_json",
"server_port": "$server_por_jsont",
"local_address": "$local_address_json",
"local_port": "$local_port_json",
"password": "$password_json",
"timeout": "180",
"method": "$method_json",
"protocol": "$protocol_json",
"protocol_param": "$protocol_param_json",
"obfs": "$obfs_json",
"obfs_param": "$obfs_param_json",
"plugin": "$plugin_json",
"plugin_opts": "$obfs_plugin_json"
}
SSJSON

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

#检查  libsodium.so.23
[ -f /lib/libsodium.so.23 ] && libsodium_so=libsodium.so.23
[ -f /lib/libsodium.so.18 ] && libsodium_so=libsodium.so.18

start_ss_redir()
{

ss_plugin_client_name="$(nvram get ss_plugin_client_name)"
[ ! -z "$ss_plugin_client_name" ] && { kill_ps "$ss_plugin_client_name" ; ss_plugin_client_name="" ; nvram set ss_plugin_client_name="" ; }
[ -z "$ss_server" ] && { logger -t "【SS】" "[错误!!] SS服务器没有设置"; stop_SS; clean_SS; } 
if [ "$ss_udp_enable" == 1 ] ; then
ss_usage=" $ss_usage -u "
else
ss_usage=" $ss_usage "
fi

# 高级启动参数分割
ss_usage="$(usage_switch "$ss_usage")"

ssr_type_obfs_custom=""
ssr_type_protocol_custom=""

# 混淆插件方式
ss_usage_custom="$(echo "$ss_usage" | grep -Eo '\-o[ ]+[^丨]+')"
if [ ! -z "$ss_usage_custom" ] ; then
	ssr_obfs="$(echo $ss_usage_custom | sed -e "s@^-o@@g" | sed -e "s@ @@g")"
	logger -t "【SS】" "ssr混淆插件方式: $ssr_obfs"
fi
# 协议插件方式
ss_usage_custom="$(echo "$ss_usage" | grep -Eo '\-O[ ]+[^丨]+')"
if [ ! -z "$ss_usage_custom" ] ; then
	ssr_protocol="$(echo $ss_usage_custom | sed -e "s@^-O@@g" | sed -e "s@ @@g")"
	logger -t "【SS】" "ssr协议插件方式: $ssr_protocol"
fi
# 混淆参数
ss_usage_obfs_custom="$(echo "$ss_usage" | grep -Eo '\-g[ ]+[^丨]+')"
if [ ! -z "$ss_usage_obfs_custom" ] ; then 
	ssr_type_obfs_custom="$(echo $ss_usage_obfs_custom | sed -e "s@^-g@@g" | sed -e "s@^ @@g")"
	logger -t "【SS】" "高级启动参数选项内容含有 -g $ssr_type_obfs_custom ，优先使用此 混淆参数"
fi
# 协议参数
ss_usage_protocol_custom="$(echo "$ss_usage" | grep -Eo '\-G[ ]+[^丨]+')"
if [ ! -z "$ss_usage_protocol_custom" ] ; then 
	ssr_type_protocol_custom="$(echo $ss_usage_protocol_custom | sed -e "s@^-G@@g" | sed -e "s@ @@g")"
	logger -t "【SS】" "高级启动参数选项内容含有 -G $ssr_type_protocol_custom ，优先使用此 协议参数"
fi

[ -z "$ssr_obfs" ] && ssr_obfs="plain"
[ -z "$ssr_protocol" ] && ssr_protocol="origin"

if [ "$ssr_obfs" != "plain" ] || [ "$ssr_protocol" != "origin" ] ; then
	# SSR 协议
	ss_type=1
fi
if [ ! -z "$ssr_type_obfs_custom" ] || [ ! -z "$ssr_type_protocol_custom" ] ; then
	ss_type=1
fi
ssrr_custom="$(echo $ssr_protocol | grep -Eo 'auth_chain_c|auth_chain_d|auth_chain_e|auth_chain_f')"
if [ ! -z "$ssrr_custom" ] ; then 
	# SSRR 协议
	ssrr_type=1
	ss_type=1
	nvram set ss_type=$ss_type
fi

# 插件名称
ss_usage_custom="$(echo "$ss_usage" | grep -Eo '\-\-plugin[ ]+[^丨]+')"
if [ ! -z "$ss_usage_custom" ] ; then
	ss_plugin_name="$(echo $ss_usage_custom | sed -e "s@^--plugin@@g" | sed -e "s@ @@g")"
	logger -t "【SS】" "高级启动参数选项内容含有 --plugin $ss_plugin_name ，优先使用此 插件名称"
fi

# 插件参数
ss_usage_custom="$(echo "$ss_usage" | grep -Eo '\-\-plugin\-opts[ ]+[^丨]+')"
if [ ! -z "$ss_usage_custom" ] ; then 
	ss_plugin_config="$(echo $ss_usage_custom | sed -e "s@^--plugin-opts@@g" | sed -e "s@ @@g")"
	ss_plugin_config="$(echo $ss_plugin_config | sed -e 's@^"@@g' | sed -e 's@"$@@g')"
	logger -t "【SS】" "高级启动参数选项内容含有 --plugin-opts $ss_plugin_config ，优先使用此 插件参数"
fi

# 插件名称 插件参数 调整名称
[ ! -z "$(echo "$ss_plugin_name" | grep "simple-obfs")" ] && ss_plugin_name="obfs-local"
[ ! -z "$(echo "$ss_plugin_config" | grep "obfs-host")" ] && ss_plugin_name="obfs-local"
[ ! -z "$(echo "$ss_plugin_config" | grep "obfs=tls")" ] && ss_plugin_name="obfs-local"
[ ! -z "$(echo "$ss_plugin_config" | grep "obfs=http")" ] && ss_plugin_name="obfs-local"
[ ! -z "$(echo "$ss_plugin_name" | grep "GoQuiet")" ] && ss_plugin_name="gq-client"
[ ! -z "$(echo "$ss_plugin_name" | grep "goquiet")" ] && ss_plugin_name="gq-client"
[ ! -z "$(echo "$ss_plugin_name" | grep "kcptun")" ] && ss_plugin_name="ss_kcptun"
[ ! -z "$(echo "$ss_plugin_name" | grep "client_linux_mipsle")" ] && ss_plugin_name="ss_kcptun"
[ ! -z "$(echo "$ss_plugin_name" | grep "Cloak")" ] && ss_plugin_name="ck-client"
[ ! -z "$(echo "$ss_plugin_name" | grep "cloak")" ] && ss_plugin_name="ck-client"
[ ! -z "$(echo "$ss_plugin_name" | grep "v2ray")" ] && ss_plugin_name="v2ray-plugin"
[ ! -z "$(echo "$ss_plugin_name" | grep "V2ray")" ] && ss_plugin_name="v2ray-plugin"
[ ! -z "$ss_plugin_name" ] && { ss_plugin_client_name="$ss_plugin_name" ; nvram set ss_plugin_client_name="$ss_plugin_client_name" ; }
[ ! -z "$ss_plugin_client_name" ] && kill_ps "$ss_plugin_client_name"

# 删除混淆、协议、分割符号
options1="$(echo "$ss_usage" | sed -r 's/\ -g[ ]+[^丨]+//g' | sed -r 's/\ -G[ ]+[^丨]+//g' | sed -r 's/\ -o[ ]+[^丨]+//g' | sed -r 's/\ -O[ ]+[^丨]+//g' | sed -r 's/\ --plugin-opts[ ]+[^丨]+//g' | sed -r 's/\ --plugin[ ]+[^丨]+//g' | sed -e "s@丨@@g" | sed -e "s@  @ @g" | sed -e "s@  @ @g")"
# 高级启动参数分割完成

# 启动程序
ss_s1_redir_port=1090
[ "$ss_threads" != 0 ] && ss_s1_redir_port=1092
logger -t "【ss-redir】" "启动所有的 SS 连线, 出现的 SS 日志并不是错误报告, 只是使用状态日志, 请不要慌张, 只要系统正常你又看不懂就无视它！"
logger -t "【SS】" "SS服务器【$app_97】设置内容：$ss_server 端口:$ss_server_port 加密方式:$ss_method 本地监听地址：0.0.0.0 本地代理端口：$ss_s1_redir_port "

SSJSON_sh "/tmp/ss-redir_1.json" "1" "r"
killall_ss_redir
check_ssr
cmd_name="SS_1_redir"
eval "ss-redir -c /tmp/ss-redir_1.json $options1 $cmd_log" &
if [ "$ss_mode_x" = "3" ] || [ "$ss_run_ss_local" = "1" ] ; then
	killall_ss_local
	logger -t "【ss-local】" "启动所有的 ss-local 连线, 出现的 SS 日志并不是错误报告, 只是使用状态日志, 请不要慌张, 只要系统正常你又看不懂就无视它！"
	logger -t "【ss-local】" "SS服务器【$app_97】设置内容：$ss_server 端口:$ss_server_port 加密方式:$ss_method 本地监听地址：$ss_s1_local_address 本地代理端口：$ss_s1_local_port "
	SSJSON_sh "/tmp/ss-local_1.json" "1" "l"
	killall_ss_local
	cmd_name="SS_1_local"
	eval "ss-local -c /tmp/ss-local_1.json $options1 $cmd_log" &

fi

}

start_ss_redir_check()
{

sleep 1
[ ! -z "`pidof ss-redir`" ] && logger -t "【SS】" "启动成功" && ss_restart o
[ -z "`pidof ss-redir`" ] && logger -t "【SS】" "启动失败, 注意检查端口是否有冲突,程序是否下载完整,10 秒后自动尝试重新启动" && sleep 10 && ss_restart x
if [ "$ss_mode_x" = "3" ] || [ "$ss_run_ss_local" = "1" ] ; then
	[ "$ss_mode_x" = "3" ] && killall_ss_redir
	[ ! -z "`pidof ss-local`" ] && logger -t "【ss-local】" "启动成功" && ss_restart o
	[ -z "`pidof ss-local`" ] && logger -t "【ss-local】" "启动失败, 注意检查端口是否有冲突,程序是否下载完整,10 秒后自动尝试重新启动" && sleep 10 && ss_restart x
fi

}

start_ss_redir_threads()
{

# 多线程启动
if [ "$ss_threads" != 0 ] ; then
logger -t "【SS-V2ray】" "启动多线程ss-local，使用v2ray随机轮询负载，占用端口1090-1092，10901-10904"
mkdir -p /tmp/cpu4
v2ray_cpu4_pb="/tmp/cpu4/ss-redir_v2ray.pb"
v2ray_cpu4_json="/tmp/cpu4/ss-redir_v2ray.json"
v2ctl_path="$(cd "$(dirname "$v2ray_path")"; pwd)/v2ctl"
wgetcurl_file $v2ctl_path "$hiboyfile/v2ctl" "$hiboyfile2/v2ctl"
if [[ "$($v2ctl_path -h 2>&1 | wc -l)" -lt 2 ]] ; then
	[ -f "$v2ctl_path" ] && rm -f "$v2ctl_path"
	logger -t "【SS】" "找不到 $v2ctl_path ，多线程启动失败"
	return
fi
wgetcurl_file "$v2ray_path" "$hiboyfile/v2ray" "$hiboyfile2/v2ray"
if [[ "$($v2ray_path -h 2>&1 | wc -l)" -lt 2 ]] ; then
	[ -f "$v2ray_path" ] && rm -f "$v2ray_path"
	logger -t "【SS】" "找不到 $v2ray_path ，多线程启动失败"
	return
fi
cat > $v2ray_cpu4_json <<-END
{
  "log": {
    "error": "/tmp/syslog.log",
    "loglevel": "warning"
  },
  "inbounds": [
  {
    "port": 1090,
    "tag": "door1090",
    "protocol": "dokodemo-door",
    "settings": {
      "network": "tcp,udp",
      "timeout": 0,
      "followRedirect": true,
      "userLevel": 0
    }
  }
  ],
  "outbounds": [
    {
      "protocol": "socks",
      "tag": "10901",
      "settings": {
        "servers": [
          {
            "address": "127.0.0.1",
            "port": 10901
          }
        ]
      }
    },
    {
      "protocol": "socks",
      "tag": "10902",
      "settings": {
        "servers": [
          {
            "address": "127.0.0.1",
            "port": 10902
          }
        ]
      }
    },
    {
      "protocol": "socks",
      "tag": "10903",
      "settings": {
        "servers": [
          {
            "address": "127.0.0.1",
            "port": 10903
          }
        ]
      }
    },
    {
      "protocol": "socks",
      "tag": "10904",
      "settings": {
        "servers": [
          {
            "address": "127.0.0.1",
            "port": 10904
          }
        ]
      }
    }
  ],
  "routing": {
    "domainStrategy": "IPIfNonMatch",
    "balancers": [
      {
        "tag": "1090cpu4",
        "selector": [
          "10901",
          "10902",
          "10903",
          "10904"
        ]
      },
      {
        "tag": "1090cpu3",
        "selector": [
          "10901",
          "10902",
          "10903"
        ]
      },
      {
        "tag": "1090cpu2",
        "selector": [
          "10901",
          "10902"
        ]
      },
      {
        "tag": "1090udp",
        "selector": [
          "10901"
        ]
      }
    ],
    "rules": [
      {
        "type": "field",
        "network": "tcp",
        "balancerTag": "1090cpu$threads",
        "inboundTag": ["door1090"]
      },
      {
        "type": "field",
        "network": "udp",
        "balancerTag": "1090udp",
        "inboundTag": ["door1090"]
      }
    ]
  }
}

END
chmod 666 $v2ray_cpu4_json
logger -t "【SS】" "检测到【$(cat /proc/cpuinfo | grep 'processor' | wc -l)】核CPU：使用 $threads 线程启动"
[ "$ss_udp_enable" == 0 ] && killall_ss_redir
cd /tmp/cpu4
rm -f /tmp/cpu4/ss-redir /tmp/cpu4/v2ctl
ln -sf "$v2ray_path" /tmp/cpu4/ss-redir
ln -sf "$v2ctl_path" /tmp/cpu4/v2ctl
kill_ps /tmp/cpu4/ss-redir
cmd_name="ss-v2ray"
eval "/tmp/cpu4/ss-redir -format json -config $v2ray_cpu4_json $cmd_log" &
rm -f /tmp/cpu4/ss-local_
ln -sf /usr/sbin/ss-local /tmp/cpu4/ss-local_
killall ss-local_
for cpu_i in $(seq 1 $threads)  
do
	logger -t "【ss-local_1_$cpu_i】" "启动ss-local 1_$cpu_i 设置内容：$ss_server 端口:$ss_server_port 加密方式:$ss_method "
	SSJSON_sh "/tmp/ss-redir_1_$cpu_i.json" "1" "c" "127.0.0.1" "1090$cpu_i"
	cmd_name="ss-local_1_$cpu_i"
	eval "/tmp/cpu4/ss-local_ -c /tmp/ss-redir_1_$cpu_i.json $options1 $cmd_log" &
	usleep 300000
done
logger -t "【SS】" "多线程启动完成！"

fi
}

killall_ss_redir()
{

kill_ps "ss-redir_"

}

killall_ss_local()
{

kill_ps "ss-local_"

}

swap_ss_redir()
{

kill_ps "$scriptname keep"
kill_ps "$scriptname"
# 重载 ipset 规则
Sh99_ss_tproxy.sh auser_check "Sh15_ss.sh"
ss_tproxy_set "Sh15_ss.sh"
Sh99_ss_tproxy.sh x_resolve_svraddr "Sh15_ss.sh"

# 启动新进程
start_ss_redir
start_ss_redir_threads
start_ss_redir_check
[ "$ss_mode_x" = "3" ] && return

}

check_ssr()
{

if [ "$ssrr_type" = "1" ] ; then 
logger -t "【SS】" "高级启动参数选项内容含有 ssrr 协议: $ssrr_custom"
ssrr_type=1
ss_type=1
fi

optssredir="0"
if [ "$ss_type" != "1" ] ; then
# SS
if [ "$ss_mode_x" != "3" ] ; then
	hash ss-redir 2>/dev/null || optssredir="1"
else
	hash ss-local 2>/dev/null || optssredir="2"
fi
if [ "$ss_run_ss_local" = "1" ] || [ "$ss_threads" != 0 ] ; then
	hash ss-local 2>/dev/null || optssredir="3"
fi
# SS
fi

if [ "$ss_type" = "1" ] ; then
if [ "$ssrr_type" = "1" ] ; then
# SSRR
if [ "$ss_mode_x" != "3" ] ; then
	hash ssrr-redir 2>/dev/null || optssredir="1"
else
	hash ssrr-local 2>/dev/null || optssredir="2"
fi
if [ "$ss_run_ss_local" = "1" ] || [ "$ss_threads" != 0 ] ; then
	hash ssrr-local 2>/dev/null || optssredir="3"
fi
# SSRR
else
# SSR
if [ "$ss_mode_x" != "3" ] ; then
	hash ssr-redir 2>/dev/null || optssredir="1"
else
	hash ssr-local 2>/dev/null || optssredir="2"
fi
if [ "$ss_run_ss_local" = "1" ] || [ "$ss_threads" != 0 ] ; then
	hash ssr-local 2>/dev/null || optssredir="3"
fi
fi
# SSR
fi
if [ "$ss_dnsproxy_x" = "0" ] ; then
hash dnsproxy 2>/dev/null || optssredir="5"
elif [ "$ss_dnsproxy_x" = "1" ] ; then
hash pdnsd 2>/dev/null || optssredir="5"
fi
[ "$ss_run_ss_local" = "1" ] || [ "$ss_threads" != 0 ] && { hash ss-local 2>/dev/null || optssredir="3" ; }
[ ! -z "$ss_plugin_name" ] && { hash $ss_plugin_name 2>/dev/null || optssredir="4" ; }
if [ "$optssredir" != "0" ] ; then
	# 找不到ss-redir，安装opt
	logger -t "【SS】" "找不到 ss-redir 、 ss-local 、 $ss_plugin_name 或 obfs-local ，挂载opt"
	/tmp/script/_mountopt start
	initopt
fi
optssredir="0"

if [ "$ss_type" != "1" ] ; then
# SS
if [ "$ss_mode_x" != "3" ] ; then
chmod 777 "/usr/sbin/ss-redir"
	[[ "$(ss-redir -h | wc -l)" -lt 2 ]] && rm -rf /opt/bin/ss-redir
	hash ss-redir 2>/dev/null || optssredir="1"
else
chmod 777 "/usr/sbin/ss-local"
	[[ "$(ss-local -h | wc -l)" -lt 2 ]] && rm -rf /opt/bin/ss-local
	hash ss-local 2>/dev/null || optssredir="2"
fi
if [ "$optssredir" = "1" ] ; then
	[ ! -s /opt/bin/ss-redir ] && wgetcurl_file "/opt/bin/ss-redir" "$hiboyfile/$libsodium_so/ss-redir" "$hiboyfile2/$libsodium_so/ss-redir"
	hash ss-redir 2>/dev/null || { logger -t "【SS】" "找不到 ss-redir, 请检查系统"; ss_restart x ; }
fi
if [ "$ss_run_ss_local" = "1" ] || [ "$ss_threads" != 0 ] ; then
chmod 777 "/usr/sbin/ss-local"
	[[ "$(ss-local -h | wc -l)" -lt 2 ]] && rm -rf /opt/bin/ss-local
	hash ss-local 2>/dev/null || optssredir="3"
fi
if [ "$optssredir" = "2" ] || [ "$optssredir" = "3" ]; then
	[ ! -s /opt/bin/ss-local ] && wgetcurl_file "/opt/bin/ss-local" "$hiboyfile/$libsodium_so/ss-local" "$hiboyfile2/$libsodium_so/ss-local"
	hash ss-local 2>/dev/null || { logger -t "【SS】" "找不到 ss-local, 请检查系统"; ss_restart x ; }
fi
# SS
fi

if [ "$ss_type" = "1" ] ; then
if [ "$ssrr_type" = "1" ] ; then
# SSRR
if [ "$ss_mode_x" != "3" ] ; then
chmod 777 "/opt/bin/ssrr-redir"
	[[ "$(ssrr-redir -h | wc -l)" -lt 2 ]] && rm -rf /opt/bin/ssrr-redir
	hash ssrr-redir 2>/dev/null || optssredir="1"
else
chmod 777 "/opt/bin/ssrr-local"
	[[ "$(ssrr-local -h | wc -l)" -lt 2 ]] && rm -rf /opt/bin/ssrr-local
	hash ssrr-local 2>/dev/null || optssredir="2"
fi
if [ "$optssredir" = "1" ] ; then
	[ ! -s /opt/bin/ssrr-redir ] && wgetcurl_file "/opt/bin/ssrr-redir" "$hiboyfile/$libsodium_so/ssrr-redir" "$hiboyfile2/$libsodium_so/ssrr-redir"
	hash ssrr-redir 2>/dev/null || { logger -t "【SS】" "找不到 ssrr-redir, 请检查系统"; ss_restart x ; }
fi
if [ "$ss_run_ss_local" = "1" ] || [ "$ss_threads" != 0 ] ; then
chmod 777 "/opt/bin/ssrr-local"
	[[ "$(ssrr-local -h | wc -l)" -lt 2 ]] && rm -rf /opt/bin/ssrr-local
	hash ssrr-local 2>/dev/null || optssredir="3"
fi
if [ "$optssredir" = "2" ] || [ "$optssredir" = "3" ]; then
	[ ! -s /opt/bin/ssrr-local ] && wgetcurl_file "/opt/bin/ssrr-local" "$hiboyfile/$libsodium_so/ssrr-local" "$hiboyfile2/$libsodium_so/ssrr-local"
	hash ssrr-local 2>/dev/null || { logger -t "【SS】" "找不到 ssrr-local, 请检查系统"; ss_restart x ; }
fi
# SSRR
else
# SSR
if [ "$ss_mode_x" != "3" ] ; then
chmod 777 "/usr/sbin/ssr-redir"
	[[ "$(ssr-redir -h | wc -l)" -lt 2 ]] && rm -rf /opt/bin/ssr-redir
	hash ssr-redir 2>/dev/null || optssredir="1"
else
chmod 777 "/usr/sbin/ssr-local"
	[[ "$(ssr-local -h | wc -l)" -lt 2 ]] && rm -rf /opt/bin/ssr-local
	hash ssr-local 2>/dev/null || optssredir="2"
fi
if [ "$optssredir" = "1" ] ; then
	[ ! -s /opt/bin/ssr-redir ] && wgetcurl_file "/opt/bin/ssr-redir" "$hiboyfile/$libsodium_so/ssr-redir" "$hiboyfile2/$libsodium_so/ssr-redir"
	hash ssr-redir 2>/dev/null || { logger -t "【SS】" "找不到 ssr-redir, 请检查系统"; ss_restart x ; }
fi
if [ "$ss_run_ss_local" = "1" ] || [ "$ss_threads" != 0 ] ; then
chmod 777 "/usr/sbin/ssr-local"
	[[ "$(ssr-local -h | wc -l)" -lt 2 ]] && rm -rf /opt/bin/ssr-local
	hash ssr-local 2>/dev/null || optssredir="3"
fi
if [ "$optssredir" = "2" ] || [ "$optssredir" = "3" ]; then
	[ ! -s /opt/bin/ssr-local ] && wgetcurl_file "/opt/bin/ssr-local" "$hiboyfile/$libsodium_so/ssr-local" "$hiboyfile2/$libsodium_so/ssr-local"
	hash ssr-local 2>/dev/null || { logger -t "【SS】" "找不到 ssr-local, 请检查系统"; ss_restart x ; }
fi
# SSR
fi
fi
# 下载插件程序
if [ ! -z "$ss_plugin_name" ] ; then
	hash $ss_plugin_name 2>/dev/null || optssredir="4"
	if [ "$optssredir" = "4" ] ; then
		[ ! -s /opt/bin/$ss_plugin_name ] && wgetcurl_file "/opt/bin/$ss_plugin_name" "$hiboyfile/$ss_plugin_name" "$hiboyfile2/$ss_plugin_name"
		hash $ss_plugin_name 2>/dev/null || optssredir="44"
	fi
	if [ "$optssredir" = "44" ] ; then
		logger -t "【SS】" "找不到 ss_plugin_name :  $ss_plugin_name, 请检查系统"; ss_restart x ;
	fi
fi
# 下载 dnsproxy 程序
if [ "$ss_dnsproxy_x" = "0" ] ; then
hash dnsproxy 2>/dev/null && dnsproxy_x="1"
hash dnsproxy 2>/dev/null || dnsproxy_x="0"
if [ "$dnsproxy_x" = "0" ] ; then
	logger -t "【SS】" "找不到 dnsproxy. opt ，挂载opt"
	/tmp/script/_mountopt start
	initopt
	if [ ! -s /opt/bin/dnsproxy ] ; then
		wgetcurl_file "/opt/bin/dnsproxy" "$hiboyfile/dnsproxy" "$hiboyfile2/dnsproxy"
	fi
	hash dnsproxy 2>/dev/null || { logger -t "【SS】" "找不到 dnsproxy, 请检查系统"; ss_restart x ; }
fi
elif [ "$ss_dnsproxy_x" = "1" ] ; then
hash pdnsd 2>/dev/null && dnsproxy_x="1"
hash pdnsd 2>/dev/null || dnsproxy_x="0"
if [ "$dnsproxy_x" = "0" ] ; then
	logger -t "【SS】" "找不到 pdnsd. opt ，挂载opt"
	/tmp/script/_mountopt start
	initopt
	if [ ! -s /opt/bin/pdnsd ] ; then
		wgetcurl_file "/opt/bin/pdnsd" "$hiboyfile/pdnsd" "$hiboyfile2/pdnsd"
	fi
	hash pdnsd 2>/dev/null || { logger -t "【SS】" "找不到 pdnsd, 请检查系统"; ss_restart x ; }
fi
fi

umount  /usr/sbin/ss-redir
umount  /usr/sbin/ss-local
umount -l /usr/sbin/ss-redir
umount -l /usr/sbin/ss-local
if [ "$ss_type" != "1" ] ; then
	# ss
	if [ ! -s "/usr/sbin/ss-redir" ] ; then
		[ ! -s "/opt/bin/ss0-redir" ] && cp -f /opt/bin/ss-redir /opt/bin/ss0-redir
		[ -s "/opt/bin/ss0-redir" ] && cp -f /opt/bin/ss0-redir /opt/bin/ss-redir
		chmod 777 "/opt/bin/ss-redir"
	fi
	if [ ! -s "/usr/sbin/ssr-local" ] ; then
		[ ! -s "/opt/bin/ss0-local" ] && cp -f /opt/bin/ss-local /opt/bin/ss0-local
		[ -s "/opt/bin/ss0-local" ] && cp -f /opt/bin/ss0-local /opt/bin/ss-local
		chmod 777 "/opt/bin/ss-local"
	fi
fi
if [ "$ss_type" = "1" ] ; then
if [ "$ssrr_type" = "1" ] ; then
	# ssrr
	if [ -s "/usr/sbin/ssrr-redir" ] ; then
		mount --bind /usr/sbin/ssrr-redir /usr/sbin/ss-redir
	else
		[ ! -s "/opt/bin/ss0-redir" ] && cp -f /opt/bin/ss-redir /opt/bin/ss0-redir
		[ -s "/opt/bin/ssrr-redir" ] && cp -f /opt/bin/ssrr-redir /opt/bin/ss-redir
		chmod 777 "/opt/bin/ss-redir"
	fi
	if [ -s "/usr/sbin/ssrr-local" ] ; then
		mount --bind /usr/sbin/ssrr-local /usr/sbin/ss-local
	else
		[ ! -s "/opt/bin/ss0-local" ] && cp -f /opt/bin/ss-local /opt/bin/ss0-local
		[ -s "/opt/bin/ssrr-local" ] && cp -f /opt/bin/ssrr-local /opt/bin/ss-local
		chmod 777 "/opt/bin/ss-local"
	fi
else
	# ssr
	if [ -s "/usr/sbin/ssr-redir" ] ; then
		mount --bind /usr/sbin/ssr-redir /usr/sbin/ss-redir
	else
		[ ! -s "/opt/bin/ss0-redir" ] && cp -f /opt/bin/ss-redir /opt/bin/ss0-redir
		[ -s "/opt/bin/ssr-redir" ] && cp -f /opt/bin/ssr-redir /opt/bin/ss-redir
		chmod 777 "/opt/bin/ss-redir"
	fi
	if [ -s "/usr/sbin/ssr-local" ] ; then
		mount --bind /usr/sbin/ssr-local /usr/sbin/ss-local
	else
		[ ! -s "/opt/bin/ss0-local" ] && cp -f /opt/bin/ss-local /opt/bin/ss0-local
		[ -s "/opt/bin/ssr-local" ] && cp -f /opt/bin/ssr-local /opt/bin/ss-local
		chmod 777 "/opt/bin/ss-local"
	fi
fi
fi
}

clean_ss_rules()
{
echo "clean_ss_rules"
Sh99_ss_tproxy.sh off_stop "Sh15_ss.sh"
}

arNslookup() {
mkdir -p /tmp/arNslookup
nslookup $1 | tail -n +3 | grep "Address" | awk '{print $3}'| grep -v ":" > /tmp/arNslookup/$$ &
I=5
while [ ! -s /tmp/arNslookup/$$ ] ; do
		I=$(($I - 1))
		[ $I -lt 0 ] && break
		sleep 1
done
killall nslookup
if [ -s /tmp/arNslookup/$$ ] ; then
cat /tmp/arNslookup/$$ | sort -u | grep -v "^$"
rm -f /tmp/arNslookup/$$
else
	curltest=`which curl`
	if [ -z "$curltest" ] || [ ! -s "`which curl`" ] ; then
		Address="`wget -T 5 -t 3 --user-agent "$user_agent" --quiet --output-document=- http://119.29.29.29/d?dn=$1`"
		if [ $? -eq 0 ]; then
		echo "$Address" |  sed s/\;/"\n"/g | grep -E -o '([0-9]+\.){3}[0-9]+'
		fi
	else
		Address="`curl --user-agent "$user_agent" -s http://119.29.29.29/d?dn=$1`"
		if [ $? -eq 0 ]; then
		echo "$Address" |  sed s/\;/"\n"/g | grep -E -o '([0-9]+\.){3}[0-9]+'
		fi
	fi
fi
}

arNslookup6() {
mkdir -p /tmp/arNslookup
nslookup $1 | tail -n +3 | grep "Address" | awk '{print $3}'| grep ":" > /tmp/arNslookup/$$ &
I=5
while [ ! -s /tmp/arNslookup/$$ ] ; do
		I=$(($I - 1))
		[ $I -lt 0 ] && break
		sleep 1
done
killall nslookup
if [ -s /tmp/arNslookup/$$ ] ; then
	cat /tmp/arNslookup/$$ | sort -u | grep -v "^$"
	rm -f /tmp/arNslookup/$$
fi
}

gen_include() {
[ -n "$FWI" ] || return 0
[ -n "$FWI" ] && echo '#!/bin/sh' >$FWI
cat <<-CAT >>$FWI
iptables-restore -n <<-EOF
$(iptables-save | sed  "s/webstr--url/webstr --url/g" | grep -E "SSTP|^\*|^COMMIT" |sed -e "s/^-A \(OUTPUT\|PREROUTING\)/-I \1 1/")
EOF
CAT
return $?
}


#================华丽的分割线====================================

start_SS()
{
check_webui_yes
	logger -t "【SS】" "启动 SS"
	logger -t "【SS】" "ss-redir start.【$app_97】"
	nvram set gfwlist3="ss-redir start.【$app_97】"
	nvram set ss_internet="2"
	rm -f /tmp/check_timeout/*

echo "Debug: $DNS_Server"
	logger -t "【SS】" "###############启动程序###############"
	if [ "$ss_mode_x" = "3" ] ; then
		start_ss_redir
		start_ss_redir_check
		Sh99_ss_tproxy.sh off_stop "Sh15_ss.sh"
		nvram set gfwlist3="ss-local start.【$app_97】"
		logger -t "【ss-local】" "本地代理启动. 可以配合 Proxifier、chrome(switchysharp、SwitchyOmega) 代理插件使用."
		logger -t "【ss-local】" "shadowsocks 进程守护启动"
		ss_cron_job
		#ss_get_status
		nvram set button_script_2_s="SS"
		eval "$scriptfilepath keep &"
		exit 0
	fi
	start_ss_redir
	start_ss_redir_threads
	start_ss_redir_check
	Sh99_ss_tproxy.sh auser_check "Sh15_ss.sh"
	ss_tproxy_set "Sh15_ss.sh"
	Sh99_ss_tproxy.sh on_start "Sh15_ss.sh"
	#检查网络
	logger -t "【SS】" "SS 检查网络连接"
	check2=404
	check_timeout_network "wget_check" "check"
if [ "$check2" != "200" ] ; then 
	logger -t "【SS】" "错误！【Google.com】连接有问题！！！"
	logger -t "【SS】" "网络连接有问题, 请更新 opt 文件夹、检查 U盘 文件和 SS 设置"
	logger -t "【SS】" "如果是本地组网可忽略此错误！！"
	logger -t "【SS】" "否则需启用【首次时连接检测】、【运行时持续检测】才能自动故障转移"
fi
	/etc/storage/script/sh_ezscript.sh 3 & #更新按钮状态
	logger -t "【SS】" "SS 启动成功"
	logger -t "【SS】" "启动后若发现一些网站打不开, 估计是 DNS 被污染了. 解决 DNS 被污染方法："
	logger -t "【SS】" "①路由 SS 设置选择其他 DNS 服务模式；"
	logger -t "【SS】" "②电脑设置 DNS 自动获取路由 ip。检查 hosts 是否有错误规则。"
	logger -t "【SS】" "③电脑运行 cmd 输入【ipconfig /flushdns】, 清理浏览器缓存。"
	logger -t "【SS】" "shadowsocks 进程守护启动"
	nvram set ss_internet="1"
	ss_cron_job
	#ss_get_status
if [ "$ss_dnsproxy_x" = "2" ] ; then
	logger -t "【SS】" "使用 dnsmasq ，开启 ChinaDNS 防止域名污染"
	if [ -f "/etc/storage/script/Sh19_chinadns.sh" ] || [ -s "/etc/storage/script/Sh19_chinadns.sh" ] ; then
		/etc/storage/script/Sh19_chinadns.sh &
	fi
fi

/etc/storage/script/sh_ezscript.sh 3 & #更新按钮状态
eval "$scriptfilepath keep &"
exit 0
}



clean_SS()
{

# 重置 SS IP 规则文件并重启 SS
logger -t "【SS】" "重置 SS IP 规则文件并重启 SS"
sed -Ei '/no-resolv|server=|dns-forward-max=1000|min-cache-ttl=1800|accelerated-domains|github|ipip.net/d' /etc/storage/dnsmasq/dnsmasq.conf
if [ "$ss_enable" != "1" ]  ; then
stop_SS
restart_dhcpd
return
else
nvram set ss_status="cleanss"
nvram set kcptun_status="cleanss"
fi
mkdir -p /tmp/ss/dnsmasq.d
rm -f /tmp/ss/dnsmasq.d/*
cd /tmp/ss/
rm_tmp="`ls -p /tmp/ss | grep -v dnsmasq.d/ | grep -v link/`"
[ ! -z "$rm_tmp" ] && rm -rf $rm_tmp
rm_tmp=""
rm -f /opt/bin/ss-redir /opt/bin/ssr-redir /opt/bin/ss-local /opt/bin/ssr-local /opt/bin/obfs-local
rm -f /opt/bin/ss0-redir /opt/bin/ssr0-redir /opt/bin/ss0-local /opt/bin/ssr0-local
rm -f /opt/bin/pdnsd /opt/bin/dnsproxy
 #rm -f /etc/storage/china_ip_list.txt /etc/storage/basedomain.txt
 #[ ! -f /etc/storage/china_ip_list.txt ] && tar -xzvf /etc_ro/china_ip_list.tgz -C /tmp && ln -sf /tmp/china_ip_list.txt /etc/storage/china_ip_list.txt
 #[ ! -f /etc/storage/basedomain.txt ] && tar -xzvf /etc_ro/basedomain.tgz -C /tmp && ln -sf /tmp/basedomain.txt /etc/storage/basedomain.txt
sync
/tmp/script/_kcp_tun &
eval "$scriptfilepath &"
exit 0
}


stop_SS()
{
kill_ps "$scriptname keep"
kill_ps "sh_ezscript.sh"
kill_ps "Sh15_ss.sh"
clean_ss_rules
cru.sh d ss_update &
rm -f /tmp/check_timeout/*
ss-rules -f
nvram set ss_internet="0"
/etc/storage/script/sh_ezscript.sh 3 & #更新按钮状态
rm -f $confdir/r.wantoss.conf
sed -Ei "/conf-dir=$confdir_x/d" /etc/storage/dnsmasq/dnsmasq.conf
restart_dhcpd
killall_ss_redir
killall_ss_local
ss_plugin_client_name="$(nvram get ss_plugin_client_name)"
[ ! -z "$ss_plugin_client_name" ] && { kill_ps "$ss_plugin_client_name" ; ss_plugin_client_name="" ; nvram set ss_plugin_client_name="" ; }
killall pdnsd dnsproxy sh_sskeey_k.sh
killall -9 pdnsd dnsproxy sh_sskeey_k.sh
rm -f /tmp/sh_sskeey_k.sh
[ -f /opt/etc/init.d/S24chinadns ] && { rm -f /var/log/chinadns.lock; /opt/etc/init.d/S24chinadns stop& }
[ -f /opt/etc/init.d/S26pdnsd ] && { rm -f /var/log/pdnsd.lock; /opt/etc/init.d/S26pdnsd stop& }
[ -f /opt/etc/init.d/S27pcap-dnsproxy ] && { rm -f /var/log/pcap-dnsproxy.lock; /opt/etc/init.d/S27pcap-dnsproxy stop& }
nvram set gfwlist3="SS stop."
/etc/storage/script/sh_ezscript.sh 3 & #更新按钮状态
umount  /usr/sbin/ss-redir
umount  /usr/sbin/ss-local
umount -l /usr/sbin/ss-redir
umount -l /usr/sbin/ss-local
kill_ps "sh_ezscript.sh"
kill_ps "/tmp/script/_ss"
kill_ps "_ss.sh"
kill_ps "$scriptname"
}

ss_restart () {

relock="/var/lock/ss_restart.lock"
if [ "$1" = "o" ] ; then
	nvram set ss_renum="0"
	[ -f $relock ] && rm -f $relock
	return 0
fi
if [ "$1" = "x" ] ; then
	if [ -f $relock ] ; then
		if [ ! -z "$app_95" ] ; then
			[ -f $relock ] && rm -f $relock
			logger -t "【SS_restart】" "匹配关键词自动选用节点故障转移 /tmp/link_matching/link_matching.txt"
			/etc/storage/script/sh_ezscript.sh ss_link_matching & 
			sleep 10
		fi
		logger -t "【ss】" "多次尝试启动失败，等待【"`cat $relock`"分钟】后自动尝试重新启动"
		exit 0
	fi
	ss_renum=${ss_renum:-"0"}
	ss_renum=`expr $ss_renum + 1`
	nvram set ss_renum="$ss_renum"
	if [ "$ss_renum" -gt "2" ] ; then
		I=19
		echo $I > $relock
		logger -t "【ss】" "多次尝试启动失败，等待【"`cat $relock`"分钟】后自动尝试重新启动"
		while [ $I -gt 0 ]; do
			I=$(($I - 1))
			echo $I > $relock
			sleep 60
			[ "$(nvram get ss_renum)" = "0" ] && exit 0
			[ $I -lt 0 ] && break
		done
		nvram set ss_renum="0"
	fi
	[ -f $relock ] && rm -f $relock
fi
nvram set ss_status=0
eval "$scriptfilepath &"
sleep 5
exit 0
}

ss_get_status () {

A_restart=`nvram get ss_status`
B_restart="$ss_enable$chinadns_enable$ss_threads$ss_link_2$ss_update$ss_update_hour$ss_update_min$lan_ipaddr$ss_updatess$ss_DNS_Redirect$ss_DNS_Redirect_IP$ss_type$ss_check$ss_run_ss_local$ss_s1_local_address$ss_s1_local_port$ss_pdnsd_wo_redir$ss_mode_x$ss_multiport$ss_sub4$ss_sub1$ss_sub2$ss_sub3$ss_sub5$ss_sub6$ss_sub7$ss_sub8$ss_upd_rules$ss_tochina_enable$ss_udp_enable$LAN_AC_IP$ss_3p_enable$ss_3p_gfwlist$ss_3p_kool$ss_pdnsd_all$kcptun_server$server_addresses$(nvram get wan0_dns |cut -d ' ' -f1)$(cat /etc/storage/shadowsocks_ss_spec_lan.sh /etc/storage/shadowsocks_ss_spec_wan.sh /etc/storage/shadowsocks_mydomain_script.sh | grep -v '^#' | grep -v "^$")"
B_restart=`echo -n "$B_restart" | md5sum | sed s/[[:space:]]//g | sed s/-//g`
if [ "$A_restart" != "$B_restart" ] ; then
	nvram set ss_status=$B_restart
	needed_restart=1
	ss_get_status2
else
	needed_restart=0
	ss_get_status2
fi
}

ss_get_status2 () {

A_restart="$(nvram get ss_status2)"
B_restart="$ss_server$ss_server_port$ss_method$ss_key$ss_usage"
B_restart=`echo -n "$B_restart" | md5sum | sed s/[[:space:]]//g | sed s/-//g`
nvram set ss_status2="$B_restart"
if [ "$needed_restart" = "1" ] ; then
	nvram set ss_status2="$B_restart"
else
if [ "$A_restart" != "$B_restart" ] ; then
	nvram set ss_status2="$B_restart"
	needed_restart=2
else
	needed_restart=0
fi
fi
}

check_setting()
{
check_webui_yes
needed_restart=0
sh_link.sh check_app_24
ss_get_status
if [ "$ss_enable" != "1" ] && [ "$needed_restart" = "1" ] ; then
	[ ! -z "`pidof ss-redir`" ] && logger -t "【SS】" "停止 ss-redir" && stop_SS
	[ ! -z "`pidof ss-local`" ] && logger -t "【SS】" "停止 ss-local" && stop_SS
	{ kill_ps "$scriptname" exit0; exit 0; }
fi
if [ "$ss_enable" = "1" ] ; then
	[ $ss_server ] || logger -t "【SS】" "服务器地址:未填写"
	[ $ss_server_port ] || logger -t "【SS】" "服务器端口:未填写"
	[ $ss_method ] || logger -t "【SS】" "加密方式:未填写"
	[ $ss_server ] && [ $ss_server_port ] && [ $ss_method ] \
	 ||  { logger -t "【SS】" "SS配置有错误，请到扩展功能检查SS配置页面"; stop_SS; [ ! -z "$app_95" ] && /etc/storage/script/sh_ezscript.sh ss_link_matching; sleep 20; exit 1; }
	if [ "$needed_restart" = "2" ] ; then
		logger -t "【SS】" "检测:更换线路配置，进行快速切换服务器。"
		swap_ss_redir
		logger -t "【SS】" "切换服务器完成。"
		eval "$scriptfilepath keep &"
		exit 0
	fi
	if [ "$needed_restart" = "1" ] ; then
		# ss_link_cron_job &
		stop_SS
		start_SS
	else
		[ "$ss_mode_x" = "3" ] && { [ -z "`pidof ss-local`" ] || [ ! -s "`which ss-local`" ] && ss_restart ; }
		[ "$ss_mode_x" != "3" ] && { [ -z "`pidof ss-redir`" ] || [ ! -s "`which ss-redir`" ] && ss_restart ; }
	fi
fi

}

sleep_rnd () {
sleep 10
#随机延时
ss_internet=`nvram get ss_internet`
if [ "$ss_internet" = "1" ] ; then
	SEED=`tr -cd 0-9 </dev/urandom | head -c 8`
	RND_NUM=`echo $SEED 66 77|awk '{srand($1);printf "%d",rand()*10000%($3-$2)+$2}'`
	[ "$RND_NUM" -lt 66 ] && RND_NUM="66" || { [ "$RND_NUM" -gt 66 ] || RND_NUM="66" ; }
	sleep $RND_NUM
fi
#/etc/storage/script/sh_ezscript.sh 3 & #更新按钮状态
}


SS_keep () {
gen_include
cat > "/tmp/sh_sskeey_k.sh" <<-SSMK
#!/bin/sh
source /etc/storage/script/init.sh
for ss_1i in \$(seq 0 16)
do
NUM=\`ps -w | grep "Sh15_ss.sh keep" | grep -v grep |wc -l\`
if [ "\$NUM" -lt "1" ] ; then
break
fi
sleep 60
done
ss_enable=\`nvram get ss_enable\`
if [ "\$ss_enable" = "1" ] ; then
rm -f /tmp/check_timeout/*
kill_ps "$scriptname"
eval "$scriptfilepath keep &"
exit 0
fi
SSMK
chmod 777 "/tmp/sh_sskeey_k.sh"
kill_ps "$scriptname keep"
kill_ps "Sh15_ss.sh"
rm -f /tmp/check_timeout/*
killall sh_sskeey_k.sh
killall -9 sh_sskeey_k.sh
/tmp/sh_sskeey_k.sh &
rebss=1
ss_run_ss_local=`nvram get ss_run_ss_local`
ss_mode_x=`nvram get ss_mode_x`
/etc/storage/script/sh_ezscript.sh 3 & #更新按钮状态
sleep 3
ss_enable=`nvram get ss_enable`
while [ "$ss_enable" = "1" ];
do
ss_rebss_n=`nvram get ss_rebss_n`
ss_rebss_a=`nvram get ss_rebss_a`
if [ "$ss_rebss_n" != 0 ] ; then
	if [ "$rebss" -gt "$ss_rebss_n" ] && [ "$ss_rebss_a" == "0" ] ; then
		logger -t "【SS】" " 网络连接 shadowsocks 中断 ['$rebss'], 重启SS."
		nvram set ss_status=0
		eval "$scriptfilepath &"
		sleep 10
		exit 0
	fi
	if [ "$rebss" -gt "$ss_rebss_n" ] && [ "$ss_rebss_a" == "1" ] ; then
		logger -t "【SS】" " 网络连接 shadowsocks 中断 ['$rebss'], 停止SS."
		nvram set ss_enable=0
		eval "$scriptfilepath &"
		sleep 10
		exit 0
	fi
	if [ "$rebss" -gt "$ss_rebss_n" ] && [ "$ss_rebss_a" == "2" ] ; then
		logger -t "【SS】" " 网络连接 shadowsocks 中断['$rebss'], 重启路由."
		sleep 5
		reboot
	fi
fi
if [ "$rebss" -gt 6 ] ; then
	logger -t "【SS】" " 网络连接 shadowsocks 中断 ['$rebss'], 重启SS."
	nvram set ss_status=0
	eval "$scriptfilepath &"
	sleep 10
	exit 0
fi
sleep 3
ss_enable=`nvram get ss_enable`
if [ "$ss_enable" != "1" ] ; then
	#跳出当前循环
	exit 
fi
if [ "$ss_mode_x" = "3" ] || [ "$ss_run_ss_local" = "1" ] ; then
	NUM=`ps -w | grep ss-local_ | grep -v grep |wc -l`
	SSRNUM=1
		if [ "$NUM" -lt "$SSRNUM" ] || [ ! -s "`which ss-local`" ] ; then
		logger -t "【SS】" "找不到 $SSRNUM ss-local 进程 $rebss, 重启SS."
		nvram set ss_status=0
		eval "$scriptfilepath &"
		sleep 10
		exit 0
	fi
	if [ "$ss_mode_x" = "3" ] ; then
		sleep_rnd
		#跳出当前循环
		continue
	fi
fi

NUM=`ps -w | grep ss-redir_ | grep -v grep |wc -l`
SSRNUM=1
SSRNUM_udp=0
[ "$ss_udp_enable" == 1 ] && SSRNUM_udp=$SSRNUM
[ "$ss_threads" != 0 ] && SSRNUM=`expr $threads \* $SSRNUM + 1 + $SSRNUM_udp`
if [ "$NUM" -lt "$SSRNUM" ] ; then
	logger -t "【SS】" "$NUM 找不到 $SSRNUM shadowsocks 进程 $rebss, 重启SS."
	nvram set ss_status=0
	eval "$scriptfilepath &"
	sleep 10
	exit 0
fi
ss_keep_check=`nvram get ss_keep_check`
[ -z "$ss_keep_check" ] && ss_keep_check=1 && nvram set ss_keep_check=$ss_keep_check
if [ "$ss_keep_check" != "1" ] ; then
	#不需要 持续检查 SS 服务器状态
	sleep_rnd
	#跳出当前循环
	continue
fi
#SS进程监控
#思路：
#先将所有ss通道全部拉起来，默认服务器为1090端口，默认走通道0
#检查SS通道是否可以连接google，如果不能，则看看网易是否正常，如果网易正常，而google无法打开，则说明当前SS通道有问题
#通道有问题时，先logger记录，然后切换SS通道端口和修改 
# sh_ssmon 建议不要重启网络，会导致断线。正常来说,ss服务基本上稳定不需要重启，我公司路由的ss客户端跑20多台机器将近3个多月没动过了。



LOGTIME=$(date "+%Y-%m-%d %H:%M:%S")

#检查是否存在当前SS服务器，没有则设为0，准备切换服务器设为1
ss_udp_enable=`nvram get ss_udp_enable` #udp转发  0、停用；1、启动
ss_upd_rules=`nvram get ss_upd_rules`
ss_pdnsd_wo_redir=`nvram get ss_pdnsd_wo_redir` #pdnsd  1、直连；0、走代理

check2=404
check_timeout_network "wget_check"
if [ "$check2" == "200" ] ; then
	echo "[$LOGTIME] SS $app_97 have no problem."
	rebss="1"
	nvram set ss_internet="1"
	sleep_rnd
	#跳出当前循环
	continue
fi

#404
Sh99_ss_tproxy.sh auser_check "Sh15_ss.sh"
Sh99_ss_tproxy.sh s_ss_tproxy_check "Sh15_ss.sh"
check2=404
check_timeout_network "wget_check" "check"
if [ "$check2" == "200" ] ; then
	echo "[$LOGTIME] SS $app_97 have no problem."
	rebss="1"
	nvram set ss_internet="1"
	sleep_rnd
	#跳出当前循环
	continue
fi
#404
if [ ! -z "$app_95" ] ; then
	nvram set ss_internet="2"
	rebss=`expr $rebss + 1`
	logger -t "【SS】" " SS 服务器 【$app_97】 检测到问题, $rebss"
	logger -t "【SS】" "匹配关键词自动选用节点故障转移 /tmp/link_matching/link_matching.txt"
	/etc/storage/script/sh_ezscript.sh ss_link_matching & 
	sleep 10
	#跳出当前循环
	continue
fi

#404
nvram set ss_internet="0"
logger -t "【SS】" " SS 服务器 【$app_97】 检测到问题, $rebss"
rebss=`expr $rebss + 1`
restart_dhcpd
#/etc/storage/crontabs_script.sh &

done

}

ss_link_cron_job(){

/etc/storage/script/sh_link.sh

}

SS_swap(){

ss_internet=`nvram get ss_internet`
if [ "$ss_internet" != "1" ] ; then
	logger -t "【ss】" "注意！各线路正在启动，请等待启动后再尝试切换"
fi
if [ ! -z "$app_95" ] && [ "$ss_internet" = "1" ] ; then
	logger -t "【SS】" "匹配关键词自动选用节点故障转移 /tmp/link_matching/link_matching.txt"
	nvram set ss_internet="2"
	/etc/storage/script/sh_ezscript.sh ss_link_matching & 
	sleep 10
	return
fi
}

ss_cron_job(){
	[ -z $ss_update ] && ss_update=0 && nvram set ss_update=$ss_update
	[ -z $ss_update_hour ] && ss_update_hour=23 && nvram set ss_update_hour=$ss_update_hour
	[ -z $ss_update_min ] && ss_update_min=59 && nvram set ss_update_min=$ss_update_min
	[ "$ss_mode_x" = "3" ] && ss_update=2 #3为ss-local 建立本地 SOCKS 代理
	if [ "0" == "$ss_update" ]; then
	[ $ss_update_hour -gt 23 ] && ss_update_hour=23 && nvram set ss_update_hour=$ss_update_hour
	[ $ss_update_hour -lt 0 ] && ss_update_hour=0 && nvram set ss_update_hour=$ss_update_hour
	[ $ss_update_min -gt 59 ] && ss_update_min=59 && nvram set ss_update_min=$ss_update_min
	[ $ss_update_min -lt 0 ] && ss_update_min=0 && nvram set ss_update_min=$ss_update_min
		logger -t "【ss】" "开启规则定时更新，每天"$ss_update_hour"时"$ss_update_min"分，检查在线规则更新..."
		cru.sh a ss_update "$ss_update_min $ss_update_hour * * * $scriptfilepath update &" &
	elif [ "1" == "$ss_update" ]; then
	#[ $ss_update_hour -gt 23 ] && ss_update_hour=23 && nvram set ss_update_hour=$ss_update_hour
	[ $ss_update_hour -lt 0 ] && ss_update_hour=0 && nvram set ss_update_hour=$ss_update_hour
	[ $ss_update_min -gt 59 ] && ss_update_min=59 && nvram set ss_update_min=$ss_update_min
	[ $ss_update_min -lt 0 ] && ss_update_min=0 && nvram set ss_update_min=$ss_update_min
		logger -t "【ss】" "开启规则定时更新，每隔"$ss_update_inter_hour"时"$ss_update_inter_min"分，检查在线规则更新..."
		cru.sh a ss_update "$ss_update_min */$ss_update_hour * * * $scriptfilepath update &" &
	else
		logger -t "【ss】" "规则自动更新关闭状态，不启用自动更新..."
	fi
}

initopt () {
optPath=`grep ' /opt ' /proc/mounts | grep tmpfs`
[ ! -z "$optPath" ] && return
if [ ! -z "$(echo $scriptfilepath | grep -v "/opt/etc/init")" ] && [ -s "/opt/etc/init.d/rc.func" ] ; then
	{ echo '#!/bin/sh' ; echo $scriptfilepath '"$@"' '&' ; } > /opt/etc/init.d/$scriptname && chmod 777  /opt/etc/init.d/$scriptname
fi

}

initconfig () {

shadowsocks_ss_spec_lan="/etc/storage/shadowsocks_ss_spec_lan.sh"
[ -z "$(cat $shadowsocks_ss_spec_lan | grep "ss_tproxy")" ] && rm -f $shadowsocks_ss_spec_lan
if [ ! -f "$shadowsocks_ss_spec_lan" ] || [ ! -s "$shadowsocks_ss_spec_lan" ] ; then
	cat > "$shadowsocks_ss_spec_lan" <<-\EEE
# 内网(LAN)IP设定行为设置, 格式如 b,192.168.1.23, 每一行一个配置
#   使用 b/g/n/1/2 前缀定义主机行为模式, 使用英文逗号与主机 IP、MAC 分隔
#   b: 绕过, 此前缀的主机IP、MAC 不使用 SS
#   g: 全局, 此前缀的主机IP、MAC 使用 全局代理 走 SS
#   n: 常规, 此前缀的主机IP、MAC 使用 mode 工作模式 走 SS
#   1: 大陆白名单, 此前缀的主机IP、MAC 使用 大陆白名单模式 走 SS
#   2: gfwlist, 此前缀的主机IP、MAC 使用 gfwlist模式 走 SS
# 优先级: 绕过 > 全局 > 常规 > gfwlist > 大陆白名单 > MAC > IP
# IPv6地址：必须以 ~ 符号开头，如 ~b,2333:2333:2333::
# MAC地址：必须以 @ 符号开头，如 @b,099B9A909FD9
# 注意：修改此文件需重启 ss_tproxy 生效，另外请删除每行首尾多余的空白符
# 注释：以井号开头的行以及空行都视为注释行
#b,192.168.123.115
#~b,2333:2333:2333::
#g,192.168.123.116
#n,192.168.123.117
#1,192.168.123.118
#2,192.168.123.119
#@b,099B9A909FD9
#@1,099B9A909FD9
#@2,A9:CB:3A:5F:1F:C7

EEE
	chmod 755 "$shadowsocks_ss_spec_lan"
fi

shadowsocks_ss_spec_wan="/etc/storage/shadowsocks_ss_spec_wan.sh"
[ -z "$(cat $shadowsocks_ss_spec_wan | grep "ss_tproxy")" ] && rm -f $shadowsocks_ss_spec_wan
if [ ! -f "$shadowsocks_ss_spec_wan" ] || [ ! -s "$shadowsocks_ss_spec_wan" ] ; then
	cat > "$shadowsocks_ss_spec_wan" <<-\EEE
# 外网(WAN)IP设定行为设置, 格式如 b,192.168.1.23, 每一行一个配置
#   使用 b/g 前缀定义访问目标行为模式, 使用英文逗号与目标 IP 分隔
#   b: 绕过, 此前缀的目标IP 不使用 SS
#   g: 全局, 此前缀的目标IP 使用 SS
# 优先级: 绕过 > 全局
# IPv6地址：必须以 ~ 符号开头，如 ~b,2333:2333:2333::
# 网址域名：必须以 @ 符号开头，如 @b,abc.net，匹配 abc.net、*.abc.net
# 注意：修改此文件需重启 ss_tproxy 生效，另外请删除每行首尾多余的空白符
# 注释：以井号开头的行以及空行都视为注释行
# 
# DNS
g,8.8.8.8
g,8.8.4.4
g,208.67.222.222
g,208.67.220.220
# 
# Telegram IPv4
g,91.108.4.0/22
g,91.108.8.0/22
g,91.108.12.0/22
g,91.108.20.0/22
g,91.108.36.0/23
g,91.108.38.0/23
g,91.108.56.0/22
g,149.154.160.0/20
g,149.154.161.0/24
g,149.154.162.0/23
g,149.154.164.0/22
g,149.154.168.0/21
g,149.154.172.0/22
g,149.154.160.1/32
g,149.154.160.2/31
g,149.154.160.4/30
g,149.154.160.8/29
g,149.154.160.16/28
g,149.154.160.32/27
g,149.154.160.64/26
g,149.154.160.128/25
g,149.154.164.0/22
g,91.108.4.0/22
g,91.108.56.0/24
g,109.239.140.0/24
g,67.198.55.0/24
g,91.108.56.172
g,149.154.175.50
# 
# Telegram IPv6
~g,2001:67c:4e8::/48
~g,2001:0b28:f23d::/48
# 
# api
@g,api.telegram.org
@g,raw.githubusercontent.com
@b,api.cloud.189.cn
@b,pv.sohu.com
@b,members.3322.org
@b,www.cloudxns.net
@b,dnsapi.cn
@b,api.dnspod.com
@b,www.ipip.net
@b,alidns.aliyuncs.com
@b,services.googleapis.cn
# 
# 以下样板是四个网段分别对应BLZ的美/欧/韩/台服
#g,24.105.0.0/18
#g,80.239.208.0/20
#g,182.162.0.0/16
#g,210.242.235.0/24

EEE
	chmod 755 "$shadowsocks_ss_spec_wan"
fi

# 删除空行
echo "" >> $shadowsocks_ss_spec_wan
echo "" >> $shadowsocks_ss_spec_lan
echo "" >> /etc/storage/shadowsocks_mydomain_script.sh
sed -Ei '/^$/d' $shadowsocks_ss_spec_wan
sed -Ei '/^$/d' $shadowsocks_ss_spec_lan
sed -Ei '/^$/d' /etc/storage/shadowsocks_mydomain_script.sh

}

initconfig


##############################
### ready go
##############################



case "$1" in
start)
	stop_SS
	check_setting
	;;
keep)
	#check_setting
	check_webui_yes
	SS_keep
	;;
rules)
	start_ss_rules
	;;
flush)
	clean_ss_rules
	;;
update)
	check_webui_yes
	[ "$ss_mode_x" = "3" ] && return #3为ss-local 建立本地 SOCKS 代理
	#check_setting
	[ ${ss_enable:=0} ] && [ "$ss_enable" -eq "0" ] && exit 0
	# [ "$ss_mode_x" = "3" ] && exit 0
	#随机延时
	SEED=`tr -cd 0-9 </dev/urandom | head -c 8`
	RND_NUM=`echo $SEED 1 600|awk '{srand($1);printf "%d",rand()*10000%($3-$2)+$2}'`
	[ "$RND_NUM" -lt 1 ] && RND_NUM="1" || { [ "$RND_NUM" -gt 1 ] || RND_NUM="1" ; }
	# echo $RND_NUM
	logger -t "【SS】" "$RND_NUM 秒后进入处理状态, 请稍候"
	sleep $RND_NUM
	killall sh_sskeey_k.sh
	killall -9 sh_sskeey_k.sh
	nvram set app_111=5
	Sh99_ss_tproxy.sh
	[ -s /tmp/sh_sskeey_k.sh ] && /tmp/sh_sskeey_k.sh &
	;;
updatess)
	check_webui_yes
	logger -t "【SS】" "手动更新 SS 规则文件 5 秒后进入处理状态, 请稍候"
	sleep 5
	nvram set app_111=5
	Sh99_ss_tproxy.sh
	;;
uplink)
	ss_link_cron_job &
	;;
stop)
	stop_SS
	;;
repdnsd)
	start_pdnsd
	;;
help)
	echo "Usage: $0 {start|rules|flush|update|stop}"
	;;
update_optss)
	ss_restart o
	clean_SS
	exit 0
	;;
swapss)
	SS_swap
	;;
*)
	check_setting
	exit 0
	;;
esac





