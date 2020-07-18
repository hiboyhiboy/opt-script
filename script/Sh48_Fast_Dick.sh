#!/bin/sh
#copyright by hiboy
source /etc/storage/script/init.sh
FastDick_enable=`nvram get FastDick_enable`
[ -z $FastDick_enable ] && FastDick_enable=0 && nvram set FastDick_enable=0
if [ "$FastDick_enable" != "0" ] ; then
#nvramshow=`nvram showall | grep '=' | grep FastDick | awk '{print gensub(/'"'"'/,"'"'"'\"'"'"'\"'"'"'","g",$0);}'| awk '{print gensub(/=/,"='\''",1,$0)"'\'';";}'` && eval $nvramshow

FastDick_uid=`nvram get FastDick_uid`
FastDick_pwd=`nvram get FastDick_pwd`
FastDicks=`nvram get FastDicks`

FastDicks_renum=`nvram get FastDicks_renum`
FastDicks_renum=${FastDicks_renum:-"0"}
cmd_log_enable=`nvram get cmd_log_enable`
cmd_name="FastDicks"
cmd_log=""
if [ "$cmd_log_enable" = "1" ] || [ "$FastDicks_renum" -gt "0" ] ; then
	cmd_log="$cmd_log2"
fi
fi

if [ ! -z "$(echo $scriptfilepath | grep -v "/tmp/script/" | grep Fast_Dick)" ]  && [ ! -s /tmp/script/_Fast_Dick ]; then
	mkdir -p /tmp/script
	{ echo '#!/bin/sh' ; echo $scriptfilepath '"$@"' '&' ; } > /tmp/script/_Fast_Dick
	chmod 777 /tmp/script/_Fast_Dick
fi

FastDicks_restart () {

relock="/var/lock/FastDicks_restart.lock"
if [ "$1" = "o" ] ; then
	nvram set FastDicks_renum="0"
	[ -f $relock ] && rm -f $relock
	return 0
fi
if [ "$1" = "x" ] ; then
	if [ -f $relock ] ; then
		logger -t "【FastDicks】" "多次尝试启动失败，等待【"`cat $relock`"分钟】后自动尝试重新启动"
		exit 0
	fi
	FastDicks_renum=${FastDicks_renum:-"0"}
	FastDicks_renum=`expr $FastDicks_renum + 1`
	nvram set FastDicks_renum="$FastDicks_renum"
	if [ "$FastDicks_renum" -gt "2" ] ; then
		I=19
		echo $I > $relock
		logger -t "【FastDicks】" "多次尝试启动失败，等待【"`cat $relock`"分钟】后自动尝试重新启动"
		while [ $I -gt 0 ]; do
			I=$(($I - 1))
			echo $I > $relock
			sleep 60
			[ "$(nvram get FastDicks_renum)" = "0" ] && exit 0
			[ $I -lt 0 ] && break
		done
		nvram set FastDicks_renum="0"
	fi
	[ -f $relock ] && rm -f $relock
fi
nvram set FastDicks_status=0
eval "$scriptfilepath &"
exit 0
}

FastDick_get_status () {

A_restart=`nvram get FastDicks_status`
B_restart="$FastDick_uid$FastDick_pwd$FastDick_enable$FastDicks"
B_restart=`echo -n "$B_restart" | md5sum | sed s/[[:space:]]//g | sed s/-//g`
if [ "$A_restart" != "$B_restart" ] ; then
	nvram set FastDicks_status=$B_restart
	needed_restart=1
else
	needed_restart=0
fi
}

FastDick_check () {

FastDick_get_status
if [ "$FastDick_enable" != "1" ] && [ "$needed_restart" = "1" ] ; then
	running=$(ps -w | grep "FastDick" | grep -v "grep" | wc -l)
	[ $running -gt 1 ] && logger -t "【迅雷快鸟】" "停止 迅雷快鸟$running" && FastDick_clos
	{ kill_ps "$scriptname" exit0; exit 0; }
fi
if [ "$FastDick_enable" = "1" ] ; then
	if [ "$needed_restart" = "1" ] ; then
		FastDick_close
		FastDick_start
	else
		running=$(ps -w | grep "FastDick" | grep -v "grep" | wc -l)
		if [ $running -lt 1 ] ; then
			FastDicks_restart
		fi
	fi
fi
}

FastDick_keep () {
logger -t "【迅雷快鸟】" "守护进程启动"
while true; do
	running=$(ps -w | grep "FastDick" | grep -v "grep" | wc -l)
	if [ $running -lt 1 ] ; then
		FastDicks_restart
	fi
sleep 948
done
}

FastDick_close () {
kill_ps "$scriptname keep"
killall FastDick_script.sh
killall -9 FastDick_script.sh
kill_ps "/opt/FastDick/swjsq"
kill_ps "/tmp/script/_Fast_Dick"
kill_ps "_Fast_Dick.sh"
kill_ps "$scriptname"
}


FastDick_start () {
check_webui_yes
logger -t "【迅雷快鸟】" "迅雷快鸟(diǎo)路由器版:https://github.com/fffonion/Xunlei-FastDick"
if [ "$FastDicks" = "2" ] ; then
	logger -t "【迅雷快鸟】" "稍等几分钟，ssh 到路由，控制台输入【ps】命令查看[/etc/storage/FastDick_script.sh]进程是否存在，是否正常启动，提速是否成功。"
	logger -t "【迅雷快鸟】" "免 U盘 启动"
	chmod 777 "/etc/storage/FastDick_script.sh"
	eval "/etc/storage/FastDick_script.sh $cmd_log" &
else
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
		logger -t "【迅雷快鸟】" "未挂载储存设备, 请重新检查配置、目录，10 秒后自动尝试重新启动"
		sleep 10
		FastDicks_restart x
		exit 0
	fi

	SVC_PATH=/opt/bin/python
	chmod 777 "$SVC_PATH"
	if [ ! -s "$SVC_PATH" ] ; then
		logger -t "【迅雷快鸟】" "找不到 $SVC_PATH，安装 opt 程序"
		/etc/storage/script/Sh01_mountopt.sh optwget
		initopt
	fi
	[[ "$(python -h 2>&1 | wc -l)" -lt 2 ]] && /etc/storage/script/Sh01_mountopt.sh libmd5_check
	if [ -s "$SVC_PATH" ] ; then
		logger -t "【迅雷快鸟】" "找到 $SVC_PATH"
	else
		logger -t "【迅雷快鸟】" "找不到 $SVC_PATH ，需要手动安装 $SVC_PATH"
		logger -t "【迅雷快鸟】" "启动失败, 10 秒后自动尝试重新启动" && sleep 10 && FastDicks_restart x
	fi
	hash python 2>/dev/null || {  logger -t "【迅雷快鸟】" "无法运行 python 程序，请检查系统，10 秒后自动尝试重新启动" ; sleep 10 ; FastDicks_restart x ; }
	rm -f "/opt/FastDick/" -R
	mkdir -p "/opt/FastDick"
	swjsqfile="https://cdn.jsdelivr.net/gh/fffonion/Xunlei-FastDick@latest/swjsq.py"
	wgetcurl.sh "/opt/FastDick/swjsq.py" $swjsqfile $swjsqfile N
	chmod 777 "/opt/FastDick/swjsq.py"
	logger -t "【迅雷快鸟】" "程序下载完成, 正在启动 python /opt/FastDick/swjsq.py"
	echo "$FastDick_uid,$FastDick_pwd" >/opt/FastDick/swjsq.account.txt
	chmod 777 /opt/FastDick -R
	cd /opt/FastDick
	export LD_LIBRARY_PATH=/lib:/opt/lib
	eval "python /opt/FastDick/swjsq.py $cmd_log" &
	chmod 777 "/opt/FastDick" -R
	sleep 30
	chmod 777 "/opt/FastDick" -R
	if [ -f /opt/FastDick/swjsq_wget.sh ] ; then
		logger -t "【迅雷快鸟】" "自动备份 swjsq 文件到路由, 【写入内部存储】后下次重启可以免U盘启动了"
		cat > "/etc/storage/FastDick_script.sh" <<-\EEF
#!/bin/sh
# 迅雷快鸟【2免U盘启动】功能需到【自定义脚本0】配置【FastDicks=2】，并在此输入swjsq_wget.sh文件内容
#【2免U盘启动】需要填写在下方的【迅雷快鸟脚本】，生成脚本两种方法：
# ①插入U盘，配置自定义脚本【1插U盘启动】启动快鸟一次即可自动生成
# ②打开https://github.com/fffonion/Xunlei-FastDick，按照网页的说明在PC上运行脚本，登陆成功后会生成swjsq_wget.sh，把swjsq_wget.sh的内容粘贴此处即可
# 生成后需要到【系统管理】 - 【恢复/导出/上传设置】 - 【路由器内部存储 (/etc/storage)】【写入】保存脚本
EEF
		cat /opt/FastDick/swjsq_wget.sh >> /etc/storage/FastDick_script.sh
		chmod 777 "/etc/storage/FastDick_script.sh"
	fi
	logger -t "【迅雷快鸟】" "启动 python 完成"
	optw_enable=`nvram get optw_enable`
	if [ "$optw_enable" != "2" ] ; then
		nvram set optw_enable=2
	fi
fi
sleep 2
[ ! -z "$(ps -w | grep "FastDick" | grep -v grep )" ] && logger -t "【迅雷快鸟】" "启动成功" && FastDicks_restart o
if [ "$FastDicks" = "2" ] ; then
[ -z "$(ps -w | grep "FastDick" | grep -v grep )" ] && logger -t "【迅雷快鸟】" "启动失败, 注意检脚本是否完整,10 秒后自动尝试重新启动" && sleep 10 && FastDicks_restart x
else
[ -z "$(ps -w | grep "FastDick" | grep -v grep )" ] && logger -t "【迅雷快鸟】" "启动失败, 注意检查python程序是否下载完整,手动ssh运行【python /opt/FastDick/swjsq.py】看报错日志,10 秒后自动尝试重新启动" && sleep 10 && FastDicks_restart x
fi
FastDick_get_status
eval "$scriptfilepath keep &"
exit 0
}

initconfig () {

FastDick_script="/etc/storage/FastDick_script.sh"
if [ ! -f "$FastDick_script" ] || [ ! -s "$FastDick_script" ] ; then
	cat > "$FastDick_script" <<-\EEE
#!/bin/sh
# 迅雷快鸟【免U盘启动】功能需在此输入swjsq_wget.sh文件内容
# swjsq_wget.sh文件脚本两种方法：
# ①插入U盘，配置自定义脚本【插U盘启动】启动快鸟一次即可自动生成
# ②打开https://github.com/fffonion/Xunlei-FastDick，按照网页的说明在PC上运行脚本，登陆成功后会生成swjsq_wget.sh，把swjsq_wget.sh的内容粘贴此处即可
# 生成后需要到【系统管理】 - 【恢复/导出/上传设置】 - 【路由器内部存储 (/etc/storage)】【写入】保存脚本

EEE
	chmod 755 "$FastDick_script"
fi

}

initconfig

initopt () {
optPath=`grep ' /opt ' /proc/mounts | grep tmpfs`
[ ! -z "$optPath" ] && return
if [ ! -z "$(echo $scriptfilepath | grep -v "/opt/etc/init")" ] && [ -s "/opt/etc/init.d/rc.func" ] ; then
	{ echo '#!/bin/sh' ; echo $scriptfilepath '"$@"' '&' ; } > /opt/etc/init.d/$scriptname && chmod 777  /opt/etc/init.d/$scriptname
fi

}

case $ACTION in
start)
	FastDick_close
	FastDick_check
	;;
check)
	FastDick_check
	;;
stop)
	FastDick_close
	;;
keep)
	#FastDick_check
	FastDick_keep
	;;
*)
	FastDick_check
	;;
esac

