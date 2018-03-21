#!/bin/sh
#copyright by hiboy
source /etc/storage/script/init.sh
meow_enable=`nvram get meow_enable`
[ -z $meow_enable ] && meow_enable=0 && nvram set meow_enable=0
meow_path=`nvram get meow_path`
[ -z $meow_path ] && meow_path="/opt/bin/meow" && nvram set meow_path=$meow_path
if [ "$meow_enable" != "0" ] ; then
#nvramshow=`nvram showall | grep '=' | grep ss | awk '{print gensub(/'"'"'/,"'"'"'\"'"'"'\"'"'"'","g",$0);}'| awk '{print gensub(/=/,"='\''",1,$0)"'\'';";}'` && eval $nvramshow
#nvramshow=`nvram showall | grep '=' | grep meow | awk '{print gensub(/'"'"'/,"'"'"'\"'"'"'\"'"'"'","g",$0);}'| awk '{print gensub(/=/,"='\''",1,$0)"'\'';";}'` && eval $nvramshow

kcptun2_enable=`nvram get kcptun2_enable`
kcptun2_enable2=`nvram get kcptun2_enable2`
ss_mode_x=`nvram get ss_mode_x`
ss_s1_local_port=`nvram get ss_s1_local_port`
ss_s2_local_port=`nvram get ss_s2_local_port`
ss_rdd_server=`nvram get ss_server2`

[ -z $ss_mode_x ] && ss_mode_x=0 && nvram set ss_mode_x=$ss_mode_x
[ -z $kcptun2_enable ] && kcptun2_enable=0 && nvram set kcptun2_enable=$kcptun2_enable
[ -z $kcptun2_enable2 ] && kcptun2_enable2=0 && nvram set kcptun2_enable2=$kcptun2_enable2
[ "$kcptun2_enable" = "2" ] && ss_rdd_server=""
[ -z $ss_s1_local_port ] && ss_s1_local_port=1081 && nvram set ss_s1_local_port=$ss_s1_local_port
[ -z $ss_s2_local_port ] && ss_s2_local_port=1082 && nvram set ss_s2_local_port=$ss_s2_local_port
fi

if [ ! -z "$(echo $scriptfilepath | grep -v "/tmp/script/" | grep meow)" ]  && [ ! -s /tmp/script/_meow ]; then
	mkdir -p /tmp/script
	{ echo '#!/bin/sh' ; echo $scriptfilepath '"$@"' '&' ; } > /tmp/script/_meow
	chmod 777 /tmp/script/_meow
fi

meow_restart () {

relock="/var/lock/meow_restart.lock"
if [ "$1" = "o" ] ; then
	nvram set meow_renum="0"
	[ -f $relock ] && rm -f $relock
	return 0
fi
if [ "$1" = "x" ] ; then
	if [ -f $relock ] ; then
		logger -t "【meow】" "多次尝试启动失败，等待【"`cat $relock`"分钟】后自动尝试重新启动"
		exit 0
	fi
	meow_renum=${meow_renum:-"0"}
	meow_renum=`expr $meow_renum + 1`
	nvram set meow_renum="$meow_renum"
	if [ "$meow_renum" -gt "2" ] ; then
		I=19
		echo $I > $relock
		logger -t "【meow】" "多次尝试启动失败，等待【"`cat $relock`"分钟】后自动尝试重新启动"
		while [ $I -gt 0 ]; do
			I=$(($I - 1))
			echo $I > $relock
			sleep 60
			[ "$(nvram get meow_renum)" = "0" ] && exit 0
			[ $I -lt 0 ] && break
		done
		nvram set meow_renum="0"
	fi
	[ -f $relock ] && rm -f $relock
fi
nvram set meow_status=0
eval "$scriptfilepath &"
exit 0
}

meow_get_status () {

lan_ipaddr=`nvram get lan_ipaddr`
A_restart=`nvram get meow_status`
B_restart="$meow_enable$meow_path$lan_ipaddr$ss_s1_local_port$ss_s2_local_port$ss_mode_x$ss_rdd_server$(cat /etc/storage/meow_script.sh /etc/storage/meow_config_script.sh | grep -v '^#' | grep -v "^$")"
B_restart=`echo -n "$B_restart" | md5sum | sed s/[[:space:]]//g | sed s/-//g`
if [ "$A_restart" != "$B_restart" ] ; then
	nvram set meow_status=$B_restart
	needed_restart=1
else
	needed_restart=0
fi
}

meow_check () {

meow_get_status
if [ "$meow_enable" != "1" ] && [ "$needed_restart" = "1" ] ; then
	[ ! -z "$(ps -w | grep "$meow_path" | grep -v grep )" ] && logger -t "【meow】" "停止 meow" && meow_close
	{ kill_ps "$scriptname" exit0; exit 0; }
fi
if [ "$meow_enable" = "1" ] ; then
	if [ "$needed_restart" = "1" ] ; then
		meow_close
		meow_start
	else
		[ -z "$(ps -w | grep "$meow_path" | grep -v grep )" ] && meow_restart
	fi
fi
}

meow_keep () {
logger -t "【meow】" "守护进程启动"
if [ -s /tmp/script/_opt_script_check ]; then
sed -Ei '/【meow】|^$/d' /tmp/script/_opt_script_check
cat >> "/tmp/script/_opt_script_check" <<-OSC
	NUM=\`grep "$meow_path" /tmp/ps | grep -v grep |wc -l\` # 【meow】
	if [ "\$NUM" -lt "1" ] || [ ! -s "$meow_path" ] ; then # 【meow】
		logger -t "【meow】" "重新启动\$NUM" # 【meow】
		nvram set meow_status=00 && eval "$scriptfilepath &" && sed -Ei '/【meow】|^$/d' /tmp/script/_opt_script_check # 【meow】
	fi # 【meow】
OSC
return
fi

while true; do
	NUM=`ps -w | grep "$meow_path" | grep -v grep |wc -l`
	if [ "$NUM" -lt "1" ] || [ ! -s "$meow_path" ] ; then
		logger -t "【meow】" "重新启动$NUM"
		meow_restart
	fi
sleep 217
done
}

meow_close () {
sed -Ei '/【meow】|^$/d' /tmp/script/_opt_script_check
[ ! -z "$meow_path" ] && kill_ps "$meow_path"
killall meow meow_script.sh
killall -9 meow meow_script.sh
kill_ps "/tmp/script/_meow"
kill_ps "_meow.sh"
kill_ps "$scriptname"
}

meow_start () {
SVC_PATH="$meow_path"
if [ ! -s "$SVC_PATH" ] ; then
	SVC_PATH="/opt/bin/meow"
fi
chmod 777 "$SVC_PATH"
[[ "$(meow -h 2>&1 | wc -l)" -lt 2 ]] && rm -rf /opt/bin/meow
if [ ! -s "$SVC_PATH" ] ; then
	logger -t "【meow】" "找不到 $SVC_PATH，安装 opt 程序"
	/tmp/script/_mountopt start
fi
if [ ! -s "$SVC_PATH" ] ; then
	logger -t "【meow】" "找不到 $SVC_PATH 下载程序"
	wgetcurl.sh /opt/bin/meow "$hiboyfile/meow" "$hiboyfile2/meow"
	chmod 755 "/opt/bin/meow"
else
	logger -t "【meow】" "找到 $SVC_PATH"
fi
if [ ! -s "$SVC_PATH" ] ; then
	logger -t "【meow】" "找不到 $SVC_PATH ，需要手动安装 $SVC_PATH"
	logger -t "【meow】" "启动失败, 10 秒后自动尝试重新启动" && sleep 10 && meow_restart x
fi
if [ -s "$SVC_PATH" ] ; then
	nvram set meow_path="$SVC_PATH"
fi
meow_path="$SVC_PATH"

logger -t "【meow】" "运行 meow_script"
/etc/storage/meow_script.sh
$meow_path -rc /etc/storage/meow_config_script.sh &
restart_dhcpd
sleep 2
[ ! -z "$(ps -w | grep "$meow_path" | grep -v grep )" ] && logger -t "【meow】" "启动成功" && meow_restart o
[ -z "$(ps -w | grep "$meow_path" | grep -v grep )" ] && logger -t "【meow】" "启动失败, 注意检查端口是否有冲突,程序是否下载完整,10 秒后自动尝试重新启动" && sleep 10 && meow_restart x
initopt
meow_get_status
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

	if [ ! -f "/etc/storage/meow_script.sh" ] || [ ! -s "/etc/storage/meow_script.sh" ] ; then
cat > "/etc/storage/meow_script.sh" <<-\FOF
#!/bin/sh
source /etc/storage/script/init.sh
export PATH='/etc/storage/bin:/tmp/script:/etc/storage/script:/opt/usr/sbin:/opt/usr/bin:/opt/sbin:/opt/bin:/usr/local/sbin:/usr/sbin:/usr/bin:/sbin:/bin'
export LD_LIBRARY_PATH=/lib:/opt/lib
sed -Ei '/UI设置自动生成/d' /etc/storage/meow_config_script.sh
sed -Ei '/^$/d' /etc/storage/meow_config_script.sh
ss_mode_x=`nvram get ss_mode_x`
ss_mode_x=${ss_mode_x:-"0"}
ss_rdd_server=`nvram get ss_server2`
kcptun2_enable=`nvram get kcptun2_enable`
kcptun2_enable=${kcptun2_enable:-"0"}
kcptun2_enable2=`nvram get kcptun2_enable2`
kcptun2_enable2=${kcptun2_enable2:-"0"}
[ "$ss_mode_x" != "0" ] && kcptun2_enable=$kcptun2_enable2
[ "$kcptun2_enable" = "2" ] && ss_rdd_server=""
ss_run_ss_local=`nvram get ss_run_ss_local`
ss_s1_local_port=`nvram get ss_s1_local_port`
ss_s2_local_port=`nvram get ss_s2_local_port`
ss_s1_local_port=${ss_s1_local_port:-"1081"}
ss_s2_local_port=${ss_s2_local_port:-"1082"}
nvram set ss_s1_local_port=$ss_s1_local_port
nvram set ss_s2_local_port=$ss_s2_local_port
lan_ipaddr=`nvram get lan_ipaddr`
sed -Ei "/$lan_ipaddr:$ss_s1_local_port/d" /etc/storage/meow_config_script.sh
sed -Ei "/$lan_ipaddr:$ss_s2_local_port/d" /etc/storage/meow_config_script.sh
if [ ! -f "/etc/storage/meow_direct_script.sh" ] || [ ! -s "/etc/storage/meow_direct_script.sh" ] ; then
logger -t "【meow】" "找不到 直连列表 下载 $hiboyfile/direct.txt"
wgetcurl.sh /etc/storage/meow_direct_script.sh "$hiboyfile/direct.txt" "$hiboyfile2/direct.txt"
chmod 666 "/etc/storage/meow_direct_script.sh"
fi
if [ "$ss_mode_x" = "3" ] || [ "$ss_run_ss_local" = "1" ] ; then
cat >> "/etc/storage/meow_config_script.sh" <<-EUI
# UI设置自动生成 
proxy = socks5://$lan_ipaddr:$ss_s1_local_port
EUI
if [ ! -z $ss_rdd_server ] ; then
cat >> "/etc/storage/meow_config_script.sh" <<-EUI
# UI设置自动生成 
proxy = socks5://$lan_ipaddr:$ss_s2_local_port
EUI
fi
fi
FOF
chmod 777 "/etc/storage/meow_script.sh"
	fi
	if [ ! -f "/etc/storage/meow_config_script.sh" ] || [ ! -s "/etc/storage/meow_config_script.sh" ] ; then
cat > "/etc/storage/meow_config_script.sh" <<-\MECON
# 配置文件中 # 开头的行为注释
#
# 代理服务器监听地址，重复多次来指定多个监听地址，语法：
#
#   listen = protocol://[optional@]server_address:server_port
#
# 支持的 protocol 如下：
#
# HTTP (提供 http 代理):
#   listen = http://127.0.0.1:4411
#
#   上面的例子中，MEOW 生成的 PAC url 为 http://127.0.0.1:4411/pac
#
# HTTPS (提供 https 代理):
#   listen = https://example.com:443
#   cert = /path/to/cert.pem
#   key = /path/to/key.pem
#
#   上面的例子中，MEOW 生成的 PAC url 为 https://example.com:443/pac
#
# MEOW (需两个 MEOW 服务器配合使用):
#   listen = meow://encrypt_method:password@1.2.3.4:5678
#
#   若 1.2.3.4:5678 在国外，位于国内的 MEOW 配置其为二级代理后，两个 MEOW 之间可以
#   通过加密连接传输 http 代理流量。采用与 shadowsocks 相同的加密方式。
#
# 其他说明：
# - 若 server_address 为 0.0.0.0，监听本机所有 IP 地址
# - 可以用如下语法指定 PAC 中返回的代理服务器地址（当使用端口映射将 http 代理提供给外网时使用）
#   listen = http://127.0.0.1:4411 1.2.3.4:5678
#
listen = http://0.0.0.0:4411
#
#############################
# 通过IP判断是否直连，默认开启
#############################
#judgeByIP = true

# 日志文件路径，如不指定则输出到 stdout
logFile = /tmp/syslog.log
#
# 指定多个二级代理时使用的负载均衡策略，可选策略如下
#
#   backup:  默认策略，优先使用第一个指定的二级代理，其他仅作备份使用
#   hash:    根据请求的 host name，优先使用 hash 到的某一个二级代理
#   latency: 优先选择连接延迟最低的二级代理
#
# 一个二级代理连接失败后会依次尝试其他二级代理
# 失败的二级代理会以一定的概率再次尝试使用，因此恢复后会重新启用
loadBalance = backup
#
#############################
# 指定二级代理
#############################
#
# 二级代理统一使用下列语法指定：
#
#   proxy = protocol://[authinfo@]server:port
#
# 重复使用 proxy 多次指定多个二级代理，backup 策略将按照二级代理出现的顺序来使用
#
# 目前支持的二级代理及配置举例：
#
# SOCKS5:
#   proxy = socks5://127.0.0.1:1080
#
# HTTP:
#   proxy = http://127.0.0.1:8080
#   proxy = http://user:password@127.0.0.1:8080
#
#   用户认证信息为可选项
#
# HTTPS:
#   proxy = https://example.com:8080
#   proxy = https://user:password@example.com:8080
#
#   用户认证信息为可选项
#
# Shadowsocks:
#   proxy = ss://encrypt_method:password@1.2.3.4:8388
#
#   authinfo 中指定加密方法和密码，所有支持的加密方法如下：
#     aes-128-cfb, aes-192-cfb, aes-256-cfb,
#     bf-cfb, cast5-cfb, des-cfb, rc4-md5,
#     chacha20, salsa20, rc4, table
#
# MEOW:
#   proxy = meow://method:passwd@1.2.3.4:4321
#
#   authinfo 与 shadowsocks 相同
#
#
#############################
# 执行 ssh 命令创建 SOCKS5 代理
#############################
#
# 下面的选项可以让 MEOW 执行 ssh 命令创建本地 SOCKS5 代理，并在 ssh 断开后重连
# MEOW 会自动使用通过 ssh 命令创建的代理，无需再通过 proxy 选项指定
# 可重复指定多个
#
# 注意这一功能需要系统上已有 ssh 命令，且必须使用 ssh public key authentication
#
# 若指定该选项，MEOW 将执行以下命令：
#     ssh -n -N -D <local_socks_port> -p <server_ssh_port> <user@server>
# server_ssh_port 端口不指定则默认为 22
# 如果要指定其他 ssh 选项，请修改 ~/.ssh/config
#sshServer = user@server:local_socks_port[:server_ssh_port]
#
#############################
# 认证
#############################
#
# 指定允许的 IP 或者网段。网段仅支持 IPv4，可以指定 IPv6 地址，用逗号分隔多个项
# 使用此选项时别忘了添加 127.0.0.1，否则本机访问也需要认证
#allowedClient = 127.0.0.1, 192.168.1.0/24, 10.0.0.0/8
#
# 要求客户端通过用户名密码认证
# MEOW 总是先验证 IP 是否在 allowedClient 中，若不在其中再通过用户名密码认证
#userPasswd = username:password
#
# 如需指定多个用户名密码，可在下面选项指定的文件中列出，文件中每行内容如下
#   username:password[:port]
# port 为可选项，若指定，则该用户只能从指定端口连接 MEOW
# 注意：如有重复用户，MEOW 会报错退出
#userPasswdFile = /path/to/file
#
# 认证失效时间
# 语法：2h3m4s 表示 2 小时 3 分钟 4 秒
#authTimeout = 2h
#
#############################
# 高级选项
#############################
#
# 将指定的 HTTP error code 认为是被干扰，使用二级代理重试，默认为空
#httpErrorCode =
#
# 最多允许使用多少个 CPU 核
#core = 2
#
# 修改 direct/proxy 文件路径，如不指定，默认在配置文件所在目录下
directFile = /etc/storage/meow_direct_script.sh
proxyFile = /etc/storage/basedomain.txt
MECON
chmod 777 "/etc/storage/meow_config_script.sh"
	fi

}

initconfig

case $ACTION in
start)
	meow_close
	meow_check
	;;
check)
	meow_check
	;;
stop)
	meow_close
	;;
keep)
	#meow_check
	meow_keep
	;;
*)
	meow_check
	;;
esac

