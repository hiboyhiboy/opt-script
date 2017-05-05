#!/bin/sh
#copyright by hiboy
source /etc/storage/script/init.sh
dnspod_enable=`nvram get dnspod_enable`
[ -z $dnspod_enable ] && dnspod_enable=0 && nvram set dnspod_enable=0
if [ "$dnspod_enable" != "0" ] ; then
nvramshow=`nvram showall | grep dnspod | awk '{print gensub(/'"'"'/,"'"'"'\"'"'"'\"'"'"'","g",$0);}'| awk '{print gensub(/=/,"='\''",1,$0)"'\'';";}'` && eval $nvramshow
hostIP=""
myIP=""
dnspod_interval=${dnspod_interval:-"600"}
fi

if [ ! -z "$(echo $scriptfilepath | grep -v "/tmp/script/" | grep dnspod)" ]  && [ ! -s /tmp/script/_dnspod ]; then
	mkdir -p /tmp/script
	ln -sf $scriptfilepath /tmp/script/_dnspod
	chmod 777 /tmp/script/_dnspod
fi

dnspod_check () {

A_restart=`nvram get dnspod_status`
B_restart="$dnspod_enable$dnspod_username$dnspod_password$dnspod_Token$dnspod_domian$dnspod_host$dnspod_domian2$dnspod_host2$dnspod_interval$(cat /etc/storage/ddns_script.sh | grep -v '^#' | grep -v "^$")"
B_restart=`echo -n "$B_restart" | md5sum | sed s/[[:space:]]//g | sed s/-//g`
if [ "$A_restart" != "$B_restart" ] ; then
	nvram set dnspod_status=$B_restart
	needed_restart=1
else
	needed_restart=0
fi
if [ "$dnspod_enable" != "1" ] && [ "$needed_restart" = "1" ] ; then
	[ ! -z "$(ps -w | grep "$scriptname keep" | grep -v grep )" ] && logger -t "【DNSPod动态域名】" "停止 dnspod" && dnspod_close
	{ eval $(ps -w | grep "$scriptname" | grep -v grep | awk '{print "kill "$1";";}'); exit 0; }
fi
if [ "$dnspod_enable" = "1" ] ; then
[ "x${dnspod_Token}" = "x" ] && [ "x${dnspod_username}" = "x" ] && [ "x${dnspod_password}" = "x" ] && { logger -t "【DNSPod动态域名】" "用户名密码或者 Token 等设置未填写, 10 秒后自动尝试重新启动" && sleep 10; nvram set dnspod_status=00; eval "$scriptfilepath &"; exit 0; }
	if [ "$needed_restart" = "1" ] ; then
		dnspod_close
		eval "$scriptfilepath keep &"
	else
		[ -z "$(ps -w | grep "$scriptname keep" | grep -v grep )" ] && nvram set dnspod_status=00 && { eval "$scriptfilepath start &"; exit 0; }
	fi
fi
}

dnspod_keep () {
dnspod_start
logger -t "【DNSPod动态域名】" "守护进程启动"
while true; do
sleep 41
sleep $dnspod_interval
nvramshow=`nvram showall | grep dnspod | awk '{print gensub(/'"'"'/,"'"'"'\"'"'"'\"'"'"'","g",$0);}'| awk '{print gensub(/=/,"='\''",1,$0)"'\'';";}'` && eval $nvramshow
[ "$dnspod_enable" = "0" ] && dnspod_close && exit 0;
if [ "$dnspod_enable" = "1" ] ; then
	dnspod_start
fi
done
}

dnspod_close () {
eval $(ps -w | grep "_dnspod keep" | grep -v grep | awk '{print "kill "$1";";}')
eval $(ps -w | grep "_dnspod.sh keep" | grep -v grep | awk '{print "kill "$1";";}')
eval $(ps -w | grep "$scriptname keep" | grep -v grep | awk '{print "kill "$1";";}')
}

dnspod_start () {
arDdnsCheck $dnspod_domian $dnspod_host
if [ "$dnspod_domian2"x != "x" ] && [ "$dnspod_domian2" != "baidu.com" ] ; then
	sleep 1
	arDdnsCheck $dnspod_domian2 $dnspod_host2
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
		#logger -t "【DNSPod动态域名】" "获取记录信息失败！"
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

# 读取接口数据
# 参数: 接口类型 待提交数据
arApiPost() {
	local agent="AnripDdns/5.07(mail@anrip.com)"
	local inter="https://dnsapi.cn/${1:?'Info.Version'}"
	if [ "x${dnspod_Token}" = "x" ] || [ "x${dnspod_Token}" = "x12345,7676f344eaeaea9074c123451234512d" ] ; then # undefine token
		local param="login_email=${dnspod_username}&login_password=${dnspod_password}&format=json&${2}"
	else
		local param="login_token=${dnspod_Token}&format=json&${2}"
	fi
	
	
	curltest=`which curl`
	if [ -z "$curltest" ] || [ ! -s "`which curl`" ] ; then
		wget --quiet --no-check-certificate --output-document=- --user-agent=$agent --post-data $param $inter
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
	echo "更新记录信息 recordID: " $recordID
	if [ "$recordID" = "" ] ; then
		# 添加子域名记录IP
		myIP=$hostIP
		logger -t "【DNSPod动态域名】" "添加子域名 ${2} 记录IP"
		recordRS=$(arApiPost "Record.Create" "domain_id=${domainID}&sub_domain=${2}&record_type=A&value=${myIP}&record_line=默认")
	else
		# 更新记录IP
		myIP=$hostIP
		recordRS=$(arApiPost "Record.Ddns" "domain_id=${domainID}&record_id=${recordID}&sub_domain=${2}&record_type=A&value=${myIP}&record_line=默认")
	fi
	recordCD=$(echo $recordRS | grep -Eo '"code":"[0-9]+"' | cut -d':' -f2 | tr -d '"')
	recordIP=$(echo $recordRS | grep -Eo '"value":"[0-9\.]*"' | cut -d':' -f2 | tr -d '"')
	# 输出记录IP
	if [ "$recordIP" = "" ] ; then
		# 获得记录ID
		recordID=$(arApiPost "Record.List" "domain_id=${domainID}&sub_domain=${2}")
		recordID=$(echo $recordID | grep -Eo '"id":"[0-9]+"' | cut -d':' -f2 | tr -d '"')
		
		# 获得最后更新IP
		recordIP=$(arApiPost "Record.Info" "domain_id=${domainID}&record_id=${recordID}")
		recordIP=$(echo $recordIP | grep -Eo '"value":"[0-9\.]*"' | cut -d':' -f2 | tr -d '"')
	fi
	if [ "$recordIP" = "$myIP" ]; then
		if [ "$recordCD" = "1" ] ; then
			echo $recordRS | grep -Eo '"value":"[0-9\.]*"' | cut -d':' -f2 | tr -d '"'
			logger -t "【DNSPod动态域名】" "`echo $recordRS | grep -Eo '"value":"[0-9\.]*"' | cut -d':' -f2 | tr -d '"'`"
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
	local postRS
	local lastIP
	source /etc/storage/ddns_script.sh
	hostIP=$arIpAddress
	echo "Updating Domain: ${2}.${1}"
	echo "hostIP: ${hostIP}"
	#lastIP=$(arNslookup "${2}.${1}")
	lastIP=$(arDdnsInfo "$1" "$2")
	if [ $? -eq 1 ]; then
		lastIP=$(arNslookup "${2}.${1}")
	fi
	echo "lastIP: ${lastIP}"
	if [ "$lastIP" != "$hostIP" ] ; then
		logger -t "【DNSPod动态域名】" "开始更新 ${2}.${1} 域名 IP 指向"
		logger -t "【DNSPod动态域名】" "目前 IP: ${hostIP}"
		logger -t "【DNSPod动态域名】" "上次 IP: ${lastIP}"
		sleep 1
		postRS=$(arDdnsUpdate $1 $2)
		if [ $? -eq 0 ]; then
			echo "postRS: ${postRS}"
			logger -t "【DNSPod动态域名】" "更新动态DNS记录成功！提交的IP: ${postRS}"
			return 0
		else
			echo ${postRS}
			logger -t "【DNSPod动态域名】" "更新动态DNS记录失败！请检查您的网络。提交的IP: ${postRS}"
			return 1
		fi
	fi
	echo "Last IP is the same as current IP!"
	return 1

}



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

