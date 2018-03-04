#!/bin/sh
#copyright by hiboy
source /etc/storage/script/init.sh
serverchan_enable=`nvram get serverchan_enable`
[ -z $serverchan_enable ] && serverchan_enable=0 && nvram set serverchan_enable=0
if [ "$serverchan_enable" != "0" ] ; then
#nvramshow=`nvram showall | grep '=' | grep serverchan | awk '{print gensub(/'"'"'/,"'"'"'\"'"'"'\"'"'"'","g",$0);}'| awk '{print gensub(/=/,"='\''",1,$0)"'\'';";}'` && eval $nvramshow

serverchan_sckey=`nvram get serverchan_sckey`
serverchan_notify_1=`nvram get serverchan_notify_1`
serverchan_notify_2=`nvram get serverchan_notify_2`
serverchan_notify_3=`nvram get serverchan_notify_3`
serverchan_notify_4=`nvram get serverchan_notify_4`

fi

if [ ! -z "$(echo $scriptfilepath | grep -v "/tmp/script/" | grep server_chan)" ]  && [ ! -s /tmp/script/_server_chan ]; then
	mkdir -p /tmp/script
	{ echo '#!/bin/sh' ; echo $scriptfilepath '"$@"' '&' ; } > /tmp/script/_server_chan
	chmod 777 /tmp/script/_server_chan
fi

serverchan_restart () {

relock="/var/lock/serverchan_restart.lock"
if [ "$1" = "o" ] ; then
	nvram set serverchan_renum="0"
	[ -f $relock ] && rm -f $relock
	return 0
fi
if [ "$1" = "x" ] ; then
	if [ -f $relock ] ; then
		logger -t "【serverchan】" "多次尝试启动失败，等待【"`cat $relock`"分钟】后自动尝试重新启动"
		exit 0
	fi
	serverchan_renum=${serverchan_renum:-"0"}
	serverchan_renum=`expr $serverchan_renum + 1`
	nvram set serverchan_renum="$serverchan_renum"
	if [ "$serverchan_renum" -gt "2" ] ; then
		I=19
		echo $I > $relock
		logger -t "【serverchan】" "多次尝试启动失败，等待【"`cat $relock`"分钟】后自动尝试重新启动"
		while [ $I -gt 0 ]; do
			I=$(($I - 1))
			echo $I > $relock
			sleep 60
			[ "$(nvram get serverchan_renum)" = "0" ] && exit 0
			[ $I -lt 0 ] && break
		done
		nvram set serverchan_renum="0"
	fi
	[ -f $relock ] && rm -f $relock
fi
nvram set serverchan_status=0
eval "$scriptfilepath &"
exit 0
}

serverchan_get_status () {

A_restart=`nvram get serverchan_status`
B_restart="$serverchan_enable$serverchan_sckey$serverchan_notify_1$serverchan_notify_2$serverchan_notify_3$serverchan_notify_4$(cat /etc/storage/serverchan_script.sh | grep -v '^#' | grep -v "^$")"
B_restart=`echo -n "$B_restart" | md5sum | sed s/[[:space:]]//g | sed s/-//g`
if [ "$A_restart" != "$B_restart" ] ; then
	nvram set serverchan_status=$B_restart
	needed_restart=1
else
	needed_restart=0
fi
}

serverchan_check () {

serverchan_get_status
if [ "$serverchan_enable" != "1" ] && [ "$needed_restart" = "1" ] ; then
	[ ! -z "$(ps -w | grep "serverchan_scri" | grep -v grep )" ] && logger -t "【微信推送】" "停止 serverchan" && serverchan_close
	{ kill_ps "$scriptname" exit0; exit 0; }
fi
if [ "$serverchan_enable" = "1" ] ; then
	if [ "$needed_restart" = "1" ] ; then
		serverchan_close
		serverchan_start
	else
		[ -z "$(ps -w | grep "serverchan_scri" | grep -v grep )" ] || [ ! -s "`which curl`" ] && serverchan_restart
	fi
fi
}

serverchan_keep () {
logger -t "【微信推送】" "守护进程启动"
if [ -s /tmp/script/_opt_script_check ]; then
sed -Ei '/【微信推送】|^$/d' /tmp/script/_opt_script_check
cat >> "/tmp/script/_opt_script_check" <<-OSC
	NUM=\`grep "/etc/storage/serverchan_script.sh" /tmp/ps | grep -v grep |wc -l\` # 【微信推送】
	if [ "\$NUM" -lt "1" ] || [ ! -s "/etc/storage/serverchan_script.sh" ] || [ ! -s "`which curl`" ] ; then # 【微信推送】
		logger -t "【微信推送】" "重新启动\$NUM" # 【微信推送】
		nvram set serverchan_status=04 && eval "$scriptfilepath &" && sed -Ei '/【微信推送】|^$/d' /tmp/script/_opt_script_check # 【微信推送】
	fi # 【微信推送】
OSC
#return
fi
sleep 60
while true; do
	[ ! -s "`which curl`" ] && { logger -t "【微信推送】" "重新启动"; serverchan_restart ; }
	if [ -z "$(ps -w | grep "serverchan_scri" | grep -v grep )" ] ; then
		logger -t "【微信推送】" "重新启动"
		serverchan_restart
	fi
	
sleep 3600
killall serverchan_script.sh
killall -9 serverchan_script.sh
/etc/storage/serverchan_script.sh &
done
}

serverchan_close () {
sed -Ei '/【微信推送】|^$/d' /tmp/script/_opt_script_check
killall serverchan_script.sh
killall -9 serverchan_script.sh
kill_ps "/tmp/script/_server_chan"
kill_ps "_server_chan.sh"
kill_ps "$scriptname"
}

serverchan_start () {
curltest=`which curl`
if [ -z "$curltest" ] || [ ! -s "`which curl`" ] ; then
	logger -t "【微信推送】" "找不到 curl ，安装 opt 程序"
	/tmp/script/_mountopt optwget
	#initopt
	curltest=`which curl`
	if [ -z "$curltest" ] || [ ! -s "`which curl`" ] ; then
		logger -t "【微信推送】" "找不到 curl ，需要手动安装 opt 后输入[opkg install curl]安装"
		logger -t "【微信推送】" "启动失败, 10 秒后自动尝试重新启动" && sleep 10 && serverchan_restart x
	fi
fi
logger -t "【微信推送】" "运行 /etc/storage/serverchan_script.sh"
/etc/storage/serverchan_script.sh &
sleep 3
[ ! -z "$(ps -w | grep "serverchan_scri" | grep -v grep )" ] && logger -t "【微信推送】" "启动成功" && serverchan_restart o
[ -z "$(ps -w | grep "serverchan_scri" | grep -v grep )" ] && logger -t "【微信推送】" "启动失败, 注意检查端口是否有冲突,程序是否下载完整,10 秒后自动尝试重新启动" && sleep 10 && serverchan_restart x
#serverchan_get_status
eval "$scriptfilepath keep &"
}

initopt () {
optPath=`grep ' /opt ' /proc/mounts | grep tmpfs`
[ ! -z "$optPath" ] && return
if [ ! -z "$(echo $scriptfilepath | grep -v "/opt/etc/init")" ] && [ -s "/opt/etc/init.d/rc.func" ] ; then
	{ echo '#!/bin/sh' ; echo $scriptfilepath '"$@"' '&' ; } > /opt/etc/init.d/$scriptname && chmod 777  /opt/etc/init.d/$scriptname
fi

}

initconfig () {

serverchan_script="/etc/storage/serverchan_script.sh"
if [ ! -f "$serverchan_script" ] || [ ! -s "$serverchan_script" ] ; then
	cat > "$serverchan_script" <<-\EEE
#!/bin/sh
# 此脚本路径：/etc/storage/serverchan_script.sh
# 自定义设置 - 脚本 - 自定义 Crontab 定时任务配置，可自定义启动时间
source /etc/storage/script/init.sh
export PATH='/etc/storage/bin:/tmp/script:/etc/storage/script:/opt/usr/sbin:/opt/usr/bin:/opt/sbin:/opt/bin:/usr/local/sbin:/usr/sbin:/usr/bin:/sbin:/bin'
export LD_LIBRARY_PATH=/lib:/opt/lib
serverchan_enable=`nvram get serverchan_enable`
serverchan_enable=${serverchan_enable:-"0"}
serverchan_sckey=`nvram get serverchan_sckey`
serverchan_notify_1=`nvram get serverchan_notify_1`
serverchan_notify_2=`nvram get serverchan_notify_2`
serverchan_notify_3=`nvram get serverchan_notify_3`
serverchan_notify_4=`nvram get serverchan_notify_4`
mkdir -p /tmp/var
resub=1
# 获得外网地址
    arIpAddress() {
    curltest=`which curl`
    if [ -z "$curltest" ] || [ ! -s "`which curl`" ] ; then
        wget --no-check-certificate --quiet --output-document=- "http://members.3322.org/dyndns/getip"
        #wget --no-check-certificate --quiet --output-document=- "ip.6655.com/ip.aspx"
        #wget --no-check-certificate --quiet --output-document=- "ip.3322.net"
    else
        curl -k -s "http://members.3322.org/dyndns/getip"
        #curl -k -s ip.6655.com/ip.aspx
        #curl -k -s ip.3322.net
    fi
    }
# 读取最近外网地址
    lastIPAddress() {
        local inter="/etc/storage/lastIPAddress"
        cat $inter
    }

while [ "$serverchan_enable" = "1" ];
do
serverchan_enable=`nvram get serverchan_enable`
serverchan_enable=${serverchan_enable:-"0"}
serverchan_sckey=`nvram get serverchan_sckey`
serverchan_notify_1=`nvram get serverchan_notify_1`
serverchan_notify_2=`nvram get serverchan_notify_2`
serverchan_notify_3=`nvram get serverchan_notify_3`
serverchan_notify_4=`nvram get serverchan_notify_4`
curltest=`which curl`
ping_text=`ping -4 114.114.114.114 -c 1 -w 2 -q`
ping_time=`echo $ping_text | awk -F '/' '{print $4}'| awk -F '.' '{print $1}'`
ping_loss=`echo $ping_text | awk -F ', ' '{print $3}' | awk '{print $1}'`
if [ ! -z "$ping_time" ] ; then
    echo "ping：$ping_time ms 丢包率：$ping_loss"
 else
    echo "ping：失效"
fi
if [ ! -z "$ping_time" ] ; then
echo "online"
if [ "$serverchan_notify_1" = "1" ] ; then
    local hostIP=$(arIpAddress)
    local lastIP=$(lastIPAddress)
    if [ "$lastIP" != "$hostIP" ] && [ ! -z "$hostIP" ] ; then
    sleep 60
        local hostIP=$(arIpAddress)
        local lastIP=$(lastIPAddress)
    fi
    if [ "$lastIP" != "$hostIP" ] && [ ! -z "$hostIP" ] ; then
        logger -t "【互联网 IP 变动】" "目前 IP: ${hostIP}"
        logger -t "【互联网 IP 变动】" "上次 IP: ${lastIP}"
        curl -s "http://sc.ftqq.com/$serverchan_sckey.send?text=【PDCN_"`nvram get computer_name`"】互联网IP变动" -d "&desp=${hostIP}" &
        logger -t "【微信推送】" "互联网IP变动:${hostIP}"
        echo -n $hostIP > /etc/storage/lastIPAddress
    fi
fi
if [ "$serverchan_notify_2" = "1" ] ; then
    # 获取接入设备名称
    touch /tmp/var/newhostname.txt
    echo "接入设备名称" > /tmp/var/newhostname.txt
    #cat /tmp/syslog.log | grep 'Found new hostname' | awk '{print $7" "$8}' >> /tmp/var/newhostname.txt
    cat /tmp/static_ip.inf | grep -v "^$" | awk -F "," '{ if ( $6 == 0 ) print "【内网IP："$1"，ＭＡＣ："$2"，名称："$3"】  "}' >> /tmp/var/newhostname.txt
    # 读取以往接入设备名称
    touch /etc/storage/hostname.txt
    [ ! -s /etc/storage/hostname.txt ] && echo "接入设备名称" > /etc/storage/hostname.txt
    # 获取新接入设备名称
    awk 'NR==FNR{a[$0]++} NR>FNR&&a[$0]' /etc/storage/hostname.txt /tmp/var/newhostname.txt > /tmp/var/newhostname相同行.txt
    awk 'NR==FNR{a[$0]++} NR>FNR&&!a[$0]' /tmp/var/newhostname相同行.txt /tmp/var/newhostname.txt > /tmp/var/newhostname不重复.txt
    if [ -s "/tmp/var/newhostname不重复.txt" ] ; then
        content=`cat /tmp/var/newhostname不重复.txt | grep -v "^$"`
        curl -s "http://sc.ftqq.com/$serverchan_sckey.send?text=【PDCN_"`nvram get computer_name`"】新设备加入" -d "&desp=${content}" &
        logger -t "【微信推送】" "PDCN新设备加入:${content}"
        cat /tmp/var/newhostname不重复.txt | grep -v "^$" >> /etc/storage/hostname.txt
    fi
fi
if [ "$serverchan_notify_4" = "1" ] ; then
    # 设备上、下线提醒
    # 获取接入设备名称
    touch /tmp/var/newhostname.txt
    echo "接入设备名称" > /tmp/var/newhostname.txt
    #cat /tmp/syslog.log | grep 'Found new hostname' | awk '{print $7" "$8}' >> /tmp/var/newhostname.txt
    cat /tmp/static_ip.inf | grep -v "^$" | awk -F "," '{ if ( $6 == 0 ) print "【内网IP："$1"，ＭＡＣ："$2"，名称："$3"】  "}' >> /tmp/var/newhostname.txt
    # 读取以往上线设备名称
    touch /etc/storage/hostname_上线.txt
    [ ! -s /etc/storage/hostname_上线.txt ] && echo "接入设备名称" > /etc/storage/hostname_上线.txt
    # 上线
    awk 'NR==FNR{a[$0]++} NR>FNR&&a[$0]' /etc/storage/hostname_上线.txt /tmp/var/newhostname.txt > /tmp/var/newhostname相同行_上线.txt
    awk 'NR==FNR{a[$0]++} NR>FNR&&!a[$0]' /tmp/var/newhostname相同行_上线.txt /tmp/var/newhostname.txt > /tmp/var/newhostname不重复_上线.txt
    if [ -s "/tmp/var/newhostname不重复_上线.txt" ] ; then
        content=`cat /tmp/var/newhostname不重复_上线.txt | grep -v "^$"`
        curl -s "http://sc.ftqq.com/$serverchan_sckey.send?text=【PDCN_"`nvram get computer_name`"】设备【上线】Online" -d "&desp=${content}" &
        logger -t "【微信推送】" "PDCN设备【上线】:${content}"
        cat /tmp/var/newhostname不重复_上线.txt | grep -v "^$" >> /etc/storage/hostname_上线.txt
    fi
    # 下线
    awk 'NR==FNR{a[$0]++} NR>FNR&&!a[$0]' /tmp/var/newhostname.txt /etc/storage/hostname_上线.txt > /tmp/var/newhostname不重复_下线.txt
    if [ -s "/tmp/var/newhostname不重复_下线.txt" ] ; then
        content=`cat /tmp/var/newhostname不重复_下线.txt | grep -v "^$"`
        curl -s "http://sc.ftqq.com/$serverchan_sckey.send?text=【PDCN_"`nvram get computer_name`"】设备【下线】offline" -d "&desp=${content}" &
        logger -t "【微信推送】" "PDCN设备【下线】:${content}"
        cat /tmp/var/newhostname.txt | grep -v "^$" > /etc/storage/hostname_上线.txt
    fi
fi
if [ "$serverchan_notify_3" = "1" ] && [ "$resub" = "1" ] ; then
    # 固件更新提醒
    [ ! -f /tmp/var/osub ] && echo -n `nvram get firmver_sub` > /tmp/var/osub
    rm -f /tmp/var/nsub
    wgetcurl.sh "/tmp/var/nsub" "$hiboyfile/osub" "$hiboyfile2/osub"
    if [ $(cat /tmp/var/osub) != $(cat /tmp/var/nsub) ] && [ -f /tmp/var/nsub ] ; then
        echo -n `nvram get firmver_sub` > /tmp/var/osub
        content="新的固件： `cat /tmp/var/nsub | grep -v "^$"` ，目前旧固件： `cat /tmp/var/osub | grep -v "^$"` "
        logger -t "【微信推送】" "固件 新的更新：${content}"
        curl -s "http://sc.ftqq.com/$serverchan_sckey.send?text=【PDCN_"`nvram get computer_name`"】固件更新提醒" -d "&desp=${content}" &
        echo -n `cat /tmp/var/nsub | grep -v "^$"` > /tmp/var/osub
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
	chmod 755 "$serverchan_script"
fi

}

initconfig

case $ACTION in
start)
	serverchan_close
	serverchan_check
	;;
check)
	serverchan_check
	;;
stop)
	serverchan_close
	;;
keep)
	#serverchan_check
	serverchan_keep
	;;
*)
	serverchan_check
	;;
esac

