#!/bin/bash
#copyright by hiboy
source /etc/storage/script/init.sh
printer_enable=`nvram get app_10`
[ -z $printer_enable ] && printer_enable=0 && nvram set app_10=0
if [ "$printer_enable" != "0" ] ; then

printer_fw=`nvram get app_11`
printer_customfw=`nvram get app_12`
app_13=`nvram get app_13`
printer_md5=`nvram get printer_md5`
if [ "$app_13" = "1" ] ; then
printer_opt="/opt/app/printer/"
else
printer_opt="/etc/storage/printer/"
fi
printer_path=""
printer_sh="/opt/bin/on_hotplug_printer.sh"
printer_renum=`nvram get printer_renum`

fi

if [ ! -z "$(echo $scriptfilepath | grep -v "/tmp/script/" | grep printer)" ] && [ ! -s /tmp/script/_app4 ] ; then
	mkdir -p /tmp/script
	{ echo '#!/bin/bash' ; echo $scriptfilepath '"$@"' '&' ; } > /tmp/script/_app4
	chmod 777 /tmp/script/_app4
fi

printer_restart () {
i_app_restart "$@" -name="printer"
}

printer_get_status () {

B_restart="$printer_enable$printer_fw$printer_customfw$app_13"

i_app_get_status -name="printer" -valb="$B_restart"
}

printer_check () {

printer_get_status
if [ "$printer_enable" != "1" ] && [ "$needed_restart" = "1" ] ; then
	[ ! -z "$(ps -w | grep "$scriptname keep" | grep -v grep )" ] && logger -t "【printer】" "停止 printer" && printer_close
	{ kill_ps "$scriptname" exit0; exit 0; }
fi
if [ "$printer_enable" = "1" ] ; then
	if [ "$needed_restart" = "1" ] ; then
		printer_close
		eval "$scriptfilepath keep &"
		exit 0
	else
		[ -z "$(ps -w | grep "$scriptname keep" | grep -v grep )" ] && printer_restart
	fi
fi
}

printer_keep () {
printer_start
i_app_keep -name="printer" -pidof="Sh27_printer.sh" &
while true; do
sleep 127
[ ! -s "$printer_path" ] && printer_restart
printer_enable=`nvram get app_10`
[ "$printer_enable" = "0" ] && printer_close && exit 0;
if [ "$printer_enable" = "1" ] ; then
	printer_start
fi
done
}

printer_close () {
sed -Ei '/【printer】|^$/d' /tmp/script/_opt_script_check
kill_ps "$scriptname keep"
kill_ps "/tmp/script/_printer"
kill_ps "_printer.sh"
kill_ps "$scriptname"
}

printer_start () {
check_webui_yes
[ -z "$(cat "$printer_sh" | grep "$(echo $printer_md5 | awk '{print $2;}')")" ] && rm -rf /tmp/printer_load
if [ ! -d /opt/app/printer ] || [ ! -s "$printer_sh" ] ; then
	logger -t "【printer】" "找不到 /opt/app/printer ，安装 opt 程序"
	/etc/storage/script/Sh01_mountopt.sh start
	initopt
	mkdir -p /opt/app/printer/
fi
[ ! -s "$printer_sh" ] && initconfig
[ ! -d "$printer_opt" ] && mkdir -p "$printer_opt"
if [ "$printer_fw" != "custom" ] ; then
	# 固件包选择
	[ "$printer_fw" = "auto" ] && auto_match
	printer_path="$printer_opt""$printer_fw"
	if [ ! -f "$printer_path" ] ; then
		rm -rf /tmp/printer_load /etc/storage/printer/*.dl
		wgetcurl_checkmd5 "$printer_path" "$hiboyfile/printer/$printer_fw" "$hiboyfile2/printer/$printer_fw" N
		set_md5
	fi
	if [ ! -f "$printer_path" ] ; then
		rm -rf /etc/storage/printer/*.dl
		wgetcurl_checkmd5 "$printer_path" "https://bitbucket.org/padavan/rt-n56u/wiki/files/hplj/$printer_fw" "http://oleg.wl500g.info/hplj/$printer_fw" N
		set_md5
	fi
fi
if [ "$printer_fw" = "custom" ] ; then
	# 自定义固件
	if [ -z "$(echo "$printer_customfw" | grep "^/")" ] ; then
		# 自定义固件 下载地址
		printer_path="$printer_opt""customfw.dl"
		if [ ! -f "$printer_path" ] ; then
			rm -rf /tmp/printer_load /etc/storage/printer/*.dl
			wgetcurl_checkmd5 "$printer_path" "$printer_customfw" "$printer_customfw" N
			set_md5
		fi
	else
		# 自定义固件 文件路径
		printer_path="$printer_customfw"
		set_md5
	fi
fi
if [ -f "$printer_path" ] ; then
	check_md5
	if [ -z "$(cat "$printer_sh" | grep $printer_path)" ] ; then
		# 写入固件路径
		logger -t "【printer】" "使用固件路径：$printer_path"
		sed -e "s|^\(lpfw.*\)=[^=]*$|\1=\"$printer_path\"|" -i "$printer_sh"
		chmod 755 "$printer_path"
		logger -t "【printer】" "若无法驱动，请重新插入 USB 打印机！"
		rm -rf /tmp/printer_load
	fi
else
	logger -t "【printer】" "设置失败，找不到 固件文件：$printer_path"
	printer_restart x
fi
if [ ! -f /tmp/printer_load ] ; then
for i in `/usr/bin/find /dev/usb -name 'lp*'` ; do
	[ -z "${i}" ] && continue
	$printer_sh "${i}"
	touch /tmp/printer_load
	logger -t "【printer】" "载入固件文件： $printer_path > ${i}"
done
fi
	
}

auto_match () {
syslog="$(cat /tmp/syslog.log | tr 'A-Z' 'a-z' | grep "kernel:")"
printer_fw="err"
[ ! -z "$(echo "$syslog" | grep "03f0" | grep "0517")" ] && printer_fw="sihp1000.dl"
[ ! -z "$(echo "$syslog" | grep "03f0" | grep "1317")" ] && printer_fw="sihp1005.dl"
[ ! -z "$(echo "$syslog" | grep "03f0" | grep "4117")" ] && printer_fw="sihp1018.dl"
[ ! -z "$(echo "$syslog" | grep "03f0" | grep "2b17")" ] && printer_fw="sihp1020.dl"
[ ! -z "$(echo "$syslog" | grep "03f0" | grep "3d17")" ] && printer_fw="sihpP1005.dl"
[ ! -z "$(echo "$syslog" | grep "03f0" | grep "3e17")" ] && printer_fw="sihpP1006.dl"
[ ! -z "$(echo "$syslog" | grep "03f0" | grep "4817")" ] && printer_fw="sihpP1005.dl"
[ ! -z "$(echo "$syslog" | grep "03f0" | grep "4917")" ] && printer_fw="sihpP1006.dl"
[ ! -z "$(echo "$syslog" | grep "03f0" | grep "3f17")" ] && printer_fw="sihpP1505.dl"
if [ "$printer_fw" = "err" ] ; then
logger -t "【printer】" "固件自动匹配失败，找不到对应型号，请手动配置"
printer_restart x
fi
nvram set app_11="$printer_fw"
printer_get_status

}

set_md5 () {
if [ -f "$printer_path" ] ; then
printer_tmpmd5="$(md5sum $printer_path )"
if [ "$printer_md5" != "$printer_tmpmd5" ] ; then
printer_md5="$(md5sum $printer_path )"
nvram set printer_md5="$printer_md5"
logger -t "【printer】" "固件md5：$printer_md5"
fi
fi

}

check_md5 () {
printer_tmpmd5="$(md5sum $printer_path )"
if [ "$printer_md5" != "$printer_tmpmd5" ] ; then
logger -t "【printer】" "错误，固件md5不匹配！ 固件文件：$printer_path"
rm -rf /opt/app/printer/*.dl
rm -rf /etc/storage/printer/*.dl
printer_restart x
fi

}

update_app () {
mkdir -p /opt/app/printer
if [ "$1" = "update_asp" ] ; then
	rm -rf /opt/app/printer/Advanced_Extensions_printer.asp
fi
if [ "$1" = "del" ] ; then
	rm -rf /opt/app/printer/Advanced_Extensions_printer.asp
	rm -rf /opt/app/printer/*.dl
	rm -rf /etc/storage/printer/*.dl
fi

# 加载程序配置页面
if [ ! -f "/opt/app/printer/Advanced_Extensions_printer.asp" ] || [ ! -s "/opt/app/printer/Advanced_Extensions_printer.asp" ] ; then
	wgetcurl.sh /opt/app/printer/Advanced_Extensions_printer.asp "$hiboyfile/Advanced_Extensions_printerasp" "$hiboyfile2/Advanced_Extensions_printerasp"
fi
umount /www/Advanced_Extensions_app04.asp
mount --bind /opt/app/printer/Advanced_Extensions_printer.asp /www/Advanced_Extensions_app04.asp
# 更新程序启动脚本

[ "$1" = "del" ] && /etc/storage/www_sh/连接打印机 del &
}

initconfig () {
if [ ! -s "$printer_sh" ] && [ -d /opt/bin/ ] ; then
cat > "$printer_sh" <<-\EEE
#!/bin/bash

[ -z "$1" ] && exit 1

### Custom user script for printer hotplug event handling
### First param is /dev/usb/lp[0-9]

### Example: load firmware to printer HP LJ1020
lpfw="/opt/share/firmware/sihp1020.dl"
if [ -r "$lpfw" ] ; then
	cat "$lpfw" > "$1"
fi

EEE
	chmod 755 "$printer_sh"
fi

}

initconfig

case $ACTION in
start)
	printer_close
	printer_check
	;;
check)
	printer_check
	;;
stop)
	printer_close
	;;
keep)
	printer_keep
	;;
updateapp4)
	printer_restart o
	[ "$printer_enable" = "1" ] && nvram set printer_status="updateprinter" && logger -t "【printer】" "重启" && printer_restart
	[ "$printer_enable" != "1" ] && nvram set printer_v="" && logger -t "【printer】" "更新" && update_app del
	;;
*)
	printer_check
	;;
esac

