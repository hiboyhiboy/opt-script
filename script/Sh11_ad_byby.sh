#!/bin/bash
#copyright by hiboy
source /etc/storage/script/init.sh
TAG="AD_BYBY"		  # iptables tag
adbyby_enable=`nvram get adbyby_enable`
[ -z $adbyby_enable ] && adbyby_enable=0 && nvram set adbyby_enable=0
if [ "$adbyby_enable" != "0" ] ; then
adbyby_mode_x=`nvram get adbyby_mode_x`
[ -z $adbyby_mode_x ] && adbyby_mode_x=0 && nvram set adbyby_mode_x=0
adbyby_update=`nvram get adbyby_update`
adbyby_update_hour=`nvram get adbyby_update_hour`
adbyby_update_min=`nvram get adbyby_update_min`
adbyby_mode_x=`nvram get adbyby_mode_x`
adbyby_adblocks=`nvram get adbyby_adblocks`
adbyby_CPUAverages=`nvram get adbyby_CPUAverages`
adbyby_whitehost_x=`nvram get adbyby_whitehost_x`
adbyby_whitehost=`nvram get adbyby_whitehost`
ss_DNS_Redirect=`nvram get ss_DNS_Redirect`
ss_DNS_Redirect_IP=`nvram get ss_DNS_Redirect_IP`
koolproxy_enable=`nvram get koolproxy_enable`
adm_enable=`nvram get adm_enable`
ss_enable=`nvram get ss_enable`
ss_mode_x=`nvram get ss_mode_x`

adbybyfile="$hiboyfile/7620i.tar.gz"
adbybyfile2="$hiboyfile2/7620i.tar.gz"


FWI="/tmp/firewall.adbyby.pdcn" # firewall include file
AD_LAN_AC_IP=`nvram get AD_LAN_AC_IP`
[ -z $AD_LAN_AC_IP ] && AD_LAN_AC_IP=0 && nvram set AD_LAN_AC_IP=$AD_LAN_AC_IP
lan_ipaddr=`nvram get lan_ipaddr`
[ -z "$ss_DNS_Redirect_IP" ] && ss_DNS_Redirect_IP=$lan_ipaddr && nvram set ss_DNS_Redirect_IP=$ss_DNS_Redirect_IP
[ -z $adbyby_adblocks ] && adbyby_adblocks=0 && nvram set adbyby_adblocks=$adbyby_adblocks

adbyby_renum=`nvram get adbyby_renum`
adbyby_renum=${adbyby_renum:-"0"}
cmd_log_enable=`nvram get cmd_log_enable`
cmd_name="Adbyby"
cmd_log=""
if [ "$cmd_log_enable" = "1" ] || [ "$adbyby_renum" -gt "0" ] ; then
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

if [ ! -z "$(echo $scriptfilepath | grep -v "/tmp/script/" | grep ad_byby)" ] && [ ! -s /tmp/script/_ad_byby ] ; then
	mkdir -p /tmp/script
	{ echo '#!/bin/bash' ; echo $scriptfilepath '"$@"' '&' ; } > /tmp/script/_ad_byby
	chmod 777 /tmp/script/_ad_byby
fi

adbyby_mount () {

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
	logger -t "【Adbyby】" "已挂载储存设备, 主程序放外置设备存储"
	initopt
	mkdir -p $upanPath/ad/bin
	rm -f /tmp/bin
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
		logger -t "【Adbyby】" "开始下载 adbyby Files"
		wgetcurl.sh $upanPath/ad/7620n.tar.gz "https://raw.githubusercontent.com/adbyby/Files/master/7620n.tar.gz" 'https://coding.net/u/adbyby/p/linux/git/raw/master/7620n.tar.gz' N
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
		logger -t "【Adbyby】" "开始下载 adbyby Files"
		wgetcurl.sh /tmp/7620n.tar.gz "https://raw.githubusercontent.com/adbyby/Files/master/7620n.tar.gz" 'https://coding.net/u/adbyby/p/linux/git/raw/master/7620n.tar.gz' N
		untar.sh /tmp/7620n.tar.gz /tmp /tmp/bin/adbyby
	fi
fi
export PATH='/tmp/bin:/etc/storage/bin:/tmp/script:/etc/storage/script:/opt/usr/sbin:/opt/usr/bin:/opt/sbin:/opt/bin:/usr/local/sbin:/usr/sbin:/usr/bin:/sbin:/bin'
chmod 777 /tmp/bin/adbyby
[[ "$(/tmp/bin/adbyby --help | wc -l)" -lt 2 ]] && rm -rf /tmp/bin/*
if [ ! -s "/tmp/bin/adbyby" ] ; then
	rm -rf /tmp/bin/*
	logger -t "【Adbyby】" "下载失败, 注意检查端口是否有冲突,程序是否下载完整,10 秒后自动尝试重新启动" && sleep 10 && adbyby_restart x
fi
}

adbyby_restart () {
i_app_restart "$@" -name="adbyby"
}

adbyby_get_status () {

B_restart="$adbyby_enable$adbyby_update$adbyby_update_hour$adbyby_update_min$adbyby_mode_x$adbybyfile$adbybyfile2$adbyby_adblocks$adbyby_CPUAverages$adbyby_whitehost_x$adbyby_whitehost$lan_ipaddr$ss_DNS_Redirect$ss_DNS_Redirect_IP$(cat /etc/storage/ad_config_script.sh | grep -v '^$' | grep -v '^#')$(cat /etc/storage/adbyby_rules_script.sh | grep -v '^$' | grep -v "^!")"

i_app_get_status -name="adbyby" -valb="$B_restart"
}

adbyby_check () {

adbyby_get_status
if [ "$adbyby_enable" != "1" ] && [ "$needed_restart" = "1" ] ; then
	[ ! -z "`pidof adbyby`" ] && logger -t "【Adbyby】" "停止 adbyby" && adbyby_close
	{ kill_ps "$scriptname" exit0; exit 0; }
fi
if [ "$adbyby_enable" = "1" ] ; then
	if [ "$needed_restart" = "1" ] ; then
		adbyby_close
		adbyby_start
	else
		[ -z "`pidof adbyby`" ] || [ ! -s "/tmp/bin/adbyby" ] && adbyby_restart
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
adbybylazytime="`sed -n '1,10p' /tmp/bin/data/lazy.txt | grep "$(sed -n '1,10p' /tmp/bin/data/lazy.txt | grep -Eo '[0-9]+-[0-9]+-[0-9]+ [0-9]+:[0-9]+|201?.{1}' | sed -n '1p')" | sed 's/[x!]//g' | sed -r 's/-{2,}//g' | sed -r 's/\ {2}//g' | sed -r 's/\ {2}//g' | sed -r 's/[^0-9a-z: \-]//g' | sed -n '1p'`"
adbybyvideotime="`sed -n '1,10p' /tmp/bin/data/video.txt | grep "$(sed -n '1,10p' /tmp/bin/data/video.txt | grep -Eo '[0-9]+-[0-9]+-[0-9]+ [0-9]+:[0-9]+|201?.{1}' | sed -n '1p')" | sed 's/[x!]//g' | sed -r 's/-{2,}//g' | sed -r 's/\ {2}//g' | sed -r 's/\ {2}//g' | sed -r 's/[^0-9a-z: \-]//g' | sed -n '1p'`"
adbybylazy_nu="`cat /tmp/bin/data/lazy.txt | grep -v ! | wc -l`"
adbybyvideo_nu="`cat /tmp/bin/data/video.txt | grep -v ! | wc -l`"
nvram set adbybylazy="$ipsetstxt lazy规则更新时间 $adbybylazytime / 【 $adbybylazy_nu 】条"
nvram set adbybyvideo="$ipsetstxt video规则更新时间 $adbybyvideotime / 【 $adbybyvideo_nu 】条"
nvram set adbybyuser3="第三方规则行数:  `sed -n '$=' /tmp/bin/data/user3adblocks.txt | sed s/[[:space:]]//g ` 行"
nvram set adbybyuser="自定义规则行数:  `sed -n '$=' /tmp/bin/data/user_rules.txt | sed s/[[:space:]]//g ` 行"
rm -f /tmp/cron_adb.lock
/etc/storage/script/sh_ezscript.sh 3 & #更新按钮状态
i_app_keep -name="adbyby" -pidof="adbyby" &
while true; do
if [ ! -f /tmp/cron_adb.lock ] ; then
	if [ ! -f /tmp/cron_adb.lock ] ; then
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
		port=$(iptables -t nat -L | grep 'AD_BYBY_to' | wc -l)
			if [ "$port" = 0 ] && [ ! -f /tmp/cron_adb.lock ] ; then
				logger -t "【Adbyby】" "找不到AD_BYBY_to转发规则, 重新添加"
				adbyby_add_rules
			fi
	fi
	sleep 211
fi
sleep 21
adbyby_keepcpu
done
}

adbyby_keepcpu () {
if [ "$adbyby_CPUAverages" = "1" ] && [ ! -f /tmp/cron_adb.lock ] ; then
	processor=`cat /proc/cpuinfo| grep "processor"| wc -l`
	[ "$processor" = "1" ] && processor=`expr $processor \* 2`
	CPULoad=`uptime |sed -e 's/\ *//g' -e 's/.*://g' | awk -F ',' '{print $2;}' | sed -e 's/\..*//g'`
	if [ $((CPULoad)) -ge "$processor" ] ; then
		logger -t "【Adbyby】" "CPU 负载拥堵, 关闭 adbyby"
		adbyby_flush_rules
		/etc/storage/script/sh_ezscript.sh 3 & #更新按钮状态
		killall adbyby
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

kill_ps "$scriptname keep"
nvram set adbybylazy="【adbyby未启动】lazy更新："
nvram set adbybyvideo="【adbyby未启动】video更新："
nvram set adbybyuser3="第三方规则行数：行"
nvram set adbybyuser="自定义规则行数：行"
cru.sh d adbyby_update &
cru.sh d adm_update &
cru.sh d koolproxy_update &
port=$(iptables -t nat -L | grep 'ports 8118' | wc -l)
[ "$port" != 0 ] && adbyby_flush_rules
killall adbyby
[ "$adm_enable" != "1" ] && killall adm sh_ad_m_keey_k.sh
[ "$koolproxy_enable" != "1" ] && killall koolproxy sh_ad_kp_keey_k.sh
/etc/storage/script/sh_ezscript.sh 3 & #更新按钮状态
rm -f /tmp/7620n.tar.gz /tmp/cron_adb.lock /tmp/adbyby_host_backup.conf
kill_ps "/tmp/script/_ad_byby"
kill_ps "_ad_byby.sh"
kill_ps "$scriptname"
}


update_ad_rules () {

xwhyc_rules="$hiboyfile/video.txt"
xwhyc_rules2="https://opt.cn2qq.com/opt-file/video.txt"
#xwhyc_rules1="https://raw.githubusercontent.com/adbyby/xwhyc-rules/master/video.txt"
#xwhyc_rules0="https://coding.net/u/adbyby/p/xwhyc-rules/git/raw/master/video.txt"
logger -t "【Adbyby】" "下载规则:$xwhyc_rules"
wgetcurl.sh /tmp/bin/data/video.txt $xwhyc_rules $xwhyc_rules2 N 5
#[ ! -s /tmp/bin/data/video.txt ] && wgetcurl.sh /tmp/bin/data/video.txt $xwhyc_rules $xwhyc_rules0 N 5
xwhyc_rules="$hiboyfile/lazy.txt"
xwhyc_rules2="https://opt.cn2qq.com/opt-file/lazy.txt"
#xwhyc_rules1="https://raw.githubusercontent.com/adbyby/xwhyc-rules/master/lazy.txt"
#xwhyc_rules0="https://coding.net/u/adbyby/p/xwhyc-rules/git/raw/master/lazy.txt"
logger -t "【Adbyby】" "下载规则:$xwhyc_rules"
wgetcurl.sh /tmp/bin/data/lazy.txt $xwhyc_rules $xwhyc_rules2 N 100
#[ ! -s /tmp/bin/data/lazy.txt ] && wgetcurl.sh /tmp/bin/data/lazy.txt $xwhyc_rules $xwhyc_rules0 N 100

}

adbyby_start () {
check_webui_yes
user_dnsmasq_serv=/etc/storage/dnsmasq/dnsmasq.servers
if [ ! -z "$(grep "update.adbyby.com" $user_dnsmasq_serv)" ] ; then
sed -Ei '/adbyby.com/d' $user_dnsmasq_serv
sed -Ei '/^$/d' $user_dnsmasq_serv
echo "address=/adbyby.com/127.0.0.1" >> $user_dnsmasq_serv
restart_dhcpd
fi
logger -t "【opt】" "提醒！adbyby.com 域名已经失去控制，继续使用会有风险。"
logger -t "【opt】" "提醒！adbyby.com 域名已经失去控制，继续使用会有风险。"
logger -t "【opt】" "提醒！adbyby.com 域名已经失去控制，继续使用会有风险。"
nvram set adbybylazy="【adbyby未启动】lazy更新："
nvram set adbybyvideo="【adbyby未启动】video更新："
nvram set adbybyuser3="第三方规则行数：行"
nvram set adbybyuser="自定义规则行数：行"
nvram set button_script_1_s="Adbyby"
/etc/storage/script/sh_ezscript.sh 3 & #更新按钮状态
if [ -z "`pidof adbyby`" ] && [ "$adbyby_enable" = "1" ] && [ ! -f /tmp/cron_adb.lock ] ; then
	touch /tmp/cron_adb.lock
	for module in ip_set ip_set_bitmap_ip ip_set_bitmap_ipmac ip_set_bitmap_port ip_set_hash_ip ip_set_hash_ipport ip_set_hash_ipportip ip_set_hash_ipportnet ip_set_hash_net ip_set_hash_netport ip_set_list_set xt_set xt_TPROXY
	do
		modprobe $module
	done 
	adbyby_mount
	sed -e '/^$/d' -i /etc/storage/dnsmasq/hosts
	sed -e '/^$/d' -i /etc/storage/dnsmasq/dnsmasq.servers
	restart_dhcpd
	[ -s /tmp/bin/data/video.txt ] && rm -f /tmp/bin/data/video.txt /tmp/bin/data/video_B.txt
	[ -s /tmp/bin/data/lazy.txt ] && rm -f /tmp/bin/data/lazy.txt /tmp/bin/data/lazy_B.txt
	# logger -t "【Adbyby】" "测试下载规则"
	# curltest=`which curl`
	# if [ -z "$curltest" ] || [ ! -s "`which curl`" ] ; then
		# wget --user-agent "$user_agent" -q  -T 5 -t 3 http://update.adbyby.com/rule3/video.jpg -O /dev/null
		# [ "$?" == "0" ] && check=200 || check=404
	# else
		# check=`curl --connect-timeout 10 --user-agent "$user_agent" -s -w "%{http_code}" "http://update.adbyby.com/rule3/video.jpg" -o /dev/null`
		# if [ "$check" != "200" ] ; then
			# wget --user-agent "$user_agent"s -q  -T 5 -t 3 http://update.adbyby.com/rule3/video.jpg -O /dev/null
			# [ "$?" == "0" ] && check=200 || check=404
		# fi
	# fi
	# if [ "$check" == "200" ] ; then
		# logger -t "【Adbyby】" "测试下载规则成功"
		# echo "[$LOGTIME] update.adbyby.com have no problem."
		# rm -rf /tmp/bin/data/video_B.txt /tmp/bin/data/lazy_B.txt
	# else
		mkdir -p /tmp/bin/data
		# logger -t "【Adbyby】" "测试下载规则失败, 强制 手动同步更新规则"
		update_ad_rules
		[ -s /tmp/bin/data/video.txt ] && mv -f /tmp/bin/data/video.txt /tmp/bin/data/video_B.txt
		[ -s /tmp/bin/data/lazy.txt ] && mv -f /tmp/bin/data/lazy.txt /tmp/bin/data/lazy_B.txt
	# fi
	chmod 777 /tmp/bin/adbyby
	# 设置路由ip:8118
	lan_ipaddr="0.0.0.0" #`nvram get lan_ipaddr`
	sed -e "s|^\(listen-address.*\)=[^=]*$|\1=$lan_ipaddr:8118|" -i /tmp/bin/adhook.ini
	sed -e "s|^\(rule.*\)=[^=]*$|\1=|" -i /tmp/bin/adhook.ini
	# 处理第三方自定义规则 /tmp/rule_DOMAIN.txt
	source /etc/storage/ad_config_script.sh
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
			wgetcurl.sh /tmp/bin/data/user2.txt $line $line N
			cat /tmp/bin/data/user2.txt | grep -v '^!' | grep -E '^(@@\||\||[[:alnum:]])' | sort -u | grep -v '^$' >> /tmp/bin/data/user3adblocks.txt
			rm -f /tmp/bin/data/user2.txt
		fi
		done < /tmp/rule_DOMAIN.txt
	fi
	cat /etc/storage/adbyby_rules_script.sh | grep -v '^!' | grep -v '^$' > /tmp/bin/data/user_rules.txt
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
	cat /tmp/bin/data/user_rules.txt | grep -v '^!' | grep -v '^$' > /tmp/bin/data/user.txt
	cat /tmp/bin/data/user3adblocks.txt | grep -v '^!' | grep -v '^$' >> /tmp/bin/data/user.txt
	if [ -f "/tmp/bin/data/lazy_B.txt" ] ; then
		logger -t "【Adbyby】" "加载手动同步更新规则"
		cat /tmp/bin/data/video_B.txt | grep -v '^!' | grep -v '^$' >> /tmp/bin/data/user.txt
		cat /tmp/bin/data/lazy_B.txt |grep -v '^!' | grep -v '^$' >> /tmp/bin/data/user.txt
		[ -s /tmp/bin/data/lazy_B.txt ] && mv -f /tmp/bin/data/lazy_B.txt /tmp/bin/data/lazy.txt
		[ -s /tmp/bin/data/video_B.txt ] && mv -f /tmp/bin/data/video_B.txt /tmp/bin/data/video.txt
	fi
	logger -t "【Adbyby】" "启动 adbyby 程序"
	eval "/tmp/bin/adbyby $cmd_log" &
	if [ "$adbyby_adblocks" = "1" ] ; then
		logger -t "【Adbyby】" "加载 第三方自定义 规则, 等候10秒"
		sleep 10
	else
		sleep 5
	fi
	# 检测规则下载
	rules_nu="`cat /tmp/bin/data/lazy.txt | grep -v ! | wc -l`"
	if [ $rules_nu -lt 100 ] ; then
		logger -t "【Adbyby】" "错误！下载规则数 $rules_nu ，再次启用脚本手动下载更新。"
		update_ad_rules
		killall adbyby
		eval "/tmp/bin/adbyby $cmd_log" &
		sleep 10
	fi
fi
i_app_keep -t -name="adbyby" -pidof="adbyby"
adbyby_add_rules
rm -f /tmp/7620n.tar.gz /tmp/cron_adb.lock
if [ "$adbyby_mode_x" = "1" ] ; then
	ipsetstxt="【ipset模式】"
else
	ipsetstxt="【全局模式】"
fi

adbybylazytime="$(sed -n '1,10p' /tmp/bin/data/lazy.txt | grep "$(sed -n '1,10p' /tmp/bin/data/lazy.txt | grep -Eo '[0-9]+-[0-9]+-[0-9]+ [0-9]+:[0-9]+|201?.{1}' | sed -n '1p')" | sed 's/[x!]//g' | sed -r 's/-{2,}//g' | sed -r 's/\ {2}//g' | sed -r 's/\ {2}//g' | sed -r 's/[^0-9a-z: \-]//g' | sed -n '1p')"
adbybyvideotime="$(sed -n '1,10p' /tmp/bin/data/video.txt | grep "$(sed -n '1,10p' /tmp/bin/data/video.txt | grep -Eo '[0-9]+-[0-9]+-[0-9]+ [0-9]+:[0-9]+|201?.{1}' | sed -n '1p')" | sed 's/[x!]//g' | sed -r 's/-{2,}//g' | sed -r 's/\ {2}//g' | sed -r 's/\ {2}//g' | sed -r 's/[^0-9a-z: \-]//g' | sed -n '1p')"
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
/etc/storage/script/sh_ezscript.sh 3 & #更新按钮状态
logger -t "【Adbyby】" "守护进程启动"
logger -t "【opt】" "提醒！adbyby.com 域名已经失去控制，继续使用会有风险。"
logger -t "【opt】" "提醒！adbyby.com 域名已经失去控制，继续使用会有风险。"
logger -t "【opt】" "提醒！adbyby.com 域名已经失去控制，继续使用会有风险。"
adbyby_cron_job
[ ! -s /tmp/adbyby_host_backup.conf ] && cp -f /tmp/adbyby_host.conf /tmp/adbyby_host_backup.conf
adbyby_cp_rules
#adbyby_get_status
eval "$scriptfilepath keep &"
exit 0
}

flush_r () {
iptables -t nat -D PREROUTING -p tcp --dport 80 -j REDIRECT --to-ports 8118 > /dev/null
iptables-save -c | sed  "s/webstr--url/webstr --url/g" | grep -v "$TAG" | iptables-restore -c
for setname in $(ipset -n list | grep -i "ad_spec"); do
	ipset destroy $setname 2>/dev/null
done
[ -n "$FWI" ] && echo '#!/bin/bash' >$FWI
}

adbyby_cp_rules() {
[ ! -s /tmp/adbyby_host.conf ] && [ -f /tmp/adbyby_host_backup.conf ] && cp -f /tmp/adbyby_host_backup.conf /tmp/adbyby_host.conf
# ipset=/opt.cn2qq.com/adbybylist
# ipset=/opt.cn2qq.com/adbybylist
# 首先生成匹配的配置文件
# 再把 adbybylist 加入 ipset 配置，这部分域名交由 sh_ss_tproxy.sh 处理。
if [ "$adbyby_mode_x" == 1 ] && [ -s /tmp/adbyby_host.conf ] ; then
logger -t "【iptables】" "添加 ipset 转发规则"
logger -t "【iptables】" "adbybylist 规则处理开始"
sed -e '/^\#\|server=/d' -e "s/ipset=\/www\./ipset=\//" -e "s/ipset=\/bbs\./ipset=\//" -e "s/ipset=\/\./ipset=\//" -e "s/ipset=\///" -i /tmp/adbyby_host.conf
sed -Ei "s/\/.+//"  /tmp/adbyby_host.conf
cat /tmp/adbyby_host.conf | sort -u | sed 's/^[[:space:]]*//g; /^$/d; /#/d' | awk '{printf("ipset=/%s/adbybylist\n", $1)}' > /tmp/adbyby_host.conf
adbyby_whitehost=`nvram get adbyby_whitehost`
[ ! -z $whitehost ] && sed -Ei "/$(echo $whitehost | tr , \|)/d" /tmp/adbyby_host.conf
sh_ss_tproxy.sh adbyby_cflist_ipset
sed -Ei "/\/opt\/app\/ss_tproxy\/dnsmasq.d\/r.gfwlist.conf/d" /etc/storage/dnsmasq/dnsmasq.conf
[ -s /tmp/ss_tproxy/dnsmasq.d/r.gfwlist.conf ] && [ -z "$(cat /etc/storage/dnsmasq/dnsmasq.conf | grep "/tmp/ss_tproxy/dnsmasq.d")" ] && echo "conf-file=/opt/app/ss_tproxy/dnsmasq.d/r.gfwlist.conf" >> "/etc/storage/dnsmasq/dnsmasq.conf"
ipset flush adbybylist
ipset add adbybylist 100.100.100.100
restart_dhcpd

logger -t "【iptables】" "gfwlist 规则处理完毕"

fi
}

adbyby_flush_rules () {
logger -t "【iptables】" "删除8118转发规则"
flush_r
ipset -F adbybylist &> /dev/null
#ipset destroy adbybylist &> /dev/null
rm -f /tmp/adbyby_host.conf
sed -Ei "/\/opt\/app\/ss_tproxy\/dnsmasq.d\/r.gfwlist.conf/d" /etc/storage/dnsmasq/dnsmasq.conf
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
ipset -! -N adbybylist hash:net hashsize 1024 family inet
lan_ipaddr=`nvram get lan_ipaddr`
ipset add ad_spec_src_bp $lan_ipaddr
ipset add ad_spec_src_bp 127.0.0.1
ipset add adbybylist 100.100.100.100
source /etc/storage/ad_config_script.sh
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
	echo "AD_BYBY-number:$wifidogn"
	logger -t "【iptables】" "AD_BYBY-number:$wifidogn"
	iptables -t nat -I PREROUTING $wifidognx -p tcp -m multiport --dports 80,8080 -j AD_BYBY
	iptables -t nat -A AD_BYBY_to -p tcp -j REDIRECT --to-ports 8118
	dns_redirect
	sleep 1
	gen_include &
	logger -t "【iptables】" "完成添加8118规则"
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
	[ -z $adbyby_update ] && adbyby_update=0 && nvram set adbyby_update=$adbyby_update
	[ -z $adbyby_update_hour ] && adbyby_update_hour=23 && nvram set adbyby_update_hour=$adbyby_update_hour
	[ -z $adbyby_update_min ] && adbyby_update_min=59 && nvram set adbyby_update_min=$adbyby_update_min
	if [ "0" == "$adbyby_update" ] ; then
	[ $adbyby_update_hour -gt 23 ] && adbyby_update_hour=23 && nvram set adbyby_update_hour=$adbyby_update_hour
	[ $adbyby_update_hour -lt 0 ] && adbyby_update_hour=0 && nvram set adbyby_update_hour=$adbyby_update_hour
	[ $adbyby_update_min -gt 59 ] && adbyby_update_min=59 && nvram set adbyby_update_min=$adbyby_update_min
	[ $adbyby_update_min -lt 0 ] && adbyby_update_min=0 && nvram set adbyby_update_min=$adbyby_update_min
		logger -t "【Adbyby】" "开启规则定时更新，每天"$adbyby_update_hour"时"$adbyby_update_min"分，检查在线规则更新..."
		cru.sh a adbyby_update "$adbyby_update_min $adbyby_update_hour * * * $scriptfilepath update &" &
	elif [ "1" == "$adbyby_update" ] ; then
	#[ $adbyby_update_hour -gt 23 ] && adbyby_update_hour=23 && nvram set adbyby_update_hour=$adbyby_update_hour
	[ $adbyby_update_hour -lt 0 ] && adbyby_update_hour=0 && nvram set adbyby_update_hour=$adbyby_update_hour
	[ $adbyby_update_min -gt 59 ] && adbyby_update_min=59 && nvram set adbyby_update_min=$adbyby_update_min
	[ $adbyby_update_min -lt 0 ] && adbyby_update_min=0 && nvram set adbyby_update_min=$adbyby_update_min
		logger -t "【Adbyby】" "开启规则定时更新，每隔"$adbyby_update_inter_hour"时"$adbyby_update_inter_min"分，检查在线规则更新..."
		cru.sh a adbyby_update "$adbyby_update_min */$adbyby_update_hour * * * $scriptfilepath update &" &
	else
		logger -t "【Adbyby】" "规则自动更新关闭状态，不启用自动更新..."
	fi
}

initconfig () {

ad_config_script="/etc/storage/ad_config_script.sh"
if [ ! -f "$ad_config_script" ] || [ ! -s "$ad_config_script" ] ; then
	cat > "$ad_config_script" <<-\EEE
# 广告过滤 访问控制功能

# 内网(LAN)访问控制的默认代理转发设置，
#    0  默认值, 常规, 未在以下设定的 内网IP 根据 AD配置工作模式 走 AD
#    1         全局, 未在以下设定的 内网IP 使用全局代理 走 AD
#    2         绕过, 未在以下设定的 内网IP 不使用 AD
AD_LAN_AC_IP=0
nvram set AD_LAN_AC_IP=$AD_LAN_AC_IP
# =========================================================
# 内网(LAN)IP设定行为设置, 格式如 b,192.168.1.23, 多个值使用空格隔开
#   使用 b/g/n 前缀定义主机行为模式, 使用英文逗号与主机 IP 分隔
#   b: 绕过, 此前缀的主机IP 不使用 AD
#   g: 全局, 此前缀的主机IP 忽略 AD配置工作模式 使用全局代理 走 AD
#   n: 常规, 此前缀的主机IP 使用 AD配置工作模式 走 AD
#   s: https, 此前缀的主机IP 使用 AD配置工作模式 https走 AD
#   优先级: 绕过 > 全局 > 常规
# （如多个设置则每一个ip一行,可选项：删除前面的#可生效）
cat > "/tmp/ad_spec_lan_DOMAIN.txt" <<-\EOF
#b,192.168.123.115
#g,192.168.123.116
#n,192.168.123.117
#s,192.168.123.118
#b,099B9A909FD9
#s,099B9A909FD9
#g,A9:CB:3A:5F:1F:C7



EOF
# =========================================================

# adbyby加载第三方adblock规则 0关闭；1启动（可选项：删除前面的#可生效）
#【不建议启用第三方规则,有可能破坏规则导致过滤失效】
nvram set adbyby_adblocks=0
adblocks=`nvram get adbyby_adblocks`
cat > "/tmp/rule_DOMAIN.txt" <<-\EOF
# 【可选多项，会占用内存：删除前面的#可生效，前面添加#停用规则】
# https://easylist-downloads.adblockplus.org/easylistchina.txt



EOF

EEE
	chmod 755 "$ad_config_script"
fi

adbyby_rules_script="/etc/storage/adbyby_rules_script.sh"
if [ ! -f "$adbyby_rules_script" ] || [ ! -s "$adbyby_rules_script" ] ; then
	cat > "$adbyby_rules_script" <<-\EEE
!  ------------------------------ ADByby 自定义过滤语法简--------------------------------
!  --------------  规则基于abp规则，并进行了字符替换部分的扩展-----------------------------
!  ABP规则请参考 https://adblockplus.org/zh_CN/filters ，下面为大致摘要
!  "!" 为行注释符，注释行以该符号起始作为一行注释语义，用于规则描述。
!  "*" 为字符通配符，能够匹配0长度或任意长度的字符串，该通配符不能与正则语法混用。
!  "^" 为分隔符，可以是除了字母、数字或者 _ - . % 之外的任何字符。
!  "|" 为管线符号，来表示地址的最前端或最末端
!  "||" 为子域通配符，方便匹配主域名下的所有子域。
!  "~" 为排除标识符，通配符能过滤大多数广告，但同时存在误杀, 可以通过排除标识符修正误杀链接。
!  "##" 为元素选择器标识符，后面跟需要隐藏元素的CSS样式例如 #ad_id  .ad_class
!!  元素隐藏暂不支持全局规则和排除规则
!! 字符替换扩展
!  文本替换选择器标识符，后面跟需要替换的文本数据，格式：$s@模式字符串@替换后的文本@
!  支持通配符*和?
! 参考以下规则格式添加指定过滤网址
! adbyby_list【模式二】指定网址过滤 功能
|http://www.sohu.com/adbyby_list
!百度广告
||cbjs.baidu.com/adbyby
||list.video.baidu.com/adbyby
||nsclick.baidu.com/adbyby
||play.baidu.com/adbyby
||sclick.baidu.com/adbyby
||tieba.baidu.com/adbyby
||baidustatic.com/adbyby
||bdimg.com/adbyby
||bdstatic.com/adbyby
||share.baidu.com/adbyby
||hm.baidu.com/adbyby
!视频广告
||v.baidu.com/adbyby
||1000fr.net/adbyby
||56.com/adbyby
||v-56.com/adbyby
||acfun.com/adbyby
||acfun.tv/adbyby
||baofeng.com/adbyby
||baofeng.net/adbyby
||cntv.cn/adbyby
||hoopchina.com.cn/adbyby
||funshion.com/adbyby
||fun.tv/adbyby
||hitvs.cn/adbyby
||hljtv.com/adbyby
||iqiyi.com/adbyby
||qiyi.com/adbyby
||agn.aty.sohu.com/adbyby
||itc.cn/adbyby
||kankan.com/adbyby
||ku6.com/adbyby
||letv.com/adbyby
||letvcloud.com/adbyby
||letvimg.com/adbyby
||pplive.cn/adbyby
||pps.tv/adbyby
||ppsimg.com/adbyby
||pptv.com/adbyby
||v.qq.com/adbyby
||l.qq.com/adbyby
||video.sina.com.cn/adbyby
||tudou.com/adbyby
||wasu.cn/adbyby
||analytics-union.xunlei.com/adbyby
||kankan.xunlei.com/adbyby
||youku.com/adbyby
||hunantv.com/adbyby
||zimuzu.tv/adbyby_list
! 参考以上规则格式添加指定过滤网址

EEE
	chmod 755 "$adbyby_rules_script"
fi

}

initconfig

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
	#adbyby_check
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
	checka="/tmp/var/lazy.txt"
	rm -f /tmp/var/lazy.txt
	urla="https://opt.cn2qq.com/opt-file/lazy.txt"
	urla1="https://raw.githubusercontent.com/adbyby/xwhyc-rules/master/lazy.txt"
	urla2="https://coding.net/u/adbyby/p/xwhyc-rules/git/raw/master/lazy.txt"
	checkb="/tmp/bin/data/lazy.txt"
	wgetcurl.sh $checka $urla $urla1 N 100
	[ ! -s $checka ] && wgetcurl.sh $checka $urla $urla2 N 100
	if [ "`md5sum $checka|cut -d" " -f1`" != "`md5sum $checkb|cut -d" " -f1`" ] ; then
		logger -t "【Adbyby】" "更新检查:lazy 有更新 $urla , 重启进程"
		adbyby_restart
	else
		logger -t "【Adbyby】" "更新检查:lazy 不需更新 $urla "
		checka="/tmp/var/video.txt"
		rm -f /tmp/var/video.txt
		urla="https://opt.cn2qq.com/opt-file/video.txt"
		urla1="https://raw.githubusercontent.com/adbyby/xwhyc-rules/master/video.txt"
		urla2="https://coding.net/u/adbyby/p/xwhyc-rules/git/raw/master/video.txt"
		checkb="/tmp/bin/data/video.txt"
		wgetcurl.sh $checka $urla $urla1 N 5
		[ ! -s $checka ] && wgetcurl.sh $checka $urla $urla2 N 5
		if [ "`md5sum $checka|cut -d" " -f1`" != "`md5sum $checkb|cut -d" " -f1`" ] ; then
			logger -t "【Adbyby】" "更新检查:video 有更新 $urla , 重启进程"
			adbyby_restart
		else
			logger -t "【Adbyby】" "更新检查:video 不需更新 $urla "
		fi
	fi
	;;
update_ad)
	adbyby_mount
	rm -rf /tmp/bin/*
	adbyby_restart o
	adbyby_restart
	;;
*)
	adbyby_check
	;;
esac

