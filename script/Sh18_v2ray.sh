#!/bin/sh
#copyright by hiboy
source /etc/storage/script/init.sh

TAG="SS_SPEC"		  # iptables tag
FWI="/tmp/firewall.v2ray.pdcn"
v2ray_enable=`nvram get v2ray_enable`
[ -z $v2ray_enable ] && v2ray_enable=0 && nvram set v2ray_enable=0
ss_enable=`nvram get ss_enable`
[ -z $ss_enable ] && ss_enable=0 && nvram set ss_enable=0
transocks_enable=`nvram get app_27`
[ -z $transocks_enable ] && transocks_enable=0 && nvram set app_27=0
v2ray_follow=`nvram get v2ray_follow`
[ -z $v2ray_follow ] && v2ray_follow=0 && nvram set v2ray_follow=0
mk_mode_x="`nvram get app_69`"
[ -z $mk_mode_x ] && mk_mode_x=0 && nvram set app_69=0
mk_mode_b="`nvram get app_70`"
[ -z $mk_mode_b ] && mk_mode_b=0 && nvram set app_70=0
[ "$mk_mode_x" = "3" ] && mk_mode_b=1
mk_mode_dns="`nvram get app_105`"
[ -z $mk_mode_dns ] && mk_mode_dns=0 && nvram set app_105=0
mk_mode_routing=`nvram get app_108`
[ -z $mk_mode_routing ] && mk_mode_routing=0 && nvram set app_108=0
lan_ipaddr=`nvram get lan_ipaddr`
server_addresses=$(cat /etc/storage/v2ray_config_script.sh | tr -d ' ' | grep -Eo '"address":.+' | grep -v 8.8.8.8 | grep -v 114.114.114.114 | sed -n '1p' | cut -d':' -f2 | cut -d'"' -f2)
if [ "$v2ray_enable" != 0 ] && [ "$mk_mode_routing" == "1" ] ; then
v2ray_follow=0 && nvram set v2ray_follow=0
nvram set app_30="$lan_ipaddr"
nvram set app_31="1088"
nvram set app_32="$server_addresses"
fi
if [ "$transocks_enable" != "0" ]  ; then
	if [ "$ss_enable" != "0" ]  ; then
		ss_mode_x=`nvram get ss_mode_x` #ss模式，0 为chnroute, 1 为 gfwlist, 2 为全局, 3为ss-local 建立本地 SOCKS 代理
		[ -z $ss_mode_x ] && ss_mode_x=0 && nvram set ss_mode_x=$ss_mode_x
		if [ "$ss_mode_x" != 3 ]  ; then
			logger -t "【v2ray】" "错误！！！由于已启用 transocks 或 ipt2socks ，停止启用 SS 透明代理！"
			ss_enable=0 && nvram set ss_enable=0
		fi
	fi
	if [ "$v2ray_enable" != 0 ] && [ "$v2ray_follow" != 0 ]  ; then
		logger -t "【v2ray】" "错误！！！由于已启用 transocks 或 ipt2socks ，停止启用 v2ray 透明代理！"
		v2ray_follow=0 && nvram set v2ray_follow=0
	fi
fi
if [ "$v2ray_enable" != "0" ] ; then
/etc/storage/script/sh_ezscript.sh 3 & #更新按钮状态
#nvramshow=`nvram showall | grep '=' | grep v2ray | awk '{print gensub(/'"'"'/,"'"'"'\"'"'"'\"'"'"'","g",$0);}'| awk '{print gensub(/=/,"='\''",1,$0)"'\'';";}'` && eval $nvramshow
v2ray_optput=`nvram get v2ray_optput`
[ -z $v2ray_optput ] && v2ray_optput=0 && nvram set v2ray_optput=0

chinadns_enable=`nvram get app_1`
[ -z $chinadns_enable ] && chinadns_enable=0 && nvram set app_1=0
chinadns_port=`nvram get app_6`
[ -z $chinadns_port ] && chinadns_port=8053 && nvram set app_6=8053
# v2ray_port=`nvram get v2ray_port`
# [ -z $v2ray_port ] && v2ray_port=1088 && nvram set v2ray_port=1088
nvram set v2ray_port=`cat /etc/storage/v2ray_config_script.sh | grep -Eo '"port": [0-9]+' | cut -d':' -f2 | tr -d ' ' | sed -n '1p'`

v2ray_renum=`nvram get v2ray_renum`
v2ray_renum=${v2ray_renum:-"0"}
cmd_log_enable=`nvram get cmd_log_enable`
cmd_name="v2ray"
cmd_log=""
if [ "$cmd_log_enable" = "1" ] || [ "$v2ray_renum" -gt "0" ] ; then
	cmd_log="$cmd_log2"
fi
fi
v2ray_path=`nvram get v2ray_path`
[ -z $v2ray_path ] && v2ray_path="/opt/bin/v2ray" && nvram set v2ray_path=$v2ray_path
v2ray_door=`nvram get v2ray_door`
[ -z $v2ray_door ] && v2ray_door=1099 && nvram set v2ray_door=1099

v2ray_http_enable=`nvram get v2ray_http_enable`
[ -z $v2ray_http_enable ] && v2ray_http_enable=0 && nvram set v2ray_http_enable=0
v2ray_http_format=`nvram get v2ray_http_format`
[ -z $v2ray_http_format ] && v2ray_http_format=1 && nvram set v2ray_http_format=1
v2ray_http_config=`nvram get v2ray_http_config`

if [ ! -z "$(echo $scriptfilepath | grep -v "/tmp/script/" | grep v2ray)" ]  && [ ! -s /tmp/script/_v2ray ]; then
	mkdir -p /tmp/script
	{ echo '#!/bin/sh' ; echo $scriptfilepath '"$@"' '&' ; } > /tmp/script/_v2ray
	chmod 777 /tmp/script/_v2ray
fi

v2ray_restart () {

relock="/var/lock/v2ray_restart.lock"
if [ "$1" = "o" ] ; then
	nvram set v2ray_renum="0"
	[ -f $relock ] && rm -f $relock
	return 0
fi
if [ "$1" = "x" ] ; then
	if [ -f $relock ] ; then
		logger -t "【v2ray】" "多次尝试启动失败，等待【"`cat $relock`"分钟】后自动尝试重新启动"
		exit 0
	fi
	v2ray_renum=${v2ray_renum:-"0"}
	v2ray_renum=`expr $v2ray_renum + 1`
	nvram set v2ray_renum="$v2ray_renum"
	if [ "$v2ray_renum" -gt "2" ] ; then
		I=19
		echo $I > $relock
		logger -t "【v2ray】" "多次尝试启动失败，等待【"`cat $relock`"分钟】后自动尝试重新启动"
		while [ $I -gt 0 ]; do
			I=$(($I - 1))
			echo $I > $relock
			sleep 60
			[ "$(nvram get v2ray_renum)" = "0" ] && exit 0
			[ $I -lt 0 ] && break
		done
		nvram set v2ray_renum="0"
	fi
	[ -f $relock ] && rm -f $relock
fi
nvram set v2ray_status=0
eval "$scriptfilepath &"
exit 0
}

v2ray_get_status () {

A_restart=`nvram get v2ray_status`
B_restart="$v2ray_enable$chinadns_enable$v2ray_path$v2ray_follow$lan_ipaddr$v2ray_door$v2ray_optput$v2ray_http_enable$v2ray_http_format$v2ray_http_config$mk_mode_routing$(cat /etc/storage/v2ray_script.sh /etc/storage/v2ray_config_script.sh | grep -v "^#" | grep -v "^$")"
B_restart=`echo -n "$B_restart" | md5sum | sed s/[[:space:]]//g | sed s/-//g`
if [ "$A_restart" != "$B_restart" ] ; then
	nvram set v2ray_status=$B_restart
	needed_restart=1
else
	needed_restart=0
fi
}

v2ray_check () {

check_link
ping_vmess_link
start_vmess_link
json_mk_vmess
v2ray_get_status
if [ "$v2ray_enable" != "1" ] && [ "$needed_restart" = "1" ] ; then
	[ ! -z "$(ps -w | grep "$v2ray_path" | grep -v grep )" ] && logger -t "【v2ray】" "停止 v2ray" && v2ray_close
	{ kill_ps "$scriptname" exit0; exit 0; }
fi
if [ "$v2ray_enable" = "1" ] ; then
	if [ "$needed_restart" = "1" ] ; then
		v2ray_close
		v2ray_start
	else
		[ -z "$(ps -w | grep "$v2ray_path" | grep -v grep )" ] && v2ray_restart
		if [ "$v2ray_follow" = "1" ] ; then
		port=$(iptables -t nat -L | grep 'SS_SPEC' | wc -l)
		if [ "$port" = 0 ] ; then
			logger -t "【v2ray】" "检测:找不到 SS_SPEC 转发规则, 重新添加"
			v2ray_restart
		fi
		fi
	fi
fi
}

v2ray_keep () {
logger -t "【v2ray】" "守护进程启动"
[ "$mk_mode_routing" == "1" ] && nvram set app_104=1 && Sh39_ipt2socks.sh # 启用 ipt2socks
/etc/storage/script/sh_ezscript.sh 3 & #更新按钮状态
if [ -s /tmp/script/_opt_script_check ]; then
sed -Ei '/【v2ray】|^$/d' /tmp/script/_opt_script_check
cat >> "/tmp/script/_opt_script_check" <<-OSC
	NUM=\`grep "$v2ray_path" /tmp/ps | grep -v grep |wc -l\` # 【v2ray】
	if [ "\$NUM" -lt "1" ] || [ ! -s "$v2ray_path" ] ; then # 【v2ray】
		logger -t "【v2ray】" "重新启动\$NUM" # 【v2ray】
		nvram set v2ray_status=00 && eval "$scriptfilepath &" && sed -Ei '/【v2ray】|^$/d' /tmp/script/_opt_script_check # 【v2ray】
	fi # 【v2ray】
OSC
#return
fi
sleep 60
v2ray_enable=`nvram get v2ray_enable`
while [ "$v2ray_enable" = "1" ]; do
	NUM=`ps -w | grep "$v2ray_path" | grep -v grep |wc -l`
	if [ "$NUM" -lt "1" ] || [ ! -s "$v2ray_path" ] ; then
		logger -t "【v2ray】" "重新启动$NUM"
		v2ray_restart
	fi
	v2ray_follow=`nvram get v2ray_follow`
	if [ "$v2ray_follow" = "1" ] ; then
		port=$(iptables -t nat -L | grep 'SS_SPEC' | wc -l)
		if [ "$port" = 0 ] ; then
			logger -t "【v2ray】" "检测:找不到 SS_SPEC 转发规则, 重新添加"
			v2ray_restart
		fi
		if [ "$chinadns_enable" = "0" ] || [ "$chinadns_port" != "8053" ] ; then
			port=$(grep "server=127.0.0.1#8053"  /etc/storage/dnsmasq/dnsmasq.conf | wc -l)
			if [ "$port" = 0 ] ; then
				sleep 10
				port=$(grep "server=127.0.0.1#8053"  /etc/storage/dnsmasq/dnsmasq.conf | wc -l)
			fi
			if [ "$port" = 0 ] ; then
				logger -t "【v2ray】" "检测:找不到 dnsmasq 转发规则, 重新添加"
				# 写入dnsmasq配置
				sed -Ei '/no-resolv|server=|server=127.0.0.1#8053|dns-forward-max=1000|min-cache-ttl=1800/d' /etc/storage/dnsmasq/dnsmasq.conf
				cat >> "/etc/storage/dnsmasq/dnsmasq.conf" <<-EOF
no-resolv
server=127.0.0.1#8053
dns-forward-max=1000
min-cache-ttl=1800
EOF
				restart_dhcpd
			fi
		fi
	fi
sleep 218
v2ray_enable=`nvram get v2ray_enable`
done
}

v2ray_close () {
flush_r
if [ "$ss_enable" = "1" ] ; then
/etc/storage/script/Sh15_ss.sh &
fi
sed -Ei '/【v2ray】|^$/d' /tmp/script/_opt_script_check
[ ! -z "$v2ray_path" ] && kill_ps "$v2ray_path"
killall v2ray v2ctl v2ray_script.sh
killall -9 v2ray v2ctl v2ray_script.sh
/etc/storage/script/sh_ezscript.sh 3 & #更新按钮状态
kill_ps "/tmp/script/_v2ray"
kill_ps "_v2ray.sh"
kill_ps "$scriptname"
}

v2ray_wget_v2ctl () {

v2ctl_path="$(cd "$(dirname "$v2ray_path")"; pwd)/v2ctl"
wgetcurl_file $v2ctl_path "$hiboyfile/v2ctl" "$hiboyfile2/v2ctl"
if [ "$mk_mode_routing" == "1" ] ; then
	#rm -f /opt/bin/geoip.dat /opt/bin/geosite.dat
	echo "mk_mode_routing"
else
	geoip_path="$(cd "$(dirname "$v2ray_path")"; pwd)/geoip.dat"
	wgetcurl_file $geoip_path "$hiboyfile/geoip.dat" "$hiboyfile2/geoip.dat"
	geosite_path="$(cd "$(dirname "$v2ray_path")"; pwd)/geosite.dat"
	wgetcurl_file $geosite_path "$hiboyfile/geosite.dat" "$hiboyfile2/geosite.dat"
fi
if [ ! -s "/etc/ssl/certs/ca-certificates.crt" ] ; then
	mkdir -p /opt/app/ipk/
	mkdir -p /opt/etc/ssl/certs
	rm -f /etc/ssl/certs
	ln -sf /opt/etc/ssl/certs  /etc/ssl/certs
	if [ ! -s "/etc/ssl/certs/ca-certificates.crt" ] && [ -s /etc_ro/certs.tgz ]; then
		tar -xzvf /etc_ro/certs.tgz -C /opt/etc/ssl/
	fi
	if [ ! -s "/etc/ssl/certs/ca-certificates.crt" ] ; then
		logger -t "【opt】" "已挂载,找不到ca-certificates证书"
		logger -t "【opt】" "下载证书"
		wgetcurl.sh /opt/app/ipk/certs.tgz "$hiboyfile/certs.tgz" "$hiboyfile2/certs.tgz"
		logger -t "【opt】" "安装证书"
		tar -xzvf /opt/app/ipk/certs.tgz -C /opt/etc/ssl/
		rm -f /opt/app/ipk/certs.tgz
	fi
	chmod 644 /etc/ssl/certs -R
	chmod 777 /etc/ssl/certs
	chmod 644 /opt/etc/ssl/certs -R
	chmod 777 /opt/etc/ssl/certs
fi
}

v2ray_start () {

check_webui_yes
mkdir -p /tmp/vmess
if [ "$v2ray_http_enable" = "1" ] && [ -z "$v2ray_http_config" ] ; then
logger -t "【v2ray】" "错误！配置远程地址 内容为空"
logger -t "【v2ray】" "请填写配置远程地址！"
logger -t "【v2ray】" "启动失败,10 秒后自动尝试重新启动"
sleep 10 && v2ray_restart x
fi
if [ "$v2ray_http_enable" != "1" ] && [ ! -f /opt/bin/v2ray_config.pb ] ; then
if [ ! -f "/etc/storage/v2ray_config_script.sh" ] || [ ! -s "/etc/storage/v2ray_config_script.sh" ] ; then
logger -t "【v2ray】" "错误！ v2ray 配置文件 内容为空"
logger -t "【v2ray】" "请在服务端运行一键安装脚本："
logger -t "【v2ray】" "bash <(curl -L -s https://opt.cn2qq.com/opt-script/v2ray.sh)"
logger -t "【v2ray】" "启动失败,10 秒后自动尝试重新启动"
sleep 10 && v2ray_restart x
fi
if [ -s "/etc/storage/v2ray_config_script.sh" ] ; then
if [ ! -z "$(grep '"inbound"'  /etc/storage/v2ray_config_script.sh)" ] || [ ! -z "$(grep '"outbound"'  /etc/storage/v2ray_config_script.sh)" ] ; then
logger -t "【v2ray】" "注意！！！v4.22.0及以上版本不再兼容旧的v2ray json配置格式（如：inbound {}，outbound {}格式。）"
logger -t "【v2ray】" "请尽快使用 inbounds []，outbounds []格式替换。"
fi
fi
fi

SVC_PATH="$v2ray_path"
if [ ! -s "$SVC_PATH" ] ; then
	SVC_PATH="/opt/bin/v2ray"
	v2ray_path="$SVC_PATH"
fi
chmod 777 "$SVC_PATH"
[[ "$(v2ray -h 2>&1 | wc -l)" -lt 2 ]] && rm -rf /opt/bin/v2ray
if [ ! -s "$SVC_PATH" ] ; then
	logger -t "【v2ray】" "找不到 $SVC_PATH，安装 opt 程序"
	/tmp/script/_mountopt start
fi
killall v2ray v2ctl v2ray_script.sh
killall -9 v2ray v2ctl v2ray_script.sh
optPath="`grep ' /opt ' /proc/mounts | grep tmpfs`"
Mem_total="$(free | sed -n '2p' | awk '{print $2;}')"
Mem_lt=100000
if [ ! -z "$optPath" ] || [ "$Mem_total" -lt "$Mem_lt" ] ; then
	[ ! -z "$optPath" ] && logger -t "【v2ray】" " /opt/ 在内存储存"
	if [ "$Mem_total" -lt "$Mem_lt" ] ; then
		logger -t "【v2ray】" "内存不足100M"
		if [ "$mk_mode_routing" == "1" ] ; then
			rm -f /opt/bin/geoip.dat /opt/bin/geosite.dat /opt/opt_backup/bin/geoip.dat /opt/opt_backup/bin/geosite.dat
		else
			logger -t "【v2ray】" "建议使用 ipt2socks 分流(降低负载，适合低配路由)"
		fi
	fi
fi
	# [ "$Mem_total" -lt "70000" ] && export  V2RAY_RAY_BUFFER_SIZE=1
	# if [ "$v2ray_http_enable" = "1" ] && [ ! -z "$v2ray_http_config" ] ; then
		# [ "$v2ray_http_format" = "1" ] && wgetcurl.sh /etc/storage/v2ray_config_script.sh "$v2ray_http_config" "$v2ray_http_config"
		# [ "$v2ray_http_format" = "2" ] &&  wgetcurl.sh /opt/bin/v2ray_config.pb "$v2ray_http_config" "$v2ray_http_config"
		# v2ray_http_enable=0
	# fi
	# A_restart=`nvram get app_19`
	# B_restart=`echo -n "$(cat /etc/storage/v2ray_config_script.sh | grep -v "^$")" | md5sum | sed s/[[:space:]]//g | sed s/-//g`
	# if [ "$A_restart" != "$B_restart" ] || [ ! -f /opt/bin/v2ray_config.pb ] ; then
		# [ ! -z "$optPath" ] && rm -f /opt/bin/v2ray
		# rm -f /opt/bin/v2ray_config.pb
		# v2ray_wget_v2ctl
		# logger -t "【v2ray】" "配置文件转换 Protobuf 格式配置 /opt/bin/v2ray_config.pb"
		# cd "$(dirname "$SVC_PATH")"
		# cp -f /etc/storage/v2ray_config_script.sh /tmp/vmess/mk_vmess.json
		# json_join_gfwlist
		# eval "v2ctl config < /tmp/vmess/mk_vmess.json > /opt/bin/v2ray_config.pb $cmd_log" 
		# [ ! -s /opt/bin/v2ray_config.pb ] && logger -t "【v2ray】" "错误！ /opt/bin/v2ray_config.pb 内容为空, 10 秒后自动尝试重新启动" && sleep 10 && v2ray_restart x
		# [ -f /opt/bin/v2ray_config.pb ] && nvram set app_19=$B_restart
		# [ ! -z "$optPath" ] && rm -f /opt/bin/v2ctl /opt/bin/geoip.dat /opt/bin/geosite.dat /tmp/vmess/mk_vmess.json
	# fi
	v2ray_wget_v2ctl
	rm -f /opt/bin/v2ray_config.pb
if [ ! -s "$SVC_PATH" ] ; then
	wgetcurl_file "$SVC_PATH" "$hiboyfile/v2ray" "$hiboyfile2/v2ray"
else
	logger -t "【v2ray】" "找到 $SVC_PATH"
	chmod 777 "$SVC_PATH"
	[ -f /opt/bin/v2ray ] && chmod 777 /opt/bin/v2ray
	[ -f /opt/bin/v2ctl ] && chmod 777 /opt/bin/v2ctl
	[ -f /opt/bin/geoip.dat ] && chmod 777 /opt/bin/geoip.dat
	[ -f /opt/bin/geosite.dat ] && chmod 777 /opt/bin/geosite.dat
fi
if [ ! -s "$SVC_PATH" ] ; then
	logger -t "【v2ray】" "找不到 $SVC_PATH ，需要手动安装 $SVC_PATH"
	logger -t "【v2ray】" "启动失败, 10 秒后自动尝试重新启动" && sleep 10 && v2ray_restart x
fi
if [ -s "$SVC_PATH" ] ; then
	nvram set v2ray_path="$SVC_PATH"
fi
v2ray_path="$SVC_PATH"
logger -t "【v2ray】" "运行 v2ray_script"
chmod 777 /etc/storage/v2ray_script.sh
chmod 644 /opt/etc/ssl/certs -R
chmod 777 /opt/etc/ssl/certs
chmod 644 /etc/ssl/certs -R
chmod 777 /etc/ssl/certs
/etc/storage/v2ray_script.sh
cd "$(dirname "$v2ray_path")"
su_cmd="eval"
if [ "$mk_mode_routing" == "1" ] ; then
# 停止 ipt2socks
/etc/storage/script/Sh15_ss.sh transock_stop
sed -Ei '/【transocks】|【ipt2socks】|^$/d' /tmp/script/_opt_script_check
killall transocks ipt2socks
killall -9 transocks ipt2socks
kill_ps "/tmp/script/_app10"
kill_ps "_tran_socks.sh"
kill_ps "/tmp/script/_app20"
kill_ps "_ipt2socks.sh"
v2ray_follow=0 && nvram set v2ray_follow=0
nvram set app_30="$lan_ipaddr"
nvram set app_31="1088"
nvram set app_32="$server_addresses"
#Sh39_ipt2socks.sh
fi
if [ "$v2ray_follow" = "1" ] && [ "$v2ray_optput" = "1" ]; then
	NUM=`iptables -m owner -h 2>&1 | grep owner | wc -l`
	hash su 2>/dev/null && su_x="1"
	hash su 2>/dev/null || su_x="0"
	[ "$su_x" != "1" ] && logger -t "【v2ray】" "缺少 su 命令"
	[ "$NUM" -ge "3" ] || logger -t "【v2ray】" "缺少 iptables -m owner 模块"
	if [ "$NUM" -ge "3" ] && [ "$v2ray_optput" = 1 ] && [ "$su_x" = "1" ] ; then
		adduser -u 777 v2 -D -S -H -s /bin/sh
		killall v2ray
		su_cmd="su v2 -c "
	else
		logger -t "【v2ray】" "停止路由自身流量走透明代理"
		v2ray_optput=0
		nvram set v2ray_optput=0
	fi
fi
v2ray_v=`v2ray -version | grep V2Ray`
nvram set v2ray_v="$v2ray_v"
if [ "$v2ray_http_enable" = "1" ] && [ ! -z "$v2ray_http_config" ] ; then
	[ "$v2ray_http_format" = "1" ] && su_cmd2="$v2ray_path -format json -config $v2ray_http_config"
	[ "$v2ray_http_format" = "2" ] && su_cmd2="$v2ray_path -format pb  -config $v2ray_http_config"
else
	if [ "$mk_mode_routing" != "0" ]  ; then
	json_mk_ipt2socks
	else
	cp -f /etc/storage/v2ray_config_script.sh /tmp/vmess/mk_vmess.json
	json_join_gfwlist
	fi
	if [ ! -f "/tmp/vmess/mk_vmess.json" ] || [ ! -s "/tmp/vmess/mk_vmess.json" ] ; then
	logger -t "【v2ray】" "错误！实际运行配置： /tmp/vmess/mk_vmess.json 文件内容为空"
	logger -t "【v2ray】" "启动失败,10 秒后自动尝试重新启动"
	sleep 10 && v2ray_restart x
	fi
	chmod 777 /tmp/vmess
	chmod 777 /tmp/vmess/mk_vmess.json
	chmod 777 /etc/storage/v2ray_config_script.sh
	chmod 777 /opt/bin
	chmod 777 /opt/bin/v2ray_config.pb
	[ ! -f /opt/bin/v2ray_config.pb ] && su_cmd2="$v2ray_path -config /tmp/vmess/mk_vmess.json -format json"
	[ -f /opt/bin/v2ray_config.pb ] && su_cmd2="$v2ray_path -config /opt/bin/v2ray_config.pb -format pb"
fi
eval "$su_cmd" '"cmd_name=v2ray && '"$su_cmd2"' $cmd_log"' &
sleep 4
restart_dhcpd
[ ! -z "$(ps -w | grep "$v2ray_path" | grep -v grep )" ] && logger -t "【v2ray】" "启动成功 $v2ray_v " && v2ray_restart o
[ -z "$(ps -w | grep "$v2ray_path" | grep -v grep )" ] && logger -t "【v2ray】" "启动失败,10 秒后自动尝试重新启动" && sleep 10 && v2ray_restart x

initopt


if [ "$v2ray_follow" = "1" ] ; then
flush_r

# 透明代理
logger -t "【v2ray】" "启动 透明代理"
logger -t "【v2ray】" "备注：默认配置的透明代理会导致广告过滤失效，需要手动改造配置前置代理过滤软件"
if [ ! -z "$(grep '"port": 8053' /etc/storage/v2ray_config_script.sh)" ] ; then
	logger -t "【v2ray】" "配置含内置 DNS outbound 功能，让 V2Ray 充当 DNS 服务。"
	chinadns_enable=0 && nvram set app_1=0
	nvram set app_102=0
	Sh09_chinadns_ng.sh
	Sh19_chinadns.sh
fi
if [ "$chinadns_enable" != "0" ] && [ "$chinadns_port" = "8053" ] ; then
logger -t "【v2ray】" "chinadns 已经启动 防止域名污染"
else
pidof dnsproxy >/dev/null 2>&1 && killall dnsproxy && killall -9 dnsproxy 2>/dev/null
pidof pdnsd >/dev/null 2>&1 && killall pdnsd && killall -9 pdnsd 2>/dev/null
if [ -z "$(grep '"port": 8053' /etc/storage/v2ray_config_script.sh)" ] ; then
logger -t "【v2ray】" "启动 dnsproxy 防止域名污染"
if [ -s /sbin/dnsproxy ] ; then
	/sbin/dnsproxy -d
else
	dnsproxy -d
fi
fi
#防火墙转发规则加载
sed -Ei '/no-resolv|server=|server=127.0.0.1#8053|dns-forward-max=1000|min-cache-ttl=1800/d' /etc/storage/dnsmasq/dnsmasq.conf
cat >> "/etc/storage/dnsmasq/dnsmasq.conf" <<-\EOF
no-resolv
server=127.0.0.1#8053
dns-forward-max=1000
min-cache-ttl=1800
EOF
fi

restart_dhcpd

logger -t "【v2ray】" "载入 透明代理 转发规则设置"
#载入iptables模块
for module in ip_set ip_set_bitmap_ip ip_set_bitmap_ipmac ip_set_bitmap_port ip_set_hash_ip ip_set_hash_ipport ip_set_hash_ipportip ip_set_hash_ipportnet ip_set_hash_net ip_set_hash_netport ip_set_list_set xt_set xt_TPROXY
do
	modprobe $module
done 

# rules规则
json_gen_special_purpose_ip
ipset -! restore <<-EOF 
create ss_spec_dst_sp hash:net hashsize 64
$(gen_special_purpose_ip | sed -e "s/^/add ss_spec_dst_sp /")
EOF

# 加载 nat 规则
include_ac_rules nat
iptables -t nat -A SS_SPEC_WAN_FW -p tcp -j REDIRECT --to-ports $v2ray_door
get_wifidognx
gen_prerouting_rules nat tcp $wifidognx
# iptables -t nat -I OUTPUT -p tcp -j SS_SPEC_V2RAY_LAN_DG
# iptables -t nat -D OUTPUT -p tcp -j SS_SPEC_V2RAY_LAN_DG



if [ -z "$(grep '"port": 8053' /etc/storage/v2ray_config_script.sh)" ] ; then
iptables -t nat -I OUTPUT -p tcp -d 8.8.8.8,8.8.4.4 --dport 53 -j REDIRECT --to-ports $v2ray_door
iptables -t nat -I OUTPUT -p tcp -d 208.67.222.222,208.67.220.220 --dport 443 -j REDIRECT --to-ports $v2ray_door
fi

# 同时将代理规则应用到 OUTPUT 链, 让路由自身流量走透明代理
NUM=`iptables -m owner -h 2>&1 | grep owner | wc -l`
hash su 2>/dev/null && su_x="1"
hash su 2>/dev/null || su_x="0"
if [ "$NUM" -ge "3" ] && [ "$v2ray_optput" = 1 ] && [ "$su_x" = "1" ] ; then

# logger -t "【v2ray】" "支持游戏模式（UDP转发）"
# 加载 mangle 规则
# ip rule add fwmark 1 table 100
# ip route add local 0.0.0.0/0 dev lo table 100
# include_ac_rules mangle
# iptables -t mangle -A SS_SPEC_WAN_FW -p udp -j TPROXY --on-port $v2ray_door --tproxy-mark 1
# get_wifidognx_mangle
# gen_prerouting_rules mangle udp $wifidognx

logger -t "【v2ray】" "同时将透明代理规则应用到 OUTPUT 链, 让路由自身流量走透明代理"
	iptables -t nat -D OUTPUT -m owner ! --uid-owner 777 -p tcp -j SS_SPEC_V2RAY_LAN_DG
	iptables -t nat -A OUTPUT -m owner ! --uid-owner 777 -p tcp -j SS_SPEC_V2RAY_LAN_DG
fi
	logger -t "【v2ray】" "完成 透明代理 转发规则设置"
	gen_include &

# 透明代理
fi

v2ray_get_status
eval "$scriptfilepath keep &"
exit 0
}

gen_include() {
[ -n "$FWI" ] || return 0
cat <<-CAT >>$FWI
iptables-restore -n <<-EOF
$(iptables-save | sed  "s/webstr--url/webstr --url/g" | grep -E "$TAG|^\*|^COMMIT" |sed -e "s/^-A \(OUTPUT\|PREROUTING\)/-I \1 1/")
EOF
CAT
return $?
}

gen_prerouting_rules() {
	iptables -t $1 -I PREROUTING $3 -p $2 -j SS_SPEC_V2RAY_LAN_DG
}

flush_r() {
	[ -n "$FWI" ] && echo '#!/bin/sh' >$FWI
	iptables-save -c | sed  "s/webstr--url/webstr --url/g" | grep -v "SS_SPEC" | iptables-restore -c
	ip rule del fwmark 1 table 100 2>/dev/null
	ip route del local 0.0.0.0/0 dev lo table 100 2>/dev/null
	for setname in $(ipset -n list | grep -i "SS_SPEC"); do
		ipset destroy $setname 2>/dev/null
	done
	v2ray_door_tmp=`nvram get v2ray_door_tmp`
	[ -z $v2ray_door_tmp ] && v2ray_door_tmp=$v2ray_door && nvram set v2ray_door_tmp=$v2ray_door_tmp
	iptables -t nat -D OUTPUT -p tcp -d 8.8.8.8,8.8.4.4 --dport 53 -j REDIRECT --to-ports $v2ray_door_tmp
	iptables -t nat -D OUTPUT -p tcp -d 208.67.222.222,208.67.220.220 --dport 443 -j REDIRECT --to-ports $v2ray_door_tmp
	[ "$v2ray_door_tmp"x != "$v2ray_door"x ] && v2ray_door_tmp=$v2ray_door && nvram set v2ray_door_tmp=$v2ray_door_tmp
	iptables -t nat -D OUTPUT -p tcp -d 8.8.8.8,8.8.4.4 --dport 53 -j REDIRECT --to-ports $v2ray_door
	iptables -t nat -D OUTPUT -p tcp -d 208.67.222.222,208.67.220.220 --dport 443 -j REDIRECT --to-ports $v2ray_door
	iptables -t nat -D OUTPUT -p tcp -d 8.8.8.8,8.8.4.4 --dport 53 -j REDIRECT --to-ports 1090
	iptables -t nat -D OUTPUT -p tcp -d 208.67.222.222,208.67.220.220 --dport 443 -j REDIRECT --to-ports 1090
	iptables -t nat -D OUTPUT -p tcp -d 8.8.8.8,8.8.4.4 --dport 53 -j REDIRECT --to-ports 1091
	iptables -t nat -D OUTPUT -p tcp -d 208.67.222.222,208.67.220.220 --dport 443 -j REDIRECT --to-ports 1091
	iptables -t nat -D OUTPUT -p tcp -d 8.8.8.8,8.8.4.4 --dport 53 -j RETURN
	iptables -t nat -D OUTPUT -p tcp -d 208.67.222.222,208.67.220.220 --dport 443 -j RETURN
	if [ "$chinadns_enable" = "0" ] || [ "$chinadns_port" != "8053" ] ; then
		sed -Ei '/no-resolv|server=|server=127.0.0.1#8053|dns-forward-max=1000|min-cache-ttl=1800/d' /etc/storage/dnsmasq/dnsmasq.conf
	fi
	[ "$ss_enable" != "1" ] && sed -Ei '/github|ipip.net/d' /etc/storage/dnsmasq/dnsmasq.conf
	restart_dhcpd
	return 0
}

gen_special_purpose_ip() {
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
$lan_ipaddr
$ss_s1_ip
$ss_s2_ip
$kcptun_server
$v2ray_server_addresses
EOF
}

#-A SS_SPEC_V2RAY_LAN_DG -p tcp -m multiport --dports 8118,3000,18309 -j RETURN

include_ac_rules() {
	iptables-restore -n <<-EOF
*$1
:SS_SPEC_V2RAY_LAN_DG - [0:0]
:SS_SPEC_WAN_FW - [0:0]
-A SS_SPEC_V2RAY_LAN_DG -m mark --mark 0xff -j RETURN
-A SS_SPEC_V2RAY_LAN_DG -m set --match-set ss_spec_dst_sp dst -j RETURN
-A SS_SPEC_V2RAY_LAN_DG -j SS_SPEC_WAN_FW
COMMIT
EOF

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
	#	wifidognx=`expr $wifidogn + 1`
	#fi
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

initopt () {
optPath=`grep ' /opt ' /proc/mounts | grep tmpfs`
[ ! -z "$optPath" ] && return
if [ ! -z "$(echo $scriptfilepath | grep -v "/opt/etc/init")" ] && [ -s "/opt/etc/init.d/rc.func" ] ; then
	{ echo '#!/bin/sh' ; echo $scriptfilepath '"$@"' '&' ; } > /opt/etc/init.d/$scriptname && chmod 777  /opt/etc/init.d/$scriptname
fi

}

initconfig () {

	if [ ! -f "/etc/storage/v2ray_script.sh" ] || [ ! -s "/etc/storage/v2ray_script.sh" ] ; then
cat > "/etc/storage/v2ray_script.sh" <<-\VVR
#!/bin/sh
# 启动前运行的脚本
export PATH='/etc/storage/bin:/tmp/script:/etc/storage/script:/opt/usr/sbin:/opt/usr/bin:/opt/sbin:/opt/bin:/usr/local/sbin:/usr/sbin:/usr/bin:/sbin:/bin'
export LD_LIBRARY_PATH=/lib:/opt/lib
server_addresses=$(cat /etc/storage/v2ray_config_script.sh | tr -d ' ' | grep -Eo '"address":.+' | grep -v 8.8.8.8 | grep -v 114.114.114.114 | sed -n '1p' | cut -d':' -f2 | cut -d'"' -f2)
v2ray_door=`nvram get v2ray_door`
[ -z $v2ray_door ] && v2ray_door=1099 && nvram set v2ray_door=1099
lan_ipaddr=`nvram get lan_ipaddr`


VVR
fi
[ ! -f "/etc/storage/v2ray_config_script.sh" ] && touch /etc/storage/v2ray_config_script.sh

}

initconfig



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

down_gfwlist() {
mkdir -p /tmp/vmess
if [ ! -s "/tmp/vmess/r.gfwlist.conf" ] ; then
wgetcurl_checkmd5 /tmp/vmess/gfwlist.b64 https://raw.githubusercontent.com/gfwlist/gfwlist/master/gfwlist.txt https://raw.githubusercontent.com/gfwlist/gfwlist/master/gfwlist.txt N
	base64 -d  /tmp/vmess/gfwlist.b64 > /tmp/vmess/gfwlist.txt
	cat /tmp/vmess/gfwlist.txt | sort -u |
	sed '/^$\|@@/d'|
	sed 's#!.\+##; s#|##g; s#@##g; s#http:\/\/##; s#https:\/\/##;' | 
	sed '/\*/d; /apple\.com/d; /sina\.cn/d; /sina\.com\.cn/d; /baidu\.com/d; /byr\.cn/d; /jlike\.com/d; /weibo\.com/d; /zhongsou\.com/d; /youdao\.com/d; /sogou\.com/d; /so\.com/d; /soso\.com/d; /aliyun\.com/d; /taobao\.com/d; /jd\.com/d; /qq\.com/d' |
	sed '/^[0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+$/d' |
	grep '^[0-9a-zA-Z\.-]\+$' | grep '\.' | sed 's#^\.\+##'  | sort -u > /tmp/vmess/gfwlist_domain.txt
touch /tmp/vmess/gfwlist_domain.txt
if [[ "$(cat /tmp/vmess/gfwlist_domain.txt | wc -l)" -lt 1000 ]] ; then
	logger -t "【v2ray】" "下载失败！ gfwlist.txt 数据不足1000条"
	logger -t "【v2ray】" "使用内置 gfwlist_domain"
	rm -f /tmp/vmess/gfwlist_domain.txt
fi
touch /etc/storage/shadowsocks_mydomain_script.sh /tmp/vmess/gfwlist_domain.txt
cat /etc/storage/shadowsocks_mydomain_script.sh | sed '/^$\|#/d' | sed "s/http://g" | sed "s/https://g" | sed "s/\///g" | sort -u > /tmp/vmess/gfwlist_0.txt
cat /etc/storage/basedomain.txt /tmp/vmess/gfwlist_0.txt /tmp/vmess/gfwlist_domain.txt | 
	sort -u > /tmp/vmess/gfwall_domain.txt
cat /tmp/vmess/gfwall_domain.txt | sort -u | grep -v "^$" | grep '\.' | grep -v '\-\-\-' > /tmp/vmess/all_domain.txt
rm -f /tmp/vmess/gfw*
awk '{printf("\,\"%s\"", $1, $1 )}' /tmp/vmess/all_domain.txt > /tmp/vmess/r.gfwlist.conf
rm -f /tmp/vmess/all_domain.txt
fi
}

json_join_gfwlist() {
[ -z "$(grep gfwall.com /tmp/vmess/mk_vmess.json)" ] && return
if [ "$mk_mode_x" = "0" ] || [ "$mk_mode_x" = "1" ] ; then
mkdir -p /tmp/vmess
if [ ! -s "/tmp/vmess/r.gfwlist.conf" ] ; then
touch /etc/storage/shadowsocks_mydomain_script.sh /tmp/vmess/gfwlist_domain.txt
cat /etc/storage/shadowsocks_mydomain_script.sh | sed '/^$\|#/d' | sed "s/http://g" | sed "s/https://g" | sed "s/\///g" | sort -u > /tmp/vmess/gfwlist_0.txt
cat /etc/storage/basedomain.txt /tmp/vmess/gfwlist_0.txt /tmp/vmess/gfwlist_domain.txt | 
	sort -u > /tmp/vmess/gfwall_domain.txt
cat /tmp/vmess/gfwall_domain.txt | sort -u | grep -v "^$" | grep '\.' | grep -v '\-\-\-' > /tmp/vmess/all_domain.txt
rm -f /tmp/vmess/gfw*
awk '{printf("\,\"%s\"", $1, $1 )}' /tmp/vmess/all_domain.txt > /tmp/vmess/r.gfwlist.conf
rm -f /tmp/vmess/all_domain.txt
fi
[ -s "/tmp/vmess/r.gfwlist.conf" ] && [ -s "/tmp/vmess/mk_vmess.json" ] && sed -Ei 's@"gfwall.com",@"services.googleapis.cn","googleapis.cn"'"$(cat /tmp/vmess/r.gfwlist.conf)"',@g'  /tmp/vmess/mk_vmess.json
fi
}


json_gen_special_purpose_ip() {
ss_s1_ip=""
ss_s2_ip=""
kcptun_server=""
v2ray_server_addresses=""
server_addresses=$(cat /etc/storage/v2ray_config_script.sh | tr -d ' ' | grep -Eo '"address":.+' | grep -v 8.8.8.8 | grep -v 114.114.114.114 | sed -n '1p' | cut -d':' -f2 | cut -d'"' -f2)
#处理肯定不走通道的目标网段
kcptun_server=`nvram get kcptun_server`
kcptun_enable=`nvram get kcptun_enable`
[ -z $kcptun_enable ] && kcptun_enable=0 && nvram set kcptun_enable=0
[ "$kcptun_enable" = "0" ] && kcptun_server=""
if [ "$kcptun_enable" != "0" ] ; then
if [ -z $(echo $kcptun_server | grep : | grep -v "\.") ] ; then 
resolveip=`/usr/bin/resolveip -4 -t 4 $kcptun_server | grep -v : | sed -n '1p'`
[ -z "$resolveip" ] && resolveip=`/usr/bin/resolveip -6 -t 4 $kcptun_server | grep : | sed -n '1p'`
[ -z "$resolveip" ] && resolveip=`arNslookup $kcptun_server | sed -n '1p'` 
[ -z "$resolveip" ] && resolveip=`arNslookup6 $kcptun_server | sed -n '1p'` 
kcptun_server=$resolveip
else
# IPv6
kcptun_server=$kcptun_server
fi
fi
ss_server1=`nvram get ss_server1`
if [ "$ss_enable" != "0" ] && [ ! -z "$ss_server1" ] ; then
if [ -z $(echo $ss_server1 | grep : | grep -v "\.") ] ; then 
resolveip=`/usr/bin/resolveip -4 -t 4 $ss_server1 | grep -v : | sed -n '1p'`
[ -z "$resolveip" ] && resolveip=`/usr/bin/resolveip -6 -t 4 $ss_server1 | grep : | sed -n '1p'`
[ -z "$resolveip" ] && resolveip=`arNslookup $ss_server1 | sed -n '1p'` 
[ -z "$resolveip" ] && resolveip=`arNslookup6 $ss_server1 | sed -n '1p'` 
ss_s1_ip=$resolveip
else
# IPv6
ss_s1_ip=$ss_server1
fi
fi
ss_server2=`nvram get ss_server2`
if [ "$ss_enable" != "0" ] && [ ! -z "$ss_server2" ] ; then
if [ -z $(echo $ss_server2 | grep : | grep -v "\.") ] ; then 
resolveip=`/usr/bin/resolveip -4 -t 4 $ss_server2 | grep -v : | sed -n '1p'`
[ -z "$resolveip" ] && resolveip=`/usr/bin/resolveip -6 -t 4 $ss_server2 | grep : | sed -n '1p'`
[ -z "$resolveip" ] && resolveip=`arNslookup $ss_server2 | sed -n '1p'` 
[ -z "$resolveip" ] && resolveip=`arNslookup6 $ss_server2 | sed -n '1p'` 
ss_s2_ip=$resolveip
else
# IPv6
ss_s2_ip=$ss_server2
fi
fi
[ ! -z "$vmess_link_add" ] && server_addresses="$vmess_link_add"
[ ! -z "$ss_link_add" ] && server_addresses="$ss_link_add"
if [ ! -z "$server_addresses" ] ; then
	resolveip=`/usr/bin/resolveip -4 -t 4 $server_addresses | grep -v : | sed -n '1p'`
	[ -z "$resolveip" ] && resolveip=`arNslookup $server_addresses | sed -n '1p'` 
	[ -z "$resolveip" ] && resolveip=`arNslookup6 $server_addresses | sed -n '1p'` 
	server_addresses=$resolveip
	v2ray_server_addresses="$server_addresses"
else
	v2ray_server_addresses=""
fi
}

json_jq_check () {

if [[ "$(jq -h 2>&1 | wc -l)" -lt 2 ]] ; then
	logger -t "【v2ray】" "找不到 jq，安装 opt 程序"
	/tmp/script/_mountopt start
if [[ "$(jq -h 2>&1 | wc -l)" -lt 2 ]] ; then
	wgetcurl_file /opt/bin/jq "$hiboyfile/jq" "$hiboyfile2/jq"
if [[ "$(jq -h 2>&1 | wc -l)" -lt 2 ]] ; then
	logger -t "【v2ray】" "找不到 jq，安装 opt 程序"
	rm -f /opt/bin/jq
	/tmp/script/_mountopt optwget
if [[ "$(jq -h 2>&1 | wc -l)" -lt 2 ]] ; then
	opkg update
	opkg install jq
if [[ "$(jq -h 2>&1 | wc -l)" -lt 2 ]] ; then
	logger -t "【v2ray】" "找不到 jq，需要手动安装 opt 后输入[opkg update; opkg install jq]安装"
	return 1
fi
fi
fi
fi
fi
}

json_int_ipt2socks () {
echo '{
  "log": {
    "error": "/tmp/syslog.log",
    "loglevel": "error"
  },
  "inbounds": [
    {
      "port": 1088,
      "listen": "192.168.123.1",
      "protocol": "socks",
      "settings": {
        "auth": "noauth",
        "udp": true,
        "ip": "192.168.123.1"
      },
      "tag": "local_1088",
      "sniffing": {
        "enabled": false,
        "destOverride": [
          "http",
          "tls"
        ]
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "",
      "settings": {},
      "tag": "outbound_1",
      "streamSettings": {
        "network": "",
        "security": "",
        "tlsSettings": {},
        "tcpSettings": {},
        "kcpSettings": {},
        "wsSettings": {},
        "httpSettings": {},
        "dsSettings": {},
        "quicSettings": {},
        "sockopt": {
          "mark": 255
        }
      }
    }
  ],
  "routing": {
    "domainStrategy": "AsIs",
    "balancers": [],
    "rules": [
      {
        "type": "field",
        "inboundTag": [
          "local_1088"
        ],
        "outboundTag": "outbound_1"
      }
    ]
  }
}
'

}

json_mk_ipt2socks () {
mkdir -p /tmp/vmess
echo "" > /tmp/vmess/mk_vmess.json
if [ "$mk_mode_routing" != "1" ] ; then
	return
fi
if [[ "$(jq -h 2>&1 | wc -l)" -lt 2 ]] ; then
json_jq_check
if [[ "$(jq -h 2>&1 | wc -l)" -lt 2 ]] ; then
	return 1
fi
fi
logger -t "【vmess】" "开始生成 ipt2socks 配置"
mk_ipt2socks=$(json_int_ipt2socks)
mk_ipt2socks=$(echo $mk_ipt2socks| jq --raw-output 'setpath(["inbounds",0,"listen"];"'$lan_ipaddr'")')
mk_ipt2socks=$(echo $mk_ipt2socks| jq --raw-output 'setpath(["inbounds",0,"settings","ip"];"'$lan_ipaddr'")')
logger -t "【vmess】" "提取 outbounds 生成 ipt2socks 配置"
mk_config="$(cat /etc/storage/v2ray_config_script.sh | jq --raw-output '.')"
#mk_config_0=$(echo $mk_config| jq --raw-output 'getpath(["outbounds",0])')
mk_config_0=$(echo $mk_config| jq --raw-output '.outbounds[] | select(.protocol == "vmess")')
if [ -z "$mk_config_0" ] ; then
mk_config_0=$(echo $mk_config| jq --raw-output '.outbounds[] | select(.protocol == "shadowsocks")')
fi
if [ -z "$mk_config_0" ] ; then
mk_config_0=$(echo $mk_config| jq --raw-output '.outbounds[] | select(.protocol == "socks")')
fi
if [ -z "$mk_config_0" ] ; then
mk_config_0=$(echo $mk_config| jq --raw-output '.outbounds[] | select(.protocol == "http")')
fi
if [ -z "$mk_config_0" ] ; then
mk_config_0=$(echo $mk_config| jq --raw-output '.outbounds[] | select(.protocol == "mtproto")')
fi
if [ -z "$mk_config_0" ] ; then
logger -t "【vmess】" "错误 outbounds 提出失败，请填写配正确的出站协议！vmess、shadowsocks、socks、http、mtproto"
return
fi
mk_ipt2socks=$(echo $mk_ipt2socks| jq --raw-output 'setpath(["outbounds",0];'"$mk_config_0"')')
mk_ipt2socks=$(echo $mk_ipt2socks| jq --raw-output 'setpath(["outbounds",0,"tag"];"outbound_1")')
echo $mk_ipt2socks | jq --raw-output '.' > /tmp/vmess/mk_vmess.json
if [ ! -s /tmp/vmess/mk_vmess.json ] ; then
	logger -t "【vmess】" "错误！生成透明代理路由规则使用 ipt2socks 方式的 V2Ray 配置为空，请看看哪里问题？"
else
	logger -t "【vmess】" "完成！生成透明代理路由规则使用 ipt2socks 方式的 V2Ray 配置，"
fi

}

json_mk_vmess () {
mkdir -p /tmp/vmess
vmess_x_tmp="`nvram get app_82`"
if [ "$vmess_x_tmp" != "vmess" ] && [ "$vmess_x_tmp" != "ss" ] ; then
	return
fi
if [ "$vmess_x_tmp" != "0" ] ; then
nvram set app_82="0"
fi


if [[ "$(jq -h 2>&1 | wc -l)" -lt 2 ]] ; then
json_jq_check
if [[ "$(jq -h 2>&1 | wc -l)" -lt 2 ]] ; then
	return 1
fi
fi

if [ "$vmess_x_tmp" = "vmess" ] ; then
logger -t "【vmess】" "开始生成vmess配置"
json_mk_vmess_settings
mk_vmess=$(json_int)
mk_vmess=$(echo $mk_vmess| jq --raw-output 'setpath(["outbounds",0,"settings"];'"$vmess_settings"')')
mk_vmess=$(echo $mk_vmess| jq --raw-output 'setpath(["outbounds",0,"streamSettings"];'"$vmess_streamSettings"')')
mk_vmess=$(echo $mk_vmess| jq --raw-output 'setpath(["outbounds",0,"protocol"];"vmess")')
fi
if [ "$vmess_x_tmp" = "ss" ] ; then
ss_link_method=`nvram get app_78`
if [ "$ss_link_method" == "aes-256-cfb" ] || [ "$ss_link_method" == "aes-128-cfb" ] || [ "$ss_link_method" == "chacha20" ] || [ "$ss_link_method" == "chacha20-ietf" ] || [ "$ss_link_method" == "aes-256-gcm" ] || [ "$ss_link_method" == "aes-128-gcm" ] || [ "$ss_link_method" == "chacha20-poly1305" ] || [ "$ss_link_method" == "chacha20-ietf-poly1305" ] ; then
logger -t "【vmess】" "开始生成ss配置"
else
logger -t "【vmess】" "ss配置加密方式不兼容V2Ray"
logger -t "【vmess】" "V2Ray兼容加密方式列表"
logger -t "【vmess】" "aes-256-cfb"
logger -t "【vmess】" "aes-128-cfb"
logger -t "【vmess】" "chacha20"
logger -t "【vmess】" "chacha20-ietf"
logger -t "【vmess】" "aes-256-gcm"
logger -t "【vmess】" "aes-128-gcm"
logger -t "【vmess】" "chacha20-poly1305 或 chacha20-ietf-poly1305"
logger -t "【vmess】" "停止生成ss配置"
return
fi
json_mk_ss_settings
mk_vmess=$(json_int)
mk_vmess=$(echo $mk_vmess| jq --raw-output 'setpath(["outbounds",0,"settings"];'"$vmess_settings"')')
mk_vmess=$(echo $mk_vmess| jq --raw-output 'setpath(["outbounds",0,"streamSettings"];'"$vmess_streamSettings"')')
mk_vmess=$(echo $mk_vmess| jq --raw-output 'setpath(["outbounds",0,"protocol"];"shadowsocks")')
fi
mk_vmess=$(echo $mk_vmess| jq --raw-output 'setpath(["inbounds",0,"listen"];"'$lan_ipaddr'")')
mk_vmess=$(echo $mk_vmess| jq --raw-output 'setpath(["inbounds",0,"settings","ip"];"'$lan_ipaddr'")')
json_gen_special_purpose_ip
[ ! -z "$ss_s1_ip" ] && mk_vmess=$(echo $mk_vmess| jq --raw-output 'setpath(["routing","rules",4,"ip",0];"'$ss_s1_ip'")')
[ ! -z "$ss_s2_ip" ] && mk_vmess=$(echo $mk_vmess| jq --raw-output 'setpath(["routing","rules",4,"ip",1];"'$ss_s2_ip'")')
[ ! -z "$kcptun_server" ] && mk_vmess=$(echo $mk_vmess| jq --raw-output 'setpath(["routing","rules",4,"ip",2];"'$kcptun_server'")')
[ ! -z "$v2ray_server_addresses" ] && mk_vmess=$(echo $mk_vmess| jq --raw-output 'setpath(["routing","rules",4,"ip",3];"'$v2ray_server_addresses'")')
mk_mode_x="`nvram get app_69`"
if [ "$mk_mode_x" = "0" ] ; then
logger -t "【vmess】" "方案一chnroutes，国外IP走代理"
mk_vmess=$(echo $mk_vmess| jq --raw-output 'setpath(["routing","domainStrategy"];"IPIfNonMatch")')
mk_vmess=$(echo $mk_vmess| jq --raw-output 'setpath(["routing","rules",7,"domain",2];"geosite:google")')
mk_vmess=$(echo $mk_vmess| jq --raw-output 'setpath(["routing","rules",7,"domain",3];"geosite:facebook")')
mk_vmess=$(echo $mk_vmess| jq --raw-output 'setpath(["routing","rules",7,"domain",4];"geosite:geolocation-!cn")')
mk_vmess=$(echo $mk_vmess| jq --raw-output 'delpaths([["routing","rules",10]])')
fi
if [ "$mk_mode_x" = "1" ] ; then
logger -t "【vmess】" "方案二gfwlist（推荐），只有被墙的站点IP走代理"
mk_vmess=$(echo $mk_vmess| jq --raw-output 'setpath(["routing","domainStrategy"];"AsIs")')
mk_vmess=$(echo $mk_vmess| jq --raw-output 'setpath(["routing","rules",7,"domain",2];"geosite:google")')
mk_vmess=$(echo $mk_vmess| jq --raw-output 'setpath(["routing","rules",7,"domain",3];"geosite:facebook")')
mk_vmess=$(echo $mk_vmess| jq --raw-output 'setpath(["routing","rules",7,"domain",4];"geosite:geolocation-!cn")')
mk_vmess=$(echo $mk_vmess| jq --raw-output 'delpaths([["routing","rules",10]])')
mk_vmess=$(echo $mk_vmess| jq --raw-output 'delpaths([["routing","rules",9]])')
mk_vmess=$(echo $mk_vmess| jq --raw-output 'delpaths([["routing","rules",8]])')
mk_vmess_0=$(echo $mk_vmess| jq --raw-output 'getpath(["outbounds",0])')
mk_vmess_1=$(echo $mk_vmess| jq --raw-output 'getpath(["outbounds",1])')
mk_vmess=$(echo $mk_vmess| jq --raw-output 'setpath(["outbounds",0];'"$mk_vmess_1"')')
mk_vmess=$(echo $mk_vmess| jq --raw-output 'setpath(["outbounds",1];'"$mk_vmess_0"')')
fi
if [ "$mk_mode_x" = "3" ] ; then
logger -t "【vmess】" "方案四回国模式，国内IP走代理"
mk_vmess=$(echo $mk_vmess| jq --raw-output 'setpath(["routing","domainStrategy"];"IPIfNonMatch")')
mk_vmess=$(echo $mk_vmess| jq --raw-output 'setpath(["routing","rules",8,"outboundTag"];"outbound_1")')
mk_vmess=$(echo $mk_vmess| jq --raw-output 'delpaths([["routing","rules",11]])')
mk_vmess=$(echo $mk_vmess| jq --raw-output 'delpaths([["routing","rules",9]])')
mk_vmess=$(echo $mk_vmess| jq --raw-output 'delpaths([["routing","rules",7]])')
mk_vmess_0=$(echo $mk_vmess| jq --raw-output 'getpath(["outbounds",0])')
mk_vmess_1=$(echo $mk_vmess| jq --raw-output 'getpath(["outbounds",1])')
mk_vmess=$(echo $mk_vmess| jq --raw-output 'setpath(["outbounds",0];'"$mk_vmess_1"')')
mk_vmess=$(echo $mk_vmess| jq --raw-output 'setpath(["outbounds",1];'"$mk_vmess_0"')')
fi
if [ "$mk_mode_x" = "2" ] ; then
logger -t "【vmess】" "方案三全局代理，全部IP走代理"
mk_vmess=$(echo $mk_vmess| jq --raw-output 'setpath(["routing","domainStrategy"];"IPIfNonMatch")')
mk_vmess=$(echo $mk_vmess| jq --raw-output 'delpaths([["routing","rules",11]])')
mk_vmess=$(echo $mk_vmess| jq --raw-output 'delpaths([["routing","rules",10]])')
mk_vmess=$(echo $mk_vmess| jq --raw-output 'delpaths([["routing","rules",9]])')
mk_vmess=$(echo $mk_vmess| jq --raw-output 'delpaths([["routing","rules",8]])')
mk_vmess=$(echo $mk_vmess| jq --raw-output 'delpaths([["routing","rules",7]])')
else
mk_vmess=$(echo $mk_vmess| jq --raw-output 'delpaths([["routing","rules",6]])')
fi
if [ "$mk_mode_b" = "0" ] ; then
mk_vmess=$(echo $mk_vmess| jq --raw-output 'delpaths([["routing","rules",5]])')
fi
if [ "$mk_mode_dns" = "0" ] ; then
mk_vmess=$(echo $mk_vmess| jq --raw-output 'delpaths([["inbounds",2]])')
mk_vmess=$(echo $mk_vmess| jq --raw-output 'delpaths([["routing","rules",0]])')
else
mk_vmess=$(echo $mk_vmess| jq --raw-output 'delpaths([["dns","servers",4]])')
fi
echo $mk_vmess| jq --raw-output '.' > /tmp/vmess/mk_vmess.json
if [ ! -s /tmp/vmess/mk_vmess.json ] ; then
	logger -t "【vmess】" "错误！生成配置为空，请看看哪里问题？"
else
	logger -t "【vmess】" "完成！生成配置，请刷新web页面查看！（应用新配置需按F5）"
	cp -f /tmp/vmess/mk_vmess.json /etc/storage/v2ray_config_script.sh
fi

}

json_mk_vmess_settings () {

vmess_link_v=`nvram get app_71`
vmess_link_ps=`nvram get app_72`
vmess_link_add=`nvram get app_73`
vmess_link_port=`nvram get app_74`
vmess_link_id=`nvram get app_75`
vmess_link_aid=`nvram get app_76`
vmess_link_net=`nvram get app_77`
vmess_link_type=`nvram get app_78`
vmess_link_host=`nvram get app_79`
vmess_link_path=`nvram get app_80`
vmess_link_tls=`nvram get app_81`
v2ray_server_addresses="$vmess_link_add"
[ "$vmess_link_v" -gt 0 ] || vmess_link_v=1
if [ "$vmess_link_v" -lt 2 ] ; then
vmess_link_path=$(echo $vmess_link_host | awk -F '/' '{print $2}')
vmess_link_host=$(echo $vmess_link_host | awk -F '/' '{print $1}')
fi

mk_vmess=$(json_int_vmess_settings)
mk_vmess=$(echo $mk_vmess | jq --raw-output 'setpath(["vnext",0,"address"];"'$vmess_link_add'")')
mk_vmess=$(echo $mk_vmess | jq --raw-output 'setpath(["vnext",0,"users",0,"alterId"];'$vmess_link_aid')')
mk_vmess=$(echo $mk_vmess | jq --raw-output 'setpath(["vnext",0,"users",0,"id"];"'$vmess_link_id'")')
mk_vmess=$(echo $mk_vmess | jq --raw-output 'setpath(["vnext",0,"port"];'$vmess_link_port')')
vmess_settings=$mk_vmess
mk_vmess=$(json_int_vmess_streamSettings)
mk_vmess=$(echo $mk_vmess | jq --raw-output 'setpath(["network"];"'$vmess_link_net'")')
[ ! -z "$vmess_link_tls" ] && mk_vmess=$(echo $mk_vmess | jq --raw-output 'setpath(["security"];"'$vmess_link_tls'")')
# tcp star
if [ "$vmess_link_net" = "tcp" ] ; then
[ ! -z "$vmess_link_type" ] && mk_vmess=$(echo $mk_vmess | jq --raw-output 'setpath(["tcpSettings","type"];"'$vmess_link_type'")')
vmess_link_path=$(echo $vmess_link_path | sed 's/,/ /g')
link_path_i=0
for link_path in $vmess_link_path
do
	mk_vmess=$(echo $mk_vmess | jq --raw-output 'setpath(["tcpSettings","request","path",'$link_path_i'];"'$link_path'")')
	link_path_i=$(( link_path_i + 1 ))
done
vmess_link_host=$(echo $vmess_link_host | sed 's/,/ /g')
link_host_i=0
for link_host in $vmess_link_host
do
	mk_vmess=$(echo $mk_vmess | jq --raw-output 'setpath(["tcpSettings","request","headers","Host",'$link_host_i'];"'$link_host'")')
	link_host_i=$(( link_host_i + 1 ))
done
fi
# tcp end
# kcp star
if [ "$vmess_link_net" = "kcp" ] ; then
[ ! -z "$vmess_link_type" ] && mk_vmess=$(echo $mk_vmess | jq --raw-output 'setpath(["kcpSettings","header","type"];"'$vmess_link_type'")')
fi
# kcp end
# ws star
if [ "$vmess_link_net" = "ws" ] ; then
[ ! -z "$vmess_link_path" ] && mk_vmess=$(echo $mk_vmess | jq --raw-output 'setpath(["wsSettings","path"];"'$vmess_link_path'")')
[ ! -z "$vmess_link_host" ] && mk_vmess=$(echo $mk_vmess | jq --raw-output 'setpath(["wsSettings","headers","Host"];"'$vmess_link_host'")')
fi
# ws end
# h2 star
if [ "$vmess_link_net" = "http" ] ; then
[ ! -z "$vmess_link_path" ] && mk_vmess=$(echo $mk_vmess | jq --raw-output 'setpath(["httpSettings","path"];"'$vmess_link_path'")')
vmess_link_host=$(echo $vmess_link_host | sed 's/,/ /g')
link_host_i=0
for link_host in $vmess_link_host
do
	mk_vmess=$(echo $mk_vmess | jq --raw-output 'setpath(["httpSettings","host",'$link_host_i'];"'$link_host'")')
	link_host_i=$(( link_host_i + 1 ))
done
fi
# h2 end
# quic star
if [ "$vmess_link_net" = "quic" ] ; then
[ ! -z "$vmess_link_type" ] && mk_vmess=$(echo $mk_vmess | jq --raw-output 'setpath(["quicSettings","header","type"];"'$vmess_link_type'")')
[ ! -z "$vmess_link_host" ] && mk_vmess=$(echo $mk_vmess | jq --raw-output 'setpath(["quicSettings","security"];"'$vmess_link_host'")')
[ ! -z "$vmess_link_path" ] && mk_vmess=$(echo $mk_vmess | jq --raw-output 'setpath(["quicSettings","key"];"'$vmess_link_path'")')
fi
# quic end
vmess_streamSettings=$mk_vmess

}

json_int_vmess_settings () {
echo '{
  "vnext": [
    {
      "address": "127.0.0.1",
      "port": 37192,
      "users": [
        {
          "id": "27848739-7e62-4138-9fd3-098a63964b6b",
          "alterId": 4,
          "security": "auto"
        }
      ]
    }
  ]
}
'
}

  # "tlsSettings": {
    # "allowInsecure": true,
    # "allowInsecureCiphers": true
  # },

json_int_vmess_streamSettings () {
echo '{
  "network": "",
  "security": "",
  "tlsSettings": {},
  "tcpSettings": {
    "type": "none",
    "request": {
      "path": [
        "/"
      ],
      "headers": {
        "Host": []
      }
    }
  },
  "kcpSettings": {
    "header": {
      "type": "none"
    }
  },
  "wsSettings": {
    "path": "/",
    "headers": {}
  },
  "httpSettings": {
    "host": [
      "v2ray.com"
    ],
    "path": "/"
  },
  "dsSettings": {},
  "quicSettings": {
    "security": "none",
    "key": "",
    "header": {
      "type": "none"
    }
  },
  "sockopt": {
    "mark": 255
  }
}
'
}

json_mk_ss_settings () {

ss_link_add=`nvram get app_73`
ss_link_port=`nvram get app_74`
ss_link_password=`nvram get app_75`
ss_link_method=`nvram get app_78`
ss_link_ota=`nvram get app_79`
v2ray_server_addresses="$ss_link_add"
mk_vmess=$(json_int_ss_settings)
mk_vmess=$(echo $mk_vmess | jq --raw-output 'setpath(["servers",0,"address"];"'$ss_link_add'")')
mk_vmess=$(echo $mk_vmess | jq --raw-output 'setpath(["servers",0,"port"];'$ss_link_port')')
mk_vmess=$(echo $mk_vmess | jq --raw-output 'setpath(["servers",0,"password"];"'$ss_link_password'")')
mk_vmess=$(echo $mk_vmess | jq --raw-output 'setpath(["servers",0,"method"];"'$ss_link_method'")')
[ "$ss_link_ota" != "0" ] && mk_vmess=$(echo $mk_vmess | jq --raw-output 'setpath(["servers",0,"ota"];"true")')
vmess_settings=$mk_vmess
vmess_streamSettings=$(json_int_ss_streamSettings)
}

json_int_ss_settings () {
echo '{
  "servers": [
    {
      "address": "127.0.0.1",
      "port": 1234,
      "method": "chacha20-poly1305",
      "password": "test",
      "ota": false
    }
  ]
}'
}
json_int_ss_streamSettings () {
echo '{
  "sockopt": {
    "mark": 255
  }
}
'
}

json_int () {
echo '{
  "log": {
    "error": "/tmp/syslog.log",
    "loglevel": "error"
  },
  "inbounds": [
    {
      "port": 1088,
      "listen": "192.168.123.1",
      "protocol": "socks",
      "settings": {
        "auth": "noauth",
        "udp": true,
        "ip": "192.168.123.1"
      },
      "tag": "local_1088",
      "sniffing": {
        "enabled": true,
        "destOverride": [
          "http",
          "tls"
        ]
      }
    },
    {
      "port": "1099",
      "listen": "0.0.0.0",
      "protocol": "dokodemo-door",
      "settings": {
        "network": "tcp,udp",
        "timeout": 30,
        "followRedirect": true
      },
      "tag": "redir_1099",
      "sniffing": {
        "enabled": true,
        "destOverride": [
          "http",
          "tls"
        ]
      }
    },
    {
      "port": 8053,
      "tag": "dns_in",
      "protocol": "dokodemo-door",
      "settings": {
        "address": "8.8.8.8",
        "port": 53,
        "network": "tcp,udp"
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "",
      "settings": {},
      "tag": "outbound_1",
      "streamSettings": {
        "network": "",
        "security": "",
        "tlsSettings": {},
        "tcpSettings": {},
        "kcpSettings": {},
        "wsSettings": {},
        "httpSettings": {},
        "dsSettings": {},
        "quicSettings": {},
        "sockopt": {
          "mark": 255
        }
      }
    },
    {
      "protocol": "freedom",
      "settings": {},
      "tag": "direct",
      "streamSettings": {
        "sockopt": {
          "mark": 255
        }
      }
    },
    {
      "protocol": "blackhole",
      "settings": {},
      "tag": "blocked",
      "streamSettings": {
        "sockopt": {
          "mark": 255
        }
      }
    },
    {
      "protocol": "dns",
      "tag": "dns_out"
    }
  ],
  "dns": {
    "servers": [
      {
        "address": "8.8.8.8",
        "port": 53,
        "domains": [
          "domain:cn2qq.com",
          "geosite:google",
          "geosite:geolocation-!cn"
        ]
      },
      {
        "address": "114.114.114.114",
        "port": 53,
        "domains": [
          "geosite:cn"
        ]
      },
      "8.8.8.8",
      "8.8.4.4",
      "localhost"
    ]
  },
  "routing": {
    "domainStrategy": "AsIs",
    "balancers": [],
    "rules": [
      {
        "inboundTag": ["dns_in"],
        "outboundTag": "dns_out",
        "type": "field"
      },
      {
        "type": "field",
        "outboundTag": "blocked",
        "domain": [
          "geosite:category-ads-all"
        ]
      },
      {
        "type": "field",
        "ip": [
          "127.0.0.0/8",
          "::1/128"
        ],
        "outboundTag": "blocked"
      },
      {
        "type": "field",
        "ip": [
          "8.8.8.8",
          "8.8.4.4",
          "208.67.222.222",
          "208.67.220.220",
          "1.1.1.1",
          "1.0.0.1"
        ],
        "outboundTag": "outbound_1"
      },
      {
        "type": "field",
        "ip": [
          "1.2.3.4",
          "1.2.3.4",
          "1.2.3.4",
          "1.2.3.4",
          "geoip:private",
          "100.100.100.100/32",
          "188.188.188.188/32",
          "110.110.110.110/32"
        ],
        "outboundTag": "direct"
      },
      {
        "type": "field",
        "inboundTag": [
          "local_1088"
        ],
        "outboundTag": "outbound_1"
      },
      {
        "type": "field",
        "inboundTag": [
          "redir_1099"
        ],
        "outboundTag": "outbound_1"
      },
      {
        "type": "field",
        "domain": [
          "gfwall.com",
          "cn2qq.com"
        ],
        "outboundTag": "outbound_1"
      },
      {
        "type": "field",
        "domain": [
          "domain:baidu.com",
          "domain:qq.com",
          "domain:taobao.com",
          "geosite:cn"
        ],
        "outboundTag": "direct"
      },
      {
        "type": "field",
        "ip": [
          "geoip:cn"
        ],
        "outboundTag": "direct"
      },
      {
        "type": "field",
        "ip": [
          "geoip:cn"
        ],
        "outboundTag": "outbound_1"
      },
      {
        "type": "field",
        "ip": [
          "149.154.160.1/32",
          "149.154.160.2/31",
          "149.154.160.4/30",
          "149.154.160.8/29",
          "149.154.160.16/28",
          "149.154.160.32/27",
          "149.154.160.64/26",
          "149.154.160.128/25",
          "149.154.161.0/24",
          "149.154.162.0/23",
          "149.154.164.0/22",
          "149.154.168.0/21",
          "91.108.4.0/22",
          "91.108.56.0/24",
          "109.239.140.0/24",
          "67.198.55.0/24",
          "91.108.56.172",
          "149.154.175.50",
          "149.154.160.0/20"
        ],
        "outboundTag": "outbound_1"
      }
    ]
  }
}
'

}

ping_vmess_link () {

vmess_x_tmp="`nvram get app_83`"
if [ "$vmess_x_tmp" != "ping_link" ] ; then
	return
fi
if [ ! -z "$vmess_x_tmp" ] ; then
nvram set app_83=""
fi
[ ! -f /www/link/vmess.js ] && logger -t "【vmess】" "错误！找不到 /www/link/vmess.js" && return 1
ilox="$(grep -v '^\]'  /www/link/vmess.js | grep -v "ACL3List = " |wc -l)"
[ "$ilox" == "0" ] && ilox="$(grep -v '^\]'  /www/link/ss.js | grep -v "ACL4List = " |wc -l)"
[ "$ilox" == "0" ] && logger -t "【ping】" "错误！节点列表为空" && return
logger -t "【ping】" "开始 ping"
allping 3
allping 4
logger -t "【ping】" "完成 ping 请按【F5】刷新 web 查看 ping"


}
allping () {

[ "$1" == "3" ] && js_vmess="vmess.js"
[ "$1" == "4" ] && js_vmess="ss.js"
mkdir -p /tmp/allping_$1
rm -f /tmp/allping_$1/?.txt
rm -f /tmp/ping_server_error.txt
touch /tmp/ping_server_error.txt
rm -f /tmp/allping_$1.js
touch /tmp/allping_$1.js
i_x_ping=2
ilox="$(grep -v '^\]'  /www/link/$js_vmess | grep -v "ACL""$1""List = " |wc -l)"
while read line
do
if [ -z "$(echo "$line" | grep "ACL""$1""List = ")" ] && [ -z "$(echo "$line" | grep '^\]')" ] ; then
if [ ! -z "$line" ] ; then
echo "$line" > /tmp/allping_$1/$i_x_ping
fi
i_x_ping=`expr $i_x_ping + 1`
fi
done < /www/link/$js_vmess
while [ "$(ls /tmp/allping_$1 | head -1)" != "" ];
do
x_ping_x $1 &
usleep 100000
i_ping="$(cat /tmp/allping_$1.js | grep -v "^$" |wc -l)"
done
i_x_ping=1
while [ "$i_ping" != "$ilox" ];
do
sleep 1
i_ping="$(cat /tmp/allping_$1.js | grep -v "^$" |wc -l)"
i_x_ping=`expr $i_x_ping + 1`
if [ "$i_x_ping" -gt 30 ] ; then
logger -t "【ping】" "刷新 ping 失败！超时 30 秒！ 请重新按【ping】按钮再次尝试。"
return
fi
done
# 排序节点
rm -f /tmp/allping_$1/?.txt
cat /tmp/allping_$1.js | sort | grep -v "^$" > /tmp/allping_$1/0.txt
echo "var ACL""$1""List = [ " > /tmp/allping_$1/1.txt
while read line
do
echo ${line:4} >> /tmp/allping_$1/1.txt
done < /tmp/allping_$1/0.txt
sed -i "s/\"\]$/\"\],/g" /tmp/allping_$1/1.txt
sed -i "$(cat /tmp/allping_$1/1.txt |wc -l)""s/\"\],$/\"\]/g" /tmp/allping_$1/1.txt
echo "]" >> /tmp/allping_$1/1.txt
cp -f /tmp/allping_$1/1.txt /www/link/$js_vmess
rm -f /tmp/allping_$1/?.txt /tmp/allping_$1.js

}

x_ping_x () {
	
[ "$1" == "3" ] && js_1_ping="4" && js_2_ping="3"
[ "$1" == "4" ] && js_1_ping="3" && js_2_ping="2"
ping_txt_list="$(ls /tmp/allping_$1 | head -1)"
if [ ! -z "$ping_txt_list" ] ; then
ping_list="$(cat /tmp/allping_$1/$ping_txt_list)"
rm -f /tmp/allping_$1/$ping_txt_list
ss_server_x="$(echo $ping_list | cut -d',' -f "$js_1_ping" | sed -e "s@"'"'"\| \|"'\['"@@g")"
ss_server_x="$(base64decode "$ss_server_x")"
if [ ! -z "$ss_server_x" ] ; then
ss_name_x="$(echo $ping_list | cut -d',' -f "$js_2_ping" | sed -e "s@"'"'"\|"'\['"@@g")"
ss_name_x="$(base64decode "$ss_name_x")"
if [ ! -z "$(grep "error_""$ss_server_x""_error" /tmp/ping_server_error.txt)" ] ; then
ping_text=""
else
ping_text=`ping -4 $ss_server_x -w 3 -W 3 -q`
fi
ping_time=`echo $ping_text | awk -F '/' '{print $4}'| awk -F '.' '{print $1}'`
ping_loss=`echo $ping_text | awk -F ', ' '{print $3}' | awk '{print $1}'`
i2log="$(expr $(cat /tmp/allping_$1.js | grep -v "^$" |wc -l) + 1)"
ilog="$(expr $i2log \* 100 / $ilox \* 100 / 100)"
[ "$ilog" -gt 100 ] && ilog=100
if [ ! -z "$ping_time" ] ; then
	echo "ping_$ilog%：$ping_time ms ✔️ $ss_server_x"
	logger -t "【ping_$ilog%】" "$ping_time ms ✔️ $ss_server_x $ss_name_x"
	[ "$ping_time" -le 250 ] && ping_list_btn="btn-success"
	[ "$ping_time" -gt 250 ] && [ "$ping_time" -le 500 ] && ping_list_btn="btn-warning"
	[ "$ping_time" -gt 500 ] && ping_list_btn="btn-danger"
	ping_time2="00000""$ping_time"
	ping_time2="${ping_time2:0-4}"
else
	ping_list_btn="btn-danger"
	echo "ping_$ilog%：>1000 ms ❌ $ss_server_x"
	logger -t "【ping_$ilog%】" ">1000 ms ❌ $ss_server_x $ss_name_x"
	ping_time=">1000"
	ping_time2="1000"
	echo "error_""$ss_server_x""_error" >> /tmp/ping_server_error.txt
fi
if [ ! -z "$(echo $ping_list | grep -E -o \"btn-.+\ ms\",)" ] ; then
	ping_list=$(echo $ping_list | sed "s@"'"'"$(echo $ping_list | grep -E -o \"btn-.+\ ms\", | cut -d',' -f2 | grep -E -o \".+\" | sed -e "s@"'"'"@@g")"'"'"@"'"'"$ping_time ms"'"'"@g")
	ping_list=$(echo $ping_list | sed "s@"'"'"$(echo $ping_list | grep -E -o \"btn-.+\ ms\", | cut -d',' -f1 | grep -E -o \".+\" | sed -e "s@"'"'"@@g")"'"'"@"'"'"$ping_list_btn"'"'"@g")
else
	ping_list=$(echo $ping_list | sed "s@"'", "", "", "'"@"'", "'"$ping_list_btn"'", "'"$ping_time ms"'", "'"@g")
fi
fi
if [ ! -z "$ping_list" ] ; then
ping_list="$ping_time2""$ping_list"
#(
#	flock 161
echo "$ping_list" >> /tmp/allping_$1.js
#) 161>/var/lock/161_flock.lock
fi
fi
}

check_link () {
mkdir -p /etc/storage/link
touch /etc/storage/link/vmess.js
touch /etc/storage/link/ss.js
# 初始化 /etc/storage/link/vmess.js
if [ -f /www/link/vmess.js ] && [ ! -s /www/link/vmess.js ] ; then
	echo "var ACL3List = [ " > /www/link/vmess.js
	echo ']' >> /www/link/vmess.js
fi
if [ -f /www/link/vmess.js ] && [ "$(sed -n 1p /www/link/vmess.js)" != "var ACL3List = [ " ] ; then
	echo "var ACL3List = [ " > /www/link/vmess.js
	echo ']' >> /www/link/vmess.js
fi
# 初始化 /etc/storage/link/ss.js
if [ -f /www/link/ss.js ] && [ ! -s /www/link/ss.js ] ; then
	echo "var ACL4List = [ " > /www/link/ss.js
	echo ']' >> /www/link/ss.js
fi
if [ -f /www/link/ss.js ] && [ "$(sed -n 1p /www/link/ss.js)" != "var ACL4List = [ " ] ; then
	echo "var ACL4List = [ " > /www/link/ss.js
	echo ']' >> /www/link/ss.js
fi
}

start_vmess_link () {

if [ -f /www/link/vmess.js ]  ; then
vmess_x_tmp="`nvram get app_83`"
if [ ! -z "$vmess_x_tmp" ] ; then
nvram set app_83=""
fi
if [ "$vmess_x_tmp" = "del_link" ] ; then
	# 清空上次订阅节点配置
	rm -f /www/link/vmess.js
	echo "var ACL3List = [ " > /www/link/vmess.js
	echo ']' >> /www/link/vmess.js
	rm -f /www/link/ss.js
	echo "var ACL4List = [ " > /www/link/ss.js
	echo ']' >> /www/link/ss.js
	vmess_x_tmp=""
	logger -t "【vmess】" "完成清空上次订阅节点配置 请按【F5】刷新 web 查看"
	return
fi

if [ "$vmess_x_tmp" != "up_link" ] ; then
	return
fi

if [[ "$(jq -h 2>&1 | wc -l)" -lt 2 ]] ; then
json_jq_check
if [[ "$(jq -h 2>&1 | wc -l)" -lt 2 ]] ; then
	return 1
fi
fi

vmess_link="`nvram get app_66`"
vmess_link_up=`nvram get app_67`
vmess_link_ping=`nvram get app_68`
A_restart=`nvram get vmess_link_status`
B_restart=`echo -n "$vmess_link" | md5sum | sed s/[[:space:]]//g | sed s/-//g`
if [ "$A_restart" != "$B_restart" ] ; then
nvram set vmess_link_status=$B_restart
	if [ -z "$vmess_link" ] ; then
		cru.sh d vmess_link_update
		logger -t "【vmess】" "停止 vmess 服务器订阅"
		return
	else
		if [ "$vmess_link_up" != 1 ] ; then
			cru.sh a vmess_link_update "12 */6 * * * $scriptfilepath up_link &" &
			logger -t "【vmess】" "启动 vmess 服务器订阅，添加计划任务 (Crontab)，每6小时更新"
		else
			cru.sh d vmess_link_update
		fi
	fi
fi
if [ -z "$vmess_link" ] ; then
	return
fi


logger -t "【vmess】" "服务器订阅：开始更新"

vmess_link="$(echo "$vmess_link" | tr , \  | sed 's@  @ @g' | sed 's@  @ @g' | sed 's@^ @@g' | sed 's@ $@@g' )"
vmess_link_i=""
[ -f /www/link/vmess.js ] && echo "var ACL3List = [ " > /www/link/vmess.js && echo ']' >> /www/link/vmess.js
[ -f /www/link/ss.js ] && echo "var ACL4List = [ " > /www/link/ss.js && echo ']' >> /www/link/ss.js
if [ ! -z "$(echo "$vmess_link" | awk -F ' ' '{print $2}')" ] ; then
	for vmess_link_ii in $vmess_link
	do
		vmess_link_i="$vmess_link_ii"
		do_link
	done
else
	vmess_link_i="$vmess_link"
	do_link
fi
sed -Ei "s@]]@]@g" /www/link/vmess.js
sed -Ei '/^\]|^$/d' /www/link/vmess.js
echo ']' >> /www/link/vmess.js;
sed -Ei "s@]]@]@g" /www/link/ss.js
sed -Ei '/^\]|^$/d' /www/link/ss.js
echo ']' >> /www/link/ss.js;
logger -t "【vmess】" "服务器订阅：更新完成"
if [ "$vmess_link_ping" != 1 ] ; then
	nvram set app_83="ping_link"
	ping_vmess_link
else
	echo "🔗$ss_link_name：停止ping订阅节点"
fi
return
fi
}

# 🔐📐|📐🔐
if [ -z "$( grep "🔐📐" /www/link_d.js )" ] ; then
name_base64=0
else
name_base64=1
fi

base64encode () {
# 转码
if [ "$name_base64" == 0 ] ; then
echo -n "$1"
else
# 转换base64
echo -n "🔐📐$(echo -n "$1" | sed ":a;N;s/\n//g;ta" | base64 | sed -e "s/\//_/g" | sed -e "s/\+/-/g" | sed 's/&==//g' | sed ":a;N;s/\n//g;ta")📐🔐"
fi
}

base64decode () {
# 解码
if [ ! -z "$(echo -n "$1" | grep "🔐📐")" ] ; then
	# 转换base64
	base64decode_tmp="$(echo -n "$1" | sed -e "s/🔗|🔐📐|📐🔐//g" | sed -e "s/_/\//g" | sed -e "s/-/\+/g" | sed 's/$/&==/g' | base64 -d | sed ":a;N;s/\n//g;ta")"
	if [ ! -z "$(echo -n "$1" | grep "🔗")" ] ; then
		echo -n "🔗$base64decode_tmp"
	else
		echo -n "$base64decode_tmp"
	fi
else
	echo -n "$1"
fi
}

get_emoji () {

if [ "$name_base64" == 0 ] ; then
echo -n "$1" \
 | sed -e 's@#@♯@g' \
 | sed -e 's@\r@_@g' \
 | sed -e 's@\n@_@g' \
 | sed -e 's@,@，@g' \
 | sed -e 's@+@➕@g' \
 | sed -e 's@=@＝@g' \
 | sed -e 's@|@丨@g' \
 | sed -e "s@%@％@g" \
 | sed -e "s@\^@∧@g" \
 | sed -e 's@/@／@g' \
 | sed -e 's@\\@＼@g' \
 | sed -e "s@<@《@g" \
 | sed -e "s@>@》@g" \
 | sed -e 's@;@；@g' \
 | sed -e 's@`@▪️@g' \
 | sed -e 's@:@：@g' \
 | sed -e 's@!@❗️@g' \
 | sed -e 's@*@﹡@g' \
 | sed -e 's@?@❓@g' \
 | sed -e 's@\$@💲@g' \
 | sed -e 's@(@（@g' \
 | sed -e 's@)@）@g' \
 | sed -e 's@{@『@g' \
 | sed -e 's@}@』@g' \
 | sed -e 's@\[@【@g' \
 | sed -e 's@\]@】@g' \
 | sed -e 's@&@﹠@g' \
 | sed -e "s@'@▫️@g" \
 | sed -e 's@"@”@g'
 
# | sed -e 's@ @_@g'
else
echo -n "$1"
fi
}

add_ss_link () {
link="$1"
if [ ! -z "$(echo -n "$link" | grep '#')" ] ; then
ss_link_name_url=$(echo -n $link | awk -F '#' '{print $2}')
ss_link_name="$(get_emoji "$(printf $(echo -n $ss_link_name_url | sed 's/\\/\\\\/g;s/\(%\)\([0-9a-fA-F][0-9a-fA-F]\)/\\x\2/g'))"| sed -n '1p')"
link=$(echo -n $link | awk -F '#' '{print $1}')
fi
if [ ! -z "$(echo -n "$link" | grep '@')" ] ; then
	#不将主机名和端口号解析为Base64URL
	#ss://cmM0LW1kNTpwYXNzd2Q=@192.168.100.1:8888/?plugin=obfs-local%3Bobfs%3Dhttp#Example2
	link3=$(echo -n $link | sed -n '1p' | awk -F '@' '{print $1}' | sed -e "s/_/\//g" | sed -e "s/-/\+/g" | sed 's/$/&==/g' | base64 -d )
	link4=$(echo -n $link | sed -n '1p' | awk -F '@' '{print $2}')
	link2="$link3""@""$link4"
else
	#部分信息解析为Base64URL
	#ss://cmM0LW1kNTpwYXNzd2RAMTkyLjE2OC4xMDAuMTo4ODg4Lz9wbHVnaW49b2Jmcy1sb2NhbCUzQm9iZnMlM0RodHRw==#Example2
	link2=$(echo -n $link | sed -n '1p' | sed -e "s/_/\//g" | sed -e "s/-/\+/g" | sed 's/$/&==/g' | base64 -d)
	
fi
ex_params="$(echo -n $link2 | sed -n '1p' | awk -F '/\\?' '{print $2}')"
if [ ! -z "$ex_params" ] ; then
	#存在插件
	ex_obfsparam="$(echo -n "$ex_params" | grep -Eo "plugin=[^&]*"  | cut -d '=' -f2)";
	ex_obfsparam=$(printf $(echo -n $ex_obfsparam | sed 's/\\/\\\\/g;s/\(%\)\([0-9a-fA-F][0-9a-fA-F]\)/\\x\2/g'))
	ss_link_plugin_opts=" -O origin -o plain --plugin ""$(echo -n "$ex_obfsparam" |  sed -e 's@;@ --plugin-opts @')"
	link2="$(echo -n $link2 | sed -n '1p' | awk -F '/\\?' '{print $1}')"
else
	ss_link_plugin_opts=" -O origin -o plain "
fi

ss_link_methodpassword=$(echo -n $link2 | sed -n '1p' | awk -F '@' '{print $1}')
ss_link_usage=$(echo -n $link2 | sed -n '1p' | awk -F '@' '{print $2}')

[ -z "$ss_link_name" ] && ss_link_name="♯"$(echo -n "$ss_link_usage" | cut -d ':' -f1)
ss_link_name="$(echo "$ss_link_name"| sed -n '1p')"
ss_link_server=$(echo -n "$ss_link_usage" | cut -d ':' -f1)
ss_link_port=`echo -n "$ss_link_usage" | cut -d ':' -f2 `
ss_link_password=$(echo -n "$ss_link_methodpassword"  | cut -d ':' -f2 )
ss_link_method=`echo -n "$ss_link_methodpassword" | cut -d ':' -f1 `

}

add_ssr_link () {
link="$1"
ex_params="$(echo -n $link | sed -n '1p' | awk -F '/\\?' '{print $2}')"
ex_obfsparam="$(echo -n "$ex_params" | grep -Eo "obfsparam=[^&]*"  | cut -d '=' -f2 | sed -e "s/_/\//g" | sed -e "s/\-/\+/g" | sed 's/$/&==/g' | base64 -d )"
ex_protoparam="$(echo -n "$ex_params" | grep -Eo "protoparam=[^&]*"  | cut -d '=' -f2 | sed -e "s/_/\//g" | sed -e "s/\-/\+/g" | sed 's/$/&==/g' | base64 -d )"
ex_remarks="$(echo -n "$ex_params" | grep -Eo "remarks[^&]*"  | cut -d '=' -f2 | sed -e "s/_/\//g" | sed -e "s/\-/\+/g" | sed 's/$/&==/g' | base64 -d )"
#ex_group="$(echo -n "$ex_params" | grep -Eo "group[^&]*"  | cut -d '=' -f2 | sed -e "s/_/\//g" | sed -e "s/\-/\+/g" | sed 's/$/&==/g' | base64 -d )"

[ ! -z "$ex_remarks" ] && ss_link_name="$(get_emoji "$(echo -n "$ex_remarks" | sed -e ":a;N;s/\n/_/g;ta" )")"
ss_link_usage="$(echo -n $link | sed -n '1p' | awk -F '/\\?' '{print $1}')"
[ -z "$ex_remarks" ] && ss_link_name="♯""`echo -n "$ss_link_usage" | cut -d ':' -f1 `"
ss_link_name="$(echo "$ss_link_name"| sed -n '1p')"

ss_link_server=`echo -n "$ss_link_usage" | cut -d ':' -f1 `
ss_link_port=`echo -n "$ss_link_usage" | cut -d ':' -f2 `
ss_link_password=$(echo -n "$ss_link_usage"  | cut -d ':' -f6 | sed -e "s/_/\//g" | sed -e "s/\-/\+/g" | sed 's/$/&==/g' | base64 -d)
ss_link_method=`echo -n "$ss_link_usage" | cut -d ':' -f4 `
ss_link_obfs=`echo -n "$ss_link_usage" | cut -d ':' -f5 ` # -o
if [ "$ss_link_obfs"x = "tls1.2_ticket_fastauth"x ] ; then
	ss_link_obfs="tls1.2_ticket_auth"
fi
ss_link_protocol="$(echo -n "$ss_link_usage" | cut -d ':' -f3)" # -O
[ ! -z "$ex_obfsparam" ] && ss_link_obfsparam=" -g $ex_obfsparam" # -g
[ ! -z "$ex_protoparam" ] && ss_link_protoparam=" -G $ex_protoparam" # -G

}

add_0 () {
ss_link_name=""
ss_link_server=""
ss_link_port=""
ss_link_password=""
ss_link_method=""
ss_link_obfs=""
ss_link_protocol=""
ss_link_obfsparam=""
ss_link_protoparam=""
ss_link_plugin_opts=""
vmess_link_add=""
vmess_link_ps=""
}

do_link () {

mkdir -p /tmp/vmess/link
#logger -t "【vmess】" "订阅文件下载: $vmess_link_i"
rm -f /tmp/vmess/link/0_link.txt
wgetcurl.sh /tmp/vmess/link/0_link.txt "$vmess_link_i" "$vmess_link_i" N
if [ ! -s /tmp/vmess/link/0_link.txt ] ; then
	rm -f /tmp/vmess/link/0_link.txt
	wget -T 5 -t 3 --user-agent "$user_agent" -O /tmp/vmess/link/0_link.txt "$vmess_link_i"
fi
if [ ! -s /tmp/vmess/link/0_link.txt ] ; then
	rm -f /tmp/vmess/link/0_link.txt
	curl -L --user-agent "$user_agent" -o /tmp/vmess/link/0_link.txt "$vmess_link_i"
fi
if [ ! -s /tmp/vmess/link/0_link.txt ] ; then
	logger -t "【vmess】" "$vmess_link_i"
	logger -t "【vmess】" "错误！！vmess 服务器订阅文件下载失败！请检查下载地址"
fi
dos2unix /tmp/vmess/link/0_link.txt
sed -e 's@\r@@g' -i /tmp/vmess/link/0_link.txt
sed -e '/^$/d' -i /tmp/vmess/link/0_link.txt
sed -e 's/$/&==/g' -i /tmp/vmess/link/0_link.txt
sed -e "s/_/\//g" -i /tmp/vmess/link/0_link.txt
sed -e "s/\-/\+/g" -i /tmp/vmess/link/0_link.txt
cat /tmp/vmess/link/0_link.txt | grep -Eo [^A-Za-z0-9+/=]+ | tr -d "\n" > /tmp/vmess/link/3_link.txt
if [ -s /tmp/vmess/link/3_link.txt ] ; then
	logger -t "【vmess】" "警告！！vmess 服务器订阅文件下载包含非 BASE64 编码字符！"
	logger -t "【vmess】" "请检查服务器配置和链接："
	logger -t "【vmess】" "$vmess_link_i"
	continue
fi
# 开始解码订阅节点配置
cat /tmp/vmess/link/0_link.txt | grep -Eo [A-Za-z0-9+/=]+ | tr -d "\n" > /tmp/vmess/link/1_link.txt
base64 -d /tmp/vmess/link/1_link.txt > /tmp/vmess/link/2_link.txt
dos2unix /tmp/vmess/link/2_link.txt
sed -e 's@\r@@g' -i /tmp/vmess/link/2_link.txt
sed -e  's@vmess://@\nvmess:://@g' -i /tmp/ss/link/2_link.txt
sed -e  's@ssr://@\nssr://@g' -i /tmp/ss/link/2_link.txt
sed -e  's@ss://@\nss://@g' -i /tmp/ss/link/2_link.txt
sed -e  's@vmess:://@vmess://@g' -i /tmp/ss/link/2_link.txt
sed -e '/^$/d' -i /tmp/ss/link/2_link.txt
echo >> /tmp/vmess/link/2_link.txt
rm -f /tmp/vmess/link/vmess_link.txt /tmp/vmess/link/ss_link.txt /tmp/vmess/link/ssr_link.txt
while read line
do
vmess_line=`echo -n $line | sed -n '1p' |grep 'vmess://'`
if [ ! -z "$vmess_line" ] ; then
	echo  "$vmess_line" | awk -F 'vmess://' '{print $2}' >> /tmp/vmess/link/vmess_link.txt
fi
ss_line=`echo -n $line | sed -n '1p' |grep '^ss://'`
if [ ! -z "$ss_line" ] ; then
	echo  "$ss_line" | awk -F 'ss://' '{print $2}' >> /tmp/vmess/link/ss_link.txt
fi
ssr_line=`echo -n $line | sed -n '1p' |grep '^ssr://'`
if [ ! -z "$ssr_line" ] ; then
	echo  "$ssr_line" | awk -F 'ssr://' '{print $2}' >> /tmp/vmess/link/ssr_link.txt
fi
done < /tmp/vmess/link/2_link.txt
if [ -f /tmp/vmess/link/vmess_link.txt ] ; then
sed -e 's/$/&==/g' -i /tmp/vmess/link/vmess_link.txt
sed -e "s/_/\//g" -i /tmp/vmess/link/vmess_link.txt
sed -e "s/\-/\+/g" -i /tmp/vmess/link/vmess_link.txt
	awk  'BEGIN{FS="\n";}  {cmd=sprintf("echo -n %s|base64 -d", $1);  system(cmd); print "";}' /tmp/vmess/link/vmess_link.txt > /tmp/vmess/link/vmess2_link.txt
	while read line
	do
	if [ ! -z "$line" ] ; then
		vmess_link_add=""
		vmess_link_ps=""
		vmess_link_add="$(echo -n $line | jq --raw-output '.add')"
		vmess_link_ps="$(get_emoji "$(echo -n $line | jq --raw-output '.ps')")"
		vmess_link_ps_en="$(base64encode "$vmess_link_ps")"
		line=$(echo $line | jq --raw-output 'setpath(["ps"];"'"$vmess_link_ps_en"'")')
		# jq 取得数据排序
		link_json=$(echo -n $line | jq --raw-output  '{"v": .v,"ps": .ps,"add": .add,"port": .port,"id": .id,"aid": .aid,"net": .net,"type": .type,"host": .host,"path": .path,"tls": .tls}')
		vmess_link_value="$(echo -n "$link_json" | jq  '.[]' | sed -e ":a;N;s/\n/, /g;ta" )"
		link_echo=""
		link_echo="$link_echo"'["vmess", '
		link_echo="$link_echo"''"$vmess_link_value"', '
		link_echo="$link_echo"'"", '
		link_echo="$link_echo"'"", '
		link_echo="$link_echo"'"end"]]'
		sed -Ei "s@]]@],@g" /www/link/vmess.js
		sed -Ei '/^\]|^$/d' /www/link/vmess.js
		echo "$link_echo" >> /www/link/vmess.js
	fi
	done < /tmp/vmess/link/vmess2_link.txt
fi

if [ -f /tmp/vmess/link/ss_link.txt ] ; then
	#awk  'BEGIN{FS="\n";}  {cmd=sprintf("echo -n %s|base64 -d", $1);  system(cmd); print "";}' /tmp/vmess/link/ss_link.txt > /tmp/vmess/link/ss_link2.txt
	while read line
	do
	if [ ! -z "$line" ] ; then
		add_0
		add_ss_link "$line"
		if [ "$ss_link_method" == "aes-256-cfb" ] || [ "$ss_link_method" == "aes-128-cfb" ] || [ "$ss_link_method" == "chacha20" ] || [ "$ss_link_method" == "chacha20-ietf" ] || [ "$ss_link_method" == "aes-256-gcm" ] || [ "$ss_link_method" == "aes-128-gcm" ] || [ "$ss_link_method" == "chacha20-poly1305" ] || [ "$ss_link_method" == "chacha20-ietf-poly1305" ] ; then
		#echo  $ss_link_name $ss_link_server $ss_link_port $ss_link_password $ss_link_method $ss_link_obfs $ss_link_protocol >> /tmp/vmess/link/c_link.txt
		link_echo=""
		link_echo="$link_echo"'["ss", '
		vmess_link_ps="$ss_link_name"
		ss_link_name="$(base64encode "$ss_link_name")"
		link_echo="$link_echo"'"'"$ss_link_name"'", '
		link_echo="$link_echo"'"'"$ss_link_server"'", '
		vmess_link_add="$ss_link_server"
		link_echo="$link_echo"'"'"$ss_link_port"'", '
		ss_link_password="$(base64encode "$ss_link_password")"
		link_echo="$link_echo"'"'"$ss_link_password"'", '
		link_echo="$link_echo"'"'"$ss_link_method"'", '
		link_echo="$link_echo"'"", '
		link_echo="$link_echo"'"", '
		ss_link_plugin_opts="$(base64encode "$ss_link_plugin_opts")"
		link_echo="$link_echo"'"'"$ss_link_plugin_opts"'", '
		link_echo="$link_echo"'"0", '
		link_echo="$link_echo"'"end"]]'
		sed -Ei "s@]]@],@g" /www/link/ss.js
		sed -Ei '/^\]|^$/d' /www/link/ss.js
		echo "$link_echo" >> /www/link/ss.js
		fi
	fi
	done < /tmp/vmess/link/ss_link.txt
fi

if [ -f /tmp/vmess/link/ssr_link.txt ] ; then
	sed -e 's/$/&==/g' -i /tmp/vmess/link/ssr_link.txt
	sed -e "s/_/\//g" -i /tmp/vmess/link/ssr_link.txt
	sed -e "s/\-/\+/g" -i /tmp/vmess/link/ssr_link.txt
	awk  'BEGIN{FS="\n";}  {cmd=sprintf("echo -n %s|base64 -d", $1);  system(cmd); print "";}' /tmp/vmess/link/ssr_link.txt > /tmp/vmess/link/ss_link2.txt
	while read line
	do
	if [ ! -z "$line" ] ; then
		add_0
		add_ssr_link "$line"
		#SS:-o plain -O origin  
		if [ "$ss_link_obfs" == "plain" ] && [ "$ss_link_protocol" == "origin" ] ; then
		if [ "$ss_link_method" == "aes-256-cfb" ] || [ "$ss_link_method" == "aes-128-cfb" ] || [ "$ss_link_method" == "chacha20" ] || [ "$ss_link_method" == "chacha20-ietf" ] || [ "$ss_link_method" == "aes-256-gcm" ] || [ "$ss_link_method" == "aes-128-gcm" ] || [ "$ss_link_method" == "chacha20-poly1305" ] || [ "$ss_link_method" == "chacha20-ietf-poly1305" ] ; then
		ss_link_plugin_opts=" -O origin -o plain "
		#echo  $ss_link_name $ss_link_server $ss_link_port $ss_link_password $ss_link_method $ss_link_obfs $ss_link_protocol >> /tmp/vmess/link/c_link.txt
		link_echo=""
		link_echo="$link_echo"'["ss", '
		vmess_link_ps="$ss_link_name"
		ss_link_name="$(base64encode "$ss_link_name")"
		link_echo="$link_echo"'"'"$ss_link_name"'", '
		link_echo="$link_echo"'"'"$ss_link_server"'", '
		vmess_link_add="$ss_link_server"
		link_echo="$link_echo"'"'"$ss_link_port"'", '
		ss_link_password="$(base64encode "$ss_link_password")"
		link_echo="$link_echo"'"'"$ss_link_password"'", '
		link_echo="$link_echo"'"'"$ss_link_method"'", '
		link_echo="$link_echo"'"", '
		link_echo="$link_echo"'"", '
		ss_link_plugin_opts="$(base64encode "$ss_link_plugin_opts")"
		link_echo="$link_echo"'"'"$ss_link_plugin_opts"'", '
		link_echo="$link_echo"'"0", '
		link_echo="$link_echo"'"end"]]'
		sed -Ei "s@]]@],@g" /www/link/ss.js
		sed -Ei '/^\]|^$/d' /www/link/ss.js
		echo "$link_echo" >> /www/link/ss.js
		fi
		fi
	fi
	done < /tmp/vmess/link/ss_link2.txt
fi

rm -rf /tmp/vmess/link/*
}

case $ACTION in
start)
	v2ray_close
	v2ray_check
	;;
check)
	v2ray_check
	;;
stop)
	v2ray_close
	;;
keep)
	#v2ray_check
	v2ray_keep
	;;
updatev2ray)
	v2ray_restart o
	[ "$v2ray_enable" = "1" ] && nvram set v2ray_status="updatev2ray" && logger -t "【v2ray】" "重启" && v2ray_restart
	[ "$v2ray_enable" != "1" ] && [ -f "$v2ray_path" ] && nvram set v2ray_v="" && logger -t "【v2ray】" "更新" && { rm -rf $v2ray_path /opt/opt_backup/bin/v2ray ; rm -f /opt/bin/v2ctl /opt/opt_backup/bin/v2ctl ; rm -f /opt/bin/v2ray_config.pb ; rm -f /opt/bin/geoip.dat /opt/opt_backup/bin/geoip.dat ; rm -f /opt/bin/geosite.dat /opt/opt_backup/bin/geosite.dat ; }
	;;
initconfig)
	initconfig
	;;
uplink)
	nvram set app_83="up_link"
	v2ray_check
	;;
up_link)
	nvram set app_83="up_link"
	v2ray_check
	;;
del_link)
	nvram set app_83="del_link"
	v2ray_check
	;;
ping_link)
	nvram set app_83="ping_link"
	v2ray_check
	;;
*)
	v2ray_check
	;;
esac

