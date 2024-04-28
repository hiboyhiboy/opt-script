#!/bin/bash
#copyright by hiboy
source /etc/storage/script/init.sh
optinstall=`nvram get optinstall`
ss_opt_x=`nvram get ss_opt_x`
upopt_enable=`nvram get upopt_enable`
opt_cifs_dir=`nvram get opt_cifs_dir`
[ -z $opt_cifs_dir ] && opt_cifs_dir="/media/cifs" && nvram set opt_cifs_dir="$opt_cifs_dir"
opt_cifs_2_dir=`nvram get opt_cifs_2_dir`
[ -z $opt_cifs_2_dir ] && opt_cifs_2_dir="/media/cifs" && nvram set opt_cifs_2_dir="$opt_cifs_2_dir"
opt_cifs_block=`nvram get opt_cifs_block`
[ "$opt_cifs_block" = "0" ] && opt_cifs_block="1999" && nvram set opt_cifs_block="$opt_cifs_block"
[ -z $opt_cifs_block ] && opt_cifs_block="1999" && nvram set opt_cifs_block="$opt_cifs_block"
size_tmpfs=`nvram get size_tmpfs`
[ -z $size_tmpfs ] && size_tmpfs="0" && nvram set size_tmpfs="$size_tmpfs"
size_media_enable=`nvram get size_media_enable`
[ -z $size_media_enable ] && size_media_enable="0" && nvram set size_media_enable="$size_media_enable"

[ -z $ss_opt_x ] && ss_opt_x=1 && nvram set ss_opt_x="$ss_opt_x"

if [ ! -z "$(echo $scriptfilepath | grep -v "/tmp/script/" | grep mountopt)" ] && [ ! -s /tmp/script/_mountopt ] ; then
	mkdir -p /tmp/script
	{ echo '#!/bin/bash' ; echo $scriptfilepath '"$@"' ; } > /tmp/script/_mountopt
	chmod 777 /tmp/script/_mountopt
fi

opt_force () {

# 自定义 opt 环境下载地址
opt_force_enable=`nvram get opt_force_enable`
[ -z $opt_force_enable ] && opt_force_enable="0" && nvram set opt_force_enable="$opt_force_enable"
opt_force_file=`nvram get opt_force_file`
[ -z $opt_force_file ] && opt_force_file="https://opt.cn2qq.com/opt-file" && nvram set opt_force_file="$opt_force_file"
opt_force_script=`nvram get opt_force_script`
[ -z $opt_force_script ] && opt_force_script="https://opt.cn2qq.com/opt-script" && nvram set opt_force_script="$opt_force_script"
if [ -z "$(cat /sbin/wgetcurl.sh | grep "/tmp/script/wgetcurl.sh")" ] ; then
opt_force_www=`nvram get opt_force_www`
[ -z $opt_force_www ] && opt_force_www="https://opt.cn2qq.com" && nvram set opt_force_www="$opt_force_www"
opt_force_file="$opt_force_www/opt-script"
opt_force_script="$opt_force_www/opt-script"
fi
if [ "$opt_force_enable" != "0" ] ; then
	opt_force_file="$(echo $opt_force_file | sed  "s@/\$@@g")"
	opt_force_script="$(echo $opt_force_script | sed  "s@/\$@@g")"
	sed -Ei '/^hiboyfile=/d' /etc/storage/script/init.sh
	sed -Ei '/^hiboyscript=/d' /etc/storage/script/init.sh
	echo 'hiboyfile="'$opt_force_file'"' >> /etc/storage/script/init.sh
	echo 'hiboyscript="'$opt_force_script'"' >> /etc/storage/script/init.sh
	hiboyfile="$opt_force_file"
	hiboyscript="$opt_force_script"
else
	sed -Ei '/^hiboyfile=/d' /etc/storage/script/init.sh
	sed -Ei '/^hiboyscript=/d' /etc/storage/script/init.sh
	echo 'hiboyfile="https://opt.cn2qq.com/opt-file"' >> /etc/storage/script/init.sh
	echo 'hiboyscript="https://opt.cn2qq.com/opt-script"' >> /etc/storage/script/init.sh
	hiboyfile="https://opt.cn2qq.com/opt-file"
	hiboyscript="https://opt.cn2qq.com/opt-script"
fi

# 部署离线 opt 环境下载地址
opt_download_enable=`nvram get opt_download_enable`
[ -z $opt_download_enable ] && opt_download_enable="0" && nvram set opt_download_enable="$opt_download_enable"
opt_force_file_tmp="/www/opt-file"
opt_force_script_tmp="/www/opt-script"
if [ "$opt_download_enable" != "0" ] ; then
	nvram set opt_force_enable=1
	# 设置下载地址
	opt_force_file="$opt_force_file_tmp"
	opt_force_script="$opt_force_script_tmp"
	nvram set opt_force_file="$opt_force_file"
	nvram set opt_force_script="$opt_force_script"
	sed -Ei '/^hiboyfile=/d' /etc/storage/script/init.sh
	sed -Ei '/^hiboyscript=/d' /etc/storage/script/init.sh
	echo 'hiboyfile="'$opt_force_file'"' >> /etc/storage/script/init.sh
	echo 'hiboyscript="'$opt_force_script'"' >> /etc/storage/script/init.sh
	hiboyfile="$opt_force_file"
	hiboyscript="$opt_force_script"
else
	if [ "$opt_force_file" == "$opt_force_file_tmp" ] ; then
		opt_force_file="https://opt.cn2qq.com/opt-file"
		opt_force_script="https://opt.cn2qq.com/opt-script"
		nvram set opt_force_file="$opt_force_file"
		nvram set opt_force_script="$opt_force_script"
		sed -Ei '/^hiboyfile=/d' /etc/storage/script/init.sh
		sed -Ei '/^hiboyscript=/d' /etc/storage/script/init.sh
		echo 'hiboyfile="'$opt_force_file'"' >> /etc/storage/script/init.sh
		echo 'hiboyscript="'$opt_force_script'"' >> /etc/storage/script/init.sh
		hiboyfile="$opt_force_file"
		hiboyscript="$opt_force_script"
	fi
fi

 opttmpfile="$hiboyfile/opttmpg12.tgz"
 opttmpfile2="$hiboyfile2/opttmpg12.tgz"
 
 optupanfile="$hiboyfile/optupang12.tgz"
 optupanfile2="$hiboyfile2/optupang12.tgz"
 optupanfileS="10"
 optupanfile_md5="95ad0784dc31263e994fb5a3d2a670e5"
 
 opt_txt_file1="$hiboyfile/optg12.txt"
 opt_txt_file2="$hiboyfile2/optg12.txt"
}

opt_force

opt_cdn_force () {

opt_force_enable=`nvram get opt_force_enable`
if [ "$opt_force_enable" != "0" ] ; then
	logger -t "【script】" "自定义 opt 环境下载地址失效 $opt_force_file"
	logger -t "【script】" "建议使用免费CDN https://gcore.jsdelivr.net/gh/HiboyHiboy/opt-file"
else
	if [ ! -z "$(ping -4 -c 1 -w 4 -q "gcore.jsdelivr.net" | head -n1 | sed -r 's/\(|\)/|/g' | awk -F'|' '{print $2}')" ] ; then
	opt_force_enable="1" && nvram set opt_force_enable="$opt_force_enable"
	opt_download_enable=`nvram get opt_download_enable`
	if [ "$opt_download_enable" != "0" ] ; then
		opt_download_enable="0" && nvram set opt_download_enable="$opt_download_enable"
	fi
	opt_force_file="https://gcore.jsdelivr.net/gh/HiboyHiboy/opt-file" && nvram set opt_force_file="$opt_force_file"
	opt_force_script="https://gcore.jsdelivr.net/gh/HiboyHiboy/opt-script" && nvram set opt_force_script="$opt_force_script"
	logger -t "【script】" "下载地址失效 https://opt.cn2qq.com"
	logger -t "【script】" "变更使用免费CDN https://gcore.jsdelivr.net/gh/HiboyHiboy/opt-file"
	opt_force
	fi
fi

}

# /etc/storage/script/sh01_mountopt.sh

# ss_opt_x 
# 1 >>自动选择:SD→U盘→内存
# 2 >>安装到内存:需要空余内存(10M+)
# 3 >>安装到 SD
# 4 >>安装到 U盘
# 5 >>安装到 指定目录
# 6 >>安装到 远程共享
# 不是ext4磁盘时用镜像生成opt

func_stop_apps()
{
	stop_rstats
}

func_start_apps()
{
	start_rstats
}

mount_check_lock () {

# 检查挂载异常设备
dev_full=$(cat  /proc/mounts | awk '{print $1}' | grep -v "^//" | grep -v -E "$(echo $(/usr/bin/find /dev/ -name '*') | sed -e 's@/dev/ /dev/@/dev/@g' | sed -e 's@ @|@g')" | grep "/dev/")
[ ! -z "$dev_full" ] && dev_mount=$(cat  /proc/mounts | grep $dev_full | grep /media/ | awk '{print $2}')
if [ ! -z "$dev_mount" ] && [ ! -z "$dev_full" ] ; then
if mountpoint -q "$dev_mount" ; then
	logger -t "【opt】" "发现挂载异常设备，尝试移除： $dev_full   $dev_mount"
	/tmp/re_upan_storage.sh 0
	func_stop_apps
	mountres2=`losetup -a | grep $dev_mount | grep o_p_t.img | awk -F ':' '{print $1}'`
	[ ! -z "$mountres2" ] && /usr/bin/opt-umount.sh $dev_full   $dev_mount
	mountres2=`losetup -a | grep $dev_mount | grep o_p_t.img | awk -F ':' '{print $1}'`
	if [ ! -z "$mountres2" ] ; then
		/usr/bin/opt-umount.sh $dev_full   $dev_mount
		for varloop0 in $(echo $(grep "$(losetup -a | grep $dev_mount | grep o_p_t.img | awk -F ':' '{print $1}')" /proc/mounts | grep -v /media/o_p_t_img | awk -F' ' '{print $2}'))
		do
			umount "$varloop0"
			umount -l "$varloop0"
		done
		mountpoint -q /media/o_p_t_img && umount /media/o_p_t_img
		mountpoint -q /media/o_p_t_img && umount -l /media/o_p_t_img
		mountpoint -q /media/o_p_t_img && { fuser -m -k /media/o_p_t_img 2>/dev/null ; umount -l /media/o_p_t_img ; }
		mountpoint -q /media/o_p_t_img && umount -l /media/o_p_t_img
		losetup -d `losetup -a | grep $dev_mount | grep o_p_t.img | awk -F ':' '{print $1}'`
	fi
	for varloop0 in $(echo $(grep "$dev_full" /proc/mounts | grep -v $dev_mount | awk -F' ' '{print $2}'))
	do
		umount "$varloop0"
		umount -l "$varloop0"
	done
	mountpoint -q "$dev_mount" && umount $dev_mount
	mountpoint -q "$dev_mount" && umount -l $dev_mount
	mountpoint -q "$dev_mount" && fuser -m -k $dev_mount 2>/dev/null
	mountpoint -q "$dev_mount" && umount -l $dev_mount
	if mountpoint -q "$dev_mount" ; then
		logger -t "【opt】" "挂载异常设备，尝试移除失败"
	fi
	func_start_apps
fi
fi
ss_opt_x=`nvram get ss_opt_x`
mountp="mountp"
mountpoint -q /opt && mountp=0 || mountp=1 # 0已挂载 1没挂载
if [ "$mountp" = "0" ] ; then
	# 找不到opt所在设备
	optPath="`grep ' /opt ' /proc/mounts | grep tmpfs| awk '{print $1}'`"
	[ -z "$optPath" ] && optPath=$(grep ' /opt ' /proc/mounts | grep -v "^//" | awk '{print $1}' | grep -E "$(echo $(/usr/bin/find /dev/ -name '*') | sed -e 's@/dev/ /dev/@/dev/@g' | sed -e 's@ @|@g')")
	[ -z "$optPath" ] && optPath="$(grep ' /opt ' /proc/mounts | grep " cifs "| awk '{print $1}')"
	if [ -z "$optPath" ] ; then
		func_stop_apps
		logger -t "【opt】" "opt 选项[$ss_opt_x] 挂载异常，重新挂载：umount -l /opt"
		/usr/bin/opt-umount.sh $(grep ' /opt ' /proc/mounts | awk '{print $1}')    $(df -m | grep "$(df -m | grep '% /opt' | awk 'NR==1' | awk '{print $1}')" | grep "/media"| awk '{print $NF}' | awk 'NR==1' )
		mountpoint -q /opt && umount /opt
		mountpoint -q /opt && umount -l /opt
		mountpoint -q /opt && { fuser -m -k /opt 2>/dev/null ; umount -l /opt ; }
		func_start_apps
		mount_opt
	else
		logger -t "【opt】" "opt 挂载正常：$optPath"
		# 部署离线 opt 环境下载地址
		opt_download
		/tmp/re_upan_storage.sh &
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

ln_mk () {

# 创建软链
/usr/bin/find /opt/ -type l -exec ls -l {} \; | grep -v opt_backup | awk '{print substr($0,58)}' > /opt/ln.txt ; sed -Ei "s/ -> /丨/g" /opt/ln.txt ; sed -Ei "s@^/opt@@g" /opt/ln.txt ;
}

ln_check () {

ln_mkflie="off"
[ ! -s "/opt/ln.txt" ] && return
[ "$(md5sum /opt/etc/passwd | awk '{print $1;}')" != "$(md5sum /etc/passwd | awk '{print $1;}')" ] && ln_mkflie="on"
[ -d /opt/opt_backup ] && [ "$(md5sum /opt/opt_backup/etc/passwd | awk '{print $1;}')" != "$(md5sum /etc/passwd | awk '{print $1;}')" ] && ln_mkflie="on"
[ "$ln_mkflie" == "off" ] && return
logger -t "【opt】" "ln 链接文件失效，开始恢复 ln 链接文件为原始文件"
echo '#!/bin/bash' > /opt/ln_mkflie.sh
chmod 777 /opt/ln_mkflie.sh
cat /opt/ln.txt | awk -F '丨' '{print "cd \"\$\(dirname \"/opt"$1"\"\)\"\; [ -f /opt"$1" ] && \{ rm -f /opt"$1" \; \}"}' >> /opt/ln_mkflie.sh
[ -d /opt/opt_backup ] && cat /opt/ln.txt | awk -F '丨' '{print "cd \"\$\(dirname \"/opt/opt_backup"$1"\"\)\"\; [ -f /opt/opt_backup"$1" ] && \{ rm -f /opt/opt_backup"$1" \; \}"}' >> /opt/ln_mkflie.sh
/opt/ln_mkflie.sh # 删除旧文件
echo '#!/bin/bash' > /opt/ln_mkflie.sh
chmod 777 /opt/ln_mkflie.sh
cat /opt/ln.txt | awk -F '丨' '{print "cd \"\$\(dirname \"/opt"$1"\"\)\"\; [ ! -f /opt"$1" ] && [ -f "$2" ] && \{ cp -f "$2" /opt"$1" \; chmod 777 /opt"$1" \; \}"}' >> /opt/ln_mkflie.sh
[ -d /opt/opt_backup ] && cat /opt/ln.txt | awk -F '丨' '{print "cd \"\$\(dirname \"/opt/opt_backup"$1"\"\)\"\; [ ! -f /opt/opt_backup"$1" ] && [ -f "$2" ] && \{ cp -f "$2" /opt/opt_backup"$1" \; chmod 777 /opt/opt_backup"$1" \; \}"}' >> /opt/ln_mkflie.sh
/opt/ln_mkflie.sh ; /opt/ln_mkflie.sh ; /opt/ln_mkflie.sh ; /opt/ln_mkflie.sh # 一些文件是多级链接需要多次处理
logger -t "【opt】" "完成恢复 ln 链接文件"
rm -f /opt/ln_mkflie.sh
rm -f /opt/bin/grep  /opt/opt_backup/bin/grep
rm -f /opt/bin/sed  /opt/opt_backup/bin/sed
rm -f /opt/bin/ash  /opt/opt_backup/bin/ash
rm -f /opt/bin/sh  /opt/opt_backup/bin/sh
rm -f /opt/bin/netstat  /opt/opt_backup/bin/netstat
rm -f /opt/sbin/ifconfig  /opt/opt_backup/sbin/ifconfig
rm -f /opt/sbin/route  /opt/opt_backup/bin/sbin/route
if [ ! -z "$(/usr/bin/find /opt/lib/ld.so.1 -type f)" ] ; then
	cp -f /etc/shadow /opt/etc/shadow
	cp -f /etc/passwd /opt/etc/passwd
	cp -f /etc/group /opt/etc/group
	cp -f /etc/shells /opt/etc/shells
	cp -f /etc/TZ /opt/etc/TZ
fi
}

prepare_authorized_keys () {

# prepare /etc/localtime
ln -sf /opt/etc/localtime /etc/localtime

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
fi
[ -f /home/admin/.wget-hsts ] && chmod 644 /home/admin/.wget-hsts
[ -d /home/admin/.ssh ] && chmod 700 /home/admin/.ssh
[ -f /home/admin/.ssh/authorized_keys ] && chmod 600 /home/admin/.ssh/authorized_keys
# Fix for multiuser environment
chmod 777 /opt/tmp
[ ! -s /opt/etc/TZ ] && ln -sf /etc/TZ /opt/etc/TZ
[ ! -s /opt/etc/group ] && ln -sf /etc/group /opt/etc/group
[ ! -s /opt/etc/passwd ] && ln -sf /etc/passwd /opt/etc/passwd
[ ! -s /opt/etc/TZ ] && cp -f /etc/TZ /opt/etc/TZ
[ ! -s /opt/etc/group ] && cp -f /etc/group /opt/etc/group
[ ! -s /opt/etc/passwd ] && cp -f /etc/passwd /opt/etc/passwd
# now try create symlinks - it is a std installation
if [ -f /etc/shells ]
then
	[ ! -s /opt/etc/shells ] && ln -sf /etc/shells /opt/etc/shells
	[ ! -s /opt/etc/shells ] && cp -f /etc/shells /opt/etc/shells
else
	cp /opt/etc/shells.1 /opt/etc/shells
fi

if [ -f /etc/shadow ]
then
	[ ! -s /opt/etc/shadow ] && ln -sf /etc/shadow /opt/etc/shadow
	[ ! -s /opt/etc/shadow ] && cp -f /etc/shadow /opt/etc/shadow
fi

if [ -f /etc/gshadow ]
then
	[ ! -s /opt/etc/gshadow ] && ln -sf /etc/gshadow /opt/etc/gshadow
	[ ! -s /opt/etc/gshadow ] && cp -f /etc/gshadow /opt/etc/gshadow
fi

if [ -f /etc/localtime ]
then
	[ ! -s /opt/etc/localtime ] && ln -sf /etc/localtime /opt/etc/localtime
	[ ! -s /opt/etc/localtime ] && cp -f /etc/localtime /opt/etc/localtime
fi	
ldconfig > /dev/null 2>&1
ldconfig -f /etc/ld.so.conf -C /etc/ld.so.cache > /dev/null 2>&1
#使用文件创建swap分区
#bs  blocksize ，每个块大小为1k.count=204800。则总大小为200M的文件
#dd if=/dev/zero of=/opt/.swap bs=1k count=204800
#mkswap /opt/.swap
# 挂载 /opt/.swap
# check swap file exist
if [ -f /opt/.swap ] && [ -f /proc/swaps ] ; then
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
[ "$ss_opt_x" = "3" ] && upanPath="`df -m | grep /dev/mmcb | grep -E "$(echo $(/usr/bin/find /dev/ -name 'mmcb*') | sed -e 's@/dev/ /dev/@/dev/@g' | sed -e 's@ @|@g')" | grep "/media" | awk '{print $NF}' | sort -u | awk 'NR==1' `"
[ "$ss_opt_x" = "4" ] && upanPath="`df -m | grep /dev/sd | grep -E "$(echo $(/usr/bin/find /dev/ -name 'sd*') | sed -e 's@/dev/ /dev/@/dev/@g' | sed -e 's@ @|@g')" | grep "/media" | awk '{print $NF}' | sort -u | awk 'NR==1' `"
[ -z "$upanPath" ] && [ "$ss_opt_x" = "1" ] && upanPath="`df -m | grep /dev/mmcb | grep -E "$(echo $(/usr/bin/find /dev/ -name 'mmcb*') | sed -e 's@/dev/ /dev/@/dev/@g' | sed -e 's@ @|@g')" | grep "/media" | awk '{print $NF}' | sort -u | awk 'NR==1' `"
[ -z "$upanPath" ] && [ "$ss_opt_x" = "1" ] && upanPath="`df -m | grep /dev/sd | grep -E "$(echo $(/usr/bin/find /dev/ -name 'sd*') | sed -e 's@/dev/ /dev/@/dev/@g' | sed -e 's@ @|@g')" | grep "/media" | awk '{print $NF}' | sort -u | awk 'NR==1' `"
if [ "$ss_opt_x" = "6" ] ; then
	# 远程共享
	modprobe -q ext4
	if ! mountpoint -q "$opt_cifs_2_dir" || [ ! -d $opt_cifs_2_dir ] ; then
		[ -s /etc/storage/cifs_script.sh ] && source /etc/storage/cifs_script.sh
	fi
	if mountpoint -q "$opt_cifs_2_dir" && [ -d "$opt_cifs_2_dir" ] ; then
		upanPath="$opt_cifs_2_dir"
	else
		logger -t "【opt】" "错误！未找到指定远程共享目录 $opt_cifs_2_dir"
	fi
fi
if [ "$ss_opt_x" = "5" ] ; then
	# 指定目录
	if [ -d $opt_cifs_dir ] ; then
		upanPath="$opt_cifs_dir"
	else
		logger -t "【opt】" "错误！未找到指定目录 $opt_cifs_dir"
	fi
fi
if [ ! -z "$upanPath" ] ; then
	func_stop_apps
	mkdir -p /tmp/AiDisk_opt
	mountpoint -q /tmp/AiDisk_opt && umount /tmp/AiDisk_opt
	mount -o bind "$upanPath" /tmp/AiDisk_opt
	[ "$(cat  /proc/mounts | grep " /tmp/AiDisk_opt " | awk '{print $3}')" = "ext4" ] && ext4_check=1 || ext4_check=0
	if [ "$ext4_check" = "0" ] ; then
        [ "$(cat  /proc/mounts | grep " /tmp/AiDisk_opt " | awk '{print $3}')" = "ubifs" ] && ext4_check=1
	fi
	mountpoint -q /tmp/AiDisk_opt && umount /tmp/AiDisk_opt
	[ -z "$(ls -l /tmp/AiDisk_opt)" ] && rm -rf /tmp/AiDisk_opt
	[ "$ext4_check" = "1" ] && [ -f "$upanPath/opt/o_p_t.img" ] && ext4_check=0
	if [ "$(losetup -h 2>&1 | wc -l)" -gt 2 ] && [ "$ext4_check" = "0" ] ; then
		# 不是ext4磁盘时用镜像生成opt
		mkoptimg "$upanPath"
	fi
	if ! mountpoint -q /opt ; then
		[ ! -d "$upanPath/opt" ] && mkdir -p "$upanPath/opt"
		logger -t "【opt】" "$upanPath/opt文件夹模式挂载/opt"
		mount -o bind "$upanPath/opt" /opt
	fi
	rm -f /tmp/AiDisk_00
	[ -d /tmp/AiDisk_00 ] || rm -rf /tmp/AiDisk_00
	ln -sf "$upanPath" /tmp/AiDisk_00
	sync
	func_start_apps
	# prepare ssh authorized_keys
	prepare_authorized_keys
	# 部署离线 opt 环境下载地址
	opt_download
	/tmp/re_upan_storage.sh &
else
	logger -t "【opt】" "/tmp/AiDisk_00/opt文件夹模式挂载/opt"
	[ "$size_tmpfs" = "0" ] && mount -o remount,size=50% tmpfs /tmp
	mountpoint -q /opt && umount /opt
	mountpoint -q /tmp/AiDisk_00 && umount /tmp/AiDisk_00
	rm -rf /tmp/AiDisk_00
	mkdir -p /tmp/AiDisk_00/opt
	mount -o bind /tmp/AiDisk_00/opt /opt
fi
mkdir -p /opt/bin

}

opt_update_download () {

[ ! -d /tmp/AiDisk_00/ ] && return
[ "$opt_download_enable" == "0" ] && return
if [ ! -d /tmp/AiDisk_00/cn2qq/opt-script ] || [ ! -d /tmp/AiDisk_00/cn2qq/opt-file ] ; then
opt_download
fi

logger -t "【opt】" "增量更新离线 opt 环境下载地址"
cn2qq_name="/tmp/AiDisk_00/cn2qq/opt-script"
if [ -d $cn2qq_name ] ; then
logger -t "【opt】" "opt-script 开始匹配： $cn2qq_name"
cd $cn2qq_name
#md5sum `/usr/bin/find ./ -type f | grep -v .git | grep -v md5.md5 | grep -v up_name.md5 | grep -v up_name.txt` > ./md5.md5
wgetcurl_checkmd5 "$cn2qq_name/up_name.md5" "https://opt.cn2qq.com/opt-script/md5.md5" "https://raw.githubusercontent.com/hiboyhiboy/opt-script/master/md5.md5"
if [ -s $cn2qq_name/up_name.md5 ] ; then
# 生成不匹配文件名
cd $cn2qq_name
md5sum -c $cn2qq_name/up_name.md5 | grep ": FAILED" | awk -F ':' '{print($1)}' | sed -e 's@^./@/@g' > $cn2qq_name/up_name.txt
# 下载不匹配文件
cat $cn2qq_name/up_name.txt | grep -v '^$' | while read update_addr; do [ ! -z "$update_addr" ] &&  wgetcurl_checkmd5 "$cn2qq_name$update_addr" "https://opt.cn2qq.com/opt-script$update_addr" "https://raw.githubusercontent.com/hiboyhiboy/opt-script/master$update_addr" Y; done
rm -f $cn2qq_name/up_name.txt
logger -t "【opt】" "opt-script 匹配完成： $cn2qq_name"
else
logger -t "【opt】" "opt-script 下载匹配md5文件失败"
fi
else
logger -t "【opt】" "opt-script 找不到目录： $cn2qq_name"
fi

cn2qq_name="/tmp/AiDisk_00/cn2qq/opt-file"
if [ -d $cn2qq_name ] ; then
logger -t "【opt】" "opt-file 开始匹配： $cn2qq_name"
cd $cn2qq_name
#md5sum `/usr/bin/find ./ -type f | grep -v .git | grep -v md5.md5 | grep -v up_name.md5 | grep -v up_name.txt` > ./md5.md5
wgetcurl_checkmd5 "$cn2qq_name/up_name.md5" "https://opt.cn2qq.com/opt-file/md5.md5" "https://raw.githubusercontent.com/hiboyhiboy/opt-file/master/md5.md5"
if [ -s $cn2qq_name/up_name.md5 ] ; then
# 生成不匹配文件名
cd $cn2qq_name
md5sum -c $cn2qq_name/up_name.md5 | grep ": FAILED" | awk -F ':' '{print($1)}' | sed -e 's@^./@/@g' > $cn2qq_name/up_name.txt
# 下载不匹配文件
cat $cn2qq_name/up_name.txt | grep -v '^$' | while read update_addr; do [ ! -z "$update_addr" ] &&  wgetcurl_checkmd5 "$cn2qq_name$update_addr" "https://opt.cn2qq.com/opt-file$update_addr" "https://raw.githubusercontent.com/hiboyhiboy/opt-file/master$update_addr" Y; done
rm -f $cn2qq_name/up_name.txt
logger -t "【opt】" "opt-file 匹配完成： $cn2qq_name"
else
logger -t "【opt】" "opt-file 下载匹配md5文件失败"
fi
else
logger -t "【opt】" "opt-file 找不到目录： $cn2qq_name"
fi

}

opt_download () {

[ ! -d /tmp/AiDisk_00/ ] && return
# 部署离线 opt 环境下载地址
if [ "$opt_download_enable" != "0" ] ; then
# 目录检测
if [ ! -d /tmp/AiDisk_00/cn2qq/opt-script ] || [ ! -d /tmp/AiDisk_00/cn2qq/opt-file ] ; then
[ ! -d /tmp/AiDisk_00/cn2qq/opt-script ] && logger -t "【opt】" "部署离线 opt-script 环境到 USB/cn2qq/opt-script"
[ ! -d /tmp/AiDisk_00/cn2qq/opt-file ] && logger -t "【opt】" "部署离线 opt-file 环境到 USB/cn2qq/opt-file"
mkdir -p /tmp/AiDisk_00/cn2qq
if [[ "$(unzip -h 2>&1 | wc -l)" -gt 2 ]] ; then
	opt_download_script="https://github.com/hiboyhiboy/opt-script/archive/master.zip"
	opt_download_file="https://github.com/hiboyhiboy/opt-file/archive/master.zip"
else
	opt_download_script="https://opt.cn2qq.com/opt-script.tgz"
	opt_download_file="https://opt.cn2qq.com/opt-file.tgz"
fi

[ -d /tmp/AiDisk_00/cn2qq/opt-script-master ] && { rm -rf /tmp/AiDisk_00/cn2qq/opt-script; ln -sf /tmp/AiDisk_00/cn2qq/opt-script-master /tmp/AiDisk_00/cn2qq/opt-script; }
if [ ! -d /tmp/AiDisk_00/cn2qq/opt-script ] ; then
	rm -rf /tmp/AiDisk_00/cn2qq/opt-script
	rm -rf /tmp/AiDisk_00/cn2qq/opt-script-master
if [ ! -f /tmp/AiDisk_00/cn2qq/opt-script.tgz ] ; then
	rm -f /tmp/AiDisk_00/cn2qq/opt-script.tgz
	logger -t "【opt】" "/tmp/AiDisk_00/cn2qq 可用空间：$(df -m | grep '% /tmp/AiDisk_00/cn2qq' | awk 'NR==1' | awk -F' ' '{print $4}')M"
	logger -t "【opt】" "下载: $opt_download_script"
	logger -t "【opt】" "下载到 USB/cn2qq/opt-script.tgz"
	wgetcurl.sh '/tmp/AiDisk_00/cn2qq/opt-script.tgz' "$opt_download_script" "$opt_download_script"
	logger -t "【opt】" "/tmp/AiDisk_00/cn2qq/opt-script.tgz 下载完成，开始解压"
else
	logger -t "【opt】" "/tmp/AiDisk_00/cn2qq/opt-script.tgz 已经存在，开始解压"
fi
if [[ "$(unzip -h 2>&1 | wc -l)" -gt 2 ]] ; then
	unzip -o /tmp/AiDisk_00/cn2qq/opt-script.tgz -d /tmp/AiDisk_00/cn2qq/
	[ -d /tmp/AiDisk_00/cn2qq/opt-script-master ] && { rm -rf /tmp/AiDisk_00/cn2qq/opt-script; ln -sf /tmp/AiDisk_00/cn2qq/opt-script-master /tmp/AiDisk_00/cn2qq/opt-script; }
else
	tar -xz -C /tmp/AiDisk_00/cn2qq/ -f /tmp/AiDisk_00/cn2qq/opt-script.tgz
fi
if [ ! -d /tmp/AiDisk_00/cn2qq/opt-script ] ; then
	tar -xz -C /tmp/AiDisk_00/cn2qq/ -f /tmp/AiDisk_00/cn2qq/opt-script.tgz
	unzip -o /tmp/AiDisk_00/cn2qq/opt-script.tgz -d /tmp/AiDisk_00/cn2qq/
	[ -d /tmp/AiDisk_00/cn2qq/opt-script-master ] && { rm -rf /tmp/AiDisk_00/cn2qq/opt-script; ln -sf /tmp/AiDisk_00/cn2qq/opt-script-master /tmp/AiDisk_00/cn2qq/opt-script; }
fi
logger -t "【opt】" "$upanPath/cn2qq/opt-script.tgz 解压完成！"
if [ -f /tmp/AiDisk_00/cn2qq/opt-file/osub ] ; then
wgetcurl.sh '/tmp/osub_tmp' "https://opt.cn2qq.com/opt-file/osub" "https://raw.githubusercontent.com/hiboyhiboy/opt-file/master/osub"
if [ -s /tmp/osub_tmp ] ; then
	cp -f /tmp/osub_tmp /tmp/AiDisk_00/cn2qq/opt-file/osub
	rm -f /tmp/osub_tmp
fi
fi
# flush buffers
sync
fi

[ -d /tmp/AiDisk_00/cn2qq/opt-file-master ] && { rm -rf /tmp/AiDisk_00/cn2qq/opt-file; ln -sf /tmp/AiDisk_00/cn2qq/opt-file-master /tmp/AiDisk_00/cn2qq/opt-file; }
if [ ! -d /tmp/AiDisk_00/cn2qq/opt-file ] ; then
	rm -rf /tmp/AiDisk_00/cn2qq/opt-file
	rm -rf /tmp/AiDisk_00/cn2qq/opt-file-master
if [ ! -f /tmp/AiDisk_00/cn2qq/opt-file.tgz ] ; then
	rm -f /tmp/AiDisk_00/cn2qq/opt-file.tgz
	logger -t "【opt】" "/tmp/AiDisk_00/cn2qq 可用空间：$(df -m | grep '% /tmp/AiDisk_00/cn2qq' | awk 'NR==1' | awk -F' ' '{print $4}')M"
	logger -t "【opt】" "下载: $opt_download_file"
	logger -t "【opt】" "下载到 USB/cn2qq/opt-file.tgz"
	wgetcurl.sh '/tmp/AiDisk_00/cn2qq/opt-file.tgz' "$opt_download_file" "$opt_download_file"
	logger -t "【opt】" "/tmp/AiDisk_00/cn2qq/opt-file.tgz 下载完成，开始解压"
else
	logger -t "【opt】" "/tmp/AiDisk_00/cn2qq/opt-file.tgz 已经存在，开始解压"
fi
if [[ "$(unzip -h 2>&1 | wc -l)" -gt 2 ]] ; then
	unzip -o /tmp/AiDisk_00/cn2qq/opt-file.tgz -d /tmp/AiDisk_00/cn2qq/
	[ -d /tmp/AiDisk_00/cn2qq/opt-file-master ] && { rm -rf /tmp/AiDisk_00/cn2qq/opt-file; ln -sf /tmp/AiDisk_00/cn2qq/opt-file-master /tmp/AiDisk_00/cn2qq/opt-file; }
else
	tar -xz -C /tmp/AiDisk_00/cn2qq/ -f /tmp/AiDisk_00/cn2qq/opt-file.tgz
fi
if [ ! -d /tmp/AiDisk_00/cn2qq/opt-file ] ; then
	tar -xz -C /tmp/AiDisk_00/cn2qq/ -f /tmp/AiDisk_00/cn2qq/opt-file.tgz
	unzip -o /tmp/AiDisk_00/cn2qq/opt-file.tgz -d /tmp/AiDisk_00/cn2qq/
	[ -d /tmp/AiDisk_00/cn2qq/opt-file-master ] && { rm -rf /tmp/AiDisk_00/cn2qq/opt-file; ln -sf /tmp/AiDisk_00/cn2qq/opt-file-master /tmp/AiDisk_00/cn2qq/opt-file; }
fi
logger -t "【opt】" "$upanPath/cn2qq/opt-file.tgz 解压完成！"
# flush buffers
sync
fi

fi

fi

}

mkoptimg () {

# 创建o_p_t.img
upanPath="$1"
logger -t "【opt】" "$upanPath/opt/o_p_t.img镜像(ext4)模式挂载/media/o_p_t_img"
if [ ! -s "$upanPath/opt/o_p_t.img" ] && [ ! -z "$(which mkfs.ext4)" ] ; then
	[ -d "$upanPath/opt" ] && mv -f "$upanPath/opt" "$upanPath/opt_old_"$(date "+%Y-%m-%d_%H-%M-%S")
	[ ! -d "$upanPath/opt" ] && mkdir -p "$upanPath/opt"
	[ -d "$upanPath" ] && block="$(check_disk_size $upanPath)"
	[ -z "$block" ] && block="0"
	[ "$block" != "0" ] && logger -t "【opt】" "路径$upanPath剩余空间：$block M"
	[ "$block" = "0" ] && logger -t "【opt】" "路径$upanPath剩余空间：获取失败"
	[ "$block" != "0" ] && [ ! -z "$block" ] && [ "$block" -lt "$opt_cifs_block" ] && opt_cifs_block=$block
	logger -t "【opt】" "创建$upanPath/opt/o_p_t.img镜像(ext4)文件，$opt_cifs_block M"
	rm -f $upanPath/opt/o_p_t.img
	dd if=/dev/zero of=$upanPath/opt/o_p_t.img bs=1M seek=$opt_cifs_block count=0
	sleep 1
	[ ! -f $upanPath/opt/o_p_t.img ] && { rm -f $upanPath/opt/o_p_t.img; dd if=/dev/zero of=$upanPath/opt/o_p_t.img bs=1M seek=$opt_cifs_block count=1 ; sleep 1 ; }
	losetup `losetup -f` $upanPath/opt/o_p_t.img
	mkfs.ext4 -i 16384 `losetup -a | grep o_p_t.img | awk -F ':' '{print $1}'`
fi
if [ ! -s "$upanPath/opt/o_p_t.img" ] && [ -z "$(which mkfs.ext4)" ] ; then
	# 直接下载镜像(ext4)文件
	[ -d "$upanPath/opt" ] && mv -f "$upanPath/opt" "$upanPath/opt_old_"$(date "+%Y-%m-%d_%H-%M-%S")
	[ ! -d "$upanPath/opt" ] && mkdir -p "$upanPath/opt"
	[ -d "$upanPath" ] && block="$(check_disk_size $upanPath)"
	[ -z "$block" ] && block="0"
	[ "$block" != "0" ] && logger -t "【opt】" "路径$upanPath剩余空间：$block M"
	[ "$block" = "0" ] && logger -t "【opt】" "路径$upanPath剩余空间：获取失败"
	if [ "$block" != "0" ] && [ ! -z "$block" ] && [ "$block" -lt "2010" ] ; then
		[ "$block" = "0" ] && logger -t "【opt】" "错误！！！路径$upanPath剩余空间少于 2010M 创建镜像(ext4)文件失败"
	else
	logger -t "【opt】" "创建$upanPath/opt/o_p_t.img镜像(ext4)文件，2000 M"
	if [ ! -s "$upanPath/opt/o_p_t_img_2000M.tgz" ] ; then
	logger -t "【opt】" "下载: $upanPath/opt/o_p_t_img_2000M.tgz"
	wgetcurl.sh "$upanPath/opt/o_p_t_img_2000M.tgz" "$hiboyfile/o_p_t_img_2000M.tgz" "$hiboyfile/o_p_t_img_2000M.tgz"
	fi 
	logger -t "【opt】" "$upanPath/opt/o_p_t_img_2000M.tgz 下载完成，开始解压，解压需要 5-15 分钟。"
	tar -xz -C "$upanPath/opt/" -f "$upanPath/opt/o_p_t_img_2000M.tgz"
	if [ -f "$upanPath/opt/o_p_t.img" ] ; then
	logger -t "【opt】" "$upanPath/opt/o_p_t_img_2000M.tgz 解压完成！"
	losetup `losetup -f` $upanPath/opt/o_p_t.img
	else
	logger -t "【opt】" "错误！！！解压 $upanPath/opt/o_p_t_img_2000M.tgz 失败！"
	fi
	fi
fi
[ -z "$(losetup -a | grep o_p_t.img | awk -F ':' '{print $1}')" ] && losetup `losetup -f` $upanPath/opt/o_p_t.img
[ -z "$(df -m | grep "/dev/loop" | grep "/media/o_p_t_img")" ] && { modprobe -q ext4 ; mkdir -p /media/o_p_t_img ; mount -t ext4 -o noatime,sync "$(losetup -a | grep o_p_t.img | awk -F ':' '{print $1}')" "/media/o_p_t_img" ; }
! mountpoint -q /opt && mountpoint -q /media/o_p_t_img && mount -o bind "/media/o_p_t_img" /opt
! mountpoint -q /opt && { logger -t "【opt】" "错误！！！未能挂载镜像(ext4)文件到 /opt" ; rm -f $upanPath/opt/o_p_t.img; }
}

re_size () {

#/tmp最大空间，调整已挂载分区的大小
[ ! -f /tmp/size_tmp ] && echo -n $(df -m | grep "% /tmp" | awk 'NR==1' | awk -F' ' '{print $4}')"M" > /tmp/size_tmp
[ "$size_tmpfs" = "0" ] && mount -o remount,size=$(cat /tmp/size_tmp) tmpfs /tmp
[ "$size_tmpfs" = "1" ] && mount -o remount,size=50% tmpfs /tmp
[ "$size_tmpfs" = "2" ] && mount -o remount,size=60% tmpfs /tmp
[ "$size_tmpfs" = "3" ] && mount -o remount,size=70% tmpfs /tmp
[ "$size_tmpfs" = "4" ] && mount -o remount,size=80% tmpfs /tmp
[ "$size_tmpfs" = "5" ] && mount -o remount,size=90% tmpfs /tmp
[ "$size_media_enable" = "0" ] && mount -o remount,size=8K tmpfs /media
[ "$size_media_enable" = "1" ] && mount -o remount,size=10485760M tmpfs /media

}

re_ca_tmp () {
re_size
if [ ! -s "/etc/ssl/certs/ca-certificates.crt" ] ; then
# 安装ca-certificates
	mkdir -p /tmp/ssl/ipk/
	mkdir -p /tmp/ssl/certs
	rm -f /etc/ssl/certs
	ln -sf /tmp/ssl/certs  /etc/ssl/certs
	if [ ! -s "/etc/ssl/certs/ca-certificates.crt" ] && [ -s /etc_ro/certs.tgz ] ; then
		tar -xzvf /etc_ro/certs.tgz -C /tmp/ssl/ ; cd /opt
	fi
	if [ ! -s "/etc/ssl/certs/ca-certificates.crt" ] ; then
		logger -t "【opt】" "已挂载,找不到ca-certificates证书"
		logger -t "【opt】" "下载证书"
		wgetcurl.sh /tmp/ssl/ipk/certs.tgz "$hiboyfile/certs.tgz" "$hiboyfile2/certs.tgz"
		[ -s /tmp/ssl/ipk/certs.tgz ] && tar -xzvf /tmp/ssl/ipk/certs.tgz -C /tmp/ssl/ ; cd /opt
		if [ ! -s "/etc/ssl/certs/ca-certificates.crt" ] ; then
			wgetcurl.sh /tmp/ssl/ipk/certs.tgz "http://opt.cn2qq.com/opt-file/certs.tgz"
			[ -s /tmp/ssl/ipk/certs.tgz ] && tar -xzvf /tmp/ssl/ipk/certs.tgz -C /tmp/ssl/ ; cd /opt
		fi
		if [ ! -s "/etc/ssl/certs/ca-certificates.crt" ] ; then
			wgetcurl.sh /tmp/ssl/ipk/certs.tgz "$(echo -n "$hiboyfile/certs.tgz" | sed -e "s/https:/http:/g")" "$(echo -n "$hiboyfile2/certs.tgz" | sed -e "s/https:/http:/g")"
		fi
		logger -t "【opt】" "安装证书"
		tar -xzvf /tmp/ssl/ipk/certs.tgz -C /tmp/ssl/ ; cd /opt
	fi
	rm -f /tmp/ssl/ipk/certs.tgz
	chmod 644 /etc/ssl/certs -R
	chmod 777 /etc/ssl/certs
	chmod 644 /tmp/ssl/certs -R
	chmod 777 /tmp/ssl/certs
fi
}

AiDisk00 () {
re_size
if [ ! -s "/etc/ssl/certs/ca-certificates.crt" ] ; then
# 安装ca-certificates
mountpoint -q /opt && mountp=0 || mountp=1 # 0已挂载 1没挂载
if [ "$mountp" = "0" ] && [ ! -s "/etc/ssl/certs/ca-certificates.crt" ] ; then
	mkdir -p /opt/app/ipk/
	mkdir -p /opt/etc/ssl/certs
	rm -f /etc/ssl/certs
	ln -sf /opt/etc/ssl/certs  /etc/ssl/certs
	if [ ! -s "/etc/ssl/certs/ca-certificates.crt" ] && [ -s /etc_ro/certs.tgz ] ; then
		tar -xzvf /etc_ro/certs.tgz -C /opt/etc/ssl/ ; cd /opt
	fi
	if [ ! -s "/etc/ssl/certs/ca-certificates.crt" ] ; then
		logger -t "【opt】" "已挂载,找不到ca-certificates证书"
		logger -t "【opt】" "下载证书"
		wgetcurl.sh /opt/app/ipk/certs.tgz "$hiboyfile/certs.tgz" "$hiboyfile2/certs.tgz"
		[ -s /opt/app/ipk/certs.tgz ] && tar -xzvf /opt/app/ipk/certs.tgz -C /opt/etc/ssl/ ; cd /opt
		if [ ! -s "/etc/ssl/certs/ca-certificates.crt" ] ; then
			wgetcurl.sh /opt/app/ipk/certs.tgz "http://opt.cn2qq.com/opt-file/certs.tgz"
			[ -s /opt/app/ipk/certs.tgz ] && tar -xzvf /opt/app/ipk/certs.tgz -C /opt/etc/ssl/ ; cd /opt
		fi
		if [ ! -s "/etc/ssl/certs/ca-certificates.crt" ] ; then
			wgetcurl.sh /opt/app/ipk/certs.tgz "$(echo -n "$hiboyfile/certs.tgz" | sed -e "s/https:/http:/g")" "$(echo -n "$hiboyfile2/certs.tgz" | sed -e "s/https:/http:/g")"
		fi
		logger -t "【opt】" "安装证书"
		tar -xzvf /opt/app/ipk/certs.tgz -C /opt/etc/ssl/ ; cd /opt
		rm -f /opt/app/ipk/certs.tgz
	fi
	chmod 644 /etc/ssl/certs -R
	chmod 777 /etc/ssl/certs
	chmod 644 /opt/etc/ssl/certs -R
	chmod 777 /opt/etc/ssl/certs
fi
fi
# flush buffers
sync
# 目录检测
[ -d /tmp/AiDisk_00/opt ] && return
ss_opt_x=`nvram get ss_opt_x`
upanPath=""
[ "$ss_opt_x" = "3" ] && upanPath="`df -m | grep /dev/mmcb | grep -E "$(echo $(/usr/bin/find /dev/ -name 'mmcb*') | sed -e 's@/dev/ /dev/@/dev/@g' | sed -e 's@ @|@g')" | grep "/media" | awk '{print $NF}' | sort -u | awk 'NR==1' `"
[ "$ss_opt_x" = "4" ] && upanPath="`df -m | grep /dev/sd | grep -E "$(echo $(/usr/bin/find /dev/ -name 'sd*') | sed -e 's@/dev/ /dev/@/dev/@g' | sed -e 's@ @|@g')" | grep "/media" | awk '{print $NF}' | sort -u | awk 'NR==1' `"
[ -z "$upanPath" ] && [ "$ss_opt_x" = "1" ] && upanPath="`df -m | grep /dev/mmcb | grep -E "$(echo $(/usr/bin/find /dev/ -name 'mmcb*') | sed -e 's@/dev/ /dev/@/dev/@g' | sed -e 's@ @|@g')" | grep "/media" | awk '{print $NF}' | sort -u | awk 'NR==1' `"
[ -z "$upanPath" ] && [ "$ss_opt_x" = "1" ] && upanPath="`df -m | grep /dev/sd | grep -E "$(echo $(/usr/bin/find /dev/ -name 'sd*') | sed -e 's@/dev/ /dev/@/dev/@g' | sed -e 's@ @|@g')" | grep "/media" | awk '{print $NF}' | sort -u | awk 'NR==1' `"
if [ "$ss_opt_x" = "6" ] ; then
	# 远程共享
	if mountpoint -q "$opt_cifs_2_dir" && [ -d "$opt_cifs_2_dir" ] ; then
		upanPath="$opt_cifs_2_dir"
	else
		logger -t "【opt】" "错误！未找到指定远程共享目录 $opt_cifs_2_dir"
	fi
fi
if [ "$ss_opt_x" = "5" ] ; then
	# 指定目录
	if [ -d $opt_cifs_dir ] ; then
		upanPath="$opt_cifs_dir"
	else
		logger -t "【opt】" "错误！未找到指定目录 $opt_cifs_dir"
	fi
fi
mkdir -p /opt/bin
if [ ! -f /sbin/check_disk_size ] && [ ! -f /opt/bin/check_disk_size ] ; then
	wgetcurl.sh '/opt/bin/check_disk_size' "$hiboyfile/check_disk_size" "$hiboyfile2/check_disk_size"
fi
[ -f /sbin/check_disk_size ] && [ -f /opt/bin/check_disk_size ] && rm -f /opt/bin/check_disk_size
if [ ! -z "$upanPath" ] ; then
	rm -f /tmp/AiDisk_00
	[ -d /tmp/AiDisk_00 ] || rm -rf /tmp/AiDisk_00
	ln -sf "$upanPath" /tmp/AiDisk_00
	sync
	# 部署离线 opt 环境下载地址
	opt_download
	/tmp/re_upan_storage.sh &
else
	mkdir -p /tmp/AiDisk_00/opt
fi
if [ ! -z "$(/usr/bin/find /opt/lib/ld.so.1 -type f)" ] ; then
	cp -f /etc/shadow /opt/etc/shadow
	cp -f /etc/passwd /opt/etc/passwd
	cp -f /etc/group /opt/etc/group
	cp -f /etc/shells /opt/etc/shells
	cp -f /etc/TZ /opt/etc/TZ
	rm -f /opt/bin/grep  /opt/opt_backup/bin/grep
	rm -f /opt/bin/sed  /opt/opt_backup/bin/sed
	rm -f /opt/bin/ash  /opt/opt_backup/bin/ash
	rm -f /opt/bin/sh  /opt/opt_backup/bin/sh
	rm -f /opt/bin/netstat  /opt/opt_backup/bin/netstat
	rm -f /opt/sbin/ifconfig  /opt/opt_backup/sbin/ifconfig
	rm -f /opt/sbin/route  /opt/opt_backup/bin/sbin/route
fi
# flush buffers
sync
[ ! -s /tmp/script/_opt_script_check ] && /etc/storage/script/sh_opt_script_check.sh &
[ -s /etc/storage/script/Sh99_ss_tproxy.sh ] && /etc/storage/script/Sh99_ss_tproxy.sh initconfig
}

opt_Available () {

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
logger -t "【opt】" "/opt 剩余可用数据空间[M] $Available_A/$Available_B"
logger -t "【opt】" "/opt 剩余可用节点空间[Inodes] $Available_C/$Available_D"
logger -t "【opt】" "/opt 已用数据空间[M] $Available_M/100%"
logger -t "【opt】" "/opt 已用节点空间[Inodes] $Available_I/100%"
logger -t "【opt】" "以上两个数据如出现占用100%时，则 opt 数据空间 或 Inodes节点 爆满，会影响 opt.tgz 解压运行，请重新正确格式化 U盘。"
}

opt_file () {
opt_mini=$1
logger -t "【opt】" "opt $opt_mini 下载/opt/opt.tgz"
if [ ! -f /opt/opt.tgz ] ; then
	rm -f /opt/opt.tgz*
	logger -t "【opt】" "/opt 可用空间：$(df -m | grep '% /opt' | awk 'NR==1' | awk -F' ' '{print $4}')M"
	optPath="`grep ' /opt ' /proc/mounts | grep tmpfs`"
	if [ ! -z "$optPath" ] || [ "$opt_mini" = "mini" ] ; then
	opt_mini="mini"
	echo "opt_mini"
	fi
	[ "$opt_mini" = "mini" ] && { logger -t "【opt】" "下载: $opttmpfile" ; wgetcurl.sh '/opt/opt.tgz' "$opttmpfile" "$opttmpfile2"; }
	if [ ! -z "$(grep ' /opt ' /proc/mounts | grep /dev)" ] || [ ! -z "$(grep ' /opt ' /proc/mounts | grep " cifs ")" ] ; then
	if [ "$opt_mini" = "full" ] ; then
		echo "opt_full"
		for optupanfileN in $(seq 0 $optupanfileS) ; do
		optupanfileN="00""$optupanfileN"
		optupanfileN_l="$(echo -n $optupanfileN | wc -c)"
		optupanfileN_a="$(( optupanfileN_l - 1 ))"
		optupanfileN="$(echo -n "$optupanfileN" | cut -b "$optupanfileN_a-$optupanfileN_l")"
		logger -t "【opt】" "下载: $optupanfile.$optupanfileN"
		wgetcurl.sh "/opt/opt.tgz.$optupanfileN" "$optupanfile.$optupanfileN" "$optupanfile2.$optupanfileN"
		done
		logger -t "【opt】" "合并文件: /opt/opt.tgz"
		cat /opt/opt.tgz.* > /opt/opt.tgz
		if [ "$optupanfile_md5" != "$(md5sum /opt/opt.tgz | awk '{print $1;}')" ] ; then
			logger -t "【opt】" "/opt/opt.tgz md5不匹配！"
			rm -f /opt/opt.tgz*
		else
			rm -f /opt/opt.tgz.*
		fi
	fi
	fi
	[ -f /opt/opt.tgz ] && logger -t "【opt】" "/opt/opt.tgz 下载完成，开始解压" || logger -t "【opt】" "/opt/opt.tgz 下载失败！"
else
	logger -t "【opt】" "/opt/opt.tgz 已经存在，开始解压，需 5-15 分钟时间，解压时可能会出现程序不能运行的情况"
fi
if [ -f /opt/opt.tgz ] ; then
tar -xzvf /opt/opt.tgz -C /opt ; cd /opt
optPath="`grep ' /opt ' /proc/mounts | grep tmpfs`"
[ ! -z "$optPath" ] && rm -f /opt/opt.tgz
fi
# flush buffers
sync

}

opt_wget () {
opt_mini=$1
#opt检查更新
upopt
if [ -s /tmp/opti.txt ] && [ "$(cat /tmp/opti.txt)"x != "$(cat /opt/opti.txt)"x ] && [ "$upopt_enable" = "1" ] && [ -f /tmp/opti.txt ] ; then
	logger -t "【opt】" "opt 需要更新, 自动启动更新"
	#rm -rf /opt/opt_backup/*
	rm -rf /opt/opti.txt /opt/opt_backup/opti.txt
	rm -rf /opt/lnmp.txt
	rm -rf /opt/opt.tgz
fi
optw_enable=`nvram get optw_enable`
if [ "$optw_enable" != "2" ] ; then
	nvram set optw_enable=2
	nvram commit
fi
if [ ! -f "/opt/opti.txt" ] ; then
	logger -t "【opt】" "自动安装 opt $opt_mini （覆盖 opt 文件夹）"
	opt_file "$opt_mini"
	opt_Available
	if [ -s "/opt/opti.txt" ] ; then
		logger -t "【opt】" "/opt 解压完成"
		#chmod 777 /opt -R
		prepare_authorized_keys
	else
		logger -t "【opt】" "/opt 解压失败"
	fi
	optPath="`grep ' /opt ' /proc/mounts | grep tmpfs`"
	if [ -z "$optPath" ] && [ -s "/opt/opt.tgz" ] ; then
		logger -t "【opt】" "备份文件到 /opt/opt_backup"
		mkdir -p /opt/opt_backup/bin /opt/opt_backup/sbin /opt/opt_backup/lib /opt/opt_backup/etc
		cp -r -f -a /opt/bin/* /opt/opt_backup/bin
		cp -r -f -a /opt/sbin/* /opt/opt_backup/sbin
		cp -r -f -a /opt/lib/* /opt/opt_backup/lib
		cp -r -f -a /opt/etc/* /opt/opt_backup/etc
		cp -f /opt/opti.txt /opt/opt_backup/opti.txt
		#libmd5_backup
		opt_Available
	fi
	ln_check
fi
}

upopt () {
if [ "$upopt_enable" = "1" ] ; then
wgetcurl.sh "/tmp/opti.txt" "$opt_txt_file1" "$opt_txt_file2"
if [ ! -s /tmp/opti.txt ] ; then
	re_ca_tmp
	wgetcurl.sh "/tmp/opti.txt" "$opt_txt_file1" "$opt_txt_file2"
fi
if [ ! -s /tmp/opti.txt ] ; then
	opt_cdn_force
	wgetcurl.sh "/tmp/opti.txt" "$opt_txt_file1" "$opt_txt_file2"
fi
[[ "$(cat /tmp/opti.txt | wc -c)" -gt 11 ]] && echo "" > /tmp/opti.txt
[ ! -z "$(cat /tmp/opti.txt | grep '<' | grep '>')" ] && echo "" > /tmp/opti.txt
nvram set optt="`cat /tmp/opti.txt`"
else
rm -rf /tmp/opti.txt
fi
[[ "$(cat /opt/opti.txt | wc -c)" -gt 11 ]] && echo "" > /opt/opti.txt
[ ! -z "$(cat /opt/opti.txt | grep '<' | grep '>')" ] && echo "" > /opt/opti.txt
sed -Ei "s@[^0-9\\-]@@g" /opt/opti.txt
nvram set opto="`cat /opt/opti.txt`"
}

libmd5_mk () {
/usr/bin/find /opt/opt_backup/lib/ -type f -name '*' ! -type l | grep -v "/lib/opkg" | sort -r  > /tmp/md5/libmd5f_opt_backup
/usr/bin/find /opt/opt_backup/bin/ -type f -name '*' ! -type l | sort -r  >> /tmp/md5/libmd5f_opt_backup
/usr/bin/find /opt/opt_backup/sbin/ -type f -name '*' ! -type l | sort -r  >> /tmp/md5/libmd5f_opt_backup
/usr/bin/find /opt/opt_backup/etc/ -type f -name '*' ! -type l | sort -r  > /tmp/md5/libmd5f_etc_backup
/usr/bin/find /opt/lib/ -type f -name '*' ! -type l | grep -v "/lib/opkg" | sort -r  > /tmp/md5/libmd5f_opt
/usr/bin/find /opt/bin/ -type f -name '*' ! -type l | sort -r  >> /tmp/md5/libmd5f_opt
/usr/bin/find /opt/sbin/ -type f -name '*' ! -type l | sort -r  >> /tmp/md5/libmd5f_opt
/usr/bin/find /opt/etc/ -type f -name '*' ! -type l | sort -r  > /tmp/md5/libmd5f_etc
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
	tar -xzvf /opt/opt.tgz -C /opt/opt_backup ; cd /opt
	if [ -s "/opt/opti.txt" ] ; then
		logger -t "【libmd5_恢复】" "/opt/opt_backup 文件解压完成"
	fi
fi
logger -t "【libmd5_恢复】" "正在对比 /opt/lib|bin|sbin 文件 md5"
mkdir -p /tmp/md5/
libmd5_mk
while read line
do
if [ -f "$line" ] ; then
	b_line="$(echo $line | sed  "s@^/opt/opt_backup/@/opt/@g")"
	if [ -f "$b_line" ] ; then
	MD5_backup="$(md5sum $line | awk '{print $1;}')"
	MD5_OPT="$(md5sum $b_line | awk '{print $1;}')"
	else
	MD5_backup="1" ; MD5_OPT="2" ;
	fi
	if [ "$MD5_backup"x != "$MD5_OPT"x ] ; then
	logger -t "【libmd5_恢复】" "【 $b_line 】，md5不匹配！"
	logger -t "【libmd5_恢复】" "恢复文件【 $line 】"
	mkdir -p "$(dirname "$b_line")"
	cp -Hrf "$line" "$b_line"
	lib_status=1
	fi
fi
done < /tmp/md5/libmd5f_opt_backup
logger -t "【libmd5_恢复】" "/opt/lib|bin|sbin ，md5 对比完成！"
# flush buffers
sync;echo 3 > /proc/sys/vm/drop_caches
func_stop_apps
func_start_apps

}

# opkg update ; opkg upgrade ;

libmd5_backup () {
optPath="`grep ' /opt ' /proc/mounts | grep tmpfs`"
if [ ! -z "$optPath" ] ; then
	logger -t "【libmd5_备份】" " /opt/lib/ 在内存储存，跳过备份"
	return 0
fi
mkdir -p /opt/opt_backup
logger -t "【libmd5_备份】" "正在对比 /opt/lib|bin|sbin 文件 md5"
mkdir -p /tmp/md5/
libmd5_mk
while read line
do
if [ -f "$line" ] ; then
	b_line="$(echo $line | sed  "s@^/opt/@/opt/opt_backup/@g")"
	if [ -f "$b_line" ] ; then
	MD5_backup="$(md5sum $line | awk '{print $1;}')"
	MD5_OPT="$(md5sum $b_line | awk '{print $1;}')"
	else
	MD5_backup="1" ; MD5_OPT="2" ;
	fi
	if [ "$MD5_backup"x != "$MD5_OPT"x ] ; then
	logger -t "【libmd5_备份】" "【 $b_line 】，md5不匹配！"
	logger -t "【libmd5_备份】" "备份文件【 $line 】"
	mkdir -p "$(dirname "$b_line")"
	cp -Hrf "$line" "$b_line"
	lib_status=1
	fi
fi
done < /tmp/md5/libmd5f_opt
while read line
do
if [ -f "$line" ] ; then
	b_line="$(echo $line | sed  "s@^/opt/opt_backup/@/opt/@g")"
	if [ ! -f "$b_line" ] ; then
	logger -t "【libmd5_备份】" "删除多余的备份文件【 $line 】"
	rm -f $line
	fi
fi
done < /tmp/md5/libmd5f_opt_backup
logger -t "【libmd5_备份】" "/opt/lib|bin|sbin ，md5 对比完成！"
logger -t "【libmd5_备份】" "/opt/lib|bin|sbin ，重启后自动恢复"
logger -t "【libmd5_备份】" "正在对比 /opt/etc/ 文件 md5"
while read line
do
if [ -f "$line" ] ; then
	b_line="$(echo $line | sed  "s@^/opt/@/opt/opt_backup/@g")"
	if [ -f "$b_line" ] ; then
	MD5_backup="$(md5sum $line | awk '{print $1;}')"
	MD5_OPT="$(md5sum $b_line | awk '{print $1;}')"
	else
	MD5_backup="1" ; MD5_OPT="2" ;
	fi
	if [ "$MD5_backup"x != "$MD5_OPT"x ] ; then
	logger -t "【libmd5_备份】" "【 $b_line 】，md5不匹配！"
	logger -t "【libmd5_备份】" "备份文件【 $line 】"
	mkdir -p "$(dirname "$b_line")"
	cp -Hrf "$line" "$b_line"
	lib_status=1
	fi
fi
done < /tmp/md5/libmd5f_etc
while read line
do
if [ -f "$line" ] ; then
	b_line="$(echo $line | sed  "s@^/opt/opt_backup/@/opt/@g")"
	if [ ! -f "$b_line" ] ; then
	logger -t "【libmd5_备份】" "删除多余的备份文件【 $line 】"
	rm -f $line
	fi
fi
done < /tmp/md5/libmd5f_etc_backup
logger -t "【libmd5_备份】" "/opt/etc ，md5 对比完成！"
logger -t "【libmd5_备份】" "/opt/etc ，重启后不会恢复"
ln_mk
cp -f /opt/ln.txt /opt/opt_backup/ln.txt
cp -f /opt/opti.txt /opt/opt_backup/opti.txt
rm -f /tmp/md5/libmd5f_opt /tmp/md5/libmd5f_opt_backup /tmp/md5/libmd5f_etc /tmp/md5/libmd5f_etc_backup
# flush buffers
sync;echo 3 > /proc/sys/vm/drop_caches

}

re_upan_storage () {
/tmp/re_upan_storage.sh &
}

initconfig () {

cat > "/tmp/re_upan_storage.sh" <<-\EEE
#!/bin/sh

func_stop_apps()
{
	stop_rstats
}

func_start_apps()
{
	start_rstats
}

if [ ! -f /tmp/upan_storage_enable.lock ] ; then
touch /tmp/upan_storage_enable.lock
upan_storage_enable=`nvram get upan_storage_enable`
if [ "$upan_storage_enable" = "1" ] && [ "$1" != "0" ] ; then
	if [ ! -s /etc/storage/start_script.sh ] ; then
		func_stop_apps
		sync
		umount /etc/storage
		sleep 1
		umount -l /etc/storage
		sleep 1
		{ fuser -m -k /etc/storage 2>/dev/null ; umount -l /etc/storage ; }
		sleep 1
		mtd_storage.sh fill
		sw_mode=`nvram get sw_mode`
		[ "$sw_mode" != "3" ] && restart_firewall
		[ "$sw_mode" == "3" ] && /etc/storage/crontabs_script.sh &
		func_start_apps
		rm -f /tmp/upan_storage_enable.lock
		exit
	fi
	if ! mountpoint -q /etc/storage ; then
		if [ ! -f /opt/storage/start_script.sh ] && [ -f /etc/storage/start_script.sh ] ; then
			mkdir -p -m 755 /opt/storage
			cp -af /etc/storage/* /opt/storage
		else
			#[ -f /opt/storage/start_script.sh ] && cp -af /opt/storage/* /etc/storage
			[ -d /opt/storage/https ] && { mkdir -p -m 700 /opt/storage/https ; cp -af /opt/storage/https/* /etc/storage/https ; }
			[ -d /opt/storage/openvpn ] && { mkdir -p /opt/storage/openvpn ; cp -af /opt/storage/openvpn/* /etc/storage/openvpn ; }
			[ -d /opt/storage/inadyn ] && { mkdir -p /opt/storage/inadyn ; cp -af /opt/storage/inadyn/* /etc/storage/inadyn ; }
			[ -d /opt/storage/dnsmasq ] && { mkdir -p /opt/storage/dnsmasq ; cp -af /opt/storage/dnsmasq/* /etc/storage/dnsmasq ; }
		fi
		logger -t "【外部存储storage】" "/etc/storage -> /opt/storage"
		func_stop_apps
		mount --bind /opt/storage /etc/storage
		sync
		mtd_storage.sh fill
		func_start_apps
	else
		func_stop_apps
		func_start_apps
	fi
else
	func_stop_apps
	sync
	mountpoint -q /etc/storage && logger -t "【外部存储storage】" "停止外部存储storage！ umount /etc/storage"
	mountpoint -q /etc/storage && umount /etc/storage
	sleep 1
	mountpoint -q /etc/storage && umount -l /etc/storage
	sleep 1
	mountpoint -q /etc/storage && { fuser -m -k /etc/storage 2>/dev/null ; umount -l /etc/storage ; }
	sleep 1
	mtd_storage.sh fill
	func_start_apps
fi
rm -f /tmp/upan_storage_enable.lock
fi

EEE
chmod 777 "/tmp/re_upan_storage.sh"

cifs_script="/etc/storage/cifs_script.sh"
if [ ! -f "$cifs_script" ] || [ ! -s "$cifs_script" ] ; then
	cat > "$cifs_script" <<-\EEE
#!/bin/bash
# SMB资源挂载(局域网共享映射，无USB也能挂载储存空间)
# 说明：【192.168.123.66】为共享服务器的IP，【nas】为共享文件夹名称
# 说明：username=、password=填账号密码
modprobe -q ext4
modprobe des_generic
modprobe cifs CIFSMaxBufSize=64512
mkdir -p /media/cifs
umount /media/cifs ; umount -l /media/cifs
mount -t cifs //192.168.123.66/nas /media/cifs -o username=user,password=pass,dynperm,nounix,noserverino,file_mode=0777,dir_mode=0777

EEE
	chmod 755 "$cifs_script"
fi

}

initconfig

mount_check () {
kill_ps "$scriptname"
kill_ps "Sh01_mountopt.sh"
kill_ps "_mountopt"
 #(
 #	flock 101
mount_check_lock
 #) 101>/var/lock/101_flock.lock

}

case $ACTION in
stop)
	echo "stop"
	kill_ps "/tmp/script/_mountopt"
	kill_ps "_mountopt.sh"
	kill_ps "$scriptname"
	;;
start)
	mount_check
	[ "$optinstall" = "1" ] && opt_wget "mini"
	[ "$optinstall" = "2" ] && opt_wget "full"
	;;
check)
	mount_check
	[ "$optinstall" = "1" ] && opt_wget "mini"
	[ "$optinstall" = "2" ] && opt_wget "full"
	;;
optwget)
	mount_check
	[ "$optinstall" != "2" ] && opt_wget "mini"
	[ "$optinstall" = "2" ] && opt_wget "full"
	;;
opt_mini_wget)
	mount_check
	opt_wget "mini"
	;;
opt_full_wget)
	mount_check
	opt_wget "full"
	;;
upopt)
	mount_check
	if [ "$upopt_enable" = "1" ] ; then
		[ "$optinstall" = "1" ] && opt_wget "mini"
		[ "$optinstall" = "2" ] && opt_wget "full"
	else
		upopt
	fi
	;;
reopt)
	mount_check
	rm -rf /opt/opti.txt /opt/opt_backup/opti.txt
	rm -rf /opt/lnmp.txt
	[ "$optinstall" != "2" ] && opt_wget "mini"
	[ "$optinstall" = "2" ] && opt_wget "full"
	[ -f /opt/lcd.tgz ] && untar.sh "/opt/lcd.tgz" "/opt/" "/opt/bin/lcd4linux"
	;;
libmd5_check)
	libmd5_check
	;;
libmd5_backup)
	libmd5_backup &
	;;
opt_download)
	opt_download_enable=1
	opt_update_download &
	;;
opt_download_script)
	[ -d /tmp/AiDisk_00/cn2qq/opt-script ] && rm -rf /tmp/AiDisk_00/cn2qq/opt-script
	[ -d /tmp/AiDisk_00/cn2qq/opt-script-master ] && rm -rf /tmp/AiDisk_00/cn2qq/opt-script-master
	[ -f /tmp/AiDisk_00/cn2qq/opt-script.tgz ] && rm -f /tmp/AiDisk_00/cn2qq/opt-script.tgz
	opt_download_enable=1
	opt_download &
	;;
opt_download_file)
	[ -d /tmp/AiDisk_00/cn2qq/opt-file ] && rm -rf /tmp/AiDisk_00/cn2qq/opt-file
	[ -d /tmp/AiDisk_00/cn2qq/opt-file-master ] && rm -rf /tmp/AiDisk_00/cn2qq/opt-file-master
	[ -f /tmp/AiDisk_00/cn2qq/opt-file.tgz ] && rm -f /tmp/AiDisk_00/cn2qq/opt-file.tgz
	opt_download_enable=1
	opt_download &
	;;
re_upan_storage)
	func_stop_apps
	mount_check
	rm -rf /opt/storage/*
	mtd_storage.sh resetsh
	func_start_apps
	;;
opt_force)
	opt_force
	;;
opt_cdn_force)
	opt_cdn_force
	;;
re_ca_tmp)
	re_ca_tmp
	;;
*)
	mount_check
	if [ "$upopt_enable" = "1" ] ; then
		[ "$optinstall" = "1" ] && opt_wget "mini"
		[ "$optinstall" = "2" ] && opt_wget "full"
	fi
	;;
esac


