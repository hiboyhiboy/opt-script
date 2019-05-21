#!/bin/sh
#copyright by hiboy
source /etc/storage/script/init.sh

if [ ! -s /tmp/script/_opt_script_check ] && [ ! -z "$(echo $scriptfilepath | grep -v "/tmp/script/" | grep opt_script_check)" ] ; then
	mkdir -p /tmp/script
	cp -Hsf $scriptfilepath /tmp/script/_opt_script_check
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
		/sbin/mtd_storage.sh fill
		echo -n "" > /tmp/dnsmasq_missing0.txt
		echo -n "" > /tmp/dnsmasq_missing1.txt
		restart_dhcpd
		sleep 1
		sed  "s/dnsmasq is missing,/【dnsmasq is missing】,/" -Ei /tmp/syslog.log
	else
		if [ ! -z "`grep "0000000000" /tmp/dnsmasq_missing0.txt `" ] ; then
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

ps -w > /tmp/ps


