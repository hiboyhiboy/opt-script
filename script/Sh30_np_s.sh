#!/bin/sh
#copyright by hiboy
source /etc/storage/script/init.sh
nps_enable=`nvram get app_60`
[ -z $nps_enable ] && nps_enable=0 && nvram set app_60=0
npsc_enable=`nvram get app_58`
[ -z $npsc_enable ] && npsc_enable=0 && nvram set app_58=0
npss_enable=`nvram get app_59`
[ -z $npss_enable ] && npss_enable=0 && nvram set app_59=0
[ $npss_enable = 0 ] && [ $npsc_enable = 0 ] && nps_enable=0
if [ "$nps_enable" != "0" ] ; then
#nvramshow=`nvram showall | grep '=' | grep nps | awk '{print gensub(/'"'"'/,"'"'"'\"'"'"'\"'"'"'","g",$0);}'| awk '{print gensub(/=/,"='\''",1,$0)"'\'';";}'` && eval $nvramshow

nps_renum=`nvram get nps_renum`
nps_renum=${nps_renum:-"0"}

nps_version=`nvram get app_57`
nps_update=`nvram get nps_update`
[ "$nps_update" == "1" ] && nps_version="" && nvram set app_57="" && nvram set nps_update="0"
cmd_log_enable=`nvram get cmd_log_enable`
cmd_name="nps"
cmd_log=""
if [ "$cmd_log_enable" = "1" ] || [ "$nps_renum" -gt "0" ] ; then
	cmd_log="$cmd_log2"
fi

fi

if [ ! -z "$(echo $scriptfilepath | grep -v "/tmp/script/" | grep np_s)" ]  && [ ! -s /tmp/script/_app14 ]; then
	mkdir -p /tmp/script
	{ echo '#!/bin/sh' ; echo $scriptfilepath '"$@"' '&' ; } > /tmp/script/_app14
	chmod 777 /tmp/script/_app14
fi

nps_restart () {

relock="/var/lock/nps_restart.lock"
if [ "$1" = "o" ] ; then
	nvram set nps_renum="0"
	[ -f $relock ] && rm -f $relock
	return 0
fi
if [ "$1" = "x" ] ; then
	if [ -f $relock ] ; then
		logger -t "【nps】" "多次尝试启动失败，等待【"`cat $relock`"分钟】后自动尝试重新启动"
		exit 0
	fi
	nps_renum=${nps_renum:-"0"}
	nps_renum=`expr $nps_renum + 1`
	nvram set nps_renum="$nps_renum"
	if [ "$nps_renum" -gt "2" ] ; then
		I=19
		echo $I > $relock
		logger -t "【nps】" "多次尝试启动失败，等待【"`cat $relock`"分钟】后自动尝试重新启动"
		while [ $I -gt 0 ]; do
			I=$(($I - 1))
			echo $I > $relock
			sleep 60
			[ "$(nvram get nps_renum)" = "0" ] && exit 0
			[ $I -lt 0 ] && break
		done
		nvram set nps_renum="0"
	fi
	[ -f $relock ] && rm -f $relock
fi
nvram set nps_status=0
eval "$scriptfilepath &"
exit 0
}

nps_get_status () {

A_restart=`nvram get nps_status`
B_restart="$nps_enable$nps_version$npsc_enable$npss_enable$(cat /etc/storage/app_15.sh /etc/storage/app_16.sh | grep -v '^#' | grep -v "^$")"
B_restart=`echo -n "$B_restart" | md5sum | sed s/[[:space:]]//g | sed s/-//g`
if [ "$A_restart" != "$B_restart" ] ; then
	nvram set nps_status=$B_restart
	needed_restart=1
else
	needed_restart=0
fi
}

nps_check () {

nps_get_status
if [ "$nps_enable" != "1" ] && [ "$needed_restart" = "1" ] ; then
	[ ! -z "$(ps -w | grep "nps" | grep -v grep )" ] && logger -t "【nps】" "停止 nps" && nps_close
	[ ! -z "$(ps -w | grep "npc" | grep -v grep )" ] && logger -t "【nps】" "停止 npc" && nps_close
	{ kill_ps "$scriptname" exit0; exit 0; }
fi
if [ "$nps_enable" = "1" ] ; then
	if [ "$needed_restart" = "1" ] ; then
		nps_close
		nps_start
	else
		[ "$npss_enable" = "1" ] && [ -z "$(ps -w | grep "nps" | grep -v grep )" ] && nps_restart
		[ "$npsc_enable" = "1" ] && [ -z "$(ps -w | grep "npc" | grep -v grep )" ] && nps_restart
	fi
fi
}

nps_keep () {
logger -t "【nps】" "守护进程启动"
if [ -s /tmp/script/_opt_script_check ]; then
sed -Ei '/【nps】|^$/d' /tmp/script/_opt_script_check
if [ "$npss_enable" = "1" ] ; then
cat >> "/tmp/script/_opt_script_check" <<-OSC
	[ -z "\`pidof nps\`" ] || [ ! -s "/opt/bin/nps/nps" ] && nvram set nps_status=00 && logger -t "【nps】" "重新启动" && eval "$scriptfilepath &" && sed -Ei '/【nps】|^$/d' /tmp/script/_opt_script_check # 【nps】
OSC
fi
sed -Ei '/【npc】|^$/d' /tmp/script/_opt_script_check
if [ "$npsc_enable" = "1" ] ; then
cat >> "/tmp/script/_opt_script_check" <<-OSC
	[ -z "\`pidof npc\`" ] || [ ! -s "/opt/bin/nps/npc" ] && nvram set nps_status=00 && logger -t "【nps】" "重新启动" && eval "$scriptfilepath &" && sed -Ei '/【npc】|^$/d' /tmp/script/_opt_script_check # 【npc】
OSC
fi
return
fi

while true; do
if [ "$npss_enable" = "1" ] ; then
	if [ -z "`pidof nps`" ] || [ ! -s "/opt/bin/nps/nps" ] ; then
		logger -t "【nps】" "nps重新启动"
		nps_restart
	fi
fi
if [ "$npsc_enable" = "1" ] ; then
	if [ -z "`pidof npc`" ] || [ ! -s "/opt/bin/nps/npc" ] ; then
		logger -t "【nps】" "npc重新启动"
		nps_restart
	fi
fi
	sleep 230
done
}

nps_close () {
sed -Ei '/【nps】|^$/d' /tmp/script/_opt_script_check
sed -Ei '/【npc】|^$/d' /tmp/script/_opt_script_check
killall nps npc
killall -9 nps npc
kill_ps "/tmp/script/_app14"
kill_ps "_np_s.sh"
kill_ps "$scriptname"
}

nps_start () {
check_webui_yes
mkdir -p /opt/bin/nps
nps_ver_wget=""
action_for=""
[ "$npsc_enable" = "1" ] && action_for="npc"
[ "$npss_enable" = "1" ] && action_for=$action_for" nps"
del_tmp=0
if [ -z "$nps_version" ] ; then
	nps_tag="$( wget -T 5 -t 3 --user-agent "$user_agent" --max-redirect=0  https://github.com/cnlh/nps/releases/latest  2>&1 | grep releases/tag | awk -F '/' '{print $NF}' | awk -F ' ' '{print $1}' )"
	[ -z "$nps_tag" ] && nps_tag="$( wget -T 5 -t 3 --user-agent "$user_agent" --quiet --output-document=-  https://github.com/cnlh/nps/releases/latest  2>&1 | grep '<a href="/cnlh/nps/tree/'  |head -n1 | awk -F '/' '{print $NF}' | awk -F '"' '{print $1}' )"
	[ -z "$nps_tag" ] && logger -t "【nps】" "最新版本获取失败！！！请手动指定版本，例：[v0.25.4]" && nps_restart x
	[ ! -z "$nps_tag" ] && logger -t "【nps】" "自动下载最新版本 $nps_tag"
	[ -z "$nps_tag" ] && nps_tag="v0.25.4"
	nps_version=$nps_tag && nvram set app_57=$nps_tag
	nps_restart o
	logger -t "【nps】" "重启" && nps_restart
fi
# 版本对比
for action_nps in $action_for
do
if [ ! -z "$action_nps" ] && [ -s "/opt/bin/nps/$action_nps" ] ; then
	cd /opt/bin/nps
	/opt/bin/nps/$action_nps 2>&1 > /tmp/nps_v.txt &
	sleep 2
	killall $action_nps
	nps_ver="$(cat /tmp/nps_v.txt | grep version | awk -F ',' '{print $1}'  | awk -F ' ' '{print $NF}')"
	if [ "$nps_ver" = "" ] ; then
		logger -t "【nps】" "$action_nps 当前版本 $nps_ver ,获取失败，请手动检查版本是否和服务器匹配!"
	else
	if [ v"$nps_ver" != "$nps_version" ] ; then
		logger -t "【nps】" "$action_nps 当前版本 $nps_ver ,需要安装 $nps_version ,自动重新下载"
		[ -s "/opt/bin/nps/$action_nps" ] && rm -f /opt/bin/nps/$action_nps
	fi
	fi
fi
done
# 下载客户端与服务端
for action_nps in $action_for
do
if [ ! -z "$action_nps" ] ; then
	SVC_PATH="/opt/bin/nps/$action_nps"
	chmod 777 "$SVC_PATH"
	[[ "$($SVC_PATH -h 2>&1 | wc -l)" -lt 2 ]] && rm -rf $SVC_PATH
	if [ ! -s "$SVC_PATH" ] ; then
		logger -t "【nps】" "找不到 $SVC_PATH ，安装 opt 程序"
		/tmp/script/_mountopt start
		initopt
	fi
	if [ ! -s "$SVC_PATH" ] && [ "$action_nps" = "npc" ] ; then
		nps_ver_wget="https://github.com/cnlh/nps/releases/download/$nps_version/linux_mipsle_client.tar.gz"
		wgetcurl_file /opt/bin/nps/linux_mipsle_client.tar.gz "$nps_ver_wget"
		rm -rf /opt/bin/nps/tmp
		mkdir -p /opt/bin/nps/tmp
		tar -xz -C /opt/bin/nps/tmp -f /opt/bin/nps/linux_mipsle_client.tar.gz
		[ -f /opt/bin/nps/tmp/npc ] && mv -f /opt/bin/nps/tmp/npc $SVC_PATH
		[ -f /opt/bin/nps/tmp/nps/npc ] && mv -f /opt/bin/nps/tmp/nps/npc $SVC_PATH
		rm -rf /opt/bin/nps/tmp /opt/bin/nps/linux_mipsle_client.tar.gz
	fi
	[ "$action_nps" = "nps" ] && [ ! -d /opt/bin/nps/conf ] && rm -rf $SVC_PATH /opt/bin/nps/conf
	if [ ! -s "$SVC_PATH" ] && [ "$action_nps" = "nps" ] ; then
		nps_ver_wget="https://github.com/cnlh/nps/releases/download/$nps_version/linux_mipsle_server.tar.gz"
		wgetcurl_file /opt/bin/nps/linux_mipsle_server.tar.gz "$nps_ver_wget"
		rm -rf /opt/bin/nps/tmp
		mkdir -p /opt/bin/nps/tmp
		tar -xz -C /opt/bin/nps/tmp -f /opt/bin/nps/linux_mipsle_server.tar.gz
		[ -f /opt/bin/nps/tmp/nps ] && mv -f /opt/bin/nps/tmp/nps $SVC_PATH
		[ -f /opt/bin/nps/tmp/nps/nps ] && mv -f /opt/bin/nps/tmp/nps/nps $SVC_PATH
		[ -d /opt/bin/nps/tmp/conf ] && { cd /opt/bin/nps/tmp; tar -cz -f /opt/bin/nps/tmp/tmp.tar.gz ./conf ./web; }
		[ -d /opt/bin/nps/tmp/nps/conf ] && { cd /opt/bin/nps/tmp/nps; tar -cz -f /opt/bin/nps/tmp/tmp.tar.gz ./conf ./web; }
		tar -xz -C /opt/bin/nps -f /opt/bin/nps/tmp/tmp.tar.gz
		rm -f /opt/bin/nps/conf/nps.conf
		rm -rf /opt/bin/nps/tmp /opt/bin/nps/linux_mipsle_server.tar.gz
		if [ ! -d /etc/storage/nps/conf ] ; then
			mkdir -p /etc/storage/nps/
			cp -rf /opt/bin/nps/conf /etc/storage/nps/
			rm -f /etc/storage/nps/conf/nps.conf
			ln -sf /etc/storage/app_16.sh /etc/storage/nps/conf/nps.conf
		fi
		rm -rf /opt/bin/nps/conf
		ln -sf /etc/storage/nps/conf /opt/bin/nps/conf
	fi
	if [ ! -s "$SVC_PATH" ] ; then
		logger -t "【nps】" "找不到 $SVC_PATH ，需要手动安装 $SVC_PATH"
		logger -t "【nps】" "启动失败, 10 秒后自动尝试重新启动" && sleep 10 && nps_restart x
	else
		logger -t "【nps】" "找到 $SVC_PATH"
		chmod 755 $SVC_PATH
		#ln -sf $SVC_PATH /opt/bin/$action_nps
		#cp -f $SVC_PATH /opt/bin/$action_nps
		chmod 755 /opt/bin/nps/$action_nps
	fi
	logger -t "【nps】" "运行 $action_nps"
	cd /opt/bin/nps
	if [ "$action_nps" = "npc" ] ; then
		app_15="/etc/storage/app_15.sh"
		if [ -z "$(grep "auto_reconnection=true" $app_15)" ] ; then
			logger -t "【nps】" "客户端配置文件添加断线重连 auto_reconnection=true"
			sed -Ei '/auto_reconnection=/d' $app_15
			echo "auto_reconnection=true" >> $app_15
		fi
		cmd_name="$action_nps"
		eval "/opt/bin/nps/$action_nps -config /etc/storage/app_15.sh $cmd_log" &
		logger -t "【nps】" "客户端配置文件在 /etc/storage/app_15.sh"
	fi
	if [ "$action_nps" = "nps" ] ; then
	# 生成配置文件/etc/storage/nps
		rm -rf /opt/bin/nps/conf
		ln -sf /etc/storage/nps/conf /opt/bin/nps/conf
		if [ ! -f /etc/storage/nps/conf/nps.conf ] ; then
			rm -rf /etc/storage/nps /opt/bin/nps/conf
			logger -t "【nps】" "找不到 /etc/storage/nps/conf/nps.conf , 尝试重新启动" && nps_restart x
		fi
		cmd_name="$action_nps"
		eval "/opt/bin/nps/$action_nps $cmd_log" &
		logger -t "【nps】" "服务端配置文件在 /etc/storage/nps/conf"
	fi
	sleep 4
	[ -z "`pidof $action_nps`" ] && logger -t "【nps】" "$action_nps启动失败, 注意检查端口是否有冲突,程序是否下载完整,10 秒后自动尝试重新启动" && sleep 10 && nps_restart x
	[ ! -z "`pidof $action_nps`" ] && logger -t "【nps】" "$action_nps启动成功" && nps_restart o
fi
done
#nps_get_status
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

app_15="/etc/storage/app_15.sh"
if [ ! -f "$app_15" ] || [ ! -s "$app_15" ] ; then
	cat > "$app_15" <<-\EEE
[common]
server_addr=1.1.1.1:8284
conn_type=tcp
vkey=web界面中显示的密钥
auto_reconnection=true

EEE
	chmod 755 "$app_15"
fi

app_16="/etc/storage/app_16.sh"
if [ ! -f "$app_16" ] || [ ! -s "$app_16" ] ; then
	cat > "$app_16" <<-\EEE
#web管理界面
web_host=
web_username=admin
web_password=123
web_port=8080
web_ip=0.0.0.0

##服务端客户端通信
bridge_type=tcp
bridge_port=8284
bridge_ip=0.0.0.0

appname = nps
#Boot mode(dev|pro)
runmode = dev

# Public password, which clients can use to connect to the server
# After the connection, the server will be able to open relevant ports and parse related domain names according to its own configuration file.
public_vkey=

# log level LevelEmergency->0  LevelAlert->1 LevelCritical->2 LevelError->3 LevelWarning->4 LevelNotice->5 LevelInformational->6 LevelDebug->7
log_level=7
log_path=/tmp/syslog.log


#allow_ports=9001-9009,10001,11000-12000

#Web management multi-user login
allow_user_login=false
allow_user_register=false
allow_user_change_username=false


#extension
allow_flow_limit=false
allow_rate_limit=false
allow_tunnel_num_limit=false
allow_local_proxy=false
allow_connection_num_limit=false
allow_multi_ip=false
system_info_display=false

#cache
http_cache=false
http_cache_length=100

EEE
	web_user=`nvram get http_username`
	SEED=`tr -cd a-b0-9 </dev/urandom | head -c 8`
	web_pass=$SEED
	sed -e "s|^\(web_username.*\)=[^=]*$|\1=$web_user|" -i $app_16
	sed -e "s|^\(web_password.*\)=[^=]*$|\1=$web_pass|" -i $app_16
	chmod 755 "$app_16"
fi

	npc_server_addr=$(grep 'server_addr=' $app_15 | awk -F '=' '{print $2;}')
	nvram set npc_server_addr=$npc_server_addr
	nps_web_port=$(grep 'web_port=' $app_16 | awk -F '=' '{print $2;}')
	nvram set nps_web_port=$nps_web_port
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
mkdir -p /opt/app/nps
if [ "$1" = "del" ] ; then
	nps_version=""
	nvram set app_57=""
	nvram set nps_update="1"
	rm -rf /opt/app/nps/Advanced_Extensions_nps.asp
	rm -rf /opt/bin/nps/web /opt/bin/nps/conf /opt/opt_backup/bin/nps/web /opt/opt_backup/bin/nps/conf
	rm -f /opt/bin/nps/linux_mipsle_client.tar.gz /opt/bin/nps/linux_mipsle_server.tar.gz /opt/opt_backup/bin/nps/linux_mipsle_client.tar.gz /opt/opt_backup/bin/nps/linux_mipsle_server.tar.gz
	rm -f /opt/bin/nps/npc.conf /opt/bin/nps/npc /opt/bin/nps/nps /opt/opt_backup/bin/nps/npc /opt/opt_backup/bin/nps/nps
fi

initconfig

# 加载程序配置页面
if [ ! -f "/opt/app/nps/Advanced_Extensions_nps.asp" ] || [ ! -s "/opt/app/nps/Advanced_Extensions_nps.asp" ] ; then
	wgetcurl.sh /opt/app/nps/Advanced_Extensions_nps.asp "$hiboyfile/Advanced_Extensions_npsasp" "$hiboyfile2/Advanced_Extensions_npsasp"
fi
umount /www/Advanced_Extensions_app14.asp
mount --bind /opt/app/nps/Advanced_Extensions_nps.asp /www/Advanced_Extensions_app14.asp
# 更新程序启动脚本

[ "$1" = "del" ] && /etc/storage/www_sh/nps del &
}

case $ACTION in
start)
	nps_close
	nps_check
	;;
check)
	nps_check
	;;
stop)
	nps_close
	;;
updateapp14)
	nps_restart o
	[ "$nps_enable" = "1" ] && nvram set nps_status="updatenps" && logger -t "【nps】" "重启" && nps_restart
	[ "$nps_enable" != "1" ] && nvram set nps_v="" && logger -t "【nps】" "更新" && update_app del
	;;
update_app)
	update_app
	;;
keep)
	#nps_check
	nps_keep
	;;
*)
	nps_check
	;;
esac

