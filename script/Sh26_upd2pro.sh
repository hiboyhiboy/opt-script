#!/bin/sh
#copyright by hiboy
source /etc/storage/script/init.sh

upd2pro_enable=`nvram get app_8`
[ -z $upd2pro_enable ] && upd2pro_enable=0 && nvram set app_8=0
upd2pro2_enable=`nvram get app_9`
[ -z $upd2pro2_enable ] && upd2pro2_enable=0 && nvram set app_9=0
upd2pro3_enable=`nvram get app_18`
[ -z $upd2pro3_enable ] && upd2pro3_enable=0 && nvram set app_18=0
if [ "$upd2pro_enable" != "0" ] || [ "$upd2pro2_enable" != "0" ] || [ "$upd2pro3_enable" != "0" ] ; then
#nvramshow=`nvram showall | grep '=' | grep upd2pro | awk '{print gensub(/'"'"'/,"'"'"'\"'"'"'\"'"'"'","g",$0);}'| awk '{print gensub(/=/,"='\''",1,$0)"'\'';";}'` && eval $nvramshow
upd2pro_enable=`nvram get app_8`
[ -z $upd2pro_enable ] && upd2pro_enable=0 && nvram set app_8=0
upd2pro2_enable=`nvram get app_9`
[ -z $upd2pro2_enable ] && upd2pro2_enable=0 && nvram set app_9=0
upd2pro3_enable=`nvram get app_18`
[ -z $upd2pro3_enable ] && upd2pro3_enable=0 && nvram set app_18=0
fi
upd2pro_path="/etc/storage/app_3.sh"
upd2pro2_path="/etc/storage/app_4.sh"
upd2pro3_path="/etc/storage/app_6.sh"

if [ ! -z "$(echo $scriptfilepath | grep -v "/tmp/script/" | grep upd2pro)" ] && [ ! -s /tmp/script/_app3 ] ; then
	mkdir -p /tmp/script
	{ echo '#!/bin/sh' ; echo $scriptfilepath '"$@"' '&' ; } > /tmp/script/_app3
	chmod 777 /tmp/script/_app3
fi

upd2pro_restart () {

upd2pro_renum=`nvram get upd2pro_renum`
relock="/var/lock/upd2pro_restart.lock"
if [ "$1" = "o" ] ; then
	nvram set upd2pro_renum="0"
	[ -f $relock ] && rm -f $relock
	return 0
fi
if [ "$1" = "x" ] ; then
	if [ -f $relock ] ; then
		logger -t "【upd2pro】" "多次尝试启动失败，等待【"`cat $relock`"分钟】后自动尝试重新启动"
		exit 0
	fi
	upd2pro_renum=${upd2pro_renum:-"0"}
	upd2pro_renum=`expr $upd2pro_renum + 1`
	nvram set upd2pro_renum="$upd2pro_renum"
	if [ "$upd2pro_renum" -gt "2" ] ; then
		I=19
		echo $I > $relock
		logger -t "【upd2pro】" "多次尝试启动失败，等待【"`cat $relock`"分钟】后自动尝试重新启动"
		while [ $I -gt 0 ]; do
			I=$(($I - 1))
			echo $I > $relock
			sleep 60
			[ "$(nvram get upd2pro_renum)" = "0" ] && exit 0
			[ $I -lt 0 ] && break
		done
		nvram set upd2pro_renum="0"
	fi
	[ -f $relock ] && rm -f $relock
fi
nvram set upd2pro_status=0
eval "$scriptfilepath &"
exit 0
}

upd2pro_get_status () {

#lan_ipaddr=`nvram get lan_ipaddr`
A_restart=`nvram get upd2pro_status`
B_restart="$upd2pro_enable$upd2pro2_enable$upd2pro3_enable$upd2pro_path$upd2pro2_path$upd2pro3_path$(cat /etc/storage/app_3.sh /etc/storage/app_4.sh /etc/storage/app_6.sh | grep -v '^#' | grep -v "^$")"
B_restart=`echo -n "$B_restart" | md5sum | sed s/[[:space:]]//g | sed s/-//g`
if [ "$A_restart" != "$B_restart" ] ; then
	nvram set upd2pro_status=$B_restart
	needed_restart=1
else
	needed_restart=0
fi
}

upd2pro_check () {

upd2pro_get_status
if  [ "$needed_restart" = "1" ] ; then
	[ "$upd2pro_enable" != "1" ] && [ ! -z "$(ps -w | grep "/opt/bin/udp2raw" | grep -v grep )" ] && logger -t "【upd2pro】" "停止 udp2raw" && upd2pro_close
	[ "$upd2pro2_enable" != "1" ] && [ ! -z "$(ps -w | grep "/opt/bin/speeder" | grep -v grep )" ] && logger -t "【upd2pro】" "停止 speeder" && upd2pro_close
	[ "$upd2pro3_enable" != "1" ] && [ ! -z "$(ps -w | grep "/opt/bin/speederv2" | grep -v grep )" ] && logger -t "【upd2pro】" "停止 speederv2" && upd2pro_close
	[ "$upd2pro_enable" != "1" ] && [ "$upd2pro2_enable" != "1" ] && [ "$upd2pro3_enable" != "1" ] && { kill_ps "$scriptname" exit0; exit 0; }
fi
if [ "$upd2pro_enable" = "1" ] || [ "$upd2pro2_enable" = "1" ] || [ "$upd2pro3_enable" = "1" ] ; then
	if [ "$needed_restart" = "1" ] ; then
		upd2pro_close
		upd2pro_start
	else
		[ "$upd2pro_enable" = "1" ] && [ -z "$(ps -w | grep "/opt/bin/udp2raw" | grep -v grep )" ] && upd2pro_restart
		[ "$upd2pro2_enable" = "1" ] && [ -z "$(ps -w | grep "/opt/bin/speeder" | grep -v grep )" ] && upd2pro_restart
		[ "$upd2pro3_enable" = "1" ] && [ -z "$(ps -w | grep "/opt/bin/speederv2" | grep -v grep )" ] && upd2pro_restart
	fi
fi
}

upd2pro_keep () {
logger -t "【upd2pro】" "守护进程启动"
if [ "$upd2pro_enable" = "1" ] && [ -s /tmp/script/_opt_script_check ]; then
sed -Ei '/【upd2pro】|^$/d' /tmp/script/_opt_script_check
cat >> "/tmp/script/_opt_script_check" <<-OSC
	NUM=\`grep "/opt/bin/udp2raw" /tmp/ps | grep -v grep |wc -l\` # 【upd2pro】
	if [ "\$NUM" -lt "1" ] || [ ! -s "/opt/bin/udp2raw" ] ; then # 【upd2pro】
		logger -t "【upd2pro】" "重新启动 udp2raw \$NUM" # 【upd2pro】
		nvram set upd2pro_status=00 && eval "$scriptfilepath &" && sed -Ei '/【upd2pro】|^$/d' /tmp/script/_opt_script_check # 【upd2pro】
	fi # 【upd2pro】
OSC
#return
fi
if [ "$upd2pro2_enable" = "1" ] && [ -s /tmp/script/_opt_script_check ]; then
sed -Ei '/【upd2pro】|^$/d' /tmp/script/_opt_script_check
cat >> "/tmp/script/_opt_script_check" <<-OSC
	NUM=\`grep "/opt/bin/speeder" /tmp/ps | grep -v grep |wc -l\` # 【upd2pro】
	if [ "\$NUM" -lt "1" ] || [ ! -s "/opt/bin/speeder" ] ; then # 【upd2pro】
		logger -t "【upd2pro】" "重新启动 speeder \$NUM" # 【upd2pro】
		nvram set upd2pro_status=00 && eval "$scriptfilepath &" && sed -Ei '/【upd2pro】|^$/d' /tmp/script/_opt_script_check # 【upd2pro】
	fi # 【upd2pro】
OSC
#return
fi
if [ "$upd2pro3_enable" = "1" ] && [ -s /tmp/script/_opt_script_check ]; then
sed -Ei '/【upd2pro】|^$/d' /tmp/script/_opt_script_check
cat >> "/tmp/script/_opt_script_check" <<-OSC
	NUM=\`grep "/opt/bin/speederv2" /tmp/ps | grep -v grep |wc -l\` # 【upd2pro】
	if [ "\$NUM" -lt "1" ] || [ ! -s "/opt/bin/speederv2" ] ; then # 【upd2pro】
		logger -t "【upd2pro】" "重新启动 speederv2 \$NUM" # 【upd2pro】
		nvram set upd2pro_status=00 && eval "$scriptfilepath &" && sed -Ei '/【upd2pro】|^$/d' /tmp/script/_opt_script_check # 【upd2pro】
	fi # 【upd2pro】
OSC
#return
fi


upd2pro_enable=`nvram get app_8` #upd2pro_enable
upd2pro2_enable=`nvram get app_9` #upd2pro2_enable
upd2pro3_enable=`nvram get app_18` #upd2pro3_enable
while [ "$upd2pro_enable" = "1" ] || [ "$upd2pro2_enable" = "1" ] || [ "$upd2pro3_enable" = "1" ]; do
if [ "$upd2pro_enable" = "1" ] ; then
	NUM=`ps -w | grep "/opt/bin/udp2raw" | grep -v grep |wc -l`
	if [ "$NUM" -lt "1" ] || [ ! -s "/opt/bin/udp2raw" ] ; then
		logger -t "【upd2pro】" "重新启动 udp2raw $NUM"
		upd2pro_restart
	fi
fi
if [ "$upd2pro2_enable" = "1" ] ; then
	NUM=`ps -w | grep "/opt/bin/speeder" | grep -v grep |wc -l`
	if [ "$NUM" -lt "1" ] || [ ! -s "/opt/bin/speeder" ] ; then
		logger -t "【upd2pro】" "重新启动 speeder $NUM"
		upd2pro_restart
	fi
fi
if [ "$upd2pro3_enable" = "1" ] ; then
	NUM=`ps -w | grep "/opt/bin/speederv2" | grep -v grep |wc -l`
	if [ "$NUM" -lt "1" ] || [ ! -s "/opt/bin/speederv2" ] ; then
		logger -t "【upd2pro】" "重新启动 speederv2 $NUM"
		upd2pro_restart
	fi
fi
sleep 69
upd2pro_enable=`nvram get app_8` #upd2pro_enable
upd2pro2_enable=`nvram get app_9` #upd2pro_enable
upd2pro3_enable=`nvram get app_18` #upd2pro3_enable
done
}

upd2pro_close () {
sed -Ei '/【upd2pro】|^$/d' /tmp/script/_opt_script_check
# restart_dhcpd
killall app_3.sh app_4.sh udp2raw speeder speederv2
killall -9 app_3.sh app_4.sh udp2raw speeder speederv2
kill_ps " /tmp/script/_app3"
kill_ps "_upd2pro.sh"
kill_ps "$scriptname"
}

upd2pro_start () {

optupd2pro="0"
[ "$upd2pro_enable" = "1" ] && { hash udp2raw 2>/dev/null || optupd2pro="1" ; }
[ "$upd2pro2_enable" = "1" ] && { hash speeder 2>/dev/null || optupd2pro="2" ; }
[ "$upd2pro3_enable" = "1" ] && { hash speederv2 2>/dev/null || optupd2pro="3" ; }
if [ "$optupd2pro" != "0" ] ; then
	# 找不到 udp2raw 、speeder 或 speederv2，安装opt
	logger -t "【SS】" "找不到 udp2raw 、speeder 或 speederv2，挂载opt"
	/tmp/script/_mountopt start
	initopt
fi
optupd2pro="0"
if [ "$upd2pro_enable" = "1" ] ; then
chmod 777 "/opt/bin/udp2raw"
[[ "$(udp2raw -h 2>&1 | wc -l)" -lt 2 ]] && rm -rf /opt/bin/udp2raw
hash udp2raw 2>/dev/null || optupd2pro="1"
if [ "$optupd2pro" = "1" ] ; then
	logger -t "【SS】" "找不到 udp2raw. opt下载程序"
	[ ! -s /opt/bin/udp2raw ] && wgetcurl.sh "/opt/bin/udp2raw" "$hiboyfile/udp2raw" "$hiboyfile2/udp2raw"
hash udp2raw 2>/dev/null || { logger -t "【SS】" "找不到 udp2raw, 请检查系统"; upd2pro_restart x ; }
fi
fi
optupd2pro="0"
if [ "$upd2pro2_enable" = "1" ] ; then
chmod 777 "/opt/bin/speeder"
[[ "$(speeder -h 2>&1 | wc -l)" -lt 2 ]] && rm -rf /opt/bin/speeder
hash speeder 2>/dev/null || optupd2pro="2"
if [ "$optupd2pro" = "2" ] ; then
	logger -t "【SS】" "找不到 speeder. opt下载程序"
	[ ! -s /opt/bin/speeder ] && wgetcurl.sh "/opt/bin/speeder" "$hiboyfile/speeder" "$hiboyfile2/speeder"
hash speeder 2>/dev/null || { logger -t "【SS】" "找不到 speeder, 请检查系统"; upd2pro_restart x ; }
fi
fi
optupd2pro="0"
if [ "$upd2pro3_enable" = "1" ] ; then
chmod 777 "/opt/bin/speederv2"
[[ "$(speederv2 -h 2>&1 | wc -l)" -lt 2 ]] && rm -rf /opt/bin/speederv2
hash speederv2 2>/dev/null || optupd2pro="3"
if [ "$optupd2pro" = "3" ] ; then
	logger -t "【SS】" "找不到 speederv2. opt下载程序"
	[ ! -s /opt/bin/speederv2 ] && wgetcurl.sh "/opt/bin/speederv2" "$hiboyfile/speederv2" "$hiboyfile2/speederv2"
hash speederv2 2>/dev/null || { logger -t "【SS】" "找不到 speederv2, 请检查系统"; upd2pro_restart x ; }
fi
fi

update_app

if [ "$upd2pro_enable" = "1" ] ; then
upd2pro_v=$(/opt/bin/udp2raw -h | grep version: | awk -F 'version:' '{print $2;}')
nvram set upd2pro_v="$upd2pro_v"
logger -t "【upd2pro】" "运行 $upd2pro_path"
eval $upd2pro_path &
sleep 2
[ ! -z "$(ps -w | grep "/opt/bin/udp2raw" | grep -v grep )" ] && logger -t "【upd2pro】" "启动成功 udp2raw $upd2pro_v " && upd2pro_restart o
[ -z "$(ps -w | grep "/opt/bin/udp2raw" | grep -v grep )" ] && logger -t "【upd2pro】" "启动失败, 注意检查端口是否有冲突,程序是否下载完整,10 秒后自动尝试重新启动" && sleep 10 && upd2pro_restart x
fi

if [ "$upd2pro2_enable" = "1" ] ; then
upd2pro2_v=$(/opt/bin/speeder -h | grep version: | awk -F 'version:' '{print $2;}')
nvram set upd2pro2_v="$upd2pro2_v"
logger -t "【upd2pro】" "运行 $upd2pro2_path"
eval $upd2pro2_path &
sleep 2
[ ! -z "$(ps -w | grep "/opt/bin/speeder" | grep -v grep )" ] && logger -t "【upd2pro】" "启动成功 speeder $upd2pro2_v " && upd2pro_restart o
[ -z "$(ps -w | grep "/opt/bin/speeder" | grep -v grep )" ] && logger -t "【upd2pro】" "启动失败, 注意检查端口是否有冲突,程序是否下载完整,10 秒后自动尝试重新启动" && sleep 10 && upd2pro_restart x
fi

if [ "$upd2pro3_enable" = "1" ] ; then
upd2pro3_v=$(/opt/bin/speederv2 -h | grep version: | awk -F 'version:' '{print $2;}')
nvram set upd2pro3_v="$upd2pro3_v"
logger -t "【upd2pro】" "运行 $upd2pro3_path"
eval $upd2pro3_path &
sleep 2
[ ! -z "$(ps -w | grep "/opt/bin/speederv2" | grep -v grep )" ] && logger -t "【upd2pro】" "启动成功 speederv2 $upd2pro3_v " && upd2pro_restart o
[ -z "$(ps -w | grep "/opt/bin/speederv2" | grep -v grep )" ] && logger -t "【upd2pro】" "启动失败, 注意检查端口是否有冲突,程序是否下载完整,10 秒后自动尝试重新启动" && sleep 10 && upd2pro_restart x
fi
upd2pro_get_status
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

if [ ! -f "/etc/storage/app_3.sh" ] || [ ! -s "/etc/storage/app_3.sh" ] ; then
	cat >> "/etc/storage/app_3.sh" <<-\EOF
#!/bin/sh
# 中文教程：https://github.com/wangyu-/udp2raw-tunnel/blob/master/doc/README.zh-cn.md
# udp2raw+kcptun step_by_step教程：
# https://github.com/wangyu-/udp2raw-tunnel/blob/master/doc/kcptun_step_by_step.md
# udp2raw+finalspeed step_by_step教程：
# https://github.com/wangyu-/udp2raw-tunnel/blob/master/doc/finalspeed_step_by_step.md
# 如果你需要加速跨国网游、网页浏览，解决方案在另一个程序：UDPspeeder
# 请手动配置【外部网络 - 端口转发 - 启用手动端口映射】来开启WAN访问
logger -t "【upd2pro】" "运行 udp2raw" ; killall udp2raw ;
/opt/bin/udp2raw -c -l0.0.0.0:3333  -r44.55.66.77:4096 -a -k "passwd" --raw-mode faketcp &


EOF
fi

if [ ! -f "/etc/storage/app_4.sh" ] || [ ! -s "/etc/storage/app_4.sh" ] ; then
	cat >> "/etc/storage/app_4.sh" <<-\EOF
#!/bin/sh
# 中文教程：https://github.com/wangyu-/UDPspeeder/blob/master/doc/README.zh-cn.v1.md
# 请手动配置【外部网络 - 端口转发 - 启用手动端口映射】来开启WAN访问
logger -t "【upd2pro】" "运行 speeder" ; killall speeder ;
/opt/bin/speeder -l0.0.0.0:3333 -r 44.55.66.77:8855 -c  -d2 -k "passwd" &

EOF
fi

if [ ! -f "/etc/storage/app_6.sh" ] || [ ! -s "/etc/storage/app_6.sh" ] ; then
	cat >> "/etc/storage/app_6.sh" <<-\EOF
#!/bin/sh
# 中文教程：https://github.com/wangyu-/UDPspeeder
# 请手动配置【外部网络 - 端口转发 - 启用手动端口映射】来开启WAN访问
logger -t "【upd2pro】" "运行 speederv2" ; killall speederv2 ;
/opt/bin/speederv2 -c -l0.0.0.0:3333 -r44.55.66.77:4096 -f20:10 -k "passwd" --mode 0 &

EOF
fi
chmod 777 /etc/storage/app_3.sh /etc/storage/app_4.sh /etc/storage/app_6.sh

}

initconfig

update_app () {
if [ "$1" = "del1" ] ; then
	rm -rf /etc/storage/app_3.sh /opt/bin/udp2raw /opt/app/upd2pro/Advanced_Extensions_upd2pro.asp
fi
if [ "$1" = "del2" ] ; then
	rm -rf /etc/storage/app_4.sh /opt/bin/speeder /opt/app/upd2pro/Advanced_Extensions_upd2pro.asp
fi
if [ "$1" = "del3" ] ; then
	rm -rf /etc/storage/app_6.sh /opt/bin/speederv2 /opt/app/upd2pro/Advanced_Extensions_upd2pro.asp
fi

initconfig

mkdir -p /opt/app/upd2pro
# 加载程序配置页面
if [ ! -f "/opt/app/upd2pro/Advanced_Extensions_upd2pro.asp" ] || [ ! -s "/opt/app/upd2pro/Advanced_Extensions_upd2pro.asp" ] ; then
	wgetcurl.sh /opt/app/upd2pro/Advanced_Extensions_upd2pro.asp "$hiboyfile/Advanced_Extensions_upd2proasp" "$hiboyfile2/Advanced_Extensions_upd2proasp"
fi
umount /www/Advanced_Extensions_app03.asp
mount --bind /opt/app/upd2pro/Advanced_Extensions_upd2pro.asp /www/Advanced_Extensions_app03.asp
# 更新程序启动脚本

[ "$1" = "del1" ] || [ "$1" = "del2" ] || [ "$1" = "del3" ] && /etc/storage/www_sh/upd2pro del &
}

case $ACTION in
start)
	upd2pro_close
	upd2pro_check
	;;
check)
	upd2pro_check
	;;
stop)
	upd2pro_close
	;;
keep)
	#upd2pro_check
	upd2pro_keep
	;;
updateapp3)
	upd2pro_restart o
	[ "$upd2pro_enable" = "1" ] && nvram set upd2pro_status="updateupd2pro" && logger -t "【upd2pro】" "重启 udp2raw" && upd2pro_restart
	[ "$upd2pro_enable" != "1" ] && nvram set upd2pro_v="" && logger -t "【upd2pro】" "更新 udp2raw" && update_app del1
	;;
updateapp_3)
	upd2pro_restart o
	[ "$upd2pro2_enable" = "1" ] && nvram set upd2pro_status="updateupd2pro2" && logger -t "【upd2pro】" "重启 speeder" && upd2pro_restart
	[ "$upd2pro2_enable" != "1" ] && nvram set upd2pro2_v="" && logger -t "【upd2pro】" "更新 speeder" && update_app del2
	[ "$upd2pro3_enable" = "1" ] && nvram set upd3pro_status="updateupd3pro2" && logger -t "【upd2pro】" "重启 speederv2" && upd2pro_restart
	[ "$upd2pro3_enable" != "1" ] && nvram set upd2pro3_v="" && logger -t "【upd2pro】" "更新 speederv2" && update_app del3
	;;
update_app)
	update_app
	;;
*)
	upd2pro_check
	;;
esac

