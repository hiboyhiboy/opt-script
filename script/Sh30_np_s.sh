#!/bin/bash
#copyright by hiboy
source /etc/storage/script/init.sh
nps_version_2="v0.26.10"
nps_enable=`nvram get app_60`
[ -z $nps_enable ] && nps_enable=0 && nvram set app_60=0
npsc_enable=`nvram get app_58`
[ -z $npsc_enable ] && npsc_enable=0 && nvram set app_58=0
npss_enable=`nvram get app_59`
[ -z $npss_enable ] && npss_enable=0 && nvram set app_59=0
[ $npss_enable = 0 ] && [ $npsc_enable = 0 ] && nps_enable=0
if [ "$nps_enable" != "0" ] ; then

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

if [ ! -z "$(echo $scriptfilepath | grep -v "/tmp/script/" | grep np_s)" ] && [ ! -s /tmp/script/_app14 ] ; then
	mkdir -p /tmp/script
	{ echo '#!/bin/bash' ; echo $scriptfilepath '"$@"' '&' ; } > /tmp/script/_app14
	chmod 777 /tmp/script/_app14
fi

nps_restart () {
i_app_restart "$@" -name="nps"
}

nps_get_status () {

B_restart="$nps_enable$nps_version$npsc_enable$npss_enable$(cat /etc/storage/app_15.sh /etc/storage/app_16.sh | grep -v '^#' | grep -v '^$')"

i_app_get_status -name="nps" -valb="$B_restart"
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
if [ "$npss_enable" = "1" ] ; then
i_app_keep -name="nps" -pidof="nps" &
fi
if [ "$npsc_enable" = "1" ] ; then
i_app_keep -name="nps" -pidof="npc" &
fi
}

nps_close () {
kill_ps "$scriptname keep"
sed -Ei '/【nps】|^$/d' /tmp/script/_opt_script_check
sed -Ei '/【npc】|^$/d' /tmp/script/_opt_script_check
killall nps npc
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
	curltest=`which curl`
	if [ -z "$curltest" ] || [ ! -s "`which curl`" ] ; then
		nps_tag="$( wget -T 5 -t 3 --user-agent "$user_agent" --max-redirect=0 --output-document=-  https://api.github.com/repos/yisier/nps/releases/latest  2>&1 | grep 'tag_name' | cut -d\" -f4 )"
		[ -z "$nps_tag" ] && nps_tag="$( wget -T 5 -t 3 --user-agent "$user_agent" --quiet --output-document=-  https://api.github.com/repos/yisier/nps/releases/latest  2>&1 | grep 'tag_name' | cut -d\" -f4 )"
	else
		nps_tag="$( curl --connect-timeout 3 --user-agent "$user_agent"  https://api.github.com/repos/yisier/nps/releases/latest  2>&1 | grep 'tag_name' | cut -d\" -f4 )"
		[ -z "$nps_tag" ] && nps_tag="$( curl -L --connect-timeout 3 --user-agent "$user_agent" -s  https://api.github.com/repos/yisier/nps/releases/latest  2>&1 | grep 'tag_name' | cut -d\" -f4 )"
	fi
	[ -z "$nps_tag" ] && logger -t "【nps】" "最新版本获取失败！！！请手动指定版本，例：[""$nps_version_2""]" && nps_restart x
	[ ! -z "$nps_tag" ] && logger -t "【nps】" "自动下载最新版本 $nps_tag"
	if [ -z "$nps_tag" ] && [ -s "/opt/bin/nps/npc" ] ; then
		cd /opt/bin/nps
		/opt/bin/nps/npc 2>&1 > /tmp/nps_v.txt &
		sleep 2
		killall npc
		nps_tag="$(cat /tmp/nps_v.txt | grep version | awk -F ',' '{print $1}'  | awk -F ' ' '{print $NF}')"
	fi
	if [ -z "$nps_tag" ] && [ -s "/opt/bin/nps/nps" ] ; then
		cd /opt/bin/nps
		/opt/bin/nps/nps 2>&1 > /tmp/nps_v.txt &
		sleep 2
		killall nps
		nps_tag="$(cat /tmp/nps_v.txt | grep version | awk -F ',' '{print $1}'  | awk -F ' ' '{print $NF}')"
	fi
	[ ! -z "$nps_tag" ] && nvram set app_57="$nps_tag"
	[ -z "$nps_tag" ] && nps_tag=`nvram get app_57`
	[ -z "$nps_tag" ] && nps_tag="$nps_version_2" && nvram set app_57="$nps_tag"
	nps_version=$nps_tag
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
	if [ -z "$nps_ver" ] ; then
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
	if [ ! -s "$SVC_PATH" ] ; then
		logger -t "【nps】" "找不到 $SVC_PATH ，安装 opt 程序"
		/etc/storage/script/Sh01_mountopt.sh start
		initopt
	fi
	if [ ! -s "$SVC_PATH" ] && [ "$action_nps" = "npc" ] ; then
		nps_ver_wget="https://github.com/yisier/nps/releases/download/$nps_version/linux_mipsle_client.tar.gz"
		wgetcurl_file /opt/bin/nps/linux_mipsle_client.tar.gz "$nps_ver_wget"
		rm -rf /opt/bin/nps/tmp
		mkdir -p /opt/bin/nps/tmp
		tar -xz -C /opt/bin/nps/tmp -f /opt/bin/nps/linux_mipsle_client.tar.gz
		rm -rf /opt/bin/nps/linux_mipsle_client.tar.gz
		[ -f /opt/bin/nps/tmp/npc ] && mv -f /opt/bin/nps/tmp/npc $SVC_PATH
		[ -f /opt/bin/nps/tmp/nps/npc ] && mv -f /opt/bin/nps/tmp/nps/npc $SVC_PATH
		rm -rf /opt/bin/nps/tmp
	fi
	[ "$action_nps" = "nps" ] && [ ! -d /opt/bin/nps/conf ] && rm -rf $SVC_PATH /opt/bin/nps/conf
	if [ ! -s "$SVC_PATH" ] && [ "$action_nps" = "nps" ] ; then
		nps_ver_wget="https://github.com/yisier/nps/releases/download/$nps_version/linux_mipsle_server.tar.gz"
		wgetcurl_file /opt/bin/nps/linux_mipsle_server.tar.gz "$nps_ver_wget"
		rm -rf /opt/bin/nps/tmp
		mkdir -p /opt/bin/nps/tmp
		tar -xz -C /opt/bin/nps/tmp -f /opt/bin/nps/linux_mipsle_server.tar.gz
		rm -rf /opt/bin/nps/linux_mipsle_server.tar.gz
		[ -f /opt/bin/nps/tmp/nps ] && mv -f /opt/bin/nps/tmp/nps $SVC_PATH
		[ -f /opt/bin/nps/tmp/nps/nps ] && mv -f /opt/bin/nps/tmp/nps/nps $SVC_PATH
		[ -d /opt/bin/nps/tmp/conf ] && { cd /opt/bin/nps/tmp; tar -cz -f /opt/bin/nps/tmp/tmp.tar.gz ./conf ./web; }
		[ -d /opt/bin/nps/tmp/nps/conf ] && { cd /opt/bin/nps/tmp/nps; tar -cz -f /opt/bin/nps/tmp/tmp.tar.gz ./conf ./web; }
		tar -xz -C /opt/bin/nps -f /opt/bin/nps/tmp/tmp.tar.gz
		rm -f /opt/bin/nps/conf/nps.conf
		rm -rf /opt/bin/nps/tmp
		if [ ! -d /etc/storage/nps/conf ] ; then
			mkdir -p /etc/storage/nps/
			cp -rf /opt/bin/nps/conf /etc/storage/nps/
			rm -f /etc/storage/nps/conf/nps.conf
			ln -sf /etc/storage/app_16.sh /etc/storage/nps/conf/nps.conf
		fi
		rm -rf /opt/bin/nps/conf
		ln -sf /etc/storage/nps/conf /opt/bin/nps/conf
		[ ! -s /opt/bin/nps/conf ] && cp -f /etc/storage/nps/conf /opt/bin/nps/conf
	fi
	chmod 755 $SVC_PATH
	[[ "$($SVC_PATH -h 2>&1 | wc -l)" -lt 2 ]] && rm -rf $SVC_PATH
	wgetcurl_file "$SVC_PATH" "$hiboyfile/$action_nps" "$hiboyfile2/$action_nps"
	if [ ! -s "$SVC_PATH" ] ; then
		logger -t "【nps】" "找不到 $SVC_PATH ，需要手动安装 $SVC_PATH"
		logger -t "【nps】" "启动失败, 10 秒后自动尝试重新启动" && sleep 10 && nps_restart x
	else
		logger -t "【nps】" "找到 $SVC_PATH"
		chmod 755 $SVC_PATH
		chmod 755 /opt/bin/nps/$action_nps
	fi
	logger -t "【nps】" "运行 $action_nps"
	cd /opt/bin/nps
	if [ "$action_nps" = "npc" ] ; then
		app_15="/etc/storage/app_15.sh"
		if [ -z "$(cat $app_15 | grep "auto_reconnection=true")" ] ; then
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
		[ ! -s /opt/bin/nps/conf ] && cp -f /etc/storage/nps/conf /opt/bin/nps/conf
		if [ ! -f /etc/storage/nps/conf/nps.conf ] ; then
			rm -rf /etc/storage/nps /opt/bin/nps/conf
			logger -t "【nps】" "找不到 /etc/storage/nps/conf/nps.conf , 尝试重新启动" && nps_restart x
		fi
		cmd_name="$action_nps"
		eval "/opt/bin/nps/$action_nps $cmd_log" &
		logger -t "【nps】" "服务端配置文件在 /etc/storage/nps/conf"
		logger -t "【nps】" "请手动配置【外部网络 - 端口转发 - 启用手动端口映射】来开启WAN访问"
	fi
	sleep 4
	i_app_keep -t -name="nps" -pidof="$action_nps"
fi
done
#nps_get_status
eval "$scriptfilepath keep &"
exit 0
}

initconfig () {

app_15="/etc/storage/app_15.sh"
if [ ! -f "$app_15" ] || [ ! -s "$app_15" ] ; then
	cat > "$app_15" <<-\EEE
[common]
server_addr=1.0.0.1:8284
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

#HTTP(S) proxy port, no startup if empty
#http_proxy_ip=0.0.0.0
#http_proxy_port=80
#https_proxy_port=443
#https_just_proxy=true
#default https certificate setting
#https_default_cert_file=conf/server.pem
#https_default_key_file=conf/server.key

# Public password, which clients can use to connect to the server
# After the connection, the server will be able to open relevant ports and parse related domain names according to its own configuration file.
public_vkey=

#Traffic data persistence interval(minute)
#Ignorance means no persistence
#flow_store_interval=1
# log level LevelEmergency->0  LevelAlert->1 LevelCritical->2 LevelError->3 LevelWarning->4 LevelNotice->5 LevelInformational->6 LevelDebug->7
log_level=7
log_path=/tmp/syslog.log

#Whether to restrict IP access, true or false or ignore
#ip_limit=true

#p2p
#p2p_ip=127.0.0.1
#p2p_port=6000

#web
#web_base_url=
#web_open_ssl=false
#web_cert_file=conf/server.pem
#web_key_file=conf/server.key
# if web under proxy use sub path. like http://host/nps need this.
#web_base_url=/nps

#Web API unauthenticated IP address(the len of auth_crypt_key must be 16)
#Remove comments if needed
#auth_key=test
#auth_crypt_key =1234567812345678

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

#get origin ip
http_add_origin_header=false

#pprof debug options
#pprof_ip=0.0.0.0
#pprof_port=9999

#client disconnect timeout
disconnect_timeout=60


EEE
	web_user=`nvram get http_username`
	SEED=`tr -cd a-b0-9 </dev/urandom | head -c 8`
	web_pass=$SEED
	sed -e "s|^\(web_username.*\)=[^=]*$|\1=$web_user|" -i $app_16
	sed -e "s|^\(web_password.*\)=[^=]*$|\1=$web_pass|" -i $app_16
	chmod 755 "$app_16"
fi

	npc_server_addr=$(cat $app_15 | grep 'server_addr=' | awk -F '=' '{print $2;}')
	nvram set npc_server_addr=$npc_server_addr
	nps_web_port=$(cat $app_16 | grep 'web_port=' | awk -F '=' '{print $2;}')
	nvram set nps_web_port=$nps_web_port
}

initconfig

update_app () {
mkdir -p /opt/app/nps
if [ "$1" = "update_asp" ] ; then
	rm -rf /opt/app/nps/Advanced_Extensions_nps.asp
fi
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
update_asp)
	update_app update_asp
	;;
keep)
	#nps_check
	nps_keep
	;;
*)
	nps_check
	;;
esac

