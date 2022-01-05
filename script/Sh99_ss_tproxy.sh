#!/bin/bash
#copyright by hiboy
source /etc/storage/script/init.sh
ss_tproxy_enable=`nvram get app_109`
[ -z $ss_tproxy_enable ] && ss_tproxy_enable=0 && nvram set app_109=0
ss_tproxy_mode_x=`nvram get app_110`
[ -z $ss_tproxy_mode_x ] && ss_tproxy_mode_x=0 && nvram set app_110=0
ss_tproxy_update=`nvram get app_111`
[ -z $ss_tproxy_update ] && ss_tproxy_update=0 && nvram set app_111=0
dns_start_dnsproxy=`nvram get app_112`
[ -z $dns_start_dnsproxy ] && dns_start_dnsproxy=0 && nvram set app_112=0
ss_pdnsd_cn_all=`nvram get app_113`
[ -z $ss_pdnsd_cn_all ] && ss_pdnsd_cn_all=0 && nvram set app_113=0
output_return=`nvram get app_114`
[ -z $output_return ] && output_return=0 && nvram set app_114=0
ss_pdnsd_all=`nvram get ss_pdnsd_all`
[ -z $ss_pdnsd_all ] && ss_pdnsd_all=0 && nvram set ss_pdnsd_all=0
ss_dnsproxy_x=`nvram get ss_dnsproxy_x`
[ -z $ss_dnsproxy_x ] && ss_dnsproxy_x=0 && nvram set ss_dnsproxy_x=0
ss_3p_enable=`nvram get ss_3p_enable`
ss_3p_gfwlist=`nvram get ss_3p_gfwlist`
ss_3p_kool=`nvram get ss_3p_kool`
ss_sub1=`nvram get ss_sub1`
ss_sub2=`nvram get ss_sub2`
ss_sub3=`nvram get ss_sub3`
ss_sub4=`nvram get ss_sub4`
ss_sub5=`nvram get ss_sub5`
ss_sub6=`nvram get ss_sub6`
ss_sub7=`nvram get ss_sub7`
ss_sub8=`nvram get ss_sub8`
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
if [ "$chinadns_enable" != "0" ] || [ "$chinadns_ng_enable" != "0" ] ; then
	ss_dnsproxy_x=2 ; nvram set ss_dnsproxy_x=2
else
	[ "$ss_dnsproxy_x" = "2" ] && ss_dnsproxy_x=0 && nvram set ss_dnsproxy_x=0
fi
koolproxy_enable=`nvram get koolproxy_enable`

if [ ! -z "$(echo $scriptfilepath | grep -v "/tmp/script/" | grep ss_tproxy)" ] && [ ! -s /tmp/script/_app21 ]; then
	nvram set ss_tproxy_auser=""
	mkdir -p /tmp/script
	{ echo '#!/bin/bash' ; echo $scriptfilepath '"$@"' '&' ; } > /tmp/script/_app21
	chmod 777 /tmp/script/_app21
fi

auser_check() {

[ -z "$auser_a" ] && auser_a="$1"
[ -z "$auser_a" ] && return
auser_b="$(nvram get ss_tproxy_auser)"
if [ -z "$auser_b" ] ; then
	nvram set ss_tproxy_auser="$auser_a"
	return
fi
[ "$auser_a" == "$auser_b" ] && return
if [ "$auser_a" != "$auser_b" ] && [ "$2" != "stop" ] ; then
	logger -t "【ss_tproxy】" "脚本 [Sh99_ss_tproxy.sh] 当前使用者: $auser_b ，跳过 $auser_a 的运行命令"
	logger -t "【ss_tproxy】" "需要停用 $auser_b 后才能使用 $auser_a 运行 [Sh99_ss_tproxy.sh] 脚本"
fi
exit

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

ss_tproxy_restart () {

relock="/var/lock/ss_tproxy_restart.lock"
if [ "$1" = "o" ] ; then
	nvram set ss_tproxy_renum="0"
	[ -f $relock ] && rm -f $relock
	return 0
fi
if [ "$1" = "x" ] ; then
	if [ -f $relock ] ; then
		logger -t "【ss_tproxy】" "多次尝试启动失败，等待【"`cat $relock`"分钟】后自动尝试重新启动"
		exit 0
	fi
	ss_tproxy_renum=${ss_tproxy_renum:-"0"}
	ss_tproxy_renum=`expr $ss_tproxy_renum + 1`
	nvram set ss_tproxy_renum="$ss_tproxy_renum"
	if [ "$ss_tproxy_renum" -gt "2" ] ; then
		I=1
		echo $I > $relock
		logger -t "【ss_tproxy】" "多次尝试启动失败，等待【"`cat $relock`"分钟】后自动尝试重新启动"
		while [ $I -gt 0 ]; do
			I=$(($I - 1))
			echo $I > $relock
			sleep 60
			[ "$(nvram get ss_tproxy_renum)" = "0" ] && exit 0
			[ $I -lt 0 ] && break
		done
		nvram set ss_tproxy_renum="0"
	fi
	[ -f $relock ] && rm -f $relock
fi
nvram set ss_tproxy_status=0
eval "$scriptfilepath &"
exit 0
}

ss_tproxy_get_status () {

A_restart=`nvram get ss_tproxy_status`
B_restart="$ss_tproxy_enable$ss_tproxy_mode_x$ss_pdnsd_all$ss_dnsproxy_x$ss_udp_enable$chinadns_enable$chinadns_ng_enable$(cat /etc/storage/app_27.sh | grep -v "^#" | grep -v "^$")$(cat /etc/storage/app_26.sh | grep -v "^#" | grep -v "^$")"
C_restart="$ss_udp_enable$dns_start_dnsproxy$ss_pdnsd_cn_all$output_return$ss_pdnsd_all$ss_dnsproxy_x$ss_3p_enable$ss_3p_gfwlist$ss_3p_kool$ss_sub1$ss_sub2$ss_sub3$ss_sub4$ss_sub5$ss_sub6$ss_sub7$ss_sub8$chinadns_enable$chinadns_ng_enable$chinadns_port$koolproxy_enable$(cat /etc/storage/app_26.sh | grep -v "^#" | grep -v "^$")"
B_restart=`echo -n "$B_restart" | md5sum | sed s/[[:space:]]//g | sed s/-//g`
cut_B_re
C_restart=`echo -n "$C_restart" | md5sum | sed s/[[:space:]]//g | sed s/-//g`
cut_C_re
if [ "$A_restart" != "$B_restart" ] ; then
	nvram set ss_tproxy_status=$B_restart
	sstp_set ss_tproxy_status="$C_restart"
	needed_restart=1
else
	needed_restart=0
fi
}

ss_tproxy_check () {

ss_tproxy_rules_update
ss_tproxy_get_status
if [ "$ss_tproxy_enable" != "1" ] && [ "$needed_restart" = "1" ] ; then
	port=$(iptables -t nat -L | grep 'SSTP' | wc -l)
	[ "$port"x == 0x ] && port=$(iptables -t mangle -L | grep 'SSTP' | wc -l)
	[ "$port"x != 0x ] && logger -t "【ss_tproxy】" "停止 ss_tproxy" && ss_tproxy_close
	{ kill_ps "$scriptname" exit0; exit 0; }
fi
if [ "$ss_tproxy_enable" = "1" ] ; then
	if [ "$needed_restart" = "1" ] ; then
		ss_tproxy_close
		ss_tproxy_start
	else
		if [ "$dns_start_dnsproxy" != "1" ] && [ "$ss_dnsproxy_x" != "2" ] && [ "$mode" != "chnlist" ] ; then
			[ -z "`pidof dnsproxy`" ] && [ -z "`pidof pdnsd`" ] && logger -t "【ss_tproxy】" "检测1:找不到 dnsproxy , 重新添加" && ss_tproxy_restart
		fi
		port=$(iptables -t nat -L | grep 'SSTP' | wc -l)
		[ "$port"x == 0x ] && port=$(iptables -t mangle -L | grep 'SSTP' | wc -l)
		if [ "$port"x == 0x ] ; then
			logger -t "【ss_tproxy】" "检测2:找不到 SSTP 转发规则, 重新添加"
			ss_tproxy_run "start_iptables"
		fi
		if [ "$mode" == "chnlist" ] ; then
			# 回国模式 检测远程 DNS 转发规则
			port=$(grep "server=$dns_remote"  /etc/storage/dnsmasq/dnsmasq.conf | wc -l)
			if [ "$port" = 0 ] ; then
				sleep 10
				port=$(grep "server=$dns_remote"  /etc/storage/dnsmasq/dnsmasq.conf | wc -l)
			fi
			if [ "$port" = 0 ] ; then
				logger -t "【ss_tproxy】" "$mode 检测1:找不到 dnsmasq [server=$dns_remote] 转发规则, 重新添加"
				ss_tproxy start_dnsserver_confset
			fi
		fi
		if [ "$ss_pdnsd_all" == "1" ] ; then
			port=$(grep "server=127.0.0.1#8053"  /etc/storage/dnsmasq/dnsmasq.conf | wc -l)
			if [ "$port" = 0 ] ; then
				sleep 10
				port=$(grep "server=127.0.0.1#8053"  /etc/storage/dnsmasq/dnsmasq.conf | wc -l)
			fi
			if [ "$port" = 0 ] ; then
				logger -t "【ss_tproxy】" "$mode 检测2:找不到 dnsmasq [server=127.0.0.1#8053] 转发规则, 重新添加"
				ss_tproxy start_dnsserver_confset
			fi
		fi
		port=$(grep "$dnsmasq_string_arg"  /etc/storage/dnsmasq/dnsmasq.conf | wc -l)
		if [ "$port" = 0 ] ; then
			sleep 10
			port=$(grep "$dnsmasq_string_arg"  /etc/storage/dnsmasq/dnsmasq.conf | wc -l)
		fi
		if [ "$port" = 0 ] ; then
			logger -t "【ss_tproxy】" "$mode 检测3:找不到 dnsmasq [$dnsmasq_string_arg] 转发规则, 重新添加"
			ss_tproxy start_dnsserver_confset
		fi
	fi
fi
}

ss_tproxy_keep () {
logger -t "【ss_tproxy】" "守护进程启动"
sleep 20
/etc/storage/script/sh_ezscript.sh 3 & #更新按钮状态
if [ -s /tmp/script/_opt_script_check ]; then
sed -Ei '/【ss_tproxy】|^$/d' /tmp/script/_opt_script_check
cat >> "/tmp/script/_opt_script_check" <<-OSC
	[ -z "\`pidof Sh99_ss_tproxy.sh\`" ] && nvram set ss_tproxy_status=00 && logger -t "【ss_tproxy】" "重新启动" && eval "$scriptfilepath &" && sed -Ei '/【ss_tproxy】|^$/d' /tmp/script/_opt_script_check # 【ss_tproxy】
OSC
#return
fi

while true; do
	ss_dnsproxy_x=`nvram get ss_dnsproxy_x`
	if [ "$dns_start_dnsproxy" != "1" ] && [ "$ss_dnsproxy_x" != "2" ] && [ "$mode" != "chnlist" ] ; then
		[ -z "`pidof dnsproxy`" ] && [ -z "`pidof pdnsd`" ] && logger -t "【ss_tproxy】" "检测1:找不到 dnsproxy , 重新添加" && ss_tproxy_restart
	fi
	port=$(iptables -t nat -L | grep 'SSTP' | wc -l)
	[ "$port"x == 0x ] && port=$(iptables -t mangle -L | grep 'SSTP' | wc -l)
	if [ "$port"x == 0x ] ; then
		logger -t "【ss_tproxy】" "检测2:找不到 SSTP 转发规则, 重新添加"
		ss_tproxy_run "start_iptables"
	fi
	if [ "$mode" == "chnlist" ] ; then
		# 回国模式 检测远程 DNS 转发规则
		port=$(grep "server=$dns_remote"  /etc/storage/dnsmasq/dnsmasq.conf | wc -l)
		if [ "$port" = 0 ] ; then
			sleep 10
			port=$(grep "server=$dns_remote"  /etc/storage/dnsmasq/dnsmasq.conf | wc -l)
		fi
		if [ "$port" = 0 ] ; then
			logger -t "【ss_tproxy】" "$mode 检测1:找不到 dnsmasq [server=$dns_remote] 转发规则, 重新添加"
			ss_tproxy start_dnsserver_confset
		fi
	fi
	if [ "$ss_pdnsd_all" == "1" ] ; then
		port=$(grep "server=127.0.0.1#8053"  /etc/storage/dnsmasq/dnsmasq.conf | wc -l)
		if [ "$port" = 0 ] ; then
			sleep 10
			port=$(grep "server=127.0.0.1#8053"  /etc/storage/dnsmasq/dnsmasq.conf | wc -l)
		fi
		if [ "$port" = 0 ] ; then
			logger -t "【ss_tproxy】" "$mode 检测2:找不到 dnsmasq [server=127.0.0.1#8053] 转发规则, 重新添加"
			ss_tproxy start_dnsserver_confset
		fi
	fi
	port=$(grep "$dnsmasq_string_arg"  /etc/storage/dnsmasq/dnsmasq.conf | wc -l)
	if [ "$port" = 0 ] ; then
		sleep 10
		port=$(grep "$dnsmasq_string_arg"  /etc/storage/dnsmasq/dnsmasq.conf | wc -l)
	fi
	if [ "$port" = 0 ] ; then
		logger -t "【ss_tproxy】" "$mode 检测3:找不到 dnsmasq [$dnsmasq_string_arg] 转发规则, 重新添加"
		ss_tproxy start_dnsserver_confset
	fi
	dnsmasq_file="`ls -p /tmp/ss_tproxy/dnsmasq.d | grep -v tmp | grep -v /`"
[ ! -z "$dnsmasq_file" ] && echo "$dnsmasq_file" | while read conf_file; do [ "$(cat /tmp/ss_tproxy/dnsmasq.d/$conf_file | grep -c "server=\|ipset=")" == "0" ] &&  rm -f /tmp/ss_tproxy/dnsmasq.d/$conf_file ; done
sleep 60
done
}

ss_tproxy_close () {
kill_ps "Sh99_ss_tproxy.sh keep"
sed -Ei '/【ss_tproxy】|^$/d' /tmp/script/_opt_script_check
ss_tproxy_run "stop"
nvram set ss_tproxy_auser="$auser_a"
restart_dhcpd &
killall ss_tproxy sh_ss_tproxy.sh
killall -9 ss_tproxy sh_ss_tproxy.sh
/etc/storage/script/sh_ezscript.sh 3 & #更新按钮状态
kill_ps "/tmp/script/_app21"
kill_ps "_ss_tproxy.sh"
kill_ps "$scriptname"
}

ss_tproxy_rules_update () {
[ "$ss_tproxy_update" == "0" ] && return
nvram set app_111=0 ; nvram commit ;
for h_i in $(seq 1 2) ; do
[ -z "$(grep "main " /etc/storage/script/sh_ss_tproxy.sh)" ] && rm -rf /etc/storage/script/sh_ss_tproxy.sh
wgetcurl_file /etc/storage/script/sh_ss_tproxy.sh "$hiboyscript/script/sh_ss_tproxy.sh" "$hiboyscript2/script/sh_ss_tproxy.sh"
done
rm -f /opt/app/ss_tproxy/tmp/*.md5
if [ "$ss_tproxy_update" == "1" ] ; then
	logger -t "【ss_tproxy】" "更新 gfwlist + chnroute 规则" 
	sh_ss_tproxy.sh update_gfwlist
	sh_ss_tproxy.sh update_chnroute
	sh_ss_tproxy.sh update_wanlanlist_ipset
fi
if [ "$ss_tproxy_update" == "2" ] ; then
	logger -t "【ss_tproxy】" "更新 chnroute [白名单IP]规则" 
	sh_ss_tproxy.sh update_chnroute
	sh_ss_tproxy.sh update_wanlanlist_ipset
fi
if [ "$ss_tproxy_update" == "26" ] ; then
	logger -t "【ss_tproxy】" "更新 chnroute6 [白名单IP]规则" 
	sh_ss_tproxy.sh update_chnroute6
	sh_ss_tproxy.sh update_wanlanlist_ipset6
fi
if [ "$ss_tproxy_update" == "3" ] ; then
	logger -t "【ss_tproxy】" "更新 gfwlist [黑名单域名]规则" 
	sh_ss_tproxy.sh update_gfwlist
	sh_ss_tproxy.sh update_wanlanlist_ipset
fi
if [ "$ss_tproxy_update" == "4" ] ; then
	logger -t "【ss_tproxy】" "更新 chnlist [白名单域名]规则规则" 
	sh_ss_tproxy.sh update_chnlist
	sh_ss_tproxy.sh update_wanlanlist_ipset
fi
if [ "$ss_tproxy_update" == "5" ] ; then
	logger -t "【ss_tproxy】" "更新 [全部] 规则" 
	sh_ss_tproxy.sh update_gfwlist
	sh_ss_tproxy.sh update_chnroute
	sh_ss_tproxy.sh update_chnlist
	sh_ss_tproxy.sh update_wanlanlist_ipset
fi
if [ "$ss_tproxy_update" == "6" ] ; then
	logger -t "【ss_tproxy】" "更新脚本" 
	sh_upscript.sh upscript
fi
if [ "$ss_tproxy_update" == "7" ] ; then
	logger -t "【ss_tproxy】" "重置 ss_tproxy 数据(出错了？重置试试)" 
	nvram set ss_tproxy_auser=""
	nvram set ss_3p_enable=0
	nvram set ss_pdnsd_all=0
	nvram set ss_DNS_Redirect=0
	rm -f /opt/app/ss_tproxy/conf/*
	rm -f /opt/app/ss_tproxy/dnsmasq.d/*
	rm -f /tmp/ss_tproxy/dnsmasq.d/*
	rm -f /opt/app/ss_tproxy/rule/*
	rm -f /opt/app/ss_tproxy/tmp/*
	rm -f /etc/storage/app_27.sh
	initconfig
	logger -t "【ss_tproxy】" "完成重置。"
fi
}

ss_tproxy_start () {
ipt_m_check
check_webui_yes
for h_i in $(seq 1 2) ; do
[ -z "$(grep "main " /etc/storage/script/sh_ss_tproxy.sh)" ] && rm -rf /etc/storage/script/sh_ss_tproxy.sh
wgetcurl_file /etc/storage/script/sh_ss_tproxy.sh "$hiboyscript/script/sh_ss_tproxy.sh" "$hiboyscript2/script/sh_ss_tproxy.sh"
done
rm -f /opt/app/ss_tproxy/ss_tproxy.conf
ln -sf /etc/storage/app_27.sh /opt/app/ss_tproxy/ss_tproxy.conf
[ ! -s /opt/app/ss_tproxy/ss_tproxy.conf ] && cp -f /etc/storage/app_27.sh /opt/app/ss_tproxy/ss_tproxy.conf
rm -f /opt/app/ss_tproxy/ss_tproxy
ln -sf /etc/storage/script/sh_ss_tproxy.sh /opt/app/ss_tproxy/ss_tproxy
[ ! -s /opt/app/ss_tproxy/ss_tproxy ] && cp -f /etc/storage/script/sh_ss_tproxy.sh /opt/app/ss_tproxy/ss_tproxy
rm -f /opt/bin/ss_tproxy
ln -sf /etc/storage/script/sh_ss_tproxy.sh /opt/bin/ss_tproxy
[ ! -s /opt/bin/ss_tproxy ] && cp -f /etc/storage/script/sh_ss_tproxy.sh /opt/bin/ss_tproxy

Available_A=$(df -m | grep "% /opt" | awk 'NR==1' | awk -F' ' '{print $4}')
size_tmpfs=`nvram get size_tmpfs`
if [ "$size_tmpfs" = "0" ] && [[ "$Available_A" -lt 15 ]] ; then
mount -o remount,size=50% tmpfs /tmp
Available_B=$(df -m | grep "% /opt" | awk 'NR==1' | awk -F' ' '{print $4}')
logger -t "【ss_tproxy】" "调整 /tmp 挂载分区的大小， /opt 可用空间： $Available_A → $Available_B M"
fi
ss_tproxy_v="$(sh_ss_tproxy.sh v | awk -F ' ' '{print $2;}')"
nvram set ss_tproxy_v="$ss_tproxy_v"
app21_ver=$(grep 'app21_ver=' /opt/app/ss_tproxy/Advanced_Extensions_ss_tproxy.asp | awk -F '=' '{print $2;}')
nvram set app21_ver=${app21_ver}
logger -t "【ss_tproxy】" "运行 /etc/storage/script/sh_ss_tproxy.sh"
#运行脚本启动sh_ss_tproxy.sh
sh_ss_tproxy.sh start
port=$(iptables -t nat -L | grep 'SSTP' | wc -l)
[ "$port"x == 0x ] && port=$(iptables -t mangle -L | grep 'SSTP' | wc -l)
[ "$port"x != 0x ] && logger -t "【ss_tproxy】" "启动成功" && ss_tproxy_restart o
[ "$port"x == 0x ] && logger -t "【ss_tproxy】" "启动失败, 注意检查端口是否有冲突,程序是否下载完整,10 秒后自动尝试重新启动" && sleep 10 && ss_tproxy_restart x
initopt
#ss_tproxy_get_status
eval "$scriptfilepath keep &"
exit 0
}

ipt_m_check () {
NUM=`iptables -m addrtype -h 2>&1 | grep 'type\ type' | wc -l`
if [ "$NUM" == "0" ] ; then
rm -f /tmp/webui_yes
logger -t "【ss_tproxy】" "【错误】！！！固件缺少 iptables -m addrtype 模块"
logger -t "【ss_tproxy】" "【错误】！！！需要升级固件才能使用 ss_tproxy 脚本"
rm -f /tmp/script/_opt_script_check
kill_ps "_opt_script_check"
kill_ps "Sh99_ss_tproxy.sh"
kill_ps "sh_ss_tproxy.sh"
kill_ps "Sh09_chinadns_ng.sh"
kill_ps "Sh10_clash.sh"
kill_ps "Sh15_ss.sh"
kill_ps "Sh18_v2ray.sh"
kill_ps "Sh39_ipt2socks.sh"
kill_ps "Sh58_tran_socks.sh"
logger -t "【ss_tproxy】" "现在自动更新固件"
rm -f /tmp/webui_yes
rm -f /tmp/script/_opt_script_check
mtd_storage.sh save
nvram set upscript_enable=0
ss_tproxy_enable=0
nvram set app_109=0
nvram commit
nvram save
#一键自动更新固件脚本
wget -q -O- https://opt.cn2qq.com/opt-script/up.sh > /tmp/up.sh && bash < /tmp/up.sh
sleep 5
/bin/mtd_write -r unlock mtd1 #reboot
sleep 5
exit
fi
}
initopt () {
optPath=`grep ' /opt ' /proc/mounts | grep tmpfs`
[ ! -z "$optPath" ] && return
if [ ! -z "$(echo $scriptfilepath | grep -v "/opt/etc/init")" ] && [ -s "/opt/etc/init.d/rc.func" ] ; then
	{ echo '#!/bin/bash' ; echo $scriptfilepath '"$@"' '&' ; } > /opt/etc/init.d/$scriptname && chmod 777  /opt/etc/init.d/$scriptname
fi

}

initconfig () {
	if [ ! -f "/etc/storage/app_26.sh" ] || [ ! -s "/etc/storage/app_26.sh" ] ; then
cat > "/etc/storage/app_26.sh" <<-\VVR
#!/bin/bash
pre_start() {
    echo "ss-tproxy 启动前执行脚本"
    
}
post_start() {
    echo "ss-tproxy 启动后执行脚本"
    
}
pre_stop() {
    echo "ss-tproxy 停止前执行脚本"
    
}
post_stop() {
    echo "ss-tproxy 停止后执行脚本"
    
}

VVR
	fi

	if [ ! -f "/etc/storage/app_27.sh" ] || [ ! -s "/etc/storage/app_27.sh" ] ; then
cat > "/etc/storage/app_27.sh" <<-\VVR
# ss-tproxy 配置文件
# https://github.com/zfl9/ss-tproxy
## mode
#mode='global'  # global 模式 (不分流)
#mode='chnlist' # 回国模式 (china走代理)
#mode='gfwlist' # gfwlist 模式 (黑名单)
mode='chnroute' # chnroute 模式 (白名单)

## ipv4/6
ipv4='true'     # true:启用ipv4透明代理; false:关闭ipv4透明代理
ipv6='false'    # true:启用ipv6透明代理; false:关闭ipv6透明代理

## tproxy
tproxy='false'  # true:TPROXY+TPROXY; false:REDIRECT+TPROXY

## tcponly
tcponly='false' # true:仅代理TCP流量; false:代理TCP和UDP流量

## selfonly
selfonly='false' # true:仅代理本机流量; false:代理本机及"内网"流量

## ss_tproxy 配置文件的配置参数覆盖 web 的配置参数
ext_dns_start_dnsproxy='' #app_112 0:自动开启第三方 DNS 程序(dnsproxy) ; 1:跳过自动开启第三方 DNS 程序但是继续把DNS绑定到 8053 端口的程序
ext_ss_dnsproxy_x=''      #DNS程序选择，0:dnsproxy ; 1:pdnsd ; 2:dnsmasq
ext_ss_pdnsd_all=''       # 0使用[本地DNS] + [GFW规则]查询DNS ; 1 使用 8053 端口查询全部 DNS
ext_ss_pdnsd_cn_all=''    #app_113 0:使用 8053 端口查询全部 DNS 时进行 China 域名加速 ; 1:不进行 China 域名加速
## iptables -t nat -I SSTP_OUTPUT -j RETURN
ext_output_return=''      #app_114 0:代理本机流量; 1:跳过代理本机流量
ext_output_udp_return=''  #ss_udp_enable 0:停用本机 UDP 转发; 1:启动本机 UDP 转发 (需服务器支持 UDP 代理才有效)
## iptables -t nat -I SSTP_OUTPUT -m owner --uid-owner 777 -j RETURN
uid_owner="0"    # 非 0 时进行用户ID匹配跳过代理本机流量
gid_owner="0"    # 非 0 时进行组ID匹配跳过代理本机流量

## proxy
proxy_all_svraddr="/opt/app/ss_tproxy/conf/proxy_all_svraddr.conf" # 服务器的地址或域名的配置文件，会自动处理分类IPv4、IPv6，允许填写多个服务器地址(文件里面每一行一个服务器地址)
proxy_svraddr4="/opt/app/ss_tproxy/conf/proxy_svraddr4.conf" # 服务器的 IPv4 地址或域名的配置文件，允许填写多个服务器地址(文件里面每一行一个服务器地址)
proxy_svraddr6="/opt/app/ss_tproxy/conf/proxy_svraddr6.conf" # 服务器的 IPv6 地址或域名的配置文件，允许填写多个服务器地址(文件里面每一行一个服务器地址)
proxy_svrport='1:65535'   # 服务器的监听端口，可填多个端口，格式同 ipts_proxy_dst_port
proxy_tcpport='1090'      # ss/ssr/v2ray 等本机进程的 TCP 监听端口，该端口支持透明代理
proxy_udpport='1090'      # ss/ssr/v2ray 等本机进程的 UDP 监听端口，该端口支持透明代理
proxy_startcmd='date'     # 用于启动本机代理进程的 shell 命令，该命令应该能立即执行完毕
proxy_stopcmd='date'      # 用于关闭本机代理进程的 shell 命令，该命令应该能立即执行完毕

## dns
dns_direct='223.5.5.5'             # 本地 IPv4 DNS，不能指定端口，也可以填组织、公司内部 DNS
dns_direct6='240C::6666'              # 本地 IPv6 DNS，不能指定端口，也可以填组织、公司内部 DNS
dns_remote='8.8.8.8#53'               # 远程 IPv4 DNS，必须指定端口，提示：访问远程 DNS 会走代理
dns_remote6='2001:4860:4860::8888#53' # 远程 IPv6 DNS，必须指定端口，提示：访问远程 DNS 会走代理
dns_bind_port='8053'                  # 本地 dnsproxy 服务器监听端口

## dnsmasq
dnsmasq_bind_port='53'                  # dnsmasq 服务器监听端口，见 README
dnsmasq_conf_dir="/tmp/ss_tproxy/dnsmasq.d"                          # `--conf-dir` 选项的参数，可以填多个，空格隔开
dnsmasq_conf_file="/opt/app/ss_tproxy/dnsmasq_conf_file.txt"           # `--conf-file` 选项的参数，可以填多个，空格隔开
dnsmasq_conf_string="/opt/app/ss_tproxy/conf/dnsmasq_conf_string.conf" # 自定义配置的配置文件(文件里面每一行一个配置)

## chinadns
chinadns_bind_port='65353'               # chinadns-ng 服务器监听端口，通常不用改动
chinadns_timeout='3'                     # 等待上游 DNS 返回响应的超时时间，单位为秒
chinadns_repeat='1'                      # 向可信 DNS 发送几次 DNS 查询请求，默认为 1
chinadns_fairmode='false'                # 使用公平模式，具体看 chinadns-ng 的 README
chinadns_gfwlist_mode='true'             # gfwlist 模式，加载 gfwlist.txt/gfwlist.ext
chinadns_noip_as_chnip='true'            # 启用 chinadns-ng 的 `--noip-as-chnip` 选项
chinadns_verbose='false'                 # 记录详细日志，除非进行调试，否则不建议启用
chinadns_logfile='/tmp/syslog.log'       # 日志文件，如果不想保存日志可以改为 /dev/null
chinadns_privaddr4="/opt/app/ss_tproxy/conf/chinadns_privaddr4.txt" # IPv4 私有地址段的配置文件(文件里面每一行一个IP)
chinadns_privaddr6="/opt/app/ss_tproxy/conf/chinadns_privaddr6.txt" # IPv6 私有地址段的配置文件(文件里面每一行一个IP)

## dns2tcp
dns2tcp_bind_port='65454'               # dns2tcp 转发服务器监听端口，如有冲突请修改
dns2tcp_verbose='false'                 # 记录详细日志，除非进行调试，否则不建议启用
dns2tcp_logfile='/tmp/syslog.log'  # 日志文件，如果不想保存日志可以改为 /dev/null

## ipts
lan_ipv4_ipaddr='127.0.0.1'
lan_ipv6_ipaddr='::1'
ipts_if_lo='lo'                 # 环回接口的名称，在标准发行版中，通常为 lo，如果不是请修改
ipts_rt_tab='233'               # iproute2 路由表名或表 ID，除非产生冲突，否则不建议改动该选项
ipts_rt_mark='0x2333'           # iproute2 策略路由的防火墙标记，除非产生冲突，否则不建议改动该选项
ipts_set_snat='false'           # 设置 iptables 的 MASQUERADE 规则，布尔值，`true/false`，详见 README
ipts_set_snat6='false'          # 设置 ip6tables 的 MASQUERADE 规则，布尔值，`true/false`，详见 README
ipts_reddns_onstop='false'      # ss-tproxy stop 后，是否将其它主机发至本机的 DNS 重定向至直连 DNS，详见 README
ipts_reddns_onstart='true'      # ss-tproxy start 后，是否将其它主机发至本机的 DNS 重定向至自定义 IPv4 地址
ipts_reddns_ip='192.168.123.1'      # 自定义 DNS 重定向地址(只支持 IPv4 )
ipts_proxy_dst_port_tcp='1:65535'   # tcp 黑名单 IP 的哪些端口走代理，多个用逗号隔开，冒号为端口范围(含边界)，详见 README
ipts_proxy_dst_port_udp='1:65535'   # udp 黑名单 IP 的哪些端口走代理，多个用逗号隔开，冒号为端口范围(含边界)，详见 README
# LAN_AC_IP 内网LAN代理转发白名单设置
# 0 常规, 未在 file_lanlist_ext 设定的 内网IP 根据 mode 配置工作模式 走代理
# 1 全局, 未在 file_lanlist_ext 设定的 内网IP 使用 全局代理模式 走代理
# 2 绕过, 未在 file_lanlist_ext 设定的 内网IP 不使用 代理
LAN_AC_IP='0' # 默认值 0

## opts
opts_ss_netstat='auto'                  # auto/ss/netstat，用哪个端口检测工具，见 README
opts_ping_cmd_to_use='auto'             # auto/standalone/parameter，ping 相关，见 README
opts_hostname_resolver='auto'           # auto/dig/getent/ping，用哪个解析工具，见 README
opts_overwrite_resolv='false'           # true/false，定义如何修改 resolv.conf，见 README
opts_ip_for_check_net='223.5.5.5'    # 检测外网是否可访问的 IP，ping，留空表示跳过此检查

## file
file_gfwlist_txt='/opt/app/ss_tproxy/rule/gfwlist.txt' # gfwlist/chnlist 模式预置文件
file_gfwlist_ext='/opt/app/ss_tproxy/gfwlist.ext'      # gfwlist/chnlist 模式扩展文件
file_ignlist_ext='/opt/app/ss_tproxy/ignlist.ext'      # global/chnroute 模式扩展文件
file_lanlist_ext='/etc/storage/shadowsocks_ss_spec_lan.sh'      # 内网(LAN)IP行为 模式扩展文件
file_wanlist_ext='/etc/storage/shadowsocks_ss_spec_wan.sh'      # 外网(WAN)IP行为 模式扩展文件
file_chnroute_txt='/opt/app/ss_tproxy/rule/chnroute.txt'   # chnroute 地址段文件(文件里面每一行一个IP)
file_chnroute6_txt='/opt/app/ss_tproxy/rule/chnroute6.txt' # chnroute 地址段文件(文件里面每一行一个IP)
file_chnroute_set='/opt/app/ss_tproxy/chnroute.set'    # chnroute 地址段文件 (iptables)
file_chnroute6_set='/opt/app/ss_tproxy/chnroute6.set'  # chnroute6 地址段文件 (ip6tables)
file_dnsserver_pid='/opt/app/ss_tproxy/.dnsserver.pid' # dns 服务器进程的 pid 文件 (shell)

## tmp
ss_tproxy_status="" # 记录参数状态变化，不需要改动该选项

VVR
	fi
source /etc/storage/app_27.sh
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
$chinadns_privaddr4
$chinadns_privaddr6
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

# 链接配置文件
rm -f /opt/app/ss_tproxy/wanlist.ext
rm -f /opt/app/ss_tproxy/lanlist.ext
ln -sf /etc/storage/shadowsocks_ss_spec_wan.sh /opt/app/ss_tproxy/wanlist.ext
ln -sf /etc/storage/shadowsocks_ss_spec_lan.sh /opt/app/ss_tproxy/lanlist.ext
[ ! -s /opt/app/ss_tproxy/wanlist.ext ] && cp -f /etc/storage/shadowsocks_ss_spec_wan.sh /opt/app/ss_tproxy/wanlist.ext
[ ! -s /opt/app/ss_tproxy/lanlist.ext ] && cp -f /etc/storage/shadowsocks_ss_spec_lan.sh /opt/app/ss_tproxy/lanlist.ext
}

initconfig

ss_tproxy_run () {
for h_i in $(seq 1 2) ; do
[ -z "$(grep "main " /etc/storage/script/sh_ss_tproxy.sh)" ] && rm -rf /etc/storage/script/sh_ss_tproxy.sh
wgetcurl_file /etc/storage/script/sh_ss_tproxy.sh "$hiboyscript/script/sh_ss_tproxy.sh" "$hiboyscript2/script/sh_ss_tproxy.sh"
done
sh_ss_tproxy.sh "$@"
}

update_app () {
mkdir -p /opt/app/ss_tproxy
if [ "$1" = "update_asp" ] ; then
	rm -rf /opt/app/ss_tproxy/Advanced_Extensions_ss_tproxy.asp
fi
if [ "$1" = "del" ] ; then
	nvram set ss_tproxy_auser=""
	rm -rf /opt/app/ss_tproxy/Advanced_Extensions_ss_tproxy.asp
	[ -f /etc/storage/script/sh_ss_tproxy.sh ] && rm -f /etc/storage/script/sh_ss_tproxy.sh
fi
for h_i in $(seq 1 2) ; do
[ -z "$(grep "main " /etc/storage/script/sh_ss_tproxy.sh)" ] && rm -rf /etc/storage/script/sh_ss_tproxy.sh
wgetcurl_file /etc/storage/script/sh_ss_tproxy.sh "$hiboyscript/script/sh_ss_tproxy.sh" "$hiboyscript2/script/sh_ss_tproxy.sh"
done
initconfig

# 加载程序配置页面
if [ ! -f "/opt/app/ss_tproxy/Advanced_Extensions_ss_tproxy.asp" ] || [ ! -s "/opt/app/ss_tproxy/Advanced_Extensions_ss_tproxy.asp" ] ; then
	wgetcurl.sh /opt/app/ss_tproxy/Advanced_Extensions_ss_tproxy.asp "$hiboyfile/Advanced_Extensions_ss_tproxyasp" "$hiboyfile2/Advanced_Extensions_ss_tproxyasp"
fi
umount /www/Advanced_Extensions_app21.asp
mount --bind /opt/app/ss_tproxy/Advanced_Extensions_ss_tproxy.asp /www/Advanced_Extensions_app21.asp
# 更新程序启动脚本

[ "$1" = "del" ] && /etc/storage/www_sh/ss_tproxy del &
}

case $ACTION in
start)
	ss_tproxy_close
	ss_tproxy_check
	;;
stop)
	ss_tproxy_close
	;;
check)
	ss_tproxy_check
	;;
s_*)
	sstp_run="$(echo "$ACTION" | awk -F '_' '{for(i=2;i<=NF;++i) { if(i==2){sum=$i}else{sum=sum"_"$i}}}END{print sum}')"
	ipt_m_check
	auser_check $2
	$sstp_run
	exit
	;;
x_*)
	sstp_run="$(echo "$ACTION" | awk -F '_' '{for(i=2;i<=NF;++i) { if(i==2){sum=$i}else{sum=sum"_"$i}}}END{print sum}')"
	ipt_m_check
	auser_check $2
	ss_tproxy_run $sstp_run
	exit
	;;
on_start)
	ipt_m_check
	auser_check $2
	ss_tproxy_enable=1
	nvram set app_109=1
	nvram set ss_tproxy_status=""
	ss_tproxy_check
	exit
	;;
off_stop)
	auser_check $2 "stop"
	ss_tproxy_enable=0
	nvram set app_109=0
	nvram set ss_tproxy_status=""
	nvram set ss_tproxy_auser=""
	auser_a=""
	ss_tproxy_check
	exit
	;;
auser_check)
	auser_check $2
	;;
updateapp21)
	ss_tproxy_restart o
	[ "$ss_tproxy_enable" = "1" ] && nvram set ss_tproxy_status="updatess_tproxy" && logger -t "【ss_tproxy】" "重启" && ss_tproxy_restart
	[ "$ss_tproxy_enable" != "1" ] && nvram set ss_tproxy_v="" && logger -t "【ss_tproxy】" "更新" && update_app del
	;;
update_app)
	update_app
	;;
update_asp)
	update_app update_asp
	;;
keep)
	#ss_tproxy_check
	ss_tproxy_keep
	;;
initconfig)
	initconfig
	;;
*)
	ss_tproxy_check
	;;
esac

