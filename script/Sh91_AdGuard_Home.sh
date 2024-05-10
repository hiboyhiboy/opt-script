#!/bin/bash
#copyright by hiboy
source /etc/storage/script/init.sh
AdGuardHome_enable=`nvram get app_84`
[ -z $AdGuardHome_enable ] && AdGuardHome_enable=0 && nvram set app_84=0
AdGuardHome_dns=`nvram get app_132`
[ -z $AdGuardHome_dns ] && AdGuardHome_dns=0 && nvram set app_132=0
AdGuardHome_2_server=`nvram get app_85`
if [ "$AdGuardHome_dns" = "1" ] ; then
	AdGuardHome_server='server=127.0.0.1#53'
else
	AdGuardHome_server='server=127.0.0.1#5353'
	[ ! -z "$AdGuardHome_2_server" ] && AdGuardHome_server="server=$(echo $AdGuardHome_2_server | sed 's@:\|：@#@g')"
fi
if [ "$AdGuardHome_enable" != "0" ] ; then

AdGuardHome_renum=`nvram get AdGuardHome_renum`
cmd_log_enable=`nvram get cmd_log_enable`
cmd_name="AdGuardHome"
cmd_log=""
if [ "$cmd_log_enable" = "1" ] || [ "$AdGuardHome_renum" -gt "0" ] ; then
	cmd_log="$cmd_log2"
fi

fi

if [ ! -z "$(echo $scriptfilepath | grep -v "/tmp/script/" | grep AdGuard_Home)" ] && [ ! -s /tmp/script/_app17 ] ; then
	mkdir -p /tmp/script
	{ echo '#!/bin/bash' ; echo $scriptfilepath '"$@"' '&' ; } > /tmp/script/_app17
	chmod 777 /tmp/script/_app17
fi

AdGuardHome_restart () {
i_app_restart "$@" -name="AdGuardHome"
}

AdGuardHome_get_status () {

B_restart="$AdGuardHome_enable$AdGuardHome_dns$AdGuardHome_2_server"
[ "$(nvram get app_86)" = "1" ] && B_restart="$B_restart""$(cat /etc/storage/app_19.sh | grep -v '^#' | grep -v '^$')"
[ "$(nvram get app_86)" = "1" ] && nvram set app_86=0

i_app_get_status -name="AdGuardHome" -valb="$B_restart"
}

AdGuardHome_check () {
AdGuardHome_get_status
if [ "$AdGuardHome_enable" != "1" ] && [ "$needed_restart" = "1" ] ; then
	[ ! -z "$(ps -w | grep "AdGuardHome" | grep -v grep )" ] && logger -t "【AdGuardHome】" "停止 AdGuardHome" && AdGuardHome_close
	{ kill_ps "$scriptname" exit0; exit 0; }
fi
if [ "$AdGuardHome_enable" = "1" ] ; then
	if [ "$needed_restart" = "1" ] ; then
		AdGuardHome_close
		AdGuardHome_start
	else
		AdGuardHome_set_dnsmasq
	fi
fi
}

AdGuardHome_set_dnsmasq () {

if [ "$AdGuardHome_dns" = "1" ] ; then
	[ -z "$(ps -w | grep "AdGuardHome" | grep -v grep )" ] && AdGuardHome_restart
	if [ "$(grep "port=12353"  /etc/storage/dnsmasq/dnsmasq.conf | wc -l)" = 0 ] ; then
		sleep 5
		if [ "$(grep "port=12353"  /etc/storage/dnsmasq/dnsmasq.conf | wc -l)" = 0 ] ; then
			logger -t "【AdGuardHome】" "变更 dnsmasq 侦听端口规则 port=12353"
			sed -Ei '/AdGuardHome/d' /etc/storage/dnsmasq/dnsmasq.conf
			echo "port=12353 #AdGuardHome" >> /etc/storage/dnsmasq/dnsmasq.conf
			sed ":a;N;s/\n\n\n/\n\n/g;ba" -i  /etc/storage/dnsmasq/dnsmasq.conf
			restart_on_dhcpd
		fi
	fi
fi
if [ "$AdGuardHome_dns" = "0" ] ; then
	[ -z "$AdGuardHome_2_server" ] && [ -z "$(ps -w | grep "AdGuardHome" | grep -v grep )" ] && AdGuardHome_restart
	port=$(grep "server=127.0.0.1#8053"  /etc/storage/dnsmasq/dnsmasq.conf | wc -l)
	port2=$(grep "server=127.0.0.1#8953"  /etc/storage/dnsmasq/dnsmasq.conf | wc -l)
	if [ ! -z "$(ps -w | grep "AdGuardHome" | grep -v grep )" ] ; then
	if [ "$port" = 1 ] ; then
		[ -z "$(yq r $app_19 dns.upstream_dns | grep 127.0.0.1:8053)" ] && AdGuardHome_restart
	fi
	if [ "$port2" = 1 ] ; then
		[ -z "$(yq r $app_19 dns.upstream_dns | grep 127.0.0.1:8953)" ] && AdGuardHome_restart
	fi
	if [ "$port" == 0 ] && [ "$port2" == 0 ] ; then
		[ ! -z "$(yq r $app_19 dns.upstream_dns | grep 127.0.0.1:8053)" ] || [ ! -z "$(yq r $app_19 dns.upstream_dns | grep 127.0.0.1:8953)" ] && AdGuardHome_restart
	fi
	fi
	port3=$(grep "$AdGuardHome_server"  /etc/storage/dnsmasq/dnsmasq.conf | wc -l)
	if [ "$port3" = 0 ] ; then
		sleep 5
		port3=$(grep "$AdGuardHome_server"  /etc/storage/dnsmasq/dnsmasq.conf | wc -l)
		if [ "$port3" = 0 ] ; then
		if [ "$port" != 0 ] ; then
			logger -t "【AdGuardHome】" "检测到 dnsmasq 转发规则, 删除 server=127.0.0.1#8053"
			sed -Ei '/server=/d' /etc/storage/dnsmasq/dnsmasq.conf
			echo '#server=127.0.0.1#8053' >> /etc/storage/dnsmasq/dnsmasq.conf
		fi
		if [ "$port2" != 0 ] ; then
			logger -t "【AdGuardHome】" "检测到 dnsmasq 转发规则, 删除 server=127.0.0.1#8953"
			sed -Ei '/server=/d' /etc/storage/dnsmasq/dnsmasq.conf
			echo '#server=127.0.0.1#8953' >> /etc/storage/dnsmasq/dnsmasq.conf
		fi
		logger -t "【AdGuardHome】" "添加 AdGuardHome 的 dnsmasq 转发规则 $AdGuardHome_server"
		# 写入dnsmasq配置
		sed -Ei '/no-resolv|^server=|dns-forward-max=1000|min-cache-ttl=1800|domain-needed|AdGuardHome/d' /etc/storage/dnsmasq/dnsmasq.conf
		cat >> "/etc/storage/dnsmasq/dnsmasq.conf" <<-EOF
no-resolv #AdGuardHome
$AdGuardHome_server #AdGuardHome
dns-forward-max=1000 #AdGuardHome
EOF
		sed ":a;N;s/\n\n\n/\n\n/g;ba" -i  /etc/storage/dnsmasq/dnsmasq.conf
		restart_on_dhcpd
		fi
	fi
fi

}

AdGuardHome_keep () {
i_app_keep -name="AdGuardHome" -pidof="AdGuardHome" -cpath="/opt/AdGuardHome/AdGuardHome" &
while true; do
[ "$(grep "</textarea>"  /etc/storage/app_19.sh | wc -l)" != 0 ] && sed -Ei s@\<\/textarea\>@@g /etc/storage/app_19.sh
sleep 61
AdGuardHome_set_dnsmasq
done
}

AdGuardHome_close () {
kill_ps "$scriptname keep"
sed -Ei '/【AdGuardHome】|^$/d' /tmp/script/_opt_script_check
sed -Ei '/AdGuardHome/d' /etc/storage/dnsmasq/dnsmasq.conf
port2=$(grep "#server=127.0.0.1#8053"  /etc/storage/dnsmasq/dnsmasq.conf | wc -l)
if [ "$port2" != 0 ] ; then
	sed -Ei '/server=127.0.0.1#8053/d' /etc/storage/dnsmasq/dnsmasq.conf
	echo 'server=127.0.0.1#8053' >> /etc/storage/dnsmasq/dnsmasq.conf
	logger -t "【AdGuardHome】" "检测到 dnsmasq 转发规则, 恢复 server=127.0.0.1#8053"
fi
port2=$(grep "#server=127.0.0.1#8953"  /etc/storage/dnsmasq/dnsmasq.conf | wc -l)
if [ "$port2" != 0 ] ; then
	sed -Ei '/server=127.0.0.1#8953/d' /etc/storage/dnsmasq/dnsmasq.conf
	echo 'server=127.0.0.1#8953' >> /etc/storage/dnsmasq/dnsmasq.conf
	logger -t "【AdGuardHome】" "检测到 dnsmasq 转发规则, 恢复 server=127.0.0.1#8953"
fi
sed ":a;N;s/\n\n\n/\n\n/g;ba" -i  /etc/storage/dnsmasq/dnsmasq.conf
restart_on_dhcpd
killall AdGuardHome
kill_ps "/tmp/script/_app17"
kill_ps "_AdGuard_Home.sh"
kill_ps "$scriptname"
}

AdGuardHome_start () {
check_webui_yes
port=$(grep "server=127.0.0.1#8053"  /etc/storage/dnsmasq/dnsmasq.conf | wc -l)
if [ ! -z "$AdGuardHome_2_server" ] && [ "$AdGuardHome_dns" = "0" ] ; then
	logger -t "【AdGuardHome】" "使用外置 AdGuardHome 服务器： $AdGuardHome_2_server"
	logger -t "【AdGuardHome】" "建议外置 AdGuardHome 服务器的上游 DNS 是无污染的"
	AdGuardHome_set_dnsmasq
else
	SVC_PATH="/opt/AdGuardHome/AdGuardHome"
	if [ ! -s "$SVC_PATH" ] ; then
		logger -t "【AdGuardHome】" "找不到 $SVC_PATH，安装 opt 程序"
		/etc/storage/script/Sh01_mountopt.sh start
		initopt
	fi
	mkdir -p "/opt/AdGuardHome"
	if [ ! -s "$SVC_PATH" ] && [ -d "/opt/AdGuardHome" ] ; then
		logger -t "【AdGuardHome】" "找不到 $SVC_PATH ，安装 AdGuardHome 程序"
		optPath="`grep ' /opt ' /proc/mounts | grep tmpfs`"
		Available_A=$(df -m | grep "% /opt" | awk 'NR==1' | awk -F' ' '{print $4}')
		size_tmpfs=`nvram get size_tmpfs`
		if [ ! -z "$optPath" ] && [ "$size_tmpfs" = "0" ] && [[ "$Available_A" -lt 40 ]] ; then
			mount -o remount,size=90% tmpfs /tmp
			Available_B=$(df -m | grep "% /opt" | awk 'NR==1' | awk -F' ' '{print $4}')
			logger -t "【AdGuardHome】" "调整 /tmp 挂载分区的大小， /opt 可用空间： $Available_A → $Available_B M"
		fi
		curltest=`which curl`
		if [ -z "$curltest" ] || [ ! -s "`which curl`" ] ; then
			tag="$( wget -T 5 -t 3 --user-agent "$user_agent" --max-redirect=0 --output-document=-  https://api.github.com/repos/AdguardTeam/AdGuardHome/releases/latest  2>&1 | grep 'tag_name' | cut -d\" -f4 )"
			[ -z "$tag" ] && tag="$( wget -T 5 -t 3 --user-agent "$user_agent" --quiet --output-document=-  https://api.github.com/repos/AdguardTeam/AdGuardHome/releases/latest  2>&1 | grep 'tag_name' | cut -d\" -f4 )"
		else
			tag="$( curl --connect-timeout 3 --user-agent "$user_agent"  https://api.github.com/repos/AdguardTeam/AdGuardHome/releases/latest  2>&1 | grep 'tag_name' | cut -d\" -f4 )"
			[ -z "$tag" ] && tag="$( curl -L --connect-timeout 3 --user-agent "$user_agent" -s  https://api.github.com/repos/AdguardTeam/AdGuardHome/releases/latest  2>&1 | grep 'tag_name' | cut -d\" -f4 )"
		fi
		if [ ! -z "$tag" ] ; then
			logger -t "【AdGuardHome】" "自动下载最新版本 $tag"
			wgetcurl.sh "/opt/AdGuardHome/AdGuardHome.tar.gz" "https://github.com/AdguardTeam/AdGuardHome/releases/download/$tag/AdGuardHome_linux_mipsle_softfloat.tar.gz"
			tar -xzvf /opt/AdGuardHome/AdGuardHome.tar.gz -C /opt
		fi
		if [ ! -s "$SVC_PATH" ] && [ -d "/opt/AdGuardHome" ] ; then
			static_adguard="https://static.adtidy.org/adguardhome/beta/AdGuardHome_linux_mipsle_softfloat.tar.gz"
			logger -t "【AdGuardHome】" "开始下载 $static_adguard"
			wgetcurl.sh "/opt/AdGuardHome/AdGuardHome.tar.gz" "$static_adguard"
			tar -xzvf /opt/AdGuardHome/AdGuardHome.tar.gz -C /opt ; cd /opt/AdGuardHome
		fi
		if [ ! -s "$SVC_PATH" ] && [ -d "/opt/AdGuardHome" ] ; then
			logger -t "【AdGuardHome】" "最新版本获取失败！！！"
			logger -t "【AdGuardHome】" "开始下载 $hiboyfile2/AdGuardHome_linux_mipsle_softfloat.tar.gz"
			wgetcurl.sh "/opt/AdGuardHome/AdGuardHome.tar.gz" "$hiboyfile/AdGuardHome_linux_mipsle_softfloat.tar.gz" "$hiboyfile2/AdGuardHome_linux_mipsle_softfloat.tar.gz"
			tar -xzvf /opt/AdGuardHome/AdGuardHome.tar.gz -C /opt ; cd /opt/AdGuardHome
		fi
		cd /opt/AdGuardHome ; rm -f ./AdGuardHome.tar.gz ./LICENSE.txt./README.md ./CHANGELOG.md ./AdGuardHome.sig
	fi
	chmod 777 "$SVC_PATH"
	# 更新 yq
	[ -z "$(yq -V 2>&1 | grep 3\.4\.1)" ] && rm -rf /opt/bin/yq /opt/opt_backup/bin/yq
	i_app_get_cmd_file -name="AdGuardHome" -cmd="yq" -cpath="/opt/bin/yq" -down1="$hiboyfile/yq" -down2="$hiboyfile2/yq"
	app_19="/etc/storage/app_19.sh"
	# 检测配置，若错误则恢复默认
	AdGuardHome_check=$($SVC_PATH -c $app_19 -w /opt/AdGuardHome --check-config --verbose 2>&1 | grep fatal)
	if [ ! -z "$AdGuardHome_check" ] ; then
		eval "$SVC_PATH -c $app_19 -w /opt/AdGuardHome --check-config --verbose $cmd_log2"
		logger -t "【AdGuardHome】" "检测配置，配置出现错误，现在恢复默认配置"
		logger -t "【AdGuardHome】" "旧配置备份为： /etc/storage/app_19.old"
		cp -f "$app_19" /etc/storage/app_19.old
		rm -f "$app_19"
		logger -t "【AdGuardHome】" "恢复默认配置"
		initconfig
		users_name="$(yq r /etc/storage/app_19.old users[0].name)"
		users_password="$(yq r /etc/storage/app_19.old users[0].password)"
		if [ ! -z "$users_name" ] && [ ! -z "$users_password" ] ; then
			logger -t "【AdGuardHome】" "从旧配置备恢复 登录账号 $users_name 和 password"
			yq d -i "$app_19" "auth_name"
			yq d -i "$app_19" "auth_pass"
			yq w -i "$app_19" "users[0].name" "$users_name"
			yq w -i "$app_19" "users[0].password" "$users_password"
		fi
	fi
	# 获取版本
	AdGuardHome_v=$($SVC_PATH -c $app_19 -w /opt/AdGuardHome --check-config --verbose 2>&1 | grep version | sed -n '1p' | awk -F 'version' '{print $2;}')
	nvram set AdGuardHome_v="$(echo $AdGuardHome_v)"
	[ -z "$AdGuardHome_v" ] && { eval "$SVC_PATH -c $app_19 -w /opt/AdGuardHome --check-config --verbose $cmd_log2" ; rm -rf $SVC_PATH ; }
	if [ ! -s "$SVC_PATH" ] ; then
		logger -t "【AdGuardHome】" "找不到 $SVC_PATH ，需要手动安装 $SVC_PATH"
		logger -t "【AdGuardHome】" "启动失败, 10 秒后自动尝试重新启动" && sleep 10 && AdGuardHome_restart x
	fi
	# 不使用本路由系统提供的主机。
	yq w -i "$app_19" clients.runtime_sources.hosts false
	logger -t "【AdGuardHome】" "启用本机 AdGuardHome 服务"
	# 生成配置文件
	if [ "$AdGuardHome_dns" = "1" ] ; then
		logger -t "【AdGuardHome】" "代替 dnsmasq 侦听 53 端口"
		yq w -i "$app_19" dns.port 53
		logger -t "【AdGuardHome】" "修改本机 AdGuardHome 服务器的上游 DNS: 127.0.0.1:12353"
		#yq w -i "$app_19" dns.upstream_dns "[]"
		[ ! -z "$(yq r $app_19 dns.upstream_dns | grep tcp://1.0.0.1)" ] && yq d -i "$app_19" "dns.upstream_dns(.==tcp://1.0.0.1)"
		[ ! -z "$(yq r $app_19 dns.upstream_dns | grep 1.0.0.1)" ] && yq d -i "$app_19" "dns.upstream_dns(.==1.0.0.1)"
		[ ! -z "$(yq r $app_19 dns.upstream_dns | grep 127.0.0.1:8053)" ] && yq d -i "$app_19" "dns.upstream_dns(.==127.0.0.1:8053)"
		[ ! -z "$(yq r $app_19 dns.upstream_dns | grep 127.0.0.1:8953)" ] && yq d -i "$app_19" "dns.upstream_dns(.==127.0.0.1:8953)"
		[ -z "$(yq r $app_19 dns.upstream_dns | grep 127.0.0.1:12353)" ] && yq w -i "$app_19" dns.upstream_dns[+] "127.0.0.1:12353"
	else
		port=$(grep "server=127.0.0.1#8053"  /etc/storage/dnsmasq/dnsmasq.conf | wc -l)
		if [ "$port" != 0 ] ; then
			logger -t "【AdGuardHome】" "修改本机 AdGuardHome 服务器的上游 DNS: 127.0.0.1:8053"
			#yq w -i "$app_19" dns.upstream_dns "[]"
			[ ! -z "$(yq r $app_19 dns.upstream_dns | grep tcp://1.0.0.1)" ] && yq d -i "$app_19" "dns.upstream_dns(.==tcp://1.0.0.1)"
			[ ! -z "$(yq r $app_19 dns.upstream_dns | grep 1.0.0.1)" ] && yq d -i "$app_19" "dns.upstream_dns(.==1.0.0.1)"
			[ ! -z "$(yq r $app_19 dns.upstream_dns | grep 127.0.0.1:12353)" ] && yq d -i "$app_19" "dns.upstream_dns(.==127.0.0.1:12353)"
			[ -z "$(yq r $app_19 dns.upstream_dns | grep 127.0.0.1:8053)" ] && yq w -i "$app_19" dns.upstream_dns[+] "127.0.0.1:8053"
			[ ! -z "$(yq r $app_19 dns.upstream_dns | grep 127.0.0.1:8953)" ] && yq d -i "$app_19" "dns.upstream_dns(.==127.0.0.1:8953)"
		fi
		port2=$(grep "server=127.0.0.1#8953"  /etc/storage/dnsmasq/dnsmasq.conf | wc -l)
		if [ "$port2" != 0 ] ; then
			logger -t "【AdGuardHome】" "修改本机 AdGuardHome 服务器的上游 DNS: 127.0.0.1:8953"
			#yq w -i "$app_19" dns.upstream_dns "[]"
			[ ! -z "$(yq r $app_19 dns.upstream_dns | grep tcp://1.0.0.1)" ] && yq d -i "$app_19" "dns.upstream_dns(.==tcp://1.0.0.1)"
			[ ! -z "$(yq r $app_19 dns.upstream_dns | grep 1.0.0.1)" ] && yq d -i "$app_19" "dns.upstream_dns(.==1.0.0.1)"
			[ ! -z "$(yq r $app_19 dns.upstream_dns | grep 127.0.0.1:12353)" ] && yq d -i "$app_19" "dns.upstream_dns(.==127.0.0.1:12353)"
			[ ! -z "$(yq r $app_19 dns.upstream_dns | grep 127.0.0.1:8053)" ] && yq d -i "$app_19" "dns.upstream_dns(.==127.0.0.1:8053)"
			[ -z "$(yq r $app_19 dns.upstream_dns | grep 127.0.0.1:8953)" ] && yq w -i "$app_19" dns.upstream_dns[+] "127.0.0.1:8953"
		fi
		if [ "$port" == 0 ] && [ "$port2" == 0 ] ; then
			[ ! -z "$(yq r $app_19 dns.upstream_dns | grep 127.0.0.1:8053)" ] && yq d -i "$app_19" "dns.upstream_dns(.==127.0.0.1:8053)"
			[ ! -z "$(yq r $app_19 dns.upstream_dns | grep 127.0.0.1:8953)" ] && yq d -i "$app_19" "dns.upstream_dns(.==127.0.0.1:8953)"
			[ ! -z "$(yq r $app_19 dns.upstream_dns | grep 127.0.0.1:12353)" ] && yq d -i "$app_19" "dns.upstream_dns(.==127.0.0.1:12353)"
			[ "$(yq r $app_19 dns.upstream_dns)" == '[]' ] && yq w -i "$app_19" dns.upstream_dns[+] "tcp://1.0.0.1"
		fi
		yq w -i "$app_19" dns.port 5353
	fi
	if [ "$AdGuardHome_dns" = "1" ] ; then
		if [ "$(grep "port=12353"  /etc/storage/dnsmasq/dnsmasq.conf | wc -l)" = 0 ] ; then
			logger -t "【AdGuardHome】" "变更 dnsmasq 侦听端口规则 port=12353"
			sed -Ei '/AdGuardHome/d' /etc/storage/dnsmasq/dnsmasq.conf
			echo "port=12353 #AdGuardHome" >> /etc/storage/dnsmasq/dnsmasq.conf
			sed ":a;N;s/\n\n\n/\n\n/g;ba" -i  /etc/storage/dnsmasq/dnsmasq.conf
			restart_on_dhcpd
			sleep 1
		fi
	fi
	logger -t "【AdGuardHome】" "运行 /opt/AdGuardHome/AdGuardHome"
	cd /opt/AdGuardHome
	eval "/opt/AdGuardHome/AdGuardHome -c /etc/storage/app_19.sh -w /opt/AdGuardHome $cmd_log" &
	sleep 4
	AdGuardHome_set_dnsmasq
	i_app_keep -t -name="AdGuardHome" -pidof="AdGuardHome" -cpath="/opt/AdGuardHome/AdGuardHome"
	restart_on_dhcpd
	AdGuardHome_get_status
	eval "$scriptfilepath keep &"
fi
sleep 5
exit 0
}

initconfig () {

app_19="/etc/storage/app_19.sh"
if [ ! -f "$app_19" ] || [ ! -s "$app_19" ] ; then
	cat > "$app_19" <<-\EEE
http:
  address: 0.0.0.0:3000
auth_name: admin
auth_pass: admin
language: zh-cn
dns:
  bind_host: 0.0.0.0
  port: 5353
  ratelimit: 0
  upstream_dns:
  - tcp://1.0.0.1
  bootstrap_dns: tcp://1.0.0.1
  all_servers: true
tls:
  enabled: false

EEE
	chmod 755 "$app_19"
fi

}

initconfig

update_app () {
mkdir -p /opt/app/AdGuardHome
if [ "$1" = "update_asp" ] ; then
	rm -rf /opt/app/AdGuardHome/Advanced_Extensions_AdGuardHome.asp
fi
if [ "$1" = "del" ] ; then
	rm -rf /opt/app/AdGuardHome/Advanced_Extensions_AdGuardHome.asp /opt/AdGuardHome/AdGuardHome
fi

initconfig

# 加载程序配置页面
if [ ! -f "/opt/app/AdGuardHome/Advanced_Extensions_AdGuardHome.asp" ] || [ ! -s "/opt/app/AdGuardHome/Advanced_Extensions_AdGuardHome.asp" ] ; then
	wgetcurl.sh /opt/app/AdGuardHome/Advanced_Extensions_AdGuardHome.asp "$hiboyfile/Advanced_Extensions_AdGuardHomeasp" "$hiboyfile2/Advanced_Extensions_AdGuardHomeasp"
fi
umount /www/Advanced_Extensions_app17.asp
mount --bind /opt/app/AdGuardHome/Advanced_Extensions_AdGuardHome.asp /www/Advanced_Extensions_app17.asp
# 更新程序启动脚本

[ "$1" = "del" ] && /etc/storage/www_sh/AdGuardHome del &
}

case $ACTION in
start)
	AdGuardHome_close
	AdGuardHome_check
	;;
check)
	AdGuardHome_check
	;;
stop)
	AdGuardHome_close
	;;
updateapp17)
	AdGuardHome_restart o
	[ "$AdGuardHome_enable" = "1" ] && nvram set AdGuardHome_status="updateAdGuardHome" && logger -t "【AdGuardHome】" "重启" && AdGuardHome_restart
	[ "$AdGuardHome_enable" != "1" ] && nvram set AdGuardHome_v="" && logger -t "【AdGuardHome】" "更新" && update_app del
	;;
update_app)
	update_app
	;;
update_asp)
	update_app update_asp
	;;
keep)
	#AdGuardHome_check
	AdGuardHome_keep
	;;
*)
	AdGuardHome_check
	;;
esac

