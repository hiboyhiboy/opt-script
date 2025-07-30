#!/bin/bash
#copyright by hiboy
source /etc/storage/script/init.sh
TAG="AD_BYBY"		  # iptables tag
koolproxy_enable=`nvram get koolproxy_enable`
[ -z $koolproxy_enable ] && koolproxy_enable=0 && nvram set koolproxy_enable=0
if [ "$koolproxy_enable" != "0" ] ; then
adbyby_mode_x=`nvram get adbyby_mode_x`
[ -z $adbyby_mode_x ] && adbyby_mode_x=0 && nvram set adbyby_mode_x=0
koolproxy_auto=`nvram get koolproxy_auto`
koolproxy_video=`nvram get koolproxy_video`
lan_ipaddr=`nvram get lan_ipaddr`
koolproxy_https=`nvram get koolproxy_https`
adm_hookport=`nvram get adm_hookport`
koolproxy_adblock=`nvram get koolproxy_adblock`
adbyby_CPUAverages=`nvram get adbyby_CPUAverages`
ss_DNS_Redirect=`nvram get ss_DNS_Redirect`
ss_DNS_Redirect_IP=`nvram get ss_DNS_Redirect_IP`
adbyby_enable=`nvram get adbyby_enable`
adm_enable=`nvram get adm_enable`
ss_enable=`nvram get ss_enable`
ss_mode_x=`nvram get ss_mode_x`
adbyby_adblocks=`nvram get adbyby_adblocks`
koolproxy_uprules=`nvram get koolproxy_uprules`

koolproxyfile="https://gcore.jsdelivr.net/gh/houzi-/CDN/binary/v3.8.5/mipsel"
koolproxyfilecdn="https://gcore.jsdelivr.net/gh/houzi-/CDN/binary/v3.8.5/mipsel"
koolproxyfile2="$hiboyfile/koolproxy"
koolproxyfile22="$hiboyfile2/koolproxy"
koolproxyfile3="$hiboyfile/7620koolproxy.tgz"
koolproxyfile33="$hiboyfile2/7620koolproxy.tgz"
koolproxy_rules_list="/etc/storage/koolproxy_rules_list.sh"
[ -z "$(cat $koolproxy_rules_list | grep '1|user.txt||')" ] && rm -f $koolproxy_rules_list
FWI="/tmp/firewall.adbyby.pdcn" # firewall include file
AD_LAN_AC_IP=`nvram get AD_LAN_AC_IP`
[ -z $AD_LAN_AC_IP ] && AD_LAN_AC_IP=0 && nvram set AD_LAN_AC_IP=$AD_LAN_AC_IP
lan_ipaddr=`nvram get lan_ipaddr`
[ -z "$ss_DNS_Redirect_IP" ] && ss_DNS_Redirect_IP=$lan_ipaddr && nvram set ss_DNS_Redirect_IP=$ss_DNS_Redirect_IP
[ -z $adbyby_adblocks ] && adbyby_adblocks=0 && nvram set adbyby_adblocks=$adbyby_adblocks
#[ "$koolproxy_video" = "1" ] && mode_video=" -e " || mode_video=""

if [ "$ss_enable" = "1" ] ; then
	if [ ! -z "$(cat /etc/storage/shadowsocks_ss_spec_lan.sh | grep -v '^#' | sort -u | grep -v '^$' | sed s/！/!/g)" ] ; then
		mode_video="$mode_video --mark "
	fi
fi
# MemT=`cat /proc/meminfo | grep MemTotal | awk -F ' ' '{print $2;}'`
# SwapT=`cat /proc/meminfo | grep SwapTotal | awk -F ' ' '{print $2;}'`
# if [ $MemT -lt 81920 ] ; then
# [ "$SwapT" != "0" ] && mode_video="$mode_video -d "
# else
# mode_video="$mode_video -d "
# fi
# echo "$mode_video"
koolproxy_renum=`nvram get koolproxy_renum`
koolproxy_renum=${koolproxy_renum:-"0"}
cmd_log_enable=`nvram get cmd_log_enable`
cmd_name="koolproxy"
cmd_log=""
if [ "$cmd_log_enable" = "1" ] || [ "$koolproxy_renum" -gt "0" ] ; then
	cmd_log="$cmd_log2"
fi
fi
#检查 dnsmasq 目录参数
#confdir=`grep "/tmp/ss/dnsmasq.d" /etc/storage/dnsmasq/dnsmasq.conf | sed 's/.*\=//g'`
#if [ -z "$confdir" ] ; then 
	confdir="/tmp/ss/dnsmasq.d"
#fi
confdir_x="$(echo -e $confdir | sed -e "s/\//"'\\'"\//g")"
[ ! -d "$confdir" ] && mkdir -p $confdir
gfwlist="/r.gfwlist.conf"
gfw_black_list="gfwlist"

if [ ! -z "$(echo $scriptfilepath | grep -v "/tmp/script/" | grep kool_proxy)" ] && [ ! -s /tmp/script/_kool_proxy ] ; then
	mkdir -p /tmp/script
	{ echo '#!/bin/bash' ; echo $scriptfilepath '"$@"' '&' ; } > /tmp/script/_kool_proxy
	chmod 777 /tmp/script/_kool_proxy
fi

koolproxy_mount () {

ss_opt_x=`nvram get ss_opt_x`
upanPath=""
[ "$ss_opt_x" = "3" ] && upanPath="`df -m | grep /dev/mmcb | grep -E "$(echo $(/usr/bin/find /dev/ -name 'mmcb*') | sed -e 's@/dev/ /dev/@/dev/@g' | sed -e 's@ @|@g')" | grep "/media" | awk '{print $NF}' | sort -u | awk 'NR==1' `"
[ "$ss_opt_x" = "4" ] && upanPath="`df -m | grep /dev/sd | grep -E "$(echo $(/usr/bin/find /dev/ -name 'sd*') | sed -e 's@/dev/ /dev/@/dev/@g' | sed -e 's@ @|@g')" | grep "/media" | awk '{print $NF}' | sort -u | awk 'NR==1' `"
[ -z "$upanPath" ] && [ "$ss_opt_x" = "1" ] && upanPath="`df -m | grep /dev/mmcb | grep -E "$(echo $(/usr/bin/find /dev/ -name 'mmcb*') | sed -e 's@/dev/ /dev/@/dev/@g' | sed -e 's@ @|@g')" | grep "/media" | awk '{print $NF}' | sort -u | awk 'NR==1' `"
[ -z "$upanPath" ] && [ "$ss_opt_x" = "1" ] && upanPath="`df -m | grep /dev/sd | grep -E "$(echo $(/usr/bin/find /dev/ -name 'sd*') | sed -e 's@/dev/ /dev/@/dev/@g' | sed -e 's@ @|@g')" | grep "/media" | awk '{print $NF}' | sort -u | awk 'NR==1' `"
if [ "$ss_opt_x" = "5" ] ; then
	# 指定目录
	opt_cifs_dir=`nvram get opt_cifs_dir`
	if [ -d $opt_cifs_dir ] ; then
		upanPath="$opt_cifs_dir"
	else
		logger -t "【opt】" "错误！未找到指定目录 $opt_cifs_dir"
	fi
fi
if [ "$ss_opt_x" = "6" ] ; then
	opt_cifs_2_dir=`nvram get opt_cifs_2_dir`
	# 远程共享
	if mountpoint -q "$opt_cifs_2_dir" && [ -d "$opt_cifs_2_dir" ] ; then
		upanPath="$opt_cifs_2_dir"
	else
		logger -t "【opt】" "错误！未找到指定远程共享目录 $opt_cifs_2_dir"
	fi
fi
echo "$upanPath"
if [ ! -z "$upanPath" ] ; then 
	logger -t "【koolproxy】" "已挂载储存设备, 主程序放外置设备存储"
	initopt
	mkdir -p $upanPath/ad/7620koolproxy
	rm -f /tmp/7620koolproxy
	ln -sf "$upanPath/ad/7620koolproxy" /tmp/7620koolproxy
	if [ -s "$(ls /etc_ro/7620koolproxy_*.tgz  | sed -n '1p')" ] && [ ! -s "$upanPath/ad/7620koolproxy/koolproxy" ] ; then
		logger -t "【koolproxy】" "使用内置主程序"
		untar.sh "$(ls /etc_ro/7620koolproxy_*.tgz  | sed -n '1p')" $upanPath/ad $upanPath/ad/7620koolproxy/data/version
	fi
	if [ ! -s "$upanPath/ad/7620koolproxy/data/version" ] ; then
		logger -t "【koolproxy】" "开始下载 7620koolproxy.tgz"
		wgetcurl.sh $upanPath/ad/7620koolproxy.tgz $koolproxyfile3 $koolproxyfile33
		untar.sh $upanPath/ad/7620koolproxy.tgz $upanPath/ad $upanPath/ad/7620koolproxy/data/version
	fi
else
	logger -t "【koolproxy】" "未挂载储存设备, 主程序放路由内存存储"
	mkdir -p /tmp/7620koolproxy
	if [ -s "$(ls /etc_ro/7620koolproxy_*.tgz  | sed -n '1p')" ] && [ ! -s "/tmp/7620koolproxy/koolproxy" ] ; then
		logger -t "【koolproxy】" "使用内置主程序"
		untar.sh "$(ls /etc_ro/7620koolproxy_*.tgz  | sed -n '1p')" /tmp /tmp/7620koolproxy/data/version
	fi
	if [ ! -s "/tmp/7620koolproxy/data/version" ] ; then
		logger -t "【koolproxy】" "开始下载 7620koolproxy.tgz"
		wgetcurl.sh /tmp/7620koolproxy.tgz $koolproxyfile3 $koolproxyfile33
		untar.sh /tmp/7620koolproxy.tgz /tmp /tmp/7620koolproxy/data/version
	fi
fi
export PATH='/tmp/7620koolproxy:/etc/storage/bin:/tmp/script:/etc/storage/script:/opt/usr/sbin:/opt/usr/bin:/opt/sbin:/opt/bin:/usr/local/sbin:/usr/sbin:/usr/bin:/sbin:/bin'
chmod 777 /tmp/7620koolproxy/koolproxy
mkdir -p /tmp/7620koolproxy/data/
[[ "$(/tmp/7620koolproxy/koolproxy -h | wc -l)" -lt 2 ]] && rm -rf /tmp/7620koolproxy/koolproxy
}

koolproxy_restart () {
i_app_restart "$@" -name="koolproxy"
}

koolproxy_get_status () {

B_restart="$koolproxy_enable$koolproxy_auto$koolproxy_video$koolproxyfile$koolproxyfile2$koolproxyfile3$lan_ipaddr$koolproxy_https$adbyby_mode_x$adm_hookport$koolproxy_adblock$adbyby_CPUAverages$ss_DNS_Redirect$ss_DNS_Redirect_IP$(cat /etc/storage/ad_config_script.sh | grep -v '^$' | grep -v '^#')$(cat /etc/storage/koolproxy_rules_script.sh /etc/storage/koolproxy_rules_list.sh | grep -v '^$' | grep -v "^!")"

i_app_get_status -name="koolproxy" -valb="$B_restart"
}

koolproxy_check () {

koolproxy_get_status
[ "$(nvram get app_86)" == "re_ca_key" ] && re_ca_key
if [ "$koolproxy_enable" != "1" ] && [ "$needed_restart" = "1" ] ; then
	[ ! -z "`pidof koolproxy`" ] && logger -t "【koolproxy】" "停止 koolproxy" && koolproxy_close
	{ kill_ps "$scriptname" exit0; exit 0; }
fi
if [ "$koolproxy_enable" = "1" ] ; then
	if [ "$needed_restart" = "1" ] ; then
		koolproxy_close
		koolproxy_start
	else
		[ -z "`pidof koolproxy`" ] || [ ! -s "/tmp/7620koolproxy/koolproxy" ] && koolproxy_restart
		PIDS=$(ps -w | grep "/tmp/7620koolproxy/koolproxy" | grep -v "grep" | wc -l)
		if [ "$PIDS" != 0 ] ; then
			port=$(iptables -t nat -L | grep 'ports 3000' | wc -l)
			if [ "$port" = 0 ] ; then
				logger -t "【koolproxy】" "检查:找不到3000转发规则, 重新添加"
				koolproxy_add_rules
			fi
		fi
	fi
fi
}

koolproxy_keep () {

if [ -s /tmp/7620koolproxy/data/rules/koolproxy.txt ] ; then
nvram set koolproxy_rules_date_local="`sed -n '1,10p' /tmp/7620koolproxy/data/rules/koolproxy.txt | grep "$(sed -n '1,10p' /tmp/7620koolproxy/data/rules/koolproxy.txt | grep -Eo '[0-9]+-[0-9]+-[0-9]+ [0-9]+:[0-9]+|201?.{1}' | sed -n '1p')" | sed 's/[x!]//g' | sed -r 's/-{2,}//g' | sed -r 's/\ {2}//g' | sed -r 's/\ {2}//g' | sed -n '1p'`"
nvram set koolproxy_rules_nu_local="`cat /tmp/7620koolproxy/data/rules/koolproxy.txt | grep -v ! | wc -l`"
nvram set koolproxy_video_date_local="`sed -n '1,10p' /tmp/7620koolproxy/data/rules/koolproxy.txt | grep "$(sed -n '1,10p' /tmp/7620koolproxy/data/rules/koolproxy.txt | grep -Eo '[0-9]+-[0-9]+-[0-9]+ [0-9]+:[0-9]+|201?.{1}' | sed -n '2p')" | sed 's/[x!]//g' | sed -r 's/-{2,}//g' | sed -r 's/\ {2}//g' | sed -r 's/\ {2}//g' | sed -n '1p'`"
nvram set koolproxy_h="`/tmp/7620koolproxy/koolproxy -h | awk 'NR==1{print}'`】【`sed -n '1,10p' /tmp/7620koolproxy/data/rules/daily.txt | grep "$(sed -n '1,10p' /tmp/7620koolproxy/data/rules/daily.txt | grep -Eo '[0-9]+-[0-9]+-[0-9]+ [0-9]+:[0-9]+|201?.{1}' | sed -n '1p')" | sed 's/[x!]//g' | sed -r 's/-{2,}//g' | sed -r 's/\ {2}//g' | sed -r 's/\ {2}//g' | sed -n '1p'`"
fi
rm -f /tmp/cron_adb.lock
/etc/storage/script/sh_ezscript.sh 3 & #更新按钮状态
i_app_keep -name="koolproxy" -pidof="koolproxy" &
while true; do
if [ ! -f /tmp/cron_adb.lock ] ; then
	if [ ! -f /tmp/cron_adb.lock ] ; then
		port=$(iptables -t nat -L | grep 'ports 3000' | wc -l)
			if [ "$port" -gt 1 ] && [ ! -f /tmp/cron_adb.lock ] ; then
				logger -t "【koolproxy】" "有多个3000转发规则, 删除多余"
				koolproxy_flush_rules
			fi
		port=$(iptables -t nat -L | grep 'ports 3000' | wc -l)
			if [ "$port" = 0 ] && [ ! -f /tmp/cron_adb.lock ] ; then
				logger -t "【koolproxy】" "找不到3000转发规则, 重新添加"
				koolproxy_add_rules
			fi
		port=$(iptables -t nat -L | grep 'AD_BYBY_to' | wc -l)
			if [ "$port" = 0 ] && [ ! -f /tmp/cron_adb.lock ] ; then
				logger -t "【koolproxy】" "找不到AD_BYBY_to转发规则, 重新添加"
				koolproxy_add_rules
			fi
	fi
	sleep 213
fi
sleep 23
koolproxy_keepcpu
done
}

koolproxy_keepcpu () {
if [ "$adbyby_CPUAverages" = "1" ] && [ ! -f /tmp/cron_adb.lock ] ; then
	processor=`cat /proc/cpuinfo| grep "processor"| wc -l`
	[ "$processor" = "1" ] && processor=`expr $processor \* 2`
	CPULoad=`uptime |sed -e 's/\ *//g' -e 's/.*://g' | awk -F ',' '{print $2;}' | sed -e 's/\..*//g'`
	if [ $((CPULoad)) -ge "$processor" ] ; then
		logger -t "【koolproxy】" "CPU 负载拥堵, 关闭 koolproxy"
		koolproxy_flush_rules
		/etc/storage/script/sh_ezscript.sh 3 & #更新按钮状态
		killall koolproxy
		touch /tmp/cron_adb.lock
		while [[ "$CPULoad" -gt "$processor" ]] 
		do
			sleep 62
			CPULoad=`uptime |sed -e 's/\ *//g' -e 's/.*://g' | awk -F ',' '{print $2;}' | sed -e 's/\..*//g'`
		done
		logger -t "【koolproxy】" "CPU 负载正常"
		rm -f /tmp/cron_adb.lock
	fi
fi
}

koolproxy_close () {

kill_ps "$scriptname keep"
cru.sh d adbyby_update &
cru.sh d adm_update &
cru.sh d koolproxy_update &
port=$(iptables -t nat -L | grep 'ports 3000' | wc -l)
[ "$port" != 0 ] && koolproxy_flush_rules
[ "$adbyby_enable" != "1" ] && killall adbyby sh_ad_byby_keey_k.sh
[ "$adm_enable" != "1" ] && killall adm sh_ad_m_keey_k.sh
killall koolproxy
/etc/storage/script/sh_ezscript.sh 3 & #更新按钮状态
rm -f /tmp/adbyby_host.conf
rm -f /tmp/7620koolproxy.tgz /tmp/cron_adb.lock /tmp/cp_rules.lock
kill_ps "/tmp/script/_kool_proxy"
kill_ps "_kool_proxy.sh"
kill_ps "$scriptname"
}

koolproxy_start () {
check_webui_yes
nvram set button_script_1_s="KP"
/etc/storage/script/sh_ezscript.sh 3 & #更新按钮状态
if [ -z "`pidof koolproxy`" ] && [ "$koolproxy_enable" = "1" ] && [ ! -f /tmp/cron_adb.lock ] ; then
	touch /tmp/cron_adb.lock
	for module in ip_set ip_set_bitmap_ip ip_set_bitmap_ipmac ip_set_bitmap_port ip_set_hash_ip ip_set_hash_ipport ip_set_hash_ipportip ip_set_hash_ipportnet ip_set_hash_net ip_set_hash_netport ip_set_list_set xt_set xt_TPROXY
	do
		modprobe $module
	done 
	koolproxy_mount
	if [ ! -s "/tmp/7620koolproxy/koolproxy" ] ; then
		logger -t "【koolproxy】" "开始下载 koolproxy"
		wgetcurl.sh /tmp/7620koolproxy/koolproxy $koolproxyfile2 $koolproxyfile22
	fi
	if [ ! -s "/tmp/7620koolproxy/koolproxy" ] ; then
		logger -t "【koolproxy】" "开始下载 koolproxy"
		wgetcurl.sh /tmp/7620koolproxy/koolproxy $koolproxyfile $koolproxyfilecdn N
	fi
	if [ ! -s "/tmp/7620koolproxy/koolproxy" ] ; then
		logger -t "【koolproxy】" "下载失败, 注意检查端口是否有冲突,程序是否下载完整,10 秒后自动尝试重新启动" && sleep 10 && koolproxy_restart x
	fi
	# 恢复上次保存的证书
	mkdir -p /etc/storage/koolproxy /tmp/7620koolproxy/data/certs /tmp/7620koolproxy/data/private
	[ -f /etc/storage/koolproxy/base.key.pem ] && cp -f /etc/storage/koolproxy/base.key.pem /tmp/7620koolproxy/data/private/base.key.pem
	[ -f /etc/storage/koolproxy/ca.key.pem ] && cp -f /etc/storage/koolproxy/ca.key.pem /tmp/7620koolproxy/data/private/ca.key.pem
	[ -f /etc/storage/koolproxy/ca.crt ] && cp -f /etc/storage/koolproxy/ca.crt /tmp/7620koolproxy/data/certs/ca.crt
	cd /tmp/7620koolproxy/data/
	if [ ! -f /tmp/7620koolproxy/data/private/ca.key.pem ] ; then
		logger -t "【koolproxy】" "检测到首次运行https，开始生成koolproxy证书，用于https过滤！"
		chmod 777 /tmp/7620koolproxy/data/gen_ca.sh && sh gen_ca.sh
		# 保存证书
		[ -f /tmp/7620koolproxy/data/certs/ca.crt ] && cp -f /tmp/7620koolproxy/data/certs/ca.crt /etc/storage/koolproxy/ca.crt
		[ -f /tmp/7620koolproxy/data/private/base.key.pem ] && cp -f /tmp/7620koolproxy/data/private/base.key.pem /etc/storage/koolproxy/base.key.pem
		[ -f /tmp/7620koolproxy/data/private/ca.key.pem ] && cp -f /tmp/7620koolproxy/data/private/ca.key.pem /etc/storage/koolproxy/ca.key.pem && mtd_storage.sh save &
	fi
	touch index.txt
	echo 1000 > serial
	mkdir -p /tmp/7620koolproxy/data/rules
	logger -t "【koolproxy】" "koolproxy证书位于/etc/storage/koolproxy/"
#3.8.2
#规则的加载不再由程序内定，现在由source.list(data/source.list)文件制定规则的加载和开启与否，source.list也能写入第三方规则，第三方规则将由koolproxy主程序负责下载。
#因为以上变更，去掉-e功能（仅加载kp.dat），现在要实现仅加载kp.dat，只需要修改source.list中对应规则的开关。
	if [ ! -f "$koolproxy_rules_list" ] || [ ! -s "$koolproxy_rules_list" ] ; then
		logger -t "【koolproxy】" "重置data/source.list"
		initconfig
	fi
	if [ ! -z "$(grep '1|koolproxy.txt|https://kprule.com/koolproxy.txt|' $koolproxy_rules_list)" ] ; then
		logger -t "【koolproxy】" "kp规则停止更新！停用kprule.com规则！"
		sed -e 's@1|koolproxy.txt|https://kprule.com/koolproxy.txt|@0|koolproxy.txt|https://kprule.com/koolproxy.txt|@' -e 's@1|daily.txt|https://kprule.com/daily.txt|@0|daily.txt|https://kprule.com/daily.txt|@' -e 's@1|kp.dat|https://kprule.com/kp.dat|@0|kp.dat|https://kprule.com/kp.dat|@' -i $koolproxy_rules_list
	fi
	source_list="/tmp/7620koolproxy/data/source.list"
	cat $koolproxy_rules_list | grep -v '#' | grep -v '^$' > $source_list
	if [ "$koolproxy_video" = "1" ] ; then
		logger -t "【koolproxy】" "仅加载视频规则"
		sed -Ei "s@^1\|koolproxy.txt@0\|koolproxy.txt@" $source_list
		sed -Ei "s@^1\|daily.txt@0\|daily.txt@" $source_list
#	else
#		sed -Ei "s@^0\|koolproxy.txt@1\|koolproxy.txt@"  $source_list
#		sed -Ei "s@^0\|daily.txt@1\|daily.txt@"  $source_list
	fi

	# 处理第三方自定义规则 /tmp/rule_DOMAIN.txt
	source /etc/storage/ad_config_script.sh
	adbyby_adblocks=`nvram get adbyby_adblocks`
	if [ "$adbyby_adblocks" = "1" ] ; then
		logger -t "【koolproxy】" "下载 第三方自定义 规则"
		rm -f /tmp/7620koolproxy/user3adblocks.txt
		while read line
		do
		c_line=`echo $line |grep -v "#"`
		if [ ! -z "$c_line" ] ; then
			logger -t "【koolproxy】" "第三方规则:$line"
			wgetcurl.sh /tmp/7620koolproxy/user2.txt $line $line N
			cat /tmp/7620koolproxy/user2.txt | grep -v '^!' | grep -E '^(@@\||\||[[:alnum:]])' | sort -u | grep -v '^$' >> /tmp/7620koolproxy/user3adblocks.txt
			rm -f /tmp/7620koolproxy/user2.txt
		fi
		done < /tmp/rule_DOMAIN.txt
	fi

	# 合并规则
	cat /etc/storage/koolproxy_rules_script.sh | grep -v '^!' | grep -v '^$' > /tmp/7620koolproxy/user.txt
	cat /tmp/7620koolproxy/user3adblocks.txt | grep -v '^!' | grep -v '^$' >> /tmp/7620koolproxy/user.txt
	rm -f /tmp/7620koolproxy/user3adblocks.txt
	ln -sf /tmp/7620koolproxy/user.txt /tmp/7620koolproxy/data/user.txt
	ln -sf /tmp/7620koolproxy/user.txt /tmp/7620koolproxy/data/rules/user.txt
	cd /tmp/7620koolproxy/

	# 更新规则
	#hash daydayup 2>/dev/null && update_kp_rules_daydayup
	#hash daydayup 2>/dev/null || update_kp_rules
	logger -t "【koolproxy】" "启动 koolproxy 程序"
	chmod 777 /tmp/7620koolproxy/koolproxy
	export PATH='/tmp/7620koolproxy:/etc/storage/bin:/tmp/script:/etc/storage/script:/opt/usr/sbin:/opt/usr/bin:/opt/sbin:/opt/bin:/usr/local/sbin:/usr/sbin:/usr/bin:/sbin:/bin'
	export LD_LIBRARY_PATH=/tmp/7620koolproxy/lib:/lib:/opt/lib
	nvram set koolproxy_h="`/tmp/7620koolproxy/koolproxy -h | awk 'NR==1{print}'`"
	cd /tmp/7620koolproxy/
	/tmp/7620koolproxy/koolproxy $mode_video -d # >/dev/null 2>&1 &
	rm -f /tmp/adbyby_host.conf
	sleep 10
	[ -z "`pidof koolproxy`" ] && sleep 4
	i_app_keep -t -name="koolproxy" -pidof="koolproxy"
	[ ! -z "`pidof koolproxy`" ] && logger -t "【koolproxy】" "等待规则下载，请等待20秒！" && sleep 10
	[ ! -z "`pidof koolproxy`" ] && logger -t "【koolproxy】" "等待规则下载，请等待10秒！" && sleep 10
fi
if [ -s /tmp/7620koolproxy/data/rules/koolproxy.txt ] ; then
nvram set koolproxy_rules_date_local="`sed -n '1,10p' /tmp/7620koolproxy/data/rules/koolproxy.txt | grep "$(sed -n '1,10p' /tmp/7620koolproxy/data/rules/koolproxy.txt | grep -Eo '[0-9]+-[0-9]+-[0-9]+ [0-9]+:[0-9]+|201?.{1}' | sed -n '1p')" | sed 's/[x!]//g' | sed -r 's/-{2,}//g' | sed -r 's/\ {2}//g' | sed -r 's/\ {2}//g' | sed -n '1p'`"
nvram set koolproxy_rules_nu_local="`cat /tmp/7620koolproxy/data/rules/koolproxy.txt | grep -v ! | wc -l`"
nvram set koolproxy_video_date_local="`sed -n '1,10p' /tmp/7620koolproxy/data/rules/koolproxy.txt | grep "$(sed -n '1,10p' /tmp/7620koolproxy/data/rules/koolproxy.txt | grep -Eo '[0-9]+-[0-9]+-[0-9]+ [0-9]+:[0-9]+|201?.{1}' | sed -n '2p')" | sed 's/[x!]//g' | sed -r 's/-{2,}//g' | sed -r 's/\ {2}//g' | sed -r 's/\ {2}//g' | sed -n '1p'`"
fi
#koolproxy_add_rules
rm -f /tmp/7620koolproxy.tgz /tmp/cron_adb.lock
/etc/storage/script/sh_ezscript.sh 3 & #更新按钮状态
logger -t "【koolproxy】" "守护进程启动"
#koolproxy_get_status
koolproxy_cp_rules
eval "$scriptfilepath keep &"
exit 0
}

flush_r () {
iptables -t nat -D PREROUTING -p tcp --dport 80 -j REDIRECT --to-ports 3000 > /dev/null
iptables-save -c | sed  "s/webstr--url/webstr --url/g" | grep -v "$TAG" | iptables-restore -c
for setname in $(ipset -n list | grep -i "ad_spec"); do
	ipset destroy $setname 2>/dev/null
done
[ -n "$FWI" ] && echo '#!/bin/bash' >$FWI
}

koolproxy_cp_rules() {
[ ! -f /tmp/adbyby_host.conf ] && [ -f /tmp/7620koolproxy/data/koolproxy_ipset.conf ] && cp -f /tmp/7620koolproxy/data/koolproxy_ipset.conf /tmp/adbyby_host.conf
# ipset=/opt.cn2qq.com/adbybylist
# ipset=/opt.cn2qq.com/adbybylist
# 首先生成匹配的配置文件
# 再把 adbybylist 加入 ipset 配置，这部分域名交由 sh_ss_tproxy.sh 处理。
if [ "$adbyby_mode_x" == 1 ] && [ -s /tmp/adbyby_host.conf ] ; then
logger -t "【iptables】" "添加 ipset 转发规则"
logger -t "【iptables】" "admlist 规则处理开始"
sed -e '/^\#\|server=/d' -e "s/ipset=\/www\./ipset=\//" -e "s/ipset=\/bbs\./ipset=\//" -e "s/ipset=\/\./ipset=\//" -e "s/ipset=\///" -i /tmp/adbyby_host.conf
sed -Ei "s/\/.+//"  /tmp/adbyby_host.conf
cat /tmp/adbyby_host.conf | sort -u | sed 's/^[[:space:]]*//g; /^$/d; /#/d' | awk '{printf("ipset=/%s/adbybylist\n", $1)}' > /tmp/adbyby_host.conf
adbyby_whitehost=`nvram get adbyby_whitehost`
[ ! -z $whitehost ] && sed -Ei "/$(echo $whitehost | tr , \|)/d" /tmp/adbyby_host.conf
sh_ss_tproxy.sh adbyby_cflist_ipset
sed -Ei "/\/opt\/app\/ss_tproxy\/dnsmasq.d\/r.gfwlist.conf/d" /etc/storage/dnsmasq/dnsmasq.conf
[ -s /tmp/ss_tproxy/dnsmasq.d/r.gfwlist.conf ] && [ -z "$(cat /etc/storage/dnsmasq/dnsmasq.conf | grep "/tmp/ss_tproxy/dnsmasq.d")" ] && echo "conf-file=/opt/app/ss_tproxy/dnsmasq.d/r.gfwlist.conf" >> "/etc/storage/dnsmasq/dnsmasq.conf"
ipset flush adbybylist
ipset add adbybylist 110.110.110.110
restart_on_dhcpd

logger -t "【iptables】" "admlist 规则处理完毕"

fi
}

koolproxy_flush_rules () {
logger -t "【iptables】" "删除3000转发规则"
flush_r
ipset -F adbybylist &> /dev/null
#ipset destroy adbybylist &> /dev/null
sed -Ei "/\/opt\/app\/ss_tproxy\/dnsmasq.d\/r.gfwlist.conf/d" /etc/storage/dnsmasq/dnsmasq.conf
restart_on_dhcpd
logger -t "【iptables】" "完成删除3000规则"
}

koolproxy_add_rules() {
logger -t "【iptables】" "添加3000转发规则"
flush_r
ipset -! restore <<-EOF || return 1
create ad_spec_src_ac hash:ip hashsize 64
create ad_spec_src_bp hash:ip hashsize 64
create ad_spec_src_fw hash:ip hashsize 64
create ad_spec_src_https hash:ip hashsize 64
create ad_spec_dst_sp hash:net hashsize 64
$(gen_special_purpose_ip | sed -e "s/^/add ad_spec_dst_sp /")
EOF
ipset -! -N adbybylist hash:net hashsize 1024 family inet
lan_ipaddr=`nvram get lan_ipaddr`
ipset add ad_spec_src_bp $lan_ipaddr
ipset add ad_spec_src_bp 127.0.0.1
ipset add adbybylist 110.110.110.110
source /etc/storage/ad_config_script.sh
# 内网(LAN)访问控制
logger -t "【koolproxy】" "设置内网(LAN)访问控制"
if [ -n "$AD_LAN_AC_IP" ] ; then
	case "${AD_LAN_AC_IP:0:1}" in
		0)
			LAN_TARGET="AD_BYBY_WAN_AC"
			DNS_LAN_TARGET="AD_BYBY_DNS_WAN_AC"
			;;
		1)
			LAN_TARGET="AD_BYBY_to"
			DNS_LAN_TARGET="AD_BYBY_DNS_WAN_FW"
			;;
		2)
			LAN_TARGET="RETURN"
			DNS_LAN_TARGET="RETURN"
			;;
	esac
fi
cat /tmp/ad_spec_lan_DOMAIN.txt | grep -v '^#' | sort -u | grep -v '^$' | sed s/！/!/g > /tmp/ad_spec_lan.txt
while read line
do
for host in $line; do
	case "${host:0:1}" in
		n|N)
			ipset add ad_spec_src_ac ${host:2}
			;;
		b|B)
			ipset add ad_spec_src_bp ${host:2}
			;;
		g|G)
			ipset add ad_spec_src_fw ${host:2}
			;;
		s|S)
			ipset add ad_spec_src_https ${host:2}
			;;
	esac
done
done < /tmp/ad_spec_lan.txt
	[ "$adbyby_mode_x" == 0 ] && WAN_TARGET="AD_BYBY_to"
	[ "$adbyby_mode_x" == 0 ] && ADBYBYLIST_TARGET="AD_BYBY_to"
	[ "$adbyby_mode_x" == 1 ] && WAN_TARGET="RETURN"
	[ "$adbyby_mode_x" == 1 ] && ADBYBYLIST_TARGET="AD_BYBY_to"
	include_ac_rules nat
	include_ac_rules2 nat
	wifidognx=""
		wifidogn=`iptables -t nat -L PREROUTING --line-number | grep SS_SPEC_V2RAY_LAN_DG | awk '{print $1}' | awk 'END{print $1}'`  ## SS_SPEC
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
	echo "AD_BYBY-number:$wifidognx"
	logger -t "【iptables】" "AD_BYBY-number:$wifidogn"
	if [ -f /tmp/7620koolproxy/koolproxy_hookport.txt ] && [ "$adm_hookport" == 1 ] ; then
		hookport443='|'
		sed -e "s/443$hookport443//" -i /tmp/7620koolproxy/koolproxy_hookport.txt
		do_i=1 && hookport1="" && hookport2="" && hookport3="" && hookport4="" && hookport5=""
		for hookport in $(cat /tmp/7620koolproxy/koolproxy_hookport.txt | sed s/\|/\ /g)
		do
			[ "$do_i" -eq 1 ] && hookport1=$hookport
			[ "$do_i" -eq 15 ] && hookport2=$hookport
			[ "$do_i" -eq 30 ] && hookport3=$hookport
			[ "$do_i" -eq 45 ] && hookport4=$hookport
			[ "$do_i" -eq 60 ] && hookport5=$hookport
			[ "$do_i" -gt 1 ] && [ "$do_i" -lt 15 ] && hookport1=$hookport1","$hookport
			[ "$do_i" -gt 15 ] && [ "$do_i" -lt 30 ] && hookport2=$hookport2","$hookport
			[ "$do_i" -gt 30 ] && [ "$do_i" -lt 45 ] && hookport3=$hookport3","$hookport
			[ "$do_i" -gt 45 ] && [ "$do_i" -lt 60 ] && hookport4=$hookport4","$hookport
			[ "$do_i" -gt 60 ] && [ "$do_i" -lt 75 ] && hookport5=$hookport5","$hookport
			do_i=`expr $do_i + 1`
		done
		[ ! -z "$hookport1" ] && iptables -t nat -I PREROUTING $wifidognx -p tcp -m multiport --dports $hookport1 -j AD_BYBY
		[ ! -z "$hookport2" ] && iptables -t nat -I PREROUTING $wifidognx -p tcp -m multiport --dports $hookport2 -j AD_BYBY
		[ ! -z "$hookport3" ] && iptables -t nat -I PREROUTING $wifidognx -p tcp -m multiport --dports $hookport3 -j AD_BYBY
		[ ! -z "$hookport4" ] && iptables -t nat -I PREROUTING $wifidognx -p tcp -m multiport --dports $hookport4 -j AD_BYBY
		[ ! -z "$hookport5" ] && iptables -t nat -I PREROUTING $wifidognx -p tcp -m multiport --dports $hookport5 -j AD_BYBY
		[ "$koolproxy_https" != "1" ] && iptables -t nat -I PREROUTING $wifidognx -p tcp -m set --match-set ad_spec_src_https src --dport 443 -j AD_BYBY
		[ "$koolproxy_https" = "1" ] && iptables -t nat -I PREROUTING $wifidognx -p tcp --dport 443 -j AD_BYBY
	else
		[ "$koolproxy_https" = "1" ] && iptables -t nat -I PREROUTING $wifidognx -p tcp -m multiport --dports 80,443,8080 -j AD_BYBY
		[ "$koolproxy_https" != "1" ] && iptables -t nat -I PREROUTING $wifidognx -p tcp -m multiport --dports 80,8080 -j AD_BYBY
	fi
	iptables -t nat -A AD_BYBY_to -p tcp -j REDIRECT --to-ports 3000
	dns_redirect
	sleep 1
	gen_include &
	logger -t "【iptables】" "完成添加3000规则"
	[ "$adbyby_mode_x" == 1 ] && koolproxy_cp_rules
}


gen_special_purpose_ip () {

#处理肯定不走通道的目标网段
lan_ipaddr=`nvram get lan_ipaddr`
kcptun_enable=`nvram get kcptun_enable`
[ -z $kcptun_enable ] && kcptun_enable=0 && nvram set kcptun_enable=$kcptun_enable
kcptun_server=`nvram get kcptun_server`
if [ "$kcptun_enable" != "0" ] ; then
if [ -z $(echo $kcptun_server | grep : | grep -v "\.") ] ; then 
resolveip=`ping -4 -n -q -c1 -w1 -W1 $kcptun_server | head -n1 | sed -r 's/\(|\)/|/g' | awk -F'|' '{print $2}'`
[ -z "$resolveip" ] && resolveip=`ping -6 -n -q -c1 -w1 -W1 $kcptun_server | head -n1 | sed -r 's/\(|\)/|/g' | awk -F'|' '{print $2}'`
[ -z "$resolveip" ] && resolveip=`arNslookup $kcptun_server | sed -n '1p'` 
kcptun_server=$resolveip
else
# IPv6
kcptun_server=$kcptun_server
fi
fi

[ "$kcptun_enable" = "0" ] && kcptun_server=""
ss_enable=`nvram get ss_enable`
[ -z $ss_enable ] && ss_enable=0 && nvram set ss_enable=$ss_enable
[ "$ss_enable" = "0" ] && ss_s1_ip=""
ss_server=`nvram get ss_server`
if [ "$ss_enable" != "0" ] ; then
if [ -z $(echo $ss_server | grep : | grep -v "\.") ] ; then 
resolveip=`ping -4 -n -q -c1 -w1 -W1 $ss_server | head -n1 | sed -r 's/\(|\)/|/g' | awk -F'|' '{print $2}'`
[ -z "$resolveip" ] && resolveip=`ping -6 -n -q -c1 -w1 -W1 $ss_server | head -n1 | sed -r 's/\(|\)/|/g' | awk -F'|' '{print $2}'`
[ -z "$resolveip" ] && resolveip=`arNslookup $ss_server | sed -n '1p'` 
ss_s1_ip=$resolveip
else
# IPv6
ss_s1_ip=$ss_server
fi
fi
ss_s1_ip_echo="`echo "$ss_s1_ip" | grep -v ":" `"
kcptun_server_echo="`echo "$kcptun_server" | grep -v ":" `"
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
$lan_ipaddr
$ss_s1_ip_echo
$kcptun_server_echo
EOF

}

include_ac_rules () {
iptables-restore -n <<-EOF
*$1
:AD_BYBY - [0:0]
:AD_BYBY_LAN_AC - [0:0]
:AD_BYBY_WAN_AC - [0:0]
:AD_BYBY_to - [0:0]
-A AD_BYBY -m set --match-set ad_spec_dst_sp dst -j RETURN
-A AD_BYBY -j AD_BYBY_LAN_AC
-A AD_BYBY_LAN_AC -m set --match-set ad_spec_src_bp src -j RETURN
-A AD_BYBY_LAN_AC -m set --match-set ad_spec_src_fw src -j AD_BYBY_to
-A AD_BYBY_LAN_AC -m set --match-set ad_spec_src_ac src -j AD_BYBY_WAN_AC
-A AD_BYBY_LAN_AC -j ${LAN_TARGET:=AD_BYBY_WAN_AC}
-A AD_BYBY_WAN_AC -m set --match-set adbybylist dst -j ${ADBYBYLIST_TARGET:=AD_BYBY_to}
-A AD_BYBY_WAN_AC -j ${WAN_TARGET:=AD_BYBY_to}
COMMIT
EOF
}

include_ac_rules2 () {
cat /tmp/ad_spec_lan_DOMAIN.txt | grep -v '^#' | sort -u | grep -v '^$' | grep -v "\." | sed s/！/!/g > /tmp/ad_spec_lan.txt
while read line
do
for host in $line; do
	mac="${host:2}"; mac=$(echo $mac | sed s/://g| sed s/：//g | tr '[a-z]' '[A-Z]'); mac="${mac:0:2}:${mac:2:2}:${mac:4:2}:${mac:6:2}:${mac:8:2}:${mac:10:2}";
if [ ! -z "$mac" ] ; then
	case "${host:0:1}" in
		s|S)
			iptables -t $1 -I AD_BYBY_LAN_AC -m mac --mac-source $mac -p tcp --dport 443 -j AD_BYBY_to
			;;
		n|N)
			iptables -t $1 -I AD_BYBY_LAN_AC -m mac --mac-source $mac -j AD_BYBY_WAN_AC 
			;;
		g|G)
			iptables -t $1 -I AD_BYBY_LAN_AC -m mac --mac-source $mac -j AD_BYBY_to
			;;
		b|B)
			iptables -t $1 -I AD_BYBY_LAN_AC -m mac --mac-source $mac -j RETURN
			;;
	esac
fi
done
done < /tmp/ad_spec_lan.txt

}

gen_include () {
[ -n "$FWI" ] || return 0
cat <<-CAT >>$FWI
iptables-restore -n <<-EOF
$(iptables-save | sed  "s/webstr--url/webstr --url/g" | grep -E "$TAG|^\*|^COMMIT" |sed -e "s/^-A \(OUTPUT\|PREROUTING\)/-I \1 1/")
EOF
CAT
return $?
}


dns_redirect () {
	# 强制使用路由的DNS
	lan_ipaddr=`nvram get lan_ipaddr`
	if [ "$ss_DNS_Redirect" == "1" ] && [ ! -z "$lan_ipaddr" ] ; then
	iptables-restore -n <<-EOF
*nat
:AD_BYBY_DNS_LAN_DG - [0:0]
:AD_BYBY_DNS_LAN_AC - [0:0]
:AD_BYBY_DNS_WAN_AC - [0:0]
:AD_BYBY_DNS_WAN_FW - [0:0]
-A AD_BYBY_DNS_LAN_DG -d $lan_ipaddr -p udp -j RETURN
-A AD_BYBY_DNS_LAN_DG -d $ss_DNS_Redirect_IP -p udp -j RETURN
-A AD_BYBY_DNS_LAN_DG -j AD_BYBY_DNS_LAN_AC
-A AD_BYBY_DNS_LAN_AC -m set --match-set ad_spec_src_bp src -j RETURN
-A AD_BYBY_DNS_LAN_AC -m set --match-set ad_spec_src_fw src -j AD_BYBY_DNS_WAN_FW
-A AD_BYBY_DNS_LAN_AC -m set --match-set ad_spec_src_ac src -j AD_BYBY_DNS_WAN_AC
-A AD_BYBY_DNS_LAN_AC -j ${DNS_LAN_TARGET:=AD_BYBY_DNS_WAN_AC}
-A AD_BYBY_DNS_WAN_AC -j AD_BYBY_DNS_WAN_FW
COMMIT
EOF
		logger -t "【koolproxy】" "udp53端口（DNS）地址重定向为 $ss_DNS_Redirect_IP 强制使用重定向地址的DNS"
		iptables -t nat -A PREROUTING -s $lan_ipaddr/24 -p udp --dport 53 -j AD_BYBY_DNS_LAN_DG
		iptables -t nat -A AD_BYBY_DNS_WAN_FW -j DNAT --to $ss_DNS_Redirect_IP
	fi

}

re_ca_key () {
[ "$(nvram get app_86)" == "re_ca_key" ] && nvram set app_86=0
rm -rf /etc/storage/koolproxy_rules_list.sh /etc/storage/koolproxy_rules_script.sh
rm -rf /tmp/7620koolproxy
rm -rf /etc/storage/koolproxy
rm -rf /tmp/7620koolproxy.tgz
needed_restart=1

}

initconfig () {

koolproxy_rules_script="/etc/storage/koolproxy_rules_script.sh"
if [ ! -f "$koolproxy_rules_script" ] || [ ! -s "$koolproxy_rules_script" ] ; then
	cat > "$koolproxy_rules_script" <<-\EEE
!  ******************************* koolproxy 自定义过滤语法简表 *******************************
!  ------------------------ 规则基于adblock规则，并进行了语法部分的扩展 ------------------------
!  ABP规则请参考https://adblockplus.org/zh_CN/filters，下面为大致摘要
!  "!" 为行注释符，注释行以该符号起始作为一行注释语义，用于规则描述
!  "@@" 为白名单符，白名单具有最高优先级，放行过滤的网站，例如:@@||taobao.com
!  "@@@@" 超级白名单，比白名单符拥有更高的优先级，主要用于放行https网站，例如:@@@@||https://taobao.com
!  ------------------------------------------------------------------------------------------
!  "*" 为字符通配符，能够匹配0长度或任意长度的字符串，该通配符不能与正则语法混用。
!  "^" 为分隔符，可以是除了字母、数字或者 _ - . % 之外的任何字符。
!  "~" 为排除标识符，通配符能过滤大多数广告，但同时存在误杀, 可以通过排除标识符修正误杀链接。
!  "$image" 为识别图片变量，搭配规则使用作用于屏蔽图片，例如:||baidu.com/cdn/adv_$image
!  "$script" 为识别脚本变量，搭配规则使用作用于屏蔽脚本，例如:||baidu.com/cdn/adv_$script
!  "$c" 为解除跨域访问，例如:|http://nl-rcd.iqiyi.com/crossdomain.xml$c
!  "$agent" 为限定浏览器过滤的标识头，例如:|http://www.baidu/adv/xxx.jpg$agent=Chrome,~Firefox
!  "$domain" 为指定网站过滤，例如:|http://*/adv/xxx.jpg$domain=~baidu.com|qq.com
!  注：通配符仅在 url 规则中支持，html 规则中不支持
!  ------------------------------------------------------------------------------------------
!  "|" 为管线符号，来表示地址的最前端或最末端
!  "||" 为子域通配符，方便匹配主域名下的所有子域
!  用法及例子如下：(以下等号表示等价于)
!  ||xx.com/ad          =  http://xx.com/ad* || http://*.xx.com/ad*
!  ||http://xx.com/ad   =  http://xx.com/ad* || http://*.xx.com/ad*
!  ||https://xx.com/ad  =  https://xx.com/ad* || https://*.xx.com/ad*
!  |xx.com/ad           =  http://xx.com/ad*
!  |http://xx.com/ad    =  http://xx.com/ad*
!  |https://xx.com/ad   =  https://xx.com/ad*
!  ad                   =  http://*ad*
!  http://ad            =  http://*ad*
!  https://ad           =  不支持，需要指定域名，如下例
!  https://xx.com/ad    =  |https://xx.com/ad  =  https://xx.com/ad*
!  [同时可以表示两个以及两个以上的域名]如下例子
!  https://xx.ad.com 和 https://xxx.xx.ad.com  =  ||https://ad.com (注意! 由于https的原因使用要非常谨慎,不可以大范围使用)
!  ------------------------------------------------------------------------------------------
!  兼容adblock规则的html规则语法，例如：
!  fulldls.com,torrentzap.com##.tp_reccomend_banner
!  但是推荐写成以下标准写法：
!  ||fulldls.com##.tp_reccomend_banner
!  ||torrentzap.com##.tp_reccomend_banner
!  如果一个网站html规则有多条，可以合并为这样：
!  ||torrentzap.com##.tp_reccomend_banner,.ad_top,[class="ad_right"]......
!  ------------------------------------------------------------------------------------------
!  文本替换语法：$s@匹配内容@替换内容@
!  文本替换例子：|http://cdn.pcbeta.js.inimc.com/data/cache/common.js?$s@old@new@
!  重定向语法：$r@匹配内容@替换内容@
!  重定向例子：|http://koolshare.cn$r@http://koolshare.cn/*@http://www.qq.com@
!  非标准端口过滤语法：||abc.com:8081/ad.html或者|http://adb.com:8081/
!  注：文本替换语法及重定向语法中的匹配内容不仅支持通配符功能，而且额外支持以下功能
!  支持通配符 * 和 ? 表示单个字符
!  支持全正则匹配，/正则内容/ 表示应用正则匹配
!  正则替换：替换内容支持 $1 $2 这样的符号
!  普通替换：替换内容支持 * 这样的符号，表示把命中的内容复制到替换的内容。（类似 $1 $2，但是 * 号会自动计算数字）
!  ------------------------------------------------------------------------------------------
!  未来将逐步添加相关语法，兼容adblock puls的更多语法，敬请期待。
!  *****************************************************************************************

EEE
	chmod 755 "$koolproxy_rules_script"
fi

koolproxy_rules_list="/etc/storage/koolproxy_rules_list.sh"
if [ ! -f "$koolproxy_rules_list" ] || [ ! -s "$koolproxy_rules_list" ] ; then
	cat > "$koolproxy_rules_list" <<-\EEE
第三方规则：
#你也能在此处添加第三方规则，不过第三方规则不能保证其和koolproxy的兼容性，有时候甚至会其它规则出现相互冲突。
#请确保第三方规则链接有对应的.md5链接，例如https://kprule.com/daily.txt，
#应该有对应的https://kprule.com/daily.txt.md5 链接，koolproxy才能正确下载规则。

#koolproxy的工作原理是基于规则来过滤页面元素，如果某些网站的一些元素无法屏蔽，
#可能是规则没有覆盖到这些网站，大家可以通过自己编写规则来实现屏蔽，或者反馈给规则维护人员，
#维护人员采纳后会通过规则推送，来实现这些网站元素的屏蔽。
#规则的更新由koolproxy主程序发起，用户只需要添加规则文件名，规则地址等信息即可获得相应规则。
#（可选项：前面添加#停用规则,删除前面的#可生效）
# 开关 0表示关闭 1表示开启
# 开关|规则名字|规则网址|规则备注名字
1|koolproxy.txt|https://gcore.jsdelivr.net/gh/houzi-/CDN/koolproxy.txt|
1|daily.txt|https://gcore.jsdelivr.net/gh/houzi-/CDN/daily.txt|
1|kp.dat|https://gcore.jsdelivr.net/gh/houzi-/CDN/kp.dat|
1|user.txt||

EEE
	chmod 755 "$koolproxy_rules_list"
fi

}

initconfig

case $ACTION in
start)
	koolproxy_close
	koolproxy_check
	;;
check)
	koolproxy_check
	;;
stop)
	koolproxy_close
	;;
keep)
	#koolproxy_check
	koolproxy_keep
	;;
A)
	koolproxy_add_rules
	;;
D)
	koolproxy_flush_rules
	;;
C)
	koolproxy_cp_rules
	;;
update_ad)
	koolproxy_mount
	rm -rf /tmp/7620koolproxy/koolproxy
	koolproxy_restart o
	koolproxy_restart
	;;
*)
	koolproxy_check
	;;
esac

