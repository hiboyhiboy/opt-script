#!/bin/sh
#copyright by hiboy
source /etc/storage/script/init.sh
#nvramshow=`nvram showall | grep '=' | grep opt | awk '{print gensub(/'"'"'/,"'"'"'\"'"'"'\"'"'"'","g",$0);}'| awk '{print gensub(/=/,"='\''",1,$0)"'\'';";}'` && eval $nvramshow
optinstall=`nvram get optinstall`
ss_opt_x=`nvram get ss_opt_x`
upopt_enable=`nvram get upopt_enable`
opt_cifs_dir=`nvram get opt_cifs_dir`
[ -z $opt_cifs_dir ] && opt_cifs_dir="/media/cifs" && nvram set opt_cifs_dir="$opt_cifs_dir"

[ -z $ss_opt_x ] && ss_opt_x=1 && nvram set ss_opt_x="$ss_opt_x"

if [ ! -z "$(echo $scriptfilepath | grep -v "/tmp/script/" | grep mountopt)" ]  && [ ! -s /tmp/script/_mountopt ]; then
	mkdir -p /tmp/script
	{ echo '#!/bin/sh' ; echo $scriptfilepath '"$@"' ; } > /tmp/script/_mountopt
	chmod 777 /tmp/script/_mountopt
fi
# /etc/storage/script/sh01_mountopt.sh
 opttmpfile="$hiboyfile/opttmpg7.tgz"
 opttmpfile2="$hiboyfile2/opttmpg7.tgz"
 optupanfile="$hiboyfile/optupang7.tgz"
 optupanfile3="$hiboyfile2/optupang7.tgz"
 optupanfile2="$hiboyfile/optg7.txt"
 optupanfile4="$hiboyfile2/optg7.txt"
# ss_opt_x 
# 1 >>自动选择:SD→U盘→内存
# 2 >>安装到内存:需要空余内存(10M+)
# 3 >>安装到 SD
# 4 >>安装到 U盘
# 5 >>安装到 指定目录

mount_check() {

ss_opt_x=`nvram get ss_opt_x`
mountp="mountp"
mountpoint -q /opt && mountp=0 || mountp=1 # 0已挂载 1没挂载
if [ "$mountp" = "0" ] ; then
	if [ "$ss_opt_x" != "5" ] ; then
		optPath="`grep ' /opt ' /proc/mounts | grep tmpfs| awk '{print $1}'`"
		[ -z "$optPath" ] && optPath="`df -m | grep "$(df -m | grep '% /opt' | awk 'NR==1' | awk '{print $1}')" | grep "/media"| awk '{print $NF}' | awk 'NR==1' `"
		if [ -z "$optPath" ] ; then
			logger -t "【opt】" "opt 选项[$ss_opt_x] 挂载异常，重新挂载：umount -l /opt"
			umount -l /opt
			mount_opt
		else
			logger -t "【opt】" "opt 挂载正常：$optPath"
		fi
	else
		# 指定目录
		optPath="`grep ' /opt ' /proc/mounts | awk '{print $1}'`"
		if [ -z "$optPath" ] ; then
			logger -t "【opt】" "opt 指定目录 挂载异常，重新挂载：umount -l /opt"
			umount -l /opt
			mount_opt
		else
			logger -t "【opt】" "opt 挂载正常：$optPath"
		fi
	fi
else
	logger -t "【opt】" "opt 没挂载，重新挂载"
	mount_opt
	mountpoint -q /opt && mountp=0 || mountp=1 # 0已挂载 1没挂载
	optPath="`grep ' /opt ' /proc/mounts | awk '{print $1}'`"
	[ "$mountp" = "0" ] && logger -t "【opt】" "opt 挂载正常：$optPath"
	[ "$mountp" = "1" ] && logger -t "【opt】" "opt 没挂载，挂载错误！"
fi
AiDisk00
}

prepare_authorized_keys () {

# prepare /etc/localtime
ln -sf /opt/etc/localtime /etc/localtime

ss_opt_x=`nvram get ss_opt_x`
if [ "$ss_opt_x" != "5" ] ; then
	# expand home to opt
	if [ -d /opt/home/admin ] ; then
		rm -f /home/admin
		ln -sf /opt/home/admin /home/admin
		chmod 700 /opt/home/admin
	fi
else
	# restore home
	rm -f /home/admin
	ln -sf /home/root /home/admin
fi

# prepare ssh authorized_keys
if [ -f /etc/storage/authorized_keys ] && [ ! -f /opt/home/admin/.ssh/authorized_keys ] ; then
	mkdir -p /opt/home/admin/.ssh
	cp -f /etc/storage/authorized_keys /opt/home/admin/.ssh
fi
[ -d /opt/home/admin/.ssh ] && chmod 700 /opt/home/admin/.ssh
[ -f /opt/home/admin/.ssh/authorized_keys ] && chmod 600 /opt/home/admin/.ssh/authorized_keys

#使用文件创建swap分区
#bs  blocksize ，每个块大小为1k.count=204800。则总大小为200M的文件
#dd if=/dev/zero of=/opt/.swap bs=1k count=204800
#mkswap /opt/.swap
# 挂载 /opt/.swap
# check swap file exist
if [ -f /opt/.swap ] ; then
	swap_part=`cat /proc/swaps | grep 'partition' 2>/dev/null`
	swap_file=`cat /proc/swaps | grep 'file' 2>/dev/null`
	if [ -z "$swap_part" ] && [ -z "$swap_file" ] ; then
		swapon /opt/.swap
		[ $? -eq 0 ] && logger -t "${self_name}" "Activate swap file /opt/.swap SUCCESS!"
	fi
fi
# 卸载 /opt/.swap
# check swap file exist
# if [ -f /opt/.swap ] ; then
	# swapoff /opt/.swap 2>/dev/null
	# [ $? -eq 0 ] && logger -t "${self_name}" "Deactivate swap file /opt/.swap SUCCESS!"
# fi

}

mount_opt () {
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
if [ ! -z "$upanPath" ] ; then
	mkdir -p "$upanPath/opt"
	mount -o bind "$upanPath/opt" /opt
	rm -f /tmp/AiDisk_00
	ln -sf "$upanPath" /tmp/AiDisk_00
	# prepare ssh authorized_keys
	prepare_authorized_keys
else
	mkdir -p /tmp/AiDisk_00/opt
	mount -o bind /tmp/AiDisk_00/opt /opt
fi
mkdir -p /opt/bin

}

AiDisk00 () {
[ -d /tmp/AiDisk_00/opt ] && return
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
if [ ! -z "$upanPath" ] ; then
	mkdir -p "$upanPath/opt"
	rm -f /tmp/AiDisk_00
	ln -sf "$upanPath" /tmp/AiDisk_00
else
	mkdir -p /tmp/AiDisk_00/opt
fi
mkdir -p /opt/bin
if [ ! -f /sbin/check_network ] && [ ! -f /opt/bin/check_network ] ; then
	wgetcurl.sh '/opt/bin/check_network' "$hiboyfile/check_network" "$hiboyfile2/check_network"
fi
[ -f /sbin/check_network ] && [ -f /opt/bin/check_network ] && rm -f /opt/bin/check_network
# flush buffers
sync

}

opt_file () {
if [ ! -f /opt/opt.tgz ]  ; then
	if [ "$ss_opt_x" = "5" ] ; then
		Available_M=$(df -m | grep "% /opt" | awk 'NR==1' | awk -F' ' '{print $4}')
		[ ! -z "$(echo $Available_M | grep '%')" ] && Available_M=$(df -m | grep '% /opt' | awk 'NR==1' | awk -F' ' '{print $3}')
		logger -t "【opt】" "/opt 可用空间：$Available_M M"
		optPath="`grep ' /opt ' /proc/mounts`"
		[ ! -z "$optPath" ] && { wgetcurl.sh '/opt/opt.tgz' "$optupanfile" "$optupanfile3"; }
	else
		logger -t "【opt】" "/opt 可用空间：$(df -m | grep '% /opt' | awk 'NR==1' | awk -F' ' '{print $4}')M"
		optPath="`grep ' /opt ' /proc/mounts | grep tmpfs`"
		[ ! -z "$optPath" ] && { wgetcurl.sh '/opt/opt.tgz' "$opttmpfile" "$opttmpfile2"; }
		optPath="`grep ' /opt ' /proc/mounts | grep /dev`"
		[ ! -z "$optPath" ] && { wgetcurl.sh '/opt/opt.tgz' "$optupanfile" "$optupanfile3"; }
		logger -t "【opt】" "/opt/opt.tgz 下载完成，开始解压"
	fi
else
	logger -t "【opt】" "/opt/opt.tgz 已经存在，开始解压"
fi
tar -xzvf /opt/opt.tgz -C /opt

optPath="`grep ' /opt ' /proc/mounts | grep tmpfs`"
[ ! -z "$optPath" ] && rm -f /opt/opt.tgz
# flush buffers
sync

}

opt_wget () {
#opt检查更新
upopt
if [ "$(cat /tmp/opti.txt)"x != "$(cat /opt/opti.txt)"x ] && [ "$upopt_enable" = "1" ] && [ -f /tmp/opti.txt ] ; then
	logger -t "【opt】" "opt 需要更新, 自动启动更新"
	rm -rf /opt/opti.txt
	rm -rf /opt/lnmp.txt
	rm -rf /opt/opt.tgz
fi
optw_enable=`nvram get optw_enable`
if [ "$optw_enable" != "2" ] ; then
	nvram set optw_enable=2
	nvram commit
fi
if [ ! -f "/opt/opti.txt" ] ; then
	logger -t "【opt】" "自动安装（覆盖 opt 文件夹）"
	logger -t "【opt】" "opt 第一次下载/opt/opt.tgz"
	opt_file
	if [ ! -s "/opt/opti.txt" ] ; then
		logger -t "【opt】" "/opt/opt.tgz 下载失败"
		logger -t "【opt】" "opt 第二次下载/opt/opt.tgz"
		opt_file
	fi
	if [ -s "/opt/opti.txt" ] ; then
		logger -t "【opt】" "opt 解压完成"
		chmod 777 /opt -R
		prepare_authorized_keys
	else
		logger -t "【opt】" "opt 解压失败"
	fi
	optPath="`grep ' /opt ' /proc/mounts | grep tmpfs`"
	if [ -z "$optPath" ] && [ -s "/opt/opt.tgz" ] ; then
		logger -t "【opt】" "opt 解压完成"
		chmod 777 /opt -R
		prepare_authorized_keys
		logger -t "【opt】" "备份文件到 /opt/opt_backup"
		mkdir -p /opt/opt_backup
		tar -xzvf /opt/opt.tgz -C /opt/opt_backup
		if [ -s "/opt/opt_backup/opti.txt" ] ; then
			logger -t "【opt】" "/opt/opt_backup 解压完成"
			# flush buffers
			sync
		else
			logger -t "【opt】" "/opt/opt_backup 解压失败"
		fi
	fi
fi
}

upopt () {
wgetcurl.sh "/tmp/opti.txt" "$optupanfile2" "$optupanfile4"
[ -s /tmp/opti.txt ] && cp -f /tmp/opti.txt /tmp/lnmpi.txt
nvram set opto="`cat /opt/opti.txt`"
nvram set optt="`cat /tmp/opti.txt`"
nvram set lnmpo="`cat /opt/lnmp.txt`"
nvram set lnmpt="`cat /tmp/lnmpi.txt`"
}

libmd5_check () {
optPath="`grep ' /opt ' /proc/mounts | grep tmpfs`"
if [ ! -z "$optPath" ] ; then
	logger -t "【libmd5_恢复】" " /opt/lib/ 在内存储存，跳过恢复"
	return 0
fi
[ ! -f "/opt/opti.txt" ] && logger -t "【libmd5_恢复】" "未找到 /opt/opti.txt 跳过文件恢复" && return 0
if [ ! -f "/opt/opt_backup/opti.txt" ] ; then
	logger -t "【libmd5_恢复】" "未找到备份文件 /opt/opt_backup/opti.txt"
	logger -t "【libmd5_恢复】" "开始解压文件到 /opt/opt_backup"
	[ ! -f "/opt/opt.tgz" ] && logger -t "【libmd5_恢复】" "未找到 /opt/opt.tgz 跳过文件恢复" && return 0
	mkdir -p /opt/opt_backup
	tar -xzvf /opt/opt.tgz -C /opt/opt_backup
	if [ -s "/opt/opti.txt" ] ; then
		logger -t "【libmd5_恢复】" "/opt/opt_backup 文件解压完成"
	fi
fi
logger -t "【libmd5_恢复】" "正在对比 /opt/lib/ 文件 md5"
mkdir -p /tmp/md5/
/usr/bin/find /opt/opt_backup/lib/ -perm '-u+x' -name '*' | grep -v "/lib/opkg" | sort -r  > /tmp/md5/libmd5f
/usr/bin/find /opt/opt_backup/bin/ -perm '-u+x' -name '*' | grep -v "\.sh" | sort -r  >> /tmp/md5/libmd5f
while read line
do
if [ -f "$line" ] ; then
	MD5_backup="$(md5sum $line | awk '{print $1;}')"
	b_line="$(echo $line | sed  "s/$\/opt\/opt_backup\//$\/opt\//g")"
	MD5_OPT="$(md5sum $b_line | awk '{print $1;}')"
	if [ "$MD5_backup"x != "$MD5_OPT"x ] ; then
	logger -t "【libmd5_恢复】" "【 $b_line 】，md5不匹配！"
	logger -t "【libmd5_恢复】" "恢复文件【 $line 】"
	mkdir -p "$(dirname "$b_line")"
	cp -Hrf $line $b_line
	lib_status=1
	fi
fi
done < /tmp/md5/libmd5f
logger -t "【libmd5_恢复】" "md5对比，完成！"
# flush buffers
sync

}

libmd5_backup () {
optPath="`grep ' /opt ' /proc/mounts | grep tmpfs`"
if [ ! -z "$optPath" ] ; then
	logger -t "【libmd5_备份】" " /opt/lib/ 在内存储存，跳过备份"
	return 0
fi
mkdir -p /opt/opt_backup
logger -t "【libmd5_备份】" "正在对比 /opt/lib/ 文件 md5"
mkdir -p /tmp/md5/
/usr/bin/find /opt/lib/ -perm '-u+x' -name '*' | grep -v "/lib/opkg" | sort -r  > /tmp/md5/libmd5f
/usr/bin/find /opt/bin/ -perm '-u+x' -name '*' | grep -v "\.sh" | sort -r  >> /tmp/md5/libmd5f
while read line
do
if [ -f "$line" ] ; then
	MD5_backup="$(md5sum $line | awk '{print $1;}')"
	b_line="$(echo $line | sed  "s/$\/opt\//$\/opt\/opt_backup\//g")"
	MD5_OPT="$(md5sum $b_line | awk '{print $1;}')"
	if [ "$MD5_backup"x != "$MD5_OPT"x ] ; then
	logger -t "【libmd5_备份】" "【 $b_line 】，md5不匹配！"
	logger -t "【libmd5_备份】" "备份文件【 $line 】"
	mkdir -p "$(dirname "$b_line")"
	cp -Hrf $line $b_line
	lib_status=1
	fi
fi
done < /tmp/md5/libmd5f
logger -t "【libmd5_备份】" "md5对比，完成！"
# flush buffers
sync

}

case $ACTION in
start)
	mount_check
	[ "$optinstall" = "1" ] && opt_wget
	;;
check)
	mount_check
	[ "$optinstall" = "1" ] && opt_wget
	;;
check_opt)
	mount_check
	;;
optwget)
	mount_check
	opt_wget
	;;
upopt)
	mount_check
	if [ "$optinstall" = "1" ] || [ "$upopt_enable" = "1" ] ; then
		opt_wget
	else
		upopt
	fi
	;;
reopt)
	mount_check
	rm -rf /opt/opti.txt
	rm -rf /opt/lnmp.txt
	opt_wget
	[ -f /opt/lcd.tgz ] && untar.sh "/opt/lcd.tgz" "/opt/" "/opt/bin/lcd4linux"
	;;
libmd5_check)
	libmd5_check
	;;
libmd5_backup)
	libmd5_backup &
	;;
*)
	mount_check
	if [ "$optinstall" = "1" ] || [ "$upopt_enable" = "1" ] ; then
		opt_wget
	fi
	;;
esac

