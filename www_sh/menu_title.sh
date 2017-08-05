#!/bin/sh
#copyright by hiboy
# 一级菜单显示标题：空格隔开
menu0_title="配置扩展环境  ShadowSocks 花生壳内网版 广告屏蔽功能 搭建Web环境"
# 菜单页面排序：空格隔开
menu_title1="配置扩展环境 锐捷认证 Wifidog 微信推送  网页终端   相框设置"
menu_title2="SS配置       SS节点   Kcptun  SS_Server SSR_Server COW       MEOW SoftEtherVPN"
menu_title3="花生壳内网版 Ngrok    frp     DNSPod    CloudXNS   Aliddns"
menu_title4="Adbyby       ADM      koolproxy"
menu_title5="搭建Web环境  v2ray chinadns"
################################
menu_title_all="$menu_title1 $menu_title2 $menu_title3 $menu_title4 $menu_title5"
source /etc/storage/script/init.sh

if [ ! -s /tmp/script/_menu_title ] && [ ! -z "$(echo $scriptfilepath | grep -v "/tmp/script/" | grep menu_title)" ] ; then
    mkdir -p /tmp/script
    cp -Hsf $scriptfilepath /tmp/script/_menu_title
    chmod 777 /tmp/script/_menu_title
    ln -sf /etc/storage/www_sh/menu_title.sh /etc/storage/menu_title_script.sh
fi

title_init()
{

# 清空数据
nvramshow=`nvram showall | grep '=' | grep menu | grep title | awk '{print "nvram set "$1";";}' | awk '{print gensub(/=.*/,"='\''",1,$0)"'\'';";}'` && eval $nvramshow

# 写入数据
i=1
for title in $menu0_title
do
    #echo "menu0_title$i=$title"
    eval 'nvram set '"menu0_title$i=$title"';'
    i=$((i+1))
done
i=1; ii=1;
for ii in 1 2 3 4 5
do
    eval 'menu_title=$menu_title'$ii
    i=1;
    for title in $menu_title
    do
        #echo 'menu'$i'_title'$ii'='$title
        eval 'nvram set menu'$i'_title'$ii'='$title';'
        i=$((i+1))
    done
done
nvram set menu_title_init=1
}

run_www_sh()
{

mkdir -p /etc/storage/www_sh
cd /etc/storage/www_sh
chmod 777 /etc/storage/www_sh -R
i=1; ii=1;
for ii in 1 2 3 4 5
do
    for i in 1 2 3 4 5 6 7 8
    do
        echo 'menu'$i'_title'$ii
        nvramrun=`eval 'nvram get menu'$i'_title'$ii`
        if [ ! -z "$nvramrun" ] && [ ! -z "$(echo "$menu_title_all" | grep "$nvramrun")" ] && [ -s "/etc/storage/www_sh/$nvramrun" ] ; then
        #dos2unix "./$nvramrun"
        eval $(ps -w | grep "/etc/storage/www_sh/$nvramrun" | grep -v grep | awk '{print "kill "$1";";}')
        /etc/storage/www_sh/$nvramrun "$i$ii" "$i" "$ii"
        #echo "/etc/storage/www_sh/$nvramrun $i$ii $i $ii"
        fi
    done
done



}

check_www_sh()
{

menu_title_init=`nvram get menu_title_init`
[ -z $menu_title_init ] && menu_title_init=0 && nvram set menu_title_init=$menu_title_init
if [ "$menu_title_init" != "1" ] ; then
    nvram set menu_title_init=1
    title_init
fi
mkdir -p /etc/storage/www_sh
cd /etc/storage/www_sh
www_no_set=""
menu_title_set=`nvram showall | grep '=' | grep menu | grep title `
mkdir -p /etc/storage/www_sh
for file in `ls -L /etc/storage/www_sh/`
do
if [ -z "$(echo "$menu_title_set" | grep "$file")" ] && [ "$file"x != "menu_title.shx" ] && [ "$file"x != "menu_title.txtx" ] ; then
www_no_set="$www_no_set $file"
eval $(ps -w | grep "/etc/storage/www_sh/$file" | grep -v grep | awk '{print "kill "$1";";}')
/etc/storage/www_sh/$file stop
fi
done
nvram set www_no_set="$www_no_set"
}

www_upwww_sh () {

#获取最新script的sh*文件MD5
rm -f /tmp/www_shsh.txt
wgetcurl.sh "/tmp/www_shsh.txt" "$hiboyscript/www_shsh.txt" "$hiboyscript2/www_shsh.txt"

mkdir -p /tmp/www_sh
while read line
do
c_line=`echo $line |grep -v "#" |grep -v 'www_sht='`
file_name="${line%%=*}"
if [ ! -z "$c_line" ] && [ ! -z "$file_name" ] ; then
    MD5_TMP="$(cat /tmp/www_shsh.txt | grep "$file_name" | awk -F '=' '{print $NF;}')"
    MD5_ORI="$(md5sum /etc/storage/www_sh/$file_name | awk '{print $1}')"
    if [ ! -s /etc/storage/www_sh/$file_name ] || [ "$MD5_TMP"x != "$MD5_ORI"x ] ; then
        logger -t "【www_sh】" "/etc/storage/www_sh/$file_name 脚本需要更新，自动下载！$hiboyscript/www_sh/$file_name"
        wgetcurl.sh "/tmp/www_sh/$file_name" "$hiboyscript/www_sh/$file_name" "$hiboyscript2/www_sh/$file_name"
        eval $(md5sum /tmp/www_sh/$file_name | awk '{print "MD5_ORI="$1;}')
        if [ -s /tmp/www_sh/$file_name ] && [ "$MD5_TMP"x = "$MD5_ORI"x ] ; then
            logger -t "【www_sh】" " 更新【$file_name】，md5匹配，更新成功！"
            mv -f /tmp/www_sh/$file_name /etc/storage/www_sh/$file_name
        else
            logger -t "【www_sh】" "/tmp/www_sh/$file_name 脚本md5与记录不同，下载失败，跳过更新！"
        fi
    fi
fi
done < /tmp/www_shsh.txt
}


www_upver () {

# 当前 www_sh 文件
touch /etc/storage/www_sh/menu_title.txt
www_ver=`cat /etc/storage/www_sh/menu_title.txt | sed -n '1p'`
nvram set www_ver=$www_ver
# 最新 www_sh 文件
wgetcurl.sh "/tmp/menu_title.txt" "$hiboyscript/www_sh/menu_title.txt" "$hiboyscript2/www_sh/menu_title.txt"
touch /tmp/menu_title.txt
www_ver_n=`cat /tmp/menu_title.txt | sed -n '1p'`
nvram set www_ver_n=$www_ver_n
if [ "$www_ver"x != "$www_ver_n"x ] ; then
logger -t "【www_sh】" "当前自定义菜单标题【 $www_ver 】需要更新, 请手动更新到【 $www_ver_n 】"
fi
# 最新 app_ver_n.txt 文件
wgetcurl.sh "/tmp/app_ver_n.txt" "$hiboyscript/app_ver_n.txt" "$hiboyscript2/app_ver_n.txt"
source /tmp/app_ver_n.txt
}

case $ACTION in
start)
    check_www_sh
    run_www_sh
    ;;
check)
    check_www_sh
    ;;
upver)
    www_upver
    ;;
upre)
    www_upwww_sh
    title_init
    check_www_sh
    run_www_sh
    ;;
re)
    rm -f /tmp/menu_title_re
    title_init
    check_www_sh
    run_www_sh
    ;;
*)
    check_www_sh
    run_www_sh
    ;;
esac



