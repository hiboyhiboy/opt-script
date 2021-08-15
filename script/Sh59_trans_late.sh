#!/bin/bash
#copyright by hiboy
source /etc/storage/script/init.sh
translate_enable=`nvram get app_44`
[ -z $translate_enable ] && translate_enable=0 && nvram set app_44=0
translate_type=`nvram get app_45`
[ -z $translate_type ] && translate_type=0 && nvram set app_45=0
http_lanport=`nvram get http_lanport`
[ -z $http_lanport ] && http_lanport=80 && nvram set http_lanport=80
#if [ "$translate_enable" != "0" ] ; then
#nvramshow=`nvram showall | grep '=' | grep translate | awk '{print gensub(/'"'"'/,"'"'"'\"'"'"'\"'"'"'","g",$0);}'| awk '{print gensub(/=/,"='\''",1,$0)"'\'';";}'` && eval $nvramshow
#fi

dir_name="/opt/app/translate/"

if [ ! -z "$(echo $scriptfilepath | grep -v "/tmp/script/" | grep trans_late)" ]  && [ ! -s /tmp/script/_app11 ]; then
	mkdir -p /tmp/script
	{ echo '#!/bin/bash' ; echo $scriptfilepath '"$@"' '&' ; } > /tmp/script/_app11
	chmod 777 /tmp/script/_app11
fi

translate_restart () {

relock="/var/lock/translate_restart.lock"
if [ "$1" = "o" ] ; then
	nvram set translate_renum="0"
	[ -f $relock ] && rm -f $relock
	return 0
fi
if [ "$1" = "x" ] ; then
	if [ -f $relock ] ; then
		logger -t "【translate】" "多次尝试启动失败，等待【"`cat $relock`"分钟】后自动尝试重新启动"
		exit 0
	fi
	translate_renum=${translate_renum:-"0"}
	translate_renum=`expr $translate_renum + 1`
	nvram set translate_renum="$translate_renum"
	if [ "$translate_renum" -gt "2" ] ; then
		I=19
		echo $I > $relock
		logger -t "【translate】" "多次尝试启动失败，等待【"`cat $relock`"分钟】后自动尝试重新启动"
		while [ $I -gt 0 ]; do
			I=$(($I - 1))
			echo $I > $relock
			sleep 60
			[ "$(nvram get translate_renum)" = "0" ] && exit 0
			[ $I -lt 0 ] && break
		done
		nvram set translate_renum="0"
	fi
	[ -f $relock ] && rm -f $relock
fi
nvram set translate_status=0
eval "$scriptfilepath &"
exit 0
}

translate_get_status () {

A_restart=`nvram get translate_status`
B_restart="$translate_enable$translate_type"
B_restart=`echo -n "$B_restart" | md5sum | sed s/[[:space:]]//g | sed s/-//g`
cut_B_re
if [ "$A_restart" != "$B_restart" ] ; then
	nvram set translate_status=$B_restart
	needed_restart=1
else
	needed_restart=0
fi
}

translate_check () {

translate_get_status
if [ "$translate_enable" != "1" ] && [ "$needed_restart" = "1" ] ; then
	www_translate_CN
	{ kill_ps "$scriptname" exit0; exit 0; }
fi
if [ "$translate_enable" = "1" ] ; then
	if [ "$needed_restart" = "1" ] ; then
		nvram set preferred_lang=EN
		translate_close
		translate_start
	fi
fi
}

translate_keep () {
logger -t "【translate】" "开始translate"
if [ "$translate_type" = "0" ]; then
#English
www_translate_EN
fi
if [ "$translate_type" = "1" ]; then
#简体中文
www_translate_CN
fi
if [ "$translate_type" = "2" ]; then
#Українська
www_translate_UK
fi
if [ "$translate_type" = "3" ]; then
#Español
www_translate_ES
fi
if [ "$translate_type" = "4" ]; then
#Brazil
www_translate_BR
fi
if [ "$translate_type" = "5" ]; then
#Svensk
www_translate_SV
fi
if [ "$translate_type" = "6" ]; then
#Dansk
www_translate_DA
fi
if [ "$translate_type" = "7" ]; then
#Finsk
www_translate_FI
fi
if [ "$translate_type" = "8" ]; then
#Norsk
www_translate_NO
fi
if [ "$translate_type" = "9" ]; then
#Français
www_translate_FR
fi
if [ "$translate_type" = "10" ]; then
#Deutsch
www_translate_DE
fi
if [ "$translate_type" = "11" ]; then
#Pусский
www_translate_RU
fi
if [ "$translate_type" = "12" ]; then
#Polski
www_translate_PL
fi
if [ "$translate_type" = "13" ]; then
#Česky
www_translate_CZ
fi
if [ "$translate_type" = "14" ]; then
#繁体中文
www_translate_FT
fi
logger -t "【translate】" "完成translate"
}

translate_close () {

kill_ps "$scriptname keep"
sed -Ei '/【translate】|^$/d' /tmp/script/_opt_script_check
kill_ps "/tmp/script/_app11"
kill_ps "_trans_late.sh"
kill_ps "$scriptname"
}

translate_start () {

check_webui_yes
initopt
#translate_get_status
eval "$scriptfilepath keep &"
translate_restart o
exit 0
}

initopt () {
optPath=`grep ' /opt ' /proc/mounts | grep tmpfs`
[ ! -z "$optPath" ] && return
if [ ! -z "$(echo $scriptfilepath | grep -v "/opt/etc/init")" ] && [ -s "/opt/etc/init.d/rc.func" ] ; then
	{ echo '#!/bin/bash' ; echo $scriptfilepath '"$@"' '&' ; } > /opt/etc/init.d/$scriptname && chmod 777  /opt/etc/init.d/$scriptname
fi

}

www_umount () {

rm -rf /opt/app/translate/www
rm -rf /opt/app/translate/app
umount /www/EN.dict

}

www_mount () {

mount --bind /opt/app/translate/$1.dict /www/EN.dict

}

www_rehttpd () {

chmod 777 -R "/opt/app/translate/"
/etc/storage/www_sh/menu_title.sh
killall httpd 
killall -9 httpd 
#/usr/sbin/httpd -p $http_lanport

}

www_translate_EN () {

www_umount
base_name="EN.dict"
if [ ! -s "$dir_name$base_name" ] ; then
	logger -t "【translate】" "找不到 $dir_name$base_name ，开始下载"
	wgetcurl.sh "$dir_name$base_name" "$hiboyfile/$base_name" "$hiboyfile2/$base_name"
fi
www_mount EN
www_rehttpd

}

www_translate_CN () {

www_umount
www_rehttpd
}

www_translate_UK () {

www_umount
base_name="UK.dict"
if [ ! -s "$dir_name$base_name" ] ; then
	logger -t "【translate】" "找不到 $dir_name$base_name ，开始下载"
	wgetcurl.sh "$dir_name$base_name" "$hiboyfile/$base_name" "$hiboyfile2/$base_name"
fi
www_mount UK
www_rehttpd

}

www_translate_ES () {

www_umount
base_name="ES.dict"
if [ ! -s "$dir_name$base_name" ] ; then
	logger -t "【translate】" "找不到 $dir_name$base_name ，开始下载"
	wgetcurl.sh "$dir_name$base_name" "$hiboyfile/$base_name" "$hiboyfile2/$base_name"
fi
www_mount ES
www_rehttpd

}

www_translate_BR () {

www_umount
base_name="BR.dict"
if [ ! -s "$dir_name$base_name" ] ; then
	logger -t "【translate】" "找不到 $dir_name$base_name ，开始下载"
	wgetcurl.sh "$dir_name$base_name" "$hiboyfile/$base_name" "$hiboyfile2/$base_name"
fi
www_mount BR
www_rehttpd

}

www_translate_SV () {

www_umount
base_name="SV.dict"
if [ ! -s "$dir_name$base_name" ] ; then
	logger -t "【translate】" "找不到 $dir_name$base_name ，开始下载"
	wgetcurl.sh "$dir_name$base_name" "$hiboyfile/$base_name" "$hiboyfile2/$base_name"
fi
www_mount SV
www_rehttpd

}

www_translate_DA () {

www_umount
base_name="DA.dict"
if [ ! -s "$dir_name$base_name" ] ; then
	logger -t "【translate】" "找不到 $dir_name$base_name ，开始下载"
	wgetcurl.sh "$dir_name$base_name" "$hiboyfile/$base_name" "$hiboyfile2/$base_name"
fi
www_mount DA
www_rehttpd

}

www_translate_FI () {

www_umount
base_name="FI.dict"
if [ ! -s "$dir_name$base_name" ] ; then
	logger -t "【translate】" "找不到 $dir_name$base_name ，开始下载"
	wgetcurl.sh "$dir_name$base_name" "$hiboyfile/$base_name" "$hiboyfile2/$base_name"
fi
www_mount FI
www_rehttpd

}

www_translate_NO () {

www_umount
base_name="NO.dict"
if [ ! -s "$dir_name$base_name" ] ; then
	logger -t "【translate】" "找不到 $dir_name$base_name ，开始下载"
	wgetcurl.sh "$dir_name$base_name" "$hiboyfile/$base_name" "$hiboyfile2/$base_name"
fi
www_mount NO
www_rehttpd

}

www_translate_FR () {

www_umount
base_name="FR.dict"
if [ ! -s "$dir_name$base_name" ] ; then
	logger -t "【translate】" "找不到 $dir_name$base_name ，开始下载"
	wgetcurl.sh "$dir_name$base_name" "$hiboyfile/$base_name" "$hiboyfile2/$base_name"
fi
www_mount FR
www_rehttpd

}

www_translate_DE () {

www_umount
base_name="DE.dict"
if [ ! -s "$dir_name$base_name" ] ; then
	logger -t "【translate】" "找不到 $dir_name$base_name ，开始下载"
	wgetcurl.sh "$dir_name$base_name" "$hiboyfile/$base_name" "$hiboyfile2/$base_name"
fi
www_mount DE
www_rehttpd

}

www_translate_RU () {

www_umount
base_name="RU.dict"
if [ ! -s "$dir_name$base_name" ] ; then
	logger -t "【translate】" "找不到 $dir_name$base_name ，开始下载"
	wgetcurl.sh "$dir_name$base_name" "$hiboyfile/$base_name" "$hiboyfile2/$base_name"
fi
www_mount RU
www_rehttpd

}

www_translate_PL () {

www_umount
base_name="PL.dict"
if [ ! -s "$dir_name$base_name" ] ; then
	logger -t "【translate】" "找不到 $dir_name$base_name ，开始下载"
	wgetcurl.sh "$dir_name$base_name" "$hiboyfile/$base_name" "$hiboyfile2/$base_name"
fi
www_mount PL
www_rehttpd

}

www_translate_CZ () {

www_umount
base_name="CZ.dict"
if [ ! -s "$dir_name$base_name" ] ; then
	logger -t "【translate】" "找不到 $dir_name$base_name ，开始下载"
	wgetcurl.sh "$dir_name$base_name" "$hiboyfile/$base_name" "$hiboyfile2/$base_name"
fi
www_mount CZ
www_rehttpd

}

www_translate_FT () {

www_umount
base_name="FT.dict"
if [ ! -s "$dir_name$base_name" ] ; then
	logger -t "【translate】" "找不到 $dir_name$base_name ，开始下载"
	wgetcurl.sh "$dir_name$base_name" "$hiboyfile/$base_name" "$hiboyfile2/$base_name"
fi
www_mount FT
www_rehttpd

}
initconfig () {

mkdir -p /opt/app/translate/
chmod 777 -R "/opt/app/translate/"
}

initconfig

update_app () {
mkdir -p /opt/app/translate
if [ "$1" = "update_asp" ] ; then
	rm -rf /opt/app/translate/Advanced_Extensions_translate.asp
fi
if [ "$1" = "del" ] ; then
	rm -rf /opt/app/translate/Advanced_Extensions_translate.asp
	[ -f /opt/bin/translate ] && rm -f /opt/bin/translate
fi

initconfig

# 加载程序配置页面
if [ ! -f "/opt/app/translate/Advanced_Extensions_translate.asp" ] || [ ! -s "/opt/app/translate/Advanced_Extensions_translate.asp" ] ; then
	wgetcurl.sh /opt/app/translate/Advanced_Extensions_translate.asp "$hiboyfile/Advanced_Extensions_translateasp" "$hiboyfile2/Advanced_Extensions_translateasp"
fi
umount /www/Advanced_Extensions_app11.asp
mount --bind /opt/app/translate/Advanced_Extensions_translate.asp /www/Advanced_Extensions_app11.asp
# 更新程序启动脚本

[ "$1" = "del" ] && /etc/storage/www_sh/translate del &
}

case $ACTION in
start)
	translate_close
	translate_check
	;;
check)
	translate_check
	;;
stop)
	translate_close
	;;
updateapp11)
	translate_restart o
	[ "$translate_enable" = "1" ] && nvram set translate_status="updatetranslate" && logger -t "【translate】" "重启" && translate_restart
	[ "$translate_enable" != "1" ] && nvram set translate_v="" && logger -t "【translate】" "更新" && update_app del
	;;
update_app)
	update_app
	;;
update_asp)
	update_app update_asp
	;;
keep)
	#translate_check
	translate_keep
	;;
initconfig)
	initconfig
	;;
*)
	translate_check
	;;
esac

