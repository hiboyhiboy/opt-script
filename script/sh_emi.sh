#!/bin/bash
#copyright by hiboy
source /etc/storage/script/init.sh

if [ ! -s /tmp/script/_emi ] && [ ! -z "$(echo $scriptfilepath | grep -v "/tmp/script/" | grep emi)" ] ; then
	mkdir -p /tmp/script
	cp -f $scriptfilepath /tmp/script/_emi
	chmod 777 /tmp/script/_emi
fi


logger -t "script_check" "检测到 电磁干扰【EMI】, 15秒后重新启动某些程序"
sleep 15
nvram set display_status=00
nvram set ssrserver_status=00
chmod 777 /etc/storage/script -R
logger -t "【WebUI】" "UI 开关遍历状态监测"
# start all services Sh??_* in /etc/storage/script
for i in /etc/storage/script/Sh??_* ; do
	[ ! -x "${i}" ] && continue
	eval ${i}
done
killall menu_title.sh 
[ -f /etc/storage/www_sh/menu_title.sh ] && /etc/storage/www_sh/menu_title.sh
