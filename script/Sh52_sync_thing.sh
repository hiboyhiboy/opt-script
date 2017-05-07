#!/bin/sh
#copyright by hiboy
source /etc/storage/script/init.sh
syncthing_wan_port=`nvram get syncthing_wan_port`
syncthing_enable=`nvram get syncthing_enable`
[ -z $syncthing_enable ] && syncthing_enable=0 && nvram set syncthing_enable=0
if [ "$syncthing_enable" != "0" ] ; then
nvramshow=`nvram showall | grep syncthing | awk '{print gensub(/'"'"'/,"'"'"'\"'"'"'\"'"'"'","g",$0);}'| awk '{print gensub(/=/,"='\''",1,$0)"'\'';";}'` && eval $nvramshow
fi

if [ ! -z "$(echo $scriptfilepath | grep -v "/tmp/script/" | grep sync_thing)" ]  && [ ! -s /tmp/script/_sync_thing ]; then
	mkdir -p /tmp/script
	ln -sf $scriptfilepath /tmp/script/_sync_thing
	chmod 777 /tmp/script/_sync_thing
fi

upanPath=""
[ -z $syncthing_wan_port ] && syncthing_wan_port=8384 && nvram set syncthing_wan_port=$syncthing_wan_port

syncthing_check () {

A_restart=`nvram get syncthing_status`
B_restart="$syncthing_enable$syncthing_wan$syncthing_wan_port"
B_restart=`echo -n "$B_restart" | md5sum | sed s/[[:space:]]//g | sed s/-//g`
if [ "$A_restart" != "$B_restart" ] ; then
	nvram set syncthing_status=$B_restart
	needed_restart=1
else
	needed_restart=0
fi
if [ "$syncthing_enable" != "1" ] && [ "$needed_restart" = "1" ] ; then
	[ ! -z "`pidof syncthing`" ] && logger -t "【syncthing】" "停止 syncthing" && syncthing_close
	{ eval $(ps -w | grep "$scriptname" | grep -v grep | awk '{print "kill "$1";";}'); exit 0; }
fi
if [ "$syncthing_enable" = "1" ] ; then
	if [ "$needed_restart" = "1" ] ; then
		syncthing_close
		syncthing_start
	else
		[ -z "`pidof syncthing`" ] && nvram set syncthing_status=00 && { eval "$scriptfilepath start &"; exit 0; }
		port=$(iptables -t filter -L INPUT -v -n --line-numbers | grep dpt:22000 | cut -d " " -f 1 | sort -nr | wc -l)
		if [ "$port" = 0 ] ; then
			iptables -t filter -I INPUT -p tcp --dport 22000 -j ACCEPT &
			iptables -t filter -I INPUT -p udp -m multiport --dports 21025,21026,21027 -j ACCEPT &
			if [ "$syncthing_wan" = "1" ] ; then
				logger -t "【syncthing】" "WebGUI 允许 $syncthing_wan_port tcp端口通过防火墙"
				iptables -t filter -I INPUT -p tcp --dport $syncthing_wan_port -j ACCEPT &
			fi
		fi
	fi
fi
}

syncthing_keep () {
logger -t "【syncthing】" "守护进程启动"
if [ -s /tmp/script/_opt_script_check ]; then
sed -Ei '/【syncthing】|^$/d' /tmp/script/_opt_script_check
cat >> "/tmp/script/_opt_script_check" <<-OSC
[ -z "\`pidof syncthing\`" ] || [ ! -s "$syncthing_upanPath/syncthing/syncthing-linux-mipsle/syncthing" ] && nvram set syncthing_status=00 && logger -t "【syncthing】" "重新启动" && eval "$scriptfilepath &" && sed -Ei '/【syncthing】|^$/d' /tmp/script/_opt_script_check # 【syncthing】
OSC
return
fi

while true; do
	if [ -z "`pidof syncthing`" ] || [ ! -s "$syncthing_upanPath/syncthing/syncthing-linux-mipsle/syncthing" ] ; then
		logger -t "【syncthing】" "重新启动"
		{ nvram set syncthing_status=00 && eval "$scriptfilepath &" ; exit 0; }
	fi
sleep 252
done
}

syncthing_close () {

sed -Ei '/【syncthing】|^$/d' /tmp/script/_opt_script_check
iptables -t filter -D INPUT -p tcp --dport 22000 -j ACCEPT &
iptables -t filter -D INPUT -p udp -m multiport --dports 21025,21026,21027 -j ACCEPT &
iptables -t filter -D INPUT -p tcp --dport $syncthing_wan_port -j ACCEPT &
killall syncthing
killall -9 syncthing
iptables -t filter -D INPUT -p tcp --dport 22000 -j ACCEPT &
iptables -t filter -D INPUT -p udp -m multiport --dports 21025,21026,21027 -j ACCEPT &
eval $(ps -w | grep "_sync_thing keep" | grep -v grep | awk '{print "kill "$1";";}')
eval $(ps -w | grep "_sync_thing.sh keep" | grep -v grep | awk '{print "kill "$1";";}')
eval $(ps -w | grep "$scriptname keep" | grep -v grep | awk '{print "kill "$1";";}')
}

syncthing_start () {
ss_opt_x=`nvram get ss_opt_x`
upanPath=""
[ "$ss_opt_x" = "3" ] && upanPath="`df -m | grep /dev/mmcb | grep "/media" | awk '{print $NF}' | awk 'NR==1' `"
[ "$ss_opt_x" = "4" ] && upanPath="`df -m | grep "/dev/sd" | grep "/media" | awk '{print $NF}' | awk 'NR==1' `"
[ -z "$upanPath" ] && [ "$ss_opt_x" = "1" ] && upanPath="`df -m | grep /dev/mmcb | grep "/media" | awk '{print $NF}' | awk 'NR==1' `"
[ -z "$upanPath" ] && [ "$ss_opt_x" = "1" ] && upanPath="`df -m | grep "/dev/sd" | grep "/media" | awk '{print $NF}' | awk 'NR==1' `"
echo "$upanPath"
if [ -z "$upanPath" ] ; then 
	logger -t "【syncthing】" "未挂载储存设备, 请重新检查配置、目录，10 秒后自动尝试重新启动"
	sleep 10
	nvram set syncthing_status=00 && eval "$scriptfilepath &"
	exit 0
fi
SVC_PATH="$upanPath/syncthing/syncthing-linux-mipsle/syncthing"
mkdir -p "$upanPath/syncthing/Downloads"
if [ ! -s "$SVC_PATH" ] && [ -d "$upanPath/syncthing/Downloads" ] ; then
	logger -t "【syncthing】" "找不到 $SVC_PATH ，安装 syncthing 程序"
	logger -t "【syncthing】" "开始下载 syncthing-linux-mipsle.tar.gz"
	wgetcurl.sh "$upanPath/syncthing/Downloads/syncthing-linux-mipsle.tar.gz" "$hiboyfile/syncthing-linux-mipsle.tar.gz" "$hiboyfile2/syncthing-linux-mipsle.tar.gz"
	untar.sh "$upanPath/syncthing/Downloads/syncthing-linux-mipsle.tar.gz" "$upanPath/syncthing"
	chmod -R 777  "$upanPath/syncthing/"
	mv -f "$upanPath/syncthing/syncthing-linux-mipsle"* "$upanPath/syncthing/syncthing-linux-mipsle"
fi
if [ ! -s "$SVC_PATH" ] ; then
	logger -t "【syncthing】" "找不到 $SVC_PATH ，需要手动安装 $SVC_PATH"
	logger -t "【syncthing】" "启动失败, 10 秒后自动尝试重新启动" && sleep 10 && { nvram set syncthing_status=00; eval "$scriptfilepath &"; exit 0; }
fi
logger -t "【syncthing】" "运行 syncthing"


nvram set syncthing_upanPath="$upanPath"
"$upanPath/syncthing/syncthing-linux-mipsle/syncthing" -home "$upanPath/syncthing" -gui-address 0.0.0.0:$syncthing_wan_port &

sleep 2
[ ! -z "$(ps -w | grep "syncthing" | grep -v grep )" ] && logger -t "【syncthing】" "启动成功"
[ -z "$(ps -w | grep "syncthing" | grep -v grep )" ] && logger -t "【syncthing】" "启动失败, 注意检查端口是否有冲突,程序是否下载完整,10 秒后自动尝试重新启动" && sleep 10 && { nvram set syncthing_status=00; eval "$scriptfilepath &"; exit 0; }
initopt

iptables -t filter -I INPUT -p tcp --dport 22000 -j ACCEPT &
iptables -t filter -I INPUT -p udp -m multiport --dports 21025,21026,21027 -j ACCEPT &
if [ "$syncthing_wan" = "1" ] ; then
	logger -t "【syncthing】" "WebGUI 允许 $syncthing_wan_port tcp端口通过防火墙"
	iptables -t filter -I INPUT -p tcp --dport $syncthing_wan_port -j ACCEPT &
fi
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
	syncthing_close
	syncthing_check
	;;
check)
	syncthing_check
	;;
stop)
	syncthing_close
	;;
keep)
	syncthing_check
	syncthing_keep
	;;
*)
	syncthing_check
	;;
esac

