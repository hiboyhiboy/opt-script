#!/bin/bash
#copyright by hiboy
source /etc/storage/script/init.sh
cow_enable=`nvram get cow_enable`
[ -z $cow_enable ] && cow_enable=0 && nvram set cow_enable=0
cow_path=`nvram get cow_path`
[ -z $cow_path ] && cow_path="$(which cow)" && nvram set cow_path=$cow_path
[ ! -s "$cow_path" ] && cow_path="/opt/bin/cow" && nvram set cow_path=$cow_path
if [ "$cow_enable" != "0" ] ; then

ss_mode_x=`nvram get ss_mode_x`
ss_s1_local_port=`nvram get ss_s1_local_port`

[ -z $ss_mode_x ] && ss_mode_x=0 && nvram set ss_mode_x=$ss_mode_x
[ -z $ss_s1_local_port ] && ss_s1_local_port=1081 && nvram set ss_s1_local_port=$ss_s1_local_port
cow_renum=`nvram get cow_renum`
cow_renum=${cow_renum:-"0"}
cmd_log_enable=`nvram get cmd_log_enable`
cmd_name="cow"
cmd_log=""
if [ "$cmd_log_enable" = "1" ] || [ "$cow_renum" -gt "0" ] ; then
	cmd_log="$cmd_log2"
fi
fi


if [ ! -z "$(echo $scriptfilepath | grep -v "/tmp/script/" | grep cow)" ] && [ ! -s /tmp/script/_cow ] ; then
	mkdir -p /tmp/script
	{ echo '#!/bin/bash' ; echo $scriptfilepath '"$@"' '&' ; } > /tmp/script/_cow
	chmod 777 /tmp/script/_cow
fi

cow_restart () {
i_app_restart "$@" -name="cow"
}

cow_get_status () {

B_restart="$cow_enable$cow_path$lan_ipaddr$ss_s1_local_port$ss_mode_x$(cat /etc/storage/cow_script.sh /etc/storage/cow_config_script.sh | grep -v '^#' | grep -v '^$')"

i_app_get_status -name="cow" -valb="$B_restart"
}

cow_check () {

cow_get_status
if [ "$cow_enable" != "1" ] && [ "$needed_restart" = "1" ] ; then
	[ ! -z "$(ps -w | grep "$cow_path" | grep -v grep )" ] && logger -t "【cow】" "停止 cow" && cow_close
	{ kill_ps "$scriptname" exit0; exit 0; }
fi
if [ "$cow_enable" = "1" ] ; then
	if [ "$needed_restart" = "1" ] ; then
		cow_close
		cow_start
	else
		[ -z "$(ps -w | grep "$cow_path" | grep -v grep )" ] && cow_restart
	fi
fi
}

cow_keep () {
i_app_keep -name="cow" -pidof="$(basename $cow_path)" -cpath="$cow_path" &
}

cow_close () {
kill_ps "$scriptname keep"
sed -Ei '/【cow】|^$/d' /tmp/script/_opt_script_check
[ ! -z "$cow_path" ] && kill_ps "$cow_path"
killall cow cow_script.sh
kill_ps "/tmp/script/_cow"
kill_ps "_cow.sh"
kill_ps "$scriptname"
}

cow_start () {
check_webui_yes
i_app_get_cmd_file -name="cow" -cmd="$cow_path" -cpath="/opt/bin/cow" -down1="$hiboyfile/cow" -down2="$hiboyfile2/cow"
[ -s "$SVC_PATH" ] && [ "$(nvram get cow_path)" != "$SVC_PATH" ] && nvram set cow_path="$SVC_PATH"
cow_path="$SVC_PATH"

logger -t "【cow】" "运行 cow_script"
/etc/storage/cow_script.sh
eval "$cow_path -rc /etc/storage/cow_config_script.sh $cmd_log" &
restart_on_dhcpd
sleep 4
i_app_keep -t -name="cow" -pidof="$(basename $cow_path)" -cpath="$cow_path"
cow_get_status
eval "$scriptfilepath keep &"
exit 0
}

initconfig () {

	if [ ! -f "/etc/storage/cow_script.sh" ] || [ ! -s "/etc/storage/cow_script.sh" ] ; then
cat > "/etc/storage/cow_script.sh" <<-\FOF
#!/bin/bash
export PATH='/etc/storage/bin:/tmp/script:/etc/storage/script:/opt/usr/sbin:/opt/usr/bin:/opt/sbin:/opt/bin:/usr/local/sbin:/usr/sbin:/usr/bin:/sbin:/bin'
export LD_LIBRARY_PATH=/lib:/opt/lib
sed -Ei '/UI设置自动生成/d' /etc/storage/cow_config_script.sh
sed -Ei '/^$/d' /etc/storage/cow_config_script.sh
ss_mode_x=`nvram get ss_mode_x`
ss_mode_x=${ss_mode_x:-"0"}
ss_run_ss_local=`nvram get ss_run_ss_local`
ss_s1_local_port=`nvram get ss_s1_local_port`
ss_s1_local_port=${ss_s1_local_port:-"1081"}
nvram set ss_s1_local_port=$ss_s1_local_port
lan_ipaddr=`nvram get lan_ipaddr`
sed -Ei "/$lan_ipaddr:$ss_s1_local_port/d" /etc/storage/cow_config_script.sh
if [ "$ss_mode_x" = "3" ] || [ "$ss_run_ss_local" = "1" ] ; then
cat >> "/etc/storage/cow_config_script.sh" <<-EUI
# UI设置自动生成 
proxy = socks5://$lan_ipaddr:$ss_s1_local_port
EUI
fi
FOF
chmod 777 "/etc/storage/cow_script.sh"
	fi
	if [ ! -f "/etc/storage/cow_config_script.sh" ] || [ ! -s "/etc/storage/cow_config_script.sh" ] ; then
cat > "/etc/storage/cow_config_script.sh" <<-\COWCON
# 配置文件中 # 开头的行为注释
#
# 代理服务器监听地址，重复多次来指定多个监听地址，语法：
#
#   listen = protocol://[optional@]server_address:server_port
#
# 支持的 protocol 如下：
#
# HTTP (提供 http 代理):
#   listen = http://127.0.0.1:7777
#
#   上面的例子中，cow 生成的 PAC url 为 http://127.0.0.1:7777/pac
#   配置浏览器或系统 HTTP 和 HTTPS 代理时请填入该地址
#   若配置代理时有对所有协议使用该代理的选项，且你不清楚此选项的含义，请勾选
#
# cow (需两个 cow 服务器配合使用):
#   listen = cow://encrypt_method:password@1.2.3.4:5678
#
#   若 1.2.3.4:5678 在国外，位于国内的 cow 配置其为二级代理后，两个 cow 之间可以
#   通过加密连接传输 http 代理流量。目前的加密采用与 shadowsocks 相同的方式。
#
# 其他说明：
# - 若 server_address 为 0.0.0.0，监听本机所有 IP 地址
# - 可以用如下语法指定 PAC 中返回的代理服务器地址（当使用端口映射将 http 代理提供给外网时使用）
#   listen = http://127.0.0.1:7777 1.2.3.4:5678
#
listen = http://0.0.0.0:7777
#
# 日志文件路径，如不指定则输出到 stdout
logFile = /tmp/syslog.log
#
# COW 默认仅对被墙网站使用二级代理
# 下面选项设置为 true 后，所有网站都通过二级代理访问
#alwaysProxy = false
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
#
# 自动生成ss-local_1.json配置
# 自动生成ss-local_2.json配置
#
#   用户认证信息为可选项
#
# shadowsocks:
#   proxy = ss://encrypt_method:password@1.2.3.4:8388
#   proxy = ss://encrypt_method-auth:password@1.2.3.4:8388
#
#   encrypt_method 添加 -auth 启用 One Time Auth
#   authinfo 中指定加密方法和密码，所有支持的加密方法如下：
#     aes-128-cfb, aes-192-cfb, aes-256-cfb,
#     bf-cfb, cast5-cfb, des-cfb, rc4-md5,
#     chacha20, salsa20, rc4, table
#   推荐使用 aes-128-cfb
#
# cow:
#   proxy = cow://method:passwd@1.2.3.4:4321
#
#   authinfo 与 shadowsocks 相同
#
#
#############################
# 执行 ssh 命令创建 SOCKS5 代理
#############################
#
# 下面的选项可以让 COW 执行 ssh 命令创建本地 SOCKS5 代理，并在 ssh 断开后重连
# COW 会自动使用通过 ssh 命令创建的代理，无需再通过 proxy 选项指定
# 可重复指定多个
#
# 注意这一功能需要系统上已有 ssh 命令，且必须使用 ssh public key authentication
#
# 若指定该选项，COW 将执行以下命令：
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
# COW 总是先验证 IP 是否在 allowedClient 中，若不在其中再通过用户名密码认证
#userPasswd = username:password
#
# 如需指定多个用户名密码，可在下面选项指定的文件中列出，文件中每行内容如下
#   username:password[:port]
# port 为可选项，若指定，则该用户只能从指定端口连接 COW
# 注意：如有重复用户，COW 会报错退出
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
# 检测超时时间使用的网站，最好使用能快速访问的站点
estimateTarget = www.miui.com
#
# 允许建立隧道连接的端口，多个端口用逗号分隔，可重复多次
# 默认总是允许下列服务的端口: ssh, http, https, rsync, imap, pop, jabber, cvs, git, svn
# 如需允许其他端口，请用该选项添加
# 限制隧道连接的端口可以防止将运行 COW 的服务器上只监听本机 ip 的服务暴露给外部
#tunnelAllowedPort = 80, 443
#
# GFW 会使 DNS 解析超时，也可能返回错误的地址，能连接但是读不到任何内容
# 下面两个值改小一点可以加速检测网站是否被墙，但网络情况差时可能误判
#
# 创建连接超时（语法跟 authTimeout 相同）
#dialTimeout = 5s
# 从服务器读超时
#readTimeout = 5s
#
# 基于 client 是否很快关闭连接来检测 SSL 错误，只对 Chrome 有效
# （Chrome 遇到 SSL 错误会直接关闭连接，而不是让用户选择是否继续）
# 可能将可直连网站误判为被墙网站，当 GFW 进行 SSL 中间人攻击时可以考虑使用
#detectSSLErr = false
#
# 修改 stat/blocked/direct 文件路径，如不指定，默认在配置文件所在目录下
# 执行 cow 的用户需要有对 stat 文件所在目录的写权限才能更新 stat 文件
#statFile = <dir to rc file>/stat
blockedFile = /etc/storage/basedomain.txt
#directFile = <dir to rc file>/direct
#
#
COWCON
chmod 777 "/etc/storage/cow_config_script.sh"
	fi

}

initconfig

case $ACTION in
start)
	cow_close
	cow_check
	;;
check)
	cow_check
	;;
stop)
	cow_close
	;;
keep)
	#cow_check
	cow_keep
	;;
*)
	cow_check
	;;
esac

