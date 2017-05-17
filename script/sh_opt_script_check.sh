#!/bin/sh
#copyright by hiboy
source /etc/storage/script/init.sh

if [ ! -s /tmp/script/_opt_script_check ] && [ ! -z "$(echo $scriptfilepath | grep -v "/tmp/script/" | grep opt_script_check)" ] ; then
	mkdir -p /tmp/script
	cp -Hsf $scriptfilepath /tmp/script/_opt_script_check
	chmod 777 /tmp/script/_opt_script_check
	exit
fi

EMI="`cat /tmp/syslog.log | grep 'EMI?'`"
if [ ! -z "$EMI" ] ; then
	sed  "s/EMI\?/EMI/" -Ei /tmp/syslog.log
	logger -t "script_check" "检测到 电磁干扰【EMI】"
	if [ -s /tmp/script/_emi ] ; then
		/tmp/script/_emi &
		exit
	else
		[ -s /etc/storage/script/sh_emi.sh ] && /etc/storage/script/sh_emi.sh &
		exit
	fi
fi

ps -w > /tmp/ps


