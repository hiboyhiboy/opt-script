#!/bin/bash
#copyright by hiboy
source /etc/storage/script/init.sh
online=""
orayslstatus=""
SN=""
STATUS=""
szUID=""
phddns=`nvram get phddns`
[ -z $phddns ] && phddns=0 && nvram set phddns=0
phddns_renum=`nvram get phddns_renum`
phddns_renum=${phddns_renum:-"0"}
cmd_log_enable=`nvram get cmd_log_enable`
cmd_name="花生壳内网版"
cmd_log=" >/dev/null 2>/dev/null "
if [ "$cmd_log_enable" = "1" ] || [ "$phddns_renum" -gt "0" ] ; then
	cmd_log="$cmd_log2"
fi
if [ ! -z "$(echo $scriptfilepath | grep -v "/tmp/script/" | grep orayd)" ] && [ ! -s /tmp/script/_orayd ] ; then
	mkdir -p /tmp/script
	{ echo '#!/bin/bash' ; echo $scriptfilepath '"$@"' '&' ; } > /tmp/script/_orayd
	chmod 777 /tmp/script/_orayd
fi

phddns_restart () {
i_app_restart "$@" -name="phddns"
}

phddns_check () {
if [ "$phddns" != "1" ] ; then
	[ ! -z "`pidof oraysl`" ] && logger -t "【花生壳内网版】" "停止 oraysl" && phddns_close
	{ kill_ps "$scriptname" exit0; exit 0; }
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
szUID=`cat /etc/storage/PhMain.ini | grep "szUID=" | awk -F '=' '{print $2}'`;
online=$(echo "$orayslstatus" | grep "ONLINE" | wc -l);
}


phddns_keep () {
sleep 25
i_app_keep -name="phddns" -pidof="oraysl" &
i_app_keep -name="phddns" -pidof="oraynewph" &
SVC_PATH="$(which oraysl)"
[ ! -s "$SVC_PATH" ] && SVC_PATH="/opt/bin/oraysl"
SVC_PATH2="$(which oraynewph)"
[ ! -s "$SVC_PATH2" ] && SVC_PATH2="/opt/bin/oraynewph"

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
szUID=`cat /etc/storage/PhMain.ini | grep "szUID=" | awk -F '=' '{print $2}'`;
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
	sleep 33
	onlinetest
	logger -t "【花生壳内网版】" "$online"
done
logger -t "【花生壳内网版】" "ONLINE"
nvram set phddns_sn="$SN"
nvram set phddns_st="$STATUS"
nvram set phddns_szUID="$szUID"
re_phddns=1
while true; do
	onlinetest
	if [ $online -le 0 ] ; then
		re_phddns=`expr $re_phddns + 1`
	fi
	if [ "$re_phddns" -ge 4 ] ; then
		re_phddns=1
		logger -t "【花生壳内网版】" "网络状态:【$orayslstatus 】，重新启动($NUM , $NUM2 , $online)"
		killall oraynewph oraysl
				phddns_restart
	fi
	sleep 66
done
}

phddns_close () {
kill_ps "$scriptname keep"
killall oraynewph oraysl
nvram set phddns_st=""
kill_ps "/tmp/script/_orayd"
kill_ps "_orayd.sh"
kill_ps "$scriptname"
}

phddns_start () {
check_webui_yes
i_app_get_cmd_file -name="phddns" -cmd="oraysl" -cpath="/opt/bin/oraysl" -down1="$hiboyfile/oraysl" -down2="$hiboyfile2/oraysl"
i_app_get_cmd_file -name="phddns" -cmd="oraynewph" -cpath="/opt/bin/oraynewph" -down1="$hiboyfile/oraynewph" -down2="$hiboyfile2/oraynewph" -runh="x"
logger -t "【花生壳内网版】" "运行 oraysl"
ln -sf "/etc/storage/PhMain.ini" "/etc/PhMain.ini"
ln -sf "/etc/storage/init.status" "/etc/init.status"
cmd_name="花生壳内网版oraynewph"
eval "oraynewph -s 0.0.0.0 $cmd_log" &
cmd_name="花生壳内网版oraysl"
eval "oraysl -a 127.0.0.1 -p 16062 -s phsle01.oray.net:6061 -d $cmd_log" &
sleep 4
i_app_keep -t -name="phddns" -pidof="oraysl"

eval "$scriptfilepath keep &"
exit 0
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
	#phddns_check
	phddns_keep
	;;
*)
	phddns_check
	;;
esac

