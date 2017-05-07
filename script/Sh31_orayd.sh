#!/bin/sh
#copyright by hiboy
source /etc/storage/script/init.sh
#nvramshow=`nvram showall | grep phddns | awk '{print gensub(/'"'"'/,"'"'"'\"'"'"'\"'"'"'","g",$0);}'| awk '{print gensub(/=/,"='\''",1,$0)"'\'';";}'` && eval $nvramshow
phddns=`nvram get phddns`

online=""
orayslstatus=""
SN=""
STATUS=""
szUID=""

[ -z $phddns ] && phddns=0 && nvram set phddns=0

if [ ! -z "$(echo $scriptfilepath | grep -v "/tmp/script/" | grep orayd)" ]  && [ ! -s /tmp/script/_orayd ]; then
	mkdir -p /tmp/script
	ln -sf $scriptfilepath /tmp/script/_orayd
	chmod 777 /tmp/script/_orayd
fi

phddns_check () {
if [ "$phddns" != "1" ] ; then
	[ ! -z "`pidof oraysl`" ] && logger -t "【花生壳内网版】" "停止 oraysl" && phddns_close
	{ eval $(ps -w | grep "$scriptname" | grep -v grep | awk '{print "kill "$1";";}'); exit 0; }
fi
if [ "$phddns" = "1" ] ; then
	if [ -z "`pidof oraysl`" ] || [ ! -s "`which oraysl`" ] ; then
		phddns_close
		phddns_start
	fi
fi
}

onlinetest () {
USER_DATA="/tmp/oraysl.status"
orayslstatus=`head -n 3 $USER_DATA`
SN=`head -n 2 $USER_DATA  | tail -n 1 | cut -d= -f2-`;
STATUS=`head -n 3 $USER_DATA  | tail -n 1 | cut -d= -f2-`;
szUID=`sed -n 's/.*szUID=*/\1/p' /etc/storage/PhMain.ini`;
online=$(echo $orayslstatus | grep "ONLINE" | wc -l);
}


phddns_keep () {
logger -t "【花生壳内网版】" "守护进程启动"
sleep 25
USER_DATA="/tmp/oraysl.status"

SN=`head -n 2 $USER_DATA  | tail -n 1 | cut -d= -f2-`;
STATUS=`head -n 3 $USER_DATA  | tail -n 1 | cut -d= -f2-`;

echo  "RUNSTATUS= $STATUS"
echo  "SN= $SN"
echo  "LoginAddress= http://b.oray.com/"
logger -t "【花生壳内网版】" "RUNSTATUS= $STATUS"
logger -t "【花生壳内网版】" "SN= $SN "
nvram set phddns_sn="$SN"
nvram set phddns_st="$STATUS"
szUID=0
if [ -f /etc/storage/PhMain.ini ] ; then
szUID=`sed -n 's/.*szUID=*/\1/p' /etc/storage/PhMain.ini`
fi
if [ "$szUID" != "0" ] ; then
logger -t "【花生壳内网版】" "已经绑定的花生壳账号:$szUID"
nvram set phddns_szUID="$szUID"
logger -t "【花生壳内网版】" "使用SN账号在【 http://b.oray.com 】登录."
else
logger -t "【花生壳内网版】" "没绑定的花生壳账号，请尽快绑定"
logger -t "【花生壳内网版】" "使用 SN 账号在【 http://b.oray.com 】默认密码是 admin 登录."
logger -t "【花生壳内网版】" "默认密码:admin, 默认密码:admin, 然后进行修改默认密码、手机验证、邮箱验证和花生壳账号绑定"
logger -t "【花生壳内网版】" "!!>>绑定后需【写入】内部存储, 不然重启会丢失绑定.<<!!"
logger -t "【花生壳内网版】" " !>>绑定后需【写入】内部存储, 不然重启会丢失绑定.<<!"
logger -t "【花生壳内网版】" "  !>绑定后需【写入】内部存储, 不然重启会丢失绑定.<!"
logger -t "【花生壳内网版】" "系统管理 - 恢复/导出/上传设置 - 路由器内部存储 /etc/storage - 【提交】"
fi

onlinetest
while [ $online -le 0 ]; do
	sleep 66
	onlinetest
	logger -t "【花生壳内网版】" "$online"
done
logger -t "【花生壳内网版】" "ONLINE"
nvram set phddns_sn="$SN"
nvram set phddns_st="$STATUS"
nvram set phddns_szUID="$szUID"
while true; do
	onlinetest
	NUM=`ps -w | grep "oraynewph -s 0.0.0.0" | grep -v grep |wc -l`
	NUM2=`ps -w | grep "oraysl -a 127.0.0.1" | grep -v grep |wc -l`
	if [ "$NUM" -lt "1" ] || [ "$NUM2" -lt "1" ] || [ $online -le 0 ] || [ ! -s "/usr/bin/oraysl" ] ; then
		logger -t "【花生壳内网版】" "网络状态:【$orayslstatus 】，重新启动($NUM , $NUM)"
		{ eval "$scriptfilepath &" ; exit 0; }
	fi
	
sleep 231
done
}

phddns_close () {
killall oraynewph oraysl
killall -9 oraynewph oraysl
eval $(ps -w | grep "_orayd keep" | grep -v grep | awk '{print "kill "$1";";}')
eval $(ps -w | grep "_orayd.sh keep" | grep -v grep | awk '{print "kill "$1";";}')
eval $(ps -w | grep "$scriptname keep" | grep -v grep | awk '{print "kill "$1";";}')
}

phddns_start () {

SVC_PATH="/usr/bin/oraysl"
SVC_PATH2="/usr/bin/oraynewph"
if [ ! -s "$SVC_PATH" ] || [ ! -s "$SVC_PATH2" ] ; then
SVC_PATH="/opt/bin/oraysl"
SVC_PATH2="/opt/bin/oraynewph"
fi
hash oraysl 2>/dev/null || rm -rf /opt/bin/oraysl
hash oraynewph 2>/dev/null || rm -rf /opt/bin/oraynewph
if [ ! -s "$SVC_PATH" ] ; then
	logger -t "【花生壳内网版】" "找不到 $SVC_PATH，安装 opt 程序"
	/tmp/script/_mountopt start
	initopt
fi
if [ ! -s "$SVC_PATH" ] || [ ! -s "$SVC_PATH2" ] ; then
	[ ! -s "$SVC_PATH" ] && logger -t "【花生壳内网版】" "找不到 $SVC_PATH 下载程序"
	[ ! -s "$SVC_PATH2" ] && logger -t "【花生壳内网版】" "找不到 $SVC_PATH2 下载程序"
	wgetcurl.sh /opt/bin/oraysl "$hiboyfile/phddns2/bin/oraysl" "$hiboyfile2/phddns2/bin/oraysl"
	wgetcurl.sh /opt/bin/oraynewph "$hiboyfile/phddns2/bin/oraynewph" "$hiboyfile2/phddns2/bin/oraynewph"
	chmod 755 /opt/bin/oraysl /opt/bin/oraynewph
else
	logger -t "【花生壳内网版】" "找到 $SVC_PATH"
fi
if [ ! -s "$SVC_PATH" ] || [ ! -s "$SVC_PATH2" ] ; then
	[ ! -s "$SVC_PATH" ] && logger -t "【花生壳内网版】" "找不到 $SVC_PATH ，需要手动安装 $SVC_PATH"
	[ ! -s "$SVC_PATH2" ] && logger -t "【花生壳内网版】" "找不到 $SVC_PATH2 ，需要手动安装 $SVC_PATH2"
	logger -t "【花生壳内网版】" "启动失败, 10 秒后自动尝试重新启动" && sleep 10 && { eval "$scriptfilepath &"; exit 0; }
fi
logger -t "【花生壳内网版】" "运行 oraysl"
ln -sf "/etc/storage/PhMain.ini" "/etc/PhMain.ini"
ln -sf "/etc/storage/init.status" "/etc/init.status"
oraynewph -s 0.0.0.0 >/dev/null 2>/dev/null &
oraysl -a 127.0.0.1 -p 16062 -s phsle01.oray.net:80 -d >/dev/null 2>/dev/null &
sleep 2
[ ! -z "`pidof oraysl`" ] && logger -t "【花生壳内网版】" "启动成功"
[ -z "`pidof oraysl`" ] && logger -t "【花生壳内网版】" "启动失败, 注意检查oraysl、oraynewph是否下载完整,10 秒后自动尝试重新启动" && sleep 10 && { rm -rf /opt/bin/oraysl /opt/bin/oraynewph ; eval "$scriptfilepath &"; exit 0; }

eval "$scriptfilepath keep &"
}

initopt () {
optPath=`grep ' /opt ' /proc/mounts | grep tmpfs`
[ ! -z "$optPath" ] && return
if [ -s "/opt/etc/init.d/rc.func" ] ; then
	cp -Hf "$scriptfilepath" "/opt/etc/init.d/$scriptname"
fi

}

case $ACTION in
start)
	phddns_close
	phddns_check
	;;
check)
	phddns_check
	;;
stop)
	phddns_close
	;;
keep)
	phddns_check
	phddns_keep
	;;
*)
	phddns_check
	;;
esac

