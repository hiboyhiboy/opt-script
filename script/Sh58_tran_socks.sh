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
ss_enable=`nvram get ss_enable`
[ -z $ss_enable ] && ss_enable=0 && nvram set ss_enable=0
v2ray_enable=`nvram get v2ray_enable`
[ -z $v2ray_enable ] && v2ray_enable=0 && nvram set v2ray_enable=0
v2ray_follow=`nvram get v2ray_follow`
[ -z $v2ray_follow ] && v2ray_follow=0 && nvram set v2ray_follow=0
if [ "$transocks_enable" != "0" ]  ; then
/etc/storage/script/sh_ezscript.sh 3 & #更新按钮状态
	if [ "$ss_enable" != "0" ]  ; then
		ss_mode_x=`nvram get ss_mode_x` #ss模式，0 为chnroute, 1 为 gfwlist, 2 为全局, 3为ss-local 建立本地 SOCKS 代理
		[ -z $ss_mode_x ] && ss_mode_x=0 && nvram set ss_mode_x=$ss_mode_x
		if [ "$ss_mode_x" != 3 ]  ; then
			logger -t "【transocks】" "错误！！！由于已启用 transocks 或 ipt2socks ，停止启用 SS 透明代理！"
			ss_enable=0 && nvram set ss_enable=0
		fi
	fi
	if [ "$v2ray_enable" != 0 ] && [ "$v2ray_follow" != 0 ]  ; then
		logger -t "【transocks】" "错误！！！由于已启用 transocks ，停止启用 v2ray 透明代理！"
		v2ray_follow=0 && nvram set v2ray_follow=0
	fi
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
		if [ -n "`pidof transocks`" ] ; then
			port=$(iptables -t nat -L | grep 'SS_SPEC' | wc -l)
			if [ "$port"x = 0x ] ; then
				logger -t "【transocks】" "检测2:找不到 SS_SPEC 转发规则, 重新添加"
				transocks_port_dpt &
			fi
		fi
		ss_pdnsd_all=`nvram get ss_pdnsd_all`
		if [ "$transocks_mode_x" = "2" ] || [ "$ss_pdnsd_all" = "1" ] ; then 
			port=$(grep "server=127.0.0.1#8053"  /etc/storage/dnsmasq/dnsmasq.conf | wc -l)
			if [ "$port" = 0 ] ; then
				sleep 10
				port=$(grep "server=127.0.0.1#8053"  /etc/storage/dnsmasq/dnsmasq.conf | wc -l)
			fi
			if [ "$port" = 0 ] ; then
				logger -t "【transocks】" "检测2:找不到 dnsmasq 转发规则, 重新添加"
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
	if [ -n "`pidof transocks`" ] ; then
		port=$(iptables -t nat -L | grep 'SS_SPEC' | wc -l)
		if [ "$port"x = 0x ] ; then
			logger -t "【transocks】" "检测2:找不到 SS_SPEC 转发规则, 重新添加"
			transocks_port_dpt &
		fi
	fi
	ss_pdnsd_all=`nvram get ss_pdnsd_all`
	if [ "$transocks_mode_x" = "2" ] || [ "$ss_pdnsd_all" = "1" ] ; then 
		port=$(grep "server=127.0.0.1#8053"  /etc/storage/dnsmasq/dnsmasq.conf | wc -l)
		if [ "$port" = 0 ] ; then
			sleep 10
			port=$(grep "server=127.0.0.1#8053"  /etc/storage/dnsmasq/dnsmasq.conf | wc -l)
		fi
		if [ "$port" = 0 ] ; then
			logger -t "【transocks】" "检测2:找不到 dnsmasq 转发规则, 重新添加"
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
sleep 30
done
}

transocks_close () {
/etc/storage/script/Sh15_ss.sh transock_stop
sed -Ei '/【transocks】|【ipt2socks】|^$/d' /tmp/script/_opt_script_check
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
transocks_port_dpt
#transocks_get_status
eval "$scriptfilepath keep &"
exit 0
}

initopt () {
optPath=`grep ' /opt ' /proc/mounts | grep tmpfs`
[ ! -z "$optPath" ] && return
if [ ! -z "$(echo $scriptfilepath | grep -v "/opt/etc/init")" ] && [ -s "/opt/etc/init.d/rc.func" ] ; then
	{ echo '#!/bin/sh' ; echo $scriptfilepath '"$@"' '&' ; } > /opt/etc/init.d/$scriptname && chmod 777  /opt/etc/init.d/$scriptname
fi

}

initconfig () {
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

transocks_port_dpt () {
if [ ! -f "/etc/storage/script/Sh15_ss.sh" ] || [ ! -s "/etc/storage/script/Sh15_ss.sh" ] ; then
	wgetcurl.sh /etc/storage/script/Sh15_ss.sh "$hiboyscript/script/Sh15_ss.sh" "$hiboyscript2/script/Sh15_ss.sh"
fi

/etc/storage/script/Sh15_ss.sh transock_start
}

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

