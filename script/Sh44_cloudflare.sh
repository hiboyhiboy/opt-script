#!/bin/bash
#copyright by hiboy
source /etc/storage/script/init.sh
cloudflare_enable=`nvram get cloudflare_enable`
[ -z $cloudflare_enable ] && cloudflare_enable=0 && nvram set cloudflare_enable=0
if [ "$cloudflare_enable" != "0" ] ; then

cloudflare_token=`nvram get cloudflare_token`
cloudflare_Email=`nvram get cloudflare_Email`
cloudflare_Key=`nvram get cloudflare_Key`
cloudflare_domian=`nvram get cloudflare_domian`
cloudflare_host=`nvram get cloudflare_host`
cloudflare_domian2=`nvram get cloudflare_domian2`
cloudflare_host2=`nvram get cloudflare_host2`
cloudflare_domian6=`nvram get cloudflare_domian6`
cloudflare_host6=`nvram get cloudflare_host6`
cloudflare_interval=`nvram get cloudflare_interval`

if [ ! -z "$cloudflare_token" ] ; then
account_key_1="Authorization: Bearer $cloudflare_token"
account_key_2="-s" # 预留位置，传入可用参数
account_key_a1=" -H "
account_key_a2="-s"
fi
if [ -z "$cloudflare_token" ] && [ ! -z "$cloudflare_Email" ] && [ ! -z "$cloudflare_Key" ] ; then
account_key_1="X-Auth-Email: $cloudflare_Email"
account_key_2="X-Auth-Key: $cloudflare_Key"
account_key_a1=" -H "
account_key_a2=" -H "
fi


if [ "$cloudflare_domian"x != "x" ] && [ "$cloudflare_host"x = "x" ] ; then
	cloudflare_host="www"
	nvram set cloudflare_host="www"
fi
if [ "$cloudflare_domian2"x != "x" ] && [ "$cloudflare_host2"x = "x" ] ; then
	cloudflare_host2="www"
	nvram set cloudflare_host2="www"
fi
if [ "$cloudflare_domian6"x != "x" ] && [ "$cloudflare_host6"x = "x" ] ; then
	cloudflare_host6="www"
	nvram set cloudflare_host6="www"
fi

IPv6=0
domain_type=""
hostIP=""
Zone_ID=""
DOMAIN=""
HOST=""
[ -z $cloudflare_interval ] && cloudflare_interval=600 && nvram set cloudflare_interval=$cloudflare_interval
cloudflare_renum=`nvram get cloudflare_renum`

fi

if [ ! -z "$(echo $scriptfilepath | grep -v "/tmp/script/" | grep cloudflare)" ] && [ ! -s /tmp/script/_cloudflare ] ; then
	mkdir -p /tmp/script
	{ echo '#!/bin/bash' ; echo $scriptfilepath '"$@"' '&' ; } > /tmp/script/_cloudflare
	chmod 777 /tmp/script/_cloudflare
fi

cloudflare_restart () {
i_app_restart "$@" -name="cloudflare"
}

cloudflare_get_status () {

B_restart="$cloudflare_enable$cloudflare_token$cloudflare_Email$cloudflare_Key$cloudflare_domian$cloudflare_host$cloudflare_domian2$cloudflare_host2$cloudflare_domian6$cloudflare_host6$cloudflare_interval$(cat /etc/storage/ddns_script.sh | grep -v '^#' | grep -v '^$')"

i_app_get_status -name="cloudflare" -valb="$B_restart"
}

cloudflare_check () {

cloudflare_get_status
if [ "$cloudflare_enable" != "1" ] && [ "$needed_restart" = "1" ] ; then
	[ ! -z "$(ps -w | grep "$scriptname keep" | grep -v grep )" ] && logger -t "【cloudflare动态域名】" "停止 cloudflare" && cloudflare_close
	{ kill_ps "$scriptname" exit0; exit 0; }
fi
if [ "$cloudflare_enable" = "1" ] ; then
	if [ "$needed_restart" = "1" ] ; then
		cloudflare_close
		sleep 1
		eval "$scriptfilepath keep &"
		exit 0
	else
		[ -z "$(ps -w | grep "$scriptname keep" | grep -v grep )" ] || [ ! -s "`which curl`" ] && cloudflare_restart
	fi
fi
}

cloudflare_keep () {
cloudflare_start
i_app_keep -name="cloudflare" -pidof="Sh44_cloudflare.sh" &
while true; do
sleep 43
sleep $cloudflare_interval
[ ! -s "`which curl`" ] && cloudflare_restart
cloudflare_enable=`nvram get cloudflare_enable`
[ "$cloudflare_enable" = "0" ] && cloudflare_close && exit 0;
if [ "$cloudflare_enable" = "1" ] ; then
	cloudflare_start
fi
done
}

cloudflare_close () {
sed -Ei '/【cloudflare】|^$/d' /tmp/script/_opt_script_check
kill_ps "$scriptname keep"
kill_ps "/tmp/script/_cloudflare"
kill_ps "_cloudflare.sh"
kill_ps "$scriptname"
}

cloudflare_start () {
check_webui_yes
curltest=`which curl`
if [ -z "$curltest" ] || [ ! -s "`which curl`" ] ; then
	logger -t "【cloudflare动态域名】" "找不到 curl ，安装 opt mini 程序"
	/etc/storage/script/Sh01_mountopt.sh opt_mini_wget
	initopt
	curltest=`which curl`
	if [ -z "$curltest" ] || [ ! -s "`which curl`" ] ; then
		logger -t "【cloudflare动态域名】" "找不到 curl ，需要手动安装 opt 后输入[opkg update; opkg install curl]安装"
		logger -t "【cloudflare动态域名】" "启动失败, 10 秒后自动尝试重新启动" && sleep 10 && cloudflare_restart x
	else
		cloudflare_restart o
	fi
fi
IPv6=0
if [ "$cloudflare_domian"x != "x" ] && [ "$cloudflare_host"x != "x" ] ; then
	DOMAIN="$cloudflare_domian"
	HOST="$cloudflare_host"
	RECORD_ID=""
	arDdnsCheck
fi
if [ "$cloudflare_domian2"x != "x" ] && [ "$cloudflare_host2"x != "x" ] ; then
	sleep 1
	DOMAIN="$cloudflare_domian2"
	HOST="$cloudflare_host2"
	RECORD_ID=""
	arDdnsCheck
fi
if [ "$cloudflare_domian6"x != "x" ] && [ "$cloudflare_host6"x != "x" ] ; then
	sleep 1
	IPv6=1
	DOMAIN="$cloudflare_domian6"
	HOST="$cloudflare_host6"
	RECORD_ID=""
	arDdnsCheck
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
	RECORD_ID=""
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

Zone_ID=""
get_Zone_ID() {
# 获得Zone_ID
Zone_ID=$(curl -L    -s -X GET "https://api.cloudflare.com/client/v4/zones" \
     -H "Content-Type: application/json" \
     $account_key_a1 "$account_key_1" \
     $account_key_a2 "$account_key_2")
Zone_ID=$(echo $Zone_ID| sed -e "s/ //g" |grep -o "id\":\"[0-9a-z]*\",\"name\":\"$DOMAIN\",\"status\""|grep -o "id\":\"[0-9a-z]*\""| awk -F : '{print $2}'|grep -o "[a-z0-9]*")
sleep 1

}

arDdnsInfo() {
if [ "$IPv6" = "1" ] ; then
	domain_type="AAAA"
else
	domain_type="A"
fi

case  $HOST  in
	  \*)
		host_domian="\\$HOST.$DOMAIN"
		;;
	  \@)
		host_domian="$DOMAIN"
		;;
	  *)
		host_domian="$HOST.$DOMAIN"
		;;
esac

# 获得Zone_ID
get_Zone_ID
# 获得最后更新IP
recordIP=$(curl -L    -s -X GET "https://api.cloudflare.com/client/v4/zones/$Zone_ID/dns_records?type=$domain_type&match=all" \
     -H "Content-Type: application/json" \
     $account_key_a1 "$account_key_1" \
     $account_key_a2 "$account_key_2")
sleep 1
RECORD_ID=$(echo $recordIP | sed -e "s/ //g" | sed -e "s/"'"ttl":'"/"' \n '"/g" | grep "type\":\"$domain_type\"" | grep ",\"name\":\"$host_domian\"" | grep -o "\"id\":\"[0-9a-z]\{32,\}\",\"" | awk -F : '{print $2}'|grep -o "[a-z0-9]*")
recordIP=$(echo $recordIP | sed -e "s/ //g" | sed -e "s/"'"ttl":'"/"' \n '"/g" | grep "type\":\"$domain_type\"" | grep ",\"name\":\"$host_domian\"" | grep -o ",\"content\":\"[^\"]*\"" | awk -F 'content":"' '{print $2}' | tr -d '"' |head -n1)
# 检查是否有名称重复的子域名
if [ "$(echo "$RECORD_ID" | grep -o "[0-9a-z]\{32,\}"| wc -l)" -gt "1" ] ; then
	logger -t "【cloudflare动态域名】" "$HOST.$DOMAIN 获得最后更新IP时发现重复的子域名！"
	for Delete_RECORD_ID in $RECORD_ID
	do
	logger -t "【cloudflare动态域名】" "$HOST.$DOMAIN 删除名称重复的子域名！ID: $Delete_RECORD_ID"
	RESULT=$(curl -L    -s -X DELETE "https://api.cloudflare.com/client/v4/zones/$Zone_ID/dns_records/$Delete_RECORD_ID" \
     -H "Content-Type: application/json"\
     $account_key_a1 "$account_key_1" \
     $account_key_a2 "$account_key_2" )
	sleep 1
	done
	recordIP="0"
	echo $recordIP
	return 0
fi
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
		echo "Get Record Info Failed!"
		#logger -t "【cloudflare动态域名】" "获取记录信息失败！"
		return 1
		;;
	esac
	fi

}

# 更新记录信息
# 参数: 主域名 子域名
arDdnsUpdate() {
I=3
RECORD_ID=""
if [ "$IPv6" = "1" ] ; then
	domain_type="AAAA"
else
	domain_type="A"
fi

case  $HOST  in
	  \*)
		host_domian="\\$HOST.$DOMAIN"
		;;
	  \@)
		host_domian="$DOMAIN"
		;;
	  *)
		host_domian="$HOST.$DOMAIN"
		;;
esac

while [ -z "$RECORD_ID" ] ; do
	I=$(($I - 1))
	[ $I -lt 0 ] && break
# 获得Zone_ID
get_Zone_ID
# 获得记录ID
RECORD_ID=$(curl -L    -s -X GET "https://api.cloudflare.com/client/v4/zones/$Zone_ID/dns_records?type=$domain_type&match=all" \
     -H "Content-Type: application/json" \
     $account_key_a1 "$account_key_1" \
     $account_key_a2 "$account_key_2")
sleep 1
RECORD_ID=$(echo $RECORD_ID | sed -e "s/ //g" | sed -e "s/"'"ttl":'"/"' \n '"/g" | grep "type\":\"$domain_type\"" | grep ",\"name\":\"$host_domian\"" | grep -o "\"id\":\"[0-9a-z]\{32,\}\",\"" | awk -F : '{print $2}'|grep -o "[a-z0-9]*")
# 检查是否有名称重复的子域名
if [ "$(echo "$RECORD_ID" | grep -o "[0-9a-z]\{32,\}"| wc -l)" -gt "1" ] ; then
	logger -t "【cloudflare动态域名】" "$HOST.$DOMAIN 更新记录信息时发现重复的子域名！"
	for Delete_RECORD_ID in $RECORD_ID
	do
	logger -t "【cloudflare动态域名】" "$HOST.$DOMAIN 删除名称重复的子域名！ID: $Delete_RECORD_ID"
	RESULT=$(curl -L    -s -X DELETE "https://api.cloudflare.com/client/v4/zones/$Zone_ID/dns_records/$Delete_RECORD_ID" \
     -H "Content-Type: application/json" \
     $account_key_a1 "$account_key_1" \
     $account_key_a2 "$account_key_2")
	sleep 1
	done
	RECORD_ID=""
fi
#echo "RECORD ID: $RECORD_ID"
sleep 1
done
if [ -z "$RECORD_ID" ] ; then
	# 添加子域名记录IP
	RESULT=$(curl -L    -s -X POST "https://api.cloudflare.com/client/v4/zones/$Zone_ID/dns_records" \
     -H "Content-Type: application/json" \
     $account_key_a1 "$account_key_1" \
     $account_key_a2 "$account_key_2" \
     --data '{"type":"'$domain_type'","name":"'$HOST'","content":"'$hostIP'","ttl":120,"proxied":false}')
	sleep 1
	RESULT=$(echo $RESULT | sed -e "s/ //g" | grep -o "success\":[a-z]*,"|awk -F : '{print $2}'|grep -o "[a-z]*")
	echo "创建dns_records: $RESULT"
else
	# 更新记录IP
	RESULT=$(curl -L    -s -X PUT "https://api.cloudflare.com/client/v4/zones/$Zone_ID/dns_records/$RECORD_ID" \
     -H "Content-Type: application/json" \
     $account_key_a1 "$account_key_1" \
     $account_key_a2 "$account_key_2" \
     --data '{"type":"'$domain_type'","name":"'$HOST'","content":"'$hostIP'","ttl":120,"proxied":false}')
	sleep 1
	RESULT=$(echo $RESULT | sed -e "s/ //g" | grep -o "success\":[a-z]*,"|awk -F : '{print $2}'|grep -o "[a-z]*")
	echo "更新dns_records: $RESULT"
fi
if [ "$(printf "%s" "$RESULT"|grep -c -o "true")" = 1 ];then
	echo "$(date) -- Update success"
	return 0
else
	echo "$(date) -- Update failed"
	return 1
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
		logger -t "【cloudflare动态域名】" "错误！$hostIP 获取目前 IPv6 失败，请在脚本更换其他获取地址，保证取得IPv6地址(例如:ff03:0:0:0:0:0:0:c1)"
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
			logger -t "【cloudflare动态域名】" "错误！获取目前 IP 失败，请在脚本更换其他获取地址"
			return 1
		fi
	fi
	echo "Updating Domain: $HOST.$DOMAIN"
	echo "hostIP: $hostIP"
	lastIP=$(arDdnsInfo)
	if [ $? -eq 1 ] ; then
		[ "$IPv6" != "1" ] && lastIP=$(arNslookup "$HOST.$DOMAIN")
		[ "$IPv6" = "1" ] && lastIP=$(arNslookup6 "$HOST.$DOMAIN")
	fi
	echo "lastIP: $lastIP"
	if [ "$lastIP" != "$hostIP" ] ; then
		logger -t "【cloudflare动态域名】" "开始更新 "$HOST.$DOMAIN" 域名 IP 指向"
		logger -t "【cloudflare动态域名】" "目前 IP: $hostIP"
		logger -t "【cloudflare动态域名】" "上次 IP: $lastIP"
		sleep 1
		postRS=$(arDdnsUpdate)
		if [ $? -eq 0 ] ; then
			echo "postRS: $postRS"
			logger -t "【cloudflare动态域名】" "更新动态DNS记录成功！"
			return 0
		else
			echo $postRS
			logger -t "【cloudflare动态域名】" "更新动态DNS记录失败！请检查您的网络。"
			if [ "$IPv6" = "1" ] ; then 
				IPv6=0
				logger -t "【cloudflare动态域名】" "错误！$hostIP 获取目前 IPv6 失败，请在脚本更换其他获取地址，保证取得IPv6地址(例如:ff03:0:0:0:0:0:0:c1)"
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
	cloudflare_close
	cloudflare_check
	;;
check)
	cloudflare_check
	;;
stop)
	cloudflare_close
	;;
keep)
	cloudflare_keep
	;;
*)
	cloudflare_check
	;;
esac

