#!/bin/sh
#copyright by hiboy
source /etc/storage/script/init.sh
TAG="AD_BYBY"		  # iptables tag
adbyby_enable=`nvram get adbyby_enable`
[ -z $adbyby_enable ] && adbyby_enable=0 && nvram set adbyby_enable=0
if [ "$adbyby_enable" != "0" ] ; then
nvramshow=`nvram showall | grep ss | awk '{print gensub(/'"'"'/,"'"'"'\"'"'"'\"'"'"'","g",$0);}'| awk '{print gensub(/=/,"='\''",1,$0)"'\'';";}'` && eval $nvramshow
nvramshow=`nvram showall | grep adm | awk '{print gensub(/'"'"'/,"'"'"'\"'"'"'\"'"'"'","g",$0);}'| awk '{print gensub(/=/,"='\''",1,$0)"'\'';";}'` && eval $nvramshow
nvramshow=`nvram showall | grep koolproxy | awk '{print gensub(/'"'"'/,"'"'"'\"'"'"'\"'"'"'","g",$0);}'| awk '{print gensub(/=/,"='\''",1,$0)"'\'';";}'` && eval $nvramshow
nvramshow=`nvram showall | grep adbyby | awk '{print gensub(/'"'"'/,"'"'"'\"'"'"'\"'"'"'","g",$0);}'| awk '{print gensub(/=/,"='\''",1,$0)"'\'';";}'` && eval $nvramshow

[ -z $adbyby_mode_x ] && adbyby_mode_x=0 && nvram set adbyby_mode_x=0


adbybyfile="$hiboyfile/7620i.tar.gz"
adbybyfile2="$hiboyfile2/7620i.tar.gz"


FWI="/tmp/firewall.adbyby.pdcn" # firewall include file
AD_LAN_AC_IP=`nvram get AD_LAN_AC_IP`
AD_LAN_AC_IP=${AD_LAN_AC_IP:-"0"}
lan_ipaddr=`nvram get lan_ipaddr`
[ -z "$ss_DNS_Redirect_IP" ] && ss_DNS_Redirect_IP=$lan_ipaddr
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

if [ ! -z "$(echo $scriptfilepath | grep -v "/tmp/script/" | grep ad_byby)" ]  && [ ! -s /tmp/script/_ad_byby ]; then
	mkdir -p /tmp/script
	ln -sf $scriptfilepath /tmp/script/_ad_byby
	chmod 777 /tmp/script/_ad_byby
fi

adbyby_mount () {

ss_opt_x=`nvram get ss_opt_x`
upanPath=""
[ "$ss_opt_x" = "3" ] && upanPath="`df -m | grep /dev/mmcb | grep "/media" | awk '{print $NF}' | awk 'NR==1' `"
[ "$ss_opt_x" = "4" ] && upanPath="`df -m | grep "/dev/sd" | grep "/media" | awk '{print $NF}' | awk 'NR==1' `"
[ -z "$upanPath" ] && [ "$ss_opt_x" = "1" ] && upanPath="`df -m | grep /dev/mmcb | grep "/media" | awk '{print $NF}' | awk 'NR==1' `"
[ -z "$upanPath" ] && [ "$ss_opt_x" = "1" ] && upanPath="`df -m | grep "/dev/sd" | grep "/media" | awk '{print $NF}' | awk 'NR==1' `"
echo "$upanPath"
if [ ! -z "$upanPath" ] ; then 
	logger -t "【Adbyby】" "已挂载储存设备, 主程序放外置设备存储"
	initopt
	mkdir -p $upanPath/ad/bin
	ln -sf "$upanPath/ad/bin" /tmp/bin
	if [ -s /etc_ro/7620i.tar.gz ] && [ ! -s "$$upanPath/ad/bin/adbyby" ] ; then
		logger -t "【Adbyby】" "使用内置主程序"
		untar.sh /etc_ro/7620i.tar.gz $upanPath/ad $upanPath/ad/bin/adbyby
	fi
	if [ ! -s "$upanPath/ad/bin/adbyby" ] ; then
		logger -t "【Adbyby】" "开始下载 7620n.tar.gz"
		wgetcurl.sh $upanPath/ad/7620n.tar.gz $adbybyfile $adbybyfile2
		untar.sh $upanPath/ad/7620n.tar.gz $upanPath/ad $upanPath/ad/bin/adbyby
	fi
	if [ ! -s "$upanPath/ad/bin/adbyby" ] ; then
		logger -t "【Adbyby】" "开始下载http://update.adbyby.com/download/7620n.tar.gz"
		wgetcurl.sh $upanPath/ad/7620n.tar.gz "https://raw.githubusercontent.com/adbyby/Files/master/7620n.tar.gz" 'http://update.adbyby.com/download/7620n.tar.gz'
		untar.sh $upanPath/ad/7620n.tar.gz $upanPath/ad $upanPath/ad/bin/adbyby
	fi
else
	logger -t "【Adbyby】" "未挂载储存设备, 主程序放路由内存存储"
	mkdir -p /tmp/bin
	if [ -s /etc_ro/7620i.tar.gz ] && [ ! -s "/tmp/bin/adbyby" ] ; then
		logger -t "【Adbyby】" "使用内置主程序"
		untar.sh /etc_ro/7620i.tar.gz /tmp /tmp/bin/adbyby
	fi
	if [ ! -s "/tmp/bin/adbyby" ] ; then
		logger -t "【Adbyby】" "开始下载 7620n.tar.gz"
		wgetcurl.sh /tmp/7620n.tar.gz $adbybyfile $adbybyfile2
		untar.sh /tmp/7620n.tar.gz /tmp /tmp/bin/adbyby
	fi
	if [ ! -s "/tmp/bin/adbyby" ] ; then
		logger -t "【Adbyby】" "开始下载http://update.adbyby.com/download/7620n.tar.gz"
		wgetcurl.sh /tmp/7620n.tar.gz "https://raw.githubusercontent.com/adbyby/Files/master/7620n.tar.gz" 'http://update.adbyby.com/download/7620n.tar.gz'
		untar.sh /tmp/7620n.tar.gz /tmp /tmp/bin/adbyby
	fi
fi
export PATH='/tmp/bin:/etc/storage/bin:/tmp/script:/etc/storage/script:/opt/usr/sbin:/opt/usr/bin:/opt/sbin:/opt/bin:/usr/local/sbin:/usr/sbin:/usr/bin:/sbin:/bin'
hash adbyby 2>/dev/null || rm -rf /tmp/bin/*
if [ ! -s "/tmp/bin/adbyby" ] ; then
	rm -rf /tmp/bin/*
	logger -t "【Adbyby】" "下载失败, 注意检查端口是否有冲突,程序是否下载完整,10 秒后自动尝试重新启动" && sleep 10 && { nvram set adbyby_status=00; eval "$scriptfilepath &"; exit 0; }
fi
}

adbyby_check () {

A_restart=`nvram get adbyby_status`
B_restart="$adbyby_enable$ss_link_1$adbyby_update$adbyby_update_hour$adbyby_update_min$adbyby_mode_x$adbybyfile$adbybyfile2$adbyby_adblocks$adbyby_CPUAverages$ss_sub4$adbyby_whitehost_x$whitehost$lan_ipaddr$lan_ipaddr$ss_DNS_Redirect$ss_DNS_Redirect_IP$ss_DNS_Redirect$(cat /etc/storage/ad_config_script.sh | grep -v "^$" | grep -v "^#")$(cat /etc/storage/adbyby_rules_script.sh | grep -v "^$" | grep -v "^!")"
B_restart=`echo -n "$B_restart" | md5sum | sed s/[[:space:]]//g | sed s/-//g`
if [ "$A_restart" != "$B_restart" ] ; then
	nvram set adbyby_status=$B_restart
	needed_restart=1
else
	needed_restart=0
fi
if [ "$adbyby_enable" != "1" ] && [ "$needed_restart" = "1" ] ; then
	[ ! -z "`pidof adbyby`" ] && logger -t "【Adbyby】" "停止 adbyby" && adbyby_close
	{ eval $(ps -w | grep "$scriptname" | grep -v grep | awk '{print "kill "$1";";}'); exit 0; }
fi
if [ "$adbyby_enable" = "1" ] ; then
	if [ "$needed_restart" = "1" ] ; then
		adbyby_close
		adbyby_start
	else
		[ -z "`pidof adbyby`" ] || [ ! -s "/tmp/bin/adbyby" ] && nvram set adbyby_status=00 && { eval "$scriptfilepath start &"; exit 0; }
		PIDS=$(ps -w | grep "/tmp/bin/adbyby" | grep -v "grep" | grep -v "adbybyupdate.sh" | grep -v "adbybyfirst.sh" | wc -l)
		if [ "$PIDS" != 0 ] ; then
			port=$(iptables -t nat -L | grep 'ports 8118' | wc -l)
			if [ "$port" = 0 ] ; then
				logger -t "【Adbyby】" "检查:找不到8118转发规则, 重新添加"
				adbyby_add_rules
			fi
		fi
	fi
fi
}

adbyby_keep () {

adbybylazytime="`sed -n '1,10p' /tmp/bin/data/lazy.txt | grep "$(sed -n '1,10p' /tmp/bin/data/lazy.txt | grep -Eo '[0-9]+-[0-9]+-[0-9]+ [0-9]+:[0-9]+' | sed -n '1p')" | sed 's/[x!]//g' | sed -r 's/-{2,}//g' | sed -r 's/\ {2}//g' | sed -r 's/\ {2}//g' | sed -r 's/[^0-9a-z: \-]//g'`"
adbybyvideotime="`sed -n '1,10p' /tmp/bin/data/video.txt | grep "$(sed -n '1,10p' /tmp/bin/data/video.txt | grep -Eo '[0-9]+-[0-9]+-[0-9]+ [0-9]+:[0-9]+' | sed -n '1p')" | sed 's/[x!]//g' | sed -r 's/-{2,}//g' | sed -r 's/\ {2}//g' | sed -r 's/\ {2}//g' | sed -r 's/[^0-9a-z: \-]//g'`"
adbybylazy_nu="`cat /tmp/bin/data/lazy.txt | grep -v ! | wc -l`"
adbybyvideo_nu="`cat /tmp/bin/data/video.txt | grep -v ! | wc -l`"
nvram set adbybylazy="$ipsetstxt lazy规则更新时间 $adbybylazytime / 【 $adbybylazy_nu 】条"
nvram set adbybyvideo="$ipsetstxt video规则更新时间 $adbybyvideotime / 【 $adbybyvideo_nu 】条"
nvram set adbybyuser3="第三方规则行数:  `sed -n '$=' /tmp/bin/data/user3adblocks.txt | sed s/[[:space:]]//g ` 行"
nvram set adbybyuser="自定义规则行数:  `sed -n '$=' /tmp/bin/data/user_rules.txt | sed s/[[:space:]]//g ` 行"
cat > "/tmp/sh_ad_byby_keey_k.sh" <<-ADMK
#!/bin/sh
sleep 919
adbyby_enable=\`nvram get adbyby_enable\`
if [ ! -f /tmp/cron_adb.lock ] && [ "\$adbyby_enable" = "1" ] ; then
eval \$(ps -w | grep "$scriptname" | grep -v grep | awk '{print "kill "\$1";";}')
eval \$(ps -w | grep "$scriptname keep" | grep -v grep | awk '{print "kill "\$1";";}')
eval "$scriptfilepath keep &"
exit 0
fi
ADMK
chmod 777 "/tmp/sh_ad_byby_keey_k.sh"
killall sh_ad_byby_keey_k.sh
killall -9 sh_ad_byby_keey_k.sh
/tmp/sh_ad_byby_keey_k.sh &

rm -f /tmp/cron_adb.lock
reb="1"
runx="1"
[ -z $ss_link_1 ] && ss_link_1="email.163.com" && nvram set ss_link_1="email.163.com"
[ -z $ss_link_2 ] && ss_link_2="www.google.com.hk" && nvram set ss_link_2="www.google.com.hk"
[ $ss_link_1 == "www.163.com" ] && ss_link_1="email.163.com" && nvram set ss_link_1="email.163.com"
while true; do
[ ! -s "/tmp/bin/adbyby" ] && nvram set adbyby_status=00 && { logger -t "【Adbyby】" "重新启动"; eval "$scriptfilepath start &"; exit 0; }
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
		PIDS=$(ps -w | grep "/tmp/bin/adbyby" | grep -v "grep" | grep -v "adbybyupdate.sh" | grep -v "adbybyfirst.sh" | wc -l)
		if [ "$PIDS" = 0 ] ; then 
			logger -t "【Adbyby】" "网络连接正常"
			logger -t "【Adbyby】" "找不到进程, 重启 adbyby"
			adbyby_flush_rules
			killall -15 adbyby
			killall -9 adbyby
			sleep 3
			/tmp/bin/adbyby >/dev/null 2>&1 &
			sleep 20
			reb=`expr $reb + 1`
		fi
		if [ "$PIDS" -gt 2 ] ; then 
			logger -t "【Adbyby】" "进程重复, 重启 adbyby"
			adbyby_flush_rules
			killall -15 adbyby
			killall -9 adbyby
			sleep 3
			/tmp/bin/adbyby >/dev/null 2>&1 &
			sleep 20
		fi
		port=$(iptables -t nat -L | grep 'ports 8118' | wc -l)
			if [ "$port" -gt 1 ] && [ ! -f /tmp/cron_adb.lock ] ; then
				logger -t "【Adbyby】" "有多个8118转发规则, 删除多余"
				adbyby_flush_rules
			fi
		port=$(iptables -t nat -L | grep 'ports 8118' | wc -l)
			if [ "$port" = 0 ] && [ ! -f /tmp/cron_adb.lock ] ; then
				logger -t "【Adbyby】" "找不到8118转发规则, 重新添加"
				adbyby_add_rules
			fi
		runx=`expr $runx + 1`
	else
		# logger -t "【Adbyby】" "网络连接中断 $reb, 关闭 adbyby"
		port=$(iptables -t nat -L | grep 'ports 8118' | wc -l)
		while [[ "$port" != 0 ]] 
		do
			logger -t "【Adbyby】" "网络连接中断 $reb, 关闭 adbyby"
			adbyby_flush_rules
			port=$(iptables -t nat -L | grep 'ports 8118' | wc -l)
			sleep 5
		done
		PIDS=$(ps -w | grep "/tmp/bin/adbyby" | grep -v "grep" | wc -l)
		if [ "$PIDS" != 0 ] ; then 
			killall -15 adbyby
			killall -9 adbyby
		fi
		reb=`expr $reb + 1`
	fi
	/etc/storage/ez_buttons_script.sh 3 & #更新按钮状态
	sleep 211
fi
sleep 21
adbyby_keepcpu
done
}

adbyby_keepcpu () {
if [ "$adbyby_CPUAverages" = "1" ] && [ ! -f /tmp/cron_adb.lock ] ; then
	processor=`cat /proc/cpuinfo| grep "processor"| wc -l`
	processor=`expr $processor \* 2`
	CPULoad=`uptime |sed -e 's/\ *//g' -e 's/.*://g' | awk -F ',' '{print $2;}' | sed -e 's/\..*//g'`
	if [ $((CPULoad)) -ge "$processor" ] ; then
		logger -t "【Adbyby】" "CPU 负载拥堵, 关闭 adbyby"
		adbyby_flush_rules
		/etc/storage/ez_buttons_script.sh 3 & #更新按钮状态
		killall -15 adbyby
		killall -9 adbyby
		touch /tmp/cron_adb.lock
		while [[ "$CPULoad" -gt "$processor" ]] 
		do
			sleep 62
			CPULoad=`uptime |sed -e 's/\ *//g' -e 's/.*://g' | awk -F ',' '{print $2;}' | sed -e 's/\..*//g'`
		done
		logger -t "【Adbyby】" "CPU 负载正常"
		rm -f /tmp/cron_adb.lock
	fi
fi
}

adbyby_close () {
cru.sh d adbyby_update &
port=$(iptables -t nat -L | grep 'ports 8118' | wc -l)
[ "$port" != 0 ] && adbyby_flush_rules
killall -15 adbyby sh_ad_byby_keey_k.sh
killall -9 adbyby sh_ad_byby_keey_k.sh
[ "$adm_enable" != "1" ] && killall -15 adm sh_ad_m_keey_k.sh
[ "$adm_enable" != "1" ] && killall -9 adm sh_ad_m_keey_k.sh
[ "$koolproxy_enable" != "1" ] && killall -15 koolproxy sh_ad_kp_keey_k.sh
[ "$koolproxy_enable" != "1" ] && killall -9 koolproxy sh_ad_kp_keey_k.sh
rm -f /tmp/7620n.tar.gz /tmp/cron_adb.lock /tmp/adbyby_host_backup.conf /tmp/sh_ad_byby_keey_k.sh
eval $(ps -w | grep "_ad_byby keep" | grep -v grep | awk '{print "kill "$1";";}')
eval $(ps -w | grep "_ad_byby.sh keep" | grep -v grep | awk '{print "kill "$1";";}')
eval $(ps -w | grep "$scriptname keep" | grep -v grep | awk '{print "kill "$1";";}')
}

adbyby_start () {
nvram set adbybylazy="【adbyby未启动】lazy更新："
nvram set adbybyvideo="【adbyby未启动】video更新："
nvram set adbybyuser3="第三方规则行数：行"
nvram set adbybyuser="自定义规则行数：行"
nvram set button_script_1_s="Adbyby"
/etc/storage/ez_buttons_script.sh 3 & #更新按钮状态
if [ -z "`pidof adbyby`" ] && [ "$adbyby_enable" = "1" ] && [ ! -f /tmp/cron_adb.lock ] ; then
	touch /tmp/cron_adb.lock
	for module in ip_set ip_set_bitmap_ip ip_set_bitmap_ipmac ip_set_bitmap_port ip_set_hash_ip ip_set_hash_ipport ip_set_hash_ipportip ip_set_hash_ipportnet ip_set_hash_net ip_set_hash_netport ip_set_list_set xt_set xt_TPROXY
	do
		modprobe $module
	done 
	adbyby_mount
	sed -e '/^$/d' -i /etc/storage/dnsmasq/hosts
	sed -e '/.*127.0.0.1.*update.adbyby.com.*/d' -i /etc/storage/dnsmasq/hosts
	sed -e '/.*119.147.134.192.*update.adbyby.com/d' -i /etc/storage/dnsmasq/hosts
	sed -e '/.*210.14.141.213.*update.adbyby.com/d' -i /etc/storage/dnsmasq/hosts
	sed -Ei '/.*update.adbyby.com\/180.76.76.76.*/d' /etc/storage/dnsmasq/dnsmasq.servers
	sed -e '/^$/d' -i /etc/storage/dnsmasq/dnsmasq.servers
	restart_dhcpd
	curltest=`which curl`
	if [ -z "$curltest" ] || [ ! -s "`which curl`" ] ; then
		wget --continue --no-check-certificate -s -q -T 10 http://update.adbyby.com/rule3/video.jpg
		[ "$?" == "0" ] && check=200 || check=404
		[ "$check" != "200" ] && check=`curl -k -s -w "%{http_code}" "http://update.adbyby.com/rule3/video.jpg" -o /dev/null`
	else
		check=`curl -k -s -w "%{http_code}" "http://update.adbyby.com/rule3/video.jpg" -o /dev/null`
		[ "$check" != "200" ] && {
		wget --continue --no-check-certificate -s -q -T 10 http://update.adbyby.com/rule3/video.jpg
		[ "$?" == "0" ] && check=200 || check=404
		}
	fi
	if [ "$check" == "200" ] ; then
		echo "[$LOGTIME] update.adbyby.com have no problem."
		rm -rf /tmp/bin/data/video_B.txt /tmp/bin/data/lazy_B.txt
	else
		mkdir -p /tmp/bin/data
		logger -t "【Adbyby】" "下载规则失败, 强制 手动同步更新规则"
		xwhyc_rules="$hiboyfile/video.txt"
		xwhyc_rules3="$hiboyfile2/video.txt"
		xwhyc_rules2="http://update.adbyby.com/rule3/video.jpg"
		logger -t "【Adbyby】" "下载规则:$xwhyc_rules"
		wgetcurl.sh /tmp/bin/data/video.txt $xwhyc_rules $xwhyc_rules2
		[ ! -s /tmp/bin/data/video.txt ] && wgetcurl.sh /tmp/bin/data/video.txt $xwhyc_rules3 $xwhyc_rules2
		mv -f /tmp/bin/data/video.txt /tmp/bin/data/video_B.txt
		xwhyc_rules="$hiboyfile/lazy.txt"
		xwhyc_rules3="$hiboyfile2/lazy.txt"
		xwhyc_rules2="http://update.adbyby.com/rule3/lazy.jpg"
		logger -t "【Adbyby】" "下载规则:$xwhyc_rules"
		wgetcurl.sh /tmp/bin/data/lazy.txt $xwhyc_rules $xwhyc_rules2
		[ ! -s /tmp/bin/data/lazy.txt ] && wgetcurl.sh /tmp/bin/data/lazy.txt $xwhyc_rules3 $xwhyc_rules2
		mv -f /tmp/bin/data/lazy.txt /tmp/bin/data/lazy_B.txt
	fi
	chmod 777 /tmp/bin/adbyby
	# 设置路由ip:8118
	lan_ipaddr="0.0.0.0" #`nvram get lan_ipaddr`
	sed -e "s|^\(listen-address.*\)=[^=]*$|\1=$lan_ipaddr:8118|" -i /tmp/bin/adhook.ini
	# 处理第三方自定义规则 /tmp/rule_DOMAIN.txt
	/etc/storage/ad_config_script.sh
	adbyby_adblocks=`nvram get adbyby_adblocks`
	rm -f /tmp/bin/data/user.bin
	rm -f /tmp/bin/data/user.txt
	if [ "$adbyby_adblocks" = "1" ] ; then
		mkdir -p /tmp/bin/data/
		logger -t "【Adbyby】" "下载 第三方自定义 规则"
		rm -f /tmp/bin/data/user3adblocks.txt
		while read line
		do
		c_line=`echo $line |grep -v "#"`
		if [ ! -z "$c_line" ] ; then
			logger -t "【Adbyby】" "下载规则:$line"
			wgetcurl.sh /tmp/bin/data/user2.txt $line
			grep -v '^!' /tmp/bin/data/user2.txt | grep -E '^(@@\||\||[[:alnum:]])' | sort -u | grep -v "^$" >> /tmp/bin/data/user3adblocks.txt
			rm -f /tmp/bin/data/user2.txt
		fi
		done < /tmp/rule_DOMAIN.txt
	fi
	grep -v '^!' /etc/storage/adbyby_rules_script.sh | grep -v "^$" > /tmp/bin/data/user_rules.txt
	# 添加过滤白名单地址
	if [ "$adbyby_whitehost_x" = "1" ] ; then
		logger -t "【Adbyby】" "添加过滤白名单地址"
		logger -t "【Adbyby】" "加白地址:$adbyby_whitehost"
		sed -Ei '/whitehost=/d' /tmp/bin/adhook.ini
		echo whitehost=$adbyby_whitehost >> /tmp/bin/adhook.ini
		echo @@\|http://\$domain=$(echo $adbyby_whitehost | tr , \|) >> /tmp/bin/data/user_rules.txt
	fi
	# 添加 ipset 过滤设置
	if [ "$adbyby_mode_x" == 1 ] ; then
		logger -t "【Adbyby】" "添加 ipset 过滤设置"
		sed -Ei '/ipset=/d' /tmp/bin/adhook.ini
		echo ipset=1 >> /tmp/bin/adhook.ini
		sed -Ei '/ad_byby|sh_adb8118.sh|restart_dhcpd/d' /tmp/bin/adbybyfirst.sh /tmp/bin/adbybyupdate.sh
		echo "$scriptfilepath C" >> /tmp/bin/adbybyfirst.sh
		echo "$scriptfilepath C" >> /tmp/bin/adbybyupdate.sh
	else
		sed -Ei '/ipset=/d' /tmp/bin/adhook.ini
		echo ipset=0 >> /tmp/bin/adhook.ini
		sed -Ei '/ad_byby|sh_adb8118.sh|restart_dhcpd/d' /tmp/bin/adbybyfirst.sh /tmp/bin/adbybyupdate.sh
	fi
	# 合并规则
	grep -v '^!' /tmp/bin/data/user_rules.txt | grep -v "^$" > /tmp/bin/data/user.txt
	grep -v '^!' /tmp/bin/data/user3adblocks.txt | grep -v "^$" >> /tmp/bin/data/user.txt
	if [ -f "/tmp/bin/data/lazy_B.txt" ] ; then
		logger -t "【Adbyby】" "加载手动同步更新规则"
		grep -v '^!' /tmp/bin/data/video_B.txt | grep -v "^$" >> /tmp/bin/data/user.txt
		grep -v '^!' /tmp/bin/data/lazy_B.txt | grep -v "^$" >> /tmp/bin/data/user.txt
		mv -f /tmp/bin/data/lazy_B.txt /tmp/bin/data/lazy.txt
		mv -f /tmp/bin/data/video_B.txt /tmp/bin/data/video.txt
	fi
	logger -t "【Adbyby】" "启动 adbyby 程序"
	/tmp/bin/adbyby >/dev/null 2>&1 &
	if [ "$adbyby_adblocks" = "1" ] ; then
		logger -t "【Adbyby】" "加载 第三方自定义 规则, 等候10秒"
		sleep 10
	else
		sleep 5
	fi
fi
[ ! -z "`pidof adbyby`" ] && logger -t "【Adbyby】" "启动成功"
[ -z "`pidof adbyby`" ] && logger -t "【Adbyby】" "启动失败, 注意检查端口是否有冲突,程序是否下载完整,10 秒后自动尝试重新启动" && sleep 10 && { nvram set adbyby_status=00; eval "$scriptfilepath &"; exit 0; }
adbyby_add_rules
rm -f /tmp/7620n.tar.gz /tmp/cron_adb.lock
if [ "$adbyby_mode_x" = "1" ] ; then
	ipsetstxt="【ipset模式】"
else
	ipsetstxt="【全局模式】"
fi

adbybylazytime="`sed -n '1,10p' /tmp/bin/data/lazy.txt | grep "$(sed -n '1,10p' /tmp/bin/data/lazy.txt | grep -Eo '[0-9]+-[0-9]+-[0-9]+ [0-9]+:[0-9]+' | sed -n '1p')" | sed 's/[x!]//g' | sed -r 's/-{2,}//g' | sed -r 's/\ {2}//g' | sed -r 's/\ {2}//g' | sed -r 's/[^0-9a-z: \-]//g'`"
adbybyvideotime="`sed -n '1,10p' /tmp/bin/data/video.txt | grep "$(sed -n '1,10p' /tmp/bin/data/video.txt | grep -Eo '[0-9]+-[0-9]+-[0-9]+ [0-9]+:[0-9]+' | sed -n '1p')" | sed 's/[x!]//g' | sed -r 's/-{2,}//g' | sed -r 's/\ {2}//g' | sed -r 's/\ {2}//g' | sed -r 's/[^0-9a-z: \-]//g'`"
adbybylazy_nu="`cat /tmp/bin/data/lazy.txt | grep -v ! | wc -l`"
adbybyvideo_nu="`cat /tmp/bin/data/video.txt | grep -v ! | wc -l`"
logger -t "【Adbyby】" "$ipsetstxt lazy规则更新时间 $adbybylazytime / 【 $adbybylazy_nu 】条"
logger -t "【Adbyby】" "$ipsetstxt video规则更新时间 $adbybyvideotime / 【 $adbybyvideo_nu 】条"
logger -t "【Adbyby】" "第三方规则行数:  `sed -n '$=' /tmp/bin/data/user3adblocks.txt` 行"
logger -t "【Adbyby】" "自定义规则行数:  `sed -n '$=' /tmp/bin/data/user_rules.txt` 行"
nvram set adbybylazy="$ipsetstxt lazy规则更新时间 $adbybylazytime / 【 $adbybylazy_nu 】条"
nvram set adbybyvideo="$ipsetstxt video规则更新时间 $adbybyvideotime / 【 $adbybyvideo_nu 】条"
nvram set adbybyuser3="第三方规则行数:  `sed -n '$=' /tmp/bin/data/user3adblocks.txt | sed s/[[:space:]]//g ` 行"
nvram set adbybyuser="自定义规则行数:  `sed -n '$=' /tmp/bin/data/user_rules.txt | sed s/[[:space:]]//g ` 行"
/etc/storage/ez_buttons_script.sh 3 & #更新按钮状态
logger -t "【Adbyby】" "守护进程启动"
adbyby_cron_job
eval "$scriptfilepath keep &"
}

flush_r () {
iptables -t nat -D PREROUTING -p tcp --dport 80 -j REDIRECT --to-ports 8118 &> /dev/null
iptables-save -c | sed  "s/webstr--url/webstr --url/g" | grep -v "$TAG" | iptables-restore -c
for setname in $(ipset -n list | grep -i "ad_spec"); do
	ipset destroy $setname 2>/dev/null
done
[ -n "$FWI" ] && echo '#!/bin/sh' >$FWI
}

adbyby_cp_rules() {
[ -s /tmp/adbyby_host_backup.conf ] && cp -f /tmp/adbyby_host_backup.conf /tmp/adbyby_host.conf
[ ! -s /tmp/adbyby_host_backup.conf ] && cp -f /tmp/adbyby_host.conf /tmp/adbyby_host_backup.conf
#去除gfw donmain中与 adbyby host 包含的域名，这部分域名交由adbyby处理。
# 参考的awk指令写法
#  awk  'NR==FNR{a[$0]}NR>FNR{ if($1 in a) print $0}' file1 file2 #找出两文件中相同的值
#  awk  'NR==FNR{a[$0]}NR>FNR{ if(!($1 in a)) print $0}' file1 file2 #去除 file2 中file1的内容
#  awk 'NR==FNR{a[$0]++} NR>FNR&&a[$0]' file1 file2 #找出两个文件之间的相同部分
#  awk 'NR==FNR{a[$0]++} NR>FNR&&!a[$0]' file1 file2 #去除 file2 中file1的内容
if [ "$adbyby_mode_x" == 1 ] && [ -s /tmp/adbyby_host.conf ] ; then
logger -t "【iptables】" "添加 ipset 转发规则"
sed -Ei '/adbyby_host.conf|cflist.conf/d' /etc/storage/dnsmasq/dnsmasq.conf
sed  "s/\/adbyby_list/\/adbybylist/" -i  /tmp/adbyby_host.conf
whitehost=`sed -n 's/.*whitehost=\(.*\)/\1/p' /tmp/bin/adhook.ini`
[ ! -z $whitehost ] && sed -Ei "/$(echo $whitehost | tr , \|)/d" /tmp/adbyby_host.conf
[ -f "$confdir$gfwlist" ] && gfw_black=$(grep "/$gfw_black_list" "$confdir$gfwlist" | sed 's/.*\=//g')
if [ -s "$confdir$gfwlist" ] && [ -s /tmp/adbyby_host.conf ] && [ ! -z "$gfw_black" ] ; then
	logger -t "【iptables】" "adbybylist 规则处理开始"
	mkdir -p /tmp/b/
	sed -e '/^\#/d' -e "s/ipset=\/www\./ipset=\/\./" -e "s/ipset=\/bbs\./ipset=\/\./" -e "s/ipset=\/\./ipset=\//" -e "s/ipset=\//ipset=\/\./" -i /tmp/adbyby_host.conf
	sed -e '/^\#/d' -e "s/ipset=\/www\./ipset=\/\./" -e "s/ipset=\/bbs\./ipset=\/\./" -e "s/ipset=\/\./ipset=\//" -e "s/ipset=\//ipset=\/\./" -i "$confdir$gfwlist"
	sed -e '/^\#/d' -e "s/ipset=\///" -e "s/adbybylist//" /tmp/adbyby_host.conf > /tmp/b/adbyby_host去干扰.conf
	sed -e '/^\#/d' -e "s/ipset=\///" -e "s/$gfw_black_list//" -e "/server=\//d" "$confdir$gfwlist" > /tmp/b/gfwlist去干扰.conf
	awk 'NR==FNR{a[$0]++} NR>FNR&&a[$0]' /tmp/b/adbyby_host去干扰.conf /tmp/b/gfwlist去干扰.conf > /tmp/b/host相同行.conf
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
ipset add adbybylist 100.100.100.100
restart_dhcpd
logger -t "【iptables】" "adbybylist 规则处理完毕"
rm -f /tmp/b/*
fi

}

adbyby_flush_rules () {
logger -t "【iptables】" "删除8118转发规则"
flush_r
ipset -F adbybylist &> /dev/null
ipset destroy adbybylist &> /dev/null
#ipset -F cflist &> /dev/null
rm -f /tmp/adbyby_host.conf
sed -Ei '/adbyby_host.conf/d' /etc/storage/dnsmasq/dnsmasq.conf
restart_dhcpd
logger -t "【iptables】" "完成删除8118规则"
}

adbyby_add_rules() {
logger -t "【iptables】" "添加8118转发规则"
flush_r
ipset -! restore <<-EOF || return 1
create ad_spec_src_ac hash:ip hashsize 64
create ad_spec_src_bp hash:ip hashsize 64
create ad_spec_src_fw hash:ip hashsize 64
create ad_spec_dst_sp hash:net hashsize 64
$(gen_special_purpose_ip | sed -e "s/^/add ad_spec_dst_sp /")
EOF
ipset -! -N cflist iphash
ipset -! -N adbybylist iphash
lan_ipaddr=`nvram get lan_ipaddr`
ipset add ad_spec_src_bp $lan_ipaddr
ipset add ad_spec_src_bp 127.0.0.1
ipset add adbybylist 100.100.100.100
/etc/storage/ad_config_script.sh
# 内网(LAN)访问控制
logger -t "【Adbyby】" "设置内网(LAN)访问控制"
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
	echo "AD_BYBY-number:$wifidogn"
	iptables -t nat -I PREROUTING $wifidognx -p tcp -m multiport --dports 80,8080 -j AD_BYBY
	iptables -t nat -A AD_BYBY_to -p tcp -j REDIRECT --to-port 8118
	dns_redirect
	sleep 1
	gen_include &
	logger -t "【iptables】" "完成添加8118规则"
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
		logger -t "【Adbyby】" "udp53端口（DNS）地址重定向为 $ss_DNS_Redirect_IP 强制使用重定向地址的DNS"
		iptables -t nat -A PREROUTING -s $lan_ipaddr/24 -p udp --dport 53 -j AD_BYBY_DNS_LAN_DG
		iptables -t nat -A AD_BYBY_DNS_WAN_FW -j DNAT --to $ss_DNS_Redirect_IP
	fi

}

adbyby_cron_job(){
	adbyby_update=${adbyby_update:-"0"}
	adbyby_update_hour=${adbyby_update_hour:-"23"}
	adbyby_update_min=${adbyby_update_min:-"59"}
	if [ "0" == "$adbyby_update" ]; then
	[ $adbyby_update_hour -gt 23 ] && adbyby_update_hour=23 && nvram set adbyby_update_hour=$adbyby_update_hour
	[ $adbyby_update_hour -lt 0 ] && adbyby_update_hour=0 && nvram set adbyby_update_hour=$adbyby_update_hour
	[ $adbyby_update_min -gt 59 ] && adbyby_update_min=59 && nvram set adbyby_update_min=$adbyby_update_min
	[ $adbyby_update_min -lt 0 ] && adbyby_update_min=0 && nvram set adbyby_update_min=$adbyby_update_min
		logger -t "【Adbyby】" "开启规则定时更新，每天"$adbyby_update_hour"时"$adbyby_update_min"分，检查在线规则更新..."
		cru.sh a adbyby_update "$adbyby_update_min $adbyby_update_hour * * * $scriptfilepath update &" &
	elif [ "1" == "$adbyby_update" ]; then
	#[ $adbyby_update_hour -gt 23 ] && adbyby_update_hour=23 && nvram set adbyby_update_hour=$adbyby_update_hour
	[ $adbyby_update_hour -lt 0 ] && adbyby_update_hour=0 && nvram set adbyby_update_hour=$adbyby_update_hour
	[ $adbyby_update_min -gt 59 ] && adbyby_update_min=59 && nvram set adbyby_update_min=$adbyby_update_min
	[ $adbyby_update_min -lt 0 ] && adbyby_update_min=0 && nvram set adbyby_update_min=$adbyby_update_min
		logger -t "【Adbyby】" "开启规则定时更新，每隔"$adbyby_update_inter_hour"时"$adbyby_update_inter_min"分，检查在线规则更新..."
		cru.sh a adbyby_update "*/$adbyby_update_min */$adbyby_update_hour * * * $scriptfilepath update &" &
	else
		logger -t "【Adbyby】" "规则自动更新关闭状态，不启用自动更新..."
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
	adbyby_close
	adbyby_check
	;;
check)
	adbyby_check
	;;
stop)
	adbyby_close
	;;
keep)
	adbyby_check
	adbyby_keep
	;;
A)
	adbyby_add_rules
	;;
D)
	adbyby_flush_rules
	;;
C)
	adbyby_cp_rules
	;;
update)
	[ "$adbyby_enable" != "1" ] && exit 0
	killall sh_ad_byby_keey_k.sh
	killall -9 sh_ad_byby_keey_k.sh
	checka="/tmp/var/video.txt"
	rm -f /tmp/var/video.txt
	urla="http://update.adbyby.com/rule3/video.jpg"
	checkb="/tmp/bin/data/video.txt"
	wgetcurl.sh $checka $urla
	if [ "`md5sum $checka|cut -d" " -f1`" != "`md5sum $checkb|cut -d" " -f1`" ] ; then
		logger -t "【Adbyby】" "更新检查:有更新 $urla , 重启进程"
		nvram set adbyby_status=00 && { eval "$scriptfilepath start &"; exit 0; }
	else
		logger -t "【Adbyby】" "更新检查:不需更新 $urla "
	fi
	[ -s /tmp/sh_ad_byby_keey_k.sh ] && /tmp/sh_ad_byby_keey_k.sh &
	;;
update_ad)
	adbyby_mount
	adbyby_close
	rm -rf /tmp/bin/*
	nvram set adbyby_status=00 && { eval "$scriptfilepath start &"; exit 0; }
	;;
*)
	adbyby_check
	;;
esac

