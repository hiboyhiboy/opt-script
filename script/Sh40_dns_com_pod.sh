#!/bin/sh
#copyright by hiboy
source /etc/storage/script/init.sh
dns_com_pod_enable=`nvram get dns_com_pod_enable`
[ -z $dns_com_pod_enable ] && dns_com_pod_enable=0 && nvram set dns_com_pod_enable=0
if [ "$dns_com_pod_enable" != "0" ] ; then
#nvramshow=`nvram showall | grep '=' | grep dns_com_pod | awk '{print gensub(/'"'"'/,"'"'"'\"'"'"'\"'"'"'","g",$0);}'| awk '{print gensub(/=/,"='\''",1,$0)"'\'';";}'` && eval $nvramshow

dns_com_pod_username=`nvram get dns_com_pod_username`
dns_com_pod_password=`nvram get dns_com_pod_password`
dns_com_pod_user_token=`nvram get dns_com_pod_user_token`
dns_com_pod_domian=`nvram get dns_com_pod_domian`
dns_com_pod_host=`nvram get dns_com_pod_host`
dns_com_pod_domian2=`nvram get dns_com_pod_domian2`
dns_com_pod_host2=`nvram get dns_com_pod_host2`
dns_com_pod_interval=`nvram get dns_com_pod_interval`

hostIP=""
myIP=""
[ -z $dns_com_pod_interval ] && dns_com_pod_interval=600 && nvram set dns_com_pod_interval=$dns_com_pod_interval
fi

if [ ! -z "$(echo $scriptfilepath | grep -v "/tmp/script/" | grep dns_com_pod)" ]  && [ ! -s /tmp/script/_dns_com_pod ]; then
	mkdir -p /tmp/script
	{ echo '#!/bin/sh' ; echo $scriptfilepath '"$@"' '&' ; } > /tmp/script/_dns_com_pod
	chmod 777 /tmp/script/_dns_com_pod
fi

dns_com_pod_get_status () {

A_restart=`nvram get dns_com_pod_status`
B_restart="$dns_com_pod_enable$dns_com_pod_username$dns_com_pod_password$dns_com_pod_user_token$dns_com_pod_domian$dns_com_pod_host$dns_com_pod_domian2$dns_com_pod_host2$dns_com_pod_interval$(cat /etc/storage/ddns_script.sh | grep -v '^#' | grep -v "^$")"
B_restart=`echo -n "$B_restart" | md5sum | sed s/[[:space:]]//g | sed s/-//g`
if [ "$A_restart" != "$B_restart" ] ; then
	nvram set dns_com_pod_status=$B_restart
	needed_restart=1
else
	needed_restart=0
fi
}

dns_com_pod_get_status2 () {

[ "x${dns_com_pod_username}" = "x" ] && [ "x${dns_com_pod_password}" = "x" ] && return 0
A_restart=`nvram get dns_com_pod_status2`
B_restart="$dns_com_pod_username$dns_com_pod_password"
B_restart=`echo -n "$B_restart" | md5sum | sed s/[[:space:]]//g | sed s/-//g`
if [ "$A_restart" != "$B_restart" ] ; then
	nvram set dns_com_pod_status2=$B_restart
	dns_com_pod_user_token=""
fi
if [ "x${dns_com_pod_user_token}" = "x" ] ; then # undefine token
	user_token=`curl -k -X POST https://api.dnspod.com/Auth -d 'login_email='"$dns_com_pod_username"'&login_password='"$dns_com_pod_password"'&format=json'`
	dns_com_pod_user_token="$(echo $user_token  | grep -Eo '"user_token":"[^"]*"' | cut -d':' -f2 | tr -d '"')"
	if [ "x${dns_com_pod_user_token}" = "x" ] ; then # undefine token
		# 输出错误信息
		message=$(echo $user_token | grep -Eo '"message":"[^"]*"' | cut -d':' -f2 | tr -d '"')
		logger -t "【dns_com_pod动态域名】" "获取 user_token 错误: ${message}"
		logger -t "【dns_com_pod动态域名】" "获取 user_token 错误，10 秒后自动尝试重新启动" && sleep 10; nvram set dns_com_pod_status=00; eval "$scriptfilepath &"; exit 0;
	fi
	nvram set dns_com_pod_user_token="$dns_com_pod_user_token"
fi
}

dns_com_pod_check () {

dns_com_pod_get_status
dns_com_pod_get_status2
if [ "$dns_com_pod_enable" != "1" ] && [ "$needed_restart" = "1" ] ; then
	[ ! -z "$(ps -w | grep "$scriptname keep" | grep -v grep )" ] && logger -t "【dns_com_pod动态域名】" "停止 dns_com_pod" && dns_com_pod_close
	{ kill_ps "$scriptname" exit0; exit 0; }
fi
if [ "$dns_com_pod_enable" = "1" ] ; then
[ "x${dns_com_pod_user_token}" = "x" ] && [ "x${dns_com_pod_username}" = "x" ] && [ "x${dns_com_pod_password}" = "x" ] && { logger -t "【dns_com_pod动态域名】" "用户名密码或者 Token 等设置未填写, 10 秒后自动尝试重新启动" && sleep 10; nvram set dns_com_pod_status=00; eval "$scriptfilepath &"; exit 0; }
	if [ "$needed_restart" = "1" ] ; then
		dns_com_pod_get_status
		dns_com_pod_close
		eval "$scriptfilepath keep &"
	else
		[ -z "$(ps -w | grep "$scriptname keep" | grep -v grep )" ] && nvram set dns_com_pod_status=00 && { eval "$scriptfilepath start &"; exit 0; }
	fi
fi
}

dns_com_pod_keep () {
dns_com_pod_start
logger -t "【dns_com_pod动态域名】" "守护进程启动"
while true; do
sleep 41
sleep $dns_com_pod_interval
#nvramshow=`nvram showall | grep '=' | grep dns_com_pod | awk '{print gensub(/'"'"'/,"'"'"'\"'"'"'\"'"'"'","g",$0);}'| awk '{print gensub(/=/,"='\''",1,$0)"'\'';";}'` && eval $nvramshow
dns_com_pod_enable=`nvram get dns_com_pod_enable`
[ "$dns_com_pod_enable" = "0" ] && dns_com_pod_close && exit 0;
if [ "$dns_com_pod_enable" = "1" ] ; then
	dns_com_pod_start
fi
done
}

dns_com_pod_close () {
kill_ps "/tmp/script/_dns_com_pod"
kill_ps "_dns_com_pod.sh"
kill_ps "$scriptname"
}

dns_com_pod_start () {
arDdnsCheck $dns_com_pod_domian $dns_com_pod_host
if [ "$dns_com_pod_domian2"x != "x" ] && [ "$dns_com_pod_domian2" != "baidu.com" ] ; then
	sleep 1
	arDdnsCheck $dns_com_pod_domian2 $dns_com_pod_host2
fi
}

arDdnsInfo() {
	local domainID recordID recordIP
	# 获得域名ID
	domainID=$(arApiPost "Domain.Info" "domain=${1}")
	domainID=$(echo $domainID | grep -Eo '"id":"[0-9]+"' | cut -d':' -f2 | tr -d '"')
	
	# 获得记录ID
	recordID=$(arApiPost "Record.List" "domain_id=${domainID}&sub_domain=${2}")
	recordID=$(echo $recordID | grep -Eo '"id":"[0-9]+"' | cut -d':' -f2 | tr -d '"')
	
	# 获得最后更新IP
	recordIP=$(arApiPost "Record.Info" "domain_id=${domainID}&record_id=${recordID}")
	recordIP=$(echo $recordIP | grep -Eo '"value":"[0-9\.]*"' | cut -d':' -f2 | tr -d '"')

	# Output IP
	case "$recordIP" in 
	[1-9][0-9]*)
		echo $recordIP
		return 0
		;;
	*)
		echo "Get Record Info Failed!"
		#logger -t "【dns_com_pod动态域名】" "获取记录信息失败！"
		return 1
		;;
	esac
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

# 读取接口数据
# 参数: 接口类型 待提交数据
arApiPost() {
	local inter="https://api.dnspod.com/${1:?'Info.Version'}"
	
	local param="user_token=${dns_com_pod_user_token}&format=json&${2}"
	
	curltest=`which curl`
	if [ -z "$curltest" ] || [ ! -s "`which curl`" ] ; then
		wget --quiet --no-check-certificate --output-document=- --post-data $param $inter
	else
		curl -k -X POST $inter -d $param
	fi
}

# 更新记录信息
# 参数: 主域名 子域名
arDdnsUpdate() {
	local domainID recordID recordRS recordCD recordIP
	# 获得域名ID
	domainID=$(arApiPost "Domain.Info" "domain=${1}")
	domainID=$(echo $domainID  | grep -Eo '"id":"[0-9]+"' | cut -d':' -f2 | tr -d '"')
	# 获得记录ID
	recordID=$(arApiPost "Record.List" "domain_id=${domainID}&sub_domain=${2}")
	recordID=$(echo $recordID  | grep -Eo '"id":"[0-9]+"' | cut -d':' -f2 | tr -d '"')
	#echo "更新记录信息 recordID: " $recordID
	if [ "$recordID" = "" ] ; then
		# 添加子域名记录IP
		myIP=$hostIP
		logger -t "【dns_com_pod动态域名】" "添加子域名 ${2} 记录IP: $myIP"
		recordRS=$(arApiPost "Record.Create" "domain_id=${domainID}&sub_domain=${2}&record_type=A&value=${myIP}&record_line=default")
	else
		# 更新记录IP
		myIP=$hostIP
		recordRS=$(arApiPost "Record.Ddns" "domain_id=${domainID}&record_id=${recordID}&sub_domain=${2}&record_type=A&value=${myIP}&record_line=default")
	fi
	recordCD=$(echo $recordRS | grep -Eo '"code":"[0-9]+"' | cut -d':' -f2 | tr -d '"')
	recordIP=$(echo $recordRS | grep -Eo '"value":"[0-9\.]*"' | cut -d':' -f2 | tr -d '"')
	# 输出记录IP
	if [ "$recordIP" = "" ] ; then
		sleep 10
		# 获得记录ID
		recordID=$(arApiPost "Record.List" "domain_id=${domainID}&sub_domain=${2}")
		recordID=$(echo $recordID | grep -Eo '"id":"[0-9]+"' | cut -d':' -f2 | tr -d '"')
		
		# 获得最后更新IP
		recordIP=$(arApiPost "Record.Info" "domain_id=${domainID}&record_id=${recordID}")
		recordIP=$(echo $recordIP | grep -Eo '"value":"[0-9\.]*"' | cut -d':' -f2 | tr -d '"')
	fi
	if [ "$recordIP" = "$myIP" ]; then
		if [ "$recordCD" = "1" ] ; then
			echo $recordIP
			logger -t "【dns_com_pod动态域名】" "`echo $recordRS | grep -Eo '"message":"[^"]*"' | cut -d':' -f2 | tr -d '"'`"
			return 0
		fi
		# 输出错误信息
		echo $recordRS | grep -Eo '"message":"[^"]*"' | cut -d':' -f2 | tr -d '"'
		logger -t "【dns_com_pod动态域名】" "`echo $recordRS | grep -Eo '"message":"[^"]*"' | cut -d':' -f2 | tr -d '"'`"
		return 1
	fi
	# 输出错误信息
	echo "Update Failed! Please check your network."
	logger -t "【dns_com_pod动态域名】" "`echo $recordRS | grep -Eo '"message":"[^"]*"' | cut -d':' -f2 | tr -d '"'`"
	return 1
}

# 动态检查更新
# 参数: 主域名 子域名
arDdnsCheck() {
	local postRS
	local lastIP
	source /etc/storage/ddns_script.sh
	hostIP=$arIpAddress
	if [ "$hostIP"x = "x"  ] ; then
		curltest=`which curl`
		if [ -z "$curltest" ] || [ ! -s "`which curl`" ] ; then
			hostIP=`wget --no-check-certificate --quiet --output-document=- "http://www.ipip.net" | grep "您当前的IP：" | grep -E -o '([0-9]+\.){3}[0-9]+'`
		else
			hostIP=`curl -L -k -s "http://www.ipip.net" | grep "您当前的IP：" | grep -E -o '([0-9]+\.){3}[0-9]+'`
		fi
		if [ "$hostIP"x = "x"  ] ; then
			logger -t "【dns_com_pod动态域名】" "错误！获取目前 IP 失败，请在脚本更换其他获取地址"
			return 1
		fi
	fi
	echo "Updating Domain: ${2}.${1}"
	echo "hostIP: ${hostIP}"
	#lastIP=$(arNslookup "${2}.${1}")
	lastIP=$(arDdnsInfo "$1" "$2")
	if [ $? -eq 1 ]; then
		lastIP=$(arNslookup "${2}.${1}")
	fi
	echo "lastIP: ${lastIP}"
	if [ "$lastIP" != "$hostIP" ] ; then
		logger -t "【dns_com_pod动态域名】" "开始更新 ${2}.${1} 域名 IP 指向"
		logger -t "【dns_com_pod动态域名】" "目前 IP: ${hostIP}"
		logger -t "【dns_com_pod动态域名】" "上次 IP: ${lastIP}"
		sleep 1
		postRS=$(arDdnsUpdate $1 $2)
		if [ $? -eq 0 ]; then
			echo "postRS: ${postRS}"
			logger -t "【dns_com_pod动态域名】" "更新动态DNS记录成功！提交的IP: ${postRS}"
			return 0
		else
			echo ${postRS}
			logger -t "【dns_com_pod动态域名】" "更新动态DNS记录失败！请检查您的网络。提交的IP: ${postRS}"
			return 1
		fi
	fi
	echo "Last IP is the same as current IP!"
	return 1

}

initconfig () {

if [ ! -s "/etc/storage/ddns_script.sh" ] ; then
cat > "/etc/storage/ddns_script.sh" <<-\EEE
# 获得外网地址
# 自行测试哪个代码能获取正确的IP，删除前面的#可生效
arIpAddress () {
curltest=`which curl`
if [ -z "$curltest" ] || [ ! -s "`which curl`" ] ; then
    wget --no-check-certificate --quiet --output-document=- "http://www.ipip.net" | grep "您当前的IP：" | grep -E -o '([0-9]+\.){3}[0-9]+'
    #wget --no-check-certificate --quiet --output-document=- "http://members.3322.org/dyndns/getip" | grep -E -o '([0-9]+\.){3}[0-9]+'
    #wget --no-check-certificate --quiet --output-document=- "ip.6655.com/ip.aspx" | grep -E -o '([0-9]+\.){3}[0-9]+'
    #wget --no-check-certificate --quiet --output-document=- "ip.3322.net" | grep -E -o '([0-9]+\.){3}[0-9]+'
else
    curl -L -k -s "http://www.ipip.net" | grep "您当前的IP：" | grep -E -o '([0-9]+\.){3}[0-9]+'
    #curl -k -s "http://members.3322.org/dyndns/getip" | grep -E -o '([0-9]+\.){3}[0-9]+'
    #curl -k -s ip.6655.com/ip.aspx | grep -E -o '([0-9]+\.){3}[0-9]+'
    #curl -k -s ip.3322.net | grep -E -o '([0-9]+\.){3}[0-9]+'
fi
}
arIpAddress=$(arIpAddress)
EEE
	chmod 755 "$ddns_script"
fi

}

initconfig

case $ACTION in
start)
	dns_com_pod_close
	dns_com_pod_check
	;;
check)
	dns_com_pod_check
	;;
stop)
	dns_com_pod_close
	;;
keep)
	dns_com_pod_keep
	;;
*)
	dns_com_pod_check
	;;
esac

