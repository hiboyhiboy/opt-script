#!/bin/sh
#copyright by hiboy
source /etc/storage/script/init.sh
#nvramshow=`nvram showall | grep '=' | grep script | awk '{print gensub(/'"'"'/,"'"'"'\"'"'"'\"'"'"'","g",$0);}'| awk '{print gensub(/=/,"='\''",1,$0)"'\'';";}'` && eval $nvramshow
upscript_enable=`nvram get upscript_enable`
scriptt=`nvram get scriptt`
scripto=`nvram get scripto`
[ "$ACTION" = "upscript" ] && upscript_enable=1

opt_force () {

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
}

opt_force

file_o_check () {

#获取script的sh*文件MD5
eval $(md5sum `/usr/bin/find /etc/storage/script/ -perm '-u+x' -name '*.sh' | sort -r` | awk '{print $2"_o="$1;}' | awk -F '/' '{print $NF;}' | sed 's/\.sh//g')
}

file_t_check () {

#获取最新script的sh*文件MD5
rm -f /tmp/scriptsh.txt
wgetcurl.sh "/tmp/scriptsh.txt" "$hiboyscript/scriptsh.txt" "$hiboyscript2/scriptsh.txt"
if [ -s /tmp/scriptsh.txt ] ; then
	source /tmp/scriptsh.txt
	nvram set scriptt="$scriptt"
	nvram set scripto="2020-01-18"
	scriptt=`nvram get scriptt`
	scripto=`nvram get scripto`
fi
}

file_check () {
mkdir -p /tmp/script
while read line
do
c_line=`echo $line |grep -v "#" |grep -v 'scriptt='`
file_name=${line%%=*}
if [ ! -z "$c_line" ] && [ ! -z "$file_name" ] ; then
	MD5_TMP=`eval echo '$'${file_name}`
	MD5_ORI=`eval echo '$'$file_name"_o"`
	if [ ! -s /etc/storage/script/$file_name.sh ] || [ "$MD5_TMP"x != "$MD5_ORI"x ] ; then
		logger -t "【script】" "/etc/storage/script/$file_name.sh 脚本需要更新，自动下载！$hiboyscript/script/$file_name.sh"
		wgetcurl.sh "/tmp/script/$file_name.sh" "$hiboyscript/script/$file_name.sh" "$hiboyscript2/script/$file_name.sh"
		eval $(md5sum /tmp/script/$file_name.sh | awk '{print "MD5_ORI="$1;}')
		if [ -s /tmp/script/$file_name.sh ] && [ "$MD5_TMP"x = "$MD5_ORI"x ] ; then
			logger -t "【script】" " 更新【$file_name.sh】，md5匹配，更新成功！"
			mv -f /tmp/script/$file_name.sh /etc/storage/script/$file_name.sh
			if [ "$file_name"x = "initx" ] ; then
				opt_force
				source /etc/storage/script/init.sh
			fi
		else
			logger -t "【script】" "/tmp/script/$file_name.sh 脚本md5与记录不同，下载失败，跳过更新！"
		fi
	fi
fi
done < /tmp/scriptsh.txt
}

start_upscript_daydayup () {

logger -t "【script】" "脚本检查更新"
file_t_check
if [ -s /tmp/scriptsh.txt ] ; then
	[ "$scriptt"x != "$scripto"x ] && [ "$upscript_enable" != "1" ] && logger -t "【script】" "当前【$scripto】脚本需要更新, 未启用自动更新, 请手动更新到【$scriptt】" && return
	if [ "$upscript_enable" = "1" ] && [ "$scriptt"x != "$scripto"x ] ; then
		logger -t "【script】" "脚本需要更新, 自动下载更新"
		nvram set scripto="$scriptt"
		file_o_check
		cd /etc/storage/script/
		rm -f ./.upscript_daydayup
		mkdir -p /tmp/script
		while read line
		do
		c_line=`echo $line |grep -v "#" |grep -v 'scriptt='`
		file_name=${line%%=*}
		if [ ! -z "$c_line" ] && [ ! -z "$file_name" ] ; then
			echo "$hiboyscript/script/$file_name.sh" >> ./.upscript_daydayup
			echo "\|$hiboyscript2/script/$file_name.sh" >> ./.upscript_daydayup
		fi
		done < /tmp/scriptsh.txt
		daydayup ./.upscript_daydayup >> /tmp/syslog.log &
	fi
else
	[ "$upscript_enable" != "1" ] && return
	logger -t "【script】" "脚本检查更新失败"
fi
}

start_upscript () {
logger -t "【script】" "脚本检查更新"
file_t_check
if [ -s /tmp/scriptsh.txt ] ; then
	[ "$scriptt"x = "$scripto"x ] && logger -t "【script】" "脚本已经最新"
	[ "$scriptt"x != "$scripto"x ] && [ "$upscript_enable" != "1" ] && logger -t "【script】" "当前【$scripto】脚本需要更新, 未启用自动更新, 请手动更新到【$scriptt】" && return
	if [ "$upscript_enable" = "1" ] && [ "$scriptt"x != "$scripto"x ] ; then
		logger -t "【script】" "脚本需要更新, 自动下载更新"
		nvram set scripto="$scriptt"
		file_o_check
		file_check
		logger -t "【script】" "脚本更新完成"
	fi
else
	[ "$upscript_enable" != "1" ] && return
	logger -t "【script】" "脚本检查更新失败"
fi
}

check_opt () {
[ ! -d /opt/etc/init.d ] && return
[ ! -f /tmp/scriptsh.txt ] && file_t_check
for initopt in `ls -p /opt/etc/init.d`
do
if [ ! -z `grep "$(echo $initopt | sed 's/\.sh//g')" /tmp/scriptsh.txt)` ] ; then
	cp -f /etc/storage/script/$initopt /opt/etc/init.d/$initopt 
fi

done

}

all_re_stop () {
logger -t "【WebUI】" "UI 开关 stop"
rm -f /tmp/webui_yes
cp -f /etc/storage/script/sh_opt_script_check.sh /tmp/script/_opt_script_check
killall menu_title.sh 
sync;echo 1 > /proc/sys/vm/drop_caches
sleep 2
}

all_stop () {
logger -t "【WebUI】" "UI 开关遍历 all_stop"
rm -f /tmp/webui_yes
chmod 777 /etc/storage/script -R
killall menu_title.sh 
# start all services Sh??_* in /etc/storage/script
for i in `ls /etc/storage/script/Sh??_* 2>/dev/null` ; do
	[ ! -x "${i}" ] && continue
	[ -f /tmp/webui_yes ] && continue
	eval ${i} stop
done
sync;echo 3 > /proc/sys/vm/drop_caches
}

all_check () {
logger -t "【WebUI】" "UI 开关遍历 all_check"
touch /tmp/webui_yes
sync;echo 3 > /proc/sys/vm/drop_caches
/etc/storage/crontabs_script.sh 
}

case $ACTION in
check_opt)
	check_opt
	;;
all_check)
	all_check
	;;
all_stop)
	all_re_stop
	;;
all_re)
	all_stop
	all_check
	;;
stop)
	echo "stop"
	kill_ps "/etc/storage/script/sh_upscript.sh"
	kill_ps "sh_upscript.sh"
	kill_ps "$scriptname"
	;;
start)
	start_upscript
	check_opt
	;;
*)
	start_upscript
	check_opt
	;;
esac

