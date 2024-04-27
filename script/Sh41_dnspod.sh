#!/bin/bash
#copyright by hiboy
source /etc/storage/script/init.sh
dnspod_enable=`nvram get dnspod_enable`
[ -z $dnspod_enable ] && dnspod_enable=0 && nvram set dnspod_enable=0
if [ "$dnspod_enable" != "0" ] ; then

dnspod_username=`nvram get dnspod_username`
dnspod_password=`nvram get dnspod_password`
dnspod_Token=`nvram get dnspod_Token`
dnspod_domian=`nvram get dnspod_domian`
dnspod_host=`nvram get dnspod_host`
dnspod_domian2=`nvram get dnspod_domian2`
dnspod_host2=`nvram get dnspod_host2`
dnspod_domian6=`nvram get dnspod_domian6`
dnspod_host6=`nvram get dnspod_host6`
dnspod_interval=`nvram get dnspod_interval`

if [ "$dnspod_domian"x != "x" ] && [ "$dnspod_host"x = "x" ] ; then
	dnspod_host="www"
	nvram set dnspod_host="www"
fi
if [ "$dnspod_domian2"x != "x" ] && [ "$dnspod_host2"x = "x" ] ; then
	dnspod_host2="www"
	nvram set dnspod_host2="www"
fi
if [ "$dnspod_domian6"x != "x" ] && [ "$dnspod_host6"x = "x" ] ; then
	dnspod_host6="www"
	nvram set dnspod_host6="www"
fi

IPv6=0
domain_type=""
post_type=""
hostIP=""
myIP=""
[ -z $dnspod_interval ] && dnspod_interval=600 && nvram set dnspod_interval=$dnspod_interval
fi

if [ ! -z "$(echo $scriptfilepath | grep -v "/tmp/script/" | grep dnspod)" ] && [ ! -s /tmp/script/_dnspod ] ; then
	mkdir -p /tmp/script
	{ echo '#!/bin/bash' ; echo $scriptfilepath '"$@"' '&' ; } > /tmp/script/_dnspod
	chmod 777 /tmp/script/_dnspod
fi

dnspod_get_status () {

B_restart="$dnspod_enable$dnspod_username$dnspod_password$dnspod_Token$dnspod_domian$dnspod_host$dnspod_domian2$dnspod_host2$dnspod_domian6$dnspod_host6$dnspod_interval$(cat /etc/storage/ddns_script.sh | grep -v '^#' | grep -v '^$')"

i_app_get_status -name="dnspod" -valb="$B_restart"
}

dnspod_check () {

dnspod_get_status
if [ "$dnspod_enable" != "1" ] && [ "$needed_restart" = "1" ] ; then
	[ ! -z "$(ps -w | grep "$scriptname keep" | grep -v grep )" ] && logger -t "【DNSPod动态域名】" "停止 dnspod" && dnspod_close
	{ kill_ps "$scriptname" exit0; exit 0; }
fi
if [ "$dnspod_enable" = "1" ] ; then
[ "x$dnspod_Token" = "x" ] && [ "x$dnspod_username" = "x" ] && [ "x$dnspod_password" = "x" ] && { logger -t "【DNSPod动态域名】" "用户名密码或者 Token 等设置未填写, 10 秒后自动尝试重新启动" && sleep 10; nvram set dnspod_status=00; eval "$scriptfilepath &"; exit 0; }
	if [ "$needed_restart" = "1" ] ; then
		dnspod_close
		eval "$scriptfilepath keep &"
		exit 0
	else
		[ -z "$(ps -w | grep "$scriptname keep" | grep -v grep )" ] && nvram set dnspod_status=00 && { eval "$scriptfilepath start &"; exit 0; }
	fi
fi
}

dnspod_keep () {
dnspod_start
i_app_keep -name="dnspod" -pidof="Sh41_dnspod.sh" &
while true; do
sleep 41
sleep $dnspod_interval
dnspod_enable=`nvram get dnspod_enable`
[ "$dnspod_enable" = "0" ] && dnspod_close && exit 0;
if [ "$dnspod_enable" = "1" ] ; then
	dnspod_start
fi
done
}

dnspod_close () {
sed -Ei '/【dnspod】|^$/d' /tmp/script/_opt_script_check
kill_ps "$scriptname keep"
kill_ps "/tmp/script/_dnspod"
kill_ps "_dnspod.sh"
kill_ps "$scriptname"
}

dnspod_start () {
check_webui_yes
IPv6=0
if [ "$dnspod_domian"x != "x" ] && [ "$dnspod_host"x != "x" ] ; then
	DOMAIN="$dnspod_domian"
	HOST="$dnspod_host"
	domainID=""
	recordID=""
	recordIP=""
	arDdnsCheck $dnspod_domian $dnspod_host
fi
if [ "$dnspod_domian2"x != "x" ] && [ "$dnspod_host2"x != "x" ] ; then
	sleep 1
	DOMAIN="$dnspod_domian2"
	HOST="$dnspod_host2"
	domainID=""
	recordID=""
	recordIP=""
	arDdnsCheck $dnspod_domian2 $dnspod_host2
fi
if [ "$dnspod_domian6"x != "x" ] && [ "$dnspod_host6"x != "x" ] ; then
	sleep 1
	IPv6=1
	DOMAIN="$dnspod_domian6"
	HOST="$dnspod_host6"
	domainID=""
	recordID=""
	recordIP=""
	arDdnsCheck $dnspod_domian6 $dnspod_host6
fi

source /etc/storage/ddns_script.sh
while read line
do
	line=`echo $line | cut -d '#' -f1`
	line=$(echo $line)
	[ -z "$line" ] && continue
	sleep 1
	IPv6=1
	IPv6_neighbor=1
	domainID=""
	recordID=""
	recordIP=""
	HOST="$(echo "$line" | cut -d '@' -f1)"
	DOMAIN="$(echo "$line" | cut -d '@' -f2)"
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
	[ ! -z "$inet6_neighbor" ] && arDdnsCheck $DOMAIN $HOST
	IPv6_neighbor=0
done < /tmp/ip6_ddns_inf

}

arDdnsInfo() {
	#local domainID recordID recordIP
	if [ "$IPv6" = "1" ] ; then
		domain_type="AAAA"
		post_type="Record.Modify"
	else
		domain_type="A"
		post_type="Record.Ddns"
	fi
	# 获得域名ID
	domainID=$(arApiPost "Domain.Info" "domain=$DOMAIN")
	domainID=$(echo $domainID | grep -Eo '"id":"[0-9]+"' | cut -d':' -f2 | tr -d '"')
	
	# 获得记录ID
	recordID=$(arApiPost "Record.List" "domain_id=$domainID&sub_domain=$HOST")
	recordID=$(echo $recordID | grep -Eo '"records".+' | sed -e "s/"'"remark":'"/"' \n '"/g" | grep '"type":"'$domain_type'"' | grep -Eo '"id":"[0-9]+"' | cut -d':' -f2 | tr -d '"' |head -n1)
	
	# 获得最后更新IP
	recordIP=$(arApiPost "Record.Info" "domain_id=$domainID&record_id=$recordID")
	recordIP=$(echo $recordIP | grep -Eo '"value":"[^"]*"' | awk -F ':"' '{print $2}' | tr -d '"' |head -n1)

	# Output IP
	if [ "$IPv6" = "1" ] ; then
	echo $recordIP
	return 0
	else
	case "$recordIP" in 
	[1-9]*)
		echo $recordIP
		return 0
		;;
	*)
		domainID=""
		recordID=""
		recordIP=""
		echo "Get Record Info Failed!"
		#logger -t "【DNSPod动态域名】" "获取记录信息失败！"
		return 1
		;;
	esac
	fi
}

# 读取接口数据
# 参数: 接口类型 待提交数据
arApiPost() {
	agent="AnripDdns/5.07(mail@anrip.com)"
	inter="https://dnsapi.cn/${1:?'Info.Version'}"
	if [ "x$dnspod_Token" = "x" ] ; then # undefine token
		param="login_email=$dnspod_username&login_password=$dnspod_password&format=json&$2"
	else
		param="login_token=$dnspod_Token&format=json&$2"
	fi
	
	
	curltest=`which curl`
	if [ -z "$curltest" ] || [ ! -s "`which curl`" ] ; then
		wget -T 5 -t 3 --quiet --output-document=- --post-data $param $inter
	else
		curl -L    -X POST $inter -d $param
	fi
	sleep 1
}

# 更新记录信息
# 参数: 主域名 子域名
arDdnsUpdate() {
	#local domainID recordID recordRS recordCD recordIP
I=3
recordID=""
	if [ "$IPv6" = "1" ] ; then
		domain_type="AAAA"
		post_type="Record.Modify"
	else
		domain_type="A"
		post_type="Record.Ddns"
	fi
while [ -z "$recordID" ] ; do
	I=$(($I - 1))
	[ $I -lt 0 ] && break
	# 获得域名ID
	domainID=$(arApiPost "Domain.Info" "domain=$DOMAIN")
	domainID=$(echo $domainID  | grep -Eo '"id":"[0-9]+"' | cut -d':' -f2 | tr -d '"')
	sleep 1
	# 获得记录ID
	recordID=$(arApiPost "Record.List" "domain_id=$domainID&sub_domain=$HOST")
	recordID=$(echo $recordID | grep -Eo '"records".+' | sed -e "s/"'"remark":'"/"' \n '"/g" | grep '"type":"'$domain_type'"' | grep -Eo '"id":"[0-9]+"' | cut -d':' -f2 | tr -d '"' |head -n1)
done
	#echo "更新记录信息 recordID: " $recordID
	if [ -z "$recordID" ] ; then
		# 添加子域名记录IP
		myIP=$hostIP
		logger -t "【DNSPod动态域名】" "添加子域名 $HOST 记录IP: $myIP"
		recordRS=$(arApiPost "Record.Create" "domain_id=$domainID&sub_domain=$HOST&record_type=$domain_type&value=$myIP&record_line=默认")
	else
		# 更新记录IP
		myIP=$hostIP
		recordRS=$(arApiPost "$post_type" "domain_id=$domainID&record_id=$recordID&sub_domain=$HOST&record_type=$domain_type&value=$myIP&record_line=默认")
	fi
	recordCD=$(echo $recordRS | grep -Eo '"code":"[0-9]+"' | cut -d':' -f2 | tr -d '"')
	recordIP=$(echo $recordRS | grep -Eo '"value":"[^"]*"' | awk -F ':"' '{print $2}' | tr -d '"')
	# 输出记录IP
	if [ -z "$recordIP" ] ; then
		sleep 10
		# 获得记录ID
		recordID=$(arApiPost "Record.List" "domain_id=$domainID&sub_domain=$HOST")
		recordID=$(echo $recordID | grep -Eo '"records".+' | sed -e "s/"'"remark":'"/"' \n '"/g" | grep '"type":"'$domain_type'"' | grep -Eo '"id":"[0-9]+"' | cut -d':' -f2 | tr -d '"' |head -n1)
		
		# 获得最后更新IP
		recordIP=$(arApiPost "Record.Info" "domain_id=$domainID&record_id=$recordID")
		recordIP=$(echo $recordIP | grep -Eo '"value":"[^"]*"' | awk -F ':"' '{print $2}' | tr -d '"' |head -n1)
	fi
	if [ "$recordIP" = "$myIP" ] ; then
		if [ "$recordCD" = "1" ] ; then
			echo $recordIP
			logger -t "【DNSPod动态域名】" "`echo $recordRS | grep -Eo '"message":"[^"]*"' | cut -d':' -f2 | tr -d '"'`"
			return 0
		fi
		# 输出错误信息
		echo $recordRS | grep -Eo '"message":"[^"]*"' | cut -d':' -f2 | tr -d '"'
		logger -t "【DNSPod动态域名】" "`echo $recordRS | grep -Eo '"message":"[^"]*"' | cut -d':' -f2 | tr -d '"'`"
		return 1
	fi
	# 输出错误信息
	echo "Update Failed! Please check your network."
	logger -t "【DNSPod动态域名】" "`echo $recordRS | grep -Eo '"message":"[^"]*"' | cut -d':' -f2 | tr -d '"'`"
	return 1
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
		logger -t "【DNSPod动态域名】" "错误！$hostIP 获取目前 IPv6 失败，请在脚本更换其他获取地址，保证取得IPv6地址(例如:ff03:0:0:0:0:0:0:c1)"
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
			logger -t "【DNSPod动态域名】" "错误！获取目前 IP 失败，请在脚本更换其他获取地址"
			return 1
		fi
	fi
	echo "Updating Domain: $HOST.$DOMAIN"
	echo "hostIP: $hostIP"
	lastIP=$(arDdnsInfo "$DOMAIN" "$HOST")
	if [ $? -eq 1 ] ; then
		[ "$IPv6" != "1" ] && lastIP=$(arNslookup "$HOST.$DOMAIN")
		[ "$IPv6" = "1" ] && lastIP=$(arNslookup6 "$HOST.$DOMAIN")
	fi
	echo "lastIP: $lastIP"
	if [ "$lastIP" != "$hostIP" ] ; then
		logger -t "【DNSPod动态域名】" "开始更新 $HOST.$DOMAIN 域名 IP 指向"
		logger -t "【DNSPod动态域名】" "目前 IP: $hostIP"
		logger -t "【DNSPod动态域名】" "上次 IP: $lastIP"
		domainID=""
		recordID=""
		recordIP=""
		sleep 1
		postRS=$(arDdnsUpdate "$DOMAIN" "$HOST")
		if [ $? -eq 0 ] ; then
			echo "postRS: $postRS"
			logger -t "【DNSPod动态域名】" "更新动态DNS记录成功！提交的IP: $postRS"
			return 0
		else
			echo $postRS
			logger -t "【DNSPod动态域名】" "更新动态DNS记录失败！请检查您的网络。提交的IP: $postRS"
			if [ "$IPv6" = "1" ] ; then 
				IPv6=0
				logger -t "【DNSPod动态域名】" "错误！$hostIP 获取目前 IPv6 失败，请在脚本更换其他获取地址，保证取得IPv6地址(例如:ff03:0:0:0:0:0:0:c1)"
				return 1
			fi
			return 1
		fi
	fi
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
	dnspod_close
	dnspod_check
	;;
check)
	dnspod_check
	;;
stop)
	dnspod_close
	;;
keep)
	dnspod_keep
	;;
*)
	dnspod_check
	;;
esac

