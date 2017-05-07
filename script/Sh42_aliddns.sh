#!/bin/sh
#copyright by hiboy
source /etc/storage/script/init.sh
aliddns_enable=`nvram get aliddns_enable`
[ -z $aliddns_enable ] && aliddns_enable=0 && nvram set aliddns_enable=0
if [ "$aliddns_enable" != "0" ] ; then
nvramshow=`nvram showall | grep aliddns | awk '{print gensub(/'"'"'/,"'"'"'\"'"'"'\"'"'"'","g",$0);}'| awk '{print gensub(/=/,"='\''",1,$0)"'\'';";}'` && eval $nvramshow
hostIP=""
domain=""
name=""
name1=""
timestamp=`date -u "+%Y-%m-%dT%H%%3A%M%%3A%SZ"`
aliddns_record_id=""
aliddns_interval=${aliddns_interval:-"600"}
aliddns_ttl=${aliddns_interval:-"600"}
fi

if [ ! -z "$(echo $scriptfilepath | grep -v "/tmp/script/" | grep aliddns)" ]  && [ ! -s /tmp/script/_aliddns ]; then
	mkdir -p /tmp/script
	ln -sf $scriptfilepath /tmp/script/_aliddns
	chmod 777 /tmp/script/_aliddns
fi


aliddns_check () {

A_restart=`nvram get aliddns_status`
B_restart="$aliddns_enable$aliddns_interval$aliddns_ak$aliddns_sk$aliddns_domain$aliddns_name$aliddns_domain2$aliddns_name2$aliddns_ttl$(cat /etc/storage/ddns_script.sh | grep -v '^#' | grep -v "^$")"
B_restart=`echo -n "$B_restart" | md5sum | sed s/[[:space:]]//g | sed s/-//g`
if [ "$A_restart" != "$B_restart" ] ; then
	nvram set aliddns_status=$B_restart
	needed_restart=1
else
	needed_restart=0
fi
if [ "$aliddns_enable" != "1" ] && [ "$needed_restart" = "1" ] ; then
	[ ! -z "$(ps -w | grep "$scriptname keep" | grep -v grep )" ] && logger -t "【aliddns动态域名】" "停止 aliddns" && aliddns_close
	{ eval $(ps -w | grep "$scriptname" | grep -v grep | awk '{print "kill "$1";";}'); exit 0; }
fi
if [ "$aliddns_enable" = "1" ] ; then
	if [ "$needed_restart" = "1" ] ; then
		aliddns_close
		eval "$scriptfilepath keep &"
	else
		[ -z "$(ps -w | grep "$scriptname keep" | grep -v grep )" ] || [ ! -s "`which curl`" ] && nvram set aliddns_status=00 &&  { eval "$scriptfilepath start &"; exit 0; }
	fi
fi
}

aliddns_keep () {
aliddns_start
logger -t "【AliDDNS动态域名】" "守护进程启动"
while true; do
sleep 43
[ ! -s "`which curl`" ] && nvram set aliddns_status=00 &&  { eval "$scriptfilepath start &"; exit 0; }
sleep $aliddns_interval
nvramshow=`nvram showall | grep aliddns | awk '{print gensub(/'"'"'/,"'"'"'\"'"'"'\"'"'"'","g",$0);}'| awk '{print gensub(/=/,"='\''",1,$0)"'\'';";}'` && eval $nvramshow
[ "$aliddns_enable" = "0" ] && aliddns_close && exit 0;
if [ "$aliddns_enable" = "1" ] ; then
	aliddns_start
fi
done
}

aliddns_close () {

eval $(ps -w | grep "_aliddns keep" | grep -v grep | awk '{print "kill "$1";";}')
eval $(ps -w | grep "_aliddns.sh keep" | grep -v grep | awk '{print "kill "$1";";}')
eval $(ps -w | grep "$scriptname keep" | grep -v grep | awk '{print "kill "$1";";}')
}

aliddns_start () {
curltest=`which curl`
if [ -z "$curltest" ] || [ ! -s "`which curl`" ] ; then
	logger -t "【AliDDNS动态域名】" "找不到 curl ，安装 opt 程序"
	/tmp/script/_mountopt optwget
	#initopt
	curltest=`which curl`
	if [ -z "$curltest" ] || [ ! -s "`which curl`" ] ; then
		logger -t "【AliDDNS动态域名】" "找不到 curl ，需要手动安装 opt 后输入[opkg install curl]安装"
		logger -t "【AliDDNS动态域名】" "启动失败, 10 秒后自动尝试重新启动" && sleep 10 && { nvram set aliddns_status=00; eval "$scriptfilepath &"; exit 0; }
	fi
fi
sleep 1
timestamp=`date -u "+%Y-%m-%dT%H%%3A%M%%3A%SZ"`
aliddns_record_id=""
domain="$aliddns_domain"
name="$aliddns_name"
arDdnsCheck $aliddns_domain $aliddns_name
if [ "$aliddns_domain2"x != "x" ] && [ "$aliddns_name2" != "baidu.com" ] ; then
	sleep 1
	timestamp=`date -u "+%Y-%m-%dT%H%%3A%M%%3A%SZ"`
	aliddns_record_id=""
	domain="$aliddns_domain2"
	name="$aliddns_name2"
	arDdnsCheck $aliddns_domain2 $aliddns_name2
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
    local args="AccessKeyId=$aliddns_ak&Action=$1&Format=json&$2&Version=2015-01-09"
    local hash=$(echo -n "GET&%2F&$(enc "$args")" | openssl dgst -sha1 -hmac "$aliddns_sk&" -binary | openssl base64)
    curl -s "http://alidns.aliyuncs.com/?$args&Signature=$(enc "$hash")"
}

get_recordid() {
    grep -Eo '"RecordId":"[0-9]+"' | cut -d':' -f2 | tr -d '"'
}

get_recordIP() {
    grep -Eo '"Value":"[0-9\.]*"' | cut -d':' -f2 | tr -d '"'
}

query_recordInfo() {
    send_request "DescribeDomainRecordInfo" "RecordId=$1&SignatureMethod=HMAC-SHA1&SignatureNonce=$timestamp&SignatureVersion=1.0&Timestamp=$timestamp"
}

query_recordid() {
    send_request "DescribeSubDomainRecords" "SignatureMethod=HMAC-SHA1&SignatureNonce=$timestamp&SignatureVersion=1.0&SubDomain=$name1.$domain&Timestamp=$timestamp"
}

update_record() {
    send_request "UpdateDomainRecord" "RR=$name1&RecordId=$1&SignatureMethod=HMAC-SHA1&SignatureNonce=$timestamp&SignatureVersion=1.0&TTL=$aliddns_ttl&Timestamp=$timestamp&Type=A&Value=$hostIP"
}

add_record() {
    send_request "AddDomainRecord&DomainName=$domain" "RR=$name1&SignatureMethod=HMAC-SHA1&SignatureNonce=$timestamp&SignatureVersion=1.0&TTL=$aliddns_ttl&Timestamp=$timestamp&Type=A&Value=$hostIP"
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

	timestamp=`date -u "+%Y-%m-%dT%H%%3A%M%%3A%SZ"`
	# 获得域名ID
	aliddns_record_id=""
	aliddns_record_id=`query_recordid | get_recordid`
	sleep 1
	timestamp=`date -u "+%Y-%m-%dT%H%%3A%M%%3A%SZ"`
	# 获得最后更新IP
	recordIP=`query_recordInfo $aliddns_record_id | get_recordIP`
	
	# Output IP
	case "$recordIP" in 
	[1-9][0-9]*)
		echo $recordIP
		return 0
		;;
	*)
		echo "Get Record Info Failed!"
		#logger -t "【AliDDNS动态域名】" "获取记录信息失败！"
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
	# 获得记录ID
	timestamp=`date -u "+%Y-%m-%dT%H%%3A%M%%3A%SZ"`
	aliddns_record_id=""
	aliddns_record_id=`query_recordid | get_recordid`
	echo "recordID $aliddns_record_id"
	sleep 1
	timestamp=`date -u "+%Y-%m-%dT%H%%3A%M%%3A%SZ"`
if [ "$aliddns_record_id" = "" ] ; then
	aliddns_record_id=`add_record | get_recordid`
	echo "added record $aliddns_record_id"
	logger -t "【AliDDNS动态域名】" "添加的记录  $aliddns_record_id"
else
	update_record $aliddns_record_id
	echo "updated record $aliddns_record_id"
	logger -t "【AliDDNS动态域名】" "更新的记录  $aliddns_record_id"
fi
# save to file
if [ "$aliddns_record_id" = "" ] ; then
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
	local postRS
	local lastIP
	source /etc/storage/ddns_script.sh
	hostIP=$arIpAddress
	echo "Updating Domain: ${2}.${1}"
	echo "hostIP: ${hostIP}"
	lastIP=$(arDdnsInfo "$1 $2")
	if [ $? -eq 1 ]; then
		lastIP=$(arNslookup "${2}.${1}")
	fi
	echo "lastIP: ${lastIP}"
	if [ "$lastIP" != "$hostIP" ] ; then
		logger -t "【AliDDNS动态域名】" "开始更新 ${2}.${1} 域名 IP 指向"
		logger -t "【AliDDNS动态域名】" "目前 IP: ${hostIP}"
		logger -t "【AliDDNS动态域名】" "上次 IP: ${lastIP}"
		sleep 1
		postRS=$(arDdnsUpdate $1 $2)
		if [ $? -eq 0 ]; then
			echo "postRS: ${postRS}"
			logger -t "【AliDDNS动态域名】" "更新动态DNS记录成功！"
			return 0
		else
			echo ${postRS}
			logger -t "【AliDDNS动态域名】" "更新动态DNS记录失败！请检查您的网络。"
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

