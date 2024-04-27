#!/bin/bash
#copyright by hiboy
source /etc/storage/script/init.sh

if [ ! -s /tmp/script/_opt_script_check ] && [ ! -z "$(echo $scriptfilepath | grep -v "/tmp/script/" | grep opt_script_check)" ] ; then
	mkdir -p /tmp/script
	cp -f $scriptfilepath /tmp/script/_opt_script_check
	chmod 777 /tmp/script/_opt_script_check
	exit
fi

crond_enable=`nvram get crond_enable`
crond_f="/etc/storage/cron/crontabs"
crond_f="$crond_f/`nvram get http_username`"
if [ ! -z "$(grep "#cru\.sh#" $crond_f)" ] && [ "$crond_enable" != "1" ] ; then
	nvram set crond_enable=1
	crond_enable=1
fi
if [ -z "`pidof crond`" ] && [ "$crond_enable" == "1" ] ; then
crond_log=`nvram get crond_log`
if [ "$crond_log" == "1" ] ; then
	crond -d8
else
	crond
fi
fi

opt_script_check=`nvram get opt_script_check`
opt_script_check=$((opt_script_check - 1))
nvram settmp opt_script_check="$opt_script_check"
if [ "$opt_script_check" -lt 1 ] ; then
nvram settmp opt_script_check="5"
ip6_neighbor_get
ip6_service=`nvram get ip6_service`
if [ ! -z "$ip6_service" ] ; then
dhcp_dnsv6_x=`nvram get dhcp_dnsv6_x`
if [ "$dhcp_dnsv6_x" == "br0" ] ; then
	addr6_lan1="$(ifconfig -a br0 | grep inet6 | grep Link | sed -n '1p' | awk '{print $3}' | awk -F '/' '{print $1}')"
	addr6_lan2="$(ifconfig -a br0 | grep inet6 | grep Global | sed -n '$p' | awk '{print $3}' | awk -F '/' '{print $1}')"
	if [ ! -z "$addr6_lan1" ] && [ -z "$(cat /etc/dnsmasq.conf | grep ${addr6_lan1})" ] ; then
		restart_on_dhcpd
	else
		if [ ! -z "$addr6_lan2" ] && [ -z "$(cat /etc/dnsmasq.conf | grep ${addr6_lan2})" ] ; then
		restart_on_dhcpd
		fi
	fi
fi
fi
fi

syslog_tmp="`cat /tmp/syslog.log | grep "EMI\?\|dnsmasq is missing,"`"
dnsmasq_tmp="`echo "$syslog_tmp" | grep 'dnsmasq is missing,'`"
if [ ! -z "$dnsmasq_tmp" ] ; then
	dnsmasq_tmp2="`echo "$dnsmasq_tmp" | grep 'dnsmasq is missing, start again!'`"
	if [ ! -z "$dnsmasq_tmp2" ] ; then
		echo -n 1 >> /tmp/dnsmasq_missing1.txt
	else
		echo -n 0 >> /tmp/dnsmasq_missing0.txt
	fi
	if [ ! -z "`cat /tmp/dnsmasq_missing1.txt | grep "1111"`" ] ; then
		logger -t "script_check" "检测到【dnsmasq】错误【dnsmasq is missing】"
		logger -t "script_check" "重置【dnsmasq配置】等待人类排查错误！"
		rm -rf /etc/storage/dnsmasq/*
		mtd_storage.sh fill
		rm -f /tmp/dnsmasq_missing0.txt /tmp/dnsmasq_missing1.txt
		echo -n "" > /tmp/dnsmasq_missing0.txt
		echo -n "" > /tmp/dnsmasq_missing1.txt
		restart_on_dhcpd
		sleep 1
		sed  "s/dnsmasq is missing,/【dnsmasq is missing】,/" -Ei /tmp/syslog.log
	else
		if [ ! -z "`cat /tmp/dnsmasq_missing0.txt | grep "0000000000"`" ] ; then
			rm -f /tmp/dnsmasq_missing0.txt /tmp/dnsmasq_missing1.txt
			echo -n "" > /tmp/dnsmasq_missing0.txt
			echo -n "" > /tmp/dnsmasq_missing1.txt
			sed  "s/dnsmasq is missing,/【dnsmasq is missing】,/" -Ei /tmp/syslog.log
		else
			sed  "s/dnsmasq is missing, start again!/dnsmasq is missing,start again!/" -Ei /tmp/syslog.log
		fi
	fi
fi
EMI_tmp="`echo "$syslog_tmp" | grep 'EMI?'`"
if [ ! -z "$EMI_tmp" ] ; then
	logger -t "script_check" "检测到 电磁干扰【EMI】"
	sleep 1
	sed  "s/EMI\?/EMI/" -Ei /tmp/syslog.log
	if [ -s /tmp/script/_emi ] ; then
		/tmp/script/_emi &
		exit
	else
		[ -s /etc/storage/script/sh_emi.sh ] && /etc/storage/script/sh_emi.sh &
		exit
	fi
fi

cmd_cpu_enable=`nvram get cmd_cpu_enable`
if [ "$cmd_cpu_enable" == "1" ] ; then
if [ -f /tmp/top ] ; then
rm -f /tmp/top
else
top -n 1 | grep " R " | grep -v "top -n 1" | grep -v "grep" | grep -v "mtd_write" | grep -v "/usr/sbin/httpd" | grep -v "/usr/sbin/dropbear" | sed -e "s@^@#@g" > /tmp/top

top -n 1 | grep " S " | grep -v "top -n 1" | grep -v "grep" | grep -v "mtd_write" | grep -v "/usr/sbin/httpd" | grep -v "/usr/sbin/dropbear" | sed -e "s@^@#@g" >> /tmp/top

if [ -s /tmp/top ] ; then
 #21445 21444 admin    R     1972  0.4   2 24.9 COMMAND
 #  810 30601 admin    R     1588  0.3   3  2.2 top -n 1

while read line
do
if [ ! -z "$line" ] ; then
top_PID="$(echo "$line" | awk '{print substr($0,2,5)}')"
top_COMMAND="$(echo ${line: 47: 34})"
top_CPU=$(echo ${line: 42: 2})
threads=$(cat /proc/cpuinfo | grep 'processor' | wc -l)
[ -z $threads ] && threads=1
max_cpu=`expr 100 / $threads - 6 `
if [ $max_cpu -lt $top_CPU ] ; then
if [ -z "$(cat /tmp/top_run | grep $top_PID©)" ] ; then
#logger -t "script_check" "检测到进程 PID【$top_PID】使用CPU $top_CPU% 进入防卡CPU检测序列 $top_COMMAND"
#©§
echo "$top_PID©$top_CPU©§1§$top_COMMAND" >> /tmp/top_run
fi
else
sed -Ei "/^[ \t]*$top_PID©/d" /tmp/top_run
fi
fi
done < /tmp/top

if [ -s /tmp/top_run ] ; then
sed -Ei "/^$/d" /tmp/top_run
while read line
do
if [ ! -z "$line" ] ; then
top_PID="$(echo "$line" | awk -F '©' '{print $1}')"
top_CPU="$(echo "$line" | awk -F '©' '{print $2}')"
top_COMMAND="$(echo "$line" | awk -F '§' '{print $3}')"
[ ! -f /tmp/top ] && top -n 1 | grep " R " | grep -v "top -n 1" | grep -v "grep" | sed -e "s@^@#@g" > /tmp/top
[ ! -f /tmp/top ] && top -n 1 | grep " S " | grep -v "top -n 1" | grep -v "grep" | sed -e "s@^@#@g" >> /tmp/top
if [ -z "$(cat /tmp/top | grep "$top_PID ")" ] ; then
sed -Ei "/^[ \t]*$top_PID©/d" /tmp/top_run
break
#continue
fi
top_i="$(echo "$line" | awk -F '§' '{print $2}')"
top_2i=`expr $top_i + 1`
if [ $top_2i -eq 9 ] ; then
logger -t "script_check" "检测到进程 PID【$top_PID】使用CPU $top_CPU% 进入防卡CPU检测序列 $top_COMMAND"
fi
if [ $top_2i -gt 100 ] ; then
kill $top_PID
kill -9 $top_PID
logger -t "script_check" "检测到进程 PID【$top_PID】 $top_COMMAND"
logger -t "script_check" "已经连续使用CPU $top_CPU% 大于33分钟，尝试 kill 进程防卡CPU"
sed -Ei "/^[ \t]*$top_PID©/d" /tmp/top_run
else
sed -e "s@^[ \t]*$top_PID©$top_CPU©§$top_i§@$top_PID©$top_CPU©§$top_2i§@g" -i /tmp/top_run
fi
fi
done < /tmp/top_run
fi
fi
fi
fi

ps -w > /tmp/ps
[ ! -f /tmp/webui_yes ] &&   exit 0

