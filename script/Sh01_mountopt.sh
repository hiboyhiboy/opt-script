#!/bin/sh
#copyright by hiboy
source /etc/storage/script/init.sh
#nvramshow=`nvram showall | grep opt | awk '{print gensub(/'"'"'/,"'"'"'\"'"'"'\"'"'"'","g",$0);}'| awk '{print gensub(/=/,"='\''",1,$0)"'\'';";}'` && eval $nvramshow
optinstall=`nvram get optinstall`
ss_opt_x=`nvram get ss_opt_x`
upopt_enable=`nvram get upopt_enable`

[ -z $ss_opt_x ] && ss_opt_x=1 && nvram set ss_opt_x="$ss_opt_x"

if [ ! -z "$(echo $scriptfilepath | grep -v "/tmp/script/" | grep mountopt)" ]  && [ ! -s /tmp/script/_mountopt ]; then
	mkdir -p /tmp/script
	ln -sf $scriptfilepath /tmp/script/_mountopt
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

mount_check() {
mountp=mountp
mountpoint -q /opt && mountp=0 || mountp=1 # 0已挂载 1没挂载
optPath="`grep ' /opt ' /proc/mounts | grep tmpfs| awk '{print $1}'`"
if [ "$mountp" = "0" ] && [ -z "$optPath" ] ; then
	optPath="`df -m | grep $(df -m | grep /opt | awk '{print $1}') | grep "/media"| awk '{print $NF}' | awk 'NR==1' `"
	if [ -z "$optPath" ] ; then
		logger -t "【opt】" "opt 挂载异常，重新挂载：umount -l /opt"
		umount -l /opt
		mount_opt
	else
		logger -t "【opt】" "opt 挂载正常：$optPath"
	fi
else
	[ "$mountp" = "1" ] && logger -t "【opt】" "opt 没挂载，重新挂载"
	[ "$mountp" = "1" ] && mount_opt
	[ "$mountp" = "0" ] && logger -t "【opt】" "opt 挂载正常：$optPath"
fi
AiDisk00
}

mount_opt () {
upanPath=""
[ "$ss_opt_x" = "3" ] && upanPath="`df -m | grep /dev/mmcb | grep "/media" | awk '{print $NF}' | awk 'NR==1' `"
[ "$ss_opt_x" = "4" ] && upanPath="`df -m | grep "/dev/sd" | grep "/media" | awk '{print $NF}' | awk 'NR==1' `"
[ -z "$upanPath" ] && [ "$ss_opt_x" = "1" ] && upanPath="`df -m | grep /dev/mmcb | grep "/media" | awk '{print $NF}' | awk 'NR==1' `"
[ -z "$upanPath" ] && [ "$ss_opt_x" = "1" ] && upanPath="`df -m | grep "/dev/sd" | grep "/media" | awk '{print $NF}' | awk 'NR==1' `"
if [ ! -z "$upanPath" ] ; then
	mkdir -p "$upanPath/opt"
	mount -o bind "$upanPath/opt" /opt
	ln -sf "$upanPath" /tmp/AiDisk_00
	# expand home to opt
	if [ -d /opt/home/admin ] ; then
		rm -f /home/admin
		ln -sf /opt/home/admin /home/admin
		chmod 700 /opt/home/admin
	fi

	# prepare ssh authorized_keys
	if [ -f /etc/storage/authorized_keys ] && [ ! -f /opt/home/admin/.ssh/authorized_keys ] ; then
		mkdir -p /opt/home/admin/.ssh
		cp -f /etc/storage/authorized_keys /opt/home/admin/.ssh
		chmod 700 /opt/home/admin/.ssh
		chmod 600 /opt/home/admin/.ssh/authorized_keys
	fi
	
	#使用文件创建swap分区
	#bs  blocksize ，每个块大小为1k.count=204800。则总大小为200M的文件
	#dd if=/dev/zero of=/opt/.swap bs=1k count=204800
	#mkswap /opt/.swap
	# 挂载 /opt/.swap
	# check swap file exist
	if [ -z "$mtd_device" ] && [ -f /opt/.swap ] ; then
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
else
	mkdir -p /tmp/AiDisk_00/opt
	mount -o bind /tmp/AiDisk_00/opt /opt
fi
mkdir -p /opt/bin

}

AiDisk00 () {
[ -d /tmp/AiDisk_00/opt ] && return
upanPath=""
[ "$ss_opt_x" = "3" ] && upanPath="`df -m | grep /dev/mmcb | grep "/media" | awk '{print $NF}' | awk 'NR==1' `"
[ "$ss_opt_x" = "4" ] && upanPath="`df -m | grep "/dev/sd" | grep "/media" | awk '{print $NF}' | awk 'NR==1' `"
[ -z "$upanPath" ] && [ "$ss_opt_x" = "1" ] && upanPath="`df -m | grep /dev/mmcb | grep "/media" | awk '{print $NF}' | awk 'NR==1' `"
[ -z "$upanPath" ] && [ "$ss_opt_x" = "1" ] && upanPath="`df -m | grep "/dev/sd" | grep "/media" | awk '{print $NF}' | awk 'NR==1' `"
if [ ! -z "$upanPath" ] ; then
	mkdir -p "$upanPath/opt"
	ln -sf "$upanPath" /tmp/AiDisk_00
else
	mkdir -p /tmp/AiDisk_00/opt
fi
mkdir -p /opt/bin
}

opt_file () {
if [ ! -f /opt/opt.tgz ]  ; then
optPath="`grep ' /opt ' /proc/mounts | grep tmpfs`"
[ ! -z "$optPath" ] && { wgetcurl.sh '/opt/opt.tgz' "$opttmpfile" "$opttmpfile2"; }
optPath="`grep ' /opt ' /proc/mounts | grep /dev`"
[ ! -z "$optPath" ] && { wgetcurl.sh '/opt/opt.tgz' "$optupanfile" "$optupanfile3"; }
logger -t "【opt】" "/opt/opt.tgz 下载完成，开始解压"
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
		logger -t "【opt】" "备份文件到 /opt/opt_backup"
		mkdir -p /opt/opt_backup
		tar -xzvf /opt/opt.tgz -C /opt/opt_backup
		if [ -s "/opt/opt_backup/opti.txt" ] ; then
			logger -t "【opt】" "/opt/opt_backup 解压完成"
		else
			logger -t "【opt】" "/opt/opt_backup 解压失败"
		fi
		# flush buffers
		sync
	else
		logger -t "【opt】" "opt 解压失败"
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
	MD5_backup=$(md5sum $line | awk '{print $1;}')
	b_line=`echo $line | sed  "s/\/opt\/opt_backup\//\/opt\//g" `
	MD5_OPT=$(md5sum $b_line | awk '{print $1;}')
	if [ "$MD5_backup"x != "$MD5_OPT"x ] ; then
	logger -t "【libmd5_恢复】" "【 $b_line 】，md5不匹配！"
	logger -t "【libmd5_恢复】" "恢复文件【 $line 】"
	cp -Hrf $line $b_line
	lib_status=1
	fi
fi
done < /tmp/md5/libmd5f
logger -t "【libmd5_恢复】" "md5对比，完成！"

}

libmd5_backup () {
mkdir -p /opt/opt_backup
logger -t "【libmd5_备份】" "正在对比 /opt/lib/ 文件 md5"
mkdir -p /tmp/md5/
/usr/bin/find /opt/lib/ -perm '-u+x' -name '*' | grep -v "/lib/opkg" | sort -r  > /tmp/md5/libmd5f
/usr/bin/find /opt/bin/ -perm '-u+x' -name '*' | grep -v "\.sh" | sort -r  >> /tmp/md5/libmd5f
while read line
do
if [ -f "$line" ] ; then
	MD5_backup=$(md5sum $line | awk '{print $1;}')
	b_line=`echo $line | sed  "s/\/opt\//\/opt\/opt_backup\//g" `
	MD5_OPT=$(md5sum $b_line | awk '{print $1;}')
	if [ "$MD5_backup"x != "$MD5_OPT"x ] ; then
	logger -t "【libmd5_备份】" "【 $b_line 】，md5不匹配！"
	logger -t "【libmd5_备份】" "备份文件【 $line 】"
	cp -Hrf $line $b_line
	lib_status=1
	fi
fi
done < /tmp/md5/libmd5f
logger -t "【libmd5_备份】" "md5对比，完成！"


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
	libmd5_check &
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

