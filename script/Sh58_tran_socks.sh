#!/bin/bash
#copyright by hiboy
source /etc/storage/script/init.sh
transocks_enable=`nvram get app_27`
[ -z $transocks_enable ] && transocks_enable=0 && nvram set app_27=0
ipt2socks_enable=`nvram get app_104`
[ -z $ipt2socks_enable ] && ipt2socks_enable=0 && nvram set app_104=0
kumasocks_enable=`nvram get app_116`
[ -z $kumasocks_enable ] && kumasocks_enable=0 && nvram set app_116=0
app_114=`nvram get app_114` #0:代理本机流量; 1:跳过代理本机流量
[ -z $app_114 ] && app_114=0 && nvram set app_114=0

if [ "$ipt2socks_enable" == "1" ] ; then
#logger -t "【transocks】" "跳过启用，已经启用 ipt2socks"
[ "$transocks_enable" == "0" ] && logger -t "【transocks】" "注意！！！需要关闭 transocks 后才能关闭 ipt2socks"
Sh39_ipt2socks.sh $ACTION
transocks_status=""
exit
fi

transocks_mode_x=`nvram get app_28`
[ -z $transocks_mode_x ] && transocks_mode_x=0 && nvram set app_28=0
transocks_proxy_mode=`nvram get app_29`
[ -z $transocks_proxy_mode ] && transocks_proxy_mode="0" && nvram set app_29="0"
if [ "$kumasocks_enable" == "1" ] ; then
tran_c_socks="kumasocks"
[ "$transocks_proxy_mode" != 0 ] && transocks_proxy_mode="0" && nvram set app_29="0"
else
tran_c_socks="transocks"
fi
[ "$transocks_proxy_mode" == 0 ] && transocks_proxy_mode_x="socks5"
[ "$transocks_proxy_mode" == 1 ] && transocks_proxy_mode_x="http"
nvram set transocks_proxy_mode_x="$transocks_proxy_mode_x"
transocks_listen_address=`nvram get app_30`
transocks_listen_port=`nvram get app_31`
transocks_server="$(nvram get app_32)"
LAN_AC_IP=`nvram get LAN_AC_IP`
[ -z $LAN_AC_IP ] && LAN_AC_IP=0 && nvram set LAN_AC_IP=$LAN_AC_IP
ss_DNS_Redirect=`nvram get ss_DNS_Redirect`
ss_DNS_Redirect_IP=`nvram get ss_DNS_Redirect_IP`
[ -z "$ss_DNS_Redirect_IP" ] && ss_DNS_Redirect_IP=$lan_ipaddr
if [ "$transocks_enable" != "0" ] ; then
ss_tproxy_auser=`nvram get ss_tproxy_auser`
if [ "Sh58_tran_socks.sh" != "$ss_tproxy_auser" ] && [ "" != "$ss_tproxy_auser" ] ; then
	logger -t "【$tran_c_socks】" "错误！！！由于已启用 $ss_tproxy_auser 透明代理，停止启用 transocks 透明代理！"
	transocks_enable=0 && nvram set app_27=0
fi
/etc/storage/script/sh_ezscript.sh 3 & #更新按钮状态
cmd_log_enable=`nvram get cmd_log_enable`
cmd_name="$tran_c_socks"
cmd_log=""
if [ "$cmd_log_enable" = "1" ] || [ "$ipt2socks_renum" -gt "0" ] ; then
	cmd_log="$cmd_log2"
fi
fi

if [ ! -z "$(echo $scriptfilepath | grep -v "/tmp/script/" | grep tran_socks)" ] && [ ! -s /tmp/script/_app10 ] ; then
	mkdir -p /tmp/script
	{ echo '#!/bin/bash' ; echo $scriptfilepath '"$@"' '&' ; } > /tmp/script/_app10
	chmod 777 /tmp/script/_app10
fi

transocks_restart () {
i_app_restart "$@" -name="transocks"
}

transocks_get_status () {

B_restart="$transocks_enable$transocks_mode_x$transocks_server$transocks_listen_address$transocks_listen_port$transocks_proxy_mode$app_114$(cat /etc/storage/app_9.sh | grep -v '^#' | grep -v '^$')"

i_app_get_status -name="transocks" -valb="$B_restart"
}

transocks_check () {

transocks_get_status
if [ "$transocks_enable" = "1" ] ; then
	[ ! -z "$transocks_server" ] || logger -t "【$tran_c_socks】" "远端服务器IP地址:未填写"
	[ $transocks_listen_address ] || logger -t "【$tran_c_socks】" "透明重定向的代理服务器IP地址:未填写"
	[ $transocks_listen_port ] || logger -t "【$tran_c_socks】" "透明重定向的代理服务器端口:未填写"
	[ ! -z "$transocks_server" ] && [ $transocks_listen_address ] && [ $transocks_listen_port ] \
	|| { logger -t "【$tran_c_socks】" "错误！！！请正确填写。"; needed_restart=1; transocks_enable=0; }
fi
if [ "$transocks_enable" != "1" ] && [ "$needed_restart" = "1" ] ; then
	[ ! -z "`pidof transocks`" ] && logger -t "【$tran_c_socks】" "停止 transocks" && transocks_close
	[ ! -z "`pidof kumasocks`" ] && logger -t "【$tran_c_socks】" "停止 kumasocks" && transocks_close
	{ kill_ps "$scriptname" exit0; exit 0; }
fi
if [ "$transocks_enable" = "1" ] ; then
	if [ "$needed_restart" = "1" ] ; then
		transocks_close
		transocks_start
	else
		[ -z "`pidof $tran_c_socks`" ] && transocks_restart
	fi
fi
}

transocks_keep () {
i_app_keep -name="transocks" -pidof="$tran_c_socks" &
}

transocks_close () {
kill_ps "$scriptname keep"
sed -Ei '/【transocks】|【ipt2socks】|^$/d' /tmp/script/_opt_script_check
Sh99_ss_tproxy.sh off_stop "Sh58_tran_socks.sh"
killall transocks ipt2socks kumasocks
/etc/storage/script/sh_ezscript.sh 3 & #更新按钮状态
kill_ps "/tmp/script/_app10"
kill_ps "_tran_socks.sh"
kill_ps "/tmp/script/_app20"
kill_ps "_ipt2socks.sh"
kill_ps "$scriptname"
}

transocks_start () {

check_webui_yes
if [ "$kumasocks_enable" == "1" ] ; then
tran_c_socks="kumasocks"
else
tran_c_socks="transocks"
fi
i_app_get_cmd_file -name="transocks" -cmd="$tran_c_socks" -cpath="/opt/bin/$tran_c_socks" -down1="$hiboyfile/$tran_c_socks" -down2="$hiboyfile2/$tran_c_socks"
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
if [ "$app_114" = "0" ] ; then
	[ "$su_x" != "1" ] && logger -t "【$tran_c_socks】" "缺少 su 命令"
	[ "$NUM" -ge "3" ] || logger -t "【$tran_c_socks】" "缺少 iptables -m owner 模块"
	if [ "$NUM" -ge "3" ] && [ "$su_x" = "1" ] ; then
		echo "$app_114"
	else
		app_114=1
		nvram set app_114=1
	fi
fi
[ "$app_114" = "0" ] && logger -t "【$tran_c_socks】" "启动路由自身流量走透明代理"
[ "$app_114" = "1" ] && logger -t "【$tran_c_socks】" "停止路由自身流量走透明代理"
transocks_v=$($tran_c_socks -h 2>&1  | grep "$tran_c_socks"_ver | sed -n '1p')
nvram set transocks_v="$transocks_v"
logger -t "【$tran_c_socks】" "运行 $tran_c_socks"

#运行脚本启动/opt/bin/transocks
/etc/storage/app_9.sh
cd $(dirname `which $tran_c_socks`)
killall $tran_c_socks
if [ "$kumasocks_enable" == "1" ] ; then
su_cmd2="kumasocks -c /tmp/kumasocks.toml"
else
su_cmd2="transocks -f /tmp/transocks.toml"
fi
eval "$su_cmd" '"cmd_name='"$tran_c_socks"' && '"$su_cmd2"' $cmd_log"' &

sleep 2
i_app_keep -t -name="transocks" -pidof="$tran_c_socks"
Sh99_ss_tproxy.sh auser_check "Sh58_tran_socks.sh"
ss_tproxy_set "Sh58_tran_socks.sh"
Sh99_ss_tproxy.sh on_start "Sh58_tran_socks.sh"

#transocks_get_status
eval "$scriptfilepath keep &"
exit 0
}

ss_tproxy_set() {
ss_tproxy_auser=`nvram get ss_tproxy_auser`
if [ "$1" != "$ss_tproxy_auser" ] ; then
	logger -t "【$tran_c_socks】" "脚本 [Sh99_ss_tproxy.sh] 当前使用者: $auser_b ，跳过 $auser_a 的运行命令"
	logger -t "【$tran_c_socks】" "需要停用 $auser_b 后才能使用 $auser_a 运行 [Sh99_ss_tproxy.sh] 脚本"
	return
fi
lan_ipaddr=`nvram get lan_ipaddr`
ss_tproxy_mode_x=`nvram get app_110`
[ -z $ss_tproxy_mode_x ] && ss_tproxy_mode_x=0 && nvram set app_110=0
[ "$ss_tproxy_mode_x" = "0" ] && logger -t "【$tran_c_socks】" "【自动】设置 ss_tproxy 配置文件，配置导入中..."
[ "$ss_tproxy_mode_x" = "1" ] && logger -t "【$tran_c_socks】" "【手动】设置 ss_tproxy 配置文件，跳过配置导入" && return
 # /etc/storage/app_27.sh
[ "$transocks_mode_x" == "0" ] && sstp_set mode='chnroute'
[ "$transocks_mode_x" == "1" ] && sstp_set mode='gfwlist'
[ "$transocks_mode_x" == "2" ] && sstp_set mode='global'
[ "$transocks_mode_x" == "3" ] && sstp_set mode='chnlist'
sstp_set ipv4='true' ; sstp_set ipv6='false' ;
 # sstp_set ipv4='false' ; sstp_set ipv6='true' ;
 # sstp_set ipv4='true' ; sstp_set ipv6='true' ;
sstp_set tproxy='false' # true:TPROXY+TPROXY; false:REDIRECT+TPROXY
sstp_set tcponly='true' # true:仅代理TCP流量; false:代理TCP和UDP流量
sstp_set selfonly='false'  # true:仅代理本机流量; false:代理本机及"内网"流量
nvram set app_112="0"      #app_112 0:自动开启第三方 DNS 程序(dnsproxy) ; 1:跳过自动开启第三方 DNS 程序但是继续把DNS绑定到 8053 端口的程序
#nvram set app_113="0"      #app_113 0:使用 8053 端口查询全部 DNS 时进行 China 域名加速 ; 1:不进行 China 域名加速
sstp_set uid_owner='0' # 非 0 时进行用户ID匹配跳过代理本机流量
gid_owner="$(nvram get gid_owner)"
sstp_set gid_owner="$gid_owner" # 非 0 时进行组ID匹配跳过代理本机流量
## proxy
sstp_set proxy_all_svraddr="/opt/app/ss_tproxy/conf/proxy_all_svraddr.conf"
sstp_set proxy_svrport='1:65535'
sstp_set proxy_tcpport='1098'
sstp_set proxy_udpport='1098'
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
# clash
#grep '^  server: ' /etc/storage/app_20.sh | tr -d ' ' | sed -e 's/server://g' | sed -e 's/"\|'"'"'\| //g' | grep -v 8.8.8.8 | grep -v google.com | grep -v 114.114.114.114 | grep -v 119.29.29.29 | grep -v 223.5.5.5 >> /opt/app/ss_tproxy/conf/proxy_all_svraddr.conf
#cat /etc/storage/app_20.sh | tr -d ' ' | grep -E -o \"server\":\"\[\^\"\]+ | sed -e 's/server\|://g' | sed -e 's/"\|'"'"'\| //g' | grep -v 8.8.8.8 | grep -v google.com | grep -v 114.114.114.114 | grep -v 119.29.29.29 | grep -v 223.5.5.5 >> /opt/app/ss_tproxy/conf/proxy_all_svraddr.conf
kcptun_server=`nvram get kcptun_server`
echo "$kcptun_server" >> /opt/app/ss_tproxy/conf/proxy_all_svraddr.conf
# transocks ipt2socks 
echo "$transocks_server" | sed -e "s@ @\n@g" >> /opt/app/ss_tproxy/conf/proxy_all_svraddr.conf

# 链接配置文件
rm -f /opt/app/ss_tproxy/wanlist.ext
rm -f /opt/app/ss_tproxy/lanlist.ext
ln -sf /etc/storage/shadowsocks_ss_spec_wan.sh /opt/app/ss_tproxy/wanlist.ext
ln -sf /etc/storage/shadowsocks_ss_spec_lan.sh /opt/app/ss_tproxy/lanlist.ext
[ ! -s /opt/app/ss_tproxy/wanlist.ext ] && cp -f /etc/storage/shadowsocks_ss_spec_wan.sh /opt/app/ss_tproxy/wanlist.ext
[ ! -s /opt/app/ss_tproxy/lanlist.ext ] && cp -f /etc/storage/shadowsocks_ss_spec_lan.sh /opt/app/ss_tproxy/lanlist.ext
logger -t "【$tran_c_socks】" "【自动】设置 ss_tproxy 配置文件，完成配置导入"
}

initconfig () {
[ -z "$(cat /etc/storage/app_9.sh | grep '0\.0\.0\.0:1098')" ] && rm -f /etc/storage/app_9.sh
[ -z "$(cat /etc/storage/app_9.sh | grep 'kumasocks')" ] && rm -f /etc/storage/app_9.sh
	if [ ! -f "/etc/storage/app_9.sh" ] || [ ! -s "/etc/storage/app_9.sh" ] ; then
cat > "/etc/storage/app_9.sh" <<-\VVR
#!/bin/bash
lan_ipaddr=`nvram get lan_ipaddr`
transocks_listen_address=`nvram get app_30`
transocks_listen_port=`nvram get app_31`
transocks_proxy_mode_x=`nvram get transocks_proxy_mode_x`
# transocks 配置
cat > "/tmp/transocks.toml" <<-TTR
# listening address of transocks.
listen = "0.0.0.0:1098"
proxy_url = "$transocks_proxy_mode_x://$transocks_listen_address:$transocks_listen_port"
[log]
filename = "/tmp/syslog.log"
level = "error"               # critical", error, warning, info, debug
format = "plain"              # plain, logfmt, json

TTR
# kumasocks 配置
cat > "/tmp/kumasocks.toml" <<-TTR
# listening address of transocks.
listen-addr = "0.0.0.0:1098"
proxy-addr = "socks5://$transocks_listen_address:$transocks_listen_port"
io-copy-hack = false

TTR

VVR
	fi


}

initconfig

update_app () {
mkdir -p /opt/app/transocks
if [ "$1" = "update_asp" ] ; then
	rm -rf /opt/app/transocks/Advanced_Extensions_transocks.asp
fi
if [ "$1" = "del" ] ; then
	rm -rf /opt/app/transocks/Advanced_Extensions_transocks.asp
	[ -f /opt/bin/transocks ] && rm -f /opt/bin/transocks /opt/opt_backup/bin/transocks /opt/bin/kumasocks /opt/opt_backup/bin/kumasocks
fi

initconfig

# 加载程序配置页面
if [ ! -f "/opt/app/transocks/Advanced_Extensions_transocks.asp" ] || [ ! -s "/opt/app/transocks/Advanced_Extensions_transocks.asp" ] ; then
	wgetcurl.sh /opt/app/transocks/Advanced_Extensions_transocks.asp "$hiboyfile/Advanced_Extensions_transocksasp" "$hiboyfile2/Advanced_Extensions_transocksasp"
fi
umount /www/Advanced_Extensions_app10.asp
mount --bind /opt/app/transocks/Advanced_Extensions_transocks.asp /www/Advanced_Extensions_app10.asp
# 更新程序启动脚本

[ "$1" = "del" ] && /etc/storage/www_sh/transocks del &
}

case $ACTION in
start)
	transocks_close
	transocks_check
	;;
check)
	transocks_check
	;;
stop)
	transocks_close
	;;
updateapp10)
	transocks_restart o
	[ "$transocks_enable" = "1" ] && nvram set transocks_status="updatetransocks" && logger -t "【$tran_c_socks】" "重启" && transocks_restart
	[ "$transocks_enable" != "1" ] && nvram set transocks_v="" && logger -t "【$tran_c_socks】" "更新" && update_app del
	;;
update_app)
	update_app
	;;
update_asp)
	update_app update_asp
	;;
keep)
	#transocks_check
	transocks_keep
	;;
initconfig)
	initconfig
	;;
*)
	transocks_check
	;;
esac

