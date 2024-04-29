#!/bin/bash
#copyright by hiboy
source /etc/storage/script/init.sh
tmall_enable=`nvram get app_55`
[ -z $tmall_enable ] && tmall_enable=0 && nvram set app_55=0
tmall_id=`nvram get app_56`
demoui_enable=`nvram get app_117`
[ -z $demoui_enable ] && demoui_enable=0 && nvram set app_117=0
wxsend_enable=`nvram get app_123`
[ -z $wxsend_enable ] && wxsend_enable=0 && nvram set app_123=0
wxsend_port=`nvram get app_128`
[ -z $wxsend_port ] && wxsend_port=0 && nvram set app_128=0
wxsend_cgi=`nvram get app_129`
if [ -z $wxsend_cgi ] ; then
weekly=`tr -cd a-b0-9 </dev/urandom | head -c 12`
wxsend_cgi="$weekly" && nvram set app_129="$weekly"
fi
app_118=`nvram get app_118`
[ -z $app_118 ] && app_118=8080 && nvram set app_118=8080
http_tmp_lanport=`nvram get http_tmp_lanport`
if [ "$demoui_enable" == "0" ] && [ ! -z "$http_tmp_lanport" ] ; then
	logger -t "【demoui】" "恢复真实 Web 服务访问端口 $lan_ipaddr:$http_tmp_lanport ，需等待15秒"
	logger -t "【demoui】" "变更源地址由于网页有缓存导致显示异常，请按 ctrl+F5 强制刷新或清除缓存"
	logger -t "【demoui】" "变更源地址由于网页有缓存导致显示异常，请按 ctrl+F5 强制刷新或清除缓存 "
	nvram set http_tmp_lanport=""
	nvram set http_lanport=$http_tmp_lanport
	sleep 2
	killall httpd 
	fi
if [ "$tmall_enable" != "0" ] ; then

tmall_renum=`nvram get tmall_renum`

cmd_log_enable=`nvram get cmd_log_enable`
cmd_name="tmall"
cmd_log=""
if [ "$cmd_log_enable" = "1" ] || [ "$tmall_renum" -gt "0" ] ; then
	cmd_log="$cmd_log2"
fi

fi

if [ ! -z "$(echo $scriptfilepath | grep -v "/tmp/script/" | grep t_mall)" ] && [ ! -s /tmp/script/_app13 ] ; then
	mkdir -p /tmp/script
	{ echo '#!/bin/bash' ; echo $scriptfilepath '"$@"' '&' ; } > /tmp/script/_app13
	chmod 777 /tmp/script/_app13
fi

tmall_restart () {
i_app_restart "$@" -name="tmall"
}

tmall_get_status () {

B_restart="$tmall_enable$wxsend_enable$wxsend_port$tmall_id$demoui_enable$app_117$app_118$(cat /etc/storage/app_13.sh /etc/storage/app_14.sh /etc/storage/app_29.sh | grep -v '^#' | grep -v '^$')"

i_app_get_status -name="tmall" -valb="$B_restart"
}

tmall_check () {

tmall_get_status
if [ "$tmall_enable" != "1" ] && [ "$needed_restart" = "1" ] ; then
	[ ! -z "$(ps -w | grep "caddy_tmall" | grep -v grep )" ] && logger -t "【天猫精灵】" "停止 tmall" && tmall_close
	{ kill_ps "$scriptname" exit0; exit 0; }
fi
if [ "$tmall_enable" = "1" ] ; then
	if [ "$needed_restart" = "1" ] ; then
		tmall_close
		tmall_start
	else
		[ -z "$(ps -w | grep "caddy_tmall" | grep -v grep )" ] && tmall_restart
	fi
fi
}

tmall_keep () {
i_app_keep -name="tmall" -pidof="caddy_tmall" -cpath="/opt/tmall/caddy_tmall" &
while true; do
	if [ -f "/tmp/tmall/RUN" ] ; then
		logger -t "【天猫精灵】" "运行远程命令"
		source /tmp/tmall/RUN
		rm -f /tmp/tmall/RUN
	fi
sleep 10
done
}

tmall_close () {
kill_ps "$scriptname keep"
sed -Ei '/【天猫精灵】|^$/d' /tmp/script/_opt_script_check
sed -Ei '/【tmall】|^$/d' /tmp/script/_opt_script_check
killall caddy_tmall
kill_ps "/tmp/script/_app13"
kill_ps "_t_mall.sh"
kill_ps "$scriptname"
}

tmall_start () {
check_webui_yes
i_app_get_cmd_file -name="tmall" -cmd="/opt/tmall/caddy_tmall" -cpath="/opt/tmall/caddy_tmall" -down1="$hiboyfile/caddy2" -down2="$hiboyfile2/caddy2" -runh="help"
mkdir -p "/tmp/tmall"
mkdir -p "/opt/tmall/www"
[ -z "$($SVC_PATH list-modules 2>&1 | grep http.handlers.cgi)" ] && rm -rf $SVC_PATH ;
[ ! -s "$SVC_PATH" ] && wgetcurl_file "$SVC_PATH" "$hiboyfile/caddy2" "$hiboyfile2/caddy2"
[ -z "$tmall_id" ] && { logger -t "【天猫精灵】" "启动失败, 注意检[认证配置]是否填写,10 秒后自动尝试重新启动" && sleep 10 && tmall_restart x ; }
# 生成配置文件
rm -f /opt/tmall/app_13.sh
ln -sf /etc/storage/app_13.sh /opt/tmall/app_13.sh
[ ! -f /opt/tmall/app_13.sh ] && cp -f /etc/storage/app_13.sh /opt/tmall/app_13.sh
rm -f /opt/tmall/app_14.sh
ln -sf /etc/storage/app_14.sh /opt/tmall/app_14.sh
[ ! -f /opt/tmall/app_14.sh ] && cp -f /etc/storage/app_14.sh /opt/tmall/app_14.sh
rm -f /opt/tmall/app_29.sh
ln -sf /etc/storage/app_29.sh /opt/tmall/app_29.sh
[ ! -f /opt/tmall/app_29.sh ] && cp -f /etc/storage/app_29.sh /opt/tmall/app_29.sh
rm -f /opt/tmall/app_31.sh
ln -sf /etc/storage/app_31.sh /opt/tmall/app_31.sh
[ ! -f /opt/tmall/app_31.sh ] && cp -f /etc/storage/app_31.sh /opt/tmall/app_31.sh

rm -f /opt/tmall/Caddyfile
[ "$demoui_enable" == "0" ] || [ "$demoui_enable" == "1" ] && { cat /etc/storage/app_13.sh >> /opt/tmall/Caddyfile ; }
echo "" >> /opt/tmall/Caddyfile
if [ "$wxsend_enable" != "0" ] && [ "$wxsend_port" != "0" ] ; then
	logger -t "【天猫精灵】" "由于已经启动 自建微信推送 部署 api 提供外部程序使用消息推送。"
	logger -t "【天猫精灵】" "导入 wxsend推送 Caddyfile cgi 配置: /etc/storage/app_31.sh"
	# 生成配置文件 /etc/storage/app_31.sh
	sed -e "s@^:.\+\({\)@:$wxsend_port {@g" -i /etc/storage/app_31.sh
	sed -e "s@^.\+cgi /.\+\(\#\)@ cgi /$wxsend_cgi/\* /etc/storage/script/Sh45_wx_send.sh \#@g" -i /etc/storage/app_31.sh
	sed -e "s@^cgi /.\+\(\#\)@ cgi /$wxsend_cgi/\* /etc/storage/script/Sh45_wx_send.sh \#@g" -i /etc/storage/app_31.sh
	cat /etc/storage/app_31.sh | grep -v 全局配置 >> /opt/tmall/Caddyfile
fi
echo "" >> /opt/tmall/Caddyfile
if [ "$demoui_enable" == "2" ] || [ "$demoui_enable" == "1" ] ; then
if [ "$demoui_enable" == "1" ] ; then
	logger -t "【demoui】" "启用 demoui + 启用 tmall 功能"
	cat /etc/storage/app_29.sh | grep -v 全局配置 >> /opt/tmall/Caddyfile
fi
if [ "$demoui_enable" == "2" ] ; then
	logger -t "【demoui】" "只启用 demoui ，停止 tmall 功能"
	cat /etc/storage/app_29.sh >> /opt/tmall/Caddyfile
fi
if [ "$app_118" != "$http_lanport" ] ; then
	logger -t "【demoui】" "变更真实 Web 服务访问端口 $lan_ipaddr:$app_118 ，需等待15秒"
	logger -t "【demoui】" "变更源地址由于网页有缓存导致显示异常，请按 ctrl+F5 强制刷新或清除缓存"
	logger -t "【demoui】" "变更源地址由于网页有缓存导致显示异常，请按 ctrl+F5 强制刷新或清除缓存 "
	nvram set http_tmp_lanport=$http_lanport
	nvram set http_lanport=$app_118
	sleep 2
	killall httpd 
	fi
else
logger -t "【demoui】" "停止 demoui "
fi
mkdir -p "/opt/tmall/www/aligenie"
cd /opt/tmall/www/aligenie
echo -n $(echo "$tmall_id" | awk -F \  '{print $2}') > ./$(echo "$(echo "$tmall_id" | awk -F \  '{print $1}')" | awk -F . '{print $1}').txt
chmod 444 /opt/tmall/www/aligenie/*

logger -t "【天猫精灵】" "运行 /opt/tmall/caddy_tmall"
eval "/opt/tmall/caddy_tmall run --config /opt/tmall/Caddyfile --adapter caddyfile $cmd_log" &
sleep 3
i_app_keep -t -name="tmall" -pidof="caddy_tmall" -cpath="/opt/tmall/caddy_tmall"
#tmall_get_status
eval "$scriptfilepath keep &"
exit 0
}

initconfig () {

app_13="/etc/storage/app_13.sh"
if [ ! -z "$(cat "$app_13" | grep rotate_size)" ] ; then
	logger -t "【天猫精灵】" "/etc/storage/app_13.old 备份旧配置，升级Caddy 2 不向后兼容 Caddy 1"
	cp -f "$app_13" /etc/storage/app_13.old
	rm -f "$app_13"
fi
if [ ! -f "$app_13" ] || [ ! -s "$app_13" ] ; then
	cat > "$app_13" <<-\EEE
# 此脚本路径：/etc/storage/app_13.sh
{ # 全局配置
order cgi before respond # 启动 cgi 模块 # 全局配置
admin off # 关闭 API 端口 # 全局配置
} # 全局配置

# 默认端口9321
:9321 {
 root * /opt/tmall/www
 # 默认cgi触发/abc123
 cgi /abc123 /opt/tmall/app_14.sh
 log {
  output file /opt/tmall/requests.log {
   roll_size     1MiB
   roll_local_time
   roll_keep     5
   roll_keep_for 120h
  }
 }
}
EEE
	chmod 755 "$app_13"
fi

app_14="/etc/storage/app_14.sh"
if [ ! -f "$app_14" ] || [ ! -s "$app_14" ] ; then
	cat > "$app_14" <<-\EEE
#!/bin/bash
# 此脚本路径：/etc/storage/app_14.sh
[ "POST" = "$REQUEST_METHOD" -a -n "$CONTENT_LENGTH" ] && read -n "$CONTENT_LENGTH" POST_DATA
POST_DATA2=$(echo "$POST_DATA" | sed "s/\///g" | sed "s/[[:space:]]//g" | grep -o "\"intentName\":\".*\"," | awk -F : '{print $2}'| awk -F , '{print $1}' | sed -e 's@"@@g')
REPLY_DATA="好的"
RUN_DATA="/tmp/tmall/RUN"
# 更多自定义命令请自行参考添加修改
if [ "$POST_DATA2" = "打开网络" ] ; then
  radio2_guest_enable
  radio5_guest_enable
  REPLY_DATA="打开网络"
fi

if [ "$POST_DATA2" = "停用网络" ] ; then
  radio2_guest_disable
  radio5_guest_disable
  REPLY_DATA="停用网络"
fi

if [ "$POST_DATA2" = "打开电脑" ] ; then
  # 下面的00:00:00:00:00:00改为电脑网卡地址即可唤醒
  ether-wake -b -i br0 00:00:00:00:00:00
  REPLY_DATA="打开电脑"
fi

if [ "$POST_DATA2" = "打开代理" ] ; then
  cat > "$RUN_DATA" <<-\RRR
  nvram set ss_status=0
  nvram set ss_enable=1
  nvram commit
  /tmp/script/_ss &
RRR
  REPLY_DATA="打开代理"
fi

if [ "$POST_DATA2" = "关闭代理" ] ; then
  cat > "$RUN_DATA" <<-\RRR
  nvram set ss_status=1
  nvram set ss_enable=0
  nvram commit
  /tmp/script/_ss &
RRR
  REPLY_DATA="关闭代理"
fi

if [ "$POST_DATA2" = "重启路由" ] ; then
  cat > "$RUN_DATA" <<-\RRR
  nvram commit
  /sbin/mtd_storage.sh save
  sync;echo 3 > /proc/sys/vm/drop_caches
  /bin/mtd_write -r unlock mtd1 #reboot
RRR
  REPLY_DATA="重启路由"
fi

if [ "$POST_DATA2" = "打开路由" ] ; then
  cat > "$RUN_DATA" <<-\RRR
  nvram set app_117=1
  nvram commit
  Sh63_t_mall.sh &
RRR
  REPLY_DATA="打开路由"
fi

if [ "$POST_DATA2" = "关闭路由" ] ; then
  cat > "$RUN_DATA" <<-\RRR
  nvram set app_117=0
  nvram commit
  Sh63_t_mall.sh &
RRR
  REPLY_DATA="关闭路由"
fi

if [ "$POST_DATA2" = "重置路由" ] ; then
  cat > "$RUN_DATA" <<-\RRR
  /sbin/mtd_storage.sh reset
  nvram set restore_defaults=1
  nvram commit
  /sbin/mtd_storage.sh save
  sync;echo 3 > /proc/sys/vm/drop_caches
  /bin/mtd_write -r unlock mtd1 #reboot
RRR
  REPLY_DATA="重置路由"
fi

printf "Content-type: text/plain\n\n"
echo "{
    \"returnCode\": \"0\",
    \"returnErrorSolution\": \"\",
    \"returnMessage\": \"\",
    \"returnValue\": {
        \"reply\": \"$REPLY_DATA\",
        \"resultType\": \"RESULT\",
        \"actions\": [
            {
                \"name\": \"audioPlayGenieSource\",
                \"properties\": {
                    \"audioGenieId\": \"123\"
                }
            }
        ],
        \"properties\": {},
        \"executeCode\": \"SUCCESS\",
        \"msgInfo\": \"\"
    }
}"

logger -t "【天猫精灵】" "$REPLY_DATA"
exit 0

EEE
	chmod 755 "$app_14"
fi

app_29="/etc/storage/app_29.sh"
if [ ! -z "$(cat "$app_29" | grep transparent)" ] ; then
	logger -t "【天猫精灵】" "/etc/storage/app_29.old 备份旧配置，升级Caddy 2 不向后兼容 Caddy 1"
	cp -f "$app_29" /etc/storage/app_29.old
	rm -f "$app_29"
fi
if [ ! -f "$app_29" ] || [ ! -s "$app_29" ] ; then
	cat > "$app_29" <<-\EEE
# 此脚本路径：/etc/storage/app_29.sh
{ # 全局配置
admin off # 关闭 API 端口 # 全局配置
} # 全局配置

:80 {
  reverse_proxy * demoui.asus.com 
}

EEE
	chmod 755 "$app_29"
fi

app_31="/etc/storage/app_31.sh"
if [ ! -z "$(cat "$app_31" | grep rotate_size)" ] ; then
	logger -t "【wxsend推送】" "/etc/storage/app_31.old 备份旧配置，升级Caddy 2 不向后兼容 Caddy 1"
	cp -f "$app_31" /etc/storage/app_31.old
	rm -f "$app_31"
fi
if [ ! -f "$app_31" ] || [ ! -s "$app_31" ] ; then
	cat > "$app_31" <<-\EEE
# 此脚本路径：/etc/storage/app_31.sh
{ # 全局配置
order cgi before respond # 启动 cgi 模块 # 全局配置
admin off # 关闭 API 端口 # 全局配置
} # 全局配置

:0 {
 root * /opt/tmall/www
 # cgi触发 /key
 #cgi /111111111111/* /etc/storage/script/Sh45_wx_send.sh # 脚本自动生成/key
 log {
  output file /opt/tmall/requests_wxsend.log {
   roll_size     1MiB
   roll_local_time
   roll_keep     5
   roll_keep_for 120h
  }
}

EEE
	chmod 755 "$app_31"
fi

}

initconfig

update_app () {
mkdir -p /opt/app/tmall
if [ "$1" = "update_asp" ] ; then
	rm -rf /opt/app/tmall/Advanced_Extensions_tmall.asp
fi
if [ "$1" = "del" ] ; then
	rm -rf /opt/app/tmall/Advanced_Extensions_tmall.asp
fi

initconfig

# 加载程序配置页面
if [ ! -f "/opt/app/tmall/Advanced_Extensions_tmall.asp" ] || [ ! -s "/opt/app/tmall/Advanced_Extensions_tmall.asp" ] ; then
	wgetcurl.sh /opt/app/tmall/Advanced_Extensions_tmall.asp "$hiboyfile/Advanced_Extensions_tmallasp" "$hiboyfile2/Advanced_Extensions_tmallasp"
fi
umount /www/Advanced_Extensions_app13.asp
mount --bind /opt/app/tmall/Advanced_Extensions_tmall.asp /www/Advanced_Extensions_app13.asp
# 更新程序启动脚本

[ "$1" = "del" ] && /etc/storage/www_sh/tmall del &
}

case $ACTION in
start)
	tmall_close
	tmall_check
	;;
check)
	tmall_check
	;;
stop)
	tmall_close
	;;
updateapp13)
	tmall_restart o
	[ "$tmall_enable" = "1" ] && nvram set tmall_status="updatetmall" && logger -t "【tmall】" "重启" && tmall_restart
	[ "$tmall_enable" != "1" ] && nvram set tmall_v="" && logger -t "【tmall】" "更新" && update_app del
	;;
update_app)
	update_app
	;;
update_asp)
	update_app update_asp
	;;
keep)
	#tmall_check
	tmall_keep
	;;
*)
	tmall_check
	;;
esac

