#!/bin/bash
#copyright by hiboy
source /etc/storage/script/init.sh
gotify_enable=`nvram get app_140`
[ -z $gotify_enable ] && gotify_enable=0 && nvram set app_140=0
gotify_apptoken=`nvram get app_141`
gotify_url=`nvram get app_142`
gotify_title=`nvram get app_143`
[ -z "$gotify_title" ] && gotify_title=`nvram get computer_name` && nvram set app_143="$gotify_title"
[ -z "$gotify_title" ] && gotify_title="！" && nvram set app_143="$gotify_title"
gotify_content="$(nvram get app_144)"
if [ "$gotify_enable" != "0" ] ; then
[ -z "$gotify_url" ] && gotify_url="http://$(nvram get lan_ipaddr):8385" && nvram set app_142="$gotify_url"
gotify_notify_1=`nvram get app_49`
gotify_notify_2=`nvram get app_50`
gotify_notify_3=`nvram get app_51`
gotify_notify_4=`nvram get app_52`
gotify_renum=`nvram get gotify_renum`

fi

send_message () {

[ ! -z "$1" ] && gotify_title="$1"
[ ! -z "$2" ] && gotify_content="$2"
PRIORITY=5
gotify_content="$( echo "$gotify_content" | sed ":a;N;s@\n@  \\\n@g;ba")"
URL="$gotify_url/message?token=$gotify_apptoken"

curl -L -s --data '{"message": "'"${gotify_content}"'", "title": "'"${gotify_title}"'", "priority":'"${PRIORITY}"', "extras": {"client::display": {"contentType": "text/markdown"}}}' -H 'Content-Type: application/json' "$URL"

}

# 在线发送gotify推送
if [ ! -z "$gotify_content" ] ; then
if [ ! -z "$gotify_apptoken" ] ; then
	curltest=`which curl`
	if [ -z "$curltest" ] ; then
		/etc/storage/script/Sh01_mountopt.sh opt_mini_wget
	fi
	curltest=`which curl`
	if [ -z "$curltest" ] ; then
		logger -t "【gotify推送】" "未找到 curl 程序，停止 gotify推送。需要手动安装 opt 后输入[opkg update; opkg install curl]安装"
		nvram set app_144=""
	else
		send_message "$gotify_title" "$gotify_content"
		logger -t "【gotify推送】" "消息内容: $gotify_content"
		nvram set app_144=""
	fi
else
logger -t "【gotify推送】" "发送失败, 注意检[apptoken、url]是否完填写整!!!"
fi
fi

if [ ! -z "$(echo $scriptfilepath | grep -v "/tmp/script/" | grep go_tify)" ] && [ ! -s /tmp/script/_app27 ] ; then
	mkdir -p /tmp/script
	{ echo '#!/bin/bash' ; echo $scriptfilepath '"$@"' '&' ; } > /tmp/script/_app27
	chmod 777 /tmp/script/_app27
fi

gotify_restart () {
i_app_restart "$@" -name="gotify"
}

gotify_get_status () {

B_restart="$gotify_enable"

i_app_get_status -name="gotify" -valb="$B_restart"
}

gotify_check () {

gotify_get_status
if [ "$gotify_enable" != "1" ] && [ "$needed_restart" = "1" ] ; then
	[ ! -z "`pidof gotifyserver`" ] && [ ! -z "$(echo "$gotify_url" | grep "$(nvram get lan_ipaddr):")" ] && logger -t "【gotify推送】" "停止 gotifyserver" && gotify_close
	[ ! -z "$(ps -w | grep "app_36" | grep -v grep )" ] && logger -t "【gotify推送】" "停止 gotify" && gotify_close
	{ kill_ps "$scriptname" exit0; exit 0; }
fi
if [ "$gotify_enable" = "1" ] ; then
	if [ "$needed_restart" = "1" ] ; then
		gotify_close
		gotify_start
	else
		[ -z "`pidof gotifyserver`" ] || [ ! -s "/opt/gotify/gotifyserver" ] && [ ! -z "$(echo "$gotify_url" | grep "$(nvram get lan_ipaddr):")" ] && gotify_restart
		[ -z "$(ps -w | grep "app_36" | grep -v grep )" ] || [ ! -s "`which curl`" ] && gotify_restart
	fi
fi
[ "$needed_restart" = "0" ] && gotify_get_status2
}

gotify_get_status2 () {

B_restart="$gotify_enable$gotify_apptoken$gotify_url$gotify_notify_1$gotify_notify_2$gotify_notify_3$gotify_notify_4$gotify_title$(cat /etc/storage/app_36.sh | grep -v '^#' | grep -v '^$')"

i_app_get_status -name="gotify_2" -valb="$B_restart"
if [ "$needed_restart" = "1" ] ; then
	gotify_close2
	eval "$scriptfilepath keep &"
fi
}

gotify_keep () {
sleep 10
logger -t "【gotify推送】" "运行 /etc/storage/app_36.sh"
/etc/storage/app_36.sh &
i_app_keep -name="gotify" -pidof="app_36.sh" &
if [ ! -z "$(echo "$gotify_url" | grep "$(nvram get lan_ipaddr):")" ] ; then
i_app_keep -name="gotify" -pidof="gotifyserver" &
fi
}

gotify_close () {
kill_ps "$scriptname keep"
sed -Ei '/【gotify推送】|^$/d' /tmp/script/_opt_script_check
sed -Ei '/【gotify】|^$/d' /tmp/script/_opt_script_check
killall gotifyserver app_36.sh
kill_ps "/tmp/script/_app27"
kill_ps "_go_tify.sh"
kill_ps "$scriptname"
}

gotify_close2 () {
kill_ps "$scriptname keep"
sed -Ei '/【gotify推送】|^$/d' /tmp/script/_opt_script_check
sed -Ei '/【gotify】|^$/d' /tmp/script/_opt_script_check
killall app_36.sh
kill_ps "/tmp/script/_app27"
kill_ps "_go_tify.sh"
kill_ps "$scriptname"
}

gotify_start () {
check_webui_yes
if [ ! -z "$(echo "$gotify_url" | grep "$(nvram get lan_ipaddr):")" ] ; then
i_app_get_cmd_file -name="gotify" -cmd="/opt/gotify/gotifyserver" -cpath="/opt/gotify/gotifyserver" -down1="$hiboyfile/gotifyserver" -down2="$hiboyfile2/gotifyserver" -runh="x"
logger -t "【gotify推送】" "运行 /opt/gotify/gotifyserver"
logger -t "【gotify推送】" "配置文件 /opt/gotify/config.yml"
initconfig
cd /opt/gotify/
/opt/gotify/gotifyserver &
sleep 3
i_app_keep -t -name="gotify" -pidof="gotifyserver"
fi
gotify_get_status2
gotify_close2
eval "$scriptfilepath keep &"
exit 0
}

initconfig () {

config_yml="/opt/gotify/config.yml"
if [ -f "/opt/gotify/gotifyserver" ] ; then
if [ ! -f "$config_yml" ] || [ ! -s "$config_yml" ] ; then
logger -t "【gotify推送】" "name: admin # 默认用户的用户名"
logger -t "【gotify推送】" "pass: admin #默认用户的密码"
logger -t "【gotify推送】" "注意！！！登录后立即更改密码"
	cat > "$config_yml" <<-\EEE
# Example configuration file for the server.
# Save it to `config.yml` when edited

server:
  keepaliveperiodseconds: 0 # 0 = use Go default (15s); -1 = disable keepalive; set the interval in which keepalive packets will be sent. Only change this value if you know what you are doing.
  listenaddr: "" # the address to bind on, leave empty to bind on all addresses
  port: 8385 # the port the HTTP server will listen on

  ssl:
    enabled: false # if https should be enabled
    redirecttohttps: true # redirect to https if site is accessed by http
    listenaddr: "" # the address to bind on, leave empty to bind on all addresses
    port: 443 # the https port
    certfile: # the cert file (leave empty when using letsencrypt)
    certkey: # the cert key (leave empty when using letsencrypt)
    letsencrypt:
      enabled: false # if the certificate should be requested from letsencrypt
      accepttos: false # if you accept the tos from letsencrypt
      cache: data/certs # the directory of the cache from letsencrypt
      hosts: # the hosts for which letsencrypt should request certificates
#      - mydomain.tld
#      - myotherdomain.tld

  responseheaders: # response headers are added to every response (default: none)
#    X-Custom-Header: "custom value"

  cors: # Sets cors headers only when needed and provides support for multiple allowed origins. Overrides Access-Control-* Headers in response headers.
    alloworigins:
#      - ".+.example.com"
#      - "otherdomain.com"
    allowmethods:
#      - "GET"
#      - "POST"
    allowheaders:
#      - "Authorization"
#      - "content-type"
  stream:
    pingperiodseconds: 45 # the interval in which websocket pings will be sent. Only change this value if you know what you are doing.
    allowedorigins: # allowed origins for websocket connections (same origin is always allowed)
#      - ".+.example.com"
#      - "otherdomain.com"

database: # for database see (configure database section)
  dialect: sqlite3
  connection: data/gotify.db

defaultuser: # on database creation, gotify creates an admin user
  name: admin # the username of the default user
  pass: admin # the password of the default user
passstrength: 10 # the bcrypt password strength (higher = better but also slower)
uploadedimagesdir: data/images # the directory for storing uploaded images
pluginsdir: data/plugins # the directory where plugin resides
registration: false # enable registrations
EEE
	chmod 755 "$config_yml"
fi
fi

app_36="/etc/storage/app_36.sh"
if [ ! -f "$app_36" ] || [ ! -s "$app_36" ] ; then
	cat > "$app_36" <<-\EEE
#!/bin/bash
# 此脚本路径：/etc/storage/app_36.sh
# 自定义设置 - 脚本 - 自定义 Crontab 定时任务配置，可自定义启动时间
source /etc/storage/script/init.sh
export PATH='/etc/storage/bin:/tmp/script:/etc/storage/script:/opt/usr/sbin:/opt/usr/bin:/opt/sbin:/opt/bin:/usr/local/sbin:/usr/sbin:/usr/bin:/sbin:/bin'
export LD_LIBRARY_PATH=/lib:/opt/lib
gotify_enable=`nvram get app_140`
gotify_enable=${gotify_enable:-"0"}
gotify_notify_1=`nvram get app_49`
gotify_notify_2=`nvram get app_50`
gotify_notify_3=`nvram get app_51`
gotify_notify_4=`nvram get app_52`
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
        inter="/etc/storage/gotify_lastIPAddress"
        touch $inter
        cat $inter
    }
    lastIPAddress6() {
        inter="/etc/storage/gotify_lastIPAddress6"
        touch $inter
        cat $inter
    }

while [ "$gotify_enable" = "1" ];
do
gotify_enable=`nvram get app_140`
gotify_title=`nvram get app_143`
gotify_enable=${gotify_enable:-"0"}
gotify_notify_1=`nvram get app_49`
gotify_notify_2=`nvram get app_50`
gotify_notify_3=`nvram get app_51`
gotify_notify_4=`nvram get app_52`
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
if [ "$gotify_notify_1" = "1" ] || [ "$gotify_notify_1" = "3" ] ; then
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
        Sh86_go_tify.sh send_message "【""$gotify_title""】互联网IP变动" "${hostIP}" &
        logger -t "【gotify推送】" "互联网IPv4变动:${hostIP}"
        echo -n $hostIP > /etc/storage/gotify_lastIPAddress
    fi
fi
if [ "$gotify_notify_1" = "2" ] || [ "$gotify_notify_1" = "3" ] ; then
    hostIP6=$(arIpAddress6)
    hostIP6=`echo $hostIP6 | head -n1 | cut -d' ' -f1`
    lastIP6=$(lastIPAddress6)
    if [ "$lastIP6" != "$hostIP6" ] && [ ! -z "$hostIP6" ] ; then
        logger -t "【互联网 IPv6 变动】" "目前 IPv6: ${hostIP6}"
        logger -t "【互联网 IPv6 变动】" "上次 IPv6: ${lastIP6}"
        Sh86_go_tify.sh send_message "【""$gotify_title""】互联网IP变动" "${hostIP6}" &
        logger -t "【gotify推送】" "互联网IPv6变动:${hostIP6}"
        echo -n $hostIP6 > /etc/storage/gotify_lastIPAddress6
    fi
fi
if [ "$gotify_notify_2" = "1" ] ; then
    # 获取接入设备名称
    touch /tmp/var/gotify_newhostname.txt
    echo "接入设备名称" > /tmp/var/gotify_newhostname.txt
    #cat /tmp/syslog.log | grep 'Found new hostname' | awk '{print $7" "$8}' >> /tmp/var/gotify_newhostname.txt
    cat /tmp/static_ip.inf | grep -v '^$' | awk -F "," '{ if ( $6 == 0 ) print "内网IP："$1"，ＭＡＣ："$2"，名称："$3"  "}' >> /tmp/var/gotify_newhostname.txt
    # 读取以往接入设备名称
    touch /etc/storage/gotify_hostname.txt
    [ ! -s /etc/storage/gotify_hostname.txt ] && echo "接入设备名称" > /etc/storage/gotify_hostname.txt
    # 获取新接入设备名称
    awk 'NR==FNR{a[$0]++} NR>FNR&&a[$0]' /etc/storage/gotify_hostname.txt /tmp/var/gotify_newhostname.txt > /tmp/var/gotify_newhostname相同行.txt
    awk 'NR==FNR{a[$0]++} NR>FNR&&!a[$0]' /tmp/var/gotify_newhostname相同行.txt /tmp/var/gotify_newhostname.txt > /tmp/var/gotify_newhostname不重复.txt
    if [ -s "/tmp/var/gotify_newhostname不重复.txt" ] ; then
        content=`cat /tmp/var/gotify_newhostname不重复.txt | grep -v '^$'`
        Sh86_go_tify.sh send_message "【""$gotify_title""】新设备加入" "${content}" &
        logger -t "【gotify推送】" "PDCN新设备加入:${content}"
        cat /tmp/var/gotify_newhostname不重复.txt | grep -v '^$' >> /etc/storage/gotify_hostname.txt
    fi
fi
if [ "$gotify_notify_4" = "1" ] ; then
    # 设备上、下线提醒
    # 获取接入设备名称
    touch /tmp/var/gotify_newhostname.txt
    echo "接入设备名称" > /tmp/var/gotify_newhostname.txt
    #cat /tmp/syslog.log | grep 'Found new hostname' | awk '{print $7" "$8}' >> /tmp/var/gotify_newhostname.txt
    cat /tmp/static_ip.inf | grep -v '^$' | awk -F "," '{ if ( $6 == 0 ) print "内网IP："$1"，ＭＡＣ："$2"，名称："$3"  "}' >> /tmp/var/gotify_newhostname.txt
    # 读取以往上线设备名称
    touch /etc/storage/gotify_hostname_上线.txt
    [ ! -s /etc/storage/gotify_hostname_上线.txt ] && echo "接入设备名称" > /etc/storage/gotify_hostname_上线.txt
    # 上线
    awk 'NR==FNR{a[$0]++} NR>FNR&&a[$0]' /etc/storage/gotify_hostname_上线.txt /tmp/var/gotify_newhostname.txt > /tmp/var/gotify_newhostname相同行_上线.txt
    awk 'NR==FNR{a[$0]++} NR>FNR&&!a[$0]' /tmp/var/gotify_newhostname相同行_上线.txt /tmp/var/gotify_newhostname.txt > /tmp/var/gotify_newhostname不重复_上线.txt
    if [ -s "/tmp/var/gotify_newhostname不重复_上线.txt" ] ; then
        content=`cat /tmp/var/gotify_newhostname不重复_上线.txt | grep -v '^$'`
        Sh86_go_tify.sh send_message "【""$gotify_title""】设备【上线】ON" "${content}" &
        logger -t "【gotify推送】" "PDCN设备【上线】:${content}"
        cat /tmp/var/gotify_newhostname不重复_上线.txt | grep -v '^$' >> /etc/storage/gotify_hostname_上线.txt
    fi
    # 下线
    awk 'NR==FNR{a[$0]++} NR>FNR&&!a[$0]' /tmp/var/gotify_newhostname.txt /etc/storage/gotify_hostname_上线.txt > /tmp/var/gotify_newhostname不重复_下线.txt
    if [ -s "/tmp/var/gotify_newhostname不重复_下线.txt" ] ; then
        content=`cat /tmp/var/gotify_newhostname不重复_下线.txt | grep -v '^$'`
        Sh86_go_tify.sh send_message "【""$gotify_title""】设备【下线】OFF" "${content}" &
        logger -t "【gotify推送】" "PDCN设备【下线】:${content}"
        cat /tmp/var/gotify_newhostname.txt | grep -v '^$' > /etc/storage/gotify_hostname_上线.txt
    fi
fi
if [ "$gotify_notify_3" = "1" ] && [ "$resub" = "1" ] ; then
    # 固件更新提醒
    [ ! -f /tmp/var/gotify_osub ] && echo -n `nvram get firmver_sub` > /tmp/var/gotify_osub
    rm -f /tmp/var/gotify_nsub
    wgetcurl.sh "/tmp/var/gotify_nsub" "$hiboyfile/osub" "$hiboyfile2/osub"
    [[ "$(cat /tmp/var/gotify_nsub | wc -c)" -ge 20 ]] && echo "" /tmp/var/gotify_nsub
    [ ! -z "$(cat /tmp/var/gotify_nsub | grep '<' | grep '>')" ] && echo "" > /tmp/var/gotify_nsub
    if [ "$(cat /tmp/var/gotify_osub |head -n1)"x != "$(cat /tmp/var/gotify_nsub |head -n1)"x ] && [ -f /tmp/var/gotify_nsub ] ; then
        echo -n `nvram get firmver_sub` > /tmp/var/gotify_osub
        content="新的固件： `cat /tmp/var/gotify_nsub | grep -v '^$'` ，|目前旧固件： `cat /tmp/var/gotify_osub | grep -v '^$'` "
        logger -t "【gotify推送】" "固件 新的更新：${content}"
        Sh86_go_tify.sh send_message "【""$gotify_title""】固件更新提醒" "${content}" &
        echo -n `cat /tmp/var/gotify_nsub | grep -v '^$'` > /tmp/var/gotify_osub
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
	chmod 755 "$app_36"
fi

}

initconfig

update_app () {
mkdir -p /opt/app/gotify
if [ "$1" = "update_asp" ] ; then
	rm -rf /opt/app/gotify/Advanced_Extensions_gotify.asp
fi
if [ "$1" = "del" ] ; then
	rm -rf /opt/app/gotify/Advanced_Extensions_gotify.asp
	[ -f /opt/gotify/gotifyserver ] && rm -f /opt/gotify/gotifyserver
fi
#[ -z "$(cat /etc/storage/app_36.sh | grep send_message)" ] && rm -f /etc/storage/app_36.sh
initconfig

# 加载程序配置页面
if [ ! -f "/opt/app/gotify/Advanced_Extensions_gotify.asp" ] || [ ! -s "/opt/app/gotify/Advanced_Extensions_gotify.asp" ] ; then
	wgetcurl.sh /opt/app/gotify/Advanced_Extensions_gotify.asp "$hiboyfile/Advanced_Extensions_gotifyasp" "$hiboyfile2/Advanced_Extensions_gotifyasp"
fi
umount /www/Advanced_Extensions_app27.asp
mount --bind /opt/app/gotify/Advanced_Extensions_gotify.asp /www/Advanced_Extensions_app27.asp
# 更新程序启动脚本

[ "$1" = "del" ] && /etc/storage/www_sh/gotify推送 del &
}

case $ACTION in
send_message)
	send_message "$2" "$3"
	;;
start)
	gotify_close
	gotify_check
	;;
check)
	gotify_check
	;;
stop)
	gotify_close
	;;
updateapp27)
	gotify_restart o
	if [ "$gotify_enable" = "1" ] ; then
		touch /etc/storage/gotify_hostname.txt
		logger -t "【gotify推送】" "清空以往接入设备名称：/etc/storage/gotify_hostname.txt"
		echo "接入设备名称" > /etc/storage/gotify_hostname.txt
	fi
	[ "$gotify_enable" = "1" ] && nvram set gotify_status="updategotify" && logger -t "【gotify】" "重启" && gotify_restart
	[ "$gotify_enable" != "1" ] && nvram set gotify_v="" && logger -t "【gotify】" "更新" && update_app del
	;;
update_app)
	update_app
	;;
update_asp)
	update_app update_asp
	;;
keep)
	#gotify_check
	gotify_keep
	;;
*)
	gotify_check
	;;
esac

