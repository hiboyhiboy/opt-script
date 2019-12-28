#!/bin/sh
#copyright by hiboy
source /etc/storage/script/init.sh
#nvramshow=`nvram showall | grep '=' | grep opt | awk '{print gensub(/'"'"'/,"'"'"'\"'"'"'\"'"'"'","g",$0);}'| awk '{print gensub(/=/,"='\''",1,$0)"'\'';";}'` && eval $nvramshow
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

if [ ! -z "$(echo $scriptfilepath | grep -v "/tmp/script/" | grep mountopt)" ]  && [ ! -s /tmp/script/_mountopt ]; then
	mkdir -p /tmp/script
	{ echo '#!/bin/sh' ; echo $scriptfilepath '"$@"' ; } > /tmp/script/_mountopt
	chmod 777 /tmp/script/_mountopt
fi

# 自定义 opt 环境下载地址
opt_force_enable=`nvram get opt_force_enable`
[ -z $opt_force_enable ] && opt_force_enable="0" && nvram set opt_force_enable="$opt_force_enable"
opt_force_www=`nvram get opt_force_www`
[ -z $opt_force_www ] && opt_force_www="https://opt.cn2qq.com" && nvram set opt_force_www="$opt_force_www"
if [ "$opt_force_enable" != "0" ] ; then
	opt_force_www="$(echo $opt_force_www | sed  "s@/\$@@g")"
	sed -Ei '/^hiboyfile=/d' /etc/storage/script/init.sh
	sed -Ei '/^hiboyscript=/d' /etc/storage/script/init.sh
	echo 'hiboyfile="'$opt_force_www'/opt-file"' >> /etc/storage/script/init.sh
	echo 'hiboyscript="'$opt_force_www'/opt-script"' >> /etc/storage/script/init.sh
	hiboyfile="$opt_force_www/opt-file"
	hiboyscript="$opt_force_www/opt-script"
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
http_proto=`nvram get http_proto`
http_lanport=`nvram get http_lanport`
[ -z $http_lanport ] && http_lanport=80 && nvram set http_lanport=80
lan_ipaddr=`nvram get lan_ipaddr`
[ "$http_proto" != "1" ] && opt_force_www_tmp="http://127.0.0.1:$http_lanport"
[ "$http_proto" == "1" ] && opt_force_www_tmp="https://127.0.0.1:$http_lanport"
if [ "$opt_download_enable" != "0" ] ; then
	nvram set opt_force_enable=1
	# 设置下载地址
	nvram set opt_force_www="$opt_force_www_tmp"
	opt_force_www="$opt_force_www_tmp"
	sed -Ei '/^hiboyfile=/d' /etc/storage/script/init.sh
	sed -Ei '/^hiboyscript=/d' /etc/storage/script/init.sh
	echo 'hiboyfile="'$opt_force_www'/opt-file"' >> /etc/storage/script/init.sh
	echo 'hiboyscript="'$opt_force_www'/opt-script"' >> /etc/storage/script/init.sh
	hiboyfile="$opt_force_www/opt-file"
	hiboyscript="$opt_force_www/opt-script"
else
	if [ "$opt_force_www" == "$opt_force_www_tmp" ] ; then
		nvram set opt_force_www="https://opt.cn2qq.com"
		opt_force_www="https://opt.cn2qq.com"
		sed -Ei '/^hiboyfile=/d' /etc/storage/script/init.sh
		sed -Ei '/^hiboyscript=/d' /etc/storage/script/init.sh
		echo 'hiboyfile="'$opt_force_www'/opt-file"' >> /etc/storage/script/init.sh
		echo 'hiboyscript="'$opt_force_www'/opt-script"' >> /etc/storage/script/init.sh
		hiboyfile="$opt_force_www/opt-file"
		hiboyscript="$opt_force_www/opt-script"
	fi
fi

# /etc/storage/script/sh01_mountopt.sh
 opttmpfile="$hiboyfile/opttmpg8.tgz"
 opttmpfile2="$hiboyfile2/opttmpg8.tgz"
 optupanfile="$hiboyfile/optupang8.tgz"
 optupanfile3="$hiboyfile2/optupang8.tgz"
 optupanfile2="$hiboyfile/optg8.txt"
 optupanfile4="$hiboyfile2/optg8.txt"

# ss_opt_x 
# 1 >>自动选择:SD→U盘→内存
# 2 >>安装到内存:需要空余内存(10M+)
# 3 >>安装到 SD
# 4 >>安装到 U盘
# 5 >>安装到 指定目录
# 6 >>安装到 远程共享
# 不是ext4磁盘时用镜像生成opt
#set -x

mount_check_lock () {

# 检查挂载异常设备
dev_full=$(cat  /proc/mounts | awk '{print $1}' | grep -v -E "$(echo $(/usr/bin/find /dev/ -name '*') | sed -e 's@/dev/ /dev/@/dev/@g' | sed -e 's@ @|@g')" | grep "/dev/")
[ ! -z "$dev_full" ] && dev_mount=$(cat  /proc/mounts | grep $dev_full | grep /media/ | awk '{print $2}')
if [ ! -z "$dev_mount" ] && [ ! -z "$dev_full" ] ; then
if mountpoint -q "$dev_mount" ; then
	logger -t "【opt】" "发现挂载异常设备，尝试移除： $dev_full   $dev_mount"
	/tmp/re_upan_storage.sh 0
	mountres2=`losetup -a | grep $dev_mount | grep o_p_t.img | awk -F ':' '{print $1}'`
	[ ! -z "$mountres2" ] && /usr/bin/opt-umount.sh $dev_full   $dev_mount
	mountres2=`losetup -a | grep $dev_mount | grep o_p_t.img | awk -F ':' '{print $1}'`
	if [ ! -z "$mountres2" ] ; then
		/usr/bin/opt-umount.sh $dev_full   $dev_mount
		for varloop0 in $(echo $(grep "$(losetup -a | grep $dev_mount | grep o_p_t.img | awk -F ':' '{print $1}')" /proc/mounts | grep -v /media/o_p_t_img | awk -F' ' '{print $2}'))
		do
			umount -l "$varloop0"
		done
		mountpoint -q /media/o_p_t_img && { fuser -m -k /media/o_p_t_img 2>/dev/null ; umount /media/o_p_t_img ; }
		mountpoint -q /media/o_p_t_img && umount -l /media/o_p_t_img
		losetup -d `losetup -a | grep $dev_mount | grep o_p_t.img | awk -F ':' '{print $1}'`
	fi
	for varloop0 in $(echo $(grep "$dev_full" /proc/mounts | grep -v $dev_mount | awk -F' ' '{print $2}'))
	do
		umount -l "$varloop0"
	done
	mountpoint -q "$dev_mount" && umount -l $dev_mount
	mountpoint -q "$dev_mount" && fuser -m -k $dev_mount 2>/dev/null
	mountpoint -q "$dev_mount" && umount -l $dev_mount
	if mountpoint -q "$dev_mount" ; then
		logger -t "【opt】" "挂载异常设备，尝试移除失败"
	fi
fi
fi
ss_opt_x=`nvram get ss_opt_x`
mountp="mountp"
mountpoint -q /opt && mountp=0 || mountp=1 # 0已挂载 1没挂载
if [ "$mountp" = "0" ] ; then
	# 找不到opt所在设备
	optPath="`grep ' /opt ' /proc/mounts | grep tmpfs| awk '{print $1}'`"
	[ -z "$optPath" ] && optPath=$(grep ' /opt ' /proc/mounts | awk '{print $1}' | grep -E "$(echo $(/usr/bin/find /dev/ -name '*') | sed -e 's@/dev/ /dev/@/dev/@g' | sed -e 's@ @|@g')")
	if [ -z "$optPath" ] ; then
		logger -t "【opt】" "opt 选项[$ss_opt_x] 挂载异常，重新挂载：umount -l /opt"
		/usr/bin/opt-umount.sh $(grep ' /opt ' /proc/mounts | awk '{print $1}')    $(df -m | grep "$(df -m | grep '% /opt' | awk 'NR==1' | awk '{print $1}')" | grep "/media"| awk '{print $NF}' | awk 'NR==1' )
		mountpoint -q /opt && umount /opt
		mountpoint -q /opt && umount -l /opt
		mountpoint -q /opt && { fuser -m -k /opt 2>/dev/null ; umount -l /opt ; }
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
ln -sf /etc/TZ /opt/etc/TZ
ln -sf /etc/group /opt/etc/group
ln -sf /etc/passwd /opt/etc/passwd
# now try create symlinks - it is a std installation
if [ -f /etc/shells ]
then
	ln -sf /etc/shells /opt/etc/shells
else
	cp /opt/etc/shells.1 /opt/etc/shells
fi

if [ -f /etc/shadow ]
then
	ln -sf /etc/shadow /opt/etc/shadow
fi

if [ -f /etc/gshadow ]
then
	ln -sf /etc/gshadow /opt/etc/gshadow
fi

if [ -f /etc/localtime ]
then
	ln -sf /etc/localtime /opt/etc/localtime
fi	
ldconfig > /dev/null 2>&1
ldconfig -f /etc/ld.so.conf -C /etc/ld.so.cache > /dev/null 2>&1
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
[ "$ss_opt_x" = "3" ] && upanPath="`df -m | grep /dev/mmcb | grep -E "$(echo $(/usr/bin/find /dev/ -name 'mmcb*') | sed -e 's@/dev/ /dev/@/dev/@g' | sed -e 's@ @|@g')" | grep "/media" | awk '{print $NF}' | sort -u | awk 'NR==1' `"
[ "$ss_opt_x" = "4" ] && upanPath="`df -m | grep /dev/sd | grep -E "$(echo $(/usr/bin/find /dev/ -name 'sd*') | sed -e 's@/dev/ /dev/@/dev/@g' | sed -e 's@ @|@g')" | grep "/media" | awk '{print $NF}' | sort -u | awk 'NR==1' `"
[ -z "$upanPath" ] && [ "$ss_opt_x" = "1" ] && upanPath="`df -m | grep /dev/mmcb | grep -E "$(echo $(/usr/bin/find /dev/ -name 'mmcb*') | sed -e 's@/dev/ /dev/@/dev/@g' | sed -e 's@ @|@g')" | grep "/media" | awk '{print $NF}' | sort -u | awk 'NR==1' `"
[ -z "$upanPath" ] && [ "$ss_opt_x" = "1" ] && upanPath="`df -m | grep /dev/sd | grep -E "$(echo $(/usr/bin/find /dev/ -name 'sd*') | sed -e 's@/dev/ /dev/@/dev/@g' | sed -e 's@ @|@g')" | grep "/media" | awk '{print $NF}' | sort -u | awk 'NR==1' `"
if [ "$ss_opt_x" = "6" ] ; then
	# 远程共享
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
	# 检测ext4磁盘
	mkdir -p /tmp/AiDisk_opt
	mountpoint -q /tmp/AiDisk_opt && umount /tmp/AiDisk_opt
	mount -o bind "$upanPath" /tmp/AiDisk_opt
	[ "$(cat  /proc/mounts | grep " /tmp/AiDisk_opt " | awk '{print $3}')" = "ext4" ] && ext4_check=1 || ext4_check=0
	umount -l /tmp/AiDisk_opt
	rm -f /tmp/AiDisk_opt
	if [ "$(losetup -h 2>&1 | wc -l)" -gt 2 ] && [ "$ext4_check" = "0" ] ; then
		# 不是ext4磁盘时用镜像生成opt
		mkoptimg "$upanPath"
	else
		[ ! -d "$upanPath/opt" ] && mkdir -p "$upanPath/opt"
		logger -t "【opt】" "$upanPath/opt文件夹模式挂载/opt"
		mount -o bind "$upanPath/opt" /opt
	fi
	rm -f /tmp/AiDisk_00
	[ -d /tmp/AiDisk_00 ] || rm -rf /tmp/AiDisk_00
	ln -sf "$upanPath" /tmp/AiDisk_00
	sync
	# prepare ssh authorized_keys
	prepare_authorized_keys
	# 部署离线 opt 环境下载地址
	opt_download
	/tmp/re_upan_storage.sh &
else
	logger -t "【opt】" "/tmp/AiDisk_00/opt文件夹模式挂载/opt"
	rm -rf /tmp/AiDisk_00
	mkdir -p /tmp/AiDisk_00/opt
	mount -o bind /tmp/AiDisk_00/opt /opt
fi
mkdir -p /opt/bin

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
if [ ! -f /tmp/AiDisk_00/cn2qq/opt-script.tgz ]  ; then
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
if [ ! -f /tmp/AiDisk_00/cn2qq/opt-file.tgz ]  ; then
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
if [ ! -s "$upanPath/opt/o_p_t.img" ] ; then
	[ -d "$upanPath/opt" ] && mv -f "$upanPath/opt" "$upanPath/opt_old_"$(date "+%Y-%m-%d_%H-%M-%S")
	[ ! -d "$upanPath/opt" ] && mkdir -p "$upanPath/opt"
	block="$(check_network 5 $upanPath)"
	[ "$block" != "0" ] && logger -t "【opt】" "路径$upanPath剩余空间：$block M"
	[ "$block" = "0" ] && logger -t "【opt】" "路径$upanPath剩余空间：获取失败"
	[ "$block" != "0" ] && [ ! -z "$block" ] && [ "$block" -lt "$opt_cifs_block" ] && opt_cifs_block=$block
	logger -t "【opt】" "创建$upanPath/opt/o_p_t.img镜像(ext4)文件，$opt_cifs_block M"
	dd if=/dev/zero of=$upanPath/opt/o_p_t.img bs=1M seek=$opt_cifs_block count=0
	losetup `losetup -f` $upanPath/opt/o_p_t.img
	mkfs.ext4 -i 16384 `losetup -a | grep o_p_t.img | awk -F ':' '{print $1}'`
fi
[ -z "$(losetup -a | grep o_p_t.img | awk -F ':' '{print $1}')" ] && losetup `losetup -f` $upanPath/opt/o_p_t.img
[ -z "$(df -m | grep "/dev/loop" | grep "/media/o_p_t_img")" ] && { modprobe -q ext4 ; mkdir -p /media/o_p_t_img ; mount -t ext4 -o noatime "$(losetup -a | grep o_p_t.img | awk -F ':' '{print $1}')" "/media/o_p_t_img" ; }
mountpoint -q /media/o_p_t_img && mount -o bind "/media/o_p_t_img" /opt

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

AiDisk00 () {
re_size &
if [ ! -s "/etc/ssl/certs/ca-certificates.crt" ] ; then
# 安装ca-certificates
mountpoint -q /opt && mountp=0 || mountp=1 # 0已挂载 1没挂载
if [ "$mountp" = "0" ] && [ ! -s "/etc/ssl/certs/ca-certificates.crt" ] ; then
	mkdir -p /opt/app/ipk/
	mkdir -p /opt/etc/ssl/certs
	rm -f /etc/ssl/certs
	ln -sf /opt/etc/ssl/certs  /etc/ssl/certs
	if [ ! -s "/etc/ssl/certs/ca-certificates.crt" ] && [ -s /etc_ro/certs.tgz ]; then
		tar -xzvf /etc_ro/certs.tgz -C /opt/etc/ssl/
	fi
	if [ ! -s "/etc/ssl/certs/ca-certificates.crt" ] ; then
		logger -t "【opt】" "已挂载,找不到ca-certificates证书"
		logger -t "【opt】" "下载证书"
		wgetcurl.sh /opt/app/ipk/certs.tgz "$hiboyfile/certs.tgz" "$hiboyfile2/certs.tgz"
		logger -t "【opt】" "安装证书"
		tar -xzvf /opt/app/ipk/certs.tgz -C /opt/etc/ssl/
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
if [ ! -f /sbin/check_network ] && [ ! -f /opt/bin/check_network ] ; then
	wgetcurl.sh '/opt/bin/check_network' "$hiboyfile/check_network" "$hiboyfile2/check_network"
fi
[ -f /sbin/check_network ] && [ -f /opt/bin/check_network ] && rm -f /opt/bin/check_network
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
# flush buffers
sync
[ ! -s /tmp/script/_opt_script_check ] && /etc/storage/script/sh_opt_script_check.sh &
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

if [ ! -f /opt/opt.tgz ]  ; then
	rm -f /opt/opt.tgz
	logger -t "【opt】" "/opt 可用空间：$(df -m | grep '% /opt' | awk 'NR==1' | awk -F' ' '{print $4}')M"
	optPath="`grep ' /opt ' /proc/mounts | grep tmpfs`"
	[ ! -z "$optPath" ] && { logger -t "【opt】" "下载: $opttmpfile" ; wgetcurl.sh '/opt/opt.tgz' "$opttmpfile" "$opttmpfile2"; }
	optPath="`grep ' /opt ' /proc/mounts | grep /dev`"
	[ ! -z "$optPath" ] && { logger -t "【opt】" "下载: $optupanfile" ; wgetcurl.sh '/opt/opt.tgz' "$optupanfile" "$optupanfile"; }
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
	logger -t "【opt】" "自动安装（覆盖 opt 文件夹）"
	logger -t "【opt】" "opt 第一次下载/opt/opt.tgz"
	opt_file
	if [ ! -s "/opt/opti.txt" ] ; then
		logger -t "【opt】" "/opt/opt.tgz 下载失败"
		logger -t "【opt】" "opt 第二次下载/opt/opt.tgz"
		opt_file
	fi
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
		mkdir -p /opt/opt_backup
		tar -xzvf /opt/opt.tgz -C /opt/opt_backup
		opt_Available
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
if [ "$upopt_enable" = "1" ] ; then
wgetcurl.sh "/tmp/opti.txt" "$optupanfile2" "$optupanfile4"
nvram set optt="`cat /tmp/opti.txt`"
else
rm -rf /tmp/opti.txt
upopt2 &
fi
nvram set opto="`cat /opt/opti.txt`"
}

upopt2 () {
wgetcurl.sh "/tmp/opti.txt" "$optupanfile2" "$optupanfile4"
nvram set optt="`cat /tmp/opti.txt`"
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
/usr/bin/find /opt/opt_backup/etc/init.d/ -perm '-u+x' -name '*' | grep -v "S10iptables" | grep -v Sh61_lnmp.sh | sort -r  >> /tmp/md5/libmd5f
while read line
do
if [ -f "$line" ] ; then
	MD5_backup="$(md5sum $line | awk '{print $1;}')"
	b_line="$(echo $line | sed  "s@^/opt/opt_backup/@/opt/@g")"
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
sync;echo 3 > /proc/sys/vm/drop_caches

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
#/usr/bin/find /opt/etc/init.d/ -perm '-u+x' -name '*' | grep -v "S10iptables" | sort -r  >> /tmp/md5/libmd5f
while read line
do
if [ -f "$line" ] ; then
	MD5_backup="$(md5sum $line | awk '{print $1;}')"
	b_line="$(echo $line | sed  "s@^/opt/@/opt/opt_backup/@g")"
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
sync;echo 3 > /proc/sys/vm/drop_caches

}

re_upan_storage () {
/tmp/re_upan_storage.sh &
}

initconfig () {

cat > "/tmp/re_upan_storage.sh" <<-\EEE
#!/bin/sh
#set -x
upan_storage_enable=`nvram get upan_storage_enable`
if [ "$upan_storage_enable" = "1" ] && [ "$1" != "0" ] ; then
if [ ! -s /etc/storage/start_script.sh ] ; then
	umount /etc/storage
	umount -l /etc/storage
	{ fuser -m -k /etc/storage 2>/dev/null ; umount -l /etc/storage ; }
	sleep 1
	mtd_storage.sh fill
	restart_firewall
	exit
fi
if ! mountpoint -q /etc/storage ; then
if [ ! -f /opt/storage/start_script.sh ] && [ -f /etc/storage/start_script.sh ]  ; then
	mkdir -p -m 755 /opt/storage
	cp -af /etc/storage/* /opt/storage
fi
	logger -t "【外部存储storage】" "/etc/storage -> /opt/storage"
	mount --bind /opt/storage /etc/storage
	mtd_storage.sh fill
fi
else
	mountpoint -q /etc/storage && logger -t "【外部存储storage】" "停止外部存储storage！ umount /etc/storage"
	mountpoint -q /etc/storage && umount /etc/storage
	mountpoint -q /etc/storage && umount -l /etc/storage
	mountpoint -q /etc/storage && { fuser -m -k /etc/storage 2>/dev/null ; umount -l /etc/storage ; }
	sleep 1
	mtd_storage.sh fill
fi
EEE
chmod 755 "/tmp/re_upan_storage.sh"

cifs_script="/etc/storage/cifs_script.sh"
if [ ! -f "$cifs_script" ] || [ ! -s "$cifs_script" ] ; then
	cat > "$cifs_script" <<-\EEE
#!/bin/sh
# SMB资源挂载(局域网共享映射，无USB也能挂载储存空间)
# 说明：【192.168.123.66】为共享服务器的IP，【nas】为共享文件夹名称
# 说明：username=、password=填账号密码
modprobe des_generic
modprobe cifs CIFSMaxBufSize=64512
mkdir -p /media/cifs
umount /media/cifs
mount -t cifs //192.168.123.66/nas /media/cifs -o username=user,password=pass,dynperm,nounix,noserverino,file_mode=0777,dir_mode=0777

EEE
	chmod 755 "$cifs_script"
fi

}

initconfig

mount_check () {
(
	flock 101
mount_check_lock
) 101>/var/lock/101_flock.lock

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
	rm -rf /opt/opti.txt /opt/opt_backup/opti.txt
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
opt_download)
	[ -d /tmp/AiDisk_00/cn2qq/opt-script ] && rm -rf /tmp/AiDisk_00/cn2qq/opt-script
	[ -d /tmp/AiDisk_00/cn2qq/opt-file ] && rm -rf /tmp/AiDisk_00/cn2qq/opt-file
	[ -d /tmp/AiDisk_00/cn2qq/opt-script-master ] && rm -rf /tmp/AiDisk_00/cn2qq/opt-script-master
	[ -d /tmp/AiDisk_00/cn2qq/opt-file-master ] && rm -rf /tmp/AiDisk_00/cn2qq/opt-file-master
	[ -f /tmp/AiDisk_00/cn2qq/opt-script.tgz ] && rm -f /tmp/AiDisk_00/cn2qq/opt-script.tgz
	[ -f /tmp/AiDisk_00/cn2qq/opt-file.tgz ] && rm -f /tmp/AiDisk_00/cn2qq/opt-file.tgz
	opt_download_enable=1
	opt_download &
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
	mount_check
	killall -q rstats
	[ $? -eq 0 ] && sleep 1
	rm -rf /opt/storage/*
	mtd_storage.sh resetsh
	/sbin/rstats &
	;;
*)
	mount_check
	if [ "$optinstall" = "1" ] || [ "$upopt_enable" = "1" ] ; then
		opt_wget
	fi
	;;
esac


