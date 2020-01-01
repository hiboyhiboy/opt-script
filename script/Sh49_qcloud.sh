#!/bin/sh
#copyright by hiboy
source /etc/storage/script/init.sh
qcloud_enable=`nvram get qcloud_enable`
[ -z $qcloud_enable ] && qcloud_enable=0 && nvram set qcloud_enable=0
if [ "$qcloud_enable" != "0" ] ; then
#nvramshow=`nvram showall | grep '=' | grep qcloud | awk '{print gensub(/'"'"'/,"'"'"'\"'"'"'\"'"'"'","g",$0);}'| awk '{print gensub(/=/,"='\''",1,$0)"'\'';";}'` && eval $nvramshow

qcloud_interval=`nvram get qcloud_interval`
qcloud_ak=`nvram get qcloud_ak`
qcloud_sk=`nvram get qcloud_sk`
qcloud_domain=`nvram get qcloud_domain`
qcloud_name=`nvram get qcloud_name`
qcloud_domain2=`nvram get qcloud_domain2`
qcloud_name2=`nvram get qcloud_name2`
qcloud_domain6=`nvram get qcloud_domain6`
qcloud_name6=`nvram get qcloud_name6`
qcloud_ttl=`nvram get qcloud_ttl`

if [ "$qcloud_domain"x != "x" ] && [ "$qcloud_name"x = "x" ] ; then
	qcloud_name="www"
	nvram set qcloud_name="www"
fi
if [ "$qcloud_domain2"x != "x" ] && [ "$qcloud_name2"x = "x" ] ; then
	qcloud_name2="www"
	nvram set qcloud_name2="www"
fi
if [ "$qcloud_domain6"x != "x" ] && [ "$qcloud_name6"x = "x" ] ; then
	qcloud_name6="www"
	nvram set qcloud_name6="www"
fi

IPv6=0
domain_type=""
hostIP=""
domain=""
name=""
name1=""
timestamp=`date +%s`
qcloud_record_id=""
[ -z $qcloud_interval ] && qcloud_interval=600 && nvram set qcloud_interval=$qcloud_interval
[ -z $qcloud_ttl ] && qcloud_ttl=600 && nvram set qcloud_ttl=$qcloud_ttl
qcloud_renum=`nvram get qcloud_renum`

fi

if [ ! -z "$(echo $scriptfilepath | grep -v "/tmp/script/" | grep qcloud)" ]  && [ ! -s /tmp/script/_qcloud ]; then
    mkdir -p /tmp/script
    { echo '#!/bin/sh' ; echo $scriptfilepath '"$@"' '&' ; } > /tmp/script/_qcloud
    chmod 777 /tmp/script/_qcloud
fi

qcloud_restart () {

relock="/var/lock/qcloud_restart.lock"
if [ "$1" = "o" ] ; then
	nvram set qcloud_renum="0"
	[ -f $relock ] && rm -f $relock
	return 0
fi
if [ "$1" = "x" ] ; then
	if [ -f $relock ] ; then
		logger -t "【qcloud】" "多次尝试启动失败，等待【"`cat $relock`"分钟】后自动尝试重新启动"
		exit 0
	fi
	qcloud_renum=${qcloud_renum:-"0"}
	qcloud_renum=`expr $qcloud_renum + 1`
	nvram set qcloud_renum="$qcloud_renum"
	if [ "$qcloud_renum" -gt "2" ] ; then
		I=19
		echo $I > $relock
		logger -t "【qcloud】" "多次尝试启动失败，等待【"`cat $relock`"分钟】后自动尝试重新启动"
		while [ $I -gt 0 ]; do
			I=$(($I - 1))
			echo $I > $relock
			sleep 60
			[ "$(nvram get qcloud_renum)" = "0" ] && exit 0
			[ $I -lt 0 ] && break
		done
		nvram set qcloud_renum="0"
	fi
	[ -f $relock ] && rm -f $relock
fi
nvram set qcloud_status=0
eval "$scriptfilepath &"
exit 0
}

qcloud_get_status () {

A_restart=`nvram get qcloud_status`
B_restart="$qcloud_enable$qcloud_interval$qcloud_ak$qcloud_sk$qcloud_domain$qcloud_name$qcloud_domain2$qcloud_name2$qcloud_domain6$qcloud_name6$qcloud_ttl$(cat /etc/storage/ddns_script.sh | grep -v '^#' | grep -v "^$")"
B_restart=`echo -n "$B_restart" | md5sum | sed s/[[:space:]]//g | sed s/-//g`
if [ "$A_restart" != "$B_restart" ] ; then
	nvram set qcloud_status=$B_restart
	needed_restart=1
else
	needed_restart=0
fi
}

qcloud_check () {

qcloud_get_status
if [ "$qcloud_enable" != "1" ] && [ "$needed_restart" = "1" ] ; then
	[ ! -z "$(ps -w | grep "$scriptname keep" | grep -v grep )" ] && logger -t "【qcloud动态域名】" "停止 qcloud" && qcloud_close
	{ kill_ps "$scriptname" exit0; exit 0; }
fi
if [ "$qcloud_enable" = "1" ] ; then
	if [ "$needed_restart" = "1" ] ; then
		qcloud_close
		eval "$scriptfilepath keep &"
		exit 0
	else
		[ -z "$(ps -w | grep "$scriptname keep" | grep -v grep )" ] || [ ! -s "`which curl`" ] && qcloud_restart
	fi
fi
}

qcloud_keep () {
qcloud_start
logger -t "【qcloud动态域名】" "守护进程启动"
while true; do
sleep 43
sleep $qcloud_interval
[ ! -s "`which curl`" ] && qcloud_restart
#nvramshow=`nvram showall | grep '=' | grep qcloud | awk '{print gensub(/'"'"'/,"'"'"'\"'"'"'\"'"'"'","g",$0);}'| awk '{print gensub(/=/,"='\''",1,$0)"'\'';";}'` && eval $nvramshow
qcloud_enable=`nvram get qcloud_enable`
[ "$qcloud_enable" = "0" ] && qcloud_close && exit 0;
if [ "$qcloud_enable" = "1" ] ; then
	qcloud_start
fi
done
}

qcloud_close () {

kill_ps "/tmp/script/_qcloud"
kill_ps "_qcloud.sh"
kill_ps "$scriptname"
}

qcloud_start () {
check_webui_yes
curltest=`which curl`
if [ -z "$curltest" ] || [ ! -s "`which curl`" ] ; then
	logger -t "【qcloud动态域名】" "找不到 curl ，安装 opt 程序"
	/tmp/script/_mountopt optwget
	initopt
	curltest=`which curl`
	if [ -z "$curltest" ] || [ ! -s "`which curl`" ] ; then
		logger -t "【qcloud动态域名】" "找不到 curl ，需要手动安装 opt 后输入[opkg update; opkg install curl]安装"
		logger -t "【qcloud动态域名】" "启动失败, 10 秒后自动尝试重新启动" && sleep 10 && qcloud_restart x
	else
		qcloud_restart o
	fi
fi
IPv6=0
if [ "$qcloud_domain"x != "x" ] && [ "$qcloud_name"x != "x" ] ; then
	timestamp=`date +%s`
	qcloud_record_id=""
	domain="$qcloud_domain"
	name="$qcloud_name"
	arDdnsCheck $qcloud_domain $qcloud_name
fi
if [ "$qcloud_domain2"x != "x" ] && [ "$qcloud_name2"x != "x" ] ; then
	sleep 1
	timestamp=`date +%s`
	qcloud_record_id=""
	domain="$qcloud_domain2"
	name="$qcloud_name2"
	arDdnsCheck $qcloud_domain2 $qcloud_name2
fi
if [ "$qcloud_domain6"x != "x" ] && [ "$qcloud_name6"x != "x" ] ; then
	sleep 1
	IPv6=1
	timestamp=`date +%s`
	qcloud_record_id=""
	domain="$qcloud_domain6"
	name="$qcloud_name6"
	arDdnsCheck $qcloud_domain6 $qcloud_name6
fi

}

urlencode() {
	# urlencode <string>
	out=""
	while read -n1 c
	do
		case $c in
			[a-zA-Z0-9._-]) out="$out$c" ;;
			*) out="$out`printf '%%%02X' "'$c"`" ;;
		esac
	done
	echo -n $out
}

enc() {
	echo -n "$1" | urlencode
}

send_request() {
	random=`cat /proc/sys/kernel/random/uuid | tr -cd "[0-9]"`
	args="Action=$1&Nonce=""`echo ${random:0:5}`""&SecretId=$qcloud_ak&SignatureMethod=HmacSHA1&Timestamp=$timestamp&$2"
	hash=$(echo -n "GETcns.api.qcloud.com/v2/index.php?$args" | openssl dgst -sha1 -hmac "$qcloud_sk" -binary | openssl base64)
	curl -L    -s "https://cns.api.qcloud.com/v2/index.php?$args&Signature=$(enc "$hash")"
	sleep 1
}

get_recordid() {
	grep -Eo '"id":[0-9]+' | cut -d':' -f2 | tr -d '"' |head -n1
}

get_recordIP() {
	grep -Eo '"value":"[^"]*"' | awk -F 'value":"' '{print $2}' | tr -d '"' |head -n1
}

get_codeDesc() {
	grep -Eo '"codeDesc":"[^"]*"' | awk -F 'codeDesc":"' '{print $2}' | tr -d '"' |head -n1
}

query_recordid() {
	send_request "RecordList" "domain=$domain&recordType=$domain_type&subDomain=$name1"
}

update_record() {
	#hostIP_tmp=$(enc "$hostIP")
	hostIP_tmp="$hostIP"
	send_request "RecordModify" "domain=$domain&recordId=$1&recordLine=默认&recordType=$domain_type&subDomain=$name1&ttl=$qcloud_ttl&value=$hostIP_tmp"
}

add_record() {
	#hostIP_tmp=$(enc "$hostIP")
	hostIP_tmp="$hostIP"
	send_request "RecordCreate" "domain=$domain&recordLine=默认&recordType=$domain_type&subDomain=$name1&ttl=$qcloud_ttl&value=$hostIP_tmp"
}

arDdnsInfo() {
name1=$name

	if [ "$IPv6" = "1" ]; then
		domain_type="AAAA"
	else
		domain_type="A"
	fi
	sleep 1
	timestamp=`date +%s`
	# 获得最后更新IP
	recordIP=`query_recordid | get_recordIP`
	
	if [ "$IPv6" = "1" ]; then
	echo $recordIP
	return 0
	else
	# Output IP
	case "$recordIP" in 
	[1-9]*)
		echo $recordIP
		return 0
		;;
	*)
		qcloud_record_id=""
		echo "Get Record Info Failed!"
		#logger -t "【qcloud动态域名】" "获取记录信息失败！"
		return 1
		;;
	esac
	fi
}

# 查询域名地址
# 参数: 待查询域名
arNslookup() {
mkdir -p /tmp/arNslookup
nslookup $1 | tail -n +3 | grep "Address" | awk '{print $3}'| grep -v ":" | sed -n '1p' > /tmp/arNslookup/$$ &
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
		echo "$Address" |  sed s/\;/"\n"/g | sed -n '1p' | grep -E -o '([0-9]+\.){3}[0-9]+'
		fi
	else
		Address="`curl --user-agent "$user_agent" -s http://119.29.29.29/d?dn=$1`"
		if [ $? -eq 0 ]; then
		echo "$Address" |  sed s/\;/"\n"/g | sed -n '1p' | grep -E -o '([0-9]+\.){3}[0-9]+'
		fi
	fi
fi
}

arNslookup6() {
mkdir -p /tmp/arNslookup
nslookup $1 | tail -n +3 | grep "Address" | awk '{print $3}'| grep ":" | sed -n '1p' > /tmp/arNslookup/$$ &
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

# 更新记录信息
# 参数: 主域名 子域名
arDdnsUpdate() {
name1="$name"
	if [ "$IPv6" = "1" ]; then
		domain_type="AAAA"
	else
		domain_type="A"
	fi
I=3
qcloud_record_id=""
while [ "$qcloud_record_id" = "" ] ; do
	I=$(($I - 1))
	[ $I -lt 0 ] && break
	# 获得记录ID
	timestamp=`date +%s`
	qcloud_record_id=`query_recordid | get_recordid`
	echo "recordID $qcloud_record_id"
	sleep 1
done
	timestamp=`date +%s`
if [ "$qcloud_record_id" = "" ] ; then
	qcloud_record_id=`add_record | get_codeDesc`
	echo "added record $qcloud_record_id"
	logger -t "【qcloud动态域名】" "添加的记录  $qcloud_record_id"
else
	qcloud_record_id=`update_record $qcloud_record_id | get_codeDesc`
	echo "updated record $qcloud_record_id"
	logger -t "【qcloud动态域名】" "更新的记录  $qcloud_record_id"
fi
# save to file
if [ "$qcloud_record_id" != "Success" ] ; then
	# failed
	nvram set qcloud_last_act="`date "+%Y-%m-%d %H:%M:%S"`   更新失败"
	logger -t "【qcloud动态域名】" "更新失败"
	return 1
else
	nvram set qcloud_last_act="`date "+%Y-%m-%d %H:%M:%S"`   成功更新：$hostIP"
	logger -t "【qcloud动态域名】" "成功更新： $hostIP"
	return 0
fi

}

# 动态检查更新
# 参数: 主域名 子域名
arDdnsCheck() {
	#local postRS
	#local lastIP
	source /etc/storage/ddns_script.sh
	hostIP=$arIpAddress
	hostIP=`echo $hostIP | head -n1 | cut -d' ' -f1`
	if [ -z $(echo "$hostIP" | grep : | grep -v "\.") ] && [ "$IPv6" = "1" ] ; then 
		IPv6=0
		logger -t "【qcloud动态域名】" "错误！$hostIP 获取目前 IPv6 失败，请在脚本更换其他获取地址，保证取得IPv6地址(例如:ff03:0:0:0:0:0:0:c1)"
		return 1
	fi
	if [ "$hostIP"x = "x"  ] ; then
		curltest=`which curl`
		if [ -z "$curltest" ] || [ ! -s "`which curl`" ] ; then
			[ "$hostIP"x = "x"  ] && hostIP=`wget -T 5 -t 3 --user-agent "$user_agent" --quiet --output-document=- "http://members.3322.org/dyndns/getip" | grep -E -o '([0-9]+\.){3}[0-9]+' | head -n1 | cut -d' ' -f1`
			[ "$hostIP"x = "x"  ] && hostIP=`wget -T 5 -t 3 --user-agent "$user_agent" --quiet --output-document=- "ip.3322.net" | grep -E -o '([0-9]+\.){3}[0-9]+' | head -n1 | cut -d' ' -f1`
			[ "$hostIP"x = "x"  ] && hostIP=`wget -T 5 -t 3 --user-agent "$user_agent" --quiet --output-document=- "https://www.ipip.net/" | grep "IP地址" | grep -E -o '([0-9]+\.){3}[0-9]+' | head -n1 | cut -d' ' -f1`
			[ "$hostIP"x = "x"  ] && hostIP=`wget -T 5 -t 3 --user-agent "$user_agent" --quiet --output-document=- "http://pv.sohu.com/cityjson?ie=utf-8" | grep -E -o '([0-9]+\.){3}[0-9]+' | head -n1 | cut -d' ' -f1`
		else
			[ "$hostIP"x = "x"  ] && hostIP=`curl -L --user-agent "$user_agent" -s "http://members.3322.org/dyndns/getip" | grep -E -o '([0-9]+\.){3}[0-9]+' | head -n1 | cut -d' ' -f1`
			[ "$hostIP"x = "x"  ] && hostIP=`curl -L --user-agent "$user_agent" -s ip.3322.net | grep -E -o '([0-9]+\.){3}[0-9]+' | head -n1 | cut -d' ' -f1`
			[ "$hostIP"x = "x"  ] && hostIP=`curl -L --user-agent "$user_agent" -s "https://www.ipip.net" | grep "IP地址" | grep -E -o '([0-9]+\.){3}[0-9]+' | head -n1 | cut -d' ' -f1`
			[ "$hostIP"x = "x"  ] && hostIP=`curl -L --user-agent "$user_agent" -s http://pv.sohu.com/cityjson?ie=utf-8 | grep -E -o '([0-9]+\.){3}[0-9]+' | head -n1 | cut -d' ' -f1`
		fi
		if [ "$hostIP"x = "x"  ] ; then
			logger -t "【qcloud动态域名】" "错误！获取目前 IP 失败，请在脚本更换其他获取地址"
			return 1
		fi
	fi
	echo "Updating Domain: $name.$domain"
	echo "hostIP: $hostIP"
	lastIP=$(arDdnsInfo)
	if [ $? -eq 1 ]; then
		[ "$IPv6" != "1" ] && lastIP=$(arNslookup "$name.$domain")
		[ "$IPv6" = "1" ] && lastIP=$(arNslookup6 "$name.$domain")
	fi
	echo "lastIP: $lastIP"
	if [ "$lastIP" != "$hostIP" ] ; then
		logger -t "【qcloud动态域名】" "开始更新 $name.$domain 域名 IP 指向"
		logger -t "【qcloud动态域名】" "目前 IP: $hostIP"
		logger -t "【qcloud动态域名】" "上次 IP: $lastIP"
		qcloud_record_id=""
		sleep 1
		postRS=$(arDdnsUpdate)
		if [ $? -eq 0 ]; then
			echo "postRS: $postRS"
			logger -t "【qcloud动态域名】" "更新动态DNS记录成功！"
			return 0
		else
			echo $postRS
			logger -t "【qcloud动态域名】" "更新动态DNS记录失败！请检查您的网络。"
			if [ "$IPv6" = "1" ] ; then 
				IPv6=0
				logger -t "【qcloud动态域名】" "错误！$hostIP 获取目前 IPv6 失败，请在脚本更换其他获取地址，保证取得IPv6地址(例如:ff03:0:0:0:0:0:0:c1)"
				return 1
			fi
			return 1
		fi
	fi
	echo $lastIP
	echo "Last IP is the same as current IP!"
	return 1
}

initopt () {
optPath=`grep ' /opt ' /proc/mounts | grep tmpfs`
[ ! -z "$optPath" ] && return
if [ ! -z "$(echo $scriptfilepath | grep -v "/opt/etc/init")" ] && [ -s "/opt/etc/init.d/rc.func" ] ; then
	{ echo '#!/bin/sh' ; echo $scriptfilepath '"$@"' '&' ; } > /opt/etc/init.d/$scriptname && chmod 777  /opt/etc/init.d/$scriptname
fi

}

initconfig () {

if [ ! -s "/etc/storage/ddns_script.sh" ] ; then
cat > "/etc/storage/ddns_script.sh" <<-\EEE
# 自行测试哪个代码能获取正确的IP，删除前面的#可生效
arIpAddress () {
# IPv4地址获取
# 获得外网地址
curltest=`which curl`
if [ -z "$curltest" ] || [ ! -s "`which curl`" ] ; then
    #wget -T 5 -t 3 --user-agent "$user_agent" --quiet --output-document=- "https://www.ipip.net" | grep "IP地址" | grep -E -o '([0-9]+\.){3}[0-9]+' | head -n1 | cut -d' ' -f1
    wget -T 5 -t 3 --user-agent "$user_agent" --quiet --output-document=- "http://members.3322.org/dyndns/getip" | grep -E -o '([0-9]+\.){3}[0-9]+' | head -n1 | cut -d' ' -f1
    #wget -T 5 -t 3 --user-agent "$user_agent" --quiet --output-document=- "ip.3322.net" | grep -E -o '([0-9]+\.){3}[0-9]+' | head -n1 | cut -d' ' -f1
    #wget -T 5 -t 3 --user-agent "$user_agent" --quiet --output-document=- "http://pv.sohu.com/cityjson?ie=utf-8" | grep -E -o '([0-9]+\.){3}[0-9]+' | head -n1 | cut -d' ' -f1
else
    #curl -L --user-agent "$user_agent" -s "https://www.ipip.net" | grep "IP地址" | grep -E -o '([0-9]+\.){3}[0-9]+' | head -n1 | cut -d' ' -f1
    curl -L --user-agent "$user_agent" -s "http://members.3322.org/dyndns/getip" | grep -E -o '([0-9]+\.){3}[0-9]+' | head -n1 | cut -d' ' -f1
    #curl -L --user-agent "$user_agent" -s ip.3322.net | grep -E -o '([0-9]+\.){3}[0-9]+' | head -n1 | cut -d' ' -f1
    #curl -L --user-agent "$user_agent" -s http://pv.sohu.com/cityjson?ie=utf-8 | grep -E -o '([0-9]+\.){3}[0-9]+' | head -n1 | cut -d' ' -f1
fi
}
arIpAddress6 () {
# IPv6地址获取
# 因为一般ipv6没有nat ipv6的获得可以本机获得
ifconfig $(nvram get wan0_ifname_t) | awk '/Global/{print $3}' | awk -F/ '{print $1}'
}
if [ "$IPv6" = "1" ] ; then
arIpAddress=$(arIpAddress6)
else
arIpAddress=$(arIpAddress)
fi
EEE
    chmod 755 "$ddns_script"
fi

}

initconfig

case $ACTION in
start)
	qcloud_close
	qcloud_check
	;;
check)
	qcloud_check
	;;
stop)
	qcloud_close
	;;
keep)
	qcloud_keep
	;;
*)
	qcloud_check
	;;
esac

