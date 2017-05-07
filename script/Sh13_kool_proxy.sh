#!/bin/sh
#copyright by hiboy
source /etc/storage/script/init.sh
TAG="AD_BYBY"		  # iptables tag
koolproxy_enable=`nvram get koolproxy_enable`
[ -z $koolproxy_enable ] && koolproxy_enable=0 && nvram set koolproxy_enable=0
if [ "$koolproxy_enable" != "0" ] ; then
nvramshow=`nvram showall | grep ss | awk '{print gensub(/'"'"'/,"'"'"'\"'"'"'\"'"'"'","g",$0);}'| awk '{print gensub(/=/,"='\''",1,$0)"'\'';";}'` && eval $nvramshow
nvramshow=`nvram showall | grep adbyby | awk '{print gensub(/'"'"'/,"'"'"'\"'"'"'\"'"'"'","g",$0);}'| awk '{print gensub(/=/,"='\''",1,$0)"'\'';";}'` && eval $nvramshow
nvramshow=`nvram showall | grep adm | awk '{print gensub(/'"'"'/,"'"'"'\"'"'"'\"'"'"'","g",$0);}'| awk '{print gensub(/=/,"='\''",1,$0)"'\'';";}'` && eval $nvramshow
nvramshow=`nvram showall | grep koolproxy | awk '{print gensub(/'"'"'/,"'"'"'\"'"'"'\"'"'"'","g",$0);}'| awk '{print gensub(/=/,"='\''",1,$0)"'\'';";}'` && eval $nvramshow

[ -z $adbyby_mode_x ] && adbyby_mode_x=0 && nvram set adbyby_mode_x=0

koolproxyfile="https://koolproxy.com/downloads/mipsel"
koolproxyfilecdn="https://github.com/koolproxy/koolproxy-bin/raw/master/mipsel"
koolproxyfile2="$hiboyfile/koolproxy"
koolproxyfile22="$hiboyfile2/koolproxy"
koolproxyfile3="$hiboyfile/7620koolproxy.tgz"
koolproxyfile33="$hiboyfile2/7620koolproxy.tgz"

FWI="/tmp/firewall.adbyby.pdcn" # firewall include file
AD_LAN_AC_IP=`nvram get AD_LAN_AC_IP`
AD_LAN_AC_IP=${AD_LAN_AC_IP:-"0"}
lan_ipaddr=`nvram get lan_ipaddr`
[ -z "$ss_DNS_Redirect_IP" ] && ss_DNS_Redirect_IP=$lan_ipaddr
[ "$koolproxy_video" = "1" ] && mode_video=" -e " || mode_video=""
adbyby_adblocks=${adbyby_adblocks:-"0"}

fi
#检查 dnsmasq 目录参数
confdir=`grep conf-dir /etc/storage/dnsmasq/dnsmasq.conf | sed 's/.*\=//g'`
if [ -z "$confdir" ] ; then 
	confdir="/tmp/ss/dnsmasq.d"
fi
[ ! -d "$confdir" ] && mkdir -p $confdir
gfwlist="/r.gfwlist.conf"
gfw_black_list="gfwlist"

if [ ! -z "$(echo $scriptfilepath | grep -v "/tmp/script/" | grep kool_proxy)" ]  && [ ! -s /tmp/script/_kool_proxy ] ; then
	mkdir -p /tmp/script
	ln -sf $scriptfilepath /tmp/script/_kool_proxy
	chmod 777 /tmp/script/_kool_proxy
fi

koolproxy_mount () {

ss_opt_x=`nvram get ss_opt_x`
upanPath=""
[ "$ss_opt_x" = "3" ] && upanPath="`df -m | grep /dev/mmcb | grep "/media" | awk '{print $NF}' | awk 'NR==1' `"
[ "$ss_opt_x" = "4" ] && upanPath="`df -m | grep "/dev/sd" | grep "/media" | awk '{print $NF}' | awk 'NR==1' `"
[ -z "$upanPath" ] && [ "$ss_opt_x" = "1" ] && upanPath="`df -m | grep /dev/mmcb | grep "/media" | awk '{print $NF}' | awk 'NR==1' `"
[ -z "$upanPath" ] && [ "$ss_opt_x" = "1" ] && upanPath="`df -m | grep "/dev/sd" | grep "/media" | awk '{print $NF}' | awk 'NR==1' `"
echo "$upanPath"
if [ ! -z "$upanPath" ] ; then 
	logger -t "【koolproxy】" "已挂载储存设备, 主程序放外置设备存储"
	initopt
	mkdir -p $upanPath/ad/7620koolproxy
	ln -sf "$upanPath/ad/7620koolproxy" /tmp/7620koolproxy
	if [ -s /etc_ro/7620koolproxy_*.tgz ] && [ ! -s "$upanPath/ad/7620koolproxy/koolproxy" ] ; then
		logger -t "【koolproxy】" "使用内置主程序"
		untar.sh /etc_ro/7620koolproxy_*.tgz $upanPath/ad $upanPath/ad/7620koolproxy/data/version
	fi
	if [ ! -s "$upanPath/ad/7620koolproxy/data/version" ] ; then
		logger -t "【koolproxy】" "开始下载 7620koolproxy.tgz"
		wgetcurl.sh $upanPath/ad/7620koolproxy.tgz $koolproxyfile3 $koolproxyfile33
		untar.sh $upanPath/ad/7620koolproxy.tgz $upanPath/ad $upanPath/ad/7620koolproxy/data/version
	fi
else
	logger -t "【koolproxy】" "未挂载储存设备, 主程序放路由内存存储"
	mkdir -p /tmp/7620koolproxy
	if [ -s /etc_ro/7620koolproxy_*.tgz ] && [ ! -s "/tmp/7620koolproxy/koolproxy" ] ; then
		logger -t "【koolproxy】" "使用内置主程序"
		untar.sh /etc_ro/7620koolproxy_*.tgz /tmp /tmp/7620koolproxy/data/version
	fi
	if [ ! -s "/tmp/7620koolproxy/data/version" ] ; then
		logger -t "【koolproxy】" "开始下载 7620koolproxy.tgz"
		wgetcurl.sh /tmp/7620koolproxy.tgz $koolproxyfile3 $koolproxyfile33
		untar.sh /tmp/7620koolproxy.tgz /tmp /tmp/7620koolproxy/data/version
	fi
fi
export PATH='/tmp/7620koolproxy:/etc/storage/bin:/tmp/script:/etc/storage/script:/opt/usr/sbin:/opt/usr/bin:/opt/sbin:/opt/bin:/usr/local/sbin:/usr/sbin:/usr/bin:/sbin:/bin'
hash koolproxy 2>/dev/null || rm -rf /tmp/7620koolproxy/*
}

koolproxy_check () {

A_restart=`nvram get koolproxy_status`
B_restart="$koolproxy_enable$ss_link_1$koolproxy_auto$koolproxy_video$koolproxy_update$koolproxy_update_hour$koolproxy_update_min$koolproxyfile$koolproxyfile2$koolproxyfile3$lan_ipaddr$koolproxy_https$adbyby_mode_x$adm_hookport$koolproxy_adblock$adbyby_CPUAverages$ss_DNS_Redirect$ss_DNS_Redirect_IP$ss_DNS_Redirect$(cat /etc/storage/ad_config_script.sh | grep -v "^$" | grep -v "^#")$(cat /etc/storage/koolproxy_rules_script.sh /etc/storage/koolproxy_rules_list.sh | grep -v "^$" | grep -v "^!")"
B_restart=`echo -n "$B_restart" | md5sum | sed s/[[:space:]]//g | sed s/-//g`
if [ "$A_restart" != "$B_restart" ] ; then
	nvram set koolproxy_status=$B_restart
	needed_restart=1
else
	needed_restart=0
fi
if [ "$koolproxy_enable" != "1" ] && [ "$needed_restart" = "1" ] ; then
	[ ! -z "`pidof koolproxy`" ] && logger -t "【koolproxy】" "停止 koolproxy" && koolproxy_close
	{ eval $(ps -w | grep "$scriptname" | grep -v grep | awk '{print "kill "$1";";}'); exit 0; }
fi
if [ "$koolproxy_enable" = "1" ] ; then
	if [ "$needed_restart" = "1" ] ; then
		koolproxy_close
		koolproxy_start
	else
		[ -z "`pidof koolproxy`" ] || [ ! -s "/tmp/7620koolproxy/koolproxy" ] && nvram set koolproxy_status=00 && { eval "$scriptfilepath start &"; exit 0; }
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
nvram set koolproxy_rules_date_local="`sed -n '1,10p' /tmp/7620koolproxy/data/rules/koolproxy.txt | grep "$(sed -n '1,10p' /tmp/7620koolproxy/data/rules/koolproxy.txt | grep -Eo '[0-9]+-[0-9]+-[0-9]+ [0-9]+:[0-9]+' | sed -n '1p')" | sed 's/[x!]//g' | sed -r 's/-{2,}//g' | sed -r 's/\ {2}//g' | sed -r 's/\ {2}//g'`"
nvram set koolproxy_rules_nu_local="`cat /tmp/7620koolproxy/data/rules/koolproxy.txt | grep -v ! | wc -l`"
nvram set koolproxy_video_date_local="`sed -n '1,10p' /tmp/7620koolproxy/data/rules/koolproxy.txt | grep "$(sed -n '1,10p' /tmp/7620koolproxy/data/rules/koolproxy.txt | grep -Eo '[0-9]+-[0-9]+-[0-9]+ [0-9]+:[0-9]+' | sed -n '2p')" | sed 's/[x!]//g' | sed -r 's/-{2,}//g' | sed -r 's/\ {2}//g' | sed -r 's/\ {2}//g'`"
nvram set koolproxy_h="`/tmp/7620koolproxy/koolproxy -h | awk 'NR==1{print}'`】【`sed -n '1,10p' /tmp/7620koolproxy/data/rules/daily.txt | grep "$(sed -n '1,10p' /tmp/7620koolproxy/data/rules/daily.txt | grep -Eo '[0-9]+-[0-9]+-[0-9]+ [0-9]+:[0-9]+' | sed -n '1p')" | sed 's/[x!]//g' | sed -r 's/-{2,}//g' | sed -r 's/\ {2}//g' | sed -r 's/\ {2}//g'`"
fi
cat > "/tmp/sh_ad_kp_keey_k.sh" <<-ADMK
#!/bin/sh
sleep 919
koolproxy_enable=\`nvram get koolproxy_enable\`
if [ ! -f /tmp/cron_adb.lock ] && [ "\$koolproxy_enable" = "1" ] ; then
eval \$(ps -w | grep "$scriptname" | grep -v grep | awk '{print "kill "\$1";";}')
eval \$(ps -w | grep "$scriptname keep" | grep -v grep | awk '{print "kill "\$1";";}')
eval "$scriptfilepath keep &"
exit 0
fi
ADMK
chmod 777 "/tmp/sh_ad_kp_keey_k.sh"
killall sh_ad_kp_keey_k.sh
killall -9 sh_ad_kp_keey_k.sh
/tmp/sh_ad_kp_keey_k.sh &

rm -f /tmp/cron_adb.lock
reb="1"
runx="1"
[ -z $ss_link_1 ] && ss_link_1="email.163.com" && nvram set ss_link_1="email.163.com"
[ -z $ss_link_2 ] && ss_link_2="www.google.com.hk" && nvram set ss_link_2="www.google.com.hk"
[ $ss_link_1 == "www.163.com" ] && ss_link_1="email.163.com" && nvram set ss_link_1="email.163.com"
while true; do
[ ! -s "/tmp/7620koolproxy/koolproxy" ] && nvram set koolproxy_status=00 && { logger -t "【koolproxy】" "重新启动"; eval "$scriptfilepath start &"; exit 0; }
if [ ! -f /tmp/cron_adb.lock ] ; then
	if [ "$reb" -gt 5 ] && [ "$(cat /tmp/reb.lock)x" == "1x" ] ; then
		LOGTIME=$(date "+%Y-%m-%d %H:%M:%S")
		echo '['$LOGTIME'] 网络连接中断['$reb']，reboot.' >> /opt/log.txt 2>&1
		sleep 5
		reboot
	fi
	hash check_network 2>/dev/null && {
	check_network 3
	[ "$?" == "0" ] && check=200 || { check=404;  sleep 3; }
		if [ "$check" == "404" ] ; then
			check_network 3
			[ "$?" == "0" ] && check=200 || check=404
		fi
	}
	hash check_network 2>/dev/null || check=404
	[ "$check" == "404" ] && {
	curltest=`which curl`
	if [ -z "$curltest" ] || [ ! -s "`which curl`" ] ; then
		wget --continue --no-check-certificate -s -q -T 10 "$ss_link_1" -O /dev/null
		[ "$?" == "0" ] && check=200 || { check=404;  sleep 3; }
		if [ "$check" == "404" ] ; then
			wget --continue --no-check-certificate -s -q -T 10 "$ss_link_1" -O /dev/null
			[ "$?" == "0" ] && check=200 || check=404
		fi
	else
		check=`curl -k -s -w "%{http_code}" "$ss_link_1" -o /dev/null`
		[ "$check" != "200" ] &&  sleep 3
		[ "$check" != "200" ] && check=`curl -k -s -w "%{http_code}" "$ss_link_1" -o /dev/null`
	fi
	}
	if [ "$check" == "200" ] && [ ! -f /tmp/cron_adb.lock ] ; then
		reb=1
		PIDS=$(ps -w | grep "/tmp/7620koolproxy/koolproxy" | grep -v "grep" | wc -l)
		if [ "$PIDS" = 0 ] ; then 
			logger -t "【koolproxy】" "网络连接正常"
			logger -t "【koolproxy】" "找不到进程, 重启 koolproxy"
			koolproxy_flush_rules
			killall -15 koolproxy
			killall -9 koolproxy
			sleep 3
			cd /tmp/7620koolproxy/
			/tmp/7620koolproxy/koolproxy -d "$mode_video" >/dev/null 2>&1 &
			sleep 20
			reb=`expr $reb + 1`
		fi
		if [ "$PIDS" -gt 2 ] ; then 
			logger -t "【koolproxy】" "进程重复, 重启 koolproxy"
			koolproxy_flush_rules
			killall -15 koolproxy
			killall -9 koolproxy
			sleep 3
			cd /tmp/7620koolproxy/
			/tmp/7620koolproxy/koolproxy -d "$mode_video" >/dev/null 2>&1 &
			sleep 20
		fi
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
		runx=`expr $runx + 1`
	else
		# logger -t "【koolproxy】" "网络连接中断 $reb, 关闭 koolproxy"
		port=$(iptables -t nat -L | grep 'ports 3000' | wc -l)
		while [[ "$port" != 0 ]] 
		do
			logger -t "【koolproxy】" "网络连接中断 $reb, 关闭 koolproxy"
			koolproxy_flush_rules
			port=$(iptables -t nat -L | grep 'ports 3000' | wc -l)
			sleep 5
		done
		PIDS=$(ps -w | grep "/tmp/7620koolproxy/koolproxy" | grep -v "grep" | wc -l)
		if [ "$PIDS" != 0 ] ; then 
			killall -15 koolproxy
			killall -9 koolproxy
		fi
		reb=`expr $reb + 1`
	fi
	/etc/storage/ez_buttons_script.sh 3 & #更新按钮状态
	sleep 213
fi
sleep 23
koolproxy_keepcpu
done
}

koolproxy_keepcpu () {
if [ "$adbyby_CPUAverages" = "1" ] && [ ! -f /tmp/cron_adb.lock ] ; then
	processor=`cat /proc/cpuinfo| grep "processor"| wc -l`
	processor=`expr $processor \* 2`
	CPULoad=`uptime |sed -e 's/\ *//g' -e 's/.*://g' | awk -F ',' '{print $2;}' | sed -e 's/\..*//g'`
	if [ $((CPULoad)) -ge "$processor" ] ; then
		logger -t "【koolproxy】" "CPU 负载拥堵, 关闭 koolproxy"
		koolproxy_flush_rules
		/etc/storage/ez_buttons_script.sh 3 & #更新按钮状态
		killall -15 koolproxy
		killall -9 koolproxy
		touch /tmp/cron_adb.lock
		processor=`cat /proc/cpuinfo| grep "processor"| wc -l`
		processor=`expr $processor \* 2`
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
cru.sh d koolproxy_update &
port=$(iptables -t nat -L | grep 'ports 3000' | wc -l)
[ "$port" != 0 ] && koolproxy_flush_rules
[ "$adbyby_enable" != "1" ] && killall -15 adbyby sh_ad_byby_keey_k.sh
[ "$adbyby_enable" != "1" ] && killall -9 adbyby sh_ad_byby_keey_k.sh
[ "$adm_enable" != "1" ] && killall -15 adm sh_ad_m_keey_k.sh
[ "$adm_enable" != "1" ] && killall -9 adm sh_ad_m_keey_k.sh
killall -15 koolproxy sh_ad_kp_keey_k.sh
killall -9 koolproxy sh_ad_kp_keey_k.sh
rm -f /tmp/adbyby_host.conf
rm -f /tmp/7620koolproxy.tgz /tmp/cron_adb.lock /tmp/sh_ad_kp_keey_k.sh /tmp/cp_rules.lock
eval $(ps -w | grep "_kool_proxy keep" | grep -v grep | awk '{print "kill "$1";";}')
eval $(ps -w | grep "_kool_proxy.sh keep" | grep -v grep | awk '{print "kill "$1";";}')
eval $(ps -w | grep "$scriptname keep" | grep -v grep | awk '{print "kill "$1";";}')
}

koolproxy_start () {
nvram set button_script_1_s="KP"
/etc/storage/ez_buttons_script.sh 3 & #更新按钮状态
if [ -z "`pidof koolproxy`" ] && [ "$koolproxy_enable" = "1" ] && [ ! -f /tmp/cron_adb.lock ] ; then
	touch /tmp/cron_adb.lock
	for module in ip_set ip_set_bitmap_ip ip_set_bitmap_ipmac ip_set_bitmap_port ip_set_hash_ip ip_set_hash_ipport ip_set_hash_ipportip ip_set_hash_ipportnet ip_set_hash_net ip_set_hash_netport ip_set_list_set xt_set xt_TPROXY
	do
		modprobe $module
	done 
	koolproxy_mount
	if [ ! -s "/tmp/7620koolproxy/koolproxy" ] ; then
		logger -t "【koolproxy】" "开始下载 koolproxy"
		wgetcurl.sh /tmp/7620koolproxy/koolproxy $koolproxyfile $koolproxyfilecdn
	fi
	if [ ! -s "/tmp/7620koolproxy/koolproxy" ] ; then
		logger -t "【koolproxy】" "开始下载 koolproxy"
		wgetcurl.sh /tmp/7620koolproxy/koolproxy $koolproxyfile2 $koolproxyfile22
	fi
	if [ ! -s "/tmp/7620koolproxy/koolproxy" ] ; then
		logger -t "【koolproxy】" "下载失败, 注意检查端口是否有冲突,程序是否下载完整,10 秒后自动尝试重新启动" && sleep 10 && { nvram set koolproxy_status=00; eval "$scriptfilepath &"; exit 0; }
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
	# 
	
	# 处理第三方自定义规则 /tmp/rule_DOMAIN.txt
	/etc/storage/ad_config_script.sh
	adbyby_adblocks=`nvram get adbyby_adblocks`
	rm -f /tmp/7620koolproxy/data/user.bin
	rm -f /tmp/7620koolproxy/data/user.txt
	rm -rf `ls -L /tmp/7620koolproxy/data/*_*.dat`
	rm -rf `ls -L /tmp/7620koolproxy/data/*_*.txt`
	if [ "$adbyby_adblocks" = "1" ] ; then
		mkdir -p /tmp/7620koolproxy/
		logger -t "【koolproxy】" "下载 第三方自定义 规则"
		rm -f /tmp/7620koolproxy/user3adblocks.txt
		while read line
		do
		c_line=`echo $line |grep -v "#"`
		if [ ! -z "$c_line" ] ; then
			logger -t "【koolproxy】" "下载规则:$line"
			wgetcurl.sh /tmp/7620koolproxy/user2.txt $line
			grep -v '^!' /tmp/7620koolproxy/user2.txt | grep -E '^(@@\||\||[[:alnum:]])' | sort -u | grep -v "^$" >> /tmp/7620koolproxy/user3adblocks.txt
			rm -f /tmp/7620koolproxy/user2.txt
		fi
		done < /tmp/rule_DOMAIN.txt
	fi
	
	# 处理 koolproxy加载规则列表 /etc/storage/koolproxy_rules_list.sh
	rm -f /tmp/7620koolproxy/user_store.txt
	while read line
	do
	c_line=`echo $line |grep -v "#" |grep -v '*'`
	if [ ! -z "$c_line" ] ; then
		logger -t "【koolproxy】" "下载规则:$line"
		wgetcurl.sh /tmp/7620koolproxy/user2.txt $line
		grep -v '^!' /tmp/7620koolproxy/user2.txt | sort -u | grep -v "^$" >> /tmp/7620koolproxy/user_store.txt
		rm -f /tmp/7620koolproxy/user2.txt
	fi
	done < /etc/storage/koolproxy_rules_list.sh
	
	# 合并规则
	cat /etc/storage/koolproxy_rules_script.sh | grep -v '^!' | grep -v "^$" > /tmp/7620koolproxy/user.txt
	grep -v '^!' /tmp/7620koolproxy/user3adblocks.txt | grep -v "^$" >> /tmp/7620koolproxy/user.txt
	grep -v '^!' /tmp/7620koolproxy/user_store.txt | grep -v "^$" >> /tmp/7620koolproxy/user.txt
	ln -sf /tmp/7620koolproxy/user.txt /tmp/7620koolproxy/data/user.txt
	ln -sf /tmp/7620koolproxy/user.txt /tmp/7620koolproxy/data/rules/user.txt
	cd /tmp/7620koolproxy/
	rm -f /tmp/7620koolproxy/user2.txt /tmp/7620koolproxy/user3adblocks.txt /tmp/7620koolproxy/user_store.txt
	
	[ "$koolproxy_uprules" != "2" ] && rm -rf /tmp/7620koolproxy/data/rules/1.dat /tmp/7620koolproxy/data/rules/kp.dat /tmp/7620koolproxy/data/rules/koolproxy.txt
	# 更新规则
	#hash daydayup 2>/dev/null && update_kp_rules_daydayup
	#hash daydayup 2>/dev/null || update_kp_rules
	logger -t "【koolproxy】" "启动 koolproxy 程序"
	chmod 777 /tmp/7620koolproxy/koolproxy
	export PATH='/opt/usr/sbin:/opt/usr/bin:/opt/sbin:/opt/bin:/usr/local/sbin:/usr/sbin:/usr/bin:/sbin:/bin'
	export LD_LIBRARY_PATH=/tmp/7620koolproxy/lib:/lib:/opt/lib
	nvram set koolproxy_h="`/tmp/7620koolproxy/koolproxy -h | awk 'NR==1{print}'`"
	cd /tmp/7620koolproxy/
	/tmp/7620koolproxy/koolproxy -d "$mode_video" >/dev/null 2>&1 &
	rm -f /tmp/adbyby_host.conf
	if [ "$adbyby_adblocks" = "1" ] ; then
		logger -t "【koolproxy】" "加载 第三方自定义 规则, 等候10秒"
		sleep 10
	else
		sleep 5
	fi

	I=15
	while [ ! -f /tmp/7620koolproxy/data/rules/koolproxy.txt ]; do
			I=$(($I - 1))
			[ $I -lt 0 ] && break
			sleep 1
	done
	[ -s /tmp/7620koolproxy/data/rules/koolproxy.txt ] && nvram set koolproxy_uprules=2
	[ ! -s /tmp/7620koolproxy/data/rules/koolproxy.txt ] && {
	logger -t "【koolproxy】" "自动更新规则失效，启用脚本手动下载更新。"
	nvram set koolproxy_uprules=1
	mkdir -p /tmp/7620koolproxy/data/rules
	cd /tmp/7620koolproxy/data/rules
	hash daydayup 2>/dev/null && update_kp_rules_daydayup
	hash daydayup 2>/dev/null || update_kp_rules
	killall koolproxy
	cd /tmp/7620koolproxy/
	/tmp/7620koolproxy/koolproxy -d "$mode_video" >/dev/null 2>&1 &
	}
	hash krdl 2>/dev/null && krdl_ipset
fi
if [ -s /tmp/7620koolproxy/data/rules/koolproxy.txt ] ; then
nvram set koolproxy_rules_date_local="`sed -n '1,10p' /tmp/7620koolproxy/data/rules/koolproxy.txt | grep "$(sed -n '1,10p' /tmp/7620koolproxy/data/rules/koolproxy.txt | grep -Eo '[0-9]+-[0-9]+-[0-9]+ [0-9]+:[0-9]+' | sed -n '1p')" | sed 's/[x!]//g' | sed -r 's/-{2,}//g' | sed -r 's/\ {2}//g' | sed -r 's/\ {2}//g'`"
nvram set koolproxy_rules_nu_local="`cat /tmp/7620koolproxy/data/rules/koolproxy.txt | grep -v ! | wc -l`"
nvram set koolproxy_video_date_local="`sed -n '1,10p' /tmp/7620koolproxy/data/rules/koolproxy.txt | grep "$(sed -n '1,10p' /tmp/7620koolproxy/data/rules/koolproxy.txt | grep -Eo '[0-9]+-[0-9]+-[0-9]+ [0-9]+:[0-9]+' | sed -n '2p')" | sed 's/[x!]//g' | sed -r 's/-{2,}//g' | sed -r 's/\ {2}//g' | sed -r 's/\ {2}//g'`"
fi

[ ! -z "`pidof koolproxy`" ] && logger -t "【koolproxy】" "启动成功"
[ -z "`pidof koolproxy`" ] && logger -t "【koolproxy】" "启动失败, 注意检查端口是否有冲突,程序是否下载完整,10 秒后自动尝试重新启动" && sleep 10 && { nvram set koolproxy_status=00; eval "$scriptfilepath &"; exit 0; }
koolproxy_add_rules
rm -f /tmp/7620koolproxy.tgz /tmp/cron_adb.lock
/etc/storage/ez_buttons_script.sh 3 & #更新按钮状态
logger -t "【koolproxy】" "守护进程启动"
#koolproxy_cron_job
eval "$scriptfilepath keep &"
}

koolproxy_rules_list () {

mkdir -p /tmp/7620koolproxy/data/rules
cat > "/tmp/7620koolproxy/data/rules/koolproxy_rules_list.sh" <<-\KPR
https://kprule.com/koolproxy.txt
https://kprule.com/kp.dat
https://kprule.com/daily.txt
KPR

}

update_kp_rules_daydayup () {
koolproxy_rules_list
cd /tmp/7620koolproxy/data/rules
daydayup /tmp/7620koolproxy/data/rules/koolproxy_rules_list.sh >> /tmp/syslog.log
[ $? -eq 0 ] && logger -t "【koolproxy】" "完成规则更新" || logger -t "【koolproxy】" "下载规则更新"
}

update_kp_rules () {

mkdir -p /tmp/7620koolproxy/rule_store
mkdir -p /tmp/7620koolproxy/rule_tmp
#rm -rf `ls -L /tmp/7620koolproxy/data/rules/*_*.dat`
#rm -rf `ls -L /tmp/7620koolproxy/data/rules/*_*.txt`
#rm -rf /tmp/7620koolproxy/data/rules/koolproxyrule_*
rm -rf /tmp/7620koolproxy/rule_tmp/*
rm -rf /tmp/7620koolproxy/data/rules/1.dat /tmp/7620koolproxy/data/rules/kp.dat /tmp/7620koolproxy/data/rules/koolproxy.txt
logger -t "【koolproxy】" "检测规则是否有更新"
koolproxy_rules_list
while read line
do
c_line=`echo $line |grep -v "#" |grep '*'`
file_name=${line##*/}
if [ ! -z $file_name ] && [ ! -z "$c_line" ] ; then
	rm -f /tmp/7620koolproxy/rule_store/$file_name
fi
c_line=`echo $line |grep -v "#" |grep -v '*'`
if [ ! -z $file_name ] && [ ! -z "$c_line" ] ; then
file_name=${line##*/}
	wgetcurl.sh /tmp/7620koolproxy/rule_tmp/$file_name $line
	if [ -f /tmp/7620koolproxy/rule_tmp/$file_name ] ; then
		MD5_TMP=`md5sum /tmp/7620koolproxy/rule_tmp/$file_name  | awk '{print $1}'`
		MD5_ORI=`md5sum /tmp/7620koolproxy/rule_store/$file_name| awk '{print $1}'`
		if [ ! -f /tmp/7620koolproxy/rule_store/$file_name ] || [ "$MD5_TMP"x != "$MD5_ORI"x ] ; then
			logger -t "【koolproxy】" " 更新【$file_name】，$line"
			mv -f /tmp/7620koolproxy/rule_tmp/$file_name /tmp/7620koolproxy/rule_store/$file_name
		else
			logger -t "【koolproxy】" " 本地【$file_name】已经是最新！，$line"
		fi
		ln -sf /tmp/7620koolproxy/rule_store/$file_name /tmp/7620koolproxy/data/rules/$file_name
	fi
fi
done < /tmp/7620koolproxy/data/rules/koolproxy_rules_list.sh
rm -rf /tmp/7620koolproxy/rule_tmp/*
}


flush_r () {
iptables -t nat -D PREROUTING -p tcp --dport 80 -j REDIRECT --to-ports 3000 &> /dev/null
iptables-save -c | sed  "s/webstr--url/webstr --url/g" | grep -v "$TAG" | iptables-restore -c
for setname in $(ipset -n list | grep -i "ad_spec"); do
	ipset destroy $setname 2>/dev/null
done
[ -n "$FWI" ] && echo '#!/bin/sh' >$FWI
}

krdl_ipset () {

[ ! -f /tmp/7620koolproxy/data/rules/koolproxy.txt ] && return 0
# Koolproxy Rules to Domain List
rm -f /tmp/7620koolproxy/domain.txt /tmp/7620koolproxy/domain2.txt /tmp/7620koolproxy/ip.txt
cd /tmp/7620koolproxy/data/rules
# while read line
# do
# c_line=`echo $line |grep -v "#" |grep '*'`
# file_name=${line##*/}
# if [ ! -z $file_name ] && [ ! -z "$c_line" ] ; then
	# [ -f ./$file_name ] && rm -f ./$file_name*
# fi
# c_line=`echo $line |grep -v "#" |grep -v '*'`
# file_name=${line##*/}
# if [ ! -z $file_name ] && [ ! -z "$c_line" ] ; then
	# [ -f ./$file_name ] && krdl ./$file_name
# fi
# done < /etc/storage/koolproxy_rules_list.sh
# krdl ./user.txt
krdl ./1.dat
krdl ./kp.dat
krdl ./koolproxy.txt
krdl ./user.txt
krdl ./daily.txt
sleep 2
eval $(ls| grep txt.http| awk '{print "cat /tmp/7620koolproxy/data/rules/"$1" >> /tmp/7620koolproxy/domain.txt;";}')
# 提取IP
cat  /tmp/7620koolproxy/domain.txt /tmp/7620koolproxy/koolproxy_blockip.txt | grep -Eo '^[0-9\.]*$' | sort -u | grep -v "^$" > /tmp/7620koolproxy/ip.txt
cat /tmp/7620koolproxy/ip.txt /tmp/7620koolproxy/koolproxy_blockip.txt | sort -u > /tmp/7620koolproxy/koolproxy_blockip.txt
# 提取Domain
cat  /tmp/7620koolproxy/domain.txt | grep  -Ev '^[0-9\.]*$' | sort -u > /tmp/7620koolproxy/domain2.txt
sed -e "s/^/ipset=\/\./" -e "s/$/\/black_koolproxy/" -i /tmp/7620koolproxy/domain2.txt
cat /tmp/7620koolproxy/domain2.txt /tmp/7620koolproxy/data/koolproxy_ipset.conf | sort -u > /tmp/adbyby_host.conf
# 删tmp
rm -f /tmp/7620koolproxy/data/rules/*.txt.http /tmp/7620koolproxy/data/rules/*.txt.https
rm -f /tmp/7620koolproxy/domain.txt /tmp/7620koolproxy/domain2.txt /tmp/7620koolproxy/ip.txt
}

koolproxy_cp_rules () {
rm -f /tmp/b/*
I=30
while [ -f /tmp/cp_rules.lock ]; do
		I=$(($I - 1))
		[ $I -lt 0 ] && break
		sleep 1
done
touch /tmp/cp_rules.lock
[ ! -f /tmp/adbyby_host.conf ] && [ -f /tmp/7620koolproxy/data/koolproxy_ipset.conf ] && cp -f /tmp/7620koolproxy/data/koolproxy_ipset.conf /tmp/adbyby_host.conf
#去除gfw donmain中与 adbyby host 包含的域名，这部分域名交由adbyby处理。
# 参考的awk指令写法
#  awk  'NR==FNR{a[$0]}NR>FNR{ if($1 in a) print $0}' file1 file2 #找出两文件中相同的值
#  awk  'NR==FNR{a[$0]}NR>FNR{ if(!($1 in a)) print $0}' file1 file2 #去除 file2 中file1的内容
#  awk 'NR==FNR{a[$0]++} NR>FNR&&a[$0]' file1 file2 #找出两个文件之间的相同部分
#  awk 'NR==FNR{a[$0]++} NR>FNR&&!a[$0]' file1 file2 #去除 file2 中file1的内容
if [ "$adbyby_mode_x" == 1 ] && [ -s /tmp/adbyby_host.conf ] ; then
logger -t "【iptables】" "添加 ipset 转发规则"
sed -Ei '/adbyby_host.conf|cflist.conf/d' /etc/storage/dnsmasq/dnsmasq.conf
sed  "s/\/black_koolproxy/\/adbybylist/" -i  /tmp/adbyby_host.conf
[ ! -z $whitehost ] && sed -Ei "/$(echo $whitehost | tr , \|)/d" /tmp/adbyby_host.conf
[ -f "$confdir$gfwlist" ] && gfw_black=$(grep "/$gfw_black_list" "$confdir$gfwlist" | sed 's/.*\=//g')
if [ -s "$confdir$gfwlist" ] && [ -s /tmp/adbyby_host.conf ] && [ ! -z "$gfw_black" ] ; then
	logger -t "【iptables】" "koolproxylist 规则处理开始"
	mkdir -p /tmp/b/
	sed -e '/^\#/d' -e "s/ipset=\/\./ipset=\//" -e "s/ipset=\/www\./ipset=\/\./" -e "s/ipset=\/bbs\./ipset=\/\./" -e "s/ipset=\/\./ipset=\//" -e "s/ipset=\//ipset=\/\./" -i /tmp/adbyby_host.conf
	sed -e '/^\#/d' -e "s/ipset=\/\./ipset=\//" -e "s/ipset=\/www\./ipset=\/\./" -e "s/ipset=\/bbs\./ipset=\/\./" -e "s/ipset=\/\./ipset=\//" -e "s/ipset=\//ipset=\/\./" -i "$confdir$gfwlist"
	sed -e '/^\#/d' -e "s/ipset=\///" -e "s/adbybylist//" /tmp/adbyby_host.conf > /tmp/b/adbyby_host去干扰.conf
	sed -e '/^\#/d' -e "s/ipset=\///" -e "s/$gfw_black_list//" -e "/server=\//d" "$confdir$gfwlist" > /tmp/b/gfwlist去干扰.conf
	awk 'NR==FNR{a[$0]++} NR>FNR&&a[$0]' /tmp/b/adbyby_host去干扰.conf /tmp/b/gfwlist去干扰.conf > /tmp/b/host相同行.conf
	[ -s /tmp/ss/cflist.conf ] && sed -e '/^\#/d' -e "s/ipset=\/\./ipset=\//" -e "s/ipset=\//ipset=\/\./" -e "s/ipset=\/\./\./" -e "s/cflist//" /tmp/ss/cflist.conf >> /tmp/b/host相同行.conf
	if [ -s /tmp/b/host相同行.conf ] ; then
		logger -t "【iptables】" "gfwlist 规则处理开始"
		sed -e "s/^/ipset=\//" -e "s/$/adbybylist/" /tmp/b/host相同行.conf > /tmp/b/host相同行2.conf
		awk 'NR==FNR{a[$0]++} NR>FNR&&!a[$0]' /tmp/b/host相同行2.conf /tmp/adbyby_host.conf > /tmp/b/adbyby_host不重复.conf
		sed -e "s/^/ipset=\//" -e "s/$/$gfw_black_list/" /tmp/b/host相同行.conf > /tmp/b/host相同行2.conf
		awk 'NR==FNR{a[$0]++} NR>FNR&&!a[$0]' /tmp/b/host相同行2.conf "$confdir$gfwlist" > /tmp/b/gfwlist不重复.conf
		sed -e "s/^/ipset=\//" -e "s/$/cflist/" /tmp/b/host相同行.conf > /tmp/b/list重复.conf
		cp -a -v /tmp/b/adbyby_host不重复.conf /tmp/adbyby_host.conf
		cp -a -v /tmp/b/gfwlist不重复.conf "$confdir$gfwlist"
		#rm -f "$confdir/cflist.conf"
		#cp -a -v /tmp/b/list重复.conf "$confdir/cflist.conf"
		cat /tmp/b/list重复.conf >> "$confdir/cflist.conf"
		logger -t "【iptables】" "gfwlist 规则处理完毕"
	fi
	grep -v '^#' $confdir/cflist.conf | sort -u | grep -v "^$" > /tmp/ss/cflist.conf
	grep -v '^#' /tmp/ss/cflist.conf | sort -u | grep -v "^$" > $confdir/cflist.conf
	echo "conf-file=$confdir/cflist.conf" >> "/etc/storage/dnsmasq/dnsmasq.conf"
fi
echo "conf-file=/tmp/adbyby_host.conf" >> "/etc/storage/dnsmasq/dnsmasq.conf"
ipset flush cflist
ipset flush adbybylist
ipset add adbybylist 110.110.110.110
if [ -f /tmp/7620koolproxy/koolproxy_blockip.txt ] ; then
	grep -v '^#' /tmp/7620koolproxy/koolproxy_blockip.txt | sort -u | grep -v "^$" | sed -e "s/^/-A adbybylist &/g" | ipset -R -!
fi
restart_dhcpd
logger -t "【iptables】" "koolproxylist 规则处理完毕"
rm -f /tmp/b/*
fi
rm -f /tmp/cp_rules.lock
}

koolproxy_flush_rules () {
logger -t "【iptables】" "删除3000转发规则"
flush_r
ipset -F adbybylist &> /dev/null
ipset destroy adbybylist &> /dev/null
#ipset -F cflist &> /dev/null
sed -Ei '/adbyby_host.conf/d' /etc/storage/dnsmasq/dnsmasq.conf
restart_dhcpd
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
ipset -! -N cflist iphash
ipset -! -N adbybylist iphash
lan_ipaddr=`nvram get lan_ipaddr`
ipset add ad_spec_src_bp $lan_ipaddr
ipset add ad_spec_src_bp 127.0.0.1
ipset add adbybylist 110.110.110.110
/etc/storage/ad_config_script.sh
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
grep -v '^#' /tmp/ad_spec_lan_DOMAIN.txt | sort -u | grep -v "^$" | sed s/！/!/g > /tmp/ad_spec_lan.txt
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
		#wifidogn=`iptables -t nat -L PREROUTING --line-number | grep Outgoing | awk '{print $1}' | awk 'END{print $1}'`  ## SS_SPEC
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
	echo "AD_BYBY-number:$wifidognx"
	if [ -f /tmp/7620koolproxy/koolproxy_hookport.txt ] && [ "$adm_hookport" == 1 ] ; then
		hookport443='|'
		sed -e "s/443$hookport443//" -i /tmp/7620koolproxy/koolproxy_hookport.txt
		i=1 && hookport1="" && hookport2="" && hookport3="" && hookport4="" && hookport5=""
		for hookport in $(cat /tmp/7620koolproxy/koolproxy_hookport.txt | sed s/\|/\ /g)
		do
			[ "$i" -eq 1 ] && hookport1=$hookport
			[ "$i" -eq 15 ] && hookport2=$hookport
			[ "$i" -eq 30 ] && hookport3=$hookport
			[ "$i" -eq 45 ] && hookport4=$hookport
			[ "$i" -eq 60 ] && hookport5=$hookport
			[ "$i" -gt 1 ] && [ "$i" -lt 15 ] && hookport1=$hookport1","$hookport
			[ "$i" -gt 15 ] && [ "$i" -lt 30 ] && hookport2=$hookport2","$hookport
			[ "$i" -gt 30 ] && [ "$i" -lt 45 ] && hookport3=$hookport3","$hookport
			[ "$i" -gt 45 ] && [ "$i" -lt 60 ] && hookport4=$hookport4","$hookport
			[ "$i" -gt 60 ] && [ "$i" -lt 75 ] && hookport5=$hookport5","$hookport
			i=`expr $i + 1`
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
	iptables -t nat -A AD_BYBY_to -p tcp -j REDIRECT --to-port 3000
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
kcptun_enable=${kcptun_enable:-"0"}
kcptun_server=`nvram get kcptun_server`
if [ "$kcptun_enable" != "0" ] ; then
resolveip=`/usr/bin/resolveip -4 -t 4 $kcptun_server | grep -v : | sed -n '1p'`
[ -z "$resolveip" ] && resolveip=`arNslookup $kcptun_server | sed -n '1p'` 
kcptun_server=$resolveip
fi

[ "$kcptun_enable" = "0" ] && kcptun_server=""
ss_enable=`nvram get ss_enable`
ss_enable=${ss_enable:-"0"}
[ "$ss_enable" = "0" ] && ss_s1_ip="" && ss_s2_ip=""
nvram set ss_server1=`nvram get ss_server`
ss_server1=`nvram get ss_server1`
ss_server2=`nvram get ss_server2`
kcptun2_enable=`nvram get kcptun2_enable`
kcptun2_enable=${kcptun2_enable:-"0"}
kcptun2_enable2=`nvram get kcptun2_enable2`
kcptun2_enable2=${kcptun2_enable2:-"0"}
[ "$ss_mode_x" != "0" ] && kcptun2_enable=$kcptun2_enable2
[ "$kcptun2_enable" = "2" ] && ss_server2=""
if [ "$ss_enable" != "0" ] ; then
if [ -z $(echo $ss_server1 | grep : | grep -v "\.") ] ; then 
resolveip=`/usr/bin/resolveip -4 -t 4 $ss_server1 | grep -v : | sed -n '1p'`
[ -z "$resolveip" ] && resolveip=`arNslookup $ss_server1 | sed -n '1p'` 
ss_s1_ip=$resolveip
else
# IPv6
ss_s1_ip=$ss_server1
fi
fi
if [ ! -z "$ss_server2" ] ; then
if [ -z $(echo $ss_server2 | grep : | grep -v "\.") ] ; then 
resolveip=`/usr/bin/resolveip -4 -t 4 $ss_server2 | grep -v : | sed -n '1p'`
[ -z "$resolveip" ] && resolveip=`arNslookup $ss_server2 | sed -n '1p'` 
ss_s2_ip=$resolveip
else
# IPv6
ss_s2_ip=$ss_server2
fi
fi
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
$ss_s1_ip
$ss_s2_ip
$kcptun_server
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
-A AD_BYBY_WAN_AC -m set --match-set cflist dst -j ${ADBYBYLIST_TARGET:=AD_BYBY_to}
-A AD_BYBY_WAN_AC -j ${WAN_TARGET:=AD_BYBY_to}
COMMIT
EOF
}

include_ac_rules2 () {
grep -v '^#' /tmp/ad_spec_lan_DOMAIN.txt | sort -u | grep -v "^$" | grep -v "\." | sed s/！/!/g > /tmp/ad_spec_lan.txt
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

koolproxy_cron_job(){
	koolproxy_update=${koolproxy_update:-"0"}
	koolproxy_update_hour=${koolproxy_update_hour:-"23"}
	koolproxy_update_min=${koolproxy_update_min:-"59"}
	if [ "0" == "$koolproxy_update" ] ; then
	[ $koolproxy_update_hour -gt 23 ] && koolproxy_update_hour=23 && nvram set koolproxy_update_hour=$koolproxy_update_hour
	[ $koolproxy_update_hour -lt 0 ] && koolproxy_update_hour=0 && nvram set koolproxy_update_hour=$koolproxy_update_hour
	[ $koolproxy_update_min -gt 59 ] && koolproxy_update_min=59 && nvram set koolproxy_update_min=$koolproxy_update_min
	[ $koolproxy_update_min -lt 0 ] && koolproxy_update_min=0 && nvram set koolproxy_update_min=$koolproxy_update_min
		logger -t "【koolproxy】" "开启规则定时更新，每天"$koolproxy_update_hour"时"$koolproxy_update_min"分，检查在线规则更新..."
		cru.sh a koolproxy_update "$koolproxy_update_min $koolproxy_update_hour * * * $scriptfilepath update &" &
	elif [ "1" == "$koolproxy_update" ] ; then
	#[ $koolproxy_update_hour -gt 23 ] && koolproxy_update_hour=23 && nvram set koolproxy_update_hour=$koolproxy_update_hour
	[ $koolproxy_update_hour -lt 0 ] && koolproxy_update_hour=0 && nvram set koolproxy_update_hour=$koolproxy_update_hour
	[ $koolproxy_update_min -gt 59 ] && koolproxy_update_min=59 && nvram set koolproxy_update_min=$koolproxy_update_min
	[ $koolproxy_update_min -lt 0 ] && koolproxy_update_min=0 && nvram set koolproxy_update_min=$koolproxy_update_min
		logger -t "【koolproxy】" "开启规则定时更新，每隔"$koolproxy_update_inter_hour"时"$koolproxy_update_inter_min"分，检查在线规则更新..."
		cru.sh a koolproxy_update "*/$koolproxy_update_min */$koolproxy_update_hour * * * $scriptfilepath update &" &
	else
		logger -t "【koolproxy】" "规则自动更新关闭状态，不启用自动更新..."
	fi
}

arNslookup() {
mkdir -p /tmp/arNslookup
nslookup $1 | tail -n +3 | grep "Address" | awk '{print $3}'| grep -v ":" > /tmp/arNslookup/$$ &
I=5
while [ ! -s /tmp/arNslookup/$$ ] ; do
		I=$(($I - 1))
		[ $I -lt 0 ] && break
		sleep 1
done
if [ -s /tmp/arNslookup/$$ ] ; then
cat /tmp/arNslookup/$$ | sort -u | grep -v "^$"
rm -f /tmp/arNslookup/$$
else
	curltest=`which curl`
	if [ -z "$curltest" ] || [ ! -s "`which curl`" ] ; then
		Address=`wget --continue --no-check-certificate --quiet --output-document=- http://119.29.29.29/d?dn=$1`
		if [ $? -eq 0 ]; then
		echo $Address |  sed s/\;/"\n"/g
		fi
	else
		Address=`curl -k http://119.29.29.29/d?dn=$1`
		if [ $? -eq 0 ]; then
		echo $Address |  sed s/\;/"\n"/g
		fi
	fi
fi
}

initopt () {
optPath=`grep ' /opt ' /proc/mounts | grep tmpfs`
[ ! -z "$optPath" ] && return
if [ -s "/opt/etc/init.d/rc.func" ] ; then
	cp -Hf "$scriptfilepath" "/opt/etc/init.d/$scriptname"
fi

}

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
	koolproxy_check
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
update)
	#exit 0
	[ "$koolproxy_enable" != "1" ] && exit 0
	killall sh_ad_kp_keey_k.sh
	killall -9 sh_ad_kp_keey_k.sh
	hash daydayup 2>/dev/null && { 
	update_kp_rules_daydayup
	[ $? != 0 ] && nvram set koolproxy_status=00 && eval "$scriptfilepath start &" && exit 0
	}
	hash daydayup 2>/dev/null || { 
	while read line
	do
	c_line=`echo $line |grep -v "#"`
	if [ ! -z "$c_line" ] ; then
		file_name=${line##*/}
		wgetcurl.sh /tmp/7620koolproxy/rule_tmp/$file_name $line
		if [ -f /tmp/7620koolproxy/rule_tmp/$file_name ] ; then
			MD5_TMP=`md5sum /tmp/7620koolproxy/rule_tmp/$file_name  | awk '{print $1}'`
			MD5_ORI=`md5sum /tmp/7620koolproxy/rule_store/$file_name| awk '{print $1}'`
			if [ ! -f /tmp/7620koolproxy/rule_store/$file_name ] || [ "$MD5_TMP"x != "$MD5_ORI"x ] ; then
			logger -t "【koolproxy】" "更新检查:有更新 $urla , 重启进程"
			nvram set koolproxy_status=00 && { eval "$scriptfilepath start &"; exit 0; }
			fi
		fi
	fi
	done < /tmp/7620koolproxy/data/rules/koolproxy_rules_list.sh
	logger -t "【koolproxy】" "更新检查:不需更新 $urla "
	}
	[ -f /tmp/sh_ad_kp_keey_k.sh ] && /tmp/sh_ad_kp_keey_k.sh &
	;;
update_ad)
	koolproxy_mount
	koolproxy_close
	rm -rf /tmp/7620koolproxy/*
	nvram set koolproxy_status=00 && { eval "$scriptfilepath start &"; exit 0; }
	;;
*)
	koolproxy_check
	;;
esac

