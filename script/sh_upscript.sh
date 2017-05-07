#!/bin/sh
#copyright by hiboy
source /etc/storage/script/init.sh
#nvramshow=`nvram showall | grep upscript_enable | awk '{print gensub(/'"'"'/,"'"'"'\"'"'"'\"'"'"'","g",$0);}'| awk '{print gensub(/=/,"='\''",1,$0)"'\'';";}'` && eval $nvramshow
nvramshow=`nvram showall | grep script | awk '{print gensub(/'"'"'/,"'"'"'\"'"'"'\"'"'"'","g",$0);}'| awk '{print gensub(/=/,"='\''",1,$0)"'\'';";}'` && eval $nvramshow
[ "$ACTION" = "upscript" ] && upscript_enable=1

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
	nvram set scripto="2017-05-07"
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
	[ "$scriptt"x != "$scripto"x ] && [ "$upscript_enable" != "1" ] && logger -t "【script】" "脚本需要更新, 未启用自动更新, 请手动更新" && return
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
	[ "$scriptt"x != "$scripto"x ] && [ "$upscript_enable" != "1" ] && logger -t "【script】" "脚本需要更新, 未启用自动更新, 请手动更新" && return
	if [ "$upscript_enable" = "1" ] && [ "$scriptt"x != "$scripto"x ] ; then
		logger -t "【script】" "脚本需要更新, 自动下载更新"
		nvram set scripto="$scriptt"
		file_o_check
		file_check
	fi
else
	[ "$upscript_enable" != "1" ] && return
	logger -t "【script】" "脚本检查更新失败"
fi
}

case $ACTION in
start)
	#hash daydayup 2>/dev/null && start_upscript_daydayup
	#hash daydayup 2>/dev/null || start_upscript
	start_upscript
	;;
*)
	#hash daydayup 2>/dev/null && start_upscript_daydayup
	#hash daydayup 2>/dev/null || start_upscript
	start_upscript
	;;
esac

