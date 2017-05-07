#!/bin/sh
#copyright by hiboy
source /etc/storage/script/init.sh
lnmp_enable=`nvram get lnmp_enable`
[ -z $lnmp_enable ] && lnmp_enable=0 && nvram set lnmp_enable=$lnmp_enable
if [ "$lnmp_enable" != "0" ] ; then
nvramshow=`nvram showall | grep lnmp | awk '{print gensub(/'"'"'/,"'"'"'\"'"'"'\"'"'"'","g",$0);}'| awk '{print gensub(/=/,"='\''",1,$0)"'\'';";}'` && eval $nvramshow


default_enable=`nvram get default_enable`
[ -z $default_enable ] && default_enable=0 && nvram set default_enable=$default_enable
default_port=`nvram get default_port`
[ -z $default_port ] && default_port=81 && nvram set default_port=$default_port
kodexplorer_enable=`nvram get kodexplorer_enable`
[ -z $kodexplorer_enable ] && kodexplorer_enable=0 && nvram set kodexplorer_enable=$kodexplorer_enable
kodexplorer_port=`nvram get kodexplorer_port`
[ -z $kodexplorer_port ] && kodexplorer_port=82 && nvram set kodexplorer_port=$kodexplorer_port
phpmyadmin_enable=`nvram get phpmyadmin_enable`
[ -z $phpmyadmin_enable ] && phpmyadmin_enable=0 && nvram set phpmyadmin_enable=$phpmyadmin_enable
phpmyadmin_port=`nvram get phpmyadmin_port`
[ -z $phpmyadmin_port ] && phpmyadmin_port=85 && nvram set phpmyadmin_port=$phpmyadmin_port
wifidog_server_enable=`nvram get wifidog_server_enable`
[ -z $wifidog_server_enable ] && wifidog_server_enable=0 && nvram set wifidog_server_enable=$wifidog_server_enable
wifidog_server_port=`nvram get wifidog_server_port`
[ -z $wifidog_server_port ] && wifidog_server_port=84 && nvram set wifidog_server_port=$wifidog_server_port
owncloud_enable=`nvram get owncloud_enable`
[ -z $owncloud_enable ] && owncloud_enable=0 && nvram set owncloud_enable=$owncloud_enable
owncloud_port=`nvram get owncloud_port`
[ -z $owncloud_port ] && owncloud_port=83 && nvram set owncloud_port=$owncloud_port
mysql_enable=`nvram get mysql_enable`
http_username=`nvram get http_username`

lnmpfile3="$hiboyfile/kodexplorer.tgz"
lnmpfile33="$hiboyfile2/kodexplorer.tgz"
lnmpfile4="$hiboyfile/phpmyadmin.tgz"
lnmpfile44="$hiboyfile2/phpmyadmin.tgz"
lnmpfile5="$hiboyfile/owncloud-8.0.14.tar.bz2"
lnmpfile55="$hiboyfile2/owncloud-8.0.14.tar.bz2"
lnmpfile6="$hiboyfile/wifidog_server.tgz"
lnmpfile66="$hiboyfile2/wifidog_server.tgz"
fi
if [ ! -z "$(echo $scriptfilepath | grep -v "/tmp/script/" | grep lnmp)" ]  && [ ! -s /tmp/script/_lnmp ]; then
	mkdir -p /tmp/script
	ln -sf $scriptfilepath /tmp/script/_lnmp
	chmod 777 /tmp/script/_lnmp
fi

lnmp_check () {

A_restart=`nvram get lnmp_status`
B_restart="$http_username$lnmp_enable$mysql_enable$default_enable$kodexplorer_enable$owncloud_enable$phpmyadmin_enable$wifidog_server_enable$default_port$kodexplorer_port$owncloud_port$phpmyadmin_port$wifidog_server_port"
B_restart=`echo -n "$B_restart" | md5sum | sed s/[[:space:]]//g | sed s/-//g`
if [ "$A_restart" != "$B_restart" ] ; then
	nvram set lnmp_status=$B_restart
	needed_restart=1
else
	needed_restart=0
fi
if [ "$lnmp_enable" != "1" ] && [ "$needed_restart" = "1" ] ; then
	[ ! -z "`pidof nginx`" ] && logger -t "【LNMP】" "停止 nginx+php 环境" && lnmp_close
	if [ "$mysql_enable" != "4" ] && [ "$mysql_enable" != "0" ] ; then
		[ ! -z "`pidof mysqld`" ] && logger -t "【LNMP】" "停止 mysql 环境" && lnmp_close
	fi
	{ eval $(ps -w | grep "$scriptname" | grep -v grep | awk '{print "kill "$1";";}'); exit 0; }
fi
if [ "$lnmp_enable" = "1" ] ; then
	if [ "$needed_restart" = "1" ] ; then
		lnmp_close
		lnmp_start
	else
		if [ "$mysql_enable" != "4" ] && [ "$mysql_enable" != "0" ] ; then
			[ -z "`pidof mysqld`" ] || [ ! -s "`which mysqld`" ] && logger -t "【LNMP】" "mysqld 重新启动" &&{ nvram set lnmp_status=00 && eval "$scriptfilepath &" ; exit 0; }
		fi
		[ -z "`pidof nginx`" ] || [ ! -s "`which nginx`" ] && logger -t "【LNMP】" "nginx 重新启动" &&  { nvram set lnmp_status=00 && eval "$scriptfilepath &" ; exit 0; }
	fi
fi
}

lnmp_keep () {

logger -t "【LNMP】" "守护进程启动"
if [ -s /tmp/script/_opt_script_check ]; then
sed -Ei '/【LNMP】|^$/d' /tmp/script/_opt_script_check
if [ "$mysql_enable" != "4" ] && [ "$mysql_enable" != "0" ] ; then
cat >> "/tmp/script/_opt_script_check" <<-OSC
[ -z "\`pidof mysqld\`" ] && nvram set lnmp_status=00 && logger -t "【LNMP】" "重新启动mysqld" && eval "$scriptfilepath &" && sed -Ei '/【LNMP】|^$/d' /tmp/script/_opt_script_check # 【LNMP】
OSC
fi
cat >> "/tmp/script/_opt_script_check" <<-OSC
[ -z "\`pidof nginx\`" ] && nvram set lnmp_status=00 && logger -t "【LNMP】" "重新启动nginx" && eval "$scriptfilepath &" && sed -Ei '/【LNMP】|^$/d' /tmp/script/_opt_script_check # 【LNMP】
OSC
return
fi

while true; do
if [ "$mysql_enable" != "4" ] && [ "$mysql_enable" != "0" ] ; then
	[ -z "`pidof mysqld`" ] || [ ! -s "`which mysqld`" ] && logger -t "【LNMP】" "mysqld 重新启动" &&{ nvram set lnmp_status=00 && eval "$scriptfilepath &" ; exit 0; }
fi
	[ -z "`pidof nginx`" ] || [ ! -s "`which nginx`" ] && logger -t "【LNMP】" "nginx 重新启动" &&  { nvram set lnmp_status=00 && eval "$scriptfilepath &" ; exit 0; }
sleep 261
done
}

lnmp_close () {

sed -Ei '/【LNMP】|^$/d' /tmp/script/_opt_script_check
/opt/etc/init.d/S70mysqld stop
/opt/etc/init.d/S79php-fpm stop
/opt/etc/init.d/S80nginx stop
killall spawn-fcgi nginx php-cgi mysqld
killall -9 spawn-fcgi nginx php-cgi mysqld
eval $(ps -w | grep "_lnmp keep" | grep -v grep | awk '{print "kill "$1";";}')
eval $(ps -w | grep "_lnmp.sh keep" | grep -v grep | awk '{print "kill "$1";";}')
eval $(ps -w | grep "$scriptname keep" | grep -v grep | awk '{print "kill "$1";";}')
}

lnmp_start () {
if [ "$mysql_enable" = "4" ] || [ ! -d "/opt/mysql/test" ] ; then
	logger -t "【LNMP】" "重置 /opt/mysql 数据"
	killall mysqld
	killall -9 mysqld
	rm -rf /opt/mysql/*
	sed -e "s/.*user.*/user = "$http_username"/g" -i /opt/etc/my.cnf
	chmod 644 /opt/etc/my.cnf
	mkdir -p /opt/mysql/
	/opt/bin/mysql_install_db
	/opt/bin/mysqld &
	sleep 2
	logger -t "【LNMP】" "重置 mysql 默认账号:root, 默认密码:admin, 请手动修改密码"
	/opt/bin/mysqladmin -u root password admin
	killall mysqld
	killall -9 mysqld
	mysql_enable=0 && nvram set mysql_enable=$mysql_enable
	nvram commit
fi
if [ "$default_enable" = "4" ] ; then
	logger -t "【LNMP】" "重置 默认主页 数据."
	rm -rf /opt/www/default
	logger -t "【LNMP】" "重置 默认主页 数据完成。"
	default_enable=0 && nvram set default_enable=$default_enable
	nvram commit
fi
if [ "$kodexplorer_enable" = "4" ] ; then
	logger -t "【LNMP】" "重置 KodExplorer 芒果云 数据."
	rm -rf /opt/www/kodexplorer
	logger -t "【LNMP】" "重置 KodExplorer 芒果云 数据完成."
	kodexplorer_enable=0 && nvram set kodexplorer_enable=$kodexplorer_enable
	nvram commit
fi
if [ "$owncloud_enable" = "4" ] ; then
	logger -t "【LNMP】" "重置 OwnCloud 私有云 数据."
	rm -rf /opt/www/owncloud
	logger -t "【LNMP】" "重置 OwnCloud 私有云 数据完成."
	owncloud_enable=0 && nvram set owncloud_enable=$owncloud_enable
	nvram commit
fi
if [ "$phpmyadmin_enable" = "4" ] ; then
	logger -t "【LNMP】" "重置 phpMyAdmin 数据."
	rm -rf /opt/www/phpmyadmin
	logger -t "【LNMP】" "重置 phpMyAdmin 数据完成."
	phpmyadmin_enable=0 && nvram set phpmyadmin_enable=$phpmyadmin_enable
	nvram commit
fi
if [ "$wifidog_server_enable" = "4" ] ; then
	logger -t "【LNMP】" "重置 wifidog_server 数据."
	rm -rf /opt/www/wifidog_server
	logger -t "【LNMP】" "重置 wifidog_server 数据完成."
	wifidog_server_enable=0 && nvram set wifidog_server_enable=$wifidog_server_enable
	nvram commit
fi
logger -t "【LNMP】" "/opt 已用数据空间`df -m|grep "% /opt" | awk ' {print $5F}'`/100%"
logger -t "【LNMP】" "/opt 已用节点空间`df -i|grep "% /opt" | awk ' {print $5F}'`/100%"
logger -t "【LNMP】" "以上两个数据如出现占用100%时，则 opt 数据空间 或 Inodes节点 爆满，会影响 LNMP 运行，请重新正确格式化 U盘。"

ss_opt_x=`nvram get ss_opt_x`
upanPath=""
[ "$ss_opt_x" = "3" ] && upanPath="`df -m | grep /dev/mmcb | grep "/media" | awk '{print $NF}' | awk 'NR==1' `"
[ "$ss_opt_x" = "4" ] && upanPath="`df -m | grep "/dev/sd" | grep "/media" | awk '{print $NF}' | awk 'NR==1' `"
[ -z "$upanPath" ] && [ "$ss_opt_x" = "1" ] && upanPath="`df -m | grep /dev/mmcb | grep "/media" | awk '{print $NF}' | awk 'NR==1' `"
[ -z "$upanPath" ] && [ "$ss_opt_x" = "1" ] && upanPath="`df -m | grep "/dev/sd" | grep "/media" | awk '{print $NF}' | awk 'NR==1' `"
echo "$upanPath"
if [ -z "$upanPath" ] ; then 
	logger -t "【LNMP】" "未挂载储存设备, 请重新检查配置、目录，10 秒后自动尝试重新启动"
	sleep 10
	nvram set lnmp_status=00 && eval "$scriptfilepath &"
	exit 0
fi

SVC_PATH="/opt/lnmp.txt"
if [ ! -f "$SVC_PATH" ] ; then
	/tmp/script/_mountopt optwget
fi
if [ ! -s "`which nginx`" ] ; then
	logger -t "【LNMP】" "找不到 nginx ，需要手动安装 opt-lnmp"
	logger -t "【LNMP】" "启动失败, 10 秒后自动尝试重新启动" && sleep 10 && { nvram set lnmp_status=00; eval "$scriptfilepath &"; exit 0; }
fi
if [ ! -s "`which mysqld`" ] ; then
	logger -t "【LNMP】" "找不到 mysqld ，需要手动安装 opt-lnmp"
	logger -t "【LNMP】" "启动失败, 10 秒后自动尝试重新启动" && sleep 10 && { nvram set lnmp_status=00; eval "$scriptfilepath &"; exit 0; }
fi

optava=`df -m|grep "% /opt" | awk ' {print $4F}'`
if [ $optava -le 300 ] || [ -z "$optava" ] ; then
	logger -t "【LNMP】" "/opt剩余空间: $optava M，不足300M, 停止启用 LNMP, 请尝试重启"
	lnmp_enable=0 && nvram set lnmp_enable=$lnmp_enable
	nvram set lnmp_status=$optava
	nvram commit
	exit 1
fi
touch /opt/testchmod
chmod 644 /opt/testchmod
optava=`ls /opt -al | grep testchmod| grep 'rw-r--r--'`
if [ -z "$optava" ] ; then
	logger -t "【LNMP】" "/opt 修改文件权限失败, 停止启用 LNMP"
	logger -t "【LNMP】" "注意: U 盘 或 储存设备 格式不支持 FAT32, 请格式化 U 盘, 要用 EXT4 或 NTFS 格式。"
	lnmp_enable=0 && nvram set lnmp_enable=$lnmp_enable
	nvram commit
	exit 1
fi

logger -t "【LNMP】" "运行 nginx+php+mysql 环境"
if [ "$default_enable" = "1" ] || [ "$default_enable" = "2" ] ; then
	if [ ! -d "/opt/www/default" ] ; then
		mkdir -p /opt/www/default
		cp -rf /opt/etc/nginx/xhost/default.conf /opt/etc/nginx/vhost/default.conf
		if [ ! -f "/opt/www/default/tz.php" ] ; then
			logger -t "【LNMP】" "找不到 tz.php, 下载程序文档, 需时1秒"
			logger -t "【LNMP】" "下载地址:$hiboyfile/tz.php"
			wgetcurl.sh /opt/www/default/tz.php "$hiboyfile/tzphp" "$hiboyfile2/tzphp"
		fi
	fi
	if [ ! -d "/opt/www/default" ] ; then
		logger -t "【LNMP】" "默认主页 停用, 因未找到 /opt/www/default"
	fi
fi
if [ "$kodexplorer_enable" = "1" ] || [ "$kodexplorer_enable" = "2" ] ; then
	if [ ! -d "/opt/www/kodexplorer/data" ] ; then
		if [ ! -f "/opt/www/kodexplorer.tgz" ] ; then
			logger -t "【LNMP】" "找不到 kodexplorer.tgz, 下载程序文档, 需时2分钟"
			logger -t "【LNMP】" "下载地址:$lnmpfile3"
			wgetcurl.sh /opt/www/kodexplorer.tgz "$lnmpfile3" "$lnmpfile33"
		fi
		logger -t "【LNMP】" "解压 kodexplorer 文档, 需时1分钟"
		tar -xzvf /opt/www/kodexplorer.tgz -C /opt/www
	fi
	if [ ! -d "/opt/www/kodexplorer/data" ] ; then
		logger -t "【LNMP】" "芒果云 停用, 因未找到 /opt/www/kodexplorer/data"
	else
		sed -e "s/.*upload_chunk_size.*/		\'upload_chunk_size\'	 => 1024*1024*1,		\/\/上传分片大小；默认1M/g" -i /opt/www/kodexplorer/config/setting.php
		chmod -R 777 /opt/www/kodexplorer/
	fi
fi
if [ "$phpmyadmin_enable" = "1" ] || [ "$phpmyadmin_enable" = "2" ] ; then
	if [ ! -d "/opt/www/phpmyadmin/libraries" ] ; then
		if [ ! -f "/opt/www/phpmyadmin.tgz" ] ; then
			logger -t "【LNMP】" "找不到 phpmyadmin.tgz, 下载程序文档, 需时2分钟"
			logger -t "【LNMP】" "下载地址:$lnmpfile4"
			wgetcurl.sh /opt/www/phpmyadmin.tgz "$lnmpfile4" "$lnmpfile44"
		fi
		logger -t "【LNMP】" "解压 phpmyadmin 文档, 需时1分钟"
		tar -xzvf /opt/www/phpmyadmin.tgz -C /opt/www
	fi
	if [ ! -d "/opt/www/phpmyadmin/libraries" ] ; then
		logger -t "【LNMP】" "phpmyadmin 停用, 因未找到 /opt/www/phpmyadmin/libraries"
	else
		chmod 644 /opt/www/phpmyadmin/config.inc.php
	fi
fi
rm -rf /opt/etc/nginx/vhost/wifidog_server.conf
if [ "$wifidog_server_enable" = "1" ] || [ "$wifidog_server_enable" = "2" ] ; then
	if [ ! -d "/opt/www/wifidog_server/auth" ] ; then
		if [ ! -f "/opt/www/wifidog_server.tgz" ] ; then
			logger -t "【LNMP】" "找不到 wifidog_server.tgz, 下载程序文档"
			logger -t "【LNMP】" "下载地址:$lnmpfile6"
			wgetcurl.sh /opt/www/wifidog_server.tgz "$lnmpfile6" "$lnmpfile66"
		fi
		logger -t "【LNMP】" "解压 wifidog_server 文档"
		tar -xzvf /opt/www/wifidog_server.tgz -C /opt/www
	fi
	if [ ! -d "/opt/www/wifidog_server/auth" ] ; then
		logger -t "【LNMP】" "wifidog_server 停用, 因未找到 /opt/www/wifidog_server/auth"
	else
		chmod -R 777 /opt/www/wifidog_server/
		[ ! -f "/opt/etc/nginx/xhost/wifidog_server.conf" ] && { wgetcurl.sh "/opt/etc/nginx/xhost/wifidog_server.conf" "$hiboyfile/wifidog_server.conf" "$hiboyfile2/wifidog_server.conf" ; }
		cp -rf /opt/etc/nginx/xhost/wifidog_server.conf /opt/etc/nginx/vhost/wifidog_server.conf
		logger -t "【LNMP】" "wifidog_server 路径:/opt/www/wifidog_server 端口:$wifidog_server_port"
		sed -e "s/.*访问端口4.*/		listen	   "$wifidog_server_port"; "' # 访问端口4/g' -i /opt/etc/nginx/vhost/wifidog_server.conf
		sed -e "s/.*output_buffering.*/output_buffering = On/g" -i /opt/etc/php.ini
		sed -e "s/.*session\.auto_start.*/session\.auto_start = 1/g" -i /opt/etc/php.ini
		logger -t "【LNMP】" "wifidog_server:`nvram get lan_ipaddr`:"$wifidog_server_port
	fi
fi
if [ "$owncloud_enable" = "1" ] || [ "$owncloud_enable" = "2" ] ; then
	if [ ! -d "/opt/www/owncloud/config" ] ; then
		if [ ! -f "/opt/www/owncloud-8.0.14.tar.bz2" ] ; then
			logger -t "【LNMP】" "找不到 owncloud-8.0.14.tar.bz2, 下载程序文档, 需时3分钟"
			logger -t "【LNMP】" "下载地址:$lnmpfile5"
			wgetcurl.sh /opt/www/owncloud-8.0.14.tar.bz2 "$lnmpfile5" "$lnmpfile55"
		fi
		logger -t "【LNMP】" "解压 owncloud 文档, 需时5分钟"
		tar -jxvf /opt/www/owncloud-8.0.14.tar.bz2 -C /opt/www
	fi
	if [ ! -d "/opt/www/owncloud/config" ] ; then
		logger -t "【LNMP】" "owncloud 停用, 因未找到 /opt/www/owncloud/config"
	else
		chmod 770 /opt/www/owncloud/data
	fi
fi
/opt/etc/init.d/S69pdcnlnmpinit start
/opt/etc/init.d/S70mysqld restart
/opt/etc/init.d/S79php-fpm restart
/opt/etc/init.d/S80nginx restart
logger -t "【LNMP】" "/opt 已用数据空间`df -m|grep "% /opt" | awk ' {print $5F}'`/100%"
logger -t "【LNMP】" "/opt 已用节点空间`df -i|grep "% /opt" | awk ' {print $5F}'`/100%"
logger -t "【LNMP】" "以上两个数据如出现占用100%时，则 opt 数据空间 或 Inodes节点 爆满，会影响 LNMP 运行，请重新正确格式化 U盘。"

[ -f /opt/lnmpi.txt ] && nvram set lnmpt=`cat /tmp/lnmpi.txt`
[ -f /opt/lnmp.txt ] && nvram set lnmpo=`cat /opt/lnmp.txt`
sleep 5
if [ "$mysql_enable" != "4" ] && [ "$mysql_enable" != "0" ] ; then
	[ ! -z "`pidof mysqld`" ] && logger -t "【LNMP】" "启动成功"
	[ -z "`pidof mysqld`" ] && logger -t "【LNMP】" "启动失败, 注意检查端口是否有冲突,程序是否下载完整,10 秒后自动尝试重新启动" && sleep 10 && { nvram set lnmp_status=00; eval "$scriptfilepath &"; exit 0; }
fi
[ ! -z "`pidof nginx`" ] && logger -t "【LNMP】" "启动成功"
[ -z "`pidof nginx`" ] && logger -t "【LNMP】" "启动失败, 注意检查端口是否有冲突,程序是否下载完整,10 秒后自动尝试重新启动" && sleep 10 && { nvram set lnmp_status=00; eval "$scriptfilepath &"; exit 0; }
initopt
eval "$scriptfilepath keep &"
}

initopt () {
optPath=`grep ' /opt ' /proc/mounts | grep tmpfs`
[ ! -z "$optPath" ] && return
optw_enable=`nvram get optw_enable`
if [ "$optw_enable" != "2" ] ; then
	nvram set optw_enable=2
fi
if [ -s "/opt/etc/init.d/rc.func" ] ; then
	cp -Hf "$scriptfilepath" "/opt/etc/init.d/$scriptname"
fi

}

case $ACTION in
start)
	lnmp_close
	lnmp_check
	;;
check)
	lnmp_check
	;;
stop)
	lnmp_close
	;;
keep)
	lnmp_check
	lnmp_keep
	;;
*)
	lnmp_check
	;;
esac

