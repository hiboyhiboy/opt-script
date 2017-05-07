#!/bin/sh
#copyright by hiboy
source /etc/storage/script/init.sh
cloudxns_enable=`nvram get cloudxns_enable`
[ -z $cloudxns_enable ] && cloudxns_enable=0 && nvram set cloudxns_enable=0
if [ "$cloudxns_enable" != "0" ] ; then
nvramshow=`nvram showall | grep cloudxns | awk '{print gensub(/'"'"'/,"'"'"'\"'"'"'\"'"'"'","g",$0);}'| awk '{print gensub(/=/,"='\''",1,$0)"'\'';";}'` && eval $nvramshow
hostIP=""
IP=""
API_KEY="$cloudxns_username"
SECRET_KEY="$cloudxns_password"
DOMAIN="$cloudxns_domian"
HOST="$cloudxns_host"
cloudxns_interval=${cloudxns_interval:-"600"}
fi

if [ ! -z "$(echo $scriptfilepath | grep -v "/tmp/script/" | grep cloudxns)" ]  && [ ! -s /tmp/script/_cloudxns ]; then
	mkdir -p /tmp/script
	ln -sf $scriptfilepath /tmp/script/_cloudxns
	chmod 777 /tmp/script/_cloudxns
fi

cloudxns_check () {

A_restart=`nvram get cloudxns_status`
B_restart="$cloudxns_enable$cloudxns_username$cloudxns_password$cloudxns_domian$cloudxns_host$cloudxns_domian2$cloudxns_host2$cloudxns_interval$(cat /etc/storage/ddns_script.sh | grep -v '^#' | grep -v "^$")"
B_restart=`echo -n "$B_restart" | md5sum | sed s/[[:space:]]//g | sed s/-//g`
if [ "$A_restart" != "$B_restart" ] ; then
	nvram set cloudxns_status=$B_restart
	needed_restart=1
else
	needed_restart=0
fi
if [ "$cloudxns_enable" != "1" ] && [ "$needed_restart" = "1" ] ; then
	[ ! -z "$(ps -w | grep "$scriptname keep" | grep -v grep )" ] && logger -t "【CloudXNS动态域名】" "停止 cloudxns" && cloudxns_close
	{ eval $(ps -w | grep "$scriptname" | grep -v grep | awk '{print "kill "$1";";}'); exit 0; }
fi
if [ "$cloudxns_enable" = "1" ] ; then
	if [ "$needed_restart" = "1" ] ; then
		cloudxns_close
		eval "$scriptfilepath keep &"
	else
		[ -z "$(ps -w | grep "$scriptname keep" | grep -v grep )" ] || [ ! -s "`which curl`" ] && nvram set cloudxns_status=00 && { eval "$scriptfilepath start &"; exit 0; }
	fi
fi
}

cloudxns_keep () {
cloudxns_start
logger -t "【CloudXNS动态域名】" "守护进程启动"
while true; do
sleep 43
[ ! -s "`which curl`" ] && nvram set cloudxns_status=00 && { eval "$scriptfilepath start &"; exit 0; }
sleep $cloudxns_interval
nvramshow=`nvram showall | grep cloudxns | awk '{print gensub(/'"'"'/,"'"'"'\"'"'"'\"'"'"'","g",$0);}'| awk '{print gensub(/=/,"='\''",1,$0)"'\'';";}'` && eval $nvramshow
[ "$cloudxns_enable" = "0" ] && cloudxns_close && exit 0;
if [ "$cloudxns_enable" = "1" ] ; then
	cloudxns_start
fi
done
}

cloudxns_close () {

eval $(ps -w | grep "_cloudxns keep" | grep -v grep | awk '{print "kill "$1";";}')
eval $(ps -w | grep "_cloudxns.sh keep" | grep -v grep | awk '{print "kill "$1";";}')
eval $(ps -w | grep "$scriptname keep" | grep -v grep | awk '{print "kill "$1";";}')
}

cloudxns_start () {
curltest=`which curl`
if [ -z "$curltest" ] || [ ! -s "`which curl`" ] ; then
	logger -t "【CloudXNS动态域名】" "找不到 curl ，安装 opt 程序"
	/tmp/script/_mountopt optwget
	#initopt
	curltest=`which curl`
	if [ -z "$curltest" ] || [ ! -s "`which curl`" ] ; then
		logger -t "【CloudXNS动态域名】" "找不到 curl ，需要手动安装 opt 后输入[opkg install curl]安装"
		logger -t "【CloudXNS动态域名】" "启动失败, 10 秒后自动尝试重新启动" && sleep 10 && { nvram set cloudxns_status=00; eval "$scriptfilepath &"; exit 0; }
	fi
fi

DOMAIN="$cloudxns_domian"
HOST="$cloudxns_host"
arDdnsCheck $cloudxns_domian $cloudxns_host
if [ "$cloudxns_domian2"x != "x" ] && [ "$cloudxns_domian2" != "baidu.com" ] ; then
	sleep 1
	DOMAIN="$cloudxns_domian2"
	HOST="$cloudxns_host2"
	arDdnsCheck $cloudxns_domian2 $cloudxns_host2
fi
}

if [ ! -s "/etc/storage/ddns_script.sh" ] ; then
cat > "/etc/storage/ddns_script.sh" <<-\EEE
# 获得外网地址
# 自行测试哪个代码能获取正确的IP，删除前面的#可生效
arIpAddress () {
curltest=`which curl`
if [ -z "$curltest" ] || [ ! -s "`which curl`" ] ; then
wget --no-check-certificate --quiet --output-document=- "http://members.3322.org/dyndns/getip"
#wget --no-check-certificate --quiet --output-document=- "1212.ip138.com/ic.asp" | grep -E -o '([0-9]+\.){3}[0-9]+'
#wget --no-check-certificate --quiet --output-document=- "ip.6655.com/ip.aspx"
#wget --no-check-certificate --quiet --output-document=- "ip.3322.net"
else
curl -k -s "http://members.3322.org/dyndns/getip"
#curl -k -s 1212.ip138.com/ic.asp | grep -E -o '([0-9]+\.){3}[0-9]+'
#curl -k -s ip.6655.com/ip.aspx
#curl -k -s ip.3322.net
fi
}
arIpAddress=$(arIpAddress)
EEE
fi

arDdnsInfo() {
	# 获得域名ID
	URL_D="https://www.cloudxns.net/api2/domain"
	DATE=$(date)
	HMAC_D=$(printf "%s" "$API_KEY$URL_D$DATE$SECRET_KEY"|md5sum|cut -d" " -f1)
	DOMAIN_ID=$(curl -k -s $URL_D -H "API-KEY: $API_KEY" -H "API-REQUEST-DATE: $DATE" -H "API-HMAC: $HMAC_D")
	DOMAIN_ID=$(echo $DOMAIN_ID|grep -o "id\":\"[0-9]*\",\"domain\":\"$DOMAIN"|grep -o "[0-9]*"|head -n1)
	#echo "DOMAIN ID: $DOMAIN_ID"
	# 获得最后更新IP
	URL_R="https://www.cloudxns.net/api2/record/$DOMAIN_ID?host_id=0&row_num=500"
	HMAC_R=$(printf "%s" "$API_KEY$URL_R$DATE$SECRET_KEY"|md5sum|cut -d" " -f1)
	recordIP=$(curl -k -s "$URL_R" -H "API-KEY: $API_KEY" -H "API-REQUEST-DATE: $DATE" -H "API-HMAC: $HMAC_R")
	recordIP=$(echo $recordIP|grep -o "\"host\":\"$HOST\",.*" | awk -F type\":\"A\"  '{print $1}'|grep -o "value\":\"[0-9\.]*"|grep -o "[0-9\.]*")

	#echo "arDdnsInfo recordIP: $recordIP"
	

	# Output IP
	case "$recordIP" in 
	[1-9][0-9]*)
		echo $recordIP
		return 0
		;;
	*)
		echo "Get Record Info Failed!"
		#logger -t "【CloudXNS动态域名】" "获取记录信息失败！"
		return 1
		;;
	esac
}

# 查询域名地址
# 参数: 待查询域名
arNslookup() {
	curltest=`which curl`
	if [ -z "$curltest" ] || [ ! -s "`which curl`" ] ; then
		Address=`wget --continue --no-check-certificate --quiet --output-document=- http://119.29.29.29/d?dn=$1`
		if [ $? -eq 0 ]; then
		echo $Address |  sed s/\;/"\n"/g | sed -n '1p'
		fi
	else
		Address=`curl -k http://119.29.29.29/d?dn=$1`
		if [ $? -eq 0 ]; then
		echo $Address |  sed s/\;/"\n"/g | sed -n '1p'
		fi
	fi
}

# 更新记录信息
# 参数: 主域名 子域名
arDdnsUpdate() {
	# 获得域名ID
	URL_D="https://www.cloudxns.net/api2/domain"
	DATE=$(date)
	HMAC_D=$(printf "%s" "$API_KEY$URL_D$DATE$SECRET_KEY"|md5sum|cut -d" " -f1)
	DOMAIN_ID=$(curl -k -s $URL_D -H "API-KEY: $API_KEY" -H "API-REQUEST-DATE: $DATE" -H "API-HMAC: $HMAC_D")
	DOMAIN_ID=$(echo $DOMAIN_ID|grep -o "id\":\"[0-9]*\",\"domain\":\"$DOMAIN"|grep -o "[0-9]*"|head -n1)
	echo "DOMAIN ID: $DOMAIN_ID"

	# 获得记录ID
	URL_R="https://www.cloudxns.net/api2/record/$DOMAIN_ID?host_id=0&row_num=500"
	HMAC_R=$(printf "%s" "$API_KEY$URL_R$DATE$SECRET_KEY"|md5sum|cut -d" " -f1)
	RECORD_ID=$(curl -k -s "$URL_R" -H "API-KEY: $API_KEY" -H "API-REQUEST-DATE: $DATE" -H "API-HMAC: $HMAC_R")
	RECORD_ID=$(echo $RECORD_ID|grep -o "record_id\":\"[0-9]*\",\"host_id\":\"[0-9]*\",\"host\":\"$HOST\""|grep -o "record_id\":\"[0-9]*"|grep -o "[0-9]*")
	echo "RECORD ID: $RECORD_ID"
	if [ "$RECORD_ID" = "" ] ; then
		# 获取线路ID
		# URL_I="https://www.cloudxns.net/api2/line"
		# DATE=$(date)
		# HMAC_I=$(printf "%s" "$API_KEY$URL_I$DATE$SECRET_KEY"|md5sum|cut -d" " -f1)
		# LINE_ID=$(curl -k -s $URL_I -H "API-KEY: $API_KEY" -H "API-REQUEST-DATE: $DATE" -H "API-HMAC: $HMAC_I")
		# LINE_ID=$(echo $LINE_ID|grep -o "id\":\"[0-9]*\","|grep -o "[0-9]*"|head -n1)
		# echo "LINE ID: $LINE_ID"

		# 添加子域名记录IP
		logger -t "【CloudXNS动态域名】" "添加子域名 ${HOST} 记录IP"
		IP=$hostIP
		URL_A="https://www.cloudxns.net/api2/record"

		PARAM_BODY="{\"domain_id\":\"$DOMAIN_ID\",\"host\":\"$HOST\",\"type\":\"A\",\"value\":\"$IP\",\"line_id\":\"1\"}"
		HMAC_A=$(printf "%s" "$API_KEY$URL_A$PARAM_BODY$DATE$SECRET_KEY"|md5sum|cut -d" " -f1)

		RESULT=$(curl -k -s "$URL_A" -X POST -d "$PARAM_BODY" -H "API-KEY: $API_KEY" -H "API-REQUEST-DATE: $DATE" -H "API-HMAC: $HMAC_A" -H 'Content-Type: application/json')
	else
		# 更新记录IP
		IP=$hostIP
		URL_U="https://www.cloudxns.net/api2/record/$RECORD_ID"

		PARAM_BODY="{\"domain_id\":\"$DOMAIN_ID\",\"host\":\"$HOST\",\"value\":\"$IP\"}"
		HMAC_U=$(printf "%s" "$API_KEY$URL_U$PARAM_BODY$DATE$SECRET_KEY"|md5sum|cut -d" " -f1)

		RESULT=$(curl -k -s "$URL_U" -X PUT -d "$PARAM_BODY" -H "API-KEY: $API_KEY" -H "API-REQUEST-DATE: $DATE" -H "API-HMAC: $HMAC_U" -H 'Content-Type: application/json')
	fi
	echo "$RESULT"

	# 输出记录IP
	if [ "$(printf "%s" "$RESULT"|grep -c -o "message\":\"success\"")" = 1 ];then
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
	echo "Updating Domain: ${2}.${1}"
	echo "hostIP: ${hostIP}"
	lastIP=$(arDdnsInfo "$1" "$2")
	if [ $? -eq 1 ]; then
		lastIP=$(arNslookup "${2}.${1}")
	fi
	echo "lastIP: ${lastIP}"
	if [ "$lastIP" != "$hostIP" ] ; then
		logger -t "【CloudXNS动态域名】" "开始更新 ${2}.${1} 域名 IP 指向"
		logger -t "【CloudXNS动态域名】" "目前 IP: ${hostIP}"
		logger -t "【CloudXNS动态域名】" "上次 IP: ${lastIP}"
		sleep 1
		postRS=$(arDdnsUpdate $1 $2)
		if [ $? -eq 0 ]; then
			echo "postRS: ${postRS}"
			logger -t "【CloudXNS动态域名】" "更新动态DNS记录成功！"
			return 0
		else
			echo ${postRS}
			logger -t "【CloudXNS动态域名】" "更新动态DNS记录失败！请检查您的网络。"
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
if [ -s "/opt/etc/init.d/rc.func" ] ; then
	cp -Hf "$scriptfilepath" "/opt/etc/init.d/$scriptname"
fi

}

case $ACTION in
start)
	cloudxns_close
	cloudxns_check
	;;
check)
	cloudxns_check
	;;
stop)
	cloudxns_close
	;;
keep)
	cloudxns_keep
	;;
*)
	cloudxns_check
	;;
esac

