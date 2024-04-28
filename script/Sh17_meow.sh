#!/bin/bash
#copyright by hiboy
source /etc/storage/script/init.sh
meow_enable=`nvram get meow_enable`
[ -z $meow_enable ] && meow_enable=0 && nvram set meow_enable=0
meow_path=`nvram get meow_path`
[ -z $meow_path ] && meow_path="$(which meow)" && nvram set meow_path=$meow_path
[ ! -s "$meow_path" ] && meow_path="/opt/bin/meow" && nvram set meow_path=$meow_path
if [ "$meow_enable" != "0" ] ; then

ss_mode_x=`nvram get ss_mode_x`
ss_s1_local_port=`nvram get ss_s1_local_port`

[ -z $ss_mode_x ] && ss_mode_x=0 && nvram set ss_mode_x=$ss_mode_x
[ -z $ss_s1_local_port ] && ss_s1_local_port=1081 && nvram set ss_s1_local_port=$ss_s1_local_port
meow_renum=`nvram get meow_renum`
meow_renum=${meow_renum:-"0"}
cmd_log_enable=`nvram get cmd_log_enable`
cmd_name="meow"
cmd_log=""
if [ "$cmd_log_enable" = "1" ] || [ "$meow_renum" -gt "0" ] ; then
	cmd_log="$cmd_log2"
fi
fi

if [ ! -z "$(echo $scriptfilepath | grep -v "/tmp/script/" | grep meow)" ] && [ ! -s /tmp/script/_meow ] ; then
	mkdir -p /tmp/script
	{ echo '#!/bin/bash' ; echo $scriptfilepath '"$@"' '&' ; } > /tmp/script/_meow
	chmod 777 /tmp/script/_meow
fi

meow_restart () {
i_app_restart "$@" -name="meow"
}

meow_get_status () {

lan_ipaddr=`nvram get lan_ipaddr`
B_restart="$meow_enable$meow_path$lan_ipaddr$ss_s1_local_port$ss_mode_x$(cat /etc/storage/meow_script.sh /etc/storage/meow_config_script.sh | grep -v '^#' | grep -v '^$')"

i_app_get_status -name="meow" -valb="$B_restart"
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
i_app_keep -name="meow" -pidof="$(basename $meow_path)" -cpath="$meow_path" &
}

meow_close () {
kill_ps "$scriptname keep"
sed -Ei '/【meow】|^$/d' /tmp/script/_opt_script_check
[ ! -z "$meow_path" ] && kill_ps "$meow_path"
killall meow meow_script.sh
kill_ps "/tmp/script/_meow"
kill_ps "_meow.sh"
kill_ps "$scriptname"
}

meow_start () {
check_webui_yes
i_app_get_cmd_file -name="meow" -cmd="$meow_path" -cpath="/opt/bin/meow" -down1="$hiboyfile/meow" -down2="$hiboyfile2/meow"
[ -s "$SVC_PATH" ] && [ "$(nvram get meow_path)" != "$SVC_PATH" ] && nvram set meow_path="$SVC_PATH"
meow_path="$SVC_PATH"

logger -t "【meow】" "运行 meow_script"
/etc/storage/meow_script.sh
eval "$meow_path -rc /etc/storage/meow_config_script.sh $cmd_log" &
restart_on_dhcpd
sleep 4
i_app_keep -t -name="meow" -pidof="$(basename $meow_path)" -cpath="$meow_path"
meow_get_status
eval "$scriptfilepath keep &"
exit 0
}

initconfig () {

	if [ ! -f "/etc/storage/meow_script.sh" ] || [ ! -s "/etc/storage/meow_script.sh" ] ; then
cat > "/etc/storage/meow_script.sh" <<-\FOF
#!/bin/bash
source /etc/storage/script/init.sh
export PATH='/etc/storage/bin:/tmp/script:/etc/storage/script:/opt/usr/sbin:/opt/usr/bin:/opt/sbin:/opt/bin:/usr/local/sbin:/usr/sbin:/usr/bin:/sbin:/bin'
export LD_LIBRARY_PATH=/lib:/opt/lib
sed -Ei '/UI设置自动生成/d' /etc/storage/meow_config_script.sh
sed -Ei '/^$/d' /etc/storage/meow_config_script.sh
ss_mode_x=`nvram get ss_mode_x`
ss_mode_x=${ss_mode_x:-"0"}
ss_run_ss_local=`nvram get ss_run_ss_local`
ss_s1_local_port=`nvram get ss_s1_local_port`
ss_s1_local_port=${ss_s1_local_port:-"1081"}
nvram set ss_s1_local_port=$ss_s1_local_port
lan_ipaddr=`nvram get lan_ipaddr`
sed -Ei "/$lan_ipaddr:$ss_s1_local_port/d" /etc/storage/meow_config_script.sh
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

