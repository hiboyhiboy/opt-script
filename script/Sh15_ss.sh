#!/bin/bash
#copyright by hiboy
source /etc/storage/script/init.sh
source /etc/storage/script/sh_link.sh

ss_enable=`nvram get ss_enable`
[ -z $ss_enable ] && ss_enable=0 && nvram set ss_enable=0
ipt2socks_enable=`nvram get app_104`
[ -z $ipt2socks_enable ] && ipt2socks_enable=0 && nvram set app_104=0
app_95="$(nvram get app_95)"
[ -z "$app_95" ] && app_95="." && nvram set app_95="."
ss_matching_enable="$(nvram get ss_matching_enable)"
[ -z $ss_matching_enable ] && ss_matching_enable=0 && nvram set ss_matching_enable=0
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
[ -z "$ss_threads" ] && ss_threads=0 && nvram set ss_threads=0
if [ "$ss_threads" != 0 ] ; then
threads="$(cat /proc/cpuinfo | grep 'processor' | wc -l)"
[ -z "$threads" ] && threads=1
if [ "$threads" = "1" ] ;then
	logger -t "【SS】" "检测到单核CPU，多线程启动失败"
	nvram set ss_threads=0
	ss_threads=0
fi
if [ "$ss_threads" != "1" ] ;then
	if [ "$ss_threads" -ge "$threads" ] ; then
	nvram set ss_threads=1
	else
	threads="$ss_threads"
	fi
fi
fi
koolproxy_enable=`nvram get koolproxy_enable`
ss_dnsproxy_x=`nvram get ss_dnsproxy_x`

ss_keep_check=`nvram get ss_keep_check`
[ -z $ss_keep_check ] && ss_keep_check=1 && nvram set ss_keep_check=$ss_keep_check
#set -x
#初始化开始
FWI="/tmp/firewall.shadowsocks.pdcn" # firewall include file

ss_type=`nvram get ss_type`
[ -z $ss_type ] && ss_type=0 && nvram set ss_type=$ss_type
ss_run_ss_local=`nvram get ss_run_ss_local`
[ -z $ss_run_ss_local ] && ss_run_ss_local=0 && nvram set ss_run_ss_local=$ss_run_ss_local

ss_server=`nvram get ss_server`
ss_server_port=`nvram get ss_server_port`
ss_key=`nvram get ss_key`
ss_method=`nvram get ss_method | tr 'A-Z' 'a-z'`

ss_s1_local_address=`nvram get ss_s1_local_address`
[ -z $ss_s1_local_address ] && ss_s1_local_address="0.0.0.0" && nvram set ss_s1_local_address=$ss_s1_local_address
ss_s1_local_port=`nvram get ss_s1_local_port`
[ -z $ss_s1_local_port ] && ss_s1_local_port=1081 && nvram set ss_s1_local_port=$ss_s1_local_port

ss_pdnsd_wo_redir=`nvram get ss_pdnsd_wo_redir` #pdnsd  0、走代理；1、直连
[ -z $ss_pdnsd_wo_redir ] && ss_pdnsd_wo_redir=0 && nvram set ss_pdnsd_wo_redir=$ss_pdnsd_wo_redir
ss_mode_x=`nvram get ss_mode_x` #ss模式，0 为chnroute, 1 为 gfwlist, 2 为全局, 3为ss-local 建立本地 SOCKS 代理
[ -z $ss_mode_x ] && ss_mode_x=0 && nvram set ss_mode_x=$ss_mode_x
ss_multiport=`nvram get ss_multiport`
[ -z "$ss_multiport" ] && ss_multiport="22,80,443" && nvram set ss_multiport=$ss_multiport
[ -n "$ss_multiport" ] || ss_multiport="22,80,443" # 处理多端口设定
# 严重警告，如果走chnrouter 和全局模式，又不限制端口，下载流量都会通过你的ss服务器往外走，随时导致你的ss服务器被封或ss服务商封你帐号，设置连累你的SS服务商被封

# DNS 端口，用于防止域名污染用的PDNSD
DNS_Server=127.0.0.1#8053

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

ss_usage="$(nvram get ss_usage)"

LAN_AC_IP=`nvram get LAN_AC_IP`
[ -z $LAN_AC_IP ] && LAN_AC_IP=0 && nvram set LAN_AC_IP=$LAN_AC_IP

lan_ipaddr=`nvram get lan_ipaddr`
ss_DNS_Redirect=`nvram get ss_DNS_Redirect`
ss_DNS_Redirect_IP=`nvram get ss_DNS_Redirect_IP`
[ -z "$ss_DNS_Redirect_IP" ] && ss_DNS_Redirect_IP=$lan_ipaddr


[ -z $ss_dnsproxy_x ] && ss_dnsproxy_x=0 && nvram set ss_dnsproxy_x=0
chinadns_enable=`nvram get app_1`
[ -z $chinadns_enable ] && chinadns_enable=0 && nvram set app_1=0
chinadns_ng_enable=`nvram get app_102`
[ -z $chinadns_ng_enable ] && chinadns_ng_enable=0 && nvram set app_102=0
chinadns_port=`nvram get app_6`
[ -z $chinadns_port ] && chinadns_port=8053 && nvram set app_6=8053
if [ "$chinadns_port" != "8053" ] ; then
chinadns_enable=0
chinadns_ng_enable=0
fi
if [ "$chinadns_enable" != "0" ] || [ "$chinadns_ng_enable" != "0" ] ; then
ss_dnsproxy_x=2 ; nvram set ss_dnsproxy_x=2
else
[ "$ss_dnsproxy_x" = "2" ] && ss_dnsproxy_x=0 && nvram set ss_dnsproxy_x=0
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

gid_owner="$(nvram get gid_owner)"
gid_owner=${gid_owner:-"0"}
ss_link_2=`nvram get ss_link_2`
[ -z $ss_link_2 ] && ss_link_2="www.google.com.hk" && nvram set ss_link_2="www.google.com.hk"
ss_link_1=`nvram get ss_link_1`
[ "$ss_link_1" -lt 66 ] && ss_link_1="66" || { [ "$ss_link_1" -ge 66 ] || { ss_link_1="66" ; nvram set ss_link_1="66" ; } ; }

#检查 dnsmasq 目录参数
#confdir=`grep "/tmp/ss/dnsmasq.d" /etc/storage/dnsmasq/dnsmasq.conf | sed 's/.*\=//g'`
#if [ -z "$confdir" ] ; then 
	confdir="/tmp/ss/dnsmasq.d"
#fi
confdir_x="$(echo -e $confdir | sed -e "s/\//"'\\'"\//g")"
[ ! -d "$confdir" ] && mkdir -p $confdir

if [ ! -z "$(echo $scriptfilepath | grep -v "/tmp/script/" | grep ss)" ]  && [ ! -s /tmp/script/_ss ]; then
	mkdir -p /tmp/script
	{ echo '#!/bin/bash' ; echo $scriptfilepath '"$@"' '&' ; } > /tmp/script/_ss
	chmod 777 /tmp/script/_ss
fi

ss_tproxy_set () {
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
[ "$ss_ip46" = "0" ] && sstp_set tproxy='false' # true:TPROXY+TPROXY; false:REDIRECT+TPROXY
[ "$ss_ip46" != "0" ] && sstp_set tproxy='true'
[ "$ss_udp_enable" == 1 ] && sstp_set tcponly='false' # true:仅代理TCP流量; false:代理TCP和UDP流量
[ "$ss_udp_enable" != 1 ] && sstp_set tcponly='true' # true:仅代理TCP流量; false:代理TCP和UDP流量
sstp_set selfonly='false'  # true:仅代理本机流量; false:代理本机及"内网"流量
nvram set app_112="0"      #app_112 0:自动开启第三方 DNS 程序(dnsproxy) ; 1:跳过自动开启第三方 DNS 程序但是继续把DNS绑定到 8053 端口的程序
#nvram set app_113="0"      #app_113 0:使用 8053 端口查询全部 DNS 时进行 China 域名加速 ; 1:不进行 China 域名加速
nvram set app_114="0" # 0:代理本机流量; 1:跳过代理本机流量
sstp_set uid_owner='0' # 非 0 时进行用户ID匹配跳过代理本机流量
gid_owner="$(nvram get gid_owner)"
sstp_set gid_owner="$gid_owner" # 非 0 时进行组ID匹配跳过代理本机流量
## proxy
sstp_set proxy_all_svraddr="/opt/app/ss_tproxy/conf/proxy_all_svraddr.conf"
sstp_set proxy_svrport='1:65535'
sstp_set proxy_tcpport='1090'
sstp_set proxy_udpport='1090'
sstp_set proxy_startcmd='date'
sstp_set proxy_stopcmd='date'
## dns
DNS_china=`nvram get wan0_dns |cut -d ' ' -f1`
[ -z "$DNS_china" ] && DNS_china="223.5.5.5"
[ "$ss_tochina_enable" == "0" ] && sstp_set dns_direct="$DNS_china"
[ "$ss_tochina_enable" == "0" ] && sstp_set dns_direct6='240C::6666'
[ "$ss_tochina_enable" == "0" ] && sstp_set dns_remote='8.8.8.8#53'
[ "$ss_tochina_enable" == "0" ] && sstp_set dns_remote6='::1#8053'
[ "$ss_tochina_enable" != "0" ] && sstp_set dns_direct='8.8.8.8' # 回国模式
[ "$ss_tochina_enable" != "0" ] && sstp_set dns_direct6='2001:4860:4860::8888' # 回国模式
[ "$ss_tochina_enable" != "0" ] && sstp_set dns_remote='223.5.5.5#53' # 回国模式
[ "$ss_tochina_enable" != "0" ] && sstp_set dns_remote6='240C::6666#53' # 回国模式
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
logger -t "【SS】" "【自动】设置 ss_tproxy 配置文件，完成配置导入"
}

SSJSON_sh () {

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
protocol_json="$(nvram get ssr_type_protocol)"
protocol_param_json="$(nvram get ssr_type_protocol_custom)"
obfs_json="$(nvram get ssr_type_obfs)"
obfs_param_json="$(nvram get ssr_type_obfs_custom)"
plugin_json="$(nvram get ss_plugin_name)"
obfs_plugin_json="$(nvram get ss_plugin_config)"
tcp_and_udp="tcp_only"
[ "$ss_udp_enable" == 1 ] && tcp_and_udp="tcp_and_udp"
tcp_tproxy="false"
[ "$ss_ip46" != "0" ] && tcp_tproxy="true"
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
"plugin_opts": "$obfs_plugin_json",
"reuse_port": true,
"mode": "$tcp_and_udp",
"tcp_tproxy": $tcp_tproxy
}

SSJSON

[ "$ss_type" == 1 ] && sed -Ei '/"plugin":|"plugin_opts":|"reuse_port":|^$/d' "$config_file"
}

usage_switch () {

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
 | sed -e 's@ -T @ 丨 -T @g' \
 | sed -e 's@ -c @ 丨 -c @g' \
 | sed -e 's@ -n @ 丨 -n @g' \
 | sed -e 's@ -i @ 丨 -i @g' \
 | sed -e 's@ -b @ 丨 -b @g' \
 | sed -e 's@ -u @ 丨 -u @g' \
 | sed -e 's@ -U @ 丨 -U @g' \
 | sed -e 's@ -6 @ 丨 -6 @g' \
 | sed -e 's@ -d @ 丨 -d @g' \
 | sed -e 's@ --tcp-incoming-sndbuf @ 丨 --tcp-incoming-sndbuf @g' \
 | sed -e 's@ --tcp-outgoing-sndbuf @ 丨 --tcp-outgoing-sndbuf @g' \
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

start_ss_redir () {

ss_plugin_client_name="$(nvram get ss_plugin_client_name)"
[ ! -z "$ss_plugin_client_name" ] && { kill_ps "$ss_plugin_client_name" ; ss_plugin_client_name="" ; nvram set ss_plugin_client_name="" ; }
[ -z "$ss_server" ] && { logger -t "【SS】" "[错误!!] SS服务器没有设置"; stop_SS; clean_SS; } 

if [ ! -z "$ss_usage" ] ; then
# 高级启动参数分割
ss_usage="$(usage_switch "$ss_usage")"
# 删除混淆、协议、分割符号
ss_usage="$(echo "$ss_usage" | sed -r 's/\ -g[ ]+[^丨]+//g' | sed -r 's/\ -G[ ]+[^丨]+//g' | sed -r 's/\ -o[ ]+[^丨]+//g' | sed -r 's/\ -O[ ]+[^丨]+//g' | sed -r 's/\ --plugin-opts[ ]+[^丨]+//g' | sed -r 's/\ --plugin[ ]+[^丨]+//g' | sed -e "s@丨@@g" | sed -e "s@  @ @g" | sed -e "s@  @ @g")"
ss_usage="$(echo $ss_usage)"
nvram set ss_usage="$ss_usage"
fi
if [ "$ss_udp_enable" == 1 ] ; then
ss_usage=" $ss_usage -u "
else
ss_usage=" $ss_usage "
fi

ssr_type_obfs="$(nvram get ssr_type_obfs)"
[ -z "$ssr_type_obfs" ] && ssr_type_obfs="plain" && nvram set ssr_type_obfs="$ssr_type_obfs"
ssr_type_protocol="$(nvram get ssr_type_protocol)"
[ -z "$ssr_type_protocol" ] && ssr_type_protocol="origin" && nvram set ssr_type_protocol="$ssr_type_protocol"
ssr_type_obfs_custom="$(nvram get ssr_type_obfs_custom)"
ssr_type_protocol_custom="$(nvram get ssr_type_protocol_custom)"


if [ "$ss_method" == "aes-128-cfb" ] || [ "$ss_method" == "aes-128-ctr" ] || [ "$ss_method" == "aes-128-gcm" ] || [ "$ss_method" == "aes-192-cfb" ] || [ "$ss_method" == "aes-192-ctr" ] || [ "$ss_method" == "aes-192-gcm" ] || [ "$ss_method" == "aes-256-cfb" ] || [ "$ss_method" == "aes-256-ctr" ] || [ "$ss_method" == "aes-256-gcm" ] || [ "$ss_method" == "bf-cfb" ] || [ "$ss_method" == "camellia-128-cfb" ] || [ "$ss_method" == "camellia-192-cfb" ] || [ "$ss_method" == "camellia-256-cfb" ] || [ "$ss_method" == "chacha20" ] || [ "$ss_method" == "chacha20-ietf" ] || [ "$ss_method" == "chacha20-ietf-poly1305" ] || [ "$ss_method" == "rc4-md5" ] || [ "$ss_method" == "salsa20" ] || [ "$ss_method" == "xchacha20-ietf-poly1305" ] ; then
	# SS 协议
if [ "$ssr_type_obfs" == "plain" ] && [ "$ssr_type_protocol" == "origin" ] ; then
	[ "$ss_type" == "1" ] && nvram set ss_type=0
	ss_type=0
	nvram set ssr_type_obfs_custom=""
	nvram set ssr_type_protocol_custom=""
	ssr_type_obfs_custom=""
	ssr_type_protocol_custom=""
else
	[ "$ss_type" == "0" ] && nvram set ss_type=1
	ss_type=1
fi
else
	[ "$ss_type" == "0" ] && nvram set ss_type=1
	ss_type=1
fi
if [ "$ssr_type_obfs" != "plain" ] || [ "$ssr_type_protocol" != "origin" ] ; then
	# SSR 协议
	ss_type=1
fi
if [ ! -z "$ssr_type_obfs_custom" ] || [ ! -z "$ssr_type_protocol_custom" ] ; then
	ss_type=1
fi
ssrr_custom="$(echo $ssr_type_protocol | grep -Eo 'auth_chain_c|auth_chain_d|auth_chain_e|auth_chain_f')"
if [ ! -z "$ssrr_custom" ] ; then 
	# SSRR 协议
	ssrr_type=1
	ss_type=1
	nvram set ss_type=$ss_type
fi

# 插件名称
ss_plugin_name="$(nvram get ss_plugin_name)"
# 插件参数
ss_plugin_config="$(nvram get ss_plugin_config)"

# 插件名称 插件参数 调整名称
ss_tmp=0
[ ! -z "$(echo "$ss_plugin_name" | grep "simple-obfs")" ] && ss_plugin_name="obfs-local" && ss_tmp=1
[ ! -z "$(echo "$ss_plugin_config" | grep "obfs-host")" ] && ss_plugin_name="obfs-local" && ss_tmp=1
[ ! -z "$(echo "$ss_plugin_config" | grep "obfs=tls")" ] && ss_plugin_name="obfs-local" && ss_tmp=1
[ ! -z "$(echo "$ss_plugin_config" | grep "obfs=http")" ] && ss_plugin_name="obfs-local" && ss_tmp=1
[ ! -z "$(echo "$ss_plugin_config" | grep "[Uu]ndefined")" ] && ss_plugin_config="" && ss_tmp=1
[ ! -z "$(echo "$ss_plugin_config" | grep "[Nn]ull")" ] && ss_plugin_config="" && ss_tmp=1
[ ! -z "$(echo "$ss_plugin_name" | grep "[Gg]oQuiet")" ] && ss_plugin_name="gq-client" && ss_tmp=1
[ ! -z "$(echo "$ss_plugin_name" | grep "kcptun")" ] && ss_plugin_name="ss_kcptun" && ss_tmp=1
[ ! -z "$(echo "$ss_plugin_name" | grep "client_linux_mipsle")" ] && ss_plugin_name="ss_kcptun" && ss_tmp=1
[ ! -z "$(echo "$ss_plugin_name" | grep "[Cc]loak")" ] && ss_plugin_name="ck-client" && ss_tmp=1
[ ! -z "$(echo "$ss_plugin_name" | grep "[Vv]2ray")" ] && ss_plugin_name="v2ray-plugin" && ss_tmp=1
[ ! -z "$(echo "$ss_plugin_name" | grep "[Uu]ndefined")" ] && ss_plugin_name="" && ss_tmp=1
[ ! -z "$(echo "$ss_plugin_name" | grep "[Nn]ull")" ] && ss_plugin_name="" && ss_tmp=1
[ "$ss_tmp" == "1" ] && nvram set ss_plugin_name="$ss_plugin_name"
[ "$ss_tmp" == "1" ] && nvram set ss_plugin_config="$ss_plugin_config"
[ ! -z "$ss_plugin_name" ] && { ss_plugin_client_name="$ss_plugin_name" ; nvram set ss_plugin_client_name="$ss_plugin_client_name" ; }
ss_plugin_client_name="$(nvram get ss_plugin_client_name)"
[ ! -z "$ss_plugin_client_name" ] && [ -z "$ss_plugin_name" ] && { kill_ps "$ss_plugin_client_name" ; ss_plugin_client_name="" ; nvram set ss_plugin_client_name="" ; }
[ ! -z "$ss_plugin_client_name" ] && kill_ps "$ss_plugin_client_name"


# 启动程序
ss_s1_redir_port=1090
logger -t "【ss-redir】" "启动所有的 ss-redir 连线, 出现的 SS 日志并不是错误报告, 只是使用状态日志, 请不要慌张, 只要系统正常你又看不懂就无视它！"
logger -t "【ss-redir】" "SS服务器【$app_97】设置内容：$ss_server 端口:$ss_server_port 加密方式:$ss_method 本地监听地址：0.0.0.0 本地代理端口：$ss_s1_redir_port "

SSJSON_sh "/tmp/ss-redir_1.json" "1" "r"
killall_ss_redir
check_ssr
gid_owner="0"
su_cmd="eval"
NUM=`iptables -m owner -h 2>&1 | grep owner | wc -l`
hash su 2>/dev/null && su_x="1"
hash su 2>/dev/null || su_x="0"
if [ "$NUM" -ge "3" ] && [ "$su_x" = "1" ] ; then
	addgroup -g 1321 ‍✈️
	adduser -G ‍✈️ -u 1321 ‍✈️ -D -S -H -s /bin/false
	sed -Ei s/1321:1321/0:1321/g /etc/passwd
	su_cmd="su ‍✈️ -s /bin/sh -c "
	gid_owner="1321"
fi
nvram set gid_owner="$gid_owner"
if [ "$ss_threads" != 0 ] ; then
for ss_1i in $(seq 1 $threads)
do
logger -t "【ss-redir】" "启动多线程均衡负载，启动 $ss_1i 线程"
cmd_name="SS_""$ss_1i""_redir"
#eval "ss-redir -c /tmp/ss-redir_1.json $ss_usage $cmd_log" &
su_cmd2="ss-redir -c /tmp/ss-redir_1.json $ss_usage"
eval "$su_cmd" '"cmd_name='"$cmd_name"' && '"$su_cmd2"' $cmd_log"' &
usleep 300000
done
else
cmd_name="SS_1_redir"
#eval "ss-redir -c /tmp/ss-redir_1.json $ss_usage $cmd_log" &
su_cmd2="ss-redir -c /tmp/ss-redir_1.json $ss_usage"
eval "$su_cmd" '"cmd_name='"$cmd_name"' && '"$su_cmd2"' $cmd_log"' &
fi
if [ "$ss_mode_x" = "3" ] || [ "$ss_run_ss_local" = "1" ] ; then
	killall_ss_local
	logger -t "【ss-local】" "启动所有的 ss-local 连线, 出现的 SS 日志并不是错误报告, 只是使用状态日志, 请不要慌张, 只要系统正常你又看不懂就无视它！"
	logger -t "【ss-local】" "SS服务器【$app_97】设置内容：$ss_server 端口:$ss_server_port 加密方式:$ss_method 本地监听地址：$ss_s1_local_address 本地代理端口：$ss_s1_local_port "
	SSJSON_sh "/tmp/ss-local_1.json" "1" "l"
	killall_ss_local
	if [ "$ss_threads" != 0 ] ; then
	for ss_1i in $(seq 1 $threads)
	do
	logger -t "【ss-local】" "启动多线程均衡负载，启动 $ss_1i 线程"
	cmd_name="SS_""$ss_1i""_local"
	#eval "ss-local -c /tmp/ss-local_1.json $ss_usage $cmd_log" &
	su_cmd2="ss-local -c /tmp/ss-local_1.json $ss_usage"
	eval "$su_cmd" '"cmd_name='"$cmd_name"' && '"$su_cmd2"' $cmd_log"' &
	usleep 300000
	done
	else
	cmd_name="SS_1_local"
	#eval "ss-local -c /tmp/ss-local_1.json $ss_usage $cmd_log" &
	su_cmd2="ss-local -c /tmp/ss-local_1.json $ss_usage"
	eval "$su_cmd" '"cmd_name='"$cmd_name"' && '"$su_cmd2"' $cmd_log"' &
	fi
fi

}

start_ss_redir_check () {

sleep 1
[ ! -z "`pidof ss-redir`" ] && logger -t "【SS】" "启动成功" && ss_restart o
[ -z "`pidof ss-redir`" ] && logger -t "【SS】" "启动失败, 注意检查端口是否有冲突,程序是否下载完整,10 秒后自动尝试重新启动" && sleep 10 && ss_restart x
if [ "$ss_mode_x" = "3" ] || [ "$ss_run_ss_local" = "1" ] ; then
	[ "$ss_mode_x" = "3" ] && killall_ss_redir
	[ ! -z "`pidof ss-local`" ] && logger -t "【ss-local】" "启动成功" && ss_restart o
	[ -z "`pidof ss-local`" ] && logger -t "【ss-local】" "启动失败, 注意检查端口是否有冲突,程序是否下载完整,10 秒后自动尝试重新启动" && sleep 10 && ss_restart x
fi

}

killall_ss_redir () {
kill_ps "ss-redir_"
}

killall_ss_local () {
kill_ps "ss-local_"
}

swap_ss_redir () {

kill_ps "$scriptname sskeep"
kill_ps "$scriptname"
# 重载 ipset 规则
Sh99_ss_tproxy.sh auser_check "Sh15_ss.sh"
ss_tproxy_set "Sh15_ss.sh"
Sh99_ss_tproxy.sh x_resolve_svraddr "Sh15_ss.sh"

# 启动新进程
start_ss_redir
start_ss_redir_check
Sh99_ss_tproxy.sh s_ss_tproxy_check "Sh15_ss.sh"
[ "$ss_mode_x" != "3" ] && nvram set gfwlist3="ss-redir start.【$app_97】"
[ "$ss_mode_x" == "3" ] && nvram set gfwlist3="ss-local start.【$app_97】"

}

check_ssr () {

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
if [ "$ss_run_ss_local" = "1" ] ; then
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
if [ "$ss_run_ss_local" = "1" ] ; then
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
if [ "$ss_run_ss_local" = "1" ] ; then
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
[ "$ss_run_ss_local" = "1" ] && { hash ss-local 2>/dev/null || optssredir="3" ; }
[ ! -z "$ss_plugin_name" ] && { hash $ss_plugin_name 2>/dev/null || optssredir="4" ; }
if [ "$optssredir" != "0" ] ; then
	# 找不到ss-redir，安装opt
	logger -t "【SS】" "找不到 ss-redir 、 ss-local 、 $ss_plugin_name 或 obfs-local ，挂载opt"
	/etc/storage/script/Sh01_mountopt.sh start
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
if [ "$ss_run_ss_local" = "1" ] ; then
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
if [ "$ss_run_ss_local" = "1" ] ; then
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
if [ "$ss_run_ss_local" = "1" ] ; then
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
		wgetcurl_file "/opt/bin/$ss_plugin_name" "$hiboyfile/$ss_plugin_name" "$hiboyfile2/$ss_plugin_name"
		hash $ss_plugin_name 2>/dev/null || optssredir="44"
	fi
	if [ "$optssredir" = "44" ] ; then
		logger -t "【SS】" "找不到 ss_plugin_name :  $ss_plugin_name, 请检查系统"; ss_restart x ;
	fi
fi

umount  /usr/sbin/ss-redir
umount  /usr/sbin/ss-local
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

clean_ss_rules () {
echo "clean_ss_rules"
Sh99_ss_tproxy.sh off_stop "Sh15_ss.sh"
}


gen_include () {
[ -n "$FWI" ] || return 0
[ -n "$FWI" ] && echo '#!/bin/bash' >$FWI
cat <<-CAT >>$FWI
iptables-restore -n <<-EOF
$(iptables-save | sed  "s/webstr--url/webstr --url/g" | grep -E "SSTP|^\*|^COMMIT" |sed -e "s/^-A \(OUTPUT\|PREROUTING\)/-I \1 1/")
EOF
CAT
return $?
}


start_SS () {
check_webui_yes
	logger -t "【SS】" "启动 SS"
	logger -t "【SS】" "ss-redir start.【$app_97】"
	nvram set gfwlist3="ss-redir start.【$app_97】"
	nvram set ss_internet="2"

echo "Debug: $DNS_Server"
	logger -t "【SS】" "###############启动程序###############"
	if [ "$ss_mode_x" = "3" ] ; then
		start_ss_redir
		start_ss_redir_check
		Sh99_ss_tproxy.sh off_stop "Sh15_ss.sh"
		nvram set gfwlist3="ss-local start.【$app_97】"
		logger -t "【ss-local】" "本地代理启动. 可以配合 Proxifier、chrome(switchysharp、SwitchyOmega) 代理插件使用."
		logger -t "【ss-local】" "shadowsocks 进程守护启动"
		ss_get_status "c1"
		nvram set button_script_2_s="SS"
		nvram set ss_internet="1"
		eval "$scriptfilepath sskeep &"
		exit 0
	fi
	start_ss_redir
	start_ss_redir_check
	Sh99_ss_tproxy.sh auser_check "Sh15_ss.sh"
	ss_tproxy_set "Sh15_ss.sh"
	Sh99_ss_tproxy.sh on_start "Sh15_ss.sh"
	#检查网络
	logger -t "【SS】" "SS 检查网络连接"
	check2=404
	check_timeout_network "wget_check" "check"
if [ "$check2" != "200" ] ; then 
	logger -t "【SS】" "错误！【$ss_link_2】连接有问题！！！"
	logger -t "【SS】" "网络连接有问题, 请更新 opt 文件夹、检查 U盘 文件和 SS 设置"
	logger -t "【SS】" "如果是本地组网可忽略此错误！！"
	logger -t "【SS】" "否则需启用【检查 SS 服务器状态：运行时持续检测】才能自动故障转移"
else
	nvram set ss_rebss_b=0
fi
	/etc/storage/script/sh_ezscript.sh 3 & #更新按钮状态
	logger -t "【SS】" "SS 启动成功"
	logger -t "【SS】" "启动后若发现一些网站打不开, 估计是 DNS 被污染了. 解决 DNS 被污染方法："
	logger -t "【SS】" "①路由 SS 设置选择其他 DNS 服务模式；"
	logger -t "【SS】" "②电脑设置 DNS 自动获取路由 ip。检查 hosts 是否有错误规则。"
	logger -t "【SS】" "③电脑运行 cmd 输入【ipconfig /flushdns】, 清理浏览器缓存。"
	logger -t "【SS】" "shadowsocks 进程守护启动"
	nvram set ss_internet="1"
	ss_get_status "c1"
if [ "$ss_dnsproxy_x" = "2" ] ; then
	logger -t "【SS】" "使用 dnsmasq ，开启 ChinaDNS 防止域名污染"
	if [ -f "/etc/storage/script/Sh19_chinadns.sh" ] || [ -s "/etc/storage/script/Sh19_chinadns.sh" ] ; then
		/etc/storage/script/Sh19_chinadns.sh &
	fi
fi

/etc/storage/script/sh_ezscript.sh 3 & #更新按钮状态
eval "$scriptfilepath sskeep &"
exit 0
}

stop_SS () {
sed -Ei '/【SS】|^$/d' /tmp/script/_opt_script_check
kill_ps "$scriptname sskeep"
kill_ps "sh_ezscript.sh"
kill_ps "Sh15_ss.sh"
clean_ss_rules
cru.sh d ss_update &
#ss-rules -f
nvram set ss_internet="0"
killall_ss_redir
killall_ss_local
ss_plugin_client_name="$(nvram get ss_plugin_client_name)"
[ ! -z "$ss_plugin_client_name" ] && { kill_ps "$ss_plugin_client_name" ; ss_plugin_client_name="" ; nvram set ss_plugin_client_name="" ; }
killall pdnsd dnsproxy
killall -9 pdnsd dnsproxy
rm -f /tmp/sh_sskeey_k.sh
[ -f /opt/etc/init.d/S24chinadns ] && { rm -f /var/log/chinadns.lock; /opt/etc/init.d/S24chinadns stop& }
[ -f /opt/etc/init.d/S26pdnsd ] && { rm -f /var/log/pdnsd.lock; /opt/etc/init.d/S26pdnsd stop& }
[ -f /opt/etc/init.d/S27pcap-dnsproxy ] && { rm -f /var/log/pcap-dnsproxy.lock; /opt/etc/init.d/S27pcap-dnsproxy stop& }
nvram set gfwlist3="SS stop."
umount  /usr/sbin/ss-redir
umount  /usr/sbin/ss-local
/etc/storage/script/sh_ezscript.sh 3 & #更新按钮状态
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
	if [ "$ss_matching_enable" == "0" ] ; then
		[ -f $relock ] && rm -f $relock
		logger -t "【SS_restart】" "匹配关键词自动选用节点故障转移 /tmp/link/matching/link_ss_matching.txt"
		eval "$scriptfilepath link_ss_matching &"
		sleep 10
		exit 0
	fi
	if [ -f $relock ] ; then
		logger -t "【ss】" "多次尝试启动失败，等待【"`cat $relock`"分钟】后自动尝试重新启动"
		exit 0
	fi
	ss_renum=${ss_renum:-"0"}
	ss_renum=`expr $ss_renum + 1`
	nvram set ss_renum="$ss_renum"
	if [ "$ss_renum" -gt "3" ] ; then
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
		nvram set ss_renum="1"
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
B_restart="$ss_enable$ss_ip46$chinadns_enable$chinadns_ng_enable$ss_threads$ss_link_1$ss_link_2$ss_rebss_n$ss_rebss_a$lan_ipaddr$ss_DNS_Redirect$ss_DNS_Redirect_IP$ss_type$ss_run_ss_local$ss_s1_local_address$ss_s1_local_port$ss_pdnsd_wo_redir$ss_mode_x$ss_multiport$ss_upd_rules$ss_tochina_enable$ss_udp_enable$LAN_AC_IP$ss_pdnsd_all$kcptun_server$(nvram get wan0_dns |cut -d ' ' -f1)$(cat /etc/storage/shadowsocks_ss_spec_lan.sh /etc/storage/shadowsocks_ss_spec_wan.sh /etc/storage/shadowsocks_mydomain_script.sh | grep -v '^#' | grep -v '^$')"
B_restart=`echo -n "$B_restart" | md5sum | sed s/[[:space:]]//g | sed s/-//g`
cut_B_re
if [ "$A_restart" != "$B_restart" ] ; then
	nvram set ss_status=$B_restart
	needed_restart=1
	[ "$1" != "c1" ] && ss_get_status2
else
	needed_restart=0
	[ "$1" != "c1" ] && ss_get_status2
fi
}

ss_get_status2 () {

A_restart="$(nvram get ss_status2)"
B_restart="$ss_server$ss_server_port$ss_method$ss_key$ss_usage"
B_restart=`echo -n "$B_restart" | md5sum | sed s/[[:space:]]//g | sed s/-//g`
cut_B_re
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

check_setting () {
check_webui_yes
needed_restart=0
ping_ss_link
start_ss_link
json_mk_ss
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
	 ||  { logger -t "【SS】" "SS配置有错误，请到扩展功能检查SS配置页面"; stop_SS; [ "$ss_matching_enable" == "0" ] && eval "$scriptfilepath link_ss_matching &"; sleep 20; exit 1; }
	if [ "$needed_restart" = "2" ] ; then
		logger -t "【SS】" "检测:更换线路配置，进行快速切换服务器。"
		swap_ss_redir
		logger -t "【SS】" "切换服务器完成。"
		eval "$scriptfilepath sskeep &"
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
#随机延时
ss_link_1=`nvram get ss_link_1`
ss_internet=`nvram get ss_internet`
if [ "$ss_internet" = "1" ] ; then
	SEED=`tr -cd 0-9 </dev/urandom | head -c 8`
	RND_NUM=`echo $SEED 50 80|awk '{srand($1);printf "%d",rand()*10000%($3-$2)+$2}'`
	[ "$RND_NUM" -lt 1 ] && RND_NUM="1" || { [ "$RND_NUM" -ge 1 ] || RND_NUM="1" ; }
	sleep $RND_NUM
	sleep $ss_link_1
fi
#/etc/storage/script/sh_ezscript.sh 3 & #更新按钮状态
}


SS_keep () {
gen_include
logger -t "【SS】" "守护进程启动"
/etc/storage/script/sh_ezscript.sh 3 & #更新按钮状态
if [ -s /tmp/script/_opt_script_check ]; then
sed -Ei '/【SS】|^$/d' /tmp/script/_opt_script_check
cat >> "/tmp/script/_opt_script_check" <<-OSC
	NUM=\`grep "Sh15_ss.sh sskeep" /tmp/ps | grep -v grep |wc -l\` # 【SS】
	if [ "\$NUM" -lt "1" ] ; then # 【SS】
	ps -w > /tmp/ps # 【SS】
	NUM=\`grep "sskeep" /tmp/ps | grep -v grep |wc -l\` # 【SS】
	fi # 【SS】
	if [ "\$NUM" -lt "1" ] ; then # 【SS】
		logger -t "【SS】" "重新启动\$NUM" # 【SS】
		nvram set ss_status=00 && eval "$scriptfilepath &" && sed -Ei '/【SS】|^$/d' /tmp/script/_opt_script_check # 【SS】
	fi # 【SS】
OSC
#return
fi
sleep 20
ss_run_ss_local=`nvram get ss_run_ss_local`
ss_mode_x=`nvram get ss_mode_x`
ss_link_2=`nvram get ss_link_2`
ss_link_1=`nvram get ss_link_1`
ss_enable=`nvram get ss_enable`
rebss=`nvram get ss_rebss_b`
[ -z "$rebss" ] && rebss=0 && nvram set ss_rebss_b=0
while [ "$ss_enable" = "1" ];
do
[ "$(grep "</textarea>"  /etc/storage/app_24.sh | wc -l)" != 0 ] && sed -Ei s@\<\/textarea\>@@g /etc/storage/app_24.sh
ss_rebss_n=`nvram get ss_rebss_n`
ss_rebss_a=`nvram get ss_rebss_a`
if [ "$ss_rebss_n" != 0 ] ; then
	if [ "$rebss" -gt "$ss_rebss_n" ] && [ "$ss_rebss_a" == "0" ] ; then
		logger -t "【SS】" " 网络连接 shadowsocks 中断 ['$rebss'], 重启SS."
		if [ "$rebss" != "0" ] ; then
		rebss="0"
		nvram set ss_rebss_b=0
		fi
		nvram set ss_status=0
		eval "$scriptfilepath &"
		sleep 10
		exit 0
	fi
	if [ "$rebss" -gt "$ss_rebss_n" ] && [ "$ss_rebss_a" == "1" ] ; then
		logger -t "【SS】" " 网络连接 shadowsocks 中断 ['$rebss'], 停止SS."
		if [ "$rebss" != "0" ] ; then
		rebss="0"
		nvram set ss_rebss_b=0
		fi
		nvram set ss_enable=0
		eval "$scriptfilepath &"
		sleep 10
		exit 0
	fi
	if [ "$rebss" -gt "$ss_rebss_n" ] && [ "$ss_rebss_a" == "2" ] ; then
		logger -t "【SS】" " 网络连接 shadowsocks 中断['$rebss'], 重启路由."
		if [ "$rebss" != "0" ] ; then
		rebss="0"
		nvram set ss_rebss_b=0
		fi
		sleep 5
		nvram commit
		/sbin/mtd_storage.sh save
		sync;echo 3 > /proc/sys/vm/drop_caches
		/bin/mtd_write -r unlock mtd1 #reboot
	fi
	if [ "$rebss" -gt "$ss_rebss_n" ] && [ "$ss_rebss_a" == "3" ] ; then
		logger -t "【SS】" " 网络连接 shadowsocks 中断['$rebss'], 更新订阅."
		if [ "$rebss" != "0" ] ; then
		rebss="0"
		nvram set ss_rebss_b=0
		fi
		sleep 5
		nvram set ss_link_status=""
		eval "$scriptfilepath uplink &"
	fi
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
		ss_internet="$(nvram get ss_internet)"
		[ "$ss_internet" != "1" ] && nvram set ss_internet="1"
		sleep 20
		#跳出当前循环
		continue
	fi
fi

NUM=`ps -w | grep ss-redir_ | grep -v grep |wc -l`
SSRNUM=1
#[ "$ss_threads" != 0 ] && SSRNUM=`$threads`
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
if [ "$check2" == "404" ] ; then
#404
Sh99_ss_tproxy.sh auser_check "Sh15_ss.sh"
Sh99_ss_tproxy.sh s_ss_tproxy_check "Sh15_ss.sh"
sleep 5
check2=404
check_timeout_network "wget_check" "check"
fi
if [ "$check2" == "200" ] ; then
#200
	echo "[$LOGTIME] SS $app_97 have no problem."
	ss_internet="$(nvram get ss_internet)"
	[ "$ss_internet" != "1" ] && nvram set ss_internet="1"
	if [ "$rebss" != "0" ] ; then
	logger -t "【SS】" " SS 服务器 【$app_97】 恢复正常"
	rebss="0"
	ss_rebss_b="$(nvram get ss_rebss_b)"
	[ "$ss_rebss_b" != "0" ] && nvram set ss_rebss_b=0
	fi
	sleep_rnd
	#跳出当前循环
	continue
fi

#404
ss_internet="$(nvram get ss_internet)"
[ "$ss_internet" != "0" ] && nvram set ss_internet="0"
logger -t "【SS】" " SS 服务器 【$app_97】 检测到问题, $rebss"
[ -z "$rebss" ] && rebss=0
rebss=`expr $rebss + 1`
nvram set ss_rebss_b="$rebss"
#restart_on_dhcpd
#/etc/storage/crontabs_script.sh &

#404
if [ "$ss_matching_enable" == "0" ] ; then
	logger -t "【SS】" " SS 已启用自动故障转移，若检测 3 次断线则更换节点，当值为 $rebss"
if [ "$rebss" -ge "3" ] ; then
	nvram set ss_rebss_b=0
	ss_internet="$(nvram get ss_internet)"
	[ "$ss_internet" != "2" ] && nvram set ss_internet="2"
	logger -t "【SS】" "匹配关键词自动选用节点故障转移 /tmp/link/matching/link_ss_matching.txt"
	eval "$scriptfilepath link_ss_matching &"
	sleep 10
	#跳出当前循环
	continue
fi
fi

done

}

json_mk_ss () {
mkdir -p /tmp/ss
link_tmp="$(nvram get app_75)"
if [ -z "$link_tmp" ] ; then
	return
fi
nvram set app_75=""

# 解码获取信息
link_de_protocol "$link_tmp" "0ss0ssr0"
if [ "$link_protocol" != "ss" ] && [ "$link_protocol" != "ssr" ] ; then
	return 1
fi
nvram set app_97="$link_name"
nvram set app_76="$link_input"
logger -t "【ss】" "应用 $link_protocol 配置： $link_name"
if [ "$link_protocol" == "ss" ] ; then
ss_type=0
fi
if [ "$link_protocol" == "ssr" ] ; then
ss_type=1
fi
nvram set ss_type=$ss_type
ss_server="$ss_link_server"
nvram set ss_server=$ss_server
ss_server_port="$ss_link_port"
nvram set ss_server_port=$ss_server_port
ss_key="$ss_link_password"
nvram set ss_key=$ss_key
ss_method="$ss_link_method"
nvram set ss_method=$ss_method
ssr_type_protocol="$ss_link_protocol"
nvram set ssr_type_protocol=$ssr_type_protocol
ssr_type_obfs="$ss_link_obfs"
nvram set ssr_type_obfs=$ssr_type_obfs
ssr_type_protocol_custom="$ss_link_protoparam"
nvram set ssr_type_protocol_custom=$ssr_type_protocol_custom
ssr_type_obfs_custom="$ss_link_obfsparam"
nvram set ssr_type_obfs_custom=$ssr_type_obfs_custom
ss_plugin_name="$ss_link_plugin"
nvram set ss_plugin_name=$ss_plugin_name
ss_plugin_config="$ss_link_plugin_opts"
nvram set ss_plugin_config=$ss_plugin_config

}

ping_ss_link () {

	ss_x_tmp="`nvram get app_77`"
	if [ "$ss_x_tmp" != "ping_link" ] ; then
		return
	fi
	nvram set app_77=""
	ss_x_tmp=""
	mkdir -p /etc/storage/link
	mkdir -p /tmp/link/matching
	rm -f /tmp/link/matching/link_ss_matching.txt
	rm -f /tmp/link/matching/link_ss_matching_0.txt
	mkdir -p /tmp/link/tmp_ss
	rm -rf /tmp/link/tmp_ss/*
	rm -f /tmp/link/ping_ss.txt
	touch /tmp/link/ping_ss.txt
	rm -f /tmp/link/ping_server_error.txt
	touch /tmp/link/ping_server_error.txt
	i_ping="0"
	while read line
	do
	line="$(echo $line)"
	if [ ! -z "$line" ] && [ -z "$(echo $line | grep '^#')" ] ; then
		i_ping=`expr $i_ping + 1`
		x_ping_x "$i_ping" &
		usleep 100000
	fi
	done < /etc/storage/app_24.sh
	ilox="$(ls -l /tmp/link/tmp_ss/ |wc -l)"
	i_x_ping="1"
	while [ "$i_ping" != "$ilox" ];
	do
	sleep 1
	ilox="$(ls -l /tmp/link/tmp_ss/ |wc -l)"
	i_x_ping=`expr $i_x_ping + 1`
	if [ "$i_x_ping" -gt 300 ] ; then
	logger -t "【ping】" "刷新 ping 失败！超时 300 秒！ 请重新按【ping】按钮再次尝试。"
	break
	fi
	done
	echo -n 'var ping_data = "' >> /tmp/link/ping_ss.txt
	for ilox in /tmp/link/tmp_ss/*
	do
	echo -n "$(cat "$ilox")"  >> /tmp/link/ping_ss.txt
	done
	echo -n '";' >> /tmp/link/ping_ss.txt
	sed -Ei '/^$/d' /tmp/link/ping_ss.txt
	rm -rf /tmp/link/tmp_ss/*
	rm -rf /www/link/ping_ss.js
	cp -f /tmp/link/ping_ss.txt /www/link/ping_ss.js

}

x_ping_x () {
# 解码获取信息
link_read="ping"
link_de_protocol "$line" "0ss0ssr0"
ping_re="$(echo /tmp/link/tmp_ss/$1)"
if [ "$link_protocol" != "ss" ] && [ "$link_protocol" != "ssr" ] ; then
# 返回空数据
touch $ping_re
return
fi
ping_i="$(echo "00000"$1)"
ping_i="${ping_i:0-3}"
if [ ! -z "$(echo "$link_name" | grep -Eo "剩余流量|过期时间")" ] || [ ! -z "$(echo "$link_server" | grep -Eo "剩余流量|过期时间")" ] || [ ! -z "$(echo "$link_server" | grep -Eo "google.com|8.8.8.8")" ] ; then
# 返回空数据
touch $ping_re
return
fi

if [[ "$(tcping -h 2>&1 | wc -l)" -gt 5 ]] ; then
resolveip=`ping -4 -n -q -c1 -w1 -W1 $link_server | head -n1 | sed -r 's/\(|\)/|/g' | awk -F'|' '{print $2}'`
[ -z "$resolveip" ] && resolveip=`ping -6 -n -q -c1 -w1 -W1 $link_server | head -n1 | sed -r 's/\(|\)/|/g' | awk -F'|' '{print $2}'`
if [ ! -z "$resolveip" ] ; then
#ipset -! add proxyaddr $resolveip
#ipset -! add ad_spec_dst_sp $resolveip
tcping_text=`tcping -p $link_port -c 1 $resolveip`
tcping_time=`echo $tcping_text | awk -F '/' '{print $4}'| awk -F '.' '{print $1}'`
[[ "$tcping_time" -gt 10 ]] || tcping_time="0"
[[ "$tcping_time" -lt 10 ]] && tcping_time="0"
fi
fi
[ "$tcping_time" == "0" ] && ping_time="0" ||  ping_time="$tcping_time"
if [ "$ping_time" == "0" ] ; then
if [ ! -z "$(cat /tmp/ping_server_error.txt | grep "error_""$link_server""_error")" ] ; then
ping_time=""
else
ping_time=`ping -4 $link_server -w 3 -W 3 -q | awk -F '/' '{print $4}'| awk -F '.' '{print $1}'`
[ -z "$ping_time" ] && ping_time=`ping -6 $link_server -w 3 -W 3 -q | awk -F '/' '{print $4}'| awk -F '.' '{print $1}'`
fi
fi
ping_time="$(echo $ping_time | tr -d "\ ")"
if [ ! -z "$ping_time" ] ; then
	echo "ping$ping_i：$ping_time ms ✔️ $link_server"
	[ "$tcping_time" == "0" ] && logger -t "【  ping$ping_i】" "$ping_time ms ✔️ $link_server $link_name"
	[ "$tcping_time" != "0" ] && logger -t "【tcping$ping_i】" "$ping_time ms ✔️ $link_server $link_name"
	echo 🔗$link_server"="$ping_time🔗 >> "$ping_re"
else
	echo "ping$ping_i：>1000 ms ❌ $link_server"
	logger -t "【  ping$ping_i】" ">1000 ms ❌ $link_server $link_name"
	echo "error_""$link_server""_error" >> /tmp/ping_server_error.txt
	echo 🔗$link_server"=>"1000🔗 >> "$ping_re"
fi
touch $ping_re
# 排序节点

if [ "$link_protocol" == "ss" ] || [ "$link_protocol" == "ssr" ] ; then
[ -z "$ping_time" ] && ping_time=9999
[ "$ping_time" -gt 9999 ] && ping_time=9999
get_ping="00000""$ping_time"
get_ping_l="$(echo -n $get_ping | wc -c)"
get_ping_a="$(( get_ping_l - 3 ))"
get_ping="$(echo -n "$get_ping" | cut -b "$get_ping_a-$get_ping_l")"
echo $get_ping"$link_name""↪️""$link_input""↩️" >> /tmp/link/matching/link_ss_matching_0.txt
fi

}

start_ss_link () {

ss_x_tmp="`nvram get app_77`"
if [ ! -z "$ss_x_tmp" ] ; then
nvram set app_77=""
fi
if [ "$ss_x_tmp" = "del_link" ] ; then
	# 清空上次订阅节点配置
	rm -f /tmp/link/matching/link_ss_matching.txt
	rm -f /www/link/ss.js
	rm -f /www/link/ss.js
	sed -Ei '/🔗|dellink_ss|^$/d' /etc/storage/app_24.sh
	ss_x_tmp=""
	logger -t "【ss】" "完成清空上次订阅节点配置 请按【F5】刷新 web 查看"
	return
fi
if [ "$ss_x_tmp" = "link_ss_matching" ] ; then
	link_ss_matching
	return
fi

ss_link="`nvram get ssr_link`"
ss_link_up=`nvram get ss_link_up`
ss_link_ping=`nvram get ss_link_ping`
A_restart=`nvram get ss_link_status`
B_restart=`echo -n "$ss_link$ss_link_up" | md5sum | sed s/[[:space:]]//g | sed s/-//g`
cut_B_re
if [ "$A_restart" != "$B_restart" ] ; then
nvram set ss_link_status=$B_restart
	if [ -z "$ss_link" ] ; then
		cru.sh d ss_link_update
		logger -t "【ss】" "停止 ss 服务器订阅"
		return
	else
		if [ "$ss_link_up" != 1 ] ; then
			cru.sh a ss_link_update "15 */6 * * * $scriptfilepath up_link &" &
			logger -t "【ss】" "启动 ss 服务器订阅，添加计划任务 (Crontab)，每6小时更新"
		else
			cru.sh d ss_link_update
		fi
	fi
fi
if [ -z "$ss_link" ] ; then
	return
fi

if [ "$ss_x_tmp" != "up_link" ] ; then
	return
fi

logger -t "【ss】" "服务器订阅：开始更新"

ss_link="$(echo "$ss_link" | tr , \  | sed 's@  @ @g' | sed 's@  @ @g' | sed 's@^ @@g' | sed 's@ $@@g' )"
rm -f /www/link/vmess.js
rm -f /www/link/ss.js
rm -f /tmp/link/matching/link_ss_matching.txt
down_i_link="1"
if [ ! -z "$(echo "$ss_link" | awk -F ' ' '{print $2}')" ] ; then
	for ss_link_i in $ss_link
	do
		down_link "$ss_link_i"
		rm -rf /tmp/link/ss/*
	done
else
	down_link "$ss_link"
	rm -rf /tmp/link/ss/*
fi
logger -t "【ss】" "服务器订阅：更新完成"
if [ "$ss_link_ping" != 1 ] ; then
	nvram set app_77="ping_link"
	ping_ss_link
	app_99="$(nvram get app_99)"
	if [ "$app_99" == 1 ] ; then
		rm -f /tmp/link/matching/link_ss_matching.txt
		link_ss_matching
	fi
else
	echo "【ss】：停止ping订阅节点"
fi

}

down_link () {
http_link="$(echo $1)"
mkdir -p /tmp/link/ss/
rm -f /tmp/link/ss/0_link.txt
if [ ! -z "$(echo "$http_link" | grep '^/')" ] ; then
[ -f "$http_link" ] && cp -f "$http_link" /tmp/link/ss/0_link.txt
[ ! -f "$http_link" ] && logger -t "【SS】" "错误！！ $http_link 文件不存在！"
else
if [ -z  "$(echo "$http_link" | grep 'http:\/\/')""$(echo "$http_link" | grep 'https:\/\/')" ]  ; then
	logger -t "【SS】" "$http_link"
	logger -t "【SS】" "错误！！ss 服务器订阅文件下载地址不含http(s)://！请检查下载地址"
	return
fi
#logger -t "【ss】" "订阅文件下载: $http_link"
wgetcurl.sh /tmp/link/ss/0_link.txt "$http_link" "$http_link" N
if [ ! -s /tmp/link/ss/0_link.txt ] ; then
	rm -f /tmp/link/ss/0_link.txt
	curl -L --user-agent "$user_agent" -o /tmp/link/ss/0_link.txt "$http_link"
fi
if [ ! -s /tmp/link/ss/0_link.txt ] ; then
	rm -f /tmp/link/ss/0_link.txt
	wget -T 5 -t 3 --user-agent "$user_agent" -O /tmp/link/ss/0_link.txt "$http_link"
fi
fi
if [ ! -s /tmp/link/ss/0_link.txt ] ; then
	rm -f /tmp/link/ss/0_link.txt
	logger -t "【ss】" "$http_link"
	logger -t "【ss】" "错误！！ss 服务器订阅文件获取失败！请检查地址"
	return
fi
dos2unix /tmp/link/ss/0_link.txt
sed -e '/^$/d' -i /tmp/link/ss/0_link.txt
if [ ! -z "$(cat /tmp/link/ss/0_link.txt | grep "ssd://")" ] ; then
	logger -t "【ss】" "不支持【ssd://】订阅文件"
	return
fi
http_link_d1="$(cat /tmp/link/ss/0_link.txt | grep "://" | wc -l)"
[ "$http_link_d1" -eq 0 ] && http_link_dd="1" #没找到链接，需要2次解码
if [ "$http_link_d1" -eq 1 ] ; then #找到1个链接，尝试解码
http_link_dd_text="$(cat /tmp/link/ss/0_link.txt  | awk -F '://' '{print $2}')"
if is_2_base64 "$http_link_dd_text" ; then 
http_link_dd_text="$(echo "$http_link_dd_text" | awk -F '#' '{print $1}' | sed -e "s/_/\//g" | sed -e "s/-/\+/g" | sed 's/$/&====/g' | base64 -d)"
# 含多个链接，不需2次解码
http_link_d2="$(echo "$http_link_dd_text" | grep "://" | wc -l)"
[ "$http_link_d2" -eq 0 ] && http_link_dd="0" #没找到链接，不需2次解码
[ "$http_link_d2" -gt 0 ] && http_link_dd="1" #含多个链接，需要2次解码
else
http_link_dd="0" #不是base64，不需2次解码
fi
fi
[ "$http_link_d1" -gt 1 ] && http_link_dd="0" #含多个链接，不需2次解码
if [ "$http_link_dd" == "1" ] ; then
# 需要2次解码
if [ "$(cat /tmp/link/ss/0_link.txt | grep "://" | wc -l)" != "0" ] ; then
cat /tmp/link/ss/0_link.txt | awk -F '://' '{cmd=sprintf("echo -n \"%s\" | sed -e \"s/_/\\//g\" | sed -e \"s/-/\\+/g\" | sed \"s/$/&====/g\" | base64 -d", $2);  system(cmd); print "";}' > /tmp/link/ss/1_link.txt
else
cat /tmp/link/ss/0_link.txt | awk '{cmd=sprintf("echo -n \"%s\" | sed -e \"s/_/\\//g\" | sed -e \"s/-/\\+/g\" | sed \"s/$/&====/g\" | base64 -d", $1);  system(cmd); print "";}' > /tmp/link/ss/1_link.txt
fi
else
# 不需2次解码
mv -f /tmp/link/ss/0_link.txt /tmp/link/ss/1_link.txt
fi
touch /etc/storage/app_24.sh
[ "$down_i_link" == "1" ] && sed -Ei '/^🔗/d' /etc/storage/app_24.sh
down_i_link="2"
sed -Ei '/^$/d' /tmp/link/ss/1_link.txt
sed -Ei 's@^@'🔗'@g' /tmp/link/ss/1_link.txt
sed -Ei s@\<\/textarea\>@@g /tmp/link/ss/1_link.txt
cat /tmp/link/ss/1_link.txt >> /etc/storage/app_24.sh
sed -Ei '/dellink_ss|^$/d' /etc/storage/app_24.sh
sed -Ei s@\<\/textarea\>@@g /etc/storage/app_24.sh
rm -rf /tmp/link/ss/*

}

link_ss_matching () {

# 排序节点
mkdir -p /tmp/link/matching
rm -f /tmp/link/matching/link_ss_matching_1.txt
if [ ! -f /tmp/link/matching/link_ss_matching.txt ] || [ ! -s /tmp/link/matching/link_ss_matching.txt ] ; then
if [ ! -f /tmp/link/matching/link_ss_matching_0.txt ] || [ ! -s /tmp/link/matching/link_ss_matching_0.txt ] ; then
nvram set app_77="ping_link"
ping_ss_link
fi
match="$(nvram get app_95)"
[ -z "$app_95" ] && app_95="." && nvram set app_95="."
[ "$match" == "*" ] && match="."
mismatch="$(nvram get app_96)"
while read line
do
line="$(echo $line)"
if [ ! -z "$line" ] ; then
	[ ! -z "$match" ] && line2="$(echo "$line" | grep -E "$match" | grep -v -E "剩余流量|过期时间")"
	[ ! -z "$mismatch" ] && line2="$(echo "$line2" | grep -v -E "$mismatch" | grep -v -E "剩余流量|过期时间")"
	if [ ! -z "$line2" ] ; then
	echo $line2 >> /tmp/link/matching/link_ss_matching_1.txt
	fi
fi
done < /tmp/link/matching/link_ss_matching_0.txt
if [ -f /tmp/link/matching/link_ss_matching_1.txt ] && [ -s /tmp/link/matching/link_ss_matching_1.txt ] ; then
sed -Ei '/^$/d' /tmp/link/matching/link_ss_matching_1.txt
cat /tmp/link/matching/link_ss_matching_1.txt | sort | grep -v '^$' > /tmp/link/matching/link_ss_matching.txt
rm -f /tmp/link/matching/link_ss_matching_1.txt
logger -t "【自动选用节点】" "重新生成自动选用节点列表： /tmp/link/matching/link_ss_matching.txt"
fi
fi

if [ -f /tmp/link/matching/link_ss_matching.txt ] && [ -s /tmp/link/matching/link_ss_matching.txt ] ; then
# 选用节点
if [ -z "$(cat /tmp/link/matching/link_ss_matching.txt | grep -v 已经自动选用节点)" ] ; then
sed -e 's/已经自动选用节点//g' -i /tmp/link/matching/link_ss_matching.txt
fi
i_matching=1
while read line
do
if [ ! -z "$(echo "$line" | grep -v "已经自动选用节点" )" ] ; then
sed -i $i_matching's/^/已经自动选用节点/' /tmp/link/matching/link_ss_matching.txt
# 选用节点
logger -t "【自动选用节点】" "自动选用节点：""$(echo "$line" | grep -Eo '^[^↪️]+')"
nvram set app_75="$(echo "$line" | grep -Eo "↪️.*[^↩️]" | grep -Eo "[^↪️].*")"
if [ "$ss_enable" == "0" ] ; then
eval "$scriptfilepath json_mk_ss &"
return
else
# 重启ss
eval "$scriptfilepath &"
exit
break
fi
fi
i_matching=`expr $i_matching + 1`
done < /tmp/link/matching/link_ss_matching.txt
else
# 重启ss
eval "$scriptfilepath &"
fi

}

del_LinkList () {
logger -t "【del_LinkList】" "$1"
del_x=$(($1 + 1))
[ -s /etc/storage/app_24.sh ] && sed -i "$del_x""c dellink_ss" /etc/storage/app_24.sh
sed -Ei '/dellink_ss|^$/d' /etc/storage/app_24.sh
}

initopt () {
optPath=`grep ' /opt ' /proc/mounts | grep tmpfs`
[ ! -z "$optPath" ] && return
if [ ! -z "$(echo $scriptfilepath | grep -v "/opt/etc/init")" ] && [ -s "/opt/etc/init.d/rc.func" ] ; then
	{ echo '#!/bin/bash' ; echo $scriptfilepath '"$@"' '&' ; } > /opt/etc/init.d/$scriptname && chmod 777  /opt/etc/init.d/$scriptname
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
#   G: 全局所有端口, 此前缀的目标IP [1:65535] 使用 SS
# 优先级: 绕过 > 全局
# IPv6地址：必须以 ~ 符号开头，如 ~b,2333:2333:2333::
# 网址域名：必须以 @ 符号开头，如 @b,abc.net，匹配 abc.net、*.abc.net
# 注意：修改此文件需重启 ss_tproxy 生效，另外请删除每行首尾多余的空白符
# 注释：以井号开头的行以及空行都视为注释行
# 
# DNS
G,8.8.8.8
G,8.8.4.4
G,208.67.222.222
G,208.67.220.220
# 
# Telegram IPv4
G,91.108.4.0/22
G,91.108.8.0/22
G,91.108.12.0/22
G,91.108.16.0/22
G,91.108.20.0/22
G,91.108.36.0/23
G,91.108.38.0/23
G,91.108.56.0/22
G,149.154.160.0/20
G,149.154.161.0/24
G,149.154.162.0/23
G,149.154.164.0/22
G,149.154.168.0/21
G,149.154.172.0/22
G,149.154.160.0/20
G,149.154.160.1/32
G,149.154.160.2/31
G,149.154.160.4/30
G,149.154.160.8/29
G,149.154.160.16/28
G,149.154.160.32/27
G,149.154.160.64/26
G,149.154.160.128/25
G,149.154.164.0/22
G,91.105.192.0/23
G,91.108.4.0/22
G,91.108.20.0/22
G,91.108.56.0/24
G,109.239.140.0/24
G,67.198.55.0/24
G,91.108.56.172
G,149.154.175.50
G,185.76.151.0/24
# 
# Telegram IPv6
~G,2001:b28:f23d::/48
~G,2001:b28:f23f::/48
~G,2001:67c:4e8::/48
~G,2001:b28:f23c::/48
~G,2a0a:f280::/32
# 
# api
@g,api.telegram.org
@g,raw.githubusercontent.com
@b,api.cloud.189.cn
@b,ddns.oray.com
@b,members.3322.org
@b,members.3322.net
@b,ip.3322.net
@b,www.cloudxns.net
@b,dnsapi.cn
@b,api.dnspod.com
@b,www.ipip.net
@b,myip.ipip.net
@b,alidns.aliyuncs.com
@b,services.googleapis.cn
# 
# 以下样板是四个网段分别对应BLZ的美/欧/韩/台服
#G,24.105.0.0/18
#G,80.239.208.0/20
#G,182.162.0.0/16
#G,210.242.235.0/24

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
sskeep)
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
	[ "$RND_NUM" -lt 1 ] && RND_NUM="1" || { [ "$RND_NUM" -ge 1 ] || RND_NUM="1" ; }
	# echo $RND_NUM
	logger -t "【SS】" "$RND_NUM 秒后进入处理状态, 请稍候"
	sleep $RND_NUM
	nvram set app_111=5
	Sh99_ss_tproxy.sh
	;;
updatess)
	check_webui_yes
	logger -t "【SS】" "手动更新 SS 规则文件 5 秒后进入处理状态, 请稍候"
	sleep 5
	nvram set app_111=5
	Sh99_ss_tproxy.sh
	;;
uplink)
	nvram set app_77="up_link"
	check_setting
	;;
up_link)
	nvram set app_77="up_link"
	check_setting
	;;
del_link)
	nvram set app_77="del_link"
	check_setting
	;;
ping_link)
	nvram set app_77="ping_link"
	check_setting
	;;
link_ss_matching)
	link_ss_matching
	;;
json_mk_ss)
	json_mk_ss
	;;
del_LinkList)
	del_LinkList $2
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
*)
	check_setting
	exit 0
	;;
esac





