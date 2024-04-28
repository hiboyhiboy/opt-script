#!/bin/bash
#copyright by hiboy
source /etc/storage/script/init.sh

upd2pro_enable=`nvram get app_8`
[ -z $upd2pro_enable ] && upd2pro_enable=0 && nvram set app_8=0
upd2pro2_enable=`nvram get app_9`
[ -z $upd2pro2_enable ] && upd2pro2_enable=0 && nvram set app_9=0
upd2pro3_enable=`nvram get app_18`
[ -z $upd2pro3_enable ] && upd2pro3_enable=0 && nvram set app_18=0
if [ "$upd2pro_enable" != "0" ] || [ "$upd2pro2_enable" != "0" ] || [ "$upd2pro3_enable" != "0" ] ; then
upd2pro_enable=`nvram get app_8`
[ -z $upd2pro_enable ] && upd2pro_enable=0 && nvram set app_8=0
upd2pro2_enable=`nvram get app_9`
[ -z $upd2pro2_enable ] && upd2pro2_enable=0 && nvram set app_9=0
upd2pro3_enable=`nvram get app_18`
[ -z $upd2pro3_enable ] && upd2pro3_enable=0 && nvram set app_18=0
upd2pro_renum=`nvram get upd2pro_renum`
upd2pro_renum=${upd2pro_renum:-"0"}
cmd_log_enable=`nvram get cmd_log_enable`
cmd_name="upd2pro"
cmd_log=""
if [ "$cmd_log_enable" = "1" ] || [ "$upd2pro_renum" -gt "0" ] ; then
	cmd_log="$cmd_log2"
fi
fi
upd2pro_path="/etc/storage/app_3.sh"
upd2pro2_path="/etc/storage/app_4.sh"
upd2pro3_path="/etc/storage/app_6.sh"

if [ ! -z "$(echo $scriptfilepath | grep -v "/tmp/script/" | grep upd2pro)" ] && [ ! -s /tmp/script/_app3 ] ; then
	mkdir -p /tmp/script
	{ echo '#!/bin/bash' ; echo $scriptfilepath '"$@"' '&' ; } > /tmp/script/_app3
	chmod 777 /tmp/script/_app3
fi

upd2pro_restart () {
i_app_restart "$@" -name="upd2pro"
}

upd2pro_get_status () {

B_restart="$upd2pro_enable$upd2pro2_enable$upd2pro3_enable$upd2pro_path$upd2pro2_path$upd2pro3_path$(cat /etc/storage/app_3.sh /etc/storage/app_4.sh /etc/storage/app_6.sh | grep -v '^#' | grep -v '^$')"

i_app_get_status -name="upd2pro" -valb="$B_restart"
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
if [ "$upd2pro_enable" = "1" ] ; then
i_app_keep -name="upd2pro" -pidof="udp2raw" &
fi
if [ "$upd2pro2_enable" = "1" ] ; then
i_app_keep -name="upd2pro" -pidof="speeder" &
fi
if [ "$upd2pro3_enable" = "1" ] ; then
i_app_keep -name="upd2pro" -pidof="speederv2" &
fi
}

upd2pro_close () {
kill_ps "$scriptname keep"
sed -Ei '/【upd2pro】|^$/d' /tmp/script/_opt_script_check
# restart_on_dhcpd
killall app_3.sh app_4.sh udp2raw speeder speederv2
kill_ps " /tmp/script/_app3"
kill_ps "_upd2pro.sh"
kill_ps "$scriptname"
}

upd2pro_start () {

check_webui_yes
if [ "$upd2pro_enable" = "1" ] ; then
	i_app_get_cmd_file -name="upd2pro" -cmd="udp2raw" -cpath="/opt/bin/udp2raw" -down1="$hiboyfile/udp2raw" -down2="$hiboyfile2/udp2raw"
fi
optupd2pro="0"
if [ "$upd2pro2_enable" = "1" ] ; then
	i_app_get_cmd_file -name="upd2pro" -cmd="speeder" -cpath="/opt/bin/speeder" -down1="$hiboyfile/speeder" -down2="$hiboyfile2/speeder"
fi
if [ "$upd2pro3_enable" = "1" ] ; then
	i_app_get_cmd_file -name="upd2pro" -cmd="speederv2" -cpath="/opt/bin/speederv2" -down1="$hiboyfile/speederv2" -down2="$hiboyfile2/speederv2"
fi

update_app

if [ "$upd2pro_enable" = "1" ] ; then
upd2pro_v=$(/opt/bin/udp2raw -h | grep version: | awk -F 'version:' '{print $2;}')
nvram set upd2pro_v="$upd2pro_v"
logger -t "【upd2pro】" "运行 $upd2pro_path"
cmd_name="udp2raw"
eval "$upd2pro_path $cmd_log" &
sleep 4
i_app_keep -t -name="upd2pro" -pidof="udp2raw"
fi

if [ "$upd2pro2_enable" = "1" ] ; then
upd2pro2_v=$(/opt/bin/speeder -h | grep version: | awk -F 'version:' '{print $2;}')
nvram set upd2pro2_v="$upd2pro2_v"
logger -t "【upd2pro】" "运行 $upd2pro2_path"
cmd_name="speeder"
eval "$upd2pro2_path $cmd_log" &
sleep 4
i_app_keep -t -name="upd2pro" -pidof="speeder"
fi

if [ "$upd2pro3_enable" = "1" ] ; then
upd2pro3_v=$(/opt/bin/speederv2 -h | grep version: | awk -F 'version:' '{print $2;}')
nvram set upd2pro3_v="$upd2pro3_v"
logger -t "【upd2pro】" "运行 $upd2pro3_path"
cmd_name="speederv2"
eval "$upd2pro3_path $cmd_log" &
sleep 4
i_app_keep -t -name="upd2pro" -pidof="speederv2"
fi
upd2pro_get_status
eval "$scriptfilepath keep &"
exit 0
}

initconfig () {

if [ ! -f "/etc/storage/app_3.sh" ] || [ ! -s "/etc/storage/app_3.sh" ] ; then
	cat >> "/etc/storage/app_3.sh" <<-\EOF
#!/bin/bash
# 中文教程：https://github.com/wangyu-/udp2raw-tunnel/blob/master/doc/README.zh-cn.md
# udp2raw+kcptun step_by_step教程：
# https://github.com/wangyu-/udp2raw-tunnel/blob/master/doc/kcptun_step_by_step.md
# udp2raw+finalspeed step_by_step教程：
# https://github.com/wangyu-/udp2raw-tunnel/blob/master/doc/finalspeed_step_by_step.md
# 如果你需要加速跨国网游、网页浏览，解决方案在另一个程序：UDPspeeder
# 请手动配置【外部网络 - 端口转发 - 启用手动端口映射】来开启WAN访问
logger -t "【upd2pro】" "运行 udp2raw" ; killall udp2raw ;
/opt/bin/udp2raw -c -l0.0.0.0:3333  -r44.55.66.77:4096 -a -k "passwd" --raw-mode faketcp 2>&1 &


EOF
fi

if [ ! -f "/etc/storage/app_4.sh" ] || [ ! -s "/etc/storage/app_4.sh" ] ; then
	cat >> "/etc/storage/app_4.sh" <<-\EOF
#!/bin/bash
# 中文教程：https://github.com/wangyu-/UDPspeeder/blob/master/doc/README.zh-cn.v1.md
# 请手动配置【外部网络 - 端口转发 - 启用手动端口映射】来开启WAN访问
logger -t "【upd2pro】" "运行 speeder" ; killall speeder ;
/opt/bin/speeder -l0.0.0.0:3333 -r 44.55.66.77:8855 -c  -d2 -k "passwd" 2>&1 &

EOF
fi

if [ ! -f "/etc/storage/app_6.sh" ] || [ ! -s "/etc/storage/app_6.sh" ] ; then
	cat >> "/etc/storage/app_6.sh" <<-\EOF
#!/bin/bash
# 中文教程：https://github.com/wangyu-/UDPspeeder
# 请手动配置【外部网络 - 端口转发 - 启用手动端口映射】来开启WAN访问
logger -t "【upd2pro】" "运行 speederv2" ; killall speederv2 ;
/opt/bin/speederv2 -c -l0.0.0.0:3333 -r44.55.66.77:4096 -f20:10 -k "passwd" --mode 0 2>&1 &

EOF
fi
chmod 777 /etc/storage/app_3.sh /etc/storage/app_4.sh /etc/storage/app_6.sh

}

initconfig

update_app () {
if [ "$1" = "update_asp" ] ; then
	rm -rf /opt/app/upd2pro/Advanced_Extensions_upd2pro.asp
fi
if [ "$1" = "del1" ] ; then
	rm -rf /etc/storage/app_3.sh /opt/bin/udp2raw /opt/opt_backup/bin/udp2raw /opt/app/upd2pro/Advanced_Extensions_upd2pro.asp
fi
if [ "$1" = "del2" ] ; then
	rm -rf /etc/storage/app_4.sh /opt/bin/speeder /opt/opt_backup/bin/speeder /opt/app/upd2pro/Advanced_Extensions_upd2pro.asp
fi
if [ "$1" = "del3" ] ; then
	rm -rf /etc/storage/app_6.sh /opt/bin/speederv2 /opt/opt_backup/bin/speederv2 /opt/app/upd2pro/Advanced_Extensions_upd2pro.asp
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
update_asp)
	update_app update_asp
	;;
*)
	upd2pro_check
	;;
esac

