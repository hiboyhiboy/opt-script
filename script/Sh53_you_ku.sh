#!/bin/sh
#copyright by hiboy
source /etc/storage/script/init.sh
nvramshow=`nvram showall | grep youku | awk '{print gensub(/'"'"'/,"'"'"'\"'"'"'\"'"'"'","g",$0);}'| awk '{print gensub(/=/,"='\''",1,$0)"'\'';";}'` && eval $nvramshow

[ -z $youku_enable ] && youku_enable=0 && nvram set youku_enable=0

if [ ! -z "$(echo $scriptfilepath | grep -v "/tmp/script/" | grep you_ku)" ]  && [ ! -s /tmp/script/_you_ku ]; then
	mkdir -p /tmp/script
	ln -sf $scriptfilepath /tmp/script/_you_ku
	chmod 777 /tmp/script/_you_ku
fi

#自定义缓存目录
hc_dir=`nvram get youku_hc_dir`
hc_dir=`echo $hc_dir`
[ -z "$hc_dir" ] && hc_dir="$(df|grep '/media/'|awk '{print$6}'|head -n 1)" && nvram set youku_hc_dir="$hc_dir"
#自定义16位sn：2115663623336666
sn_youku=`nvram get youku_sn`
[ -z $sn_youku ] && sn_youku="2115$(cat /sys/class/net/ra0/address |tr -d ':'|md5sum |tr -dc [0-9]|cut -c 0-12)" && nvram set youku_sn=$sn_youku
#缓存大小，单位MB。
hc=`nvram get youku_hc`
[ -z $hc ] && hc=6000 && nvram set youku_hc=$hc
#速度模式
#"0" "激进模式：赚取收益优先"
#"2" "平衡模式：赚钱上网兼顾"
#"3" "保守模式：上网体验优先"
spd=`nvram get youku_spd`

youku_check () {

A_restart=`nvram get youku_status`
B_restart="$youku_enable$hc_dir$sn_youku$hc$spd"
B_restart=`echo -n "$B_restart" | md5sum | sed s/[[:space:]]//g | sed s/-//g`
if [ "$A_restart" != "$B_restart" ] ; then
	nvram set youku_status=$B_restart
	needed_restart=1
else
	needed_restart=0
fi
if [ "$youku_enable" != "1" ] && [ "$needed_restart" = "1" ] ; then
	[ ! -z "`pidof ikuacc`" ] && logger -t "【路由宝】" "停止 youku" && youku_close
	{ eval $(ps - w | grep "$scriptname" | grep -v grep | awk '{print "kill "$1;}'); exit 0; }
fi
if [ "$youku_enable" = "1" ] ; then
	if [ "$needed_restart" = "1" ] ; then
		youku_close
		youku_start
	else
		port=$(iptables -t filter -L INPUT -v -n --line-numbers | grep dpt:4466 | cut -d " " -f 1 | sort -nr | wc -l)
		if [ "$port" = 0 ] ; then
			logger -t "【路由宝】" " 允许 4466 tcp、udp端口通过防火墙"
			iptables -I INPUT -p tcp --dport 4466 -j ACCEPT &
			iptables -I INPUT -p udp --dport 4466 -j ACCEPT &
		fi
	fi
fi
}

youku_keep () {

logger -t "【路由宝】" "守护进程启动"
sleep 20
optimize
wget -O - 'http://127.0.0.1:8908/peer/limit/network/set?upload_model='"$spd" > /dev/null 2>&1
if [ -s /tmp/script/_opt_script_check ]; then
sed -Ei '/【路由宝】|^$/d' /tmp/script/_opt_script_check
cat >> "/tmp/script/_opt_script_check" <<-OSC
[ -z "\`pidof ikuacc\`" ] || [ ! -s "$hc_dir/youku/ikuacc" ] && nvram set youku_status=00 && logger -t "【路由宝】" "重新启动" && eval "$scriptfilepath &" && sed -Ei '/【路由宝】|^$/d' /tmp/script/_opt_script_check # 【路由宝】
OSC
return
fi
while true; do
	if [ -z "`pidof ikuacc`" ] || [ ! -s "$hc_dir/youku/ikuacc" ] ; then
		logger -t "【路由宝】" "重新启动"
		{ nvram set youku_status=00 && eval "$scriptfilepath &" ; exit 0; }
	fi
sleep 53
done
}

youku_close () {
sed -Ei '/【路由宝】|^$/d' /tmp/script/_opt_script_check
killall ikuacc
killall -9 ikuacc
iptables -D INPUT -p tcp --dport 4466 -j ACCEPT &
iptables -D INPUT -p udp --dport 4466 -j ACCEPT &
eval $(ps - w | grep "$scriptname keep" | grep -v grep | awk '{print "kill "$1;}')
}

youku_start () {

SVC_PATH=/opt/youku/bin/ikuacc
if [ ! -s "$SVC_PATH" ] ; then
	logger -t "【路由宝】" "找不到 $SVC_PATH，安装 opt 程序"
	/tmp/script/_mountopt start
fi
mkdir -p /opt/youku
if [ ! -s "$SVC_PATH" ] ; then
	logger -t "【路由宝】" "找不到 $SVC_PATH 下载程序"
	wgetcurl.sh "/opt/youku.tgz" "$hiboyfile/youku.tgz"
	untar.sh /opt/youku.tgz /opt/youku /opt/youku/bin/ikuacc
fi
chmod -R 777 /opt/youku
if [ ! -s "$SVC_PATH" ] ; then
	logger -t "【路由宝】" "找不到 $SVC_PATH ，需要手动安装 $SVC_PATH"
	logger -t "【路由宝】" "启动失败, 10 秒后自动尝试重新启动" && sleep 10 && { nvram set youku_status=00; eval "$scriptfilepath &"; exit 0; }
fi
echo $hc_dir > $hc_dir/youku.test
if [ ! -s "$hc_dir/youku.test" ] ; then
	ss_opt_x=`nvram get ss_opt_x`
	upanPath=""
	[ "$ss_opt_x" = "3" ] && upanPath="`df -m | grep /dev/mmcb | grep "/media" | awk '{print $NF}' | awk 'NR==1' `"
	[ "$ss_opt_x" = "4" ] && upanPath="`df -m | grep "/dev/sd" | grep "/media" | awk '{print $NF}' | awk 'NR==1' `"
	[ -z "$upanPath" ] && [ "$ss_opt_x" = "1" ] && upanPath="`df -m | grep /dev/mmcb | grep "/media" | awk '{print $NF}' | awk 'NR==1' `"
	[ -z "$upanPath" ] && [ "$ss_opt_x" = "1" ] && upanPath="`df -m | grep "/dev/sd" | grep "/media" | awk '{print $NF}' | awk 'NR==1' `"
	echo "$upanPath"
	if [ -z "$upanPath" ] ; then 
		logger -t "【路由宝】" "未挂载储存设备, 请重新检查配置、目录，10 秒后自动尝试重新启动"
		sleep 10
		nvram set youku_status=00 && eval "$scriptfilepath &"
		exit 0
	fi
	hc_dir="$upanPath" && nvram set youku_hc_dir="$hc_dir"
	B_restart="$youku_enable$hc_dir$sn_youku$hc$spd"
	B_restart=`echo -n "$B_restart" | md5sum | sed s/[[:space:]]//g | sed s/-//g`
	[ "$A_restart" != "$B_restart" ] && nvram set youku_status=$B_restart
fi
path=$hc_dir/youku
mkdir -p $path/meta
mkdir -p $path/data
chmod -R 777 $path/meta
chmod -R 777 $path/data
ln -sf /opt/youku/bin/ikuacc $hc_dir/youku/ikuacc
logger -t "【路由宝】" "开始运行"
cd $hc_dir/youku
export LD_LIBRARY_PATH=/opt/youku/lib:/lib
$hc_dir/youku/ikuacc  --device-serial-number="0000$sn_youku"  --mobile-meta-path="$path/meta" --mobile-data-path="$path/data:$hc"  &
export LD_LIBRARY_PATH=/lib:/opt/lib

logger -t "【路由宝】" " 允许 4466 tcp、udp端口通过防火墙"
iptables -I INPUT -p tcp --dport 4466 -j ACCEPT &
iptables -I INPUT -p udp --dport 4466 -j ACCEPT &
sleep 5
[ ! -z "`pidof ikuacc`" ] && logger -t "【路由宝】" "启动成功"
[ -z "`pidof ikuacc`" ] && logger -t "【路由宝】" "启动失败, 注意检查端口是否有冲突,程序是否下载完整,10 秒后自动尝试重新启动" && sleep 10 && { nvram set youku_status=00; eval "$scriptfilepath &"; exit 0; }
#获取绑定地址
rm /tmp/youku_sn.log
/opt/youku/bin/getykbdlink 0000$sn_youku >/tmp/youku_sn.log
sleep 5
bdlink=$(grep http -r /tmp/youku_sn.log)
nvram set youku_bdlink=$bdlink
logger -t "【路由宝】" "绑定地址："
logger -t "【路由宝】" "$bdlink"
echo "Youku $bdlink"
logger -t "【路由宝】" "SN:$sn_youku"
initopt
eval "$scriptfilepath keep &"
}

optimize()
{
  local data="\
linux-vm-max-cpu-busy-linger=10&\
linux-vm-max-net-upload-k-speed=2000&\
linux-vm-max-net-download-k-speed=2000&\
upload-limit-model=0&\
pcdn-work-mode=0&\
upload-max-uploading-count=2000&\
upload-max-waiting-count=80&\
pcdn-radic-max-download-size-per-hour=8294967296&\
pcdn-radic-max-remove-size-per-hour=8294967296&\
peak-period=07:00-24:00&\
download-disable-in-peak-period=0&\
enable-flash-p2p-hint=1&\
max-cache-buffer-size=24&\
";
  curl --connect-timeout 2 --data "${data}" "http://127.0.0.1:8908/peer/config/xml?m=put"
return 0
}

initopt () {
optPath=`grep ' /opt ' /proc/mounts | grep tmpfs`
[ ! -z "$optPath" ] && return
if [ -s "/opt/etc/init.d/rc.func" ] ; then
	ln -sf "$scriptfilepath" "/opt/etc/init.d/$scriptname"
fi

}

case $ACTION in
start)
	youku_close
	youku_check
	;;
check)
	youku_check
	;;
stop)
	youku_close
	;;
keep)
	youku_check
	youku_keep
	;;
*)
	youku_check
	;;
esac

