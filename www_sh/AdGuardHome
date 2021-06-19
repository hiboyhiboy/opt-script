#!/bin/bash
#copyright by hiboy
source /etc/storage/script/init.sh

link="Advanced_Extensions_app17.asp"
echo $1
if [ "$1"x = "stop"x ] ; then
    nvram set app_84=0 #AdGuardHome_enable
    exit
fi

if [ "$1" != "del" ] ; then
eval 'nvram set tablink'$1'='$link';'

nvram set AdGuardHome_L2="$(($3 + 10))"
nvram set AdGuardHome_L3="$2"
#     show_menu(8,<% nvram_get_x("", "AdGuardHome_L2"); %>,<% nvram_get_x("", "AdGuardHome_L3"); %>);
fi

get_www ()
{

# 加载程序配置页面
mkdir -p /opt/app/AdGuardHome
if [ -f "/tmp/www_asp/Advanced_Extensions_AdGuardHomeasp" ] ; then
if [ ! -f "/opt/app/AdGuardHome/Advanced_Extensions_AdGuardHome.asp" ] ; then
	mv -f /tmp/www_asp/Advanced_Extensions_AdGuardHomeasp /opt/app/AdGuardHome/Advanced_Extensions_AdGuardHome.asp
else
	rm -f /tmp/www_asp/Advanced_Extensions_AdGuardHomeasp
fi
fi
if [ ! -f "/opt/app/AdGuardHome/Advanced_Extensions_AdGuardHome.asp" ] || [ ! -s "/opt/app/AdGuardHome/Advanced_Extensions_AdGuardHome.asp" ] ; then
	wgetcurl.sh /opt/app/AdGuardHome/Advanced_Extensions_AdGuardHome.asp "$hiboyfile/Advanced_Extensions_AdGuardHomeasp" "$hiboyfile2/Advanced_Extensions_AdGuardHomeasp"
fi
umount /www/Advanced_Extensions_app17.asp
if [ -f "/opt/app/AdGuardHome/Advanced_Extensions_AdGuardHome.asp" ] ; then
	mount --bind /opt/app/AdGuardHome/Advanced_Extensions_AdGuardHome.asp /www/Advanced_Extensions_app17.asp
	app17_ver=$(grep 'app17_ver=' /opt/app/AdGuardHome/Advanced_Extensions_AdGuardHome.asp | awk -F '=' '{print $2;}')
	nvram set app17_ver=${app17_ver}
fi

}

get_app ()
{

# 更新程序启动脚本
[ "$1" = "del" ] && rm -rf /etc/storage/script/Sh91_AdGuard_Home.sh
if [ ! -f "/etc/storage/script/Sh91_AdGuard_Home.sh" ] || [ ! -s "/etc/storage/script/Sh91_AdGuard_Home.sh" ] ; then
	wgetcurl.sh /etc/storage/script/Sh91_AdGuard_Home.sh "$hiboyscript/script/Sh91_AdGuard_Home.sh" "$hiboyscript/script/Sh91_AdGuard_Home.sh"
fi
chmod 777 /etc/storage/script -R
if [ ! -f "/etc/storage/app_19.sh" ] || [ ! -s "/etc/storage/app_19.sh" ] ; then
/etc/storage/script/Sh91_AdGuard_Home.sh update_app
fi

[ "$1" = "del" ] && exit

}

if [ -f /tmp/webui_yes ] ; then
get_www &
get_app $1 &
[ "$1" = "del" ] && exit
fi

