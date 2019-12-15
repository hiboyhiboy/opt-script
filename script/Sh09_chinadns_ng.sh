#!/bin/sh
#copyright by hiboy
source /etc/storage/script/init.sh

chinadns_ng_enable="`nvram get app_102`"
[ -z $chinadns_ng_enable ] && chinadns_ng_enable=0 && nvram set app_102=0
chinadns_enable=`nvram get app_1`
[ -z $chinadns_enable ] && chinadns_enable=0 && nvram set app_1=0
#if [ "$chinadns_ng_enable" != "0" ] ; then
#nvramshow=`nvram showall | grep '=' | grep chinadns_ng | awk '{print gensub(/'"'"'/,"'"'"'\"'"'"'\"'"'"'","g",$0);}'| awk '{print gensub(/=/,"='\''",1,$0)"'\'';";}'` && eval $nvramshow
#fi
if [ "$chinadns_ng_enable" == "1" ] ; then
[ "$chinadns_enable" == "0" ] && logger -t "【chinadns】" "注意！！！需要关闭 ChinaDNS-NG 后才能关闭 ChinaDNS"
chinadns_enable=1 && nvram set app_1=1
fi

chinadns_ng_usage=`nvram get app_103`
[ -z "$chinadns_ng_usage" ] && chinadns_ng_usage=' -n -b 0.0.0.0 -c 223.5.5.5 -t 127.0.0.1#55353 -g /opt/app/chinadns_ng/gfwlist.txt ' && nvram set app_103="$chinadns_ng_usage"
chinadns_ng_port=`nvram get app_6`
[ -z $chinadns_ng_port ] && chinadns_ng_port=8053 && nvram set app_6=8053

chinadns_ng_renum=`nvram get chinadns_ng_renum`
chinadns_ng_renum=${chinadns_ng_renum:-"0"}
cmd_log_enable=`nvram get cmd_log_enable`
cmd_name="chinadns_ng"
cmd_log=""
if [ "$cmd_log_enable" = "1" ] || [ "$chinadns_ng_renum" -gt "0" ] ; then
	cmd_log="$cmd_log2"
fi


if [ ! -z "$(echo $scriptfilepath | grep -v "/tmp/script/" | grep chinadns_ng)" ]  && [ ! -s /tmp/script/_app19 ]; then
	mkdir -p /tmp/script
	{ echo '#!/bin/sh' ; echo $scriptfilepath '"$@"' '&' ; } > /tmp/script/_app19
	chmod 777 /tmp/script/_app19
fi

chinadns_ng_restart () {

relock="/var/lock/chinadns_ng_restart.lock"
if [ "$1" = "o" ] ; then
	nvram set chinadns_ng_renum="0"
	[ -f $relock ] && rm -f $relock
	return 0
fi
if [ "$1" = "x" ] ; then
	if [ -f $relock ] ; then
		logger -t "【chinadns_ng】" "多次尝试启动失败，等待【"`cat $relock`"分钟】后自动尝试重新启动"
		exit 0
	fi
	chinadns_ng_renum=${chinadns_ng_renum:-"0"}
	chinadns_ng_renum=`expr $chinadns_ng_renum + 1`
	nvram set chinadns_ng_renum="$chinadns_ng_renum"
	if [ "$chinadns_ng_renum" -gt "2" ] ; then
		I=19
		echo $I > $relock
		logger -t "【chinadns_ng】" "多次尝试启动失败，等待【"`cat $relock`"分钟】后自动尝试重新启动"
		while [ $I -gt 0 ]; do
			I=$(($I - 1))
			echo $I > $relock
			sleep 60
			[ "$(nvram get chinadns_ng_renum)" = "0" ] && exit 0
			[ $I -lt 0 ] && break
		done
		nvram set chinadns_ng_renum="0"
	fi
	[ -f $relock ] && rm -f $relock
fi
nvram set chinadns_ng_status=0
eval "$scriptfilepath &"
exit 0
}

chinadns_ng_get_status () {

#lan_ipaddr=`nvram get lan_ipaddr`
A_restart=`nvram get chinadns_ng_status`
B_restart="$chinadns_ng_enable$chinadns_ng_usage"
B_restart=`echo -n "$B_restart" | md5sum | sed s/[[:space:]]//g | sed s/-//g`
if [ "$A_restart" != "$B_restart" ] ; then
	nvram set chinadns_ng_status=$B_restart
	needed_restart=1
else
	needed_restart=0
fi
}

chinadns_ng_check () {

chinadns_ng_get_status
if [ "$chinadns_ng_enable" != "1" ] && [ "$needed_restart" = "1" ] ; then
	[ ! -z "$(ps -w | grep "/opt/bin/chinadns_ng" | grep -v grep )" ] && logger -t "【chinadns_ng】" "停止 chinadns_ng" && chinadns_close
	{ kill_ps "$scriptname" exit0; exit 0; }
fi
if [ "$chinadns_ng_enable" = "1" ] ; then
	if [ "$needed_restart" = "1" ] ; then
		chinadns_ng_close
		chinadns_ng_start
	else
		[ -z "$(ps -w | grep "/opt/bin/chinadns_ng" | grep -v grep )" ] && chinadns_ng_restart
		port=$(grep "server=127.0.0.1#$chinadns_ng_port"  /etc/storage/dnsmasq/dnsmasq.conf | wc -l)
		if [ "$port" = 0 ] ; then
			sleep 10
			port=$(grep "server=127.0.0.1#$chinadns_ng_port"  /etc/storage/dnsmasq/dnsmasq.conf | wc -l)
		fi
		if [ "$port" = 0 ] ; then
			logger -t "【chinadns_ng】" "检测:找不到 dnsmasq 转发规则, 重新添加"
			# 写入dnsmasq配置
			sed -Ei '/no-resolv|server=|server=127.0.0.1|dns-forward-max=1000|min-cache-ttl=1800|chinadns_ng/d' /etc/storage/dnsmasq/dnsmasq.conf
			cat >> "/etc/storage/dnsmasq/dnsmasq.conf" <<-EOF
no-resolv #chinadns_ng
server=127.0.0.1#$chinadns_ng_port #chinadns_ng
dns-forward-max=1000 #chinadns_ng
min-cache-ttl=1800 #chinadns_ng
domain-needed #chinadns_ng
EOF
			restart_dhcpd
		fi
	fi
fi
}

chinadns_ng_keep () {
logger -t "【chinadns_ng】" "守护进程启动"
if [ -s /tmp/script/_opt_script_check ]; then
sed -Ei '/【chinadns_ng】|^$/d' /tmp/script/_opt_script_check
cat >> "/tmp/script/_opt_script_check" <<-OSC
	NUM=\`grep "/opt/bin/chinadns_ng" /tmp/ps | grep -v grep |wc -l\` # 【chinadns_ng】
	if [ "\$NUM" -lt "1" ] || [ ! -s "/opt/bin/chinadns_ng" ] ; then # 【chinadns_ng】
		logger -t "【chinadns_ng】" "重新启动\$NUM" # 【chinadns_ng】
		nvram set chinadns_ng_status=00 && eval "$scriptfilepath &" && sed -Ei '/【chinadns_ng】|^$/d' /tmp/script/_opt_script_check # 【chinadns_ng】
	fi # 【chinadns_ng】
OSC
#return
fi
sleep 60
chinadns_ng_enable=`nvram get app_102` #chinadns_ng_enable
while [ "$chinadns_ng_enable" = "1" ]; do
	NUM=`ps -w | grep "/opt/bin/chinadns_ng" | grep -v grep |wc -l`
	if [ "$NUM" -lt "1" ] || [ ! -s "/opt/bin/chinadns_ng" ] ; then
		logger -t "【chinadns_ng】" "重新启动$NUM"
		chinadns_ng_restart
	fi
	port=$(grep "server=127.0.0.1#$chinadns_ng_port"  /etc/storage/dnsmasq/dnsmasq.conf | wc -l)
	if [ "$port" = 0 ] ; then
		sleep 10
		port=$(grep "server=127.0.0.1#$chinadns_ng_port"  /etc/storage/dnsmasq/dnsmasq.conf | wc -l)
	fi
	if [ "$port" = 0 ] ; then
		logger -t "【chinadns_ng】" "检测:找不到 dnsmasq 转发规则, 重新添加"
		# 写入dnsmasq配置
		sed -Ei '/no-resolv|server=|server=127.0.0.1|dns-forward-max=1000|min-cache-ttl=1800|chinadns_ng/d' /etc/storage/dnsmasq/dnsmasq.conf
		cat >> "/etc/storage/dnsmasq/dnsmasq.conf" <<-EOF
no-resolv #chinadns_ng
server=127.0.0.1#$chinadns_ng_port #chinadns_ng
dns-forward-max=1000 #chinadns_ng
min-cache-ttl=1800 #chinadns_ng
domain-needed #chinadns_ng
EOF
		restart_dhcpd
	fi
sleep 69
chinadns_ng_enable=`nvram get app_102` #chinadns_ng_enable
done
}

chinadns_ng_close () {
sed -Ei '/【chinadns_ng】|【chinadns】|^$/d' /tmp/script/_opt_script_check
sed -Ei '/no-resolv|server=|server=127.0.0.1|dns-forward-max=1000|min-cache-ttl=1800|chinadns_ng/d' /etc/storage/dnsmasq/dnsmasq.conf
ipset -F chnroute
ipset -F chnroute6
restart_dhcpd
killall chinadns chinadns_ng dns2tcp
killall -9 chinadns chinadns_ng dns2tcp
kill_ps "/tmp/script/_app1"
kill_ps "_chinadns.sh"
kill_ps "/tmp/script/_app19"
kill_ps "_chinadns_ng.sh"
kill_ps "$scriptname"
}

chinadns_ng_start () {
check_webui_yes
SVC_PATH="/opt/bin/chinadns_ng"
[[ "$("$SVC_PATH" -h | wc -l)" -lt 2 ]] && rm -rf "$SVC_PATH"
if [ ! -s "$SVC_PATH" ] ; then
	logger -t "【chinadns_ng】" "找不到 $SVC_PATH，安装 opt 程序"
	/tmp/script/_mountopt start
fi
wgetcurl_file "$SVC_PATH" "$hiboyfile/chinadns_ng" "$hiboyfile2/chinadns_ng"
if [ ! -s "$SVC_PATH" ] ; then
	logger -t "【chinadns_ng】" "找不到 $SVC_PATH ，需要手动安装 $SVC_PATH"
	logger -t "【chinadns_ng】" "启动失败, 10 秒后自动尝试重新启动" && sleep 10 && chinadns_ng_restart x
else
ln -sf /opt/bin/chinadns_ng /opt/bin/chinadns-ng
fi
wgetcurl_file /opt/bin/dns2tcp "$hiboyfile/dns2tcp" "$hiboyfile2/dns2tcp"
if [ ! -s "/opt/bin/dns2tcp" ] ; then
	logger -t "【chinadns_ng】" "找不到 /opt/bin/dns2tcp ，需要手动安装 /opt/bin/dns2tcp"
	logger -t "【chinadns_ng】" "启动失败, 10 秒后自动尝试重新启动" && sleep 10 && chinadns_ng_restart x
fi
logger -t "【chinadns_ng】" "运行 /opt/bin/dns2tcp"
cmd_name="dns2tcp"
eval "/opt/bin/dns2tcp -L0.0.0.0#55353 -R8.8.8.8#53 $cmd_log" &
[ ! -f /opt/app/chinadns_ng/gfwlist.txt ] && update_gfwlist
# 配置参数 '/opt/bin/chinadns_ng -l 8053  -n -b 0.0.0.0 -c 223.5.5.5 -t 127.0.0.1#55353 -g /opt/app/chinadns_ng/gfwlist.txt  '
usage=" -l $chinadns_ng_port "
usage="$usage $chinadns_ng_usage "
update_app
chinadns_ng_v=`chinadns_ng -V | awk -F ' ' '{print $2;}'`
nvram set chinadns_ng_v="$chinadns_ng_v"

killall dnsproxy && killall -9 dnsproxy 2>/dev/null
killall pdnsd && killall -9 pdnsd 2>/dev/null
killall chinadns && killall -9 chinadns 2>/dev/null
logger -t "【chinadns_ng】" "运行 $SVC_PATH"
cmd_name="chinadns_ng"
eval "/opt/bin/chinadns_ng $usage $cmd_log" &
sleep 2
[ ! -f /opt/app/chinadns_ng/chnroute.ipset ] && update_chnroute || { ipset -F chnroute; ipset -R -exist </opt/app/chinadns_ng/chnroute.ipset; }
[ ! -f /opt/app/chinadns_ng/chnroute6.ipset ] && update_chnroute6 || { ipset -F chnroute6; ipset -R -exist </opt/app/chinadns_ng/chnroute6.ipset; }

[ ! -z "$(ps -w | grep "/opt/bin/chinadns_ng" | grep -v grep )" ] && [ ! -z "$(ps -w | grep "/opt/bin/dns2tcp" | grep -v grep )" ] && logger -t "【chinadns_ng】" "启动成功 $chinadns_ng_v " && chinadns_ng_restart o
[ -z "$(ps -w | grep "/opt/bin/chinadns_ng" | grep -v grep )" ] && logger -t "【chinadns_ng】" "/opt/bin/chinadns_ng 启动失败, 注意检查端口是否有冲突,程序是否下载完整,10 秒后自动尝试重新启动" && sleep 10 && chinadns_ng_restart x
[ -z "$(ps -w | grep "/opt/bin/dns2tcp" | grep -v grep )" ] && logger -t "【chinadns_ng】" "/opt/bin/dns2tcp 启动失败, 注意检查端口是否有冲突,程序是否下载完整,10 秒后自动尝试重新启动" && sleep 10 && chinadns_ng_restart x
initopt

# 写入dnsmasq配置
sed -Ei '/no-resolv|server=|server=127.0.0.1|dns-forward-max=1000|min-cache-ttl=1800|chinadns_ng/d' /etc/storage/dnsmasq/dnsmasq.conf
	cat >> "/etc/storage/dnsmasq/dnsmasq.conf" <<-EOF
no-resolv #chinadns_ng
server=127.0.0.1#$chinadns_ng_port #chinadns_ng
dns-forward-max=1000 #chinadns_ng
min-cache-ttl=1800 #chinadns_ng
domain-needed #chinadns_ng
EOF

restart_dhcpd

chinadns_ng_get_status
eval "$scriptfilepath keep &"
exit 0
}

update_gfwlist () {
wgetcurl_checkmd5 /opt/app/chinadns_ng/gfwlist.b64 https://raw.github.com/gfwlist/gfwlist/master/gfwlist.txt https://raw.githubusercontent.com/gfwlist/gfwlist/master/gfwlist.txt N
	base64 -d  /opt/app/chinadns_ng/gfwlist.b64 > /opt/app/chinadns_ng/gfwlist.txt
	cat /opt/app/chinadns_ng/gfwlist.txt | sort -u |
			sed '/^$\|@@/d'|
			sed 's#!.\+##; s#|##g; s#@##g; s#http:\/\/##; s#https:\/\/##;' | 
			sed '/\*/d; /apple\.com/d; /sina\.cn/d; /sina\.com\.cn/d; /baidu\.com/d; /byr\.cn/d; /jlike\.com/d; /weibo\.com/d; /zhongsou\.com/d; /youdao\.com/d; /sogou\.com/d; /so\.com/d; /soso\.com/d; /aliyun\.com/d; /taobao\.com/d; /jd\.com/d; /qq\.com/d' |
			sed '/^[0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+$/d' |
			grep '^[0-9a-zA-Z\.-]\+$' | grep '\.' | sed 's#^\.\+##'  | sort -u > /opt/app/chinadns_ng/gfwlist_domain.txt
echo "whatsapp.net" >> /opt/app/chinadns_ng/gfwlist_domain.txt
	printf "twimg.edgesuite.net\n" >> /opt/app/chinadns_ng/gfwlist_domain.txt
	printf "blogspot.ae\nblogspot.al\nblogspot.am\nblogspot.ba\nblogspot.be\nblogspot.bg\nblogspot.bj\nblogspot.ca\nblogspot.cat\nblogspot.cf\nblogspot.ch\nblogspot.cl\nblogspot.co.at\nblogspot.co.id\nblogspot.co.il\nblogspot.co.ke\nblogspot.com\nblogspot.com.ar\nblogspot.com.au\nblogspot.com.br\nblogspot.com.by\nblogspot.com.co\nblogspot.com.cy\nblogspot.com.ee\nblogspot.com.eg\nblogspot.com.es\nblogspot.com.mt\nblogspot.com.ng\nblogspot.com.tr\nblogspot.com.uy\nblogspot.co.nz\nblogspot.co.uk\nblogspot.co.za\nblogspot.cv\nblogspot.cz\nblogspot.de\nblogspot.dk\nblogspot.fi\nblogspot.fr\nblogspot.gr\nblogspot.hk\nblogspot.hr\nblogspot.hu\nblogspot.ie\nblogspot.in\nblogspot.is\nblogspot.it\nblogspot.jp\nblogspot.kr\nblogspot.li\nblogspot.lt\nblogspot.lu\nblogspot.md\nblogspot.mk\nblogspot.mr\nblogspot.mx\nblogspot.my\nblogspot.nl\nblogspot.no\nblogspot.pe\nblogspot.pt\nblogspot.qa\nblogspot.re\nblogspot.ro\nblogspot.rs\nblogspot.ru\nblogspot.se\nblogspot.sg\nblogspot.si\nblogspot.sk\nblogspot.sn\nblogspot.td\nblogspot.tw\nblogspot.ug\nblogspot.vn\n" >> /opt/app/chinadns_ng/gfwlist_domain.txt
	printf "dns.google\ngoogle.ac\ngoogle.ad\ngoogle.ae\ngoogle.al\ngoogle.am\ngoogle.as\ngoogle.at\ngoogle.az\ngoogle.ba\ngoogle.be\ngoogle.bf\ngoogle.bg\ngoogle.bi\ngoogle.bj\ngoogle.bs\ngoogle.bt\ngoogle.by\ngoogle.ca\ngoogle.cat\ngoogle.cc\ngoogle.cd\ngoogle.cf\ngoogle.cg\ngoogle.ch\ngoogle.ci\ngoogle.cl\ngoogle.cm\ngoogle.cn\ngoogle.co.ao\ngoogle.co.bw\ngoogle.co.ck\ngoogle.co.cr\ngoogle.co.id\ngoogle.co.il\ngoogle.co.in\ngoogle.co.jp\ngoogle.co.ke\ngoogle.co.kr\ngoogle.co.ls\ngoogle.com\ngoogle.co.ma\ngoogle.com.af\ngoogle.com.ag\ngoogle.com.ai\ngoogle.com.ar\ngoogle.com.au\ngoogle.com.bd\ngoogle.com.bh\ngoogle.com.bn\ngoogle.com.bo\ngoogle.com.br\ngoogle.com.bz\ngoogle.com.co\ngoogle.com.cu\ngoogle.com.cy\ngoogle.com.do\ngoogle.com.ec\ngoogle.com.eg\ngoogle.com.et\ngoogle.com.fj\ngoogle.com.gh\ngoogle.com.gi\ngoogle.com.gt\ngoogle.com.hk\ngoogle.com.jm\ngoogle.com.kh\ngoogle.com.kw\ngoogle.com.lb\ngoogle.com.lc\ngoogle.com.ly\ngoogle.com.mm\ngoogle.com.mt\ngoogle.com.mx\ngoogle.com.my\ngoogle.com.na\ngoogle.com.nf\ngoogle.com.ng\ngoogle.com.ni\ngoogle.com.np\ngoogle.com.om\ngoogle.com.pa\ngoogle.com.pe\ngoogle.com.pg\ngoogle.com.ph\ngoogle.com.pk\ngoogle.com.pr\ngoogle.com.py\ngoogle.com.qa\ngoogle.com.sa\ngoogle.com.sb\ngoogle.com.sg\ngoogle.com.sl\ngoogle.com.sv\ngoogle.com.tj\ngoogle.com.tr\ngoogle.com.tw\ngoogle.com.ua\ngoogle.com.uy\ngoogle.com.vc\ngoogle.com.vn\ngoogle.co.mz\ngoogle.co.nz\ngoogle.co.th\ngoogle.co.tz\ngoogle.co.ug\ngoogle.co.uk\ngoogle.co.uz\ngoogle.co.ve\ngoogle.co.vi\ngoogle.co.za\ngoogle.co.zm\ngoogle.co.zw\ngoogle.cv\ngoogle.cz\ngoogle.de\ngoogle.dj\ngoogle.dk\ngoogle.dm\ngoogle.dz\ngoogle.ee\ngoogle.es\ngoogle.fi\ngoogle.fm\ngoogle.fr\ngoogle.ga\ngoogle.ge\ngoogle.gf\ngoogle.gg\ngoogle.gl\ngoogle.gm\ngoogle.gp\ngoogle.gr\ngoogle.gy\ngoogle.hn\ngoogle.hr\ngoogle.ht\ngoogle.hu\ngoogle.ie\ngoogle.im\ngoogle.io\ngoogle.iq\ngoogle.is\ngoogle.it\ngoogle.je\ngoogle.jo\ngoogle.kg\ngoogle.ki\ngoogle.kz\ngoogle.la\ngoogle.li\ngoogle.lk\ngoogle.lt\ngoogle.lu\ngoogle.lv\ngoogle.md\ngoogle.me\ngoogle.mg\ngoogle.mk\ngoogle.ml\ngoogle.mn\ngoogle.ms\ngoogle.mu\ngoogle.mv\ngoogle.mw\ngoogle.ne\ngoogle.net\ngoogle.nl\ngoogle.no\ngoogle.nr\ngoogle.nu\ngoogle.org\ngoogle.pl\ngoogle.pn\ngoogle.ps\ngoogle.pt\ngoogle.ro\ngoogle.rs\ngoogle.ru\ngoogle.rw\ngoogle.sc\ngoogle.se\ngoogle.sh\ngoogle.si\ngoogle.sk\ngoogle.sm\ngoogle.sn\ngoogle.so\ngoogle.sr\ngoogle.st\ngoogle.td\ngoogle.tg\ngoogle.tk\ngoogle.tl\ngoogle.tm\ngoogle.tn\ngoogle.to\ngoogle.tt\ngoogle.vg\ngoogle.vu\ngoogle.ws\n" >> /opt/app/chinadns_ng/gfwlist_domain.txt
grep -v '^#' /etc/storage/basedomain.txt | sort -u | grep -v "^$" > /opt/app/chinadns_ng/gfwlist.txt
grep -v '^#' /opt/app/chinadns_ng/gfwlist_domain.txt | sort -u | grep -v "^$" >> /opt/app/chinadns_ng/gfwlist.txt
rm -f /opt/app/chinadns_ng/gfwlist.b64 /opt/app/chinadns_ng/gfwlist_domain.txt

}

update_chnroute () {
echo "create chnroute hash:net family inet" >/opt/app/chinadns_ng/chnroute.ipset
curl -4sSkL 'http://ftp.apnic.net/apnic/stats/apnic/delegated-apnic-latest' | grep CN | grep ipv4 | awk -F'|' '{printf("add chnroute %s/%d\n", $4, 32-log($5)/log(2))}' >>/opt/app/chinadns_ng/chnroute.ipset
ipset -F chnroute
ipset -R -exist </opt/app/chinadns_ng/chnroute.ipset


}

update_chnroute6 () {
echo "create chnroute6 hash:net family inet6" >/opt/app/chinadns_ng/chnroute6.ipset
curl -4sSkL 'http://ftp.apnic.net/apnic/stats/apnic/delegated-apnic-latest' | grep CN | grep ipv6 | awk -F'|' '{printf("add chnroute6 %s/%d\n", $4, $5)}' >>/opt/app/chinadns_ng/chnroute6.ipset
ipset -F chnroute6
ipset -R -exist </opt/app/chinadns_ng/chnroute6.ipset

}

initopt () {
mkdir -p /opt/app/chinadns_ng
optPath=`grep ' /opt ' /proc/mounts | grep tmpfs`
[ ! -z "$optPath" ] && return
if [ ! -z "$(echo $scriptfilepath | grep -v "/opt/etc/init")" ] && [ -s "/opt/etc/init.d/rc.func" ] ; then
	{ echo '#!/bin/sh' ; echo $scriptfilepath '"$@"' '&' ; } > /opt/etc/init.d/$scriptname && chmod 777  /opt/etc/init.d/$scriptname
fi

}

update_init () {
source /etc/storage/script/init.sh
[ "$init_ver" -lt 0 ] && init_ver="0" || { [ "$init_ver" -gt 0 ] || init_ver="0" ; }
init_s_ver=2
if [ "$init_s_ver" -gt "$init_ver" ] ; then
	logger -t "【update_init】" "更新 /etc/storage/script/init.sh 文件"
	wgetcurl.sh /tmp/init_tmp.sh  "$hiboyscript/script/init.sh" "$hiboyscript2/script/init.sh"
	[ -s /tmp/init_tmp.sh ] && cp -f /tmp/init_tmp.sh /etc/storage/script/init.sh
	chmod 755 /etc/storage/script/init.sh
	source /etc/storage/script/init.sh
fi
}

update_app () {
update_init
if [ "$1" = "del" ] ; then
	rm -rf /opt/bin/dns2tcp /opt/opt_backup/bin/dns2tcp /opt/bin/chinadns_ng /opt/opt_backup/bin/chinadns_ng /opt/app/chinadns_ng/Advanced_Extensions_chinadns_ng.asp /opt/app/chinadns_ng/gfwlist.txt /opt/app/chinadns_ng/chnroute6.ipset /opt/app/chinadns_ng/chnroute.ipset
fi
# 加载程序配置页面
mkdir -p /opt/app/chinadns_ng
if [ ! -f "/opt/app/chinadns_ng/Advanced_Extensions_chinadns_ng.asp" ] || [ ! -s "/opt/app/chinadns_ng/Advanced_Extensions_chinadns_ng.asp" ] ; then
	wgetcurl.sh /opt/app/chinadns_ng/Advanced_Extensions_chinadns_ng.asp "$hiboyfile/Advanced_Extensions_chinadns_ngasp" "$hiboyfile2/Advanced_Extensions_chinadns_ngasp"
fi
umount /www/Advanced_Extensions_app19.asp
mount --bind /opt/app/chinadns_ng/Advanced_Extensions_chinadns_ng.asp /www/Advanced_Extensions_app19.asp
# 更新程序启动脚本
[ "$1" = "del" ] && /etc/storage/www_sh/chinadns_ng del &
}

case $ACTION in
start)
	chinadns_ng_close
	chinadns_ng_check
	;;
check)
	chinadns_ng_check
	;;
stop)
	chinadns_ng_close
	;;
keep)
	#chinadns_ng_check
	chinadns_ng_keep
	;;
updateapp19)
	chinadns_ng_restart o
	[ "$chinadns_ng_enable" = "1" ] && nvram set chinadns_ng_status="updatechinadns_ng" && logger -t "【chinadns_ng】" "更新规则" && { update_gfwlist; update_chnroute; update_chnroute6; chinadns_ng_restart; }
	[ "$chinadns_ng_enable" != "1" ] && nvram set chinadns_ng_v="" && logger -t "【chinadns_ng】" "更新" && update_app del
	;;
update_app)
	update_app
	;;
*)
	chinadns_ng_check
	;;
esac

