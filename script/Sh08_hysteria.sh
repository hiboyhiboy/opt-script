#!/bin/bash
#copyright by hiboy
source /etc/storage/script/init.sh
TAG="SSTP"		  # iptables tag
FWI="/tmp/firewall.hysteria.pdcn"
hysteria_enable=`nvram get app_136`
[ -z $hysteria_enable ] && hysteria_enable=0 && nvram set app_136=0
hysteria_follow=`nvram get app_137`
[ -z $hysteria_follow ] && hysteria_follow=0 && nvram set app_137=0
transocks_mode_x=`nvram get app_28`
[ -z $transocks_mode_x ] && transocks_mode_x=0 && nvram set app_28=0
ss_ip46=`nvram get ss_ip46`
[ -z $ss_ip46 ] && ss_ip46=0 && nvram set ss_ip46=0

if [ "$hysteria_enable" != "0" ] ; then
if [ "$hysteria_follow" != 0 ] ; then
ss_tproxy_auser=`nvram get ss_tproxy_auser`
	if [ "Sh08_hysteria.sh" != "$ss_tproxy_auser" ] && [ "" != "$ss_tproxy_auser" ] ; then
		logger -t "【hysteria】" "错误！！！由于已启用 $ss_tproxy_auser 透明代理，停止启用 hysteria 透明代理！"
		hysteria_follow=0 && nvram set app_137=0
	fi
fi
/etc/storage/script/sh_ezscript.sh 3 & #更新按钮状态
#nvramshow=`nvram showall | grep '=' | grep hysteria | awk '{print gensub(/'"'"'/,"'"'"'\"'"'"'\"'"'"'","g",$0);}'| awk '{print gensub(/=/,"='\''",1,$0)"'\'';";}'` && eval $nvramshow

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

LAN_AC_IP=`nvram get LAN_AC_IP`
[ -z $LAN_AC_IP ] && LAN_AC_IP=0 && nvram set LAN_AC_IP=$LAN_AC_IP
ss_DNS_Redirect=`nvram get ss_DNS_Redirect`
ss_DNS_Redirect_IP=`nvram get ss_DNS_Redirect_IP`
[ -z "$ss_DNS_Redirect_IP" ] && ss_DNS_Redirect_IP=$lan_ipaddr
hysteria_renum=`nvram get hysteria_renum`
cmd_log_enable=`nvram get cmd_log_enable`
cmd_name="hysteria"
cmd_log=""
if [ "$cmd_log_enable" = "1" ] || [ "$hysteria_renum" -gt "0" ] ; then
	cmd_log="$cmd_log2"
fi

fi

if [ ! -z "$(echo $scriptfilepath | grep -v "/tmp/script/" | grep hysteria)" ]  && [ ! -s /tmp/script/_app24 ]; then
	mkdir -p /tmp/script
	{ echo '#!/bin/bash' ; echo $scriptfilepath '"$@"' '&' ; } > /tmp/script/_app24
	chmod 777 /tmp/script/_app24
fi

hysteria_restart () {

relock="/var/lock/hysteria_restart.lock"
if [ "$1" = "o" ] ; then
	nvram set hysteria_renum="0"
	[ -f $relock ] && rm -f $relock
	return 0
fi
if [ "$1" = "x" ] ; then
	if [ -f $relock ] ; then
		logger -t "【hysteria】" "多次尝试启动失败，等待【"`cat $relock`"分钟】后自动尝试重新启动"
		exit 0
	fi
	hysteria_renum=${hysteria_renum:-"0"}
	hysteria_renum=`expr $hysteria_renum + 1`
	nvram set hysteria_renum="$hysteria_renum"
	if [ "$hysteria_renum" -gt "3" ] ; then
		I=19
		echo $I > $relock
		logger -t "【hysteria】" "多次尝试启动失败，等待【"`cat $relock`"分钟】后自动尝试重新启动"
		while [ $I -gt 0 ]; do
			I=$(($I - 1))
			echo $I > $relock
			sleep 60
			[ "$(nvram get hysteria_renum)" = "0" ] && exit 0
			[ $I -lt 0 ] && break
		done
		nvram set hysteria_renum="1"
	fi
	[ -f $relock ] && rm -f $relock
fi
nvram set hysteria_status=0
eval "$scriptfilepath &"
exit 0
}

hysteria_get_status () {

A_restart=`nvram get hysteria_status`
B_restart="$hysteria_enable$ss_ip46$chinadns_enable$chinadns_ng_enable$hysteria_follow$transocks_mode_x$ss_udp_enable$app_114"
B_restart="$B_restart""$(cat /etc/storage/app_34.sh | grep -v '^#' | grep -v "^$")"
B_restart=`echo -n "$B_restart" | md5sum | sed s/[[:space:]]//g | sed s/-//g`
cut_B_re
if [ "$A_restart" != "$B_restart" ] ; then
	nvram set hysteria_status=$B_restart
	needed_restart=1
else
	needed_restart=0
fi
}

hysteria_check () {

hysteria_get_status
if [ "$hysteria_enable" != "1" ] && [ "$needed_restart" = "1" ] ; then
	[ ! -z "`pidof hysteria`" ] && logger -t "【hysteria】" "停止 hysteria" && hysteria_close
	{ kill_ps "$scriptname" exit0; exit 0; }
fi
if [ "$hysteria_enable" = "1" ] ; then
	if [ "$needed_restart" = "1" ] ; then
		hysteria_close
		hysteria_start
	else
		[ -z "`pidof hysteria`" ] && hysteria_restart
		if [ "$hysteria_follow" = "1" ] ; then
			echo hysteria_follow
		fi
	fi
fi
}

hysteria_keep () {
logger -t "【hysteria】" "守护进程启动"
/etc/storage/script/sh_ezscript.sh 3 & #更新按钮状态
if [ -s /tmp/script/_opt_script_check ]; then
SVC_PATH="$(which hysteria)"
sed -Ei '/【hysteria】|^$/d' /tmp/script/_opt_script_check
cat >> "/tmp/script/_opt_script_check" <<-OSC
	[ -z "\`pidof hysteria\`" ] || [ ! -s "$SVC_PATH" ] && nvram set hysteria_status=00 && logger -t "【hysteria】" "重新启动" && eval "$scriptfilepath &" && sed -Ei '/【hysteria】|^$/d' /tmp/script/_opt_script_check # 【hysteria】
OSC
#return
fi
hysteria_enable=`nvram get app_136`
while [ "$hysteria_enable" = "1" ]; do
	hysteria_follow=`nvram get app_137`
	if [ "$hysteria_follow" = "1" ] ; then
		ss_internet="$(nvram get ss_internet)"
		[ "$ss_internet" != "1" ] && nvram set ss_internet="1"
	fi
sleep 68
hysteria_enable=`nvram get app_136`
done
}

hysteria_close () {
kill_ps "$scriptname keep"
nvram set ss_internet="0"
sed -Ei '/【hysteria】|^$/d' /tmp/script/_opt_script_check
Sh99_ss_tproxy.sh off_stop "Sh08_hysteria.sh"
killall hysteria
killall -9 hysteria
restart_on_dhcpd
/etc/storage/script/sh_ezscript.sh 3 & #更新按钮状态
kill_ps "/tmp/script/_app24"
kill_ps "_hysteria.sh"
kill_ps "$scriptname"
}

hysteria_start () {
check_webui_yes
ss_internet="$(nvram get ss_internet)"
[ "$ss_internet" != "2" ] && nvram set ss_internet="2"
SVC_PATH="$(which hysteria)"
[ ! -s "$SVC_PATH" ] && SVC_PATH="/opt/bin/hysteria"
if [ ! -s "$SVC_PATH" ] ; then
	logger -t "【hysteria】" "找不到 $SVC_PATH，安装 opt 程序"
	/etc/storage/script/Sh01_mountopt.sh start
	initopt
fi
for h_i in $(seq 1 2) ; do
[[ "$($SVC_PATH -h 2>&1 | wc -l)" -lt 2 ]] && [ ! -z $SVC_PATH ] && rm -rf $SVC_PATH
wgetcurl_file "$SVC_PATH" "$hiboyfile/hysteria" "$hiboyfile2/hysteria"
done
hysteria_v=$($SVC_PATH -v | grep Hysteria | awk -F ' ' '{print $3;}')
[ -z "$hysteria_v" ] && hysteria_v=$($SVC_PATH -v)
nvram set hysteria_v="$hysteria_v"
if [ ! -s "$SVC_PATH" ] ; then
	logger -t "【hysteria】" "找不到 $SVC_PATH ，需要手动安装 $SVC_PATH"
	logger -t "【hysteria】" "启动失败, 10 秒后自动尝试重新启动" && sleep 10 && hysteria_restart x
fi
Available_A=$(df -m | grep "% /opt" | awk 'NR==1' | awk -F' ' '{print $4}')
size_tmpfs=`nvram get size_tmpfs`
if [ "$size_tmpfs" = "0" ] && [[ "$Available_A" -lt 15 ]] ; then
mount -o remount,size=60% tmpfs /tmp
Available_B=$(df -m | grep "% /opt" | awk 'NR==1' | awk -F' ' '{print $4}')
logger -t "【ss_tproxy】" "调整 /tmp 挂载分区的大小， /opt 可用空间： $Available_A → $Available_B M"
fi
cd "$(dirname "$SVC_PATH")"
tcponly='true'
gid_owner="0"
su_cmd="eval"
NUM=`iptables -m owner -h 2>&1 | grep owner | wc -l`
hash su 2>/dev/null && su_x="1"
hash su 2>/dev/null || su_x="0"
if [ "$NUM" -ge "3" ] && [ "$su_x" = "1" ] ; then
	addgroup -g 1321 ‍✈️
	adduser -G ‍✈️ -u 1321 ‍✈️ -D -S -H -s /bin/sh
	sed -Ei s/1321:1321/0:1321/g /etc/passwd
	su_cmd="su ‍✈️ -c "
	gid_owner="1321"
fi
nvram set gid_owner="$gid_owner"
if [ "$hysteria_follow" = "1" ] ; then
if [ "$ss_udp_enable" = "1" ] || [ "$app_114" = "0" ] ; then
	[ "$su_x" != "1" ] && logger -t "【hysteria】" "缺少 su 命令"
	[ "$NUM" -ge "3" ] || logger -t "【hysteria】" "缺少 iptables -m owner 模块"
	if [ "$NUM" -ge "3" ] && [ "$su_x" = "1" ] ; then
		[ "$ss_udp_enable" = "1" ] && tcponly='false'
	else
		ss_udp_enable=0
		nvram set ss_udp_enable=0
		app_114=1
		nvram set app_114=1
	fi
fi
[ "$ss_udp_enable" = "0" ] && logger -t "【hysteria】" "仅代理 TCP 流量"
[ "$ss_udp_enable" = "1" ] && logger -t "【hysteria】" "代理 TCP 和 UDP 流量"
[ "$app_114" = "0" ] && logger -t "【hysteria】" "启动路由自身流量走透明代理"
[ "$app_114" = "1" ] && logger -t "【hysteria】" "停止路由自身流量走透明代理"
fi
logger -t "【hysteria】" "运行 $SVC_PATH"
/etc/storage/app_34.sh
su_cmd2="$SVC_PATH -config /tmp/hysteria.json"
eval "$su_cmd" '"cmd_name=hysteria && '"$su_cmd2"' $cmd_log"' &
sleep 4
[ ! -z "`pidof hysteria`" ] && logger -t "【hysteria】" "启动成功" && hysteria_restart o
[ -z "`pidof hysteria`" ] && logger -t "【hysteria】" "启动失败, 注意检hysteria是否下载完整,10 秒后自动尝试重新启动" && sleep 10 && hysteria_restart x

if [ "$hysteria_follow" = "1" ] ; then
Sh99_ss_tproxy.sh auser_check "Sh08_hysteria.sh"
ss_tproxy_set "Sh08_hysteria.sh"
Sh99_ss_tproxy.sh on_start "Sh08_hysteria.sh"
# 同时将代理规则应用到 OUTPUT 链, 让路由自身流量走透明代理
if [ "$app_114" = 0 ] ; then
logger -t "【hysteria】" "同时将透明代理规则应用到 OUTPUT 链, 让路由自身流量走透明代理"
fi
logger -t "【hysteria】" "完成 透明代理 转发规则设置"
if [ "$chinadns_enable" != "0" ] || [ "$chinadns_ng_enable" != "0" ] ; then
logger -t "【hysteria】" "已经启动 chinadns 防止域名污染"
fi
restart_on_dhcpd
logger -t "【hysteria】" "启动后若发现一些网站打不开, 估计是 DNS 被污染了. 解决 DNS 被污染方法："
logger -t "【hysteria】" "①电脑设置 DNS 自动获取路由 ip。检查 hosts 是否有错误规则。"
logger -t "【hysteria】" "②电脑运行 cmd 输入【ipconfig /flushdns】, 清理浏览器缓存。"
# 透明代理
fi
nvram set ss_internet="1"
eval "$scriptfilepath keep &"

exit 0
}

ss_tproxy_set() {
ss_tproxy_auser=`nvram get ss_tproxy_auser`
if [ "$1" != "$ss_tproxy_auser" ] ; then
	logger -t "【hysteria】" "脚本 [Sh99_ss_tproxy.sh] 当前使用者: $auser_b ，跳过 $auser_a 的运行命令"
	logger -t "【hysteria】" "需要停用 $auser_b 后才能使用 $auser_a 运行 [Sh99_ss_tproxy.sh] 脚本"
	return
fi
lan_ipaddr=`nvram get lan_ipaddr`
ss_tproxy_mode_x=`nvram get app_110`
[ -z $ss_tproxy_mode_x ] && ss_tproxy_mode_x=0 && nvram set app_110=0
[ "$ss_tproxy_mode_x" = "0" ] && logger -t "【hysteria】" "【自动】设置 ss_tproxy 配置文件，配置导入中..."
[ "$ss_tproxy_mode_x" = "1" ] && logger -t "【hysteria】" "【手动】设置 ss_tproxy 配置文件，跳过配置导入" && return
 # /etc/storage/app_27.sh
[ "$transocks_mode_x" == "0" ] && sstp_set mode='chnroute'
[ "$transocks_mode_x" == "1" ] && sstp_set mode='gfwlist'
[ "$transocks_mode_x" == "2" ] && sstp_set mode='global'
[ "$transocks_mode_x" == "3" ] && sstp_set mode='chnlist'
[ "$ss_ip46" = "0" ] && { sstp_set ipv4='true' ; sstp_set ipv6='false' ; }
[ "$ss_ip46" = "1" ] && { sstp_set ipv4='false' ; sstp_set ipv6='true' ; }
[ "$ss_ip46" = "2" ] && { sstp_set ipv4='true' ; sstp_set ipv6='true' ; }
[ "$ss_ip46" = "0" ] && sstp_set tproxy='false' # true:TPROXY+TPROXY; false:REDIRECT+TPROXY
[ "$ss_ip46" != "0" ] && sstp_set tproxy='true'
sstp_set tcponly="$tcponly" # true:仅代理TCP流量; false:代理TCP和UDP流量
sstp_set selfonly='false'  # true:仅代理本机流量; false:代理本机及"内网"流量
nvram set app_112="1"      #app_112 0:自动开启第三方 DNS 程序(dnsproxy) ; 1:跳过自动开启第三方 DNS 程序但是继续把DNS绑定到 8053 端口的程序
#nvram set ss_pdnsd_all="0" # 0使用[本地DNS] + [GFW规则]查询DNS ; 1 使用 8053 端口查询全部 DNS
#nvram set app_113="0"      #app_113 0:使用 8053 端口查询全部 DNS 时进行 China 域名加速 ; 1:不进行 China 域名加速
sstp_set uid_owner='0'     # 非 0 时进行用户ID匹配跳过代理本机流量
gid_owner="$(nvram get gid_owner)"
sstp_set gid_owner="$gid_owner" # 非 0 时进行组ID匹配跳过代理本机流量
## proxy
sstp_set proxy_all_svraddr="/opt/app/ss_tproxy/conf/proxy_all_svraddr.conf"
sstp_set proxy_svrport='1:65535'
[ "$ss_ip46" = "0" ] && sstp_set proxy_tcpport='18000'
[ "$ss_ip46" != "0" ] && sstp_set proxy_tcpport='18001'
sstp_set proxy_udpport='18002'
sstp_set proxy_startcmd='date'
sstp_set proxy_stopcmd='date'
## dns
DNS_china=`nvram get wan0_dns |cut -d ' ' -f1`
[ -z "$DNS_china" ] && DNS_china="223.5.5.5"
sstp_set dns_direct="$DNS_china"
sstp_set dns_direct6='240C::6666'
sstp_set dns_remote='8.8.8.8#53'
sstp_set dns_remote6='::1#8053'
[ "$transocks_mode_x" == "3" ] && sstp_set dns_direct='8.8.8.8' # 回国模式
[ "$transocks_mode_x" == "3" ] && sstp_set dns_direct6='2001:4860:4860::8888' # 回国模式
[ "$transocks_mode_x" == "3" ] && sstp_set dns_remote='223.5.5.5#53' # 回国模式
[ "$transocks_mode_x" == "3" ] && sstp_set dns_remote6='240C::6666#53' # 回国模式
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
# hysteria
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
logger -t "【hysteria】" "【自动】设置 ss_tproxy 配置文件，完成配置导入"
}

initopt () {
optPath=`grep ' /opt ' /proc/mounts | grep tmpfs`
[ ! -z "$optPath" ] && return
if [ ! -z "$(echo $scriptfilepath | grep -v "/opt/etc/init")" ] && [ -s "/opt/etc/init.d/rc.func" ] ; then
	{ echo '#!/bin/bash' ; echo $scriptfilepath '"$@"' '&' ; } > /opt/etc/init.d/$scriptname && chmod 777  /opt/etc/init.d/$scriptname
fi

}

initconfig () {

app_34="/etc/storage/app_34.sh"
if [ ! -f "$app_34" ] || [ ! -s "$app_34" ] || [ -z "$(cat $app_34 | grep "ss_ip46" )" ] ; then
	cat > "$app_34" <<-\EEE
#!/bin/bash
ss_ip46=`nvram get ss_ip46` ; tp_set="4" ;
[ "$ss_ip46" = "1" ] && tp_set="6" ; [ "$ss_ip46" = "2" ] && tp_set="46" ;


# hysteria 配置
cat > "/tmp/hysteria.json" <<-EEFF
{
  "server": "example.com:36712",
  "obfs": "password",
  "protocol": "udp",
  "up_mbps": 10,
  "down_mbps": 50,
  "retry": -1,
  "retry_interval": 10,
  "quit_on_disconnect": false,
  "handshake_timeout": 10,
  "idle_timeout": 100,
  "hop_interval": 180,
  "socks5": {
    "listen": "0.0.0.0:1089",
    "timeout": 300,
    "disable_udp": false,
    "user": "",
    "password": ""
  },
  "relay_tcps": [
    {
      "listen": ":8053",
      "remote": "8.8.8.8:53",
      "timeout": 300
    }
  ],
  "relay_udps": [
    {
      "listen": ":8053",
      "remote": "8.8.8.8:53",
      "timeout": 60
    }
  ],
  "redirect_tcp": {
    "listen": "127.0.0.1:18000",
    "timeout": 300
  },
  "tproxy_tcp": {
    "listen": ":18001",
    "timeout": 300
  },
  "tproxy_udp": {
    "listen": ":18002",
    "timeout": 60
  },
  "disable_mtu_discovery": true,
  "resolver": "udp://8.8.8.8:53",
  "resolve_preference": "$tp_set"
}

EEFF

EEE
	chmod 755 "$app_34"
fi

}

initconfig

update_app () {
mkdir -p /opt/app/hysteria
if [ "$1" = "update_asp" ] ; then
	rm -rf /opt/app/hysteria/Advanced_Extensions_hysteria.asp
fi
if [ "$1" = "del" ] ; then
	rm -rf /opt/app/hysteria/Advanced_Extensions_hysteria.asp /opt/bin/hysteria /opt/opt_backup/bin/hysteria
fi

initconfig

# 加载程序配置页面
if [ ! -f "/opt/app/hysteria/Advanced_Extensions_hysteria.asp" ] || [ ! -s "/opt/app/hysteria/Advanced_Extensions_hysteria.asp" ] ; then
	wgetcurl.sh /opt/app/hysteria/Advanced_Extensions_hysteria.asp "$hiboyfile/Advanced_Extensions_hysteriaasp" "$hiboyfile2/Advanced_Extensions_hysteriaasp"
fi
umount /www/Advanced_Extensions_app24.asp
mount --bind /opt/app/hysteria/Advanced_Extensions_hysteria.asp /www/Advanced_Extensions_app24.asp
# 更新程序启动脚本

[ "$1" = "del" ] && /etc/storage/www_sh/hysteria del &
}

case $ACTION in
start)
	hysteria_close
	hysteria_check
	;;
check)
	hysteria_check
	;;
stop)
	hysteria_close
	;;
updateapp24)
	hysteria_restart o
	[ "$hysteria_enable" = "1" ] && nvram set hysteria_status="updatehysteria" && logger -t "【hysteria】" "重启" && hysteria_restart
	[ "$hysteria_enable" != "1" ] && nvram set hysteria_v="" && logger -t "【hysteria】" "更新" && update_app del
	;;
update_app)
	update_app
	;;
update_asp)
	update_app update_asp
	;;
keep)
	#hysteria_check
	hysteria_keep
	;;
*)
	hysteria_check
	;;
esac

