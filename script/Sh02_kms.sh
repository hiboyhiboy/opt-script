#!/bin/bash
#copyright by hiboy
source /etc/storage/script/init.sh
kms_enable=`nvram get kms_enable`
[ -z $kms_enable ] && kms_enable=0 && nvram set kms_enable=0
#[ "$kms_enable" != "0" ] && nvramshow=`nvram showall | grep '=' | grep kms | awk '{print gensub(/'"'"'/,"'"'"'\"'"'"'\"'"'"'","g",$0);}'| awk '{print gensub(/=/,"='\''",1,$0)"'\'';";}'` && eval $nvramshow

if [ ! -z "$(echo $scriptfilepath | grep -v "/tmp/script/" | grep kms)" ] && [ ! -s /tmp/script/_kms ] ; then
	mkdir -p /tmp/script
	{ echo '#!/bin/bash' ; echo $scriptfilepath '"$@"' '&' ; } > /tmp/script/_kms
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
i_app_keep -name="kms" -pidof="vlmcsd" &
}

kms_close () {
kill_ps "$scriptname keep"
sed -Ei '/【kms】|^$/d' /tmp/script/_opt_script_check
sed -Ei '/_vlmcs._tcp/d' /etc/storage/dnsmasq/dnsmasq.conf; restart_on_dhcpd;
killall vlmcsd vlmcsdini_script.sh
kill_ps "/tmp/script/_kms"
kill_ps "_kms.sh"
kill_ps "$scriptname"
}

kms_start () {

check_webui_yes
cmd_log_enable=`nvram get cmd_log_enable`
cmd_log=' -l /tmp/vlmcsd.log '
[ "$cmd_log_enable" = "1" ] && cmd_log=' -v -l syslog '
[ ! -f /etc_ro/vlmcsd.kmd ] && /usr/bin/vlmcsd -i /etc/storage/vlmcsdini_script.sh $cmd_log
[ -f /etc_ro/vlmcsd.kmd ] && /usr/bin/vlmcsd -j /etc_ro/vlmcsd.kmd -i /etc/storage/vlmcsdini_script.sh $cmd_log
computer_name=`nvram get computer_name`
sed -Ei '/_vlmcs._tcp/d' /etc/storage/dnsmasq/dnsmasq.conf
nvram set lan_domain="lan"
echo "srv-host=_vlmcs._tcp.lan,$computer_name.lan,1688,0,100" >> /etc/storage/dnsmasq/dnsmasq.conf
/etc/storage/vlmcsdini_script.sh
restart_on_dhcpd
sleep 4
[ ! -z "`pidof vlmcsd`" ] && logger -t "【kms】" "启动成功"
[ -z "`pidof vlmcsd`" ] && logger -t "【kms】" "启动失败, 注意检查端口是否有冲突,10 秒后自动尝试重新启动" && sleep 10 && { eval "$scriptfilepath &"; exit 0; }
eval "$scriptfilepath keep &"
exit 0
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
# https://docs.microsoft.com/en-us/windows-server/get-started/kmsclientkeys


#开头的字符号（#）或分号（;）的每一行被视为注释；删除（;）启用指定选项。
#明确设置Windows的ePID / HwId
;Windows = 06401-00206-471-111111-03-1033-17763.0000-2822018 / 01 02 03 04 05 06 07 08

#明确设置Office 2010（包括Visio和Project）的ePID
;Office2010 = 06401-00096-199-222222-03-1033-17763.0000-2822018

#明确设置Office 2013（包括Visio和Project）的ePID / HwId
;Office2013 = 06401-00206-234-333333-03-1033-17763.0000-2822018 / 01 02 03 04 05 06 07 08

#明确设置Office 2016（包括Visio和Project）的ePID / HwId
;Office2016 = 06401-00206-437-444444-03-1033-17763.0000-2822018 / 01 02 03 04 05 06 07 08

#明确设置Office 2019（包括Visio和Project）的ePID / HwId
;Office2019 = 06401-00206-666-666666-03-1033-17763.0000-2822018 / 01 02 03 04 05 06 07 08
#明确为Windows中国政府（企业G / GN）设置ePID / HwId
;WinChinaGov = 06401-03858-000-555555-03-1033-17763.0000-2822018 / 01 02 03 04 05 06 07 08

#使用兼容的VPN设备创建隐藏的本地IPv4地址
#命令行： -O
#VPN = <VPN适配器名称> [= <IPv4地址>] [/ <CIDR掩码>] [：<DHCP租约持续时间>]
#使用VPN适配器“KMS Mirror”为其提供IP地址192.168.123.100，租期为一天，并使整个192.168.128.x成为隐藏的本地IPv4地址。
;VPN = KMS Mirror=192.168.123.100/24:1d

#使用自定义TCP端口
#命令行： -P
#***只有在编译vlmcsd以使用MS RPC或简单套接字时，Port指令才有效
#***否则使用Listen
;Port = 1688

#监听所有IPv4地址（默认端口1688）
# Command line: -L
# Does not work with MS RPC or simple sockets, use Port=
;Listen = 0.0.0.0:1688

#监听所有IPv6地址（默认端口1688）
# Command line: -L
;Listen = [::]:1688

#侦听所有私有IP地址并拒绝来自公共IP地址的传入请求
# Command line: -o
# PublicIPProtectionLevel = 3

#允许绑定到外部IP地址
# Command line: -F0 and -F1
;FreeBind = true

#在程序启动时随机化ePID（仅限未明确指定的那些）
# Command line: -r
;RandomizationLevel = 1

#即使ePID是随机的，也要在ePID中使用特定的主机版本
# Command line: -H
;HostBuild = 17763

#即使ePID是随机的，也要在ePID中使用特定的文化（1033 = English US）
# Command line: -C
;LCID = 1033

#最多设置4个同时工作（分叉进程或线程）
# Command line: -m
;MaxWorkers = 4

#在30秒不活动后断开用户连接
# Command line: -t
;ConnectionTimeout = 30

#每次请求后立即断开客户端连接
# Command line: -d and -k
;DisconnectClientsImmediately = yes

#编写一个pid文件（包含进程ID为vlmcsd的文件）
# Command line: -p
;PidFile = /var/run/vlmcsd.pid

# Load a KMS data file
# Command line: -j
;KmsData = /etc/vlmcsd.kmd

#将日志写入/var/log/vlmcsd.log
# Command line: -l (-e and -f also override this directive)
;LogFile = /var/log/vlmcsd.log

#不要在日志中包含日期和时间（默认为true）
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

