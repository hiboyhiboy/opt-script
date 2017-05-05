#!/bin/sh
#copyright by hiboy
source /etc/storage/script/init.sh
FastDick_enable=`nvram get FastDick_enable`
[ -z $FastDick_enable ] && FastDick_enable=0 && nvram set FastDick_enable=0
if [ "$FastDick_enable" != "0" ] ; then
nvramshow=`nvram showall | grep FastDick | awk '{print gensub(/'"'"'/,"'"'"'\"'"'"'\"'"'"'","g",$0);}'| awk '{print gensub(/=/,"='\''",1,$0)"'\'';";}'` && eval $nvramshow
fi

if [ ! -z "$(echo $scriptfilepath | grep -v "/tmp/script/" | grep Fast_Dick)" ]  && [ ! -s /tmp/script/_Fast_Dick ]; then
	mkdir -p /tmp/script
	ln -sf $scriptfilepath /tmp/script/_Fast_Dick
	chmod 777 /tmp/script/_Fast_Dick
fi

FastDick_check () {
A_restart=`nvram get FastDicks_status`
B_restart="$FastDick_uid$FastDick_pwd$FastDick_enable$FastDicks"
B_restart=`echo -n "$B_restart" | md5sum | sed s/[[:space:]]//g | sed s/-//g`
if [ "$A_restart" != "$B_restart" ] ; then
	nvram set FastDicks_status=$B_restart
	needed_restart=1
else
	needed_restart=0
fi
if [ "$FastDick_enable" != "1" ] && [ "$needed_restart" = "1" ] ; then
	running=$(ps -w | grep "FastDick" | grep -v "grep" | wc -l)
	[ $running -gt 1 ] && logger -t "【迅雷快鸟】" "停止 迅雷快鸟$running" && FastDick_clos
	{ eval $(ps -w | grep "$scriptname" | grep -v grep | awk '{print "kill "$1";";}'); exit 0; }
fi
if [ "$FastDick_enable" = "1" ] ; then
	if [ "$needed_restart" = "1" ] ; then
		FastDick_close
		FastDick_start
	else
		running=$(ps -w | grep "FastDick" | grep -v "grep" | wc -l)
		if [ $running -lt 1 ] ; then
			nvram set FastDicks_status=00 && { eval "$scriptfilepath start &"; exit 0; }
		fi
	fi
fi
}

FastDick_keep () {
logger -t "【迅雷快鸟】" "守护进程启动"
while true; do
sleep 948
eval $(ps -w | grep "/opt/FastDick/swjsq" | grep -v grep | awk '{print "kill "$1";";}')
killall FastDick_script.sh
killall -9 FastDick_script.sh
/etc/storage/FastDick_script.sh &
done
}

FastDick_close () {
killall FastDick_script.sh
killall -9 FastDick_script.sh
eval $(ps -w | grep "/opt/FastDick/swjsq" | grep -v grep | awk '{print "kill "$1";";}')
eval $(ps -w | grep "_Fast_Dick keep" | grep -v grep | awk '{print "kill "$1";";}')
eval $(ps -w | grep "_Fast_Dick.sh keep" | grep -v grep | awk '{print "kill "$1";";}')
eval $(ps -w | grep "$scriptname keep" | grep -v grep | awk '{print "kill "$1";";}')
}


FastDick_start () {
logger -t "【迅雷快鸟】" "迅雷快鸟(diǎo)路由器版:https://github.com/fffonion/Xunlei-FastDick"
if [ "$FastDicks" = "2" ] ; then
	logger -t "【迅雷快鸟】" "稍等几分钟，ssh 到路由，控制台输入【ps】命令查看[/etc/storage/FastDick_script.sh]进程是否存在，是否正常启动，提速是否成功。"
	logger -t "【迅雷快鸟】" "免 U盘 启动"
	chmod 777 "/etc/storage/FastDick_script.sh"
	/etc/storage/FastDick_script.sh &
else
	ss_opt_x=`nvram get ss_opt_x`
	upanPath=""
	[ "$ss_opt_x" = "3" ] && upanPath="`df -m | grep /dev/mmcb | grep "/media" | awk '{print $NF}' | awk 'NR==1' `"
	[ "$ss_opt_x" = "4" ] && upanPath="`df -m | grep "/dev/sd" | grep "/media" | awk '{print $NF}' | awk 'NR==1' `"
	[ -z "$upanPath" ] && [ "$ss_opt_x" = "1" ] && upanPath="`df -m | grep /dev/mmcb | grep "/media" | awk '{print $NF}' | awk 'NR==1' `"
	[ -z "$upanPath" ] && [ "$ss_opt_x" = "1" ] && upanPath="`df -m | grep "/dev/sd" | grep "/media" | awk '{print $NF}' | awk 'NR==1' `"
	echo "$upanPath"
	if [ -z "$upanPath" ] ; then 
		logger -t "【迅雷快鸟】" "未挂载储存设备, 请重新检查配置、目录，10 秒后自动尝试重新启动"
		sleep 10
		eval "$scriptfilepath &"
		exit 0
	fi

	SVC_PATH=/opt/bin/python
	hash python 2>/dev/null || rm -rf /opt/bin/python /opt/opti.txt
	if [ ! -s "$SVC_PATH" ] ; then
		logger -t "【迅雷快鸟】" "找不到 $SVC_PATH，安装 opt 程序"
		/tmp/script/_mountopt optwget
	fi
	if [ -s "$SVC_PATH" ] ; then
		logger -t "【迅雷快鸟】" "找到 $SVC_PATH"
	else
		logger -t "【迅雷快鸟】" "找不到 $SVC_PATH ，需要手动安装 $SVC_PATH"
		logger -t "【迅雷快鸟】" "启动失败, 10 秒后自动尝试重新启动" && sleep 10 && { nvram set FastDicks_status=00; eval "$scriptfilepath &"; exit 0; }
	fi
	hash python 2>/dev/null || {  logger -t "【迅雷快鸟】" "无法运行 python 程序，请检查系统，10 秒后自动尝试重新启动" ; sleep 10 ; nvram set FastDicks_status=00 ; eval "$scriptfilepath &" ; exit 1; }
	rm -f "/opt/FastDick/" -R
	mkdir -p "/opt/FastDick"
	swjsqfile="https://raw.githubusercontent.com/fffonion/Xunlei-FastDick/master/swjsq.py"
	wgetcurl.sh "/opt/FastDick/swjsq.py" $swjsqfile
	chmod 777 "/opt/FastDick/swjsq.py"
	logger -t "【迅雷快鸟】" "程序下载完成, 正在启动 python /opt/FastDick/swjsq.py"
	echo "$FastDick_uid,$FastDick_pwd" >/opt/FastDick/swjsq.account.txt
	chmod 777 /opt/FastDick -R
	cd /opt/FastDick
	export LD_LIBRARY_PATH=/lib:/opt/lib
	python /opt/FastDick/swjsq.py 2>&1 > /opt/FastDick/swjsq.log &
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
	logger -t "【迅雷快鸟】" "启动完成`cat /opt/FastDick/swjsq.log`"
	optw_enable=`nvram get optw_enable`
	if [ "$optw_enable" != "2" ] ; then
		nvram set optw_enable=2
	fi
fi
sleep 2
[ ! -z "$(ps -w | grep "FastDick" | grep -v grep )" ] && logger -t "【迅雷快鸟】" "启动成功"
[ -z "$(ps -w | grep "FastDick" | grep -v grep )" ] && logger -t "【迅雷快鸟】" "启动失败, 注意检查端口是否有冲突,程序是否下载完整,10 秒后自动尝试重新启动" && sleep 10 && { nvram set FastDicks_status=00 ; eval "$scriptfilepath &"; exit 0; }

eval "$scriptfilepath keep &"
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
	FastDick_check
	FastDick_keep
	;;
*)
	FastDick_check
	;;
esac

