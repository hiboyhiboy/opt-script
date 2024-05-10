#!/bin/bash
#copyright by hiboy
source /etc/storage/script/init.sh
#nvramshow=`nvram showall | grep '=' | grep script | awk '{print gensub(/'"'"'/,"'"'"'\"'"'"'\"'"'"'","g",$0);}'| awk '{print gensub(/=/,"='\''",1,$0)"'\'';";}'` && eval $nvramshow
upscript_enable=`nvram get upscript_enable`
scriptt=`nvram get scriptt`
scripto=`nvram get scripto`
[ "$ACTION" = "upscript" ] && upscript_enable=1

if [ ! -z "$(echo $scriptfilepath | grep -v "/tmp/script/" | grep _upscript)" ] && [ ! -s /tmp/script/_upscript ] ; then
	mkdir -p /tmp/script
	{ echo '#!/bin/bash' ; echo $scriptfilepath '"$@"' '&' ; } > /tmp/script/_upscript
	chmod 777 /tmp/script/_upscript
fi

file_o_check () {

#获取script的sh*文件MD5
eval $(md5sum `/usr/bin/find /etc/storage/script/ -perm '-u+x' -name '*.sh' | sort -r` | awk '{print $2"_o="$1;}' | awk -F '/' '{print $NF;}' | sed 's/\.sh//g')
}

file_t_check () {

#获取最新script的sh*文件MD5
rm -f /tmp/scriptsh.txt
wgetcurl.sh "/tmp/scriptsh.txt" "$hiboyscript/scriptsh.txt" "$hiboyscript2/scriptsh.txt"
if [ ! -s /tmp/scriptsh.txt ] || [ -z "$(cat /tmp/scriptsh.txt | grep "sh_upscript")" ] || [ -z "$(cat /tmp/scriptsh.txt | grep "scriptt")" ] ; then
	/etc/storage/script/Sh01_mountopt.sh re_ca_tmp
	source /etc/storage/script/init.sh
	wgetcurl.sh "/tmp/scriptsh.txt" "$hiboyscript/scriptsh.txt" "$hiboyscript2/scriptsh.txt"
fi
if [ ! -s /tmp/scriptsh.txt ] || [ -z "$(cat /tmp/scriptsh.txt | grep "sh_upscript")" ] || [ -z "$(cat /tmp/scriptsh.txt | grep "scriptt")" ] ; then
	/etc/storage/script/Sh01_mountopt.sh opt_cdn_force
	source /etc/storage/script/init.sh
	wgetcurl.sh "/tmp/scriptsh.txt" "$hiboyscript/scriptsh.txt" "$hiboyscript2/scriptsh.txt"
fi
if [ -s /tmp/scriptsh.txt ] && [ ! -z "$(cat /tmp/scriptsh.txt | grep "sh_upscript")" ] && [ ! -z "$(cat /tmp/scriptsh.txt | grep "scriptt")" ] ; then
	sed -Ei '/\s/d' /tmp/scriptsh.txt
	source /tmp/scriptsh.txt
	nvram set scriptt="$scriptt"
	nvram set scripto="2024-05-10"
	scriptt=`nvram get scriptt`
	scripto=`nvram get scripto`
fi
}

file_check () {
mkdir -p /tmp/script
if [ -s /tmp/scriptsh.txt ] && [ ! -z "$(cat /tmp/scriptsh.txt | grep "sh_upscript")" ] && [ ! -z "$(cat /tmp/scriptsh.txt | grep "scriptt")" ] ; then
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
				/etc/storage/script/Sh01_mountopt.sh opt_force
				echo -n "" > /tmp/script/wgetcurl.sh
				source /etc/storage/script/init.sh
			fi
		else
			logger -t "【script】" "/tmp/script/$file_name.sh 脚本md5与记录不同，下载失败，跳过更新！"
		fi
	fi
fi
done < /tmp/scriptsh.txt
fi
}

start_upscript () {
[ "$upscript_enable" != "1" ] && return # 未启用自动更新
logger -t "【script】" "脚本检查更新"
file_t_check
if [ -s /tmp/scriptsh.txt ] && [ ! -z "$(cat /tmp/scriptsh.txt | grep "sh_upscript")" ] && [ ! -z "$(cat /tmp/scriptsh.txt | grep "scriptt")" ] ; then
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
for i in /etc/storage/script/Sh??_* ; do
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

all_up_web () {
logger -t "【WebUI】" "遍历更新 web 页面"
# 解压内置 asp 文件
[ -s /etc_ro/www_asp.tgz ] && { tar -xzvf /etc_ro/www_asp.tgz -C /tmp ;  chmod 666 /tmp/www_asp -R ; }
chmod 777 /etc/storage/script -R
# start all services Sh??_* in /etc/storage/script
for i in /etc/storage/script/Sh??_* ; do
	[ ! -x "${i}" ] && continue
	eval ${i} update_asp
done
/etc/storage/www_sh/menu_title.sh
sync;echo 3 > /proc/sys/vm/drop_caches
}

www_asp_re () {
rm -f /tmp/www_asp_re
logger -t "【WebUI】" "恢复内置 web 页面"
# 解压内置 asp 文件
[ -s /etc_ro/www_asp.tgz ] && { tar -xzvf /etc_ro/www_asp.tgz -C /tmp ;  chmod 666 /tmp/www_asp -R ; }
for i in `/usr/bin/find /tmp/www_asp/ -name 'Advanced*'` ; do
	[ -z "${i}" ] && continue
	i_2="$(/usr/bin/find /opt/app/ -name '*'"$(echo $(basename $i) | sed -e 's@asp$@@g')"'.asp')"
	[ -z "${i_2}" ] && continue
	cp -f "${i}" "${i_2}"
	rm -f "${i}"
done
sync;echo 3 > /proc/sys/vm/drop_caches
}

case $ACTION in
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
	;;
upweb)
	all_up_web
	;;
www_asp_re)
	www_asp_re
	;;
upscript)
	upscript_enable=1
	start_upscript
	;;
*)
	start_upscript
	;;
esac

