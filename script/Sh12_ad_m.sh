#!/bin/sh
#copyright by hiboy
source /etc/storage/script/init.sh
TAG="AD_BYBY"		  # iptables tag
adm_enable=`nvram get adm_enable`
[ -z $adm_enable ] && adm_enable=0 && nvram set adm_enable=0
if [ "$adm_enable" != "0" ] ; then
#nvramshow=`nvram showall | grep '=' | grep ss | awk '{print gensub(/'"'"'/,"'"'"'\"'"'"'\"'"'"'","g",$0);}'| awk '{print gensub(/=/,"='\''",1,$0)"'\'';";}'` && eval $nvramshow
#nvramshow=`nvram showall | grep '=' | grep adbyby | awk '{print gensub(/'"'"'/,"'"'"'\"'"'"'\"'"'"'","g",$0);}'| awk '{print gensub(/=/,"='\''",1,$0)"'\'';";}'` && eval $nvramshow
#nvramshow=`nvram showall | grep '=' | grep koolproxy | awk '{print gensub(/'"'"'/,"'"'"'\"'"'"'\"'"'"'","g",$0);}'| awk '{print gensub(/=/,"='\''",1,$0)"'\'';";}'` && eval $nvramshow
#nvramshow=`nvram showall | grep '=' | grep adm | awk '{print gensub(/'"'"'/,"'"'"'\"'"'"'\"'"'"'","g",$0);}'| awk '{print gensub(/=/,"='\''",1,$0)"'\'';";}'` && eval $nvramshow
adbyby_mode_x=`nvram get adbyby_mode_x`
[ -z $adbyby_mode_x ] && adbyby_mode_x=0 && nvram set adbyby_mode_x=0
ss_link_1=`nvram get ss_link_1`
adm_update=`nvram get adm_update`
adm_update_hour=`nvram get adm_update_hour`
adm_update_min=`nvram get adm_update_min`
lan_ipaddr=`nvram get lan_ipaddr`
adm_https=`nvram get adm_https`
adm_hookport=`nvram get adm_hookport`
adbyby_CPUAverages=`nvram get adbyby_CPUAverages`
ss_DNS_Redirect=`nvram get ss_DNS_Redirect`
ss_DNS_Redirect_IP=`nvram get ss_DNS_Redirect_IP`
koolproxy_enable=`nvram get koolproxy_enable`
adbyby_enable=`nvram get adbyby_enable`
ss_enable=`nvram get ss_enable`
ss_mode_x=`nvram get ss_mode_x`
adbyby_adblocks=`nvram get adbyby_adblocks`

adbmfile="$hiboyfile/7620adm.tgz"
adbmfile2="$hiboyfile2/7620adm.tgz"

FWI="/tmp/firewall.adbyby.pdcn" # firewall include file
AD_LAN_AC_IP=`nvram get AD_LAN_AC_IP`
[ -z $AD_LAN_AC_IP ] && AD_LAN_AC_IP=0 && nvram set AD_LAN_AC_IP=$AD_LAN_AC_IP
lan_ipaddr=`nvram get lan_ipaddr`
[ -z "$ss_DNS_Redirect_IP" ] && ss_DNS_Redirect_IP=$lan_ipaddr && nvram set ss_DNS_Redirect_IP=$ss_DNS_Redirect_IP
[ -z $adbyby_adblocks ] && adbyby_adblocks=0 && nvram set adbyby_adblocks=$adbyby_adblocks

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

if [ ! -z "$(echo $scriptfilepath | grep -v "/tmp/script/" | grep ad_m)" ]  && [ ! -s /tmp/script/_ad_m ]; then
	mkdir -p /tmp/script
	{ echo '#!/bin/sh' ; echo $scriptfilepath '"$@"' '&' ; } > /tmp/script/_ad_m
	chmod 777 /tmp/script/_ad_m
fi

adm_mount () {

ss_opt_x=`nvram get ss_opt_x`
upanPath=""
[ "$ss_opt_x" = "3" ] && upanPath="`df -m | grep /dev/mmcb | grep "/media" | awk '{print $NF}' | sort -u | awk 'NR==1' `"
[ "$ss_opt_x" = "4" ] && upanPath="`df -m | grep "/dev/sd" | grep "/media" | awk '{print $NF}' | sort -u | awk 'NR==1' `"
[ -z "$upanPath" ] && [ "$ss_opt_x" = "1" ] && upanPath="`df -m | grep /dev/mmcb | grep "/media" | awk '{print $NF}' | sort -u | awk 'NR==1' `"
[ -z "$upanPath" ] && [ "$ss_opt_x" = "1" ] && upanPath="`df -m | grep "/dev/sd" | grep "/media" | awk '{print $NF}' | sort -u | awk 'NR==1' `"
if [ "$ss_opt_x" = "5" ] ; then
	# 指定目录
	opt_cifs_dir=`nvram get opt_cifs_dir`
	if [ -d $opt_cifs_dir ] ; then
		upanPath="$opt_cifs_dir"
	else
		logger -t "【opt】" "错误！未找到指定目录 $opt_cifs_dir"
		upanPath=""
		[ -z "$upanPath" ] && upanPath="`df -m | grep /dev/mmcb | grep "/media" | awk '{print $NF}' | sort -u | awk 'NR==1' `"
		[ -z "$upanPath" ] && upanPath="`df -m | grep "/dev/sd" | grep "/media" | awk '{print $NF}' | sort -u | awk 'NR==1' `"
	fi
fi
echo "$upanPath"
if [ ! -z "$upanPath" ] ; then 
	logger -t "【ADM】" "已挂载储存设备, 主程序放外置设备存储"
	initopt
	mkdir -p $upanPath/ad/7620adm
	rm -f /tmp/7620adm
	ln -sf "$upanPath/ad/7620adm" /tmp/7620adm
	if [ ! -s "$upanPath/ad/7620adm/adm" ] ; then
		logger -t "【ADM】" "开始下载 7620adm.tgz"
		wgetcurl.sh $upanPath/ad/7620adm.tgz $adbmfile $adbmfile2
		untar.sh $upanPath/ad/7620adm.tgz $upanPath/ad $upanPath/ad/7620adm/adm
	fi
	if [ ! -s "$upanPath/ad/7620adm/adm" ] ; then
		logger -t "【ADM】" "开始下载 7620adm.tgz"
		wgetcurl.sh $upanPath/ad/7620adm.tgz "http://admup2.admflt.com/cross_platform/2_6/7620a.tar.gz" "http://admup2.admflt.com/cross_platform/2_6/7620a.tar.gz" N
		untar.sh $upanPath/ad/7620adm.tgz $upanPath/ad $upanPath/ad/7620a/adm
		if [ -d "$upanPath/ad/7620a" ] ; then
			mkdir -p $upanPath/ad/7620adm
			cp -r -f -a $upanPath/ad/7620a/* $upanPath/ad/7620adm
			rm -rf $upanPath/ad/7620a
		fi
	fi
else
	logger -t "【ADM】" "未挂载储存设备, 主程序放路由内存存储"
	mkdir -p /tmp/7620adm
	if [ ! -s "/tmp/7620adm/adm" ] ; then
		logger -t "【ADM】" "开始下载 7620adm.tgz"
		wgetcurl.sh /tmp/7620adm.tgz $adbmfile $adbmfile2
		untar.sh /tmp/7620adm.tgz /tmp /tmp/7620adm/adm
	fi
	if [ ! -s "/tmp/7620adm/adm" ] ; then
		logger -t "【ADM】" "开始下载 7620adm.tgz"
		wgetcurl.sh /tmp/7620adm.tgz "http://admup2.admflt.com/cross_platform/2_6/7620a.tar.gz" "http://admup2.admflt.com/cross_platform/2_6/7620a.tar.gz" N
		untar.sh /tmp/7620adm.tgz /tmp /tmp/7620a/adm
		if [ -d "/tmp/7620a" ] ; then
			mkdir -p $upanPath/ad/7620adm
			cp -r -f -a /tmp/7620a/* /tmp/7620adm
			rm -rf /tmp/7620a/
		fi
	fi
fi
export PATH='/tmp/7620adm:/etc/storage/bin:/tmp/script:/etc/storage/script:/opt/usr/sbin:/opt/usr/bin:/opt/sbin:/opt/bin:/usr/local/sbin:/usr/sbin:/usr/bin:/sbin:/bin'
chmod 777 /tmp/7620adm/adm
[[ "$(ldd /tmp/7620adm/adm | wc -l)" -lt 2 ]] && rm -rf /tmp/7620adm/*
if [ ! -s "/tmp/7620adm/adm" ] ; then
	rm -rf /tmp/7620adm/*
	logger -t "【ADM】" "下载失败, 注意检查端口是否有冲突,程序是否下载完整,10 秒后自动尝试重新启动" && sleep 10 && adm_restart x
fi
}

adm_restart () {

relock="/var/lock/adm_restart.lock"
if [ "$1" = "o" ] ; then
	nvram set adm_renum="0"
	[ -f $relock ] && rm -f $relock
	return 0
fi
if [ "$1" = "x" ] ; then
	rm -rf /tmp/7620adm/*
	if [ -f $relock ] ; then
		logger -t "【adm】" "多次尝试启动失败，等待【"`cat $relock`"分钟】后自动尝试重新启动"
		exit 0
	fi
	adm_renum=${adm_renum:-"0"}
	adm_renum=`expr $adm_renum + 1`
	nvram set adm_renum="$adm_renum"
	if [ "$adm_renum" -gt "2" ] ; then
		I=19
		echo $I > $relock
		logger -t "【adm】" "多次尝试启动失败，等待【"`cat $relock`"分钟】后自动尝试重新启动"
		while [ $I -gt 0 ]; do
			I=$(($I - 1))
			echo $I > $relock
			sleep 60
			[ "$(nvram get adm_renum)" = "0" ] && exit 0
			[ $I -lt 0 ] && break
		done
		nvram set adm_renum="0"
	fi
	[ -f $relock ] && rm -f $relock
fi
nvram set adm_status=0
eval "$scriptfilepath &"
exit 0
}

adm_get_status () {

A_restart=`nvram get adm_status`
B_restart="$adm_enable$ss_link_1$adm_update$adm_update_hour$adm_update_min$adbmfile$adbmfile2$lan_ipaddr$adm_https$adbyby_mode_x$adm_hookport$adbyby_CPUAverages$ss_DNS_Redirect$ss_DNS_Redirect_IP$(cat /etc/storage/ad_config_script.sh | grep -v "^$" | grep -v "^#")$(cat /etc/storage/adm_rules_script.sh | grep -v "^$" | grep -v "^!")"
B_restart=`echo -n "$B_restart" | md5sum | sed s/[[:space:]]//g | sed s/-//g`
if [ "$A_restart" != "$B_restart" ] ; then
	nvram set adm_status=$B_restart
	needed_restart=1
else
	needed_restart=0
fi
}

adm_check () {

adm_get_status
if [ "$adm_enable" != "1" ] && [ "$needed_restart" = "1" ] ; then
	[ ! -z "`pidof adm`" ] && logger -t "【ADM】" "停止 adm" && adm_close
	{ kill_ps "$scriptname" exit0; exit 0; }
fi
if [ "$adm_enable" = "1" ] ; then
	if [ "$needed_restart" = "1" ] ; then
		adm_close
		adm_start
	else
		[ -z "`pidof adm`" ] || [ ! -s "/tmp/7620adm/adm" ] && adm_restart
		PIDS=$(ps -w | grep "/tmp/7620adm/adm" | grep -v "grep" | wc -l)
		if [ "$PIDS" != 0 ] ; then
			port=$(iptables -t nat -L | grep 'ports 18309' | wc -l)
			if [ "$port" = 0 ] ; then
				logger -t "【ADM】" "检查:找不到18309转发规则, 重新添加"
				adm_add_rules
			fi
		fi
	fi
fi
}

adm_keep () {

cat > "/tmp/sh_ad_m_keey_k.sh" <<-ADMK
#!/bin/sh
source /etc/storage/script/init.sh
sleep 919
adm_enable=\`nvram get adm_enable\`
if [ ! -f /tmp/cron_adb.lock ] && [ "\$adm_enable" = "1" ] ; then
kill_ps "$scriptname"
eval "$scriptfilepath keep &"
exit 0
fi
ADMK
chmod 777 "/tmp/sh_ad_m_keey_k.sh"
killall sh_ad_m_keey_k.sh
killall -9 sh_ad_m_keey_k.sh
/tmp/sh_ad_m_keey_k.sh &

rm -f /tmp/cron_adb.lock
reb="1"
[ -z $ss_link_1 ] && ss_link_1="www.163.com" && nvram set ss_link_1="www.163.com"
[ -z $ss_link_2 ] && ss_link_2="www.google.com.hk" && nvram set ss_link_2="www.google.com.hk"
[ $ss_link_1 == "email.163.com" ] && ss_link_1="www.163.com" && nvram set ss_link_1="www.163.com"
while true; do
adm_enable=`nvram get adm_enable`
[ "$adm_enable" != "1" ] && exit
[ ! -s "/tmp/7620adm/adm" ] && logger -t "【ADM】" "重新启动" && adm_restart
if [ ! -f /tmp/cron_adb.lock ] ; then
	if [ "$reb" -gt 5 ] && [ "$(cat /tmp/reb.lock)x" == "1x" ] ; then
		LOGTIME=$(date "+%Y-%m-%d %H:%M:%S")
		echo '['$LOGTIME'] 网络连接中断['$reb']，reboot.' >> /opt/log.txt 2>&1
		sleep 5
		reboot
	fi
	check=0
	hash check_network 2>/dev/null && check=1
	if [ "$check" == "1" ] ; then
		check_network 3
		[ "$?" == "0" ] && check=200 || { check=404;  sleep 1; }
		if [ "$check" == "404" ] ; then
			check_network 3
			[ "$?" == "0" ] && check=200 || check=404
		fi
	fi
	hash check_network 2>/dev/null || check=404
	if [ "$check" == "404" ] ; then
		curltest=`which curl`
		if [ -z "$curltest" ] || [ ! -s "`which curl`" ] ; then
			wget --no-check-certificate -q -T 10 "$ss_link_1" -O /dev/null
			[ "$?" == "0" ] && check=200 || { check=404;  sleep 1; }
			if [ "$check" == "404" ] ; then
				wget --no-check-certificate -q -T 10 "$ss_link_1" -O /dev/null
				[ "$?" == "0" ] && check=200 || check=404
			fi
		else
			check=`curl -k -s -w "%{http_code}" "$ss_link_1" -o /dev/null`
			[ "$check" != "200" ] &&  sleep 1
			[ "$check" != "200" ] && check=`curl -k -s -w "%{http_code}" "$ss_link_1" -o /dev/null`
		fi
	fi
	if [ "$check" == "200" ] && [ ! -f /tmp/cron_adb.lock ] ; then
		reb=1
		PIDS=$(ps -w | grep "/tmp/7620adm/adm" | grep -v "grep" | wc -l)
		if [ "$PIDS" = 0 ] ; then 
			logger -t "【ADM】" "网络连接正常"
			logger -t "【ADM】" "找不到进程, 重启 adm"
			adm_flush_rules
			killall -15 adm
			killall -9 adm
			sleep 3
			/tmp/7620adm/adm &
			sleep 20
			reb=`expr $reb + 1`
		fi
		if [ "$PIDS" -gt 2 ] ; then 
			logger -t "【ADM】" "进程重复, 重启 adm"
			adm_flush_rules
			killall -15 adm
			killall -9 adm
			sleep 3
			/tmp/7620adm/adm &
			sleep 20
		fi
		port=$(iptables -t nat -L | grep 'ports 18309' | wc -l)
			if [ "$port" -gt 1 ] && [ ! -f /tmp/cron_adb.lock ] ; then
				logger -t "【ADM】" "有多个18309转发规则, 删除多余"
				adm_flush_rules
			fi
		port=$(iptables -t nat -L | grep 'ports 18309' | wc -l)
			if [ "$port" = 0 ] && [ ! -f /tmp/cron_adb.lock ] ; then
				logger -t "【ADM】" "找不到18309转发规则, 重新添加"
				adm_add_rules
			fi
		port=$(iptables -t nat -L | grep 'AD_BYBY_to' | wc -l)
			if [ "$port" = 0 ] && [ ! -f /tmp/cron_adb.lock ] ; then
				logger -t "【ADM】" "找不到AD_BYBY_to转发规则, 重新添加"
				adm_add_rules
			fi
	else
		# logger -t "【ADM】" "网络连接中断 $reb, 关闭 adm"
		port=$(iptables -t nat -L | grep 'ports 18309' | wc -l)
		while [[ "$port" != 0 ]] 
		do
			logger -t "【ADM】" "网络连接中断 $reb, 关闭 adm"
			adm_flush_rules
			port=$(iptables -t nat -L | grep 'ports 18309' | wc -l)
			sleep 5
		done
		PIDS=$(ps -w | grep "/tmp/7620adm/adm" | grep -v "grep" | wc -l)
		if [ "$PIDS" != 0 ] ; then 
			killall -15 adm
			killall -9 adm
		fi
		reb=`expr $reb + 1`
	fi
	/etc/storage/ez_buttons_script.sh 3 & #更新按钮状态
	sleep 212
fi
sleep 22
adm_keepcpu
done
}

adm_keepcpu () {
if [ "$adbyby_CPUAverages" = "1" ] && [ ! -f /tmp/cron_adb.lock ] ; then
	processor=`cat /proc/cpuinfo| grep "processor"| wc -l`
	[ "$processor" = "1" ] && processor=`expr $processor \* 2`
	CPULoad=`uptime |sed -e 's/\ *//g' -e 's/.*://g' | awk -F ',' '{print $2;}' | sed -e 's/\..*//g'`
	if [ $((CPULoad)) -ge "$processor" ] ; then
		logger -t "【ADM】" "CPU 负载拥堵, 关闭 adm"
		adm_flush_rules
		/etc/storage/ez_buttons_script.sh 3 & #更新按钮状态
		killall -15 adm
		killall -9 adm
		touch /tmp/cron_adb.lock
		while [[ "$CPULoad" -gt "$processor" ]] 
		do
			sleep 62
			CPULoad=`uptime |sed -e 's/\ *//g' -e 's/.*://g' | awk -F ',' '{print $2;}' | sed -e 's/\..*//g'`
		done
		logger -t "【ADM】" "CPU 负载正常"
		rm -f /tmp/cron_adb.lock
	fi
fi
}

adm_close () {

cru.sh d adbyby_update &
cru.sh d adm_update &
cru.sh d koolproxy_update &
port=$(iptables -t nat -L | grep 'ports 18309' | wc -l)
[ "$port" != 0 ] && adm_flush_rules
[ "$adbyby_enable" != "1" ] && killall -15 adbyby sh_ad_byby_keey_k.sh
[ "$adbyby_enable" != "1" ] && killall -9 adbyby sh_ad_byby_keey_k.sh
killall -15 adm sh_ad_m_keey_k.sh
killall -9 adm sh_ad_m_keey_k.sh
[ "$koolproxy_enable" != "1" ] && killall -15 koolproxy sh_ad_kp_keey_k.sh
[ "$koolproxy_enable" != "1" ] && killall -9 koolproxy sh_ad_kp_keey_k.sh
rm -f /tmp/adbyby_host.conf
rm -f /tmp/7620adm.tgz /tmp/cron_adb.lock /tmp/sh_ad_m_keey_k.sh /tmp/cp_rules.lock
kill_ps "/tmp/script/_ad_m"
kill_ps "_ad_m.sh"
kill_ps "$scriptname"
}

adm_start () {
nvram set button_script_1_s="ADM"
/etc/storage/ez_buttons_script.sh 3 & #更新按钮状态
if [ -z "`pidof adm`" ] && [ "$adm_enable" = "1" ] && [ ! -f /tmp/cron_adb.lock ] ; then
	touch /tmp/cron_adb.lock
	for module in ip_set ip_set_bitmap_ip ip_set_bitmap_ipmac ip_set_bitmap_port ip_set_hash_ip ip_set_hash_ipport ip_set_hash_ipportip ip_set_hash_ipportnet ip_set_hash_net ip_set_hash_netport ip_set_list_set xt_set xt_TPROXY
	do
		modprobe $module
	done 
	adm_mount
	# 恢复上次保存的证书
	#if [ "$adm_https" = "0" ] ; then
	#	sed -e "s|^\(support_ssl.*\)=[^=]*$|\1=0|" -i /tmp/7620adm/ADMConfig.ini
	#fi
	#if [ "$adm_https" = "1" ] ; then
		mkdir -p /etc/storage/adm
		sed -e "s|^\(support_ssl.*\)=[^=]*$|\1=1|" -i /tmp/7620adm/ADMConfig.ini
		[ -f /etc/storage/adm/adm_ca.crt ] && cp -f /etc/storage/adm/adm_ca.crt /tmp/7620adm/adm_ca.crt
		[ -f /etc/storage/adm/adm_ca_key.pem ] && cp -f /etc/storage/adm/adm_ca_key.pem /tmp/7620adm/adm_ca_key.pem
	#fi
	logger -t "【ADM】" "adm证书位于/etc/storage/adm/"
	# 
	
	# 处理第三方自定义规则 /tmp/rule_DOMAIN.txt
	/etc/storage/ad_config_script.sh
	adbyby_adblocks=`nvram get adbyby_adblocks`
	rm -f /tmp/7620adm/user.bin
	rm -f /tmp/7620adm/user.txt
	if [ "$adbyby_adblocks" = "1" ] ; then
		mkdir -p /tmp/7620adm/
		logger -t "【ADM】" "下载 第三方自定义 规则"
		rm -f /tmp/7620adm/user3adblocks.txt
		while read line
		do
		c_line=`echo $line |grep -v "#"`
		if [ ! -z "$c_line" ] ; then
			logger -t "【ADM】" "下载规则:$line"
			wgetcurl.sh /tmp/7620adm/user2.txt $line $line N
			grep -v '^!' /tmp/7620adm/user2.txt | grep -E '^(@@\||\||[[:alnum:]])' | sort -u | grep -v "^$" >> /tmp/7620adm/user3adblocks.txt
			rm -f /tmp/7620adm/user2.txt
		fi
		done < /tmp/rule_DOMAIN.txt
	fi
	# 合并规则
	cat /etc/storage/adm_rules_script.sh | grep -v '^!' | grep -v "^$" > /tmp/7620adm/user.txt
	grep -v '^!' /tmp/7620adm/user3adblocks.txt | grep -v "^$" >> /tmp/7620adm/user.txt
	logger -t "【ADM】" "启动 adm 程序"
	cd /tmp/7620adm
	export PATH='/tmp/7620adm:/etc/storage/bin:/tmp/script:/etc/storage/script:/opt/usr/sbin:/opt/usr/bin:/opt/sbin:/opt/bin:/usr/local/sbin:/usr/sbin:/usr/bin:/sbin:/bin'
	export LD_LIBRARY_PATH=/tmp/7620adm/lib:/lib:/opt/lib
	/tmp/7620adm/adm &
	if [ "$adbyby_adblocks" = "1" ] ; then
		logger -t "【ADM】" "加载 第三方自定义 规则, 等候15秒"
		sleep 15
	else
		sleep 10
	fi
	# 保存证书
	#if [ "$adm_https" = "1" ] ; then
		[ ! -f /etc/storage/adm/adm_ca.crt ] && [ -f /tmp/7620adm/adm_ca.crt ] && cp /tmp/7620adm/adm_ca.crt /etc/storage/adm/adm_ca.crt
		[ ! -f /etc/storage/adm/adm_ca_key.pem ] && [ -f /tmp/7620adm/adm_ca_key.pem ] && cp /tmp/7620adm/adm_ca_key.pem /etc/storage/adm/adm_ca_key.pem && mtd_storage.sh save &
	#fi
fi
[ ! -z "`pidof adm`" ] && logger -t "【ADM】" "启动成功" && adm_restart o
[ -z "`pidof adm`" ] && logger -t "【ADM】" "启动失败, 注意检查端口是否有冲突,程序是否下载完整,10 秒后自动尝试重新启动" && sleep 10 && adm_restart x
adm_add_rules
rm -f /tmp/7620adm.tgz /tmp/cron_adb.lock
/etc/storage/ez_buttons_script.sh 3 & #更新按钮状态
logger -t "【ADM】" "守护进程启动"
adm_cron_job
#adm_get_status
eval "$scriptfilepath keep &"
}

flush_r () {
iptables -t nat -D PREROUTING -p tcp --dport 80 -j REDIRECT --to-ports 18309 > /dev/null
iptables-save -c | sed  "s/webstr--url/webstr --url/g" | grep -v "$TAG" | iptables-restore -c
for setname in $(ipset -n list | grep -i "ad_spec"); do
	ipset destroy $setname 2>/dev/null
done
[ -n "$FWI" ] && echo '#!/bin/sh' >$FWI
}

adm_cp_rules () {
rm -f /tmp/b/*
I=30
while [ -f /tmp/cp_rules.lock ]; do
		I=$(($I - 1))
		[ $I -lt 0 ] && break
		sleep 1
done
touch /tmp/cp_rules.lock
[ ! -f /tmp/adbyby_host.conf ] && [ -f /tmp/7620adm/adm_ipset.txt ] && cp -f /tmp/7620adm/adm_ipset.txt /tmp/adbyby_host.conf
# 去除gfw donmain中与 adbyby host 包含的域名，这部分域名交由adbyby处理。
# 参考的awk指令写法
#  awk  'NR==FNR{a[$0]}NR>FNR{ if($1 in a) print $0}' file1 file2 #找出两文件中相同的值
#  awk  'NR==FNR{a[$0]}NR>FNR{ if(!($1 in a)) print $0}' file1 file2 #去除 file2 中file1的内容
#  awk 'NR==FNR{a[$0]++} NR>FNR&&a[$0]' file1 file2 #找出两个文件之间的相同部分
#  awk 'NR==FNR{a[$0]++} NR>FNR&&!a[$0]' file1 file2 #去除 file2 中file1的内容
if [ "$adbyby_mode_x" == 1 ] && [ -s /tmp/adbyby_host.conf ] ; then
logger -t "【iptables】" "添加 ipset 转发规则"
sed -Ei '/adbyby_host.conf|cflist.conf/d' /etc/storage/dnsmasq/dnsmasq.conf
sed  "s/\/adm_list/\/adbybylist/" -i  /tmp/adbyby_host.conf
[ ! -z $whitehost ] && sed -Ei "/$(echo $whitehost | tr , \|)/d" /tmp/adbyby_host.conf
[ -f "$confdir$gfwlist" ] && gfw_black=$(grep "/$gfw_black_list" "$confdir$gfwlist" | sed 's/.*\=//g')
if [ -s "$confdir$gfwlist" ] && [ -s /tmp/adbyby_host.conf ] && [ ! -z "$gfw_black" ] ; then
	logger -t "【iptables】" "admlist 规则处理开始"
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
ipset add adbybylist 188.188.188.188
if [ -f /tmp/7620adm/adm_blockip.txt ] ; then
	grep -v '^#' /tmp/7620adm/adm_blockip.txt | sort -u | grep -v "^$" | sed -e "s/^/-A adbybylist &/g" | ipset -R -!
fi
restart_dhcpd
logger -t "【iptables】" "admlist 规则处理完毕"
rm -f /tmp/b/*
fi
rm -f /tmp/cp_rules.lock
}

adm_flush_rules () {
logger -t "【iptables】" "删除18309转发规则"
flush_r
ipset -F adbybylist &> /dev/null
ipset destroy adbybylist &> /dev/null
#ipset -F cflist &> /dev/null
sed -Ei '/adbyby_host.conf/d' /etc/storage/dnsmasq/dnsmasq.conf
restart_dhcpd
logger -t "【iptables】" "完成删除18309规则"
}

adm_add_rules() {
logger -t "【iptables】" "添加18309转发规则"
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
ipset add adbybylist 188.188.188.188
/etc/storage/ad_config_script.sh
# 内网(LAN)访问控制
logger -t "【ADM】" "设置内网(LAN)访问控制"
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
	if [ -f /tmp/7620adm/adm_hookport.txt ] && [ "$adm_hookport" == 1 ] ; then
		hookport443='|'
		sed -e "s/443$hookport443//" -i /tmp/7620adm/adm_hookport.txt
		i=1 && hookport1="" && hookport2="" && hookport3="" && hookport4="" && hookport5=""
		for hookport in $(cat /tmp/7620adm/adm_hookport.txt | sed s/\|/\ /g)
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
		[ "$adm_https" != "1" ] && iptables -t nat -I PREROUTING $wifidognx -p tcp -m set --match-set ad_spec_src_https src --dport 443 -j AD_BYBY
		[ "$adm_https" = "1" ] && iptables -t nat -I PREROUTING $wifidognx -p tcp --dport 443 -j AD_BYBY
	else
		[ "$adm_https" = "1" ] && iptables -t nat -I PREROUTING $wifidognx -p tcp -m multiport --dports 80,443,8080 -j AD_BYBY
		[ "$adm_https" != "1" ] && iptables -t nat -I PREROUTING $wifidognx -p tcp -m multiport --dports 80,8080 -j AD_BYBY
	fi
	iptables -t nat -A AD_BYBY_to -p tcp -j REDIRECT --to-port 18309
	dns_redirect
	sleep 1
	gen_include &
	logger -t "【iptables】" "完成添加18309规则"
	[ "$adbyby_mode_x" == 1 ] && adm_cp_rules
}


gen_special_purpose_ip () {
#处理肯定不走通道的目标网段
lan_ipaddr=`nvram get lan_ipaddr`
kcptun_enable=`nvram get kcptun_enable`
[ -z $kcptun_enable ] && kcptun_enable=0 && nvram set kcptun_enable=$kcptun_enable
kcptun_server=`nvram get kcptun_server`
if [ "$kcptun_enable" != "0" ] ; then
resolveip=`/usr/bin/resolveip -4 -t 4 $kcptun_server | grep -v : | sed -n '1p'`
[ -z "$resolveip" ] && resolveip=`arNslookup $kcptun_server | sed -n '1p'` 
kcptun_server=$resolveip
fi

[ "$kcptun_enable" = "0" ] && kcptun_server=""
ss_enable=`nvram get ss_enable`
[ -z $ss_enable ] && ss_enable=0 && nvram set ss_enable=$ss_enable
[ "$ss_enable" = "0" ] && ss_s1_ip="" && ss_s2_ip=""
nvram set ss_server1=`nvram get ss_server`
ss_server1=`nvram get ss_server1`
ss_server2=`nvram get ss_server2`
kcptun2_enable=`nvram get kcptun2_enable`
[ -z $kcptun2_enable ] && kcptun2_enable=0 && nvram set kcptun2_enable=$kcptun2_enable
kcptun2_enable2=`nvram get kcptun2_enable2`
[ -z $kcptun2_enable2 ] && kcptun2_enable2=0 && nvram set kcptun2_enable2=$kcptun2_enable2
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
213.183.51.102
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
		logger -t "【ADM】" "udp53端口（DNS）地址重定向为 $ss_DNS_Redirect_IP 强制使用重定向地址的DNS"
		iptables -t nat -A PREROUTING -s $lan_ipaddr/24 -p udp --dport 53 -j AD_BYBY_DNS_LAN_DG
		iptables -t nat -A AD_BYBY_DNS_WAN_FW -j DNAT --to $ss_DNS_Redirect_IP
	fi

}

adm_cron_job(){
	[ -z $adm_update ] && adm_update=0 && nvram set adm_update=$adm_update
	[ -z $adm_update_hour ] && adm_update_hour=23 && nvram set adm_update_hour=$adm_update_hour
	[ -z $adm_update_min ] && adm_update_min=59 && nvram set adm_update_min=$adm_update_min
	if [ "0" == "$adm_update" ]; then
	[ $adm_update_hour -gt 23 ] && adm_update_hour=23 && nvram set adm_update_hour=$adm_update_hour
	[ $adm_update_hour -lt 0 ] && adm_update_hour=0 && nvram set adm_update_hour=$adm_update_hour
	[ $adm_update_min -gt 59 ] && adm_update_min=59 && nvram set adm_update_min=$adm_update_min
	[ $adm_update_min -lt 0 ] && adm_update_min=0 && nvram set adm_update_min=$adm_update_min
		logger -t "【adm】" "开启规则定时更新，每天"$adm_update_hour"时"$adm_update_min"分，检查在线规则更新..."
		cru.sh a adm_update "$adm_update_min $adm_update_hour * * * $scriptfilepath update &" &
	elif [ "1" == "$adm_update" ]; then
	#[ $adm_update_hour -gt 23 ] && adm_update_hour=23 && nvram set adm_update_hour=$adm_update_hour
	[ $adm_update_hour -lt 0 ] && adm_update_hour=0 && nvram set adm_update_hour=$adm_update_hour
	[ $adm_update_min -gt 59 ] && adm_update_min=59 && nvram set adm_update_min=$adm_update_min
	[ $adm_update_min -lt 0 ] && adm_update_min=0 && nvram set adm_update_min=$adm_update_min
		logger -t "【adm】" "开启规则定时更新，每隔"$adm_update_inter_hour"时"$adm_update_inter_min"分，检查在线规则更新..."
		cru.sh a adm_update "$adm_update_min */$adm_update_hour * * * $scriptfilepath update &" &
	else
		logger -t "【adm】" "规则自动更新关闭状态，不启用自动更新..."
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
		Address="`wget --no-check-certificate --quiet --output-document=- http://119.29.29.29/d?dn=$1`"
		if [ $? -eq 0 ]; then
		echo "$Address" |  sed s/\;/"\n"/g | grep -E -o '([0-9]+\.){3}[0-9]+'
		fi
	else
		Address="`curl -k http://119.29.29.29/d?dn=$1`"
		if [ $? -eq 0 ]; then
		echo "$Address" |  sed s/\;/"\n"/g | grep -E -o '([0-9]+\.){3}[0-9]+'
		fi
	fi
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

adm_rules_script="/etc/storage/adm_rules_script.sh"
if [ ! -f "$adm_rules_script" ] || [ ! -s "$adm_rules_script" ] ; then
	cat > "$adm_rules_script" <<-\EEE
[ADM]
!  ------------------------------ 阿呆喵[ADM] 自定义过滤语法简表---------------------------------
!  --------------  规则语法基于ABP规则，并进行了字符替换部分的扩展-----------------------------
! ADM支持绝大多数ABP规则语法, 
! 所以, 你可以装一个ABP浏览器插件, 然后用它来辅助写规则, 把写好的规则导入ADM自定义规则文件中保存即可正常使用了.

!  ABP规则请参考https://adblockplus.org/zh_CN/filters，下面为大致摘要
!  "!" 为行注释符，注释行以该符号起始作为一行注释语义，用于规则描述
!  "*" 为字符通配符，能够匹配0长度或任意长度的字符串。
!  "^" 为分隔符，可以匹配任何单个字符。
!  "|" 为管线符号，来表示地址的最前端或最末端  比如 "|http://"  或  |http://www.abc.com/a.js|  
!  "||" 为子域通配符，方便匹配主域名下的所有子域。比如 "||www.baidu.com"  就可以不要前面的 "http://"
!  "~" 为排除标识符，通配符能过滤大多数广告，但同时存在误杀, 可以通过排除标识符修正误杀链接。
!  "@@" 网址白名单, 例如不拦截此条地址   @@|http://www.baidu.com/js/u.js   或者 @@||www.baidu.com/js/u.js

! ## #@# ##&  这3种为元素插入语法 (在语句末尾加 $B , 可以选择插入css语句在</body>前, 默认为</head>)
!  "##" 为元素选择器标识符，后面跟需要隐藏元素的CSS样式例如 #ad_id  .ad_class
! "#@#" 元素选择器白名单 
! "##&" 为JQuery选择器标识符，后面跟需要隐藏元素的JQuery筛选语法, 如 ##&div:has(p)
!  元素隐藏支持全局规则   ##.ad_text  不需要前面配置域名,对所有页面有效. 简单有效,但误杀会比较多, 慎用.

! 文本替换规则一般人使用较少, 过滤视频规则一般必须使用之;
!  文本替换选择器标识符, 支持通配符*和？，格式："页面C$s@内容A@内容B@"   意思为 <在使用"某正则模式" 在 "页面C"上用"内容A"替换"内容B" >  ; 
! 文本替换方式1:  S@   使用正则匹配替换
! 文本替换方式2:  s@   使用通配符 ?  *  匹配替换  
!  -------------------------------------------------------------------------------------------

!全局白名单
!如果你有其他不想过滤的论坛或者网站类的, 可以在自定义里面仿造上面的规则写一条
!例如 有些人不想过滤 http://www.baidu.com/
!那么可以在user.txt 自定义中加一条规则  @@|http://$domain=.baidu.com|   保存即可

!新增文本替换规则语法测试样例
!样例1 使用正则删除某地方(替换 "<p...</p>" 字符串为 "http://www.admflt.com")
!<p id="lg"><img src="http://www.baidu.com/img/bdlogo.gif" width="270" height="129"></p>
!||www.baidu.com$S@<p.*<\/p>@http://www.admflt.com@
!||kafan.cn$s@<div id="hd">@<div id="hd" style="display:none!important">@

!ADM https黑名单写法;参考规则文件 https_black.txt
!例如
!B:baidu.com
!B:taobao.com



EEE
	chmod 755 "$adm_rules_script"
fi

}

initconfig

case $ACTION in
start)
	adm_close
	adm_check
	;;
check)
	adm_check
	;;
stop)
	adm_close
	;;
keep)
	#adm_check
	adm_keep
	;;
A)
	adm_add_rules
	;;
D)
	adm_flush_rules
	;;
C)
	adm_cp_rules
	;;
update)
	[ "$adm_enable" != "1" ] && exit 0
	killall sh_ad_m_keey_k.sh
	killall -9 sh_ad_m_keey_k.sh
	checka="/tmp/var/admrule_everyday.txt"
	rm -f /tmp/var/admrule_everyday.txt
	urla="http://update2.admflt.com/ruler/admrule_everyday.txt"
	checkb="/tmp/7620adm/subscribe/admrule_everyday.txt"
	wgetcurl.sh $checka $urla $urla N 5
	if [ "`md5sum $checka|cut -d" " -f1`" != "`md5sum $checkb|cut -d" " -f1`" ] ; then
		logger -t "【ADM】" "更新检查:有更新 $urla , 重启进程"
		adm_restart
	else
		logger -t "【ADM】" "更新检查:不需更新 $urla "
	fi
	[ -s /tmp/sh_ad_m_keey_k.sh ] && /tmp/sh_ad_m_keey_k.sh &
	;;
update_ad)
	adm_mount
	adm_close
	rm -rf /tmp/7620adm/*
	adm_restart o
	adm_restart
	;;
*)
	adm_check
	;;
esac

