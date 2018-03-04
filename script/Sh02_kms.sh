#!/bin/sh
#copyright by hiboy
source /etc/storage/script/init.sh
kms_enable=`nvram get kms_enable`
[ -z $kms_enable ] && kms_enable=0 && nvram set kms_enable=0
#[ "$kms_enable" != "0" ] && nvramshow=`nvram showall | grep '=' | grep kms | awk '{print gensub(/'"'"'/,"'"'"'\"'"'"'\"'"'"'","g",$0);}'| awk '{print gensub(/=/,"='\''",1,$0)"'\'';";}'` && eval $nvramshow

if [ ! -z "$(echo $scriptfilepath | grep -v "/tmp/script/" | grep kms)" ]  && [ ! -s /tmp/script/_kms ]; then
	mkdir -p /tmp/script
	{ echo '#!/bin/sh' ; echo $scriptfilepath '"$@"' '&' ; } > /tmp/script/_kms
	chmod 777 /tmp/script/_kms
fi

kms_check () {
if [ "$kms_enable" != "1" ] ; then
	[ ! -z "`pidof vlmcsd`" ] && logger -t "【kms】" "停止 vlmcsd" && kms_close
	{ kill_ps "$scriptname" exit0; exit 0; }
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
kill_ps "/tmp/script/_kms"
kill_ps "_kms.sh"
kill_ps "$scriptname"
}

kms_start () {
[ ! -f /etc_ro/vlmcsd.kmd ] && /usr/bin/vlmcsd -i /etc/storage/vlmcsdini_script.sh -l /tmp/vlmcsd.log
[ -f /etc_ro/vlmcsd.kmd ] && /usr/bin/vlmcsd -j /etc_ro/vlmcsd.kmd -i /etc/storage/vlmcsdini_script.sh -l /tmp/vlmcsd.log
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

initconfig () {
vlmcsdini_script="/etc/storage/vlmcsdini_script.sh"
if [ ! -f "$vlmcsdini_script" ] || [ ! -s "$vlmcsdini_script" ] ; then
	cat > "$vlmcsdini_script" <<-\EEE
# Office手动激活命令：

# cd C:\Program Files\Microsoft Office\Office15
# cscript ospp.vbs /sethst:192.168.123.1
# cscript ospp.vbs /act
# cscript ospp.vbs /dstatus

# windows手动激活命令

# slmgr.vbs /upk
# slmgr.vbs /skms 192.168.123.1
# slmgr.vbs /ipk XXXXX-XXXXX-XXXXX-XXXXX-XXXXX
# slmgr.vbs /ato
# slmgr.vbs /xpr

# key查看
# cat /etc/storage/key


#开头的字符号（#）或分号（;）的每一行被视为注释；删除（;）启用指定选项。
#ePID/HwId设置Windows为显式
;Windows = 06401-00206-471-111111-03-1033-9600.0000-3622014 / 01 02 03 04 05 06 07 08

#ePID设置Office2010（包含Visio和Project）为显式
;Office2010 = 06401-00096-199-222222-03-1033-9600.0000-3622014

#ePID/HwId设置Office2013（包含Visio和Project）为显式
;Office2013 = 06401-00206-234-333333-03-1033-9600.0000-3622014 / 01 02 03 04 05 06 07 08

#ePID/HwId设置Office2016（包含Visio和Project）为显式
;Office2016 = 06401-00206-437-444444-03-1033-9600.0000-3622014 / 01 02 03 04 05 06 07 08

# Set ePID/HwId for Windows China Government (Enterprise G/GN) explicitly
;WinChinaGov = 06401-03858-000-555555-03-1033-9600.0000-3622014 / 01 02 03 04 05 06 07 08

#使用兼容的VPN设备创建隐藏的本地IPv4地址
#命令行：-O
#VPN = <VPN适配器名称> [= <IPv4地址>] [/ <CIDR掩码>] [：<DHCP租期>
#使用VPN适配器“KMS镜像”，它的IP地址为192.168.123.100，租期为一天，使整个192.168.128.x成为隐藏的本地IPv4地址。
;VPN = KMS Mirror=192.168.123.100/24:1d

#使用自定义的TCP端口
#命令行：-P
#*** Port命令只有在vlmcsd被编译为使用MS RPC或简单套接字时才有效
#***使用Listen否则
;Port = 1688

#监听所有IPv4地址（默认端口1688）
# Command line: -L
# Does not work with MS RPC or simple sockets, use Port=
;Listen = 0.0.0.0:1688

#监听所有IPv6地址（默认端口1688）
# Command line: -L
;Listen = [::]:1688

#侦听所有私有IP地址，并拒绝来自公共IP地址的请求
# Command line: -o
# PublicIPProtectionLevel = 3

#允许绑定外部IP地址
# Command line: -F0 and -F1
;FreeBind = true

#程序启动时随机ePIDs（只有那些未指定的显式）
# Command line: -r
;RandomizationLevel = 1

#在ePIDs中使用特定区域 (1033 = 美国英语)，即使ePID是随机的
# Command line: -C
;LCID = 1033

#设置最多4个同时工作（分叉进程或线程）
# Command line: -m
;MaxWorkers = 4

#闲置30秒后断开用户
# Command line: -t
;ConnectionTimeout = 30

#每次请求后立即断开客户端
# Command line: -d and -k
;DisconnectClientsImmediately = yes

#写一个pid文件（包含vlmcsd的进程ID的文件）
# Command line: -p
;PidFile = /var/run/vlmcsd.pid

# Load a KMS data file
# Command line: -j
;KmsData = /etc/vlmcsd.kmd

#写日志到/var/log/vlmcsd.log
# Command line: -l (-e and -f also override this directive)
;LogFile = /var/log/vlmcsd.log

#不要在日志中包括日期和时间（默认值为true）
# Command line: -T0 and -T1
;LogDateAndTime = false

#创建详细日志
# Command line: -v and -q
;LogVerbose = true

#将已知产品列入白名单
# Command line: -K0, -K1, -K2, -K3
;WhiteListingLevel = 0

#检查客户端时间是否在系统时间的+/- 4小时之内
# Command line: -c0, -c1
;CheckClientTime = false

# Maintain a list of CMIDs
# Command line: -M0, -M1
;MaintainClients = false

# Start with empty CMID list (Requires MaintainClients = true)
# Command line: -E0, -E1
;StartEmpty = false

#设置激活间隔2小时
# Command line: -A
;ActivationInterval = 2h

#设置更新间隔7天
# Command line: -R
;RenewalInterval = 7d

# Exit vlmcsd if warning of certain level has been reached
# Command line: -x
# 0 = Never
# 1 = Exit, if any listening socket could not be established or TAP error occurs
;ExitLevel = 0

#运行程序的用户为vlmcsduser
# Command line: -u
;user = vlmcsduser

#运行程序的组为vlmcsdgroup
# Command line: -g
;group = vlmcsdgroup 

#禁用或启用RPC的NDR64传输语法（默认启用）
# Command line: -N0 and -N1
;UseNDR64 = true

#禁用或启用RPC的绑定时间特性协商（默认启用）
# Command line: -B0 and -B1
;UseBTFN = true

EEE
	chmod 755 "$vlmcsdini_script"
fi

kmskey="/tmp/key"
ln -sf /tmp/key /etc/storage/key
if [ ! -f "$kmskey" ] ; then
	cat > "$kmskey" <<-\EEE
# Office手动激活命令：

# cd C:\Program Files\Microsoft Office\Office15
# cscript ospp.vbs /sethst:192.168.123.1
# cscript ospp.vbs /act
# cscript ospp.vbs /dstatus

# windows手动激活命令

# slmgr.vbs /upk
# slmgr.vbs /skms 192.168.123.1
# slmgr.vbs /ipk XXXXX-XXXXX-XXXXX-XXXXX-XXXXX
# slmgr.vbs /ato
# slmgr.vbs /xpr

EEE
	chmod 666 "$kmskey"
fi

}

initconfig

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
	#kms_check
	kms_keep
	;;
*)
	kms_check
	;;
esac

