#!/bin/sh
#copyright by hiboy
source /etc/storage/script/init.sh
jbls_enable=`nvram get jbls_enable`
[ -z $jbls_enable ] && jbls_enable=0 && nvram set jbls_enable=0
[ "$jbls_enable" != "0" ] && nvramshow=`nvram showall | grep jbls | awk '{print gensub(/'"'"'/,"'"'"'\"'"'"'\"'"'"'","g",$0);}'| awk '{print gensub(/=/,"='\''",1,$0)"'\'';";}'` && eval $nvramshow

if [ ! -z "$(echo $scriptfilepath | grep -v "/tmp/script/" | grep jbls)" ]  && [ ! -s /tmp/script/_jbls ]; then
	mkdir -p /tmp/script
	ln -sf $scriptfilepath /tmp/script/_jbls
	chmod 777 /tmp/script/_jbls
fi

jbls_check () {
if [ "$jbls_enable" != "1" ] ; then
	[ ! -z "`pidof jblicsvr`" ] && logger -t "【jbls】" "停止 jblicsvr" && jbls_close
	{ eval $(ps -w | grep "$scriptname" | grep -v grep | awk '{print "kill "$1";";}'); exit 0; }
fi
[ -z "`pidof jblicsvr`" ] && sleep 20
if [ -z "`pidof jblicsvr`" ] && [ "$jbls_enable" = "1" ] ; then
	jbls_close
	jbls_start
fi

}

jbls_keep () {
logger -t "【jbls】" "守护进程启动"
if [ -s /tmp/script/_opt_script_check ]; then
sed -Ei '/【jbls】|^$/d' /tmp/script/_opt_script_check
cat >> "/tmp/script/_opt_script_check" <<-OSC
[ -z "\`pidof jblicsvr\`" ] && logger -t "【jbls】" "重新启动" && eval "$scriptfilepath &" && sed -Ei '/【jbls】|^$/d' /tmp/script/_opt_script_check # 【jbls】
OSC
return
fi
while true; do
	if [ -z "`pidof jblicsvr`" ] ; then
		logger -t "【jbls】" "重新启动"
		{ eval "$scriptfilepath &" ; exit 0; }
	fi
sleep 993
done
}

jbls_close () {
sed -Ei '/【jbls】|^$/d' /tmp/script/_opt_script_check
sed -Ei '/txt-record=_jetbrains-license-server.lan/d' /etc/storage/dnsmasq/dnsmasq.conf
killall jblicsvr jbls_script.sh
killall -9 jblicsvr jbls_script.sh
eval $(ps -w | grep "_jbls keep" | grep -v grep | awk '{print "kill "$1";";}')
eval $(ps -w | grep "_jbls.sh keep" | grep -v grep | awk '{print "kill "$1";";}')
eval $(ps -w | grep "$scriptname keep" | grep -v grep | awk '{print "kill "$1";";}')
}

jbls_start () {
#jblicsvr -d -p 1027
/etc/storage/jbls_script.sh
sleep 2
[ ! -z "$(ps -w | grep "jblicsvr" | grep -v grep )" ] && logger -t "【jbls】" "启动成功"
[ -z "$(ps -w | grep "jblicsvr" | grep -v grep )" ] && logger -t "【jbls】" "启动失败, 注意检查端口是否有冲突,10 秒后自动尝试重新启动" && sleep 10 && { eval "$scriptfilepath &"; exit 0; }
eval "$scriptfilepath keep &"
}


case $ACTION in
start)
	jbls_close
	jbls_check
	;;
check)
	jbls_check
	;;
stop)
	jbls_close
	;;
keep)
	jbls_check
	jbls_keep
	;;
*)
	jbls_check
	;;
esac

