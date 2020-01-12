#!/bin/sh
#copyright by hiboy
source /etc/storage/script/init.sh

if [ ! -s /tmp/script/_opt_script_check ] && [ ! -z "$(echo $scriptfilepath | grep -v "/tmp/script/" | grep opt_script_check)" ] ; then
	mkdir -p /tmp/script
	cp -f $scriptfilepath /tmp/script/_opt_script_check
	chmod 777 /tmp/script/_opt_script_check
	exit
fi

syslog_tmp="`grep "EMI\?\|dnsmasq is missing," /tmp/syslog.log `"
dnsmasq_tmp="`echo $syslog_tmp | grep 'dnsmasq is missing,'`"
if [ ! -z "$dnsmasq_tmp" ] ; then
	dnsmasq_tmp2="`echo $dnsmasq_tmp | grep 'dnsmasq is missing, start again!'`"
	if [ ! -z "$dnsmasq_tmp2" ] ; then
		echo -n 1 >> /tmp/dnsmasq_missing1.txt
	else
		echo -n 0 >> /tmp/dnsmasq_missing0.txt
	fi
	if [ ! -z "`grep "1111" /tmp/dnsmasq_missing1.txt `" ] ; then
		logger -t "script_check" "检测到【dnsmasq】错误【dnsmasq is missing】"
		logger -t "script_check" "重置【dnsmasq配置】等待人类排查错误！"
		rm -rf /etc/storage/dnsmasq/*
		mtd_storage.sh fill
		rm -f /tmp/dnsmasq_missing0.txt /tmp/dnsmasq_missing1.txt
		echo -n "" > /tmp/dnsmasq_missing0.txt
		echo -n "" > /tmp/dnsmasq_missing1.txt
		restart_dhcpd
		sleep 1
		sed  "s/dnsmasq is missing,/【dnsmasq is missing】,/" -Ei /tmp/syslog.log
	else
		if [ ! -z "`grep "0000000000" /tmp/dnsmasq_missing0.txt `" ] ; then
			rm -f /tmp/dnsmasq_missing0.txt /tmp/dnsmasq_missing1.txt
			echo -n "" > /tmp/dnsmasq_missing0.txt
			echo -n "" > /tmp/dnsmasq_missing1.txt
			sed  "s/dnsmasq is missing,/【dnsmasq is missing】,/" -Ei /tmp/syslog.log
		else
			sed  "s/dnsmasq is missing, start again!/dnsmasq is missing,start again!/" -Ei /tmp/syslog.log
		fi
	fi
fi
EMI_tmp="`echo $syslog_tmp | grep 'EMI?'`"
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
top -n 1 | grep " R " | grep -v "top -n 1" | grep -v "grep" | sed -e "s@^@#@g" > /tmp/top
if [ -s /tmp/top ] ; then
 #21445 21444 admin    R     1972  0.4   2 24.9 COMMAND
 #  810 30601 admin    R     1588  0.3   3  2.2 top -n 1

while read line
do
if [ ! -z "$line" ] ; then
top_PID="$(echo "$line" | awk '{print substr($0,2,5)}')"
top_COMMAND="$(echo ${line: 47: 34})"
top_CPU="$(echo ${line: 42: 2})"
threads=$(cat /proc/cpuinfo | grep 'processor' | wc -l)
[ -z $threads ] && threads=1
max_cpu=`expr 100 / $threads - 3 `
if [ $max_cpu -lt $top_CPU ] ; then
if [ -z "$(grep $top_PID© /tmp/top_run)" ] ; then
logger -t "script_check" "检测到进程 PID【$top_PID】使用CPU $top_CPU% 进入防卡CPU检测序列 $top_COMMAND"
#©§
echo "$top_PID©$top_CPU©§1§$top_COMMAND" >> /tmp/top_run
fi
fi
fi
done < /tmp/top

if [ -s /tmp/top_run ] ; then
while read line
do
if [ ! -z "$line" ] ; then
top_PID="$(echo $line | awk -F '©' '{print $1}')"
top_CPU="$(echo $line | awk -F '©' '{print $2}')"
top_COMMAND="$(echo $line | awk -F '§' '{print $3}')"
if [ -z "$(grep "$top_PID " /tmp/top)" ] ; then
sed -Ei "/^$top_PID©/d" /tmp/top_run
break
#continue
fi
top_i="$(echo $line | awk -F '§' '{print $2}')"
top_2i=`expr $top_i + 1`
if [ $top_2i -gt 100 ] ; then
kill $top_PID
kill -9 $top_PID
logger -t "script_check" "检测到进程 PID【$top_PID】 $top_COMMAND"
logger -t "script_check" "已经连续使用CPU $top_CPU% 大于33分钟，尝试 kill 进程防卡CPU"
sed -Ei "/^$top_PID©/d" /tmp/top_run
fi
sed -e "s@^$top_PID©$top_CPU©§$top_i§@$top_PID©$top_CPU©§$top_2i§@g" -i /tmp/top_run
fi
done < /tmp/top_run
fi
else
[ -f /tmp/top_run ] && rm -f /tmp/top_run
fi
fi
fi

rm -f /tmp/ps
ps -w > /tmp/ps
[ ! -f /tmp/webui_yes ] &&   exit 0

