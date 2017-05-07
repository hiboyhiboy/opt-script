#!/bin/sh
#copyright by hiboy
source /etc/storage/script/init.sh
wifidog_enable=`nvram get wifidog_enable`
[ -z $wifidog_enable ] && wifidog_enable=0 && nvram set wifidog_enable=0
if [ "$wifidog_enable" != "0" ] ; then
nvramshow=`nvram showall | grep wifidog | awk '{print gensub(/'"'"'/,"'"'"'\"'"'"'\"'"'"'","g",$0);}'| awk '{print gensub(/=/,"='\''",1,$0)"'\'';";}'` && eval $nvramshow
fi

if [ ! -z "$(echo $scriptfilepath | grep -v "/tmp/script/" | grep wifi_dog)" ]  && [ ! -s /tmp/script/_wifi_dog ]; then
	mkdir -p /tmp/script
	ln -sf $scriptfilepath /tmp/script/_wifi_dog
	chmod 777 /tmp/script/_wifi_dog
fi

IPT="/bin/iptables"
WD_DIR="/usr/bin"
SVC_PATH=$WD_DIR/wifidog
if [ ! -f "$SVC_PATH" ] ; then
	WD_DIR="/opt/bin"
fi
#开关
wifidog_Daemon=`nvram get wifidog_Daemon`


#认证服务器
[ -z $wifidog_HTTPPort ] && wifidog_HTTPPort="84" && nvram set wifidog_HTTPPort=$wifidog_HTTPPort
[ -z $wifidog_Path ] && wifidog_Path="/" && nvram set wifidog_Path=$wifidog_Path

#高级设置
[ -z $wifidog_id ] && wifidog_id=$(/sbin/ifconfig br0  | sed -n '/HWaddr/ s/^.*HWaddr */HWADDR=/pg'  | awk -F"=" '{print $2}' |sed -n 's/://pg'| awk -F" " '{print $1}')  && nvram set wifidog_id=$wifidog_id
[ -z $wifidog_lanif ] && wifidog_lanif="br0" && nvram set wifidog_lanif=$wifidog_lanif
[ -z $wifidog_wanif ] && wifidog_wanif=$(nvram get wan0_ifname_t) && nvram set wifidog_wanif=$wifidog_wanif
[ -z $wifidog_Port ] && wifidog_Port="2060" && nvram set wifidog_Port=$wifidog_Port
[ -z $wifidog_Interval ] && wifidog_Interval="60" && nvram set wifidog_Interval=$wifidog_Interval
[ -z $wifidog_Timeout ] && wifidog_Timeout="5" && nvram set wifidog_Timeout=$wifidog_Timeout
[ -z $wifidog_MaxConn ] && wifidog_MaxConn="30" && nvram set wifidog_MaxConn=$wifidog_MaxConn
[ -z $wifidog_MACList ] && wifidog_MACList="00:00:DE:AD:BE:AF" && nvram set wifidog_MACList=$wifidog_MACList

wifidog_check () {

A_restart=`nvram get wifidog_status`
B_restart="$wifidog_enable$wifidog_Daemon$wifidog_Hostname$wifidog_HTTPPort$wifidog_Path$wifidog_id$wifidog_lanif$wifidog_wanif$wifidog_Port$wifidog_Interval$wifidog_Timeout$wifidog_MaxConn$wifidog_MACList"
B_restart=`echo -n "$B_restart" | md5sum | sed s/[[:space:]]//g | sed s/-//g`
if [ "$A_restart" != "$B_restart" ] ; then
	nvram set wifidog_status=$B_restart
	needed_restart=1
else
	needed_restart=0
fi
if [ "$wifidog_enable" != "1" ] && [ "$needed_restart" = "1" ] ; then
	[ ! -z "`pidof wifidog`" ] && logger -t "【wifidog】" "停止 wifidog" && wifidog_close
	{ eval $(ps -w | grep "$scriptname" | grep -v grep | awk '{print "kill "$1";";}'); exit 0; }
fi
if [ "$wifidog_enable" = "1" ] ; then
	if [ "$needed_restart" = "1" ] ; then
		wifidog_close
		wifidog_start
	else
		[ -z "`pidof wifidog`" ] && nvram set wifidog_status=00 && { eval "$scriptfilepath start &"; exit 0; }
	fi
fi
}

wifidog_keep () {

logger -t "【wifidog】" "守护进程启动"
if [ -s /tmp/script/_opt_script_check ]; then
sed -Ei '/【wifidog】|^$/d' /tmp/script/_opt_script_check
cat >> "/tmp/script/_opt_script_check" <<-OSC
[ -z "\`pidof wifidog\`" ] || [ ! -s "`which wifidog`" ] && nvram set wifidog_status=00 && logger -t "【wifidog】" "重新启动" && eval "$scriptfilepath &" && sed -Ei '/【wifidog】|^$/d' /tmp/script/_opt_script_check # 【wifidog】
OSC
return
fi
while true; do
	if [ -z "`pidof wifidog`" ] || [ ! -s "`which wifidog`" ] ; then
		logger -t "【wifidog】" "重新启动"
		{ nvram set wifidog_status=00 && eval "$scriptfilepath &" ; exit 0; }
	fi
sleep 234
done
}

wifidog_close () {
sed -Ei '/【wifidog】|^$/d' /tmp/script/_opt_script_check
echo "Stopping Wifidog ... "
if $WD_DIR/wdctl status 2> /dev/null
then
	if $WD_DIR/wdctl stop
	then
			echo "OK"
	else
			echo "FAILED:  wdctl stop exited with non 0 status"
	fi
else
   echo "FAILED:  Wifidog was not running"
fi
$WD_DIR/wdctl stop
killall wifidog wdctl
killall -9 wifidog wdctl
eval $(ps -w | grep "_wifi_dog keep" | grep -v grep | awk '{print "kill "$1";";}')
eval $(ps -w | grep "_wifi_dog.sh keep" | grep -v grep | awk '{print "kill "$1";";}')
eval $(ps -w | grep "$scriptname keep" | grep -v grep | awk '{print "kill "$1";";}')
}

wifidog_start () {
SVC_PATH=$WD_DIR/wifidog
if [ ! -s "$SVC_PATH" ] ; then
	SVC_PATH="/usr/bin/wifidog"
fi
if [ ! -s "$SVC_PATH" ] ; then
	SVC_PATH="/opt/bin/wifidog"
fi
hash wifidog 2>/dev/null || rm -rf /opt/bin/wifidog
if [ ! -s "$SVC_PATH" ] ; then
	logger -t "【wifidog】" "找不到 $SVC_PATH ，安装 opt 程序"
	/tmp/script/_mountopt start
	initopt
fi
if [ ! -s "$SVC_PATH" ] ; then
	logger -t "【Wifidog】" "找不到 $SVC_PATH 下载程序"
	wgetcurl.sh /opt/bin/wifidog "$hiboyfile/wifidog" "$hiboyfile2/wifidog"
	chmod 755 "/opt/bin/wifidog"
	wgetcurl.sh /opt/bin/wdctl "$hiboyfile/wdctl" "$hiboyfile2/wdctl"
	chmod 755 "/opt/bin/wdctl"
else
	logger -t "【wifidog】" "找到 $SVC_PATH"
fi
if [ ! -s "$SVC_PATH" ] ; then
	logger -t "【wifidog】" "找不到 $SVC_PATH ，需要手动安装 $SVC_PATH"
	logger -t "【wifidog】" "启动失败, 10 秒后自动尝试重新启动" && sleep 10 && { nvram set wifidog_status=00; eval "$scriptfilepath &"; exit 0; }
fi

logger -t "【wifidog】" "运行 wifidog"

rm -f /etc/storage/wifidog.conf  
# 将数值赋给WiFiDog官方的配置参数
cat > "/etc/storage/wifidog.conf" <<-FWD
#WiFiDog 配置文件

#网关ID
GatewayID $wifidog_id

#内部网卡
GatewayInterface $wifidog_lanif

#外部网卡
ExternalInterface $wifidog_wanif 

#认证服务器
AuthServer {
Hostname $wifidog_Hostname
HTTPPort $wifidog_HTTPPort
Path $wifidog_Path
}

#守护进程
Daemon $wifidog_Daemon

#检查DNS状态(Check DNS health by querying IPs of these hosts)
PopularServers $wifidog_Hostname

#运行状态
HtmlMessageFile /www/wifidog-msg.html

#监听端口
GatewayPort $wifidog_Port

#心跳间隔时间
CheckInterval $wifidog_Interval

#心跳间隔次数
ClientTimeout $wifidog_Timeout

#HTTP最大连接数
HTTPDMaxConn $wifidog_MaxConn

#信任的MAC地址,加入信任列表将不用登录可访问
TrustedMACList $wifidog_MACList

#全局防火墙设置
FirewallRuleSet global {
FirewallRule allow tcp port 443
}

#新验证用户
FirewallRuleSet validating-users {
	FirewallRule allow to 0.0.0.0/0
}
#正常用户
FirewallRuleSet known-users {
	FirewallRule allow to 0.0.0.0/0
}

#未知用户
FirewallRuleSet unknown-users {
	FirewallRule allow udp port 53
	FirewallRule allow tcp port 53
	FirewallRule allow udp port 67
	FirewallRule allow tcp port 67
}

#锁住用户
FirewallRuleSet locked-users {
	FirewallRule block to 0.0.0.0/0
FWD

$SVC_PATH -c /etc/storage/wifidog.conf &

sleep 2
[ ! -z "`pidof wifidog`" ] && logger -t "【wifidog】" "启动成功"
[ -z "`pidof wifidog`" ] && logger -t "【wifidog】" "启动失败, 注意检查端口是否有冲突,程序是否下载完整,10 秒后自动尝试重新启动" && sleep 10 && { nvram set wifidog_status=00; eval "$scriptfilepath &"; exit 0; }
eval "$scriptfilepath keep &"
}



stop()
{
	logger -t "【Wifidog】" "关闭"
	echo "Stopping Wifidog ... "
	if $WD_DIR/wdctl status 2> /dev/null
	then
		if $WD_DIR/wdctl stop
		then
				echo "OK"
		else
				echo "FAILED:  wdctl stop exited with non 0 status"
		fi
	else
	   echo "FAILED:  Wifidog was not running"
	fi
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
	wifidog_close
	wifidog_check
	;;
check)
	wifidog_check
	;;
stop)
	wifidog_close
	;;
keep)
	wifidog_check
	wifidog_keep
	;;
*)
	wifidog_check
	;;
esac

