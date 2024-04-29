#!/bin/bash
#copyright by hiboy
source /etc/storage/script/init.sh
source /etc/storage/script/sh_link.sh

TAG="SSTP"		  # iptables tag
FWI="/tmp/firewall.v2ray.pdcn"
v2ray_enable=`nvram get v2ray_enable`
[ -z $v2ray_enable ] && v2ray_enable=0 && nvram set v2ray_enable=0
ss_enable=`nvram get ss_enable`
[ -z $ss_enable ] && ss_enable=0 && nvram set ss_enable=0
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
transocks_mode_x=`nvram get app_28`
[ -z $transocks_mode_x ] && transocks_mode_x=0 && nvram set app_28=0
lan_ipaddr=`nvram get lan_ipaddr`
app_default_config=`nvram get app_115`
[ -z $app_default_config ] && app_default_config=0 && nvram set app_115=0
server_addresses=$(cat /etc/storage/v2ray_config_script.sh | tr -d ' ' | grep -Eo '"address":.+' | grep -v 8.8.8.8 | grep -v google.com | grep -v 114.114.114.114 | grep -v 119.29.29.29 | grep -v 223.5.5.5 | sed -n '1p' | cut -d':' -f2 | cut -d'"' -f2)
if [ "$v2ray_enable" != "0" ] ; then
app_74="$(nvram get app_74)"
app_98="$(nvram get app_98)"
app_95="$(nvram get app_95)"
[ -z "$app_95" ] && app_95="." && nvram set app_95="."
ss_matching_enable="$(nvram get ss_matching_enable)"
[ -z $ss_matching_enable ] && ss_matching_enable=0 && nvram set ss_matching_enable=0
if [ "$v2ray_follow" != 0 ] ; then
ss_tproxy_auser=`nvram get ss_tproxy_auser`
	if [ "Sh18_v2ray.sh" != "$ss_tproxy_auser" ] && [ "" != "$ss_tproxy_auser" ] ; then
		logger -t "【v2ray】" "错误！！！由于已启用 $ss_tproxy_auser 透明代理，停止启用 v2ray 透明代理！"
		v2ray_follow=0 && nvram set v2ray_follow=0
	fi
fi
[ "$v2ray_follow" == 0 ] && mk_mode_routing=0
/etc/storage/script/sh_ezscript.sh 3 & #更新按钮状态
ss_udp_enable=`nvram get ss_udp_enable` #udp转发  0、停用；1、启动
[ -z $ss_udp_enable ] && ss_udp_enable=0 && nvram set ss_udp_enable=0
app_114=`nvram get app_114` #0:代理本机流量; 1:跳过代理本机流量
[ -z $app_114 ] && app_114=0 && nvram set app_114=0

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
ss_link_2=`nvram get ss_link_2`
[ -z $ss_link_2 ] && ss_link_2="www.google.com.hk" && nvram set ss_link_2="www.google.com.hk"
ss_link_1=`nvram get ss_link_1`
[ "$ss_link_1" -lt 66 ] && ss_link_1="66" || { [ "$ss_link_1" -ge 66 ] || { ss_link_1="66" ; nvram set ss_link_1="66" ; } ; }
v2ray_path=`nvram get v2ray_path`
[ -z $v2ray_path ] && v2ray_path="/opt/bin/v2ray" && nvram set v2ray_path=$v2ray_path
geoip_path="$(cd "$(dirname "$v2ray_path")"; pwd)/geoip.dat"
geosite_path="$(cd "$(dirname "$v2ray_path")"; pwd)/geosite.dat"
v2ray_door=`nvram get v2ray_door`
[ -z $v2ray_door ] && v2ray_door=1099 && nvram set v2ray_door=1099

v2ray_http_enable=`nvram get v2ray_http_enable`
[ -z $v2ray_http_enable ] && v2ray_http_enable=0 && nvram set v2ray_http_enable=0
v2ray_http_format=`nvram get v2ray_http_format`
[ -z $v2ray_http_format ] && v2ray_http_format=1 && nvram set v2ray_http_format=1
v2ray_http_config=`nvram get v2ray_http_config`
ss_ip46=`nvram get ss_ip46`
[ -z $ss_ip46 ] && ss_ip46=0 && nvram set ss_ip46=0
LAN_AC_IP=`nvram get LAN_AC_IP`
[ -z $LAN_AC_IP ] && LAN_AC_IP=0 && nvram set LAN_AC_IP=$LAN_AC_IP
ss_DNS_Redirect=`nvram get ss_DNS_Redirect`
ss_DNS_Redirect_IP=`nvram get ss_DNS_Redirect_IP`
[ -z "$ss_DNS_Redirect_IP" ] && ss_DNS_Redirect_IP=$lan_ipaddr

if [ ! -z "$(echo $scriptfilepath | grep -v "/tmp/script/" | grep v2ray)" ] && [ ! -s /tmp/script/_v2ray ] ; then
	mkdir -p /tmp/script
	{ echo '#!/bin/bash' ; echo $scriptfilepath '"$@"' '&' ; } > /tmp/script/_v2ray
	chmod 777 /tmp/script/_v2ray
fi

v2ray_restart () {
i_app_restart "$@" -name="v2ray"
}

v2ray_get_status () {

B_restart="$v2ray_enable$ss_udp_enable$app_114$chinadns_ng_enable$ss_link_1$ss_link_2$ss_rebss_n$ss_rebss_a$transocks_mode_x$v2ray_path$v2ray_follow$lan_ipaddr$v2ray_door$v2ray_http_enable$v2ray_http_format$v2ray_http_config$mk_mode_routing$app_default_config$app_74$ss_ip46$(cat /etc/storage/v2ray_script.sh /etc/storage/v2ray_config_script.sh | grep -v '^#' | grep -v '^$')"

i_app_get_status -name="v2ray" -valb="$B_restart"
}

v2ray_check () {

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
		[ ! -z "$(ps -w | grep "$v2ray_path" | grep -v grep )" ] && v2ray_get_releases
		v2ray_close
		v2ray_start
	else
		[ -z "$(ps -w | grep "$v2ray_path" | grep -v grep )" ] && v2ray_restart
		if [ "$v2ray_follow" = "1" ] ; then
			echo v2ray_follow
		fi
	fi
fi
}

v2ray_keep () {
i_app_keep -name="v2ray" -pidof="$(basename $v2ray_path)" -cpath="$v2ray_path" -ps=v2raykeep &
/etc/storage/script/sh_ezscript.sh 3 & #更新按钮状态
sleep 20
ss_link_2=`nvram get ss_link_2`
ss_link_1=`nvram get ss_link_1`
v2ray_enable=`nvram get v2ray_enable`
rebss=`nvram get ss_rebss_b`
[ -z "$rebss" ] &&  rebss=0 && nvram set ss_rebss_b=0
while [ "$v2ray_enable" = "1" ]; do
[ "$(grep "</textarea>"  /etc/storage/app_25.sh | wc -l)" != 0 ] && sed -Ei s@\<\/textarea\>@@g /etc/storage/app_25.sh
	NUM=`ps -w | grep "$v2ray_path" | grep -v grep |wc -l`
	if [ "$NUM" -lt "1" ] || [ ! -s "$v2ray_path" ] ; then
		logger -t "【v2ray】" "重新启动$NUM"
		v2ray_restart
	fi
	v2ray_enable=`nvram get v2ray_enable`
	v2ray_follow=`nvram get v2ray_follow`
	ss_keep_check=`nvram get ss_keep_check`
	app_114=`nvram get app_114`
	if [ "$v2ray_follow" = "1" ] && [ "$ss_keep_check" == "1" ] && [ "$app_114" == 0 ] ; then
# 自动故障转移(透明代理时生效)


ss_rebss_n=`nvram get ss_rebss_n`
ss_rebss_a=`nvram get ss_rebss_a`
if [ "$ss_rebss_n" != 0 ] ; then
	if [ "$rebss" -gt "$ss_rebss_n" ] && [ "$ss_rebss_a" == "0" ] ; then
		nvram set ss_rebss_b=0
		logger -t "【v2ray】" " 网络连接 v2ray 中断 ['$rebss'], 重启v2ray."
		if [ "$rebss" != "0" ] ; then
		rebss="0"
		nvram set ss_rebss_b=0
		fi
		nvram set v2ray_status=0
		eval "$scriptfilepath &"
		sleep 10
		exit 0
	fi
	if [ "$rebss" -gt "$ss_rebss_n" ] && [ "$ss_rebss_a" == "1" ] ; then
		logger -t "【v2ray】" " 网络连接 v2ray 中断 ['$rebss'], 停止v2ray."
		if [ "$rebss" != "0" ] ; then
		rebss="0"
		nvram set ss_rebss_b=0
		fi
		nvram set v2ray_enable=0
		eval "$scriptfilepath &"
		sleep 10
		exit 0
	fi
	if [ "$rebss" -gt "$ss_rebss_n" ] && [ "$ss_rebss_a" == "2" ] ; then
		logger -t "【v2ray】" " 网络连接 v2ray 中断['$rebss'], 重启路由."
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
		logger -t "【v2ray】" " 网络连接 v2ray 中断['$rebss'], 更新订阅."
		if [ "$rebss" != "0" ] ; then
		rebss="0"
		nvram set ss_rebss_b=0
		fi
		sleep 5
		nvram set vmess_link_status=""
		eval "$scriptfilepath up_link &"
	fi
fi
sleep 3
v2ray_enable=`nvram get v2ray_enable`
if [ "$v2ray_enable" != "1" ] ; then
	#跳出当前循环
	exit 
fi

check2=404
check_timeout_network "wget_check"
if [ "$check2" == "404" ] ; then
#404
Sh99_ss_tproxy.sh auser_check "Sh18_v2ray.sh"
Sh99_ss_tproxy.sh s_ss_tproxy_check "Sh18_v2ray.sh"
sleep 5
check2=404
check_timeout_network "wget_check" "check"
fi
if [ "$check2" == "200" ] ; then
#200
	echo "[v2ray_keep] $app_98 have no problem."
	[ "$(nvram get ss_internet)" != "1" ] && nvram set ss_internet="1"
	if [ "$rebss" != "0" ] ; then
	logger -t "【v2ray】" " v2ray 服务器 【$app_98】 恢复正常"
	rebss="0"
	ss_rebss_b="$(nvram get ss_rebss_b)"
	[ "$ss_rebss_b" != "0" ] && nvram set ss_rebss_b=0
	fi
	sleep_rnd
	#跳出当前循环
	continue
fi

#404
[ "$(nvram get ss_internet)" != "0" ] && nvram set ss_internet="0"
[ -z "$rebss" ] && rebss=0
rebss=`expr $rebss + 1`
nvram set ss_rebss_b="$rebss"
logger -t "【v2ray】" " v2ray 服务器 【$app_98】 检测到问题"
#restart_on_dhcpd
#/etc/storage/crontabs_script.sh &

#404
if [ "$ss_matching_enable" == "0" ] ; then
	logger -t "【v2ray】" " v2ray 已启用自动故障转移(透明代理时生效)，若检测 3 次断线则更换节点，当值为 $rebss"
if [ "$rebss" -ge "3" ] ; then
	nvram set ss_rebss_b=0
	[ "$(nvram get ss_internet)" != "2" ] && nvram set ss_internet="2"
	logger -t "【v2ray】" "匹配关键词自动选用节点故障转移 /tmp/link/matching/link_v2_matching.txt"
	eval "$scriptfilepath v2ray_link_v2_matching &"
	sleep 10
	#跳出当前循环
	continue
fi
fi
		sleep 15
	else
		sleep 60
	fi
	v2ray_enable=`nvram get v2ray_enable`
done
}

v2ray_close () {
[ "$(nvram get ss_internet)" != "0" ] && nvram set ss_internet="0"
kill_ps "$scriptname v2raykeep"
kill_ps "$scriptname"
kill_ps "Sh18_v2ray.sh"
sed -Ei '/【v2ray】|^$/d' /tmp/script/_opt_script_check
Sh99_ss_tproxy.sh off_stop "Sh18_v2ray.sh"
[ ! -z "$v2ray_path" ] && kill_ps "$v2ray_path"
killall v2ray v2ray_script.sh
/etc/storage/script/sh_ezscript.sh 3 & #更新按钮状态
kill_ps "/tmp/script/_v2ray"
kill_ps "_v2ray.sh"
kill_ps "$scriptname"
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
if [ "$v2ray_http_enable" != "1" ] ; then
if [ ! -f "/etc/storage/v2ray_config_script.sh" ] || [ ! -s "/etc/storage/v2ray_config_script.sh" ] ; then
logger -t "【v2ray】" "错误！ v2ray 配置文件 内容为空"
if [ "$ss_matching_enable" == "1" ] ; then
logger -t "【v2ray】" "尝试使用上次配置生成"
nvram set app_71="$(nvram get app_72)"
fi
v2ray_restart x
fi
if [ -s "/etc/storage/v2ray_config_script.sh" ] ; then
if [ ! -z "$(cat /etc/storage/v2ray_config_script.sh | grep '"inbound"')" ] || [ ! -z "$(grep '"outbound"'  /etc/storage/v2ray_config_script.sh)" ] ; then
logger -t "【v2ray】" "注意！！！v4.22.0及以上版本不再兼容旧的v2ray json配置格式（如：inbound {}，outbound {}格式。）"
logger -t "【v2ray】" "请尽快使用 inbounds []，outbounds []格式替换。"
if [ ! -z "$(grep '"outbound"'  /etc/storage/v2ray_config_script.sh)" ] ; then
logger -t "【v2ray】" "错误！！！outbound {}格式不兼容【使用 ss_tproxy 分流】。"
logger -t "【v2ray】" "错误！！！outbound {}格式不兼容【使用 ss_tproxy 分流】。 "
logger -t "【v2ray】" "错误！！！outbound {}格式不兼容【使用 ss_tproxy 分流】。  "
fi
fi
fi
fi
[ "$(nvram get ss_internet)" != "2" ] && nvram set ss_internet="2"
if [ ! -s "$v2ray_path" ] ; then
	v2ray_path="/opt/bin/v2ray"
fi
geoip_path="$(cd "$(dirname "$v2ray_path")"; pwd)/geoip.dat"
geosite_path="$(cd "$(dirname "$v2ray_path")"; pwd)/geosite.dat"
chmod 777 "$v2ray_path"
if [ ! -s "$v2ray_path" ] ; then
	[ ! -s "$v2ray_path" ] && logger -t "【v2ray】" "找不到 $v2ray_path，安装 opt 程序"
	/etc/storage/script/Sh01_mountopt.sh start
fi
killall v2ray v2ray_script.sh
optPath="`grep ' /opt ' /proc/mounts | grep tmpfs`"
Mem_total="$(free | sed -n '2p' | awk '{print $2;}')"
[ "$Mem_total" -lt 1024 ] && Mem_total="1024" || { [ "$Mem_total" -ge 1024 ] || Mem_total="1024" ; }
Mem_M=$(($Mem_total / 1024 ))
if [ ! -z "$optPath" ] || [ "$Mem_M" -lt "100" ] ; then
	[ ! -z "$optPath" ] && logger -t "【v2ray】" " /opt/ 在内存储存"
	if [ "$Mem_M" -lt "100" ] ; then
		logger -t "【v2ray】" "内存不足100M"
		if [ "$mk_mode_routing" == "1" ] ; then
			rm -f $geoip_path $geosite_path
			rm -f /opt/bin/geoip.dat /opt/bin/geosite.dat /opt/opt_backup/bin/geoip.dat /opt/opt_backup/bin/geosite.dat
		else
			logger -t "【v2ray】" "建议使用 ss_tproxy 分流(降低负载，适合低配路由)"
		fi
	fi
fi
if [ "$mk_mode_routing" == "1" ] ; then
	logger -t "【v2ray】" "使用 ss_tproxy 分流(降低负载，适合低配路由)"
else
	if [ "$Mem_M" -lt "200" ] ; then
	[ ! -s $geoip_path ] && wgetcurl_checkmd5 $geoip_path "https://testingcf.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@release/geoip-lite.dat" "$hiboyfile/geoip.dat" N
	[ ! -s $geosite_path ] && wgetcurl_checkmd5 $geosite_path "https://testingcf.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@release/geosite-lite.dat" "$hiboyfile/geosite.dat" N
	else
	[ ! -s $geoip_path ] && wgetcurl_checkmd5 $geoip_path "https://testingcf.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@release/geoip.dat" "$hiboyfile/geoip_s.dat" N
	[ ! -s $geosite_path ] && wgetcurl_checkmd5 $geosite_path "https://testingcf.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@release/geosite.dat" "$hiboyfile/geosite_s.dat" N
	fi
fi
if [ ! -s "/etc/ssl/certs/ca-certificates.crt" ] ; then
	mkdir -p /opt/app/ipk/
	mkdir -p /opt/etc/ssl/certs
	rm -f /etc/ssl/certs
	ln -sf /opt/etc/ssl/certs  /etc/ssl/certs
	if [ ! -s "/etc/ssl/certs/ca-certificates.crt" ] && [ -s /etc_ro/certs.tgz ] ; then
		tar -xzvf /etc_ro/certs.tgz -C /opt/etc/ssl/ ; cd /opt
	fi
	if [ ! -s "/etc/ssl/certs/ca-certificates.crt" ] ; then
		logger -t "【opt】" "已挂载,找不到ca-certificates证书"
		logger -t "【opt】" "下载证书"
		wgetcurl.sh /opt/app/ipk/certs.tgz "$hiboyfile/certs.tgz" "$hiboyfile2/certs.tgz"
		[ -s /opt/app/ipk/certs.tgz ] && tar -xzvf /opt/app/ipk/certs.tgz -C /opt/etc/ssl/ ; cd /opt
		if [ ! -s "/etc/ssl/certs/ca-certificates.crt" ] ; then
			wgetcurl.sh /opt/app/ipk/certs.tgz "http://opt.cn2qq.com/opt-file/certs.tgz"
			[ -s /opt/app/ipk/certs.tgz ] && tar -xzvf /opt/app/ipk/certs.tgz -C /opt/etc/ssl/ ; cd /opt
		fi
		if [ ! -s "/etc/ssl/certs/ca-certificates.crt" ] ; then
			wgetcurl.sh /opt/app/ipk/certs.tgz "$(echo -n "$hiboyfile/certs.tgz" | sed -e "s/https:/http:/g")" "$(echo -n "$hiboyfile2/certs.tgz" | sed -e "s/https:/http:/g")"
		fi
		logger -t "【opt】" "安装证书"
		tar -xzvf /opt/app/ipk/certs.tgz -C /opt/etc/ssl/ ; cd /opt
		rm -f /opt/app/ipk/certs.tgz
	fi
	chmod 644 /etc/ssl/certs -R
	chmod 777 /etc/ssl/certs
	chmod 644 /opt/etc/ssl/certs -R
	chmod 777 /opt/etc/ssl/certs
fi
Available_A=$(df -m | grep "% /opt" | awk 'NR==1' | awk -F' ' '{print $4}')
size_tmpfs=`nvram get size_tmpfs`
if [ "$size_tmpfs" = "0" ] && [[ "$Available_A" -lt 15 ]] ; then
mount -o remount,size=60% tmpfs /tmp
Available_B=$(df -m | grep "% /opt" | awk 'NR==1' | awk -F' ' '{print $4}')
logger -t "【v2ray】" "调整 /tmp 挂载分区的大小， /opt 可用空间： $Available_A → $Available_B M"
fi
v2ray_get_releases
if [ "$app_74" == "5" ] || [ "$app_74" == "6" ] ; then
	[[ "$($v2ray_path help 2>&1 | wc -l)" -lt 2 ]] && [ ! -z $v2ray_path ] && rm -rf $v2ray_path
	[ ! -s "$v2ray_path" ] && logger -t "【v2ray】" "自动下载 V2ray-core v5 主程序"
	[ "$app_74" != "6" ] && nvram set app_74="6" && app_74="6"
	i_app_get_cmd_file -name="v2ray" -cmd="$v2ray_path" -cpath="/opt/bin/v2ray" -down1="$hiboyfile/v2ray-v2ray5" -down2="$hiboyfile2/v2ray-v2ray5" -runh="help"
else
	[[ "$($v2ray_path help 2>&1 | wc -l)" -lt 2 ]] && [ ! -z $v2ray_path ] && rm -rf $v2ray_path
	[ ! -s "$v2ray_path" ] && logger -t "【v2ray】" "自动下载 Xray-core 主程序"
	[ "$app_74" != "4" ] && nvram set app_74="4" && app_74="4"
	i_app_get_cmd_file -name="v2ray" -cmd="$v2ray_path" -cpath="/opt/bin/v2ray" -down1="$hiboyfile/v2ray" -down2="$hiboyfile2/v2ray" -runh="help"
fi
v2ray_path="$SVC_PATH"
[ "$(nvram get v2ray_path)" != "$v2ray_path" ] && nvram set v2ray_path=$v2ray_path
if [ -s "$v2ray_path" ] ; then
	logger -t "【v2ray】" "找到 $v2ray_path"
	chmod 777 "$(dirname "$v2ray_path")"
	chmod 777 $v2ray_path
	[ -f $geoip_path ] && chmod 777 $geoip_path
	[ -f $geosite_path ] && chmod 777 $geosite_path
fi
logger -t "【v2ray】" "运行 v2ray_script"
chmod 777 /etc/storage/v2ray_script.sh
chmod 644 /opt/etc/ssl/certs -R
chmod 777 /opt/etc/ssl/certs
chmod 644 /etc/ssl/certs -R
chmod 777 /etc/ssl/certs
/etc/storage/v2ray_script.sh
cd "$(dirname "$v2ray_path")"
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
if [ "$v2ray_follow" = "1" ] ; then
if [ "$ss_udp_enable" = "1" ] || [ "$app_114" = "0" ] ; then
	[ "$su_x" != "1" ] && logger -t "【v2ray】" "缺少 su 命令"
	[ "$NUM" -ge "3" ] || logger -t "【v2ray】" "缺少 iptables -m owner 模块"
	if [ "$NUM" -ge "3" ] && [ "$su_x" = "1" ] ; then
		[ "$ss_udp_enable" = "1" ] && tcponly='false'
	else
		ss_udp_enable=0
		nvram set ss_udp_enable=0
	fi
fi
[ "$ss_udp_enable" = "0" ] && logger -t "【v2ray】" "仅代理 TCP 流量"
[ "$ss_udp_enable" = "1" ] && logger -t "【v2ray】" "代理 TCP 和 UDP 流量"
[ "$app_114" = "0" ] && logger -t "【v2ray】" "启动路由自身流量走透明代理"
[ "$app_114" = "1" ] && logger -t "【v2ray】" "停止路由自身流量走透明代理"
fi
if [ "$v2ray_http_enable" = "1" ] && [ ! -z "$v2ray_http_config" ] ; then
	[ "$v2ray_http_format" = "1" ] && su_cmd2="$v2ray_path -format json -config $v2ray_http_config"
	[ "$v2ray_http_format" = "2" ] && su_cmd2="$v2ray_path -format pb  -config $v2ray_http_config"
	[ "$app_74" == "4" ] && su_cmd2="$v2ray_path run -c $v2ray_http_config"
	[ "$app_74" == "6" ] && su_cmd2="$v2ray_path run -c $v2ray_http_config"
else
	if [ "$app_default_config" = "1" ] ; then
	logger -t "【v2ray】" "不改写配置，直接使用原始配置启动！（有可能端口不匹配导致功能失效）"
	logger -t "【v2ray】" "请手动修改配置，透明代理端口：$v2ray_door"
	echo "" > /tmp/vmess/mk_vmess.json
	cp -f /etc/storage/v2ray_config_script.sh /tmp/vmess/mk_vmess.json
	else
	# 改写配置适配脚本
	if [ "$mk_mode_routing" != "0" ] ; then
	json_mk_ss_tproxy
	else
	echo "" > /tmp/vmess/mk_vmess.json
	cp -f /etc/storage/v2ray_config_script.sh /tmp/vmess/mk_vmess.json
	json_join_gfwlist
	fi
	if [ ! -z "$(cat /etc/storage/v2ray_config_script.sh | grep '"port": 8053')" ] && [ "$v2ray_follow" == "0" ] ; then
		logger -t "【v2ray】" "不是透明代理模式，变更配置含内置 DNS 端口 listen 0.0.0.0:8055"
		sed -Ei s/8053/8055/g /tmp/vmess/mk_vmess.json
	fi
	# 改写错误日志路径
	cat /tmp/vmess/mk_vmess.json | jq --raw-output 'setpath(["log"];{"access": "none","error":"/tmp/syslog.log","loglevel":"error"})' > /tmp/vmess/mk_vmess2.json
	[ -s /tmp/vmess/mk_vmess2.json ] && cp -f /tmp/vmess/mk_vmess2.json /tmp/vmess/mk_vmess.json
	rm -f /tmp/vmess/mk_vmess2.json
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
	su_cmd2="$v2ray_path -config /tmp/vmess/mk_vmess.json -format json"
	[ "$app_74" == "4" ] && su_cmd2="$v2ray_path run -c /tmp/vmess/mk_vmess.json"
	[ "$app_74" == "6" ] && su_cmd2="$v2ray_path run -c /tmp/vmess/mk_vmess.json"
fi
[ "$app_74" == "3" ] && v2ray_v_tmp=`$v2ray_path -version`
[ "$app_74" == "4" ] && v2ray_v_tmp=`$v2ray_path version`
[ "$app_74" == "6" ] && v2ray_v_tmp=`$v2ray_path version`
v2ray_v=`echo "$v2ray_v_tmp" | grep -Eo "^[^(]+" | sed -n '1p'`
nvram set v2ray_v="$v2ray_v"
cd "$(dirname "$v2ray_path")"
eval "$su_cmd" '"export V2RAY_CONF_GEOLOADER=memconservative;cmd_name=v2ray;'"$su_cmd2"' $cmd_log"' &
#eval "$su_cmd2 $cmd_log" &
sleep 4
#restart_on_dhcpd
i_app_keep -t -name="v2ray" -pidof="$(basename $v2ray_path)" -cpath="$v2ray_path"

if [ "$v2ray_follow" = "1" ] ; then

# 透明代理
logger -t "【v2ray】" "启动 透明代理"
logger -t "【v2ray】" "备注：默认配置的透明代理会导致广告过滤失效，需要手动改造配置前置代理过滤软件"
if [ ! -z "$(cat /etc/storage/v2ray_config_script.sh | grep '"port": 8053')" ] && [ "$mk_mode_routing" == "0" ] ; then
	if [ "$chinadns_ng_enable" = "3" ] ; then
	logger -t "【v2ray】" "配置含内置 DNS outbound 功能，让 V2Ray 充当 DNS 服务。"
	chinadns_ng_enable=0 && nvram set app_102=0
	nvram set chinadns_ng_status=""
	Sh09_chinadns_ng.sh stop &
	dns_start_dnsproxy='1' # 1:跳过自动开启第三方 DNS 程序但是继续把DNS绑定到 8053 端口的程序
	else
	dns_start_dnsproxy='0' # 0:自动开启第三方 DNS 程序(dnsproxy) ;
	fi
else
	dns_start_dnsproxy='0' # 0:自动开启第三方 DNS 程序(dnsproxy) ;
fi

Sh99_ss_tproxy.sh auser_check "Sh18_v2ray.sh"
ss_tproxy_set "Sh18_v2ray.sh"
Sh99_ss_tproxy.sh on_start "Sh18_v2ray.sh"
#restart_on_dhcpd

logger -t "【v2ray】" "载入 透明代理 转发规则设置"

# 同时将代理规则应用到 OUTPUT 链, 让路由自身流量走透明代理
if [ "$app_114" = 0 ] ; then
logger -t "【v2ray】" "同时将透明代理规则应用到 OUTPUT 链, 让路由自身流量走透明代理"
fi
logger -t "【v2ray】" "完成 透明代理 转发规则设置"
logger -t "【v2ray】" "启动后若发现一些网站打不开, 估计是 DNS 被污染了. 解决 DNS 被污染方法："
logger -t "【v2ray】" "①电脑设置 DNS 自动获取路由 ip。检查 hosts 是否有错误规则。"
logger -t "【v2ray】" "②电脑运行 cmd 输入【ipconfig /flushdns】, 清理浏览器缓存。"
# 透明代理
fi
[ "$(nvram get ss_internet)" != "1" ] && nvram set ss_internet="1"

v2ray_get_status
eval "$scriptfilepath v2raykeep &"
exit 0
}

ss_tproxy_set() {
ss_tproxy_auser=`nvram get ss_tproxy_auser`
if [ "$1" != "$ss_tproxy_auser" ] ; then
	logger -t "【v2ray】" "脚本 [Sh99_ss_tproxy.sh] 当前使用者: $auser_b ，跳过 $auser_a 的运行命令"
	logger -t "【v2ray】" "需要停用 $auser_b 后才能使用 $auser_a 运行 [Sh99_ss_tproxy.sh] 脚本"
	return
fi
lan_ipaddr=`nvram get lan_ipaddr`
ss_tproxy_mode_x=`nvram get app_110`
[ -z $ss_tproxy_mode_x ] && ss_tproxy_mode_x=0 && nvram set app_110=0
[ "$ss_tproxy_mode_x" = "0" ] && logger -t "【v2ray】" "【自动】设置 ss_tproxy 配置文件，配置导入中..."
[ "$ss_tproxy_mode_x" = "1" ] && logger -t "【v2ray】" "【手动】设置 ss_tproxy 配置文件，跳过配置导入" && return
 # /etc/storage/app_27.sh
[ "$mk_mode_routing" == "1" ] && [ "$transocks_mode_x" == "0" ] && sstp_set mode='chnroute'
[ "$mk_mode_routing" == "1" ] && [ "$transocks_mode_x" == "1" ] && sstp_set mode='gfwlist'
[ "$mk_mode_routing" == "1" ] && [ "$transocks_mode_x" == "2" ] && sstp_set mode='global'
[ "$mk_mode_routing" == "1" ] && [ "$transocks_mode_x" == "3" ] && sstp_set mode='chnlist'
[ "$mk_mode_routing" == "0" ] && sstp_set mode='global'
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
sstp_set proxy_tcpport="$v2ray_door"
sstp_set proxy_udpport="$v2ray_door"
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
[ "$mk_mode_routing" == "1" ] && [ "$transocks_mode_x" == "3" ] && sstp_set dns_direct='8.8.8.8' # 回国模式
[ "$mk_mode_routing" == "1" ] && [ "$transocks_mode_x" == "3" ] && sstp_set dns_direct6='2001:4860:4860::8888' # 回国模式
[ "$mk_mode_routing" == "1" ] && [ "$transocks_mode_x" == "3" ] && sstp_set dns_remote='223.5.5.5#53' # 回国模式
[ "$mk_mode_routing" == "1" ] && [ "$transocks_mode_x" == "3" ] && sstp_set dns_remote6='240C::6666#53' # 回国模式
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
logger -t "【v2ray】" "【自动】设置 ss_tproxy 配置文件，完成配置导入"
}

sleep_rnd () {
#随机延时
ss_link_1=`nvram get ss_link_1`
if [ "$(nvram get ss_internet)" = "1" ] ; then
SEED=`tr -cd 0-9 </dev/urandom | head -c 8`
RND_NUM=`echo $SEED 50 80|awk '{srand($1);printf "%d",rand()*10000%($3-$2)+$2}'`
[ "$RND_NUM" -lt 1 ] && RND_NUM="1" || { [ "$RND_NUM" -ge 1 ] || RND_NUM="1" ; }
sleep $RND_NUM
sleep $ss_link_1
fi
#/etc/storage/script/sh_ezscript.sh 3 & #更新按钮状态
}

initconfig () {

	if [ ! -f "/etc/storage/v2ray_script.sh" ] || [ ! -s "/etc/storage/v2ray_script.sh" ] ; then
cat > "/etc/storage/v2ray_script.sh" <<-\VVR
#!/bin/bash
# 启动前运行的脚本
export PATH='/etc/storage/bin:/tmp/script:/etc/storage/script:/opt/usr/sbin:/opt/usr/bin:/opt/sbin:/opt/bin:/usr/local/sbin:/usr/sbin:/usr/bin:/sbin:/bin'
export LD_LIBRARY_PATH=/lib:/opt/lib
server_addresses=$(cat /etc/storage/v2ray_config_script.sh | tr -d ' ' | grep -Eo '"address":.+' | grep -v 8.8.8.8 | grep -v google.com | grep -v 114.114.114.114 | grep -v 119.29.29.29 | grep -v 223.5.5.5 | sed -n '1p' | cut -d':' -f2 | cut -d'"' -f2)
v2ray_door=`nvram get v2ray_door`
[ -z $v2ray_door ] && v2ray_door=1099 && nvram set v2ray_door=1099
lan_ipaddr=`nvram get lan_ipaddr`


VVR
fi
[ ! -f "/etc/storage/v2ray_config_script.sh" ] && touch /etc/storage/v2ray_config_script.sh

}

initconfig

json_join_gfwlist() {
[ -z "$(cat /tmp/vmess/mk_vmess.json | grep gfwall.com)" ] && return
if [ "$mk_mode_x" = "0" ] || [ "$mk_mode_x" = "1" ] ; then
mkdir -p /tmp/vmess
if [ ! -s "/tmp/vmess/r.gfwlist.conf" ] ; then
touch /etc/storage/shadowsocks_mydomain_script.sh /tmp/vmess/gfwlist_domain.txt
cat /etc/storage/shadowsocks_mydomain_script.sh | sed '/^$\|#/d' | sed "s/http://g" | sed "s/https://g" | sed "s/\///g" | sort -u > /tmp/vmess/gfwlist_0.txt
cat /opt/app/ss_tproxy/rule/gfwlist.txt | sort -u | grep -v '^$' | grep '\.' | grep -v '\-\-\-' >> /tmp/vmess/gfwlist_0.txt
cat /etc/storage/basedomain.txt /tmp/vmess/gfwlist_0.txt /tmp/vmess/gfwlist_domain.txt | 
	sort -u > /tmp/vmess/gfwall_domain.txt
cat /tmp/vmess/gfwall_domain.txt | sort -u | grep -v '^$' | grep '\.' | grep -v '\-\-\-' > /tmp/vmess/all_domain.txt
rm -f /tmp/vmess/gfw*
awk '{printf("\,\"%s\"", $1, $1 )}' /tmp/vmess/all_domain.txt > /tmp/vmess/r.gfwlist.conf
rm -f /tmp/vmess/all_domain.txt
fi
[ -s "/tmp/vmess/r.gfwlist.conf" ] && [ -s "/tmp/vmess/mk_vmess.json" ] && sed -Ei 's@"gfwall.com",@"services.googleapis.cn","googleapis.cn","translate.googleapis.com"'"$(cat /tmp/vmess/r.gfwlist.conf)"',"geosite:facebook","geosite:twitter","geosite:telegram",@g'  /tmp/vmess/mk_vmess.json
fi
}

json_jq_check () {
i_app_get_cmd_file -name="v2ray" -cmd="jq" -cpath="/opt/bin/jq" -down1="$hiboyfile/jq" -down2="$hiboyfile2/jq"
}

json_int_ss_tproxy () {
echo '{
  "log": {
    "access": "none",
    "error": "/tmp/syslog.log",
    "loglevel": "error"
  },
  "inbounds": [
    {
      "port": 1088,
      "listen": "0.0.0.0",
      "protocol": "socks",
      "settings": {
        "auth": "noauth",
        "udp": true,
        "ip": "127.0.0.1"
      },
      "tag": "local_1088",
      "sniffing": {
        "enabled": false,
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
      "streamSettings": {
        "sockopt": {
          "tproxy": "redirect"
        }
      },
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
        "realitySettings": {},
        "tlsSettings": {},
        "xtlsSettings": {},
        "tcpSettings": {},
        "kcpSettings": {},
        "wsSettings": {},
        "httpSettings": {},
        "dsSettings": {},
        "quicSettings": {},
        "grpcSettings": {},
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
    }
  ],
  "routing": {
    "domainStrategy": "IPIfNonMatch",
    "domainMatcher": "mph",
    "balancers": [],
    "rules": [
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
      }
    ]
  }
}
'

}

json_mk_ss_tproxy () {
mkdir -p /tmp/vmess
echo "" > /tmp/vmess/mk_vmess.json
if [ "$mk_mode_routing" != "1" ] ; then
	return
fi
json_jq_check
logger -t "【v2ray】" "开始生成 ss_tproxy 配置"
mk_ss_tproxy=$(json_int_ss_tproxy)
[ "$ss_ip46" != "0" ] && mk_ss_tproxy=$(echo $mk_ss_tproxy| jq --raw-output 'setpath(["inbounds",1,"streamSettings","sockopt","tproxy"];"tproxy")')
mk_ss_tproxy=$(echo $mk_ss_tproxy| jq --raw-output 'setpath(["inbounds",0,"listen"];"0.0.0.0")')
mk_ss_tproxy=$(echo $mk_ss_tproxy| jq --raw-output 'setpath(["inbounds",0,"settings","ip"];"127.0.0.1")')
logger -t "【v2ray】" "提取 outbounds 生成 ss_tproxy 配置"
mk_config="$(cat /etc/storage/v2ray_config_script.sh | jq --raw-output '.')"
#mk_config_0=$(echo $mk_config| jq --raw-output 'getpath(["outbounds",0])')
if [ ! -z "$(echo $mk_config | grep '"protocol": "vmess"')" ] ; then
mk_config_0=$(echo $mk_config| jq --raw-output '.outbounds[] | select(.protocol == "vmess")')
fi
if [ -z "$mk_config_0" ] && [ ! -z "$(echo $mk_config | grep '"protocol": "vless"')" ] ; then
mk_config_0=$(echo $mk_config| jq --raw-output '.outbounds[] | select(.protocol == "vless")')
fi
if [ -z "$mk_config_0" ] && [ ! -z "$(echo $mk_config | grep '"protocol": "shadowsocks"')" ] ; then
mk_config_0=$(echo $mk_config| jq --raw-output '.outbounds[] | select(.protocol == "shadowsocks")')
fi
if [ -z "$mk_config_0" ] && [ ! -z "$(echo $mk_config | grep '"protocol": "trojan"')" ] ; then
mk_config_0=$(echo $mk_config| jq --raw-output '.outbounds[] | select(.protocol == "trojan")')
fi
if [ -z "$mk_config_0" ] && [ ! -z "$(echo $mk_config | grep '"protocol": "socks"')" ] ; then
mk_config_0=$(echo $mk_config| jq --raw-output '.outbounds[] | select(.protocol == "socks")')
fi
if [ -z "$mk_config_0" ] && [ ! -z "$(echo $mk_config | grep '"protocol": "http"')" ] ; then
mk_config_0=$(echo $mk_config| jq --raw-output '.outbounds[] | select(.protocol == "http")')
fi
if [ -z "$mk_config_0" ] && [ ! -z "$(echo $mk_config | grep '"protocol": "mtproto"')" ] ; then
mk_config_0=$(echo $mk_config| jq --raw-output '.outbounds[] | select(.protocol == "mtproto")')
fi
if [ -z "$mk_config_0" ] && [ ! -z "$(echo $mk_config | grep '"protocol": "freedom"')" ] ; then
mk_config_0=$(echo $mk_config| jq --raw-output '.outbounds[] | select(.protocol == "freedom")')
fi
if [ -z "$mk_config_0" ] ; then
logger -t "【v2ray】" "错误 outbounds 提出失败，请填写配正确的出站协议！vmess、vless、shadowsocks、trojan、socks、http、mtproto、freedom"
return
fi
mk_ss_tproxy=$(echo $mk_ss_tproxy| jq --raw-output 'setpath(["outbounds",0];'"$mk_config_0"')')
mk_ss_tproxy=$(echo $mk_ss_tproxy| jq --raw-output 'setpath(["outbounds",0,"tag"];"outbound_1")')
echo $mk_ss_tproxy | jq --raw-output '.' > /tmp/vmess/mk_vmess.json
if [ ! -s /tmp/vmess/mk_vmess.json ] ; then
	logger -t "【v2ray】" "错误！生成透明代理路由规则使用 ss_tproxy 方式的 V2Ray 配置为空，请看看哪里问题？"
else
	logger -t "【v2ray】" "完成！生成透明代理路由规则使用 ss_tproxy 方式的 V2Ray 配置，"
fi

}

json_mk_vmess () {
mkdir -p /tmp/vmess
link_tmp="$(nvram get app_71)"
if [ -z "$link_tmp" ] ; then
	return
fi
nvram set app_71=""


json_jq_check

# 解码获取信息
link_de_protocol "$link_tmp" "0vmess0vless0ss0trojan0"
if [ "$link_protocol" != "vmess" ] && [ "$link_protocol" != "vless" ] && [ "$link_protocol" != "ss" ] && [ "$link_protocol" != "trojan" ] ; then
	return 1
fi
if [ "$link_protocol" == "vmess" ] || [ "$link_protocol" == "vless" ] ; then
logger -t "【v2ray】" "开始生成 $link_protocol 配置"
json_mk_vmess_settings
mk_vmess=$(json_int)
mk_vmess=$(echo $mk_vmess| jq --raw-output 'setpath(["outbounds",0,"settings"];'"$vmess_settings"')')
mk_vmess=$(echo $mk_vmess| jq --raw-output 'setpath(["outbounds",0,"streamSettings"];'"$vmess_streamSettings"')')
mk_vmess=$(echo $mk_vmess| jq --raw-output 'setpath(["outbounds",0,"protocol"];"'"$link_protocol"'")')
fi
if [ "$link_protocol" == "ss" ] ; then
if [ "$ss_link_method" == "aes-256-gcm" ] || [ "$ss_link_method" == "aead_aes_256_gcm" ] || [ "$ss_link_method" == "aes-128-gcm" ] || [ "$ss_link_method" == "aead_aes_128_gcm" ] || [ "$ss_link_method" == "chacha20-poly1305" ] || [ "$ss_link_method" == "aead_chacha20_poly1305" ] || [ "$ss_link_method" == "chacha20-ietf-poly1305" ] || [ "$ss_link_method" == "none" ] || [ "$ss_link_method" == "plain" ] ; then
logger -t "【v2ray】" "开始生成 ss 配置，加密方式： $ss_link_method"
else
logger -t "【v2ray】" "ss配置加密方式不兼容V2Ray"
logger -t "【v2ray】" "V2Ray兼容加密方式列表"
logger -t "【v2ray】" "aes-256-gcm,aead_aes_256_gcm"
logger -t "【v2ray】" "aes-128-gcm,aead_aes_128_gcm"
logger -t "【v2ray】" "chacha20-poly1305,aead_chacha20_poly1305 或 chacha20-ietf-poly1305"
logger -t "【v2ray】" "none 或 plain"
#logger -t "【v2ray】" "停止生成ss配置"
#return
logger -t "【v2ray】" "可以尝试更换 V2Ray 主程序配置兼容加密方式： $ss_link_method"
fi
json_mk_ss_settings
mk_vmess=$(json_int)
mk_vmess=$(echo $mk_vmess| jq --raw-output 'setpath(["outbounds",0,"settings"];'"$vmess_settings"')')
mk_vmess=$(echo $mk_vmess| jq --raw-output 'setpath(["outbounds",0,"streamSettings"];'"$vmess_streamSettings"')')
mk_vmess=$(echo $mk_vmess| jq --raw-output 'setpath(["outbounds",0,"protocol"];"shadowsocks")')
fi
if [ "$link_protocol" == "trojan" ] ; then
logger -t "【v2ray】" "开始生成 $link_protocol 配置"
json_mk_trojan_settings
mk_vmess=$(json_int)
mk_vmess=$(echo $mk_vmess| jq --raw-output 'setpath(["outbounds",0,"settings"];'"$vmess_settings"')')
mk_vmess=$(echo $mk_vmess| jq --raw-output 'setpath(["outbounds",0,"streamSettings"];'"$vmess_streamSettings"')')
mk_vmess=$(echo $mk_vmess| jq --raw-output 'setpath(["outbounds",0,"protocol"];"trojan")')
fi
mk_vmess=$(echo $mk_vmess| jq --raw-output 'setpath(["inbounds",0,"listen"];"0.0.0.0")')
mk_vmess=$(echo $mk_vmess| jq --raw-output 'setpath(["inbounds",0,"settings","ip"];"127.0.0.1")')
mk_mode_x="`nvram get app_69`"
if [ "$mk_mode_x" = "0" ] ; then
logger -t "【v2ray】" "方案一chnroutes，国外IP走代理"
mk_vmess=$(echo $mk_vmess| jq --raw-output 'setpath(["routing","domainStrategy"];"IPIfNonMatch")')
mk_vmess=$(echo $mk_vmess| jq --raw-output 'setpath(["routing","rules",7,"domains",2];"geosite:google")')
mk_vmess=$(echo $mk_vmess| jq --raw-output 'setpath(["routing","rules",7,"domains",3];"geosite:facebook")')
mk_vmess=$(echo $mk_vmess| jq --raw-output 'setpath(["routing","rules",7,"domains",4];"geosite:geolocation-!cn")')
mk_vmess=$(echo $mk_vmess| jq --raw-output 'delpaths([["routing","rules",10]])')
fi
if [ "$mk_mode_x" = "1" ] ; then
logger -t "【v2ray】" "方案二gfwlist（推荐），只有被墙的站点IP走代理"
mk_vmess=$(echo $mk_vmess| jq --raw-output 'setpath(["routing","domainStrategy"];"AsIs")')
mk_vmess=$(echo $mk_vmess| jq --raw-output 'setpath(["routing","rules",7,"domains",2];"geosite:google")')
mk_vmess=$(echo $mk_vmess| jq --raw-output 'setpath(["routing","rules",7,"domains",3];"geosite:facebook")')
mk_vmess=$(echo $mk_vmess| jq --raw-output 'setpath(["routing","rules",7,"domains",4];"geosite:geolocation-!cn")')
mk_vmess=$(echo $mk_vmess| jq --raw-output 'delpaths([["routing","rules",10]])')
mk_vmess=$(echo $mk_vmess| jq --raw-output 'delpaths([["routing","rules",9]])')
mk_vmess=$(echo $mk_vmess| jq --raw-output 'delpaths([["routing","rules",8]])')
mk_vmess_0=$(echo $mk_vmess| jq --raw-output 'getpath(["outbounds",0])')
mk_vmess_1=$(echo $mk_vmess| jq --raw-output 'getpath(["outbounds",1])')
mk_vmess=$(echo $mk_vmess| jq --raw-output 'setpath(["outbounds",0];'"$mk_vmess_1"')')
mk_vmess=$(echo $mk_vmess| jq --raw-output 'setpath(["outbounds",1];'"$mk_vmess_0"')')
fi
if [ "$mk_mode_x" = "3" ] ; then
logger -t "【v2ray】" "方案四回国模式，国内IP走代理"
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
logger -t "【v2ray】" "方案三全局代理，全部IP走代理"
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
mk_vmess=$(echo $mk_vmess| jq --raw-output 'delpaths([["routing","rules",3]])')
fi
if [ "$mk_mode_dns" = "0" ] ; then
mk_vmess=$(echo $mk_vmess| jq --raw-output 'delpaths([["inbounds",2]])')
mk_vmess=$(echo $mk_vmess| jq --raw-output 'delpaths([["routing","rules",0]])')
else
mk_vmess=$(echo $mk_vmess| jq --raw-output 'delpaths([["dns","servers",4]])')
fi
[ "$ss_ip46" = "0" ] && mk_vmess=$(echo $mk_vmess| jq --raw-output 'setpath(["dns","queryStrategy"];"UseIPv4")')
[ "$ss_ip46" = "1" ] && mk_vmess=$(echo $mk_vmess| jq --raw-output 'setpath(["dns","queryStrategy"];"UseIPv6")')
[ "$ss_ip46" = "2" ] && mk_vmess=$(echo $mk_vmess| jq --raw-output 'setpath(["dns","queryStrategy"];"UseIPv4")')
[ "$ss_ip46" != "0" ] && mk_vmess=$(echo $mk_vmess| jq --raw-output 'setpath(["inbounds",1,"streamSettings","sockopt","tproxy"];"tproxy")')
echo $mk_vmess| jq --raw-output '.' > /tmp/vmess/mk_vmess.json
if [ ! -s /tmp/vmess/mk_vmess.json ] ; then
	logger -t "【v2ray】" "错误！生成配置为空，请看看哪里问题？"
else
	nvram set app_98="$link_name"
	nvram set app_72="$link_input"
	logger -t "【v2ray】" "完成！生成配置，请刷新web页面查看！（应用新配置需按F5）"
	cp -f /tmp/vmess/mk_vmess.json /etc/storage/v2ray_config_script.sh
	sed -Ei s@\<\/textarea\>@@g /etc/storage/v2ray_config_script.sh
fi

}

json_mk_vmess_settings () {

# 配置 settings https://www.v2fly.org/config/protocols/vless.html#outboundconfigurationobject
mk_vmess=$(json_int_vmess_settings)
mk_vmess=$(echo $mk_vmess | jq --raw-output 'setpath(["vnext",0,"address"];"'$vless_link_remote_host'")')
mk_vmess=$(echo $mk_vmess | jq --raw-output 'setpath(["vnext",0,"users",0,"id"];"'$vless_link_uuid'")')
mk_vmess=$(echo $mk_vmess | jq --raw-output 'setpath(["vnext",0,"port"];'$vless_link_remote_port')')
if [ "$link_protocol" == "vless" ] ; then
mk_vmess=$(echo $mk_vmess | jq --raw-output 'setpath(["vnext",0,"users",0,"encryption"];"'$vless_link_encryption'")')
if [ "$vless_link_security" == "tls" ] || [ "$vless_link_security" == "xtls" ] || [ "$vless_link_security" == "reality" ] ; then
[ ! -z "$vless_link_flow" ] && mk_vmess=$(echo $mk_vmess | jq --raw-output 'setpath(["vnext",0,"users",0,"flow"];"'$vless_link_flow'")')
else
mk_vmess=$(echo $mk_vmess | jq --raw-output 'delpaths([["vnext",0,"users",0,"flow"]])')
fi
mk_vmess=$(echo $mk_vmess | jq --raw-output 'delpaths([["vnext",0,"users",0,"security"]])')
mk_vmess=$(echo $mk_vmess | jq --raw-output 'delpaths([["vnext",0,"users",0,"alterId"]])')
fi
if [ "$link_protocol" == "vmess" ] ; then
mk_vmess=$(echo $mk_vmess | jq --raw-output 'setpath(["vnext",0,"users",0,"security"];"'$vless_link_encryption'")')
mk_vmess=$(echo $mk_vmess | jq --raw-output 'delpaths([["vnext",0,"users",0,"encryption"]])')
[ ! -z "$vless_link_aid" ] && mk_vmess=$(echo $mk_vmess | jq --raw-output 'setpath(["vnext",0,"users",0,"alterId"];'$vless_link_aid')')
fi
vmess_settings=$mk_vmess

# 配置 streamSettings https://www.v2fly.org/config/transport.html#streamsettingsobject
mk_vmess=$(json_int_vmess_streamSettings)
mk_vmess=$(echo $mk_vmess | jq --raw-output 'setpath(["network"];"'$vless_link_type'")')
[ ! -z "$vless_link_security" ] && mk_vmess=$(echo $mk_vmess | jq --raw-output 'setpath(["security"];"'$vless_link_security'")')
# allowInsecure: 是否允许不安全连接（仅用于客户端）。默认值为 false。当值为 true 时，V2Ray 不会检查远端主机所提供的 TLS 证书的有效性。
[ -z "$vless_link_allowInsecure" ] && vless_link_allowInsecure=`nvram get app_73`
[ "$vless_link_allowInsecure" == "1" ] && vless_link_allowInsecure="true"
# 配置 realitySettings star
if [ "$vless_link_security" == "reality" ] ; then
mk_vmess=$(echo $mk_vmess | jq --raw-output 'setpath(["realitySettings","fingerprint"];"'$vless_link_fp'")')
mk_vmess=$(echo $mk_vmess | jq --raw-output 'setpath(["realitySettings","serverName"];"'$vless_link_sni'")')
mk_vmess=$(echo $mk_vmess | jq --raw-output 'setpath(["realitySettings","publicKey"];"'$vless_link_pbk'")')
mk_vmess=$(echo $mk_vmess | jq --raw-output 'setpath(["realitySettings","shortId"];"'$vless_link_sid'")')
mk_vmess=$(echo $mk_vmess | jq --raw-output 'setpath(["realitySettings","spiderX"];"'$vless_link_spx'")')
fi
# 配置 realitySettings end
# 配置 tlsSettings star
if [ "$vless_link_security" == "tls" ] ; then
if [ "$vless_link_allowInsecure" == "true" ] || [ "$vless_link_allowInsecure" == "false" ] ; then
	mk_vmess=$(echo $mk_vmess | jq --raw-output 'setpath(["tlsSettings","allowInsecure"];'$vless_link_allowInsecure')')
else
	mk_vmess=$(echo $mk_vmess | jq --raw-output 'setpath(["tlsSettings","allowInsecure"];false)')
fi
if [ ! -z "$vless_link_sni" ] ; then
	mk_vmess=$(echo $mk_vmess | jq --raw-output 'setpath(["tlsSettings","serverName"];"'$vless_link_sni'")')
else
	mk_vmess=$(echo $mk_vmess | jq --raw-output 'delpaths([["tlsSettings","serverName"]])')
fi
if [ "$vless_link_flow" == "xtls-rprx-vision" ] ; then
mk_vmess=$(echo $mk_vmess | jq --raw-output 'setpath(["tlsSettings","fingerprint"];"'$vless_link_fp'")')
fi
if [ ! -z "$vless_link_alpn" ] ; then
	vless_link_alpn=$(echo $vless_link_alpn | sed 's/,/ /g')
	link_alpn_i=0
	for link_alpn in $vless_link_alpn
	do
		mk_vmess=$(echo $mk_vmess | jq --raw-output 'setpath(["tlsSettings","alpn",'$link_alpn_i'];"'$link_alpn'")')
		link_alpn_i=$(( link_alpn_i + 1 ))
	done
else
	mk_vmess=$(echo $mk_vmess | jq --raw-output 'delpaths([["tlsSettings","alpn"]])')
fi
fi
# 配置 tlsSettings end
# 配置 xtlsSettings star
if [ "$vless_link_security" == "xtls" ] ; then
if [ "$vless_link_allowInsecure" == "true" ] || [ "$vless_link_allowInsecure" == "false" ] ; then
	mk_vmess=$(echo $mk_vmess | jq --raw-output 'setpath(["xtlsSettings","allowInsecure"];'$vless_link_allowInsecure')')
else
	mk_vmess=$(echo $mk_vmess | jq --raw-output 'setpath(["xtlsSettings","allowInsecure"];false)')
fi
if [ ! -z "$vless_link_sni" ] ; then
	mk_vmess=$(echo $mk_vmess | jq --raw-output 'setpath(["xtlsSettings","serverName"];"'$vless_link_sni'")')
else
	mk_vmess=$(echo $mk_vmess | jq --raw-output 'delpaths([["xtlsSettings","serverName"]])')
fi
if [ ! -z "$vless_link_alpn" ] ; then
	vless_link_alpn=$(echo $vless_link_alpn | sed 's/,/ /g')
	link_alpn_i=0
	for link_alpn in $vless_link_alpn
	do
		mk_vmess=$(echo $mk_vmess | jq --raw-output 'setpath(["xtlsSettings","alpn",'$link_alpn_i'];"'$link_alpn'")')
		link_alpn_i=$(( link_alpn_i + 1 ))
	done
else
	mk_vmess=$(echo $mk_vmess | jq --raw-output 'delpaths([["xtlsSettings","alpn"]])')
fi
fi
# 配置 xtlsSettings end
# tcp star
if [ "$vless_link_type" = "tcp" ] ; then
[ ! -z "$vless_link_headerType" ] && mk_vmess=$(echo $mk_vmess | jq --raw-output 'setpath(["tcpSettings","header","type"];"'$vless_link_headerType'")')
if [ "$vless_link_headerType" = "none" ] ; then
	mk_vmess=$(echo $mk_vmess | jq --raw-output 'delpaths([["tcpSettings","header","request"]])')
fi
if [ "$vless_link_headerType" = "http" ] ; then
# request: HTTPRequestObject https://www.v2fly.org/config/transport/tcp.html#httprequestobject
# response: HTTPResponseObject
# 旧方案写入 path 和 host
[ -z "$vless_link_path" ] && vless_link_path="/"
vless_link_path=$(echo $vless_link_path | sed 's/,/ /g')
link_path_i=0
for link_path in $vless_link_path
do
	mk_vmess=$(echo $mk_vmess | jq --raw-output 'setpath(["tcpSettings","header","request","path",'$link_path_i'];"'$link_path'")')
	link_path_i=$(( link_path_i + 1 ))
done
if [ ! -z "$vless_link_host" ] ; then
vless_link_host=$(echo $vless_link_host | sed 's/,/ /g')
link_host_i=0
for link_host in $vless_link_host
do
	mk_vmess=$(echo $mk_vmess | jq --raw-output 'setpath(["tcpSettings","header","request","headers","Host",'$link_host_i'];"'$link_host'")')
	link_host_i=$(( link_host_i + 1 ))
done
fi
fi
fi
# tcp end
# kcp star
if [ "$vless_link_type" = "kcp" ] ; then
[ ! -z "$vless_link_headerType" ] && mk_vmess=$(echo $mk_vmess | jq --raw-output 'setpath(["kcpSettings","header","type"];"'$vless_link_headerType'")')
[ ! -z "$vless_link_seed" ] && mk_vmess=$(echo $mk_vmess | jq --raw-output 'setpath(["kcpSettings","seed"];"'$vless_link_headerType'")')
fi
# kcp end
# ws star
if [ "$vless_link_type" = "ws" ] ; then
[ -z "$vless_link_path" ] && vless_link_path="/"
[ ! -z "$vless_link_path" ] && mk_vmess=$(echo $mk_vmess | jq --raw-output 'setpath(["wsSettings","path"];"'$vless_link_path'")')
if [ ! -z "$vless_link_host" ] ; then
vless_link_host=$(echo $vless_link_host | sed 's/,/ /g')
link_host_i=0
for link_host in $vless_link_host
do
	[ "$link_host_i" == "0" ] && mk_vmess=$(echo $mk_vmess | jq --raw-output 'setpath(["wsSettings","headers","Host"];"'$link_host'")')
	link_host_i=$(( link_host_i + 1 ))
done
fi
fi
# ws end
# http h2 star
if [ "$vless_link_type" = "http" ] || [ "$vless_link_type" = "h2" ] ; then
[ -z "$vless_link_path" ] && vless_link_path="/"
mk_vmess=$(echo $mk_vmess | jq --raw-output 'setpath(["httpSettings","path"];"'$vless_link_path'")')
[ -z "$vless_link_host" ] && vless_link_host="$vless_link_remote_host"
vless_link_host=$(echo $vless_link_host | sed 's/,/ /g')
link_host_i=0
for link_host in $vless_link_host
do
	mk_vmess=$(echo $mk_vmess | jq --raw-output 'setpath(["httpSettings","host",'$link_host_i'];"'$link_host'")')
	link_host_i=$(( link_host_i + 1 ))
done
fi
# http h2 end
# quic star
if [ "$vless_link_type" = "quic" ] ; then
[ ! -z "$vless_link_headerType" ] && mk_vmess=$(echo $mk_vmess | jq --raw-output 'setpath(["quicSettings","header","type"];"'$vless_link_headerType'")')
[ ! -z "$vless_link_quicSecurity" ] && mk_vmess=$(echo $mk_vmess | jq --raw-output 'setpath(["quicSettings","security"];"'$vless_link_quicSecurity'")')
if [ "$vless_link_quicSecurity" != "none" ] ; then
	mk_vmess=$(echo $mk_vmess | jq --raw-output 'setpath(["quicSettings","key"];"'$vless_link_key'")')
else
	mk_vmess=$(echo $mk_vmess | jq --raw-output 'delpaths([["quicSettings","key"]])')
fi
fi
# quic end
# grpc star
if [ "$vless_link_type" = "grpc" ] ; then
[ ! -z "$vless_link_serviceName" ] && mk_vmess=$(echo $mk_vmess | jq --raw-output 'setpath(["grpcSettings","serviceName"];"'$vless_link_serviceName'")')
[ ! -z "$vless_link_authority" ] && mk_vmess=$(echo $mk_vmess | jq --raw-output 'setpath(["grpcSettings","authority"];"'$vless_link_authority'")')
if [ "$vless_link_mode" == "mutil" ] ; then
	mk_vmess=$(echo $mk_vmess | jq --raw-output 'setpath(["grpcSettings","multiMode"];"true")')
else
	mk_vmess=$(echo $mk_vmess | jq --raw-output 'delpaths([["grpcSettings","multiMode"]])')
fi
fi
# grpc end
# HTTPUpgrade star
if [ "$vless_link_type" = "httpupgrade" ] ; then
[ -z "$vless_link_path" ] && vless_link_path="/"
[ ! -z "$vless_link_path" ] && mk_vmess=$(echo $mk_vmess | jq --raw-output 'setpath(["httpupgradeSettings","path"];"'$vless_link_path'")')
[ ! -z "$vless_link_host" ] && mk_vmess=$(echo $mk_vmess | jq --raw-output 'setpath(["httpupgradeSettings","host"];"'$vless_link_host'")')
fi
# HTTPUpgrade end
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
          "encryption": "none"
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
  "realitySettings": {
    "show": false
  },
  "tlsSettings": {
    "allowInsecure": true
  },
  "xtlsSettings": {
    "allowInsecure": true
  },
  "tcpSettings": {
    "header": {
      "type": "none",
      "request": {
        "path": [
          "/"
        ],
        "headers": {
          "Host": []
        }
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
  "grpcSettings": {
    "authority": "",
    "serviceName": ""
  },
  "httpupgradeSettings": {
    "path": "/",
    "host": ""
  },
  "sockopt": {
    "mark": 255
  }
}
'
}

json_mk_ss_settings () {

mk_vmess=$(json_int_ss_settings)
mk_vmess=$(echo $mk_vmess | jq --raw-output 'setpath(["servers",0,"address"];"'$ss_link_server'")')
mk_vmess=$(echo $mk_vmess | jq --raw-output 'setpath(["servers",0,"port"];'$ss_link_port')')
mk_vmess=$(echo $mk_vmess | jq --raw-output 'setpath(["servers",0,"password"];"'$ss_link_password'")')
mk_vmess=$(echo $mk_vmess | jq --raw-output 'setpath(["servers",0,"method"];"'$ss_link_method'")')
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
      "password": "test"
    }
  ]
}
'
}

json_int_ss_streamSettings () {
echo '{
  "sockopt": {
    "mark": 255
  }
}
'
}

json_mk_trojan_settings () {

mk_vmess=$(json_int_trojan_settings)
mk_vmess=$(echo $mk_vmess | jq --raw-output 'setpath(["servers",0,"address"];"'$trojan_link_server'")')
mk_vmess=$(echo $mk_vmess | jq --raw-output 'setpath(["servers",0,"port"];'$trojan_link_port')')
mk_vmess=$(echo $mk_vmess | jq --raw-output 'setpath(["servers",0,"password"];"'$trojan_link_password'")')
vmess_settings=$mk_vmess
mk_vmess=$(json_int_trojan_streamSettings)
[ -z "$vless_link_allowInsecure" ] && vless_link_allowInsecure=`nvram get app_73`
[ "$vless_link_allowInsecure" == "1" ] && vless_link_allowInsecure="true"
if [ "$vless_link_allowInsecure" == "true" ] || [ "$vless_link_allowInsecure" == "false" ] ; then
	mk_vmess=$(echo $mk_vmess | jq --raw-output 'setpath(["tlsSettings","allowInsecure"];'$vless_link_allowInsecure')')
else
	mk_vmess=$(echo $mk_vmess | jq --raw-output 'setpath(["tlsSettings","allowInsecure"];false)')
fi
vmess_streamSettings=$mk_vmess
}

json_int_trojan_settings () {
echo '{
  "servers": [
    {
      "address": "127.0.0.1",
      "port": 1234,
      "password": "test"
    }
  ]
}
'
}

json_int_trojan_streamSettings () {
echo '{
  "network": "tcp",
  "security": "tls",
  "tlsSettings": {
    "allowInsecure": true
  },
  "sockopt": {
    "mark": 255
  }
}
'
}

json_int () {
echo '{
  "log": {
    "access": "none",
    "error": "/tmp/syslog.log",
    "loglevel": "error"
  },
  "inbounds": [
    {
      "port": 1088,
      "listen": "0.0.0.0",
      "protocol": "socks",
      "settings": {
        "auth": "noauth",
        "udp": true,
        "ip": "127.0.0.1"
      },
      "tag": "local_1088",
      "sniffing": {
        "enabled": true,
        "destOverride": [
          "http",
          "tls"
        ],
        "domainsExcluded": [
          "mijia cloud",
          "courier.push.apple.com"
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
      "streamSettings": {
        "sockopt": {
          "tproxy": "redirect"
        }
      },
      "sniffing": {
        "enabled": true,
        "destOverride": [
          "http",
          "tls"
        ],
        "domainsExcluded": [
          "mijia cloud",
          "courier.push.apple.com"
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
        "realitySettings": {},
        "tlsSettings": {},
        "xtlsSettings": {},
        "tcpSettings": {},
        "kcpSettings": {},
        "wsSettings": {},
        "httpSettings": {},
        "dsSettings": {},
        "quicSettings": {},
        "grpcSettings": {},
        "httpupgradeSettings ": {},
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
    "queryStrategy": "UseIPv4",
    "servers": [
      {
        "address": "8.8.8.8",
        "port": 53,
        "domains": [
          "domain:cn2qq.com",
          "geosite:google",
          "geosite:geolocation-!cn",
          "geosite:facebook",
          "geosite:twitter",
          "geosite:telegram",
          "domain:youtube.com",
          "domain:appspot.com",
          "domain:telegram.com",
          "domain:facebook.com",
          "domain:twitter.com",
          "domain:blogger.com",
          "domain:gmail.com",
          "domain:translate.googleapis.com",
          "domain:gvt1.com"
        ]
      },
      {
        "address": "223.5.5.5",
        "port": 53,
        "domains": [
          "geosite:cn",
          "geosite:apple",
          "domain:courier.push.apple.com"
        ],
        "expectIPs": [
          "geoip:cn"
        ]
      },
      "8.8.8.8",
      "8.8.4.4",
      "localhost"
    ]
  },
  "routing": {
    "domainStrategy": "IPIfNonMatch",
    "domainMatcher": "mph",
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
        "domains": [
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
        "inboundTag": [
          "local_1088"
        ],
        "outboundTag": "outbound_1"
      },
      {
        "type": "field",
        "ip": [
          "192.168.0.0/16",
          "172.16.0.0/12",
          "169.254.0.0/16",
          "255.255.255.255/32",
          "geoip:private",
          "100.100.100.100/32",
          "188.188.188.188/32",
          "110.110.110.110/32"
        ],
        "outboundTag": "direct"
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
        "inboundTag": [
          "redir_1099"
        ],
        "outboundTag": "outbound_1"
      },
      {
        "type": "field",
        "domains": [
          "gfwall.com",
          "cn2qq.com"
        ],
        "outboundTag": "outbound_1"
      },
      {
        "type": "field",
        "domains": [
          "domain:baidu.com",
          "domain:qq.com",
          "domain:taobao.com",
          "geosite:cn",
          "geosite:apple",
          "domain:courier.push.apple.com"
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
nvram set app_83=""
vmess_x_tmp=""
mkdir -p /etc/storage/link
mkdir -p /tmp/link/matching
rm -f /tmp/link/matching/link_v2_matching.txt
rm -f /tmp/link/matching/link_v2_matching_0.txt
mkdir -p /tmp/link/tmp_vmess
rm -rf /tmp/link/tmp_vmess/*
rm -f /tmp/link/ping_vmess.txt
touch /tmp/link/ping_vmess.txt
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
done < /etc/storage/app_25.sh
ilox="$(ls -l /tmp/link/tmp_vmess/ |wc -l)"
i_x_ping="1"
while [ "$i_ping" != "$ilox" ];
do
sleep 1
ilox="$(ls -l /tmp/link/tmp_vmess/ |wc -l)"
i_x_ping=`expr $i_x_ping + 1`
if [ "$i_x_ping" -gt 300 ] ; then
logger -t "【ping】" "刷新 ping 失败！超时 300 秒！ 请重新按【ping】按钮再次尝试。"
break
fi
done
echo -n 'var ping_data = "' >> /tmp/link/ping_vmess.txt
for ilox in /tmp/link/tmp_vmess/*
do
echo -n "$(cat "$ilox")"  >> /tmp/link/ping_vmess.txt
done
echo -n '";' >> /tmp/link/ping_vmess.txt
sed -Ei '/^$/d' /tmp/link/ping_vmess.txt
rm -rf /tmp/link/tmp_vmess/*
rm -rf /www/link/ping_vmess.js
cp -f /tmp/link/ping_vmess.txt /www/link/ping_vmess.js

}

x_ping_x () {
# 解码获取信息
link_read="ping"
link_de_protocol "$line" "0vmess0vless0ss0trojan0"
ping_re="$(echo /tmp/link/tmp_vmess/$1)"
if [ "$link_protocol" != "vmess" ] && [ "$link_protocol" != "vless" ] && [ "$link_protocol" != "ss" ] && [ "$link_protocol" != "trojan" ] ; then
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

if [ "$link_protocol" == "vmess" ] || [ "$link_protocol" == "vless" ] || [ "$link_protocol" == "ss" ] || [ "$link_protocol" == "trojan" ] ; then
[ -z "$ping_time" ] && ping_time=9999
[ "$ping_time" -gt 9999 ] && ping_time=9999
get_ping="00000""$ping_time"
get_ping_l="$(echo -n $get_ping | wc -c)"
get_ping_a="$(( get_ping_l - 3 ))"
get_ping="$(echo -n "$get_ping" | cut -b "$get_ping_a-$get_ping_l")"
echo $get_ping"$link_name""↪️""$link_input""↩️" >> /tmp/link/matching/link_v2_matching_0.txt
fi

}

start_vmess_link () {

vmess_x_tmp="`nvram get app_83`"
if [ ! -z "$vmess_x_tmp" ] ; then
nvram set app_83=""
fi
if [ "$vmess_x_tmp" = "del_link" ] ; then
	# 清空上次订阅节点配置
	rm -f /tmp/link/matching/link_v2_matching.txt
	rm -f /www/link/vmess.js
	rm -f /www/link/ss.js
	sed -Ei '/🔗|dellink_ss|^$/d' /etc/storage/app_25.sh
	vmess_x_tmp=""
	logger -t "【v2ray】" "完成清空上次订阅节点配置 请按【F5】刷新 web 查看"
	return
fi
if [ "$vmess_x_tmp" = "v2ray_link_v2_matching" ] ; then
	v2ray_link_v2_matching
	return
fi

vmess_link="`nvram get app_66`"
vmess_link_up=`nvram get app_67`
vmess_link_ping=`nvram get app_68`
A_restart=`nvram get vmess_link_status`
B_restart=`echo -n "$vmess_link$vmess_link_up" | md5sum | sed s/[[:space:]]//g | sed s/-//g`
cut_B_re
if [ "$A_restart" != "$B_restart" ] ; then
nvram set vmess_link_status=$B_restart
	if [ -z "$vmess_link" ] ; then
		cru.sh d vmess_link_update
		logger -t "【v2ray】" "停止 vmess 服务器订阅"
		return
	else
		if [ "$vmess_link_up" != 1 ] ; then
			cru.sh a vmess_link_update "18 */6 * * * $scriptfilepath up_link &" &
			logger -t "【v2ray】" "启动 vmess 服务器订阅，添加计划任务 (Crontab)，每6小时更新"
		else
			cru.sh d vmess_link_update
		fi
	fi
fi
if [ -z "$vmess_link" ] ; then
	return
fi

if [ "$vmess_x_tmp" != "up_link" ] ; then
	return
fi

json_jq_check
logger -t "【v2ray】" "服务器订阅：开始更新"

vmess_link="$(echo "$vmess_link" | tr , \  | sed 's@  @ @g' | sed 's@  @ @g' | sed 's@^ @@g' | sed 's@ $@@g' )"
rm -f /www/link/vmess.js
rm -f /www/link/ss.js
rm -f /tmp/link/matching/link_v2_matching.txt
down_i_link="1"
if [ ! -z "$(echo "$vmess_link" | awk -F ' ' '{print $2}')" ] ; then
	for vmess_link_i in $vmess_link
	do
		down_link "$vmess_link_i"
		rm -rf /tmp/link/vmess/*
	done
else
	down_link "$vmess_link"
	rm -rf /tmp/link/vmess/*
fi
logger -t "【v2ray】" "服务器订阅：更新完成"
if [ "$vmess_link_ping" != 1 ] ; then
	nvram set app_83="ping_link"
	ping_vmess_link
	app_99="$(nvram get app_99)"
	if [ "$app_99" == 1 ] ; then
		rm -f /tmp/link/matching/link_v2_matching.txt
		v2ray_link_v2_matching
	fi
else
	echo "【v2ray】：停止ping订阅节点"
fi

}

down_link () {
http_link="$(echo $1)"
mkdir -p /tmp/link/vmess/
rm -f /tmp/link/vmess/0_link.txt
if [ ! -z "$(echo "$http_link" | grep '^/')" ] ; then
[ -f "$http_link" ] && cp -f "$http_link" /tmp/link/vmess/0_link.txt
[ ! -f "$http_link" ] && logger -t "【v2ray】" "错误！！ $http_link 文件不存在！"
else
if [ -z "$(echo "$http_link" | grep 'http:\/\/')""$(echo "$http_link" | grep 'https:\/\/')" ] ; then
	logger -t "【v2ray】" "$http_link"
	logger -t "【v2ray】" "错误！！vmess 服务器订阅文件下载地址不含http(s)://！请检查下载地址"
	return
fi
#logger -t "【v2ray】" "订阅文件下载: $http_link"
rm -f /tmp/link/vmess/0_link.txt
wgetcurl.sh /tmp/link/vmess/0_link.txt "$http_link" "$http_link" N
if [ ! -s /tmp/link/vmess/0_link.txt ] ; then
	rm -f /tmp/link/vmess/0_link.txt
	curl -L --user-agent "$user_agent" -o /tmp/link/vmess/0_link.txt "$http_link"
fi
if [ ! -s /tmp/link/vmess/0_link.txt ] ; then
	rm -f /tmp/link/vmess/0_link.txt
	wget -T 5 -t 3 --user-agent "$user_agent" -O /tmp/link/vmess/0_link.txt "$http_link"
fi
fi
if [ ! -s /tmp/link/vmess/0_link.txt ] ; then
	rm -f /tmp/link/vmess/0_link.txt
	logger -t "【v2ray】" "$http_link"
	logger -t "【v2ray】" "错误！！vmess 服务器订阅文件获取失败！请检查地址"
	return
fi
dos2unix /tmp/link/vmess/0_link.txt
sed -e '/^$/d' -i /tmp/link/vmess/0_link.txt
if [ ! -z "$(cat /tmp/link/vmess/0_link.txt | grep "ssd://")" ] ; then
	logger -t "【v2ray】" "不支持【ssd://】订阅文件"
	return
fi
http_link_d1="$(cat /tmp/link/vmess/0_link.txt | grep "://" | wc -l)"
[ "$http_link_d1" -eq 0 ] && http_link_dd="1" #没找到链接，需要2次解码
if [ "$http_link_d1" -eq 1 ] ; then #找到1个链接，尝试解码
http_link_dd_text="$(cat /tmp/link/vmess/0_link.txt  | awk -F '://' '{print $2}')"
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
if [ "$(cat /tmp/link/vmess/0_link.txt | grep "://" | wc -l)" != "0" ] ; then
cat /tmp/link/vmess/0_link.txt | awk -F '://' '{cmd=sprintf("echo -n \"%s\" | sed -e \"s/_/\\//g\" | sed -e \"s/-/\\+/g\" | sed \"s/$/&====/g\" | base64 -d", $2);  system(cmd); print "";}' > /tmp/link/vmess/1_link.txt
else
cat /tmp/link/vmess/0_link.txt | awk '{cmd=sprintf("echo -n \"%s\" | sed -e \"s/_/\\//g\" | sed -e \"s/-/\\+/g\" | sed \"s/$/&====/g\" | base64 -d", $1);  system(cmd); print "";}' > /tmp/link/vmess/1_link.txt
fi
else
# 不需2次解码
mv -f /tmp/link/vmess/0_link.txt /tmp/link/vmess/1_link.txt
fi
touch /etc/storage/app_25.sh
[ "$down_i_link" == "1" ] && sed -Ei '/^🔗/d' /etc/storage/app_25.sh
down_i_link="2"
sed -Ei '/^$/d' /tmp/link/vmess/1_link.txt
sed -Ei 's@^@'🔗'@g' /tmp/link/vmess/1_link.txt
sed -Ei s@\<\/textarea\>@@g /tmp/link/vmess/1_link.txt
cat /tmp/link/vmess/1_link.txt >> /etc/storage/app_25.sh
sed -Ei '/dellink_ss|^$/d' /etc/storage/app_25.sh
sed -Ei s@\<\/textarea\>@@g /etc/storage/app_25.sh
rm -rf /tmp/link/vmess/*

}

v2ray_link_v2_matching(){

json_jq_check
# 排序节点
mkdir -p /tmp/link/matching
rm -f /tmp/link/matching/link_v2_matching_1.txt
if [ ! -f /tmp/link/matching/link_v2_matching.txt ] || [ ! -s /tmp/link/matching/link_v2_matching.txt ] ; then
if [ ! -f /tmp/link/matching/link_v2_matching_0.txt ] || [ ! -s /tmp/link/matching/link_v2_matching_0.txt ] ; then
nvram set app_83="ping_link"
ping_vmess_link
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
	echo $line2 >> /tmp/link/matching/link_v2_matching_1.txt
	fi
fi
done < /tmp/link/matching/link_v2_matching_0.txt
if [ -f /tmp/link/matching/link_v2_matching_1.txt ] && [ -s /tmp/link/matching/link_v2_matching_1.txt ] ; then
sed -Ei '/^$/d' /tmp/link/matching/link_v2_matching_1.txt
cat /tmp/link/matching/link_v2_matching_1.txt | sort | grep -v '^$' > /tmp/link/matching/link_v2_matching.txt
rm -f /tmp/link/matching/link_v2_matching_1.txt
logger -t "【自动选用节点】" "重新生成自动选用节点列表： /tmp/link/matching/link_v2_matching.txt"
fi
fi

if [ -f /tmp/link/matching/link_v2_matching.txt ] && [ -s /tmp/link/matching/link_v2_matching.txt ] ; then
# 选用节点
if [ -z "$(cat /tmp/link/matching/link_v2_matching.txt | grep -v 已经自动选用节点)" ] ; then
sed -e 's/已经自动选用节点//g' -i /tmp/link/matching/link_v2_matching.txt
fi
i_matching=1
while read line
do
if [ ! -z "$(echo "$line" | grep -v "已经自动选用节点" )" ] ; then
sed -i $i_matching's/^/已经自动选用节点/' /tmp/link/matching/link_v2_matching.txt
# 选用节点
logger -t "【自动选用节点】" "自动选用节点：""$(echo "$line" | grep -Eo '^[^↪️]+')"
nvram set app_71="$(echo "$line" | grep -Eo "↪️.*[^↩️]" | grep -Eo "[^↪️].*")"
if [ "$v2ray_enable" == "0" ] ; then
eval "$scriptfilepath json_mk_vmess &"
return 
else
# 重启v2ray
eval "$scriptfilepath &"
exit
break
fi
fi
i_matching=`expr $i_matching + 1`
done < /tmp/link/matching/link_v2_matching.txt
else
# 重启v2ray
eval "$scriptfilepath &"
fi

}

del_LinkList(){
logger -t "【del_LinkList】" "$1"
del_x=$(($1 + 1))
[ -s /etc/storage/app_25.sh ] && sed -i "$del_x""c dellink_ss" /etc/storage/app_25.sh
sed -Ei '/dellink_ss|^$/d' /etc/storage/app_25.sh
}

v2ray_get_releases(){
app_74="$(nvram get app_74)"
link_get=""
if [ "$app_74" == "0" ] ; then
echo "不检测主程序版本"
fi
if [ "$app_74" == "2" ] ; then
nvram set app_74="4" ; app_74="4"
link_get="v2ray"
logger -t "【v2ray】" "自动下载 Xray-core 主程序"
fi
if [ "$app_74" == "5" ] ; then
nvram set app_74="6" ; app_74="6"
link_get="v2ray-v2ray5"
logger -t "【v2ray】" "自动下载 Xray-core v5 主程序"
fi
if [ ! -z "$link_get" ] ; then
wgetcurl_file "$v2ray_path""_file" "$hiboyfile/""$link_get" "$hiboyfile2/""$link_get"
sed -Ei '/【v2ray】|^$/d' /tmp/script/_opt_script_check
killall v2ray v2ray_script.sh
rm -rf $v2ray_path
mv -f "$v2ray_path""_file" "$v2ray_path"
fi

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
v2raykeep)
	#v2ray_check
	v2ray_keep
	;;
updatev2ray)
	v2ray_restart o
	[ "$v2ray_enable" = "1" ] && nvram set v2ray_status="updatev2ray" && logger -t "【v2ray】" "重启" && v2ray_restart
	[ "$v2ray_enable" != "1" ] && [ -f "$v2ray_path" ] && nvram set v2ray_v="" && logger -t "【v2ray】" "更新" && { rm -rf $v2ray_path $geoip_path $geosite_path ; rm -rf /opt/bin/v2ray ; rm -rf /opt/opt_backup/bin/v2ray ; rm -f /opt/bin/v2ray_config.pb ; rm -f /opt/bin/geoip.dat /opt/opt_backup/bin/geoip.dat ; rm -f /opt/bin/geosite.dat /opt/opt_backup/bin/geosite.dat ; }
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
v2ray_link_v2_matching)
	v2ray_link_v2_matching
	;;
json_mk_vmess)
	json_mk_vmess
	;;
del_LinkList)
	del_LinkList $2
	;;
*)
	v2ray_check
	;;
esac

