#!/bin/bash
#copyright by hiboy
source /etc/storage/script/init.sh
kcptun_enable=`nvram get kcptun_enable`
[ -z $kcptun_enable ] && kcptun_enable=0 && nvram set kcptun_enable=0
kcptun_path=`nvram get kcptun_path`
[ -z $kcptun_path ] && kcptun_path="$(which kcptun)" && nvram set kcptun_path=$kcptun_path
[ ! -s "$kcptun_path" ] && kcptun_path="/opt/bin/kcptun" && nvram set kcptun_path=$kcptun_path
[ -f "/opt/bin/client_linux_mips" ] && rm -f /opt/bin/client_linux_mips
[ -f "/opt/opt_backup/bin/client_linux_mips" ] && rm -f /opt/opt_backup/bin/client_linux_mips
[ -f "/opt/bin/client_linux_mipsle" ] && rm -f /opt/bin/client_linux_mipsle
[ -f "/opt/opt_backup/bin/client_linux_mipsle" ] && rm -f /opt/opt_backup/bin/client_linux_mipsle
[ "$kcptun_path" == "/opt/bin/client_linux_mips" ] && kcptun_path="/opt/bin/kcptun" && nvram set kcptun_path=$kcptun_path
[ "$kcptun_path" == "/opt/bin/client_linux_mipsle" ] && kcptun_path="/opt/bin/kcptun" && nvram set kcptun_path=$kcptun_path
if [ "$kcptun_enable" != "0" ] ; then

kcptun_sport=`nvram get kcptun_sport`
kcptun_crypt=`nvram get kcptun_crypt`
kcptun_lport=`nvram get kcptun_lport`
kcptun_sndwnd=`nvram get kcptun_sndwnd`
kcptun_rcvwnd=`nvram get kcptun_rcvwnd`
kcptun_mode=`nvram get kcptun_mode`
kcptun_mtu=`nvram get kcptun_mtu`
kcptun_dscp=`nvram get kcptun_dscp`
kcptun_datashard=`nvram get kcptun_datashard`
kcptun_parityshard=`nvram get kcptun_parityshard`
kcptun_autoexpire=`nvram get kcptun_autoexpire`
kcptun_key=`nvram get kcptun_key`
kcptun_server=`nvram get kcptun_server`
kcptun_user=`nvram get kcptun_user`


kcptun_s_server=""
[ -z $kcptun_sport ] && kcptun_sport=29900 && nvram set kcptun_sport=$kcptun_sport
[ -z $kcptun_crypt ] && kcptun_crypt="none" && nvram set kcptun_crypt=$kcptun_crypt
[ -z $kcptun_lport ] && kcptun_lport=8388 && nvram set kcptun_lport=$kcptun_lport
[ -z $kcptun_sndwnd ] && kcptun_sndwnd="1024" && nvram set kcptun_sndwnd=$kcptun_sndwnd
[ -z $kcptun_rcvwnd ] && kcptun_rcvwnd="1024" && nvram set kcptun_rcvwnd=$kcptun_rcvwnd
[ -z $kcptun_mode ] && kcptun_mode="fast" && nvram set kcptun_mode=$kcptun_mode
[ -z $kcptun_mtu ] && kcptun_mtu="1350" && nvram set kcptun_mtu=$kcptun_mtu
[ -z $kcptun_dscp ] && kcptun_dscp=0 && nvram set kcptun_dscp=$kcptun_dscp
[ -z $kcptun_datashard ] && kcptun_datashard=10 && nvram set kcptun_datashard=$kcptun_datashard
[ -z $kcptun_parityshard ] && kcptun_parityshard=3 && nvram set kcptun_parityshard=$kcptun_parityshard
[ -z $kcptun_autoexpire ] && kcptun_autoexpire=0 && nvram set kcptun_autoexpire=$kcptun_autoexpire
kcptun_renum=`nvram get kcptun_renum`
kcptun_renum=${kcptun_renum:-"0"}
cmd_log_enable=`nvram get cmd_log_enable`
cmd_name="kcptun"
cmd_log=""
if [ "$cmd_log_enable" = "1" ] || [ "$kcptun_renum" -gt "0" ] ; then
	cmd_log="$cmd_log2"
fi
fi
if [ ! -z "$(echo $scriptfilepath | grep -v "/tmp/script/" | grep kcp_tun)" ] && [ ! -s /tmp/script/_kcp_tun ] ; then
	mkdir -p /tmp/script
	{ echo '#!/bin/bash' ; echo $scriptfilepath '"$@"' '&' ; } > /tmp/script/_kcp_tun
	chmod 777 /tmp/script/_kcp_tun
fi

kcptun_restart () {
i_app_restart "$@" -name="kcptun"
}

kcptun_get_status () {

B_restart="$kcptun_enable$kcptun_user$kcptun_path$kcptun_parityshard$kcptun_datashard$kcptun_server$kcptun_sport$kcptun_key$kcptun_crypt$kcptun_lport$kcptun_sndwnd$kcptun_rcvwnd$kcptun_mode$kcptun_mtu$kcptun_dscp$(cat /etc/storage/kcptun_script.sh | grep -v '^#' | grep -v '^$')"

i_app_get_status -name="kcptun" -valb="$B_restart"
}

kcptun_check () {

kcptun_get_status
if [ "$kcptun_enable" != "1" ] && [ "$needed_restart" = "1" ] ; then
	[ ! -z "$(ps -w | grep "$kcptun_path" | grep -v grep )" ] && logger -t "【kcptun】" "停止 $kcptun_path" && kcptun_close
	{ kill_ps "$scriptname" exit0; exit 0; }
fi
if [ "$kcptun_enable" = "1" ] ; then
	if [ "$needed_restart" = "1" ] ; then
		kcptun_close
		kcptun_start
	else
		[ -z "$(ps -w | grep "$kcptun_path" | grep -v grep )" ] && kcptun_restart
	fi
fi

}

kcptun_keep () {
i_app_keep -name="kcptun" -pidof="$(basename $kcptun_path)" -cpath="$kcptun_path" &
}

kcptun_close () {

kill_ps "$scriptname keep"
sed -Ei '/【kcptun】|^$/d' /tmp/script/_opt_script_check
[ ! -z "$kcptun_path" ] && kill_ps "$kcptun_path"
killall kcptun kcptun_script.sh sh_kcpkeep.sh
kill_ps "/tmp/script/_kcp_tun"
kill_ps "_kcp_tun.sh"
kill_ps "$scriptname"
}

kcptun_start () {

check_webui_yes
i_app_get_cmd_file -name="ddnsgo" -cmd="$kcptun_path" -cpath="/opt/bin/kcptun" -down1="$hiboyfile/kcptun" -down2="$hiboyfile2/kcptun"
if [ -s "$SVC_PATH" ] ; then
	[ "$(nvram get kcptun_path)" != "$SVC_PATH" ] && nvram set kcptun_path="$SVC_PATH"
	[ "$SVC_PATH" != "/opt/bin/kcptun" ] && ln -sf "$SVC_PATH" /opt/bin/kcptun
	[ "$SVC_PATH" != "/opt/bin/kcptun" ] && [ ! -s /opt/bin/kcptun ] && cp -f "$SVC_PATH" /opt/bin/kcptun
fi
chmod 777 "$SVC_PATH"
kcptun_path="$SVC_PATH"
kcptun_v=`$SVC_PATH -v | awk '{print $3}'`
nvram set kcptun_v=$kcptun_v
logger -t "【kcptun】" "kcptun-version: $kcptun_v"
logger -t "【kcptun】" "运行 kcptun_script"
gid_owner="0"
su_cmd="eval"
NUM=`iptables -m owner -h 2>&1 | grep owner | wc -l`
hash su 2>/dev/null && su_x="1"
hash su 2>/dev/null || su_x="0"
if [ "$NUM" -ge "3" ] && [ "$su_x" = "1" ] ; then
	addgroup -g 1321 ‍✈️
	adduser -G ‍✈️ -u 1321 ‍✈️ -D -S -H -s /bin/false
	sed -Ei s/1321:1321/0:1321/g /etc/passwd
	su_cmd="su ‍✈️ -s /bin/sh -c "
	gid_owner="1321"
fi
nvram set gid_owner="$gid_owner"

if [ -z $(echo $kcptun_server | grep : | grep -v "\.") ] ; then 
resolveip=`ping -4 -n -q -c1 -w1 -W1 $kcptun_server | head -n1 | sed -r 's/\(|\)/|/g' | awk -F'|' '{print $2}'`
[ -z "$resolveip" ] && resolveip=`ping -6 -n -q -c1 -w1 -W1 $kcptun_server | head -n1 | sed -r 's/\(|\)/|/g' | awk -F'|' '{print $2}'`
[ -z "$resolveip" ] && resolveip=`arNslookup $kcptun_server | sed -n '1p'` 
[ -z "$resolveip" ] && resolveip=`arNslookup6 $kcptun_server | sed -n '1p'` 
kcptun_s_server=$resolveip
else
# IPv6
kcptun_s_server=$kcptun_server
fi

[ -z "$kcptun_s_server" ] && logger -t "【kcptun】" "[错误!!] 实在找不到你的 kcptun 服务器IP，麻烦看看哪里错了？10 秒后自动尝试重新启动" && sleep 10 && kcptun_restart x

sed -Ei '/UI设置自动生成/d' /etc/storage/kcptun_script.sh
sed -Ei '/^$/d' /etc/storage/kcptun_script.sh


# 自动生成客户端启动命令

cat >> "/etc/storage/kcptun_script.sh" <<-EUI
# UI设置自动生成  客户端启动参数
eval "$su_cmd" '$SVC_PATH $kcptun_user -r "$kcptun_s_server:$kcptun_sport" -l ":$kcptun_lport" -key $kcptun_key -mtu $kcptun_mtu -sndwnd $kcptun_sndwnd -rcvwnd $kcptun_rcvwnd -crypt $kcptun_crypt -mode $kcptun_mode -dscp $kcptun_dscp -datashard $kcptun_datashard -parityshard $kcptun_parityshard -autoexpire $kcptun_autoexpire -nocomp $cmd_log' & #UI设置自动生成
# UI设置自动生成  默认启用 -nocomp 参数,需在服务端使用此参数来禁止压缩传输
EUI

# 自动生成服务端启动命令

cat >> "/etc/storage/kcptun_script.sh" <<-EUI
# UI设置自动生成 64位系统 服务端启动参数：此参数复制到服务器启动。（服务端请自行下载部署）
#./server_linux_amd64 -t "$kcptun_s_server:$kcptun_lport" -l ":$kcptun_sport" -key $kcptun_key -mtu $kcptun_mtu -sndwnd 2048 -rcvwnd 2048 -crypt $kcptun_crypt -mode $kcptun_mode -dscp $kcptun_dscp -datashard $kcptun_datashard -parityshard $kcptun_parityshard -nocomp & #UI设置自动生成
# UI设置自动生成 32位系统 服务端启动参数：此参数复制到服务器启动。（服务端请自行下载部署）
#./server_linux_386 -t "$kcptun_s_server:$kcptun_lport" -l ":$kcptun_sport" -key $kcptun_key -mtu $kcptun_mtu -sndwnd 2048 -rcvwnd 2048 -crypt $kcptun_crypt -mode $kcptun_mode -dscp $kcptun_dscp -datashard $kcptun_datashard -parityshard $kcptun_parityshard -nocomp & #UI设置自动生成
EUI

/etc/storage/kcptun_script.sh &
restart_on_dhcpd
sleep 4
i_app_keep -t -name="kcptun" -pidof="$(basename $kcptun_path)" -cpath="$kcptun_path"
kcptun_get_status
eval "$scriptfilepath keep &"
exit 0
}

initconfig () {

kcptun_script="/etc/storage/kcptun_script.sh"
if [ ! -f "$kcptun_script" ] || [ ! -s "$kcptun_script" ] ; then
	cat > "$kcptun_script" <<-\EEE
#!/bin/bash
export PATH='/etc/storage/bin:/tmp/script:/etc/storage/script:/opt/usr/sbin:/opt/usr/bin:/opt/sbin:/opt/bin:/usr/local/sbin:/usr/sbin:/usr/bin:/sbin:/bin'
export LD_LIBRARY_PATH=/lib:/opt/lib
# Kcptun 项目地址：https://github.com/xtaci/kcptun
# 参数填写教程例子：https://github.com/xtaci/kcptun
# 注意！！由于路由参数默认加上--nocomp，服务端也要加上--nocomp，在两端同时设定以关闭压缩。
# 两端参数必须一致的有:
# datashard
# parityshard
# nocomp
# key
# crypt
#
################################################################
# Kcptun 客户端配置例子
# 服务器地址（服务器自行购买）:111.111.111.111
# 服务器端口:29900
# 加密方式:none
# 监听端口:8388
# 服务器密码:自定义密码
#
# 备注：由于可用参数太多，不一一举例，其他参数可以参考项目主页的介绍。
#
################################################################
# Shadowsocks 客户端配置例子
# 服务端需要部署ss服务，新建SS服务端口：8388
# 配置路由SS服务器地址：127.0.0.1
# 配置路由SS服务器端口：8388
# 正确填写你刚刚新建SS服务端口、密码、加密方式、协议和混淆方式。
#
# 备注：如果其他设备做 Kcptun 客户端，SS服务器地址填写那个设备的内网地址。
# 
################################################################
# 客户端进程数量（守护脚本判断数据，请正确填写）
KCPNUM=1
killall kcptun
#
################################################################
EEE
	chmod 755 "$kcptun_script"
fi

}

initconfig

case $ACTION in
start)
	kcptun_close
	kcptun_check
	;;
check)
	kcptun_check
	;;
stop)
	kcptun_close
	;;
keep)
	#kcptun_check
	kcptun_keep
	;;
updatekcptun)
	kcptun_restart o
	[ "$kcptun_enable" = "1" ] && nvram set kcptun_status="updatekcptun" && logger -t "【kcptun】" "重启" && kcptun_restart
	[ "$kcptun_enable" != "1" ] && [ -f "$kcptun_path" ] && nvram set kcptun_v="" && logger -t "【kcptun】" "更新" && rm -rf $kcptun_path /opt/opt_backup/bin/kcptun
	;;
*)
	kcptun_check
	;;
esac

