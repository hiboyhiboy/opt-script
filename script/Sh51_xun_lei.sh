#!/bin/sh
#copyright by hiboy
source /etc/storage/script/init.sh
xunleis=`nvram get xunleis`
[ -z $xunleis ] && xunleis=0 && nvram set xunleis=0
if [ "$xunleis" != "0" ] ; then
nvramshow=`nvram showall | grep xunlei | awk '{print gensub(/'"'"'/,"'"'"'\"'"'"'\"'"'"'","g",$0);}'| awk '{print gensub(/=/,"='\''",1,$0)"'\'';";}'` && eval $nvramshow
fi

if [ ! -z "$(echo $scriptfilepath | grep -v "/tmp/script/" | grep xun_lei)" ]  && [ ! -s /tmp/script/_xun_lei ]; then
	mkdir -p /tmp/script
	ln -sf $scriptfilepath /tmp/script/_xun_lei
	chmod 777 /tmp/script/_xun_lei
fi

xunlei_check () {
A_restart=`nvram get xunleis_status`
B_restart="$xunleis$xunleis_dir"
B_restart=`echo -n "$B_restart" | md5sum | sed s/[[:space:]]//g | sed s/-//g`
if [ "$A_restart" != "$B_restart" ] ; then
	nvram set xunleis_status=$B_restart
	needed_restart=1
else
	needed_restart=0
fi
if [ "$xunleis" != "1" ] && [ "$needed_restart" = "1" ] ; then
	[ ! -z "`pidof ETMDaemon`" ] && logger -t "【迅雷下载】" "停止 xunleis" && xunlei_close
	{ eval $(ps -w | grep "$scriptname" | grep -v grep | awk '{print "kill "$1";";}'); exit 0; }
fi
if [ "$xunleis" = "1" ] ; then
	if [ "$needed_restart" = "1" ] ; then
		xunlei_close
		xunlei_start
	else
		[ -z "`pidof ETMDaemon`" ] && nvram set xunleis_status=00 && { eval "$scriptfilepath start &"; exit 0; }
	fi
fi
}

xunlei_keep () {
sleep 15
wgetcurl.sh "/tmp/xunlei.info" "http://127.0.0.1:9000/getsysinfo" "http://127.0.0.1:9001/getsysinfo"
if [ ! -s /tmp/xunlei.info ] ; then
	sleep 15
	wgetcurl.sh "/tmp/xunlei.info" "http://127.0.0.1:9000/getsysinfo" "http://127.0.0.1:9001/getsysinfo"
	[ ! -s /tmp/xunlei.info ] && { wgetcurl.sh "/tmp/xunlei.info" "http://`nvram get lan_ipaddr`:9002/getsysinfo" "http://`nvram get lan_ipaddr`:9003/getsysinfo" ; }
fi
logger -t "【迅雷下载】" "启动 xunlei, 绑定设备页面【http://yuancheng.xunlei.com】"
logger -t "【迅雷下载】" "在浏览器中输入【http://`nvram get lan_ipaddr`:9000/getsysinfo】"
logger -t "【迅雷下载】" "显示错误则输入【http://`nvram get lan_ipaddr`:9001/getsysinfo】"
logger -t "【迅雷下载】" "会看到类似如下信息："
logger -t "【迅雷下载】" "`cat /tmp/xunlei.info | sed s/[[:space:]]//g `"
nvram set xunleis_sn=`cat /tmp/xunlei.info | sed s/[[:space:]]//g | sed s/"\["//g | sed s/"\]"//g`
logger -t "【迅雷下载】" "其中有用的几项为："
logger -t "【迅雷下载】" "①: 0表示返回结果成功"
logger -t "【迅雷下载】" "②: 1表示检测网络正常, 0表示检测网络异常"
logger -t "【迅雷下载】" "④: 1表示已绑定成功, 0表示未绑定"
logger -t "【迅雷下载】" "⑤: 未绑定的情况下, 为绑定的需要的激活码"
logger -t "【迅雷下载】" "⑥: 1表示磁盘挂载检测成功, 0表示磁盘挂载检测失败"
logger -t "【迅雷下载】" "如果出现错误可以手动启动, 输入以下命令测试"
logger -t "【迅雷下载】" "export LD_LIBRARY_PATH=$xunleis_dir/xunlei/lib:/lib:/opt/lib ; cd $xunleis_dir/xunlei ; $xunleis_dir/xunlei/portal"
logger -t "【迅雷下载】" "守护进程启动 $xunleis_dir/xunlei"
if [ -s /tmp/script/_opt_script_check ]; then
sed -Ei '/【迅雷下载】|^$/d' /tmp/script/_opt_script_check
cat >> "/tmp/script/_opt_script_check" <<-OSC
	NUM=\`grep "/xunlei/lib/" /tmp/ps | grep -v grep |wc -l\` # 【迅雷下载】
	if [ "\$NUM" -le "2" ] || [ ! -s "$xunleis_dir/xunlei/portal" ] ; then # 【迅雷下载】
		logger -t "【迅雷下载】" "重新启动\$NUM" # 【迅雷下载】
		nvram set xunleis_status=00 && eval "$scriptfilepath &" && sed -Ei '/【迅雷下载】|^$/d' /tmp/script/_opt_script_check # 【迅雷下载】
	fi # 【迅雷下载】
OSC
return
fi

while true; do
	if [ ! -s "$xunleis_dir/xunlei/portal" ] ; then
		logger -t "【迅雷下载】" "找不到文件 $xunleis_dir/xunlei/portal"
		{ eval "$scriptfilepath &" ; exit 0; }
	fi
	running=$(ps -w | grep "/xunlei/lib/" | grep -v "grep" | wc -l)
	if [ $running -le 2 ] ; then
		logger -t "【迅雷下载】" "重新启动$running"
		{ nvram set xunleis_status=00 && eval "$scriptfilepath &" ; exit 0; }
	fi
sleep 251
done
}

xunlei_close () {
sed -Ei '/【迅雷下载】|^$/d' /tmp/script/_opt_script_check
killall ETMDaemon EmbedThunderManager vod_httpserver portal
killall -9 ETMDaemon EmbedThunderManager vod_httpserver portal
rm -f "/opt/etc/init.d/$scriptname"
eval $(ps -w | grep "_xun_lei keep" | grep -v grep | awk '{print "kill "$1";";}')
eval $(ps -w | grep "_xun_lei.sh keep" | grep -v grep | awk '{print "kill "$1";";}')
eval $(ps -w | grep "$scriptname keep" | grep -v grep | awk '{print "kill "$1";";}')
}

xunlei_start () {
SVC_PATH="$xunleis_dir/xunlei/portal"
if [ ! -s "$SVC_PATH" ] ; then
	ss_opt_x=`nvram get ss_opt_x`
	upanPath=""
	[ "$ss_opt_x" = "3" ] && upanPath="`df -m | grep /dev/mmcb | grep "/media" | awk '{print $NF}' | awk 'NR==1' `"
	[ "$ss_opt_x" = "4" ] && upanPath="`df -m | grep "/dev/sd" | grep "/media" | awk '{print $NF}' | awk 'NR==1' `"
	[ -z "$upanPath" ] && [ "$ss_opt_x" = "1" ] && upanPath="`df -m | grep /dev/mmcb | grep "/media" | awk '{print $NF}' | awk 'NR==1' `"
	[ -z "$upanPath" ] && [ "$ss_opt_x" = "1" ] && upanPath="`df -m | grep "/dev/sd" | grep "/media" | awk '{print $NF}' | awk 'NR==1' `"
	echo "$upanPath"
	if [ -z "$upanPath" ] ; then 
		logger -t "【迅雷下载】" "未挂载储存设备, 请重新检查配置、目录，10 秒后自动尝试重新启动"
		sleep 10
		nvram set xunleis_status=00 && eval "$scriptfilepath &"
		exit 0
	fi
	xunleis_dir="$upanPath"
	nvram set xunleis_dir="$upanPath"
	SVC_PATH="$xunleis_dir/xunlei/portal"
fi
SVC_PATH="$xunleis_dir/xunlei/portal"
mkdir -p "$xunleis_dir/xunlei/"
[ -f "$SVC_PATH" ] && portal_md5=`md5sum "$SVC_PATH" | awk -F ' ' '{print $1}'`
xunleimd5="86f8c2c931687c4876bdd8ca5febe038"
if [ ! -s "$SVC_PATH" ] || [ $portal_md5 != $xunleimd5 ] ; then
	logger -t "【迅雷下载】" "找不到 $SVC_PATH ，安装 Xware1.0.31_mipsel_32_uclibc 程序"
	Xware1="$hiboyfile/Xware1.0.31_mipsel_32_uclibc.tgz"
	wgetcurl.sh "$xunleis_dir/xunlei/Xware1.tgz" "$hiboyfile/Xware1.0.31_mipsel_32_uclibc.tgz" "$hiboyfile2/Xware1.0.31_mipsel_32_uclibc.tgz"
	untar.sh "$xunleis_dir/xunlei/Xware1.tgz" "$xunleis_dir/xunlei" "$SVC_PATH"
fi
if [ ! -s "$SVC_PATH" ] ; then
	logger -t "【迅雷下载】" "找不到 $SVC_PATH ，需要手动安装 Xware1.0.31_mipsel_32_uclibc"
	logger -t "【迅雷下载】" "启动失败, 10 秒后自动尝试重新启动" && sleep 10 && { nvram set xunleis_status=00; eval "$scriptfilepath &"; exit 0; }
fi
chmod 777 "$xunleis_dir/xunlei" -R
logger -t "【迅雷下载】" "启动程序"
cd "$xunleis_dir/xunlei"
export LD_LIBRARY_PATH="$xunleis_dir/xunlei/lib:/lib:/opt/lib"
"$xunleis_dir/xunlei/portal" >/dev/null 2>&1 &
sleep 2
export LD_LIBRARY_PATH="/lib:/opt/lib"
sleep 5
[ ! -z "$(ps -w | grep "/xunlei/lib/" | grep -v grep )" ] && logger -t "【迅雷下载】" "启动成功"
[ -z "$(ps -w | grep "/xunlei/lib/" | grep -v grep )" ] && logger -t "【迅雷下载】" "启动失败, 注意检查端口是否有冲突,程序是否下载完整,10 秒后自动尝试重新启动" && sleep 10 && { nvram set xunleis_status=00; eval "$scriptfilepath &"; exit 0; }
initopt
eval "$scriptfilepath keep &"
}

initopt () {
optPath=`grep ' /opt ' /proc/mounts | grep tmpfs`
[ ! -z "$optPath" ] && return
if [ -s "/opt/etc/init.d/rc.func" ] ; then
	cp -Hf "$scriptfilepath" "/opt/etc/init.d/$scriptname"
fi

}

case $ACTION in
start)
	xunlei_close
	xunlei_check
	;;
check)
	xunlei_check
	;;
stop)
	xunlei_close
	;;
keep)
	xunlei_check
	xunlei_keep
	;;
*)
	xunlei_check
	;;
esac

