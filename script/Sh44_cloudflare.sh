#!/bin/sh
#copyright by hiboy
source /etc/storage/script/init.sh
cloudflare_enable=`nvram get cloudflare_enable`
[ -z $cloudflare_enable ] && cloudflare_enable=0 && nvram set cloudflare_enable=0
if [ "$cloudflare_enable" != "0" ] ; then
#nvramshow=`nvram showall | grep '=' | grep cloudflare | awk '{print gensub(/'"'"'/,"'"'"'\"'"'"'\"'"'"'","g",$0);}'| awk '{print gensub(/=/,"='\''",1,$0)"'\'';";}'` && eval $nvramshow

cloudflare_Email=`nvram get cloudflare_Email`
cloudflare_Key=`nvram get cloudflare_Key`
cloudflare_domian=`nvram get cloudflare_domian`
cloudflare_host=`nvram get cloudflare_host`
cloudflare_domian2=`nvram get cloudflare_domian2`
cloudflare_host2=`nvram get cloudflare_host2`
cloudflare_domian6=`nvram get cloudflare_domian6`
cloudflare_host6=`nvram get cloudflare_host6`
cloudflare_interval=`nvram get cloudflare_interval`

IPv6=0
domain_type=""
hostIP=""
Zone_ID=""
[ -z $cloudflare_interval ] && cloudflare_interval=120 && nvram set cloudflare_interval=$cloudflare_interval
fi

if [ ! -z "$(echo $scriptfilepath | grep -v "/tmp/script/" | grep cloudflare)" ]  && [ ! -s /tmp/script/_cloudflare ]; then
	mkdir -p /tmp/script
	{ echo '#!/bin/sh' ; echo $scriptfilepath '"$@"' '&' ; } > /tmp/script/_cloudflare
	chmod 777 /tmp/script/_cloudflare
fi

cloudflare_restart () {

relock="/var/lock/cloudflare_restart.lock"
if [ "$1" = "o" ] ; then
	nvram set cloudflare_renum="0"
	[ -f $relock ] && rm -f $relock
	return 0
fi
if [ "$1" = "x" ] ; then
	if [ -f $relock ] ; then
		logger -t "【cloudflare】" "多次尝试启动失败，等待【"`cat $relock`"分钟】后自动尝试重新启动"
		exit 0
	fi
	cloudflare_renum=${cloudflare_renum:-"0"}
	cloudflare_renum=`expr $cloudflare_renum + 1`
	nvram set cloudflare_renum="$cloudflare_renum"
	if [ "$cloudflare_renum" -gt "2" ] ; then
		I=19
		echo $I > $relock
		logger -t "【cloudflare】" "多次尝试启动失败，等待【"`cat $relock`"分钟】后自动尝试重新启动"
		while [ $I -gt 0 ]; do
			I=$(($I - 1))
			echo $I > $relock
			sleep 60
			[ "$(nvram get cloudflare_renum)" = "0" ] && exit 0
			[ $I -lt 0 ] && break
		done
		nvram set cloudflare_renum="0"
	fi
	[ -f $relock ] && rm -f $relock
fi
nvram set cloudflare_status=0
eval "$scriptfilepath &"
exit 0
}

cloudflare_get_status () {

A_restart=`nvram get cloudflare_status`
B_restart="$cloudflare_enable$cloudflare_Email$cloudflare_Key$cloudflare_domian$cloudflare_host$cloudflare_domian2$cloudflare_host2$cloudflare_domian6$cloudflare_host6$cloudflare_interval$(cat /etc/storage/ddns_script.sh | grep -v '^#' | grep -v "^$")"
B_restart=`echo -n "$B_restart" | md5sum | sed s/[[:space:]]//g | sed s/-//g`
if [ "$A_restart" != "$B_restart" ] ; then
	nvram set cloudflare_status=$B_restart
	needed_restart=1
else
	needed_restart=0
fi
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
		eval "$scriptfilepath keep &"
		exit 0
	else
		[ -z "$(ps -w | grep "$scriptname keep" | grep -v grep )" ] || [ ! -s "`which curl`" ] && cloudflare_restart
	fi
fi
}

cloudflare_keep () {
cloudflare_start
logger -t "【cloudflare动态域名】" "守护进程启动"
while true; do
sleep 43
sleep $cloudflare_interval
[ ! -s "`which curl`" ] && cloudflare_restart
#nvramshow=`nvram showall | grep '=' | grep cloudflare | awk '{print gensub(/'"'"'/,"'"'"'\"'"'"'\"'"'"'","g",$0);}'| awk '{print gensub(/=/,"='\''",1,$0)"'\'';";}'` && eval $nvramshow
cloudflare_enable=`nvram get cloudflare_enable`
[ "$cloudflare_enable" = "0" ] && cloudflare_close && exit 0;
if [ "$cloudflare_enable" = "1" ] ; then
	cloudflare_start
fi
done
}

cloudflare_close () {

kill_ps "/tmp/script/_cloudflare"
kill_ps "_cloudflare.sh"
kill_ps "$scriptname"
}

cloudflare_start () {
curltest=`which curl`
if [ -z "$curltest" ] || [ ! -s "`which curl`" ] ; then
	logger -t "【cloudflare动态域名】" "找不到 curl ，安装 opt 程序"
	/tmp/script/_mountopt optwget
	#initopt
	curltest=`which curl`
	if [ -z "$curltest" ] || [ ! -s "`which curl`" ] ; then
		logger -t "【cloudflare动态域名】" "找不到 curl ，需要手动安装 opt 后输入[opkg install curl]安装"
		logger -t "【cloudflare动态域名】" "启动失败, 10 秒后自动尝试重新启动" && sleep 10 && cloudflare_restart x
	else
		cloudflare_restart o
	fi
fi
IPv6=0
if [ "$cloudflare_domian"x != "x" ] ; then
	arDdnsCheck $cloudflare_domian $cloudflare_host
fi
if [ "$cloudflare_domian2"x != "x" ] ; then
	sleep 1
	arDdnsCheck $cloudflare_domian2 $cloudflare_host2
fi
if [ "$cloudflare_domian6"x != "x" ] ; then
	sleep 1
	IPv6=1
	arDdnsCheck $cloudflare_domian6 $cloudflare_host6
fi
}

Zone_ID=""
get_Zone_ID() {
host_tmp=$1
# 获得Zone_ID
Zone_ID=$(curl -k -s -X GET "https://api.cloudflare.com/client/v4/zones" \
     -H "X-Auth-Email: $cloudflare_Email" \
     -H "X-Auth-Key: $cloudflare_Key" \
     -H "Content-Type: application/json")
Zone_ID=$(echo $Zone_ID|grep -o "id\":\"[0-9a-z]*\",\"name\":\"$host_tmp\",\"status\""|grep -o "id\":\"[0-9a-z]*\""| awk -F : '{print $2}'|grep -o "[a-z0-9]*")

}

arDdnsInfo() {
host_tmp=$1
domian_tmp=$2
# 获得Zone_ID
get_Zone_ID $host_tmp
# 获得最后更新IP
recordIP=$(curl -k -s -X GET "https://api.cloudflare.com/client/v4/zones/$Zone_ID/dns_records" \
     -H "X-Auth-Email: $cloudflare_Email" \
     -H "X-Auth-Key: $cloudflare_Key" \
     -H "Content-Type: application/json")
recordIP=$(echo $recordIP|grep -o "name\":\"$domian_tmp.$host_tmp\",\"content\":\"[^\"]*\""| awk -F 'content":"' '{print $2}' | tr -d '"')
	if [ "$IPv6" = "1" ]; then
	echo $recordIP
	return 0
	else
	case "$recordIP" in 
	[1-9][0-9]*)
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

# 查询域名地址
# 参数: 待查询域名
arNslookup() {
	curltest=`which curl`
	if [ -z "$curltest" ] || [ ! -s "`which curl`" ] ; then
		Address="`wget --no-check-certificate --quiet --output-document=- http://119.29.29.29/d?dn=$1`"
		if [ $? -eq 0 ]; then
		echo "$Address" |  sed s/\;/"\n"/g | sed -n '1p' | grep -E -o '([0-9]+\.){3}[0-9]+'
		fi
	else
		Address="`curl -k http://119.29.29.29/d?dn=$1`"
		if [ $? -eq 0 ]; then
		echo "$Address" |  sed s/\;/"\n"/g | sed -n '1p' | grep -E -o '([0-9]+\.){3}[0-9]+'
		fi
	fi
}

# 更新记录信息
# 参数: 主域名 子域名
arDdnsUpdate() {
host_tmp=$1
domian_tmp=$2
# 获得Zone_ID
get_Zone_ID $host_tmp
# 获得记录ID
RECORD_ID=$(curl -k -s -X GET "https://api.cloudflare.com/client/v4/zones/$Zone_ID/dns_records" \
     -H "X-Auth-Email: $cloudflare_Email" \
     -H "X-Auth-Key: $cloudflare_Key" \
     -H "Content-Type: application/json")
RECORD_ID=$(echo $RECORD_ID|grep -o "id\":\"[0-9a-z]\{32,\}\",\"type\":\"[A-z]\{1,\}\",\"name\":\"$domian_tmp.$host_tmp\",\"content\":\""|grep -o "id\":\"[0-9a-z]\{32,\}\",\""| awk -F : '{print $2}'|grep -o "[a-z0-9]*")
echo "RECORD ID: $RECORD_ID"
if [ "$IPv6" = "1" ]; then
	domain_type="AAAA"
else
	domain_type="A"
fi
if [ "$RECORD_ID" = "" ] ; then
	# 添加子域名记录IP
	RESULT=$(curl -k -s -X POST "https://api.cloudflare.com/client/v4/zones/$Zone_ID/dns_records" \
     -H "X-Auth-Email: $cloudflare_Email" \
     -H "X-Auth-Key: $cloudflare_Key" \
     -H "Content-Type: application/json" \
     --data '{"type":"'$domain_type'","name":"'$domian_tmp'","content":"'$hostIP'","ttl":120,"proxied":false}')
	RESULT=$(echo $RESULT | grep -o "success\":[a-z]*,"|awk -F : '{print $2}'|grep -o "[a-z]*")
	echo "创建dns_records: $RESULT"
else
	# 更新记录IP
	RESULT=$(curl -k -s -X PUT "https://api.cloudflare.com/client/v4/zones/$Zone_ID/dns_records/$RECORD_ID" \
     -H "X-Auth-Email: $cloudflare_Email" \
     -H "X-Auth-Key: $cloudflare_Key" \
     -H "Content-Type: application/json" \
     --data '{"type":"'$domain_type'","name":"'$domian_tmp'","content":"'$hostIP'","ttl":120,"proxied":false}')
	RESULT=$(echo $RESULT | grep -o "success\":[a-z]*,"|awk -F : '{print $2}'|grep -o "[a-z]*")
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
	local postRS
	local lastIP
	source /etc/storage/ddns_script.sh
	hostIP=$arIpAddress
	if [ -z $(echo "$hostIP" | grep : | grep -v "\.") ] && [ "$IPv6" = "1" ] ; then 
		IPv6=0
		logger -t "【cloudflare动态域名】" "错误！$hostIP 获取目前 IPv6 失败，请在脚本更换其他获取地址，保证取得IPv6地址(例如:ff03:0:0:0:0:0:0:c1)"
		return 1
	fi
	if [ "$hostIP"x = "x"  ] ; then
		curltest=`which curl`
		if [ -z "$curltest" ] || [ ! -s "`which curl`" ] ; then
			hostIP=`wget --no-check-certificate --quiet --output-document=- "http://www.ipip.net" | grep "您当前的IP：" | grep -E -o '([0-9]+\.){3}[0-9]+'`
		else
			hostIP=`curl -L -k -s "http://www.ipip.net" | grep "您当前的IP：" | grep -E -o '([0-9]+\.){3}[0-9]+'`
		fi
		if [ "$hostIP"x = "x"  ] ; then
			logger -t "【cloudflare动态域名】" "错误！获取目前 IP 失败，请在脚本更换其他获取地址"
			return 1
		fi
	fi
	echo "Updating Domain: ${2}.${1}"
	echo "hostIP: ${hostIP}"
	lastIP=$(arDdnsInfo "$1" "$2")
	if [ $? -eq 1 ]; then
		lastIP=$(arNslookup "${2}.${1}")
	fi
	echo "lastIP: ${lastIP}"
	if [ "$lastIP" != "$hostIP" ] ; then
		logger -t "【cloudflare动态域名】" "开始更新 ${2}.${1} 域名 IP 指向"
		logger -t "【cloudflare动态域名】" "目前 IP: ${hostIP}"
		logger -t "【cloudflare动态域名】" "上次 IP: ${lastIP}"
		sleep 1
		postRS=$(arDdnsUpdate $1 $2)
		if [ $? -eq 0 ]; then
			echo "postRS: ${postRS}"
			logger -t "【cloudflare动态域名】" "更新动态DNS记录成功！"
			return 0
		else
			echo ${postRS}
			logger -t "【cloudflare动态域名】" "更新动态DNS记录失败！请检查您的网络。"
			if [ "$IPv6" = "1" ] ; then 
				IPv6=0
				logger -t "【cloudflare动态域名】" "错误！$hostIP 获取目前 IPv6 失败，请在脚本更换其他获取地址，保证取得IPv6地址(例如:ff03:0:0:0:0:0:0:c1)"
				return 1
			fi
			return 1
		fi
	fi
	echo ${lastIP}
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
    wget --no-check-certificate --quiet --output-document=- "https://www.ipip.net" | grep "您当前的IP：" | grep -E -o '([0-9]+\.){3}[0-9]+'
    #wget --no-check-certificate --quiet --output-document=- "http://members.3322.org/dyndns/getip" | grep -E -o '([0-9]+\.){3}[0-9]+'
    #wget --no-check-certificate --quiet --output-document=- "ip.6655.com/ip.aspx" | grep -E -o '([0-9]+\.){3}[0-9]+'
    #wget --no-check-certificate --quiet --output-document=- "ip.3322.net" | grep -E -o '([0-9]+\.){3}[0-9]+'
else
    curl -L -k -s "https://www.ipip.net" | grep "您当前的IP：" | grep -E -o '([0-9]+\.){3}[0-9]+'
    #curl -k -s "http://members.3322.org/dyndns/getip" | grep -E -o '([0-9]+\.){3}[0-9]+'
    #curl -k -s ip.6655.com/ip.aspx | grep -E -o '([0-9]+\.){3}[0-9]+'
    #curl -k -s ip.3322.net | grep -E -o '([0-9]+\.){3}[0-9]+'
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

