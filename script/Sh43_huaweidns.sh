#!/bin/bash
#copyright by hiboy
source /etc/storage/script/init.sh
huaweidns_enable=`nvram get huaweidns_enable`
[ -z $huaweidns_enable ] && huaweidns_enable=0 && nvram set huaweidns_enable=0
if [ "$huaweidns_enable" != "0" ] ; then

huaweidns_username=`nvram get huaweidns_username`
huaweidns_password=`nvram get huaweidns_password`
huaweidns_domian=`nvram get huaweidns_domian`
huaweidns_host=`nvram get huaweidns_host`
huaweidns_domian2=`nvram get huaweidns_domian2`
huaweidns_host2=`nvram get huaweidns_host2`
huaweidns_domian6=`nvram get huaweidns_domian6`
huaweidns_host6=`nvram get huaweidns_host6`
huaweidns_interval=`nvram get huaweidns_interval`

if [ "$huaweidns_domian"x != "x" ] && [ "$huaweidns_host"x = "x" ] ; then
	huaweidns_host="www"
	nvram set huaweidns_host="www"
fi
if [ "$huaweidns_domian2"x != "x" ] && [ "$huaweidns_host2"x = "x" ] ; then
	huaweidns_host2="www"
	nvram set huaweidns_host2="www"
fi
if [ "$huaweidns_domian6"x != "x" ] && [ "$huaweidns_host6"x = "x" ] ; then
	huaweidns_host6="www"
	nvram set huaweidns_host6="www"
fi

IPv6=0
domain_type=""
hostIP=""
IP=""
API_KEY="$huaweidns_username"
SECRET_KEY="$huaweidns_password"
DOMAIN="$huaweidns_domian"
HOST="$huaweidns_host"
[ -z $huaweidns_interval ] && huaweidns_interval=300 && nvram set huaweidns_interval=$huaweidns_interval
huaweidns_renum=`nvram get huaweidns_renum`

fi

if [ ! -z "$(echo $scriptfilepath | grep -v "/tmp/script/" | grep huaweidns)" ] && [ ! -s /tmp/script/_huaweidns ] ; then
	mkdir -p /tmp/script
	{ echo '#!/bin/bash' ; echo $scriptfilepath '"$@"' '&' ; } > /tmp/script/_huaweidns
	chmod 777 /tmp/script/_huaweidns
fi

huaweidns_restart () {
i_app_restart "$@" -name="huaweidns"
}

huaweidns_get_status () {

B_restart="$huaweidns_enable$huaweidns_username$huaweidns_password$huaweidns_domian$huaweidns_host$huaweidns_domian2$huaweidns_host2huaweidns_domian6$huaweidns_host6$huaweidns_interval$(cat /etc/storage/ddns_script.sh | grep -v '^#' | grep -v '^$')"

i_app_get_status -name="huaweidns" -valb="$B_restart"
}

huaweidns_check () {

huaweidns_get_status
if [ "$huaweidns_enable" != "1" ] && [ "$needed_restart" = "1" ] ; then
	[ ! -z "$(ps -w | grep "$scriptname keep" | grep -v grep )" ] && logger -t "【huaweidns动态域名】" "停止 huaweidns" && huaweidns_close
	{ kill_ps "$scriptname" exit0; exit 0; }
fi
if [ "$huaweidns_enable" = "1" ] ; then
	if [ "$needed_restart" = "1" ] ; then
		huaweidns_close
		eval "$scriptfilepath keep &"
		exit 0
	else
		[ -z "$(ps -w | grep "$scriptname keep" | grep -v grep )" ] || [ ! -s "`which curl`" ] && huaweidns_restart
	fi
fi
}

huaweidns_keep () {
get_token
get_Zone_ID
huaweidns_start
i_app_keep -name="huaweidns" -pidof="Sh43_huaweidns.sh" &
expires_time=1
while true; do
sleep 43
sleep $huaweidns_interval
expires_time=$(($expires_time + $huaweidns_interval +43))
[ $expires_time -gt 80000 ] && { expires_time=1; get_token;}
[ ! -s "`which curl`" ] && huaweidns_restart
huaweidns_enable=`nvram get huaweidns_enable`
[ "$huaweidns_enable" = "0" ] && huaweidns_close && exit 0;
if [ "$huaweidns_enable" = "1" ] ; then
	huaweidns_start
fi

done
}

huaweidns_close () {
sed -Ei '/【huaweidns】|^$/d' /tmp/script/_opt_script_check
kill_ps "$scriptname keep"
kill_ps "/tmp/script/_huaweidns"
kill_ps "_huaweidns.sh"
kill_ps "$scriptname"
}

huaweidns_start () {
check_webui_yes
curltest=`which curl`
if [ -z "$curltest" ] || [ ! -s "`which curl`" ] ; then
	logger -t "【huaweidns动态域名】" "找不到 curl ，安装 opt mini 程序"
	/etc/storage/script/Sh01_mountopt.sh opt_mini_wget
	initopt
	curltest=`which curl`
	if [ -z "$curltest" ] || [ ! -s "`which curl`" ] ; then
		logger -t "【huaweidns动态域名】" "找不到 curl ，需要手动安装 opt 后输入[opkg update; opkg install curl]安装"
		logger -t "【huaweidns动态域名】" "启动失败, 10 秒后自动尝试重新启动" && sleep 10 && huaweidns_restart x
	else
		huaweidns_restart o
	fi
fi

IPv6=0
if [ "$huaweidns_domian"x != "x" ] && [ "$huaweidns_host"x != "x" ] ; then
	DOMAIN="$huaweidns_domian"
	HOST="$huaweidns_host"
	Record_ID=""
	arDdnsCheck $huaweidns_domian $huaweidns_host
fi
if [ "$huaweidns_domian2"x != "x" ] && [ "$huaweidns_host2"x != "x" ] ; then
	sleep 1
	DOMAIN="$huaweidns_domian2"
	HOST="$huaweidns_host2"
	Record_ID=""
	arDdnsCheck $huaweidns_domian2 $huaweidns_host2
fi
if [ "$huaweidns_domian6"x != "x" ] && [ "$huaweidns_host6"x != "x" ] ; then
	sleep 1
	IPv6=1
	DOMAIN="$huaweidns_domian6"
	HOST="$huaweidns_host6"
	Record_ID=""
	arDdnsCheck $huaweidns_domian6 $huaweidns_host6
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

token=""
get_token() {

versions="$(curl -L    -s -X  GET \
"https://apiexplorer.cn-north-1.myhuaweicloud.com/v1/mock/DNS/ShowApiInfo?status_code=200&number=1&region_id=cn-north-1" \
  -H 'content-type: application/json' \
   | grep -Eo '"id":"[^"]*"' | awk -F 'id":"' '{print $2}' | tr -d '"' |head -n1)"
[ "$versions" != "v2" ] && logger -t "【huaweidns动态域名】" "错误！API的版本不是【v2】，请更新脚本后尝试重新启动" && sleep 10 && huaweidns_restart x
sleep 1
eval 'token_X="$(curl -L    -s -D - -o /dev/null  -X POST \
  https://iam.myhuaweicloud.com/v3/auth/tokens \
  -H '"'"'content-type: application/json'"'"' \
  -d '"'"'{
    "auth": {
        "identity": {
            "methods": ["password"],
            "password": {
                "user": {
                    "name": "'$huaweidns_username'",
                    "password": "'$huaweidns_password'",
                    "domain": {
                        "name": "'$huaweidns_username'"
                    }
                }
            }
        },
        "scope": {
            "project": {
                "name": "cn-north-1"
            }
        }
    }
  }'"'"'| grep X-Subject-Token)"'
token="$(echo $token_X | awk -F ' ' '{print $2}')"
[ -z "$token" ] && logger -t "【huaweidns动态域名】" "错误！【token】获取失败，请检查用户名或密码后尝试重新启动" && sleep 10 && huaweidns_restart x
sleep 1

}

Zone_ID=""
get_Zone_ID() {
# 获得Zone_ID
Zone_ID="$(curl -L    -s -X GET \
  https://dns.myhuaweicloud.com/v2/zones?name=$DOMAIN. \
  -H 'content-type: application/json' \
  -H 'X-Auth-Token: '$token)"
Zone_ID="$(echo $Zone_ID|grep -Eo "\"id\":\"[0-9a-z]*\",\"name\":\"$DOMAIN.\",\"description\""|grep -o "id\":\"[0-9a-z]*\""| awk -F : '{print $2}'|grep -o "[a-z0-9]*")"
[ -z "$Zone_ID" ] && logger -t "【huaweidns动态域名】" "错误！【Zone_ID】获取失败，请到华为云DNS手动创建公网域名后尝试重新启动" && sleep 10 && huaweidns_restart x
sleep 1

}

arDdnsInfo() {
case  $HOST  in
	  \*)
		HOST2="\\*"
		;;
	  \@)
		HOST2="@"
		;;
	  *)
		HOST2="$HOST"
		;;
esac

	if [ "$IPv6" = "1" ] ; then
		domain_type="AAAA"
	else
		domain_type="A"
	fi
	Record_re="$(curl -L    -s -X GET \
      https://dns.myhuaweicloud.com/v2/recordsets?name=$HOST2.$DOMAIN.\&type=$domain_type \
      -H 'content-type: application/json' \
      -H 'X-Auth-Token: '$token)"
	sleep 1
	Record_ID="$(echo $Record_re|grep -o "\"id\":\"[0-9a-z]*\",\"name\":\"$HOST2.$DOMAIN.\",\"description\""|grep -o "id\":\"[0-9a-z]*\""| awk -F : '{print $2}'|grep -o "[a-z0-9]*")"
	# 检查是否有名称重复的子域名
	if [ "$(echo "$Record_ID" | grep -o "[0-9a-z]\{32,\}"| wc -l)" -gt "1" ] ; then
		logger -t "【huaweidns动态域名】" "$HOST.$DOMAIN 更新记录信息时发现重复的子域名！"
        for Delete_RECORD_ID in $Record_ID
        do
        logger -t "【huaweidns动态域名】" "$HOST.$DOMAIN 删除名称重复的子域名！ID: $Delete_RECORD_ID"
        RRecord_re="$(curl -L    -s -X DELETE \
          https://dns.myhuaweicloud.com/v2/zones/$Zone_ID/recordsets/$Delete_RECORD_ID \
          -H 'content-type: application/json' \
          -H 'X-Auth-Token: '$token)"
        sleep 1
        done
		Record_IP="0"
		echo $Record_IP
		return 0
	fi
	Record_IP="$(echo $Record_re |grep -Eo "\"records\":\[\"[^\"]+" | tr -d '"' | awk -F [ '{print $2}' |head -n1)"
	# Output IP
	if [ "$IPv6" = "1" ] ; then
	echo $Record_IP
	return 0
	else
	case "$Record_IP" in 
	[1-9]*)
		echo $Record_IP
		return 0
		;;
	*)
		Record_ID=""
		echo "Get Record Info Failed!"
		#logger -t "【huaweidns动态域名】" "获取记录信息失败！"
		return 1
		;;
	esac
	fi
}

# 更新记录信息
# 参数: 主域名 子域名
arDdnsUpdate() {
case  $HOST  in
	  \*)
		HOST2="\\*"
		;;
	  \@)
		HOST2="@"
		;;
	  *)
		HOST2="$HOST"
		;;
esac
	if [ "$IPv6" = "1" ] ; then
		domain_type="AAAA"
	else
		domain_type="A"
	fi
I=3
Record_ID=""
while [ -z "$Record_ID" ] ; do
    I=$(($I - 1))
    [ $I -lt 0 ] && break    # 获得记录ID
    Record_re="$(curl -L    -s -X GET \
      https://dns.myhuaweicloud.com/v2/recordsets?name=$HOST2.$DOMAIN.\&type=$domain_type \
      -H 'content-type: application/json' \
      -H 'X-Auth-Token: '$token)"
    sleep 1
    Record_ID="$(echo $Record_re|grep -o "\"id\":\"[0-9a-z]*\",\"name\":\"$HOST2.$DOMAIN.\",\"description\""|grep -o "id\":\"[0-9a-z]*\""| awk -F : '{print $2}'|grep -o "[a-z0-9]*")"
    echo "RECORD ID: $Record_ID"
done
    if [ -z "$Record_ID" ] ; then
        # 添加子域名记录IP
        logger -t "【huaweidns动态域名】" "添加子域名 $HOST 记录IP"
        IP=$hostIP
        eval 'RESULT="$(curl -L    -s -X POST \
          https://dns.myhuaweicloud.com/v2/zones/'$Zone_ID'/recordsets \
          -H '"'"'content-type: application/json'"'"' \
          -H '"'"'X-Auth-Token: '$token''"'"' \
          -d '"'"'{
            "name": "'$HOST2'.'$DOMAIN'.",
            "type": "'$domain_type'",
            "ttl": '$huaweidns_interval',
            "records": [
                "'$IP'"
            ]
          }'"'"')"'
        sleep 1
        RESULT="$(echo $RESULT |grep -Eo "\"status\":\"[^\"]+" | tr -d '"' | awk -F : '{print $2}' |head -n1)"
    else
        # 更新记录IP
        IP=$hostIP
        eval 'RESULT="$(curl -L    -s -X PUT \
          https://dns.myhuaweicloud.com/v2/zones/'$Zone_ID'/recordsets/'$Record_ID' \
          -H '"'"'content-type: application/json'"'"' \
          -H '"'"'X-Auth-Token: '$token''"'"' \
          -d '"'"'{
            "name": "'$HOST2'.'$DOMAIN'.",
            "type": "'$domain_type'",
            "ttl": '$huaweidns_interval',
            "records": [
                "'$IP'"
            ]
          }'"'"')"'
        sleep 1
        RESULT="$(echo $RESULT |grep -Eo "\"status\":\"[^\"]+" | tr -d '"' | awk -F : '{print $2}' |head -n1)"
    fi
    echo "$RESULT"

    # 输出记录IP
    if [ "$RESULT" = "PENDING_UPDATE" ];then
        echo "$(date) -- update success"
        return 0
    fi
    if [ "$RESULT" = "PENDING_CREATE" ];then
        echo "$(date) -- create success"
        return 0
    else 
        echo "$(date) -- UPDATE failed"
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
		logger -t "【huaweidns动态域名】" "错误！$hostIP 获取目前 IPv6 失败，请在脚本更换其他获取地址，保证取得IPv6地址(例如:ff03:0:0:0:0:0:0:c1)"
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
			logger -t "【huaweidns动态域名】" "错误！获取目前 IP 失败，请在脚本更换其他获取地址"
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
		logger -t "【huaweidns动态域名】" "开始更新 $HOST.$DOMAIN 域名 IP 指向"
		logger -t "【huaweidns动态域名】" "目前 IP: $hostIP"
		logger -t "【huaweidns动态域名】" "上次 IP: $lastIP"
		Record_ID=""
		sleep 1
		postRS=$(arDdnsUpdate "$DOMAIN" "$HOST")
		if [ $? -eq 0 ] ; then
			echo "postRS: $postRS"
			logger -t "【huaweidns动态域名】" "更新动态DNS记录成功！"
			return 0
		else
			echo $postRS
			logger -t "【huaweidns动态域名】" "更新动态DNS记录失败！请检查您的网络。"
			if [ "$IPv6" = "1" ] ; then 
				IPv6=0
				logger -t "【huaweidns动态域名】" "错误！$hostIP 获取目前 IPv6 失败，请在脚本更换其他获取地址，保证取得IPv6地址(例如:ff03:0:0:0:0:0:0:c1)"
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
	huaweidns_close
	huaweidns_check
	;;
check)
	huaweidns_check
	;;
stop)
	huaweidns_close
	;;
keep)
	huaweidns_keep
	;;
*)
	huaweidns_check
	;;
esac

