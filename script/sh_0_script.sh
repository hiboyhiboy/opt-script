#!/bin/sh
#copyright by hiboy
#/etc/storage/script/sh_0_script.sh
#/etc/storage/script_script.sh
source /etc/storage/script/init.sh
[ -f /tmp/script.lock ] && exit 0
touch /tmp/script.lock
touch /tmp/script_script_yes
[ ! -z "$(grep "SPI flash chip" /tmp/syslog.log | grep 32768)" ] && nvram set cmd_reboot_enable=1
. /etc/storage/script0_script.sh
ln -sf "/etc/storage/PhMain.ini" "/etc/PhMain.ini"
ln -sf "/etc/storage/init.status" "/etc/init.status"
rm -f "/opt/etc/init.d/S96sh3.sh"
echo "" > /var/log/shadowsocks_watchdog.log
echo "" > /var/log/Pcap_DNSProxy_watchdog.log
echo "" > /var/log/chinadns_watchdog.log
http_username=`nvram get http_username`
export PATH='/etc/storage/bin:/tmp/script:/etc/storage/script:/opt/usr/sbin:/opt/usr/bin:/opt/sbin:/opt/bin:/usr/local/sbin:/usr/sbin:/usr/bin:/sbin:/bin'
export LD_LIBRARY_PATH=/lib:/opt/lib
sed -Ei '/github|ipip.net|_vlmcs._tcp|txt-record=_jetbrains-license-server.lan|adbyby_host.conf|cflist.conf|accelerated-domains|no-resolv|server=127.0.0.1#8053|dns-forward-max=1000|min-cache-ttl=1800/d' /etc/storage/dnsmasq/dnsmasq.conf
sed -Ei "/\/tmp\/ss\/dnsmasq.d/d" /etc/storage/dnsmasq/dnsmasq.conf
rm -f /tmp/ss/dnsmasq.d/*
killall crond
restart_dhcpd ; sleep 1
[ -f /tmp/menu_title_re ] && /etc/storage/www_sh/menu_title.sh re &
mkdir -p /tmp/script
{ echo '#!/bin/sh' ; echo /etc/storage/script/Sh01_mountopt.sh '"$@"' ; } > /tmp/script/_mountopt
chmod 777 /tmp/script/_mountopt
nvram set ss_internet="0"
/etc/storage/inet_state_script.sh 12 t
/etc/storage/script/Sh??_mento_hust.sh &
ping_text=`ping -4 114.114.114.114 -c 1 -w 4 -q`
ping_time=`echo $ping_text | awk -F '/' '{print $4}'| awk -F '.' '{print $1}'`
ping_loss=`echo $ping_text | awk -F ', ' '{print $3}' | awk '{print $1}'`
if [ ! -z "$ping_time" ] ; then
	echo "ping：$ping_time ms 丢包率：$ping_loss"
 else
	echo "ping：失效"
fi
rb=1
while [ -z "$ping_time" ];
do
logger -t "【自定义脚本】" "等待联网后开始脚本"
sleep 8

ping_text=`ping -4 114.114.114.114 -c 1 -w 4 -q`
ping_time=`echo $ping_text | awk -F '/' '{print $4}'| awk -F '.' '{print $1}'`
ping_loss=`echo $ping_text | awk -F ', ' '{print $3}' | awk '{print $1}'`
if [ ! -z "$ping_time" ] ; then
	echo "ping：$ping_time ms 丢包率：$ping_loss"
 else
	echo "ping：失效"
fi
rb=`expr $rb + 1`
if [ "$rb" -gt 3 ] ; then
	logger -t "【自定义脚本】" "等待联网超时"
	ping_time=200
	break
fi
done
if [[ $(cat /tmp/apauto.lock) == 1 ]] ; then
	killall sh_apauto.sh
	/tmp/sh_apauto.sh &
fi
[ -d /etc/storage/script ] && chmod 777 /etc/storage/script -R
/etc/storage/script/Sh01_mountopt.sh upopt
/etc/storage/script/sh_upscript.sh
/etc/storage/www_sh/menu_title.sh upver &
/etc/storage/script/Sh01_mountopt.sh libmd5_check
/tmp/sh_theme.sh &
run_aria
run_transmission
rm -f /tmp/cron_adb.lock
[ ! -f /etc/storage/PhMain.ini ] && touch /etc/storage/PhMain.ini
[ ! -f /etc/storage/init.status ] && touch /etc/storage/init.status
rm -f /tmp/webui_yes
/etc/storage/script/sh_opt_script_check.sh
chmod 777 /tmp/script -R
touch /tmp/webui_yes
/etc/storage/www_sh/menu_title.sh &
# extend path to /opt
for i in `ls /opt/etc/init.d/_* 2>/dev/null` ; do
	rm -f ${i}
done
for i in `ls /opt/etc/init.d/Sh??_* 2>/dev/null` ; do
	rm -f ${i}
done
# start all services S* in /opt/etc/init.d
for i in `ls /opt/etc/init.d/S??* 2>/dev/null` ; do
	[ ! -x "${i}" ] && continue
	[ ! -f /tmp/webui_yes ] && continue
	${i} start
done
restart_firewall &
rm -f /tmp/script.lock
logger -t "【自定义脚本】" "初始化脚本完成"
