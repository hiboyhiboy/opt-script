#!/bin/sh
#copyright by hiboy
source /etc/storage/script/init.sh
wxsend_enable=`nvram get app_123`
[ -z $wxsend_enable ] && wxsend_enable=0 && nvram set app_123=0
wxsend_appid=`nvram get app_124`
wxsend_appsecret=`nvram get app_125`
wxsend_touser=`nvram get app_126`
wxsend_template_id=`nvram get app_127`
wxsend_port=`nvram get app_128`
[ -z $wxsend_port ] && wxsend_port=0 && nvram set app_128=0
wxsend_cgi=`nvram get app_129`
if [ -z $wxsend_cgi ] ; then
weekly=`tr -cd a-b0-9 </dev/urandom | head -c 12`
wxsend_cgi="$weekly" && nvram set app_129="$weekly"
fi
tmall_enable=`nvram get app_55`
[ -z $tmall_enable ] && tmall_enable=0 && nvram set app_55=0
if [ "$wxsend_enable" != "0" ] ; then
#nvramshow=`nvram showall | grep '=' | grep wxsend | awk '{print gensub(/'"'"'/,"'"'"'\"'"'"'\"'"'"'","g",$0);}'| awk '{print gensub(/=/,"='\''",1,$0)"'\'';";}'` && eval $nvramshow

wxsend_notify_1=`nvram get app_49`
wxsend_notify_2=`nvram get app_50`
wxsend_notify_3=`nvram get app_51`
wxsend_notify_4=`nvram get app_52`
wxsend_renum=`nvram get wxsend_renum`

fi
get_token () {
touch /tmp/wx_access_token
access_token="$(cat /tmp/wx_access_token)"
http_type="$(curl -L -s "https://api.weixin.qq.com/cgi-bin/get_api_domain_ip?access_token=$access_token")"
get_api_domain="$(echo $http_type | grep ip_list)"
if [ ! -z "$get_api_domain" ] ; then
echo "Access token 有效"
else
http_type="$(curl -L -s "https://api.weixin.qq.com/cgi-bin/token?grant_type=client_credential&appid=$wxsend_appid&secret=$wxsend_appsecret")"
access_token="$(echo $http_type | grep -o "\"access_token\":\"[^\,\"\}]*" | awk -F 'access_token":"' '{print $2}')"
if [ ! -z "$access_token" ] ; then
expires_in="$(echo $http_type | grep -o "\"expires_in\":[^\,\"\}]*" | awk -F 'expires_in":' '{print $2}')"
logger -t "【wxsend推送】" "获取 Access token 成功，凭证有效时间，单位： $expires_in 秒"
echo -n "$access_token" > /tmp/wx_access_token
else
errcode="$(echo $http_type | grep -o "\"errcode\":[^\,\"\}]*" | awk -F ':' '{print $2}')"
if [ ! -z "$errcode" ] ; then
errmsg="$(echo $http_type | grep -o "\"errmsg\":\"[^\,\"\}]*" | awk -F 'errmsg":"' '{print $2}')"
logger -t "【wxsend推送】" "获取 Access token 返回错误码: $errcode"
logger -t "【wxsend推送】" "错误信息: $errmsg"
access_token=""
echo -n "" > /tmp/wx_access_token
fi
fi
fi
}

send_message () {
get_token
access_token="$(cat /tmp/wx_access_token)"
if [ ! -z "$access_token" ] ; then
curl -H "Content-type: application/json;charset=UTF-8" -H "Accept: application/json" -H "Cache-Control: no-cache" -H "Pragma: no-cache" -X POST -d '{"touser":"'"$wxsend_touser"'","template_id":"'"$wxsend_template_id"'","data":{"title":{"value":"'"$1"'"},"content":{"value":"'"$2"'"}}}' "https://api.weixin.qq.com/cgi-bin/message/template/send?access_token=$access_token"
else
logger -t "【wxsend推送】" "获取 Access token 错误，请看看哪里问题？"
fi
}

if [ ! -z "$PATH_INFO" ] && [ ! -z "$GATEWAY_INTERFACE" ] ; then
#source /etc/storage/script/init.sh
wxsend_title="$(echo -n "$PATH_INFO" | awk -F "/" '{print $2}')"
wxsend_content="$(echo -n "$PATH_INFO" | awk -F "/" '{print $3}')"
PATH_INFO=""
GATEWAY_INTERFACE=""
logger -t "【wxsend推送】" "API 消息标题: $wxsend_title"
logger -t "【wxsend推送】" "API 消息内容: $wxsend_content"
send_message "$wxsend_title" "$wxsend_content"
exit 0
fi

wxsend_title="$(nvram get app_130)"
wxsend_content="$(nvram get app_131)"
# 在线发送wxsend推送
if [ ! -z "$wxsend_title" ] || [ ! -z "$wxsend_content" ] ; then
if [ ! -z "$wxsend_appid" ] && [ ! -z "$wxsend_appsecret" ] && [ ! -z "$wxsend_touser" ] && [ ! -z "$wxsend_template_id" ] ; then
	curltest=`which curl`
	if [ -z "$curltest" ] ; then
		/etc/storage/script/Sh01_mountopt.sh optwget
	fi
	curltest=`which curl`
	if [ -z "$curltest" ] ; then
		logger -t "【wxsend推送】" "未找到 curl 程序，停止 wxsend推送。需要手动安装 opt 后输入[opkg update; opkg install curl]安装"
		nvram set app_130=""
		nvram set app_131=""
	else
		send_message "$wxsend_title" "$wxsend_content"
		logger -t "【wxsend推送】" "消息标题: $wxsend_title"
		logger -t "【wxsend推送】" "消息内容: $wxsend_content"
		nvram set app_130=""
		nvram set app_131=""
	fi
else
logger -t "【wxsend推送】" "发送失败, 注意检[测试号信息]是否完填写整!!!"
fi
fi

if [ ! -z "$(echo $scriptfilepath | grep -v "/tmp/script/" | grep wx_send)" ]  && [ ! -s /tmp/script/_app22 ]; then
	mkdir -p /tmp/script
	{ echo '#!/bin/sh' ; echo $scriptfilepath '"$@"' '&' ; } > /tmp/script/_app22
	chmod 777 /tmp/script/_app22
fi

wxsend_restart () {

relock="/var/lock/wxsend_restart.lock"
if [ "$1" = "o" ] ; then
	nvram set wxsend_renum="0"
	[ -f $relock ] && rm -f $relock
	return 0
fi
if [ "$1" = "x" ] ; then
	if [ -f $relock ] ; then
		logger -t "【wxsend】" "多次尝试启动失败，等待【"`cat $relock`"分钟】后自动尝试重新启动"
		exit 0
	fi
	wxsend_renum=${wxsend_renum:-"0"}
	wxsend_renum=`expr $wxsend_renum + 1`
	nvram set wxsend_renum="$wxsend_renum"
	if [ "$wxsend_renum" -gt "2" ] ; then
		I=19
		echo $I > $relock
		logger -t "【wxsend】" "多次尝试启动失败，等待【"`cat $relock`"分钟】后自动尝试重新启动"
		while [ $I -gt 0 ]; do
			I=$(($I - 1))
			echo $I > $relock
			sleep 60
			[ "$(nvram get wxsend_renum)" = "0" ] && exit 0
			[ $I -lt 0 ] && break
		done
		nvram set wxsend_renum="0"
	fi
	[ -f $relock ] && rm -f $relock
fi
nvram set wxsend_status=0
eval "$scriptfilepath &"
exit 0
}

wxsend_get_status () {

A_restart=`nvram get wxsend_status`
B_restart="$wxsend_enable$wxsend_port$tmall_enable$wxsend_appid$wxsend_appsecret$wxsend_touser$wxsend_template_id$wxsend_cgi$wxsend_notify_1$wxsend_notify_2$wxsend_notify_3$wxsend_notify_4$(cat /etc/storage/app_30.sh | grep -v '^#' | grep -v "^$")$(cat /etc/storage/app_31.sh | grep -v '^#' | grep -v "^$")"
B_restart=`echo -n "$B_restart" | md5sum | sed s/[[:space:]]//g | sed s/-//g`
if [ "$A_restart" != "$B_restart" ] ; then
	nvram set wxsend_status=$B_restart
	needed_restart=1
else
	needed_restart=0
fi
}

wxsend_check () {

wxsend_get_status
if [ "$wxsend_enable" != "1" ] && [ "$needed_restart" = "1" ] ; then
	[ "$wxsend_port" != "0" ] && [ "$tmall_enable" == "0" ] && [ ! -z "$(ps -w | grep "caddy_tmall" | grep -v grep )" ] && logger -t "【wxsend推送】" "停止 caddy"
	[ ! -z "$(ps -w | grep "app_30" | grep -v grep )" ] && logger -t "【wxsend推送】" "停止 wxsend" && wxsend_close
	{ kill_ps "$scriptname" exit0; exit 0; }
fi
if [ "$wxsend_enable" = "1" ] ; then
	if [ "$needed_restart" = "1" ] ; then
		wxsend_close
		wxsend_start
	else
		[ "$wxsend_port" != "0" ] && [ "$tmall_enable" == "0" ] && [ -z "$(ps -w | grep "caddy_tmall" | grep -v grep )" ] && wxsend_restart
		[ -z "$(ps -w | grep "app_30" | grep -v grep )" ] || [ ! -s "`which curl`" ] && wxsend_restart
	fi
fi
}

wxsend_keep () {
logger -t "【wxsend推送】" "守护进程启动"
if [ -s /tmp/script/_opt_script_check ]; then
sed -Ei '/【wxsend推送】|^$/d' /tmp/script/_opt_script_check
cat >> "/tmp/script/_opt_script_check" <<-OSC
	NUM=\`grep "/etc/storage/app_30.sh" /tmp/ps | grep -v grep |wc -l\` # 【wxsend推送】
	if [ "\$NUM" -lt "1" ] || [ ! -s "/etc/storage/app_30.sh" ] || [ ! -s "`which curl`" ] ; then # 【wxsend推送】
		logger -t "【wxsend推送】" "重新启动\$NUM" # 【wxsend推送】
		nvram set wxsend_status=04 && eval "$scriptfilepath &" && sed -Ei '/【wxsend推送】|^$/d' /tmp/script/_opt_script_check # 【wxsend推送】
	fi # 【wxsend推送】
OSC
if [ "$wxsend_port" != "0" ] && [ "$tmall_enable" == "0" ] ; then
cat >> "/tmp/script/_opt_script_check" <<-OSC
	[ -z "\`pidof caddy_tmall\`" ] || [ ! -s "/opt/tmall/caddy_tmall" ] && nvram set wxsend_status=00 && logger -t "【wxsend推送】" "重新启动" && eval "$scriptfilepath &" && sed -Ei '/【wxsend推送】|^$/d' /tmp/script/_opt_script_check # 【wxsend推送】
OSC
fi
#return
fi
sleep 60
while true; do
	[ ! -s "`which curl`" ] && { logger -t "【wxsend推送】" "重新启动"; wxsend_restart ; }
	if [ -z "$(ps -w | grep "app_30" | grep -v grep )" ] ; then
		logger -t "【wxsend推送】" "重新启动"
		wxsend_restart
	fi
	
sleep 3600
killall app_30.sh
killall -9 app_30.sh
/etc/storage/app_30.sh &
done
}

wxsend_close () {
kill_ps "$scriptname keep"
sed -Ei '/【wxsend推送】|^$/d' /tmp/script/_opt_script_check
killall app_30.sh
killall -9 app_30.sh
[ "$tmall_enable" == "0" ] && killall caddy_tmall
[ "$tmall_enable" == "0" ] && killall -9 caddy_tmall
kill_ps "/tmp/script/_app22"
kill_ps "_wx_send.sh"
kill_ps "$scriptname"
}

wxsend_start () {
check_webui_yes
curltest=`which curl`
if [ -z "$curltest" ] || [ ! -s "`which curl`" ] ; then
	logger -t "【wxsend推送】" "找不到 curl ，安装 opt 程序"
	/etc/storage/script/Sh01_mountopt.sh optwget
	initopt
	curltest=`which curl`
	if [ -z "$curltest" ] || [ ! -s "`which curl`" ] ; then
		logger -t "【wxsend推送】" "找不到 curl ，需要手动安装 opt 后输入[opkg update; opkg install curl]安装"
		logger -t "【wxsend推送】" "启动失败, 10 秒后自动尝试重新启动" && sleep 10 && wxsend_restart x
	fi
fi
[ -z "$wxsend_appid" ] || [ -z "$wxsend_appsecret" ] || [ -z "$wxsend_touser" ] || [ -z "$wxsend_template_id" ] && { logger -t "【wxsend推送】" "启动失败, 注意检[测试号信息]是否完填写整,10 秒后自动尝试重新启动" && sleep 10 && wxsend_restart x ; }
logger -t "【wxsend推送】" "运行 /etc/storage/app_30.sh"
/etc/storage/app_30.sh &
sleep 3
[ ! -z "$(ps -w | grep "app_30" | grep -v grep )" ] && logger -t "【wxsend推送】" "启动成功" && wxsend_restart o
[ -z "$(ps -w | grep "app_30" | grep -v grep )" ] && logger -t "【wxsend推送】" "启动失败, 注意检app_30.sh脚本和curl是否下载完整,10 秒后自动尝试重新启动" && sleep 10 && wxsend_restart x
# caddy1
if [ "$wxsend_port" != "0" ] ; then
logger -t "【wxsend推送】" "部署 api 提供外部程序使用消息推送"
# 生成配置文件 /etc/storage/app_31.sh
sed -e "s@^:.\+\({\)@:$wxsend_port {@g" -i /etc/storage/app_31.sh
sed -e "s@^.\+cgi /.\+\(\#\)@ cgi /$wxsend_cgi /etc/storage/script/Sh45_wx_send.sh \#@g" -i /etc/storage/app_31.sh
sed -e "s@^cgi /.\+\(\#\)@ cgi /$wxsend_cgi /etc/storage/script/Sh45_wx_send.sh \#@g" -i /etc/storage/app_31.sh
if [ "$tmall_enable" == "0" ] ; then
SVC_PATH="/opt/tmall/caddy_tmall"
if [ ! -s "$SVC_PATH" ] ; then
	logger -t "【wxsend推送】" "找不到 $SVC_PATH，安装 opt 程序"
	/etc/storage/script/Sh01_mountopt.sh start
	initopt
fi
mkdir -p "/opt/tmall/www"
wgetcurl_file "$SVC_PATH" "$hiboyfile/caddy1" "$hiboyfile2/caddy1"
[ -z "$($SVC_PATH -plugins 2>&1 | grep http.cgi)" ] && rm -rf $SVC_PATH ;
wgetcurl_file "$SVC_PATH" "$hiboyfile/caddy1" "$hiboyfile2/caddy1"
if [ ! -s "$SVC_PATH" ] ; then
	logger -t "【wxsend推送】" "找不到 $SVC_PATH ，需要手动安装 $SVC_PATH"
	logger -t "【wxsend推送】" "启动失败, 10 秒后自动尝试重新启动" && sleep 10 && wxsend_restart x
fi
rm -f /opt/tmall/Caddyfile
cat /etc/storage/app_31.sh >> /opt/tmall/Caddyfile
eval "/opt/tmall/caddy_tmall -conf /opt/tmall/Caddyfile $cmd_log" &
sleep 3
[ ! -z "$(ps -w | grep "caddy_tmall" | grep -v grep )" ] && logger -t "【wxsend推送】" "部署 api 启动成功" && wxsend_restart o
[ -z "$(ps -w | grep "caddy_tmall" | grep -v grep )" ] && logger -t "【wxsend推送】" "部署 api 启动失败, 注意检caddy_tmall是否下载完整,10 秒后自动尝试重新启动" && sleep 10 && wxsend_restart x
else
logger -t "【wxsend推送】" "由于已经启动 tmall ，自定义 Caddyfile cgi 配置待 tmall 脚本导入启动。"
fi
fi
wxsend_get_status
eval "$scriptfilepath keep &"
exit 0
}

initopt () {
optPath=`grep ' /opt ' /proc/mounts | grep tmpfs`
[ ! -z "$optPath" ] && return
if [ ! -z "$(echo $scriptfilepath | grep -v "/opt/etc/init")" ] && [ -s "/opt/etc/init.d/rc.func" ] ; then
	{ echo '#!/bin/sh' ; echo $scriptfilepath '"$@"' '&' ; } > /opt/etc/init.d/$scriptname && chmod 777  /opt/etc/init.d/$scriptname
fi

}

initconfig () {

app_30="/etc/storage/app_30.sh"
if [ ! -f "$app_30" ] || [ ! -s "$app_30" ] ; then
	cat > "$app_30" <<-\EEE
#!/bin/sh
# 此脚本路径：/etc/storage/app_30.sh
# 自定义设置 - 脚本 - 自定义 Crontab 定时任务配置，可自定义启动时间
source /etc/storage/script/init.sh
export PATH='/etc/storage/bin:/tmp/script:/etc/storage/script:/opt/usr/sbin:/opt/usr/bin:/opt/sbin:/opt/bin:/usr/local/sbin:/usr/sbin:/usr/bin:/sbin:/bin'
export LD_LIBRARY_PATH=/lib:/opt/lib
wxsend_enable=`nvram get app_123`
wxsend_enable=${wxsend_enable:-"0"}
wxsend_notify_1=`nvram get app_49`
wxsend_notify_2=`nvram get app_50`
wxsend_notify_3=`nvram get app_51`
wxsend_notify_4=`nvram get app_52`
mkdir -p /tmp/var
resub=1
# 获得外网地址
    arIpAddress() {
    curltest=`which curl`
    if [ -z "$curltest" ] || [ ! -s "`which curl`" ] ; then
        #wget -T 5 -t 3 --user-agent "$user_agent" --quiet --output-document=- "https://www.ipip.net" | grep "IP地址" | grep -E -o '([0-9]+\.){3}[0-9]+' | head -n1 | cut -d' ' -f1
        wget -T 5 -t 3 --user-agent "$user_agent" --quiet --output-document=- "http://members.3322.org/dyndns/getip" | grep -E -o '([0-9]+\.){3}[0-9]+' | head -n1 | cut -d' ' -f1
        #wget -T 5 -t 3 --user-agent "$user_agent" --quiet --output-document=- "ip.3322.net" | grep -E -o '([0-9]+\.){3}[0-9]+' | head -n1 | cut -d' ' -f1
        #wget -T 5 -t 3 --user-agent "$user_agent" --quiet --output-document=- "http://pv.sohu.com/cityjson?ie=utf-8" | grep -E -o '([0-9]+\.){3}[0-9]+' | head -n1 | cut -d' ' -f1
    else
        #curl -L --user-agent "$user_agent" -s "https://www.ipip.net" | grep "IP地址" | grep -E -o '([0-9]+\.){3}[0-9]+' | head -n1 | cut -d' ' -f1
        curl -L --user-agent "$user_agent" -s "http://members.3322.org/dyndns/getip" | grep -E -o '([0-9]+\.){3}[0-9]+' | head -n1 | cut -d' ' -f1
        #curl -L --user-agent "$user_agent" -s ip.3322.net | grep -E -o '([0-9]+\.){3}[0-9]+' | head -n1 | cut -d' ' -f1
        #curl -L --user-agent "$user_agent" -s http://pv.sohu.com/cityjson?ie=utf-8 | grep -E -o '([0-9]+\.){3}[0-9]+' | head -n1 | cut -d' ' -f1
    fi
    }
# 读取最近外网地址
    lastIPAddress() {
        inter="/etc/storage/wxsend_lastIPAddress"
        cat $inter
    }

while [ "$wxsend_enable" = "1" ];
do
wxsend_enable=`nvram get app_123`
wxsend_enable=${wxsend_enable:-"0"}
wxsend_notify_1=`nvram get app_49`
wxsend_notify_2=`nvram get app_50`
wxsend_notify_3=`nvram get app_51`
wxsend_notify_4=`nvram get app_52`
curltest=`which curl`
ping_text=`ping -4 223.5.5.5 -c 1 -w 2 -q`
ping_time=`echo $ping_text | awk -F '/' '{print $4}'| awk -F '.' '{print $1}'`
ping_loss=`echo $ping_text | awk -F ', ' '{print $3}' | awk '{print $1}'`
if [ ! -z "$ping_time" ] ; then
    echo "ping：$ping_time ms 丢包率：$ping_loss"
 else
    echo "ping：失效"
fi
if [ ! -z "$ping_time" ] ; then
echo "online"
if [ "$wxsend_notify_1" = "1" ] ; then
    hostIP=$(arIpAddress)
    hostIP=`echo $hostIP | head -n1 | cut -d' ' -f1`
    if [ "$hostIP"x = "x"  ] ; then
        curltest=`which curl`
        if [ -z "$curltest" ] || [ ! -s "`which curl`" ] ; then
            [ "$hostIP"x = "x"  ] && hostIP=`wget -T 5 -t 3 --user-agent "$user_agent" --quiet --output-document=- "http://members.3322.org/dyndns/getip" | grep -E -o '([0-9]+\.){3}[0-9]+' | head -n1 | cut -d' ' -f1`
            [ "$hostIP"x = "x"  ] && hostIP=`wget -T 5 -t 3 --user-agent "$user_agent" --quiet --output-document=- "ip.3322.net" | grep -E -o '([0-9]+\.){3}[0-9]+' | head -n1 | cut -d' ' -f1`
            [ "$hostIP"x = "x"  ] && hostIP=`wget -T 5 -t 3 --user-agent "$user_agent" --quiet --output-document=- "https://www.ipip.net/" | grep "IP地址" | grep -E -o '([0-9]+\.){3}[0-9]+' | head -n1 | cut -d' ' -f1`
            [ "$hostIP"x = "x"  ] && hostIP=`wget -T 5 -t 3 --user-agent "$user_agent" --quiet --output-document=- "http://pv.sohu.com/cityjson?ie=utf-8" | grep -E -o '([0-9]+\.){3}[0-9]+' | head -n1 | cut -d' ' -f1`
        else
            [ "$hostIP"x = "x"  ] && hostIP=`curl -L --user-agent "$user_agent" -s "http://members.3322.org/dyndns/getip" | grep -E -o '([0-9]+\.){3}[0-9]+' | head -n1 | cut -d' ' -f1`
            [ "$hostIP"x = "x"  ] && hostIP=`curl -L --user-agent "$user_agent" -s ip.3322.net | grep -E -o '([0-9]+\.){3}[0-9]+' | head -n1 | cut -d' ' -f1`
            [ "$hostIP"x = "x"  ] && hostIP=`curl -L --user-agent "$user_agent" -s "https://www.ipip.net" | grep "IP地址" | grep -E -o '([0-9]+\.){3}[0-9]+' | head -n1 | cut -d' ' -f1`
            [ "$hostIP"x = "x"  ] && hostIP=`curl -L --user-agent "$user_agent" -s http://pv.sohu.com/cityjson?ie=utf-8 | grep -E -o '([0-9]+\.){3}[0-9]+' | head -n1 | cut -d' ' -f1`
        fi
    fi
    lastIP=$(lastIPAddress)
    if [ "$lastIP" != "$hostIP" ] && [ ! -z "$hostIP" ] ; then
    sleep 60
        hostIP=$(arIpAddress)
        hostIP=`echo $hostIP | head -n1 | cut -d' ' -f1`
        lastIP=$(lastIPAddress)
    fi
    if [ "$lastIP" != "$hostIP" ] && [ ! -z "$hostIP" ] ; then
        logger -t "【互联网 IP 变动】" "目前 IP: ${hostIP}"
        logger -t "【互联网 IP 变动】" "上次 IP: ${lastIP}"
        Sh45_wx_send.sh send_message "【PDCN_`nvram get computer_name`】互联网IP变动" "${hostIP}" &
        logger -t "【wxsend推送】" "互联网IP变动:${hostIP}"
        echo -n $hostIP > /etc/storage/wxsend_lastIPAddress
    fi
fi
if [ "$wxsend_notify_2" = "1" ] ; then
    # 获取接入设备名称
    touch /tmp/var/wxsend_newhostname.txt
    echo "接入设备名称" > /tmp/var/wxsend_newhostname.txt
    #cat /tmp/syslog.log | grep 'Found new hostname' | awk '{print $7" "$8}' >> /tmp/var/wxsend_newhostname.txt
    cat /tmp/static_ip.inf | grep -v "^$" | awk -F "," '{ if ( $6 == 0 ) print "【内网IP："$1"，ＭＡＣ："$2"，名称："$3"】  "}' >> /tmp/var/wxsend_newhostname.txt
    # 读取以往接入设备名称
    touch /etc/storage/wxsend_hostname.txt
    [ ! -s /etc/storage/wxsend_hostname.txt ] && echo "接入设备名称" > /etc/storage/wxsend_hostname.txt
    # 获取新接入设备名称
    awk 'NR==FNR{a[$0]++} NR>FNR&&a[$0]' /etc/storage/wxsend_hostname.txt /tmp/var/wxsend_newhostname.txt > /tmp/var/wxsend_newhostname相同行.txt
    awk 'NR==FNR{a[$0]++} NR>FNR&&!a[$0]' /tmp/var/wxsend_newhostname相同行.txt /tmp/var/wxsend_newhostname.txt > /tmp/var/wxsend_newhostname不重复.txt
    if [ -s "/tmp/var/wxsend_newhostname不重复.txt" ] ; then
        content=`cat /tmp/var/wxsend_newhostname不重复.txt | grep -v "^$"`
        Sh45_wx_send.sh send_message "【PDCN_`nvram get computer_name`】新设备加入" "${content}" &
        logger -t "【wxsend推送】" "PDCN新设备加入:${content}"
        cat /tmp/var/wxsend_newhostname不重复.txt | grep -v "^$" >> /etc/storage/wxsend_hostname.txt
    fi
fi
if [ "$wxsend_notify_4" = "1" ] ; then
    # 设备上、下线提醒
    # 获取接入设备名称
    touch /tmp/var/wxsend_newhostname.txt
    echo "接入设备名称" > /tmp/var/wxsend_newhostname.txt
    #cat /tmp/syslog.log | grep 'Found new hostname' | awk '{print $7" "$8}' >> /tmp/var/wxsend_newhostname.txt
    cat /tmp/static_ip.inf | grep -v "^$" | awk -F "," '{ if ( $6 == 0 ) print "【内网IP："$1"，ＭＡＣ："$2"，名称："$3"】  "}' >> /tmp/var/wxsend_newhostname.txt
    # 读取以往上线设备名称
    touch /etc/storage/wxsend_hostname_上线.txt
    [ ! -s /etc/storage/wxsend_hostname_上线.txt ] && echo "接入设备名称" > /etc/storage/wxsend_hostname_上线.txt
    # 上线
    awk 'NR==FNR{a[$0]++} NR>FNR&&a[$0]' /etc/storage/wxsend_hostname_上线.txt /tmp/var/wxsend_newhostname.txt > /tmp/var/wxsend_newhostname相同行_上线.txt
    awk 'NR==FNR{a[$0]++} NR>FNR&&!a[$0]' /tmp/var/wxsend_newhostname相同行_上线.txt /tmp/var/wxsend_newhostname.txt > /tmp/var/wxsend_newhostname不重复_上线.txt
    if [ -s "/tmp/var/wxsend_newhostname不重复_上线.txt" ] ; then
        content=`cat /tmp/var/wxsend_newhostname不重复_上线.txt | grep -v "^$"`
        Sh45_wx_send.sh send_message "【PDCN_`nvram get computer_name`】设备【上线】Online" "${content}" &
        logger -t "【wxsend推送】" "PDCN设备【上线】:${content}"
        cat /tmp/var/wxsend_newhostname不重复_上线.txt | grep -v "^$" >> /etc/storage/wxsend_hostname_上线.txt
    fi
    # 下线
    awk 'NR==FNR{a[$0]++} NR>FNR&&!a[$0]' /tmp/var/wxsend_newhostname.txt /etc/storage/wxsend_hostname_上线.txt > /tmp/var/wxsend_newhostname不重复_下线.txt
    if [ -s "/tmp/var/wxsend_newhostname不重复_下线.txt" ] ; then
        content=`cat /tmp/var/wxsend_newhostname不重复_下线.txt | grep -v "^$"`
        Sh45_wx_send.sh send_message "【PDCN_`nvram get computer_name`】设备【下线】offline" "${content}" &
        logger -t "【wxsend推送】" "PDCN设备【下线】:${content}"
        cat /tmp/var/wxsend_newhostname.txt | grep -v "^$" > /etc/storage/wxsend_hostname_上线.txt
    fi
fi
if [ "$wxsend_notify_3" = "1" ] && [ "$resub" = "1" ] ; then
    # 固件更新提醒
    [ ! -f /tmp/var/wxsend_osub ] && echo -n `nvram get firmver_sub` > /tmp/var/wxsend_osub
    rm -f /tmp/var/wxsend_nsub
    wgetcurl.sh "/tmp/var/wxsend_nsub" "$hiboyfile/osub" "$hiboyfile2/osub"
    if [ "$(cat /tmp/var/wxsend_osub |head -n1)"x != "$(cat /tmp/var/wxsend_nsub |head -n1)"x ] && [ -f /tmp/var/wxsend_nsub ] ; then
        echo -n `nvram get firmver_sub` > /tmp/var/wxsend_osub
        content="新的固件： `cat /tmp/var/wxsend_nsub | grep -v "^$"` ，目前旧固件： `cat /tmp/var/wxsend_osub | grep -v "^$"` "
        logger -t "【wxsend推送】" "固件 新的更新：${content}"
        Sh45_wx_send.sh send_message "【PDCN_`nvram get computer_name`】固件更新提醒" "${content}" &
        echo -n `cat /tmp/var/wxsend_nsub | grep -v "^$"` > /tmp/var/wxsend_osub
    fi
fi
    resub=`expr $resub + 1`
    [ "$resub" -gt 360 ] && resub=1
else
echo "Internet down 互联网断线"
resub=1
fi
sleep 60
continue
done

EEE
	chmod 755 "$app_30"
fi


app_31="/etc/storage/app_31.sh"
if [ ! -f "$app_31" ] || [ ! -s "$app_31" ] ; then
	cat > "$app_31" <<-\EEE
# 此脚本路径：/etc/storage/app_31.sh
:0 {
 root /opt/tmall/www
 # cgi触发 /key
 #cgi /111111111111 /etc/storage/script/Sh45_wx_send.sh # 脚本自动生成/key
 log /opt/tmall/requests_wxsend.log {
 rotate_size 1
 }
}

EEE
	chmod 755 "$app_31"
fi


}

initconfig

update_init () {
source /etc/storage/script/init.sh
[ "$init_ver" -lt 0 ] && init_ver="0" || { [ "$init_ver" -ge 0 ] || init_ver="0" ; }
init_s_ver=2
if [ "$init_s_ver" -gt "$init_ver" ] ; then
	logger -t "【update_init】" "更新 /etc/storage/script/init.sh 文件"
	wgetcurl.sh /tmp/init_tmp.sh  "$hiboyscript/script/init.sh" "$hiboyscript2/script/init.sh"
	[ -s /tmp/init_tmp.sh ] && cp -f /tmp/init_tmp.sh /etc/storage/script/init.sh
	chmod 755 /etc/storage/script/init.sh
	source /etc/storage/script/init.sh
fi
}

update_app () {
update_init
mkdir -p /opt/app/wxsend
if [ "$1" = "del" ] ; then
	rm -rf /opt/app/wxsend/Advanced_Extensions_wxsend.asp
fi
#[ -z "$(cat /etc/storage/app_30.sh | grep send_message)" ] && rm -f /etc/storage/app_30.sh
initconfig

# 加载程序配置页面
if [ ! -f "/opt/app/wxsend/Advanced_Extensions_wxsend.asp" ] || [ ! -s "/opt/app/wxsend/Advanced_Extensions_wxsend.asp" ] ; then
	wgetcurl.sh /opt/app/wxsend/Advanced_Extensions_wxsend.asp "$hiboyfile/Advanced_Extensions_wxsendasp" "$hiboyfile2/Advanced_Extensions_wxsendasp"
fi
umount /www/Advanced_Extensions_app22.asp
mount --bind /opt/app/wxsend/Advanced_Extensions_wxsend.asp /www/Advanced_Extensions_app22.asp
# 更新程序启动脚本

[ "$1" = "del" ] && /etc/storage/www_sh/自建微信推送 del &
}

case $ACTION in
send_message)
	send_message "$2" "$3"
	;;
start)
	wxsend_close
	wxsend_check
	;;
check)
	wxsend_check
	;;
stop)
	wxsend_close
	;;
updateapp22)
	wxsend_restart o
	if [ "$wxsend_enable" = "1" ] ; then
		touch /etc/storage/wxsend_hostname.txt
		logger -t "【wxsend推送】" "清空以往接入设备名称：/etc/storage/wxsend_hostname.txt"
		echo "接入设备名称" > /etc/storage/wxsend_hostname.txt
	fi
	[ "$wxsend_enable" = "1" ] && nvram set wxsend_status="updatewxsend" && logger -t "【wxsend】" "重启" && wxsend_restart
	[ "$wxsend_enable" != "1" ] && nvram set wxsend_v="" && logger -t "【wxsend】" "更新" && update_app del
	;;
update_app)
	update_app
	;;
keep)
	#wxsend_check
	wxsend_keep
	;;
*)
	wxsend_check
	;;
esac

