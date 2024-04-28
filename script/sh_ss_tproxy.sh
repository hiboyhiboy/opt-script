#!/bin/bash
# hiboy改 原项目地址: https://github.com/zfl9/ss-tproxy
source /etc/storage/script/init.sh
source /etc/storage/app_26.sh
source /etc/storage/app_27.sh

# trap "exit 1" HUP INT QUIT TERM PIPE

# 载入iptables模块
for module in ip_set ip_set_bitmap_ip ip_set_bitmap_ipmac ip_set_bitmap_port ip_set_hash_ip ip_set_hash_ipport ip_set_hash_ipportip ip_set_hash_ipportnet ip_set_hash_net ip_set_hash_netport ip_set_list_set xt_set xt_TPROXY
do
	modprobe $module
done 
if [ ! -d /opt/app/ss_tproxy ] ; then
	logger -t "【clash】" "找不到 /opt/app/ss_tproxy ，安装 opt 程序"
	/etc/storage/script/Sh01_mountopt.sh start
	mkdir -p /opt/app/ss_tproxy
fi

ss_tproxy_config='/etc/storage/app_27.sh'
echo "$dnsmasq_conf_dir
/opt/app/ss_tproxy/tmp
/opt/app/ss_tproxy/conf
/opt/app/ss_tproxy/rule
/opt/app/ss_tproxy/dnsmasq.d
/tmp/ss_tproxy/dnsmasq.d" | while read dir_name; do [ ! -z "$dir_name" ] && [ ! -d "$dir_name" ] && mkdir -p $dir_name ; done 
echo "$dnsmasq_conf_file
$proxy_all_svraddr
$proxy_svraddr4
$proxy_svraddr6
$dnsmasq_conf_string
$file_gfwlist_txt
$file_gfwlist_ext
$file_ignlist_ext
$file_lanlist_ext
$file_wanlist_ext
$file_chnroute_txt
$file_chnroute6_txt
$file_chnroute_set
$file_chnroute6_set" | while read file_name; do [ ! -z "$file_name" ] && [ ! -f "$file_name" ] && touch $file_name ; done

if [ -n "$LAN_AC_IP" ] ; then
	case "${LAN_AC_IP:0:1}" in
		0)
			LAN_TARGET="SSTP_WAN_AC"
			;;
		1)
			LAN_TARGET="SSTP_WAN_FW"
			;;
		2)
			LAN_TARGET="SSTP_WAN_AC"
			#LAN_TARGET="RETURN"
			;;
	esac
fi

IPV4_RESERVED_IPADDRS="
0.0.0.0/8
10.0.0.0/8
100.64.0.0/10
127.0.0.0/8
169.254.0.0/16
172.16.0.0/12
192.0.0.0/24
192.0.2.0/24
192.88.99.0/24
192.168.0.0/16
198.18.0.0/15
198.51.100.0/24
203.0.113.0/24
224.0.0.0/4
240.0.0.0/4
255.255.255.255/32
100.100.100.100/32
188.188.188.188/32
110.110.110.110/32
"

IPV6_RESERVED_IPADDRS="
::/128
::1/128
::ffff:0:0/96
::ffff:0:0:0/96
64:ff9b::/96
100::/64
2001::/32
2001:20::/28
2001:db8::/32
2002::/16
fc00::/7
fe80::/10
ff00::/8
"

font_bold() {
	printf "\e[1m$*\e[0m"
}

color_red() {
	printf "\e[35m$*\e[0m"
}

color_green() {
	printf "\e[32m$*\e[0m"
}

color_yellow() {
	printf "\e[31m$*\e[0m"
}

log_error() {
	logger -t "【sh_ss_tproxy.sh】" "【错误】""$*"
	logger -t "【sh_ss_tproxy.sh】" "【错误】""出错了？试试手动重置 ss_tproxy 数据"
	echo "$(font_bold $(color_yellow '[ERROR]')) $*" 1>&2
	stop
	exit 1
}

is_true() {
	[ "$1" = 'true' ]
}

is_false() {
	[ "$1" = 'false' ]
}

file_is_exists() {
	[ -f "$1" ]
}

command_is_exists() {
	#command -v "$1" &>/dev/null
	hash "$1" 2>/dev/null
}

process_is_running() {
	kill -0 "$1" &>/dev/null
}

tcp_port_is_exists() {
	[ $($netstat -lnpt | grep -E ":$1[ \t]" | wc -l) -ne 0 ]
}

udp_port_is_exists() {
	[ $($netstat -anpu | grep -E ":$1[ \t]" | wc -l) -ne 0 ]
}

ss_tproxy_is_started() {
#    process_is_running "$status_dnsmasq_pid"  ||
#	process_is_running "$status_chinadns_pid" ||
#	process_is_running "$status_dns2tcp4_pid" ||
#	process_is_running "$status_dns2tcp6_pid" ||
	iptables  -t mangle -nL SSTP_OUTPUT &>/dev/null ||
	iptables  -t nat    -nL SSTP_OUTPUT &>/dev/null ||
	ip6tables -t mangle -nL SSTP_OUTPUT &>/dev/null ||
	ip6tables -t nat    -nL SSTP_OUTPUT &>/dev/null ||
	[ $(ip -4 route show table $ipts_rt_tab 2>/dev/null | wc -l) -ne 0 ] ||
	[ $(ip -6 route show table $ipts_rt_tab 2>/dev/null | wc -l) -ne 0 ] ||
	[ $(ip -4 rule 2>/dev/null | grep -c "fwmark $ipts_rt_mark") -ne 0 ] ||
	[ $(ip -6 rule 2>/dev/null | grep -c "fwmark $ipts_rt_mark") -ne 0 ]
}

is_ipv4_ipts() {
	[ "$1" = 'iptables' ]
}

is_ipv6_ipts() {
	[ "$1" = 'ip6tables' ]
}

is_global_mode() {
	[ "$mode" = 'global' ]
}

is_chnlist_mode() {
	[ "$mode" = 'chnlist' ]
}

is_gfwlist_mode() {
	[ "$mode" = 'gfwlist' ]
}

is_chnroute_mode() {
	[ "$mode" = 'chnroute' ]
}

is_enabled_udp() {
	is_false "$tcponly"
}

is_need_iproute() {
	is_true "$tproxy" || is_enabled_udp
}

is_usrgrp_mode() {
    [ "$uid_owner" != "0" ] || [ "$gid_owner" != "0" ]
}

get_usrgrp_args() {
    if [ "$uid_owner" != "0" ] && [ "$gid_owner" != "0" ] ; then
        echo "--uid-owner $uid_owner --gid-owner $gid_owner"
    elif [ "$uid_owner" != "0" ] ; then
        echo "--uid-owner $uid_owner"
    elif [ "$gid_owner" != "0" ] ; then
        echo "--gid-owner $gid_owner"
    fi
}

is_nonstd_dnsport() {
	[ "$1" != '53' ]
}

is_empty_iptschain() {
	ipts="$1" ; table="$2" ; chain="$3"
	[ $($ipts -t $table -nvL $chain --line-numbers | grep -Ec '^[0-9]') -eq 0 ]
}

is_ipv4_address() {
	[ $(echo "$1" | grep -Ec '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$') -ne 0 ]
}

is_ipv6_address() {
	[ $(echo "$1" | grep -c ':') -ne 0 ]
}

is_domain_name() {
	! is_ipv4_address "$1" && ! is_ipv6_address "$1"
}

is_md5_ok() {
	[ "$md5_check" == "OK" ]
}

is_md5_not() {
	[ "$md5_check" == "NOT" ]
}

set_sysctl_option() {
	option_name="$1" ; option_value="$2"
	if command_is_exists "sysctl"; then
		sysctl -w "$option_name=$option_value" >/dev/null
	else
		option_path="/proc/sys/${option_name//.//}"
		echo "$option_value" >$option_path
	fi
}

resolve_hostname_by_hosts() {
	cat /etc/hosts /etc/storage/dnsmasq/hosts | sed 's/#.*//g' | grep -v '^$' | grep -F "$1" | head -n1 | awk '{print $1}'
}

resolve_hostname_by_doh() {
	addr_family="$1" ; hostname="$2"
	ipaddr=$(resolve_hostname_by_hosts "$hostname")
	if [ "$ipaddr" ] ; then
		if [ "$addr_family" = '-4' ] ; then
			ipaddr=$(echo "$ipaddr" | grep -v ":" | head -n1)
			is_ipv4_address "$ipaddr" && echo "$ipaddr"
			return
		fi
		if [ "$addr_family" = '-6' ] ; then
			ipaddr=$(echo "$ipaddr" | grep ':' | head -n1)
			is_ipv6_address "$ipaddr" && echo "$ipaddr"
			return
		fi
	fi
	[ "$addr_family" = '-4' ] && arNslookup "$hostname" || arNslookup6 "$hostname"
}

resolve_hostname_by_dig() {
	addr_family="$1" ; hostname="$2"
	ipaddr=$(resolve_hostname_by_hosts "$hostname")
	if [ "$ipaddr" ] ; then
		if [ "$addr_family" = '-4' ] && is_ipv4_address "$ipaddr"; then
			echo "$ipaddr"
			return
		fi
		if [ "$addr_family" = '-6' ] && is_ipv6_address "$ipaddr"; then
			echo "$ipaddr"
			return
		fi
	fi
	[ "$addr_family" = '-4' ] && dns_qtype='A' || dns_qtype='AAAA'
	dig +short "$dns_qtype" "$hostname" | grep -Ev '^;|\.$' | head -n1
}

resolve_hostname_by_getent() {
	addr_family="$1" ; hostname="$2"
	[ "$addr_family" = '-4' ] && db_name='ahostsv4' || db_name='ahostsv6'
	getent "$db_name" "$hostname" | head -n1 | awk '{print $1}'
}

resolve_hostname_by_ping() {
	addr_family="$1" ; hostname="$2"
	[ "$addr_family" = '-4' ] && ping_cmd="$ping4" || ping_cmd="$ping6"
	$ping_cmd -nq -c1 -w1 -W1 "$hostname" | head -n1 | sed -r 's/\(|\)/|/g' | awk -F'|' '{print $2}'
}

resolve_hostname4() {
	ipaddr=""
	i_timeout=1
	while [ -z "$ipaddr" ]; do
		ipaddr=$($resolver_func -4 "$1")
		[ -z "$ipaddr" ] && usleep 300000
		i_timeout=`expr $i_timeout + 1`
		if [ "$i_timeout" -gt 2 ] ; then
			break
		fi
	done
	is_ipv4_address "$ipaddr" && echo "$ipaddr"
}

resolve_hostname6() {
	ipaddr=""
	i_timeout=1
	while [ -z "$ipaddr" ]; do
		ipaddr=$($resolver_func -6 "$1")
		[ -z "$ipaddr" ] && usleep 300000
		i_timeout=`expr $i_timeout + 1`
		if [ "$i_timeout" -gt 2 ] ; then
			break
		fi
	done
	is_ipv6_address "$ipaddr" && echo "$ipaddr"
}

resolve_svraddr() {
	update_dnsmasq_file
	if [ "$uid_owner" == "0" ] && [ "$gid_owner" == "0" ] ; then
	
	while read svraddr; do
		[ -z "$svraddr" ] && continue
		[ ! -z "$(echo $svraddr | grep 8.8.8.8)$(echo $svraddr | grep 114.114.114.114)$(echo $svraddr | grep 119.29.29.29)$(echo $svraddr | grep 223.5.5.5)" ] && continue
		[ ! -z "$(cat $file_wanlist_ext | grep -E "^@g" | cut -c4- | grep "$svraddr")" ] && continue
		if is_true "$ipv4"; then
			is_ipv6_address "$svraddr" && continue
			is_ipv4_address "$svraddr" && svrip_all="$svraddr" || svrip_all=$(resolve_hostname4 "$svraddr")
			is_ipv4_address "$svrip_all" && [ -z "$(grep $svrip_all $proxy_svraddr4)" ] && echo "$svrip_all" >> $proxy_svraddr4
		fi
		
		if is_true "$ipv6"; then
			is_ipv4_address "$svraddr" && continue
			is_ipv6_address "$svraddr" && svrip_all="$svraddr" || svrip_all=$(resolve_hostname6 "$svraddr")
			is_ipv6_address "$svrip_all" && [ -z "$(grep $svrip_all $proxy_svraddr6)" ] && echo "$svrip_all" >> $proxy_svraddr6
		fi
	done < $proxy_all_svraddr
	fi

#ipset destroy $setname &>/dev/null
ipset flush proxyaddr &>/dev/null
ipset flush proxyaddr6 &>/dev/null
ipset flush localaddr &>/dev/null
ipset flush localaddr6 &>/dev/null
ipset flush privaddr &>/dev/null
ipset flush privaddr6 &>/dev/null

echo "create proxyaddr hash:net hashsize 64 family inet
create proxyaddr6 hash:net hashsize 64 family inet6
create chnroute hash:net hashsize 1024 family inet
create chnroute6 hash:net hashsize 1024 family inet6
create gfwlist hash:net hashsize 1024 family inet
create gfwlist6 hash:net hashsize 1024 family inet6
create adbybylist hash:net hashsize 1024 family inet
create localaddr hash:net hashsize 64 family inet
create localaddr6 hash:net hashsize 64 family inet6
create privaddr hash:net hashsize 64 family inet
create privaddr6 hash:net hashsize 64 family inet6
create sstp_dst_bp hash:net hashsize 64 family inet
create sstp_dst_bp6 hash:net hashsize 64 family inet6
create sstp_dst_fw hash:net hashsize 64 family inet
create sstp_dst_fw6 hash:net hashsize 64 family inet6
create sstp_dst_dns_fw hash:net hashsize 64 family inet
create sstp_dst_dns_fw6 hash:net hashsize 64 family inet6
create sstp_src_ac hash:net hashsize 64 family inet
create sstp_src_ac6 hash:net hashsize 64 family inet6
create sstp_src_bp hash:net hashsize 64 family inet
create sstp_src_bp6 hash:net hashsize 64 family inet6
create sstp_src_fw hash:net hashsize 64 family inet
create sstp_src_fw6 hash:net hashsize 64 family inet6
create sstp_src_gfw hash:net hashsize 64 family inet
create sstp_src_gfw6 hash:net hashsize 64 family inet6
create sstp_src_chn hash:net hashsize 64 family inet
create sstp_src_chn6 hash:net hashsize 64 family inet6
create sstp_mac_ac hash:mac hashsize 64
create sstp_mac_bp hash:mac hashsize 64
create sstp_mac_fw hash:mac hashsize 64
create sstp_mac_gfw hash:mac hashsize 64
create sstp_mac_chn hash:mac hashsize 64" | while read sstp_name; do ipset -! $sstp_name ; done 

	ipset flush proxyaddr &>/dev/null
	ipset flush proxyaddr6 &>/dev/null
	proxy_svripv4="$(cat $proxy_svraddr4)"
	[ ! -z "$proxy_svripv4" ] && { for svr_ip in $proxy_svripv4; do echo "-A proxyaddr $svr_ip"; done | ipset -! restore &>/dev/null ; }
	proxy_svripv6="$(cat $proxy_svraddr6)"
	[ ! -z "$proxy_svripv6" ] && { for svr_ip in $proxy_svripv6; do echo "-A proxyaddr6 $svr_ip"; done | ipset -! restore &>/dev/null ; }
	ipset flush localaddr &>/dev/null
	ipset flush localaddr6 &>/dev/null
	ifconfig -a | grep inet | grep -v inet6 | awk '{print $2}' | tr -d "addr:" | while read ip_addr; do echo "-A localaddr $ip_addr"; done | ipset -! restore &>/dev/null
	ifconfig -a | grep inet6 | awk '{print $3}' | while read ip_addr; do echo "-A localaddr6 $ip_addr"; done | ipset -! restore &>/dev/null
	ipset flush privaddr &>/dev/null
	ipset flush privaddr6 &>/dev/null
	for priv_ip in $IPV4_RESERVED_IPADDRS; do echo "-A privaddr $priv_ip"; done | ipset -! restore &>/dev/null
	cat $file_ignlist_ext | grep -E "^-" | cut -c2- | while read ip_addr; do echo "-A privaddr $ip_addr"; done | ipset -! restore &>/dev/null
	for priv_ip in $IPV6_RESERVED_IPADDRS; do echo "-A privaddr6 $priv_ip"; done | ipset -! restore &>/dev/null
	cat $file_ignlist_ext | grep -E "^~" | cut -c2- | while read ip_addr; do echo "-A privaddr6 $ip_addr"; done | ipset -! restore &>/dev/null


}

waiting_network() {
	[ -z "$1" ] && return
	is_ipv4_address "$1" && ping_cmd="$ping4" || ping_cmd="$ping6"
	until $ping_cmd -nq -c1 -W1 "$1" >/dev/null; do
		echo "waiting for network available..."
		sleep 1
	done
}

load_pidfile() {
	source "$file_dnsserver_pid" || log_error "load pidfile failed, exit-code: $?"
}

update_pidfile() {
echo "update_pidfile"
#	echo "status_dnsmasq_pid=$status_dnsmasq_pid"    >$file_dnsserver_pid
#	echo "status_chinadns_pid=$status_chinadns_pid"  >$file_dnsserver_pid
#	echo "status_dns2tcp4_pid=$status_dns2tcp4_pid" >>$file_dnsserver_pid
#	echo "status_dns2tcp6_pid=$status_dns2tcp6_pid" >>$file_dnsserver_pid
}

delete_pidfile() {
	rm -f $file_dnsserver_pid &>/dev/null
}

load_config() {
	if ! file_is_exists "$ss_tproxy_config"; then
		log_error "file not found: $ss_tproxy_config"
	else
		source "$ss_tproxy_config" $arguments || log_error "load config failed, exit-code: $?"
	fi

	for optentry in $optentries; do eval "$optentry"; done

	[ -z "$uid_owner" ] && uid_owner="0"
	[ -z "$gid_owner" ] && gid_owner="0"

	# MODE_TARGET
	if is_global_mode; then
		MODE_TARGET="SSTP_WAN_FW"
	fi
	if is_chnroute_mode; then
		MODE_TARGET="SSTP_WAN_CHN"
		GFWLIST_TARGET="SSTP_WAN_FW"
		CHN_TARGET="RETURN"
		CHN_WAN_TARGET="SSTP_WAN_FW"
	fi
	if is_gfwlist_mode; then
		MODE_TARGET="SSTP_WAN_GFW"
		GFWLIST_TARGET="SSTP_WAN_FW"
		CHN_TARGET="RETURN"
		CHN_WAN_TARGET="SSTP_WAN_FW"
	fi
	if is_chnlist_mode; then
		MODE_TARGET="SSTP_GFW_CHN"
		GFWLIST_TARGET="SSTP_WAN_FW"
		CHN_TARGET="SSTP_WAN_FW"
		CHN_WAN_TARGET="RETURN"
	fi

	# update_wanlanlist_ipset 规则处理标签
	if is_true "$ipv4" && is_true "$ipv6"; then
		gfwlist_ipset_setname="gfwlist,gfwlist6"
		sstp_dst_fw_ipset_setname="sstp_dst_fw,sstp_dst_fw6"
		sstp_dst_dns_fw_ipset_setname="sstp_dst_dns_fw,sstp_dst_dns_fw6"
		sstp_dst_bp_ipset_setname="sstp_dst_bp,sstp_dst_bp6"
	elif is_true "$ipv4"; then
		gfwlist_ipset_setname="gfwlist"
		sstp_dst_fw_ipset_setname="sstp_dst_fw"
		sstp_dst_dns_fw_ipset_setname="sstp_dst_dns_fw"
		sstp_dst_bp_ipset_setname="sstp_dst_bp"
	else
		gfwlist_ipset_setname="gfwlist6"
		sstp_dst_fw_ipset_setname="sstp_dst_fw6"
		sstp_dst_dns_fw_ipset_setname="sstp_dst_dns_fw6"
		sstp_dst_bp_ipset_setname="sstp_dst_bp6"
	fi
	if is_chnlist_mode; then # 回国模式 反转 wanlist 规则， china DNS 需要走代理
		dst_fw_ipset_type="$sstp_dst_bp_ipset_setname"
		dst_dns_fw_ipset_type="$sstp_dst_bp_ipset_setname"
		dst_bp_ipset_type="$sstp_dst_fw_ipset_setname"
		dst4_fw_type="sstp_dst_bp"
		dst6_fw_type="sstp_dst_bp6"
		dst4_dns_fw_type="sstp_dst_bp"
		dst6_dns_fw_type="sstp_dst_bp6"
		dst4_bp_type="sstp_dst_fw"
		dst6_bp_type="sstp_dst_fw6"
		dns4_fw_type="$dns_direct"
		dns6_fw_type="$dns_direct6"
		dns4_bp_type="$dns_remote"
		dns6_bp_type="$dns_remote6"
		chinadns_ng_trust_dns4="$dns_direct"
		chinadns_ng_trust_dns6="$dns_direct6"
		chinadns_ng_china_dns4="$dns_remote"
		chinadns_ng_china_dns6="$dns_remote6"
	else # 正常走代理模式
		dst_fw_ipset_type="$sstp_dst_fw_ipset_setname"
		dst_dns_fw_ipset_type="$sstp_dst_dns_fw_ipset_setname"
		dst_bp_ipset_type="$sstp_dst_bp_ipset_setname"
		dst4_fw_type="sstp_dst_fw"
		dst6_fw_type="sstp_dst_fw6"
		dst4_dns_fw_type="sstp_dst_dns_fw"
		dst6_dns_fw_type="sstp_dst_dns_fw6"
		dst4_bp_type="sstp_dst_bp"
		dst6_bp_type="sstp_dst_bp6"
		dns4_fw_type="127.0.0.1#8053"
		dns6_fw_type="$dns_remote6"
		dns4_bp_type="$dns_direct"
		dns6_bp_type="$dns_direct6"
		chinadns_ng_trust_dns4="$dns_remote"
		chinadns_ng_trust_dns6="$dns_remote6"
		chinadns_ng_china_dns4="$dns_direct"
		chinadns_ng_china_dns6="$dns_direct6"
	fi

	#dns
	wan_dnsenable_x="$(nvram get wan_dnsenable_x)"
	[ "$wan_dnsenable_x" == "1" ] && DNS_china=`nvram get wan0_dns |cut -d ' ' -f1`
	[ "$wan_dnsenable_x" != "1" ] && DNS_china=`nvram get wan_dns1_x |cut -d ' ' -f1`
	[ -z "$DNS_china" ] && DNS_china="$dns_direct"

	chinadns_ng_8953="`nvram get app_1`"
	[ -z $chinadns_ng_8953 ] && chinadns_ng_8953=0 && nvram set app_1=0
	chinadns_ng_enable=`nvram get app_102`
	[ -z $chinadns_ng_enable ] && chinadns_ng_enable=0 && nvram set app_102=0
	chinadns_port=`nvram get app_6`
	[ -z $chinadns_port ] && chinadns_port=8053 && nvram set app_6=8053
	if [ "$chinadns_port" != "8053" ] && [ "$chinadns_ng_enable" = "3" ] ; then
	chinadns_ng_enable=2
	fi
	smartdns_enable="`nvram get app_106`"
	[ -z $smartdns_enable ] && smartdns_enable=0 && nvram set app_106=0

	# ss_tproxy 配置文件的配置参数覆盖 web 的配置参数
	dns_start_dnsproxy=`nvram get app_112`
	[ -z $dns_start_dnsproxy ] && dns_start_dnsproxy=0 && nvram set app_112=0
	[ ! -z "$ext_dns_start_dnsproxy" ] && dns_start_dnsproxy="$ext_dns_start_dnsproxy"
	
	ss_dnsproxy_x=`nvram get ss_dnsproxy_x`
	[ -z $ss_dnsproxy_x ] && ss_dnsproxy_x=0 && nvram set ss_dnsproxy_x=0
	[ ! -z "$ext_ss_dnsproxy_x" ] && ss_dnsproxy_x="$ext_ss_dnsproxy_x"
	
	ss_pdnsd_all=`nvram get ss_pdnsd_all`
	[ -z $ss_pdnsd_all ] && ss_pdnsd_all=0 && nvram set ss_pdnsd_all=0
	[ ! -z "$ext_ss_pdnsd_all" ] && ss_pdnsd_all="$ext_ss_pdnsd_all"
	
	ss_pdnsd_cn_all=`nvram get app_113`
	[ -z $ss_pdnsd_cn_all ] && ss_pdnsd_cn_all=0 && nvram set app_113=0
	[ ! -z "$ext_ss_pdnsd_cn_all" ] && ss_pdnsd_cn_all="$ext_ss_pdnsd_cn_all"
	
	output_return=`nvram get app_114`
	[ -z $output_return ] && output_return=0 && nvram set app_114=0
	[ ! -z "$ext_output_return" ] && output_return="$ext_output_return"
	
	output_udp_return=`nvram get ss_udp_enable`
	[ -z $output_udp_return ] && output_udp_return=0 && nvram set ss_udp_enable=0
	[ ! -z "$ext_output_udp_return" ] && output_udp_return="$ext_output_udp_return"
	
	ss_all_udp=`nvram get app_81`
	[ -z $ss_all_udp ] && ss_all_udp=0 && nvram set app_81=0
	[ ! -z "$ext_ss_all_udp" ] && ss_all_udp="$ext_ss_all_udp"
}

check_config() {
	file_is_exists "$file_gfwlist_txt"   || log_error "file not found: $file_gfwlist_txt"
	file_is_exists "$file_gfwlist_ext"   || log_error "file not found: $file_gfwlist_ext"
	file_is_exists "$file_ignlist_ext"   || log_error "file not found: $file_ignlist_ext"
	file_is_exists "$file_chnroute_set"  || log_error "file not found: $file_chnroute_set"
	file_is_exists "$file_chnroute6_set" || log_error "file not found: $file_chnroute6_set"
	#file_is_exists "$file_dnsserver_pid" && load_pidfile

	{ ! is_global_mode && ! is_gfwlist_mode && ! is_chnroute_mode && ! is_chnlist_mode; } && log_error "the value of the mode option is invalid: $mode"

	{ is_false "$ipv4" && is_false "$ipv6"; } && log_error "both ipv4 and ipv6 are disabled, nothing to do"

	[ -z "$proxy_svrport" ] && log_error "the value of the proxy_svrport option is empty: $proxy_svrport"
	#if [ "$uid_owner" == "0" ] && [ "$gid_owner" == "0" ] ; then
		#[ -z "$(cat $proxy_svraddr4)" ] && [ -z "$(cat $proxy_svraddr6)" ] && log_error "both proxy_svraddr4 and proxy_svraddr6 are empty"
	#fi

	command_is_exists 'ipset'   || log_error "command not found: ipset"
	command_is_exists 'dnsmasq' || log_error "command not found: dnsmasq"
	is_need_iproute && { command_is_exists 'ip' || log_error "command not found: ip"; }
	is_true "$ipv4" && { command_is_exists 'iptables'  || log_error "command not found: iptables";  }
	is_true "$ipv6" && { command_is_exists 'ip6tables' || log_error "command not found: ip6tables"; }
#	is_chnroute_mode && { command_is_exists 'chinadns_ng' || log_error "command not found: chinadns_ng"; }
#	! is_enabled_udp && { command_is_exists "dns2tcp" || log_error "command not found: dns2tcp"; }

	case "$opts_ss_netstat" in
		auto)
			if command_is_exists 'ss'; then
				netstat='ss'
			elif command_is_exists 'netstat'; then
				netstat='netstat'
			else
				log_error "command not found: ss/netstat"
			fi
			;;
		ss)
			command_is_exists 'ss' && netstat='ss' || log_error "command not found: ss"
			;;
		netstat)
			command_is_exists 'netstat' && netstat='netstat' || log_error "command not found: netstat"
			;;
		*)
			log_error "the value of the opts_ss_netstat option is invalid: $opts_ss_netstat"
			;;
	esac

	case "$opts_ping_cmd_to_use" in
		auto)
			if command_is_exists 'ping' && command_is_exists 'ping6'; then
				ping4='ping'; ping6='ping6'
			elif command_is_exists 'ping'; then
				ping4='ping -4'; ping6='ping -6'
			else
				log_error "command not found: ping/ping6"
			fi
			;;
		standalone)
			{ command_is_exists 'ping' && command_is_exists 'ping6'; } && { ping4='ping'; ping6='ping6'; } || log_error "command not found: ping/ping6"
			;;
		parameter)
			command_is_exists 'ping' && { ping4='ping -4'; ping6='ping -6'; } || log_error "command not found: ping"
			;;
		*)
			log_error "the value of the opts_ping_cmd_to_use option is invalid: $opts_ping_cmd_to_use"
			;;
	esac

	case "$opts_hostname_resolver" in
		auto)
			if command_is_exists 'nslookup' || command_is_exists 'wget' || command_is_exists 'curl' ; then
				resolver_func='resolve_hostname_by_doh'
			elif command_is_exists 'dig'; then
				resolver_func='resolve_hostname_by_dig'
			elif command_is_exists 'getent'; then
				resolver_func='resolve_hostname_by_getent'
			elif command_is_exists 'ping'; then
				resolver_func='resolve_hostname_by_ping'
			else
				log_error "command not found: nslookup/wget/curl/dig/getent/ping"
			fi
			;;
		doh)
			if command_is_exists 'nslookup' || command_is_exists 'wget' || command_is_exists 'curl' ; then
				resolver_func='resolve_hostname_by_doh'
			else
				log_error "command not found: nslookup/wget/curl"
			fi
			;;
		dig)
			command_is_exists 'dig' && resolver_func='resolve_hostname_by_dig' || log_error "command not found: dig"
			;;
		getent)
			command_is_exists 'getent' && resolver_func='resolve_hostname_by_getent' || log_error "command not found: getent"
			;;
		ping)
			command_is_exists 'ping' && resolver_func='resolve_hostname_by_ping' || log_error "command not found: ping"
			;;
		*)
			log_error "the value of the opts_hostname_resolver option is invalid: $opts_hostname_resolver"
			;;
	esac
}

gfwlist_txt_append_domain_names() {
	printf "cn2qq.com\ngithub.io\ngithub.com\nrawgit.com\nrawgithub.com\ngithubusercontent.com\ngoogleapis.cn\ngoogleapis.com\n"
	printf "twimg.edgesuite.net\nv2fly.org\nv2ray.com\n"
	printf "blogspot.ae\nblogspot.al\nblogspot.am\nblogspot.ba\nblogspot.be\nblogspot.bg\nblogspot.bj\nblogspot.ca\nblogspot.cat\nblogspot.cf\nblogspot.ch\nblogspot.cl\nblogspot.co.at\nblogspot.co.id\nblogspot.co.il\nblogspot.co.ke\nblogspot.com\nblogspot.com.ar\nblogspot.com.au\nblogspot.com.br\nblogspot.com.by\nblogspot.com.co\nblogspot.com.cy\nblogspot.com.ee\nblogspot.com.eg\nblogspot.com.es\nblogspot.com.mt\nblogspot.com.ng\nblogspot.com.tr\nblogspot.com.uy\nblogspot.co.nz\nblogspot.co.uk\nblogspot.co.za\nblogspot.cv\nblogspot.cz\nblogspot.de\nblogspot.dk\nblogspot.fi\nblogspot.fr\nblogspot.gr\nblogspot.hk\nblogspot.hr\nblogspot.hu\nblogspot.ie\nblogspot.in\nblogspot.is\nblogspot.it\nblogspot.jp\nblogspot.kr\nblogspot.li\nblogspot.lt\nblogspot.lu\nblogspot.md\nblogspot.mk\nblogspot.mr\nblogspot.mx\nblogspot.my\nblogspot.nl\nblogspot.no\nblogspot.pe\nblogspot.pt\nblogspot.qa\nblogspot.re\nblogspot.ro\nblogspot.rs\nblogspot.ru\nblogspot.se\nblogspot.sg\nblogspot.si\nblogspot.sk\nblogspot.sn\nblogspot.td\nblogspot.tw\nblogspot.ug\nblogspot.vn\n"
	printf "google.ac\ngoogle.ad\ngoogle.ae\ngoogle.al\ngoogle.am\ngoogle.as\ngoogle.at\ngoogle.az\ngoogle.ba\ngoogle.be\ngoogle.bf\ngoogle.bg\ngoogle.bi\ngoogle.bj\ngoogle.bs\ngoogle.bt\ngoogle.by\ngoogle.ca\ngoogle.cat\ngoogle.cc\ngoogle.cd\ngoogle.cf\ngoogle.cg\ngoogle.ch\ngoogle.ci\ngoogle.cl\ngoogle.cm\ngoogle.cn\ngoogle.co.ao\ngoogle.co.bw\ngoogle.co.ck\ngoogle.co.cr\ngoogle.co.id\ngoogle.co.il\ngoogle.co.in\ngoogle.co.jp\ngoogle.co.ke\ngoogle.co.kr\ngoogle.co.ls\ngoogle.com\ngoogle.co.ma\ngoogle.com.af\ngoogle.com.ag\ngoogle.com.ai\ngoogle.com.ar\ngoogle.com.au\ngoogle.com.bd\ngoogle.com.bh\ngoogle.com.bn\ngoogle.com.bo\ngoogle.com.br\ngoogle.com.bz\ngoogle.com.co\ngoogle.com.cu\ngoogle.com.cy\ngoogle.com.do\ngoogle.com.ec\ngoogle.com.eg\ngoogle.com.et\ngoogle.com.fj\ngoogle.com.gh\ngoogle.com.gi\ngoogle.com.gt\ngoogle.com.hk\ngoogle.com.jm\ngoogle.com.kh\ngoogle.com.kw\ngoogle.com.lb\ngoogle.com.lc\ngoogle.com.ly\ngoogle.com.mm\ngoogle.com.mt\ngoogle.com.mx\ngoogle.com.my\ngoogle.com.na\ngoogle.com.nf\ngoogle.com.ng\ngoogle.com.ni\ngoogle.com.np\ngoogle.com.om\ngoogle.com.pa\ngoogle.com.pe\ngoogle.com.pg\ngoogle.com.ph\ngoogle.com.pk\ngoogle.com.pr\ngoogle.com.py\ngoogle.com.qa\ngoogle.com.sa\ngoogle.com.sb\ngoogle.com.sg\ngoogle.com.sl\ngoogle.com.sv\ngoogle.com.tj\ngoogle.com.tr\ngoogle.com.tw\ngoogle.com.ua\ngoogle.com.uy\ngoogle.com.vc\ngoogle.com.vn\ngoogle.co.mz\ngoogle.co.nz\ngoogle.co.th\ngoogle.co.tz\ngoogle.co.ug\ngoogle.co.uk\ngoogle.co.uz\ngoogle.co.ve\ngoogle.co.vi\ngoogle.co.za\ngoogle.co.zm\ngoogle.co.zw\ngoogle.cv\ngoogle.cz\ngoogle.de\ngoogle.dj\ngoogle.dk\ngoogle.dm\ngoogle.dz\ngoogle.ee\ngoogle.es\ngoogle.fi\ngoogle.fm\ngoogle.fr\ngoogle.ga\ngoogle.ge\ngoogle.gf\ngoogle.gg\ngoogle.gl\ngoogle.gm\ngoogle.gp\ngoogle.gr\ngoogle.gy\ngoogle.hn\ngoogle.hr\ngoogle.ht\ngoogle.hu\ngoogle.ie\ngoogle.im\ngoogle.io\ngoogle.iq\ngoogle.is\ngoogle.it\ngoogle.je\ngoogle.jo\ngoogle.kg\ngoogle.ki\ngoogle.kz\ngoogle.la\ngoogle.li\ngoogle.lk\ngoogle.lt\ngoogle.lu\ngoogle.lv\ngoogle.md\ngoogle.me\ngoogle.mg\ngoogle.mk\ngoogle.ml\ngoogle.mn\ngoogle.ms\ngoogle.mu\ngoogle.mv\ngoogle.mw\ngoogle.ne\ngoogle.net\ngoogle.nl\ngoogle.no\ngoogle.nr\ngoogle.nu\ngoogle.org\ngoogle.pl\ngoogle.pn\ngoogle.ps\ngoogle.pt\ngoogle.ro\ngoogle.rs\ngoogle.ru\ngoogle.rw\ngoogle.sc\ngoogle.se\ngoogle.sh\ngoogle.si\ngoogle.sk\ngoogle.sm\ngoogle.sn\ngoogle.so\ngoogle.sr\ngoogle.st\ngoogle.td\ngoogle.tg\ngoogle.tk\ngoogle.tl\ngoogle.tm\ngoogle.tn\ngoogle.to\ngoogle.tt\ngoogle.vg\ngoogle.vu\ngoogle.ws\n"
}

update_gfwlist() {
	update_gfwlist_file
	update_gfwlist_ipset
	update_chinadns_ng_ipset
	return
}

update_gfwlist_file() {
	logger -t "【update_gfwlist】" "开始下载更新 gfwlist 文件...."
	mkdir -p /opt/app/ss_tproxy/rule
	tmp_base64_gfwlist="/opt/app/ss_tproxy/rule/tmp_base64_gfwlist.txt"
	tmp_gfwlist="/opt/app/ss_tproxy/rule/tmp_gfwlist.txt"
	tmp_down_file="/opt/app/ss_tproxy/rule/tmp_gfwlist_tmp.txt"
	rm -f $tmp_gfwlist $tmp_down_file $tmp_base64_gfwlist
	echo "" > /opt/app/ss_tproxy/rule/gfwlist_dns.txt
	echo "" > /opt/app/ss_tproxy/rule/gfwlist_ip.txt
	echo "" > /opt/app/ss_tproxy/rule/gfwlist_dns_b.txt
	ss_3p_enable=`nvram get ss_3p_enable`
	if [ "$ss_3p_enable" = "1" ] ; then
	ss_3p_gfwlist=`nvram get ss_3p_gfwlist`
	if [ "$ss_3p_gfwlist" = "1" ] ; then
		logger -t "【update_gfwlist】" "正在获取官方 gfwlist...."
		url='https://gcore.jsdelivr.net/gh/gfwlist/gfwlist/gfwlist.txt'
		raw_url='https://raw.githubusercontent.com/gfwlist/gfwlist/master/gfwlist.txt'
		wgetcurl_checkmd5 $tmp_base64_gfwlist  "$url" "$raw_url" N 5
		if [ -s $tmp_base64_gfwlist ] && [ -z "$(cat $tmp_base64_gfwlist | grep -Eo [^A-Za-z0-9+/=]+ | tr -d "\n")" ] ; then
		dos2unix $tmp_base64_gfwlist
		sed -e  ':a;N;$!ba;s/\n//g' -i $tmp_base64_gfwlist
		sed -e  's@$@====@g' -i $tmp_base64_gfwlist
		cat $tmp_base64_gfwlist | base64 -d > $tmp_down_file
		rm -f $tmp_base64_gfwlist 
		[ -z "$(cat $tmp_down_file | grep google )" ] && { rm -f $tmp_down_file ; logger -t "【update_gfwlist】" "错误！！！找不到 google ，base64 解码官方 gfwlist 数据不完整" ; }
		[ -z "$(cat $tmp_down_file | grep '\-\-\-EOF\-\-\-' )" ] && { rm -f $tmp_down_file ; logger -t "【update_gfwlist】" "错误！！！ 找不到 EOF ， base64 解码官方 gfwlist 数据不完整" ; }
		if [ -s $tmp_down_file ] ; then
		# blacklist
		cat $tmp_down_file | sort -u |
			sed '/^$\|@@/d'|
			sed 's#!.\+##; s#|##g; s#@##g; s#http:\/\/##; s#https:\/\/##;' | 
			sed '/\*/d; /apple\.com/d; /sina\.cn/d; /sina\.com\.cn/d; /baidu\.com/d; /byr\.cn/d; /weibo\.com/d; /zhongsou\.com/d; /youdao\.com/d; /sogou\.com/d; /so\.com/d; /soso\.com/d; /aliyun\.com/d; /taobao\.com/d; /jd\.com/d; /qq\.com/d; /iqiyi\.com/d;' |
			sed '/^[0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+$/d' |
			grep '^[0-9a-zA-Z\.-]\+$' | grep '\.' | sed 's#^\.\+##' | sed 's/^[[:space:]]*//g; /^$/d; /#/d; s/comUSA/com/g;' | sort -u >> $tmp_gfwlist
		# whitelist
		cat $tmp_down_file | sort -u |
			sed '/^$/d'| grep '^@@.\+$' |
			sed 's#@##g; s#|##g; s#http:\/\/##; s#https:\/\/##;' |
			sed '/^[0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+$/d' |
			grep '^[0-9a-zA-Z\.-]\+$' | grep '\.' | sed 's#^\.\+##' | sed 's/^[[:space:]]*//g; /^$/d; /#/d; s/comUSA/com/g;' | sort -u | sed '/^$/d' >> /opt/app/ss_tproxy/rule/gfwlist_dns_b.txt
			printf "sina.cn\nsina.com.cn\nbaidu.com\nbyr.cn\n\nweibo.com\nzhongsou.com\nyoudao.com\nsogou.com\nso.com\nsoso.com\naliyun.com\ntaobao.com\njd.com\nqq.com\niqiyi.com\ngoogle.cn\n" >> /opt/app/ss_tproxy/rule/gfwlist_dns_b.txt
			sed -e '/^$/d' -i /opt/app/ss_tproxy/rule/gfwlist_dns_b.txt
		fi
		else
		logger -t "【update_gfwlist】" "错误！！！获取官方 gfwlist 下载失败"
		fi
		rm -f $tmp_down_file
	fi
	ss_3p_kool=`nvram get ss_3p_kool`
	if [ "$ss_3p_kool" = "1" ] ; then
		logger -t "【update_gfwlist】" "正在获取 koolshare 列表...."
		url='https://gcore.jsdelivr.net/gh/hq450/fancyss/rules/gfwlist.conf'
		raw_url='https://raw.githubusercontent.com/hq450/fancyss/master/rules/gfwlist.conf'
		wgetcurl_checkmd5 $tmp_down_file "$url" "$raw_url" N 5
		if [ -s $tmp_down_file ] ; then
		echo ""  >> $tmp_down_file
		cat $tmp_down_file | sort -u | sed 's/^[[:space:]]*//g; /^$/d; /#/d' | sed 's/ipset=\/\.//g; s/\/gfwlist//g; /^server/d' >> $tmp_gfwlist
		fi
		rm -f $tmp_down_file
	fi
	ss_sub5=`nvram get ss_sub5`
	if [ ! -z "$ss_sub5" ] ; then
		logger -t "【update_gfwlist】" "正在获取 GFW 自定义域名 列表...."
		wgetcurl_checkmd5 $tmp_down_file $ss_sub5 $ss_sub5 Y
		if [ -s $tmp_down_file ] && [ ! -z "$(cat $tmp_down_file | grep -Eo [^A-Za-z0-9+/=]+ | tr -d "\n")" ] ; then
		echo ""  >> $tmp_down_file
		cat $tmp_down_file | sort -u | sed 's/^[[:space:]]*//g; /^$/d; /#/d' | sed 's/ipset=\/\.//g; s/\/gfwlist//g; /^server/d' | sort -u | grep -v '^$' >> $tmp_gfwlist
		else
		logger -t "【update_chnroute】" "错误！！！获取 GFW 自定义域名 列表 下载失败"
		fi
		rm -f $tmp_down_file
	fi
	if [ ! -s $tmp_gfwlist ] ; then
		logger -t "【update_gfwlist】" "加入 固件内置list规则 列表...."
		rm -f /etc/storage/basedomain.txt
		tar -xzvf /etc_ro/basedomain.tgz -C /tmp ; cd /opt
		ln -sf /tmp/basedomain.txt /etc/storage/basedomain.txt
		[ -s /etc/storage/basedomain.txt ] && cat /etc/storage/basedomain.txt | sort -u >> $tmp_gfwlist
	fi
	ss_sub1=`nvram get ss_sub1`
	if [ "$ss_sub1" = "1" ] ; then
		logger -t "【update_gfwlist】" "处理订阅列表1....海外加速"
		url='/list.txt'
		wgetcurl_checkmd5 $tmp_down_file "$hiboyfile$url" "$hiboyfile2$url" N 5
		if [ -s $tmp_down_file ] ; then
		echo ""  >> $tmp_down_file
		cat $tmp_down_file | sort -u | sed 's/^[[:space:]]*//g; /^$/d; /#/d' | sed 's/ipset=\/\.//g; s/\/gfwlist//g; /^server/d' >> $tmp_gfwlist
		fi
		rm -f $tmp_down_file
	fi
	ss_sub2=`nvram get ss_sub2`
	if [ "$ss_sub2" = "1" ] ; then
		#处理只做dns解释的域名
		logger -t "【update_gfwlist】" "处理订阅列表2....处理只做dns解释的域名"
		url='/dnsonly.txt'
		wgetcurl_checkmd5 $tmp_down_file "$hiboyfile$url" "$hiboyfile2$url" N 5
		if [ -s $tmp_down_file ] ; then
		echo ""  >> $tmp_down_file
		cat $tmp_down_file | sort -u | sed 's/^[[:space:]]*//g; /^$/d; /#/d' | sed 's/ipset=\/\.//g; s/\/gfwlist//g; /^server/d' > /opt/app/ss_tproxy/rule/gfwlist_dns.txt
		fi
		rm -f $tmp_down_file
	fi
	ss_sub3=`nvram get ss_sub3`
	if [ "$ss_sub3" = "1" ] ; then
		#处理需要排除的域名解释
		logger -t "【update_gfwlist】" "处理订阅列表3....处理需要排除的域名解释"
		url='/passby.txt'
		wgetcurl_checkmd5 $tmp_down_file "$hiboyfile$url" "$hiboyfile2$url" N 5
		if [ -s $tmp_down_file ] ; then
		echo ""  >> $tmp_down_file
		cat $tmp_down_file | sort -u | sed 's/^[[:space:]]*//g; /^$/d; /#/d' | sed 's/ipset=\/\.//g; s/\/gfwlist//g; /^server/d' >> /opt/app/ss_tproxy/rule/gfwlist_dns_b.txt
		fi
		rm -f $tmp_down_file
	fi
	ss_sub6=`nvram get ss_sub6`
	if [ ! -z "$ss_sub6" ] ; then
		logger -t "【update_gfwlist】" "正在获取 GFW IP 列表...."
		wgetcurl_checkmd5 $tmp_down_file $ss_sub6 $ss_sub6 Y
		if [ -s $tmp_down_file ] && [ ! -z "$(cat $tmp_down_file | grep -Eo [^A-Za-z0-9+/=]+ | tr -d "\n")" ] ; then
		echo ""  >> $tmp_down_file
		cat $tmp_down_file | grep -v '^#' | sort -u | grep -v '^$' | grep -E -o '([0-9]+\.){3}[0-9/]+' > /opt/app/ss_tproxy/rule/gfwlist_ip.txt
		else
		logger -t "【update_chnroute】" "错误！！！获取 GFW IP 列表 下载失败"
		fi
		rm -f $tmp_down_file
	fi
	fi
	if [ ! -s $tmp_gfwlist ] ; then
		logger -t "【update_gfwlist】" "加入 固件内置list规则 列表...."
		rm -f /etc/storage/basedomain.txt
		tar -xzvf /etc_ro/basedomain.tgz -C /tmp ; cd /opt
		ln -sf /tmp/basedomain.txt /etc/storage/basedomain.txt
		[ -s /etc/storage/basedomain.txt ] && cat /etc/storage/basedomain.txt | sort -u >> $tmp_gfwlist
	fi
	rm -f $tmp_down_file
	# 临时添加的域名
	echo "whatsapp.net" >> $tmp_gfwlist
	gfwlist_txt_append_domain_names >> $tmp_gfwlist
	# 添加自定义黑名单
	cat $file_wanlist_ext | grep -E "^@g" | cut -c4- | while read domain_addr; do echo "$domain_addr" >> $tmp_gfwlist; done 
	#删除忽略的域名
	cat $file_wanlist_ext | grep -E "^@b" | cut -c4- > /opt/app/ss_tproxy/tmp/awk_del_list_tmp
	awk_del_list /opt/app/ss_tproxy/tmp/awk_del_list_tmp $tmp_gfwlist
	cat /etc/storage/shadowsocks_mydomain_script.sh | sed '/^$\|#/d' | sed "s/http://g" | sed "s/https://g" | sed "s/\///g" | sort -u >> $tmp_gfwlist
	cat $tmp_gfwlist |grep -v '^#' | sort -u | grep -v '^$' > $file_gfwlist_txt
	sed -e '/^$/d' -i $file_gfwlist_txt
	dos2unix $file_gfwlist_txt
	logger -t "【update_gfwlist】" "完成下载 gfwlist 文件"
	rm -f $tmp_gfwlist
	rm -f /etc/storage/basedomain.txt
	ln -sf $file_gfwlist_txt /etc/storage/basedomain.txt
}

update_md5_check() {
    md5_file=/opt/app/ss_tproxy/tmp/$1.md5
    shift
    touch "$@"
    md5_check="NOT"
    # 检测配置文件变化，不匹配则进行更新ipset
    if [ ! -s "$md5_file" ] ; then
        md5sum "$@" $ss_tproxy_config /opt/app/ss_tproxy/ss_tproxy > $md5_file
        return 1
    fi
    md5sum -s -c $md5_file
    if [ "$?" == "0" ] ; then
        md5_check="OK"
        return 0
    else
        md5sum "$@" $ss_tproxy_config /opt/app/ss_tproxy/ss_tproxy > $md5_file
        md5_check="NOT"
        return 1
    fi
}
update_cflist_ipset() {
touch $1 $2
a_ipset_conf=$1
b_ipset_conf=$2
# [a =>> b] 重复的 ipset 规则合并
# 把 a 文件 [ipset=/opt.cn2qq.com/adbybylist]
# 合并到已存在的 b 文件 [ipset=/opt.cn2qq.com/gfwlist]
# 得到 b 文件 [ipset=/opt.cn2qq.com/gfwlist,adbybylist]
if [ -s $a_ipset_conf ] ; then

echo "$(awk -F '/' '\
NR==FNR{\
  alist=$3
  if($1 == "ipset=") {\
    a[$2]++\
  }\
}\
NR>FNR{\
  if($1 == "ipset=") {\
    if($2 in a) {\
      if($0 ~ alist) {\
        print $0}\
      else{\
        print $0","alist}\
      }\
    else{\
      print $0}\
  }\
  else{\
    print $0
  }\
}' $a_ipset_conf $b_ipset_conf)" > $b_ipset_conf

echo "$(awk -F '/' '\
NR==FNR{\
  if($1 == "ipset=") {\
    a[$2]++\
  }\
}\
NR>FNR{\
  if($1 == "ipset=") {\
    if(!($2 in a)) {\
      print $0}\
  }\
  else{\
    print $0
  }\
}' $b_ipset_conf $a_ipset_conf)" >> $b_ipset_conf

fi
}

update_chinadns_ng_ipset() {
	if [ "$chinadns_ng_enable" != "1" ] ; then
		return
	fi
	mkdir -p /opt/app/ss_tproxy/rule
	if is_true "$ipv4" && is_true "$ipv6"; then
		chinadns_ng_gfwlist_ipset_setname="gfwlist,gfwlist6"
		chinadns_ng_chnip_ipset_setname="chnroute,chnroute6"
		chinadns_ng_black_ipset_setname="sstp_dst_fw,sstp_dst_fw6"
		chinadns_ng_white_ipset_setname="sstp_dst_bp,sstp_dst_bp6"
		ipset -! create gfwlist hash:net family inet
		ipset flush gfwlist &>/dev/null
		ipset -! create gfwlist6 hash:net family inet6
		ipset flush gfwlist6 &>/dev/null
		ipset -! create chnroute hash:net family inet
		ipset -! create chnroute6 hash:net family inet6
		ipset -! sstp_dst_fw hash:net hashsize 64 family inet
		ipset -! sstp_dst_fw6 hash:net hashsize 64 family inet6
		ipset -! create sstp_dst_bp hash:net hashsize 64 family inet
		ipset -! create sstp_dst_bp6 hash:net hashsize 64 family inet6
	elif is_true "$ipv4"; then
		chinadns_ng_gfwlist_ipset_setname="gfwlist,null"
		chinadns_ng_chnip_ipset_setname="chnroute,null"
		chinadns_ng_black_ipset_setname="sstp_dst_fw,null"
		chinadns_ng_white_ipset_setname="sstp_dst_bp,null"
		ipset -! create gfwlist hash:net family inet
		ipset flush gfwlist &>/dev/null
		ipset -! create chnroute hash:net family inet
		ipset -! sstp_dst_fw hash:net hashsize 64 family inet
		ipset -! create sstp_dst_bp hash:net hashsize 64 family inet
	else
		chinadns_ng_gfwlist_ipset_setname="null,gfwlist6"
		chinadns_ng_chnip_ipset_setname="null,chnroute6"
		chinadns_ng_black_ipset_setname="null,sstp_dst_fw6"
		chinadns_ng_white_ipset_setname="null,sstp_dst_bp6"
		ipset -! create gfwlist6 hash:net family inet6
		ipset flush gfwlist6 &>/dev/null
		ipset -! create chnroute6 hash:net family inet6
		ipset -! sstp_dst_fw6 hash:net hashsize 64 family inet6
		ipset -! create sstp_dst_bp6 hash:net hashsize 64 family inet6
	fi

	chinadns_ng_2_usage=" --no-ipv6 tag:gfw "
	if [ "$chinadns_ng_8953" = "1" ] ; then
		logger -t "【update_chinadns_ng_ipset】" "第三方 DNS 前套娃一个 chinadns_ng"
		chinadns_ng_2_usage="$chinadns_ng_2_usage -b 0.0.0.0 -l 8953 "
		chinadns_ng_trust_tcp_dns4="127.0.0.1#8053"
	else
		chinadns_ng_2_usage="$chinadns_ng_2_usage -b 0.0.0.0 -l 8053 "
		if [ "$smartdns_enable" == "1" ] && [ -s /etc/storage/app_23.sh ] ; then
			logger -t "【update_chinadns_ng_ipset】" "chinadns_ng + smartdns 做查询接口"
			chinadns_ng_china_dns4="127.0.0.1#8051"
			chinadns_ng_trust_tcp_dns4="127.0.0.1#8052"
		else
			logger -t "【update_chinadns_ng_ipset】" "chinadns_ng 做查询接口"
			if [ "${chinadns_ng_trust_dns4}" = "8.8.8.8#53" ] ; then
				chinadns_ng_trust_tcp_dns4="tcp://""${chinadns_ng_trust_dns4}"
			else
				chinadns_ng_trust_tcp_dns4="${chinadns_ng_trust_dns4}"
			fi
		fi
	fi
	if is_true "$ipv4"; then
	chinadns_ng_2_usage="$chinadns_ng_2_usage --china-dns $chinadns_ng_china_dns4 --trust-dns $chinadns_ng_trust_tcp_dns4 "
	fi
	if is_true "$ipv6"; then
	chinadns_ng_2_usage="$chinadns_ng_2_usage --china-dns $chinadns_ng_china_dns6 --trust-dns $chinadns_ng_trust_dns6 "
	fi
	if is_global_mode; then
		# global
		if [ "$ss_pdnsd_cn_all" = "1" ] ; then # 1:不进行 China 域名加速
		chinadns_ng_2_usage="$chinadns_ng_2_usage""\
--chnlist-file /opt/app/ss_tproxy/rule/chnlist_null.txt "
		echo "" > /opt/app/ss_tproxy/rule/chnlist_null.txt
		fi
		if [ "$ss_pdnsd_cn_all" = "0" ] ; then # 0:使用 8053 端口查询全部 DNS 时进行 China 域名加速
		chinadns_ng_2_usage="$chinadns_ng_2_usage""\
--chnlist-file /opt/app/ss_tproxy/rule/chnlist_mini.txt,/opt/app/ss_tproxy/rule/chnlist.txt "
		fi
		chinadns_ng_2_usage="$chinadns_ng_2_usage""\
--default-tag gfw \
--add-tagchn-ip $chinadns_ng_chnip_ipset_setname \
--add-taggfw-ip $chinadns_ng_gfwlist_ipset_setname "
		touch /opt/app/ss_tproxy/rule/chnlist_mini.txt /opt/app/ss_tproxy/rule/chnlist.txt
	elif is_gfwlist_mode; then
		# gfwlist
		chinadns_ng_2_usage="$chinadns_ng_2_usage""\
--gfwlist-file $file_gfwlist_txt --default-tag chn \
--add-tagchn-ip $chinadns_ng_chnip_ipset_setname \
--add-taggfw-ip $chinadns_ng_gfwlist_ipset_setname "
		if [ ! -s $file_gfwlist_txt ] ; then
			logger -t "【update_chinadns_ng_ipset】" "错误！！！$file_gfwlist_txt 文件为空，使用 固件内置 /etc/storage/basedomain.txt 规则...."
			rm -f /etc/storage/basedomain.txt
			tar -xzvf /etc_ro/basedomain.tgz -C /tmp ; cd /opt
			ln -sf /tmp/basedomain.txt /etc/storage/basedomain.txt
			[ -s /etc/storage/basedomain.txt ] && cat /etc/storage/basedomain.txt | sort -u >> $file_gfwlist_txt
			gfwlist_txt_append_domain_names >> $file_gfwlist_txt
		fi
	elif is_chnroute_mode; then
		# chnroute
		chinadns_ng_2_usage="$chinadns_ng_2_usage""\
--chnlist-file /opt/app/ss_tproxy/rule/chnlist_mini.txt,/opt/app/ss_tproxy/rule/chnlist.txt \
--add-tagchn-ip $chinadns_ng_chnip_ipset_setname --chnlist-first \
--gfwlist-file $file_gfwlist_txt \
--add-taggfw-ip $chinadns_ng_gfwlist_ipset_setname \
--ipset-name4 chnroute \
--ipset-name6 chnroute6 "
		touch /opt/app/ss_tproxy/rule/chnlist_mini.txt /opt/app/ss_tproxy/rule/chnlist.txt
	elif is_chnlist_mode; then
		# 回国模式 反转 gfwlist
		chinadns_ng_2_usage="$chinadns_ng_2_usage""\
--gfwlist-file /opt/app/ss_tproxy/rule/chnlist_mini.txt,/opt/app/ss_tproxy/rule/chnlist.txt \
--add-taggfw-ip $chinadns_ng_gfwlist_ipset_setname "
		touch /opt/app/ss_tproxy/rule/chnlist_mini.txt /opt/app/ss_tproxy/rule/chnlist.txt
	fi
	chinadns_ng_2_usage="$chinadns_ng_2_usage"" --verdict-cache 1000 "
	# 域名解释加速
	chinadns_ng_2_usage="$chinadns_ng_2_usage"" --group dnsonly \
--group-dnl /opt/app/ss_tproxy/rule/gfwlist_dns.txt \
--group-upstream $chinadns_ng_trust_tcp_dns4 "
	touch /opt/app/ss_tproxy/rule/gfwlist_dns.txt
	# 需要忽略的域名处理
	chinadns_ng_2_usage="$chinadns_ng_2_usage"" --group passby \
--group-dnl /opt/app/ss_tproxy/rule/gfwlist_dns_b.txt \
--group-upstream $DNS_china "
	touch /opt/app/ss_tproxy/rule/gfwlist_dns_b.txt
	# black
	chinadns_ng_2_usage="$chinadns_ng_2_usage"" --group black \
--group-dnl /opt/app/ss_tproxy/rule/blacklist.txt \
--group-upstream $chinadns_ng_trust_tcp_dns4 \
--group-ipset $chinadns_ng_black_ipset_setname "
	touch /opt/app/ss_tproxy/rule/blacklist.txt
	# white
	chinadns_ng_2_usage="$chinadns_ng_2_usage"" --group white \
--group-dnl /opt/app/ss_tproxy/rule/whitelist.txt \
--group-upstream $chinadns_ng_china_dns4 \
--group-ipset $chinadns_ng_white_ipset_setname "
	touch /opt/app/ss_tproxy/rule/whitelist.txt
	[ ! -z "$ext_chinadns_ng_usage" ] && chinadns_ng_2_usage="$ext_chinadns_ng_usage"
	rule_file=""
	for i in $(echo "$chinadns_ng_2_usage" | sed "s@,@\ @g") ; do
		[ -f "$i" ] && [ -s "$i" ] && rule_file="$rule_file"" $i"
	done
	nvram set gfwlist_list="chinadns_ng 规则 `cat $rule_file | wc -l` 行 Update:$(date "+%m-%d %H:%M")"
	nvram set app_2="$chinadns_ng_2_usage"
	
	if [ "$1" == "not_check" ] ; then
		return
	fi
	update_md5_check update_chinadns_ng_gfwlist_dns $file_gfwlist_txt /opt/app/ss_tproxy/rule/chnlist_mini.txt /opt/app/ss_tproxy/rule/chnlist.txt /opt/app/ss_tproxy/rule/gfwlist_dns.txt /opt/app/ss_tproxy/rule/gfwlist_dns_b.txt /opt/app/ss_tproxy/rule/blacklist.txt /opt/app/ss_tproxy/rule/whitelist.txt
	if is_md5_not ; then
		chinadns_ng_status=0 && nvram set chinadns_ng_status=0
		/etc/storage/script/Sh09_chinadns_ng.sh
	fi
}

update_gfwlist_ipset() {
	if [ "$chinadns_ng_enable" == "1" ] ; then
		return
	fi
	mkdir -p /opt/app/ss_tproxy/dnsmasq.d
	touch /opt/app/ss_tproxy/rule/gfwlist_ip.txt /opt/app/ss_tproxy/rule/gfwlist_dns_b.txt /opt/app/ss_tproxy/rule/gfwlist_dns.txt
	update_md5_check update_gfwlist_dns /opt/app/ss_tproxy/rule/gfwlist_dns.txt /opt/app/ss_tproxy/rule/gfwlist_dns_b.txt
	if is_md5_not ; then
		echo "" > /opt/app/ss_tproxy/dnsmasq.d/r.sub.conf
		if [ -s /opt/app/ss_tproxy/rule/gfwlist_dns.txt ] ; then
		is_true "$ipv4" && cat /opt/app/ss_tproxy/rule/gfwlist_dns.txt | sort -u | sed 's/^[[:space:]]*//g; /^$/d; /#/d' | awk '{printf("server=/%s/'"$dns4_fw_type"'\n", $1)}' >> /opt/app/ss_tproxy/dnsmasq.d/r.sub.conf
		is_true "$ipv6" && cat /opt/app/ss_tproxy/rule/gfwlist_dns.txt | sort -u | sed 's/^[[:space:]]*//g; /^$/d; /#/d' | awk '{printf("server=/%s/'"$dns6_fw_type"'\n", $1)}' >> /opt/app/ss_tproxy/dnsmasq.d/r.sub.conf
		fi
		if [ -s /opt/app/ss_tproxy/rule/gfwlist_dns_b.txt ] ; then
		is_true "$ipv4" && cat /opt/app/ss_tproxy/rule/gfwlist_dns_b.txt | sort -u | sed 's/^[[:space:]]*//g; /^$/d; /#/d' | awk '{printf("server=/%s/'"$DNS_china"'\n", $1)}' >> /opt/app/ss_tproxy/dnsmasq.d/r.sub.conf
		is_true "$ipv6" && cat /opt/app/ss_tproxy/rule/gfwlist_dns_b.txt | sort -u | sed 's/^[[:space:]]*//g; /^$/d; /#/d' | awk '{printf("server=/%s/'"$dns_direct6"'\n", $1)}' >> /opt/app/ss_tproxy/dnsmasq.d/r.sub.conf
		fi
	fi
	if [ ! -s $file_gfwlist_txt ] ; then
		logger -t "【update_gfwlist】" "错误！！！$file_gfwlist_txt 文件为空，使用 固件内置 /etc/storage/basedomain.txt 规则...."
		rm -f /etc/storage/basedomain.txt
		tar -xzvf /etc_ro/basedomain.tgz -C /tmp ; cd /opt
		ln -sf /tmp/basedomain.txt /etc/storage/basedomain.txt
		[ -s /etc/storage/basedomain.txt ] && cat /etc/storage/basedomain.txt | sort -u >> $file_gfwlist_txt
		gfwlist_txt_append_domain_names >> $file_gfwlist_txt
	fi
	sed -e '/^$/d' -i $file_gfwlist_txt
	if ! is_chnlist_mode; then
	update_md5_check update_gfwlist_txt $file_gfwlist_txt
	logger -t "【update_gfwlist】" "开始加载 gfwlist 规则...."
	if is_md5_not ; then
	echo "" > /opt/app/ss_tproxy/dnsmasq.d/r.gfwlist.conf
	if [ -s $file_gfwlist_txt ] ; then
		# 开始构造dnsmasq.conf
		if is_true "$ipv4" && is_true "$ipv6"; then
			gfwlist_ipset_setname="gfwlist,gfwlist6"
			ipset -! create gfwlist hash:net family inet
			ipset flush gfwlist &>/dev/null
			ipset -! create gfwlist6 hash:net family inet6
			ipset flush gfwlist6 &>/dev/null
		elif is_true "$ipv4"; then
			gfwlist_ipset_setname="gfwlist"
			ipset -! create gfwlist hash:net family inet
			ipset flush gfwlist &>/dev/null
		else
			gfwlist_ipset_setname="gfwlist6"
			ipset -! create gfwlist6 hash:net family inet6
			ipset flush gfwlist6 &>/dev/null
		fi
		gfwlist_conf=""
		export file_number=`wc -l $file_gfwlist_txt | awk -F'\ ' '{print $1}'`
		is_true "$ipv4" && logger -t "【update_gfwlist】" "已经加载 gfwlist dns ipv4 规则 0%" && gfwlist_conf="$(awk 'BEGIN {c=0;a=1}{printf("server=/%s/127.0.0.1#8053\n", $1 )}{i++}{b=i/ENVIRON["file_number"]*10}{if(b>a){a++}}{if(c!=a){c=a;system("eval  sed \\\"s/已经加载 gfwlist dns ipv4 规则.+/已经加载 gfwlist dns ipv4 规则 "c"0%/g\\\"  -Ei /tmp/syslog.log")}}' $file_gfwlist_txt)" && echo "$gfwlist_conf" >> /opt/app/ss_tproxy/dnsmasq.d/r.gfwlist.conf
		gfwlist_conf=""
		is_true "$ipv6" && logger -t "【update_gfwlist】" "已经加载 gfwlist dns ipv6 规则 0%" && gfwlist_conf="$(awk 'BEGIN {c=0;a=1}{printf("server=/%s/'"$dns_remote6"'\n", $1 )}{i++}{b=i/ENVIRON["file_number"]*10}{if(b>a){a++}}{if(c!=a){c=a;system("eval  sed \\\"s/已经加载 gfwlist dns ipv6 规则.+/已经加载 gfwlist dns ipv6 规则 "c"0%/g\\\"  -Ei /tmp/syslog.log")}}' $file_gfwlist_txt)" && echo "$gfwlist_conf" >> /opt/app/ss_tproxy/dnsmasq.d/r.gfwlist.conf
		gfwlist_conf=""
		logger -t "【update_gfwlist】" "已经加载 gfwlist ipset 规则 0%" && gfwlist_conf="$(awk 'BEGIN {c=0;a=1}{printf("ipset=/%s/'"$gfwlist_ipset_setname"'\n", $1 )}{i++}{b=i/ENVIRON["file_number"]*10}{if(b>a){a++}}{if(c!=a){c=a;system("eval  sed \\\"s/已经加载 gfwlist ipset 规则.+/已经加载 gfwlist ipset 规则 "c"0%/g\\\"  -Ei /tmp/syslog.log")}}' $file_gfwlist_txt)" && echo "$gfwlist_conf" >> /opt/app/ss_tproxy/dnsmasq.d/r.gfwlist.conf
		gfwlist_conf=""
		sed -e '/^$/d' -i /opt/app/ss_tproxy/dnsmasq.d/r.gfwlist.conf
		nvram set gfwlist_list="gfwlist 规则 `cat /opt/app/ss_tproxy/dnsmasq.d/r.gfwlist.conf | wc -l` 行 Update:$(date "+%m-%d %H:%M")"
		logger -t "【update_gfwlist】" "配置更新，完成加载 gfwlist 规则...."
	else
		logger -t "【update_gfwlist】" "更新错误！！！ $file_gfwlist_txt 规则为空...."
	fi
	else
		[ ! -s $file_gfwlist_txt ] && logger -t "【update_gfwlist】" "匹配错误！！！ $file_gfwlist_txt 规则为空...."
		logger -t "【update_gfwlist】" "配置匹配，完成加载 gfwlist 规则...."
	fi
	fi
}

update_chnlist() {
	[ "$chinadns_ng_enable" == "1" ] || [ "$chinadns_ng_enable" == "3" ] && update_chnlist_file
	[ "$ss_pdnsd_cn_all" != "1" ] && update_chnlist_file "chnlist_mini.txt"
	return
}

update_chnlist_file() {
	logger -t "【update_chnlist】" "开始下载更新 chnlist 文件...."
	mkdir -p /opt/app/ss_tproxy/rule
	tmp_down_file="/opt/app/ss_tproxy/rule/tmp_chnlist_tmp.txt"
	rm -f $tmp_down_file
	#url='https://gcore.jsdelivr.net/gh/felixonmars/dnsmasq-china-list/accelerated-domains.china.conf'
	#raw_url='https://raw.githubusercontent.com/felixonmars/dnsmasq-china-list/master/accelerated-domains.china.conf'
	#wgetcurl_checkmd5 $tmp_down_file "$url" "$raw_url" N 5
	if [ "$1" = 'chnlist_mini.txt' ] ; then
	chnlist_txt="chnlist_mini.txt"
	wgetcurl_checkmd5 $tmp_down_file "$hiboyfile/chinalist.txt" "$hiboyfile2/chinalist.txt" N 5
	else
	chnlist_txt="chnlist.txt"
	wgetcurl_checkmd5 $tmp_down_file "$hiboyfile/accelerated-domains.china.conf" "$hiboyfile2/accelerated-domains.china.conf" N 5
	fi
	sed -e "s@server=/@@g" -i  $tmp_down_file
	sed -e 's@/.*@@g' -i  $tmp_down_file
	printf "com.cn\nedu.cn\nnet.cn\norg.cn\ngov.cn\n" >> $tmp_down_file
	# 添加自定义白名单
	cat $file_wanlist_ext | grep -E "^@b" | cut -c4- | while read domain_addr; do echo "$domain_addr" >> $tmp_down_file; done 
	#删除忽略的域名
	cat $file_wanlist_ext | grep -E "^@g" | cut -c4- > /opt/app/ss_tproxy/tmp/awk_del_list_tmp
	awk_del_list /opt/app/ss_tproxy/tmp/awk_del_list_tmp $tmp_down_file
	cat $tmp_down_file | grep -v '^#' | sort -u | grep -v '^$' > /opt/app/ss_tproxy/rule/$chnlist_txt
	sed -e '/^$/d' -i /opt/app/ss_tproxy/rule/$chnlist_txt
	#删除gfwlist的域名
	awk_del_list $file_gfwlist_txt /opt/app/ss_tproxy/rule/$chnlist_txt
	dos2unix /opt/app/ss_tproxy/rule/$chnlist_txt
	sed -e '/^$/d' -i /opt/app/ss_tproxy/rule/$chnlist_txt
	logger -t "【update_chnlist】" "完成下载 $chnlist_txt 文件"
	rm -f $tmp_down_file
}

update_chnlist_ipset() {
	if [ "$chinadns_ng_enable" == "1" ] ; then
		return
	fi
	mkdir -p /opt/app/ss_tproxy/dnsmasq.d
	sed -e '/^$/d' -i /opt/app/ss_tproxy/rule/chnlist.txt
	if is_chnlist_mode; then
		[ ! -s /opt/app/ss_tproxy/rule/chnlist.txt ] && update_chnlist_file "chnlist_mini.txt"
		logger -t "【update_chnlist】" "开始加载 chnlist 规则（回国模式）...."
		update_md5_check update_chnlist1_txt /opt/app/ss_tproxy/rule/chnlist.txt
		if is_md5_not ; then
		echo "" > /opt/app/ss_tproxy/dnsmasq.d/r.gfwlist.conf
		echo "" > /opt/app/ss_tproxy/dnsmasq.d/accelerated-domains.china.conf
		if [ -s /opt/app/ss_tproxy/rule/chnlist.txt ] ; then
		# 开始构造dnsmasq.conf
		if is_true "$ipv4" && is_true "$ipv6"; then
			gfwlist_ipset_setname="gfwlist,gfwlist6"
			ipset -! create gfwlist hash:net family inet
			ipset flush gfwlist &>/dev/null
			ipset -! create gfwlist6 hash:net family inet6
			ipset flush gfwlist6 &>/dev/null
		elif is_true "$ipv4"; then
			gfwlist_ipset_setname="gfwlist"
			ipset -! create gfwlist hash:net family inet
			ipset flush gfwlist &>/dev/null
		else
			gfwlist_ipset_setname="gfwlist6"
			ipset -! create gfwlist6 hash:net family inet6
			ipset flush gfwlist6 &>/dev/null
		fi
		# 回国模式直接使用远端DNS走代理，停止使用 dnsproxy
		chnlist_conf=""
		export file_number=`wc -l /opt/app/ss_tproxy/rule/chnlist.txt | awk -F'\ ' '{print $1}'`
		is_true "$ipv4" && logger -t "【update_chnlist】" "已经加载 chnlist dns ipv4 规则 0%" && chnlist_conf="$(awk 'BEGIN {c=0;a=1}{printf("server=/%s/'"$dns_remote"'\n", $1 )}{i++}{b=i/ENVIRON["file_number"]*10}{if(b>a){a++}}{if(c!=a){c=a;system("eval  sed \\\"s/已经加载 chnlist dns ipv4 规则.+/已经加载 chnlist dns ipv4 规则 "c"0%/g\\\"  -Ei /tmp/syslog.log")}}' /opt/app/ss_tproxy/rule/chnlist.txt)" && echo "$chnlist_conf" >> /opt/app/ss_tproxy/dnsmasq.d/r.gfwlist.conf
		chnlist_conf=""
		is_true "$ipv6" && logger -t "【update_chnlist】" "已经加载 chnlist dns ipv6 规则 0%" && chnlist_conf="$(awk 'BEGIN {c=0;a=1}{printf("server=/%s/'"$dns_remote6"'\n", $1 )}{i++}{b=i/ENVIRON["file_number"]*10}{if(b>a){a++}}{if(c!=a){c=a;system("eval  sed \\\"s/已经加载 chnlist dns ipv6 规则.+/已经加载 chnlist dns ipv6 规则 "c"0%/g\\\"  -Ei /tmp/syslog.log")}}' /opt/app/ss_tproxy/rule/chnlist.txt)" && echo "$chnlist_conf" >> /opt/app/ss_tproxy/dnsmasq.d/r.gfwlist.conf
		chnlist_conf=""
		logger -t "【update_chnlist】" "已经加载 chnlist ipset 规则 0%" && chnlist_conf="$(awk 'BEGIN {c=0;a=1}{printf("ipset=/%s/'"$gfwlist_ipset_setname"'\n", $1 )}{i++}{b=i/ENVIRON["file_number"]*10}{if(b>a){a++}}{if(c!=a){c=a;system("eval  sed \\\"s/已经加载 chnlist ipset 规则.+/已经加载 chnlist ipset 规则 "c"0%/g\\\"  -Ei /tmp/syslog.log")}}' /opt/app/ss_tproxy/rule/chnlist.txt)" && echo "$chnlist_conf" >> /opt/app/ss_tproxy/dnsmasq.d/r.gfwlist.conf
		chnlist_conf=""
		sed -e '/^$/d' -i /opt/app/ss_tproxy/dnsmasq.d/r.gfwlist.conf
		logger -t "【update_chnlist】" "配置更新，完成加载 chnlist 规则...."
		else
		logger -t "【update_chnlist】" "更新错误！！！ /opt/app/ss_tproxy/rule/chnlist.txt 规则为空...."
		fi
		else
			[ ! -s /opt/app/ss_tproxy/rule/chnlist.txt ] && logger -t "【update_chnlist】" "匹配错误！！！ /opt/app/ss_tproxy/rule/chnlist.txt 规则为空...."
			logger -t "【update_chnlist】" "配置匹配，完成加载 chnlist 规则...."
		fi
	else
		if [ "$ss_pdnsd_cn_all" != "1" ] ; then
		[ ! -s /opt/app/ss_tproxy/rule/chnlist_mini.txt ] && update_chnlist_file "chnlist_mini.txt"
		update_md5_check update_chnlist2_txt /opt/app/ss_tproxy/rule/chnlist_mini.txt
		if is_md5_not ; then
		echo "" > /opt/app/ss_tproxy/dnsmasq.d/accelerated-domains.china.conf
		if [ -s /opt/app/ss_tproxy/rule/chnlist_mini.txt ] ; then
		logger -t "【update_chnlist_mini】" "加速国内 dns 访问"
		logger -t "【update_chnlist_mini】" "开始加载 chnlist_mini 规则...."
		chnlist_conf=""
		export file_number=`cat /opt/app/ss_tproxy/rule/chnlist_mini.txt | sed -e 's@^cn$@com.cn@g' |sed 's/^[[:space:]]*//g; /^$/d; /#/d' |wc -l|awk -F'\ ' '{print $1}'`
		is_true "$ipv4" && logger -t "【update_chnlist_mini】" "已经加载 chnlist_mini ipv4 规则 0%" && chnlist_conf="$(cat /opt/app/ss_tproxy/rule/chnlist_mini.txt | sed -e 's@^cn$@com.cn@g' | sort -u | sed 's/^[[:space:]]*//g; /^$/d; /#/d' | awk 'BEGIN {c=0;a=1}{printf("server=/%s/'"$DNS_china"'\n", $1)}{i++}{b=i/ENVIRON["file_number"]*10}{if(b>a){a++}}{if(c!=a){c=a;system("eval  sed \\\"s/已经加载 chnlist_mini ipv4 规则.+/已经加载 chnlist_mini ipv4 规则 "c"0%/g\\\"  -Ei /tmp/syslog.log")}}')" && echo "$chnlist_conf" >> /opt/app/ss_tproxy/dnsmasq.d/accelerated-domains.china.conf
		chnlist_conf=""
		is_true "$ipv6" && logger -t "【update_chnlist_mini】" "已经加载 chnlist_mini ipv6 规则 0%" && chnlist_conf="$(cat /opt/app/ss_tproxy/rule/chnlist_mini.txt | sed -e 's@^cn$@com.cn@g' | sort -u | sed 's/^[[:space:]]*//g; /^$/d; /#/d' | awk 'BEGIN {c=0;a=1}{printf("server=/%s/'"$dns_direct6"'\n", $1)}{i++}{b=i/ENVIRON["file_number"]*10}{if(b>a){a++}}{if(c!=a){c=a;system("eval  sed \\\"s/已经加载 chnlist_mini ipv6 规则.+/已经加载 chnlist_mini ipv6 规则 "c"0%/g\\\"  -Ei /tmp/syslog.log")}}')" && echo "$chnlist_conf" >> /opt/app/ss_tproxy/dnsmasq.d/accelerated-domains.china.conf
		chnlist_conf=""
		logger -t "【update_chnlist_mini】" "配置更新，完成加载 chnlist_mini 规则...."
		sed -e '/^$/d' -i /opt/app/ss_tproxy/dnsmasq.d/accelerated-domains.china.conf
		else
		logger -t "【update_chnlist_mini】" "更新错误！！！ /opt/app/ss_tproxy/rule/chnlist_mini.txt 规则为空...."
		fi
		else
		[ ! -s /opt/app/ss_tproxy/rule/chnlist_mini.txt ] && logger -t "【update_chnlist_mini】" "匹配错误！！！ /opt/app/ss_tproxy/rule/chnlist_mini.txt 规则为空...."
		logger -t "【update_chnlist_mini】" "配置匹配，完成加载 chnlist_mini 规则...."
		fi
		else
		echo "" > /opt/app/ss_tproxy/dnsmasq.d/accelerated-domains.china.conf
		fi
	fi
	nvram set gfwlist_list="gfwlist 规则 `cat /opt/app/ss_tproxy/dnsmasq.d/r.gfwlist.conf | wc -l` 行 Update:$(date "+%m-%d %H:%M")"

}

update_chnroute() {
	update_chnroute_file
	update_chnroute_ipset
	return
}

update_chnroute6() {
	update_chnroute_file "ipv6"
	update_chnroute_ipset "ipv6"
	return
}

update_chnroute_file() {
	mkdir -p /opt/app/ss_tproxy/rule
	tmp_chnroute="/opt/app/ss_tproxy/rule/tmp_chnroute.txt"
	tmp_down_file="/opt/app/ss_tproxy/rule/tmp_chnroute_tmp.txt"
	rm -f $tmp_chnroute $tmp_down_file
	if [ "$1" != "ipv6" ] ; then
	logger -t "【update_chnroute】" "开始下载更新 chnroute 文件...."
	#url='https://gcore.jsdelivr.net/gh/17mon/china_ip_list/china_ip_list.txt'
	#wgetcurl_checkmd5 $tmp_down_file "$url" "$url" N 5
	#if [ -s $tmp_down_file ] ; then
	#echo ""  >> $tmp_down_file
	#cat $tmp_down_file | grep -v '^#' | sort -u | grep -v '^$' >> $tmp_chnroute
	#fi
	#rm -f $tmp_down_file
	wgetcurl_checkmd5 $tmp_down_file "$hiboyfile/chnroute.txt" "$hiboyfile2/chnroute.txt" N 5
	if [ -s $tmp_down_file ] ; then
	echo ""  >> $tmp_down_file
	cat $tmp_down_file | grep -v '^#' | sort -u | grep -v '^$' >> $tmp_chnroute
	fi
	rm -f $tmp_down_file
	ss_sub7=`nvram get ss_sub7`
	if [ ! -z "$ss_sub7" ] ; then
		logger -t "【update_chnroute】" "正在获取 ① 大陆白名单 IP 下载地址...."
		wgetcurl_checkmd5 $tmp_down_file $ss_sub7 $ss_sub7 Y
		if [ -s $tmp_down_file ] && [ ! -z "$(cat $tmp_down_file | grep -Eo [^A-Za-z0-9+/=]+ | tr -d "\n")" ] ; then
		echo ""  >> $tmp_down_file
		cat $tmp_down_file | grep -v '^#' | sort -u | grep -v '^$' >> $tmp_chnroute
		else
		logger -t "【update_chnroute】" "错误！！！获取 ① 大陆白名单 IP 下载失败"
		fi
		rm -f $tmp_down_file
	fi
	ss_sub8=`nvram get ss_sub8`
	if [ ! -z "$ss_sub8" ] ; then
		logger -t "【update_chnroute】" "正在获取 ② 大陆白名单 IP 下载地址...."
		wgetcurl_checkmd5 $tmp_down_file $ss_sub8 $ss_sub8 Y
		if [ -s $tmp_down_file ] && [ ! -z "$(cat $tmp_down_file | grep -Eo [^A-Za-z0-9+/=]+ | tr -d "\n")" ] ; then
		echo ""  >> $tmp_down_file
		cat $tmp_down_file | grep -v '^#' | sort -u | grep -v '^$' >> $tmp_chnroute
		else
		logger -t "【update_chnroute】" "错误！！！获取 ② 大陆白名单 IP 下载失败"
		fi
		rm -f $tmp_down_file
	fi
	rm -f $tmp_down_file
	if [ ! -s $tmp_chnroute ] ; then
		tar -xzvf /etc_ro/china_ip_list.tgz -C /tmp ; cd /opt
		[ -s /tmp/china_ip_list.txt ] && logger -t "【update_chnroute】" "错误！！！下载文件为空，使用 固件内置 /etc_ro/china_ip_list.tgz 规则...." && cat /tmp/china_ip_list.txt > $tmp_chnroute
	fi
	# 添加自定义白名单
	cat $file_wanlist_ext | grep -E "^b" | cut -c3- | while read ip_addr; do echo "$ip_addr" >> $tmp_down_file; done 
	cat $tmp_chnroute | grep -v '^#' | sort -u | grep -v '^$' | grep -E -o '([0-9]+\.){3}[0-9/]+' > $file_chnroute_txt
	rm -f $tmp_chnroute
	rm -f /etc/storage/china_ip_list.txt
	ln -sf $file_chnroute_txt /etc/storage/china_ip_list.txt
	rm -f $tmp_down_file
	dos2unix $file_chnroute_txt
	logger -t "【update_chnroute】" "完成下载 chnroute 文件"
	fi
	if is_true "$ipv6" || [ "$1" == "ipv6" ] ; then
		rm -f $tmp_chnroute $tmp_down_file
		logger -t "【update_chnroute】" "开始下载更新 chnroute6 文件...."
		# wget --user-agent "$user_agent" -O- 'https://ftp.apnic.net/apnic/stats/apnic/delegated-apnic-latest' | grep CN | grep ipv6 | awk -F'|' '{printf("%s/%d\n", $4, $5)}' > $tmp_down_file
		url="$hiboyfile/chnroute6.txt"
		wgetcurl_checkmd5 $tmp_down_file "$url" "$url" N 5
		# 添加自定义白名单
		cat $file_wanlist_ext | grep -E "^~b" | cut -c4- | while read ip_addr; do echo "$ip_addr" >> $tmp_down_file; done 
		cat $tmp_down_file | grep -v '^#' | sort -u | grep -v '^$' > $file_chnroute6_txt
		rm -f $tmp_down_file
		dos2unix $file_chnroute6_txt
		logger -t "【update_chnroute】" "完成下载 chnroute6 文件"
	fi
}

update_chnroute_ipset() {
	mkdir -p /opt/app/ss_tproxy/rule
	if [ ! -s $file_chnroute_txt ] ; then
		tar -xzvf /etc_ro/china_ip_list.tgz -C /tmp ; cd /opt
		[ -s /tmp/china_ip_list.txt ] && logger -t "【update_chnroute】" "错误！！！ $file_chnroute_txt 文件为空，使用 固件内置 /etc_ro/china_ip_list.tgz 规则...." && cat /tmp/china_ip_list.txt > $file_chnroute_txt
	fi
	rm -f /etc/storage/china_ip_list.txt
	ln -sf $file_chnroute_txt /etc/storage/china_ip_list.txt
	chnroute_list="chnroute规则`ipset list chnroute -t | awk -F: '/Number/{print $2}'` 行"
	chnroute6_list="chnroute6规则`ipset list chnroute6 -t | awk -F: '/Number/{print $2}'` 行"
	if [ "$1" != "ipv6" ] ; then
	logger -t "【update_chnroute】" "开始加载 chnroute 规则...."
	if is_true "$ipv4"; then
	echo "$chnroute_list" > /opt/app/ss_tproxy/tmp/chnroute_list_Number
	update_md5_check update_chnroute_txt $file_chnroute_txt /opt/app/ss_tproxy/tmp/chnroute_list_Number
	if is_md5_not ; then
		if [ -s $file_chnroute_txt ] ; then
		ipset -! create chnroute hash:net family inet
		ipset flush chnroute &>/dev/null
		cat $file_chnroute_txt | grep -v '^#' | sort -u | grep -v '^$' | grep -E -o '([0-9]+\.){3}[0-9/]+' | sed -e "s/^/-A chnroute &/g" | ipset -! restore
		chnroute_list="chnroute规则`ipset list chnroute -t | awk -F: '/Number/{print $2}'` 行"
		nvram set chnroute_list="$chnroute_list Update:$(date "+%m-%d %H:%M")"
		echo "$chnroute_list" > /opt/app/ss_tproxy/tmp/chnroute_list_Number
		update_md5_check update_chnroute_txt $file_chnroute_txt /opt/app/ss_tproxy/tmp/chnroute_list_Number
		logger -t "【update_chnroute】" "配置更新，完成加载 chnroute 规则...."
		else
		logger -t "【update_chnroute】" "更新错误！！！ $file_chnroute_txt 规则为空...."
		fi
	else
		[ ! -s $file_chnroute_txt ] && logger -t "【update_chnroute】" "匹配错误！！！ $file_chnroute_txt 规则为空...."
		logger -t "【update_chnroute】" "配置匹配，完成加载 chnroute 规则...."
	fi
	else
	nvram set chnroute_list="$chnroute_list"
	fi
	fi
	if is_true "$ipv6" || [ "$1" == "ipv6" ] ; then
	logger -t "【update_chnroute】" "开始加载 chnroute6 规则...."
	echo "$chnroute6_list" > /opt/app/ss_tproxy/tmp/chnroute6_list_Number
	update_md5_check update_chnroute6_txt $file_chnroute6_txt /opt/app/ss_tproxy/tmp/chnroute6_list_Number
	if is_md5_not ; then
		if [ -s $file_chnroute6_txt ] ; then
		ipset -! create chnroute6 hash:net family inet6
		ipset flush chnroute6 &>/dev/null
		cat $file_chnroute6_txt | grep -v '^#' | sort -u | grep -v '^$' | sed -e "s/^/-A chnroute6 &/g" | ipset -! restore
		chnroute6_list="chnroute6规则`ipset list chnroute6 -t | awk -F: '/Number/{print $2}'` 行"
		nvram set chnroute6_list="$chnroute6_list Update:$(date "+%m-%d %H:%M")"
		echo "$chnroute6_list" > /opt/app/ss_tproxy/tmp/chnroute6_list_Number
		update_md5_check update_chnroute6_txt $file_chnroute6_txt /opt/app/ss_tproxy/tmp/chnroute6_list_Number
		logger -t "【update_chnroute】" "配置更新，完成加载 chnroute6 规则...."
		else
		logger -t "【update_chnroute】" "更新跳过！！！ $file_chnroute6_txt 规则为空...."
		fi
	else
		[ ! -s $file_chnroute6_txt ] && logger -t "【update_chnroute】" "匹配错误！！！ $file_chnroute6_txt 规则为空...."
		logger -t "【update_chnroute】" "配置匹配，完成加载 chnroute6 规则...."
	fi
	else
	nvram set chnroute6_list="$chnroute6_list"
	fi

}

update_wanlanlist_ipset() {

	for setname in $(ipset -n list | grep -i "sstp_"); do
		ipset flush $setname &>/dev/null
		#ipset destroy $setname &>/dev/null
	done

echo "create proxyaddr hash:net hashsize 64 family inet
create proxyaddr6 hash:net hashsize 64 family inet6
create chnroute hash:net hashsize 1024 family inet
create chnroute6 hash:net hashsize 1024 family inet6
create gfwlist hash:net hashsize 1024 family inet
create gfwlist6 hash:net hashsize 1024 family inet6
create adbybylist hash:net hashsize 1024 family inet
create localaddr hash:net hashsize 64 family inet
create localaddr6 hash:net hashsize 64 family inet6
create privaddr hash:net hashsize 64 family inet
create privaddr6 hash:net hashsize 64 family inet6
create sstp_dst_bp hash:net hashsize 64 family inet
create sstp_dst_bp6 hash:net hashsize 64 family inet6
create sstp_dst_fw hash:net hashsize 64 family inet
create sstp_dst_fw6 hash:net hashsize 64 family inet6
create sstp_dst_dns_fw hash:net hashsize 64 family inet
create sstp_dst_dns_fw6 hash:net hashsize 64 family inet6
create sstp_src_ac hash:net hashsize 64 family inet
create sstp_src_ac6 hash:net hashsize 64 family inet6
create sstp_src_bp hash:net hashsize 64 family inet
create sstp_src_bp6 hash:net hashsize 64 family inet6
create sstp_src_fw hash:net hashsize 64 family inet
create sstp_src_fw6 hash:net hashsize 64 family inet6
create sstp_src_gfw hash:net hashsize 64 family inet
create sstp_src_gfw6 hash:net hashsize 64 family inet6
create sstp_src_chn hash:net hashsize 64 family inet
create sstp_src_chn6 hash:net hashsize 64 family inet6
create sstp_mac_ac hash:mac hashsize 64
create sstp_mac_bp hash:mac hashsize 64
create sstp_mac_fw hash:mac hashsize 64
create sstp_mac_gfw hash:mac hashsize 64
create sstp_mac_chn hash:mac hashsize 64" | while read sstp_name; do ipset -! $sstp_name ; done 

	# Telegram IP 规则
	echo "G,8.8.8.8
G,8.8.4.4
G,208.67.222.222
G,208.67.220.220
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
" | grep -E "^G" | cut -c3- | while read ip_addr; do echo "-A $dst4_dns_fw_type $ip_addr"; done | ipset -! restore &>/dev/null
	echo "~G,2001:b28:f23d::/48
~G,2001:b28:f23f::/48
~G,2001:67c:4e8::/48
~G,2001:b28:f23c::/48
~G,2a0a:f280::/32
" | grep -E "^~G" | cut -c4- | while read ip_addr; do echo "-A $dst6_dns_fw_type $ip_addr"; done | ipset -! restore &>/dev/null


	# wanlist dst IP 规则
	if is_true "$ipv4"; then
	cat $file_wanlist_ext | grep -E "^b" | cut -c3- | while read ip_addr; do echo "-A $dst4_bp_type $ip_addr"; done | ipset -! restore &>/dev/null
	cat $file_wanlist_ext | grep -E "^g" | cut -c3- | while read ip_addr; do echo "-A $dst4_fw_type $ip_addr"; done | ipset -! restore &>/dev/null
	cat $file_wanlist_ext | grep -E "^G" | cut -c3- | while read ip_addr; do echo "-A $dst4_dns_fw_type $ip_addr"; done | ipset -! restore &>/dev/null
	fi
	if is_true "$ipv6"; then
	cat $file_wanlist_ext | grep -E "^~b" | cut -c4- | while read ip_addr; do echo "-A $dst6_bp_type $ip_addr"; done | ipset -! restore &>/dev/null
	cat $file_wanlist_ext | grep -E "^~g" | cut -c4- | while read ip_addr; do echo "-A $dst6_fw_type $ip_addr"; done | ipset -! restore &>/dev/null
	cat $file_wanlist_ext | grep -E "^~G" | cut -c4- | while read ip_addr; do echo "-A $dst6_dns_fw_type $ip_addr"; done | ipset -! restore &>/dev/null
	fi

	if [ -s /opt/app/ss_tproxy/rule/gfwlist_ip.txt ] ; then
	if is_true "$ipv4"; then
		cat /opt/app/ss_tproxy/rule/gfwlist_ip.txt | grep -v '^#' | sort -u | grep -v '^$' | grep -E -o '([0-9]+\.){3}[0-9/]+' | sed -e "s/^/-A $dst4_fw_type &/g" | ipset -! restore
	fi
	fi

	# wanlist 域名 规则
	if [ -s /opt/app/ss_tproxy/dnsmasq.d/r.gfwlist.conf ] ; then
		# 删除自定义黑名单 (黑名单不走 gfwlist)
		cat $file_wanlist_ext | grep -E "^@g" | cut -c4- > /opt/app/ss_tproxy/tmp/awk_del_list_tmp
		awk_del_list /opt/app/ss_tproxy/tmp/awk_del_list_tmp /opt/app/ss_tproxy/dnsmasq.d/r.gfwlist.conf
		cat $file_wanlist_ext | grep -E "^@G" | cut -c4- > /opt/app/ss_tproxy/tmp/awk_del_list_tmp
		awk_del_list /opt/app/ss_tproxy/tmp/awk_del_list_tmp /opt/app/ss_tproxy/dnsmasq.d/r.gfwlist.conf
		sed -e '/^$/d' -i /opt/app/ss_tproxy/dnsmasq.d/r.gfwlist.conf
	fi
	if [ "$chinadns_ng_enable" == "1" ] ; then
		# 删除自定义黑名单 (黑名单不走 gfwlist)
		cat $file_wanlist_ext | grep -E "^@g" | cut -c4- > /opt/app/ss_tproxy/rule/blacklist.txt
		cat $file_wanlist_ext | grep -E "^@G" | cut -c4- >> /opt/app/ss_tproxy/rule/blacklist.txt
		awk_del_list /opt/app/ss_tproxy/rule/blacklist.txt $file_gfwlist_txt
		cat $file_wanlist_ext | grep -E "^@b" | cut -c4- > /opt/app/ss_tproxy/rule/whitelist.txt 
		awk_del_list /opt/app/ss_tproxy/rule/whitelist.txt /opt/app/ss_tproxy/rule/blacklist.txt
		awk_del_list /opt/app/ss_tproxy/rule/whitelist.txt $file_gfwlist_txt
	fi
	if [ "$chinadns_ng_enable" != "1" ] ; then
	# 添加自定义黑名单 (黑名单改走 sstp_dst_fw sstp_dst_dns_fw)
	is_true "$ipv4" && cat $file_wanlist_ext | grep -E "^@g" | cut -c4- | awk '{printf("server=/%s/'"$dns4_fw_type"'\n", $1 )}' >> /opt/app/ss_tproxy/dnsmasq.d/r.gfwlist.conf
	is_true "$ipv6" && cat $file_wanlist_ext | grep -E "^@g" | cut -c4- | awk '{printf("server=/%s/'"$dns6_fw_type"'\n", $1 )}' >> /opt/app/ss_tproxy/dnsmasq.d/r.gfwlist.conf
	cat $file_wanlist_ext | grep -E "^@g" | cut -c4- | awk '{printf("ipset=/%s/'"$dst_fw_ipset_type"'\n", $1 )}' >> /opt/app/ss_tproxy/dnsmasq.d/r.gfwlist.conf
	is_true "$ipv4" && cat $file_wanlist_ext | grep -E "^@G" | cut -c4- | awk '{printf("server=/%s/'"$dns4_fw_type"'\n", $1 )}' >> /opt/app/ss_tproxy/dnsmasq.d/r.gfwlist.conf
	is_true "$ipv6" && cat $file_wanlist_ext | grep -E "^@G" | cut -c4- | awk '{printf("server=/%s/'"$dns6_fw_type"'\n", $1 )}' >> /opt/app/ss_tproxy/dnsmasq.d/r.gfwlist.conf
	cat $file_wanlist_ext | grep -E "^@G" | cut -c4- | awk '{printf("ipset=/%s/'"$dst_dns_fw_ipset_type"'\n", $1 )}' >> /opt/app/ss_tproxy/dnsmasq.d/r.gfwlist.conf
	fi

	# smartdns IP 规则
	if [ "$smartdns_enable" == "1" ] && [ -s /etc/storage/app_23.sh ] ; then
		touch /etc/storage/app_23.sh
		cat /etc/storage/app_23.sh | grep "^server" | grep office | grep -E -o '([0-9]+\.){3}[0-9]+' | while read ip_addr; do echo "-A $dst4_dns_fw_type $ip_addr"; done | ipset -! restore &>/dev/null
		cat /etc/storage/app_23.sh | grep "^server" | grep china  | grep -E -o '([0-9]+\.){3}[0-9]+' | while read ip_addr; do echo "-A $dst4_bp_type $ip_addr"; done | ipset -! restore &>/dev/null
	if [ "$chinadns_ng_enable" == "1" ] ; then
		cat /etc/storage/app_23.sh | grep "^server" | grep office | grep -E -o 'https://.+/' | awk -F "/" '{print $3}' | awk '{printf("%s\n", $1 )}' >> /opt/app/ss_tproxy/rule/blacklist.txt
		cat /etc/storage/app_23.sh | grep "^server" | grep china  | grep -E -o 'https://.+/' | awk -F "/" '{print $3}' | awk '{printf("%s\n", $1 )}' >> /opt/app/ss_tproxy/rule/whitelist.txt
	fi
	if [ "$chinadns_ng_enable" == "3" ] ; then
		is_true "$ipv4" && cat /etc/storage/app_23.sh | grep "^server" | grep office | grep -E -o 'https://.+/' | awk -F "/" '{print $3}' | awk '{printf("server=/%s/'"$dns4_fw_type"'\n", $1 )}' >> /opt/app/ss_tproxy/dnsmasq.d/r.gfwlist.conf
		is_true "$ipv6" && cat /etc/storage/app_23.sh | grep "^server" | grep office | grep -E -o 'https://.+/' | awk -F "/" '{print $3}' | awk '{printf("server=/%s/'"$dns6_fw_type"'\n", $1 )}' >> /opt/app/ss_tproxy/dnsmasq.d/r.gfwlist.conf
		cat /etc/storage/app_23.sh | grep "^server" | grep office | grep -E -o 'https://.+/' | awk -F "/" '{print $3}' | awk '{printf("ipset=/%s/'"$dst_dns_fw_ipset_type"'\n", $1 )}' >> /opt/app/ss_tproxy/dnsmasq.d/r.gfwlist.conf
		is_true "$ipv4" && cat /etc/storage/app_23.sh | grep "^server" | grep china  | grep -E -o 'https://.+/' | awk -F "/" '{print $3}' | awk '{printf("server=/%s/'"$dns4_bp_type"'\n", $1 )}' >> /opt/app/ss_tproxy/dnsmasq.d/r.gfwlist.conf
		is_true "$ipv6" && cat /etc/storage/app_23.sh | grep "^server" | grep china  | grep -E -o 'https://.+/' | awk -F "/" '{print $3}' | awk '{printf("server=/%s/'"$dns6_bp_type"'\n", $1 )}' >> /opt/app/ss_tproxy/dnsmasq.d/r.gfwlist.conf
		cat /etc/storage/app_23.sh | grep "^server" | grep china  | grep -E -o 'https://.+/' | awk -F "/" '{print $3}' | awk '{printf("ipset=/%s/'"$dst_bp_ipset_type"'\n", $1 )}' >> /opt/app/ss_tproxy/dnsmasq.d/r.gfwlist.conf
	fi
	fi

	# lanlist src IP 规则
	if is_true "$ipv4"; then
	cat $file_lanlist_ext | grep -E "^b" | cut -c3- | while read ip_addr; do echo "-A sstp_src_bp $ip_addr"; done | ipset -! restore &>/dev/null
	cat $file_lanlist_ext | grep -E "^g" | cut -c3- | while read ip_addr; do echo "-A sstp_src_fw $ip_addr"; done | ipset -! restore &>/dev/null
	cat $file_lanlist_ext | grep -E "^n" | cut -c3- | while read ip_addr; do echo "-A sstp_src_ac $ip_addr"; done | ipset -! restore &>/dev/null
	cat $file_lanlist_ext | grep -E "^1" | cut -c3- | while read ip_addr; do echo "-A sstp_src_chn $ip_addr"; done | ipset -! restore &>/dev/null
	cat $file_lanlist_ext | grep -E "^2" | cut -c3- | while read ip_addr; do echo "-A sstp_src_gfw $ip_addr"; done | ipset -! restore &>/dev/null
	fi
	if is_true "$ipv6"; then
	cat $file_lanlist_ext | grep -E "^~b" | cut -c4- | while read ip_addr; do echo "-A sstp_src_bp6 $ip_addr"; done | ipset -! restore &>/dev/null
	cat $file_lanlist_ext | grep -E "^~g" | cut -c4- | while read ip_addr; do echo "-A sstp_src_fw6 $ip_addr"; done | ipset -! restore &>/dev/null
	cat $file_lanlist_ext | grep -E "^~n" | cut -c4- | while read ip_addr; do echo "-A sstp_src_ac6 $ip_addr"; done | ipset -! restore &>/dev/null
	cat $file_lanlist_ext | grep -E "^~1" | cut -c4- | while read ip_addr; do echo "-A sstp_src_chn6 $ip_addr"; done | ipset -! restore &>/dev/null
	cat $file_lanlist_ext | grep -E "^~2" | cut -c4- | while read ip_addr; do echo "-A sstp_src_gfw6 $ip_addr"; done | ipset -! restore &>/dev/null
	fi

	# lanlist mac 规则
	cat $file_lanlist_ext | grep -E '^@' | cut -c2- | while read mac_c; do
	mac="${mac_c:2}"; mac=$(echo $mac | sed s/://g| sed s/：//g | tr '[a-z]' '[A-Z]'); mac="${mac:0:2}:${mac:2:2}:${mac:4:2}:${mac:6:2}:${mac:8:2}:${mac:10:2}";
	if [ ! -z "$mac" ] ; then
		case "${mac_c:0:1}" in
			n|N)
				ipset -! -A sstp_mac_ac $mac
				;;
			g|G)
				ipset -! -A sstp_mac_fw $mac
				;;
			b|B)
				ipset -! -A sstp_mac_bp $mac
				;;
			1)
				ipset -! -A sstp_mac_chn $mac
				;;
			2)
				ipset -! -A sstp_mac_gfw $mac
				;;
		esac
	fi
	done
	is_true "$ipv4" && update_lanlist_mac "iptables" "nat"
	is_true "$ipv6" && update_lanlist_mac "ip6tables" "nat"
	is_enabled_udp && is_true "$ipv4" && update_lanlist_mac "iptables" "mangle"
	is_enabled_udp && is_true "$ipv6" && update_lanlist_mac "ip6tables" "mangle"

	# adbyby host 规则
	update_cflist_ipset /tmp/adbyby_host.conf /opt/app/ss_tproxy/dnsmasq.d/r.gfwlist.conf

	update_dnsmasq_file
}

update_lanlist_mac() {

cat $file_lanlist_ext | grep -E '^@' | cut -c2- | while read mac_c; do
mac="${mac_c:2}"; mac=$(echo $mac | sed s/://g| sed s/：//g | tr '[a-z]' '[A-Z]'); mac="${mac:0:2}:${mac:2:2}:${mac:4:2}:${mac:6:2}:${mac:8:2}:${mac:10:2}";
if [ ! -z "$mac" ] ; then
	case "${mac_c:0:1}" in
		n|N)
			$1 -t $2 -I SSTP_PREROUTING -m mac --mac-source $mac -j SSTP_WAN_AC
			;;
		g|G)
			$1 -t $2 -I SSTP_PREROUTING -m mac --mac-source $mac -j SSTP_WAN_FW
			;;
		b|B)
			$1 -t $2 -I SSTP_PREROUTING -m mac --mac-source $mac -j RETURN
			;;
		1)
			$1 -t $2 -I SSTP_PREROUTING -m mac --mac-source $mac -j SSTP_WAN_CHN
			;;
		2)
			$1 -t $2 -I SSTP_PREROUTING -m mac --mac-source $mac -j SSTP_WAN_GFW
			;;
	esac
fi
done
}

update_dnsmasq_file() {
mkdir -p /tmp/ss_tproxy/dnsmasq.d
rm -rf /tmp/ss/dnsmasq.d/*
if [ "$chinadns_ng_enable" != "1" ] ; then
dnsmasq_file="$(ls -p /opt/app/ss_tproxy/dnsmasq.d | grep -v tmp | grep -v /)"
[ ! -z "$dnsmasq_file" ] && echo "$dnsmasq_file" | while read conf_file; do [ "$(cat /opt/app/ss_tproxy/dnsmasq.d/$conf_file | grep -c "server=\|ipset=")" != "0"  ] &&  ln -sf /opt/app/ss_tproxy/dnsmasq.d/$conf_file /tmp/ss_tproxy/dnsmasq.d/$conf_file ; done
fi
restart_on_dhcpd
}

update_check_file() {
	[ ! -f /opt/app/ss_tproxy/tmp/update_check_time ] && echo -n "0" > /opt/app/ss_tproxy/tmp/update_check_time
	if [ $(($(date "+1%m%d%H%M") - $(cat /opt/app/ss_tproxy/tmp/update_check_time))) -ge 70000 ] || [ ! -s /opt/app/ss_tproxy/tmp/update_check_time ] ; then
		echo "update_check_file 开始新的 update_file"
		echo -n "$(date "+1%m%d%H%M")" > /opt/app/ss_tproxy/tmp/update_check_time
		update_gfwlist
		update_chnroute
		update_chnlist
		update_wanlanlist_ipset
	else
		echo "update_check_file 间隔少于7天直接返回"
		return
	fi
}

start_dnsserver() {
	start_dnsserver_dnsproxy
	start_dnsserver_confset
	return
}

start_dnsserver_dnsproxy() {

# 尝试使用 chinadns_ng 实现 gfwliste 分流
if [ "$chinadns_ng_enable" = "0" ] || [ "$chinadns_ng_enable" = "1" ] ; then
	chinadns_ng_enable=1 && nvram set app_102=1
	if [ -z "$(chinadns_ng -h 2>&1 | grep "group-ipset")" ] ; then
		rm -f /opt/bin/chinadns_ng
		i_app_get_cmd_file -name="chinadns_ng" -cmd="chinadns_ng" -cpath="/opt/bin/chinadns_ng" -down1="$hiboyfile/chinadns_ng" -down2="$hiboyfile2/chinadns_ng" -notrestart
	fi
	if [ -z "$(chinadns_ng -h 2>&1 | grep "group-ipset")" ] ; then
		chinadns_ng_enable=2 && nvram set app_102=2
		[ "$ss_dnsproxy_x" = "2" ] && ss_dnsproxy_x=0 ; nvram set ss_dnsproxy_x=0
	fi
fi
# 自动开启第三方 DNS 程序(dnsproxy) 
if [ "$chinadns_ng_enable" = "3" ] ; then
	ss_dnsproxy_x=2 ; nvram set ss_dnsproxy_x=2
fi
if [ "$chinadns_ng_enable" == "1" ] ; then
	# 已有开启 8053 第三方 DNS 程序
	[ "$dns_start_dnsproxy" = "0" ] && chinadns_ng_8953=0 && nvram set app_1=$chinadns_ng_8953
	[ "$dns_start_dnsproxy" = "1" ] && chinadns_ng_8953=1 && nvram set app_1=$chinadns_ng_8953
	update_chinadns_ng_ipset "not_check"
	ss_dnsproxy_x=2 ; nvram set ss_dnsproxy_x=2
fi

[ ! -z "$ext_ss_dnsproxy_x" ] && ss_dnsproxy_x="$ext_ss_dnsproxy_x"
if [ "$chinadns_ng_enable" == "1" ] && [ "$ss_dnsproxy_x" = "2" ] ; then
	logger -t "【sh_ss_tproxy.sh】" "使用 chinadns_ng 实现 gfwliste 分流"
	logger -t "【sh_ss_tproxy.sh】" "自动开启 ChinaDNS-NG 防止域名污染"
	/etc/storage/script/Sh09_chinadns_ng.sh start
	return 0
fi
# 跳过自动开启第三方 DNS 程序
[ "$dns_start_dnsproxy" = "1" ] && return

if is_chnlist_mode ; then
	# 回国模式直接使用远端DNS走代理，停止使用 dnsproxy
	return
fi
if [ "$ss_dnsproxy_x" = "0" ] ; then
	i_app_get_cmd_file -name="dnsproxy" -cmd="dnsproxy" -cpath="/opt/bin/dnsproxy" -down1="$hiboyfile/dnsproxy" -down2="$hiboyfile2/dnsproxy" -notrestart
	logger -t "【sh_ss_tproxy.sh】" "启动 dnsproxy 防止域名污染"
	pidof dnsproxy >/dev/null 2>&1 && killall dnsproxy
	pidof pdnsd >/dev/null 2>&1 && killall pdnsd
	if [ -s /sbin/dnsproxy ] ; then
		/sbin/dnsproxy -d
	else
		dnsproxy -d
	fi
	[ ! -z "`pidof dnsproxy`" ] && return
	logger -t "【sh_ss_tproxy.sh】" "错误 dnsproxy 没启动！"
	ss_dnsproxy_x=1 ; nvram set ss_dnsproxy_x=1
fi
if [ "$ss_dnsproxy_x" = "1" ] ; then
i_app_get_cmd_file -name="pdnsd" -cmd="pdnsd" -cpath="/opt/bin/pdnsd" -down1="$hiboyfile/pdnsd" -down2="$hiboyfile2/pdnsd" -notrestart
logger -t "【sh_ss_tproxy.sh】" "启动 pdnsd 防止域名污染"
pidof dnsproxy >/dev/null 2>&1 && killall dnsproxy
pidof pdnsd >/dev/null 2>&1 && killall pdnsd
pdnsd_conf="/etc/storage/pdnsd.conf"
if [ ! -f "$pdnsd_conf" ] || [ ! -s "$pdnsd_conf" ] ; then
	cat > $pdnsd_conf <<-\END
global {
perm_cache=2048;
cache_dir="/var/pdnsd";
run_as="nobody";
server_port = 8053;
server_ip = 0.0.0.0;
status_ctl = on;
query_method=tcp_only;
min_ttl=1m;
max_ttl=1w;
timeout=5;
}

server {
label= "opendns";
ip = 208.67.222.222, 208.67.220.220;
port = 443;
root_server = on;
uptest= none;
}

server {
label= "google dns";
ip = 8.8.8.8, 8.8.4.4;
port = 53;
root_server = on;
uptest= none;
}

END
fi
chmod 755 $pdnsd_conf
CACHEDIR=/var/pdnsd
CACHE=$CACHEDIR/pdnsd.cache

USER=nobody
GROUP=nogroup

if ! test -f "$CACHE"; then
	mkdir -p `dirname $CACHE`
	dd if=/dev/zero of="$CACHE" bs=1 count=4 2> /dev/null
	chown -R $USER.$GROUP $CACHEDIR
fi
pdnsd -c $pdnsd_conf -p /var/run/pdnsd.pid &
[ ! -z "`pidof pdnsd`" ] && return
logger -t "【sh_ss_tproxy.sh】" "错误 pdnsd 没启动！"
ss_dnsproxy_x=2 ; nvram set ss_dnsproxy_x=2
fi
if [ "$ss_dnsproxy_x" = "2" ] ; then
	chinadns_ng_enable=3 && nvram set app_102=3
	logger -t "【sh_ss_tproxy.sh】" "使用 chinadns_ng 实现 gfwliste 分流"
	logger -t "【sh_ss_tproxy.sh】" "自动开启 ChinaDNS-NG 防止域名污染"
	/etc/storage/script/Sh09_chinadns_ng.sh start
	return 0
fi

}

start_dnsserver_confset() {
if [ "$chinadns_ng_enable" != "1" ] ; then
sed -Ei '/no-resolv|server=127.0.0.1|dns-forward-max=1000|min-cache-ttl=1800|ss_tproxy/d' /etc/storage/dnsmasq/dnsmasq.conf
sed ":a;N;s/\n\n\n/\n\n/g;ba" -i  /etc/storage/dnsmasq/dnsmasq.conf
echo "#ss_tproxy" >> /etc/storage/dnsmasq/dnsmasq.conf
if [ "$ss_pdnsd_all" = "1" ] ; then
	cat >> "/etc/storage/dnsmasq/dnsmasq.conf" <<-\EOF
no-resolv #ss_tproxy
server=127.0.0.1#8053 #ss_tproxy
EOF
fi
cat >> "/etc/storage/dnsmasq/dnsmasq.conf" <<-\EOF
dns-forward-max=1000 #ss_tproxy
min-cache-ttl=1800 #ss_tproxy
EOF
if is_chnlist_mode; then
	# 回国模式直接使用远端DNS走代理，停止使用 dnsproxy
	sed -Ei "/server=127.0.0.1#8053/d" /etc/storage/dnsmasq/dnsmasq.conf
#	echo "#server=127.0.0.1#8053 #ss_tproxy" >> /etc/storage/dnsmasq/dnsmasq.conf
	echo "server=${dns_remote:=8.8.8.8#53} #ss_tproxy" >> /etc/storage/dnsmasq/dnsmasq.conf
fi
is_true "$ipv6" && echo "server=${dns_remote6:=2001:4860:4860::8888#53} #ss_tproxy" >> /etc/storage/dnsmasq/dnsmasq.conf
fi
sed -Ei "/conf-dir=\/tmp\/ss\/dnsmasq.d/d" /etc/storage/dnsmasq/dnsmasq.conf
sed -Ei "/conf-dir=\/opt\/app\/ss_tproxy\/dnsmasq.d/d" /etc/storage/dnsmasq/dnsmasq.conf
sed -Ei "/conf-dir=\/tmp\/ss_tproxy\/dnsmasq.d/d" /etc/storage/dnsmasq/dnsmasq.conf
mkdir -p $dnsmasq_conf_dir
echo "$(for conf_dir_arg in $dnsmasq_conf_dir; do [ -d $conf_dir_arg ] && echo "conf-dir=$conf_dir_arg #ss_tproxy"; done)" >> /etc/storage/dnsmasq/dnsmasq.conf
echo "$(for conf_file_arg in $dnsmasq_conf_file; do [ -s $conf_file_arg ] && echo "conf-file=$conf_file_arg #ss_tproxy"; done)" >> /etc/storage/dnsmasq/dnsmasq.conf
while read dnsmasq_string_arg; do
	if [ ! -z "$dnsmasq_string_arg" ] ; then
		echo "$dnsmasq_string_arg #ss_tproxy" >> /etc/storage/dnsmasq/dnsmasq.conf
	fi
done < $dnsmasq_conf_string
update_dnsmasq_file
}

stop_dnsserver() {
sed -Ei '/no-resolv|server=127.0.0.1|dns-forward-max=1000|min-cache-ttl=1800|ss_tproxy/d' /etc/storage/dnsmasq/dnsmasq.conf
sed ":a;N;s/\n\n\n/\n\n/g;ba" -i  /etc/storage/dnsmasq/dnsmasq.conf
sed -Ei "/conf-dir=\/opt\/app\/ss_tproxy\/dnsmasq.d/d" /etc/storage/dnsmasq/dnsmasq.conf
update_md5_check stop_dnsserver_restart_dhcpd /etc/storage/dnsmasq/dnsmasq.conf
if is_md5_not ; then
update_dnsmasq_file
fi
killall pdnsd dnsproxy
if [ "$chinadns_ng_enable" = "1" ] ; then
	chinadns_ng_enable=0 && nvram set app_102=0
	/etc/storage/script/Sh09_chinadns_ng.sh stop
fi
#	kill -9 $status_dnsmasq_pid  &>/dev/null
#	kill -9 $status_chinadns_pid &>/dev/null
#	kill -9 $status_dns2tcp4_pid &>/dev/null
#	kill -9 $status_dns2tcp6_pid &>/dev/null
#	delete_pidfile
}

flush_dnscache() {
	! ss_tproxy_is_started && return
#    kill -HUP "$status_dnsmasq_pid"
}

modify_resolvconf() {
	return
	if is_false "$opts_overwrite_resolv"; then
		while umount /etc/resolv.conf &>/dev/null; do true; done
		temp_resolv_conf="/opt/app/ss_tproxy/resolv.conf"
		touch $temp_resolv_conf
		chmod 0644 $temp_resolv_conf
		umount /etc/resolv.conf
		mount -o bind $temp_resolv_conf /etc/resolv.conf
		#rm -f $temp_resolv_conf
	fi
	echo "# Generated by ss-tproxy at $(date '+%F %T')" >/etc/resolv.conf
	is_true "$ipv4" && echo "nameserver 127.0.0.1" >>/etc/resolv.conf
	is_true "$ipv6" && echo "nameserver ::1" >>/etc/resolv.conf
	is_true "$ipv4" && DNS_china=`nvram get wan0_dns |cut -d ' ' -f1`
	is_true "$ipv4" && [ ! -z "$DNS_china" ] && echo "nameserver $DNS_china" >>/etc/resolv.conf
	is_true "$ipv6" && DNS6_china=`nvram get wan0_dns6 |cut -d ' ' -f1`
	is_true "$ipv6" && [ ! -z "$DNS6_china" ] && echo "nameserver $DNS6_china" >>/etc/resolv.conf
}

restore_resolvconf() {
	return
	if is_false "$opts_overwrite_resolv"; then
		while umount /etc/resolv.conf &>/dev/null; do true; done
	else
		echo "# Generated by ss-tproxy at $(date '+%F %T')" >/etc/resolv.conf
		is_true "$ipv4" && echo "nameserver $dns_direct" >>/etc/resolv.conf
		is_true "$ipv6" && echo "nameserver $dns_direct6" >>/etc/resolv.conf
	fi
}

start_proxy_proc() {
	eval "$proxy_startcmd" || log_error "failed to start local proxy process, exit-code: $?"
}

stop_proxy_proc() {
	eval "$proxy_stopcmd" &>/dev/null
}

enable_ipforward() {
	is_true "$ipv4" && set_sysctl_option 'net.ipv4.ip_forward' 1
	is_true "$ipv6" && set_sysctl_option 'net.ipv6.conf.all.forwarding' 1
}

disable_icmpredir() {
	for dir in /proc/sys/net/ipv4/conf/* ; do
		dir="$(basename "$dir")"
		set_sysctl_option "net.ipv4.conf.${dir//.//}.send_redirects" 0
	done
}

delete_gfwlist() {
	ss_tproxy_is_started && return
	is_true "$ipv4" && ipset -X gfwlist  &>/dev/null
	is_true "$ipv6" && ipset -X gfwlist6 &>/dev/null
}

delete_chnroute() {
	ipset -X localaddr  &>/dev/null
	ipset -X localaddr6 &>/dev/null
	ipset -X privaddr  &>/dev/null
	ipset -X privaddr6 &>/dev/null
	ipset -X chnroute  &>/dev/null
	ipset -X chnroute6 &>/dev/null
}

delete_iproute2() {
	is_true "$ipv4" && {
		ip -4 rule  del   table $ipts_rt_tab
		ip -4 route flush table $ipts_rt_tab
	} &>/dev/null

	is_true "$ipv6" && {
		ip -6 rule  del   table $ipts_rt_tab
		ip -6 route flush table $ipts_rt_tab
	} &>/dev/null
}

_flush_iptables() {
	$1 -t mangle -D PREROUTING  -j SSTP_PREROUTING  &>/dev/null
	$1 -t mangle -D OUTPUT      -j SSTP_OUTPUT      &>/dev/null
	$1 -t nat    -D PREROUTING  -j SSTP_PREROUTING  &>/dev/null
	$1 -t nat    -D OUTPUT      -j SSTP_OUTPUT      &>/dev/null
	$1 -t nat    -D POSTROUTING -j SSTP_POSTROUTING &>/dev/null

	$1 -t mangle -F SSTP_PREROUTING  &>/dev/null
	$1 -t mangle -X SSTP_PREROUTING  &>/dev/null
	$1 -t mangle -F SSTP_OUTPUT      &>/dev/null
	$1 -t mangle -X SSTP_OUTPUT      &>/dev/null
	$1 -t nat    -F SSTP_PREROUTING  &>/dev/null
	$1 -t nat    -X SSTP_PREROUTING  &>/dev/null
	$1 -t nat    -F SSTP_OUTPUT      &>/dev/null
	$1 -t nat    -X SSTP_OUTPUT      &>/dev/null
	$1 -t nat    -F SSTP_POSTROUTING &>/dev/null
	$1 -t nat    -X SSTP_POSTROUTING &>/dev/null

	$1 -t mangle -F SSTP_RULE &>/dev/null
	$1 -t mangle -X SSTP_RULE &>/dev/null
	$1 -t nat    -F SSTP_RULE &>/dev/null
	$1 -t nat    -X SSTP_RULE &>/dev/null

	$1 -t mangle -F SSTP_LAN_AC  &>/dev/null
	$1 -t mangle -X SSTP_LAN_AC  &>/dev/null
	$1 -t mangle -F SSTP_WAN_AC  &>/dev/null
	$1 -t mangle -X SSTP_WAN_AC  &>/dev/null
	$1 -t mangle -F SSTP_GFW_CHN &>/dev/null
	$1 -t mangle -X SSTP_GFW_CHN &>/dev/null
	$1 -t mangle -F SSTP_WAN_GFW &>/dev/null
	$1 -t mangle -X SSTP_WAN_GFW &>/dev/null
	$1 -t mangle -F SSTP_WAN_CHN &>/dev/null
	$1 -t mangle -X SSTP_WAN_CHN &>/dev/null
	$1 -t mangle -F SSTP_WAN_FW  &>/dev/null
	$1 -t mangle -X SSTP_WAN_FW  &>/dev/null
	$1 -t mangle -F SSTP_WAN_DNS  &>/dev/null
	$1 -t mangle -X SSTP_WAN_DNS  &>/dev/null
	$1 -t nat    -F SSTP_LAN_AC  &>/dev/null
	$1 -t nat    -X SSTP_LAN_AC  &>/dev/null
	$1 -t nat    -F SSTP_WAN_AC  &>/dev/null
	$1 -t nat    -X SSTP_WAN_AC  &>/dev/null
	$1 -t nat    -F SSTP_GFW_CHN &>/dev/null
	$1 -t nat    -X SSTP_GFW_CHN &>/dev/null
	$1 -t nat    -F SSTP_WAN_GFW &>/dev/null
	$1 -t nat    -X SSTP_WAN_GFW &>/dev/null
	$1 -t nat    -F SSTP_WAN_CHN &>/dev/null
	$1 -t nat    -X SSTP_WAN_CHN &>/dev/null
	$1 -t nat    -F SSTP_WAN_FW  &>/dev/null
	$1 -t nat    -X SSTP_WAN_FW  &>/dev/null
	$1 -t nat    -F SSTP_WAN_DNS  &>/dev/null
	$1 -t nat    -X SSTP_WAN_DNS  &>/dev/null
}

flush_iptables() {
	is_true "$ipv4" && _flush_iptables "iptables"
	is_true "$ipv6" && _flush_iptables "ip6tables"
	[ ! -z "$(ip6tables -vnL INPUT --line-numbers | grep -Ei "udp *dpt:53 *reject")" ] && ip6tables -D INPUT -p udp --dport 53 -j REJECT
}

_show_iptables() {
	echo "$(color_green "==> $1-mangle <==")"
	$1 -t mangle -nvL --line-numbers
	echo
	echo "$(color_green "==> $1-nat <==")"
	$1 -t nat -nvL --line-numbers
}

show_iptables() {
	is_true "$ipv4" && _show_iptables "iptables"
	{ is_true "$ipv4" && is_true "$ipv6"; } && echo
	is_true "$ipv6" && _show_iptables "ip6tables"
}

check_dnsredir() {
	is_false "$ipts_reddns_onstop" && return

	is_ipv4_ipts $1 && direct_dns_ip="$dns_direct" || direct_dns_ip="$dns_direct6"
	[ ! -z "$ipts_reddns_ip" ] && is_ipv4_ipts $1 && direct_dns_ip="$ipts_reddns_ip"

	$1 -t nat -N SSTP_PREROUTING  &>/dev/null
	$1 -t nat -A SSTP_PREROUTING  -m set ! --match-set $localaddr_setname src -p udp --dport 53 -j DNAT --to-destination $direct_dns_ip
	$1 -t nat -N SSTP_POSTROUTING &>/dev/null
	$1 -t nat -A SSTP_POSTROUTING -m set ! --match-set $localaddr_setname src -p udp -d $direct_dns_ip --dport 53 -j MASQUERADE &>/dev/null
}

check_startdnsredir() {
	is_false "$ipts_reddns_onstart" && return

	is_ipv4_ipts $1 && direct_dns_ip="${dns4_fw_type%%#*}" || direct_dns_ip="${dns6_fw_type%%#*}"
	[ ! -z "$ipts_reddns_ip" ] && is_ipv4_ipts $1 && direct_dns_ip="$ipts_reddns_ip"

	$1 -t nat -N SSTP_PREROUTING  &>/dev/null
	$1 -t nat -I SSTP_PREROUTING  -m set ! --match-set $localaddr_setname src -p udp --dport 53 -j DNAT --to-destination $direct_dns_ip
	$1 -t nat -N SSTP_POSTROUTING &>/dev/null
	$1 -t nat -A SSTP_POSTROUTING -m set ! --match-set $localaddr_setname src -p udp -d $direct_dns_ip --dport 53 -j MASQUERADE &>/dev/null
}

check_snatrule() {
	set_snat_rule='false'
	{ is_ipv4_ipts $1 && is_true "$ipts_set_snat";  } && set_snat_rule='true'
	{ is_ipv6_ipts $1 && is_true "$ipts_set_snat6"; } && set_snat_rule='true'
	is_false "$set_snat_rule" && return

	$1 -t nat -N SSTP_POSTROUTING &>/dev/null
	$1 -t nat -A SSTP_POSTROUTING -m set ! --match-set $localaddr_setname src -m conntrack --ctstate SNAT,DNAT   -j RETURN
	$1 -t nat -A SSTP_POSTROUTING -m set ! --match-set $localaddr_setname src -p tcp --syn                       -j MASQUERADE
	$1 -t nat -A SSTP_POSTROUTING -m set ! --match-set $localaddr_setname src -p udp -m conntrack --ctstate NEW  -j MASQUERADE
	$1 -t nat -A SSTP_POSTROUTING -m set ! --match-set $localaddr_setname src -p icmp -m conntrack --ctstate NEW -j MASQUERADE
}

check_iptschain() {
	$1 -t nat -nL SSTP_PREROUTING  &>/dev/null && $1 -t nat -A PREROUTING  -j SSTP_PREROUTING
	$1 -t nat -nL SSTP_POSTROUTING &>/dev/null && $1 -t nat -I POSTROUTING -j SSTP_POSTROUTING
}

check_postrule() {
	ss_tproxy_is_started && return
	{ is_false "$ipts_reddns_onstop" && is_false "$ipts_set_snat" && is_false "$ipts_set_snat6"; } && return
	is_true "$ipv4" && { check_dnsredir "iptables";  check_snatrule "iptables";  check_iptschain "iptables";  }
	is_true "$ipv6" && { check_dnsredir "ip6tables"; check_snatrule "ip6tables"; check_iptschain "ip6tables"; }
}

_flush_postrule() {
	$1 -t nat -D PREROUTING  -j SSTP_PREROUTING  &>/dev/null
	$1 -t nat -D POSTROUTING -j SSTP_POSTROUTING &>/dev/null
	$1 -t nat -F SSTP_PREROUTING  &>/dev/null
	$1 -t nat -X SSTP_PREROUTING  &>/dev/null
	$1 -t nat -F SSTP_POSTROUTING &>/dev/null
	$1 -t nat -X SSTP_POSTROUTING &>/dev/null
}

flush_postrule() {
	ss_tproxy_is_started && return
	is_true "$ipv4" && _flush_postrule "iptables"
	is_true "$ipv6" && _flush_postrule "ip6tables"
}

_delete_unused_iptchains() {
	if is_empty_iptschain $1 mangle SSTP_PREROUTING; then
		$1 -t mangle -D PREROUTING -j SSTP_PREROUTING
		$1 -t mangle -X SSTP_PREROUTING
	fi
	if is_empty_iptschain $1 mangle SSTP_OUTPUT; then
		$1 -t mangle -D OUTPUT -j SSTP_OUTPUT
		$1 -t mangle -X SSTP_OUTPUT
	fi
	if is_empty_iptschain $1 nat SSTP_PREROUTING; then
		$1 -t nat -D PREROUTING -j SSTP_PREROUTING
		$1 -t nat -X SSTP_PREROUTING
	fi
	if is_empty_iptschain $1 nat SSTP_OUTPUT; then
		$1 -t nat -D OUTPUT -j SSTP_OUTPUT
		$1 -t nat -X SSTP_OUTPUT
	fi
	if is_empty_iptschain $1 nat SSTP_POSTROUTING; then
		$1 -t nat -D POSTROUTING -j SSTP_POSTROUTING
		$1 -t nat -X SSTP_POSTROUTING
	fi
}

delete_unused_iptchains() {
	is_true "$ipv4" && _delete_unused_iptchains "iptables"
	is_true "$ipv6" && _delete_unused_iptchains "ip6tables"
}

start_iptables_pre_rules() {
	$1 -t mangle -N SSTP_PREROUTING
	$1 -t mangle -N SSTP_OUTPUT
	$1 -t nat    -N SSTP_PREROUTING
	$1 -t nat    -N SSTP_OUTPUT
	$1 -t nat    -N SSTP_POSTROUTING

	if is_need_iproute; then
		is_ipv4_ipts $1 && iproute2_family="-4" || iproute2_family="-6"
		ip $iproute2_family route add local default dev $ipts_if_lo table $ipts_rt_tab
		ip $iproute2_family rule  add fwmark $ipts_rt_mark          table $ipts_rt_tab
	fi
}

start_iptables_post_rules() {
	$1 -t mangle -I PREROUTING  $wifidogn_manglex -j SSTP_PREROUTING
	$1 -t mangle -A OUTPUT      -j SSTP_OUTPUT
	$1 -t nat    -I PREROUTING  $wifidognx -j SSTP_PREROUTING
	$1 -t nat    -I OUTPUT      $wifidognx_output -j SSTP_OUTPUT
	$1 -t nat    -I POSTROUTING -j SSTP_POSTROUTING
}

start_iptables_tproxy_mode() {
	is_ipv4_ipts $1 && loopback_addr="127.0.0.1" || loopback_addr="::1"

	is_ipv4_ipts $1 && lan_ipaddr="$lan_ipv4_ipaddr" || lan_ipaddr="$lan_ipv6_ipaddr"

	is_ipv4_ipts $1 && gfwlist_setname="gfwlist" || gfwlist_setname="gfwlist6"

	is_ipv4_ipts $1 && gfwlist_setfamily="inet" || gfwlist_setfamily="inet6"

	is_ipv4_ipts $1 && grep_pattern="^-" || grep_pattern="^~"

	is_ipv4_ipts $1 && proxyaddr_setname="proxyaddr" || proxyaddr_setname="proxyaddr6"

	is_ipv4_ipts $1 && direct_dns_ip="$dns_direct" || direct_dns_ip="$dns_direct6"

	is_ipv4_ipts $1 && remote_dns_ip="${dns_remote%%#*}" || remote_dns_ip="${dns_remote6%%#*}"
	is_ipv4_ipts $1 && remote_dns_port="${dns_remote##*#}" || remote_dns_port="${dns_remote6##*#}"

	is_ipv4_ipts $1 && chnroute_setname="chnroute" || chnroute_setname="chnroute6"

	is_ipv4_ipts $1 && privaddr_setname="privaddr" || privaddr_setname="privaddr6"

	is_ipv4_ipts $1 && localaddr_setname="localaddr" || localaddr_setname="localaddr6"

	ipset -! -N $localaddr_setname hash:net hashsize 64 family $gfwlist_setfamily
	ipset -! -N $privaddr_setname hash:net hashsize 64 family $gfwlist_setfamily
	ipset -! -N $chnroute_setname hash:net family $gfwlist_setfamily &>/dev/null
	ipset -! -N $gfwlist_setname hash:net family $gfwlist_setfamily &>/dev/null
	cat $file_gfwlist_ext | grep -E "$grep_pattern" | cut -c2- | while read ip_addr; do echo "-A $gfwlist_setname $ip_addr"; done | ipset -! restore &>/dev/null

	# src 规则
	is_ipv4_ipts $1 && sstp_src_ac_setname="sstp_src_ac" || sstp_src_ac_setname="sstp_src_ac6"

	is_ipv4_ipts $1 && sstp_src_bp_setname="sstp_src_bp" || sstp_src_bp_setname="sstp_src_bp6"

	is_ipv4_ipts $1 && sstp_src_fw_setname="sstp_src_fw" || sstp_src_fw_setname="sstp_src_fw6"

	is_ipv4_ipts $1 && sstp_src_gfw_setname="sstp_src_gfw" || sstp_src_gfw_setname="sstp_src_gfw6"

	is_ipv4_ipts $1 && sstp_src_chn_setname="sstp_src_chn" || sstp_src_chn_setname="sstp_src_chn6"

	
	#ipset -X $sstp_src_bp_setname &>/dev/null
	ipset -! -N $sstp_src_bp_setname hash:net hashsize 64 family $gfwlist_setfamily &>/dev/null
	#ipset -X $sstp_src_fw_setname &>/dev/null
	ipset -! -N $sstp_src_fw_setname hash:net hashsize 64 family $gfwlist_setfamily &>/dev/null
	#ipset -X $sstp_src_ac_setname &>/dev/null
	ipset -! -N $sstp_src_ac_setname hash:net hashsize 64 family $gfwlist_setfamily &>/dev/null
	#ipset -X $sstp_src_chn_setname &>/dev/null
	ipset -! -N $sstp_src_chn_setname hash:net hashsize 64 family $gfwlist_setfamily &>/dev/null
	#ipset -X $sstp_src_gfw_setname &>/dev/null
	ipset -! -N $sstp_src_gfw_setname hash:net hashsize 64 family $gfwlist_setfamily &>/dev/null

	# dst 规则
	is_ipv4_ipts $1 && sstp_dst_bp_setname="sstp_dst_bp" || sstp_dst_bp_setname="sstp_dst_bp6"

	is_ipv4_ipts $1 && sstp_dst_fw_setname="sstp_dst_fw" || sstp_dst_fw_setname="sstp_dst_fw6"

	is_ipv4_ipts $1 && sstp_dst_dns_fw_setname="sstp_dst_dns_fw" || sstp_dst_dns_fw_setname="sstp_dst_dns_fw6"

	#ipset -X $sstp_dst_bp_setname &>/dev/null
	ipset -! -N $sstp_dst_bp_setname hash:net hashsize 64 family $gfwlist_setfamily &>/dev/null
	#ipset -X $sstp_dst_fw_setname &>/dev/null
	ipset -! -N $sstp_dst_fw_setname hash:net hashsize 64 family $gfwlist_setfamily &>/dev/null
	#ipset -X $sstp_dst_dns_fw_setname &>/dev/null
	ipset -! -N $sstp_dst_dns_fw_setname hash:net hashsize 64 family $gfwlist_setfamily &>/dev/null

	######################### SSTP_RULE (tcp and udp) #########################

	$1 -t mangle -N SSTP_RULE
	$1 -t mangle -N SSTP_LAN_AC
	$1 -t mangle -N SSTP_WAN_AC
	$1 -t mangle -N SSTP_WAN_CHN
	$1 -t mangle -N SSTP_WAN_GFW
	$1 -t mangle -N SSTP_GFW_CHN
	$1 -t mangle -N SSTP_WAN_FW
	$1 -t mangle -N SSTP_WAN_DNS

	$1 -t mangle -A SSTP_RULE -j CONNMARK --restore-mark
	$1 -t mangle -A SSTP_RULE -m mark --mark $ipts_rt_mark -j RETURN
	$1 -t mangle -A SSTP_RULE -m mark --mark 0xff -j RETURN
	$1 -t mangle -A SSTP_RULE -m set --match-set $privaddr_setname dst -j RETURN

	$1 -t mangle -A SSTP_RULE -p tcp -m set --match-set $proxyaddr_setname dst -m multiport --dports $proxy_svrport -j RETURN
	is_enabled_udp && $1 -t mangle -A SSTP_RULE -p udp -m set --match-set $proxyaddr_setname dst -m multiport --dports $proxy_svrport -j RETURN

	if is_enabled_udp; then
		$1 -t mangle -A SSTP_RULE -p udp -d $direct_dns_ip --dport 53               -j RETURN
		$1 -t mangle -A SSTP_RULE -p udp -d $remote_dns_ip --dport $remote_dns_port -j MARK --set-mark $ipts_rt_mark
		$1 -t mangle -A SSTP_RULE -p udp -d $remote_dns_ip --dport $remote_dns_port -j RETURN
	else
		$1 -t mangle -A SSTP_RULE -p tcp -d $remote_dns_ip --dport $remote_dns_port -j MARK --set-mark $ipts_rt_mark
		$1 -t mangle -A SSTP_RULE -p tcp -d $remote_dns_ip --dport $remote_dns_port -j RETURN
	fi

	$1 -t mangle -A SSTP_RULE -j SSTP_LAN_AC
	$1 -t mangle -A SSTP_LAN_AC -m set --match-set sstp_mac_bp src -j RETURN
	$1 -t mangle -A SSTP_LAN_AC -m set --match-set sstp_mac_fw src -j SSTP_WAN_FW
	$1 -t mangle -A SSTP_LAN_AC -m set --match-set sstp_mac_ac src -j SSTP_WAN_AC
	$1 -t mangle -A SSTP_LAN_AC -m set --match-set sstp_mac_gfw src -j SSTP_WAN_GFW
	$1 -t mangle -A SSTP_LAN_AC -m set --match-set sstp_mac_chn src -j SSTP_WAN_CHN
	$1 -t mangle -A SSTP_LAN_AC -m set --match-set $sstp_src_bp_setname src -j RETURN
	$1 -t mangle -A SSTP_LAN_AC -m set --match-set $sstp_src_fw_setname src -j SSTP_WAN_FW
	$1 -t mangle -A SSTP_LAN_AC -m set --match-set $sstp_src_ac_setname src -j SSTP_WAN_AC
	$1 -t mangle -A SSTP_LAN_AC -m set --match-set $sstp_src_gfw_setname src -j SSTP_WAN_GFW
	$1 -t mangle -A SSTP_LAN_AC -m set --match-set $sstp_src_chn_setname src -j SSTP_WAN_CHN
	if [ "$LAN_AC_IP" == "2" ] ; then
	$1 -t mangle -A SSTP_LAN_AC -m set ! --match-set $localaddr_setname src -j RETURN
	$1 -t mangle -A SSTP_LAN_AC -m set --match-set $localaddr_setname src -j SSTP_WAN_AC
	else
	$1 -t mangle -A SSTP_LAN_AC -j ${LAN_TARGET:=SSTP_WAN_AC}
	fi
	$1 -t mangle -A SSTP_WAN_AC -j ${MODE_TARGET:=RETURN}
	$1 -t mangle -A SSTP_GFW_CHN -j SSTP_WAN_GFW
	$1 -t mangle -A SSTP_GFW_CHN -j SSTP_WAN_CHN
	$1 -t mangle -A SSTP_GFW_CHN -j RETURN
	is_enabled_udp && [ "$ss_all_udp" == "1" ] && $1 -t mangle -A SSTP_WAN_GFW -p udp -j SSTP_WAN_FW
	$1 -t mangle -A SSTP_WAN_GFW -m set --match-set $sstp_dst_dns_fw_setname dst -j SSTP_WAN_DNS
	$1 -t mangle -A SSTP_WAN_GFW -m set --match-set $sstp_dst_fw_setname dst -j SSTP_WAN_FW
	$1 -t mangle -A SSTP_WAN_GFW -m set --match-set $sstp_dst_bp_setname dst -j RETURN
	$1 -t mangle -A SSTP_WAN_GFW -m set --match-set $gfwlist_setname dst -j ${GFWLIST_TARGET:=SSTP_WAN_FW}
	$1 -t mangle -A SSTP_WAN_GFW -j RETURN
	is_enabled_udp && [ "$ss_all_udp" == "1" ] && $1 -t mangle -A SSTP_WAN_CHN -p udp -j SSTP_WAN_FW
	$1 -t mangle -A SSTP_WAN_CHN -m set --match-set $sstp_dst_dns_fw_setname dst -j SSTP_WAN_DNS
	$1 -t mangle -A SSTP_WAN_CHN -m set --match-set $sstp_dst_fw_setname dst -j SSTP_WAN_FW
	$1 -t mangle -A SSTP_WAN_CHN -m set --match-set $sstp_dst_bp_setname dst -j RETURN
	$1 -t mangle -A SSTP_WAN_CHN -m set --match-set $chnroute_setname dst -j ${CHN_TARGET:=RETURN}
	$1 -t mangle -A SSTP_WAN_CHN -j ${CHN_WAN_TARGET:=SSTP_WAN_FW}
	$1 -t mangle -A SSTP_WAN_FW -p tcp -m multiport --dports $ipts_proxy_dst_port_tcp --syn -j MARK --set-mark $ipts_rt_mark
	is_enabled_udp && $1 -t mangle -A SSTP_WAN_FW -p udp -m multiport --dports $ipts_proxy_dst_port_udp -m conntrack --ctstate NEW -j MARK --set-mark $ipts_rt_mark

	$1 -t mangle -A SSTP_WAN_FW -m set --match-set $sstp_dst_dns_fw_setname dst -j SSTP_WAN_DNS
	$1 -t mangle -A SSTP_WAN_DNS -p tcp -m multiport --dports 1:65535 --syn -j MARK --set-mark $ipts_rt_mark
	is_enabled_udp && $1 -t mangle -A SSTP_WAN_DNS -p udp -m multiport --dports 1:65535 -m conntrack --ctstate NEW -j MARK --set-mark $ipts_rt_mark

	$1 -t mangle -A SSTP_RULE -j CONNMARK --save-mark

	######################### SSTP_OUTPUT/SSTP_PREROUTING #########################

	if is_usrgrp_mode; then
		$1 -t mangle -I SSTP_OUTPUT -m owner $(get_usrgrp_args) -j RETURN
	fi

	if is_nonstd_dnsport "$dnsmasq_bind_port"; then
		if [ "$lan_ipaddr" != "$loopback_addr" ] ; then
			$1 -t nat -A SSTP_OUTPUT -p udp -d $lan_ipaddr --dport 53 -j REDIRECT --to-ports $dnsmasq_bind_port
		else
			$1 -t nat -A SSTP_OUTPUT -p udp -d $loopback_addr --dport 53 -j REDIRECT --to-ports $dnsmasq_bind_port
		fi
	fi

	$1 -t mangle -A SSTP_OUTPUT -m set --match-set $localaddr_setname src -m set ! --match-set $localaddr_setname dst -p tcp -j SSTP_RULE
	is_enabled_udp && $1 -t mangle -A SSTP_OUTPUT -m set --match-set $localaddr_setname src -m set ! --match-set $localaddr_setname dst -p udp -j SSTP_RULE

	$1 -t mangle -A SSTP_PREROUTING -i $ipts_if_lo -m mark ! --mark $ipts_rt_mark -j RETURN

	if is_false "$selfonly"; then
		if is_nonstd_dnsport "$dnsmasq_bind_port"; then
			is_enabled_udp && $1 -t mangle -A SSTP_PREROUTING -m set ! --match-set $localaddr_setname src -m set --match-set $localaddr_setname dst -p udp --dport 53 -j RETURN
			$1 -t nat -A SSTP_PREROUTING -m set ! --match-set $localaddr_setname src -m set --match-set $localaddr_setname dst -p udp --dport 53 -j REDIRECT --to-ports $dnsmasq_bind_port
		fi

		$1 -t mangle -A SSTP_PREROUTING -m set ! --match-set $localaddr_setname src -m set ! --match-set $localaddr_setname dst -p tcp -j SSTP_RULE
		is_enabled_udp && $1 -t mangle -A SSTP_PREROUTING -m set ! --match-set $localaddr_setname src -m set ! --match-set $localaddr_setname dst -p udp -j SSTP_RULE
	fi

	if [ "$lan_ipaddr" != "$loopback_addr" ] ; then
		$1 -t mangle -A SSTP_PREROUTING -p tcp -m mark --mark $ipts_rt_mark -j TPROXY --on-ip $lan_ipaddr --on-port $proxy_tcpport
		is_enabled_udp && $1 -t mangle -A SSTP_PREROUTING -p udp -m mark --mark $ipts_rt_mark -j TPROXY --on-ip $lan_ipaddr --on-port $proxy_udpport
	else
		$1 -t mangle -A SSTP_PREROUTING -p tcp -m mark --mark $ipts_rt_mark -j TPROXY --on-ip $loopback_addr --on-port $proxy_tcpport
		is_enabled_udp && $1 -t mangle -A SSTP_PREROUTING -p udp -m mark --mark $ipts_rt_mark -j TPROXY --on-ip $loopback_addr --on-port $proxy_udpport
	fi

	check_snatrule $1
}

start_iptables_redirect_mode() {
	is_ipv4_ipts $1 && loopback_addr="127.0.0.1" || loopback_addr="::1"
	
	is_ipv4_ipts $1 && lan_ipaddr="$lan_ipv4_ipaddr" || lan_ipaddr="$lan_ipv6_ipaddr"
	
	is_ipv4_ipts $1 && gfwlist_setname="gfwlist" || gfwlist_setname="gfwlist6"

	is_ipv4_ipts $1 && gfwlist_setfamily="inet" || gfwlist_setfamily="inet6"

	is_ipv4_ipts $1 && grep_pattern="^-" || grep_pattern="^~"

	is_ipv4_ipts $1 && proxyaddr_setname="proxyaddr" || proxyaddr_setname="proxyaddr6"

	is_ipv4_ipts $1 && direct_dns_ip="$dns_direct" || direct_dns_ip="$dns_direct6"

	is_ipv4_ipts $1 && remote_dns_ip="${dns_remote%%#*}" || remote_dns_ip="${dns_remote6%%#*}"
	is_ipv4_ipts $1 && remote_dns_port="${dns_remote##*#}" || remote_dns_port="${dns_remote6##*#}"

	is_ipv4_ipts $1 && chnroute_setname="chnroute" || chnroute_setname="chnroute6"

	is_ipv4_ipts $1 && privaddr_setname="privaddr" || privaddr_setname="privaddr6"

	is_ipv4_ipts $1 && localaddr_setname="localaddr" || localaddr_setname="localaddr6"

	ipset -! -N $localaddr_setname hash:net hashsize 64 family $gfwlist_setfamily
	ipset -! -N $privaddr_setname hash:net hashsize 64 family $gfwlist_setfamily
	ipset -! -N $chnroute_setname hash:net family $gfwlist_setfamily &>/dev/null
	ipset -! -N $gfwlist_setname hash:net family $gfwlist_setfamily &>/dev/null
	cat $file_gfwlist_ext | grep -E "$grep_pattern" | cut -c2- | while read ip_addr; do echo "-A $gfwlist_setname $ip_addr"; done | ipset -! restore &>/dev/null

	# src 规则
	is_ipv4_ipts $1 && sstp_src_ac_setname="sstp_src_ac" || sstp_src_ac_setname="sstp_src_ac6"

	is_ipv4_ipts $1 && sstp_src_bp_setname="sstp_src_bp" || sstp_src_bp_setname="sstp_src_bp6"

	is_ipv4_ipts $1 && sstp_src_fw_setname="sstp_src_fw" || sstp_src_fw_setname="sstp_src_fw6"

	is_ipv4_ipts $1 && sstp_src_gfw_setname="sstp_src_gfw" || sstp_src_gfw_setname="sstp_src_gfw6"

	is_ipv4_ipts $1 && sstp_src_chn_setname="sstp_src_chn" || sstp_src_chn_setname="sstp_src_chn6"

	
	#ipset -X $sstp_src_bp_setname &>/dev/null
	ipset -! -N $sstp_src_bp_setname hash:net hashsize 64 family $gfwlist_setfamily &>/dev/null
	#ipset -X $sstp_src_fw_setname &>/dev/null
	ipset -! -N $sstp_src_fw_setname hash:net hashsize 64 family $gfwlist_setfamily &>/dev/null
	#ipset -X $sstp_src_ac_setname &>/dev/null
	ipset -! -N $sstp_src_ac_setname hash:net hashsize 64 family $gfwlist_setfamily &>/dev/null
	#ipset -X $sstp_src_chn_setname &>/dev/null
	ipset -! -N $sstp_src_chn_setname hash:net hashsize 64 family $gfwlist_setfamily &>/dev/null
	#ipset -X $sstp_src_gfw_setname &>/dev/null
	ipset -! -N $sstp_src_gfw_setname hash:net hashsize 64 family $gfwlist_setfamily &>/dev/null

	# dst 规则
	is_ipv4_ipts $1 && sstp_dst_bp_setname="sstp_dst_bp" || sstp_dst_bp_setname="sstp_dst_bp6"

	is_ipv4_ipts $1 && sstp_dst_fw_setname="sstp_dst_fw" || sstp_dst_fw_setname="sstp_dst_fw6"

	is_ipv4_ipts $1 && sstp_dst_dns_fw_setname="sstp_dst_dns_fw" || sstp_dst_dns_fw_setname="sstp_dst_dns_fw6"

	#ipset -X $sstp_dst_bp_setname &>/dev/null
	ipset -! -N $sstp_dst_bp_setname hash:net hashsize 64 family $gfwlist_setfamily &>/dev/null
	#ipset -X $sstp_dst_fw_setname &>/dev/null
	ipset -! -N $sstp_dst_fw_setname hash:net hashsize 64 family $gfwlist_setfamily &>/dev/null
	#ipset -X $sstp_dst_dns_fw_setname &>/dev/null
	ipset -! -N $sstp_dst_dns_fw_setname hash:net hashsize 64 family $gfwlist_setfamily &>/dev/null

	######################### SSTP_RULE (for tcp) #########################

	$1 -t nat -N SSTP_RULE
	$1 -t nat -N SSTP_LAN_AC
	$1 -t nat -N SSTP_WAN_AC
	$1 -t nat -N SSTP_WAN_CHN
	$1 -t nat -N SSTP_WAN_GFW
	$1 -t nat -N SSTP_GFW_CHN
	$1 -t nat -N SSTP_WAN_FW
	$1 -t nat -N SSTP_WAN_DNS

	$1 -t nat -A SSTP_RULE -p tcp -m set --match-set $proxyaddr_setname dst -m multiport --dports $proxy_svrport -j RETURN
	$1 -t nat -A SSTP_RULE -m mark --mark 0xff -j RETURN
	$1 -t nat -A SSTP_RULE -m set --match-set $privaddr_setname dst -j RETURN

	if ! is_enabled_udp; then
		$1 -t nat -A SSTP_RULE -p tcp -d $remote_dns_ip --dport $remote_dns_port --syn -j REDIRECT --to-ports $proxy_tcpport
	fi
	$1 -t nat -A SSTP_RULE -j SSTP_LAN_AC
	$1 -t nat -A SSTP_LAN_AC -m set --match-set sstp_mac_bp src -j RETURN
	$1 -t nat -A SSTP_LAN_AC -m set --match-set sstp_mac_fw src -j SSTP_WAN_FW
	$1 -t nat -A SSTP_LAN_AC -m set --match-set sstp_mac_ac src -j SSTP_WAN_AC
	$1 -t nat -A SSTP_LAN_AC -m set --match-set sstp_mac_gfw src -j SSTP_WAN_GFW
	$1 -t nat -A SSTP_LAN_AC -m set --match-set sstp_mac_chn src -j SSTP_WAN_CHN
	$1 -t nat -A SSTP_LAN_AC -m set --match-set $sstp_src_bp_setname src -j RETURN
	$1 -t nat -A SSTP_LAN_AC -m set --match-set $sstp_src_fw_setname src -j SSTP_WAN_FW
	$1 -t nat -A SSTP_LAN_AC -m set --match-set $sstp_src_ac_setname src -j SSTP_WAN_AC
	$1 -t nat -A SSTP_LAN_AC -m set --match-set $sstp_src_gfw_setname src -j SSTP_WAN_GFW
	$1 -t nat -A SSTP_LAN_AC -m set --match-set $sstp_src_chn_setname src -j SSTP_WAN_CHN
	if [ "$LAN_AC_IP" == "2" ] ; then
	$1 -t nat -A SSTP_LAN_AC -m set ! --match-set $localaddr_setname src -j RETURN
	$1 -t nat -A SSTP_LAN_AC -m set --match-set $localaddr_setname src -j SSTP_WAN_AC
	else
	$1 -t nat -A SSTP_LAN_AC -j ${LAN_TARGET:=SSTP_WAN_AC}
	fi
	$1 -t nat -A SSTP_WAN_AC -j ${MODE_TARGET:=RETURN}
	$1 -t nat -A SSTP_GFW_CHN -j SSTP_WAN_GFW
	$1 -t nat -A SSTP_GFW_CHN -j SSTP_WAN_CHN
	$1 -t nat -A SSTP_GFW_CHN -j RETURN
	$1 -t nat -A SSTP_WAN_GFW -m set --match-set $sstp_dst_dns_fw_setname dst -j SSTP_WAN_DNS
	$1 -t nat -A SSTP_WAN_GFW -m set --match-set $sstp_dst_fw_setname dst -j SSTP_WAN_FW
	$1 -t nat -A SSTP_WAN_GFW -m set --match-set $sstp_dst_bp_setname dst -j RETURN
	$1 -t nat -A SSTP_WAN_GFW -m set --match-set $gfwlist_setname dst -j ${GFWLIST_TARGET:=SSTP_WAN_FW}
	$1 -t nat -A SSTP_WAN_GFW -j RETURN
	$1 -t nat -A SSTP_WAN_CHN -m set --match-set $sstp_dst_dns_fw_setname dst -j SSTP_WAN_DNS
	$1 -t nat -A SSTP_WAN_CHN -m set --match-set $sstp_dst_fw_setname dst -j SSTP_WAN_FW
	$1 -t nat -A SSTP_WAN_CHN -m set --match-set $sstp_dst_bp_setname dst -j RETURN
	$1 -t nat -A SSTP_WAN_CHN -m set --match-set $chnroute_setname dst -j ${CHN_TARGET:=RETURN}
	$1 -t nat -A SSTP_WAN_CHN -j ${CHN_WAN_TARGET:=SSTP_WAN_FW}
	$1 -t nat -A SSTP_WAN_FW -p tcp -m multiport --dports $ipts_proxy_dst_port_tcp --syn -j REDIRECT --to-ports $proxy_tcpport

	$1 -t nat -A SSTP_WAN_FW -m set --match-set $sstp_dst_dns_fw_setname dst -j SSTP_WAN_DNS
	$1 -t nat -A SSTP_WAN_DNS -p tcp -m multiport --dports 1:65535 --syn -j REDIRECT --to-ports $proxy_tcpport

	if is_ipv4_ipts $1; then
		koolproxy_enable=`nvram get koolproxy_enable`
		if [ "$koolproxy_enable" != "0" ] ; then
		# 加载 kp过滤方案 规则
		logger -t "【SS】" "设置内网(LAN)访问控制【kp过滤方案】"
		cat $file_lanlist_ext | sort -u | grep -v '^$' | grep -v '^@' | grep -v '^#' | while read ip_addr
		do
		if [ ! -z "$ip_addr" ] ; then
			case "${ip_addr:0:1}" in
				1|1)
					iptables -t nat -I SSTP_LAN_AC  -p tcp -m mark --mark $(echo ${ip_addr:2} | awk -F "." '{printf ("0x%02x", $1)} {printf ("%02x", $2)} {printf ("%02x", $3)} {printf ("00/0xffffff00\n")}') $EXT_ARGS_TCP -j SSTP_WAN_CHN
					;;
				2|2)
					iptables -t nat -I SSTP_LAN_AC  -p tcp -m mark --mark $(echo ${ip_addr:2} | awk -F "." '{printf ("0x%02x", $1)} {printf ("%02x", $2)} {printf ("%02x", $3)} {printf ("00/0xffffff00\n")}') $EXT_ARGS_TCP -j SSTP_WAN_GFW
					;;
				n|N)
					iptables -t nat -I SSTP_LAN_AC  -p tcp -m mark --mark $(echo ${ip_addr:2} | awk -F "." '{printf ("0x%02x", $1)} {printf ("%02x", $2)} {printf ("%02x", $3)} {printf ("00/0xffffff00\n")}') $EXT_ARGS_TCP -j SSTP_WAN_AC
					;;
				g|G)
					iptables -t nat -I SSTP_LAN_AC  -p tcp -m mark --mark $(echo ${ip_addr:2} | awk -F "." '{printf ("0x%02x", $1)} {printf ("%02x", $2)} {printf ("%02x", $3)} {printf ("00/0xffffff00\n")}') $EXT_ARGS_TCP -j SSTP_WAN_FW
					;;
				b|B)
					iptables -t nat -I SSTP_LAN_AC  -p tcp -m mark --mark $(echo ${ip_addr:2} | awk -F "." '{printf ("0x%02x", $1)} {printf ("%02x", $2)} {printf ("%02x", $3)} {printf ("00/0xffffff00\n")}') -j RETURN
					;;
			esac
		fi
		done
		fi
	fi

	######################### SSTP_RULE (for udp) #########################

	if is_enabled_udp; then
		$1 -t mangle -N SSTP_RULE
		$1 -t mangle -N SSTP_LAN_AC
		$1 -t mangle -N SSTP_WAN_AC
		$1 -t mangle -N SSTP_WAN_CHN
		$1 -t mangle -N SSTP_WAN_GFW
		$1 -t mangle -N SSTP_GFW_CHN
		$1 -t mangle -N SSTP_WAN_FW
		$1 -t mangle -N SSTP_WAN_DNS

		$1 -t mangle -A SSTP_RULE -j CONNMARK --restore-mark
		$1 -t mangle -A SSTP_RULE -m mark --mark $ipts_rt_mark -j RETURN
		$1 -t mangle -A SSTP_RULE -m mark --mark 0xff -j RETURN
		$1 -t mangle -A SSTP_RULE -m set --match-set $privaddr_setname dst -j RETURN

		$1 -t mangle -A SSTP_RULE -p udp -m set --match-set $proxyaddr_setname dst -m multiport --dports $proxy_svrport -j RETURN

		$1 -t mangle -A SSTP_RULE -p udp -d $direct_dns_ip --dport 53               -j RETURN
		$1 -t mangle -A SSTP_RULE -p udp -d $remote_dns_ip --dport $remote_dns_port -j MARK --set-mark $ipts_rt_mark
		$1 -t mangle -A SSTP_RULE -p udp -d $remote_dns_ip --dport $remote_dns_port -j RETURN

		$1 -t mangle -A SSTP_RULE -j SSTP_LAN_AC
		$1 -t mangle -A SSTP_LAN_AC -m set --match-set sstp_mac_bp src -j RETURN
		$1 -t mangle -A SSTP_LAN_AC -m set --match-set sstp_mac_fw src -j SSTP_WAN_FW
		$1 -t mangle -A SSTP_LAN_AC -m set --match-set sstp_mac_ac src -j SSTP_WAN_AC
		$1 -t mangle -A SSTP_LAN_AC -m set --match-set sstp_mac_gfw src -j SSTP_WAN_GFW
		$1 -t mangle -A SSTP_LAN_AC -m set --match-set sstp_mac_chn src -j SSTP_WAN_CHN
		$1 -t mangle -A SSTP_LAN_AC -m set --match-set $sstp_src_bp_setname src -j RETURN
		$1 -t mangle -A SSTP_LAN_AC -m set --match-set $sstp_src_fw_setname src -j SSTP_WAN_FW
		$1 -t mangle -A SSTP_LAN_AC -m set --match-set $sstp_src_ac_setname src -j SSTP_WAN_AC
		$1 -t mangle -A SSTP_LAN_AC -m set --match-set $sstp_src_gfw_setname src -j SSTP_WAN_GFW
		$1 -t mangle -A SSTP_LAN_AC -m set --match-set $sstp_src_chn_setname src -j SSTP_WAN_CHN
		if [ "$LAN_AC_IP" == "2" ] ; then
		$1 -t mangle -A SSTP_LAN_AC -m set ! --match-set $localaddr_setname src -j RETURN
		$1 -t mangle -A SSTP_LAN_AC -m set --match-set $localaddr_setname src -j SSTP_WAN_AC
		else
		$1 -t mangle -A SSTP_LAN_AC -j ${LAN_TARGET:=SSTP_WAN_AC}
		fi
		$1 -t mangle -A SSTP_WAN_AC -j ${MODE_TARGET:=RETURN}
		$1 -t mangle -A SSTP_GFW_CHN -j SSTP_WAN_GFW
		$1 -t mangle -A SSTP_GFW_CHN -j SSTP_WAN_CHN
		$1 -t mangle -A SSTP_GFW_CHN -j RETURN
		[ "$ss_all_udp" == "1" ] && $1 -t mangle -A SSTP_WAN_GFW -p udp -j SSTP_WAN_FW
		$1 -t mangle -A SSTP_WAN_GFW -m set --match-set $sstp_dst_dns_fw_setname dst -j SSTP_WAN_DNS
		$1 -t mangle -A SSTP_WAN_GFW -m set --match-set $sstp_dst_fw_setname dst -j SSTP_WAN_FW
		$1 -t mangle -A SSTP_WAN_GFW -m set --match-set $sstp_dst_bp_setname dst -j RETURN
		$1 -t mangle -A SSTP_WAN_GFW -m set --match-set $gfwlist_setname dst -j ${GFWLIST_TARGET:=SSTP_WAN_FW}
		$1 -t mangle -A SSTP_WAN_GFW -j RETURN
		[ "$ss_all_udp" == "1" ] && $1 -t mangle -A SSTP_WAN_CHN -p udp -j SSTP_WAN_FW
		$1 -t mangle -A SSTP_WAN_CHN -m set --match-set $sstp_dst_dns_fw_setname dst -j SSTP_WAN_DNS
		$1 -t mangle -A SSTP_WAN_CHN -m set --match-set $sstp_dst_fw_setname dst -j SSTP_WAN_FW
		$1 -t mangle -A SSTP_WAN_CHN -m set --match-set $sstp_dst_bp_setname dst -j RETURN
		$1 -t mangle -A SSTP_WAN_CHN -m set --match-set $chnroute_setname dst -j ${CHN_TARGET:=RETURN}
		$1 -t mangle -A SSTP_WAN_CHN -j ${CHN_WAN_TARGET:=SSTP_WAN_FW}
		$1 -t mangle -A SSTP_WAN_FW -p udp -m multiport --dports $ipts_proxy_dst_port_udp -m conntrack --ctstate NEW -j MARK --set-mark $ipts_rt_mark
		
		$1 -t mangle -A SSTP_WAN_FW -m set --match-set $sstp_dst_dns_fw_setname dst -j SSTP_WAN_DNS
		$1 -t mangle -A SSTP_WAN_DNS -p udp -m multiport --dports 1:65535 -m conntrack --ctstate NEW -j MARK --set-mark $ipts_rt_mark

		$1 -t mangle -A SSTP_RULE -j CONNMARK --save-mark
	fi


	######################### SSTP_OUTPUT/SSTP_PREROUTING #########################

	if is_usrgrp_mode; then
		$1 -t nat -I SSTP_OUTPUT -m owner $(get_usrgrp_args) -j RETURN
		is_enabled_udp && $1 -t mangle -I SSTP_OUTPUT -m owner $(get_usrgrp_args) -j RETURN
	fi
	if is_nonstd_dnsport "$dnsmasq_bind_port"; then
		if [ "$lan_ipaddr" != "$loopback_addr" ] ; then
			$1 -t nat -A SSTP_OUTPUT -p udp -d $lan_ipaddr --dport 53 -j REDIRECT --to-ports $dnsmasq_bind_port
		else
			$1 -t nat -A SSTP_OUTPUT -p udp -d $loopback_addr --dport 53 -j REDIRECT --to-ports $dnsmasq_bind_port
		fi
	fi

	[ "$output_return" != "1" ] && $1 -t nat -A SSTP_OUTPUT -m set --match-set $localaddr_setname src -m set ! --match-set $localaddr_setname dst -p tcp -j SSTP_RULE
	if [ "$output_return" != "1" ] || [ "$output_udp_return" == "1" ] ; then
		is_enabled_udp && $1 -t mangle -A SSTP_OUTPUT -m set --match-set $localaddr_setname src -m set ! --match-set $localaddr_setname dst -p udp -j SSTP_RULE
	fi

	is_enabled_udp && $1 -t mangle -A SSTP_PREROUTING -i $ipts_if_lo -m mark ! --mark $ipts_rt_mark -j RETURN

	if is_false "$selfonly"; then
		if is_nonstd_dnsport "$dnsmasq_bind_port"; then
			is_enabled_udp && $1 -t mangle -A SSTP_PREROUTING -m set ! --match-set $localaddr_setname src -m set --match-set $localaddr_setname dst -p udp --dport 53 -j RETURN
			$1 -t nat -A SSTP_PREROUTING -m set ! --match-set $localaddr_setname src -m set --match-set $localaddr_setname dst -p udp --dport 53 -j REDIRECT --to-ports $dnsmasq_bind_port
		fi

		$1 -t nat -A SSTP_PREROUTING -m set ! --match-set $localaddr_setname src -m set ! --match-set $localaddr_setname dst -p tcp -j SSTP_RULE
		is_enabled_udp && $1 -t mangle -A SSTP_PREROUTING -m set ! --match-set $localaddr_setname src -m set ! --match-set $localaddr_setname dst -p udp -j SSTP_RULE
	fi

	if [ "$lan_ipaddr" != "$loopback_addr" ] ; then
		is_enabled_udp && $1 -t mangle -A SSTP_PREROUTING -p udp -m mark --mark $ipts_rt_mark -j TPROXY --on-ip $lan_ipaddr --on-port $proxy_udpport
	else
		is_enabled_udp && $1 -t mangle -A SSTP_PREROUTING -p udp -m mark --mark $ipts_rt_mark -j TPROXY --on-ip $loopback_addr --on-port $proxy_udpport
	fi

	check_snatrule $1
}

start_iptables() {
	resolve_svraddr
	is_true "$ipv4" && start_iptables_pre_rules "iptables"
	is_true "$ipv6" && start_iptables_pre_rules "ip6tables"

	if is_true "$tproxy"; then
		is_true "$ipv4" && start_iptables_tproxy_mode "iptables"
		is_true "$ipv6" && start_iptables_tproxy_mode "ip6tables"
	else
		is_true "$ipv4" && start_iptables_redirect_mode "iptables"
		is_true "$ipv6" && start_iptables_redirect_mode "ip6tables"
	fi
	is_true "$ipv4" && get_wifidognx_output
	is_true "$ipv4" && get_wifidognx
	is_true "$ipv4" && get_wifidognx_mangle
	is_true "$ipv4" && start_iptables_post_rules "iptables"
	check_startdnsredir "iptables"
	wifidognx_output=""
	wifidognx=""
	wifidogn_manglex=""
	is_true "$ipv6" && start_iptables_post_rules "ip6tables"
	is_true "$ipv4" && { is_false "$ipv6" && [ -z "$(ip6tables -vnL INPUT --line-numbers | grep -Ei "udp *dpt:53 *reject")" ] && ip6tables -I INPUT -p udp --dport 53 -j REJECT ; }
	logger -t "【sh_ss_tproxy.sh】" "完成加载 iptables 转发规则...."
}

gen_include() {
echo '#!/bin/bash' >/tmp/firewall.sstp.pdcn
cat <<-CAT >>/tmp/firewall.sstp.pdcn
iptables-restore -n <<-EOF
$(iptables-save | sed  "s/webstr--url/webstr --url/g" | grep -E "SSTP|^\*|^COMMIT" |sed -e "s/^-A \(OUTPUT\|PREROUTING\)/-I \1 1/")
EOF
CAT
return $?
}

get_wifidognx_output() {
	wifidognx_output=""
	wifidogn=`iptables -t nat -L OUTPUT --line-number | grep Outgoing | awk '{print $1}' | awk 'END{print $1}'`  ## Outgoing
	if [ -z "$wifidogn" ] ; then
		wifidogn=`iptables -t nat -L OUTPUT --line-number | grep vserver | awk '{print $1}' | awk 'END{print $1}'`  ## vserver
		if [ -z "$wifidogn" ] ; then
			wifidognx_output=1
		else
			wifidognx_output=`expr $wifidogn + 1`
		fi
	else
		wifidognx_output=`expr $wifidogn + 1`
	fi
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
	#    wifidognx=`expr $wifidogn + 1`
	#fi
	wifidognx=$wifidognx
}

get_wifidognx_mangle() {
	wifidogn_manglex=""
	wifidogn=`iptables -t mangle -L PREROUTING --line-number | grep Outgoing | awk '{print $1}' | awk 'END{print $1}'`  ## Outgoing
		if [ -z "$wifidogn" ] ; then
			wifidogn=`iptables -t mangle -L PREROUTING --line-number | grep UP | awk '{print $1}' | awk 'END{print $1}'`  ## UP
			if [ -z "$wifidogn" ] ; then
				wifidogn_manglex=1
			else
				wifidogn_manglex=`expr $wifidogn + 1`
			fi
		else
			wifidogn_manglex=`expr $wifidogn + 1`
		fi
	wifidogn_manglex=$wifidogn_manglex
}

awk_del_list() {
touch $1 $2
a_list_conf=$1
b_list_conf=$2
# [a =>> b] 在 b 文件寻找 a 文件的匹配文字并删除，重新生成b文件
if [ -s $a_list_conf ] && [ -s $b_list_conf ] ; then
echo "$(awk '\
NR==FNR{\
  a[$0]++\
}\
NR>FNR{\
  if(($0 in a)) {\
      print ""\
  }\
  else{\
    print $0
  }\
}' $a_list_conf $b_list_conf)" > $b_list_conf
fi
}

start() {
	ss_tproxy_is_started && { stop; status; echo; }
	waiting_network "$opts_ip_for_check_net"
	[ ! -z "$(type -t pre_start)" ] && pre_start

	flush_postrule
	enable_ipforward
	disable_icmpredir
	restore_resolvconf
	start_proxy_proc
	start_dnsserver
	start_iptables
	modify_resolvconf
	update_gfwlist_ipset
	update_chinadns_ng_ipset
	update_chnroute_ipset
	update_wanlanlist_ipset
	update_chnlist_ipset
	update_check_file
	
	update_dnsmasq_file
	
	[ ! -z "$(type -t post_start)" ] && post_start
	delete_unused_iptchains
	gen_include
}

stop() {
	[ ! -z "$(type -t pre_stop)" ] && pre_stop

	restore_resolvconf
	flush_iptables
	#delete_chnroute
	delete_iproute2
	stop_dnsserver
	stop_proxy_proc
	check_postrule

	[ ! -z "$(type -t post_stop)" ] && post_stop
	gen_include
}

status() {
	echo "mode:     $mode"
	tcp_port_is_exists $proxy_tcpport && echo "pxy/tcp:  $(color_green '[running]')" || echo "pxy/tcp:  $(color_red '[stopped]')"
	if is_enabled_udp; then
		udp_port_is_exists $proxy_udpport && echo "pxy/udp:  $(color_green '[running]')" || echo "pxy/udp:  $(color_red '[stopped]')"
	fi
#    process_is_running $status_dnsmasq_pid && echo "dnsmasq:  $(color_green '[running]')" || echo "dnsmasq:  $(color_red '[stopped]')"
#	if is_chnroute_mode; then
#		process_is_running $status_chinadns_pid && echo "chinadns: $(color_green '[running]')" || echo "chinadns: $(color_red '[stopped]')"
#	fi
#	if ! is_enabled_udp; then
#		is_true "$ipv4" && { process_is_running $status_dns2tcp4_pid && echo "dns2tcp4: $(color_green '[running]')" || echo "dns2tcp4: $(color_red '[stopped]')"; }
#		is_true "$ipv6" && { process_is_running $status_dns2tcp6_pid && echo "dns2tcp6: $(color_green '[running]')" || echo "dns2tcp6: $(color_red '[stopped]')"; }
#	fi
}

version() {
	echo "ss-tproxy v4.6"
}

help() {
	cat <<'EOF'
Usage: ss-tproxy <COMMAND> [-x] [name=value...]
COMMAND := {
	start               start ss-tproxy
	stop                stop ss-tproxy
	restart             restart ss-tproxy
	status              status of ss-tproxy
	show-iptables       show iptables rules
	flush-postrule      flush legacy rules
	flush-dnscache      flush dnsmasq cache
	delete-gfwlist      delete ipset@gfwlist
	update-chnlist      update chnlist list
	update-gfwlist      update gfwlist list
	update-chnroute     update chnroute list
	version             show version and exit
	help                show help and exit
}
Specify the -x option for debugging of bash scripts
Specify the name=value to override ss-tproxy configs
Issues or bug report: https://github.com/zfl9/ss-tproxy
See https://github.com/zfl9/ss-tproxy/wiki for more details
EOF
}

main() {
	arguments=""
	optentries=""

	for arg in "$@"; do
		if [ "$arg" = '-x' ] ; then
			set -x
		elif [ $(echo "$arg" | grep -c '=') -ne 0 ] ; then
			optentries="$optentries ""$arg"
		else
			arguments="$arguments ""$arg"
		fi
	done

	if [ -z "$arguments" ] ; then
		echo "$(color_yellow "Missing necessary options")"
		help
		return 0
	fi

	load_config
	check_config

for options in $arguments; do 
	[ "$options" != "h" ] && [ "$options" != "v" ] && logger -t "【sh_ss_tproxy.sh】" "$options"
	case "$options" in
		start)           start; status;;
		stop)            stop; status;;
		restart)              stop; status; echo; start; status;;
		status)          status;;
		show_iptables)           show_iptables;;
		flush-postrule)  flush_postrule;;
		flush-dnscache)  flush_dnscache;;
		delete_gfwlist)  delete_gfwlist;;
		delete_chnroute) delete_chnroute;;
		update-chnlist|update_chnlist)   update_chnlist;;
		update-gfwlist|update_gfwlist)   update_gfwlist;;
		update-chnroute|update_chnroute) update_chnroute;;
		update-chnroute6|update_chnroute6) update_chnroute6;;
		update_chnlist_file)     update_chnlist_file;;
		update_gfwlist_file)     update_gfwlist_file;;
		update_chnroute_file)    update_chnroute_file;;
		update_chnroute_file6)    update_chnroute_file "ipv6";;
		update_chnlist_ipset)    update_chnlist_ipset;;
		update_gfwlist_ipset)    update_gfwlist_ipset;;
		update_chnroute_ipset)   update_chnroute_ipset;;
		update_chnroute_ipset6)   update_chnroute_ipset "ipv6";;
		update_wanlanlist_ipset) update_wanlanlist_ipset;;
		adbyby_cflist_ipset) update_cflist_ipset /tmp/adbyby_host.conf /opt/app/ss_tproxy/dnsmasq.d/r.gfwlist.conf ;;
		resolve_svraddr)         resolve_svraddr;;
		start_iptables)          start_iptables;;
		start_dnsserver_confset) start_dnsserver_confset;;
		v)              version;;
		h|help)              help;;
		*)               echo "$(color_yellow "Unknown option: $arg")"; help; return 1;;
	esac
done
	return 0
}

main "$@"
