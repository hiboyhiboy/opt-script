#!/bin/sh
#copyright by hiboy
#一键自动更新固件脚本
#wget --no-check-certificate -O- https://opt.cn2qq.com/opt-script/up.sh | sed -e "s|^\(Firmware.*\)=[^=]*$|\1=|" > /tmp/up.sh && bash < /tmp/up.sh
logger_echo () {
    logger -t "【Firmware】" "$1"
    echo "$(date "+%Y-%m-%d_%H-%M-%S") ""$1"
}
if [ -f /tmp/up_Firmware ] ; then
    logger_echo " 上次更新未完成，跳过更新！稍等几分钟可再次尝试更新！"
    exit
fi
touch /tmp/up_Firmware
[ -f ~/.wget-hsts ] && chmod 644 ~/.wget-hsts
export LD_LIBRARY_PATH=/lib:/opt/lib
Firmware="$1"
mkdir -p /tmp/padavan
rm -f /tmp/padavan/*
# 固件更新判断
[ ! -f /tmp/ver_time ] && echo -n "0" > /tmp/ver_time
if [ $(($(date "+1%m%d%H%M") - $(cat /tmp/ver_time))) -gt 1 ] ; then
echo -n `nvram get firmver_sub` > /tmp/padavan/ver_osub
rm -f /tmp/padavan/ver_nsub
wget  -O /tmp/padavan/ver_nsub https://opt.cn2qq.com/opt-file/osub
if [ ! -s /tmp/padavan/ver_nsub ] ; then
rm -f /tmp/padavan/ver_nsub
wget --no-check-certificate  -O /tmp/padavan/ver_nsub https://opt.cn2qq.com/opt-file/osub
fi
if [ -s /tmp/padavan/ver_osub ] && [ -s /tmp/padavan/ver_nsub ] && [ "$(cat /tmp/padavan/ver_osub |head -n1)"x == "$(cat /tmp/padavan/ver_nsub |head -n1)"x ] ; then
    logger_echo "新的固件：$(cat /tmp/padavan/ver_nsub | grep -v "^$")"
    logger_echo "目前固件：$(cat /tmp/padavan/ver_osub | grep -v "^$") "
    logger_echo "未有更新！如需再次刷入,请在一分钟内再次运行此命令进行强制更新"
    echo -n "$(date "+1%m%d%H%M")" > /tmp/ver_time
    echo "$(date "+1%m%d%H%M")"
    rm -f /tmp/up_Firmware; rm -f /tmp/padavan/* ;
    logger_echo "更新脚本"
    sh_upscript.sh upscript
    exit;
else
    echo -n `nvram get firmver_sub` > /tmp/padavan/ver_osub
    logger_echo "新的固件：$(cat /tmp/padavan/ver_nsub | grep -v "^$") ，目前旧固件： $(cat /tmp/padavan/ver_osub | grep -v "^$") "
    logger_echo "更新固件：$(cat /tmp/padavan/ver_nsub | grep -v "^$") "
fi
else
    logger_echo "进行强制更新"
fi
# 固件 MD5 判断
wget  -O /tmp/padavan/MD5.txt https://opt.cn2qq.com/padavan/MD5.txt
if [ ! -s /tmp/padavan/MD5.txt ] ; then
rm -f /tmp/padavan/MD5.txt
wget --no-check-certificate  -O /tmp/padavan/MD5.txt https://opt.cn2qq.com/padavan/MD5.txt
fi
dos2unix /tmp/padavan/MD5.txt
sed -e 's@\r@@g' -i /tmp/padavan/MD5.txt
if [ "$Firmware"x != "x" ] ; then
MD5_txt=`cat /tmp/padavan/MD5.txt | sed 's@\r@@g' |sed -n '/'$Firmware'/,/CRC32/{/'$Firmware'/n;/CRC32/b;p}' | grep "MD5：" | tr 'A-Z' 'a-z' |awk '{print $2}'`
if [ "$MD5_txt"x = x ] ; then
    logger_echo " 未能获取【 $Firmware 】型号"
    Firmware=""
fi
fi
if [ "$Firmware"x = "x" ] ; then
PN=`grep Web_Title= /www/EN.dict | sed 's@\r@@g' | sed 's/Web_Title=//g'| sed 's/ 无线路由器\| Wireless Router//g'`
[ "$PN"x != "x" ] && Firmware=`cat /tmp/padavan/MD5.txt | sed 's@\r@@g' | grep -Eo "$PN"'_.*' | sed -n '1p'`
fi
if [ "$Firmware"x = x ] ; then
    logger_echo " 未能获取【无线路由器】型号，跳过更新！可尝试手动指定型号更新！ /tmp/up.sh newifi3D2_3.4.3.9-099.trx &"
    rm -f /tmp/up_Firmware; rm -f /tmp/padavan/* ; exit;
fi
MD5_txt=`cat /tmp/padavan/MD5.txt | sed 's@\r@@g' |sed -n '/'$Firmware'/,/CRC32/{/'$Firmware'/n;/CRC32/b;p}' | grep "MD5：" | tr 'A-Z' 'a-z' |awk '{print $2}'`
if [ "$MD5_txt"x = x ] ; then
    logger_echo " 未能获取【 $Firmware 】型号 https://opt.cn2qq.com/padavan/MD5.txt 记录，跳过更新！稍后可再次尝试更新！"
    rm -f /tmp/up_Firmware; rm -f /tmp/padavan/* ; exit;
fi
# 调整 /tmp 剩余空间
size_tmpfs=`nvram get size_tmpfs`
[ -z "$size_tmpfs" ] && size_tmpfs="0"
[ "$size_tmpfs" = "0" ] && mount -o remount,size=80% tmpfs /tmp
rm -rf /tmp/xupnpd-cache
rm -rf /tmp/xupnpd-feeds
sync;echo 1 > /proc/sys/vm/drop_caches
logger_echo " 下载【 $Firmware 】， https://opt.cn2qq.com/padavan/$Firmware"
wget  -O "/tmp/padavan/$Firmware" "https://opt.cn2qq.com/padavan/$Firmware"
if [ ! -s "/tmp/padavan/$Firmware" ] ; then
rm -f "/tmp/padavan/$Firmware"
wget --no-check-certificate  -O "/tmp/padavan/$Firmware" "https://opt.cn2qq.com/padavan/$Firmware"
fi
eval $(md5sum /tmp/padavan/$Firmware | awk '{print "MD5_down="$1;}')
echo "$MD5_down"
echo "$MD5_txt"
# 固件刷入
if [ -s "/tmp/padavan/$Firmware" ] && [ "$MD5_txt"x = "$MD5_down"x ] ; then
    logger_echo " 完成下载【$Firmware】，md5匹配，开始更新！请勿断电！"
    rm -f /tmp/padavan/log.txt
    mtd_write -r write "/tmp/padavan/$Firmware" Firmware_Stub  > /tmp/padavan/log.txt  2>&1 &
    sleep 1
    while [ ! -f /tmp/padavan/log.txt ] ; do
        sleep 10
        logger_echo " 稍等【$Firmware】请勿断电！"
    done
    while [ -s /tmp/padavan/log.txt ] && [ ! -z "`pidof mtd_write`" ] ; do
        logger_echo " 稍等【$Firmware】正在更新！请勿断电！"
        sleep 10
    done
    mtd_log=`cat /tmp/padavan/log.txt | grep -Eo '\[ok\]'`
    if [ -s /tmp/padavan/log.txt ] && [ "$mtd_log"x = '[ok]x' ] ; then
        logger_echo " 更新【$Firmware】，[ok]！"
        logger_echo " 稍等【$Firmware】，自动重启！"
        logger_echo " 出现[ok]！为刷入成功，自动重启路由"
        sleep 2
        mtd_write -r unlock mtd1
        sleep 10
        reboot
        sleep 10
        mtd_write -r unlock mtd1
        sleep 10
        reboot
        logger_echo "如果自动重启失败可尝试手动重启路由"
    else
        logger_echo "`cat /tmp/padavan/log.txt`"
        logger_echo " 刷入出错【$Firmware】，更新失败！"
    fi
else
    logger_echo " 下载【$Firmware】，md5与记录不同，下载失败，跳过更新！可重启后再次尝试更新！"
    logger_echo " 下载md5: $MD5_down"
    logger_echo " 记录md5: $MD5_txt"
fi
rm -f /tmp/up_Firmware; rm -f /tmp/padavan/* ; exit;

