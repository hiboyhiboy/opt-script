#!/bin/bash
#copyright by hiboy
source /etc/storage/script/init.sh
aliddns_enable=`nvram get aliddns_enable`
[ -z $aliddns_enable ] && aliddns_enable=0 && nvram set aliddns_enable=0
if [ "$aliddns_enable" != "0" ] ; then

aliddns_interval=`nvram get aliddns_interval`
aliddns_ak=`nvram get aliddns_ak`
aliddns_sk=`nvram get aliddns_sk`
aliddns_domain=`nvram get aliddns_domain`
aliddns_name=`nvram get aliddns_name`
aliddns_domain2=`nvram get aliddns_domain2`
aliddns_name2=`nvram get aliddns_name2`
aliddns_domain6=`nvram get aliddns_domain6`
aliddns_name6=`nvram get aliddns_name6`
aliddns_ttl=`nvram get aliddns_ttl`

if [ "$aliddns_domain"x != "x" ] && [ "$aliddns_name"x = "x" ] ; then
	aliddns_name="www"
	nvram set aliddns_name="www"
fi
if [ "$aliddns_domain2"x != "x" ] && [ "$aliddns_name2"x = "x" ] ; then
	aliddns_name2="www"
	nvram set aliddns_name2="www"
fi
if [ "$aliddns_domain6"x != "x" ] && [ "$aliddns_name6"x = "x" ] ; then
	aliddns_name6="www"
	nvram set aliddns_name6="www"
fi

IPv6=0
domain_type=""
hostIP=""
domain=""
name=""
name1=""
timestamp=`date -u "+%Y-%m-%dT%H%%3A%M%%3A%SZ"`
aliddns_record_id=""
[ -z $aliddns_interval ] && aliddns_interval=600 && nvram set aliddns_interval=$aliddns_interval
[ -z $aliddns_ttl ] && aliddns_ttl=600 && nvram set aliddns_ttl=$aliddns_ttl
aliddns_renum=`nvram get aliddns_renum`

fi

if [ ! -z "$(echo $scriptfilepath | grep -v "/tmp/script/" | grep aliddns)" ] && [ ! -s /tmp/script/_aliddns ] ; then
	mkdir -p /tmp/script
	{ echo '#!/bin/bash' ; echo $scriptfilepath '"$@"' '&' ; } > /tmp/script/_aliddns
	chmod 777 /tmp/script/_aliddns
fi

aliddns_restart () {
i_app_restart "$@" -name="aliddns"
}

aliddns_get_status () {

B_restart="$aliddns_enable$aliddns_interval$aliddns_ak$aliddns_sk$aliddns_domain$aliddns_name$aliddns_domain2$aliddns_name2$aliddns_domain6$aliddns_name6$aliddns_ttl$(cat /etc/storage/ddns_script.sh | grep -v '^#' | grep -v '^$')"

i_app_get_status -name="aliddns" -valb="$B_restart"
}

aliddns_check () {

aliddns_get_status
if [ "$aliddns_enable" != "1" ] && [ "$needed_restart" = "1" ] ; then
	[ ! -z "$(ps -w | grep "$scriptname keep" | grep -v grep )" ] && logger -t "【aliddns动态域名】" "停止 aliddns" && aliddns_close
	{ kill_ps "$scriptname" exit0; exit 0; }
fi
if [ "$aliddns_enable" = "1" ] ; then
	if [ "$needed_restart" = "1" ] ; then
		aliddns_close
		eval "$scriptfilepath keep &"
		exit 0
	else
		[ -z "$(ps -w | grep "$scriptname keep" | grep -v grep )" ] || [ ! -s "`which curl`" ] && aliddns_restart
	fi
fi
}

aliddns_keep () {
aliddns_start
i_app_keep -name="aliddns" -pidof="Sh42_aliddns.sh" &
while true; do
sleep 43
sleep $aliddns_interval
[ ! -s "`which curl`" ] && aliddns_restart
aliddns_enable=`nvram get aliddns_enable`
[ "$aliddns_enable" = "0" ] && aliddns_close && exit 0;
if [ "$aliddns_enable" = "1" ] ; then
	aliddns_start
fi
done
}

aliddns_close () {
sed -Ei '/【aliddns】|^$/d' /tmp/script/_opt_script_check
kill_ps "$scriptname keep"
kill_ps "/tmp/script/_aliddns"
kill_ps "_aliddns.sh"
kill_ps "$scriptname"
}

aliddns_start () {
check_webui_yes
curltest=`which curl`
if [ -z "$curltest" ] || [ ! -s "`which curl`" ] ; then
	logger -t "【AliDDNS动态域名】" "找不到 curl ，安装 opt mini 程序"
	/etc/storage/script/Sh01_mountopt.sh opt_mini_wget
	initopt
	curltest=`which curl`
	if [ -z "$curltest" ] || [ ! -s "`which curl`" ] ; then
		logger -t "【AliDDNS动态域名】" "找不到 curl ，需要手动安装 opt 后输入[opkg update; opkg install curl]安装"
		logger -t "【AliDDNS动态域名】" "启动失败, 10 秒后自动尝试重新启动" && sleep 10 && aliddns_restart x
	else
		aliddns_restart o
	fi
fi
IPv6=0
if [ "$aliddns_domain"x != "x" ] && [ "$aliddns_name"x != "x" ] ; then
	timestamp=`date -u "+%Y-%m-%dT%H%%3A%M%%3A%SZ"`
	aliddns_record_id=""
	domain="$aliddns_domain"
	name="$aliddns_name"
	arDdnsCheck $aliddns_domain $aliddns_name
fi
if [ "$aliddns_domain2"x != "x" ] && [ "$aliddns_name2"x != "x" ] ; then
	sleep 1
	timestamp=`date -u "+%Y-%m-%dT%H%%3A%M%%3A%SZ"`
	aliddns_record_id=""
	domain="$aliddns_domain2"
	name="$aliddns_name2"
	arDdnsCheck $aliddns_domain2 $aliddns_name2
fi
if [ "$aliddns_domain6"x != "x" ] && [ "$aliddns_name6"x != "x" ] ; then
	sleep 1
	IPv6=1
	timestamp=`date -u "+%Y-%m-%dT%H%%3A%M%%3A%SZ"`
	aliddns_record_id=""
	domain="$aliddns_domain6"
	name="$aliddns_name6"
	arDdnsCheck $aliddns_domain6 $aliddns_name6
fi

source /etc/storage/ddns_script.sh
while read line
do
	line=`echo $line | cut -d '#' -f1`
	line=$(echo $line)
	[ -z "$line" ] && continue
	sleep 1
	IPv6=1
	timestamp=`date -u "+%Y-%m-%dT%H%%3A%M%%3A%SZ"`
	IPv6_neighbor=1
	aliddns_record_id=""
	name="$(echo "$line" | cut -d '@' -f1)"
	domain="$(echo "$line" | cut -d '@' -f2)"
	inf_MAC="$(echo "$line" | cut -d '@' -f3 | tr 'A-Z' 'a-z')"
	inf_match="$(echo "$line" | cut -d '@' -f4)"
	inf_v_match="$(echo "$line" | cut -d '@' -f5)"
	[ -z "$inf_v_match" ] && inf_v_match="inf_v_match"
	inet6_neighbor="$(echo "$line" | cut -d '@' -f6)"
	inet6_neighbor=$(echo $inet6_neighbor)
	if [ -z "$inet6_neighbor" ] ; then
		ip6_neighbor_get
		inet6_neighbor="$(cat /tmp/ip6_neighbor.log | grep "$inf_MAC" | grep -v "$inf_v_match" | grep "$inf_match" | awk -F ' ' '{print $1}' | sed -n '$p')"
	fi
	[ ! -z "$inet6_neighbor" ] && arDdnsCheck $domain $name
	IPv6_neighbor=0
done < /tmp/ip6_ddns_inf

}

urlencode() {
	# urlencode <string>
	out=""
	read S
	for i in $(seq 0 $(($(echo -n "$S" |awk -F "" '{print NF}') - 1)) )
	do
		c="${S:$i:1}"
		case "$c" in
			[-_.~a-zA-Z0-9]) out="$out$c" ;;
			*) out="$out`printf '%%%02X' "'$c"`" ;;
		esac
	done
	echo -n $out
}

enc() {
	echo -n "$1" | urlencode
}

send_request() {
	args="AccessKeyId=$aliddns_ak&Action=$1&Format=json&$2&Version=2015-01-09"
	hash=$(echo -n "GET&%2F&$(enc "$args")" | openssl dgst -sha1 -hmac "$aliddns_sk&" -binary | openssl base64)
	curl -L    -s "http://alidns.aliyuncs.com/?$args&Signature=$(enc "$hash")"
	sleep 1
}

get_recordid() {
	grep -Eo '"RecordId":"[0-9]+"' | cut -d':' -f2 | tr -d '"' |head -n1
}

get_recordIP() {
	sed -e "s/"'"TTL":'"/"' \n '"/g" | grep '"Type":"'$domain_type'"' | grep -Eo '"Value":"[^"]*"' | awk -F 'Value":"' '{print $2}' | tr -d '"' |head -n1
}

query_recordInfo() {
	send_request "DescribeDomainRecordInfo" "RecordId=$1&SignatureMethod=HMAC-SHA1&SignatureNonce=$timestamp&SignatureVersion=1.0&Timestamp=$timestamp"
}

query_recordid() {
	send_request "DescribeSubDomainRecords" "SignatureMethod=HMAC-SHA1&SignatureNonce=$timestamp&SignatureVersion=1.0&SubDomain=$name1.$domain&Timestamp=$timestamp&Type=$domain_type"
}

update_record() {
	hostIP_tmp=$(enc "$hostIP")
	send_request "UpdateDomainRecord" "RR=$name1&RecordId=$1&SignatureMethod=HMAC-SHA1&SignatureNonce=$timestamp&SignatureVersion=1.0&TTL=$aliddns_ttl&Timestamp=$timestamp&Type=$domain_type&Value=$hostIP_tmp"
}

add_record() {
	hostIP_tmp=$(enc "$hostIP")
	send_request "AddDomainRecord&DomainName=$domain" "RR=$name1&SignatureMethod=HMAC-SHA1&SignatureNonce=$timestamp&SignatureVersion=1.0&TTL=$aliddns_ttl&Timestamp=$timestamp&Type=$domain_type&Value=$hostIP_tmp"
}

arDdnsInfo() {
case  $name  in
	  \*)
		name1=%2A
		;;
	  \@)
		name1=%40
		;;
	  *)
		name1=$name
		;;
esac

	if [ "$IPv6" = "1" ] ; then
		domain_type="AAAA"
	else
		domain_type="A"
	fi
	timestamp=`date -u "+%Y-%m-%dT%H%%3A%M%%3A%SZ"`
	# 获得域名ID
	aliddns_record_id=""
	aliddns_record_id=`query_recordid | get_recordid`
	sleep 1
	timestamp=`date -u "+%Y-%m-%dT%H%%3A%M%%3A%SZ"`
	# 获得最后更新IP
	recordIP=`query_recordInfo $aliddns_record_id | get_recordIP`
	
	if [ "$IPv6" = "1" ] ; then
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
		aliddns_record_id=""
		echo "Get Record Info Failed!"
		#logger -t "【AliDDNS动态域名】" "获取记录信息失败！"
		return 1
		;;
	esac
	fi
}

# 更新记录信息
# 参数: 主域名 子域名
arDdnsUpdate() {
case  $name  in
	  \*)
		name1=%2A
		;;
	  \@)
		name1=%40
		;;
	  *)
		name1=$name
		;;
esac
	if [ "$IPv6" = "1" ] ; then
		domain_type="AAAA"
	else
		domain_type="A"
	fi
I=3
aliddns_record_id=""
while [ -z "$aliddns_record_id" ] ; do
	I=$(($I - 1))
	[ $I -lt 0 ] && break
	# 获得记录ID
	timestamp=`date -u "+%Y-%m-%dT%H%%3A%M%%3A%SZ"`
	aliddns_record_id=`query_recordid | get_recordid`
	echo "recordID $aliddns_record_id"
	sleep 1
done
	timestamp=`date -u "+%Y-%m-%dT%H%%3A%M%%3A%SZ"`
if [ -z "$aliddns_record_id" ] ; then
	aliddns_record_id=`add_record | get_recordid`
	echo "added record $aliddns_record_id"
	logger -t "【AliDDNS动态域名】" "添加的记录  $aliddns_record_id"
else
	update_record $aliddns_record_id
	echo "updated record $aliddns_record_id"
	logger -t "【AliDDNS动态域名】" "更新的记录  $aliddns_record_id"
fi
# save to file
if [ -z "$aliddns_record_id" ] ; then
	# failed
	nvram set aliddns_last_act="`date "+%Y-%m-%d %H:%M:%S"`   更新失败"
	logger -t "【AliDDNS动态域名】" "更新失败"
	return 1
else
	nvram set aliddns_record_id="$aliddns_record_id"
	nvram set aliddns_last_act="`date "+%Y-%m-%d %H:%M:%S"`   成功更新：$hostIP"
	logger -t "【AliDDNS动态域名】" "成功更新： $hostIP"
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
		logger -t "【AliDDNS动态域名】" "错误！$hostIP 获取目前 IPv6 失败，请在脚本更换其他获取地址，保证取得IPv6地址(例如:ff03:0:0:0:0:0:0:c1)"
		return 1
	fi
	if [ "$hostIP"x = "x"  ] ; then
		curltest=`which curl`
		if [ -z "$curltest" ] || [ ! -s "`which curl`" ] ; then
			[ "$hostIP"x = "x"  ] && hostIP=`wget -T 5 -t 3 --user-agent "$user_agent" --quiet --output-document=- "http://members.3322.org/dyndns/getip" | grep -E -o '([0-9]+\.){3}[0-9]+' | head -n1 | cut -d' ' -f1`
			[ "$hostIP"x = "x"  ] && hostIP=`wget -T 5 -t 3 --user-agent "$user_agent" --quiet --output-document=- "ip.3322.net" | grep -E -o '([0-9]+\.){3}[0-9]+' | head -n1 | cut -d' ' -f1`
			[ "$hostIP"x = "x"  ] && hostIP=`wget -T 5 -t 3 --user-agent "$user_agent" --quiet --output-document=- "http://myip.ipip.net" | grep "当前 IP" | grep -E -o '([0-9]+\.){3}[0-9]+' | head -n1 | cut -d' ' -f1`
			[ "$hostIP"x = "x"  ] && hostIP=`wget -T 5 -t 3 --user-agent "$user_agent" --quiet --output-document=- "http://ddns.oray.com/checkip" | grep -E -o '([0-9]+\.){3}[0-9]+' | head -n1 | cut -d' ' -f1`
		else
			[ "$hostIP"x = "x"  ] && hostIP=`curl -L --user-agent "$user_agent" -s "http://members.3322.org/dyndns/getip" | grep -E -o '([0-9]+\.){3}[0-9]+' | head -n1 | cut -d' ' -f1`
			[ "$hostIP"x = "x"  ] && hostIP=`curl -L --user-agent "$user_agent" -s ip.3322.net | grep -E -o '([0-9]+\.){3}[0-9]+' | head -n1 | cut -d' ' -f1`
			[ "$hostIP"x = "x"  ] && hostIP=`curl -L --user-agent "$user_agent" -s "http://myip.ipip.net" | grep "当前 IP" | grep -E -o '([0-9]+\.){3}[0-9]+' | head -n1 | cut -d' ' -f1`
			[ "$hostIP"x = "x"  ] && hostIP=`curl -L --user-agent "$user_agent" -s http://ddns.oray.com/checkip | grep -E -o '([0-9]+\.){3}[0-9]+' | head -n1 | cut -d' ' -f1`
		fi
		if [ "$hostIP"x = "x"  ] ; then
			logger -t "【AliDDNS动态域名】" "错误！获取目前 IP 失败，请在脚本更换其他获取地址"
			return 1
		fi
	fi
	echo "Updating Domain: $2.$1"
	echo "hostIP: $hostIP"
	lastIP=$(arDdnsInfo "$1 $2")
	if [ $? -eq 1 ] ; then
		[ "$IPv6" != "1" ] && lastIP=$(arNslookup "$2.$1")
		[ "$IPv6" = "1" ] && lastIP=$(arNslookup6 "$2.$1")
	fi
	echo "lastIP: $lastIP"
	if [ "$lastIP" != "$hostIP" ] ; then
		logger -t "【AliDDNS动态域名】" "开始更新 $2.$1 域名 IP 指向"
		logger -t "【AliDDNS动态域名】" "目前 IP: $hostIP"
		logger -t "【AliDDNS动态域名】" "上次 IP: $lastIP"
		aliddns_record_id=""
		sleep 1
		postRS=$(arDdnsUpdate "$1" "$2")
		if [ $? -eq 0 ] ; then
			echo "postRS: $postRS"
			logger -t "【AliDDNS动态域名】" "更新动态DNS记录成功！"
			return 0
		else
			echo $postRS
			logger -t "【AliDDNS动态域名】" "更新动态DNS记录失败！请检查您的网络。"
			if [ "$IPv6" = "1" ] ; then 
				IPv6=0
				logger -t "【AliDDNS动态域名】" "错误！$hostIP 获取目前 IPv6 失败，请在脚本更换其他获取地址，保证取得IPv6地址(例如:ff03:0:0:0:0:0:0:c1)"
				return 1
			fi
			return 1
		fi
	fi
	echo $lastIP
	echo "Last IP is the same as current IP!"
	return 1
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
    #wget -T 5 -t 3 --user-agent "$user_agent" --quiet --output-document=- "https://1.0.0.2/cdn-cgi/trace" | awk -F= '/ip/{print $2}'
    #wget -T 5 -t 3 --user-agent "$user_agent" --quiet --output-document=- "http://myip.ipip.net" | grep "当前 IP" | grep -E -o '([0-9]+\.){3}[0-9]+' | head -n1 | cut -d' ' -f1
    wget -T 5 -t 3 --user-agent "$user_agent" --quiet --output-document=- "http://members.3322.org/dyndns/getip" | grep -E -o '([0-9]+\.){3}[0-9]+' | head -n1 | cut -d' ' -f1
    #wget -T 5 -t 3 --user-agent "$user_agent" --quiet --output-document=- "ip.3322.net" | grep -E -o '([0-9]+\.){3}[0-9]+' | head -n1 | cut -d' ' -f1
    #wget -T 5 -t 3 --user-agent "$user_agent" --quiet --output-document=- "http://ddns.oray.com/checkip" | grep -E -o '([0-9]+\.){3}[0-9]+' | head -n1 | cut -d' ' -f1
else
    #curl -L --user-agent "$user_agent" -s "https://1.0.0.2/cdn-cgi/trace" | awk -F= '/ip/{print $2}'
    #curl -L --user-agent "$user_agent" -s "http://myip.ipip.net" | grep "当前 IP" | grep -E -o '([0-9]+\.){3}[0-9]+' | head -n1 | cut -d' ' -f1
    curl -L --user-agent "$user_agent" -s "http://members.3322.org/dyndns/getip" | grep -E -o '([0-9]+\.){3}[0-9]+' | head -n1 | cut -d' ' -f1
    #curl -L --user-agent "$user_agent" -s ip.3322.net | grep -E -o '([0-9]+\.){3}[0-9]+' | head -n1 | cut -d' ' -f1
    #curl -L --user-agent "$user_agent" -s http://ddns.oray.com/checkip | grep -E -o '([0-9]+\.){3}[0-9]+' | head -n1 | cut -d' ' -f1
fi
}
arIpAddress6 () {
# IPv6地址获取
# 因为一般ipv6没有nat ipv6的获得可以本机获得
ifconfig $(nvram get wan0_ifname_t) | awk '/Global/{print $3}' | awk -F/ '{print $1}'
#curl -6 -L --user-agent "$user_agent" -s "https://[2606:4700:4700::1002]/cdn-cgi/trace" | awk -F= '/ip/{print $2}'
}
if [ "$IPv6_neighbor" != "1" ] ; then
if [ "$IPv6" = "1" ] ; then
arIpAddress=$(arIpAddress6)
else
arIpAddress=$(arIpAddress)
fi
else
arIpAddress=$inet6_neighbor
inet6_neighbor=""
IPv6_neighbor=0
fi

# 根据 ip -f inet6 neighbor show 获取终端的信息，设置 ddns 解析，实现每个终端的 IPV6 动态域名
# 参数说明：使用 @ 符号分割，①前缀名称 ②域名 ③MAC【不限大小写】
# ④匹配关键词的ip6地址【可留空】 ⑤排除关键词的ip6地址【可留空】 ⑥手动指定ip【可留空】 
# 下面是信号填写例子：（删除前面的#可生效）
cat >/tmp/ip6_ddns.inf <<-\EOF
#www@google.com@09:9B:9A:90:9F:D9@@fe80::@  # 参数填写例子



EOF
cat /tmp/ip6_ddns.inf | grep -v '^#'  | grep -v '^$' > /tmp/ip6_ddns_inf
rm -f /tmp/ip6_ddns.inf
EEE
	chmod 755 "$ddns_script"
fi

}

initconfig

case $ACTION in
start)
	aliddns_close
	aliddns_check
	;;
check)
	aliddns_check
	;;
stop)
	aliddns_close
	;;
keep)
	aliddns_keep
	;;
*)
	aliddns_check
	;;
esac

