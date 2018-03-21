#!/bin/sh
#copyright by hiboy
source /etc/storage/script/init.sh

fakeincn_enable=`nvram get app_7`
[ -z $fakeincn_enable ] && fakeincn_enable=0 && nvram set app_7=0
if [ "$fakeincn_enable" != "0" ] ; then
#nvramshow=`nvram showall | grep '=' | grep fakeincn | awk '{print gensub(/'"'"'/,"'"'"'\"'"'"'\"'"'"'","g",$0);}'| awk '{print gensub(/=/,"='\''",1,$0)"'\'';";}'` && eval $nvramshow
fakeincn_enable=`nvram get app_7`
[ -z $fakeincn_enable ] && fakeincn_enable=0 && nvram set app_7=0
fi
fakeincn_path="/etc/storage/app_1.sh"


if [ ! -z "$(echo $scriptfilepath | grep -v "/tmp/script/" | grep fakeincn)" ]  && [ ! -s /tmp/script/_app2 ]; then
	mkdir -p /tmp/script
	{ echo '#!/bin/sh' ; echo $scriptfilepath '"$@"' '&' ; } > /tmp/script/_app2
	chmod 777 /tmp/script/_app2
fi

fakeincn_restart () {

fakeincn_renum=`nvram get fakeincn_renum`
relock="/var/lock/fakeincn_restart.lock"
if [ "$1" = "o" ] ; then
	nvram set fakeincn_renum="0"
	[ -f $relock ] && rm -f $relock
	return 0
fi
if [ "$1" = "x" ] ; then
	if [ -f $relock ] ; then
		logger -t "【fakeincn】" "多次尝试启动失败，等待【"`cat $relock`"分钟】后自动尝试重新启动"
		exit 0
	fi
	fakeincn_renum=${fakeincn_renum:-"0"}
	fakeincn_renum=`expr $fakeincn_renum + 1`
	nvram set fakeincn_renum="$fakeincn_renum"
	if [ "$fakeincn_renum" -gt "2" ] ; then
		I=19
		echo $I > $relock
		logger -t "【fakeincn】" "多次尝试启动失败，等待【"`cat $relock`"分钟】后自动尝试重新启动"
		while [ $I -gt 0 ]; do
			I=$(($I - 1))
			echo $I > $relock
			sleep 60
			[ "$(nvram get fakeincn_renum)" = "0" ] && exit 0
			[ $I -lt 0 ] && break
		done
		nvram set fakeincn_renum="0"
	fi
	[ -f $relock ] && rm -f $relock
fi
nvram set fakeincn_status=0
eval "$scriptfilepath &"
exit 0
}

fakeincn_get_status () {

#lan_ipaddr=`nvram get lan_ipaddr`
A_restart=`nvram get fakeincn_status`
B_restart="$fakeincn_enable$fakeincn_path$(cat /etc/storage/app_1.sh /etc/storage/app_2.sh | grep -v '^#' | grep -v "^$")"
B_restart=`echo -n "$B_restart" | md5sum | sed s/[[:space:]]//g | sed s/-//g`
if [ "$A_restart" != "$B_restart" ] ; then
	nvram set fakeincn_status=$B_restart
	needed_restart=1
else
	needed_restart=0
fi
}

fakeincn_check () {

fakeincn_get_status
if [ "$fakeincn_enable" != "1" ] && [ "$needed_restart" = "1" ] ; then
	[ ! -z "$(ps -w | grep "$fakeincn_path" | grep -v grep )" ] && logger -t "【fakeincn】" "停止 fakeincn" && fakeincn_close
	{ kill_ps "$scriptname" exit0; exit 0; }
fi
if [ "$fakeincn_enable" = "1" ] ; then
	if [ "$needed_restart" = "1" ] ; then
		fakeincn_close
		fakeincn_start
	else
		[ -z "$(ps -w | grep "$fakeincn_path" | grep -v grep )" ] && fakeincn_restart
		port=$(iptables -t nat -L | grep 'redir ports 1008' | wc -l)
		if [ "$port" = 0 ] ; then
			logger -t "【fakeincn】" "检测:找不到 1008 转发规则, 重新添加"
			fakeincn_restart
		fi
	fi
fi
}

fakeincn_keep () {
logger -t "【fakeincn】" "守护进程启动"
if [ -s /tmp/script/_opt_script_check ]; then
sed -Ei '/【fakeincn】|^$/d' /tmp/script/_opt_script_check
cat >> "/tmp/script/_opt_script_check" <<-OSC
	NUM=\`grep "$fakeincn_path" /tmp/ps | grep -v grep |wc -l\` # 【fakeincn】
	if [ "\$NUM" -lt "1" ] || [ ! -s "$fakeincn_path" ] ; then # 【fakeincn】
		logger -t "【fakeincn】" "重新启动\$NUM" # 【fakeincn】
		nvram set fakeincn_status=00 && eval "$scriptfilepath &" && sed -Ei '/【fakeincn】|^$/d' /tmp/script/_opt_script_check # 【fakeincn】
	fi # 【fakeincn】
OSC
#return
fi
sleep 60
fakeincn_enable=`nvram get app_7` #fakeincn_enable
while [ "$fakeincn_enable" = "1" ]; do
	NUM=`ps -w | grep "$fakeincn_path" | grep -v grep |wc -l`
	if [ "$NUM" -lt "1" ] || [ ! -s "$fakeincn_path" ] ; then
		logger -t "【fakeincn】" "重新启动$NUM"
		fakeincn_restart
	fi
	port=$(iptables -t nat -L | grep 'redir ports 1008' | wc -l)
	if [ "$port" = 0 ] ; then
		logger -t "【fakeincn】" "检测:找不到 1008 转发规则, 重新添加"
		eval "$scriptfilepath rules &"
	fi
sleep 69
fakeincn_enable=`nvram get app_7` #fakeincn_enable
done
}

fakeincn_close () {
sed -Ei '/【fakeincn】|^$/d' /tmp/script/_opt_script_check
iptables -t nat -D PREROUTING -p tcp -m set --match-set rtocn dst -j REDIRECT --to-port 1008
iptables -t nat -D OUTPUT -p tcp -m set --match-set rtocn dst -j REDIRECT --to-port 1008
iptables -t nat -D PREROUTING -p tcp -m set --match-set tocn dst -j REDIRECT --to-port 1008
iptables -t nat -D OUTPUT -p tcp -m set --match-set tocn dst -j REDIRECT --to-port 1008
rm -rf /etc/storage/dnsmasq/dnsmasq.d/r.tocn.conf
restart_dhcpd
[ ! -z "$fakeincn_path" ] && eval $(ps -w | grep 'l 1008' | grep -v grep | awk '{print "kill "$1";";}')
killall app_1.sh fakeincn
killall -9 app_1.sh fakeincn
kill_ps "/tmp/script/_app2"
kill_ps "_fakeincn.sh"
kill_ps "$scriptname"
}

fakeincn_start () {

optssredir="0"
# SS
chmod 777 "`which ss-redir`"
	[[ "$(ss-redir -h | wc -l)" -lt 2 ]] && rm -rf /opt/bin/ss-redir
hash ss-redir 2>/dev/null || optssredir="1"
if [ "$optssredir" != "0" ] ; then
	# 找不到ss-redir，安装opt
	logger -t "【SS】" "找不到 ss-redir 、 ss-local 或 obfs-local ，挂载opt"
	/tmp/script/_mountopt start
	initopt
fi
optssredir="0"
hash ss-redir 2>/dev/null || optssredir="1"
if [ "$optssredir" = "1" ] ; then
	logger -t "【SS】" "找不到 ss-redir. opt下载程序"
	[ ! -s /opt/bin/ss-redir ] && wgetcurl.sh "/opt/bin/ss-redir" "$hiboyfile/ss-redir" "$hiboyfile2/ss-redir"
	chmod 777 "/opt/bin/ss-redir"
	[[ "$(ss-redir -h | wc -l)" -lt 2 ]] && rm -rf /opt/bin/ss-redir
	[ ! -s `which ss-redir` ] && { logger -t "【SS】" "找不到 ss-redir, 请检查系统"; fakeincn_restart x ; }
hash ss-redir 2>/dev/null || { logger -t "【SS】" "找不到 ss-redir, 请检查系统"; fakeincn_restart x ; }
fi
update_app

fakeincn_v=$(grep 'fakeincn_v=' /etc/storage/app_1.sh | awk -F '=' '{print $2;}')
nvram set fakeincn_v="$fakeincn_v"
logger -t "【fakeincn】" "运行 $fakeincn_path"
eval $fakeincn_path &
sleep 2
[ ! -z "$(ps -w | grep "/opt/app/fakeincn/fakeincn" | grep -v grep )" ] && logger -t "【fakeincn】" "启动成功 $fakeincn_v " && fakeincn_restart o
[ -z "$(ps -w | grep "/opt/app/fakeincn/fakeincn" | grep -v grep )" ] && logger -t "【fakeincn】" "启动失败, 注意检查端口是否有冲突,程序是否下载完整,10 秒后自动尝试重新启动" && sleep 10 && fakeincn_restart x

#载入iptables模块
for module in ip_set ip_set_bitmap_ip ip_set_bitmap_ipmac ip_set_bitmap_port ip_set_hash_ip ip_set_hash_ipport ip_set_hash_ipportip ip_set_hash_ipportnet ip_set_hash_net ip_set_hash_netport ip_set_list_set xt_set xt_TPROXY
do
	modprobe $module
done 

# 写入防火墙规则

logger -t "【fakeincn】" "防火墙规则恢复，开始返回国内规则"

ipset -! -N tocn iphash

iptables -t nat -D PREROUTING -p tcp -m set --match-set tocn dst -j REDIRECT --to-port 1008
iptables -t nat -D OUTPUT -p tcp -m set --match-set tocn dst -j REDIRECT --to-port 1008
iptables -t nat -A PREROUTING -p tcp -m set --match-set tocn dst -j REDIRECT --to-port 1008
iptables -t nat -A OUTPUT -p tcp -m set --match-set tocn dst -j REDIRECT --to-port 1008

while read line ; do ipset add tocn $line ;done <<-EOF
120.92.96.181
101.227.139.217
101.227.169.200
103.7.30.89
103.7.31.186
106.11.186.4
106.11.47.20
106.11.47.19
106.11.209.2
111.13.127.46
111.206.208.163
111.206.208.164
111.206.208.166
111.206.208.36
111.206.208.37
111.206.208.38
111.206.208.61
111.206.208.62
111.206.211.129
111.206.211.130
111.206.211.131
111.206.211.145
111.206.211.146
111.206.211.147
111.206.211.148
115.182.200.50
115.182.200.51
115.182.200.52
115.182.200.53
115.182.200.54
115.182.63.51
115.182.63.93
117.185.116.152
118.244.244.124
122.72.82.31
123.125.89.101
123.125.89.102
123.125.89.103
123.125.89.157
123.125.89.159
123.125.89.6
123.126.32.134
123.126.99.39
123.126.99.57
123.59.122.104
123.59.122.75
123.59.122.76
123.59.122.77
14.152.77.22
14.152.77.25
14.152.77.26
14.152.77.32
14.18.245.250
140.207.69.99
163.177.90.61
180.153.225.136
182.16.230.98
182.254.11.174
182.254.116.117
182.254.34.151
182.254.4.234
183.192.192.139
183.232.119.198
183.232.126.23
183.232.229.21
183.232.229.22
183.232.229.25
183.232.229.32
203.205.151.23
210.129.145.150
211.151.157.15
211.151.158.155
211.151.50.10
220.181.153.113
220.181.154.137
220.181.185.150
220.249.243.70
223.167.82.139
36.110.222.105
36.110.222.119
36.110.222.146
36.110.222.156
59.37.96.220
61.135.196.99
103.7.30.79
EOF

logger -t "【fakeincn】" "国内IP规则设置完成"



ipset -! -N rtocn hash:net
ipset add rtocn 106.11.1.1/16

iptables -t nat -D PREROUTING -p tcp -m set --match-set rtocn dst -j REDIRECT --to-port 1008
iptables -t nat -D OUTPUT -p tcp -m set --match-set rtocn dst -j REDIRECT --to-port 1008
iptables -t nat -A PREROUTING -p tcp -m set --match-set rtocn dst -j REDIRECT --to-port 1008
iptables -t nat -A OUTPUT -p tcp -m set --match-set rtocn dst -j REDIRECT --to-port 1008
logger -t "【fakeincn】" "优酷IP规则设置完成"

cp -f /etc/storage/app_2.sh /etc/storage/dnsmasq/dnsmasq.d/r.tocn.conf
echo >> /etc/storage/dnsmasq/dnsmasq.d/r.tocn.conf
sed -Ei '/^$|api.ip.sb/d' /etc/storage/dnsmasq/dnsmasq.d/r.tocn.conf
	cat >> "/etc/storage/dnsmasq/dnsmasq.d/r.tocn.conf" <<-\_CONF
ipset=/api.ip.sb/tocn
_CONF

restart_dhcpd

fakeincn_get_status
eval "$scriptfilepath keep &"

}

initopt () {
optPath=`grep ' /opt ' /proc/mounts | grep tmpfs`
[ ! -z "$optPath" ] && return
if [ ! -z "$(echo $scriptfilepath | grep -v "/opt/etc/init")" ] && [ -s "/opt/etc/init.d/rc.func" ] ; then
	{ echo '#!/bin/sh' ; echo $scriptfilepath '"$@"' '&' ; } > /opt/etc/init.d/$scriptname && chmod 777  /opt/etc/init.d/$scriptname
fi

}

initconfig () {

# 说明和SS参数
if [ ! -f "/etc/storage/app_1.sh" ] || [ ! -s "/etc/storage/app_1.sh" ] ; then
	cat >> "/etc/storage/app_1.sh" <<-\EOF
#!/bin/sh
# FakeInChina(假装在中国) 
# 用途：与“由于版权限制，你所在的地区不能播放”告别，目前支持大多数主流的视音频app，包括：youku、iqiyi、qq（音乐、视频）、网易、乐视、CNTV等等，数量太多，不全部列出了。
# 这个功能模块需要使用国内SS服务器，其实最早让H大把ss-server集成到基础固件就是为了这一个模块，只是由于前一段时间基本上在国内，也就一直没有时间去调试这个模块，这段时间终于有时间和条件进行调试了。
# 模块运行时候，仅对检测服务器进行流量伪装（可能会包括部分网页文字以及图片），视音频码流依然直连线路，因此，对国内的SS服务器流量需求极低，一般普通家庭用的宽带便可以使用，在国内家人或者朋友的路由上运行SS-server，你在国外就可以正常使用。
# 毕竟大多数国内宽带IP是动态的，并且很多地区会限制时间自动断线，模块支持多台ss服务器备份，会自动检测可用的SS服务器，自动重连。
# 目前这个模块在我自己的路由上跑了将近2个月，没有遇到任何问题，各APP均使用正常。
# 由于各大公司检测IP的方法可能会变，某些规则会出现失效，某些服务商针对不同地区会用不同IP的服务器进行检测（例如youku，美国和德国地区用于地区检测的服务器就不同），所以我仅能保证我所居住的德国地区可以使用正常。
# 如果你所用的app出现了地区限制，可以发邮件给我：gaocuo@gmail.com。邮件内请说明你使用的app（无论如何请尽量使用最新版本的app，iOS系统是无法安装旧版本进行测试的）、你所在的国家、出现版权限制的视音频节目，我会尽量解决，但这不是保证。
# 如果是由于地区不同而导致检测服务器不同出现的地区限制，恕我无能为力。

# bigANDY  gaocuo@gmail.com
# 2018-01-16@DE
# Ver 0.2

# 配置文件包括以下几个：
# /etc/storage/script/Sh20_fakeincn.sh  ，启动脚本 和 用于初始化流量伪装表。
# /etc/storage/app_2.sh  这个文件复制到 /etc/storage/dnsmasq/dnsmasq.d/r.tocn.conf ，其中的 https://api.ip.sb/geoip 是用于检测地区的，你也可以在模块运行后浏览器访问 https://api.ip.sb/geoip 看看到底流量伪装是否成功。
# /etc/storage/app_1.sh  这个文件用于自动检测 ss 是否正常，自动切换ss 服务器。里面需要设置你自己的ss服务器参数，请保证各台ss-server 的端口、密码、加密方式的一致，我是个懒人，不想处理那么复杂的情况。

# ↓↓↓↓↓配置你自己的ss服务器参数↓↓↓↓↓
server1=xxx1.dynu.net
server2=xxx2.dynu.com
server3=xxx3.dynu.com
ss_router_port=1234   #服务器端口
ss_passwd=xxxxxxxxx   #密码
method=chacha20       #加密方式

index=1
ln -sf `which ss-redir` /opt/app/fakeincn/fakeincn
eval server="\$"server${index}
logger -t "【fakeincn】" "ChinaServer：$server。"
eval $(ps -w | grep '/opt/app/fakeincn/fakeincn' | grep -v grep | awk '{print "kill "$1";";}')
/opt/app/fakeincn/fakeincn -s $server -p $ss_router_port -l 1008 -b 0.0.0.0 -k $ss_passwd -m $method -u -f /tmp/tocn_ss.pid
let index+=1
sleep 15
fakeincn_enable=`nvram get app_7` #fakeincn_enable
while [ "$fakeincn_enable" = "1" ]; do
	curltest=`which curl`
	if [ -z "$curltest" ] || [ ! -s "`which curl`" ] ; then
		country=`wget -qO- https://api.ip.sb/geoip | sed 's/.*try_code":"\([A-Z]*\).*/\1/g'`
	else
		country=`curl -k -s https://api.ip.sb/geoip | sed 's/.*try_code":"\([A-Z]*\).*/\1/g'`
	fi
	if [ "$country" != "CN" ]; then
		logger -t "【fakeincn】" "ChinaServer不正确：$country，尝试下一个服务器：$server。"
		let index+=1
		eval server="\$"server${index}
		if [ -z "$server" ]; then
			index=0
			logger -t "FIC:" "ChinaServer run over. Sleep 60sec."
			sleep 60
		else
			eval $(ps -w | grep '/opt/app/fakeincn/fakeincn' | grep -v grep | awk '{print "kill "$1";";}')
			/opt/app/fakeincn/fakeincn -s $server -p $ss_router_port -l 1008 -b 0.0.0.0 -k $ss_passwd -m $method -u -f /tmp/tocn_ss.pid
			sleep 5
			NUM=`ps -w | grep "/opt/app/fakeincn/fakeincn" | grep -v grep |wc -l`
			if [ "$NUM" -lt "1" ] ; then
				logger -t "【fakeincn】" "fakeincn没启动$NUM，启动下个服务器：$index"
				fakeincn_enable=`nvram get app_7` #fakeincn_enable
				#跳出当前循环
				continue
			fi
		fi
	else
		logger -t "FIC" "Country Check: $country, next checkpoint: 120sec."
		sleep 120 #等120秒继续监测地区代码
	fi
fakeincn_enable=`nvram get app_7` #fakeincn_enable
done
fakeincn_v=2018-2-19

EOF
fi

# 伪装表
if [ ! -f "/etc/storage/app_2.sh" ] || [ ! -s "/etc/storage/app_2.sh" ] ; then
	cat >> "/etc/storage/app_2.sh" <<-\EOF
ipset=/3g.music.qq.com/tocn
ipset=/a.play.api.3g.youku.com/tocn
ipset=/ac.qq.com/tocn
ipset=/acc.music.qq.com/tocn
ipset=/access.tv.sohu.com/tocn
ipset=/aid.video.qq.com/tocn
ipset=/aidbak.video.qq.com/tocn
ipset=/antiserver.kuwo.cn/tocn
ipset=/api.3g.tudou.com/tocn
ipset=/api.3g.youku.com/tocn
ipset=/api.appsdk.soku.com/tocn
ipset=/api.itv.letv.com/tocn
ipset=/api.le.com/tocn
ipset=/api.letv.com/tocn
ipset=/api.live.letv.com/tocn
ipset=/api.mob.app.letv.com/tocn
ipset=/api.tv.itc.cn/tocn
ipset=/api.tv.sohu.com/tocn
ipset=/api.unipay.qq.com/tocn
ipset=/api.www.letv.com/tocn
ipset=/api.youku.com/tocn
ipset=/app.bilibili.com/tocn
ipset=/ark.letv.com/tocn
ipset=/bangumi.bilibili.com/tocn
ipset=/c.y.qq.com/tocn
ipset=/cache.m.iqiyi.com/tocn
ipset=/cache.video.iqiyi.com/tocn
ipset=/cache.video.qiyi.com/tocn
ipset=/cache.vip.iqiyi.com/tocn
ipset=/cache.vip.qiyi.com/tocn
ipset=/cctv1.vtime.cntv.cloudcdn.net/tocn
ipset=/cctv13.vtime.cntv.cloudcdn.net/tocn
ipset=/cctv5.vtime.cntv.cloudcdn.net/tocn
ipset=/cctv5plus.vtime.cntv.cloudcdn.net/tocn
ipset=/chrome.2345.com/tocn
ipset=/client.api.ttpod.com/tocn
ipset=/cloud.vip.xunlei.com/tocn
ipset=/cupid.iqiyi.com/tocn
ipset=/data.bilibili.com/tocn
ipset=/data.video.iqiyi.com/tocn
ipset=/data.video.qiyi.com/tocn
ipset=/dispatcher.video.sina.com.cn/tocn
ipset=/douban.fm/tocn
ipset=/dpool.sina.com.cn/tocn
ipset=/dyn.ugc.pps.tv/tocn
ipset=/dynamic.app.m.letv.com/tocn
ipset=/dynamic.cloud.vip.xunlei.com/tocn
ipset=/dynamic.live.app.m.letv.com/tocn
ipset=/dynamic.meizi.app.m.letv.com/tocn
ipset=/dynamic.search.app.m.letv.com/tocn
ipset=/epg.api.pptv.com/tocn
ipset=/geo.js.kankan.com/tocn
ipset=/hot.vrs.letv.com/tocn
ipset=/hot.vrs.sohu.com/tocn
ipset=/i-play.mobile.youku.com/tocn
ipset=/i.play.api.3g.youku.com/tocn
ipset=/i.y.qq.com/tocn
ipset=/iface.iqiyi.com/tocn
ipset=/iface2.iqiyi.com/tocn
ipset=/info.zb.qq.com/tocn
ipset=/info.zb.video.qq.com/tocn
ipset=/inner.kandian.com/tocn
ipset=/interface.bilibili.com/tocn
ipset=/internal.check.duokanbox.com/tocn
ipset=/ip.apps.cntv.cn/tocn
ipset=/ip.kankan.com/tocn
ipset=/ip.kugou.com/tocn
ipset=/ip2.kugou.com/tocn
ipset=/ipcheck.kuwo.cn/tocn
ipset=/iplocation.geo.iqiyi.com/tocn
ipset=/iplocation.geo.qiyi.com/tocn
ipset=/ipservice.163.com/tocn
ipset=/kandian.com/tocn
ipset=/letv.cn/tocn
ipset=/letv.com/tocn
ipset=/list.youku.com/tocn
ipset=/listso.m.areainfo.ppstream.com/tocn
ipset=/live.api.hunantv.com/tocn
ipset=/live.g3proxy.lecloud.com/tocn
ipset=/live.gslb.letv.com/tocn
ipset=/live.pptv.com/tocn
ipset=/live.tv.sohu.com/tocn
ipset=/lixian.vip.xunlei.com/tocn
ipset=/lixian.xunlei.com/tocn
ipset=/m.letv.com/tocn
ipset=/m10.music.126.net/tocn
ipset=/mobi.kuwo.cn/tocn
ipset=/mobile.api.hunantv.com/tocn
ipset=/mobilefeedback.kugou.com/tocn
ipset=/mqqplayer.3g.qq.com/tocn
ipset=/music.163.com/tocn
ipset=/music.baidu.com/tocn
ipset=/music.sina.com.cn/tocn
ipset=/my.tv.sohu.com/tocn
ipset=/nmobi.kuwo.cn/tocn
ipset=/openapi.youku.com/tocn
ipset=/pad.tv.sohu.com/tocn
ipset=/pay.tudou.com/tocn
ipset=/pay.video.qq.com/tocn
ipset=/pay.youku.com/tocn
ipset=/paybak.video.qq.com/tocn
ipset=/pcweb.api.mgtv.com/tocn
ipset=/pl-ali.youku.com/tocn
ipset=/play-ali.youku.com/tocn
ipset=/play-dxk.youku.com/tocn
ipset=/play.api.3g.tudou.com/tocn
ipset=/play.api.3g.youku.com/tocn
ipset=/play.api.pptv.com/tocn
ipset=/play.baidu.com/tocn
ipset=/play.youku.com/tocn
ipset=/player-pc.le.com/tocn
ipset=/player.pc.le.com/tocn
ipset=/proxy.music.qq.com/tocn
ipset=/proxymc.qq.com/tocn
ipset=/qzs.qq.com/tocn
ipset=/s.plcloud.music.qq.com/tocn
ipset=/search.api.3g.tudou.com/tocn
ipset=/search.api.3g.youku.com/tocn
ipset=/search.lekan.letv.com/tocn
ipset=/serviceinfo.sdk.duomi.com/tocn
ipset=/sns.video.qq.com/tocn
ipset=/so.open.163.com/tocn
ipset=/spark.api.xiami.com/tocn
ipset=/sports1pull.live.wscdns.com/tocn
ipset=/ssports.com/tocn
ipset=/ssports.smgbb.cn/tocn
ipset=/st.live.letv.com/tocn
ipset=/static.api.sports.letv.com/tocn
ipset=/static.itv.letv.com/tocn
ipset=/tingapi.ting.baidu.com/tocn
ipset=/tms.is.ysten.com/tocn
ipset=/tools.aplusapi.pptv.com/tocn
ipset=/tv.api.3g.tudou.com/tocn
ipset=/tv.api.3g.youku.com/tocn
ipset=/tv.weibo.com/tocn
ipset=/ups.youku.com/tocn
ipset=/v.api.hunantv.com/tocn
ipset=/v.api.mgtv.com/tocn
ipset=/v.iask.com/tocn
ipset=/v.pps.tv/tocn
ipset=/v.youku.com/tocn
ipset=/v5.pc.duomi.com/tocn
ipset=/vdn.apps.cntv.cn/tocn
ipset=/vdn.live.cntv.cn/tocn
ipset=/video.qq.com/tocn
ipset=/video.sina.com.cn/tocn
ipset=/video.tudou.com/tocn
ipset=/vip.sports.cntv.cn/tocn
ipset=/vxml.56.com/tocn
ipset=/web-play.pplive.cn/tocn
ipset=/web-play.pptv.com/tocn
ipset=/wtv.v.iask.com/tocn
ipset=/www.bilibili.com/tocn
ipset=/www.iqiyi.com/tocn
ipset=/www.kugou.com/tocn
ipset=/www.kuwo.cn/tocn
ipset=/www.qie.tv/tocn
ipset=/www.soku.com/tocn
ipset=/www.tudou.com/tocn
ipset=/www.xiami.com/tocn
ipset=/www.yinyuetai.com/tocn
ipset=/www.youku.com/tocn
ipset=/zb.s.qq.com/tocn
ipset=/ipip.net/tocn
ipset=/ipinfo.io/tocn
ipset=/ifconfig.co/tocn

EOF
fi

chmod 777 /etc/storage/app_1.sh /etc/storage/app_2.sh

}

initconfig

update_app () {
if [ "$1" = "del" ] ; then
	rm -rf /etc/storage/app_1.sh /etc/storage/app_2.sh /opt/app/fakeincn/Advanced_Extensions_fakeincn.asp
fi

initconfig

mkdir -p /opt/app/fakeincn
# 加载程序配置页面
if [ ! -f "/opt/app/fakeincn/Advanced_Extensions_fakeincn.asp" ] || [ ! -s "/opt/app/fakeincn/Advanced_Extensions_fakeincn.asp" ] ; then
	wgetcurl.sh /opt/app/fakeincn/Advanced_Extensions_fakeincn.asp "$hiboyfile/Advanced_Extensions_fakeincnasp" "$hiboyfile2/Advanced_Extensions_fakeincnasp"
fi
umount /www/Advanced_Extensions_app02.asp
mount --bind /opt/app/fakeincn/Advanced_Extensions_fakeincn.asp /www/Advanced_Extensions_app02.asp
# 更新程序启动脚本
[ "$1" = "del" ] && rm -rf /etc/storage/app_2.sh
[ "$1" = "del" ] && /etc/storage/www_sh/假装在中国 del &
}

case $ACTION in
start)
	fakeincn_close
	fakeincn_check
	;;
check)
	fakeincn_check
	;;
stop)
	fakeincn_close
	;;
keep)
	#fakeincn_check
	fakeincn_keep
	;;
updateapp2)
	fakeincn_restart o
	[ "$fakeincn_enable" = "1" ] && nvram set fakeincn_status="updatefakeincn" && logger -t "【fakeincn】" "重启" && fakeincn_restart
	[ "$fakeincn_enable" != "1" ] && nvram set fakeincn_v="" && logger -t "【fakeincn】" "更新" && update_app del
	;;
update_app)
	update_app
	;;
*)
	fakeincn_check
	;;
esac

