#!/bin/bash
#copyright by hiboy
source /etc/storage/script/init.sh
tgbot_enable=`nvram get app_46`
[ -z $tgbot_enable ] && tgbot_enable=0 && nvram set app_46=0
tgbot_id=`nvram get app_47`
tgbot_api=`nvram get app_87`
[ -z $tgbot_api ] && tgbot_api="https://api.telegram.org" && nvram set app_87="$tgbot_api"
if [ "$tgbot_enable" != "0" ] ; then

tgbot_sckey=`nvram get app_48`
tgbot_notify_1=`nvram get app_49`
tgbot_notify_2=`nvram get app_50`
tgbot_notify_3=`nvram get app_51`
tgbot_notify_4=`nvram get app_52`
tgbot_renum=`nvram get tgbot_renum`

fi
tgbot_text=`nvram get app_53`
# 在线发送tgbot推送
if [ ! -z "$tgbot_id" ] && [ ! -z "$tgbot_text" ] && [ ! -z "$tgbot_sckey" ] ; then
	curltest=`which curl`
	if [ -z "$curltest" ] ; then
	/etc/storage/script/Sh01_mountopt.sh opt_mini_wget
	fi
	curltest=`which curl`
	if [ -z "$curltest" ] ; then
		logger -t "【tgbot推送】" "未找到 curl 程序，停止 tgbot推送。需要手动安装 opt 后输入[opkg update; opkg install curl]安装"
		nvram set app_53=""
	else
		curl -L -s "$tgbot_api/bot$tgbot_sckey/sendMessage?chat_id=$tgbot_id" --data-binary "&text=$tgbot_text" 
		logger -t "【tgbot推送】" "消息内容:$tgbot_text"
		nvram set app_53=""
		tgbot_text=""
	fi
fi

if [ ! -z "$(echo $scriptfilepath | grep -v "/tmp/script/" | grep tg_bot)" ] && [ ! -s /tmp/script/_app12 ] ; then
	mkdir -p /tmp/script
	{ echo '#!/bin/bash' ; echo $scriptfilepath '"$@"' '&' ; } > /tmp/script/_app12
	chmod 777 /tmp/script/_app12
fi

tgbot_restart () {
i_app_restart "$@" -name="tgbot"
}

tgbot_get_status () {

B_restart="$tgbot_enable$tgbot_api$tgbot_id$tgbot_sckey$tgbot_notify_1$tgbot_notify_2$tgbot_notify_3$tgbot_notify_4$(cat /etc/storage/app_10.sh | grep -v '^#' | grep -v '^$')"

i_app_get_status -name="tgbot" -valb="$B_restart"
}

tgbot_check () {

tgbot_get_status
if [ "$tgbot_enable" != "1" ] && [ "$needed_restart" = "1" ] ; then
	[ ! -z "$(ps -w | grep "app_10" | grep -v grep )" ] && logger -t "【tgbot推送】" "停止 tgbot" && tgbot_close
	{ kill_ps "$scriptname" exit0; exit 0; }
fi
if [ "$tgbot_enable" = "1" ] ; then
	if [ "$needed_restart" = "1" ] ; then
		tgbot_close
		tgbot_start
	else
		[ -z "$(ps -w | grep "app_10" | grep -v grep )" ] || [ ! -s "`which curl`" ] && tgbot_restart
	fi
fi
}

tgbot_keep () {
i_app_keep -name="tgbot" -pidof="app_10.sh" -cpath="$(which curl)" &
logger -t "【tgbot推送】" "守护进程启动"
sleep 60
while true; do
sleep 3600
killall app_10.sh
/etc/storage/app_10.sh &
done
}

tgbot_close () {
kill_ps "$scriptname keep"
sed -Ei '/【tgbot推送】|^$/d' /tmp/script/_opt_script_check
sed -Ei '/【tgbot】|^$/d' /tmp/script/_opt_script_check
killall app_10.sh
kill_ps "/tmp/script/_app12"
kill_ps "_tg_bot.sh"
kill_ps "$scriptname"
}

tgbot_start () {
check_webui_yes
curltest=`which curl`
if [ -z "$curltest" ] || [ ! -s "`which curl`" ] ; then
	logger -t "【tgbot推送】" "找不到 curl ，安装 opt mini 程序"
	/etc/storage/script/Sh01_mountopt.sh opt_mini_wget
	initopt
	curltest=`which curl`
	if [ -z "$curltest" ] || [ ! -s "`which curl`" ] ; then
		logger -t "【tgbot推送】" "找不到 curl ，需要手动安装 opt 后输入[opkg update; opkg install curl]安装"
		logger -t "【tgbot推送】" "启动失败, 10 秒后自动尝试重新启动" && sleep 10 && tgbot_restart x
	fi
fi
[ -z "$tgbot_id" ] || [ -z "$tgbot_sckey" ] && { logger -t "【tgbot推送】" "启动失败, 注意检[接收人ID]和[token]是否完整,10 秒后自动尝试重新启动" && sleep 10 && tgbot_restart x ; }
logger -t "【tgbot推送】" "运行 /etc/storage/app_10.sh"
/etc/storage/app_10.sh &
sleep 3
i_app_keep -t -name="tgbot" -pidof="app_10.sh"
#tgbot_get_status
eval "$scriptfilepath keep &"
exit 0
}

initconfig () {

app_10="/etc/storage/app_10.sh"
if [ ! -f "$app_10" ] || [ ! -s "$app_10" ] ; then
	cat > "$app_10" <<-\EEE
#!/bin/bash
# 此脚本路径：/etc/storage/app_10.sh
# 自定义设置 - 脚本 - 自定义 Crontab 定时任务配置，可自定义启动时间
source /etc/storage/script/init.sh
export PATH='/etc/storage/bin:/tmp/script:/etc/storage/script:/opt/usr/sbin:/opt/usr/bin:/opt/sbin:/opt/bin:/usr/local/sbin:/usr/sbin:/usr/bin:/sbin:/bin'
export LD_LIBRARY_PATH=/lib:/opt/lib
tgbot_enable=`nvram get app_46`
tgbot_enable=${tgbot_enable:-"0"}
tgbot_sckey=`nvram get app_48`
tgbot_id=`nvram get app_47`
tgbot_notify_1=`nvram get app_49`
tgbot_notify_2=`nvram get app_50`
tgbot_notify_3=`nvram get app_51`
tgbot_notify_4=`nvram get app_52`
tgbot_api=`nvram get app_87`
[ -z $tgbot_api ] && tgbot_api="https://api.telegram.org" && nvram set app_87="$tgbot_api"
user_agent='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36'
mkdir -p /tmp/var
resub=1
# 获得外网地址
    arIpAddress() {
    curltest=`which curl`
    if [ -z "$curltest" ] || [ ! -s "`which curl`" ] ; then
        #wget -T 5 -t 3 --user-agent "$user_agent" --quiet --output-document=- "http://myip.ipip.net" | grep "当前 IP" | grep -E -o '([0-9]+\.){3}[0-9]+' | head -n1 | cut -d' ' -f1
        wget -T 5 -t 3 --user-agent "$user_agent" --quiet --output-document=- "http://members.3322.org/dyndns/getip" | grep -E -o '([0-9]+\.){3}[0-9]+' | head -n1 | cut -d' ' -f1
        #wget -T 5 -t 3 --user-agent "$user_agent" --quiet --output-document=- "ip.3322.net" | grep -E -o '([0-9]+\.){3}[0-9]+' | head -n1 | cut -d' ' -f1
        #wget -T 5 -t 3 --user-agent "$user_agent" --quiet --output-document=- "http://ddns.oray.com/checkip" | grep -E -o '([0-9]+\.){3}[0-9]+' | head -n1 | cut -d' ' -f1
    else
        #curl -L --user-agent "$user_agent" -s "http://myip.ipip.net" | grep "当前 IP" | grep -E -o '([0-9]+\.){3}[0-9]+' | head -n1 | cut -d' ' -f1
        curl -L --user-agent "$user_agent" -s "http://members.3322.org/dyndns/getip" | grep -E -o '([0-9]+\.){3}[0-9]+' | head -n1 | cut -d' ' -f1
        #curl -L --user-agent "$user_agent" -s ip.3322.net | grep -E -o '([0-9]+\.){3}[0-9]+' | head -n1 | cut -d' ' -f1
        #curl -L --user-agent "$user_agent" -s http://ddns.oray.com/checkip | grep -E -o '([0-9]+\.){3}[0-9]+' | head -n1 | cut -d' ' -f1
    fi
    }
    arIpAddress6 () {
    # IPv6地址获取
    # 因为一般ipv6没有nat ipv6的获得可以本机获得
    #ifconfig $(nvram get wan0_ifname_t) | awk '/Global/{print $3}' | awk -F/ '{print $1}'
    if [ -z "$curltest" ] || [ ! -s "`which curl`" ] ; then
        wget -T 5 -t 3 --user-agent "$user_agent" --quiet --output-document=- "https://[2606:4700:4700::1002]/cdn-cgi/trace" | awk -F= '/ip/{print $2}'
        #wget -T 5 -t 3 --user-agent "$user_agent" --quiet --output-document=- "https://ipv6.icanhazip.com"
    else
        curl -6 -L --user-agent "$user_agent" -s "https://[2606:4700:4700::1002]/cdn-cgi/trace" | awk -F= '/ip/{print $2}'
        #curl -6 -L --user-agent "$user_agent" -s "https://ipv6.icanhazip.com"
    fi
    }
# 读取最近外网地址
    lastIPAddress() {
        inter="/etc/storage/tgbot_lastIPAddress"
        touch $inter
        cat $inter
    }
    lastIPAddress6() {
        inter="/etc/storage/tgbot_lastIPAddress6"
        touch $inter
        cat $inter
    }

while [ "$tgbot_enable" = "1" ];
do
tgbot_enable=`nvram get app_46`
tgbot_enable=${tgbot_enable:-"0"}
tgbot_sckey=`nvram get app_48`
tgbot_id=`nvram get app_47`
tgbot_notify_1=`nvram get app_49`
tgbot_notify_2=`nvram get app_50`
tgbot_notify_3=`nvram get app_51`
tgbot_notify_4=`nvram get app_52`
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
if [ "$tgbot_notify_1" = "1" ] || [ "$tgbot_notify_1" = "3" ] ; then
    hostIP=$(arIpAddress)
    hostIP=`echo $hostIP | head -n1 | cut -d' ' -f1`
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
    fi
    lastIP=$(lastIPAddress)
    if [ "$lastIP" != "$hostIP" ] && [ ! -z "$hostIP" ] ; then
    sleep 60
        hostIP=$(arIpAddress)
        hostIP=`echo $hostIP | head -n1 | cut -d' ' -f1`
        lastIP=$(lastIPAddress)
    fi
    if [ "$lastIP" != "$hostIP" ] && [ ! -z "$hostIP" ] ; then
        logger -t "【互联网 IPv4 变动】" "目前 IPv4: ${hostIP}"
        logger -t "【互联网 IPv4 变动】" "上次 IPv4: ${lastIP}"
        curl -L -s "$tgbot_api/bot$tgbot_sckey/sendMessage?chat_id=$tgbot_id" --data-binary "&text=【PDCN_"`nvram get computer_name`"】互联网IP变动""`echo -e " \n "`""${hostIP}" &
        logger -t "【tgbot推送】" "互联网IPv4变动:${hostIP}"
        echo -n $hostIP > /etc/storage/tgbot_lastIPAddress
    fi
fi
if [ "$tgbot_notify_1" = "2" ] || [ "$tgbot_notify_1" = "3" ] ; then
    hostIP6=$(arIpAddress6)
    hostIP6=`echo $hostIP6 | head -n1 | cut -d' ' -f1`
    lastIP6=$(lastIPAddress6)
    if [ "$lastIP6" != "$hostIP6" ] && [ ! -z "$hostIP6" ] ; then
        logger -t "【互联网 IPv6 变动】" "目前 IPv6: ${hostIP6}"
        logger -t "【互联网 IPv6 变动】" "上次 IPv6: ${lastIP6}"
        curl -L -s "$tgbot_api/bot$tgbot_sckey/sendMessage?chat_id=$tgbot_id" --data-binary "&text=【PDCN_"`nvram get computer_name`"】互联网IP变动""`echo -e " \n "`""${hostIP6}" &
        logger -t "【tgbot推送】" "互联网IPv6变动:${hostIP6}"
        echo -n $hostIP > /etc/storage/tgbot_lastIPAddress6
    fi
fi
if [ "$tgbot_notify_2" = "1" ] ; then
    # 获取接入设备名称
    touch /tmp/var/tgbot_newhostname.txt
    echo "接入设备名称" > /tmp/var/tgbot_newhostname.txt
    #cat /tmp/syslog.log | grep 'Found new hostname' | awk '{print $7" "$8}' >> /tmp/var/tgbot_newhostname.txt
    cat /tmp/static_ip.inf | grep -v '^$' | awk -F "," '{ if ( $6 == 0 ) print "【内网IP："$1"，ＭＡＣ："$2"，名称："$3"】  "}' >> /tmp/var/tgbot_newhostname.txt
    # 读取以往接入设备名称
    touch /etc/storage/tgbot_hostname.txt
    [ ! -s /etc/storage/tgbot_hostname.txt ] && echo "接入设备名称" > /etc/storage/tgbot_hostname.txt
    # 获取新接入设备名称
    awk 'NR==FNR{a[$0]++} NR>FNR&&a[$0]' /etc/storage/tgbot_hostname.txt /tmp/var/tgbot_newhostname.txt > /tmp/var/tgbot_newhostname相同行.txt
    awk 'NR==FNR{a[$0]++} NR>FNR&&!a[$0]' /tmp/var/tgbot_newhostname相同行.txt /tmp/var/tgbot_newhostname.txt > /tmp/var/tgbot_newhostname不重复.txt
    if [ -s "/tmp/var/tgbot_newhostname不重复.txt" ] ; then
        content=`cat /tmp/var/tgbot_newhostname不重复.txt | grep -v '^$'`
        curl -L -s "$tgbot_api/bot$tgbot_sckey/sendMessage?chat_id=$tgbot_id" --data-binary "&text=【PDCN_"`nvram get computer_name`"】新设备加入""`echo -e " \n "`""${content}" &
        logger -t "【tgbot推送】" "PDCN新设备加入:${content}"
        cat /tmp/var/tgbot_newhostname不重复.txt | grep -v '^$' >> /etc/storage/tgbot_hostname.txt
    fi
fi
if [ "$tgbot_notify_4" = "1" ] ; then
    # 设备上、下线提醒
    # 获取接入设备名称
    touch /tmp/var/tgbot_newhostname.txt
    echo "接入设备名称" > /tmp/var/tgbot_newhostname.txt
    #cat /tmp/syslog.log | grep 'Found new hostname' | awk '{print $7" "$8}' >> /tmp/var/tgbot_newhostname.txt
    cat /tmp/static_ip.inf | grep -v '^$' | awk -F "," '{ if ( $6 == 0 ) print "【内网IP："$1"，ＭＡＣ："$2"，名称："$3"】  "}' >> /tmp/var/tgbot_newhostname.txt
    # 读取以往上线设备名称
    touch /etc/storage/tgbot_hostname_上线.txt
    [ ! -s /etc/storage/tgbot_hostname_上线.txt ] && echo "接入设备名称" > /etc/storage/tgbot_hostname_上线.txt
    # 上线
    awk 'NR==FNR{a[$0]++} NR>FNR&&a[$0]' /etc/storage/tgbot_hostname_上线.txt /tmp/var/tgbot_newhostname.txt > /tmp/var/tgbot_newhostname相同行_上线.txt
    awk 'NR==FNR{a[$0]++} NR>FNR&&!a[$0]' /tmp/var/tgbot_newhostname相同行_上线.txt /tmp/var/tgbot_newhostname.txt > /tmp/var/tgbot_newhostname不重复_上线.txt
    if [ -s "/tmp/var/tgbot_newhostname不重复_上线.txt" ] ; then
        content=`cat /tmp/var/tgbot_newhostname不重复_上线.txt | grep -v '^$'`
        curl -L -s "$tgbot_api/bot$tgbot_sckey/sendMessage?chat_id=$tgbot_id" --data-binary "&text=【PDCN_"`nvram get computer_name`"】设备【上线】Online""`echo -e " \n "`""${content}" &
        logger -t "【tgbot推送】" "PDCN设备【上线】:${content}"
        cat /tmp/var/tgbot_newhostname不重复_上线.txt | grep -v '^$' >> /etc/storage/tgbot_hostname_上线.txt
    fi
    # 下线
    awk 'NR==FNR{a[$0]++} NR>FNR&&!a[$0]' /tmp/var/tgbot_newhostname.txt /etc/storage/tgbot_hostname_上线.txt > /tmp/var/tgbot_newhostname不重复_下线.txt
    if [ -s "/tmp/var/tgbot_newhostname不重复_下线.txt" ] ; then
        content=`cat /tmp/var/tgbot_newhostname不重复_下线.txt | grep -v '^$'`
        curl -L -s "$tgbot_api/bot$tgbot_sckey/sendMessage?chat_id=$tgbot_id" --data-binary "&text=【PDCN_"`nvram get computer_name`"】设备【下线】offline""`echo -e " \n "`""${content}" &
        logger -t "【tgbot推送】" "PDCN设备【下线】:${content}"
        cat /tmp/var/tgbot_newhostname.txt | grep -v '^$' > /etc/storage/tgbot_hostname_上线.txt
    fi
fi
if [ "$tgbot_notify_3" = "1" ] && [ "$resub" = "1" ] ; then
    # 固件更新提醒
    [ ! -f /tmp/var/tgbot_osub ] && echo -n `nvram get firmver_sub` > /tmp/var/tgbot_osub
    rm -f /tmp/var/tgbot_nsub
    wgetcurl.sh "/tmp/var/tgbot_nsub" "$hiboyfile/osub" "$hiboyfile2/osub"
    [[ "$(cat /tmp/var/tgbot_nsub | wc -c)" -ge 20 ]] && echo "" /tmp/var/tgbot_nsub
    [ ! -z "$(cat /tmp/var/tgbot_nsub | grep '<' | grep '>')" ] && echo "" > /tmp/var/tgbot_nsub
    if [ "$(cat /tmp/var/tgbot_osub |head -n1)"x != "$(cat /tmp/var/tgbot_nsub |head -n1)"x ] && [ -f /tmp/var/tgbot_nsub ] ; then
        echo -n `nvram get firmver_sub` > /tmp/var/tgbot_osub
        content="新的固件： `cat /tmp/var/tgbot_nsub | grep -v '^$'` ，目前旧固件： `cat /tmp/var/tgbot_osub | grep -v '^$'` "
        logger -t "【tgbot推送】" "固件 新的更新：${content}"
        curl -L -s "$tgbot_api/bot$tgbot_sckey/sendMessage?chat_id=$tgbot_id" --data-binary "&text=【PDCN_"`nvram get computer_name`"】固件更新提醒""`echo -e " \n "`""${content}" &
        echo -n `cat /tmp/var/tgbot_nsub | grep -v '^$'` > /tmp/var/tgbot_osub
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
	chmod 755 "$app_10"
fi
sed -Ei 's@local @@g' $app_10

}

initconfig

update_app () {
mkdir -p /opt/app/tgbot
if [ "$1" = "update_asp" ] ; then
	rm -rf /opt/app/tgbot/Advanced_Extensions_tgbot.asp
fi
if [ "$1" = "del" ] ; then
	rm -rf /opt/app/tgbot/Advanced_Extensions_tgbot.asp
fi
[ -z "$(cat /etc/storage/app_10.sh | grep tgbot_api)" ] && rm -f /etc/storage/app_10.sh
initconfig

# 加载程序配置页面
if [ ! -f "/opt/app/tgbot/Advanced_Extensions_tgbot.asp" ] || [ ! -s "/opt/app/tgbot/Advanced_Extensions_tgbot.asp" ] ; then
	wgetcurl.sh /opt/app/tgbot/Advanced_Extensions_tgbot.asp "$hiboyfile/Advanced_Extensions_tgbotasp" "$hiboyfile2/Advanced_Extensions_tgbotasp"
fi
umount /www/Advanced_Extensions_app12.asp
mount --bind /opt/app/tgbot/Advanced_Extensions_tgbot.asp /www/Advanced_Extensions_app12.asp
# 更新程序启动脚本

[ "$1" = "del" ] && /etc/storage/www_sh/tgbot del &
}

case $ACTION in
start)
	tgbot_close
	tgbot_check
	;;
check)
	tgbot_check
	;;
stop)
	tgbot_close
	;;
updateapp12)
	tgbot_restart o
	if [ "$tgbot_enable" = "1" ] ; then
		touch /etc/storage/tgbot_hostname.txt
		logger -t "【tgbot推送】" "清空以往接入设备名称：/etc/storage/tgbot_hostname.txt"
		echo "接入设备名称" > /etc/storage/tgbot_hostname.txt
	fi
	[ "$tgbot_enable" = "1" ] && nvram set tgbot_status="updatetgbot" && logger -t "【tgbot】" "重启" && tgbot_restart
	[ "$tgbot_enable" != "1" ] && nvram set tgbot_v="" && logger -t "【tgbot】" "更新" && update_app del
	;;
update_app)
	update_app
	;;
update_asp)
	update_app update_asp
	;;
keep)
	#tgbot_check
	tgbot_keep
	;;
*)
	tgbot_check
	;;
esac

