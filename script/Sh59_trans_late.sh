#!/bin/sh
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
	{ echo '#!/bin/sh' ; echo $scriptfilepath '"$@"' '&' ; } > /tmp/script/_app11
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

sed -Ei '/【translate】|^$/d' /tmp/script/_opt_script_check
kill_ps "/tmp/script/_app11"
kill_ps "_trans_late.sh"
kill_ps "$scriptname"
}

translate_start () {

check_webui_yes
dir_name="/opt/app/translate/"
base_name="translate_app_EN.txt"
if [ ! -s "$dir_name$base_name" ] ; then
	logger -t "【translate】" "找不到 $dir_name$base_name ，开始下载"
	wgetcurl.sh "$dir_name$base_name" "$hiboyfile/$base_name" "$hiboyfile2/$base_name"
fi
base_name="translate_map_EN.txt"
if [ ! -s "$dir_name$base_name" ] ; then
	logger -t "【translate】" "找不到 $dir_name$base_name ，开始下载"
	wgetcurl.sh "$dir_name$base_name" "$hiboyfile/$base_name" "$hiboyfile2/$base_name"
fi
base_name="translate_www_EN.txt"
if [ ! -s "$dir_name$base_name" ] ; then
	logger -t "【translate】" "找不到 $dir_name$base_name ，开始下载"
	wgetcurl.sh "$dir_name$base_name" "$hiboyfile/$base_name" "$hiboyfile2/$base_name"
fi

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
	{ echo '#!/bin/sh' ; echo $scriptfilepath '"$@"' '&' ; } > /opt/etc/init.d/$scriptname && chmod 777  /opt/etc/init.d/$scriptname
fi

}

www_umount () {

umount /www/help.js
umount /www/as2.asp
umount /www/Advanced_Tweaks_Content.asp
umount /www/Advanced_System_Content.asp
umount /www/Advanced_Extensions_wifidog.asp
umount /www/Advanced_Extensions_v2ray.asp
umount /www/Advanced_Extensions_softether.asp
umount /www/Advanced_Extensions_shellinabox.asp
umount /www/Advanced_Extensions_script.asp
umount /www/Advanced_Extensions_qcloud.asp
umount /www/Advanced_Extensions_phddns.asp
umount /www/Advanced_Extensions_ngrok.asp
umount /www/Advanced_Extensions_mentohust.asp
umount /www/Advanced_Extensions_lnmp.asp
umount /www/Advanced_Extensions_koolproxy.asp
umount /www/Advanced_Extensions_frp.asp
umount /www/Advanced_Extensions_display.asp
umount /www/Advanced_Extensions_cloudflare.asp
umount /www/Advanced_Extensions_aliddns.asp
umount /www/Advanced_Extensions_adm.asp
umount /www/Advanced_Extensions_adbyby.asp
umount /www/Advanced_Extensions_ServerChan.asp
umount /www/Advanced_Extensions_SS_list.asp
umount /www/Advanced_Extensions_SS_Server.asp
umount /www/Advanced_Extensions_SS_Kcptun.asp
umount /www/Advanced_Extensions_SSR_Server.asp
umount /www/Advanced_Extensions_SS.asp
umount /www/Advanced_Extensions_MEOW.asp
umount /www/Advanced_Extensions_DNSPod.asp
umount /www/Advanced_Extensions_CloudXNS.asp
umount /www/Advanced_Extensions_COW.asp

umount /www/device-map/ssinfo.asp
umount /www/device-map/ss.asp
umount /www/device-map/sata.asp
umount /www/device-map/printer.asp
umount /www/device-map/hub.asp
umount /www/device-map/disk.asp

umount /opt/app/virtualhere/Advanced_Extensions_virtualhere.asp
umount /opt/app/verysync/Advanced_Extensions_verysync.asp
umount /opt/app/upd2pro/Advanced_Extensions_upd2pro.asp
umount /opt/app/transocks/Advanced_Extensions_transocks.asp
umount /opt/app/speedup/Advanced_Extensions_speedup.asp
umount /opt/app/guestkit/Advanced_Extensions_guestkit.asp
umount /opt/app/goflyway/Advanced_Extensions_goflyway.asp
umount /opt/app/filemanager/Advanced_Extensions_filemanager.asp
umount /opt/app/fakeincn/Advanced_Extensions_fakeincn.asp
umount /opt/app/chinadns/Advanced_Extensions_chinadns.asp
umount /opt/app/translate/Advanced_Extensions_translate.asp
umount /opt/app/tgbot/Advanced_Extensions_tgbot.asp

umount /www/EN.dict

}

www_cp () {

rm -rf /opt/app/translate/www/device-map/*
cp -f /www/device-map/ssinfo.asp /opt/app/translate/www/device-map/ssinfo.asp
cp -f /www/device-map/ss.asp /opt/app/translate/www/device-map/ss.asp
cp -f /www/device-map/sata.asp /opt/app/translate/www/device-map/sata.asp
cp -f /www/device-map/printer.asp /opt/app/translate/www/device-map/printer.asp
cp -f /www/device-map/hub.asp /opt/app/translate/www/device-map/hub.asp
cp -f /www/device-map/disk.asp /opt/app/translate/www/device-map/disk.asp

rm -rf /opt/app/translate/www/*
cp -f /www/help.js /opt/app/translate/www/help.js
cp -f /www/as2.asp /opt/app/translate/www/as2.asp
cp -f /www/Advanced_Tweaks_Content.asp /opt/app/translate/www/Advanced_Tweaks_Content.asp
cp -f /www/Advanced_System_Content.asp /opt/app/translate/www/Advanced_System_Content.asp
cp -f /www/Advanced_Extensions_wifidog.asp /opt/app/translate/www/Advanced_Extensions_wifidog.asp
cp -f /www/Advanced_Extensions_v2ray.asp /opt/app/translate/www/Advanced_Extensions_v2ray.asp
cp -f /www/Advanced_Extensions_softether.asp /opt/app/translate/www/Advanced_Extensions_softether.asp
cp -f /www/Advanced_Extensions_shellinabox.asp /opt/app/translate/www/Advanced_Extensions_shellinabox.asp
cp -f /www/Advanced_Extensions_script.asp /opt/app/translate/www/Advanced_Extensions_script.asp
cp -f /www/Advanced_Extensions_qcloud.asp /opt/app/translate/www/Advanced_Extensions_qcloud.asp
cp -f /www/Advanced_Extensions_phddns.asp /opt/app/translate/www/Advanced_Extensions_phddns.asp
cp -f /www/Advanced_Extensions_ngrok.asp /opt/app/translate/www/Advanced_Extensions_ngrok.asp
cp -f /www/Advanced_Extensions_mentohust.asp /opt/app/translate/www/Advanced_Extensions_mentohust.asp
cp -f /www/Advanced_Extensions_lnmp.asp /opt/app/translate/www/Advanced_Extensions_lnmp.asp
cp -f /www/Advanced_Extensions_koolproxy.asp /opt/app/translate/www/Advanced_Extensions_koolproxy.asp
cp -f /www/Advanced_Extensions_frp.asp /opt/app/translate/www/Advanced_Extensions_frp.asp
cp -f /www/Advanced_Extensions_display.asp /opt/app/translate/www/Advanced_Extensions_display.asp
cp -f /www/Advanced_Extensions_cloudflare.asp /opt/app/translate/www/Advanced_Extensions_cloudflare.asp
cp -f /www/Advanced_Extensions_aliddns.asp /opt/app/translate/www/Advanced_Extensions_aliddns.asp
cp -f /www/Advanced_Extensions_adm.asp /opt/app/translate/www/Advanced_Extensions_adm.asp
cp -f /www/Advanced_Extensions_adbyby.asp /opt/app/translate/www/Advanced_Extensions_adbyby.asp
cp -f /www/Advanced_Extensions_ServerChan.asp /opt/app/translate/www/Advanced_Extensions_ServerChan.asp
cp -f /www/Advanced_Extensions_SS_list.asp /opt/app/translate/www/Advanced_Extensions_SS_list.asp
cp -f /www/Advanced_Extensions_SS_Server.asp /opt/app/translate/www/Advanced_Extensions_SS_Server.asp
cp -f /www/Advanced_Extensions_SS_Kcptun.asp /opt/app/translate/www/Advanced_Extensions_SS_Kcptun.asp
cp -f /www/Advanced_Extensions_SSR_Server.asp /opt/app/translate/www/Advanced_Extensions_SSR_Server.asp
cp -f /www/Advanced_Extensions_SS.asp /opt/app/translate/www/Advanced_Extensions_SS.asp
cp -f /www/Advanced_Extensions_MEOW.asp /opt/app/translate/www/Advanced_Extensions_MEOW.asp
cp -f /www/Advanced_Extensions_DNSPod.asp /opt/app/translate/www/Advanced_Extensions_DNSPod.asp
cp -f /www/Advanced_Extensions_CloudXNS.asp /opt/app/translate/www/Advanced_Extensions_CloudXNS.asp
cp -f /www/Advanced_Extensions_COW.asp /opt/app/translate/www/Advanced_Extensions_COW.asp

rm -rf /opt/app/translate/app/*
cp -f /opt/app/virtualhere/Advanced_Extensions_virtualhere.asp /opt/app/translate/app/Advanced_Extensions_virtualhere.asp
cp -f /opt/app/verysync/Advanced_Extensions_verysync.asp /opt/app/translate/app/Advanced_Extensions_verysync.asp
cp -f /opt/app/upd2pro/Advanced_Extensions_upd2pro.asp /opt/app/translate/app/Advanced_Extensions_upd2pro.asp
cp -f /opt/app/transocks/Advanced_Extensions_transocks.asp /opt/app/translate/app/Advanced_Extensions_transocks.asp
cp -f /opt/app/speedup/Advanced_Extensions_speedup.asp /opt/app/translate/app/Advanced_Extensions_speedup.asp
cp -f /opt/app/guestkit/Advanced_Extensions_guestkit.asp /opt/app/translate/app/Advanced_Extensions_guestkit.asp
cp -f /opt/app/goflyway/Advanced_Extensions_goflyway.asp /opt/app/translate/app/Advanced_Extensions_goflyway.asp
cp -f /opt/app/filemanager/Advanced_Extensions_filemanager.asp /opt/app/translate/app/Advanced_Extensions_filemanager.asp
cp -f /opt/app/fakeincn/Advanced_Extensions_fakeincn.asp /opt/app/translate/app/Advanced_Extensions_fakeincn.asp
cp -f /opt/app/chinadns/Advanced_Extensions_chinadns.asp /opt/app/translate/app/Advanced_Extensions_chinadns.asp
cp -f /opt/app/translate/Advanced_Extensions_translate.asp /opt/app/translate/app/Advanced_Extensions_translate.asp
cp -f /opt/app/tgbot/Advanced_Extensions_tgbot.asp /opt/app/translate/app/Advanced_Extensions_tgbot.asp

}

www_mount () {

mount --bind /opt/app/translate/www/help.js /www/help.js
mount --bind /opt/app/translate/www/as2.asp /www/as2.asp
mount --bind /opt/app/translate/www/Advanced_Tweaks_Content.asp /www/Advanced_Tweaks_Content.asp
mount --bind /opt/app/translate/www/Advanced_System_Content.asp /www/Advanced_System_Content.asp
mount --bind /opt/app/translate/www/Advanced_Extensions_wifidog.asp /www/Advanced_Extensions_wifidog.asp
mount --bind /opt/app/translate/www/Advanced_Extensions_v2ray.asp /www/Advanced_Extensions_v2ray.asp
mount --bind /opt/app/translate/www/Advanced_Extensions_softether.asp /www/Advanced_Extensions_softether.asp
mount --bind /opt/app/translate/www/Advanced_Extensions_shellinabox.asp /www/Advanced_Extensions_shellinabox.asp
mount --bind /opt/app/translate/www/Advanced_Extensions_script.asp /www/Advanced_Extensions_script.asp
mount --bind /opt/app/translate/www/Advanced_Extensions_qcloud.asp /www/Advanced_Extensions_qcloud.asp
mount --bind /opt/app/translate/www/Advanced_Extensions_phddns.asp /www/Advanced_Extensions_phddns.asp
mount --bind /opt/app/translate/www/Advanced_Extensions_ngrok.asp /www/Advanced_Extensions_ngrok.asp
mount --bind /opt/app/translate/www/Advanced_Extensions_mentohust.asp /www/Advanced_Extensions_mentohust.asp
mount --bind /opt/app/translate/www/Advanced_Extensions_lnmp.asp /www/Advanced_Extensions_lnmp.asp
mount --bind /opt/app/translate/www/Advanced_Extensions_koolproxy.asp /www/Advanced_Extensions_koolproxy.asp
mount --bind /opt/app/translate/www/Advanced_Extensions_frp.asp /www/Advanced_Extensions_frp.asp
mount --bind /opt/app/translate/www/Advanced_Extensions_display.asp /www/Advanced_Extensions_display.asp
mount --bind /opt/app/translate/www/Advanced_Extensions_cloudflare.asp /www/Advanced_Extensions_cloudflare.asp
mount --bind /opt/app/translate/www/Advanced_Extensions_aliddns.asp /www/Advanced_Extensions_aliddns.asp
mount --bind /opt/app/translate/www/Advanced_Extensions_adm.asp /www/Advanced_Extensions_adm.asp
mount --bind /opt/app/translate/www/Advanced_Extensions_adbyby.asp /www/Advanced_Extensions_adbyby.asp
mount --bind /opt/app/translate/www/Advanced_Extensions_ServerChan.asp /www/Advanced_Extensions_ServerChan.asp
mount --bind /opt/app/translate/www/Advanced_Extensions_SS_list.asp /www/Advanced_Extensions_SS_list.asp
mount --bind /opt/app/translate/www/Advanced_Extensions_SS_Server.asp /www/Advanced_Extensions_SS_Server.asp
mount --bind /opt/app/translate/www/Advanced_Extensions_SS_Kcptun.asp /www/Advanced_Extensions_SS_Kcptun.asp
mount --bind /opt/app/translate/www/Advanced_Extensions_SSR_Server.asp /www/Advanced_Extensions_SSR_Server.asp
mount --bind /opt/app/translate/www/Advanced_Extensions_SS.asp /www/Advanced_Extensions_SS.asp
mount --bind /opt/app/translate/www/Advanced_Extensions_MEOW.asp /www/Advanced_Extensions_MEOW.asp
mount --bind /opt/app/translate/www/Advanced_Extensions_DNSPod.asp /www/Advanced_Extensions_DNSPod.asp
mount --bind /opt/app/translate/www/Advanced_Extensions_CloudXNS.asp /www/Advanced_Extensions_CloudXNS.asp
mount --bind /opt/app/translate/www/Advanced_Extensions_COW.asp /www/Advanced_Extensions_COW.asp

mount --bind /opt/app/translate/www/device-map/ssinfo.asp /www/device-map/ssinfo.asp
mount --bind /opt/app/translate/www/device-map/ss.asp /www/device-map/ss.asp
mount --bind /opt/app/translate/www/device-map/sata.asp /www/device-map/sata.asp
mount --bind /opt/app/translate/www/device-map/printer.asp /www/device-map/printer.asp
mount --bind /opt/app/translate/www/device-map/hub.asp /www/device-map/hub.asp
mount --bind /opt/app/translate/www/device-map/disk.asp /www/device-map/disk.asp

mount --bind /opt/app/translate/app/Advanced_Extensions_virtualhere.asp /opt/app/virtualhere/Advanced_Extensions_virtualhere.asp
mount --bind /opt/app/translate/app/Advanced_Extensions_verysync.asp /opt/app/verysync/Advanced_Extensions_verysync.asp
mount --bind /opt/app/translate/app/Advanced_Extensions_upd2pro.asp /opt/app/upd2pro/Advanced_Extensions_upd2pro.asp
mount --bind /opt/app/translate/app/Advanced_Extensions_transocks.asp /opt/app/transocks/Advanced_Extensions_transocks.asp
mount --bind /opt/app/translate/app/Advanced_Extensions_speedup.asp /opt/app/speedup/Advanced_Extensions_speedup.asp
mount --bind /opt/app/translate/app/Advanced_Extensions_guestkit.asp /opt/app/guestkit/Advanced_Extensions_guestkit.asp
mount --bind /opt/app/translate/app/Advanced_Extensions_goflyway.asp /opt/app/goflyway/Advanced_Extensions_goflyway.asp
mount --bind /opt/app/translate/app/Advanced_Extensions_filemanager.asp /opt/app/filemanager/Advanced_Extensions_filemanager.asp
mount --bind /opt/app/translate/app/Advanced_Extensions_fakeincn.asp /opt/app/fakeincn/Advanced_Extensions_fakeincn.asp
mount --bind /opt/app/translate/app/Advanced_Extensions_chinadns.asp /opt/app/chinadns/Advanced_Extensions_chinadns.asp
mount --bind /opt/app/translate/app/Advanced_Extensions_translate.asp /opt/app/translate/Advanced_Extensions_translate.asp
mount --bind /opt/app/translate/app/Advanced_Extensions_tgbot.asp /opt/app/tgbot/Advanced_Extensions_tgbot.asp

mount --bind /opt/app/translate/$1.dict /www/EN.dict

}

www_rehttpd () {

chmod 777 -R "/opt/app/translate/"
/etc/storage/www_sh/menu_title.sh
killall httpd 
killall -9 httpd 
#/usr/sbin/httpd -p $http_lanport

}

www_translate_txt () {

translate_www="translate_www_$1.txt"
translate_map="translate_map_$1.txt"
translate_app="translate_app_$1.txt"
if [ ! -s "/opt/app/translate/translate_www_$1.txt" ] ; then
translate_www="translate_www_EN.txt"
translate_map="translate_map_EN.txt"
translate_app="translate_app_EN.txt"
logger -t "【translate】" "找不到 translate_www_$1.txt ，使用 translate_www_EN.txt 代替"
fi
echo -n "sed" > /opt/app/translate/translate4.txt
cat /opt/app/translate/$translate_www | awk -F '丨' '{printf (" -e '"'"'s@%s@%s@g'"'"'", $3, $4)}' >> /opt/app/translate/translate4.txt
echo -n " -i /opt/app/translate/www/* ; " >> /opt/app/translate/translate4.txt
. /opt/app/translate/translate4.txt

echo -n "sed" > /opt/app/translate/translate4.txt
cat /opt/app/translate/$translate_map | awk -F '丨' '{printf (" -e '"'"'s@%s@%s@g'"'"'", $3, $4)}' >> /opt/app/translate/translate4.txt
echo -n " -i /opt/app/translate/www/device-map/* ; " >> /opt/app/translate/translate4.txt

. /opt/app/translate/translate4.txt

echo -n "sed" > /opt/app/translate/translate4.txt
cat /opt/app/translate/$translate_app | awk -F '丨' '{printf (" -e '"'"'s@%s@%s@g'"'"'", $3, $4)}' >> /opt/app/translate/translate4.txt
echo -n " -i /opt/app/translate/app/* ; " >> /opt/app/translate/translate4.txt

. /opt/app/translate/translate4.txt

rm -f /opt/app/translate/translate4.txt
}

www_translate_EN () {

www_umount
www_cp
www_translate_txt EN
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
rm -rf /opt/app/translate/app/*
rm -rf /opt/app/translate/www/device-map/*
rm -rf /opt/app/translate/www/*
www_rehttpd
}

www_translate_UK () {

www_umount
www_cp
www_translate_txt UK
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
www_cp
www_translate_txt ES
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
www_cp
www_translate_txt BR
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
www_cp
www_translate_txt SV
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
www_cp
www_translate_txt DA
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
www_cp
www_translate_txt FI
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
www_cp
www_translate_txt NO
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
www_cp
www_translate_txt FR
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
www_cp
www_translate_txt DE
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
www_cp
www_translate_txt RU
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
www_cp
www_translate_txt PL
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
www_cp
www_translate_txt CZ
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
www_cp
base_name="translate_app_FT.txt"
if [ ! -s "$dir_name$base_name" ] ; then
	logger -t "【translate】" "找不到 $dir_name$base_name ，开始下载"
	wgetcurl.sh "$dir_name$base_name" "$hiboyfile/$base_name" "$hiboyfile2/$base_name"
fi
base_name="translate_map_FT.txt"
if [ ! -s "$dir_name$base_name" ] ; then
	logger -t "【translate】" "找不到 $dir_name$base_name ，开始下载"
	wgetcurl.sh "$dir_name$base_name" "$hiboyfile/$base_name" "$hiboyfile2/$base_name"
fi
base_name="translate_www_FT.txt"
if [ ! -s "$dir_name$base_name" ] ; then
	logger -t "【translate】" "找不到 $dir_name$base_name ，开始下载"
	wgetcurl.sh "$dir_name$base_name" "$hiboyfile/$base_name" "$hiboyfile2/$base_name"
fi
www_translate_txt FT
base_name="FT.dict"
if [ ! -s "$dir_name$base_name" ] ; then
	logger -t "【translate】" "找不到 $dir_name$base_name ，开始下载"
	wgetcurl.sh "$dir_name$base_name" "$hiboyfile/$base_name" "$hiboyfile2/$base_name"
fi
www_mount FT
www_rehttpd

}
initconfig () {

mkdir -p /opt/app/translate/www/
mkdir -p /opt/app/translate/www/device-map/
mkdir -p /opt/app/translate/app/
chmod 777 -R "/opt/app/translate/"
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
mkdir -p /opt/app/translate
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

