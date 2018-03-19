#!/bin/sh
#copyright by hiboy
source /etc/storage/script/init.sh
TAG="SS_SPEC"		  # iptables tag
ss_enable=`nvram get ss_enable`
[ -z $ss_enable ] && ss_enable=0 && nvram set ss_enable=0
if [ "$ss_enable" != "0" ] ; then
#nvramshow=`nvram showall | grep '=' | grep kcptun | awk '{print gensub(/'"'"'/,"'"'"'\"'"'"'\"'"'"'","g",$0);}'| awk '{print gensub(/=/,"='\''",1,$0)"'\'';";}'` && eval $nvramshow
#nvramshow=`nvram showall | grep '=' | grep ss | awk '{print gensub(/'"'"'/,"'"'"'\"'"'"'\"'"'"'","g",$0);}'| awk '{print gensub(/=/,"='\''",1,$0)"'\'';";}'` && eval $nvramshow

kcptun_server=`nvram get kcptun_server`
koolproxy_enable=`nvram get koolproxy_enable`
ss_dnsproxy_x=`nvram get ss_dnsproxy_x`
ss_link_1=`nvram get ss_link_1`
ss_link_2=`nvram get ss_link_2`
ss_update=`nvram get ss_update`
ss_update_hour=`nvram get ss_update_hour`
ss_update_min=`nvram get ss_update_min`

#================华丽的分割线====================================
#set -x
#初始化开始
FWI="/tmp/firewall.shadowsocks.pdcn" # firewall include file

ss_type=`nvram get ss_type`
[ -z $ss_type ] && ss_type=0 && nvram set ss_type=$ss_type
ss_run_ss_local=`nvram get ss_run_ss_local`

kcptun_enable=`nvram get kcptun_enable`
[ -z $kcptun_enable ] && kcptun_enable=0 && nvram set kcptun_enable=$kcptun_enable
kcptun2_enable=`nvram get kcptun2_enable`
[ -z $kcptun2_enable ] && kcptun2_enable=0 && nvram set kcptun2_enable=$kcptun2_enable
kcptun2_enable2=`nvram get kcptun2_enable2`
[ -z $kcptun2_enable2 ] && kcptun2_enable2=0 && nvram set kcptun2_enable2=$kcptun2_enable2
[ "$kcptun_enable" = "0" ] && kcptun_server=""

server_addresses=$(cat /etc/storage/v2ray_config_script.sh | tr -d ' ' | grep -Eo '"address":"[0-9\.]*"' | cut -d':' -f2 | tr -d '"')

nvram set ss_server1=`nvram get ss_server`
nvram set ss_s1_port=`nvram get ss_server_port`
nvram set ss_s1_key=`nvram get ss_key`
nvram set ss_s1_method=`nvram get ss_method`

#以后多线支持弄个循环，现在只做两线就算了，如果
#如果server2 只设置了ip，则其他配置与S1一样
ss_s1_local_address=`nvram get ss_s1_local_address`
ss_s2_local_address=`nvram get ss_s2_local_address`
[ -z $ss_s1_local_address ] && ss_s1_local_address="0.0.0.0" && nvram set ss_s1_local_address=$ss_s1_local_address
[ -z $ss_s2_local_address ] && ss_s2_local_address="0.0.0.0" && nvram set ss_s2_local_address=$ss_s2_local_address
ss_s1_local_port=`nvram get ss_s1_local_port`
ss_s2_local_port=`nvram get ss_s2_local_port`
[ -z $ss_s1_local_port ] && ss_s1_local_port=1081 && nvram set ss_s1_local_port=$ss_s1_local_port
[ -z $ss_s2_local_port ] && ss_s2_local_port=1082 && nvram set ss_s2_local_port=$ss_s2_local_port
ss_server1=`nvram get ss_server1`
ss_server2=`nvram get ss_server2`

ss_s1_port=`nvram get ss_s1_port`
ss_s2_port=`nvram get ss_s2_port`
[ -z $ss_s2_port ] && ss_s2_port="$ss_s1_port" && nvram set ss_s2_port=$ss_s2_port
ss_s1_method=`nvram get ss_s1_method| tr 'A-Z' 'a-z'`
ss_s2_method=`nvram get ss_s2_method| tr 'A-Z' 'a-z'`
[ -z $ss_s2_method ] && ss_s2_method="$ss_s1_method" && nvram set ss_s2_method=$ss_s2_method
ss_s1_key="$(nvram get ss_s1_key)"
ss_s2_key="$(nvram get ss_s2_key)"
[ -z "$ss_s2_key" ] && ss_s2_key="$ss_s1_key" && nvram set ss_s2_key="$ss_s2_key"
ss_pdnsd_wo_redir=`nvram get ss_pdnsd_wo_redir` #pdnsd  0、走代理；1、直连
[ -z $ss_pdnsd_wo_redir ] && ss_pdnsd_wo_redir=0 && nvram set ss_pdnsd_wo_redir=$ss_pdnsd_wo_redir
ss_mode_x=`nvram get ss_mode_x` #ss模式，0 为chnroute, 1 为 gfwlist, 2 为全局, 3为ss-local 建立本地 SOCKS 代理
[ -z $ss_mode_x ] && ss_mode_x=0 && nvram set ss_mode_x=$ss_mode_x
ss_working_port=`nvram get ss_working_port` #working port 不需要在界面设置，在watchdog里面设置。
[ -z $ss_working_port ] && ss_working_port=1090 && nvram set ss_working_port=$ss_working_port
ss_multiport=`nvram get ss_multiport`
[ -z "$ss_multiport" ] && ss_multiport="22,80,443" && nvram set ss_multiport=$ss_multiport
[ -n "$ss_multiport" ] && ss_multiport="-m multiport --dports $ss_multiport" || ss_multiport="-m multiport --dports 22,80,443" # 处理多端口设定
# 严重警告，如果走chnrouter 和全局模式，又不限制端口，下载流量都会通过你的ss服务器往外走，随时导致你的ss服务器被封或ss服务商封你帐号，设置连累你的SS服务商被封

# DNS 端口，用于防止域名污染用的PDNSD
DNS_Server=127.0.0.1#8053

ss_pdnsd_all=`nvram get ss_pdnsd_all`
[ "$ss_mode_x" != "0" ] && kcptun2_enable=$kcptun2_enable2
[ "$kcptun2_enable" = "2" ] && ss_server2=""
[ -z "$ss_server2" ] && [ "$kcptun2_enable" != "2" ] && kcptun2_enable=2 && { [ "$ACTION" != "keep" ] && logger -t "【SS】" "设置内容:非 chnroute 模式, 备服务器 停用" ; }
[ "$ss_mode_x" != "0" ] && [ ! -z "$ss_server2" ] && [ "$kcptun2_enable" != "2" ] && kcptun2_enable=0 && { [ "$ACTION" != "keep" ] && logger -t "【SS】" "设置内容:非 chnroute 模式，备服务器 故障转移 模式" ; }
[ "$ss_mode_x" != "0" ] && nvram set kcptun2_enable2=$kcptun2_enable
[ "$ss_mode_x" = "0" ] && nvram set kcptun2_enable=$kcptun2_enable
[ "$ss_pdnsd_all" = "1" ] && [ "$ss_mode_x" != "0" ] && ss_pdnsd_all=0 && { [ "$ACTION" != "keep" ] && logger -t "【SS】" "设置内容:非 chnroute 模式，不转全部发pdnsd" ; }
[ "$ss_pdnsd_all" = "1" ] && [ "$kcptun2_enable" = "1" ] && ss_pdnsd_all=0 && { [ "$ACTION" != "keep" ] && logger -t "【SS】" "设置内容:开启 kcptun+gfwlist 模式，不转全部发 pdnsd" ; }
nvram set ss_pdnsd_all=$ss_pdnsd_all
ss_3p_enable=`nvram get ss_3p_enable`
ss_3p_gfwlist=`nvram get ss_3p_gfwlist`
ss_3p_kool=`nvram get ss_3p_kool`


ss_sub1=`nvram get ss_sub1`
ss_sub2=`nvram get ss_sub2`
ss_sub3=`nvram get ss_sub3`
ss_sub4=`nvram get ss_sub4`

ss_tochina_enable=`nvram get ss_tochina_enable`
[ -z $ss_tochina_enable ] && ss_tochina_enable=0 && nvram set ss_tochina_enable=$ss_tochina_enable
ss_udp_enable=`nvram get ss_udp_enable` #udp转发  0、停用；1、启动
[ -z $ss_udp_enable ] && ss_udp_enable=0 && nvram set ss_udp_enable=$ss_udp_enable
ss_upd_rules=`nvram get ss_upd_rules`
if [ ! -z "$ss_upd_rules" ] ; then
	ss_upd_rules="-s $ss_upd_rules" 
fi
# ss_upd_rules UDP参数用法，暂时不考虑字符安全过滤的问题，单用户系统输入，并且全root开放的平台，你愿意注入自己的路由器随意吧。
# 范例 
# 单机全部 192.168.123.10 
# 多台单机 192.168.123.10,192.168.123.12
# 子网段  192.168.123.16/28  不知道怎么设置自己找在线子网掩码工具计算
# 单机但限定目的端口  192.168.123.10 --dport 3000:30010
# 如果需要更加细节的设置，可以让用户自己修改一个iptables 文件来处理。

ss_usage=" `nvram get ss_usage`"
ss_s2_usage=" `nvram get ss_s2_usage`"


touch /etc/storage/shadowsocks_mydomain_script.sh
LAN_AC_IP=`nvram get LAN_AC_IP`
[ -z $LAN_AC_IP ] && LAN_AC_IP=0 && nvram set LAN_AC_IP=$LAN_AC_IP

lan_ipaddr=`nvram get lan_ipaddr`
ss_DNS_Redirect=`nvram get ss_DNS_Redirect`
ss_DNS_Redirect_IP=`nvram get ss_DNS_Redirect_IP`
[ -z "$ss_DNS_Redirect_IP" ] && ss_DNS_Redirect_IP=$lan_ipaddr

ss_updatess=`nvram get ss_updatess`
[ -z $ss_updatess ] && ss_updatess=0 && nvram set ss_updatess=$ss_updatess
[ -z $ss_link_1 ] && ss_link_1="www.163.com" && nvram set ss_link_1="www.163.com"
[ -z $ss_link_2 ] && ss_link_2="www.google.com.hk" && nvram set ss_link_2="www.google.com.hk"
[ $ss_link_1 == "email.163.com" ] && ss_link_1="www.163.com" && nvram set ss_link_1="www.163.com"

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
fi
##  bigandy modify 
##  1. 增加xbox的支持 （未实现，下一版本）
##  2. 改写获取gfwlist逻辑
##  3. 增加对自定义域名的支持
##  4. 订阅机制，提供网站加速的列表订阅功能
##ss_xbox=`nvram get ss_xbox`  //andy
ss_s1_ip=""
ss_s2_ip=""

# 
GFWLIST_TARGET="SS_SPEC_WAN_FW"
LAN_TARGET=""
WAN_TARGET=""
SH_TARGET=""
ip_list=""
wifidognx=""

#检查 ssrr 协议
if [ "$ss_type" != "1" ] ; then
ssrr_type=0
else
ssrr_custom="$(echo $ss_usage | grep -Eo 'auth_chain_c|auth_chain_d|auth_chain_e|auth_chain_f')"
ssrr_s2_custom="$(echo $ss_s2_usage | grep -Eo 'auth_chain_c|auth_chain_d|auth_chain_e|auth_chain_f')"
if [ ! -z "$ssrr_custom" ] || [ ! -z "$ssrr_s2_custom" ] ; then 
ssrr_type=1
fi
fi

#SS插件参数
if [ "$ss_type" != "1" ] ; then 
	ss_plugin_config="`nvram get ss_plugin_config`"
	ss2_plugin_config="`nvram get ss2_plugin_config`"
else
	ss_plugin_config=""
	ss2_plugin_config=""
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

# 创建JSON
cat > "/tmp/SSJSON.sh" <<-\SSJSONSH
while getopts "a:o:O:g:G:s:p:b:l:k:m:f:h:" arg; do
	case "$arg" in
		a)
			a="$OPTARG"
			;;
		o)
			obfs="$OPTARG"
			;;
		O)
			protocol="$OPTARG"
			;;
		g)
			obfs_param="$OPTARG"
			[ "$a" = 1 ] && obfs_param="`nvram get $OPTARG`"
			;;
		G)
			protocol_param="$OPTARG"
			[ "$a" = 2 ] && protocol_param="`nvram get $OPTARG`"
			;;
		s)
			server="$OPTARG"
			;;
		p)
			server_port="$OPTARG"
			;;
		b)
			local_address="$OPTARG"
			;;
		l)
			local_port="$OPTARG"
			;;
		k)
			password="$OPTARG"
			[ "$a" = 3 ] && password="`nvram get $OPTARG`"
			;;
		m)
			method="$OPTARG"
			;;
		f)
			config_file="$OPTARG"
			;;
		h)
			obfs_plugin="`nvram get $OPTARG`"
			;;
	esac
done
plugin_c=""
[ ! -z "$obfs_plugin" ] && plugin_c="obfs-local"
cat > "$config_file" <<-SSJSON
{
"server": "$server",
"server_port": "$server_port",
"local_address": "$local_address",
"local_port": "$local_port",
"password": "$password",
"timeout": "180",
"method": "$method",
"protocol": "$protocol",
"protocol_param": "$protocol_param",
"obfs": "$obfs",
"obfs_param": "$obfs_param",
"plugin": "$plugin_c",
"plugin_opts": "$obfs_plugin"
}
SSJSON
SSJSONSH
chmod 755 /tmp/SSJSON.sh


start_ss_redir()
{
logger -t "【ss-redir】" "启动所有的 SS 连线, 出现的 SS 日志并不是错误报告, 只是使用状态日志, 请不要慌张, 只要系统正常你又看不懂就无视它！"
logger -t "【SS】" "SS服务器1 设置内容：$ss_server1 端口:$ss_s1_port 加密方式:$ss_s1_method "
[ -z "$ss_server1" ] && { logger -t "【SS】" "[错误!!] SS服务器没有设置"; stop_SS; clean_SS; } 
if [ -z $(echo $ss_server1 | grep : | grep -v "\.") ] ; then 
[ ! -z "$ss_server1" ] && ss_s1_ip=`/usr/bin/resolveip -4 -t 4 $ss_server1 | grep -v : | sed -n '1p'`
[ -z "$ss_s1_ip" ] && ss_s1_ip=`arNslookup $ss_server1 | sed -n '1p'` 
else
# IPv6
ss_s1_ip=$ss_server1
fi
[ -z "$ss_s1_ip" ] && { logger -t "【SS】" "[错误!!] 实在找不到你的SS1服务器IP，麻烦看看哪里错了？"; clean_SS; } 
if [ -z $(echo $ss_server2 | grep : | grep -v "\.") ] ; then 
[ ! -z "$ss_server2" ] && ss_s2_ip=`/usr/bin/resolveip -4 -t 4 $ss_server2 | grep -v : | sed -n '1p'`
[ ! -z "$ss_server2" ] && [ -z "$ss_s2_ip" ] && ss_s2_ip=`arNslookup $ss_server2 | sed -n '1p'`
[ ! -z "$ss_server2" ] && [ -z "$ss_s2_ip" ] && { logger -t "【SS】" "[错误!!] 实在找不到你的SS2服务器IP，麻烦看看哪里错了？"; } 
else
# IPv6
ss_s2_ip=$ss_server2
fi
[ ! -z "$ss_s2_ip" ] && ss_ip="$ss_s1_ip,$ss_s2_ip" || ss_ip=$ss_s1_ip
if [ "$ss_udp_enable" == 1 ] ; then
ss_usage="$ss_usage -u "
ss_s2_usage="$ss_s2_usage -u "
fi


if [ "$ss_type" = "1" ] ; then 
# 混淆参数
ssr_type_obfs_custom="`nvram get ssr_type_obfs_custom`"
ssr2_type_obfs_custom="`nvram get ssr2_type_obfs_custom`"
ss_usage_json=""
ss_s2_usage_json=""
ss_usage_obfs_custom="$(echo $ss_usage | grep -Eo '\-g[ ]+[^-]+')"
if [ ! -z "$ss_usage_obfs_custom" ] ; then 
	ss_usage_obfs_custom_tmp="${ss_usage##* -g }"
	ss_usage_obfs_custom_tmp="${ss_usage_obfs_custom_tmp%% -*}"
	nvram set ss_usage_obfs_custom_tmp="$ss_usage_obfs_custom_tmp"
	ss_usage_json=" -a 1 -g ss_usage_obfs_custom_tmp"
	[ ! -z "$ss_usage_obfs_custom_tmp" ] && ss_usage="`echo "$ss_usage" | sed -e "s@$ss_usage_obfs_custom_tmp@@g" `"
	ss_usage="`echo "$ss_usage" | sed -e "s/ -g //g" `"
	logger -t "【SS】" "高级启动参数选项内容含有 -g $ss_usage_obfs_custom_tmp ，服务1优先使用此 混淆参数"
else
	ss_usage="`echo "$ss_usage" | sed -e "s/ -g//g" `" # 删除空的混淆参数
	[ ! -z "$ssr_type_obfs_custom" ] && [ "$ss_type" = "1" ] && ss_usage_json="-a 1 -g ssr_type_obfs_custom"
fi
ss_s2_usage_obfs_custom="$(echo $ss_s2_usage | grep -Eo '\-g[ ]+[^-]+')"
if [ ! -z "$ss_s2_usage_obfs_custom" ] ; then 
	ss_s2_usage_obfs_custom_tmp="${ss_s2_usage##* -g }"
	ss_s2_usage_obfs_custom_tmp="${ss_s2_usage_obfs_custom_tmp%% -*}"
	nvram set ss_s2_usage_obfs_custom_tmp="$ss_s2_usage_obfs_custom_tmp"
	ss_s2_usage_json=" -a 1 -g ss_s2_usage_obfs_custom_tmp"
	[ ! -z "$ss_s2_usage_obfs_custom_tmp" ] && ss_s2_usage="`echo "$ss_s2_usage" | sed -e "s@$ss_s2_usage_obfs_custom_tmp@@g" `"
	ss_s2_usage="`echo "$ss_s2_usage" | sed -e "s/ -g //g" `"
	logger -t "【SS】" "高级启动参数选项内容含有 -g $ss_s2_usage_obfs_custom_tmp ，服务2优先使用此 混淆参数"
else
	ss_s2_usage="`echo "$ss_s2_usage" | sed -e "s/ -g//g" `" # 删除空的混淆参数
	[ ! -z "$ssr2_type_obfs_custom" ] && [ "$ss_type" = "1" ] && ss_s2_usage_json="-a 1 -g ssr2_type_obfs_custom"
fi

# 协议参数
ssr_type_protocol_custom="`nvram get ssr_type_protocol_custom`"
ssr2_type_protocol_custom="`nvram get ssr2_type_protocol_custom`"
ss_usage_protocol_custom="$(echo $ss_usage | grep -Eo '\-G[ ]+[^-]+')"
if [ ! -z "$ss_usage_protocol_custom" ] ; then 
	ss_usage_protocol_custom_tmp="${ss_usage##* -G }"
	ss_usage_protocol_custom_tmp="${ss_usage_protocol_custom_tmp%% -*}"
	nvram set ss_usage_protocol_custom_tmp="$ss_usage_protocol_custom_tmp"
	ss_usage_json="$ss_usage_json -a 2 -G ss_usage_protocol_custom_tmp"
	[ ! -z "$ss_usage_protocol_custom_tmp" ] && ss_usage="`echo "$ss_usage" | sed -e "s@$ss_usage_protocol_custom_tmp@@g" `"
	ss_usage="`echo "$ss_usage" | sed -e "s/ -G //g" `"
	logger -t "【SS】" "高级启动参数选项内容含有 -G $ss_usage_protocol_custom_tmp ，服务1优先使用此 协议参数"
else
	ss_usage="`echo "$ss_usage" | sed -e "s/ -G//g" `" # 删除空的协议参数
	[ ! -z "$ssr_type_protocol_custom" ] && [ "$ss_type" = "1" ] && ss_usage_json="$ss_usage_json -a 2 -G ssr_type_protocol_custom"
fi
ss_s2_usage_protocol_custom="$(echo $ss_s2_usage | grep -Eo '\-G[ ]+[^-]+')"
if [ ! -z "$ss_s2_usage_protocol_custom" ] ; then 
	ss_s2_usage_protocol_custom_tmp="${ss_s2_usage##* -G }"
	ss_s2_usage_protocol_custom_tmp="${ss_s2_usage_protocol_custom_tmp%% -*}"
	nvram set ss_s2_usage_protocol_custom_tmp="$ss_s2_usage_protocol_custom_tmp"
	ss_s2_usage_json="$ss_s2_usage_json -a 2 -G ss_s2_usage_protocol_custom_tmp"
	[ ! -z "$ss_s2_usage_protocol_custom_tmp" ] && ss_s2_usage="`echo "$ss_s2_usage" | sed -e "s@$ss_s2_usage_protocol_custom_tmp@@g" `"
	ss_s2_usage="`echo "$ss_s2_usage" | sed -e "s/ -G //g" `"
	logger -t "【SS】" "高级启动参数选项内容含有 -G $ss_s2_usage_protocol_custom_tmp ，服务2优先使用此 协议参数"
else
	ss_s2_usage="`echo "$ss_s2_usage" | sed -e "s/ -G//g" `" # 删除空的协议参数
	[ ! -z "$ssr2_type_protocol_custom" ] && [ "$ss_type" = "1" ] && ss_s2_usage_json="$ss_s2_usage_json -a 2 -G ssr2_type_protocol_custom"
fi

ss_usage_custom="$(echo $ss_usage | grep -Eo '\-o[ ]+[^-]+')"
if [ -z "$ss_usage_custom" ] ; then
	logger -t "【SS】" "混淆插件方式:未填写"
	logger -t "【SS】" "SS配置有错误，请到扩展功能检查SS配置页面"; stop_SS; exit 1;
fi
ss_usage_custom="$(echo $ss_usage | grep -Eo '\-O[ ]+[^-]+')"
if [ -z "$ss_usage_custom" ] ; then
	logger -t "【SS】" "协议插件方式:未填写"
	logger -t "【SS】" "SS配置有错误，请到扩展功能检查SS配置页面"; stop_SS; exit 1;
fi

else
ssr_type_obfs_custom=""
ssr2_type_obfs_custom=""
ssr_type_protocol_custom=""
ssr2_type_protocol_custom=""
fi

# 插件参数
if [ "$ss_type" != "1" ] ; then 
	ss_plugin_config="`nvram get ss_plugin_config`"
	ss2_plugin_config="`nvram get ss2_plugin_config`"
else
	ss_plugin_config=""
	ss2_plugin_config=""
fi

options1="`echo "$ss_usage" | sed -r 's/\-G[ ]+[^-]+//g' | sed -r 's/\-g[ ]+[^-]+//g' | sed -r 's/\-O[ ]+[^-]+//g' | sed -r 's/\-o[ ]+[^-]+//g' | sed -e "s/ -g//g" | sed -e "s/ -G//g" | sed -e "s/ -o//g" | sed -e "s/ -O//g" `"
options2="`echo "$ss_s2_usage" | sed -r 's/\-G[ ]+[^-]+//g' | sed -r 's/\-g[ ]+[^-]+//g' | sed -r 's/\-O[ ]+[^-]+//g' | sed -r 's/\-o[ ]+[^-]+//g' | sed -e "s/ -g//g" | sed -e "s/ -G//g" | sed -e "s/ -o//g" | sed -e "s/ -O//g" `"

ss_usage="`echo "$ss_usage" | sed -r 's/\--[^ ]+[^-]+//g'`"
ss_s2_usage="`echo "$ss_s2_usage" | sed -r 's/\--[^ ]+[^-]+//g'`"

# 启动程序
/tmp/SSJSON.sh -f /tmp/ss-redir_1.json $ss_usage $ss_usage_json -s $ss_s1_ip -p $ss_s1_port -l 1090 -b 0.0.0.0 -a 3 -k ss_s1_key -m $ss_s1_method -h ss_plugin_config
killall_ss_redir
ss-redir -c /tmp/ss-redir_1.json $options1 &
if [ ! -z $ss_server2 ] ; then
	#启动第二个SS 连线
	[  -z "$ss_s2_ip" ] && { logger -t "【SS】" "[错误!!] 无法获得 SS 服务器2的IP, 请核查设置"; stop_SS; clean_SS; }
	logger -t "【SS】" "SS服务器2 设置内容：$ss_server2 端口:$ss_s2_port 加密方式:$ss_s2_method "
	/tmp/SSJSON.sh -f /tmp/ss-redir_2.json $ss_s2_usage $ss_s2_usage_json -s $ss_s2_ip -p $ss_s2_port -l 1091 -b 0.0.0.0 -a 3 -k ss_s2_key -m $ss_s2_method -h ss2_plugin_config
	ss-redir -c /tmp/ss-redir_2.json $options2 &
fi
if [ "$ss_mode_x" = "3" ] || [ "$ss_run_ss_local" = "1" ] ; then
	logger -t "【ss-local】" "启动所有的 ss-local 连线, 出现的 SS 日志并不是错误报告, 只是使用状态日志, 请不要慌张, 只要系统正常你又看不懂就无视它！"
	logger -t "【ss-local】" "本地监听地址：$ss_s1_local_address 本地代理端口：$ss_s1_local_port SS服务器1 设置内容：$ss_server1 端口:$ss_s1_port 加密方式:$ss_s1_method "
	/tmp/SSJSON.sh -f /tmp/ss-local_1.json $ss_usage $ss_usage_json -s $ss_s1_ip -p $ss_s1_port -b $ss_s1_local_address -l $ss_s1_local_port -a 3 -k ss_s1_key -m $ss_s1_method -h ss_plugin_config
	killall_ss_local
	ss-local -c /tmp/ss-local_1.json $options1 &
	if [ ! -z $ss_server2 ] ; then
		#启动第二个SS 连线
		[  -z "$ss_s2_ip" ] && { logger -t "【ss-local】" "[错误!!] 无法获得 SS 服务器2的IP,请核查设置"; stop_SS; clean_SS; }
		logger -t "【ss-local】" "本地监听地址：$ss_s2_local_address 本地代理端口：$ss_s2_local_port SS服务器2 设置内容：$ss_server2 端口:$ss_s2_port 加密方式:$ss_s2_method "
		/tmp/SSJSON.sh -f /tmp/ss-local_2.json $ss_s2_usage $ss_s2_usage_json -s $ss_s2_ip -p $ss_s2_port -b $ss_s2_local_address -l $ss_s2_local_port -a 3 -k ss_s2_key -m $ss_s2_method -h ss2_plugin_config
		ss-local -c /tmp/ss-local_2.json $options2 &
	fi
fi

}

start_ss_redir_check()
{

sleep 2
[ ! -z "`pidof ss-redir`" ] && logger -t "【SS】" "启动成功" && ss_restart o
[ -z "`pidof ss-redir`" ] && logger -t "【SS】" "启动失败, 注意检查端口是否有冲突,程序是否下载完整,10 秒后自动尝试重新启动" && sleep 10 && ss_restart x
check_ip
if [ "$ss_mode_x" = "3" ] || [ "$ss_run_ss_local" = "1" ] ; then
	[ "$ss_mode_x" = "3" ] && killall_ss_redir
	[ ! -z "`pidof ss-local`" ] && logger -t "【ss-local】" "启动成功" && ss_restart o
	[ -z "`pidof ss-local`" ] && logger -t "【ss-local】" "启动失败, 注意检查端口是否有冲突,程序是否下载完整,10 秒后自动尝试重新启动" && sleep 10 && ss_restart x
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

# 重载rules规则
ipset -! restore <<-EOF
create ss_spec_dst_sp hash:net hashsize 64
$(gen_special_purpose_ip | sed -e "s/^/add ss_spec_dst_sp /")
EOF

# 启动新进程
start_ss_redir
start_ss_redir_check

port=$(iptables -t nat -L | grep 'SS_SPEC' | wc -l)
if [ "$port"x = 0x ] ; then
	logger -t "【SS】" "检测1:找不到 SS_SPEC 转发规则, 重新添加"
	eval "$scriptfilepath rules &"
fi

}
check_ssr()
{

if [ "$ssrr_type" = "1" ] ; then 
logger -t "【SS】" "高级启动参数选项内容含有 ssrr 协议: $ssrr_custom $ssrr_s2_custom"
ssrr_type=1
fi
umount -l /usr/sbin/ss-redir
umount -l /usr/sbin/ss-local
if [ "$ss_type" != "1" ] ; then
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


check_ip()
{
ss_check=`nvram get ss_check`
if [ "$ss_check" = "1" ] ; then
	# 检查主服务器是否能用
	checkip=0
	sleep 1
	for action_port in 1090 1091
	do
		action_port=$action_port
		echo $action_port
		[ $action_port == 1090 ] && action_ssip=$ss_s1_ip
		[ $action_port == 1091 ] && action_ssip=$ss_s2_ip
		[ $action_port == 1090 ] && Server_ip=$ss_server1 && CURRENT_ip=$ss_server2
		[ $action_port == 1091 ] && Server_ip=$ss_server2 && CURRENT_ip=$ss_server1
		if [ ! -z "$action_ssip" ] ; then
			logger -t "【ss-redir】" "check_ip 检查 SS 服务器$action_port是否能用"
			lan_ipaddr=`nvram get lan_ipaddr`
			[ -z "$kcptun_server" ] && BP_IP="$ss_s1_ip,$ss_s2_ip"
			[ ! -z "$kcptun_server" ] && BP_IP="$ss_s1_ip,$ss_s2_ip,$kcptun_server"
			ss-rules -s "$action_ssip" -l "$action_port" -b $BP_IP -d "RETURN" -a "g,$lan_ipaddr" -e '-m multiport --dports 80,8080,53,5353' -o -O
			sleep 1
			check=0
			hash check_network 2>/dev/null && check=1
			if [ "$check" == "1" ] ; then
				check_network 1
				[ "$?" == "0" ] && check=200 || { check=404; sleep 1; }
				if [ "$check" == "404" ] ; then
					check_network 1
					[ "$?" == "0" ] && check=200 || check=404
				fi
				logger -t "【ss-redir】" "check_network 检查 Google.com : $check"
				ss_link_1_tmp=Google.com
			fi
			hash check_network 2>/dev/null || check=404
			if [ "$check" == "404" ] ; then
				curltest=`which curl`
				if [ -z "$curltest" ] || [ ! -s "`which curl`" ] ; then
					wget --no-check-certificate -q -T 10 "$ss_link_1" -O /dev/null
					[ "$?" == "0" ] && check=200 || { check=404; sleep 1; }
					if [ "$check" == "404" ] ; then
						wget --no-check-certificate -q -T 10 "$ss_link_1" -O /dev/null
						[ "$?" == "0" ] && check=200 || check=404
					fi
					logger -t "【ss-redir】" "wget  检查 $ss_link_1 : $check"
				else
					check=`curl -k -s -w "%{http_code}" "$ss_link_1" -o /dev/null`
					[ "$check" != "200" ] && sleep 1
					[ "$check" != "200" ] && check=`curl -k -s -w "%{http_code}" "$ss_link_1" -o /dev/null`
					logger -t "【ss-redir】" "curl  检查 $ss_link_1 : $check"
				fi
				ss_link_1_tmp=$ss_link_1
			fi
			if [ "$check" == "200" ] ; then
				hash check_network 2>/dev/null && logger -t "【ss-redir】" "check_ip 检查 SS 服务器 $Server_ip 【$action_port】 代理连接 $ss_link_1_tmp 成功"
				hash check_network 2>/dev/null || logger -t "【ss-redir】" "check_ip 检查 SS 服务器 $Server_ip 【$action_port】 代理连接 $ss_link_1 成功"
				checkip=1
			else
				hash check_network 2>/dev/null && logger -t "【ss-redir】" "check_ip 检查 SS 服务器 $Server_ip 【$action_port】 代理连接 $ss_link_1_tmp 失败"
				hash check_network 2>/dev/null || logger -t "【ss-redir】" "check_ip 检查 SS 服务器 $Server_ip 【$action_port】 代理连接 $ss_link_1 失败"
				[ ${action_port:=1090} ] && [ $action_port == 1091 ] && Server=1090 || Server=1091
				#加上切换标记
				nvram set ss_working_port=$Server
				ss_working_port=`nvram get ss_working_port`
				[ "$checkip" == "0" ] && checkip=0
			fi
		fi
		ss-rules -f
	done
	echo "checkip: "$checkip
	if [ "$checkip" == "0" ] ; then
		logger -t "【ss-redir】" "check_ip 检查两个 SS 服务器代理连接失败, 请检查配置, 10 秒后重启shadowsocks"
		killall_ss_local
		killall_ss_redir
		sleep 10
		clean_SS 
		exit 0
	fi
fi

}

start_dnsproxy()
{

logger -t "【SS】" "启动 dnsproxy 防止域名污染"
pidof dnsproxy >/dev/null 2>&1 && killall dnsproxy && killall -9 dnsproxy 2>/dev/null
pidof pdnsd >/dev/null 2>&1 && killall pdnsd && killall -9 pdnsd 2>/dev/null
if [ -s /sbin/dnsproxy ] ; then
	/sbin/dnsproxy -d
else
	dnsproxy -d
fi
}

start_pdnsd()
{
if [ "$ss_dnsproxy_x" = "0" ] ; then
	hash dnsproxy 2>/dev/null && dnsproxy_x="1"
	hash dnsproxy 2>/dev/null || dnsproxy_x="0"
	if [ "$dnsproxy_x" = "1" ] ; then
		start_dnsproxy
		return
	else
		ss_dnsproxy_x=1 && nvram set ss_dnsproxy_x=1
	fi
fi
if [ "$ss_dnsproxy_x" = "1" ] ; then
logger -t "【SS】" "启动 pdnsd 防止域名污染"
pidof dnsproxy >/dev/null 2>&1 && killall dnsproxy && killall -9 dnsproxy 2>/dev/null
pidof pdnsd >/dev/null 2>&1 && killall pdnsd && killall -9 pdnsd 2>/dev/null
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
fi
if [ "$ss_dnsproxy_x" = "2" ] && [ -s /etc/storage/script/Sh19_chinadns.sh ] ; then
	/etc/storage/script/Sh19_chinadns.sh stop
	logger -t "【SS】" "使用 dnsmasq ，自动开启 ChinaDNS 防止域名污染"
	nvram set app_1=1
	nvram set chinadns_status=""
	/etc/storage/script/Sh19_chinadns.sh
	sleep 5
fi
}


clean_ss_rules()
{
echo "clean_ss_rules"
flush_r
	ipset destroy gfwlist
	iptables -t nat -D OUTPUT -p tcp -d 8.8.8.8,8.8.4.4 --dport 53 -j REDIRECT --to-port 1090
	iptables -t nat -D OUTPUT -p tcp -d 208.67.222.222,208.67.220.220 --dport 443 -j REDIRECT --to-port 1090
	iptables -t nat -D OUTPUT -p tcp -d 8.8.8.8,8.8.4.4 --dport 53 -j REDIRECT --to-port 1091
	iptables -t nat -D OUTPUT -p tcp -d 208.67.222.222,208.67.220.220 --dport 443 -j REDIRECT --to-port 1091
	iptables -t nat -D OUTPUT -p tcp -d 8.8.8.8,8.8.4.4 --dport 53 -j RETURN
	iptables -t nat -D OUTPUT -p tcp -d 208.67.222.222,208.67.220.220 --dport 443 -j RETURN
}

flush_r() {
	iptables-save -c | sed  "s/webstr--url/webstr --url/g" | grep -v "$TAG" | iptables-restore -c
	ip rule del fwmark 1 lookup 100 2>/dev/null
	ip route del local default dev lo table 100 2>/dev/null
	for setname in $(ipset -n list | grep -i "$TAG"); do
		ipset destroy $setname 2>/dev/null
	done
	[ -n "$FWI" ] && echo '#!/bin/sh' >$FWI
	return 0
}

start_ss_rules()
{
#载入iptables模块
for module in ip_set ip_set_bitmap_ip ip_set_bitmap_ipmac ip_set_bitmap_port ip_set_hash_ip ip_set_hash_ipport ip_set_hash_ipportip ip_set_hash_ipportnet ip_set_hash_net ip_set_hash_netport ip_set_list_set xt_set xt_TPROXY
do
	modprobe $module
done 
logger -t "【SS】" "设置 SS 的防火墙规则"
clean_ss_rules
echo "start_ss_rules"
#内网LAN代理转发白名单设置
#	0  默认值, 常规, 未在以下设定的 内网IP 根据 SS配置工作模式 走 SS
#	1		 全局, 未在以下设定的 内网IP 使用全局代理 走 SS
#	2		 绕过, 未在以下设定的 内网IP 不使用 SS
mkdir /tmp/ss -p
if [ -n "$LAN_AC_IP" ] ; then
	case "${LAN_AC_IP:0:1}" in
		0)
			LAN_TARGET="SS_SPEC_WAN_AC"
			DNS_LAN_TARGET="SS_SPEC_DNS_WAN_AC"
			;;
		1)
			LAN_TARGET="SS_SPEC_WAN_FW"
			DNS_LAN_TARGET="SS_SPEC_DNS_WAN_FW"
			;;
		2)
			LAN_TARGET="RETURN"
			DNS_LAN_TARGET="RETURN"
			;;
	esac
fi

#如果是 gfwlist 模式，则 gfwlist 为 ipash，chnroute 模式，则为 hash:net模式
ipset -! -N gfwlist iphash
ipset -! -N cflist iphash

# rules规则
ipset -! restore <<-EOF
create ss_spec_src_ac hash:ip hashsize 64
create ss_spec_src_bp hash:ip hashsize 64
create ss_spec_src_fw hash:ip hashsize 64
create ss_spec_dst_sp hash:net hashsize 64
create ss_spec_dst_bp hash:net hashsize 64
create ss_spec_dst_fw hash:net hashsize 64
create ss_spec_dst_sh hash:net hashsize 64
create ss_spec_src_gfw hash:net hashsize 64
create ss_spec_src_chn hash:net hashsize 64
$(gen_special_purpose_ip | sed -e "s/^/add ss_spec_dst_sp /")
EOF

if [ "$ss_tochina_enable" = "0" ] ; then
# 出国模式
	logger -t "【SS】" "出国模式" && echo "ss_tochina_enable:$ss_tochina_enable"
	SH_TARGET="RETURN"
	WAN_TARGET="SS_SPEC_WAN_FW"
else
# 回国模式
	logger -t "【SS】" "回国模式" && echo "ss_tochina_enable:$ss_tochina_enable"
	SH_TARGET="SS_SPEC_WAN_FW"
	WAN_TARGET="RETURN"
fi

if [ "$ss_mode_x" = "0" ] ; then
# 0 为 chnroute 规则
	MODE_TARGET="SS_SPEC_WAN_CHN"
	if [ "$kcptun2_enable" = "1" ] ; then
		# Kcptun_enable
		logger -t "【SS】" "备服务器 同时启用 GFW 规则代理"
		MODE_TARGET="SS_SPEC_WAN_CHNGFW"
		GFWLIST_TARGET="SS_SPEC_WAN_KCPTUN"
	fi
	if [ -f /tmp/ss/chnroute.txt ] ; then
		ipset flush ss_spec_dst_sh
		grep -v '^#' /tmp/ss/chnroute.txt | sort -u | grep -v "^$" | sed -e "s/^/-A ss_spec_dst_sh &/g" | ipset -R -!
	fi
fi

if [ "$ss_mode_x" = "1" ] ; then
	MODE_TARGET="SS_SPEC_WAN_GFW"
# 1 为 gfwlist 规则
	GFWLIST_TARGET="SS_SPEC_WAN_FW"
fi

if [ "$ss_mode_x" = "2" ] ; then
# 2 为 全局 规则
	MODE_TARGET="SS_SPEC_WAN_FW"
	#LAN_TARGET="SS_SPEC_WAN_FW"
fi

# /etc/storage/shadowsocks_config_script.sh
# 内网(LAN)IP设定行为设置, 格式如 b,192.168.1.23, 多个值使用空格隔开
#   使用 b/g/n 前缀定义主机行为模式, 使用英文逗号与主机 IP 分隔
#   b: 绕过, 此前缀的主机IP 不使用 SS
#   g: 全局, 此前缀的主机IP 使用 全局代理 走 SS
#   n: 常规, 此前缀的主机IP 使用 SS配置工作模式 走 SS
#   1: 大陆白名单, 此前缀的主机IP 使用 大陆白名单模式 走 SS
#   2: gfwlist, 此前缀的主机IP 使用 gfwlist模式 走 SS
logger -t "【SS】" "设置内网(LAN)访问控制"
grep -v '^#' /etc/storage/shadowsocks_ss_spec_lan.sh | sort -u | grep -v "^$" | sed s/！/!/g > /tmp/ss_spec_lan.txt
while read line
do
for host in $line; do
	case "${host:0:1}" in
		n|N)
			ipset add ss_spec_src_ac ${host:2}
			;;
		b|B)
			ipset add ss_spec_src_bp ${host:2}
			;;
		g|G)
			ipset add ss_spec_src_fw ${host:2}
			;;
		1|1)
			ipset add ss_spec_src_chn ${host:2}
			;;
		2|2)
			ipset add ss_spec_src_gfw ${host:2}
			;;
	esac
done
done < /tmp/ss_spec_lan.txt

# 加载 nat 规则
nvram set ss_internet="2"
ss_working_port=`nvram get ss_working_port`
echo "ss_multiport:$ss_multiport"
EXT_ARGS_TCP="$ss_multiport"
include_ac_rules nat
include_ac_rules2 nat
get_wifidognx
gen_prerouting_rules nat $wifidognx
dns_redirect
iptables -t nat -A SS_SPEC_WAN_KCPTUN -p tcp -j REDIRECT --to-port 1091
iptables -t nat -A SS_SPEC_WAN_FW -p tcp -j REDIRECT --to-port $ss_working_port
wifidognx=""
wifidogn=`iptables -t nat -L OUTPUT --line-number | grep Outgoing | awk '{print $1}' | awk 'END{print $1}'`  ## Outgoing
if [ -z "$wifidogn" ] ; then
	wifidogn=`iptables -t nat -L OUTPUT --line-number | grep vserver | awk '{print $1}' | awk 'END{print $1}'`  ## vserver
	if [ -z "$wifidogn" ] ; then
		wifidognx=1
	else
		wifidognx=`expr $wifidogn + 1`
	fi
else
	wifidognx=`expr $wifidogn + 1`
fi
iptables -t nat -N SS_SPEC_WAN_DG
iptables -t nat -A SS_SPEC_WAN_DG -m set --match-set ss_spec_dst_sp dst -j RETURN
iptables -t nat -A SS_SPEC_WAN_DG -p tcp $EXT_ARGS_TCP -j SS_SPEC_WAN_AC
iptables -t nat -I OUTPUT $wifidognx -p tcp -j SS_SPEC_WAN_DG

if [ "$koolproxy_enable" != "0" ] ; then
# 加载 kp过滤方案 规则
logger -t "【SS】" "设置内网(LAN)访问控制【kp过滤方案】"
grep -v '^#' /etc/storage/shadowsocks_ss_spec_lan.sh | sort -u | grep -v "^$" | sed s/！/!/g > /tmp/ss_spec_lan.txt
while read line
do
for host in $line; do
	case "${host:0:1}" in
		1|1)
			iptables -t nat -I SS_SPEC_WAN_DG 2 -p tcp -m mark --mark $(echo ${host:2} | awk -F "." '{printf ("0x%02x", $1)} {printf ("%02x", $2)} {printf ("%02x", $3)} {printf ("00/0xffffff00\n")}') $EXT_ARGS_TCP -j SS_SPEC_WAN_CHN
			;;
		2|2)
			iptables -t nat -I SS_SPEC_WAN_DG 2 -p tcp -m mark --mark $(echo ${host:2} | awk -F "." '{printf ("0x%02x", $1)} {printf ("%02x", $2)} {printf ("%02x", $3)} {printf ("00/0xffffff00\n")}') $EXT_ARGS_TCP -j SS_SPEC_WAN_GFW
			;;
		n|N)
			iptables -t nat -I SS_SPEC_WAN_DG 2 -p tcp -m mark --mark $(echo ${host:2} | awk -F "." '{printf ("0x%02x", $1)} {printf ("%02x", $2)} {printf ("%02x", $3)} {printf ("00/0xffffff00\n")}') $EXT_ARGS_TCP -j SS_SPEC_WAN_AC
			;;
		g|G)
			iptables -t nat -I SS_SPEC_WAN_DG 2 -p tcp -m mark --mark $(echo ${host:2} | awk -F "." '{printf ("0x%02x", $1)} {printf ("%02x", $2)} {printf ("%02x", $3)} {printf ("00/0xffffff00\n")}') $EXT_ARGS_TCP -j SS_SPEC_WAN_FW
			;;
		b|B)
			iptables -t nat -I SS_SPEC_WAN_DG 2 -p tcp -m mark --mark $(echo ${host:2} | awk -F "." '{printf ("0x%02x", $1)} {printf ("%02x", $2)} {printf ("%02x", $3)} {printf ("00/0xffffff00\n")}') -j RETURN
			;;
	esac
done
done < /tmp/ss_spec_lan.txt
fi

# 加载 mangle 规则
echo "ss_upd_rules:$ss_upd_rules"
EXT_ARGS_UDP="$ss_upd_rules"
if [ "$ss_udp_enable" == 1 ] ; then
	ip rule add fwmark 1 lookup 100
	ip route add local default dev lo table 100
	include_ac_rules mangle
	include_ac_rules2 mangle
	get_wifidognx_mangle
	gen_prerouting_rules mangle $wifidognx
	[ "$ss_DNS_Redirect" != "1" ] && iptables -t mangle -A SS_SPEC_WAN_KCPTUN -p udp --dport 53  -m set ! --match-set ss_spec_dst_fw dst -j RETURN
	[ "$ss_DNS_Redirect" == "1" ] && iptables -t mangle -A SS_SPEC_WAN_KCPTUN -p udp --dport 53  -j RETURN
	iptables -t mangle -A SS_SPEC_WAN_KCPTUN -p udp -j TPROXY --on-port 1091 --tproxy-mark 0x01/0x01
	[ "$ss_DNS_Redirect" != "1" ] && iptables -t mangle -A SS_SPEC_WAN_FW -p udp --dport 53  -m set ! --match-set ss_spec_dst_fw dst -j RETURN
	[ "$ss_DNS_Redirect" == "1" ] && iptables -t mangle -A SS_SPEC_WAN_FW -p udp --dport 53  -j RETURN
	iptables -t mangle -A SS_SPEC_WAN_FW -p udp -j TPROXY --on-port $ss_working_port --tproxy-mark 0x01/0x01
fi
# 加载 pdnsd 规则
logger -t "【SS】" "DNS程序 $ss_dnsproxy_x 模式: $ss_pdnsd_wo_redir 【0走代理 1直连】"
echo "ss_pdnsd_wo_redir:$ss_pdnsd_wo_redir"
if [ "$ss_pdnsd_wo_redir" == 0 ] ; then
	# pdnsd 0走代理
	iptables -t nat -I OUTPUT -p tcp -d 8.8.8.8,8.8.4.4 --dport 53 -j REDIRECT --to-port $ss_working_port
	iptables -t nat -I OUTPUT -p tcp -d 208.67.222.222,208.67.220.220 --dport 443 -j REDIRECT --to-port $ss_working_port
else
	# pdnsd 1直连
	iptables -t nat -I OUTPUT -p tcp -d 8.8.8.8,8.8.4.4 --dport 53 -j RETURN
	iptables -t nat -I OUTPUT -p tcp -d 208.67.222.222,208.67.220.220 --dport 443 -j RETURN
fi

nvram set ss_internet="1"
ss_working_port=`nvram get ss_working_port`
[ $ss_working_port == 1090 ] && ss_info="SS_[1]"
[ $ss_working_port == 1091 ] && ss_info="SS_[2]"
nvram set button_script_2_s="$ss_info"

# 外网(WAN)访问控制
	logger -t "【SS】" "外网(WAN)访问控制，设置 WAN IP 转发或忽略代理中转"
	sed -e '/.*opt.cn2qq.com/d' -i /etc/storage/shadowsocks_ss_spec_wan.sh
	echo "WAN!opt.cn2qq.com" >> /etc/storage/shadowsocks_ss_spec_wan.sh
	speedup_enable=`nvram get app_10`
	[ -z $speedup_enable ] && speedup_enable=0 && nvram set app_10=0
	if [ "$speedup_enable" != "0" ] ; then
		sed -e '/.*api.cloud.189.cn/d' -i /etc/storage/shadowsocks_ss_spec_wan.sh
		echo "WAN!api.cloud.189.cn" >> /etc/storage/shadowsocks_ss_spec_wan.sh
	fi
	grep -v '^#' /etc/storage/shadowsocks_ss_spec_wan.sh | sort -u | grep -v "^$" | sed s/！/!/g > /tmp/ss_spec_wan.txt
	sed -e '/.*members.3322.org/d' -i /tmp/ss_spec_wan.txt
	echo "WAN!members.3322.org" >> /tmp/ss_spec_wan.txt
	sed -e '/.*www.cloudxns.net/d' -i /tmp/ss_spec_wan.txt
	echo "WAN!www.cloudxns.net" >> /tmp/ss_spec_wan.txt
	sed -e '/.*dnsapi.cn/d' -i /tmp/ss_spec_wan.txt
	echo "WAN!dnsapi.cn" >> /tmp/ss_spec_wan.txt
	sed -e '/.*api.dnspod.com/d' -i /tmp/ss_spec_wan.txt
	echo "WAN!api.dnspod.com" >> /tmp/ss_spec_wan.txt
	sed -e '/.*www.ipip.net/d' -i /tmp/ss_spec_wan.txt
	echo "WAN!www.ipip.net" >> /tmp/ss_spec_wan.txt
	sed -e '/.*alidns.aliyuncs.com/d' -i /tmp/ss_spec_wan.txt
	echo "WAN!alidns.aliyuncs.com" >> /tmp/ss_spec_wan.txt
	sed -e '/.*googleapis.cn/d' -i /tmp/ss_spec_wan.txt
	echo "WAN!googleapis.cn" >> /tmp/ss_spec_wan.txt
	rm -f /tmp/ss/wantoss.list
	rm -f /tmp/ss/wannoss.list
	while read line
	do
	del_line=`echo $line |grep "WAN@"`
	if [ ! -z "$del_line" ] ; then
		del_line=`echo $del_line | sed s/WAN@//g` #WAN@开头的 域名 使用 代理中转
		/usr/bin/resolveip -4 -t 4 $del_line | grep -v :  > /tmp/ss/tmp.list
		[ ! -s /tmp/ss/tmp.list ] && arNslookup $del_line | sort -u | grep -v "^$"  >> /tmp/ss/wantoss.list
		[ -s /tmp/ss/tmp.list ] && cat /tmp/ss/tmp.list| sort -u | grep -v "^$" >> /tmp/ss/wantoss.list && echo "" > /tmp/ss/tmp.list
	fi
	add_line=`echo $line |grep "WAN!"`
	if [ ! -z "$add_line" ] ; then
		add_line=`echo $add_line | sed s/WAN!//g` #WAN!开头的 域名 忽略 代理中转
		/usr/bin/resolveip -4 -t 4 $add_line | grep -v :  > /tmp/ss/tmp.list
		[ ! -s /tmp/ss/tmp.list ] && arNslookup $add_line | sort -u | grep -v "^$"  >> /tmp/ss/wannoss.list
		[ -s /tmp/ss/tmp.list ] && cat /tmp/ss/tmp.list| sort -u | grep -v "^$" >> /tmp/ss/wannoss.list && echo "" > /tmp/ss/tmp.list
	fi
		net_line=`echo $line |grep "WAN+"`
	if [ ! -z "$net_line" ] ; then
		net_line=`echo $net_line | sed s/WAN+//g` #WAN+开头的 IP网段/掩码 使用 代理
		echo $net_line  >> /tmp/ss/wantoss.list
	fi
		net_line=`echo $line |grep "WAN-"`
	if [ ! -z "$net_line" ] ; then
		net_line=`echo $net_line | sed s/WAN-//g` #WAN-开头的 IP网段/掩码 忽略 代理
		echo $net_line  >> /tmp/ss/wannoss.list
	fi
	done < /tmp/ss_spec_wan.txt
	
# 加载telegram网段
cat >> "/tmp/ss/wantoss.list" <<-\TELEGRAM
91.108.56.0/22
91.108.4.0/22
109.239.140.0/24
149.154.160.0/20
TELEGRAM

# 当启动【海外加速】加载以下网段
if [ "$ss_sub1" = "1" ] ; then
cat >> "/tmp/ss/wantoss.list" <<-\WHATSAPP
31.13.64.51/32
31.13.65.49/32
31.13.66.49/32
31.13.67.51/32
31.13.68.52/32
31.13.69.240/32
31.13.70.49/32
31.13.71.49/32
31.13.72.52/32
31.13.73.49/32
31.13.74.49/32
31.13.75.52/32
31.13.76.81/32
31.13.77.49/32
31.13.78.53/32
31.13.79.195/32
31.13.80.53/32
31.13.81.53/32
31.13.82.51/32
31.13.83.51/32
31.13.84.51/32
31.13.85.51/32
31.13.86.51/32
31.13.87.51/32
31.13.88.49/32
31.13.90.51/32
31.13.91.51/32
31.13.92.52/32
31.13.93.51/32
31.13.94.52/32
31.13.95.63/32
50.22.198.204/30
50.22.210.32/30
50.22.210.128/27
50.22.225.64/27
50.22.235.248/30
50.22.240.160/27
50.23.90.128/27
50.97.57.128/27
75.126.39.32/27
108.168.174.0/27
108.168.176.192/26
108.168.177.0/27
108.168.180.96/27
108.168.254.65/32
108.168.255.224/32
108.168.255.227/32
158.85.0.96/27
158.85.5.192/27
158.85.46.128/27
158.85.48.224/27
158.85.58.0/25
158.85.61.192/27
158.85.224.160/27
158.85.233.32/27
158.85.249.128/27
158.85.249.224/27
158.85.254.64/27
169.44.36.0/25
169.44.57.64/27
169.44.58.64/27
169.44.80.0/26
169.44.82.96/27
169.44.82.128/27
169.44.82.192/26
169.44.83.0/26
169.44.83.96/27
169.44.83.128/27
169.44.83.192/26
169.44.84.0/24
169.44.85.64/27
169.45.71.32/27
169.45.71.96/27
169.45.87.128/26
169.45.169.192/27
169.45.182.96/27
169.45.210.64/27
169.45.214.224/27
169.45.219.224/27
169.45.237.192/27
169.45.238.32/27
169.45.248.96/27
169.45.248.160/27
169.53.29.128/27
169.53.48.32/27
169.53.71.224/27
169.53.250.128/26
169.53.252.64/27
169.53.255.64/27
169.54.2.160/27
169.54.44.224/27
169.54.51.32/27
169.54.55.192/27
169.54.193.160/27
169.54.210.0/27
169.54.222.128/27
169.55.69.128/26
169.55.74.32/27
169.55.126.64/26
169.55.210.96/27
169.55.235.160/27
173.192.162.32/27
173.192.219.128/27
173.192.222.160/27
173.192.231.32/27
173.193.205.0/27
173.193.230.96/27
173.193.230.128/27
173.193.230.192/27
173.193.239.0/27
174.36.208.128/27
174.36.210.32/27
174.36.251.192/27
174.37.199.192/27
174.37.217.64/27
174.37.231.64/27
174.37.243.64/27
174.37.251.0/27
179.60.192.51/32
179.60.193.51/32
179.60.195.51/32
184.173.136.64/27
184.173.147.32/27
184.173.161.64/32
184.173.161.160/27
184.173.173.116/32
184.173.179.32/27
185.60.216.53/32
192.155.212.192/27
198.11.193.182/31
198.11.251.32/27
198.23.80.0/27
208.43.115.192/27
208.43.117.79/32
208.43.122.128/27
31.13.0.0/16
50.22.0.0/15
50.97.0.0/16
75.126.0.0/16
108.168.0.0/16
158.85.0.0/16
169.32.0.0/11
173.192.0.0/15
174.36.0.0/15
179.60.0.0/16
184.173.0.0/16
192.155.212.0/24
198.11.0.0/16
198.22.0.0/16
208.43.0.0/16
WHATSAPP
fi
	if [ -s "/tmp/ss/wannoss.list" ] ; then
		sed -e "s/^/-A ss_spec_dst_bp &/g" -e "1 i\-N ss_spec_dst_bp hash:net " /tmp/ss/wannoss.list | ipset -R -!
	fi
	if [ -s "/tmp/ss/wantoss.list" ] ; then
		sed -e "s/^/-A ss_spec_dst_fw &/g" -e "1 i\-N ss_spec_dst_fw hash:net " /tmp/ss/wantoss.list | ipset -R -!
	fi
	logger -t "【SS】" "完成 SS 转发规则设置"
	gen_include
}

dns_redirect() {
	# 强制使用路由的DNS
	lan_ipaddr=`nvram get lan_ipaddr`
	if [ "$ss_DNS_Redirect" == "1" ] && [ ! -z "$lan_ipaddr" ] ; then
	iptables-restore -n <<-EOF
*nat
:SS_SPEC_DNS_LAN_DG - [0:0]
:SS_SPEC_DNS_LAN_AC - [0:0]
:SS_SPEC_DNS_WAN_AC - [0:0]
:SS_SPEC_DNS_WAN_FW - [0:0]
-A SS_SPEC_DNS_LAN_DG -d $lan_ipaddr -p udp -j RETURN
-A SS_SPEC_DNS_LAN_DG -d $ss_DNS_Redirect_IP -p udp -j RETURN
-A SS_SPEC_DNS_LAN_DG -j SS_SPEC_DNS_LAN_AC
-A SS_SPEC_DNS_LAN_AC -m set --match-set ss_spec_src_bp src -j RETURN
-A SS_SPEC_DNS_LAN_AC -m set --match-set ss_spec_src_fw src -j SS_SPEC_DNS_WAN_FW
-A SS_SPEC_DNS_LAN_AC -m set --match-set ss_spec_src_ac src -j SS_SPEC_DNS_WAN_AC
-A SS_SPEC_DNS_LAN_AC -m set --match-set ss_spec_src_gfw src -j SS_SPEC_DNS_WAN_AC
-A SS_SPEC_DNS_LAN_AC -m set --match-set ss_spec_src_chn src -j SS_SPEC_DNS_WAN_AC
-A SS_SPEC_DNS_LAN_AC -j ${DNS_LAN_TARGET:=SS_SPEC_DNS_WAN_AC}
-A SS_SPEC_DNS_WAN_AC -j SS_SPEC_DNS_WAN_FW
COMMIT
EOF
		logger -t "【SS】" "udp53端口（DNS）地址重定向为 $ss_DNS_Redirect_IP 强制使用重定向地址的DNS"
		iptables -t nat -A PREROUTING -s $lan_ipaddr/24 -p udp --dport 53 -j SS_SPEC_DNS_LAN_DG
		iptables -t nat -A SS_SPEC_DNS_WAN_FW -j DNAT --to $ss_DNS_Redirect_IP
	fi

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
if [ -s /tmp/arNslookup/$$ ] ; then
cat /tmp/arNslookup/$$ | sort -u | grep -v "^$"
rm -f /tmp/arNslookup/$$
else
	curltest=`which curl`
	if [ -z "$curltest" ] || [ ! -s "`which curl`" ] ; then
		Address="`wget --no-check-certificate --quiet --output-document=- http://119.29.29.29/d?dn=$1`"
		if [ $? -eq 0 ]; then
		echo "$Address" |  sed s/\;/"\n"/g | grep -E -o '([0-9]+\.){3}[0-9]+'
		fi
	else
		Address="`curl -k http://119.29.29.29/d?dn=$1`"
		if [ $? -eq 0 ]; then
		echo "$Address" |  sed s/\;/"\n"/g | grep -E -o '([0-9]+\.){3}[0-9]+'
		fi
	fi
fi
}

if [ "$ss_enable" != "0" ] ; then
	kcptun_server=`nvram get kcptun_server`
	if [ "$kcptun_enable" != "0" ] ; then
		resolveip=`/usr/bin/resolveip -4 -t 4 $kcptun_server | grep -v : | sed -n '1p'`
		[ -z "$resolveip" ] && resolveip=`arNslookup $kcptun_server | sed -n '1p'` 
		kcptun_server=$resolveip
	fi
fi

gen_special_purpose_ip() {
#处理肯定不走通道的目标网段
lan_ipaddr=`nvram get lan_ipaddr`
kcptun_enable=`nvram get kcptun_enable`
[ -z $kcptun_enable ] && kcptun_enable=0 && nvram set kcptun_enable=0
kcptun_server=`nvram get kcptun_server`
if [ "$kcptun_enable" != "0" ] && [ -z "$kcptun_server" ] ; then
resolveip=`/usr/bin/resolveip -4 -t 4 $kcptun_server | grep -v : | sed -n '1p'`
[ -z "$resolveip" ] && resolveip=`arNslookup $kcptun_server | sed -n '1p'` 
kcptun_server=$resolveip
fi
[ "$kcptun_enable" = "0" ] && kcptun_server=""
if [ "$ss_enable" != "0" ] && [ -z "$ss_s1_ip" ] ; then
if [ -z $(echo $ss_server1 | grep : | grep -v "\.") ] ; then 
resolveip=`/usr/bin/resolveip -4 -t 4 $ss_server1 | grep -v : | sed -n '1p'`
[ -z "$resolveip" ] && resolveip=`arNslookup $ss_server1 | sed -n '1p'` 
ss_s1_ip=$resolveip
else
# IPv6
ss_s1_ip=$ss_server1
fi
fi
if [ ! -z "$ss_server2" ] ; then
if [ -z $(echo $ss_server2 | grep : | grep -v "\.") ] ; then 
resolveip=`/usr/bin/resolveip -4 -t 4 $ss_server2 | grep -v : | sed -n '1p'`
[ -z "$resolveip" ] && resolveip=`arNslookup $ss_server2 | sed -n '1p'` 
ss_s2_ip=$resolveip
else
# IPv6
ss_s2_ip=$ss_server2
fi
fi
v2ray_enable=`nvram get v2ray_enable`
[ -z $v2ray_enable ] && v2ray_enable=0 && nvram set v2ray_enable=0
if [ "$v2ray_enable" != "0" ] && [ ! -z "$server_addresses" ] ; then
	resolveip=`/usr/bin/resolveip -4 -t 4 $server_addresses | grep -v : | sed -n '1p'`
	[ -z "$resolveip" ] && resolveip=`arNslookup $server_addresses | sed -n '1p'` 
	server_addresses=$resolveip
	v2ray_server_addresses="$server_addresses"
else
	v2ray_server_addresses=""
fi
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
$ss_s1_ip
$ss_s2_ip
$kcptun_server
$v2ray_server_addresses
EOF
}

include_ac_rules() {
	iptables-restore -n <<-EOF
*$1
:SS_SPEC_LAN_DG - [0:0]
:SS_SPEC_LAN_AC - [0:0]
:SS_SPEC_WAN_AC - [0:0]
:SS_SPEC_WAN_FW - [0:0]
:SS_SPEC_WAN_GFW - [0:0]
:SS_SPEC_WAN_CHN - [0:0]
:SS_SPEC_WAN_CHNGFW - [0:0]
:SS_SPEC_WAN_KCPTUN - [0:0]
-A SS_SPEC_LAN_DG -m set --match-set ss_spec_dst_sp dst -j RETURN
-A SS_SPEC_LAN_DG -j SS_SPEC_LAN_AC
-A SS_SPEC_LAN_AC -m set --match-set ss_spec_src_bp src -j RETURN
-A SS_SPEC_LAN_AC -m set --match-set ss_spec_src_fw src -j SS_SPEC_WAN_FW
-A SS_SPEC_LAN_AC -m set --match-set ss_spec_src_ac src -j SS_SPEC_WAN_AC
-A SS_SPEC_LAN_AC -m set --match-set ss_spec_src_gfw src -j SS_SPEC_WAN_GFW
-A SS_SPEC_LAN_AC -m set --match-set ss_spec_src_gfw src -j RETURN
-A SS_SPEC_LAN_AC -m set --match-set ss_spec_src_chn src -j SS_SPEC_WAN_CHN
-A SS_SPEC_LAN_AC -m set --match-set ss_spec_src_chn src -j RETURN
-A SS_SPEC_LAN_AC -j ${LAN_TARGET:=SS_SPEC_WAN_AC}
-A SS_SPEC_WAN_AC -m set --match-set ss_spec_dst_fw dst -j SS_SPEC_WAN_FW
-A SS_SPEC_WAN_AC -m set --match-set ss_spec_dst_bp dst -j RETURN
-A SS_SPEC_WAN_AC -j ${MODE_TARGET:=RETURN}
-A SS_SPEC_WAN_CHN -m set --match-set ss_spec_dst_fw dst -j SS_SPEC_WAN_FW
-A SS_SPEC_WAN_CHN -m set --match-set ss_spec_dst_bp dst -j RETURN
-A SS_SPEC_WAN_CHN -m set --match-set ss_spec_dst_sh dst -j ${SH_TARGET:=RETURN}
-A SS_SPEC_WAN_CHN -j ${WAN_TARGET:=SS_SPEC_WAN_FW}
-A SS_SPEC_WAN_GFW -m set --match-set ss_spec_dst_fw dst -j SS_SPEC_WAN_FW
-A SS_SPEC_WAN_GFW -m set --match-set ss_spec_dst_bp dst -j RETURN
-A SS_SPEC_WAN_GFW -m set --match-set gfwlist dst -j ${GFWLIST_TARGET:=SS_SPEC_WAN_FW}
-A SS_SPEC_WAN_GFW -m set --match-set cflist dst -j ${GFWLIST_TARGET:=SS_SPEC_WAN_FW}
-A SS_SPEC_WAN_GFW -j RETURN
-A SS_SPEC_WAN_CHNGFW -j SS_SPEC_WAN_GFW
-A SS_SPEC_WAN_CHNGFW -j SS_SPEC_WAN_CHN
COMMIT
EOF
}

include_ac_rules2() {
grep -v '^#' /etc/storage/shadowsocks_ss_spec_lan.sh | sort -u | grep -v "^$" | grep -v "\." | sed s/！/!/g > /tmp/ss_spec_lan.txt
while read line
do
for host in $line; do
	mac="${host:2}"; mac=$(echo $mac | sed s/://g| sed s/：//g | tr '[a-z]' '[A-Z]'); mac="${mac:0:2}:${mac:2:2}:${mac:4:2}:${mac:6:2}:${mac:8:2}:${mac:10:2}";
if [ ! -z "$mac" ] ; then
	case "${host:0:1}" in
		n|N)
			iptables -t $1 -I SS_SPEC_LAN_AC -m mac --mac-source $mac -j SS_SPEC_WAN_AC
			;;
		g|G)
			iptables -t $1 -I SS_SPEC_LAN_AC -m mac --mac-source $mac -j SS_SPEC_WAN_FW
			;;
		b|B)
			iptables -t $1 -I SS_SPEC_LAN_AC -m mac --mac-source $mac -j RETURN
			;;
		1|1)
			iptables -t $1 -I SS_SPEC_LAN_AC -m mac --mac-source $mac -j SS_SPEC_WAN_CHN
			;;
		2|2)
			iptables -t $1 -I SS_SPEC_LAN_AC -m mac --mac-source $mac -j SS_SPEC_WAN_GFW
			;;
	esac
fi
done
done < /tmp/ss_spec_lan.txt

}

get_wifidognx() {
	wifidognx=""
	wifidogn=`iptables -t nat -L PREROUTING --line-number | grep AD_BYBY | awk '{print $1}' | awk 'END{print $1}'`  ## AD_BYBY
	if [ -z "$wifidogn" ] ; then
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
	else
		wifidognx=`expr $wifidogn + 1`
	fi
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

gen_prerouting_rules() {
	local protocol=$([ "$1" = "mangle" ] && echo udp $EXT_ARGS_UDP || echo tcp $EXT_ARGS_TCP )
	iptables -t $1 -I PREROUTING $2 -p $protocol -j SS_SPEC_LAN_DG
}

gen_include() {
[ -n "$FWI" ] || return 0
[ -n "$FWI" ] && echo '#!/bin/sh' >$FWI
cat <<-CAT >>$FWI
iptables-restore -n <<-EOF
$(iptables-save | sed  "s/webstr--url/webstr --url/g" | grep -E "$TAG|^\*|^COMMIT" |sed -e "s/^-A \(OUTPUT\|PREROUTING\)/-I \1 1/")
EOF
CAT
return $?
}

#获取所有被墙domain
#1 获取gfwlist 被墙列表
update_gfwlist()
{
echo "gfwlist updating"
if [ -f /tmp/cron_ss.lock ] ; then
	  logger -t "【SS】" "Other SS GFWList updating...."
else
	touch /tmp/cron_ss.lock
	mkdir -p /tmp/ss/dnsmasq.d
	logger -t "【SS】" "正在处理 gfwlist 列表，此时 SS 未能使用，请稍候...."
	sed -Ei "/conf-dir=$confdir_x/d" /etc/storage/dnsmasq/dnsmasq.conf
	[ ! -z "$confdir" ] && echo "conf-dir=$confdir" >> /etc/storage/dnsmasq/dnsmasq.conf
	echo "从代理获取list"
	rm -f $confdir/r.wantoss.conf
	cat >> "$confdir/r.wantoss.conf" <<-\_CONF
ipset=/githubusercontent.com/gfwlist
server=/githubusercontent.com/127.0.0.1#8053
ipset=/github.io/gfwlist
server=/github.io/127.0.0.1#8053
_CONF
	restart_dhcpd
	ss_updatess2=`nvram get ss_updatess2`
if [ "$ss_updatess" = "0" ] || [ "$ss_updatess2" = "1" ] ; then
	if [ "$ss_3p_enable" = "1" ] ; then
		if [ "$ss_3p_gfwlist" = "1" ] ; then
			logger -t "【SS】" "正在获取官方 gfwlist...."
			wgetcurl.sh /tmp/ss/gfwlist.b64 https://raw.githubusercontent.com/gfwlist/gfwlist/master/gfwlist.txt https://raw.githubusercontent.com/gfwlist/gfwlist/master/gfwlist.txt N
			base64 -d  /tmp/ss/gfwlist.b64 > /tmp/ss/gfwlist.txt
			cat /tmp/ss/gfwlist.txt | sort -u |
					sed '/^$\|@@/d'|
					sed 's#!.\+##; s#|##g; s#@##g; s#http:\/\/##; s#https:\/\/##;' | 
					sed '/\*/d; /apple\.com/d; /sina\.cn/d; /sina\.com\.cn/d; /baidu\.com/d; /qq\.com/d' |
					sed '/^[0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+$/d' |
					grep '^[0-9a-zA-Z\.-]\+$' | grep '\.' | sed 's#^\.\+##'  | sort -u > /tmp/ss/gfwlist_domain.txt
		fi
		if [ "$ss_3p_kool" = "1" ] ; then
			# 2 获取koolshare.github.io/maintain_files/gfwlist.conf
			logger -t "【SS】" "正在获取 koolshare 列表...."
			wgetcurl.sh /tmp/ss/gfwdomain_tmp.txt https://raw.githubusercontent.com/koolshare/koolshare.github.io/acelan_softcenter_ui/maintain_files/gfwlist.conf https://raw.githubusercontent.com/koolshare/koolshare.github.io/acelan_softcenter_ui/maintain_files/gfwlist.conf N
			cat /tmp/ss/gfwdomain_tmp.txt | sed 's/ipset=\/\.//g; s/\/gfwlist//g; /^server/d' > /tmp/ss/gfwdomain_1.txt
			# wgetcurl.sh /tmp/ss/gfwdomain_tmp.txt https://raw.githubusercontent.com/koolshare/koolshare.github.io/master/maintain_files/gfwlist.conf https://raw.githubusercontent.com/koolshare/koolshare.github.io/master/maintain_files/gfwlist.conf N
			# cat /tmp/ss/gfwdomain_tmp.txt | sed 's/ipset=\/\.//g; s/\/gfwlist//g; /^server/d' > /tmp/ss/gfwdomain_2.txt
		fi
		rm -rf /tmp/ss/gfwdomain_tmp.txt
		# /tmp/ss/gfwdomain_1.txt /tmp/ss/gfwdomain_2.txt 、koolshare以及自定义列表
	fi
	#合并多个域名列表（自定义域名，GFWLIST，自带的三个列表）
	logger -t "【SS】" "根据选项不同，分别会合并固件自带、gfwlist官方...."
	touch /etc/storage/shadowsocks_mydomain_script.sh
	cat /etc/storage/shadowsocks_mydomain_script.sh | sed '/^$\|#/d' | sed "s/http://g" | sed "s/https://g" | sed "s/\///g" | sort -u > /tmp/ss/gfwdomain_0.txt
	cat /etc/storage/basedomain.txt /tmp/ss/gfwdomain_0.txt /tmp/ss/gfwdomain_1.txt /tmp/ss/gfwlist_domain.txt | 
		sort -u > /tmp/ss/gfwall_domain.txt
else
	logger -t "【SS】" "启动时使用 固件内置list规则 列表...."
	touch /etc/storage/shadowsocks_mydomain_script.sh
	cat /etc/storage/shadowsocks_mydomain_script.sh | sed '/^$\|#/d' | sed "s/http://g" | sed "s/https://g" | sed "s/\///g" | sort -u > /tmp/ss/gfwdomain_0.txt
	cat /etc/storage/basedomain.txt /tmp/ss/gfwdomain_0.txt | 
		sort -u > /tmp/ss/gfwall_domain.txt
fi
	# 临时添加的域名
	echo "whatsapp.net" >> /tmp/ss/gfwall_domain.txt
	grep -v '^#' /etc/storage/shadowsocks_ss_spec_wan.sh | sort -u | grep -v "^$" | sed s/！/!/g > /tmp/ss_spec_wan.txt
	#删除忽略的域名
	while read line
	do
	del_line=`echo $line |grep "WAN@"`
	if [ ! -z "$del_line" ] ; then
		del_line=`echo $del_line | sed s/WAN@//g` #WAN@开头的 域名 使用 代理中转
		echo "$del_line" >> /tmp/ss/gfwall_domain.txt
	fi
	add_line=`echo $line |grep "WAN!"`
	if [ ! -z "$add_line" ] ; then
		add_line=`echo $add_line | sed s/WAN!//g` #WAN!开头的 域名 忽略 代理中转
		sed -Ei "/$add_line/d" /tmp/ss/gfwall_domain.txt
	fi
	done < /tmp/ss_spec_wan.txt

	cat /tmp/ss/gfwall_domain.txt | sort -u | grep -v "^$" > /tmp/ss/all_domain.txt

	# 到此全域名列表都已经获取完毕，开始构造dnsmasq.conf
	rm -f /tmp/ss/gfw*.txt
	rm -f $confdir/r.gfwlist.conf


#killall -9 sh_adblock_hosts.sh
#/tmp/sh_adblock_hosts.sh $confdir &

	#用awk代替文件逐行读写，速度快3倍以上。
	awk '{printf("server=/%s/127.0.0.1#8053\nipset=/%s/gfwlist\n", $1, $1 )}' /tmp/ss/all_domain.txt > $confdir/r.gfwlist.conf

	#订阅处理
	#此处订阅有3种内容, 需要在UI里面增加订阅3个列表的选项，对应 ss_sub1,2,3三个值。
	#1. 海外加速，用于直连速度慢的网站  https://coding.net/u/bigandy/p/DogcomBooster/git/raw/master/list.txt
	#2. 域名解释加速，用于有亚洲CDN，但是DNS不能正确识别中国IP返回美国服务器IP的情况，通常用于XBOX Live 联网  https://coding.net/u/bigandy/p/DogcomBooster/git/raw/master/dnsonly.txt 
	#3. 需要忽略的域名处理，用于国内有CDN的节点 https://coding.net/u/bigandy/p/DogcomBooster/git/raw/master/passby.txt
	#处理订阅了加速列表的域名
if [ "$ss_3p_enable" = "1" ] ; then
	if [ "$ss_sub1" = "1" ] ; then
		logger -t "【SS】" "处理订阅列表1...."
		wgetcurl.sh /tmp/ss/tmp_sub.txt https://coding.net/u/bigandy/p/DogcomBooster/git/raw/master/list.txt https://coding.net/u/bigandy/p/DogcomBooster/git/raw/master/list.txt N
		cat /tmp/ss/tmp_sub.txt |
			sort -u | sed 's/^[[:space:]]*//g; /^$/d; /#/d' |
			awk '{printf("server=/%s/127.0.0.1#8053\nipset=/%s/gfwlist\n", $1, $1 )}'  > $confdir/r.sub.conf
	fi
	#处理只做dns解释的域名
	if [ "$ss_sub2" = "1" ] ; then
		logger -t "【SS】" "处理订阅列表2...."
		wgetcurl.sh /tmp/ss/tmp_sub.txt https://coding.net/u/bigandy/p/DogcomBooster/git/raw/master/dnsonly.txt https://coding.net/u/bigandy/p/DogcomBooster/git/raw/master/dnsonly.txt N
		cat /tmp/ss/tmp_sub.txt |
			sort -u | sed 's/^[[:space:]]*//g; /^$/d; /#/d' |
			awk '{printf("server=/%s/127.0.0.1#8053\n", $1 )}'  >> $confdir/r.sub.conf
	fi
	#处理需要排除的域名解释
	if [ "$ss_sub3" = "1" ] ; then
		logger -t "【SS】" "处理订阅列表3...."
		DNS=`nvram get wan0_dns |cut -d ' ' -f1`
		[ -z "$DNS" ] && DNS="114.114.114.114"
	awk_cmd="awk '{printf(\"server=/%s/$DNS\\n\", \$1 )}'  >> $confdir/r.sub.conf"
	#echo $awk_cmd
	wgetcurl.sh /tmp/ss/tmp_sub.txt https://coding.net/u/bigandy/p/DogcomBooster/git/raw/master/passby.txt https://coding.net/u/bigandy/p/DogcomBooster/git/raw/master/passby.txt N
		cat /tmp/ss/tmp_sub.txt |
			sort -u | sed 's/^[[:space:]]*//g; /^$/d; /#/d' |
			eval $awk_cmd
			#awk '{printf("server=/%s/114.114.114.114\n", $1 )}'  >> $confdir/r.sub.conf
	fi
	rm -rf /tmp/ss/tmp_sub.txt
fi
	#订阅处理完成
	#删除ipset=，留下server=
	# if [ "$ss_mode_x" = "0" ] ; then
		# if [ "$kcptun2_enable" ! = "1" ] ; then
			# logger -t "【SS】" "模式一：DNSList update 重启 dnsmasq 更新列表"
			# cd $confdir
			# ls -R |awk '{print i$0}' i=`pwd`'/' | grep -v ':' > /tmp/tmp_dnsmasqd
			# while read line
			# do
				# logger -t "【SS】" "删除【ipset=】DNSList: $line"
				# sed -Ei '/ipset=/d' $line
			# done < /tmp/tmp_dnsmasqd
		# fi
		# gfwlist3=`nvram get gfwlist3`
		# Update="DNSlist"
	# else
		# gfwlist3=""
		# Update="Update: "$(date)"  GFWlist"
	# fi
	gfwlist3=`nvram get gfwlist3`
	Update="GFWlist"
	lines=`cat $confdir/* | wc -l`
	logger -t "【SS】" "GFWlist 规则 $lines 行  $gfwlist3"
	logger -t "【SS】" "所有规则处理完毕，SS即将开始工作"
	logger -t "【SS】" "GFWlist规则目录：$confdir"
	nvram set gfwlist3="$Update 规则 $lines 行  $gfwlist3"
	echo `nvram get gfwlist3`
	rm -f /tmp/cron_ss.lock
	# [ "$ss_mode_x" = "1" ] && adbyby_cflist
	# [ "$ss_mode_x" = "0" ] && [ "$kcptun2_enable" = "1" ] && adbyby_cflist
	adbyby_cflist
	logger -t "【SS】" "GFWList update 重启 dnsmasq 更新列表"
	restart_dhcpd
	ipset flush gfwlist
fi

}


update_chnroutes()
{
echo "chnroutes updating"
if [ -f /tmp/cron_ss.lock ] ; then
	logger -t "【SS】" "Other SS chnroutes updating...."
else


#killall -9 sh_adblock_hosts.sh
#/tmp/sh_adblock_hosts.sh $confdir &
# if [ "$ss_mode_x" != "2" ] ; then
	touch /tmp/cron_ss.lock
	mkdir /tmp/ss -p
	ss_updatess2=`nvram get ss_updatess2`
if [ "$ss_updatess" = "0" ] || [ "$ss_updatess2" = "1" ] ; then
	# 启动时先用高春辉的这个列表，更新交给守护进程去做。
	# 完整apnic 列表更新指令，不需要去重，ipset -! 会自动去重。此指令暂时屏蔽，这个列表获取10~90秒不等，有时候甚至卡住不动。
	# wget --no-check-certificate -q -O- 'http://ftp.apnic.net/apnic/stats/apnic/delegated-apnic-latest' | awk -F\| '/CN\|ipv4/ { printf("%s/%d\n", $4, 32-log($5)/log(2)) }' | sed -e "s/^/-A nogfwnet &/g" | ipset -R -!
	logger -t "【SS】" "下载 chnroutes"
	ip_list="ss_spec_dst_sh"
		echo ss_spec_dst_sh
		# wget --no-check-certificate -O- 'http://ftp.apnic.net/apnic/stats/apnic/delegated-apnic-latest' | awk -F\| '/CN\|ipv4/ { printf("%s/%d\n", $4, 32-log($5)/log(2)) }' > /tmp/ss/chnroute.txt
		# echo ""  >> /tmp/ss/chnroute.txt
		wgetcurl.sh /tmp/ss/tmp_chnroute.txt https://raw.githubusercontent.com/17mon/china_ip_list/master/china_ip_list.txt https://raw.githubusercontent.com/17mon/china_ip_list/master/china_ip_list.txt N
		cat /tmp/ss/tmp_chnroute.txt > /tmp/ss/chnroute.txt
		echo ""  >> /tmp/ss/chnroute.txt
		wgetcurl.sh /tmp/ss/tmp_chnroute.txt "$hiboyfile/chnroute.txt" "$hiboyfile2/chnroute.txt"
		cat /tmp/ss/tmp_chnroute.txt >> /tmp/ss/chnroute.txt
		[ ! -s /tmp/ss/chnroute.txt ] && logger -t "【SS】" "使用 固件内置chnroutes规则 列表...." && cat /etc/storage/china_ip_list.txt > /tmp/ss/chnroute.txt
else
		logger -t "【SS】" "启动时使用 固件内置chnroutes规则 列表...."
		cat /etc/storage/china_ip_list.txt > /tmp/ss/chnroute.txt
fi
		rm -rf /tmp/ss/tmp_chnroute.txt
		ipset flush ss_spec_dst_sh
		grep -v '^#' /tmp/ss/chnroute.txt | sort -u | grep -v "^$" > /tmp/ss/tmp_chnroute.txt
		mv -f /tmp/ss/tmp_chnroute.txt /tmp/ss/chnroute.txt
		grep -v '^#' /tmp/ss/chnroute.txt | sort -u | grep -v "^$" | sed -e "s/^/-A ss_spec_dst_sh &/g" | ipset -R -!
	
	nvram set gfwlist3="chnroutes规则`ipset list ss_spec_dst_sh -t | awk -F: '/Number/{print $2}'` 行 Update: $(date)"
	echo `nvram get gfwlist3`
# fi
	if [ "$ss_mode_x" = "2" ] || [ "$ss_pdnsd_all" = "1" ] ; then
		# 2 为全局,模式3全局代理。加速国内dns访问
		logger -t "【SS】" "加速国内 dns 访问，模式:$ss_mode_x, pdnsd_all:$ss_pdnsd_all, 下载 accelerated-domains.china.conf"
		DNS_china=`nvram get wan0_dns |cut -d ' ' -f1`
		[ -z "$DNS_china" ] && DNS_china="114.114.114.114"
		if [ ! -s /tmp/ss/accelerated-domains.china.conf ] ; then
			wgetcurl.sh /tmp/ss/tmp_accelerated-domains.china.conf "$hiboyfile/accelerated-domains.china.conf" "$hiboyfile2/accelerated-domains.china.conf"
		else
			[ -s /tmp/ss/accelerated-domains.china.conf ] && mv -f /tmp/ss/accelerated-domains.china.conf /tmp/ss/tmp_accelerated-domains.china.conf
		fi
		cat /tmp/ss/tmp_accelerated-domains.china.conf |
			sort -u | sed 's/^[[:space:]]*//g; /^$/d; /#/d' |
			sed -e "s|^\(server.*\)/[^/]*$|\1/$DNS_china|" > /tmp/ss/accelerated-domains.china.conf
		rm -rf /tmp/ss/tmp_accelerated-domains.china.conf
		sed -Ei '/accelerated-domains/d' /etc/storage/dnsmasq/dnsmasq.conf
		echo "conf-file=/tmp/ss/accelerated-domains.china.conf" >> "/etc/storage/dnsmasq/dnsmasq.conf"
	fi
	logger -t "【SS】" "chnroutes update 重启 dnsmasq 更新列表"
	restart_dhcpd
	rm -f /tmp/cron_ss.lock

fi
}



#================华丽的分割线====================================



adbyby_cflist()
{
	logger -t dnsmasq "restart adbyby_cflist"
	ipsets=`nvram get adbyby_mode_x`
if [ "$ipsets" == 1 ] ; then
	if [ -s "/tmp/7620adm/adm" ] ; then
		port=$(iptables -t nat -L | grep 'ports 18309' | wc -l)
		PIDS=$(ps -w | grep "/tmp/7620adm/adm" | grep -v "grep" | wc -l)
		if [ "$port" -ge 1 ] || [ "$PIDS" != 0 ] ; then
			chmod 777 /tmp/script/_ad_m
			/tmp/script/_ad_m C &
		fi
	fi
	if [ -s "/tmp/7620koolproxy/koolproxy" ] ; then
		port=$(iptables -t nat -L | grep 'ports 3000' | wc -l)
		PIDS=$(ps -w | grep "/tmp/7620koolproxy/koolproxy" | grep -v "grep" | wc -l)
		if [ "$port" -ge 1 ] || [ "$PIDS" != 0 ] ; then
			chmod 777 /tmp/script/_kool_proxy
			/tmp/script/_kool_proxy C &
		fi
	fi
	if [ -s "/tmp/bin/adbyby" ] ; then
		port=$(iptables -t nat -L | grep 'ports 8118' | wc -l)
		PIDS=$(ps -w | grep "/tmp/bin/adbyby" | grep -v "grep" | grep -v "adbybyupdate.sh" | grep -v "adbybyfirst.sh" | wc -l)
		if [ "$port" -ge 1 ] || [ "$PIDS" != 0 ] ; then
			chmod 777 /tmp/script/_ad_byby
			/tmp/script/_ad_byby C &
		fi
	fi
fi
}

dnsmasq_reconf()
{
	#防火墙转发规则加载
	# for dnsmasq 
#启动PDNSD防止域名污染
start_pdnsd
	sed -Ei '/no-resolv|server=127.0.0.1#8053|dns-forward-max=1000|min-cache-ttl=1800/d' /etc/storage/dnsmasq/dnsmasq.conf
if [ "$ss_mode_x" = "2" ] || [ "$ss_pdnsd_all" = "1" ] ; then 
#   #方案三
	cat >> "/etc/storage/dnsmasq/dnsmasq.conf" <<-\EOF
no-resolv
server=127.0.0.1#8053
dns-forward-max=1000
min-cache-ttl=1800
EOF
fi
sed -Ei "/conf-dir=$confdir_x/d" /etc/storage/dnsmasq/dnsmasq.conf
[ ! -z "$confdir" ] && echo "conf-dir=$confdir" >> /etc/storage/dnsmasq/dnsmasq.conf
rm -f $confdir/r.wantoss.conf
cat >> "$confdir/r.wantoss.conf" <<-\_CONF
server=/githubusercontent.com/127.0.0.1#8053
server=/github.io/127.0.0.1#8053
_CONF
restart_dhcpd
}


start_SS()
{
	logger -t "【SS】" "启动 SS"
	nvram set ss_internet="2"
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
check_ss_plugin="`echo $ss_plugin_config`"
check_ss_plugin2="`echo $ss2_plugin_config`"
if [ ! -z "$check_ss_plugin" ] || [ ! -z "$check_ss_plugin2" ]; then
	hash obfs-local 2>/dev/null || optssredir="4"
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
if [ "$optssredir" != "0" ] ; then
	# 找不到ss-redir，安装opt
	logger -t "【SS】" "找不到 ss-redir 、 ss-local 或 obfs-local ，挂载opt"
	/tmp/script/_mountopt start
	initopt
fi
optssredir="0"

if [ "$ss_type" != "1" ] ; then
# SS
if [ "$ss_mode_x" != "3" ] ; then
chmod 777 "`which ss-redir`"
	[[ "$(ss-redir -h | wc -l)" -lt 2 ]] && rm -rf /opt/bin/ss-redir
	hash ss-redir 2>/dev/null || optssredir="1"
else
chmod 777 "`which ss-local`"
	[[ "$(ss-local -h | wc -l)" -lt 2 ]] && rm -rf /opt/bin/ss-local
	hash ss-local 2>/dev/null || optssredir="2"
fi
if [ "$optssredir" = "1" ] ; then
	logger -t "【SS】" "找不到 ss-redir. opt下载程序"
	[ ! -s /opt/bin/ss-redir ] && wgetcurl.sh "/opt/bin/ss-redir" "$hiboyfile/ss-redir" "$hiboyfile2/ss-redir"
	chmod 777 "/opt/bin/ss-redir"
hash ss-redir 2>/dev/null || { logger -t "【SS】" "找不到 ss-redir, 请检查系统"; ss_restart x ; }
fi
if [ "$ss_run_ss_local" = "1" ] ; then
chmod 777 "`which ss-local`"
	[[ "$(ss-local -h | wc -l)" -lt 2 ]] && rm -rf /opt/bin/ss-local
	hash ss-local 2>/dev/null || optssredir="3"
fi
if [ "$optssredir" = "2" ] || [ "$optssredir" = "3" ]; then
	logger -t "【SS】" "找不到 ss-local. opt 下载程序"
	[ ! -s /opt/bin/ss-local ] && wgetcurl.sh "/opt/bin/ss-local" "$hiboyfile/ss-local" "$hiboyfile2/ss-local"
	chmod 777 "/opt/bin/ss-local"
	hash ss-local 2>/dev/null || { logger -t "【SS】" "找不到 ss-local, 请检查系统"; ss_restart x ; }
fi
if [ ! -z "$check_ss_plugin" ] || [ ! -z "$check_ss_plugin2" ]; then
	hash obfs-local 2>/dev/null || optssredir="4"
fi
if [ "$optssredir" = "4" ] ; then
	logger -t "【SS】" "找不到 obfs-local. opt 下载程序"
	wgetcurl.sh "/opt/bin/obfs-local" "$hiboyfile/obfs-local" "$hiboyfile2/obfs-local"
	chmod 777 "/opt/bin/obfs-local"
	hash obfs-local 2>/dev/null || { logger -t "【SS】" "找不到 obfs-local, 请检查系统"; ss_restart x ; }
fi
# SS
fi

if [ "$ss_type" = "1" ] ; then
if [ "$ssrr_type" = "1" ] ; then
# SSRR
if [ "$ss_mode_x" != "3" ] ; then
chmod 777 "`which ssrr-redir`"
	[[ "$(ssrr-redir -h | wc -l)" -lt 2 ]] && rm -rf /opt/bin/ssrr-redir
	hash ssrr-redir 2>/dev/null || optssredir="1"
else
chmod 777 "`which ssrr-local`"
	[[ "$(ssrr-local -h | wc -l)" -lt 2 ]] && rm -rf /opt/bin/ssrr-local
	hash ssrr-local 2>/dev/null || optssredir="2"
fi
if [ "$optssredir" = "1" ] ; then
	[ ! -s /opt/bin/ssrr-redir ] && wgetcurl.sh "/opt/bin/ssrr-redir" "$hiboyfile/ssrr-redir" "$hiboyfile2/ssrr-redir"
	chmod 777 "/opt/bin/ssrr-redir"
hash ssrr-redir 2>/dev/null || { logger -t "【SS】" "找不到 ssrr-redir, 请检查系统"; ss_restart x ; }
fi
if [ "$ss_run_ss_local" = "1" ] ; then
chmod 777 "`which ssrr-local`"
	[[ "$(ssrr-local -h | wc -l)" -lt 2 ]] && rm -rf /opt/bin/ssrr-local
	hash ssrr-local 2>/dev/null || optssredir="3"
fi
if [ "$optssredir" = "2" ] || [ "$optssredir" = "3" ]; then
	[ ! -s /opt/bin/ssrr-local ] && wgetcurl.sh "/opt/bin/ssrr-local" "$hiboyfile/ssrr-local" "$hiboyfile2/ssrr-local"
	chmod 777 "/opt/bin/ssrr-local"
	hash ssrr-local 2>/dev/null || { logger -t "【SS】" "找不到 ssrr-local, 请检查系统"; ss_restart x ; }
fi
# SSRR
else
# SSR
if [ "$ss_mode_x" != "3" ] ; then
chmod 777 "`which ssr-redir`"
	[[ "$(ssr-redir -h | wc -l)" -lt 2 ]] && rm -rf /opt/bin/ssr-redir
	hash ssr-redir 2>/dev/null || optssredir="1"
else
chmod 777 "`which ssr-local`"
	[[ "$(ssr-local -h | wc -l)" -lt 2 ]] && rm -rf /opt/bin/ssr-local
	hash ssr-local 2>/dev/null || optssredir="2"
fi
if [ "$optssredir" = "1" ] ; then
	[ ! -s /opt/bin/ssr-redir ] && wgetcurl.sh "/opt/bin/ssr-redir" "$hiboyfile/ssr-redir" "$hiboyfile2/ssr-redir"
	chmod 777 "/opt/bin/ssr-redir"
hash ssr-redir 2>/dev/null || { logger -t "【SS】" "找不到 ssr-redir, 请检查系统"; ss_restart x ; }
fi
if [ "$ss_run_ss_local" = "1" ] ; then
chmod 777 "`which ssr-local`"
	[[ "$(ssr-local -h | wc -l)" -lt 2 ]] && rm -rf /opt/bin/ssr-local
	hash ssr-local 2>/dev/null || optssredir="3"
fi
if [ "$optssredir" = "2" ] || [ "$optssredir" = "3" ]; then
	[ ! -s /opt/bin/ssr-local ] && wgetcurl.sh "/opt/bin/ssr-local" "$hiboyfile/ssr-local" "$hiboyfile2/ssr-local"
	chmod 777 "/opt/bin/ssr-local"
	hash ssr-local 2>/dev/null || { logger -t "【SS】" "找不到 ssr-local, 请检查系统"; ss_restart x ; }
fi
# SSR
fi
fi

if [ "$ss_dnsproxy_x" = "0" ] ; then
hash dnsproxy 2>/dev/null && dnsproxy_x="1"
hash dnsproxy 2>/dev/null || dnsproxy_x="0"
if [ "$dnsproxy_x" = "0" ] ; then
	logger -t "【SS】" "找不到 dnsproxy. opt ，挂载opt"
	/tmp/script/_mountopt start
	initopt
	if [ ! -s /opt/bin/dnsproxy ] ; then
		wgetcurl.sh "/opt/bin/dnsproxy" "$hiboyfile/dnsproxy" "$hiboyfile2/dnsproxy"
		chmod 777 "/opt/bin/dnsproxy"
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
		wgetcurl.sh "/opt/bin/pdnsd" "$hiboyfile/pdnsd" "$hiboyfile2/pdnsd"
		chmod 777 "/opt/bin/pdnsd"
	fi
	hash pdnsd 2>/dev/null || { logger -t "【SS】" "找不到 pdnsd, 请检查系统"; ss_restart x ; }
fi
fi

check_ssr
echo "Debug: $DNS_Server"
	rm -f /tmp/cron_ss.lock
	logger -t "【SS】" "###############启动程序###############"
	if [ "$ss_mode_x" = "3" ] ; then
		start_ss_redir
		start_ss_redir_check
		logger -t "【ss-local】" "启动. 可以配合 Proxifier、chrome(switchysharp、SwitchyOmega) 代理插件使用."
		logger -t "【ss-local】" "shadowsocks 进程守护启动"
		ss_cron_job
		#ss_get_status
		nvram set button_script_2_s="SS"
		eval "$scriptfilepath keep &"
		exit 0
	fi
	dnsmasq_reconf
	start_ss_redir
	start_ss_redir_check
	start_ss_rules

	nvram set ss_updatess2=0
	update_gfwlist
	update_chnroutes
	nvram set ss_updatess2=1
	#检查网络
	logger -t "【SS】" "SS 检查网络连接"

	check=0
	hash check_network 2>/dev/null && check=1
	if [ "$check" == "1" ] ; then
		check_link="Google.com"
		check_network 1
		[ "$?" == "0" ] && check=200 || { check=404; sleep 1; }
		if [ "$check" == "404" ] ; then
			check_network 1
			[ "$?" == "0" ] && check=200 || check=404
		fi
		logger -t "【ss-redir】" "check_network 检查 Google.com : $check"
	fi
	hash check_network 2>/dev/null || check=404
	if [ "$check" == "404" ] ; then
		check_link="$ss_link_1"
		curltest=`which curl`
		if [ -z "$curltest" ] || [ ! -s "`which curl`" ] ; then
			wget --no-check-certificate -q -T 10 "$ss_link_1" -O /dev/null
			[ "$?" == "0" ] && check=200 || { check=404; sleep 1; }
			if [ "$check" == "404" ] ; then
				wget --no-check-certificate -q -T 10 "$ss_link_1" -O /dev/null
				[ "$?" == "0" ] && check=200 || check=404
			fi
			logger -t "【ss-redir】" "wget  检查 $ss_link_1 : $check"
		else
			check=`curl -k -s -w "%{http_code}" "$ss_link_1" -o /dev/null`
			[ "$check" != "200" ] && sleep 1
			[ "$check" != "200" ] && check=`curl -k -s -w "%{http_code}" "$ss_link_1" -o /dev/null`
			logger -t "【ss-redir】" "curl  检查 $ss_link_1 : $check"
		fi
	fi
if [ "$check" != "200" ] ; then 
	logger -t "【SS】" "连 $check_link 的域名都解析不了, 你的网络能用？？"
	logger -t "【SS】" "SS 网络连接有问题, 请更新 opt 文件夹、检查 U盘 文件和 SS 设置"
	clean_SS
fi
	/etc/storage/ez_buttons_script.sh 3 &
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
ss_working_port=`nvram get ss_working_port`
[ $ss_working_port == 1090 ] && ss_info="SS_[1]"
[ $ss_working_port == 1091 ] && ss_info="SS_[2]"
nvram set button_script_2_s="$ss_info"
eval "$scriptfilepath keep &"
}



clean_SS()
{
# 重置 SS IP 规则文件并重启 SS
logger -t "【SS】" "重置 SS IP 规则文件并重启 SS"
stop_SS
sed -Ei '/no-resolv|server=|dns-forward-max=1000|min-cache-ttl=1800|accelerated-domains|github|ipip.net/d' /etc/storage/dnsmasq/dnsmasq.conf
rm -f /tmp/ss/dnsmasq.d/*
restart_dhcpd
rm -rf /etc/storage/china_ip_list.txt /etc/storage/basedomain.txt /tmp/ss/*
[ ! -f /etc/storage/china_ip_list.txt ] && tar -xzvf /etc_ro/china_ip_list.tgz -C /tmp && ln -sf /tmp/china_ip_list.txt /etc/storage/china_ip_list.txt
[ ! -f /etc/storage/basedomain.txt ] && tar -xzvf /etc_ro/basedomain.tgz -C /tmp && ln -sf /tmp/basedomain.txt /etc/storage/basedomain.txt
nvram set kcptun_status="cleanss"
nvram set ss_status="cleanss"
/tmp/script/_kcp_tun &
sleep 1
ss_restart $1
exit 0
}


stop_SS()
{
cru.sh d ss_update &
ss-rules -f
nvram set ss_internet="0"
nvram set ss_working_port="1090" #恢复主服务器端口
ss_working_port=`nvram get ss_working_port`
[ $ss_working_port == 1090 ] && ss_info="SS_[1]"
[ $ss_working_port == 1091 ] && ss_info="SS_[2]"
nvram set button_script_2_s="$ss_info"
rm -f $confdir/r.wantoss.conf
sed -Ei '/github|ipip.net|accelerated-domains|no-resolv|server=127.0.0.1#8053|dns-forward-max=1000|min-cache-ttl=1800/d' /etc/storage/dnsmasq/dnsmasq.conf
sed -Ei "/conf-dir=$confdir_x/d" /etc/storage/dnsmasq/dnsmasq.conf
restart_dhcpd
clean_ss_rules
killall_ss_redir
killall_ss_local
killall pdnsd dnsproxy sh_sskeey_k.sh obfs-local
killall -9 pdnsd dnsproxy sh_sskeey_k.sh obfs-local
rm -f /tmp/sh_sskeey_k.sh
rm -f $confdir/r.gfwlist.conf
rm -f $confdir/r.sub.conf
rm -f $confdir/r.adhost.conf
#rm -f $confdir/accelerated-domains.china.conf
[ -f /opt/etc/init.d/S24chinadns ] && { rm -f /var/log/chinadns.lock; /opt/etc/init.d/S24chinadns stop& }
[ -f /opt/etc/init.d/S26pdnsd ] && { rm -f /var/log/pdnsd.lock; /opt/etc/init.d/S26pdnsd stop& }
[ -f /opt/etc/init.d/S27pcap-dnsproxy ] && { rm -f /var/log/pcap-dnsproxy.lock; /opt/etc/init.d/S27pcap-dnsproxy stop& }
nvram set gfwlist3="ss-redir stop."
/etc/storage/ez_buttons_script.sh 3 &
umount -l /usr/sbin/ss-redir
umount -l /usr/sbin/ss-local
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
B_restart="$ss_enable$ss_dnsproxy_x$ss_link_1$ss_link_2$ss_update$ss_update_hour$ss_update_min$lan_ipaddr$ss_updatess$ss_DNS_Redirect$ss_DNS_Redirect_IP$ss_type$ss_check$ss_run_ss_local$ss_s1_local_address$ss_s2_local_address$ss_s1_local_port$ss_s2_local_port$ss_pdnsd_wo_redir$ss_mode_x$ss_multiport$ss_sub4$ss_sub1$ss_sub2$ss_sub3$ss_upd_rules$ss_plugin_config$ss2_plugin_config$ss_usage_json$ss_s2_usage_json$ss_tochina_enable$ss_udp_enable$LAN_AC_IP$ss_3p_enable$ss_3p_gfwlist$ss_3p_kool$ss_pdnsd_all$kcptun_server$server_addresses$(nvram get wan0_dns |cut -d ' ' -f1)$(cat /etc/storage/shadowsocks_ss_spec_lan.sh /etc/storage/shadowsocks_ss_spec_wan.sh /etc/storage/shadowsocks_mydomain_script.sh | grep -v '^#' | grep -v "^$")"
B_restart=`echo -n "$B_restart" | md5sum | sed s/[[:space:]]//g | sed s/-//g`
if [ "$A_restart" != "$B_restart" ] ; then
	nvram set ss_status=$B_restart
	needed_restart=1
	ss_get_status2
	#/etc/storage/ez_buttons_script.sh ping &
else
	needed_restart=0
	ss_get_status2
fi
}

ss_get_status2 () {

A_restart="$(nvram get ss_status2)"
B_restart="$ss_server1$ss_server2$ss_s1_port$ss_s2_port$ss_s1_method$ss_s2_method$ss_s1_key$ss_s2_key$ss_usage$ss_s2_usage"
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
needed_restart=0
ss_get_status
if [ "$ss_enable" != "1" ] && [ "$needed_restart" = "1" ] ; then
	[ ! -z "`pidof ss-redir`" ] && logger -t "【SS】" "停止 ss-redir" && stop_SS
	[ ! -z "`pidof ss-local`" ] && logger -t "【SS】" "停止 ss-local" && stop_SS
	{ kill_ps "$scriptname" exit0; exit 0; }
fi
if [ "$ss_enable" = "1" ] ; then
	hash getopts 2>/dev/null ||  { logger -t "【SS】" "错误！Shell未加载getopts，请检查固件和busybox配置"; stop_SS; exit 1; }
	[ $ss_server1 ] || logger -t "【SS】" "服务器地址:未填写"
	[ $ss_s1_port ] || logger -t "【SS】" "服务器端口:未填写"
	[ $ss_s1_method ] || logger -t "【SS】" "加密方式:未填写"
	[ $ss_server1 ] && [ $ss_s1_port ] && [ $ss_s1_method ] \
	 ||  { logger -t "【SS】" "SS配置有错误，请到扩展功能检查SS配置页面"; stop_SS; exit 1; }
	if [ "$needed_restart" = "2" ] ; then
		logger -t "【SS】" "检测:更换线路配置，进行快速切换服务器。"
		swap_ss_redir
		logger -t "【SS】" "切换服务器完成。"
		exit 0
	fi
	if [ "$needed_restart" = "1" ] ; then
		# ss_link_cron_job &
		stop_SS
		start_SS
	else
		[ "$ss_mode_x" = "3" ] && { [ -z "`pidof ss-local`" ] || [ ! -s "`which ss-local`" ] && ss_restart ; }
		[ "$ss_dnsproxy_x" = "0" ] && [ "$ss_mode_x" != "3" ] && { [ -z "`pidof ss-redir`" ] || [ ! -s "`which ss-redir`" ] || [ ! -s "`which dnsproxy`" ] && ss_restart ; }
		[ "$ss_dnsproxy_x" = "1" ] && [ "$ss_mode_x" != "3" ] && { [ -z "`pidof ss-redir`" ] || [ ! -s "`which ss-redir`" ] || [ ! -s "`which pdnsd`" ] && ss_restart ; }
		[ "$ss_dnsproxy_x" = "2" ] && [ "$ss_mode_x" != "3" ] && { [ -z "`pidof ss-redir`" ] || [ ! -s "`which ss-redir`" ] && ss_restart ; }
		if [ -n "`pidof ss-redir`" ] && [ "$ss_enable" = "1" ] && [ "$ss_mode_x" != "3" ] ; then
			port=$(iptables -t nat -L | grep 'SS_SPEC' | wc -l)
			if [ "$port"x = 0x ] ; then
				logger -t "【SS】" "检测2:找不到 SS_SPEC 转发规则, 重新添加"
				eval "$scriptfilepath rules &"
			fi
		fi
		if [ "$ss_mode_x" = "2" ] || [ "$ss_pdnsd_all" = "1" ] ; then 
			port=$(grep "server=127.0.0.1#8053"  /etc/storage/dnsmasq/dnsmasq.conf | wc -l)
			if [ "$port" = 0 ] ; then
				logger -t "【SS】" "检测2:找不到 dnsmasq 转发规则, 重新添加"
				#   #方案三
				sed -Ei '/no-resolv|server=127.0.0.1#8053|dns-forward-max=1000|min-cache-ttl=1800/d' /etc/storage/dnsmasq/dnsmasq.conf
				cat >> "/etc/storage/dnsmasq/dnsmasq.conf" <<-\EOF
no-resolv
server=127.0.0.1#8053
dns-forward-max=1000
min-cache-ttl=1800
EOF
				sed -Ei '/accelerated-domains/d' /etc/storage/dnsmasq/dnsmasq.conf
				[ -s /tmp/ss/accelerated-domains.china.conf ] && echo "conf-file=/tmp/ss/accelerated-domains.china.conf" >> "/etc/storage/dnsmasq/dnsmasq.conf"
			fi
		fi
	fi
fi

}

SS_keep () {
cat > "/tmp/sh_sskeey_k.sh" <<-SSMK
#!/bin/sh
source /etc/storage/script/init.sh
sleep 919
ss_enable=\`nvram get ss_enable\`
if [ ! -f /tmp/cron_ss.lock ] && [ "\$ss_enable" = "1" ] ; then
kill_ps "$scriptname"
eval "$scriptfilepath keep &"
exit 0
fi
SSMK
chmod 777 "/tmp/sh_sskeey_k.sh"
killall sh_sskeey_k.sh
killall -9 sh_sskeey_k.sh
/tmp/sh_sskeey_k.sh &
rebss=1
ss_rdd_server=`nvram get ss_server2`
kcptun2_enable=`nvram get kcptun2_enable`
[ -z $kcptun2_enable ] && kcptun2_enable=0 && nvram set kcptun2_enable=$kcptun2_enable
kcptun2_enable2=`nvram get kcptun2_enable2`
[ -z $kcptun2_enable2 ] && kcptun2_enable2=0 && nvram set kcptun2_enable2=$kcptun2_enable2
ss_run_ss_local=`nvram get ss_run_ss_local`
ss_mode_x=`nvram get ss_mode_x`
[ -z $ss_mode_x ] && ss_mode_x=0 && nvram set ss_mode_x=$ss_mode_x
[ "$ss_mode_x" != "0" ] && kcptun2_enable=$kcptun2_enable2
[ "$kcptun2_enable" = "2" ] && ss_rdd_server=""
rm -f /tmp/cron_ss.lock
ss_enable=`nvram get ss_enable`
sleep 15
while [ "$ss_enable" = "1" ];
do
ss_internet=`nvram get ss_internet`
sleep 9
#随机延时
if [ "$ss_internet" = "1" ] ; then
	SEED=`tr -cd 0-9 </dev/urandom | head -c 8`
	RND_NUM=`echo $SEED 60 100|awk '{srand($1);printf "%d",rand()*10000%($3-$2)+$2}'`
	sleep $RND_NUM
fi
/etc/storage/ez_buttons_script.sh 3 &
ss_enable=`nvram get ss_enable`
if [ -f /tmp/cron_ss.lock ] || [ "$ss_enable" != "1" ] ; then
	#跳出当前循环
	continue
fi
if [ "$rebss" -gt 6 ] && [ $(cat /tmp/reb.lock) == "1" ] ; then
	logger -t "【SS】" " 网络连接 shadowsocks 中断['$rebss'], 重启路由."
	sleep 5
	reboot
fi
if [ "$rebss" -gt 6 ] ; then
	if [ "$kcptun2_enable" = "1" ] || [ -z $ss_rdd_server ] ; then
		logger -t "【SS】" " 网络连接 shadowsocks 中断 ['$rebss'], 重启SS."
		nvram set ss_status=0
		eval "$scriptfilepath &"
		sleep 10
		exit 0
	fi
fi
if [ "$ss_mode_x" = "3" ] || [ "$ss_run_ss_local" = "1" ] ; then
	NUM=`ps -w | grep ss-local_ | grep -v grep |wc -l`
	SSRNUM=1
	[ ! -z $ss_rdd_server ] && SSRNUM=2
	if [ "$NUM" -lt "$SSRNUM" ] || [ ! -s "`which ss-local`" ] ; then
		logger -t "【SS】" "找不到 $SSRNUM ss-local 进程 $rebss, 重启SS."
		nvram set ss_status=0
		eval "$scriptfilepath &"
		sleep 10
		exit 0
	fi
	#跳出当前循环
	[ "$ss_mode_x" = "3" ] && continue
fi

NUM=`ps -w | grep ss-redir_ | grep -v grep |wc -l`
SSRNUM=1
[ ! -z $ss_rdd_server ] && SSRNUM=2
if [ "$NUM" -lt "$SSRNUM" ] ; then
	logger -t "【SS】" "找不到 $SSRNUM shadowsocks 进程 $rebss, 重启SS."
	nvram set ss_status=0
	eval "$scriptfilepath &"
	sleep 10
	exit 0
fi
if [ "$ss_dnsproxy_x" = "0" ] ; then
if [ -z "`pidof dnsproxy`" ] || [ ! -s "`which dnsproxy`" ] ; then
	logger -t "【SS】" "找不到 dnsproxy 进程 $rebss，重启 dnsproxy"
	eval "$scriptfilepath repdnsd &"
	sleep 10
fi
elif [ "$ss_dnsproxy_x" = "1" ] ; then
if [ -z "`pidof pdnsd`" ] || [ ! -s "`which pdnsd`" ] ; then
	logger -t "【SS】" "找不到 pdnsd 进程 $rebss，重启 pdnsd"
	eval "$scriptfilepath repdnsd &"
	sleep 10
fi
fi
if [ "$ss_mode_x" = "2" ] || [ "$ss_pdnsd_all" = "1" ] ; then 
	port=$(grep "server=127.0.0.1#8053"  /etc/storage/dnsmasq/dnsmasq.conf | wc -l)
	if [ "$port" = 0 ] ; then
		logger -t "【SS】" "检测3:找不到 dnsmasq 转发规则, 重新添加"
		#   #方案三
		sed -Ei '/no-resolv|server=127.0.0.1#8053|dns-forward-max=1000|min-cache-ttl=1800/d' /etc/storage/dnsmasq/dnsmasq.conf
		cat >> "/etc/storage/dnsmasq/dnsmasq.conf" <<-\EOF
no-resolv
server=127.0.0.1#8053
dns-forward-max=1000
min-cache-ttl=1800
EOF
		sed -Ei '/accelerated-domains/d' /etc/storage/dnsmasq/dnsmasq.conf
		[ -s /tmp/ss/accelerated-domains.china.conf ] && echo "conf-file=/tmp/ss/accelerated-domains.china.conf" >> "/etc/storage/dnsmasq/dnsmasq.conf"
	fi
fi
#SS进程监控和双线切换
#思路：
#先将所有ss通道全部拉起来，默认服务器为1090端口，新服务器为1091端口，默认走通道0，DNS的ss-tunnel 走8053 和 8054
#检查SS通道是否可以连接google，如果不能，则看看网易是否正常，如果网易正常，而google无法打开，则说明当前SS通道有问题
#通道有问题时，先logger记录，然后切换SS通道端口和修改 
# sh_ssmon 建议不要重启网络，会导致断线。正常来说,ss服务基本上稳定不需要重启，我公司路由的ss客户端跑20多台机器将近3个多月没动过了。



LOGTIME=$(date "+%Y-%m-%d %H:%M:%S")

#检查是否存在当前SS服务器，没有则设为0，准备切换服务器设为1
CURRENT=`nvram get ss_working_port`
ss_udp_enable=`nvram get ss_udp_enable` #udp转发  0、停用；1、启动
ss_upd_rules=`nvram get ss_upd_rules`
ss_pdnsd_wo_redir=`nvram get ss_pdnsd_wo_redir` #pdnsd  1、直连；0、走代理

[ ${CURRENT:=1090} ] && [ $CURRENT == 1091 ] && Server=1090 || Server=1091
[ $Server == 1090 ] && Server_ip=$ss_server1 && CURRENT_ip=$ss_server2
[ $Server == 1091 ] && Server_ip=$ss_server2 && CURRENT_ip=$ss_server1

#检查是否存在SS备份服务器, 这里通过判断 ss_rdd_server 是否填写来检查是否存在备用服务器

check=0
hash check_network 2>/dev/null && check=1
if [ "$check" == "1" ] ; then
	check_network
	[ "$?" == "0" ] && check=200 || { check=404; sleep 1; }
	if [ "$check" == "404" ] ; then
		check_network
		[ "$?" == "0" ] && check=200 || check=404
	fi
fi
hash check_network 2>/dev/null || check=404
if [ "$check" == "404" ] ; then
	curltest=`which curl`
	if [ -z "$curltest" ] || [ ! -s "`which curl`" ] ; then
		wget --no-check-certificate -q -T 10 $ss_link_2 -O /dev/null
		[ "$?" == "0" ] && check=200 || { check=404; sleep 1; }
		if [ "$check" == "404" ] ; then
			wget --no-check-certificate -q -T 10 "$ss_link_2" -O /dev/null
			[ "$?" == "0" ] && check=200 || check=404
		fi
	else
		check=`curl -k -s -w "%{http_code}" "$ss_link_2" -o /dev/null`
		[ "$check" != "200" ] && sleep 1
		[ "$check" != "200" ] && check=`curl -k -s -w "%{http_code}" "$ss_link_2" -o /dev/null`
	fi
fi
if [ "$check" == "200" ] ; then
	echo "[$LOGTIME] SS $CURRENT have no problem."
	rebss="1"
	nvram set ss_internet="1"
	#跳出当前循环
	continue
fi

check=0
hash check_network 2>/dev/null && check=1
if [ "$check" == "1" ] ; then
	check_network 3
	[ "$?" == "0" ] && check=200 || { check=404; sleep 1; }
	if [ "$check" == "404" ] ; then
		check_network 3
		[ "$?" == "0" ] && check=200 || check=404
	fi
fi
hash check_network 2>/dev/null || check=404
if [ "$check" == "404" ] ; then
	curltest=`which curl`
	if [ -z "$curltest" ] || [ ! -s "`which curl`" ] ; then
		wget --no-check-certificate -q -T 10 "$ss_link_1" -O /dev/null
		[ "$?" == "0" ] && check=200 || { check=404; sleep 1; }
		if [ "$check" == "404" ] ; then
			wget --no-check-certificate -q -T 10 "$ss_link_1" -O /dev/null
			[ "$?" == "0" ] && check=200 || check=404
		fi
	else
		check=`curl -k -s -w "%{http_code}" "$ss_link_1" -o /dev/null`
		[ "$check" != "200" ] && sleep 1
		[ "$check" != "200" ] && check=`curl -k -s -w "%{http_code}" "$ss_link_1" -o /dev/null`
	fi
fi
if [ "$check" == "200" ] ; then
	echo "[$LOGTIME] Internet have no problem."
else
	logger -t "【SS】" " Internet 问题, 请检查您的服务供应商."
	rebss=`expr $rebss + 1`
	restart_dhcpd
fi

#404
sleep 5
if [ -n "`pidof ss-redir`" ] && [ "$ss_enable" = "1" ] && [ "$ss_mode_x" != "3" ] ; then
	port=$(iptables -t nat -L | grep 'SS_SPEC' | wc -l)
	if [ "$port" = 0 ] ; then
		sleep 5
	fi
	port=$(iptables -t nat -L | grep 'SS_SPEC' | wc -l)
	if [ "$port" = 0 ] ; then
		logger -t "【SS】" "检测3:找不到 SS_SPEC 转发规则, 重新添加"
		eval "$scriptfilepath rules &"
		restart_dhcpd
		sleep 5
	fi
fi
check=0
hash check_network 2>/dev/null && check=1
if [ "$check" == "1" ] ; then
	check_network
	[ "$?" == "0" ] && check=200 || { check=404; sleep 1; }
	if [ "$check" == "404" ] ; then
		check_network
		[ "$?" == "0" ] && check=200 || check=404
	fi
fi
hash check_network 2>/dev/null || check=404
if [ "$check" == "404" ] ; then
	curltest=`which curl`
	if [ -z "$curltest" ] || [ ! -s "`which curl`" ] ; then
		wget --no-check-certificate -q -T 10 $ss_link_2 -O /dev/null
		[ "$?" == "0" ] && check=200 || { check=404; sleep 1; }
		if [ "$check" == "404" ] ; then
			wget --no-check-certificate -q -T 10 "$ss_link_2" -O /dev/null
			[ "$?" == "0" ] && check=200 || check=404
		fi
	else
		check=`curl -k -s -w "%{http_code}" "$ss_link_2" -o /dev/null`
		[ "$check" != "200" ] && sleep 1
		[ "$check" != "200" ] && check=`curl -k -s -w "%{http_code}" "$ss_link_2" -o /dev/null`
	fi
fi
if [ "$check" == "200" ] ; then
	echo "[$LOGTIME] SS $CURRENT have no problem."
	rebss="1"
	nvram set ss_internet="1"
	#跳出当前循环
	continue
fi

#404
if [ "$kcptun2_enable" = "1" ] ; then
	nvram set ss_internet="2"
	rebss=`expr $rebss + 2`
	logger -t "【SS】" " SS 服务器 $CURRENT_ip 【$CURRENT】 检测到问题, $rebss"
	#跳出当前循环
	continue
fi
if [ ! -z $ss_rdd_server ] ; then
	logger -t "【SS】" " SS 服务器 $CURRENT_ip 【$CURRENT】检测到问题, 尝试切换到 $Server_ip 【$Server】"
	nvram set ss_internet="2"
	#端口切换
	iptables -t nat -D SS_SPEC_WAN_FW -p tcp -j REDIRECT --to-port $CURRENT
	iptables -t nat -A SS_SPEC_WAN_FW -p tcp -j REDIRECT --to-port $Server
	if [ "$ss_udp_enable" == 1 ] ; then
		iptables -t mangle -D SS_SPEC_WAN_FW -p udp -j TPROXY --on-port $CURRENT --tproxy-mark 0x01/0x01
		iptables -t mangle -A SS_SPEC_WAN_FW -p udp -j TPROXY --on-port $Server --tproxy-mark 0x01/0x01
	fi
	if [ "$ss_pdnsd_wo_redir" == 0 ] ; then
	# pdnsd 是否直连  1、直连；0、走代理
		iptables -t nat -D OUTPUT -p tcp -d 8.8.8.8,8.8.4.4 --dport 53 -j REDIRECT --to-port $CURRENT
		iptables -t nat -D OUTPUT -p tcp -d 208.67.222.222,208.67.220.220 --dport 443 -j REDIRECT --to-port $CURRENT
		iptables -t nat -I OUTPUT -p tcp -d 8.8.8.8,8.8.4.4 --dport 53 -j REDIRECT --to-port $Server
		iptables -t nat -I OUTPUT -p tcp -d 208.67.222.222,208.67.220.220 --dport 443 -j REDIRECT --to-port $Server
	fi
	#加上切换标记
	nvram set ss_working_port=$Server
	ss_working_port=`nvram get ss_working_port`
	[ $ss_working_port == 1090 ] && ss_info="SS_[1]"
	[ $ss_working_port == 1091 ] && ss_info="SS_[2]"
	nvram set button_script_2_s="$ss_info"
	#检查切换后的状态
	TAG="SS_SPEC"		  # iptables tag
	FWI="/tmp/firewall.shadowsocks.pdcn" # firewall include file
	[ -n "$FWI" ] && echo '#!/bin/sh' >$FWI
	gen_include
	restart_dhcpd
	sleep 5
	check=0
	hash check_network 2>/dev/null && check=1
	if [ "$check" == "1" ] ; then
	check_network
	[ "$?" == "0" ] && check=200 || { check=404; sleep 1; }
		if [ "$check" == "404" ] ; then
			check_network
			[ "$?" == "0" ] && check=200 || check=404
		fi
	fi
	hash check_network 2>/dev/null || check=404
	if [ "$check" == "404" ] ; then
		curltest=`which curl`
		if [ -z "$curltest" ] || [ ! -s "`which curl`" ] ; then
			wget --no-check-certificate -q -T 10 $ss_link_2 -O /dev/null
			[ "$?" == "0" ] && check=200 || { check=404; sleep 1; }
			if [ "$check" == "404" ] ; then
				wget --no-check-certificate -q -T 10 "$ss_link_2" -O /dev/null
				[ "$?" == "0" ] && check=200 || check=404
			fi
		else
			check=`curl -k -s -w "%{http_code}" "$ss_link_2" -o /dev/null`
			[ "$check" != "200" ] && sleep 1
			[ "$check" != "200" ] && check=`curl -k -s -w "%{http_code}" "$ss_link_2" -o /dev/null`
		fi
	fi
	if [ "$check" == "200" ] ; then
		logger -t "【SS】" " SS 服务器 $Server_ip 【$Server】 连接√"
		rebss="1"
		#跳出当前循环
		continue
	else
		logger -t "【SS】" " SS 服务器 $Server_ip 【$Server】检测到问题"
	fi
fi

#404
nvram set ss_internet="0"
[ ! -z $ss_rdd_server ] && logger -t "【SS】" " 两个 SS 服务器检测到问题, $rebss"
[ -z $ss_rdd_server ] && logger -t "【SS】" " SS 服务器 $CURRENT_ip 【$CURRENT】 检测到问题, $rebss"
rebss=`expr $rebss + 1`
restart_dhcpd
#/etc/storage/crontabs_script.sh &

done

}


ss_link_cron_job(){

/etc/storage/script/sh_link.sh

}

SS_swap(){


CURRENT=`nvram get ss_working_port`
[ ${CURRENT:=1090} ] && [ $CURRENT == 1091 ] && Server=1090 || Server=1091
[ $Server == 1090 ] && Server_ip=$ss_server1 && CURRENT_ip=$ss_server2
[ $Server == 1091 ] && Server_ip=$ss_server2 && CURRENT_ip=$ss_server1
ss_info=`nvram get button_script_2_s`
ss_internet=`nvram get ss_internet`
ss_rdd_server=`nvram get ss_server2`
kcptun2_enable=`nvram get kcptun2_enable`
[ -z $kcptun2_enable ] && kcptun2_enable=0 && nvram set kcptun2_enable=$kcptun2_enable
kcptun2_enable2=`nvram get kcptun2_enable2`
[ -z $kcptun2_enable2 ] && kcptun2_enable2=0 && nvram set kcptun2_enable2=$kcptun2_enable2
ss_mode_x=`nvram get ss_mode_x`
[ -z $ss_mode_x ] && ss_mode_x=0 && nvram set ss_mode_x=$ss_mode_x
[ "$ss_mode_x" != "0" ] && kcptun2_enable=$kcptun2_enable2
[ "$kcptun2_enable" = "2" ] && ss_rdd_server=""
if [ "$ss_internet" != "1" ] ; then
	logger -t "【ss】" "注意！各线路正在启动，请等待启动后再尝试切换"
fi
if [ -z $ss_rdd_server ] ; then
	logger -t "【ss】" "错误！备用线路未启用，请配置启用后再尝试切换"
fi
if [ ! -z $ss_rdd_server ] && [ "$ss_internet" = "1" ] ; then
	logger -t "【SS】" "手动切换 $ss_info 服务器 $CURRENT_ip 【$CURRENT】"
	nvram set ss_internet="2"
	#端口切换
	iptables -t nat -D SS_SPEC_WAN_FW -p tcp -j REDIRECT --to-port $CURRENT
	iptables -t nat -A SS_SPEC_WAN_FW -p tcp -j REDIRECT --to-port $Server
	if [ "$ss_udp_enable" == 1 ] ; then
		iptables -t mangle -D SS_SPEC_WAN_FW -p udp -j TPROXY --on-port $CURRENT --tproxy-mark 0x01/0x01
		iptables -t mangle -A SS_SPEC_WAN_FW -p udp -j TPROXY --on-port $Server --tproxy-mark 0x01/0x01
	fi
	if [ "$ss_pdnsd_wo_redir" == 0 ] ; then
	# pdnsd 是否直连  1、直连；0、走代理
		iptables -t nat -D OUTPUT -p tcp -d 8.8.8.8,8.8.4.4 --dport 53 -j REDIRECT --to-port $CURRENT
		iptables -t nat -D OUTPUT -p tcp -d 208.67.222.222,208.67.220.220 --dport 443 -j REDIRECT --to-port $CURRENT
		iptables -t nat -I OUTPUT -p tcp -d 8.8.8.8,8.8.4.4 --dport 53 -j REDIRECT --to-port $Server
		iptables -t nat -I OUTPUT -p tcp -d 208.67.222.222,208.67.220.220 --dport 443 -j REDIRECT --to-port $Server
	fi
	#加上切换标记
	nvram set ss_working_port=$Server
	ss_working_port=`nvram get ss_working_port`
	[ $ss_working_port == 1090 ] && ss_info="SS_[1]"
	[ $ss_working_port == 1091 ] && ss_info="SS_[2]"
	nvram set button_script_2_s="$ss_info"
	nvram set ss_internet="1"
	logger -t "【SS】" "当前使用 $ss_info 服务器 $Server_ip 【$Server】"
	#检查切换后的状态
	TAG="SS_SPEC"		  # iptables tag
	FWI="/tmp/firewall.shadowsocks.pdcn" # firewall include file
	[ -n "$FWI" ] && echo '#!/bin/sh' >$FWI
	gen_include
fi
}

ss_cron_job(){
	[ -z $ss_update ] && ss_update=0 && nvram set ss_update=$ss_update
	[ -z $ss_update_hour ] && ss_update_hour=23 && nvram set ss_update_hour=$ss_update_hour
	[ -z $ss_update_min ] && ss_update_min=59 && nvram set ss_update_min=$ss_update_min
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
if [ ! -f "$shadowsocks_ss_spec_lan" ] || [ ! -s "$shadowsocks_ss_spec_lan" ] ; then
	cat > "$shadowsocks_ss_spec_lan" <<-\EEE
#b,192.168.123.115
#g,192.168.123.116
#n,192.168.123.117
#1,192.168.123.118
#2,192.168.123.119
#b,099B9A909FD9
#1,099B9A909FD9
#2,A9:CB:3A:5F:1F:C7


EEE
	chmod 755 "$shadowsocks_ss_spec_lan"
fi

shadowsocks_ss_spec_wan="/etc/storage/shadowsocks_ss_spec_wan.sh"
if [ ! -f "$shadowsocks_ss_spec_wan" ] || [ ! -s "$shadowsocks_ss_spec_wan" ] ; then
	cat > "$shadowsocks_ss_spec_wan" <<-\EEE
WAN@raw.githubusercontent.com
#WAN+8.8.8.8
#WAN@www.google.com
#WAN!www.baidu.com
#WAN-223.5.5.5
#WAN-114.114.114.114
WAN!members.3322.org
WAN!www.cloudxns.net
WAN!dnsapi.cn
WAN!api.dnspod.com
WAN!www.ipip.net
WAN!alidns.aliyuncs.com


#以下样板是四个网段分别对应BLZ的美/欧/韩/台服
#WAN+24.105.0.0/18
#WAN+80.239.208.0/20
#WAN+182.162.0.0/16
#WAN+210.242.235.0/24
#以下样板是telegram
#WAN+149.154.160.1/32
#WAN+149.154.160.2/31
#WAN+149.154.160.4/30
#WAN+149.154.160.8/29
#WAN+149.154.160.16/28
#WAN+149.154.160.32/27
#WAN+149.154.160.64/26
#WAN+149.154.160.128/25
#WAN+149.154.161.0/24
#WAN+149.154.162.0/23
#WAN+149.154.164.0/22
#WAN+149.154.168.0/21
#WAN+91.108.4.0/22
#WAN+91.108.56.0/24
#WAN+109.239.140.0/24
#WAN+67.198.55.0/24
#WAN+91.108.56.172
#WAN+149.154.175.50


EEE
	chmod 755 "$shadowsocks_ss_spec_wan"
fi

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
	SS_keep
	;;
rules)
	start_ss_rules
	;;
flush)
	clean_ss_rules
	;;
update)
	#check_setting
	[ ${ss_enable:=0} ] && [ "$ss_enable" -eq "0" ] && exit 0
	# [ "$ss_mode_x" = "3" ] && exit 0
	#随机延时
	killall sh_sskeey_k.sh
	killall -9 sh_sskeey_k.sh
	if [ -z "$RANDOM" ] ; then
	SEED=`tr -cd 0-9 </dev/urandom | head -c 8`
	else
	SEED=$RANDOM
	fi
	RND_NUM=`echo $SEED 1 120|awk '{srand($1);printf "%d",rand()*10000%($3-$2)+$2}'`
	# echo $RND_NUM
	logger -t "【SS】" "$RND_NUM 秒后进入处理状态, 请稍候"
	sleep $RND_NUM
	# start_ss_rules
	# [ "$ss_mode_x" != "1" ] && update_chnroutes
	# [ "$ss_mode_x" != "2" ] && [ "$ss_pdnsd_all" != "1" ] && update_gfwlist
	nvram set ss_updatess2=1
	update_gfwlist
	update_chnroutes
	[ -s /tmp/sh_sskeey_k.sh ] && /tmp/sh_sskeey_k.sh &
	;;
updatess)
	logger -t "【SS】" "手动更新 SS 规则文件 5 秒后进入处理状态, 请稍候"
	sleep 5
	nvram set ss_updatess2=1
	update_gfwlist
	update_chnroutes
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
	rm -f /opt/bin/ss-redir /opt/bin/ssr-redir /opt/bin/ss-local /opt/bin/ssr-local /opt/bin/obfs-local
	rm -f /opt/bin/ss0-redir /opt/bin/ssr0-redir /opt/bin/ss0-local /opt/bin/ssr0-local
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





