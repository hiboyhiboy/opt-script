#!/bin/sh
#copyright by hiboy
source /etc/storage/script/init.sh
lnmp_enable=`nvram get lnmp_enable`
[ -z $lnmp_enable ] && lnmp_enable=0 && nvram set lnmp_enable=$lnmp_enable
if [ "$lnmp_enable" != "0" ] ; then
#nvramshow=`nvram showall | grep '=' | grep lnmp | awk '{print gensub(/'"'"'/,"'"'"'\"'"'"'\"'"'"'","g",$0);}'| awk '{print gensub(/=/,"='\''",1,$0)"'\'';";}'` && eval $nvramshow


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
	{ echo '#!/bin/sh' ; echo $scriptfilepath '"$@"' '&' ; } > /tmp/script/_lnmp
	chmod 777 /tmp/script/_lnmp
fi

lnmp_restart () {

relock="/var/lock/lnmp_restart.lock"
if [ "$1" = "o" ] ; then
	nvram set lnmp_renum="0"
	[ -f $relock ] && rm -f $relock
	return 0
fi
if [ "$1" = "x" ] ; then
	if [ -f $relock ] ; then
		logger -t "【lnmp】" "多次尝试启动失败，等待【"`cat $relock`"分钟】后自动尝试重新启动"
		exit 0
	fi
	lnmp_renum=${lnmp_renum:-"0"}
	lnmp_renum=`expr $lnmp_renum + 1`
	nvram set lnmp_renum="$lnmp_renum"
	if [ "$lnmp_renum" -gt "2" ] ; then
		I=19
		echo $I > $relock
		logger -t "【lnmp】" "多次尝试启动失败，等待【"`cat $relock`"分钟】后自动尝试重新启动"
		while [ $I -gt 0 ]; do
			I=$(($I - 1))
			echo $I > $relock
			sleep 60
			[ "$(nvram get lnmp_renum)" = "0" ] && exit 0
			[ $I -lt 0 ] && break
		done
		nvram set lnmp_renum="0"
	fi
	[ -f $relock ] && rm -f $relock
fi
nvram set lnmp_status=0
eval "$scriptfilepath &"
exit 0
}

lnmp_get_status () {

A_restart=`nvram get lnmp_status`
B_restart="$http_username$lnmp_enable$mysql_enable$default_enable$kodexplorer_enable$owncloud_enable$phpmyadmin_enable$wifidog_server_enable$default_port$kodexplorer_port$owncloud_port$phpmyadmin_port$wifidog_server_port"
B_restart=`echo -n "$B_restart" | md5sum | sed s/[[:space:]]//g | sed s/-//g`
if [ "$A_restart" != "$B_restart" ] ; then
	nvram set lnmp_status=$B_restart
	needed_restart=1
else
	needed_restart=0
fi
}

lnmp_check () {

lnmp_get_status
if [ "$lnmp_enable" != "1" ] && [ "$needed_restart" = "1" ] ; then
	[ ! -z "`pidof nginx`" ] && logger -t "【LNMP】" "停止 nginx+php 环境" && lnmp_close
	if [ "$mysql_enable" != "4" ] && [ "$mysql_enable" != "0" ] ; then
		[ ! -z "`pidof mysqld`" ] && logger -t "【LNMP】" "停止 mysql 环境" && lnmp_close
	fi
	{ kill_ps "$scriptname" exit0; exit 0; }
fi
if [ "$lnmp_enable" = "1" ] ; then
	if [ "$needed_restart" = "1" ] ; then
		lnmp_close
		lnmp_start
	else
		if [ "$mysql_enable" != "4" ] && [ "$mysql_enable" != "0" ] ; then
			[ -z "`pidof mysqld`" ] || [ ! -s "`which mysqld`" ] && logger -t "【LNMP】" "mysqld 重新启动" && lnmp_restart
		fi
		[ -z "`pidof nginx`" ] || [ ! -s "`which nginx`" ] && logger -t "【LNMP】" "nginx 重新启动" && lnmp_restart
		
		lnmp_port_dpt
		
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
	[ -z "`pidof mysqld`" ] || [ ! -s "`which mysqld`" ] && logger -t "【LNMP】" "mysqld 重新启动" && lnmp_restart
fi
	[ -z "`pidof nginx`" ] || [ ! -s "`which nginx`" ] && logger -t "【LNMP】" "nginx 重新启动" && lnmp_restart
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
iptables -t filter -I INPUT -p tcp --dport $default_port -j ACCEPT
iptables -t filter -I INPUT -p tcp --dport 3306 -j ACCEPT
iptables -t filter -I INPUT -p tcp --dport $kodexplorer_port -j ACCEPT
iptables -t filter -I INPUT -p tcp --dport $owncloud_port -j ACCEPT
iptables -t filter -I INPUT -p tcp --dport $phpmyadmin_port -j ACCEPT
iptables -t filter -I INPUT -p tcp --dport $wifidog_server_port -j ACCEPT
kill_ps "/tmp/script/_lnmp"
kill_ps "_lnmp.sh"
kill_ps "$scriptname"
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

lnmp_Available

ss_opt_x=`nvram get ss_opt_x`
upanPath=""
[ "$ss_opt_x" = "3" ] && upanPath="`df -m | grep /dev/mmcb | grep "/media" | awk '{print $NF}' | sort -u | awk 'NR==1' `"
[ "$ss_opt_x" = "4" ] && upanPath="`df -m | grep "/dev/sd" | grep "/media" | awk '{print $NF}' | sort -u | awk 'NR==1' `"
[ -z "$upanPath" ] && [ "$ss_opt_x" = "1" ] && upanPath="`df -m | grep /dev/mmcb | grep "/media" | awk '{print $NF}' | sort -u | awk 'NR==1' `"
[ -z "$upanPath" ] && [ "$ss_opt_x" = "1" ] && upanPath="`df -m | grep "/dev/sd" | grep "/media" | awk '{print $NF}' | sort -u | awk 'NR==1' `"
if [ "$ss_opt_x" = "5" ] ; then
	# 指定目录
	opt_cifs_dir=`nvram get opt_cifs_dir`
	if [ -d $opt_cifs_dir ] ; then
		upanPath="$opt_cifs_dir"
	else
		logger -t "【opt】" "错误！未找到指定目录 $opt_cifs_dir"
		upanPath=""
		[ -z "$upanPath" ] && upanPath="`df -m | grep /dev/mmcb | grep "/media" | awk '{print $NF}' | sort -u | awk 'NR==1' `"
		[ -z "$upanPath" ] && upanPath="`df -m | grep "/dev/sd" | grep "/media" | awk '{print $NF}' | sort -u | awk 'NR==1' `"
	fi
fi
echo "$upanPath"
if [ -z "$upanPath" ] ; then 
	logger -t "【LNMP】" "未挂载储存设备, 请重新检查配置、目录，10 秒后自动尝试重新启动"
	sleep 10
	lnmp_restart x
	exit 0
fi

SVC_PATH="/opt/lnmp.txt"
if [ ! -f "$SVC_PATH" ] ; then
	/tmp/script/_mountopt optwget
fi
chmod 777 "`which nginx`"
[[ "$(nginx -h 2>&1 | wc -l)" -lt 2 ]] && rm -rf /opt/lnmp.txt
if [ ! -s "`which nginx`" ] ; then
	logger -t "【LNMP】" "找不到 nginx ，需要手动安装 opt-lnmp"
	logger -t "【LNMP】" "启动失败, 10 秒后自动尝试重新启动" && sleep 10 && lnmp_restart x
fi
chmod 777 "`which mysqld`"
[[ "$(mysqld -h 2>&1 | wc -l)" -lt 2 ]] && rm -rf /opt/lnmp.txt
if [ ! -s "`which mysqld`" ] ; then
	logger -t "【LNMP】" "找不到 mysqld ，需要手动安装 opt-lnmp"
	logger -t "【LNMP】" "启动失败, 10 秒后自动尝试重新启动" && sleep 10 && lnmp_restart x
fi

Available_M=$(df -m | grep "% /opt" | awk 'NR==1' | awk -F' ' '{print $4}')
[ ! -z "$(echo $Available_M | grep '%')" ] && Available_M=$(df -m | grep '% /opt' | awk 'NR==1' | awk -F' ' '{print $3}')
optava="$Available_M"
if [ $optava -le 300 ] || [ -z "$optava" ] ; then
	logger -t "【LNMP】" "/opt剩余空间: $optava M，不足300M, 停止启用 LNMP, 请尝试重启"
	lnmp_enable=0 && nvram set lnmp_enable=$lnmp_enable
	nvram set lnmp_status=$optava
	nvram commit
	exit 1
fi
touch /opt/testchmod
chmod 644 /opt/testchmod
opt_testchmod=`ls /opt -al | grep testchmod| grep 'rw-r--r--'`
if [ -z "$opt_testchmod" ] ; then
	logger -t "【LNMP】" "错误！/opt 修改文件权限失败, LNMP 一些功能会启动失败"
	logger -t "【LNMP】" "错误！/opt 修改文件权限失败, LNMP 一些功能会启动失败"
	logger -t "【LNMP】" "错误！/opt 修改文件权限失败, LNMP 一些功能会启动失败"
	logger -t "【LNMP】" "注意: U 盘 或 储存设备 格式不支持 FAT32, 请格式化 U 盘, 要用 EXT4 或 NTFS 格式。"
	#lnmp_enable=0 && nvram set lnmp_enable=$lnmp_enable
	#nvram commit
	#exit 1
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

lnmp_Available

[ -f /opt/lnmpi.txt ] && nvram set lnmpt=`cat /tmp/lnmpi.txt`
[ -f /opt/lnmp.txt ] && nvram set lnmpo=`cat /opt/lnmp.txt`
sleep 5
if [ "$mysql_enable" != "4" ] && [ "$mysql_enable" != "0" ] ; then
	[ -z "`pidof mysqld`" ] && logger -t "【LNMP】" "启动失败, 注意检查端口是否有冲突,程序是否下载完整,10 秒后自动尝试重新启动" && sleep 10 && lnmp_restart x
fi
[ -z "`pidof nginx`" ] && logger -t "【LNMP】" "启动失败, 注意检查端口是否有冲突,程序是否下载完整,10 秒后自动尝试重新启动" && sleep 10 && lnmp_restart x
[ ! -z "`pidof nginx`" ] && logger -t "【LNMP】" "启动成功" && lnmp_restart o
[ "$mysql_enable" != "4" ] && [ "$mysql_enable" != "0" ] && [ ! -z "`pidof mysqld`" ] && logger -t "【LNMP】" "启动成功" && lnmp_restart o
lnmp_port_dpt
initopt
lnmp_get_status
eval "$scriptfilepath keep &"
}


lnmp_Available () {

Available_M=$(df -m | grep "% /opt" | awk 'NR==1' | awk -F' ' '{print $5}')
[ -z "$(echo $Available_M | grep '%')" ] && Available_M=$(df -m | grep '% /opt' | awk 'NR==1' | awk -F' ' '{print $4}')
logger -t "【LNMP】" "/opt 已用数据空间$Available_M/100%"
Available_I=$(df -i | grep "% /opt" | awk 'NR==1' | awk -F' ' '{print $5}')
[ -z "$(echo $Available_I | grep '%')" ] && Available_I=$(df -i | grep '% /opt' | awk 'NR==1' | awk -F' ' '{print $4}')
logger -t "【LNMP】" "/opt 已用节点空间$Available_I/100%"
logger -t "【LNMP】" "以上两个数据如出现占用100%时，则 opt 数据空间 或 Inodes节点 爆满，会影响 LNMP 运行，请重新正确格式化 U盘。"
}

initopt () {
optPath=`grep ' /opt ' /proc/mounts | grep tmpfs`
[ ! -z "$optPath" ] && return
optw_enable=`nvram get optw_enable`
if [ "$optw_enable" != "2" ] ; then
	nvram set optw_enable=2
fi
if [ ! -z "$(echo $scriptfilepath | grep -v "/opt/etc/init")" ] && [ -s "/opt/etc/init.d/rc.func" ] ; then
	{ echo '#!/bin/sh' ; echo $scriptfilepath '"$@"' '&' ; } > /opt/etc/init.d/$scriptname && chmod 777  /opt/etc/init.d/$scriptname
fi

}

lnmp_port_dpt () {

lnmp_enable=`nvram get lnmp_enable`
default_enable=`nvram get default_enable`
if [ "$default_enable" = "1" ] && [ "$lnmp_enable" = "1" ] ; then
	default_port=`nvram get default_port`
		echo "default_port:$default_port"
	port=$(iptables -t filter -L INPUT -v -n --line-numbers | grep dpt:$default_port | cut -d " " -f 1 | sort -nr | wc -l)
	if [ "$port" = 0 ] ; then
		logger -t "【默认主页】" "默认服务网站允许远程访问, 允许 $default_port 端口通过防火墙"
		iptables -t filter -I INPUT -p tcp --dport $default_port -j ACCEPT
	fi
fi
mysql_enable=`nvram get mysql_enable`
if [ "$mysql_enable" = "1" ] && [ "$lnmp_enable" = "1" ] ; then
	port=$(iptables -t filter -L INPUT -v -n --line-numbers | grep dpt:3306 | cut -d " " -f 1 | sort -nr | wc -l)
	if [ "$port" = 0 ] ; then
		logger -t "【MySQL】" "允许远程访问, 允许 3306 端口通过防火墙"
		iptables -t filter -I INPUT -p tcp --dport 3306 -j ACCEPT
	fi
fi
kodexplorer_enable=`nvram get kodexplorer_enable`
if [ "$kodexplorer_enable" = "1" ] && [ "$lnmp_enable" = "1" ] ; then
	kodexplorer_port=`nvram get kodexplorer_port`
		echo "kodexplorer_port:$kodexplorer_port"
	port=$(iptables -t filter -L INPUT -v -n --line-numbers | grep dpt:$kodexplorer_port | cut -d " " -f 1 | sort -nr | wc -l)
	if [ "$port" = 0 ] ; then
		logger -t "【芒果云】" "允许远程访问, 允许 $kodexplorer_port 端口通过防火墙"
		iptables -t filter -I INPUT -p tcp --dport $kodexplorer_port -j ACCEPT
	fi
fi
owncloud_enable=`nvram get owncloud_enable`
if [ "$owncloud_enable" = "1" ] && [ "$lnmp_enable" = "1" ] ; then
	owncloud_port=`nvram get owncloud_port`
		echo "owncloud_port:$owncloud_port"
	port=$(iptables -t filter -L INPUT -v -n --line-numbers | grep dpt:$owncloud_port | cut -d " " -f 1 | sort -nr | wc -l)
	if [ "$port" = 0 ] ; then
		logger -t "【OwnCloud私有云】" "允许远程访问, 允许 $owncloud_port 端口通过防火墙"
		iptables -t filter -I INPUT -p tcp --dport $owncloud_port -j ACCEPT
	fi
fi
phpmyadmin_enable=`nvram get phpmyadmin_enable`
if [ "$phpmyadmin_enable" = "1" ] && [ "$lnmp_enable" = "1" ] ; then
	phpmyadmin_port=`nvram get phpmyadmin_port`
		echo "phpmyadmin_port:$phpmyadmin_port"
	port=$(iptables -t filter -L INPUT -v -n --line-numbers | grep dpt:$phpmyadmin_port | cut -d " " -f 1 | sort -nr | wc -l)
	if [ "$port" = 0 ] ; then
		logger -t "【phpMyAdmin】" "允许远程访问, 允许 $phpmyadmin_port 端口通过防火墙"
		iptables -t filter -I INPUT -p tcp --dport $phpmyadmin_port -j ACCEPT
	fi
fi
wifidog_server_enable=`nvram get wifidog_server_enable`
if [ "$wifidog_server_enable" = "1" ] && [ "$lnmp_enable" = "1" ] ; then
	wifidog_server_port=`nvram get wifidog_server_port`
		echo "wifidog_server_port:$wifidog_server_port"
	port=$(iptables -t filter -L INPUT -v -n --line-numbers | grep dpt:$wifidog_server_port | cut -d " " -f 1 | sort -nr | wc -l)
	if [ "$port" = 0 ] ; then
		logger -t "【wifidog_server】" "允许远程访问, 允许 $wifidog_server_port 端口通过防火墙"
		iptables -t filter -I INPUT -p tcp --dport $wifidog_server_port -j ACCEPT
	fi
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
	#lnmp_check
	lnmp_keep
	;;
*)
	lnmp_check
	;;
esac

