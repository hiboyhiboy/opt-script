#!/bin/bash
#copyright by hiboy
source /etc/storage/script/init.sh
source /etc/storage/script/sh_link.sh
TAG="SSTP"		  # iptables tag
FWI="/tmp/firewall.clash.pdcn"
clash_enable=`nvram get app_88`
[ -z $clash_enable ] && clash_enable=0 && nvram set app_88=0
clash_http_enable=`nvram get app_89`
[ -z $clash_http_enable ] && clash_http_enable=0 && nvram set app_89=0
clash_socks_enable=`nvram get app_90`
[ -z $clash_socks_enable ] && clash_socks_enable=0 && nvram set app_90=0
clash_wget_yml=`nvram get app_91` # 订阅地址
clash_follow=`nvram get app_92`
[ -z $clash_follow ] && clash_follow=0 && nvram set app_92=0
ss_udp_enable=`nvram get ss_udp_enable` #udp转发  0、停用；1、启动
[ -z $ss_udp_enable ] && ss_udp_enable=0 && nvram set ss_udp_enable=0
app_114=`nvram get app_114` #0:代理本机流量; 1:跳过代理本机流量
[ -z $app_114 ] && app_114=0 && nvram set app_114=0
lan_ipaddr=`nvram get lan_ipaddr`
clash_ui=`nvram get app_94`
if [ -z $clash_ui ] || [ ! -z "$(echo "$clash_ui" | grep "0.0.0.0")" ] || [ -z "$(echo $clash_ui | grep ":")" ] ; then
	SEED=`tr -cd 0-9 </dev/urandom | head -c 8`
	RND_NUM=`echo $SEED 19090 49090|awk '{srand($1);printf "%d",rand()*10000%($3-$2)+$2}'`
	clash_ui="$lan_ipaddr:$RND_NUM" && nvram set app_94="$clash_ui"
fi
app_default_config=`nvram get app_115`
[ -z $app_default_config ] && app_default_config=0 && nvram set app_115=0
clash_secret=`nvram get app_119`
if [ -z $clash_secret ] ; then
	SEED=`tr -cd 0-9 </dev/urandom | head -c 8`
	RND_NUM=`echo $SEED 8 12|awk '{srand($1);printf "%d",rand()*10000%($3-$2)+$2}'`
	clash_secret="$(echo -n $SEED | md5sum | sed s/[[:space:]]//g | sed s/-//g | head -c $RND_NUM)"
	nvram set app_119=$clash_secret
fi
app_120=`nvram get app_120`
curltest=`which curl`
secret=""
api_port=""
log_level=`nvram get app_121`
clash_mode_x=`nvram get app_122`
[ -z $clash_mode_x ] && clash_mode_x=0 && nvram set app_122=0
[ -z $log_level ] && log_level="error" && nvram set app_121="error"
app_78="$(nvram get app_78)"
app_79="$(nvram get app_79)"
[ -z $app_79 ] && app_79="clash" && nvram set app_79="clash"
if [ "$clash_enable" != "0" ] ; then
if [ "$clash_follow" != 0 ] ; then
ss_tproxy_auser=`nvram get ss_tproxy_auser`
	if [ "Sh10_clash.sh" != "$ss_tproxy_auser" ] && [ "" != "$ss_tproxy_auser" ] ; then
		logger -t "【clash】" "错误！！！由于已启用 $ss_tproxy_auser 透明代理，停止启用 clash 透明代理！"
		clash_follow=0 && nvram set app_92=0
	fi
fi
/etc/storage/script/sh_ezscript.sh 3 & #更新按钮状态

clash_input="$(nvram get app_93)"
[ -z $clash_input ] && clash_input=0 && nvram set clash_input=0
clash_mixed="$(nvram get app_101)"
[ -z $clash_mixed ] && clash_mixed=0 && nvram set clash_mixed=0
chinadns_ng_enable=`nvram get app_102`
[ -z $chinadns_ng_enable ] && chinadns_ng_enable=0 && nvram set app_102=0
chinadns_port=`nvram get app_6`
[ -z $chinadns_port ] && chinadns_port=8053 && nvram set app_6=8053
if [ "$chinadns_port" != "8053" ] && [ "$chinadns_ng_enable" = "3" ] ; then
chinadns_ng_enable=2
fi
if [ "$chinadns_ng_enable" = "1" ] ; then
chinadns_ng_enable=0
fi
ss_ip46=`nvram get ss_ip46`
[ -z $ss_ip46 ] && ss_ip46=0 && nvram set ss_ip46=0
LAN_AC_IP=`nvram get LAN_AC_IP`
[ -z $LAN_AC_IP ] && LAN_AC_IP=0 && nvram set LAN_AC_IP=$LAN_AC_IP
ss_DNS_Redirect=`nvram get ss_DNS_Redirect`
ss_DNS_Redirect_IP=`nvram get ss_DNS_Redirect_IP`
[ -z "$ss_DNS_Redirect_IP" ] && ss_DNS_Redirect_IP=$lan_ipaddr
clash_renum=`nvram get clash_renum`
cmd_log_enable=`nvram get cmd_log_enable`
cmd_name="clash"
cmd_log=""
if [ "$cmd_log_enable" = "1" ] || [ "$clash_renum" -gt "0" ] ; then
	cmd_log="$cmd_log2"
fi

fi

if [ ! -z "$(echo $scriptfilepath | grep -v "/tmp/script/" | grep clash)" ] && [ ! -s /tmp/script/_app18 ] ; then
	mkdir -p /tmp/script
	{ echo '#!/bin/bash' ; echo $scriptfilepath '"$@"' '&' ; } > /tmp/script/_app18
	chmod 777 /tmp/script/_app18
fi

clash_restart () {
i_app_restart "$@" -name="clash"
}

clash_get_status () {

B_restart="$clash_enable$chinadns_ng_enable$clash_http_enable$clash_socks_enable$clash_wget_yml$clash_follow$clash_ui$clash_input$clash_mixed$app_default_config$clash_secret$app_120$log_level$clash_mode_x$ss_udp_enable$app_114$app_78$ss_ip46"
B_restart="$B_restart""$(cat /etc/storage/app_21.sh | grep -v '^#' | grep -v '^$')""$(cat /etc/storage/app_33.sh | grep -v '^#' | grep -v '^$')"
if [ -z "$curltest" ] || [ "$app_120" == "2" ] ; then
B_restart="$B_restart""$(cat /etc/storage/app_20.sh | grep -v '^#' | grep -v '^$')"
fi
[ "$(nvram get app_86)" = "wget_yml" ] && wget_yml
[ "$(nvram get app_86)" = "clash_wget_geoip" ] && update_geoip

i_app_get_status -name="clash" -valb="$B_restart"

if [ "$needed_restart" = "1" ] ; then
	if [ -z "$clash_wget_yml" ] ; then
		cru.sh d clash_link_update
		logger -t "【clash】" "停止 clash 服务器订阅"
	else
		if [ "$app_120" == "1" ] ; then
			cru.sh a clash_link_update "24 */6 * * * $scriptfilepath wget_yml &" &
			logger -t "【clash】" "启动 clash 服务器订阅，添加计划任务 (Crontab)，每6小时更新"
		else
			cru.sh d clash_link_update
		fi
	fi
fi
}

clash_check () {

clash_get_status
if [ "$clash_enable" != "1" ] && [ "$needed_restart" = "1" ] ; then
	[ ! -z "`pidof clash`" ] && logger -t "【clash】" "停止 clash" && clash_close
	{ kill_ps "$scriptname" exit0; exit 0; }
fi
if [ "$clash_enable" = "1" ] ; then
	[ ! -z "`pidof clash`" ] && clash_get_clash_webs
	if [ "$needed_restart" = "1" ] ; then
		[ ! -z "`pidof clash`" ] && clash_get_releases
		clash_close
		clash_start
	else
		[ -z "`pidof clash`" ] && clash_restart
		if [ "$clash_follow" = "1" ] ; then
			echo clash_follow
		fi
	fi
	[ ! -z "$curltest" ] && [ "$app_120" != "2" ] && i_app_get_status "$@" -name="clash_2" -valb="$(cat /etc/storage/app_20.sh | grep -v '^#' | grep -v '^$')"
	if [ "$needed_restart" = "1" ] || [ "$(nvram get app_86)" = "clash_save_yml" ] ; then
		#api热重载
		reload_api
	fi
fi

}

clash_keep () {
/etc/storage/script/sh_ezscript.sh 3 & #更新按钮状态
i_app_keep -name="clash" -pidof="clash" &
while true; do
[ "$(grep "</textarea>"  /etc/storage/app_20.sh | wc -l)" != 0 ] && sed -Ei s@\<\/textarea\>@@g /etc/storage/app_20.sh
sleep 68
done
}

clash_close () {
kill_ps "$scriptname keep"
[ "$(nvram get ss_internet)" != "0" ] && nvram set ss_internet="0"
sed -Ei '/【clash】|^$/d' /tmp/script/_opt_script_check
Sh99_ss_tproxy.sh off_stop "Sh10_clash.sh"
killall clash
restart_on_dhcpd
/etc/storage/script/sh_ezscript.sh 3 & #更新按钮状态
kill_ps "/tmp/script/_app18"
kill_ps "_clash.sh"
kill_ps "$scriptname"
}

clash_start () {
check_webui_yes
SVC_PATH="$(which clash)"
[ "$(nvram get ss_internet)" != "2" ] && nvram set ss_internet="2"
if [ "$app_78" == "premium" ] || [ "$app_78" == "premium_1" ] ; then
	[ ! -s "$SVC_PATH" ] && logger -t "【clash】" "下载 premium (闭源版) 主程序: https://github.com/Dreamacro/clash/releases/tag/premium"
	[ "$app_78" != "premium_1" ] && nvram set app_78="premium_1" && app_78="premium_1"
	i_app_get_cmd_file -name="clash" -cmd="clash" -cpath="/opt/bin/clash" -down1="$hiboyfile/clash-premium" -down2="$hiboyfile2/clash-premium"
else
	[ ! -s "$SVC_PATH" ] && logger -t "【clash】" "下载 mihomo.Meta 主程序: https://github.com/MetaCubeX/mihomo"
	[ "$app_78" != "meta_1" ] && nvram set app_78="meta_1" && app_78="meta_1"
	i_app_get_cmd_file -name="clash" -cmd="clash" -cpath="/opt/bin/clash" -down1="$hiboyfile/clash-meta" -down2="$hiboyfile2/clash-meta"
fi
clash_v=$($SVC_PATH -v | grep Clash | awk -F ' ' '{print $2;}')
[ -z "$clash_v" ] && clash_v=$($SVC_PATH -v | grep Meta | awk -F ' ' '{print $2;}')
[ -z "$clash_v" ] && clash_v=$($SVC_PATH -v)
[ "$clash_v" == "Meta" ] && clash_v="$clash_v""_""$($SVC_PATH -v | grep Meta | awk -F ' ' '{print $3;}')"
nvram set clash_v="$clash_v"
clash_path="$SVC_PATH"
i_app_get_cmd_file -name="clash" -cmd="yq" -cpath="/opt/bin/yq" -down1="$hiboyfile/yq" -down2="$hiboyfile2/yq"
SVC_PATH="$clash_path"
Available_A=$(df -m | grep "% /opt" | awk 'NR==1' | awk -F' ' '{print $4}')
size_tmpfs=`nvram get size_tmpfs`
if [ "$size_tmpfs" = "0" ] && [[ "$Available_A" -lt 15 ]] ; then
mount -o remount,size=60% tmpfs /tmp
Available_B=$(df -m | grep "% /opt" | awk 'NR==1' | awk -F' ' '{print $4}')
logger -t "【clash】" "调整 /tmp 挂载分区的大小， /opt 可用空间： $Available_A → $Available_B M"
fi
mkdir -p /opt/app/clash/clash_webs/
if [ ! -s /opt/app/clash/config/Country.mmdb ] ; then
logger -t "【clash】" "初次启动会自动下载 geoip 数据库文件：/opt/app/clash/config/Country.mmdb"
logger -t "【clash】" "备注：如果缺少 geoip 数据库文件会启动失败，需 v0.17.1 或以上版本才能自动下载 geoip 数据库文件"
if [ ! -f /opt/app/clash/config/Country_mmdb ] ; then
Mem_total="$(free | sed -n '2p' | awk '{print $2;}')"
[ "$Mem_total" -lt 1024 ] && Mem_total="1024" || { [ "$Mem_total" -ge 1024 ] || Mem_total="1024" ; }
Mem_M=$(($Mem_total / 1024 ))
if [ "$Mem_M" -lt "200" ] ; then
logger -t "【clash】" "内存 $Mem_M ，下载使用 Country-only-cn-private.mmdb"
wgetcurl_checkmd5 /opt/app/clash/config/Country.mmdb "https://testingcf.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@release/country-lite.mmdb" "$hiboyfile/Country-only-cn-private.mmdb" N
else
logger -t "【clash】" "内存 $Mem_M ，下载使用 Country.mmdb"
wgetcurl_checkmd5 /opt/app/clash/config/Country.mmdb "https://testingcf.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@release/country.mmdb" "$hiboyfile/Country.mmdb" N
fi
[ -s /opt/app/clash/config/Country.mmdb ] && touch /opt/app/clash/config/Country_mmdb
fi
fi

update_yml

cd "$(dirname "$SVC_PATH")"
tcponly='true'
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
if [ "$clash_follow" = "1" ] ; then
if [ "$ss_udp_enable" = "1" ] || [ "$app_114" = "0" ] ; then
	[ "$su_x" != "1" ] && logger -t "【clash】" "缺少 su 命令"
	[ "$NUM" -ge "3" ] || logger -t "【clash】" "缺少 iptables -m owner 模块"
	if [ "$NUM" -ge "3" ] && [ "$su_x" = "1" ] ; then
		[ "$ss_udp_enable" = "1" ] && tcponly='false'
	else
		ss_udp_enable=0
		nvram set ss_udp_enable=0
		app_114=1
		nvram set app_114=1
	fi
fi
[ "$ss_udp_enable" = "0" ] && logger -t "【clash】" "仅代理 TCP 流量"
[ "$ss_udp_enable" = "1" ] && logger -t "【clash】" "代理 TCP 和 UDP 流量"
[ "$app_114" = "0" ] && logger -t "【clash】" "启动路由自身流量走透明代理"
[ "$app_114" = "1" ] && logger -t "【clash】" "停止路由自身流量走透明代理"
fi
logger -t "【clash】" "运行 $SVC_PATH"
chmod 777 /opt/app/clash/config -R
chmod 777 /opt/app/clash/config
chmod 644 /opt/etc/ssl/certs -R
chmod 777 /opt/etc/ssl/certs
chmod 644 /etc/ssl/certs -R
chmod 777 /etc/ssl/certs
$SVC_PATH -t -d /opt/app/clash/config >/dev/null
if [ "$?" = 0 ];then
su_cmd2="$SVC_PATH -d /opt/app/clash/config"
eval "$su_cmd" '"cmd_name=clash && '"$su_cmd2"' $cmd_log"' &
sleep 4
fi
i_app_keep -t -name="clash" -pidof="clash"
clash_get_status
i_app_get_status -name="clash_2" -valb="$(cat /etc/storage/app_20.sh | grep -v '^#' | grep -v '^$')"

if [ "$clash_follow" = "1" ] ; then
Sh99_ss_tproxy.sh auser_check "Sh10_clash.sh"
ss_tproxy_set "Sh10_clash.sh"
Sh99_ss_tproxy.sh on_start "Sh10_clash.sh"
# 同时将代理规则应用到 OUTPUT 链, 让路由自身流量走透明代理
if [ "$app_114" = 0 ] ; then
logger -t "【clash】" "同时将透明代理规则应用到 OUTPUT 链, 让路由自身流量走透明代理"
fi
logger -t "【clash】" "完成 透明代理 转发规则设置"
restart_on_dhcpd
logger -t "【clash】" "启动后若发现一些网站打不开, 估计是 DNS 被污染了. 解决 DNS 被污染方法："
logger -t "【clash】" "①电脑设置 DNS 自动获取路由 ip。检查 hosts 是否有错误规则。"
logger -t "【clash】" "②电脑运行 cmd 输入【ipconfig /flushdns】, 清理浏览器缓存。"
# 透明代理
fi
[ "$(nvram get ss_internet)" != "1" ] && nvram set ss_internet="1"
clash_get_clash_webs
# 下载clash_webs
if [ ! -f "/opt/app/clash/clash_webs/index.html" ] ; then
	if [ "$app_79" == "clash" ] || [ "$app_79" == "clash_1" ] ; then
		logger -t "【clash】" " 下载 clash 面板 : https://github.com/Dreamacro/clash-dashboard/tree/gh-pages"
		wgetcurl_checkmd5 /opt/app/clash/clash_webs.tgz "$hiboyfile/clash_webs2.tgz" "$hiboyfile2/clash_webs2.tgz" N
		[ "$app_79" != "clash_1" ] && nvram set app_79="clash_1" && app_79="clash_1"
	fi
	if [ "$app_79" == "yacd" ] || [ "$app_79" == "yacd_1" ] ; then
		logger -t "【clash】" "下载 yacd 面板 : https://github.com/MetaCubeX/Yacd-meta/tree/gh-pages"
		wgetcurl_checkmd5 /opt/app/clash/clash_webs.tgz "$hiboyfile/clash_webs.tgz" "$hiboyfile2/clash_webs.tgz" N
		[ "$app_79" != "yacd_1" ] && nvram set app_79="yacd_1" && app_79="yacd_1"
	fi
	if [ "$app_79" == "meta" ] || [ "$app_79" == "meta_1" ] ; then
		logger -t "【clash】" "下载 Meta 面板 : https://github.com/MetaCubeX/Razord-meta/tree/gh-pages"
		wgetcurl_checkmd5 /opt/app/clash/clash_webs.tgz "$hiboyfile/clash_webs3.tgz" "$hiboyfile2/clash_webs3.tgz" N
		[ "$app_79" != "meta_1" ] && nvram set app_79="meta_1" && app_79="meta_1"
	fi
	if [ "$app_79" == "xd" ] || [ "$app_79" == "xd_1" ] ; then
		logger -t "【clash】" "下载 xd 面板 : https://github.com/metacubex/metacubexd/tree/gh-pages"
		wgetcurl_checkmd5 /opt/app/clash/clash_webs.tgz "$hiboyfile/clash_webs4.tgz" "$hiboyfile2/clash_webs4.tgz" N
		[ "$app_79" != "xd_1" ] && nvram set app_79="xd_1" && app_79="xd_1"
	fi
	tar -xzvf /opt/app/clash/clash_webs.tgz -C /opt/app/clash ; cd /opt
	rm -f /opt/app/clash/clash_webs.tgz
	[ -f "/opt/app/clash/clash_webs/index.html" ] && logger -t "【clash】" "下载 clash_webs 完成"
fi

eval "$scriptfilepath keep &"

exit 0
}

ss_tproxy_set() {
ss_tproxy_auser=`nvram get ss_tproxy_auser`
if [ "$1" != "$ss_tproxy_auser" ] ; then
	logger -t "【clash】" "脚本 [Sh99_ss_tproxy.sh] 当前使用者: $auser_b ，跳过 $auser_a 的运行命令"
	logger -t "【clash】" "需要停用 $auser_b 后才能使用 $auser_a 运行 [Sh99_ss_tproxy.sh] 脚本"
	return
fi
lan_ipaddr=`nvram get lan_ipaddr`
ss_tproxy_mode_x=`nvram get app_110`
[ -z $ss_tproxy_mode_x ] && ss_tproxy_mode_x=0 && nvram set app_110=0
[ "$ss_tproxy_mode_x" = "0" ] && logger -t "【clash】" "【自动】设置 ss_tproxy 配置文件，配置导入中..."
[ "$ss_tproxy_mode_x" = "1" ] && logger -t "【clash】" "【手动】设置 ss_tproxy 配置文件，跳过配置导入" && return
 # /etc/storage/app_27.sh
[ "$clash_mode_x" = "1" ] && sstp_set mode='gfwlist'
[ "$clash_mode_x" = "2" ] && sstp_set mode='chnroute'
[ "$clash_mode_x" = "0" ] && sstp_set mode='global'
[ "$clash_mode_x" = "3" ] && sstp_set mode='chnlist'
[ "$ss_ip46" = "0" ] && { sstp_set ipv4='true' ; sstp_set ipv6='false' ; }
[ "$ss_ip46" = "1" ] && { sstp_set ipv4='false' ; sstp_set ipv6='true' ; }
[ "$ss_ip46" = "2" ] && { sstp_set ipv4='true' ; sstp_set ipv6='true' ; }
[ "$ss_ip46" = "0" ] && sstp_set tproxy='false' # true:TPROXY+TPROXY; false:REDIRECT+TPROXY
[ "$ss_ip46" != "0" ] && sstp_set tproxy='true'
sstp_set tcponly="$tcponly" # true:仅代理TCP流量; false:代理TCP和UDP流量
sstp_set selfonly='false'  # true:仅代理本机流量; false:代理本机及"内网"流量
nvram set app_112="$dns_start_dnsproxy"      #app_112 0:自动开启第三方 DNS 程序(dnsproxy) ; 1:跳过自动开启第三方 DNS 程序但是继续把DNS绑定到 8053 端口的程序
#nvram set ss_pdnsd_all="$dns_start_dnsproxy" # 0使用[本地DNS] + [GFW规则]查询DNS ; 1 使用 8053 端口查询全部 DNS
#nvram set app_113="$dns_start_dnsproxy"      #app_113 0:使用 8053 端口查询全部 DNS 时进行 China 域名加速 ; 1:不进行 China 域名加速
sstp_set uid_owner='0'          # 非 0 时进行用户ID匹配跳过代理本机流量
gid_owner="$(nvram get gid_owner)"
sstp_set gid_owner="$gid_owner" # 非 0 时进行组ID匹配跳过代理本机流量
## proxy
sstp_set proxy_all_svraddr="/opt/app/ss_tproxy/conf/proxy_all_svraddr.conf"
sstp_set proxy_svrport='1:65535'
sstp_set proxy_tcpport='7892'
sstp_set proxy_udpport='7892'
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
[ "$clash_mode_x" = "3" ] && sstp_set dns_direct='8.8.8.8' # 回国模式
[ "$clash_mode_x" = "3" ] && sstp_set dns_direct6='2001:4860:4860::8888' # 回国模式
[ "$clash_mode_x" = "3" ] && sstp_set dns_remote='223.5.5.5#53' # 回国模式
[ "$clash_mode_x" = "3" ] && sstp_set dns_remote6='240C::6666#53' # 回国模式
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
logger -t "【clash】" "【自动】设置 ss_tproxy 配置文件，完成配置导入"
}

wget_yml () {
[ "$(nvram get app_86)" = "wget_yml" ] && nvram set app_86=0
clash_wget_yml="$(echo $clash_wget_yml)"
[ -z "$clash_wget_yml" ] && logger -t "【clash】" "找不到 【订阅链接】，需要手动填写" && return
clash_path="$SVC_PATH"
i_app_get_cmd_file -name="clash" -cmd="yq" -cpath="/opt/bin/yq" -down1="$hiboyfile/yq" -down2="$hiboyfile2/yq"
SVC_PATH="$clash_path"
mkdir -p /tmp/clash
logger -t "【clash】" "服务器订阅：开始更新"
yml_tmp="/tmp/clash/app_20.sh"
rm -f $yml_tmp
if [ ! -z "$(echo "$clash_wget_yml" | grep '^/')" ] ; then
[ -f "$clash_wget_yml" ] && cp -f "$clash_wget_yml" "$yml_tmp"
[ ! -f "$clash_wget_yml" ] && logger -t "【clash】" "错误！！ $clash_wget_yml 文件不存在！"
else
if [ -z "$(echo "$clash_wget_yml" | grep 'http:\/\/')""$(echo "$clash_wget_yml" | grep 'https:\/\/')" ] ; then
	logger -t "【clash】" "$clash_wget_yml"
	logger -t "【clash】" "错误！！clash 服务器订阅文件下载地址不含http(s)://！请检查下载地址"
	return
fi
wgetcurl.sh $yml_tmp "$clash_wget_yml" "$clash_wget_yml" N
if [ ! -s $yml_tmp ] ; then
	rm -f $yml_tmp
	curl -L --user-agent "$user_agent" -o $yml_tmp "$clash_wget_yml"
fi
if [ ! -s $yml_tmp ] ; then
	rm -f $yml_tmp
	wget -T 5 -t 3 --user-agent "$user_agent" -O $yml_tmp "$clash_wget_yml"
fi
fi
if [ ! -s $yml_tmp ] ; then
	rm -f $yml_tmp
	logger -t "【clash】" "错误！！clash 服务器订阅文件获取失败！请检查地址"
	return
else
	if is_2_base64 "$(cat $yml_tmp)" ; then 
	# 需2次解码
	echo "$(echo -n "$(cat $yml_tmp)" | sed -e "s/_/\//g" | sed -e "s/-/\+/g" | sed 's/$/&====/g' | base64 -d)" > $yml_tmp
	fi
	dos2unix $yml_tmp
	sed -Ei s@\<\/textarea\>@@g $yml_tmp
	cp -f $yml_tmp /etc/storage/app_20.sh
	#yq w -i $app_20 allow-lan true
	#rm_temp
	logger -t "【clash】" "下载 clash 配置完成！"
	rm -f $yml_tmp
fi
if [ -z "$curltest" ] || [ "$app_120" == "2" ] ; then
nvram set clash_status=wget_yml
fi
logger -t "【clash】" "服务器订阅：更新完成"
logger -t "【clash】" "请按F5或刷新 web 页面刷新配置"
}

merge_dns_ip () {
mkdir -p /tmp/clash
dns_ip="/tmp/clash/dns_ip.txt"
cat > "$dns_ip" <<-\EEE
Rule:
- "IP-CIDR,8.8.8.8/32,Proxy"
- "IP-CIDR,8.8.4.4/32,Proxy"
- "IP-CIDR,208.67.222.222/32,Proxy"
- "IP-CIDR,208.67.220.220/32,Proxy"
EEE
chmod 755 "$dns_ip"
Proxy_txt="$(yq r $config_yml Rule | grep DOMAIN | grep instagram | awk -F ',' '{print $3}'| head -n1)"
rm_temp
[ -z "$Proxy_txt" ] && Proxy_txt="$(yq r $config_yml Rule | grep DOMAIN | grep twitter | awk -F ',' '{print $3}'| head -n1)"
rm_temp
[ -z "$Proxy_txt" ] && Proxy_txt="$(yq r $config_yml Rule | grep DOMAIN | grep telegram | awk -F ',' '{print $3}'| head -n1)"
rm_temp
[ -z "$Proxy_txt" ] && Proxy_txt="$(yq r $config_yml Rule | grep DOMAIN | grep gmail | awk -F ',' '{print $3}'| head -n1)"
rm_temp
[ ! -z "$Proxy_txt" ] && Proxy_txt="$(echo "$Proxy_txt" | sed -e 's/\\/\\\\/g')"
if [ ! -z "$Proxy_txt" ] ; then
logger -t "【clash】" "把 DNS 地址加入规则！ $Proxy_txt ：8.8.8.8,8.8.4.4,208.67.222.222,208.67.220.220"
sed -e "s/,Proxy/,$Proxy_txt/g" -i "$dns_ip"
sed -e "s/"'""'"$/"'"'"/g" -i "$dns_ip"
yq m -a -i $dns_ip $config_yml
rm_temp
cp -f $dns_ip $config_yml
rm -f $dns_ip
fi

}

rm_temp () {
rm -f /tmp/temp?????????
}

initconfig () {

app_20="/etc/storage/app_20.sh"
if [ ! -f "$app_20" ] || [ ! -s "$app_20" ] ; then
	cat > "$app_20" <<-\EEE
#如果您不知道如何操作，请参阅 https://github.com/Hackl0us/SS-Rule-Snippet/blob/master/LAZY_RULES/clash.yaml

EEE
	chmod 755 "$app_20"
fi

app_21="/etc/storage/app_21.sh"
if [ ! -f "$app_21" ] || [ ! -s "$app_21" ] ; then
	cat > "$app_21" <<-\EEE
dns:
  enable: true
  ipv6: false
  listen: 0.0.0.0:8053
  default-nameserver :
    - 8.8.8.8
  enhanced-mode: fake-ip
  # enhanced-mode: redir-host # 或 fake-ip
  # # fake-ip-range: 198.18.0.1/16 # 如果你不知道这个参数的作用，请勿修改
  # # 实验性功能 hosts, 支持通配符 (例如 *.clash.dev 甚至 *.foo.*.example.com)
  # # 静态的域名 比 通配域名 具有更高的优先级 (foo.example.com 优先于 *.example.com)
  # # 注意: hosts 在 fake-ip 模式下不生效
  # hosts:
  #   '*.clash.dev': 127.0.0.1
  #   'alpha.clash.dev': '::1'
  use-hosts: true # 查询 hosts
  # 配置不使用fake-ip的域名
  fake-ip-filter:
    - '+.*'
  #   - '*.lan'
  #   - localhost.ptlogin2.qq.com

  nameserver:
    - 223.5.5.5
    - 114.114.114.114
    - 119.29.29.29
    # - tls://dns.rubyfish.cn:853
    # - https://dns.rubyfish.cn/dns-query
    # - https://dns.alidns.com/dns-query

  fallback:
    # 与 nameserver 内的服务器列表同时发起请求，当规则符合 GEOIP 在 CN 以外时，fallback 列表内的域名服务器生效。
    - https://dns.google/dns-query
    - https://1.0.0.1/dns-query
    - tcp://8.8.8.8:53
    - tcp://8.8.4.4:53
    - tcp://208.67.222.222:443
    - tcp://208.67.220.220:443
    # - tls://1.0.0.1:853
    # - tls://dns.google:853
    # - tls://dns.google
    # - https://dns.rubyfish.cn/dns-query
    # - https://cloudflare-dns.com/dns-query

  fallback-filter:
    geoip: true
    geoip-code: CN
    ipcidr:
      - 240.0.0.0/4
    domain:
      - '+.google.com'
      - '+.googleapis.com'
      - '+.youtube.com'
      - '+.appspot.com'
      - '+.telegram.com'
      - '+.facebook.com'
      - '+.twitter.com'
      - '+.blogger.com'
      - '+.gmail.com'
      - '+.gvt1.com'
experimental:
  quic-go-disable-gso: true
  quic-go-disable-ecn: true
  dialer-ip4p-convert: false
EEE
	chmod 755 "$app_21"
fi


if [ -z "$(cat $app_21 | grep sniffer)" ] ; then
	cat >> "$app_21" <<-\EEE
sniffer:
  enable: true
  override-destination: true
  sniff:
    http: { ports: [80, 8080] }
    tls: { ports: [443, 8443] }
  skip-domain:
    #Apple
    - 'courier.push.apple.com'
    #mi
    - 'Mijia Cloud'

EEE
	chmod 755 "$app_21"
fi


app_33="/etc/storage/app_33.sh"
if [ ! -f "$app_33" ] || [ ! -s "$app_33" ] ; then
	cat > "$app_33" <<-\EEE
#!/bin/bash
if [ "$1" == "config1" ] ; then
# 更新修改 ① 启动 clash 的配置代理节点
config_yml="/opt/app/clash/config/config.yaml"
# 先删除旧配置
echo '- command: delete
  path: proxies(name==V2Ray本地代理)
- command: delete
  path: proxy-groups[*].proxies.(.==V2Ray本地代理)
- command: delete
  path: proxies(name==SS本地代理)
- command: delete
  path: proxy-groups[*].proxies.(.==SS本地代理)
' | yq w -i -s - $config_yml

# 再添加本地代理节点，若不支持udp需禁用
echo '- command: update 
  path: proxies[+]
  value:
    name: V2Ray本地代理
    type: socks5
    server: 127.0.0.1
    port: 1088
    # username: username
    # password: password
    # tls: true
    # skip-cert-verify: true
    udp: true
- command: update 
  path: proxy-groups[*].proxies[+]
  value:
    V2Ray本地代理
- command: update 
  path: proxies[+]
  value:
    name: SS本地代理
    type: socks5
    server: 127.0.0.1
    port: 1081
    # username: username
    # password: password
    # tls: true
    # skip-cert-verify: true
    udp: true
- command: update 
  path: proxy-groups[*].proxies[+]
  value:
    SS本地代理
' | yq w -i -s - $config_yml
fi
EEE
	chmod 755 "$app_33"
fi

}

initconfig

update_app () {
mkdir -p /opt/app/clash
if [ "$1" = "update_asp" ] ; then
	rm -rf /opt/app/clash/Advanced_Extensions_clash.asp
fi
if [ "$1" = "del" ] ; then
	rm -rf /opt/app/clash/Advanced_Extensions_clash.asp /opt/bin/clash /opt/opt_backup/bin/clash /opt/app/clash/config/Country.mmdb /opt/app/clash/config/Country_mmdb /opt/app/clash/clash_webs
fi

initconfig

# 加载程序配置页面
if [ ! -f "/opt/app/clash/Advanced_Extensions_clash.asp" ] || [ ! -s "/opt/app/clash/Advanced_Extensions_clash.asp" ] ; then
	wgetcurl.sh /opt/app/clash/Advanced_Extensions_clash.asp "$hiboyfile/Advanced_Extensions_clashasp" "$hiboyfile2/Advanced_Extensions_clashasp"
fi
umount /www/Advanced_Extensions_app18.asp
mount --bind /opt/app/clash/Advanced_Extensions_clash.asp /www/Advanced_Extensions_app18.asp
# 更新程序启动脚本

[ "$1" = "del" ] && /etc/storage/www_sh/clash del &
}

update_geoip () {

[ "$(nvram get app_86)" = "clash_wget_geoip" ] && nvram set app_86=0
logger -t "【clash】" "更新下载 GeoIP2国家数据库 数据库文件"
/etc/storage/script/Sh01_mountopt.sh start
mkdir -p /opt/app/clash/config
rm -f /opt/app/clash/config/Country_mmdb
if [ ! -f /opt/app/clash/config/Country_mmdb ] ; then
wgetcurl_checkmd5 /opt/app/clash/config/Country.mmdb "https://testingcf.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@release/country.mmdb" "$hiboyfile/Country.mmdb" N
[ -s /opt/app/clash/config/Country.mmdb ] && touch /opt/app/clash/config/Country_mmdb
fi
reload_api
}

update_yml () {
secret="$(yq r /etc/storage/app_20.sh secret)"
rm_temp
if [ "$secret" != "$clash_secret" ] ; then
yq w -i /etc/storage/app_20.sh secret "$clash_secret"
rm_temp
fi
mkdir -p /opt/app/clash/config
mkdir -p /etc/storage/clash/config
[ -f /opt/app/clash/config/cache.db ] && [ ! -f /etc/storage/clash/config/cache.db ] && cp -f /opt/app/clash/config/cache.db /etc/storage/clash/config/cache.db
touch /etc/storage/clash/config/cache.db
ln -sf /etc/storage/clash/config/cache.db /opt/app/clash/config/cache.db
if [ "$app_default_config" = "1" ] ; then
logger -t "【clash】" "不改写配置，直接使用原始配置启动！（有可能端口不匹配导致功能失效）"
logger -t "【clash】" "请手动修改配置， HTTP 代理端口：7890"
logger -t "【clash】" "请手动修改配置， SOCKS5 代理端口：7891"
logger -t "【clash】" "请手动修改配置，透明代理端口：7892"
cp -f /etc/storage/app_20.sh /opt/app/clash/config/config.yaml
else
 # 改写配置适配脚本
logger -t "【clash】" "初始化 clash dns 配置"
mkdir -p /tmp/clash
config_dns_yml="/tmp/clash/dns.yml"
rm_temp
cp -f /etc/storage/app_21.sh $config_dns_yml
sed -Ei '/^$/d' $config_dns_yml
# 更新 yq
[ -z "$(yq -V 2>&1 | grep 3\.4\.1)" ] && rm -rf /opt/bin/yq /opt/opt_backup/bin/yq
wgetcurl_file /opt/bin/yq "$hiboyfile/yq" "$hiboyfile2/yq"
if [ ! -z "$(yq -V 2>&1 | grep 3\.4\.1)" ] ; then
echo '- command: delete
  path: dns.fallback(.==https://dns.google/dns-query)
- command: delete
  path: dns.fallback(.==https://1.1.1.1/dns-query)
- command: delete
  path: dns.fallback(.==https://1.0.0.1/dns-query)
- command: update 
  path: dns.fallback[+]
  value: https://dns.google/dns-query
- command: update 
  path: dns.fallback[+]
  value: https://1.0.0.1/dns-query
' | yq w -i -s - $config_dns_yml
config_dns_yml_txt=`yq r $config_dns_yml --stripComments`
echo "$config_dns_yml_txt"  >  $config_dns_yml
sed -Ei '/^$/d' $config_dns_yml
if [ ! -s $config_dns_yml ] ; then
cp -f /etc/storage/app_21.sh $config_dns_yml
sed -Ei '/^$/d' $config_dns_yml
fi
fi
if [ "$ss_ip46" = "0" ] || [ "$ss_ip46" = "2" ] ; then
yq w -i $config_dns_yml dns.ipv6 false
else
yq w -i $config_dns_yml dns.ipv6 true
fi
if [ "$chinadns_ng_enable" = "3" ] || [ "$clash_follow" == 0 ] ; then
logger -t "【clash】" "变更 clash dns 端口 listen 0.0.0.0:8054 自动开启第三方 DNS 程序"
yq w -i $config_dns_yml dns.listen 0.0.0.0:8054
rm_temp
dns_start_dnsproxy='0' # 0:自动开启第三方 DNS 程序(dnsproxy) ;
else
logger -t "【clash】" "变更 clash dns 端口 listen 0.0.0.0:8053 跳过自动开启第三方 DNS 程序但是继续把DNS绑定到 8053 端口的程序"
yq w -i $config_dns_yml dns.listen 0.0.0.0:8053
rm_temp
dns_start_dnsproxy='1' # 1:跳过自动开启第三方 DNS 程序但是继续把DNS绑定到 8053 端口的程序
fi
if [ ! -s $config_dns_yml ] ; then
logger -t "【clash】" "yq 初始化 clash dns 配置错误！请检查配置！"
logger -t "【clash】" "恢复原始 clash dns 配置！"
rm -f /etc/storage/app_21.sh
initconfig
cp -f /etc/storage/app_21.sh $config_dns_yml

fi
logger -t "【clash】" "初始化 clash 配置"
config_yml="/opt/app/clash/config/config.yaml"
rm_temp
cp -f /etc/storage/app_20.sh $config_yml
rm -f /opt/app/clash/config/config.yml
ln -sf $config_yml /opt/app/clash/config/config.yml
if [ "$clash_input" == "1" ] ; then
logger -t "【clash】" "配置 clash 添加本地代理节点"
[ ! -z "$(yq -V 2>&1 | grep 3\.4\.1)" ] && /etc/storage/app_33.sh "config1"
if [ ! -s $config_yml ] ; then
logger -t "【clash】" "yq 添加本地代理节点 配置错误！请检查配置！"
cp -f /etc/storage/app_20.sh $config_yml
fi
fi
sed -Ei '/^$/d' $config_yml
yq w -i $config_yml allow-lan true
rm_temp
logger -t "【clash】" "允许局域网的连接"
if [ "$clash_http_enable" != "0" ] ; then
yq w -i $config_yml port 7890
rm_temp
logger -t "【clash】" "HTTP 代理端口：7890"
else
yq d -i $config_yml port
rm_temp
fi
if [ "$clash_socks_enable" != "0" ] ; then
yq w -i $config_yml socks-port 7891
rm_temp
logger -t "【clash】" "SOCKS5 代理端口：7891"
else
yq d -i $config_yml socks-port
rm_temp
fi
if [ "$clash_mixed" != "0" ] ; then
yq w -i $config_yml mixed-port 7893
rm_temp
logger -t "【clash】" "SOCKS5 代理端口：7891"
else
yq d -i $config_yml mixed-port
rm_temp
fi
if [ "$clash_follow" != "0" ] ; then
if [ "$ss_ip46" = "0" ] ; then
yq d -i $config_yml tproxy-port
yq w -i $config_yml redir-port 7892
rm_temp
logger -t "【clash】" "redir 代理端口：7892"
else
yq d -i $config_yml redir-port
yq w -i $config_yml tproxy-port 7892
rm_temp
logger -t "【clash】" "tproxy 代理端口：7892"
fi
else
yq d -i $config_yml redir-port
yq d -i $config_yml tproxy-port
rm_temp
fi
logger -t "【clash】" "删除 Clash 配置文件中原有的 DNS 或其他配置"
yq d -i $config_yml dns
rm_temp
yq d -i $config_yml sniffer
rm_temp
[ -s $config_dns_yml ] && eval "$(yq r $config_dns_yml --stripComments | grep -v "^ " | tr -d ":" | awk '{print "yq d -i $config_yml "$1;}')"
logger -t "【clash】" "将 DNS 或其他配置 /tmp/clash/dns.yml 以覆盖的方式与 $config_yml 合并"
cat $config_dns_yml >> $config_yml
#merge_dns_ip
yq w -i $config_yml external-controller $clash_ui
rm_temp
yq w -i $config_yml external-ui "/opt/app/clash/clash_webs/"
rm_temp
# 转换新参数兼容 1.0 或更高版本
[ ! -z "$(cat $config_yml | grep "Proxy:" )" ] && sed -e 's@Proxy:@proxies:@g' -i $config_yml && logger -t "【clash】" "转换新参数: Proxy --> proxies"
[ ! -z "$(cat $config_yml | grep "Proxy Group:" )" ] && sed -e 's@Proxy Group:@proxy-groups:@g' -i $config_yml && logger -t "【clash】" "转换新参数: Proxy Group --> proxy-groups"
[ ! -z "$(cat $config_yml | grep "Rule:" )" ] && sed -e 's@Rule:@rules:@g' -i $config_yml && logger -t "【clash】" "转换新参数: Rule --> rules"
[ ! -z "$(cat $config_yml | grep "proxy-provider:" )" ] && sed -e 's@proxy-provider:@proxy-providers:@g' -i $config_yml && logger -t "【clash】" "转换新参数: proxy-provider --> proxy-providers"
# 设置日志输出 silent / info / warning / error / debug(默认[error]，避免日志内容过多导致卡机）。
logger -t "【clash】" "设置日志输出: $log_level"
yq w -i $config_yml log-level $log_level
if [ ! -s $config_yml ] ; then
logger -t "【clash】" "yq 初始化 clash 配置错误！请检查配置！"
logger -t "【clash】" "尝试直接使用原始配置启动！"
cp -f /etc/storage/app_20.sh $config_yml
else
logger -t "【clash】" "初始化 clash 配置完成！实际运行配置：/opt/app/clash/config/config.yaml"

fi
fi
}

reload_api () {
if [ -z "$curltest" ] || [ "$app_120" == "2" ] ; then
return
fi
[ -z "`pidof clash`" ] && return
#api热重载
reload_yml "check"
update_yml
reload_yml "reload"
Sh99_ss_tproxy.sh auser_check "Sh10_clash.sh"
ss_tproxy_set "Sh10_clash.sh"
Sh99_ss_tproxy.sh x_resolve_svraddr "Sh10_clash.sh"
}

reload_yml () {
[ "$(nvram get app_86)" = "clash_save_yml" ] && nvram set app_86=0
if [ -z "$curltest" ] || [ "$app_120" == "2" ] ; then
return
fi
[ -z "`pidof clash`" ] && return

if [ "$1" == "check" ] ; then
mkdir -p /etc/storage/clash
secret="$(yq r /opt/app/clash/config/config.yaml secret)"
rm_temp
[ -z "$secret" ] && secret="$clash_secret"
api_port="$(yq r /opt/app/clash/config/config.yaml external-controller)"
rm_temp
[ -z "$api_port" ] && api_port="$clash_ui"
fi
if [ "$1" == "reload" ] ; then
logger -t "【clash】" "api热重载配置"
curl -X PUT -w "%{http_code}" -H "Authorization: Bearer $secret" -H "Content-Type: application/json" -d '{"path": "/opt/app/clash/config/config.yaml"}' 'http://'"$api_port"'/configs?force=true'
logger -t "【clash】" "api热重载配置，完成！"
fi

}

clash_get_releases(){
app_78="$(nvram get app_78)"
link_get=""
if [ "$app_78" == "premium" ] ; then
link_get="clash-premium"
nvram set app_78="premium_1" ; app_78="premium_1"
logger -t "【clash】" "更换 premium (闭源版) 主程序: https://github.com/Dreamacro/clash/releases/tag/premium"
fi
if [ "$app_78" == "meta" ] ; then
link_get="clash-meta"
nvram set app_78="meta_1" ; app_78="meta_1"
logger -t "【clash】" "更换 mihomo.Meta 主程序: https://github.com/MetaCubeX/mihomo"
fi
if [ ! -z "$link_get" ] ; then
SVC_PATH="$(which clash)"
[ ! -s "$SVC_PATH" ] && SVC_PATH="/opt/bin/clash"
logger -t "【clash】" "自动下载 clash 主程序"
wgetcurl_file "$SVC_PATH""_file" "$hiboyfile/""$link_get" "$hiboyfile2/""$link_get"
sed -Ei '/【clash】|^$/d' /tmp/script/_opt_script_check
killall clash
rm -rf "$SVC_PATH"
mv -f "$SVC_PATH""_file" "$SVC_PATH"
fi
}

clash_get_clash_webs(){
app_79="$(nvram get app_79)"
link_get=""
if [ "$app_79" == "yacd" ] ; then
link_get="clash_webs.tgz"
nvram set app_79="yacd_1" ; app_79="yacd_1"
logger -t "【clash】" "更换 yacd 面板 : https://github.com/MetaCubeX/Yacd-meta/tree/gh-pages"
fi
if [ "$app_79" == "clash" ] ; then
link_get="clash_webs2.tgz"
nvram set app_79="clash_1" ; app_79="clash_1"
logger -t "【clash】" " 更换 clash 面板 : https://github.com/Dreamacro/clash-dashboard/tree/gh-pages"
fi
if [ "$app_79" == "meta" ] ; then
link_get="clash_webs3.tgz"
nvram set app_79="meta_1" ; app_79="meta_1"
logger -t "【clash】" " 更换 Meta 面板 : https://github.com/MetaCubeX/Razord-meta/tree/gh-pages"
fi
if [ "$app_79" == "xd" ] ; then
link_get="clash_webs4.tgz"
nvram set app_79="xd_1" ; app_79="xd_1"
logger -t "【clash】" " 更换 xd 面板 : https://github.com/metacubex/metacubexd/tree/gh-pages"
fi
if [ ! -z "$link_get" ] ; then
# 下载clash_webs
rm -rf /opt/app/clash/clash_webs_tmp
mkdir -p /opt/app/clash/clash_webs_tmp
wgetcurl_checkmd5 /opt/app/clash/clash_webs_tmp/clash_webs.tgz "$hiboyfile/""$link_get" "$hiboyfile2/""$link_get" N
tar -xzvf /opt/app/clash/clash_webs_tmp/clash_webs.tgz -C /opt/app/clash/clash_webs_tmp ; cd /opt
if [ -f "/opt/app/clash/clash_webs_tmp/clash_webs/index.html" ] ; then
rm -rf /opt/app/clash/clash_webs_tmp/clash_webs
logger -t "【clash】" "下载 clash_webs 完成"
logger -t "【clash】" "需按 Ctrl + F5 强制刷新 web 面板"
rm -rf /opt/app/clash/clash_webs
tar -xzvf /opt/app/clash/clash_webs_tmp/clash_webs.tgz -C /opt/app/clash ; cd /opt
fi
rm -rf /opt/app/clash/clash_webs_tmp
fi
if [ ! -z "$(cat /opt/app/clash/Advanced_Extensions_clash.asp | grep 9090)" ] ; then
sed -e 's@var port = .*@var port = document.querySelector("#app_94").value.split(":")[1];@' -i /opt/app/clash/Advanced_Extensions_clash.asp
sed -e 's@0.0.0.0:9090@@' -i /opt/app/clash/Advanced_Extensions_clash.asp
fi
}

urlencode() {
	# urlencode <string>
	out=""
	read S
	for i in $(seq 0 $(($(echo -n "$S" |awk -F "" '{print NF}') - 1)) )
	do
		c="${S:$i:1}"
		case "$c" in
			[-_.~a-zA-Z0-9]) out="$out$c" ;;
			*) out="$out`printf '%%%02X' "'$c"`" ;;
		esac
	done
	echo $out
}

enc() {
	echo -n "$1" | urlencode
}

case $ACTION in
start)
	clash_close
	clash_check
	;;
check)
	clash_check
	;;
stop)
	clash_close
	;;
updateapp18)
	clash_restart o
	[ "$clash_enable" = "1" ] && nvram set clash_status="updateclash" && logger -t "【clash】" "重启" && clash_restart
	[ "$clash_enable" != "1" ] && nvram set clash_v="" && logger -t "【clash】" "更新" && update_app del
	;;
update_app)
	update_app
	;;
update_asp)
	update_app update_asp
	;;
keep)
	#clash_check
	clash_keep
	;;
wget_yml)
	nvram set app_86="wget_yml"
	wget_yml
	clash_check
	;;
reload_yml)
	reload_yml "check"
	reload_yml $2
	;;
*)
	clash_check
	;;
esac

