#!/bin/bash
#copyright by hiboy
source /etc/storage/script/init.sh
netbird_enable=`nvram get app_150`
[ -z $netbird_enable ] && netbird_enable=0 && nvram set app_150=0
netbird_keys="$(nvram get app_5)"

if [ "$netbird_enable" != "0" ] ; then

netbird_renum=`nvram get netbird_renum`
netbird_renum=${netbird_renum:-"0"}

cmd_log_enable=`nvram get cmd_log_enable`
cmd_name="netbird"
cmd_log=""
if [ "$cmd_log_enable" = "1" ] || [ "$netbird_renum" -gt "0" ] ; then
	cmd_log="$cmd_log2"
fi

fi

if [ ! -z "$(echo $scriptfilepath | grep -v "/tmp/script/" | grep netbird)" ] && [ ! -s /tmp/script/_app32 ] ; then
	mkdir -p /tmp/script
	{ echo '#!/bin/bash' ; echo $scriptfilepath '"$@"' '&' ; } > /tmp/script/_app32
	chmod 777 /tmp/script/_app32
fi

netbird_restart () {
i_app_restart "$@" -name="netbird"
}

netbird_get_status () {

B_restart="$netbird_enable$netbird_keys""$(cat /etc/storage/app_38.sh | grep -v '^#' | grep -v '^$')"

i_app_get_status -name="netbird" -valb="$B_restart"
}

netbird_check () {

netbird_get_status
if [ "$netbird_enable" != "1" ] && [ "$needed_restart" = "1" ] ; then
	[ ! -z "`pidof netbird`" ] && logger -t "【netbird】" "停止 netbird" && netbird_close
	{ kill_ps "$scriptname" exit0; exit 0; }
fi
if [ "$netbird_enable" = "1" ] ; then
	if [ "$needed_restart" = "1" ] ; then
		netbird_close
		netbird_start
	else
		[ "$netbird_enable" = "1" ] && [ -z "`pidof netbird`" ] && netbird_restart
	fi
fi
}

netbird_keep () {
i_app_keep -name="netbird" -pidof="netbird" &

}

netbird_close () {
sed -Ei '/【netbird】|^$/d' /tmp/script/_opt_script_check
iptables -t nat -D POSTROUTING -o wt0 -j MASQUERADE
netbird down
killall netbird
sleep 2
kill_ps "app_38.sh"
kill_ps "/tmp/script/_app32"
kill_ps "_netbird.sh"
kill_ps "$scriptname"
}

netbird_start () {
check_webui_yes

SVC_PATH="$(which netbird)"
[ ! -s "$SVC_PATH" ] && SVC_PATH="/opt/bin/netbird"
if [ ! -f $SVC_PATH ] ; then
	logger -t "【clash】" "找不到 $SVC_PATH ，安装 opt 程序"
	/etc/storage/script/Sh01_mountopt.sh start
	initopt
fi
mkdir -p /opt/app/netbird
SVC_PATH="$(which netbird)"
if [ ! -s "$SVC_PATH" ] ; then
	logger -t "【netbird】" "找不到 $SVC_PATH ，安装 netbird 程序"
	block=$(check_disk_size /opt/app/netbird)
	[ -z "$block" ] && block="0"
	[ "$block" != "0" ] && logger -t "【netbird】" "路径 /opt/app/netbird 剩余空间：$block M"
	if [ "$block" != "0" ] && [ ! -z "$block" ] && [ "$block" -lt "40" ] && [ ! -f "/opt/bin/netbird" ] ; then
		[ "$block" = "0" ] && logger -t "【netbird】" "opt 剩余空间少于 40M netbird 启动失败"
		nvram set app_150=0
		eval "$scriptfilepath &"
		exit 0
	fi
	if [ "$block" != "0" ] && [ ! -z "$block" ] && [ "$block" -lt "50" ] && [ ! -f "/opt/bin/netbird" ] ; then
		i_app_get_cmd_file -name="netbird" -cmd="netbird" -cpath="/opt/bin/netbird" -down1="$hiboyfile/netbird" -down2="$hiboyfile2/netbird"
	fi
fi
SVC_PATH="$(which netbird)"
if [ ! -s "$SVC_PATH" ] ; then
	if [ -z "$curltest" ] || [ ! -s "`which curl`" ] ; then
		tag="$( wget -T 5 -t 3 --user-agent "$user_agent" --max-redirect=0 --output-document=-  https://api.github.com/repos/netbirdio/netbird/releases/latest  2>&1 | grep 'tag_name' | cut -d\" -f4 )"
		[ -z "$tag" ] && tag="$( wget -T 5 -t 3 --user-agent "$user_agent" --quiet --output-document=-  https://api.github.com/repos/netbirdio/netbird/releases/latest  2>&1 | grep 'tag_name' | cut -d\" -f4 )"
	else
		tag="$( curl --connect-timeout 3 --user-agent "$user_agent"  https://api.github.com/repos/netbirdio/netbird/releases/latest  2>&1 | grep 'tag_name' | cut -d\" -f4 )"
		[ -z "$tag" ] && tag="$( curl -L --connect-timeout 3 --user-agent "$user_agent" -s  https://api.github.com/repos/netbirdio/netbird/releases/latest  2>&1 | grep 'tag_name' | cut -d\" -f4 )"
	fi
	tag="$(echo "$tag" | tr -d 'v' | tr -d ' ')"
	# 下载主程序
	rm -rf /opt/bin/netbird
	mkdir -p /opt/app/netbird/tmp
	url_tmp="https://github.com/netbirdio/netbird/releases/download/v""$tag""/netbird_""$tag""_linux_mipsle_softfloat.tar.gz"
	logger -t "【netbird】" "下载: $tag url: $url_tmp"
	wgetcurl_file "/opt/app/netbird/tmp/netbird_linux_mipsle_softfloat.tar.gz" "$url_tmp"
	logger -t "【netbird】" "解压: /opt/app/netbird/tmp/netbird_linux_mipsle_softfloat.tar.gz"
	tar -xz -C /opt/app/netbird/tmp -f /opt/app/netbird/tmp/netbird_linux_mipsle_softfloat.tar.gz
	mv -f "/opt/app/netbird/tmp/netbird" /opt/bin/netbird
	rm -rf /opt/app/netbird/tmp
	if [ ! -s "$SVC_PATH" ] ; then
		logger -t "【netbird】" "最新版本获取失败！！！"
		logger -t "【netbird】" "请打开 https://github.com/netbirdio/netbird/releases"
		logger -t "【netbird】" "手动下载 netbird_linux_mipsle_softfloat 文件。"
		logger -t "【netbird】" "文件文件放到 /opt/bin/netbird"
	fi
fi
chmod 777 "$SVC_PATH"

[ ! -d /opt/app/netbird/etc/netbird ] && mkdir -p /opt/app/netbird/etc/netbird
rm -f "/etc/netbird"
ln -sf "/opt/app/netbird/etc/netbird" "/etc/netbird"

[ ! -d /opt/app/netbird/etc/wiretrustee ] && mkdir -p /opt/app/netbird/etc/wiretrustee
rm -f "/etc/wiretrustee"
ln -sf "/opt/app/netbird/etc/wiretrustee" "/etc/wiretrustee"

[ ! -d /var/lib ] && mkdir -p /var/lib
[ ! -d /opt/app/netbird/var/lib/netbird ] && mkdir -p /opt/app/netbird/var/lib/netbird
rm -f "/var/lib/netbird"
ln -sf "/opt/app/netbird/var/lib/netbird" "/var/lib/netbird"
[ ! -d /opt/app/netbird/var/lib/wiretrustee ] && mkdir -p /opt/app/netbird/var/lib/wiretrustee
rm -f "/var/lib/wiretrustee"
ln -sf "/opt/app/netbird/var/lib/wiretrustee" "/var/lib/wiretrustee"

[ ! -d /var/run/log ] && mkdir -p /var/log
[ ! -d /opt/app/netbird/var/log/netbird ] && mkdir -p /opt/app/netbird/var/log/netbird
rm -f "/var/log/netbird"
ln -sf "/opt/app/netbird/var/log/netbird" "/var/log/netbird"
[ ! -d /opt/app/netbird/var/log/wiretrustee ] && mkdir -p /opt/app/netbird/var/log/wiretrustee
rm -f "/var/log/wiretrustee"
ln -sf "/opt/app/netbird/var/log/wiretrustee" "/var/log/wiretrustee"

[ ! -d /var/run ] && mkdir -p /var/run
[ ! -d /opt/app/netbird/var/run/wireguard ] && mkdir -p /opt/app/netbird/var/run/wireguard
rm -f "/var/run/wireguard"
ln -sf "/opt/app/netbird/var/run/wireguard" "/var/run/wireguard"



netbird_v="$($SVC_PATH version | head -n1)"
nvram set netbird_v="$netbird_v"
logger -t "【netbird】" "运行 NetBird 启动脚本 /etc/storage/app_38.sh"
dos2unix /etc/storage/app_38.sh
eval "/etc/storage/app_38.sh $cmd_log" &
sleep 3
i_app_keep -t -name="netbird" -pidof="netbird"
#netbird_get_status
eval "$scriptfilepath keep &"
exit 0
}


initconfig () {

if [ ! -f "/etc/storage/app_38.sh" ] || [ ! -s "/etc/storage/app_38.sh" ] ; then
	cat >> "/etc/storage/app_38.sh" <<-\EOF
#!/bin/bash
# 此脚本路径：/etc/storage/app_38.sh
# 请手动配置【外部网络 - 端口转发 - 启用手动端口映射】来开启WAN访问
netbird_keys="$(nvram get app_5)"
cd /opt/app/netbird
netbird service run &
sleep 5
netbird up --setup-key $netbird_keys
iptables -t nat -A POSTROUTING -o wt0 -j MASQUERADE

EOF
fi

}

initconfig

update_app () {

mkdir -p /opt/app/netbird
if [ "$1" = "del" ] ; then
	rm -rf /opt/app/netbird/Advanced_Extensions_netbird.asp
	rm -rf /opt/bin/netbird
fi

initconfig

# 加载程序配置页面
if [ ! -f "/opt/app/netbird/Advanced_Extensions_netbird.asp" ] || [ ! -s "/opt/app/netbird/Advanced_Extensions_netbird.asp" ] ; then
	wgetcurl.sh /opt/app/netbird/Advanced_Extensions_netbird.asp "$hiboyfile/Advanced_Extensions_netbirdasp" "$hiboyfile2/Advanced_Extensions_netbirdasp"
fi
umount /www/Advanced_Extensions_app32.asp
mount --bind /opt/app/netbird/Advanced_Extensions_netbird.asp /www/Advanced_Extensions_app32.asp
# 更新程序启动脚本

[ "$1" = "del" ] && /etc/storage/www_sh/netbird del &
}

case $ACTION in
start)
	netbird_close
	netbird_check
	;;
check)
	netbird_check
	;;
stop)
	netbird_close
	;;
updateapp32)
	netbird_restart o
	[ "$netbird_enable" = "1" ] && nvram set netbird_status="updatenetbird" && logger -t "【netbird】" "重启" && netbird_restart
	[ "$netbird_enable" != "1" ] && nvram set netbird_v="" && logger -t "【netbird】" "更新" && update_app del
	;;
update_app)
	update_app
	;;
keep)
	#netbird_check
	netbird_keep
	;;
*)
	netbird_check
	;;
esac

