#!/bin/sh
#copyright by hiboy
source /etc/storage/script/init.sh

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
server_addresses=$(cat /etc/storage/v2ray_config_script.sh | tr -d ' ' | grep -Eo '"address":.+' | grep -v 8.8.8.8 | grep -v google.com | grep -v 114.114.114.114 | grep -v 119.29.29.29 | sed -n '1p' | cut -d':' -f2 | cut -d'"' -f2)
if [ "$v2ray_enable" != "0" ] ; then
app_98="$(nvram get app_98)"
app_95="$(nvram get app_95)"
ss_matching_enable="$(nvram get ss_matching_enable)"
[ -z $ss_matching_enable ] && ss_matching_enable=0 && nvram set ss_matching_enable=0
[ "$ss_matching_enable" == "0" ] && [ -z "$app_95" ] && app_95="." && nvram set app_95="."
[ "$ss_matching_enable" == "1" ] && [ ! -z "$app_95" ] && app_95="" && nvram set app_95=""
if [ "$v2ray_follow" != 0 ] ; then
ss_tproxy_auser=`nvram get ss_tproxy_auser`
	if [ "Sh18_v2ray.sh" != "$ss_tproxy_auser" ] && [ "" != "$ss_tproxy_auser" ] ; then
		logger -t "【v2ray】" "错误！！！由于已启用 $ss_tproxy_auser 透明代理，停止启用 v2ray 透明代理！"
		v2ray_follow=0 && nvram set v2ray_follow=0
	fi
fi
[ "$v2ray_follow" == 0 ] && mk_mode_routing=0
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
v2ctl_path="$(cd "$(dirname "$v2ray_path")"; pwd)/v2ctl"
geoip_path="$(cd "$(dirname "$v2ray_path")"; pwd)/geoip.dat"
geosite_path="$(cd "$(dirname "$v2ray_path")"; pwd)/geosite.dat"
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
		if [ ! -z "$app_95" ] ; then
			[ -f $relock ] && rm -f $relock
			logger -t "【v2ray_restart】" "匹配关键词自动选用节点故障转移 /tmp/link_v2_matching/link_v2_matching.txt"
			v2ray_link_v2_matching
			sleep 10
		fi
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

script_tmp_config
A_restart=`nvram get v2ray_status`
B_restart="$v2ray_enable$chinadns_enable$ss_link_1$ss_link_2$ss_rebss_n$ss_rebss_a$transocks_mode_x$v2ray_path$v2ray_follow$lan_ipaddr$v2ray_door$v2ray_optput$v2ray_http_enable$v2ray_http_format$v2ray_http_config$mk_mode_routing$app_default_config$(cat /etc/storage/v2ray_script.sh /etc/storage/v2ray_config_script.sh | grep -v "^#" | grep -v "^$")"
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
check_app_25
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
			echo v2ray_follow
		fi
	fi
fi
}

v2ray_keep () {
logger -t "【v2ray】" "守护进程启动"
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
sleep 20
ss_link_2=`nvram get ss_link_2`
[ -z $ss_link_2 ] && ss_link_2="www.google.com.hk" && nvram set ss_link_2="www.google.com.hk"
ss_link_1=`nvram get ss_link_1`
[ "$ss_link_1" -lt 66 ] && ss_link_1="66" || { [ "$ss_link_1" -ge 66 ] || { ss_link_1="66" ; nvram set ss_link_1="66" ; } ; }
v2ray_enable=`nvram get v2ray_enable`
while [ "$v2ray_enable" = "1" ]; do
	NUM=`ps -w | grep "$v2ray_path" | grep -v grep |wc -l`
	if [ "$NUM" -lt "1" ] || [ ! -s "$v2ray_path" ] ; then
		logger -t "【v2ray】" "重新启动$NUM"
		v2ray_restart
	fi
	v2ray_enable=`nvram get v2ray_enable`
	v2ray_follow=`nvram get v2ray_follow`
	ss_keep_check=`nvram get ss_keep_check`
	v2ray_optput=`nvram get v2ray_optput`
	if [ "$v2ray_follow" = "1" ] && [ "$ss_keep_check" == "1" ] && [ "$v2ray_optput" == 1 ] ; then
# 自动故障转移(透明代理时生效)


rebss=`nvram get ss_rebss_b`
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
		start_vmess_link
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
if [ "$check2" == "200" ] ; then
	echo "[$LOGTIME] v2ray $app_98 have no problem."
	if [ "$rebss" != "0" ] ; then
	rebss="0"
	nvram set ss_rebss_b=0
	fi
	sleep_rnd
	#跳出当前循环
	continue
fi

#404
Sh99_ss_tproxy.sh auser_check "Sh18_v2ray.sh"
Sh99_ss_tproxy.sh s_ss_tproxy_check "Sh18_v2ray.sh"
sleep 5
check2=404
check_timeout_network "wget_check" "check"
if [ "$check2" == "200" ] ; then
	echo "[$LOGTIME] v2ray $app_98 have no problem."
	if [ "$rebss" != "0" ] ; then
	rebss="0"
	nvram set ss_rebss_b=0
	fi
	sleep_rnd
	#跳出当前循环
	continue
fi
#404
if [ ! -z "$app_95" ] ; then
	rebss=`expr $rebss + 1`
	nvram set ss_rebss_b="$rebss"
	logger -t "【v2ray】" " v2ray 服务器 【$app_98】 检测到问题"
	logger -t "【v2ray】" "匹配关键词自动选用节点故障转移 /tmp/link_v2_matching/link_v2_matching.txt"
	v2ray_link_v2_matching
	sleep 10
	#跳出当前循环
	continue
fi

#404
rebss=`expr $rebss + 1`
nvram set ss_rebss_b="$rebss"
logger -t "【v2ray】" " v2ray 服务器 【$app_98】 检测到问题"
restart_dhcpd
#/etc/storage/crontabs_script.sh &
		sleep 15
	else
		sleep 60
	fi
	v2ray_enable=`nvram get v2ray_enable`
done
}

v2ray_close () {
kill_ps "$scriptname keep"
kill_ps "$scriptname"
kill_ps "Sh18_v2ray.sh"
sed -Ei '/【v2ray】|^$/d' /tmp/script/_opt_script_check
Sh99_ss_tproxy.sh off_stop "Sh18_v2ray.sh"
[ ! -z "$v2ray_path" ] && kill_ps "$v2ray_path"
killall v2ray v2ctl v2ray_script.sh
killall -9 v2ray v2ctl v2ray_script.sh
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
if [ "$v2ray_http_enable" != "1" ] && [ ! -f /opt/bin/v2ray_config.pb ] ; then
if [ ! -f "/etc/storage/v2ray_config_script.sh" ] || [ ! -s "/etc/storage/v2ray_config_script.sh" ] ; then
logger -t "【v2ray】" "错误！ v2ray 配置文件 内容为空"
logger -t "【v2ray】" "请在导入节点或配置后，选择一个节点【应用】并点击【应用本页面设置】待配置生成"
logger -t "【v2ray】" "启动失败,10 秒后自动尝试重新启动"
sleep 10 && v2ray_restart x
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

if [ ! -s "$v2ray_path" ] ; then
	v2ray_path="/opt/bin/v2ray"
fi
v2ctl_path="$(cd "$(dirname "$v2ray_path")"; pwd)/v2ctl"
geoip_path="$(cd "$(dirname "$v2ray_path")"; pwd)/geoip.dat"
geosite_path="$(cd "$(dirname "$v2ray_path")"; pwd)/geosite.dat"
chmod 777 "$v2ray_path"
chmod 777 "$v2ctl_path"
[[ "$(v2ray -h 2>&1 | wc -l)" -lt 2 ]] && [ ! -z $v2ray_path ] && rm -rf $v2ray_path
[[ "$(v2ctl -h 2>&1 | wc -l)" -lt 2 ]] && [ ! -z $v2ctl_path ] && rm -rf $v2ctl_path
if [ ! -s "$v2ray_path" ] || [ ! -s "$v2ctl_path" ] ; then
	[ ! -s "$v2ray_path" ] && logger -t "【v2ray】" "找不到 $v2ray_path，安装 opt 程序"
	[ ! -s "$v2ctl_path" ] && logger -t "【v2ray】" "找不到 $v2ctl_path，安装 opt 程序"
	/etc/storage/script/Sh01_mountopt.sh start
fi
killall v2ray v2ctl v2ray_script.sh
killall -9 v2ray v2ctl v2ray_script.sh
optPath="`grep ' /opt ' /proc/mounts | grep tmpfs`"
Mem_total="$(free | sed -n '2p' | awk '{print $2;}')"
Mem_lt=100000
[ "$Mem_total" -lt 66 ] && Mem_total="66" || { [ "$Mem_total" -ge 66 ] || Mem_total="66" ; }
if [ ! -z "$optPath" ] || [ "$Mem_total" -lt "$Mem_lt" ] ; then
	[ ! -z "$optPath" ] && logger -t "【v2ray】" " /opt/ 在内存储存"
	if [ "$Mem_total" -lt "$Mem_lt" ] ; then
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
	[ ! -s $geoip_path ] && wgetcurl_checkmd5 $geoip_path "$hiboyfile/geoip.dat" "$hiboyfile2/geoip.dat" N
	if [ "$Mem_total" -lt "200000" ] ; then
	[ ! -s $geosite_path ] && wgetcurl_checkmd5 $geosite_path "$hiboyfile/geosite.dat" "$hiboyfile2/geosite.dat" N
	else
	[ ! -s $geosite_path ] && wgetcurl_checkmd5 $geosite_path "$hiboyfile/geosite_s.dat" "$hiboyfile2/geosite_s.dat" N
	fi
fi
if [ ! -s "/etc/ssl/certs/ca-certificates.crt" ] ; then
	mkdir -p /opt/app/ipk/
	mkdir -p /opt/etc/ssl/certs
	rm -f /etc/ssl/certs
	ln -sf /opt/etc/ssl/certs  /etc/ssl/certs
	if [ ! -s "/etc/ssl/certs/ca-certificates.crt" ] && [ -s /etc_ro/certs.tgz ]; then
		tar -xzvf /etc_ro/certs.tgz -C /opt/etc/ssl/ ; cd /opt
	fi
	if [ ! -s "/etc/ssl/certs/ca-certificates.crt" ] ; then
		logger -t "【opt】" "已挂载,找不到ca-certificates证书"
		logger -t "【opt】" "下载证书"
		wgetcurl.sh /opt/app/ipk/certs.tgz "$hiboyfile/certs.tgz" "$hiboyfile2/certs.tgz"
		if [ ! -s "/opt/app/ipk/certs.tgz" ] ; then
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
mount -o remount,size=50% tmpfs /tmp
Available_B=$(df -m | grep "% /opt" | awk 'NR==1' | awk -F' ' '{print $4}')
logger -t "【ss_tproxy】" "调整 /tmp 挂载分区的大小， /opt 可用空间： $Available_A → $Available_B M"
fi

for h_i in $(seq 1 2) ; do
[[ "$(v2ray -h 2>&1 | wc -l)" -lt 2 ]] && [ ! -z $v2ray_path ] && rm -rf $v2ray_path
wgetcurl_file "$v2ray_path" "$hiboyfile/v2ray" "$hiboyfile2/v2ray"
done
for h_i in $(seq 1 2) ; do
[[ "$(v2ctl -h 2>&1 | wc -l)" -lt 2 ]] && [ ! -z $v2ctl_path ] && rm -rf $v2ctl_path
wgetcurl_file $v2ctl_path "$hiboyfile/v2ctl" "$hiboyfile2/v2ctl"
done
if [ -s "$v2ray_path" ] && [ -s "$v2ctl_path" ] ; then
	logger -t "【v2ray】" "找到 $v2ray_path $v2ctl_path"
	chmod 777 "$(dirname "$v2ray_path")"
	chmod 777 $v2ray_path
	[ -f $v2ctl_path ] && chmod 777 $v2ctl_path
	[ -f $geoip_path ] && chmod 777 $geoip_path
	[ -f $geosite_path ] && chmod 777 $geosite_path
fi
if [ ! -s "$v2ray_path" ] || [ ! -s "$v2ctl_path" ] ; then
	[ ! -s "$v2ray_path" ] && logger -t "【v2ray】" "找不到 $v2ray_path ，需要手动安装 $v2ray_path"
	[ ! -s "$v2ctl_path" ] && logger -t "【v2ray】" "找不到 $v2ctl_path ，需要手动安装 $v2ctl_path"
	logger -t "【v2ray】" "启动失败, 10 秒后自动尝试重新启动" && sleep 10 && v2ray_restart x
fi
if [ -s "$v2ray_path" ] ; then
	nvram set v2ray_path="$v2ray_path"
fi
v2ray_path="$v2ray_path"
logger -t "【v2ray】" "运行 v2ray_script"
chmod 777 /etc/storage/v2ray_script.sh
chmod 644 /opt/etc/ssl/certs -R
chmod 777 /opt/etc/ssl/certs
chmod 644 /etc/ssl/certs -R
chmod 777 /etc/ssl/certs
/etc/storage/v2ray_script.sh
cd "$(dirname "$v2ray_path")"
# su_cmd="eval"
# if [ "$v2ray_follow" = "1" ] && [ "$v2ray_optput" = "1" ]; then
	# NUM=`iptables -m owner -h 2>&1 | grep owner | wc -l`
	# hash su 2>/dev/null && su_x="1"
	# hash su 2>/dev/null || su_x="0"
	# [ "$su_x" != "1" ] && logger -t "【v2ray】" "缺少 su 命令"
	# [ "$NUM" -ge "3" ] || logger -t "【v2ray】" "缺少 iptables -m owner 模块"
	# if [ "$NUM" -ge "3" ] && [ "$v2ray_optput" = 1 ] && [ "$su_x" = "1" ] ; then
		# adduser -u 777 v2 -D -S -H -s /bin/sh
		# killall v2ray
		# su_cmd="su v2 -c "
	# else
		# logger -t "【v2ray】" "停止路由自身流量走透明代理"
		# v2ray_optput=0
		# nvram set v2ray_optput=0
	# fi
# fi
v2ray_v=`v2ray -version | grep V2Ray`
nvram set v2ray_v="$v2ray_v"
if [ "$v2ray_http_enable" = "1" ] && [ ! -z "$v2ray_http_config" ] ; then
	[ "$v2ray_http_format" = "1" ] && su_cmd2="$v2ray_path -format json -config $v2ray_http_config"
	[ "$v2ray_http_format" = "2" ] && su_cmd2="$v2ray_path -format pb  -config $v2ray_http_config"
else
	if [ "$app_default_config" = "1" ] ; then
	logger -t "【v2ray】" "不改写配置，直接使用原始配置启动！（有可能端口不匹配导致功能失效）"
	logger -t "【v2ray】" "请手动修改配置，透明代理端口：$v2ray_door"
	cp -f /etc/storage/v2ray_config_script.sh /tmp/vmess/mk_vmess.json
	else
	# 改写配置适配脚本
	if [ "$mk_mode_routing" != "0" ]  ; then
	json_mk_ss_tproxy
	else
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
	script_tmp_config "/tmp/vmess/mk_vmess.json" "D"
	if [ ! -f "/tmp/vmess/mk_vmess.json" ] || [ ! -s "/tmp/vmess/mk_vmess.json" ] ; then
	logger -t "【v2ray】" "错误！实际运行配置： /tmp/vmess/mk_vmess.json 文件内容为空"
	logger -t "【v2ray】" "启动失败,10 秒后自动尝试重新启动"
	sleep 10 && v2ray_restart x
	fi
	chmod 777 /tmp/vmess
	chmod 777 /tmp/vmess/mk_vmess.json
	chmod 777 /etc/storage/v2ray_config_script.sh
	chmod 777 /opt/bin
	A_restart=`nvram get app_19`
	B_restart=`echo -n "$(cat /tmp/vmess/mk_vmess.json | grep -v "^$")" | md5sum | sed s/[[:space:]]//g | sed s/-//g`
	if [ "$A_restart" != "$B_restart" ] || [ ! -f /opt/bin/v2ray_config.pb ] ; then
		rm -f /opt/bin/v2ray_config.pb
		logger -t "【v2ray】" "配置文件转换 Protobuf 格式配置 /opt/bin/v2ray_config.pb"
		cd "$(dirname "$v2ray_path")"
		v2ctl config /tmp/vmess/mk_vmess.json > /opt/bin/v2ray_config.pb
		#v2ctl config < /tmp/vmess/mk_vmess.json > /opt/bin/v2ray_config.pb
		[ ! -s /opt/bin/v2ray_config.pb ] && logger -t "【v2ray】" "错误！ /opt/bin/v2ray_config.pb 内容为空, 10 秒后自动尝试重新启动" && sleep 10 && v2ray_restart x
		[ -s /opt/bin/v2ray_config.pb ] && nvram set app_19=$B_restart
	fi
	chmod 777 /opt/bin/v2ray_config.pb
	[ ! -f /opt/bin/v2ray_config.pb ] && su_cmd2="$v2ray_path -config /tmp/vmess/mk_vmess.json -format json"
	[ -f /opt/bin/v2ray_config.pb ] && su_cmd2="$v2ray_path -config /opt/bin/v2ray_config.pb -format pb"
fi
cd "$(dirname "$v2ray_path")"
#eval "$su_cmd" '"cmd_name=v2ray && '"$su_cmd2"' $cmd_log"' &
eval "$su_cmd2 $cmd_log" &
sleep 4
restart_dhcpd
[ ! -z "$(ps -w | grep "$v2ray_path" | grep -v grep )" ] && logger -t "【v2ray】" "启动成功 $v2ray_v " && v2ray_restart o
[ -z "$(ps -w | grep "$v2ray_path" | grep -v grep )" ] && logger -t "【v2ray】" "启动失败,10 秒后自动尝试重新启动" && sleep 10 && v2ray_restart x

initopt


if [ "$v2ray_follow" = "1" ] ; then

# 透明代理
logger -t "【v2ray】" "启动 透明代理"
logger -t "【v2ray】" "备注：默认配置的透明代理会导致广告过滤失效，需要手动改造配置前置代理过滤软件"
if [ ! -z "$(cat /etc/storage/v2ray_config_script.sh | grep '"port": 8053')" ] && [ "$mk_mode_routing" == "0" ] ; then
	logger -t "【v2ray】" "配置含内置 DNS outbound 功能，让 V2Ray 充当 DNS 服务。"
	chinadns_enable=0
	nvram set app_102=0
	nvram set app_1=0
	nvram set chinadns_status=""
	nvram set chinadns_ng_status=""
	Sh09_chinadns_ng.sh stop &
	Sh19_chinadns.sh stop &
	dns_start_dnsproxy='1' # 1:跳过自动开启第三方 DNS 程序但是继续把DNS绑定到 8053 端口的程序
else
	dns_start_dnsproxy='0' # 0:自动开启第三方 DNS 程序(dnsproxy) ;
fi
if [ "$chinadns_enable" != "0" ] && [ "$chinadns_port" = "8053" ] ; then
logger -t "【v2ray】" "chinadns 已经启动 防止域名污染"
else
if [ -z "$(cat /etc/storage/v2ray_config_script.sh | grep '"port": 8053')" ] ; then
logger -t "【v2ray】" "启动 dnsproxy 防止域名污染"
fi
fi

Sh99_ss_tproxy.sh auser_check "Sh18_v2ray.sh"
ss_tproxy_set "Sh18_v2ray.sh"
Sh99_ss_tproxy.sh on_start "Sh18_v2ray.sh"
#restart_dhcpd

logger -t "【v2ray】" "载入 透明代理 转发规则设置"

# 同时将代理规则应用到 OUTPUT 链, 让路由自身流量走透明代理
if [ "$v2ray_optput" = 1 ] ; then
logger -t "【v2ray】" "同时将透明代理规则应用到 OUTPUT 链, 让路由自身流量走透明代理"
fi
logger -t "【v2ray】" "完成 透明代理 转发规则设置"
logger -t "【v2ray】" "启动后若发现一些网站打不开, 估计是 DNS 被污染了. 解决 DNS 被污染方法："
logger -t "【v2ray】" "①电脑设置 DNS 自动获取路由 ip。检查 hosts 是否有错误规则。"
logger -t "【v2ray】" "②电脑运行 cmd 输入【ipconfig /flushdns】, 清理浏览器缓存。"
# 透明代理
fi

v2ray_get_status
eval "$scriptfilepath keep &"
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
sstp_set ipv4='true' ; sstp_set ipv6='false' ;
 # sstp_set ipv4='false' ; sstp_set ipv6='true' ;
 # sstp_set ipv4='true' ; sstp_set ipv6='true' ;
sstp_set tproxy='false' # true:TPROXY+TPROXY; false:REDIRECT+TPROXY
sstp_set tcponly='true' # true:仅代理TCP流量; false:代理TCP和UDP流量
sstp_set selfonly='false'  # true:仅代理本机流量; false:代理本机及"内网"流量
nvram set app_112="$dns_start_dnsproxy"      #app_112 0:自动开启第三方 DNS 程序(dnsproxy) ; 1:跳过自动开启第三方 DNS 程序但是继续把DNS绑定到 8053 端口的程序
nvram set ss_pdnsd_all="$dns_start_dnsproxy" # 0使用[本地DNS] + [GFW规则]查询DNS ; 1 使用 8053 端口查询全部 DNS
nvram set app_113="$dns_start_dnsproxy"      #app_113 0:使用 8053 端口查询全部 DNS 时进行 China 域名加速 ; 1:不进行 China 域名加速
[ "$v2ray_optput" == 1 ] && nvram set app_114="0" # 0:代理本机流量; 1:跳过代理本机流量
[ "$v2ray_optput" == 0 ] && nvram set app_114="1" # 0:代理本机流量; 1:跳过代理本机流量
sstp_set uid_owner='0' # 非 0 时进行用户ID匹配跳过代理本机流量
## proxy
sstp_set proxy_all_svraddr="/opt/app/ss_tproxy/conf/proxy_all_svraddr.conf"
sstp_set proxy_svrport='1:65535'
sstp_set proxy_tcpport="$v2ray_door"
sstp_set proxy_udpport="$v2ray_door"
sstp_set proxy_startcmd='date'
sstp_set proxy_stopcmd='date'
## dns
DNS_china=`nvram get wan0_dns |cut -d ' ' -f1`
[ -z "$DNS_china" ] && DNS_china="119.29.29.29"
sstp_set dns_direct="$DNS_china"
sstp_set dns_direct6='240C::6666'
sstp_set dns_remote='8.8.8.8#53'
sstp_set dns_remote6='2001:4860:4860::8888#53'
[ "$mk_mode_routing" == "1" ] && [ "$transocks_mode_x" == "3" ] && sstp_set dns_direct='8.8.8.8' # 回国模式
[ "$mk_mode_routing" == "1" ] && [ "$transocks_mode_x" == "3" ] && sstp_set dns_direct6='2001:4860:4860::8888' # 回国模式
[ "$mk_mode_routing" == "1" ] && [ "$transocks_mode_x" == "3" ] && sstp_set dns_remote='119.29.29.29#53' # 回国模式
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
server_addresses=$(cat /etc/storage/v2ray_config_script.sh | tr -d ' ' | grep -Eo '"address":.+' | grep -v 8.8.8.8 | grep -v google.com | grep -v 114.114.114.114 | grep -v 119.29.29.29 | sed -n '1p' | cut -d':' -f2 | cut -d'"' -f2)
echo "$server_addresses" >> /opt/app/ss_tproxy/conf/proxy_all_svraddr.conf
# clash
grep '^  server: ' /etc/storage/app_20.sh | tr -d ' ' | sed -e 's/server://g' | sed -e 's/"\|'"'"'\| //g' | grep -v 8.8.8.8 | grep -v google.com | grep -v 114.114.114.114 | grep -v 119.29.29.29 >> /opt/app/ss_tproxy/conf/proxy_all_svraddr.conf
cat /etc/storage/app_20.sh | tr -d ' ' | grep -E -o \"server\":\"\[\^\"\]+ | sed -e 's/server\|://g' | sed -e 's/"\|'"'"'\| //g' | grep -v 8.8.8.8 | grep -v google.com | grep -v 114.114.114.114 | grep -v 119.29.29.29 >> /opt/app/ss_tproxy/conf/proxy_all_svraddr.conf
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

sleep_rnd () {
#随机延时
SEED=`tr -cd 0-9 </dev/urandom | head -c 8`
RND_NUM=`echo $SEED 1 15|awk '{srand($1);printf "%d",rand()*10000%($3-$2)+$2}'`
[ "$RND_NUM" -lt 1 ] && RND_NUM="1" || { [ "$RND_NUM" -ge 1 ] || RND_NUM="1" ; }
sleep $RND_NUM
sleep $ss_link_1
#/etc/storage/script/sh_ezscript.sh 3 & #更新按钮状态
}


script_tmp_config () {
 # 处理特殊字符导致的web页面错误
[ ! -z "$1" ] && tmp_config="$1" || tmp_config="/etc/storage/v2ray_config_script.sh"
[ ! -s "$tmp_config" ] && return
if [ "$2" != "D" ] ; then
 # 临时变更特殊字符
sed -Ei 's@\*/@﹡／@g' $tmp_config
sed -Ei 's@/\*@／﹡@g' $tmp_config
else
 # 恢复临时特殊字符
sed -Ei 's@﹡／@\*/@g' $tmp_config
sed -Ei 's@／﹡@/\*@g' $tmp_config
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

	if [ ! -f "/etc/storage/v2ray_script.sh" ] || [ ! -s "/etc/storage/v2ray_script.sh" ] ; then
cat > "/etc/storage/v2ray_script.sh" <<-\VVR
#!/bin/sh
# 启动前运行的脚本
export PATH='/etc/storage/bin:/tmp/script:/etc/storage/script:/opt/usr/sbin:/opt/usr/bin:/opt/sbin:/opt/bin:/usr/local/sbin:/usr/sbin:/usr/bin:/sbin:/bin'
export LD_LIBRARY_PATH=/lib:/opt/lib
server_addresses=$(cat /etc/storage/v2ray_config_script.sh | tr -d ' ' | grep -Eo '"address":.+' | grep -v 8.8.8.8 | grep -v google.com | grep -v 114.114.114.114 | grep -v 119.29.29.29 | sed -n '1p' | cut -d':' -f2 | cut -d'"' -f2)
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

json_join_gfwlist() {
[ -z "$(cat /tmp/vmess/mk_vmess.json | grep gfwall.com)" ] && return
if [ "$mk_mode_x" = "0" ] || [ "$mk_mode_x" = "1" ] ; then
mkdir -p /tmp/vmess
if [ ! -s "/tmp/vmess/r.gfwlist.conf" ] ; then
touch /etc/storage/shadowsocks_mydomain_script.sh /tmp/vmess/gfwlist_domain.txt
cat /etc/storage/shadowsocks_mydomain_script.sh | sed '/^$\|#/d' | sed "s/http://g" | sed "s/https://g" | sed "s/\///g" | sort -u > /tmp/vmess/gfwlist_0.txt
cat /opt/app/ss_tproxy/rule/gfwlist.txt | sort -u | grep -v "^$" | grep '\.' | grep -v '\-\-\-' >> /tmp/vmess/gfwlist_0.txt
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
kcptun_server=""
v2ray_server_addresses=""
server_addresses=$(cat /etc/storage/v2ray_config_script.sh | tr -d ' ' | grep -Eo '"address":.+' | grep -v 8.8.8.8 | grep -v google.com | grep -v 114.114.114.114 | grep -v 119.29.29.29 | sed -n '1p' | cut -d':' -f2 | cut -d'"' -f2)
#处理肯定不走通道的目标网段
kcptun_server=`nvram get kcptun_server`
kcptun_enable=`nvram get kcptun_enable`
[ -z $kcptun_enable ] && kcptun_enable=0 && nvram set kcptun_enable=0
[ "$kcptun_enable" = "0" ] && kcptun_server=""
if [ "$kcptun_enable" != "0" ] ; then
if [ -z $(echo $kcptun_server | grep : | grep -v "\.") ] ; then 
resolveip=`ping -4 -n -q -c1 -w1 -W1 $kcptun_server | head -n1 | sed -r 's/\(|\)/|/g' | awk -F'|' '{print $2}'`
[ -z "$resolveip" ] && resolveip=`ping -6 -n -q -c1 -w1 -W1 $kcptun_server | head -n1 | sed -r 's/\(|\)/|/g' | awk -F'|' '{print $2}'`
[ -z "$resolveip" ] && resolveip=`arNslookup $kcptun_server | sed -n '1p'` 
[ -z "$resolveip" ] && resolveip=`arNslookup6 $kcptun_server | sed -n '1p'` 
kcptun_server=$resolveip
else
# IPv6
kcptun_server=$kcptun_server
fi
fi
ss_server=`nvram get ss_server`
if [ "$ss_enable" != "0" ] && [ ! -z "$ss_server" ] ; then
if [ -z $(echo $ss_server | grep : | grep -v "\.") ] ; then 
resolveip=`ping -4 -n -q -c1 -w1 -W1 $ss_server | head -n1 | sed -r 's/\(|\)/|/g' | awk -F'|' '{print $2}'`
[ -z "$resolveip" ] && resolveip=`ping -6 -n -q -c1 -w1 -W1 $ss_server | head -n1 | sed -r 's/\(|\)/|/g' | awk -F'|' '{print $2}'`
[ -z "$resolveip" ] && resolveip=`arNslookup $ss_server | sed -n '1p'` 
[ -z "$resolveip" ] && resolveip=`arNslookup6 $ss_server | sed -n '1p'` 
ss_s1_ip=$resolveip
else
# IPv6
ss_s1_ip=$ss_server
fi
fi
[ ! -z "$vmess_link_add" ] && server_addresses="$vmess_link_add"
[ ! -z "$ss_link_add" ] && server_addresses="$ss_link_add"
if [ ! -z "$server_addresses" ] ; then
	resolveip=`ping -4 -n -q -c1 -w1 -W1 $server_addresses | head -n1 | sed -r 's/\(|\)/|/g' | awk -F'|' '{print $2}'`
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
	/etc/storage/script/Sh01_mountopt.sh start
if [[ "$(jq -h 2>&1 | wc -l)" -lt 2 ]] ; then
	for h_i in $(seq 1 2) ; do
	wgetcurl_file /opt/bin/jq "$hiboyfile/jq" "$hiboyfile2/jq"
	[[ "$(jq -h 2>&1 | wc -l)" -lt 2 ]] && rm -rf /opt/bin/jq
	done
if [[ "$(jq -h 2>&1 | wc -l)" -lt 2 ]] ; then
	logger -t "【v2ray】" "找不到 jq，安装 opt 程序"
	rm -f /opt/bin/jq
	/etc/storage/script/Sh01_mountopt.sh optwget
if [[ "$(jq -h 2>&1 | wc -l)" -lt 2 ]] ; then
	#opkg update
	#opkg install jq
if [[ "$(jq -h 2>&1 | wc -l)" -lt 2 ]] ; then
	logger -t "【v2ray】" "找不到 jq，需要手动安装 opt 后输入[opkg update; opkg install jq]安装"
	return 1
fi
fi
fi
fi
fi
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
    "domainStrategy": "AsIs",
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
if [[ "$(jq -h 2>&1 | wc -l)" -lt 2 ]] ; then
json_jq_check
if [[ "$(jq -h 2>&1 | wc -l)" -lt 2 ]] ; then
	return 1
fi
fi
logger -t "【vmess】" "开始生成 ss_tproxy 配置"
mk_ss_tproxy=$(json_int_ss_tproxy)
mk_ss_tproxy=$(echo $mk_ss_tproxy| jq --raw-output 'setpath(["inbounds",0,"listen"];"0.0.0.0")')
mk_ss_tproxy=$(echo $mk_ss_tproxy| jq --raw-output 'setpath(["inbounds",0,"settings","ip"];"127.0.0.1")')
logger -t "【vmess】" "提取 outbounds 生成 ss_tproxy 配置"
mk_config="$(cat /etc/storage/v2ray_config_script.sh | jq --raw-output '.')"
#mk_config_0=$(echo $mk_config| jq --raw-output 'getpath(["outbounds",0])')
mk_config_0=$(echo $mk_config| jq --raw-output '.outbounds[] | select(.protocol == "vmess")')
if [ -z "$mk_config_0" ] ; then
mk_config_0=$(echo $mk_config| jq --raw-output '.outbounds[] | select(.protocol == "vless")')
fi
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
logger -t "【vmess】" "错误 outbounds 提出失败，请填写配正确的出站协议！vmess、vless、shadowsocks、socks、http、mtproto"
return
fi
mk_ss_tproxy=$(echo $mk_ss_tproxy| jq --raw-output 'setpath(["outbounds",0];'"$mk_config_0"')')
mk_ss_tproxy=$(echo $mk_ss_tproxy| jq --raw-output 'setpath(["outbounds",0,"tag"];"outbound_1")')
echo $mk_ss_tproxy | jq --raw-output '.' > /tmp/vmess/mk_vmess.json
if [ ! -s /tmp/vmess/mk_vmess.json ] ; then
	logger -t "【vmess】" "错误！生成透明代理路由规则使用 ss_tproxy 方式的 V2Ray 配置为空，请看看哪里问题？"
else
	logger -t "【vmess】" "完成！生成透明代理路由规则使用 ss_tproxy 方式的 V2Ray 配置，"
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
mk_vmess=$(echo $mk_vmess| jq --raw-output 'setpath(["inbounds",0,"listen"];"0.0.0.0")')
mk_vmess=$(echo $mk_vmess| jq --raw-output 'setpath(["inbounds",0,"settings","ip"];"127.0.0.1")')
json_gen_special_purpose_ip
[ ! -z "$ss_s1_ip" ] && mk_vmess=$(echo $mk_vmess| jq --raw-output 'setpath(["routing","rules",4,"ip",0];"'$ss_s1_ip'")')
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
[ "$vmess_link_v" -ge 0 ] || vmess_link_v=1
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
if [ "$vmess_link_net" = "http" ] || [ "$vmess_link_net" = "h2" ] ; then
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
  "tlsSettings": {
    "allowInsecure": true,
    "allowInsecureCiphers": true
  },
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
        "address": "119.29.29.29",
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
check_app_25 "X_allping"
if [ ! -z "$vmess_x_tmp" ] ; then
nvram set app_83=""
fi
[ ! -f /www/link/vmess.js ] && logger -t "【vmess】" "错误！找不到 /www/link/vmess.js" && return 1
ilox="$(cat /www/link/vmess.js | grep -v '^\]' | grep -v "ACL3List = " |wc -l)"
[ "$ilox" == "0" ] && ilox="$(cat /www/link/ss.js | grep -v '^\]' | grep -v "ACL4List = " |wc -l)"
[ "$ilox" == "0" ] && ilox="$(cat /tmp/link/link_vmess.txt | grep -v '^\]' | grep -v "ACL4List = " |wc -l)"
[ "$ilox" == "0" ] && ilox="$(cat /tmp/link/link_ss.txt | grep -v '^\]' | grep -v "ACL4List = " |wc -l)"
[ "$ilox" == "0" ] && logger -t "【ping】" "错误！节点列表为空" && return
if [[ "$(tcping -h 2>&1 | wc -l)" -lt 5 ]] ; then
for h_i in $(seq 1 2) ; do
[[ "$(tcping -h 2>&1 | wc -l)" -lt 5 ]] && rm -rf /opt/bin/tcping
wgetcurl_file /opt/bin/tcping "$hiboyfile/tcping" "$hiboyfile2/tcping"
done
fi
[[ "$(tcping -h 2>&1 | wc -l)" -lt 5 ]] && rm -rf /opt/bin/tcping
[[ "$(tcping -h 2>&1 | wc -l)" -gt 5 ]] && logger -t "【ping】" "开始 ping" || logger -t "【ping】" "开始 tcping"
allping 3
allping 4
logger -t "【ping】" "完成 ping 请按【F5】刷新 web 查看 ping"
app_99="$(nvram get app_99)"
if [ "$app_99" == 1 ] ; then
rm -f /tmp/link_v2_matching/link_v2_matching.txt
v2ray_link_v2_matching
fi

}

allping () {

[ "$1" == "3" ] && js_vmess="vmess.js" && js_t_vmess="vmess.txt"
[ "$1" == "4" ] && js_vmess="ss.js" && js_t_vmess="ss.txt"
mkdir -p /tmp/allping_$1
rm -f /tmp/allping_$1/?.txt
rm -f /tmp/ping_server_error.txt
touch /tmp/ping_server_error.txt
rm -f /tmp/allping_$1.js
touch /tmp/allping_$1.js
i_x_ping=2
ilox="$(cat /www/link/$js_vmess | grep -v '^\]' | grep -v "ACL""$1""List = " |wc -l)"
[ "$ilox" == "0" ] && [ ! -s /etc/storage/app_25.sh ] && return
if [ "$ilox" != "0" ] ; then
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
fi
allping_app_25 $1
}
allping_app_25 () {

[ ! -s /etc/storage/app_25.sh ] && return
if [ "$1" == "3" ] ; then
js_vmess="vmess.js"
js_t_vmess="vmess.txt"
[ -z "$(cat /etc/storage/app_25.sh | grep "vmess://" )" ] && return
fi
if [ "$1" == "4" ] ; then
js_vmess="ss.js"
js_t_vmess="ss.txt"
[ -z "$(cat /etc/storage/app_25.sh | grep -v "vmess://" | grep "ss://\|ssr://" )" ] && return
fi
mkdir -p /tmp/link
rm -f /tmp/link/ping_$js_t_vmess
touch /tmp/link/ping_$js_t_vmess
mkdir -p /tmp/allping_$1
rm -f /tmp/allping_$1/?.txt
rm -f /tmp/ping_server_error.txt
touch /tmp/ping_server_error.txt
rm -f /tmp/allping_$1.js
touch /tmp/allping_$1.js
i_x_ping=2
ilox="$(cat /tmp/link/link_$js_t_vmess | grep -v '^\]' | grep -v "ACL""$1""List = " |wc -l)"
[ "$ilox" == "0" ] && return
echo -n 'var ping_data_'"$1"' = "' >> /tmp/link/ping_$js_t_vmess
while read line
do
if [ -z "$(echo "$line" | grep "ACL""$1""List = ")" ] && [ -z "$(echo "$line" | grep '^\]')" ] ; then
if [ ! -z "$line" ] ; then
echo "$line" > /tmp/allping_$1/$i_x_ping
fi
i_x_ping=`expr $i_x_ping + 1`
fi
done < /tmp/link/link_$js_t_vmess
while [ "$(ls /tmp/allping_$1 | head -1)" != "" ];
do
x_ping_x $1 "1" &
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
echo -n '"' >> /tmp/link/ping_$js_t_vmess
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
cp -f /tmp/allping_$1/1.txt /tmp/link/link_$js_t_vmess
rm -f /www/link/ping_$js_vmess
cp -f /tmp/link/ping_$js_t_vmess /www/link/ping_$js_vmess
rm -f /tmp/allping_$1/?.txt /tmp/allping_$1.js
}

x_ping_x () {

mk_ping_txt="$2"
[ "$1" == "3" ] && js_1_ping="4" && js_2_ping="3" && js_3_ping="5"
[ "$1" == "4" ] && js_1_ping="3" && js_2_ping="2" && js_3_ping="4"
[ "$1" == "3" ] && js_vmess="vmess.js" && js_t_vmess="vmess.txt"
[ "$1" == "4" ] && js_vmess="ss.js" && js_t_vmess="ss.txt"
ping_txt_list="$(ls /tmp/allping_$1 | head -1)"
if [ ! -z "$ping_txt_list" ] ; then
ping_list="$(cat /tmp/allping_$1/$ping_txt_list)"
rm -f /tmp/allping_$1/$ping_txt_list
ss_server_x="$(echo $ping_list | cut -d',' -f "$js_1_ping" | sed -e "s@"'"'"\| \|"'\['"@@g")"
ss_server_x="$(base64decode "$ss_server_x")"
if [ ! -z "$ss_server_x" ] ; then
ss_name_x="$(echo $ping_list | cut -d',' -f "$js_2_ping" | sed -e "s@"'"'"\|"'\['"@@g")"
ss_name_x="$(base64decode "$ss_name_x")"
ss_port_x="$(echo $ping_list | cut -d',' -f "$js_3_ping" | sed -e "s@"'"'"\|"'\['"@@g")"
tcping_time="0"
if [[ "$(tcping -h 2>&1 | wc -l)" -gt 5 ]] ; then
if [ ! -z "$(echo "$ss_name_x" | grep -Eo "剩余流量|过期时间")" ] || [ ! -z "$(echo "$ss_server_x" | grep -Eo "google.com|8.8.8.8")" ] ; then
tcping_time="0"
else
resolveip=`ping -4 -n -q -c1 -w1 -W1 $ss_server_x | head -n1 | sed -r 's/\(|\)/|/g' | awk -F'|' '{print $2}'`
if [ ! -z "$resolveip" ] ; then
ipset -! add proxyaddr $resolveip
ipset -! add ad_spec_dst_sp $resolveip
tcping_text=`tcping -p $ss_port_x -c 1 $resolveip`
tcping_time=`echo $tcping_text | awk -F '/' '{print $4}'| awk -F '.' '{print $1}'`
[[ "$tcping_time" -gt 2 ]] || tcping_time="0"
[[ "$tcping_time" -lt 2 ]] && tcping_time="0"
fi
fi
[ "$tcping_time" == "0" ] && ping_time="" ||  ping_time="$tcping_time"
fi
if [ "$tcping_time" == "0" ] ; then
if [ ! -z "$(cat /tmp/ping_server_error.txt | grep "error_""$ss_server_x""_error")" ] ; then
ping_text=""
else
if [ ! -z "$(echo "$ss_name_x" | grep -Eo "剩余流量|过期时间")" ] || [ ! -z "$(echo "$ss_server_x" | grep -Eo "google.com|8.8.8.8")" ] ; then
ping_text=""
else
ping_text=`ping -4 $ss_server_x -w 3 -W 3 -q`
fi
fi
ping_time=`echo $ping_text | awk -F '/' '{print $4}'| awk -F '.' '{print $1}'`
fi
#ping_loss=`echo $ping_text | awk -F ', ' '{print $3}' | awk '{print $1}'`
i2log="$(expr $(cat /tmp/allping_$1.js | grep -v "^$" |wc -l) + 1)"
ilog=""
[ "$i2log" -gt 0 ] && [ "$ilox" -gt 0 ] && ilog="$(echo "$i2log,$ilox" | awk -F ',' '{printf("%3.0f\n", $1/$2*100)}')"
[ "$ilog" == "" ] && ilog="  0"
[ "$ilog" -gt 100 ] && ilog=100
if [ ! -z "$ping_time" ] ; then
	echo "ping$ilog%：$ping_time ms ✔️ $ss_server_x"
	[ "$tcping_time" == "0" ] && logger -t "【  ping$ilog%】" "$ping_time ms ✔️ $ss_server_x $ss_name_x"
	[ "$tcping_time" != "0" ] && logger -t "【tcping$ilog%】" "$ping_time ms ✔️ $ss_server_x $ss_name_x"
	[ "$ping_time" -le 250 ] && ping_list_btn="btn-success"
	[ "$ping_time" -gt 250 ] && [ "$ping_time" -le 500 ] && ping_list_btn="btn-warning"
	[ "$ping_time" -gt 500 ] && ping_list_btn="btn-danger"
	ping_time2="00000""$ping_time"
	ping_time2="${ping_time2:0-4}"
else
	ping_list_btn="btn-danger"
	echo "ping$ilog%：>1000 ms ❌ $ss_server_x"
	logger -t "【  ping$ilog%】" ">1000 ms ❌ $ss_server_x $ss_name_x"
	ping_time=">1000"
	ping_time2="1000"
	echo "error_""$ss_server_x""_error" >> /tmp/ping_server_error.txt
fi
[ "$mk_ping_txt" == "1" ] && [ -z "$(cat /tmp/link/ping_$js_t_vmess | grep "🔗$ss_server_x=")" ] && echo -n "🔗$ss_server_x=$ping_time🔗" >> /tmp/link/ping_$js_t_vmess
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
vmess_link_ping=`nvram get app_68`
app_99="$(nvram get app_99)"
if [ "$app_99" == 1 ] ; then
	vmess_link_ping=0
	nvram set app_68=0
fi
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
	rm -f /tmp/link_v2_matching/link_v2_matching.txt
	rm -f /www/link/vmess.js
	echo "var ACL3List = [ " > /www/link/vmess.js
	echo ']' >> /www/link/vmess.js
	rm -f /www/link/ss.js
	echo "var ACL4List = [ " > /www/link/ss.js
	echo ']' >> /www/link/ss.js
	sed -Ei '/🔗|dellink_ss|^$/d' /etc/storage/app_25.sh
	vmess_x_tmp=""
	logger -t "【vmess】" "完成清空上次订阅节点配置 请按【F5】刷新 web 查看"
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
B_restart=`echo -n "$vmess_link$vmess_link_up" | md5sum | sed s/[[:space:]]//g | sed s/-//g`
if [ "$A_restart" != "$B_restart" ] ; then
nvram set vmess_link_status=$B_restart
	if [ -z "$vmess_link" ] ; then
		cru.sh d vmess_link_update
		logger -t "【vmess】" "停止 vmess 服务器订阅"
		return
	else
		if [ "$vmess_link_up" != 1 ] ; then
			cru.sh a vmess_link_update "18 */6 * * * $scriptfilepath up_link &" &
			logger -t "【vmess】" "启动 vmess 服务器订阅，添加计划任务 (Crontab)，每6小时更新"
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

logger -t "【vmess】" "服务器订阅：开始更新"

vmess_link="$(echo "$vmess_link" | tr , \  | sed 's@  @ @g' | sed 's@  @ @g' | sed 's@^ @@g' | sed 's@ $@@g' )"
vmess_link_i=""
[ ! -s /www/link/vmess.js ] &&  { rm -f /www/link/vmess.js ; echo "var ACL3List = [ " > /www/link/vmess.js ; echo ']' >> /www/link/vmess.js ; }
[ "$(sed -n 1p /www/link/vmess.js)" != "var ACL3List = [ " ] && { rm -f /www/link/vmess.js ; echo "var ACL3List = [ " > /www/link/vmess.js ; echo ']' >> /www/link/vmess.js ; }
[ ! -s /www/link/ss.js ] &&  { rm -f /www/link/ss.js ; echo "var ACL4List = [ " > /www/link/ss.js ; echo ']' >> /www/link/ss.js ; }
[ "$(sed -n 1p /www/link/ss.js)" != "var ACL4List = [ " ] && { rm -f /www/link/ss.js ; echo "var ACL4List = [ " > /www/link/ss.js ; echo ']' >> /www/link/ss.js ; }
rm -f /tmp/link_v2_matching/link_v2_matching.txt
down_i_link="1"
if [ ! -z "$(echo "$vmess_link" | awk -F ' ' '{print $2}')" ] ; then
	for vmess_link_ii in $vmess_link
	do
		vmess_link_i="$vmess_link_ii"
		down_link
		rm -rf /tmp/vmess/link/*
	done
else
	vmess_link_i="$vmess_link"
	down_link
	rm -rf /tmp/vmess/link/*
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
if [ -z "$(cat /www/link_d.js | grep "🔐📐")" ] ; then
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
if [ -z "$ex_params" ] ; then
	ex_params="$(echo -n $link2 | sed -n '1p' | awk -F '\\?' '{print $2}')"
	[ ! -z "$ex_params" ] && link2="$(echo -n $link2 | sed -n '1p' | awk -F '\\?' '{print $1}')"
else
	link2="$(echo -n $link2 | sed -n '1p' | awk -F '/\\?' '{print $1}')"
fi
if [ ! -z "$ex_params" ] ; then
	#存在插件
	ex_obfsparam="$(echo -n "$ex_params" | grep -Eo "plugin=[^&#]*"  | cut -d '=' -f2)";
	ex_obfsparam=$(printf $(echo -n $ex_obfsparam | sed 's/\\/\\\\/g;s/\(%\)\([0-9a-fA-F][0-9a-fA-F]\)/\\x\2/g'))
	ss_link_plugin_opts=" -O origin -o plain --plugin ""$(echo -n "$ex_obfsparam" |  sed -e 's@;@ --plugin-opts "@' | sed -e 's@$@"@')"
	
else
	ss_link_plugin_opts=" -O origin -o plain --plugin --plugin-opts "
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
ss_link_usage="$(echo -n $link | sed -n '1p' | awk -F '/\\?' '{print $1}')"
if [ -z "$ex_params" ] ; then
	# 兼容漏一个/
	ex_params="$(echo -n $link | sed -n '1p' | awk -F '\\?' '{print $2}')"
	ss_link_usage="$(echo -n $link | sed -n '1p' | awk -F '\\?' '{print $1}')"
fi
ex_obfsparam="$(echo -n "$ex_params" | grep -Eo "obfsparam=[^&]*"  | cut -d '=' -f2 | sed -e "s/_/\//g" | sed -e "s/\-/\+/g" | sed 's/$/&==/g' | base64 -d )"
ex_protoparam="$(echo -n "$ex_params" | grep -Eo "protoparam=[^&]*"  | cut -d '=' -f2 | sed -e "s/_/\//g" | sed -e "s/\-/\+/g" | sed 's/$/&==/g' | base64 -d )"
ex_remarks="$(echo -n "$ex_params" | grep -Eo "remarks[^&]*"  | cut -d '=' -f2 | sed -e "s/_/\//g" | sed -e "s/\-/\+/g" | sed 's/$/&==/g' | base64 -d )"
#ex_group="$(echo -n "$ex_params" | grep -Eo "group[^&]*"  | cut -d '=' -f2 | sed -e "s/_/\//g" | sed -e "s/\-/\+/g" | sed 's/$/&==/g' | base64 -d )"

[ ! -z "$ex_remarks" ] && ss_link_name="$(get_emoji "$(echo -n "$ex_remarks" | sed -e ":a;N;s/\n/_/g;ta" )")"
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

down_link () {

if [ -z  "$(echo "$vmess_link_i" | grep 'http:\/\/')""$(echo "$vmess_link_i" | grep 'https:\/\/')" ]  ; then
	logger -t "【SS】" "$vmess_link_i"
	logger -t "【SS】" "错误！！vmess 服务器订阅文件下载地址不含http(s)://！请检查下载地址"
	return
fi
mkdir -p /tmp/vmess/link
#logger -t "【vmess】" "订阅文件下载: $vmess_link_i"
rm -f /tmp/vmess/link/0_link.txt
wgetcurl.sh /tmp/vmess/link/0_link.txt "$vmess_link_i" "$vmess_link_i" N
if [ ! -s /tmp/vmess/link/0_link.txt ] ; then
	rm -f /tmp/vmess/link/0_link.txt
	curl -L --user-agent "$user_agent" -o /tmp/vmess/link/0_link.txt "$vmess_link_i"
fi
if [ ! -s /tmp/vmess/link/0_link.txt ] ; then
	rm -f /tmp/vmess/link/0_link.txt
	wget -T 5 -t 3 --user-agent "$user_agent" -O /tmp/vmess/link/0_link.txt "$vmess_link_i"
fi
if [ ! -s /tmp/vmess/link/0_link.txt ] ; then
	logger -t "【vmess】" "$vmess_link_i"
	logger -t "【vmess】" "错误！！vmess 服务器订阅文件下载失败！请检查下载地址"
	return
fi
dos2unix /tmp/vmess/link/0_link.txt
sed -e 's@\r@@g' -i /tmp/vmess/link/0_link.txt
sed -e '/^$/d' -i /tmp/vmess/link/0_link.txt
if [ ! -z "$(cat /tmp/vmess/link/0_link.txt | grep "ssd://")" ] ; then
	logger -t "【v2ray】" "解码【ssd://】订阅文件"
	ssd_link /tmp/vmess/link/0_link.txt /www/link/ss.js
	return
fi
sed -e 's/$/&==/g' -i /tmp/vmess/link/0_link.txt
sed -e "s/_/\//g" -i /tmp/vmess/link/0_link.txt
sed -e "s/\-/\+/g" -i /tmp/vmess/link/0_link.txt
cat /tmp/vmess/link/0_link.txt | grep -Eo [^A-Za-z0-9+/=]+ | tr -d "\n" > /tmp/vmess/link/3_link.txt
if [ -s /tmp/vmess/link/3_link.txt ] ; then
	logger -t "【vmess】" "警告！！vmess 服务器订阅文件下载包含非 BASE64 编码字符！"
	logger -t "【vmess】" "请检查服务器配置和链接："
	logger -t "【vmess】" "$vmess_link_i"
	return
fi
rm -f /tmp/vmess/link/3_link.txt
# 开始解码订阅节点配置
cat /tmp/vmess/link/0_link.txt | grep -Eo [A-Za-z0-9+/=]+ | tr -d "\n" > /tmp/vmess/link/1_link.txt
base64 -d /tmp/vmess/link/1_link.txt > /tmp/vmess/link/2_link.txt
rm -f /tmp/vmess/0_link.txt /tmp/vmess/1_link.txt

if [ "$down_i_link" == "1" ] ; then
# 初次导入节点清空旧的订阅
touch /etc/storage/app_25.sh
sed -Ei '/^🔗/d' /etc/storage/app_25.sh
[ -f /www/link/ss.js ] && echo "var ACL4List = [ " > /www/link/ss.js && echo ']' >> /www/link/ss.js
[ -f /www/link/vmess.js ] && echo "var ACL3List = [ " > /www/link/vmess.js && echo ']' >> /www/link/vmess.js
down_i_link=0
fi
if [ ! -z "$(cat /www/link_d.js | grep "app_25.sh")" ] ; then
echo >> /etc/storage/app_25.sh
sed -Ei 's@^@🔗@g' /tmp/vmess/link/2_link.txt
cat /tmp/vmess/link/2_link.txt >> /etc/storage/app_25.sh
sed -Ei '/dellink_ss|^$/d' /etc/storage/app_25.sh
B_restart=`"$(cat /etc/storage/app_25.sh | grep -v "^🔗")" | md5sum | sed s/[[:space:]]//g | sed s/-//g`
nvram set app_25_sh_status=$B_restart
if [ -s /etc/storage/app_25.sh ] ; then
 # 备份提取批量导入链接节点
logger -t "【v2ray】" "批量导入链接节点：开始解码"
mkdir -p /tmp/link
rm -f /tmp/link/link_vmess.txt
rm -f /tmp/link/link_ss.txt
do_link "/etc/storage/app_25.sh" "app_25"
logger -t "【v2ray】" "批量导入链接节点：完成解码"
fi
else
do_link "/tmp/vmess/link/2_link.txt"
fi
rm -rf /tmp/vmess/link/*
}

do_link () {

mkdir -p /tmp/vmess/link
mkdir -p /tmp/link
cp $1 /tmp/vmess/link/do_link.txt
dos2unix /tmp/vmess/link/do_link.txt
sed -e 's@\r@@g' -i /tmp/vmess/link/do_link.txt
sed -e  's@vmess://@\nvmess:://@g' -i /tmp/vmess/link/do_link.txt
sed -e  's@ssr://@\nssr://@g' -i /tmp/vmess/link/do_link.txt
sed -e  's@ss://@\nss://@g' -i /tmp/vmess/link/do_link.txt
sed -e  's@vmess:://@vmess://@g' -i /tmp/vmess/link/do_link.txt
sed -e '/^$/d' -i /tmp/vmess/link/do_link.txt
echo >> /tmp/vmess/link/do_link.txt
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
done < /tmp/vmess/link/do_link.txt
if [ -f /tmp/vmess/link/vmess_link.txt ] ; then
sed -e 's/$/&==/g' -i /tmp/vmess/link/vmess_link.txt
sed -e "s/_/\//g" -i /tmp/vmess/link/vmess_link.txt
sed -e "s/\-/\+/g" -i /tmp/vmess/link/vmess_link.txt
	#awk  'BEGIN{FS="\n";}  {cmd=sprintf("echo -n %s|base64 -d", $1);  system(cmd); print "";}' /tmp/vmess/link/vmess_link.txt > /tmp/vmess/link/vmess2_link.txt
	while read line
	do
	if [ ! -z "$line" ] ; then
		line="$(echo "$line" | awk  'BEGIN{FS="\n";}  {cmd=sprintf("echo -n %s|base64 -d", $1);  system(cmd); print "";}')"
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
		if [ "$2" == "app_25" ] ; then
		sed -Ei "s@]]@],@g" /tmp/link/link_vmess.txt
		sed -Ei '/^\]|^$/d' /tmp/link/link_vmess.txt
		echo "$link_echo" >> /tmp/link/link_vmess.txt
		else
		sed -Ei "s@]]@],@g" /www/link/vmess.js
		sed -Ei '/^\]|^$/d' /www/link/vmess.js
		echo "$link_echo" >> /www/link/vmess.js
		fi
	fi
	done < /tmp/vmess/link/vmess_link.txt
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
		if [ "$2" == "app_25" ] ; then
		sed -Ei "s@]]@],@g" /tmp/link/link_ss.txt
		sed -Ei '/^\]|^$/d' /tmp/link/link_ss.txt
		echo "$link_echo" >> /tmp/link/link_ss.txt
		else
		sed -Ei "s@]]@],@g" /www/link/ss.js
		sed -Ei '/^\]|^$/d' /www/link/ss.js
		echo "$link_echo" >> /www/link/ss.js
		fi
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
		ss_link_plugin_opts=" -O origin -o plain --plugin --plugin-opts "
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
		if [ "$2" == "app_25" ] ; then
		sed -Ei "s@]]@],@g" /tmp/link/link_ss.txt
		sed -Ei '/^\]|^$/d' /tmp/link/link_ss.txt
		echo "$link_echo" >> /tmp/link/link_ss.txt
		else
		sed -Ei "s@]]@],@g" /www/link/ss.js
		sed -Ei '/^\]|^$/d' /www/link/ss.js
		echo "$link_echo" >> /www/link/ss.js
		fi
		fi
		fi
	fi
	done < /tmp/vmess/link/ss_link2.txt
fi

rm -rf /tmp/vmess/link/*
}
ssd_link () {

if [ "$down_i_link" == "1" ] ; then
# 初次导入节点清空旧的订阅
touch /etc/storage/app_25.sh
sed -Ei '/^🔗/d' /etc/storage/app_25.sh
[ -f /www/link/ss.js ] && echo "var ACL4List = [ " > /www/link/ss.js && echo ']' >> /www/link/ss.js
[ -f /www/link/vmess.js ] && echo "var ACL3List = [ " > /www/link/vmess.js && echo ']' >> /www/link/vmess.js
down_i_link=0
fi
mkdir -p /tmp/vmess/link
mkdir -p /tmp/link
rm -f /tmp/vmess/link/ssd_link.txt
cp $1 /tmp/vmess/link/ssd_link.txt
sed -e  's@ssd://@@g' -i /tmp/vmess/link/ssd_link.txt
sed -e  's@$@==@g' -i /tmp/vmess/link/ssd_link.txt
ssd_jq_link="$(cat /tmp/vmess/link/ssd_link.txt | sed -n '1p' | base64 -d)"
ssd_port="$(echo $ssd_jq_link | jq --compact-output --raw-output 'getpath(["port"])')" # 端口
ssd_password="$(echo $ssd_jq_link | jq --compact-output --raw-output 'getpath(["password"])')" # 密码
ssd_encryption="$(echo $ssd_jq_link | jq --compact-output --raw-output 'getpath(["encryption"])')" # 加密
ssd_plugin="$(echo $ssd_jq_link | jq --compact-output --raw-output 'getpath(["plugin"])')" # plugin
ssd_options="$(echo $ssd_jq_link | jq --compact-output --raw-output 'getpath(["plugin_options"])')" # plugin_options
ssd_expiry="$(echo $ssd_jq_link | jq --compact-output --raw-output 'getpath(["expiry"])')" # 时间
ssd_airport="$(echo $ssd_jq_link | jq --compact-output --raw-output 'getpath(["airport"])')" # 名称
ssd_length="$(echo $ssd_jq_link | jq --compact-output --raw-output 'getpath(["servers"]) | length')" # 数量
[ "$ssd_port" == "null" ] && ssd_port=""
[ "$ssd_encryption" == "null" ] && ssd_encryption=""
[ "$ssd_password" == "null" ] && ssd_password=""
[ "$ssd_plugin" == "null" ] && ssd_plugin=""
[ "$ssd_options" == "null" ] && ssd_options=""
logger -t "【SSD订阅】" "【$ssd_airport】过期时间： $ssd_expiry"
ssd_length=$(( ssd_length - 1 ))
if [ "$ssd_length" -ge 0 ] ; then
	for ssd_x in $(seq 0 $ssd_length)
	do
	ssd_jq_x_link="$(echo $ssd_jq_link | jq --compact-output --raw-output 'getpath(["servers",'"$ssd_x"'])')"
	[ ! -z "$(echo $ssd_jq_x_link | grep '"encryption"')" ] && ssd_x_encryption="$(echo $ssd_jq_x_link | jq --compact-output --raw-output 'getpath(["encryption"])')" # 加密
	[ "$ssd_x_encryption" == "null" ] && ssd_x_encryption=""
	[ -z "$ssd_x_encryption" ] && ssd_x_encryption="$ssd_encryption"
	if [ "$ssd_x_encryption" == "aes-256-cfb" ] || [ "$ssd_x_encryption" == "aes-128-cfb" ] || [ "$ssd_x_encryption" == "chacha20" ] || [ "$ssd_x_encryption" == "chacha20-ietf" ] || [ "$ssd_x_encryption" == "aes-256-gcm" ] || [ "$ssd_x_encryption" == "aes-128-gcm" ] || [ "$ssd_x_encryption" == "chacha20-poly1305" ] || [ "$ssd_x_encryption" == "chacha20-ietf-poly1305" ] ; then
		ssd_server="$(echo $ssd_jq_x_link | jq --compact-output --raw-output 'getpath(["server"])')" # 服务器
		ssd_remarks="$(echo $ssd_jq_x_link | jq --compact-output --raw-output 'getpath(["remarks"])')" # 节点名称
		ssd_x_ratio="$(echo $ssd_jq_x_link | jq --compact-output --raw-output 'getpath(["ratio"])')" # ratio
		ssd_x_ratio="$(echo "$ssd_x_ratio" | awk '{printf("%5.3f\n",$1)}')"
		ilog=""
		[ "$ssd_length" -gt 0 ] && [ "$ssd_x" -gt 0 ] && ilog="$(echo "$ssd_x,$ssd_length" | awk -F ',' '{printf("%3.0f\n", $1/$2*100)}')"
		[ "0" == "$ssd_x" ] && ilog="  0"
		[ "$ssd_length" == "$ssd_x" ] && ilog=100
		[ "$ilog" -gt 100 ] && ilog=100
		logger -t "【SSD订阅$ilog%】" "比率:「$ssd_x_ratio」 [ $ssd_server ] $ssd_remarks"
		[ ! -z "$(echo $ssd_jq_x_link | grep '"port"')" ] && ssd_x_port="$(echo $ssd_jq_x_link | jq --compact-output --raw-output 'getpath(["port"])')" # 端口
		[ ! -z "$(echo $ssd_jq_x_link | grep '"password"')" ] && ssd_x_password="$(echo $ssd_jq_x_link | jq --compact-output --raw-output 'getpath(["password"])')" # 密码
		[ ! -z "$(echo $ssd_jq_x_link | grep '"plugin"')" ] && ssd_x_plugin="$(echo $ssd_jq_x_link | jq --compact-output --raw-output 'getpath(["plugin"])')" # plugin
		[ ! -z "$(echo $ssd_jq_x_link | grep '"plugin_options"')" ] && ssd_x_options="$(echo $ssd_jq_x_link | jq --compact-output --raw-output 'getpath(["plugin_options"])')" # plugin_options
		[ "$ssd_x_ratio" == "null" ] && ssd_x_ratio=""
		[ "$ssd_x_ratio" == "1" ] && ssd_x_ratio=""
		[ "$ssd_x_ratio" == "1.000" ] && ssd_x_ratio=""
		[ ! -z "$ssd_x_ratio" ] && ssd_x_ratio="「$ssd_x_ratio」"
		[ "$ssd_x_port" == "null" ] && ssd_x_port=""
		[ "$ssd_x_password" == "null" ] && ssd_x_password=""
		[ "$ssd_x_plugin" == "null" ] && ssd_x_plugin=""
		[ "$ssd_x_options" == "null" ] && ssd_x_options=""
		[ -z "$ssd_x_port" ] && ssd_x_port="$ssd_port"
		[ -z "$ssd_x_password" ] && ssd_x_password="$ssd_password"
		[ -z "$ssd_x_plugin" ] && ssd_x_plugin="$ssd_plugin"
		[ -z "$ssd_x_options" ] && ssd_x_options="$ssd_options"
		ss_link_plugin_opts=" -O origin -o plain --plugin $ssd_x_plugin --plugin-opts $ssd_x_options "
		link_echo=""
		link_echo="$link_echo"'["ss", '
		vmess_link_ps="$ssd_remarks"
		ss_link_name="$(base64encode "$ssd_remarks $ssd_x_ratio")"
		link_echo="$link_echo"'"'"$ss_link_name"'", '
		link_echo="$link_echo"'"'"$ssd_server"'", '
		vmess_link_add="$ssd_server"
		link_echo="$link_echo"'"'"$ssd_x_port"'", '
		ss_link_password="$(base64encode "$ssd_x_password")"
		link_echo="$link_echo"'"'"$ss_link_password"'", '
		link_echo="$link_echo"'"'"$ssd_x_encryption"'", '
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
	done
fi
rm -rf /tmp/vmess/link/*
}

check_app_25 () {
a1_tmp="$1"
if [[ "$(jq -h 2>&1 | wc -l)" -lt 2 ]] ; then
json_jq_check
if [[ "$(jq -h 2>&1 | wc -l)" -lt 2 ]] ; then
	logger -t "【v2ray】" "错误！找不到 jq 程序"
	return 1
fi
fi
touch /etc/storage/app_25.sh
if [ -s /etc/storage/app_25.sh ] ; then
app_95="$(nvram get app_95)"
A_restart="$(nvram get app_25_sh_status)"
B_restart="$app_95""$(cat /etc/storage/app_25.sh | grep -v "^🔗")"
B_restart=`echo -n "$B_restart" | md5sum | sed s/[[:space:]]//g | sed s/-//g`
if [ "$A_restart" == "$B_restart" ] ; then
 # 文件没更新，停止ping
a1_tmp="X_allping"
fi
 # 读取批量导入链接节点
if [ ! -z "$(cat /etc/storage/app_25.sh | grep -v "^#" | grep -v "^$" | grep "vmess://\|ss://\|ssr://" )" ] && [ -z "$(cat /tmp/link/link_vmess.txt /tmp/link/link_ss.txt | grep -v "^#" | grep -v '^\]' | grep -v "ACL3List = " | grep -v "ACL4List = " | grep -v "^$")" ] ; then
A_restart=""
fi
if [ "$A_restart" != "$B_restart" ] ; then
nvram set app_25_sh_status=$B_restart
 # 备份提取批量导入链接节点
logger -t "【v2ray】" "批量导入链接节点：开始解码"
mkdir -p /tmp/link
rm -f /tmp/link/link_vmess.txt
rm -f /tmp/link/link_ss.txt
do_link "/etc/storage/app_25.sh" "app_25"
logger -t "【v2ray】" "批量导入链接节点：完成解码"
if [ "$a1_tmp" != "X_allping" ] ; then
vmess_link_ping=`nvram get app_68`
vmess_x_tmp="`nvram get app_83`"
if [ "$vmess_x_tmp" != "ping_link" ] ; then
if [ "$vmess_link_ping" != 1 ] ; then
	allping 3
	allping 4
else
	echo "$ss_link_name：停止ping订阅节点"
fi
app_99="$(nvram get app_99)"
if [ "$app_99" == 1 ] ; then
rm -f /tmp/link_v2_matching/link_v2_matching.txt
v2ray_link_v2_matching
fi
fi
fi
fi
fi

}

v2ray_link_v2_matching(){

check_app_25 "X_allping"
if [[ "$(jq -h 2>&1 | wc -l)" -lt 2 ]] ; then
json_jq_check
if [[ "$(jq -h 2>&1 | wc -l)" -lt 2 ]] ; then
	return 1
fi
fi
# 排序节点
mkdir -p /tmp/link_v2_matching
if [ ! -f /tmp/link_v2_matching/link_v2_matching.txt ] || [ ! -s /tmp/link_v2_matching/link_v2_matching.txt ] ; then
match="$(nvram get app_95)"
[ "$match" == "*" ] && match="."
mismatch="$(nvram get app_96)"

cat /www/link/ss.js /www/link/vmess.js > /tmp/link_v2_matching/0.txt
echo -n "" > /tmp/link_v2_matching/1.txt
[ -s /tmp/link/link_ss.txt ] && cat /tmp/link/link_ss.txt >> /tmp/link_v2_matching/0.txt
[ -s /tmp/link/link_vmess.txt ] && cat /tmp/link/link_vmess.txt >> /tmp/link_v2_matching/0.txt
sed -Ei "/^var ACL2List|^\[\]\]/d" /tmp/link_v2_matching/0.txt
sed -Ei "/^var ACL3List|^\]/d" /tmp/link_v2_matching/0.txt
sed -Ei "/^var ACL4List|^$/d" /tmp/link_v2_matching/0.txt
sed -Ei "s@]]@],@g" /tmp/link_v2_matching/0.txt
while read line
do
if [ ! -z "$(echo -n "$line" | grep "🔐📐")" ] ; then
	# 解码base64
	line0="$(echo -n "$line" | awk -F "🔐📐" '{print $2}' | awk -F "📐🔐" '{print $1}')"
	line0="$(base64decode 🔐📐"$line0"📐🔐)"'",'
else
	line0="$line"
fi
[ ! -z "$mismatch" ] && line3="$(echo "$line0" | grep -E .+'",' | cut -d',' -f1 | grep -E "$match" | grep -v -E "$mismatch" | grep -v -E "剩余流量|过期时间")"
[ -z "$mismatch" ] && line3="$(echo "$line0" | grep -E .+'",' | cut -d',' -f1 | grep -E "$match" | grep -v -E "剩余流量|过期时间")"
[ -z "$match" ] && line3="line3"
line4="line4" ; line2="" ; 
if [ ! -z "$line3" ] ; then
line2_type="$(echo "$line" | sed -e "s@\ @@g" | awk -F '"' '{ print($2) }')"
[ "$line2_type" == "ss" ] && line2_server_type=3
[ "$line2_type" == "vmess" ] && line2_server_type=4
line2_server="$(echo "$line" | sed -e "s@\ @@g" | awk -F ',' '{ print($'$line2_server_type') }' | sed -e 's@\"@@g')"
[ ! -z "$line2_server" ] && line2="$(cat /etc/storage/link/ping_$line2_type.js | sed -e "s@\ @@g" | awk -F "$line2_server=" '{ print($2) }' | awk -F "🔗" '{ print($1) }')"
[ -z "$line2" ] && line2="$(echo "$line" | grep -E -o \"btn-success.+\ ms\", | cut -d',' -f2 | grep -E -o \".+\" | grep -Eo [0-9]+ )"
[ -z "$line2" ] && line2="$(echo "$line" | grep -E -o \"btn-warning.+\ ms\", | cut -d',' -f2 | grep -E -o \".+\" | grep -Eo [0-9]+ )"
[ -z "$line2" ] && line2="$(echo "$line" | grep -E -o \"btn-danger.+\ ms\", | cut -d',' -f2 | grep -E -o \".+\" | grep -Eo [0-9]+ )"
[ ! -z "$line2" ] && line2="00000""$line2" && echo -n "${line2:0-4}" >> /tmp/link_v2_matching/1.txt && line4=""
[ ! -z "$line4" ] && line2="0000" && echo -n "$line2" >> /tmp/link_v2_matching/1.txt
echo -n "$line" >> /tmp/link_v2_matching/1.txt
echo "" >> /tmp/link_v2_matching/1.txt
fi
done < /tmp/link_v2_matching/0.txt
cat /tmp/link_v2_matching/1.txt | sort  | grep -v "^$" > /tmp/link_v2_matching/2.txt
echo -n "" > /tmp/link_v2_matching/link_v2_matching.txt
while read line
do
line="$(echo $line | sed -e 's/],/]/g' )"
echo ${line:4} >> /tmp/link_v2_matching/link_v2_matching.txt
done < /tmp/link_v2_matching/2.txt
rm -f /tmp/link_v2_matching/?.txt
logger -t "【自动选用节点】" "重新生成自动选用节点列表： /tmp/link_v2_matching/link_v2_matching.txt"
fi
# 选用节点
if [ -z "$(cat /tmp/link_v2_matching/link_v2_matching.txt | grep -v 已经自动选用节点)" ] ; then
sed -e 's/已经自动选用节点//g' -i /tmp/link_v2_matching/link_v2_matching.txt
fi
i_matching=1
while read line
do
line2="$(echo "$line" | grep -v "已经自动选用节点" )"
if [ ! -z "$line2" ] ; then
line2_type="$(echo "$line" | sed -e "s@\ @@g" | awk -F '"' '{ print($2) }')"
if [ "$line2_type" == "ss" ] ; then
app_98="$(echo $line| jq --compact-output --raw-output 'getpath([1])')"
app_98="$(base64decode "$app_98")"
ss_server="$(echo $line| jq --compact-output --raw-output 'getpath([2])')"
ss_server_port="$(echo $line| jq --compact-output --raw-output 'getpath([3])')"
ss_key="$(echo $line| jq --compact-output --raw-output 'getpath([4])')"
ss_key="$(base64decode "$ss_key")"
ss_method="$(echo $line| jq --compact-output --raw-output 'getpath([5])')"
#ss_usage="$(echo $line| jq --compact-output --raw-output 'getpath([8])')"
#ss_usage="$(base64decode "$ss_usage")"
[ -z "$app_98" ] && app_98="♯$ss_server"
logger -t "【自动选用节点】" "已经自动选用节点： [ss]$app_98"
[ -z "$ss_server" ] && logger -t "【自动选用节点】" "错误！！！获取 ss_server 数据为空 " && break
[ -z "$ss_server_port" ] && logger -t "【自动选用节点】" "错误！！！获取 ss_server_port 数据为空 " && break
[ -z "$ss_key" ] && logger -t "【自动选用节点】" "错误！！！获取 ss_key 数据为空 " && break
[ -z "$ss_method" ] && logger -t "【自动选用节点】" "错误！！！获取 ss_method 数据为空 " && break
#[ -z "$ss_usage" ] && logger -t "【自动选用节点】" "错误！！！获取 ss_usage 数据为空 " && break
nvram set app_98="[ss]$app_98"
sed -i $i_matching's/^/已经自动选用节点/' /tmp/link_v2_matching/link_v2_matching.txt
nvram set app_72="$app_98"
nvram set app_73="$ss_server"
nvram set app_74="$ss_server_port"
nvram set app_75="$ss_key"
nvram set app_78="$ss_method"
nvram set app_77=""
nvram set app_79="0"
nvram set app_82="ss"
nvram set app_71=""
nvram set app_76=""
nvram set app_80=""
nvram set app_81=""
fi
if [ "$line2_type" == "vmess" ] ; then
obj_v="$(echo $line| jq --compact-output --raw-output 'getpath([1])')"
obj_ps="$(echo $line| jq --compact-output --raw-output 'getpath([2])')"
obj_ps="$(base64decode "$obj_ps")"
obj_add="$(echo $line| jq --compact-output --raw-output 'getpath([3])')"
obj_port="$(echo $line| jq --compact-output --raw-output 'getpath([4])')"
obj_id="$(echo $line| jq --compact-output --raw-output 'getpath([5])')"
obj_aid="$(echo $line| jq --compact-output --raw-output 'getpath([6])')"
obj_net="$(echo $line| jq --compact-output --raw-output 'getpath([7])')"
obj_type="$(echo $line| jq --compact-output --raw-output 'getpath([8])')"
obj_host="$(echo $line| jq --compact-output --raw-output 'getpath([9])')"
obj_path="$(echo $line| jq --compact-output --raw-output 'getpath([10])')"
obj_tls="$(echo $line| jq --compact-output --raw-output 'getpath([11])')"
app_98="$obj_ps";
logger -t "【自动选用节点】" "已经自动选用节点： [vmess]$app_98"
[ -z "$obj_add" ] && logger -t "【自动选用节点】" "错误！！！获取 add 数据为空 " && break
[ -z "$obj_port" ] && logger -t "【自动选用节点】" "错误！！！获取 port 数据为空 " && break
#[ -z "$obj_id" ] && logger -t "【自动选用节点】" "错误！！！获取 id 数据为空 " && break
#[ -z "$obj_aid" ] && logger -t "【自动选用节点】" "错误！！！获取 aid 数据为空 " && break
[ -z "$obj_net" ] && logger -t "【自动选用节点】" "错误！！！获取 net 数据为空 " && break
nvram set app_98="[vmess]$app_98"
sed -i $i_matching's/^/已经自动选用节点/' /tmp/link_v2_matching/link_v2_matching.txt
nvram set app_71="$obj_v"
nvram set app_72="$obj_ps"
nvram set app_73="$obj_add"
nvram set app_74="$obj_port"
nvram set app_75="$obj_id"
nvram set app_76="$obj_aid"
nvram set app_77="$obj_net"
nvram set app_78="$obj_type"
nvram set app_79="$obj_host"
nvram set app_80="$obj_path"
nvram set app_81="$obj_tls"
nvram set app_82="vmess"
fi
# 重启v2ray
[ "$v2ray_enable" == "0" ] && return
eval "$scriptfilepath &"
exit
break
fi
i_matching=`expr $i_matching + 1`
done < /tmp/link_v2_matching/link_v2_matching.txt

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
	[ "$v2ray_enable" != "1" ] && [ -f "$v2ray_path" ] && nvram set v2ray_v="" && logger -t "【v2ray】" "更新" && { rm -rf $v2ray_path $v2ctl_path $geoip_path $geosite_path ; rm -rf /opt/opt_backup/bin/v2ray ; rm -f /opt/bin/v2ctl /opt/opt_backup/bin/v2ctl ; rm -f /opt/bin/v2ray_config.pb ; rm -f /opt/bin/geoip.dat /opt/opt_backup/bin/geoip.dat ; rm -f /opt/bin/geosite.dat /opt/opt_backup/bin/geosite.dat ; }
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
check_app_25)
	check_app_25
	;;
v2ray_link_v2_matching)
	v2ray_link_v2_matching
	;;
*)
	v2ray_check
	;;
esac

