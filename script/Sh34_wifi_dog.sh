#!/bin/bash
#copyright by hiboy
source /etc/storage/script/init.sh
wifidog_enable=`nvram get wifidog_enable`
[ -z $wifidog_enable ] && wifidog_enable=0 && nvram set wifidog_enable=0
if [ "$wifidog_enable" != "0" ] ; then

wifidog_Daemon=`nvram get wifidog_Daemon`
wifidog_Hostname=`nvram get wifidog_Hostname`
wifidog_HTTPPort=`nvram get wifidog_HTTPPort`
wifidog_Path=`nvram get wifidog_Path`
wifidog_id=`nvram get wifidog_id`
wifidog_lanif=`nvram get wifidog_lanif`
wifidog_wanif=`nvram get wifidog_wanif`
wifidog_Port=`nvram get wifidog_Port`
wifidog_Interval=`nvram get wifidog_Interval`
wifidog_Timeout=`nvram get wifidog_Timeout`
wifidog_MaxConn=`nvram get wifidog_MaxConn`
wifidog_MACList=`nvram get wifidog_MACList`

wifidog_renum=`nvram get wifidog_renum`
wifidog_renum=${wifidog_renum:-"0"}
cmd_log_enable=`nvram get cmd_log_enable`
cmd_name="wifidog"
cmd_log=""
if [ "$cmd_log_enable" = "1" ] || [ "$wifidog_renum" -gt "0" ] ; then
	cmd_log="$cmd_log2"
fi
fi

if [ ! -z "$(echo $scriptfilepath | grep -v "/tmp/script/" | grep wifi_dog)" ] && [ ! -s /tmp/script/_wifi_dog ] ; then
	mkdir -p /tmp/script
	{ echo '#!/bin/bash' ; echo $scriptfilepath '"$@"' '&' ; } > /tmp/script/_wifi_dog
	chmod 777 /tmp/script/_wifi_dog
fi

IPT="/bin/iptables"
#开关
wifidog_Daemon=`nvram get wifidog_Daemon`


#认证服务器
[ -z $wifidog_HTTPPort ] && wifidog_HTTPPort="84" && nvram set wifidog_HTTPPort=$wifidog_HTTPPort
[ -z $wifidog_Path ] && wifidog_Path="/" && nvram set wifidog_Path=$wifidog_Path

#高级设置
[ -z "$wifidog_id" ] && wifidog_id=$(/sbin/ifconfig br0  | sed -n '/HWaddr/ s/^.*HWaddr */HWADDR=/pg'  | awk -F"=" '{print $2}' |sed -n 's/://pg'| awk -F" " '{print $1}')  && nvram set wifidog_id=$wifidog_id
[ -z $wifidog_lanif ] && wifidog_lanif="br0" && nvram set wifidog_lanif=$wifidog_lanif
[ -z $wifidog_wanif ] && wifidog_wanif=$(nvram get wan0_ifname_t) && nvram set wifidog_wanif=$wifidog_wanif
[ -z $wifidog_Port ] && wifidog_Port="2060" && nvram set wifidog_Port=$wifidog_Port
[ -z $wifidog_Interval ] && wifidog_Interval="60" && nvram set wifidog_Interval=$wifidog_Interval
[ -z $wifidog_Timeout ] && wifidog_Timeout="5" && nvram set wifidog_Timeout=$wifidog_Timeout
[ -z $wifidog_MaxConn ] && wifidog_MaxConn="30" && nvram set wifidog_MaxConn=$wifidog_MaxConn
[ -z $wifidog_MACList ] && wifidog_MACList="00:00:DE:AD:BE:AF" && nvram set wifidog_MACList=$wifidog_MACList

wifidog_restart () {
i_app_restart "$@" -name="wifidog"
}

wifidog_get_status () {

B_restart="$wifidog_enable$wifidog_Daemon$wifidog_Hostname$wifidog_HTTPPort$wifidog_Path$wifidog_id$wifidog_lanif$wifidog_wanif$wifidog_Port$wifidog_Interval$wifidog_Timeout$wifidog_MaxConn$wifidog_MACList"

i_app_get_status -name="wifidog" -valb="$B_restart"
}

wifidog_check () {

wifidog_get_status
if [ "$wifidog_enable" != "1" ] && [ "$needed_restart" = "1" ] ; then
	[ ! -z "`pidof wifidog`" ] && logger -t "【wifidog】" "停止 wifidog" && wifidog_close
	{ kill_ps "$scriptname" exit0; exit 0; }
fi
if [ "$wifidog_enable" = "1" ] ; then
	if [ "$needed_restart" = "1" ] ; then
		wifidog_close
		wifidog_start
	else
		[ -z "`pidof wifidog`" ] && wifidog_restart
	fi
fi
}

wifidog_keep () {
i_app_keep -name="wifidog" -pidof="wifidog" &
}

wifidog_close () {
kill_ps "$scriptname keep"
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
kill_ps "/tmp/script/_wifi_dog"
kill_ps "_wifi_dog.sh"
kill_ps "$scriptname"
}

wifidog_start () {
check_webui_yes
i_app_get_cmd_file -name="wifidog" -cmd="wdctl" -cpath="/opt/bin/wdctl" -down1="$hiboyfile/wdctl" -down2="$hiboyfile2/wdctl" -runh="x"
i_app_get_cmd_file -name="wifidog" -cmd="wifidog" -cpath="/opt/bin/wifidog" -down1="$hiboyfile/wifidog" -down2="$hiboyfile2/wifidog"

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

chmod 777 "$SVC_PATH"
eval "$SVC_PATH -c /etc/storage/wifidog.conf $cmd_log" &

sleep 4
i_app_keep -t -name="wifidog" -pidof="wifidog"
#wifidog_get_status
eval "$scriptfilepath keep &"
exit 0
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
	#wifidog_check
	wifidog_keep
	;;
*)
	wifidog_check
	;;
esac

