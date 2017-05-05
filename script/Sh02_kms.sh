#!/bin/sh
#copyright by hiboy
source /etc/storage/script/init.sh
kms_enable=`nvram get kms_enable`
[ -z $kms_enable ] && kms_enable=0 && nvram set kms_enable=0
[ "$kms_enable" != "0" ] && nvramshow=`nvram showall | grep kms | awk '{print gensub(/'"'"'/,"'"'"'\"'"'"'\"'"'"'","g",$0);}'| awk '{print gensub(/=/,"='\''",1,$0)"'\'';";}'` && eval $nvramshow

if [ ! -z "$(echo $scriptfilepath | grep -v "/tmp/script/" | grep kms)" ]  && [ ! -s /tmp/script/_kms ]; then
	mkdir -p /tmp/script
	ln -sf $scriptfilepath /tmp/script/_kms
	chmod 777 /tmp/script/_kms
fi

kms_check () {
if [ "$kms_enable" != "1" ] ; then
	[ ! -z "`pidof vlmcsd`" ] && logger -t "【kms】" "停止 vlmcsd" && kms_close
	{ eval $(ps -w | grep "$scriptname" | grep -v grep | awk '{print "kill "$1";";}'); exit 0; }
fi
[ -z "`pidof vlmcsd`" ] && sleep 20
if [ -z "`pidof vlmcsd`" ] && [ "$kms_enable" = "1" ] ; then
	kms_close
	kms_start
fi

}

kms_keep () {
logger -t "【kms】" "守护进程启动"
if [ -s /tmp/script/_opt_script_check ]; then
sed -Ei '/【kms】|^$/d' /tmp/script/_opt_script_check
cat >> "/tmp/script/_opt_script_check" <<-OSC
[ -z "\`pidof vlmcsd\`" ] && logger -t "【kms】" "重新启动" && eval "$scriptfilepath &" && sed -Ei '/【kms】|^$/d' /tmp/script/_opt_script_check # 【kms】
OSC
return
fi
while true; do
	if [ -z "`pidof vlmcsd`" ] ; then
		logger -t "【kms】" "重新启动"
		{ eval "$scriptfilepath &" ; exit 0; }
	fi
sleep 992
done
}

kms_close () {
sed -Ei '/【kms】|^$/d' /tmp/script/_opt_script_check
sed -Ei '/_vlmcs._tcp/d' /etc/storage/dnsmasq/dnsmasq.conf; restart_dhcpd;
killall vlmcsd vlmcsdini_script.sh
killall -9 vlmcsd vlmcsdini_script.sh
eval $(ps -w | grep "_kms keep" | grep -v grep | awk '{print "kill "$1";";}')
eval $(ps -w | grep "_kms.sh keep" | grep -v grep | awk '{print "kill "$1";";}')
eval $(ps -w | grep "$scriptname keep" | grep -v grep | awk '{print "kill "$1";";}')
}

kms_start () {
[ ! -f /etc_ro/vlmcsd.kmd ] && /usr/bin/vlmcsd -i /etc/storage/vlmcsdini_script.sh -l /tmp/vlmcsd.log &
[ -f /etc_ro/vlmcsd.kmd ] && /usr/bin/vlmcsd -j /etc_ro/vlmcsd.kmd -i /etc/storage/vlmcsdini_script.sh -l /tmp/vlmcsd.log &
computer_name=`nvram get computer_name`
sed -Ei '/_vlmcs._tcp/d' /etc/storage/dnsmasq/dnsmasq.conf
nvram set lan_domain="lan"
echo "srv-host=_vlmcs._tcp.lan,$computer_name.lan,1688,0,100" >> /etc/storage/dnsmasq/dnsmasq.conf
/etc/storage/vlmcsdini_script.sh
restart_dhcpd
sleep 2
[ ! -z "$(ps -w | grep "vlmcsd" | grep -v grep )" ] && logger -t "【kms】" "启动成功"
[ -z "$(ps -w | grep "vlmcsd" | grep -v grep )" ] && logger -t "【kms】" "启动失败, 注意检查端口是否有冲突,10 秒后自动尝试重新启动" && sleep 10 && { eval "$scriptfilepath &"; exit 0; }
eval "$scriptfilepath keep &"
}


case $ACTION in
start)
	kms_close
	kms_check
	;;
check)
	kms_check
	;;
stop)
	kms_close
	;;
keep)
	kms_check
	kms_keep
	;;
*)
	kms_check
	;;
esac

