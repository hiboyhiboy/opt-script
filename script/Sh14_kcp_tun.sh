#!/bin/sh
#copyright by hiboy
source /etc/storage/script/init.sh
kcptun_enable=`nvram get kcptun_enable`
[ -z $kcptun_enable ] && kcptun_enable=0 && nvram set kcptun_enable=0
kcptun_path=`nvram get kcptun_path`
[ -z $kcptun_path ] && kcptun_path="/opt/bin/client_linux_mips" && nvram set kcptun_path=$kcptun_path
if [ "$kcptun_enable" != "0" ] ; then
#nvramshow=`nvram showall | grep '=' | grep ss | awk '{print gensub(/'"'"'/,"'"'"'\"'"'"'\"'"'"'","g",$0);}'| awk '{print gensub(/=/,"='\''",1,$0)"'\'';";}'` && eval $nvramshow
#nvramshow=`nvram showall | grep '=' | grep kcptun | awk '{print gensub(/'"'"'/,"'"'"'\"'"'"'\"'"'"'","g",$0);}'| awk '{print gensub(/=/,"='\''",1,$0)"'\'';";}'` && eval $nvramshow

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
fi
if [ ! -z "$(echo $scriptfilepath | grep -v "/tmp/script/" | grep kcp_tun)" ]  && [ ! -s /tmp/script/_kcp_tun ]; then
	mkdir -p /tmp/script
	{ echo '#!/bin/sh' ; echo $scriptfilepath '"$@"' '&' ; } > /tmp/script/_kcp_tun
	chmod 777 /tmp/script/_kcp_tun
fi

kcptun_restart () {

relock="/var/lock/kcptun_restart.lock"
if [ "$1" = "o" ] ; then
	nvram set kcptun_renum="0"
	[ -f $relock ] && rm -f $relock
	return 0
fi
if [ "$1" = "x" ] ; then
	if [ -f $relock ] ; then
		logger -t "【kcptun】" "多次尝试启动失败，等待【"`cat $relock`"分钟】后自动尝试重新启动"
		exit 0
	fi
	kcptun_renum=${kcptun_renum:-"0"}
	kcptun_renum=`expr $kcptun_renum + 1`
	nvram set kcptun_renum="$kcptun_renum"
	if [ "$kcptun_renum" -gt "2" ] ; then
		I=19
		echo $I > $relock
		logger -t "【kcptun】" "多次尝试启动失败，等待【"`cat $relock`"分钟】后自动尝试重新启动"
		while [ $I -gt 0 ]; do
			I=$(($I - 1))
			echo $I > $relock
			sleep 60
			[ "$(nvram get kcptun_renum)" = "0" ] && exit 0
			[ $I -lt 0 ] && break
		done
		nvram set kcptun_renum="0"
	fi
	[ -f $relock ] && rm -f $relock
fi
nvram set kcptun_status=0
eval "$scriptfilepath &"
exit 0
}

kcptun_get_status () {

A_restart=`nvram get kcptun_status`
B_restart="$kcptun_enable$kcptun_user$kcptun_path$kcptun_parityshard$kcptun_datashard$kcptun_server$kcptun_sport$kcptun_key$kcptun_crypt$kcptun_lport$kcptun_sndwnd$kcptun_rcvwnd$kcptun_mode$kcptun_mtu$kcptun_dscp$(cat /etc/storage/kcptun_script.sh | grep -v '^#' | grep -v "^$")"
B_restart=`echo -n "$B_restart" | md5sum | sed s/[[:space:]]//g | sed s/-//g`
if [ "$A_restart" != "$B_restart" ] ; then
	nvram set kcptun_status=$B_restart
	needed_restart=1
else
	needed_restart=0
fi
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
logger -t "【kcptun】" "守护进程启动"
KCPNUM=$(echo `cat /etc/storage/kcptun_script.sh | grep -v "^#" | grep "KCPNUM=" | sed 's/KCPNUM=//'`)
if [ -s /tmp/script/_opt_script_check ]; then
sed -Ei '/【kcptun】|^$/d' /tmp/script/_opt_script_check
cat >> "/tmp/script/_opt_script_check" <<-OSC
	NUM=\`grep "$kcptun_path" /tmp/ps | grep -v grep |wc -l\` # 【kcptun】
	if [ "\$NUM" -lt "$KCPNUM" ] || [ "\$NUM" -gt "$KCPNUM" ] || [ ! -s "$kcptun_path" ] ; then # 【kcptun】
		logger -t "【kcptun】" "重新启动\$NUM" # 【kcptun】
		nvram set kcptun_status=00 && eval "$scriptfilepath &" && sed -Ei '/【kcptun】|^$/d' /tmp/script/_opt_script_check # 【kcptun】
	fi # 【kcptun】
OSC
return
fi

while true; do
	NUM=`ps -w | grep "$kcptun_path" | grep -v grep |wc -l`
	if [ "$NUM" -lt "$KCPNUM" ] || [ "$NUM" -gt "$KCPNUM" ] || [ ! -s "$kcptun_path" ] ; then
		logger -t "【kcptun】" "重新启动$NUM"
		kcptun_restart
	fi
sleep 214
done
}

kcptun_close () {

sed -Ei '/【kcptun】|^$/d' /tmp/script/_opt_script_check
[ ! -z "$kcptun_path" ] && kill_ps "$kcptun_path"
killall client_linux_mips kcptun_script.sh sh_kcpkeep.sh
killall -9 client_linux_mips kcptun_script.sh sh_kcpkeep.sh
kill_ps "/tmp/script/_kcp_tun"
kill_ps "_kcp_tun.sh"
kill_ps "$scriptname"
}

kcptun_start () {

SVC_PATH="$kcptun_path"
if [ ! -s "$SVC_PATH" ] ; then
	SVC_PATH="/opt/bin/client_linux_mips"
fi
chmod 777 "$SVC_PATH"
[[ "$(client_linux_mips -h | wc -l)" -lt 2 ]] && rm -rf /opt/bin/client_linux_mips
if [ ! -s "$SVC_PATH" ] ; then
	logger -t "【kcptun】" "找不到 $kcptun_path，安装 opt 程序"
	/tmp/script/_mountopt start
fi
if [ ! -s "$SVC_PATH" ] ; then
	logger -t "【kcptun】" "找不到 $SVC_PATH 下载程序"
	wgetcurl.sh /opt/bin/client_linux_mips "$hiboyfile/client_linux_mips" "$hiboyfile2/client_linux_mips"
	chmod 755 "/opt/bin/client_linux_mips"
else
	logger -t "【kcptun】" "找到 $SVC_PATH"
fi
if [ ! -s "$SVC_PATH" ] ; then
	logger -t "【kcptun】" "找不到 $SVC_PATH ，需要手动安装 $SVC_PATH"
	logger -t "【kcptun】" "启动失败, 10 秒后自动尝试重新启动" && sleep 10 && kcptun_restart x
fi
if [ -s "$SVC_PATH" ] ; then
	nvram set kcptun_path="$SVC_PATH"
fi
chmod 777 "$SVC_PATH"
kcptun_path="$SVC_PATH"
kcptun_v=`$SVC_PATH -v | awk '{print $3}'`
nvram set kcptun_v=$kcptun_v
logger -t "【kcptun】" "kcptun-version: $kcptun_v"
logger -t "【kcptun】" "运行 kcptun_script"

resolveip=`/usr/bin/resolveip -4 -t 4 $kcptun_server | grep -v : | sed -n '1p'`
[ -z "$resolveip" ] && resolveip=`arNslookup $kcptun_server | sed -n '1p'` 
kcptun_s_server=$resolveip
[ -z "$kcptun_s_server" ] && logger -t "【kcptun】" "[错误!!] 实在找不到你的 kcptun 服务器IP，麻烦看看哪里错了？10 秒后自动尝试重新启动" && sleep 10 && kcptun_restart x

sed -Ei '/UI设置自动生成/d' /etc/storage/kcptun_script.sh
sed -Ei '/^$/d' /etc/storage/kcptun_script.sh


# 自动生成客户端启动命令

cat >> "/etc/storage/kcptun_script.sh" <<-EUI
# UI设置自动生成  客户端启动参数
$SVC_PATH $kcptun_user -r "$kcptun_s_server:$kcptun_sport" -l ":$kcptun_lport" -key $kcptun_key -mtu $kcptun_mtu -sndwnd $kcptun_sndwnd -rcvwnd $kcptun_rcvwnd -crypt $kcptun_crypt -mode $kcptun_mode -dscp $kcptun_dscp -datashard $kcptun_datashard -parityshard $kcptun_parityshard -autoexpire $kcptun_autoexpire -nocomp & #UI设置自动生成
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
restart_dhcpd
sleep 2
[ ! -z "$(ps -w | grep "$kcptun_path" | grep -v grep )" ] && logger -t "【kcptun】" "启动成功" && kcptun_restart o
[ -z "$(ps -w | grep "$kcptun_path" | grep -v grep )" ] && logger -t "【kcptun】" "启动失败, 注意检查端口是否有冲突,程序是否下载完整,10 秒后自动尝试重新启动" && sleep 10 && kcptun_restart x
initopt
kcptun_get_status
eval "$scriptfilepath keep &"
}

arNslookup() {
mkdir -p /tmp/arNslookup
nslookup $1 | tail -n +3 | grep "Address" | awk '{print $3}'| grep -v ":" > /tmp/arNslookup/$$ &
I=5
while [ ! -s /tmp/arNslookup/$$ ] ; do
		I=$(($I - 1))
		[ $I -lt 0 ] && break
		sleep 1
done
if [ -s /tmp/arNslookup/$$ ] ; then
cat /tmp/arNslookup/$$ | sort -u | grep -v "^$"
rm -f /tmp/arNslookup/$$
else
	curltest=`which curl`
	if [ -z "$curltest" ] || [ ! -s "`which curl`" ] ; then
		Address="`wget --no-check-certificate --quiet --output-document=- http://119.29.29.29/d?dn=$1`"
		if [ $? -eq 0 ]; then
		echo "$Address" |  sed s/\;/"\n"/g | grep -E -o '([0-9]+\.){3}[0-9]+'
		fi
	else
		Address="`curl -k http://119.29.29.29/d?dn=$1`"
		if [ $? -eq 0 ]; then
		echo "$Address" |  sed s/\;/"\n"/g | grep -E -o '([0-9]+\.){3}[0-9]+'
		fi
	fi
fi
}

initopt () {
optPath=`grep ' /opt ' /proc/mounts | grep tmpfs`
[ ! -z "$optPath" ] && return
if [ ! -z "$(echo $scriptfilepath | grep -v "/opt/etc/init")" ] && [ -s "/opt/etc/init.d/rc.func" ] ; then
	{ echo '#!/bin/sh' ; echo $scriptfilepath '"$@"' '&' ; } > /opt/etc/init.d/$scriptname && chmod 777  /opt/etc/init.d/$scriptname
fi

}

initconfig () {

kcptun_script="/etc/storage/kcptun_script.sh"
if [ ! -f "$kcptun_script" ] || [ ! -s "$kcptun_script" ] ; then
	cat > "$kcptun_script" <<-\EEE
#!/bin/sh
export PATH='/etc/storage/bin:/tmp/script:/etc/storage/script:/opt/usr/sbin:/opt/usr/bin:/opt/sbin:/opt/bin:/usr/local/sbin:/usr/sbin:/usr/bin:/sbin:/bin'
export LD_LIBRARY_PATH=/lib:/opt/lib
# Kcptun 项目地址：https://github.com/xtaci/kcptun
# 参数填写教程例子：https://github.com/xtaci/kcptun
# Kcptun Server一键安装脚本:https://blog.kuoruan.com/110.html
# kcptun服务端部署教程
# https://blog.kuoruan.com/102.html
# http://www.cmsky.com/kcptun/
# kcptun服务端主程序下载：
# 32位系统：wget --no-check-certificate http://opt.cn2qq.com/opt-file/server_linux_386 && chmod 755 server_linux_*
# 64位系统：wget --no-check-certificate http://opt.cn2qq.com/opt-file/server_linux_amd64 && chmod 755 server_linux_*
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
killall client_linux_mips
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
	[ "$kcptun_enable" != "1" ] && [ -f "$kcptun_path" ] && nvram set kcptun_v="" && logger -t "【kcptun】" "更新" && rm -rf $kcptun_path
	;;
*)
	kcptun_check
	;;
esac

