#!/bin/bash
#copyright by hiboy
source /etc/storage/script/init.sh
lnmp_enable=`nvram get lnmp_enable`
[ -z $lnmp_enable ] && lnmp_enable=0 && nvram set lnmp_enable=$lnmp_enable
onmp_enable=`nvram get onmp_enable`
[ -z $onmp_enable ] && onmp_enable=0 && nvram set onmp_enable=$onmp_enable
nvram set onmp_1="更新 ONMP 脚本"
if [ "$lnmp_enable" != "0" ] ; then

default_enable=`nvram get default_enable`
[ -z $default_enable ] && default_enable=0 && nvram set default_enable=$default_enable
default_port=`nvram get default_port`
[ -z $default_port ] && default_port=81 && nvram set default_port=$default_port
kodexplorer_enable=`nvram get kodexplorer_enable`
[ -z $kodexplorer_enable ] && kodexplorer_enable=0 && nvram set kodexplorer_enable=$kodexplorer_enable
kodexplorer_port=`nvram get kodexplorer_port`
[ -z $kodexplorer_port ] && kodexplorer_port=88 && nvram set kodexplorer_port=$kodexplorer_port
phpmyadmin_enable=`nvram get phpmyadmin_enable`
[ -z $phpmyadmin_enable ] && phpmyadmin_enable=0 && nvram set phpmyadmin_enable=$phpmyadmin_enable
phpmyadmin_port=`nvram get phpmyadmin_port`
[ -z $phpmyadmin_port ] && phpmyadmin_port=82 && nvram set phpmyadmin_port=$phpmyadmin_port
wifidog_server_enable=`nvram get wifidog_server_enable`
[ -z $wifidog_server_enable ] && wifidog_server_enable=0 && nvram set wifidog_server_enable=$wifidog_server_enable
wifidog_server_port=`nvram get wifidog_server_port`
[ -z $wifidog_server_port ] && wifidog_server_port=84 && nvram set wifidog_server_port=$wifidog_server_port
owncloud_enable=`nvram get owncloud_enable`
[ -z $owncloud_enable ] && owncloud_enable=0 && nvram set owncloud_enable=$owncloud_enable
owncloud_port=`nvram get owncloud_port`
[ -z $owncloud_port ] && owncloud_port=98 && nvram set owncloud_port=$owncloud_port
mysql_enable=`nvram get mysql_enable`
http_username=`nvram get http_username`

nextcloud_enable=`nvram get nextcloud_enable`
[ -z $nextcloud_enable ] && nextcloud_enable=0 && nvram set nextcloud_enable=$nextcloud_enable
nextcloud_port=`nvram get nextcloud_port`
[ -z $nextcloud_port ] && nextcloud_port=99 && nvram set nextcloud_port=$nextcloud_port
wordpress_enable=`nvram get wordpress_enable`
[ -z $wordpress_enable ] && wordpress_enable=0 && nvram set wordpress_enable=$wordpress_enable
wordpress_port=`nvram get wordpress_port`
[ -z $wordpress_port ] && wordpress_port=83 && nvram set wordpress_port=$wordpress_port
h5ai_enable=`nvram get h5ai_enable`
[ -z $h5ai_enable ] && h5ai_enable=0 && nvram set h5ai_enable=$h5ai_enable
h5ai_port=`nvram get h5ai_port`
[ -z $h5ai_port ] && h5ai_port=85 && nvram set h5ai_port=$h5ai_port
lychee_enable=`nvram get lychee_enable`
[ -z $lychee_enable ] && lychee_enable=0 && nvram set lychee_enable=$lychee_enable
lychee_port=`nvram get lychee_port`
[ -z $lychee_port ] && lychee_port=86 && nvram set lychee_port=$lychee_port
typecho_enable=`nvram get typecho_enable`
[ -z $typecho_enable ] && typecho_enable=0 && nvram set typecho_enable=$typecho_enable
typecho_port=`nvram get typecho_port`
[ -z $typecho_port ] && typecho_port=90 && nvram set typecho_port=$typecho_port
zblog_enable=`nvram get zblog_enable`
[ -z $zblog_enable ] && zblog_enable=0 && nvram set zblog_enable=$zblog_enable
zblog_port=`nvram get zblog_port`
[ -z $zblog_port ] && zblog_port=91 && nvram set zblog_port=$zblog_port
dzzoffice_enable=`nvram get dzzoffice_enable`
[ -z $dzzoffice_enable ] && dzzoffice_enable=0 && nvram set dzzoffice_enable=$dzzoffice_enable
dzzoffice_port=`nvram get dzzoffice_port`
[ -z $dzzoffice_port ] && dzzoffice_port=92 && nvram set dzzoffice_port=$dzzoffice_port

lnmpfile6="$hiboyfile/wifidog_server.tgz"
lnmpfile66="$hiboyfile2/wifidog_server.tgz"
lnmp_renum=`nvram get lnmp_renum`
lnmp_renum=${lnmp_renum:-"0"}
cmd_log_enable=`nvram get cmd_log_enable`
cmd_name="lnmp"
cmd_log=""
if [ "$cmd_log_enable" = "1" ] || [ "$lnmp_renum" -gt "0" ] ; then
	cmd_log="$cmd_log2"
fi
fi
if [ ! -z "$(echo $scriptfilepath | grep -v "/tmp/script/" | grep lnmp)" ] && [ ! -s /tmp/script/_lnmp ] ; then
	mkdir -p /tmp/script
	{ echo '#!/bin/bash' ; echo $scriptfilepath '"$@"' '&' ; } > /tmp/script/_lnmp
	chmod 777 /tmp/script/_lnmp
fi

lnmp_restart () {
i_app_restart "$@" -name="lnmp"
}

lnmp_get_status () {

B_restart="$http_username$lnmp_enable$mysql_enable$default_enable$kodexplorer_enable$owncloud_enable$phpmyadmin_enable$wifidog_server_enable$default_port$kodexplorer_port$owncloud_port$phpmyadmin_port$wifidog_server_port$nextcloud_enable$nextcloud_port$wordpress_enable$wordpress_port$h5ai_enable$h5ai_port$lychee_enable$lychee_port$typecho_enable$typecho_port$zblog_enable$zblog_port$dzzoffice_enable$dzzoffice_port$redis_enable$onmp_enable"

i_app_get_status -name="lnmp" -valb="$B_restart"
}

lnmp_check () {
sh_onmp_check
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
i_app_keep -name="lnmp" -pidof="nginx" &
if [ "$mysql_enable" != "4" ] && [ "$mysql_enable" != "0" ] ; then
i_app_keep -name="lnmp" -pidof="mysqld" &
fi
}

lnmp_close () {
kill_ps "$scriptname keep"
echo -n "" > /opt/etc/init.d/S79php-fpm
echo -n "" > /opt/etc/init.d/S69pdcnlnmpinit
sed -Ei '/【LNMP】|^$/d' /tmp/script/_opt_script_check
sed -Ei '/【lnmp】|^$/d' /tmp/script/_opt_script_check
/opt/etc/init.d/S70mysqld stop > /dev/null 2>&1
/opt/etc/init.d/S79php8-fpm stop > /dev/null 2>&1
/opt/etc/init.d/S80nginx stop > /dev/null 2>&1
/opt/etc/init.d/S70redis stop > /dev/null 2>&1
killall nginx mysqld php-fpm sh_onmp.sh sh_onmp8.sh php-cgi > /dev/null 2>&1
iptables -t filter -D INPUT -p tcp --dport $default_port -j ACCEPT
iptables -t filter -D INPUT -p tcp --dport 3306 -j ACCEPT
iptables -t filter -D INPUT -p tcp --dport $kodexplorer_port -j ACCEPT
iptables -t filter -D INPUT -p tcp --dport $owncloud_port -j ACCEPT
iptables -t filter -D INPUT -p tcp --dport $phpmyadmin_port -j ACCEPT
iptables -t filter -D INPUT -p tcp --dport $wifidog_server_port -j ACCEPT
iptables -t filter -D INPUT -p tcp --dport $nextcloud_port -j ACCEPT
iptables -t filter -D INPUT -p tcp --dport $wordpress_port -j ACCEPT
iptables -t filter -D INPUT -p tcp --dport $h5ai_port -j ACCEPT
iptables -t filter -D INPUT -p tcp --dport $lychee_port -j ACCEPT
iptables -t filter -D INPUT -p tcp --dport $typecho_port -j ACCEPT
iptables -t filter -D INPUT -p tcp --dport $zblog_port -j ACCEPT
iptables -t filter -D INPUT -p tcp --dport $dzzoffice_port -j ACCEPT
sync;echo 3 > /proc/sys/vm/drop_caches
kill_ps "/tmp/script/_lnmp"
kill_ps "_lnmp.sh"
kill_ps "$scriptname"
}

lnmp_start () {

check_webui_yes
ss_opt_x=`nvram get ss_opt_x`
upanPath=""
[ "$ss_opt_x" = "3" ] && upanPath="`df -m | grep /dev/mmcb | grep -E "$(echo $(/usr/bin/find /dev/ -name 'mmcb*') | sed -e 's@/dev/ /dev/@/dev/@g' | sed -e 's@ @|@g')" | grep "/media" | awk '{print $NF}' | sort -u | awk 'NR==1' `"
[ "$ss_opt_x" = "4" ] && upanPath="`df -m | grep /dev/sd | grep -E "$(echo $(/usr/bin/find /dev/ -name 'sd*') | sed -e 's@/dev/ /dev/@/dev/@g' | sed -e 's@ @|@g')" | grep "/media" | awk '{print $NF}' | sort -u | awk 'NR==1' `"
[ -z "$upanPath" ] && [ "$ss_opt_x" = "1" ] && upanPath="`df -m | grep /dev/mmcb | grep -E "$(echo $(/usr/bin/find /dev/ -name 'mmcb*') | sed -e 's@/dev/ /dev/@/dev/@g' | sed -e 's@ @|@g')" | grep "/media" | awk '{print $NF}' | sort -u | awk 'NR==1' `"
[ -z "$upanPath" ] && [ "$ss_opt_x" = "1" ] && upanPath="`df -m | grep /dev/sd | grep -E "$(echo $(/usr/bin/find /dev/ -name 'sd*') | sed -e 's@/dev/ /dev/@/dev/@g' | sed -e 's@ @|@g')" | grep "/media" | awk '{print $NF}' | sort -u | awk 'NR==1' `"
if [ "$ss_opt_x" = "5" ] ; then
	# 指定目录
	opt_cifs_dir=`nvram get opt_cifs_dir`
	if [ -d $opt_cifs_dir ] ; then
		upanPath="$opt_cifs_dir"
	else
		logger -t "【opt】" "错误！未找到指定目录 $opt_cifs_dir"
	fi
fi
if [ "$ss_opt_x" = "6" ] ; then
	opt_cifs_2_dir=`nvram get opt_cifs_2_dir`
	# 远程共享
	if mountpoint -q "$opt_cifs_2_dir" && [ -d "$opt_cifs_2_dir" ] ; then
		upanPath="$opt_cifs_2_dir"
	else
		logger -t "【opt】" "错误！未找到指定远程共享目录 $opt_cifs_2_dir"
	fi
fi
echo "$upanPath"
if [ -z "$upanPath" ] ; then 
	logger -t "【LNMP】" "未挂载储存设备, 请重新检查配置、目录，10 秒后自动尝试重新启动"
	sleep 10
	lnmp_restart x
	exit 0
fi

SVC_PATH="/opt/opti.txt"
if [ ! -f "$SVC_PATH" ] ; then
	/etc/storage/script/Sh01_mountopt.sh opt_full_wget
fi
chmod 777 "/opt/sbin/nginx"
[[ "$(nginx -h 2>&1 | wc -l)" -lt 2 ]] && rm -rf /opt/lnmp.txt
if [ ! -s "`which nginx`" ] ; then
	logger -t "【LNMP】" "找不到 nginx ，需要手动安装 opt-lnmp"
	logger -t "【LNMP】" "启动失败, 10 秒后自动尝试重新启动" && sleep 10 && lnmp_restart x
fi
chmod 777 "/opt/bin/mysqld"
[[ "$(mysqld --help 2>&1 | wc -l)" -lt 2 ]] && rm -rf /opt/lnmp.txt
if [ ! -s "`which mysqld`" ] ; then
	logger -t "【LNMP】" "找不到 mysqld ，需要手动安装 opt-lnmp"
	logger -t "【LNMP】" "启动失败, 10 秒后自动尝试重新启动" && sleep 10 && lnmp_restart x
fi

Available_M=$(df -m | grep "% /opt" | awk 'NR==1' | awk -F' ' '{print $4}')
[ ! -z "$(echo $Available_M | grep '%')" ] && Available_M=$(df -m | grep '% /opt' | awk 'NR==1' | awk -F' ' '{print $3}')
optava="$Available_M"
if [ $optava -le 200 ] || [ -z "$optava" ] ; then
	lnmp_Available
	logger -t "【LNMP】" "/opt剩余空间: $optava M，不足200M, 停止启用 LNMP, 请尝试重启"
	lnmp_enable=0 && nvram set lnmp_enable=$lnmp_enable
	nvram set lnmp_status=$optava
	nvram commit
	exit 1
fi
touch /opt/testchmod
chmod 644 /opt/testchmod
opt_testchmod=`ls /opt -al | grep testchmod| grep 'rw-r--r--'`
rm -f /opt/testchmod
if [ -z "$opt_testchmod" ] ; then
	logger -t "【LNMP】" "错误！/opt 修改文件权限失败, LNMP 一些功能会启动失败"
	logger -t "【LNMP】" "错误！/opt 修改文件权限失败, LNMP 一些功能会启动失败"
	logger -t "【LNMP】" "错误！/opt 修改文件权限失败, LNMP 一些功能会启动失败"
	logger -t "【LNMP】" "注意: U 盘 或 储存设备 格式不支持 FAT32, 请格式化 U 盘, 要用 EXT4 或 NTFS 格式。"
	#lnmp_enable=0 && nvram set lnmp_enable=$lnmp_enable
	#nvram commit
	#exit 1
fi

lnmp_Available

[ -f /opt/bin/onmp ] && sed -e 's/^#exit_tmp/exit #exit_tmp/g' -i /opt/bin/onmp # 外部控制启动
ldconfig > /dev/null 2>&1
ldconfig -f /etc/ld.so.conf -C /etc/ld.so.cache > /dev/null 2>&1
if [ "$default_enable" = "5" ] ; then
	logger -t "【LNMP】" "重置 所有网站+mysql 数据.初始化lnmp重新再来，需时3分钟左右"
	mysql_enable_tmp=$mysql_enable ; nvram set mysql_enable=9 ; nvram commit ;
	[ -f /opt/bin/onmp ] && sed -e 's/^exit #exit_tmp/#exit_tmp/g' -i /opt/bin/onmp # 内部控制启动
	eval "sh_onmp8.sh init_onmp $cmd_log2"
	[ -f /opt/bin/onmp ] && sed -e 's/^#exit_tmp/exit #exit_tmp/g' -i /opt/bin/onmp # 外部控制启动
	mysql_enable=$mysql_enable_tmp ; nvram set mysql_enable=$mysql_enable ; nvram commit ;
	down_tzphp
	logger -t "【LNMP】" "重置 所有网站+mysql 数据完成。"
	default_enable=0 && nvram set default_enable=$default_enable
	nvram commit
fi

if [ ! -d "/opt/wwwroot/init_onmp_yes" ] ; then
	logger -t "【LNMP】" "初始化onmp 环境，需时3分钟左右"
	mysql_enable_tmp=$mysql_enable ; nvram set mysql_enable=9 ; nvram commit ;
	eval "sh_onmp8.sh init_onmp $cmd_log2"
	mysql_enable=$mysql_enable_tmp ; nvram set mysql_enable=$mysql_enable ; nvram commit ;
	down_tzphp
fi

init_mysql=0
[ "$mysql_enable" != "0" ] && [ ! -d "/opt/var/mysql" ] && init_mysql=1
[ "$mysql_enable" = "4" ] && init_mysql=1
if [ "$init_mysql" = "1" ] ; then
	logger -t "【LNMP】" "重置 /opt/mysql 数据，需时2分钟左右"
	logger -t "【LNMP】" "重置 mysql 默认账号:root, 默认密码:123456, 请手动修改密码"
	mysql_enable_tmp=$mysql_enable ; nvram set mysql_enable=9 ; nvram commit ;
	[ -f /opt/bin/onmp ] && sed -e 's/^exit #exit_tmp/#exit_tmp/g' -i /opt/bin/onmp # 内部控制启动
	eval "sh_onmp8.sh init_sql $cmd_log2"
	[ -f /opt/bin/onmp ] && sed -e 's/^#exit_tmp/exit #exit_tmp/g' -i /opt/bin/onmp # 外部控制启动
	/opt/etc/init.d/S70mysqld stop > /dev/null 2>&1
	mysql_enable=$mysql_enable_tmp ; nvram set mysql_enable=$mysql_enable ; nvram commit ;
	[ "$mysql_enable" = "4" ] && { mysql_enable=0 ; nvram set mysql_enable=$mysql_enable ; nvram commit ; }
fi
if [ "$default_enable" = "4" ] ; then
	logger -t "【LNMP】" "重置 默认主页 数据."
	eval "sh_onmp8.sh install_default del $cmd_log2"
	logger -t "【LNMP】" "重置 默认主页 数据完成。"
	default_enable=0 && nvram set default_enable=$default_enable
	nvram commit
	down_tzphp
fi
if [ "$kodexplorer_enable" = "4" ] ; then
	logger -t "【LNMP】" "重置 KodExplorer 芒果云 数据."
	eval "sh_onmp8.sh install_kodexplorer del $cmd_log2"
	logger -t "【LNMP】" "重置 KodExplorer 芒果云 数据完成."
	kodexplorer_enable=0 && nvram set kodexplorer_enable=$kodexplorer_enable
	nvram commit
fi
if [ "$owncloud_enable" = "4" ] ; then
	logger -t "【LNMP】" "重置 OwnCloud 私有云 数据."
	eval "sh_onmp8.sh install_owncloud del $cmd_log2"
	logger -t "【LNMP】" "重置 OwnCloud 私有云 数据完成."
	owncloud_enable=0 && nvram set owncloud_enable=$owncloud_enable
	nvram commit
fi
if [ "$nextcloud_enable" = "4" ] ; then
	logger -t "【LNMP】" "重置 Owncloud 私有云 数据."
	eval "sh_onmp8.sh install_nextcloud del $cmd_log2"
	logger -t "【LNMP】" "重置 Owncloud 私有云 数据完成."
	nextcloud_enable=0 && nvram set nextcloud_enable=$nextcloud_enable
	nvram commit
fi
if [ "$phpmyadmin_enable" = "4" ] ; then
	logger -t "【LNMP】" "重置 phpMyAdmin 数据."
	eval "sh_onmp8.sh install_phpmyadmin del $cmd_log2"
	logger -t "【LNMP】" "重置 phpMyAdmin 数据完成."
	phpmyadmin_enable=0 && nvram set phpmyadmin_enable=$phpmyadmin_enable
	nvram commit
fi
if [ "$wifidog_server_enable" = "4" ] ; then
	logger -t "【LNMP】" "重置 wifidog_server 数据."
	eval "sh_onmp8.sh install_wifidog_server del $cmd_log2"
	logger -t "【LNMP】" "重置 wifidog_server 数据完成."
	wifidog_server_enable=0 && nvram set wifidog_server_enable=$wifidog_server_enable
	nvram commit
fi
if [ "$wordpress_enable" = "4" ] ; then
	logger -t "【LNMP】" "重置 wordpress 数据."
	eval "	sh_onmp8.sh install_wordpress del $cmd_log2"
	logger -t "【LNMP】" "重置 wordpress 数据完成."
	wordpress_enable=0 && nvram set wordpress_enable=$wordpress_enable
	nvram commit
fi
if [ "$h5ai_enable" = "4" ] ; then
	logger -t "【LNMP】" "重置 h5ai 数据."
	eval "sh_onmp8.sh install_h5ai del $cmd_log2"
	logger -t "【LNMP】" "重置 h5ai 数据完成."
	h5ai_enable=0 && nvram set h5ai_enable=$h5ai_enable
	nvram commit
fi
if [ "$lychee_enable" = "4" ] ; then
	logger -t "【LNMP】" "重置 lychee 数据."
	eval "sh_onmp8.sh install_lychee del $cmd_log2"
	logger -t "【LNMP】" "重置 lychee 数据完成."
	lychee_enable=0 && nvram set lychee_enable=$lychee_enable
	nvram commit
fi
if [ "$typecho_enable" = "4" ] ; then
	logger -t "【LNMP】" "重置 typecho 数据."
	eval "sh_onmp8.sh install_typecho del $cmd_log2"
	logger -t "【LNMP】" "重置 typecho 数据完成."
	typecho_enable=0 && nvram set typecho_enable=$typecho_enable
	nvram commit
fi
if [ "$zblog_enable" = "4" ] ; then
	logger -t "【LNMP】" "重置 zblog 数据."
	eval "sh_onmp8.sh install_zblog del $cmd_log2"
	logger -t "【LNMP】" "重置 zblog 数据完成."
	zblog_enable=0 && nvram set zblog_enable=$zblog_enable
	nvram commit
fi
if [ "$dzzoffice_enable" = "4" ] ; then
	logger -t "【LNMP】" "重置 dzzoffice 数据."
	eval "sh_onmp8.sh install_dzzoffice del $cmd_log2"
	logger -t "【LNMP】" "重置 dzzoffice 数据完成."
	dzzoffice_enable=0 && nvram set dzzoffice_enable=$dzzoffice_enable
	nvram commit
fi

[ -f /opt/bin/onmp ] && sed -e 's/^#exit_tmp/exit #exit_tmp/g' -i /opt/bin/onmp # 外部控制启动
eval "sh_onmp8.sh install_default stop $cmd_log2"
eval "sh_onmp8.sh install_wifidog_server stop $cmd_log2"
eval "sh_onmp8.sh install_phpmyadmin stop $cmd_log2"
eval "sh_onmp8.sh install_wordpress stop $cmd_log2"
eval "sh_onmp8.sh install_owncloud stop $cmd_log2"
eval "sh_onmp8.sh install_nextcloud stop $cmd_log2"
eval "sh_onmp8.sh install_h5ai stop $cmd_log2"
eval "sh_onmp8.sh install_lychee stop $cmd_log2"
eval "sh_onmp8.sh install_kodexplorer stop $cmd_log2"
eval "sh_onmp8.sh install_typecho stop $cmd_log2"
eval "sh_onmp8.sh install_zblog stop $cmd_log2"
eval "sh_onmp8.sh install_dzzoffice stop $cmd_log2"

[ -d /opt/lib/php8 ] && { rm -rf /opt/lib/php /opt/opt_backup/lib/php ; ln -sf /opt/lib/php8 /opt/lib/php ; }

logger -t "【LNMP】" "运行 nginx+php+mysql 环境"
if [ "$default_enable" = "1" ] || [ "$default_enable" = "2" ] ; then
	eval "sh_onmp8.sh install_default $default_port n $cmd_log2"
fi
if [ "$kodexplorer_enable" = "1" ] || [ "$kodexplorer_enable" = "2" ] ; then
	eval "sh_onmp8.sh install_kodexplorer $kodexplorer_port n $cmd_log2"
fi
if [ "$phpmyadmin_enable" = "1" ] || [ "$phpmyadmin_enable" = "2" ] ; then
	eval "sh_onmp8.sh install_phpmyadmin $phpmyadmin_port n $cmd_log2"
fi
if [ "$wifidog_server_enable" = "1" ] || [ "$wifidog_server_enable" = "2" ] ; then
	if [ ! -d "/opt/wwwroot/wifidog_server/auth" ] ; then
		if [ ! -f "/opt/wwwroot/wifidog_server.tgz" ] ; then
			logger -t "【LNMP】" "找不到 wifidog_server.tgz, 下载程序文档"
			logger -t "【LNMP】" "下载地址:$lnmpfile6"
			wgetcurl.sh /opt/wwwroot/wifidog_server.tgz "$lnmpfile6" "$lnmpfile66"
		fi
		logger -t "【LNMP】" "解压 wifidog_server 文档"
		tar -xzvf /opt/wwwroot/wifidog_server.tgz -C /opt/wwwroot
	fi
	if [ ! -d "/opt/wwwroot/wifidog_server/auth" ] ; then
		logger -t "【LNMP】" "wifidog_server 停用, 因未找到 /opt/wwwroot/wifidog_server/auth"
	else
		chmod -R 777 /opt/wwwroot/wifidog_server/
		eval "sh_onmp8.sh install_wifidog_server $wifidog_server_port n $cmd_log2"
		logger -t "【LNMP】" "wifidog_server:`nvram get lan_ipaddr`:"$wifidog_server_port
	fi
fi
if [ "$owncloud_enable" = "1" ] || [ "$owncloud_enable" = "2" ] ; then
	eval "sh_onmp8.sh install_owncloud $owncloud_port n $cmd_log2"
fi
if [ "$nextcloud_enable" = "1" ] || [ "$nextcloud_enable" = "2" ] ; then
	eval "sh_onmp8.sh install_nextcloud $nextcloud_port n $cmd_log2"
fi
if [ "$wordpress_enable" = "1" ] || [ "$wordpress_enable" = "2" ] ; then
	eval "sh_onmp8.sh install_wordpress $wordpress_port n $cmd_log2"
fi
if [ "$h5ai_enable" = "1" ] || [ "$h5ai_enable" = "2" ] ; then
	eval "sh_onmp8.sh install_h5ai $h5ai_port n $cmd_log2"
fi
if [ "$lychee_enable" = "1" ] || [ "$lychee_enable" = "2" ] ; then
	eval "sh_onmp8.sh install_lychee $lychee_port n $cmd_log2"
fi
if [ "$typecho_enable" = "1" ] || [ "$typecho_enable" = "2" ] ; then
	eval "sh_onmp8.sh install_typecho $typecho_port n $cmd_log2"
fi
if [ "$zblog_enable" = "1" ] || [ "$zblog_enable" = "2" ] ; then
	eval "sh_onmp8.sh install_zblog $zblog_port n $cmd_log2"
fi
if [ "$dzzoffice_enable" = "1" ] || [ "$dzzoffice_enable" = "2" ] ; then
	eval "sh_onmp8.sh install_dzzoffice $dzzoffice_port n $cmd_log2"
fi

/opt/etc/init.d/S70mysqld stop > /dev/null 2>&1
/opt/etc/init.d/S79php8-fpm stop > /dev/null 2>&1
/opt/etc/init.d/S80nginx stop > /dev/null 2>&1
/opt/etc/init.d/S70redis stop > /dev/null 2>&1

eval "/opt/etc/init.d/S70mysqld start $cmd_log2" 
eval "/opt/etc/init.d/S79php8-fpm start $cmd_log2" 
eval "/opt/etc/init.d/S80nginx start $cmd_log2" 
eval "/opt/etc/init.d/S70redis start $cmd_log2" 

lnmp_Available

sleep 5
if [ "$mysql_enable" != "4" ] && [ "$mysql_enable" != "0" ] ; then
	i_app_keep -t -name="lnmp" -pidof="mysqld"
fi
i_app_keep -t -name="lnmp" -pidof="nginx"
lnmp_port_dpt
lnmp_get_status
eval "$scriptfilepath keep &"
exit 0
}


lnmp_Available () {

Available_A=$(df -m | grep "% /opt" | awk 'NR==1' | awk -F' ' '{print $4}')
Available_B=$(df -m | grep "% /opt" | awk 'NR==1' | awk -F' ' '{print $2}')
Available_C=$(df -i | grep "% /opt" | awk 'NR==1' | awk -F' ' '{print $4}')
Available_D=$(df -i | grep "% /opt" | awk 'NR==1' | awk -F' ' '{print $2}')
Available_M=$(df -m | grep "% /opt" | awk 'NR==1' | awk -F' ' '{print $5}')
Available_I=$(df -i | grep "% /opt" | awk 'NR==1' | awk -F' ' '{print $5}')
if [ -z "$(echo $Available_M | grep '%')" ] ; then
Available_A=$(df -m | grep "% /opt" | awk 'NR==1' | awk -F' ' '{print $3}')
Available_B=$(df -m | grep "% /opt" | awk 'NR==1' | awk -F' ' '{print $1}')
Available_C=$(df -i | grep "% /opt" | awk 'NR==1' | awk -F' ' '{print $3}')
Available_D=$(df -i | grep "% /opt" | awk 'NR==1' | awk -F' ' '{print $1}')
Available_M=$(df -m | grep '% /opt' | awk 'NR==1' | awk -F' ' '{print $4}')
Available_I=$(df -i | grep '% /opt' | awk 'NR==1' | awk -F' ' '{print $4}')
fi
logger -t "【LNMP】" "/opt 剩余可用数据空间[M] $Available_A/$Available_B"
logger -t "【LNMP】" "/opt 剩余可用节点空间[Inodes] $Available_C/$Available_D"
logger -t "【LNMP】" "/opt 已用数据空间[M] $Available_M/100%"
logger -t "【LNMP】" "/opt 已用节点空间[Inodes] $Available_I/100%"
logger -t "【LNMP】" "以上两个数据如出现占用100%时，则 opt 数据空间 或 Inodes节点 爆满，会影响 LNMP 运行，请重新正确格式化 U盘。"
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
nextcloud_enable=`nvram get nextcloud_enable`
if [ "$nextcloud_enable" = "1" ] && [ "$lnmp_enable" = "1" ] ; then
	nextcloud_port=`nvram get nextcloud_port`
		echo "nextcloud_port:$nextcloud_port"
	port=$(iptables -t filter -L INPUT -v -n --line-numbers | grep dpt:$nextcloud_port | cut -d " " -f 1 | sort -nr | wc -l)
	if [ "$port" = 0 ] ; then
		logger -t "【nextcloud】" "允许远程访问, 允许 $nextcloud_port 端口通过防火墙"
		iptables -t filter -I INPUT -p tcp --dport $nextcloud_port -j ACCEPT
	fi
fi
wordpress_enable=`nvram get wordpress_enable`
if [ "$wordpress_enable" = "1" ] && [ "$lnmp_enable" = "1" ] ; then
	wordpress_port=`nvram get wordpress_port`
		echo "wordpress_port:$wordpress_port"
	port=$(iptables -t filter -L INPUT -v -n --line-numbers | grep dpt:$wordpress_port | cut -d " " -f 1 | sort -nr | wc -l)
	if [ "$port" = 0 ] ; then
		logger -t "【wordpress】" "允许远程访问, 允许 $wordpress_port 端口通过防火墙"
		iptables -t filter -I INPUT -p tcp --dport $wordpress_port -j ACCEPT
	fi
fi
h5ai_enable=`nvram get h5ai_enable`
if [ "$h5ai_enable" = "1" ] && [ "$lnmp_enable" = "1" ] ; then
	h5ai_port=`nvram get h5ai_port`
		echo "h5ai_port:$h5ai_port"
	port=$(iptables -t filter -L INPUT -v -n --line-numbers | grep dpt:$h5ai_port | cut -d " " -f 1 | sort -nr | wc -l)
	if [ "$port" = 0 ] ; then
		logger -t "【h5ai】" "允许远程访问, 允许 $h5ai_port 端口通过防火墙"
		iptables -t filter -I INPUT -p tcp --dport $h5ai_port -j ACCEPT
	fi
fi
lychee_enable=`nvram get lychee_enable`
if [ "$lychee_enable" = "1" ] && [ "$lnmp_enable" = "1" ] ; then
	lychee_port=`nvram get lychee_port`
		echo "lychee_port:$lychee_port"
	port=$(iptables -t filter -L INPUT -v -n --line-numbers | grep dpt:$lychee_port | cut -d " " -f 1 | sort -nr | wc -l)
	if [ "$port" = 0 ] ; then
		logger -t "【lychee】" "允许远程访问, 允许 $lychee_port 端口通过防火墙"
		iptables -t filter -I INPUT -p tcp --dport $lychee_port -j ACCEPT
	fi
fi
typecho_enable=`nvram get typecho_enable`
if [ "$typecho_enable" = "1" ] && [ "$lnmp_enable" = "1" ] ; then
	typecho_port=`nvram get typecho_port`
		echo "typecho_port:$typecho_port"
	port=$(iptables -t filter -L INPUT -v -n --line-numbers | grep dpt:$typecho_port | cut -d " " -f 1 | sort -nr | wc -l)
	if [ "$port" = 0 ] ; then
		logger -t "【typecho】" "允许远程访问, 允许 $typecho_port 端口通过防火墙"
		iptables -t filter -I INPUT -p tcp --dport $typecho_port -j ACCEPT
	fi
fi
zblog_enable=`nvram get zblog_enable`
if [ "$zblog_enable" = "1" ] && [ "$lnmp_enable" = "1" ] ; then
	zblog_port=`nvram get zblog_port`
		echo "zblog_port:$zblog_port"
	port=$(iptables -t filter -L INPUT -v -n --line-numbers | grep dpt:$zblog_port | cut -d " " -f 1 | sort -nr | wc -l)
	if [ "$port" = 0 ] ; then
		logger -t "【zblog】" "允许远程访问, 允许 $zblog_port 端口通过防火墙"
		iptables -t filter -I INPUT -p tcp --dport $zblog_port -j ACCEPT
	fi
fi
dzzoffice_enable=`nvram get dzzoffice_enable`
if [ "$dzzoffice_enable" = "1" ] && [ "$lnmp_enable" = "1" ] ; then
	dzzoffice_port=`nvram get dzzoffice_port`
		echo "dzzoffice_port:$dzzoffice_port"
	port=$(iptables -t filter -L INPUT -v -n --line-numbers | grep dpt:$dzzoffice_port | cut -d " " -f 1 | sort -nr | wc -l)
	if [ "$port" = 0 ] ; then
		logger -t "【dzzoffice】" "允许远程访问, 允许 $dzzoffice_port 端口通过防火墙"
		iptables -t filter -I INPUT -p tcp --dport $dzzoffice_port -j ACCEPT
	fi
fi

}

sh_onmp_check () {
down_sh_onmp=0
if [ "$onmp_enable" = "1" ] ; then
	down_sh_onmp=1
fi
if [ ! -f "/opt/bin/sh_onmp8.sh" ] && [ "$lnmp_enable" = "1" ] ; then
	down_sh_onmp=1
fi
if [ ! -f "/opt/bin/sh_onmp8.sh" ] && [ "$onmp_enable" != "0" ] ; then
	down_sh_onmp=1
fi
if [ "$down_sh_onmp" = "1" ] ; then
	logger -t "【LNMP】" "更新 /opt/bin/sh_onmp8.sh, 下载脚本: $hiboyscript/sh_onmp8.sh"
	wgetcurl.sh /tmp/sh_onmp8.sh "$hiboyscript/sh_onmp8.sh" "$hiboyscript2/sh_onmp8.sh"
	[[ "$(cat /tmp/sh_onmp8.sh | wc -l)" -gt 1000 ]] && [ ! -z "$(cat /tmp/sh_onmp8.sh | grep "kodexplorer")" ] && { rm -f /opt/bin/sh_onmp8.sh ; mv -f /tmp/sh_onmp8.sh /opt/bin/sh_onmp8.sh ; }
fi
[ -f /opt/bin/sh_onmp8.sh ] && chmod 777 "/opt/bin/sh_onmp8.sh"

# 更换【通用环境变量获取】方式
[ -f /opt/bin/sh_onmp8.sh ] && sed -e 's/localhost=.*/localhost=`nvram get lan_ipaddr`/g' -i /opt/bin/sh_onmp8.sh
[ -f /opt/bin/onmp ] && sed  -e 's/localhost=.*/localhost=`nvram get lan_ipaddr`/g' -i /opt/bin/onmp
[ -f /opt/bin/sh_onmp8.sh ] && sed -i '/get_env()/,/##### 软件包状态检测 #####/{/get_env()/n;/##### 软件包状态检测 #####/b;d;p}' /opt/bin/sh_onmp8.sh

[ -f /opt/bin/sh_onmp8.sh ] && sed -i '/^get_env()/a {\
\
username=`nvram get http_username`\
localhost=`nvram get lan_ipaddr`\
\
}\
' /opt/bin/sh_onmp8.sh

[ -f /opt/bin/onmp ] && sed -e 's/^exit #exit_tmp/#exit_tmp/g' -i /opt/bin/onmp # 内部控制启动
sh_onmp8.sh check
[ -f /opt/bin/onmp ] && sed -e 's/^#exit_tmp/exit #exit_tmp/g' -i /opt/bin/onmp # 外部控制启动
if [ -f /opt/lnmp.txt ] ; then
[[ "$(cat /opt/lnmp.txt | wc -c)" -gt 11 ]] && echo "" > /opt/lnmp.txt
[ ! -z "$(cat /opt/lnmp.txt | grep '<' | grep '>')" ] && echo "" > /opt/lnmp.txt
nvram set lnmpo=`cat /opt/lnmp.txt`
fi
onmp_enable=0 && nvram set onmp_enable=$onmp_enable ; nvram commit ; 

}

down_tzphp()
{
if [ ! -f "/opt/wwwroot/default/tz.php" ] ; then
	logger -t "【LNMP】" "找不到 tz.php, 下载程序文档, 需时1秒"
	logger -t "【LNMP】" "下载地址:$hiboyfile/tz.php"
	wgetcurl.sh /opt/wwwroot/default/tz.php "$hiboyfile/tzphp" "$hiboyfile2/tzphp"
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

