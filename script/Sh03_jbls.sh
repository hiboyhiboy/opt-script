#!/bin/sh
#copyright by hiboy
source /etc/storage/script/init.sh
jbls_enable=`nvram get jbls_enable`
[ -z $jbls_enable ] && jbls_enable=0 && nvram set jbls_enable=0
#[ "$jbls_enable" != "0" ] && nvramshow=`nvram showall | grep '=' | grep jbls | awk '{print gensub(/'"'"'/,"'"'"'\"'"'"'\"'"'"'","g",$0);}'| awk '{print gensub(/=/,"='\''",1,$0)"'\'';";}'` && eval $nvramshow

if [ ! -z "$(echo $scriptfilepath | grep -v "/tmp/script/" | grep jbls)" ]  && [ ! -s /tmp/script/_jbls ]; then
	mkdir -p /tmp/script
	{ echo '#!/bin/sh' ; echo $scriptfilepath '"$@"' '&' ; } > /tmp/script/_jbls
	chmod 777 /tmp/script/_jbls
fi

jbls_check () {
if [ "$jbls_enable" != "1" ] ; then
	[ ! -z "`pidof jblicsvr`" ] && logger -t "【jbls】" "停止 jblicsvr" && jbls_close
	{ kill_ps "$scriptname" exit0; exit 0; }
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
kill_ps "/tmp/script/_jbls"
kill_ps "_jbls.sh"
kill_ps "$scriptname"
}

jbls_start () {
#jblicsvr -d -p 1027
/etc/storage/jbls_script.sh
sleep 2
[ ! -z "$(ps -w | grep "jblicsvr" | grep -v grep )" ] && logger -t "【jbls】" "启动成功"
[ -z "$(ps -w | grep "jblicsvr" | grep -v grep )" ] && logger -t "【jbls】" "启动失败, 注意检查端口是否有冲突,10 秒后自动尝试重新启动" && sleep 10 && { eval "$scriptfilepath &"; exit 0; }
eval "$scriptfilepath keep &"
}

initconfig () {

jbls_script="/etc/storage/jbls_script.sh"
if [ ! -f "$jbls_script" ] || [ ! -s "$jbls_script" ] ; then
	cat > "$jbls_script" <<-\EEE
#!/bin/sh
export PATH='/etc/storage/bin:/tmp/script:/etc/storage/script:/opt/usr/sbin:/opt/usr/bin:/opt/sbin:/opt/bin:/usr/local/sbin:/usr/sbin:/usr/bin:/sbin:/bin'
export LD_LIBRARY_PATH=/lib:/opt/lib

# 感谢bigandy编译和提供： http://www.right.com.cn/forum/forum.php?mod=viewthread&tid=161324&page=672#pid1640158
# jetbrains license server 。
# 进展： Deamon 开发完成，通过了 IDEA， CLION 的验证测试。
# 特点：纯C编写，编译后仅16K大小，不给路由存储增加压力，独立http 服务。
# 适用情况：理论上适用于所有 Jetbrains 产品，但未完全测试。使用环境：padavan 路由hiboay固件，其他固件运行情况未知。

# 使用方法：

# Jetbrains License Server Emulator build Jan 13 2017 13:04:12  

# usage: jblicsvr [option]
# option:  
  
#  -d             run on daemon mode  
#  -p <port>      port to listen  
#  -s <seconds>   seconds of prolongation period  
#  -u <name>      license to user name  

#  -d 进入守护进程模式  
#  -p httpd侦听端口，默认 1027 ，原作者女友生日  
#  -s license 有效时间（单位：秒），默认约为7天多（607875500），原厂server传递的数值。  
#  -u 授权给谁，默认为ilanyu（原作者）。  
# 彩蛋：http://my.router:1027/version
# http://ip:port/version

# 在线激活方式:注册界面选择授权服务器(license server)，点击多几次“Discover server”（自动发现配置），然后点击“OK” 。
# 或手动填写 http://my.router:1027 或 http://路由ip:1027 ，然后点击“OK” 

sed -Ei '/txt-record=_jetbrains-license-server.lan/d' /etc/storage/dnsmasq/dnsmasq.conf
nvram set lan_domain="lan"
lan_ipaddr=`nvram get lan_ipaddr`
echo "txt-record=_jetbrains-license-server.lan,url=http://$lan_ipaddr:1027" >> /etc/storage/dnsmasq/dnsmasq.conf
killall jblicsvr
jblicsvr -d -p 1027
restart_dhcpd

EEE
	chmod 755 "$jbls_script"
fi

}

initconfig

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
	#jbls_check
	jbls_keep
	;;
*)
	jbls_check
	;;
esac

