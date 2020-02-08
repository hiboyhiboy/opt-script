#!/bin/sh
#copyright by hiboy
source /etc/storage/script/init.sh
transocks_enable=`nvram get app_27`
[ -z $transocks_enable ] && transocks_enable=0 && nvram set app_27=0
ipt2socks_enable=`nvram get app_104`
[ -z $ipt2socks_enable ] && ipt2socks_enable=0 && nvram set app_104=0

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
[ "$transocks_proxy_mode" == 0 ] && transocks_proxy_mode_x="socks5"
[ "$transocks_proxy_mode" == 1 ] && transocks_proxy_mode_x="http"
nvram set transocks_proxy_mode_x="$transocks_proxy_mode_x"
transocks_listen_address=`nvram get app_30`
transocks_listen_port=`nvram get app_31`
transocks_server="$(nvram get app_32)"
if [ "$transocks_enable" != "0" ]  ; then
ss_tproxy_auser=`nvram get ss_tproxy_auser`
if [ "Sh58_tran_socks.sh" != "$ss_tproxy_auser" ] && [ "" != "$ss_tproxy_auser" ] ; then
	logger -t "【transocks】" "错误！！！由于已启用 $ss_tproxy_auser 透明代理，停止启用 transocks 透明代理！"
	transocks_enable=0 && nvram set app_27=0
fi
/etc/storage/script/sh_ezscript.sh 3 & #更新按钮状态
fi
#if [ "$transocks_enable" != "0" ] ; then
#nvramshow=`nvram showall | grep '=' | grep transocks | awk '{print gensub(/'"'"'/,"'"'"'\"'"'"'\"'"'"'","g",$0);}'| awk '{print gensub(/=/,"='\''",1,$0)"'\'';";}'` && eval $nvramshow
#fi

if [ ! -z "$(echo $scriptfilepath | grep -v "/tmp/script/" | grep tran_socks)" ]  && [ ! -s /tmp/script/_app10 ]; then
	mkdir -p /tmp/script
	{ echo '#!/bin/sh' ; echo $scriptfilepath '"$@"' '&' ; } > /tmp/script/_app10
	chmod 777 /tmp/script/_app10
fi

transocks_restart () {

relock="/var/lock/transocks_restart.lock"
if [ "$1" = "o" ] ; then
	nvram set transocks_renum="0"
	[ -f $relock ] && rm -f $relock
	return 0
fi
if [ "$1" = "x" ] ; then
	if [ -f $relock ] ; then
		logger -t "【transocks】" "多次尝试启动失败，等待【"`cat $relock`"分钟】后自动尝试重新启动"
		exit 0
	fi
	transocks_renum=${transocks_renum:-"0"}
	transocks_renum=`expr $transocks_renum + 1`
	nvram set transocks_renum="$transocks_renum"
	if [ "$transocks_renum" -gt "2" ] ; then
		I=19
		echo $I > $relock
		logger -t "【transocks】" "多次尝试启动失败，等待【"`cat $relock`"分钟】后自动尝试重新启动"
		while [ $I -gt 0 ]; do
			I=$(($I - 1))
			echo $I > $relock
			sleep 60
			[ "$(nvram get transocks_renum)" = "0" ] && exit 0
			[ $I -lt 0 ] && break
		done
		nvram set transocks_renum="0"
	fi
	[ -f $relock ] && rm -f $relock
fi
nvram set transocks_status=0
eval "$scriptfilepath &"
exit 0
}

transocks_get_status () {

A_restart=`nvram get transocks_status`
B_restart="$transocks_enable$transocks_mode_x$transocks_server$transocks_listen_address$transocks_listen_port$transocks_proxy_mode$(cat /etc/storage/app_9.sh | grep -v "^#" | grep -v "^$")"
B_restart=`echo -n "$B_restart" | md5sum | sed s/[[:space:]]//g | sed s/-//g`
if [ "$A_restart" != "$B_restart" ] ; then
	nvram set transocks_status=$B_restart
	needed_restart=1
else
	needed_restart=0
fi
}

transocks_check () {

transocks_get_status
if [ "$transocks_enable" = "1" ] ; then
	[ ! -z "$transocks_server" ] || logger -t "【transocks】" "远端服务器IP地址:未填写"
	[ $transocks_listen_address ] || logger -t "【transocks】" "透明重定向的代理服务器IP地址:未填写"
	[ $transocks_listen_port ] || logger -t "【transocks】" "透明重定向的代理服务器端口:未填写"
	[ ! -z "$transocks_server" ] && [ $transocks_listen_address ] && [ $transocks_listen_port ] \
	|| { logger -t "【transocks】" "错误！！！请正确填写。"; needed_restart=1; transocks_enable=0; }
fi
if [ "$transocks_enable" != "1" ] && [ "$needed_restart" = "1" ] ; then
	[ ! -z "`pidof transocks`" ] && logger -t "【transocks】" "停止 transocks" && transocks_close
	{ kill_ps "$scriptname" exit0; exit 0; }
fi
if [ "$transocks_enable" = "1" ] ; then
	if [ "$needed_restart" = "1" ] ; then
		transocks_close
		transocks_start
	else
		[ -z "`pidof transocks`" ] && transocks_restart
	fi
fi
}

transocks_keep () {
logger -t "【transocks】" "守护进程启动"
/etc/storage/script/sh_ezscript.sh 3 & #更新按钮状态
if [ -s /tmp/script/_opt_script_check ]; then
sed -Ei '/【transocks】|^$/d' /tmp/script/_opt_script_check
cat >> "/tmp/script/_opt_script_check" <<-OSC
[ -z "\`pidof transocks\`" ] && nvram set transocks_status=00 && logger -t "【transocks】" "重新启动" && eval "$scriptfilepath &" && sed -Ei '/【transocks】|^$/d' /tmp/script/_opt_script_check # 【transocks】
OSC
#return
fi

while true; do
	if [ -z "`pidof transocks`" ] ; then
		logger -t "【transocks】" "重新启动"
		transocks_restart
	fi
sleep 30
done
}

transocks_close () {
kill_ps "$scriptname keep"
sed -Ei '/【transocks】|【ipt2socks】|^$/d' /tmp/script/_opt_script_check
Sh99_ss_tproxy.sh off_stop "Sh58_tran_socks.sh"
killall transocks ipt2socks
killall -9 transocks ipt2socks
/etc/storage/script/sh_ezscript.sh 3 & #更新按钮状态
kill_ps "/tmp/script/_app10"
kill_ps "_tran_socks.sh"
kill_ps "/tmp/script/_app20"
kill_ps "_ipt2socks.sh"
kill_ps "$scriptname"
}

transocks_start () {

check_webui_yes
SVC_PATH="/opt/bin/transocks"
if [ ! -s "$SVC_PATH" ] ; then
	logger -t "【transocks】" "找不到 $SVC_PATH，安装 opt 程序"
	/tmp/script/_mountopt start
fi
wgetcurl_file "$SVC_PATH" "$hiboyfile/transocks" "$hiboyfile2/transocks"
[[ "$(transocks -h 2>&1 | wc -l)" -lt 2 ]] && rm -rf /opt/bin/transocks
if [ ! -s "$SVC_PATH" ] ; then
	logger -t "【transocks】" "找不到 $SVC_PATH ，需要手动安装 $SVC_PATH"
	logger -t "【transocks】" "启动失败, 10 秒后自动尝试重新启动" && sleep 10 && transocks_restart x
fi
chmod 777 "$SVC_PATH"
transocks_v=$(transocks -h 2>&1  | grep transocks_ver | sed -n '1p')
nvram set transocks_v="$transocks_v"
logger -t "【transocks】" "运行 transocks"

#运行脚本启动/opt/bin/transocks
/etc/storage/app_9.sh
cd $(dirname `which transocks`)
killall -9 transocks
transocks -f /tmp/transocks.toml &

sleep 2
[ ! -z "$(ps -w | grep "transocks" | grep -v grep )" ] && logger -t "【transocks】" "启动成功" && transocks_restart o
[ -z "$(ps -w | grep "transocks" | grep -v grep )" ] && logger -t "【transocks】" "启动失败, 注意检查端口是否有冲突,程序是否下载完整,10 秒后自动尝试重新启动" && sleep 10 && transocks_restart x
initopt
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
	logger -t "【transocks】" "脚本 [Sh99_ss_tproxy.sh] 当前使用者: $auser_b ，跳过 $auser_a 的运行命令"
	logger -t "【transocks】" "需要停用 $auser_b 后才能使用 $auser_a 运行 [Sh99_ss_tproxy.sh] 脚本"
	return
fi
lan_ipaddr=`nvram get lan_ipaddr`
ss_tproxy_mode_x=`nvram get app_110`
[ -z $ss_tproxy_mode_x ] && ss_tproxy_mode_x=0 && nvram set app_110=0
[ "$ss_tproxy_mode_x" = "0" ] && logger -t "【transocks】" "【自动】设置 ss_tproxy 配置文件，配置导入中..."
[ "$ss_tproxy_mode_x" = "1" ] && logger -t "【transocks】" "【手动】设置 ss_tproxy 配置文件，跳过配置导入" && return
 # /etc/storage/app_27.sh
[ "$transocks_mode_x" == "0" ] && sstp_set mode='chnroute'
[ "$transocks_mode_x" == "1" ] && sstp_set mode='gfwlist'
[ "$transocks_mode_x" == "2" ] && sstp_set mode='global'
[ "$transocks_mode_x" == "3" ] && sstp_set mode='chnlist'
sstp_set ipv4='true' ; sstp_set ipv6='false' ;
 # sstp_set ipv4='false' ; sstp_set ipv6='true' ;
 # sstp_set ipv4='true' ; sstp_set ipv6='true' ;
sstp_set tproxy='false' # true:TPROXY+TPROXY; false:REDIRECT+TPROXY
sstp_set tcponly='false' # true:仅代理TCP流量; false:代理TCP和UDP流量
sstp_set selfonly='false'  # true:仅代理本机流量; false:代理本机及"内网"流量
nvram set app_112="0"      #app_112 0:自动开启第三方 DNS 程序(dnsproxy) ; 1:跳过自动开启第三方 DNS 程序但是继续把DNS绑定到 8053 端口的程序
nvram set app_113="0"      #app_113 0:使用 8053 端口查询全部 DNS 时进行 China 域名加速 ; 1:不进行 China 域名加速
nvram set app_114="0" # 0:代理本机流量; 1:跳过代理本机流量
sstp_set uid_owner='0' # 非 0 时进行用户ID匹配跳过代理本机流量
## proxy
sstp_set proxy_all_svraddr="/opt/app/ss_tproxy/conf/proxy_all_svraddr.conf"
sstp_set proxy_svrport='1:65535'
sstp_set proxy_tcpport='1098'
sstp_set proxy_udpport='1098'
sstp_set proxy_startcmd='echo'
sstp_set proxy_stopcmd='echo'
## dns
DNS_china=`nvram get wan0_dns |cut -d ' ' -f1`
[ -z "$DNS_china" ] && DNS_china="114.114.114.114"
sstp_set dns_direct="$DNS_china"
sstp_set dns_direct6='240C::6666'
sstp_set dns_remote='8.8.8.8#53'
sstp_set dns_remote6='2001:4860:4860::8888#53'
[ "$transocks_mode_x" == "3" ] && sstp_set dns_direct='8.8.8.8' # 回国模式
[ "$transocks_mode_x" == "3" ] && sstp_set dns_direct6='2001:4860:4860::8888' # 回国模式
[ "$transocks_mode_x" == "3" ] && sstp_set dns_remote='114.114.114.114#53' # 回国模式
[ "$transocks_mode_x" == "3" ] && sstp_set dns_remote6='240C::6666#53' # 回国模式
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
sstp_set ipts_reddns_onstart='true' # ss-tproxy start 后，是否将其它主机发至本机的 DNS 重定向至自定义 IPv4 地址
 # sstp_set ipts_reddns_onstart='false'
sstp_set ipts_reddns_ip="$lan_ipaddr" # 自定义 DNS 重定向地址(只支持 IPv4 )
sstp_set ipts_proxy_dst_port_tcp="1:65535"
sstp_set ipts_proxy_dst_port_udp="1:65535"
sstp_set LAN_AC_IP="0"
## opts
sstp_set opts_overwrite_resolv='false'
sstp_set opts_ip_for_check_net=''
## file
sstp_set file_gfwlist_txt='/opt/app/ss_tproxy/rule/gfwlist.txt'
sstp_set file_gfwlist_ext='/opt/app/ss_tproxy/gfwlist.ext'
sstp_set file_ignlist_ext='/opt/app/ss_tproxy/ignlist.ext'
sstp_set file_lanlist_ext='/opt/app/ss_tproxy/lanlist.ext'
sstp_set file_wanlist_ext='/opt/app/ss_tproxy/wanlist.ext'
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
server_addresses=$(cat /etc/storage/v2ray_config_script.sh | tr -d ' ' | grep -Eo '"address":.+' | grep -v 8.8.8.8 | grep -v 114.114.114.114 | sed -n '1p' | cut -d':' -f2 | cut -d'"' -f2)
echo "$server_addresses" >> /opt/app/ss_tproxy/conf/proxy_all_svraddr.conf
# clash
grep '^  server: ' /etc/storage/app_20.sh | sed -e 's/server://g' | sed -e 's/"\|'"'"'\| //g' >> /opt/app/ss_tproxy/conf/proxy_all_svraddr.conf
kcptun_server=`nvram get kcptun_server`
echo "$kcptun_server" >> /opt/app/ss_tproxy/conf/proxy_all_svraddr.conf
# transocks ipt2socks 
echo "$transocks_server" | sed -e "s@ @\n@g" >> /opt/app/ss_tproxy/conf/proxy_all_svraddr.conf

# 链接配置文件
umount -l /opt/app/ss_tproxy/wanlist.ext
mount --bind /opt/storage/shadowsocks_ss_spec_wan.sh /opt/app/ss_tproxy/wanlist.ext
umount -l /opt/app/ss_tproxy/lanlist.ext
mount --bind /opt/storage/shadowsocks_ss_spec_lan.sh /opt/app/ss_tproxy/lanlist.ext
logger -t "【transocks】" "【自动】设置 ss_tproxy 配置文件，完成配置导入"
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

initopt () {
optPath=`grep ' /opt ' /proc/mounts | grep tmpfs`
[ ! -z "$optPath" ] && return
if [ ! -z "$(echo $scriptfilepath | grep -v "/opt/etc/init")" ] && [ -s "/opt/etc/init.d/rc.func" ] ; then
	{ echo '#!/bin/sh' ; echo $scriptfilepath '"$@"' '&' ; } > /opt/etc/init.d/$scriptname && chmod 777  /opt/etc/init.d/$scriptname
fi

}

initconfig () {
[ -z "$(cat /etc/storage/app_9.sh | grep '0\.0\.0\.0:1098')" ] && rm -f /etc/storage/app_9.sh
	if [ ! -f "/etc/storage/app_9.sh" ] || [ ! -s "/etc/storage/app_9.sh" ] ; then
cat > "/etc/storage/app_9.sh" <<-\VVR
#!/bin/sh
lan_ipaddr=`nvram get lan_ipaddr`
transocks_listen_address=`nvram get app_30`
transocks_listen_port=`nvram get app_31`
transocks_proxy_mode_x=`nvram get transocks_proxy_mode_x`
cat > "/tmp/transocks.toml" <<-TTR
# listening address of transocks.
listen = "$lan_ipaddr:1098"

proxy_url = "$transocks_proxy_mode_x://$transocks_listen_address:$transocks_listen_port"

[log]
filename = "/tmp/syslog.log"
level = "error"               # critical", error, warning, info, debug
format = "plain"              # plain, logfmt, json

TTR

VVR
	fi


}

initconfig

update_init () {
source /etc/storage/script/init.sh
[ "$init_ver" -lt 0 ] && init_ver="0" || { [ "$init_ver" -gt 0 ] || init_ver="0" ; }
init_s_ver=2
if [ "$init_s_ver" -gt "$init_ver" ] ; then
	logger -t "【update_init】" "更新 /etc/storage/script/init.sh 文件"
	wgetcurl.sh /tmp/init_tmp.sh  "$hiboyscript/script/init.sh" "$hiboyscript2/script/init.sh"
	[ -s /tmp/init_tmp.sh ] && cp -f /tmp/init_tmp.sh /etc/storage/script/init.sh
	chmod 755 /etc/storage/script/init.sh
	source /etc/storage/script/init.sh
fi
}

update_app () {
update_init
mkdir -p /opt/app/transocks
if [ "$1" = "del" ] ; then
	rm -rf /opt/app/transocks/Advanced_Extensions_transocks.asp
	[ -f /opt/bin/transocks ] && rm -f /opt/bin/transocks /opt/opt_backup/bin/transocks
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
	[ "$transocks_enable" = "1" ] && nvram set transocks_status="updatetransocks" && logger -t "【transocks】" "重启" && transocks_restart
	[ "$transocks_enable" != "1" ] && nvram set transocks_v="" && logger -t "【transocks】" "更新" && update_app del
	;;
update_app)
	update_app
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

