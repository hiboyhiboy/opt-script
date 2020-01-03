#!/bin/sh
#copyright by hiboy
source /etc/storage/script/init.sh
frp_enable=`nvram get frp_enable`
[ -z $frp_enable ] && frp_enable=0 && nvram set frp_enable=0
frp_version_2="0.31.0"
frp_version_0="0.24.1"
frp_version_1="0.16.1"
frp_version_3="使用最新版"
frp_version_4="使用最新版"
frp_version_5="使用最新版"
frp_version_6="使用最新版"
frp_version_7="使用最新版"
frp_version_8="使用最新版"
frp_version_9="使用最新版"
frp_version_10="不变动版本"
nvram set frp_version_2="$frp_version_2"
nvram set frp_version_0="$frp_version_0"
nvram set frp_version_1="$frp_version_1"
nvram set frp_version_3="$frp_version_3"
nvram set frp_version_4="$frp_version_4"
nvram set frp_version_5="$frp_version_5"
nvram set frp_version_6="$frp_version_6"
nvram set frp_version_7="$frp_version_7"
nvram set frp_version_8="$frp_version_8"
nvram set frp_version_9="$frp_version_9"
nvram set frp_version_10="$frp_version_10"
frp_version=`nvram get frp_version`
[ -z $frp_version ] && frp_version=10 && nvram set frp_version=10
if [ "$frp_enable" != "0" ] ; then
#nvramshow=`nvram showall | grep '=' | grep frp | awk '{print gensub(/'"'"'/,"'"'"'\"'"'"'\"'"'"'","g",$0);}'| awk '{print gensub(/=/,"='\''",1,$0)"'\'';";}'` && eval $nvramshow
frpc_enable=`nvram get frpc_enable`
frps_enable=`nvram get frps_enable`
frp_renum=`nvram get frp_renum`
frp_renum=${frp_renum:-"0"}
cmd_log_enable=`nvram get cmd_log_enable`
cmd_name="frp"
cmd_log=""
if [ "$cmd_log_enable" = "1" ] || [ "$frp_renum" -gt "0" ] ; then
	cmd_log="$cmd_log2"
fi
fi

if [ ! -z "$(echo $scriptfilepath | grep -v "/tmp/script/" | grep frp)" ]  && [ ! -s /tmp/script/_frp ]; then
	mkdir -p /tmp/script
	{ echo '#!/bin/sh' ; echo $scriptfilepath '"$@"' '&' ; } > /tmp/script/_frp
	chmod 777 /tmp/script/_frp
fi

frp_restart () {

relock="/var/lock/frp_restart.lock"
if [ "$1" = "o" ] ; then
	nvram set frp_renum="0"
	[ -f $relock ] && rm -f $relock
	return 0
fi
if [ "$1" = "x" ] ; then
	if [ -f $relock ] ; then
		logger -t "【frp】" "多次尝试启动失败，等待【"`cat $relock`"分钟】后自动尝试重新启动"
		exit 0
	fi
	frp_renum=${frp_renum:-"0"}
	frp_renum=`expr $frp_renum + 1`
	nvram set frp_renum="$frp_renum"
	if [ "$frp_renum" -gt "2" ] ; then
		I=19
		echo $I > $relock
		logger -t "【frp】" "多次尝试启动失败，等待【"`cat $relock`"分钟】后自动尝试重新启动"
		while [ $I -gt 0 ]; do
			I=$(($I - 1))
			echo $I > $relock
			sleep 60
			[ "$(nvram get frp_renum)" = "0" ] && exit 0
			[ $I -lt 0 ] && break
		done
		nvram set frp_renum="0"
	fi
	[ -f $relock ] && rm -f $relock
fi
nvram set frp_status=0
eval "$scriptfilepath &"
exit 0
}

frp_get_status () {

A_restart=`nvram get frp_status`
B_restart="$frp_enable$frpc_enable$frps_enable$frp_version$(cat /etc/storage/frp_script.sh | grep -v '^#' | grep -v "^$")"
B_restart=`echo -n "$B_restart" | md5sum | sed s/[[:space:]]//g | sed s/-//g`
if [ "$A_restart" != "$B_restart" ] ; then
nvram set frp_status=$B_restart
needed_restart=1
else
needed_restart=0
fi
}

frp_check () {

frp_get_status
if [ "$frp_enable" != "1" ] && [ "$needed_restart" = "1" ] ; then
	[ ! -z "`pidof frpc`" ] && logger -t "【frp】" "停止 frpc" && frp_close
	[ ! -z "`pidof frps`" ] && logger -t "【frp】" "停止 frps" && frp_close
	{ kill_ps "$scriptname" exit0; exit 0; }
fi
if [ "$frp_enable" = "1" ] ; then
	if [ "$needed_restart" = "1" ] ; then
		frp_close
		frp_start
	else
		[ "$frpc_enable" = "1" ] && [ -z "`pidof frpc`" ] && frp_restart
		[ "$frps_enable" = "1" ] && [ -z "`pidof frps`" ] && frp_restart
	fi
fi
}

frp_keep () {

logger -t "【frp】" "守护进程启动"
if [ -s /tmp/script/_opt_script_check ]; then
sed -Ei '/【frp】|^$/d' /tmp/script/_opt_script_check
if [ "$frpc_enable" = "1" ] ; then
cat >> "/tmp/script/_opt_script_check" <<-OSC
[ -z "\`pidof frpc\`" ] || [ ! -s "`which frpc`" ] && nvram set frp_status=00 && logger -t "【frp】" "重新启动frpc" && eval "$scriptfilepath &" && sed -Ei '/【frp】|^$/d' /tmp/script/_opt_script_check # 【frp】
OSC
fi
if [ "$frps_enable" = "1" ] ; then
cat >> "/tmp/script/_opt_script_check" <<-OSC
[ -z "\`pidof frps\`" ] || [ ! -s "`which frps`" ] && nvram set frp_status=00 && logger -t "【frp】" "重新启动frps" && eval "$scriptfilepath &" && sed -Ei '/【frp】|^$/d' /tmp/script/_opt_script_check # 【frp】
OSC
fi
return
fi

while true; do
if [ "$frpc_enable" = "1" ] ; then
	if [ -z "`pidof frpc`" ] || [ ! -s "`which frpc`" ] ; then
		logger -t "【frp】" "frpc重新启动"
		frp_restart
	fi
fi
if [ "$frps_enable" = "1" ] ; then
	if [ -z "`pidof frps`" ] || [ ! -s "`which frps`" ] ; then
		logger -t "【frp】" "frps重新启动"
		frp_restart
	fi
fi
	sleep 232
done
}

frp_close () {
sed -Ei '/【frp】|^$/d' /tmp/script/_opt_script_check
killall frpc frps frp_script.sh
killall -9 frpc frps frp_script.sh
rm -f /dev/null ; mknod /dev/null c 1 3 ; chmod 666 /dev/null;
kill_ps "/tmp/script/_frp"
kill_ps "_frp.sh"
kill_ps "$scriptname"
}

frp_start () {
check_webui_yes
action_for=""
frp_ver_wget=""
[ "$frp_version" = "2" ] && frp_ver_wget="0.25.0" && frp_version_txt=$frp_version_2
[ "$frp_version" = "0" ] && frp_ver_wget="0.24.1" && frp_version_txt=$frp_version_0
[ "$frp_version" = "1" ] && frp_ver_wget="0.16.1" && frp_version_txt=$frp_version_1
[ "$frp_version" = "3" ] && frp_ver_wget="0.25.0" && nvram set frp_version=9
[ "$frp_version" = "4" ] && frp_ver_wget="0.25.0" && nvram set frp_version=9
[ "$frp_version" = "5" ] && frp_ver_wget="0.25.0" && nvram set frp_version=9
[ "$frp_version" = "6" ] && frp_ver_wget="0.25.0" && nvram set frp_version=9
[ "$frp_version" = "7" ] && frp_ver_wget="0.25.0" && nvram set frp_version=9
[ "$frp_version" = "8" ] && frp_ver_wget="0.25.0" && nvram set frp_version=9
[ "$frp_version" = "9" ] && frp_ver_wget="0.25.0" && frp_version_txt=$frp_version_2
[ "$frp_version" = "10" ] && frp_ver_wget="0.25.0"
[ "$frpc_enable" = "1" ] && action_for="frpc"
[ "$frps_enable" = "1" ] && action_for=$action_for" frps"
del_tmp=0
if [ "$frp_version" != "10" ] ; then
for action_frp in $action_for
do
if [ -s "/opt/bin/$action_frp" ] ; then
	frp_ver="`/opt/bin/$action_frp --version`"
	if [ "$frp_ver" != "$frp_version_txt" ] ; then
		logger -t "【frp】" "$action_frp 当前版本 $frp_ver ,需要安装 $frp_version_txt ,自动重新下载"
		[ -s "/opt/bin/$action_frp" ] && rm -f /opt/bin/$action_frp
		del_tmp=1
	fi
fi
done
if [ "$del_tmp" = "1" ] ; then
	rm -rf /etc/storage/script/Sh32_frp.sh
	if [ ! -f "/etc/storage/script/Sh32_frp.sh" ] || [ ! -s "/etc/storage/script/Sh32_frp.sh" ] ; then
		wgetcurl.sh /etc/storage/script/Sh32_frp.sh "$hiboyscript/script/Sh32_frp.sh" "$hiboyscript2/script/Sh32_frp.sh"
	fi
	frp_restart o
	/etc/storage/script/Sh32_frp.sh update_app
fi
fi
for action_frp in $action_for
do
	SVC_PATH="/opt/bin/$action_frp"
	chmod 777 "$SVC_PATH"
	[[ "$($action_frp -h 2>&1 | wc -l)" -lt 2 ]] && rm -rf /opt/bin/$action_frp
	if [ ! -s "$SVC_PATH" ] ; then
		logger -t "【frp】" "找不到 $SVC_PATH ，安装 opt 程序"
		/tmp/script/_mountopt start
		initopt
	fi
	wgetcurl_file "$SVC_PATH" "$hiboyfile/$action_frp$frp_ver_wget" "$hiboyfile2/$action_frp$frp_ver_wget"
	if [ ! -s "$SVC_PATH" ] ; then
		logger -t "【frp】" "找不到 $SVC_PATH ，需要手动安装 $SVC_PATH"
		logger -t "【frp】" "启动失败, 10 秒后自动尝试重新启动" && sleep 10 && frp_restart x
	fi
done

logger -t "【frp】" "运行 frp_script"

rm -f /dev/null ; mknod /dev/null c 1 3 ; chmod 666 /dev/null;
eval "/etc/storage/frp_script.sh $cmd_log" &
restart_dhcpd
sleep 4
if [ "$frpc_enable" = "1" ] ; then
	frpc_v="`/opt/bin/frpc --version`"
	nvram set frpc_v=$frpc_v
	logger -t "【frp】" "frpc-version: $frpc_v"
	[ -z "`pidof frpc`" ] && logger -t "【frp】" "frpc启动失败, 注意检查端口是否有冲突,程序是否下载完整,10 秒后自动尝试重新启动" && sleep 10 && frp_restart x
fi
if [ "$frps_enable" = "1" ] ; then
	frps_v="`/opt/bin/frps --version`"
	nvram set frps_v=$frps_v
	logger -t "【frp】" "frps-version: $frps_v"
	[ -z "`pidof frps`" ] && logger -t "【frp】" "frps启动失败, 注意检查端口是否有冲突,程序是否下载完整,10 秒后自动尝试重新启动" && sleep 10 && frp_restart x
fi
[ "$frpc_enable" = "1" ] && [ ! -z "`pidof frpc`" ] && logger -t "【frp】" "frpc启动成功" && frp_restart o
[ "$frps_enable" = "1" ] && [ ! -z "`pidof frps`" ] && logger -t "【frp】" "frps启动成功" && frp_restart o
#frp_get_status
eval "$scriptfilepath keep &"
exit 0
}

initopt () {
optPath=`grep ' /opt ' /proc/mounts | grep tmpfs`
[ ! -z "$optPath" ] && return
if [ ! -z "$(echo $scriptfilepath | grep -v "/opt/etc/init")" ] && [ -s "/opt/etc/init.d/rc.func" ] ; then
	{ echo '#!/bin/sh' ; echo $scriptfilepath '"$@"' '&' ; } > /opt/etc/init.d/$scriptname && chmod 777  /opt/etc/init.d/$scriptname
fi

}

initconfig () {

frp_script="/etc/storage/frp_script.sh"
if [ ! -f "$frp_script" ] || [ ! -s "$frp_script" ] ; then
	cat > "$frp_script" <<-\EEE
#!/bin/sh
export PATH='/etc/storage/bin:/tmp/script:/etc/storage/script:/opt/usr/sbin:/opt/usr/bin:/opt/sbin:/opt/bin:/usr/local/sbin:/usr/sbin:/usr/bin:/sbin:/bin'
export LD_LIBRARY_PATH=/lib:/opt/lib
killall frpc frps
rm -f /dev/null ; mknod /dev/null c 1 3 ; chmod 666 /dev/null;
mkdir -p /tmp/frp
#启动frp功能后会运行以下脚本
#frp项目地址教程: https://github.com/fatedier/frp/blob/master/README_zh.md
#请自行修改 token 用于对客户端连接进行身份验证
# IP查询： http://119.29.29.29/d?dn=github.com

cat > "/tmp/frp/myfrpc.ini" <<-\EOF
# ==========客户端配置：==========
[common]
server_addr = 远端frp服务器ip或域名
server_port = 7000
token = 12345

#log_file = /dev/null
#log_level = info
#log_max_days = 3

[web]
remote_port = 6000
type = http
local_ip = 192.168.123.1
local_port = 80
subdomain = test
#host_header_rewrite = 实际你内网访问的域名，可以供公网的域名不一致，如果一致可以不写
# ====================
EOF

#请手动配置【外部网络 (WAN) - 端口转发 (UPnP)】开启 WAN 外网端口
cat > "/tmp/frp/myfrps.ini" <<-\EOF
# ==========服务端配置：==========
[common]
bind_port = 7000
dashboard_port = 7500
# dashboard 用户名密码，默认都为 admin
dashboard_user = admin
dashboard_pwd = admin
vhost_http_port = 88
token = 12345
subdomain_host = frps.com
max_pool_count = 50
#log_file = /dev/null
#log_level = info
#log_max_days = 3
# ====================
EOF

#启动：
frpc_enable=`nvram get frpc_enable`
frpc_enable=${frpc_enable:-"0"}
frps_enable=`nvram get frps_enable`
frps_enable=${frps_enable:-"0"}
if [ "$frpc_enable" = "1" ] ; then
    frpc -c /tmp/frp/myfrpc.ini 2>&1 &
fi
if [ "$frps_enable" = "1" ] ; then
    frps -c /tmp/frp/myfrps.ini 2>&1 &
fi

EEE
	chmod 755 "$frp_script"
fi

}

initconfig

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
	rm -rf /opt/bin/frpc /opt/bin/frps /opt/opt_backup/bin/frpc /opt/opt_backup/bin/frps
fi

initconfig

# 加载更新程序启动脚本
if [ ! -f "/etc/storage/www_sh/frp" ] || [ -z "$(grep "更新程序启动脚本" /etc/storage/www_sh/frp)" ] ; then
	wgetcurl.sh /etc/storage/www_sh/frp "$hiboyscript/www_sh/frp" "$hiboyscript2/www_sh/frp"
fi
# 更新程序启动脚本

[ "$1" = "del" ] && /etc/storage/www_sh/frp del &
}

case $ACTION in
start)
	frp_close
	frp_check
	;;
check)
	frp_check
	;;
stop)
	frp_close
	;;
keep)
	#frp_check
	frp_keep
	;;
updatefrp)
	frp_restart o
	[ "$frp_enable" = "1" ] && nvram set frp_status="updatefrp" && logger -t "【frp】" "重启" && frp_restart
	[ "$frp_enable" != "1" ] && nvram set frpc_v="" && nvram set frps_v="" && logger -t "【frp】" "frpc、frps更新" && update_app del
	;;
update_app)
	update_app
	frp_restart
	;;
*)
	frp_check
	;;
esac

