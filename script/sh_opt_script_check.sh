#!/bin/sh
#copyright by hiboy
source /etc/storage/script/init.sh

if [ ! -z "$(echo $scriptfilepath | grep -v "/tmp/script/" | grep opt_script_check)" ]  && [ ! -s /tmp/script/_opt_script_check ]; then
	mkdir -p /tmp/script
	ln -sf $scriptfilepath /tmp/script/_opt_script_check
	chmod 777 /tmp/script/_opt_script_check
fi

ps -w > /tmp/ps

EMI="`cat /tmp/syslog.log | grep 'EMI?'`"
if [ ! -z "$EMI" ] ; then
sed  "s/EMI\?/EMI/" -Ei /tmp/syslog.log
logger -t "script_check" "检测到 电磁干扰【EMI】, 重新启动某些程序"
killall lcd4linux
eval $(ps -w | grep "manyuser/shadowsocks/server" | grep -v grep | awk '{print "kill "$1";";}')

fi
