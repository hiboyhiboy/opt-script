#!/bin/bash
#copyright by hiboy
source /etc/storage/script/init.sh
goflyway_enable=`nvram get app_23`
[ -z $goflyway_enable ] && goflyway_enable=0 && nvram set app_23=0
mkdir -p /etc/storage/goflyway
keypem_s_path="/etc/storage/goflyway/key.pem"
capem_s_path="/etc/storage/goflyway/ca.pem"
keypem_path="/opt/bin/key.pem"
capem_path="/opt/bin/ca.pem"

goflyway_renum=`nvram get goflyway_renum`
goflyway_renum=${goflyway_renum:-"0"}
cmd_log_enable=`nvram get cmd_log_enable`
cmd_name="goflyway"
cmd_log=""
if [ "$cmd_log_enable" = "1" ] || [ "$goflyway_renum" -gt "0" ] ; then
	cmd_log="$cmd_log2"
fi
if [ ! -z "$(echo $scriptfilepath | grep -v "/tmp/script/" | grep gofly_way)" ] && [ ! -s /tmp/script/_app7 ] ; then
	mkdir -p /tmp/script
	{ echo '#!/bin/bash' ; echo $scriptfilepath '"$@"' '&' ; } > /tmp/script/_app7
	chmod 777 /tmp/script/_app7
fi

goflyway_restart () {
i_app_restart "$@" -name="goflyway"
}

goflyway_get_status () {

B_restart="$goflyway_enable$(cat /etc/storage/app_7.sh | grep -v '^#' | grep -v '^$')"

i_app_get_status -name="goflyway" -valb="$B_restart"
}

goflyway_check () {

goflyway_get_status
if [ "$goflyway_enable" != "1" ] && [ "$needed_restart" = "1" ] ; then
	[ ! -z "`pidof goflyway`" ] && logger -t "【goflyway】" "停止 goflyway" && goflyway_close
	{ kill_ps "$scriptname" exit0; exit 0; }
fi
if [ "$goflyway_enable" = "1" ] ; then
	if [ "$needed_restart" = "1" ] ; then
		goflyway_close
		goflyway_start
	else
		[ -z "`pidof goflyway`" ] && goflyway_restart
	fi
fi
}

goflyway_keep () {
i_app_keep -name="goflyway" -pidof="goflyway" &
}

goflyway_close () {

kill_ps "$scriptname keep"
sed -Ei '/【goflyway】|^$/d' /tmp/script/_opt_script_check
killall goflyway
kill_ps "/tmp/script/_app7"
kill_ps "_gofly_way.sh"
kill_ps "$scriptname"
}

goflyway_start () {

check_webui_yes
i_app_get_cmd_file -name="goflyway" -cmd="goflyway" -cpath="/opt/bin/goflyway" -down1="$hiboyfile/goflyway" -down2="$hiboyfile2/goflyway"
if [ -s "$SVC_PATH" ] ; then
if [ ! -s "$capem_s_path" ] && [ -s "$capem_path" ] ; then
cp -f "$keypem_path" "$keypem_s_path"
cp -f "$capem_path" "$capem_s_path"
fi
rm -f  "$keypem_path" "$capem_path"
ln -sf "$keypem_s_path" "$keypem_path"
ln -sf "$capem_s_path" "$capem_path"
if [ ! -s "$capem_path" ] && [[ "$(goflyway -h 2>&1 | grep gen-ca | wc -l)" -gt 0 ]] ; then
	logger -t "【goflyway】" "找不到 $capem_path 正在生成 ca.pem、key.pem 稍等几分钟"
	cd /opt/bin/
	./goflyway -gen-ca
fi
if [ ! -s "$capem_path" ] ; then
wgetcurl_checkmd5 "$capem_path" "$hiboyfile/ca.pem" "$hiboyfile2/ca.pem" N
fi
if [ -s "$capem_path" ] ; then
	chmod 755 "$capem_path" "$keypem_path"
fi
[ ! -f /opt/bin/chinalist.txt ] && update_chnlist

fi
[[ "$(goflyway -h 2>&1 | wc -l)" -lt 2 ]] && rm -rf /opt/bin/goflyway
if [ ! -s "$SVC_PATH" ] ; then
	logger -t "【goflyway】" "找不到 $SVC_PATH ，需要手动安装 $SVC_PATH"
	logger -t "【goflyway】" "启动失败, 10 秒后自动尝试重新启动" && sleep 10 && goflyway_restart x
fi
chmod 777 "$SVC_PATH"
goflyway_v=$(goflyway -version | grep goflyway | sed -n '1p')
nvram set goflyway_v="$goflyway_v"
logger -t "【goflyway】" "运行 goflyway"

#运行脚本启动/opt/bin/goflyway
chmod 777 /etc/storage/app_7.sh
cd $(dirname `which goflyway`)
eval "/etc/storage/app_7.sh $cmd_log" &

sleep 4
i_app_keep -t -name="goflyway" -pidof="goflyway"

#goflyway_get_status
eval "$scriptfilepath keep &"
exit 0
}

update_chnlist () {
nvram set app_111=4 && Sh99_ss_tproxy.sh
cat /opt/app/ss_tproxy/rule/chnlist.txt | grep -v '^#' | sed -e 's@^cn$@com.cn@g' | sort -u | grep -v '^$' > /opt/bin/chinalist.txt

}

initconfig () {
	if [ ! -f "/etc/storage/app_7.sh" ] || [ ! -s "/etc/storage/app_7.sh" ] ; then
cat > "/etc/storage/app_7.sh" <<-\VVR
#!/bin/bash
# 启动运行的脚本
export PATH='/etc/storage/bin:/tmp/script:/etc/storage/script:/opt/usr/sbin:/opt/usr/bin:/opt/sbin:/opt/bin:/usr/local/sbin:/usr/sbin:/usr/bin:/sbin:/bin'
export LD_LIBRARY_PATH=/lib:/opt/lib
# https://github.com/coyove/goflyway/wiki/使用教程
cd $(dirname ` which goflyway`)
#在服务器执行下面命令即可启动服务端，KEY123为自定义密码，默认监听8100。本地执行
#./goflyway -t 0 -k=KEY123 -l="0.0.0.0:8100" 2>&1 &

#客户端命令（1.2.3.4要修改为服务器IP，默认监听8100）
goflyway -t 0 -k=KEY123 -up="1.2.3.4:8100" -l="0.0.0.0:8100" 2>&1 &

#可以配合 Proxifier、chrome(switchysharp、SwitchyOmega) 代理插件使用
#请设置以上软件的本地代理为 192.168.123.1:8100（协议为HTTP或SOCKS5代理，192.168.123.1为路由器IP）

VVR
	fi

}

initconfig

update_app () {
mkdir -p /opt/app/goflyway
if [ "$1" = "update_asp" ] ; then
	rm -rf /opt/app/goflyway/Advanced_Extensions_goflyway.asp
fi
if [ "$1" = "del" ] ; then
	rm -rf /opt/app/goflyway/Advanced_Extensions_goflyway.asp
	[ -f /opt/bin/goflyway ] && rm -f /opt/bin/goflyway /opt/bin/chinalist.txt /etc/storage/app_7.sh
	[ -f "$capem_s_path" ] && rm -f  "$keypem_s_path" "$capem_s_path" "$keypem_path" "$capem_path"
	rm -f /opt/opt_backup/bin/goflyway /opt/opt_backup/bin/key.pem /opt/opt_backup/bin/ca.pem

fi

initconfig

# 加载程序配置页面
if [ ! -f "/opt/app/goflyway/Advanced_Extensions_goflyway.asp" ] || [ ! -s "/opt/app/goflyway/Advanced_Extensions_goflyway.asp" ] ; then
	wgetcurl.sh /opt/app/goflyway/Advanced_Extensions_goflyway.asp "$hiboyfile/Advanced_Extensions_goflywayasp" "$hiboyfile2/Advanced_Extensions_goflywayasp"
fi
umount /www/Advanced_Extensions_app07.asp
mount --bind /opt/app/goflyway/Advanced_Extensions_goflyway.asp /www/Advanced_Extensions_app07.asp
# 更新程序启动脚本

[ "$1" = "del" ] && /etc/storage/www_sh/goflyway del &
}

case $ACTION in
start)
	goflyway_close
	goflyway_check
	;;
check)
	goflyway_check
	;;
stop)
	goflyway_close
	;;
updateapp7)
	goflyway_restart o
	[ "$goflyway_enable" = "1" ] && nvram set goflyway_status="updategoflyway" && logger -t "【goflyway】" "重启" && goflyway_restart
	[ "$goflyway_enable" != "1" ] && nvram set goflyway_v="" && logger -t "【goflyway】" "更新" && update_app del
	;;
update_app)
	update_app
	;;
update_asp)
	update_app update_asp
	;;
keep)
	#goflyway_check
	goflyway_keep
	;;
initconfig)
	initconfig
	;;
*)
	goflyway_check
	;;
esac

