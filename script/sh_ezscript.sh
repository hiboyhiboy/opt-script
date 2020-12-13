#!/bin/sh
#copyright by hiboy
sh_link_sh="sh_link_sh"
source /etc/storage/script/sh_link.sh
source /etc/storage/script/init.sh

# 按钮名称可自定义
ad=`nvram get button_script_1_s`
[ -z "$ad" ] && ad="Adbyby" && nvram set button_script_1_s="Adbyby"
ss=`nvram get button_script_2_s`
[ -z "$ss" ] && ss="SS" && nvram set button_script_2_s="SS"

ipt2socks_enable=`nvram get app_104`
[ -z $ipt2socks_enable ] && ipt2socks_enable=0 && nvram set app_104=0
transocks_enable=`nvram get app_27`
[ -z $transocks_enable ] && transocks_enable=0 && nvram set app_27=0
[ "$ipt2socks_enable" != "0" ] && [ "$ss" != "2socks" ] && ss="2socks" && nvram set button_script_2_s="2socks"
if [ "$ss" != "2socks" ]  ; then
[ "$transocks_enable" != "0" ] && [ "$ss" != "Tsocks" ] && ss="Tsocks" && nvram set button_script_2_s="Tsocks"
else
[ "$ipt2socks_enable" == "0" ] && [ "$transocks_enable" != "0" ] && [ "$ss" != "Tsocks" ] && ss="Tsocks" && nvram set button_script_2_s="Tsocks"
fi

clash_enable=`nvram get app_88`
[ -z $clash_enable ] && clash_enable=0 && nvram set clash_enable=0
clash_follow=`nvram get app_92`
[ -z $clash_follow ] && clash_follow=0 && nvram set clash_follow=0
[ "$clash_enable" != "0" ] && [ "$clash_follow" != 0 ] && [ "$ss" != "clash" ] && ss="clash" && nvram set button_script_2_s="clash"

v2ray_enable=`nvram get v2ray_enable`
[ -z $v2ray_enable ] && v2ray_enable=0 && nvram set v2ray_enable=0
v2ray_follow=`nvram get v2ray_follow`
[ -z $v2ray_follow ] && v2ray_follow=0 && nvram set v2ray_follow=0
[ "$v2ray_enable" != "0" ] && [ "$v2ray_follow" != 0 ] && [ "$ss" != "V2Ray" ] && ss="V2Ray" && nvram set button_script_2_s="V2Ray"

ss_enable=`nvram get ss_enable`
[ -z $ss_enable ] && ss_enable=0 && nvram set ss_enable=0
if [ "$ss_enable" != "0" ]  ; then
	ss_mode_x=`nvram get ss_mode_x` #ss模式，0 为chnroute, 1 为 gfwlist, 2 为全局, 3为ss-local 建立本地 SOCKS 代理
	[ -z $ss_mode_x ] && ss_mode_x=0 && nvram set ss_mode_x=$ss_mode_x
	if [ "$ss_mode_x" != 3 ]  ; then
		ss_working_port=`nvram get ss_working_port`
		[ $ss_working_port == 1090 ] && ss_info="SS"
		[ ${ss_info:=SS} ] && [ "$ss" != "$ss_info" ] && { ss="$ss_info" ; nvram set button_script_2_s="$ss"; }
	fi
	if [ "$ss_mode_x" = 3 ]  ; then
		[ "$ss" != "SS" ] && [ "$ss" != "V2Ray" ] && [ "$ss" != "clash" ] && [ "$ss" != "Tsocks" ] && [ "$ss" != "2socks" ] && { ss="SS" ; nvram set button_script_2_s="$ss"; }
	fi
fi

button_1 () {

# 按钮①子程序 名称可自定义
button1=`nvram get button_script_1_s`
logger -t "【按钮①】" "$button1"
apply=`nvram get button_script_1`
# apply=1 状态 1开 0关



if [ "$ad" = "ADM" ] ; then
if [ ! -s /tmp/script/_ad_m ] ; then
	logger -t "【按钮①】" "请稍等 ADM 脚本初始化！"
	return
fi
port=$(iptables -t nat -L | grep 'ports 18309' | wc -l)
PIDS=$(ps -w | grep "/tmp/7620adm/adm" | grep -v "grep" | wc -l)
if [ "$apply" = 0 ] && [ "$port" = 0 ] && [ "$PIDS" = 0 ] ; then
	logger -t "【按钮①】" "添加转发规则, 启动 $ad"
	nvram set adm_status=0
	nvram set adm_enable=1
	nvram commit
	/tmp/script/_ad_m &
fi
if [ "$apply" = 1 ] && [ "$port" -ge 1 ] || [ "$PIDS" != 0 ] ; then
	logger -t "【按钮①】" "关闭转发规则, 关闭 $ad"
	nvram set adm_status=1
	nvram set adm_enable=0
	nvram commit
	/tmp/script/_ad_m stop &
	nvram set button_script_1="0"
fi
fi

if [ "$ad" = "KP" ] ; then
if [ ! -s /tmp/script/_kool_proxy ] ; then
	logger -t "【按钮①】" "请稍等 KP 脚本初始化！"
	return
fi
port=$(iptables -t nat -L | grep 'ports 3000' | wc -l)
PIDS=$(ps -w | grep "/tmp/7620koolproxy/koolproxy" | grep -v "grep" | wc -l)
if [ "$apply" = 0 ] && [ "$port" = 0 ] && [ "$PIDS" = 0 ] ; then
	logger -t "【按钮①】" "添加转发规则, 启动 $ad"
	nvram set koolproxy_status=0
	nvram set koolproxy_enable=1
	nvram commit
	/tmp/script/_kool_proxy &
fi
if [ "$apply" = 1 ] && [ "$port" -ge 1 ] || [ "$PIDS" != 0 ] ; then
	logger -t "【按钮①】" "关闭转发规则, 关闭 $ad"
	nvram set koolproxy_status=1
	nvram set koolproxy_enable=0
	nvram commit
	/tmp/script/_kool_proxy &
	nvram set button_script_1="0"
fi
fi

if [ "$ad" = "Adbyby" ] ; then
if [ ! -s /tmp/script/_ad_byby ] ; then
	logger -t "【按钮①】" "请稍等 Adbyby 脚本初始化！"
	return
fi
port=$(iptables -t nat -L | grep 'ports 8118' | wc -l)
PIDS=$(ps -w | grep "/tmp/bin/adbyby" | grep -v "grep" | grep -v "adbybyupdate.sh" | grep -v "adbybyfirst.sh" | wc -l)
if [ "$apply" = 0 ] && [ "$port" = 0 ] && [ "$PIDS" = 0 ] ; then
	logger -t "【按钮①】" "添加转发规则, 启动 $ad"
	nvram set adbyby_status=0
	nvram set adbyby_enable=1
	nvram commit
	/tmp/script/_ad_byby &
fi
if [ "$apply" = 1 ] && [ "$port" -ge 1 ] || [ "$PIDS" != 0 ] ; then
	logger -t "【按钮①】" "关闭转发规则, 关闭 $ad"
	nvram set adbyby_status=1
	nvram set adbyby_enable=0
	nvram commit
	/tmp/script/_ad_byby  &
	nvram set button_script_1="0"
fi
fi

button_3 &

}

button_2 () {

# 按钮②子程序
button2=`nvram get button_script_2_s`
logger -t "【按钮②】" "$button2"
apply=`nvram get button_script_2`

if [ "$ss" = "SS" ] ; then
if [ ! -s /tmp/script/_ss ] ; then
	logger -t "【按钮②】" "请稍等 SS 脚本初始化！"
	return
fi
# 按钮②状态0 执行以下命令
if [ "$apply" = 0 ] ; then
	logger -t "【按钮②】" "开启 shadowsocks 进程"
	nvram set ss_status=0
	nvram set ss_enable=1
	nvram commit
	/tmp/script/_ss &
	sleep 1
	nvram set button_script_2="1"
fi
# 按钮②状态1时执行以下命令
if [ "$apply" = 1 ] ; then
	logger -t "【按钮②】" "关闭 shadowsocks 进程"
	nvram set ss_status=1
	nvram set ss_enable=0
	nvram commit
	/tmp/script/_ss &
	sleep 1
	nvram set button_script_2="0"
fi
fi

if [ "$ss" = "V2Ray" ] ; then
if [ ! -s /tmp/script/_v2ray ] ; then
	logger -t "【按钮②】" "请稍等 v2ray 脚本初始化！"
	return
fi
# 按钮②状态0 执行以下命令
if [ "$apply" = 0 ] ; then
	#nvram set button_script_2="1"
	logger -t "【按钮②】" "开启 v2ray 进程"
	nvram set v2ray_status=0
	nvram set v2ray_enable=1
	nvram commit
	/tmp/script/_v2ray &
	sleep 1
	nvram set button_script_2="1"
fi
# 按钮②状态1时执行以下命令
if [ "$apply" = 1 ] ; then
	logger -t "【按钮②】" "关闭 v2ray 进程"
	nvram set v2ray_status=1
	nvram set v2ray_enable=0
	nvram commit
	/tmp/script/_v2ray &
	sleep 1
	nvram set button_script_2="0"
fi
fi

if [ "$ss" = "2socks" ] ; then
if [ ! -s /tmp/script/_app20 ] ; then
	logger -t "【按钮②】" "请稍等 ipt2socks 脚本初始化！"
	return
fi
# 按钮②状态0 执行以下命令
if [ "$apply" = 0 ] ; then
	#nvram set button_script_2="1"
	logger -t "【按钮②】" "开启 ipt2socks 进程"
	nvram set ipt2socks_status=0
	nvram set app_104=1
	nvram set app_27=1
	nvram commit
	/tmp/script/_app20 &
	sleep 1
	nvram set button_script_2="1"
fi
# 按钮②状态1时执行以下命令
if [ "$apply" = 1 ] ; then
	logger -t "【按钮②】" "关闭 ipt2socks 进程"
	nvram set ipt2socks_status=1
	nvram set app_104=0
	nvram set app_27=0
	nvram commit
	/tmp/script/_app20 &
	sleep 1
	nvram set button_script_2="0"
fi
fi

if [ "$ss" = "Tsocks" ] ; then
if [ ! -s /tmp/script/_app10 ] ; then
	logger -t "【按钮②】" "请稍等 transocks 脚本初始化！"
	return
fi
# 按钮②状态0 执行以下命令
if [ "$apply" = 0 ] ; then
	#nvram set button_script_2="1"
	logger -t "【按钮②】" "开启 transocks 进程"
	nvram set transocks_status=0
	nvram set app_27=1
	nvram commit
	/tmp/script/_app10 &
	sleep 1
	nvram set button_script_2="1"
fi
# 按钮②状态1时执行以下命令
if [ "$apply" = 1 ] ; then
	logger -t "【按钮②】" "关闭 transocks 进程"
	nvram set transocks_status=1
	nvram set app_27=0
	nvram commit
	/tmp/script/_app10 &
	sleep 1
	nvram set button_script_2="0"
fi
fi

if [ "$ss" = "clash" ] ; then
if [ ! -s /tmp/script/_app10 ] ; then
	logger -t "【按钮②】" "请稍等 clash 脚本初始化！"
	return
fi
# 按钮②状态0 执行以下命令
if [ "$apply" = 0 ] ; then
	#nvram set button_script_2="1"
	logger -t "【按钮②】" "开启 clash 进程"
	nvram set clash_status=0
	nvram set app_88=1
	nvram commit
	/tmp/script/_app18 &
	sleep 1
	nvram set button_script_2="1"
fi
# 按钮②状态1时执行以下命令
if [ "$apply" = 1 ] ; then
	logger -t "【按钮②】" "关闭 clash 进程"
	nvram set clash_status=1
	nvram set app_88=0
	nvram commit
	/tmp/script/_app18 &
	sleep 1
	nvram set button_script_2="0"
fi
fi

button_3 &

}

button_3 () {

sleep 1
# 按钮状态检测子程序
port=$(iptables -t nat -L | grep 'AD_BYBY_to' | wc -l)
if [ "$port" -ge 1 ] ; then
	nvram set button_script_1="1"
else
	nvram set button_script_1="0"
fi
PROCESS=""
if [ "$ss" = "SS" ] ; then
	PROCESS=$(ps -w | grep "ss-redir" | grep -v "grep")
elif [ "$ss" = "SS" ] ; then
	PROCESS=$(ps -w | grep "ss-local" | grep -v "grep")
elif [ "$ss" = "V2Ray" ] ; then
	PROCESS=$(pidof v2ray)
elif [ "$ss" = "Tsocks" ] ; then
	PROCESS=$(pidof transocks)
elif [ "$ss" = "2socks" ] ; then
	PROCESS=$(pidof ipt2socks)
elif [ "$ss" = "clash" ] ; then
	PROCESS=$(pidof clash)
fi
if [ -z "$PROCESS" ] ; then
	nvram set button_script_2="0"
else
	nvram set button_script_2="1"
fi

}

cleanss () {

# 重置 SS IP 规则文件并重启 SS
/tmp/script/_ss update_optss &
}

timesystem () {

# 手动设置时间
sleep 1
time_system=`nvram get time_system`
if [ ! -z "$time_system" ] ; then
date -s "$time_system"
nvram set time_system=""
fi
}

serverchan () {

# 在线发送微信推送
serverchan_sckey=`nvram get serverchan_sckey`
if [ ! -z "$serverchan_sckey" ] ; then
serverchan_text=`nvram get serverchan_text`
serverchan_desp=`nvram get serverchan_desp`
if [ ! -z "$serverchan_text" ] ; then
curltest=`which curl`
if [ -z "$curltest" ] ; then
/etc/storage/script/Sh01_mountopt.sh optwget
fi
curltest=`which curl`
if [ -z "$curltest" ] ; then
	logger -t "【微信推送】" "未找到 curl 程序，停止 微信推送。需要手动安装 opt 后输入[opkg update; opkg install curl]安装"
	nvram set serverchan_text=""
	nvram set serverchan_desp=""
fi
if [ ! -z "$serverchan_text" ] ; then
curl -s "http://sc.ftqq.com/$serverchan_sckey.send?text=$serverchan_text" -d "&desp=$serverchan_desp" 
logger -t "【微信推送】" "消息标题:$serverchan_text"
logger -t "【微信推送】" "消息内容:$serverchan_desp"
nvram set serverchan_text=""
nvram set serverchan_desp=""
fi
fi
fi
}

serverchan_clean () {

# 清空以往接入设备名称
touch /etc/storage/hostname.txt
logger -t "【微信推送】" "清空以往接入设备名称：/etc/storage/hostname.txt"
rm -f /etc/storage/hostname.txt
echo "接入设备名称" > /etc/storage/hostname.txt
}

relnmp () {
logger -t "【按钮】" "重启 LNMP 服务"
nvram set lnmp_status="relnmp"
/etc/storage/crontabs_script.sh &
}

mkfs () {

# mkfs.ext4快速格式化
logger -t "【mkfs.ext4】" "快速格式化"
logger -t "【mkfs.ext4】" "$2"
logger -t "【mkfs.ext4】" "$3"
{
df | grep $3 |  awk -F' ' '{print $NF}' | while read line  
do	
	[ ! -z $line ] && umount $line 2>/dev/null
	[ ! -z $line ] && umount $line -l 2>/dev/null
done
sleep 2
echo `fdisk -l | grep $3 | grep -v swap | grep -v Disk | cut -d' ' -f1` | while read line
do	
	logger -t "【mkfs.ext4】" "正在格式化 $line"
	mkfs.ext4 -i 16384 $line
done	
logger -t "【mkfs.ext4】" "格式化完成."
} &
}

jq_check () {

if [[ "$(jq -h 2>&1 | wc -l)" -lt 2 ]] ; then
	logger -t "【jq_check】" "找不到 jq，安装 opt 程序"
	/etc/storage/script/Sh01_mountopt.sh start
if [[ "$(jq -h 2>&1 | wc -l)" -lt 2 ]] ; then
	for h_i in $(seq 1 2) ; do
	wgetcurl_file /opt/bin/jq "$hiboyfile/jq" "$hiboyfile2/jq"
	[[ "$(jq -h 2>&1 | wc -l)" -lt 2 ]] && rm -rf /opt/bin/jq
	done
if [[ "$(jq -h 2>&1 | wc -l)" -lt 2 ]] ; then
	logger -t "【jq_check】" "找不到 jq，安装 opt 程序"
	rm -f /opt/bin/jq
	/etc/storage/script/Sh01_mountopt.sh optwget
if [[ "$(jq -h 2>&1 | wc -l)" -lt 2 ]] ; then
	#opkg update
	#opkg install jq
if [[ "$(jq -h 2>&1 | wc -l)" -lt 2 ]] ; then
	logger -t "【jq_check】" "找不到 jq，需要手动安装 opt 后输入[opkg update; opkg install jq]安装"
	return 1
fi
fi
fi
fi
fi
}


ss_link_matching(){

check_link "X_check_app_24"
[ ! -f /www/link/link.js ] && logger -t "【自动选用节点】" "错误！找不到 /www/link/link.js" && return 1
kill_ps "Sh15_ss.sh"
if [[ "$(jq -h 2>&1 | wc -l)" -lt 2 ]] ; then
jq_check
if [[ "$(jq -h 2>&1 | wc -l)" -lt 2 ]] ; then
	logger -t "【自动选用节点】" "错误！找不到 jq 程序"
	return 1
fi
fi
# 排序节点
mkdir -p /tmp/link_matching
if [ ! -f /tmp/link_matching/link_matching.txt ] || [ ! -s /tmp/link_matching/link_matching.txt ] ; then
match="$(nvram get app_95)"
[ "$match" == "*" ] && match="."
mismatch="$(nvram get app_96)"

cat /www/link/link.js > /tmp/link_matching/0.txt
echo -n "" > /tmp/link_matching/1.txt
[ -s /tmp/link/link.txt ] && cat /tmp/link/link.txt >> /tmp/link_matching/0.txt
sed -Ei "/^var ACL2List|^\[\]\]/d" /tmp/link_matching/0.txt
while read line
do
if [ ! -z "$(echo -n "$line" | grep "🔐📐")" ] ; then
	# 解码base64
	line0="$(echo -n "$line" | awk -F "🔐📐" '{print $2}' | awk -F "📐🔐" '{print $1}')"
	line0="$(base64decode 🔐📐"$line0"📐🔐)"'",'
else
	line0="$line"
fi
[ ! -z "$mismatch" ] && line3="$(echo "$line0" | grep -E .+'",' | cut -d',' -f1 | grep -E "$match" | grep -v -E "$mismatch" | grep -v -E "剩余流量|过期时间")"
[ -z "$mismatch" ] && line3="$(echo "$line0" | grep -E .+'",' | cut -d',' -f1 | grep -E "$match" | grep -v -E "剩余流量|过期时间")"
[ -z "$match" ] && line3="line3"
line4="line4" ; line2="" ; 
if [ ! -z "$line3" ] ; then
line2_server="$(echo "$line" | sed -e "s@\ @@g" | awk -F '","' '{ print($2) }')"
[ ! -z "$line2_server" ] && line2="$(cat /etc/storage/link/ping.js | sed -e "s@\ @@g" | awk -F "$line2_server=" '{ print($2) }' | awk -F "🔗" '{ print($1) }')"
[ -z "$line2" ] && line2="$(echo "$line" | grep -E -o \"btn-success.+\ ms\", | cut -d',' -f2 | grep -E -o \".+\" | grep -Eo [0-9]+ )"
[ -z "$line2" ] && line2="$(echo "$line" | grep -E -o \"btn-warning.+\ ms\", | cut -d',' -f2 | grep -E -o \".+\" | grep -Eo [0-9]+ )"
[ -z "$line2" ] && line2="$(echo "$line" | grep -E -o \"btn-danger.+\ ms\", | cut -d',' -f2 | grep -E -o \".+\" | grep -Eo [0-9]+ )"
[ ! -z "$line2" ] && line2="00000""$line2" && echo -n "${line2:0-4}" >> /tmp/link_matching/1.txt && line4=""
[ ! -z "$line4" ] && line2="0000" && echo -n "$line2" >> /tmp/link_matching/1.txt
echo -n "$line" >> /tmp/link_matching/1.txt
echo "" >> /tmp/link_matching/1.txt
fi
done < /tmp/link_matching/0.txt
cat /tmp/link_matching/1.txt | sort  | grep -v "^$" > /tmp/link_matching/2.txt
echo -n "" > /tmp/link_matching/link_matching.txt
while read line
do
line="$(echo $line | sed -e 's/],/]/g' )"
echo ${line:4} >> /tmp/link_matching/link_matching.txt
done < /tmp/link_matching/2.txt
rm -f /tmp/link_matching/?.txt
logger -t "【自动选用节点】" "重新生成自动选用节点列表： /tmp/link_matching/link_matching.txt"
fi
# 选用节点
if [ -z "$(cat /tmp/link_matching/link_matching.txt | grep -v 已经自动选用节点)" ] ; then
sed -e 's/已经自动选用节点//g' -i /tmp/link_matching/link_matching.txt
fi
i_matching=1
while read line
do
line2="$(echo "$line" | grep -v "已经自动选用节点" )"
if [ ! -z "$line2" ] ; then
app_97="$(echo $line| jq --compact-output --raw-output 'getpath([0])')"
app_97="$(base64decode "$app_97")"
ss_server="$(echo $line| jq --compact-output --raw-output 'getpath([1])')"
ss_server_port="$(echo $line| jq --compact-output --raw-output 'getpath([2])')"
ss_key="$(echo $line| jq --compact-output --raw-output 'getpath([3])')"
ss_key="$(base64decode "$ss_key")"
ss_method="$(echo $line| jq --compact-output --raw-output 'getpath([4])')"
ss_usage="$(echo $line| jq --compact-output --raw-output 'getpath([7])')"
ss_usage="$(base64decode "$ss_usage")"
ss_type_tmp="$(echo $line| jq --compact-output --raw-output 'getpath([8])')"
logger -t "【自动选用节点】" "已经自动选用节点： [$ss_type_tmp]$app_97"
[ -z "$ss_server" ] && logger -t "【自动选用节点】" "错误！！！获取 ss_server 数据为空 " && break
[ -z "$ss_server_port" ] && logger -t "【自动选用节点】" "错误！！！获取 ss_server_port 数据为空 " && break
[ -z "$ss_key" ] && logger -t "【自动选用节点】" "错误！！！获取 ss_key 数据为空 " && break
[ -z "$ss_method" ] && logger -t "【自动选用节点】" "错误！！！获取 ss_method 数据为空 " && break
#[ -z "$ss_usage" ] && logger -t "【自动选用节点】" "错误！！！获取 ss_usage 数据为空 " && break
nvram set app_97="[$ss_type_tmp]$app_97"
sed -i $i_matching's/^/已经自动选用节点/' /tmp/link_matching/link_matching.txt
[ "$ss_type_tmp" == "ssr" ] && nvram set ss_type="1"
[ "$ss_type_tmp" == "ss" ] && nvram set ss_type="0"
nvram set ss_server="$ss_server"
nvram set ss_server_port="$ss_server_port"
nvram set ss_key="$ss_key"
nvram set ss_method="$ss_method"
nvram set ss_usage="$ss_usage"
# 重启SS
[ "$ss_enable" == "0" ] && return
eval "/etc/storage/script/Sh15_ss.sh &"
exit
break
fi
i_matching=`expr $i_matching + 1`
done < /tmp/link_matching/link_matching.txt

}

allping () {

check_link "X_check_app_24"
[ ! -f /www/link/link.js ] && logger -t "【ping】" "错误！找不到 /www/link/link.js" && return 1
if [[ "$(tcping -h 2>&1 | wc -l)" -lt 5 ]] ; then
for h_i in $(seq 1 2) ; do
[[ "$(tcping -h 2>&1 | wc -l)" -lt 5 ]] && rm -rf /opt/bin/tcping
wgetcurl_file /opt/bin/tcping "$hiboyfile/tcping" "$hiboyfile2/tcping"
done
fi
[[ "$(tcping -h 2>&1 | wc -l)" -lt 5 ]] && rm -rf /opt/bin/tcping
[[ "$(tcping -h 2>&1 | wc -l)" -gt 5 ]] && logger -t "【ping】" "开始 ping" || logger -t "【ping】" "开始 tcping"
mkdir -p /tmp/allping
rm -f /tmp/allping/?.txt
rm -f /tmp/ping_server_error.txt
touch /tmp/ping_server_error.txt
rm -f /tmp/allping.js
touch /tmp/allping.js
rm -f /tmp/link_matching/link_matching.txt
i_x_ping=2
ilox="$(cat /www/link/link.js | grep -v '\[\]\]'  | grep -v "ACL2List = " |wc -l)"
[ "$ilox" == "0" ] && [ ! -s /etc/storage/app_24.sh ] && logger -t "【ping】" "错误！节点列表为空" && return
if [ "$ilox" != "0" ] ; then
app_100="$(nvram get app_100)"
if [ "$app_100" == "1" ] ; then
logger -t "【ping】" "默认排序节点"
else
logger -t "【ping】" "优选排序节点"
app_100="0"
fi
while read line
do
if [ -z "$(echo "$line" | grep "ACL2List = ")" ] && [ -z "$(echo "$line" | grep '\[\]\]')" ] ; then
if [ ! -z "$line" ] ; then
echo "$line" > /tmp/allping/$i_x_ping
fi
i_x_ping=`expr $i_x_ping + 1`
fi
done < /www/link/link.js
while [ "$(ls /tmp/allping | head -1)" != "" ];
do
x_ping_x &
usleep 100000
i_ping="$(cat /tmp/allping.js | grep -v "^$" |wc -l)"
done
i_x_ping=1
while [ "$i_ping" != "$ilox" ];
do
sleep 1
i_ping="$(cat /tmp/allping.js | grep -v "^$" |wc -l)"
i_x_ping=`expr $i_x_ping + 1`
if [ "$i_x_ping" -gt 30 ] ; then
logger -t "【ping】" "刷新 ping 失败！超时 30 秒！ 请重新按【ping】按钮再次尝试。"
return
fi
done
# 排序节点
rm -f /tmp/allping/?.txt
cat /tmp/allping.js | sort | grep -v "^$" > /tmp/allping/0.txt
echo "var ACL2List = [[], " > /tmp/allping/1.txt
while read line
do
echo ${line:4} >> /tmp/allping/1.txt
done < /tmp/allping/0.txt
echo "[]]" >> /tmp/allping/1.txt
cp -f /tmp/allping/1.txt /www/link/link.js
rm -f /tmp/allping/?.txt /tmp/allping.js
fi
allping_app_24

logger -t "【ping】" "完成 ping 请按【F5】刷新 web 查看 ping"
app_99="$(nvram get app_99)"
if [ "$app_99" == 1 ] ; then
logger -t "【ping】" "服务器订阅：更新后自动选用节点 /tmp/link_matching/link_matching.txt"
/etc/storage/script/sh_ezscript.sh ss_link_matching & 
fi
}

allping_app_24 () {

[ ! -s /etc/storage/app_24.sh ] && return 1
mkdir -p /tmp/allping
mkdir -p /tmp/link
rm -f /tmp/link/ping.txt 
touch /tmp/link/ping.txt
rm -f /tmp/allping/?.txt
rm -f /tmp/ping_server_error.txt
touch /tmp/ping_server_error.txt
rm -f /tmp/allping.js
touch /tmp/allping.js
rm -f /tmp/link_matching/link_matching.txt
i_x_ping=2
ilox="$(cat /tmp/link/link.txt | grep -v '\[\]\]' | grep -v "ACL2List = " |wc -l)"
[ "$ilox" == "0" ] && return
echo -n 'var ping_data = "' >> /tmp/link/ping.txt
while read line
do
if [ -z "$(echo "$line" | grep "ACL2List = ")" ] && [ -z "$(echo "$line" | grep '\[\]\]')" ] ; then
if [ ! -z "$line" ] ; then
echo "$line" > /tmp/allping/$i_x_ping
fi
i_x_ping=`expr $i_x_ping + 1`
fi
done < /tmp/link/link.txt
while [ "$(ls /tmp/allping | head -1)" != "" ];
do
x_ping_x "1" &
usleep 100000
i_ping="$(cat /tmp/allping.js | grep -v "^$" |wc -l)"
done
i_x_ping=1
while [ "$i_ping" != "$ilox" ];
do
sleep 1
i_ping="$(cat /tmp/allping.js | grep -v "^$" |wc -l)"
i_x_ping=`expr $i_x_ping + 1`
if [ "$i_x_ping" -gt 30 ] ; then
logger -t "【ping】" "刷新 ping 失败！超时 30 秒！ 请重新按【ping】按钮再次尝试。"
return
fi
done
echo -n '"' >> /tmp/link/ping.txt
# 排序节点
rm -f /tmp/allping/?.txt
cat /tmp/allping.js | sort | grep -v "^$" > /tmp/allping/0.txt
echo "var ACL2List = [[], " > /tmp/allping/1.txt
while read line
do
echo ${line:4} >> /tmp/allping/1.txt
done < /tmp/allping/0.txt
echo "[]]" >> /tmp/allping/1.txt
cp -f /tmp/allping/1.txt /tmp/link/link.txt
rm -f /www/link/ping.js
cp -f /tmp/link/ping.txt /www/link/ping.js
rm -f /tmp/allping/?.txt /tmp/allping.js

}


base64decode () {
# 解码
if [ ! -z "$(echo -n "$1" | grep "🔐📐")" ] ; then
	# 转换base64
	base64decode_tmp="$(echo -n "$1" | sed -e "s/🔗\|🔐📐\|📐🔐//g" | sed -e "s/_/\//g" | sed -e "s/-/\+/g" | sed 's/$/&==/g' | base64 -d | sed ":a;N;s/\n//g;ta")"
	if [ ! -z "$(echo -n "$1" | grep "🔗")" ] ; then
		echo -n "🔗$base64decode_tmp"
	else
		echo -n "$base64decode_tmp"
	fi
else
	echo -n "$1"
fi
}

x_ping_x () {
	
mk_ping_txt="$1"
ping_txt_list="$(ls /tmp/allping | head -1)"
if [ ! -z "$ping_txt_list" ] ; then
ping_list="$(cat /tmp/allping/$ping_txt_list)"
rm -f /tmp/allping/$ping_txt_list
ss_server_x=$(echo $ping_list | cut -d',' -f2 | sed -e "s@"'"'"\| \|"'\['"@@g")
if [ ! -z "$ss_server_x" ] ; then
ss_name_x="$(echo $ping_list | cut -d',' -f1 | sed -e "s@"'"'"\|"'\['"@@g")"
ss_name_x="$(base64decode "$ss_name_x")"
ss_port_x="$(echo $ping_list | cut -d',' -f3 | sed -e "s@"'"'"\|"'\['"@@g")"
tcping_time="0"
if [[ "$(tcping -h 2>&1 | wc -l)" -gt 5 ]] ; then
if [ ! -z "$(echo "$ss_name_x" | grep -Eo "剩余流量|过期时间")" ] || [ ! -z "$(echo "$ss_server_x" | grep -Eo "google.com|8.8.8.8")" ] ; then
tcping_time="0"
else
resolveip=`ping -4 -n -q -c1 -w1 -W1 $ss_server_x | head -n1 | sed -r 's/\(|\)/|/g' | awk -F'|' '{print $2}'`
if [ ! -z "$resolveip" ] ; then
ipset -! add proxyaddr $resolveip
ipset -! add ad_spec_dst_sp $resolveip
tcping_text=`tcping -p $ss_port_x -c 1 $resolveip`
tcping_time=`echo $tcping_text | awk -F '/' '{print $4}'| awk -F '.' '{print $1}'`
[[ "$tcping_time" -gt 2 ]] || tcping_time="0"
[[ "$tcping_time" -lt 2 ]] && tcping_time="0"
fi
fi
[ "$tcping_time" == "0" ] && ping_time="" ||  ping_time="$tcping_time"
fi
if [ "$tcping_time" == "0" ] ; then
if [ ! -z "$(cat /tmp/ping_server_error.txt | grep "error_""$ss_server_x""_error")" ] ; then
ping_text=""
else
if [ ! -z "$(echo "$ss_name_x" | grep -Eo "剩余流量|过期时间")" ] || [ ! -z "$(echo "$ss_server_x" | grep -Eo "google.com|8.8.8.8")" ] ; then
ping_text=""
else
ping_text=`ping -4 $ss_server_x -w 3 -W 3 -q`
fi
fi
ping_time=`echo $ping_text | awk -F '/' '{print $4}'| awk -F '.' '{print $1}'`
fi
#ping_loss=`echo $ping_text | awk -F ', ' '{print $3}' | awk '{print $1}'`
i2log="$(expr $(cat /tmp/allping.js | grep -v "^$" |wc -l) + 1)"
ilog=""
[ "$i2log" -gt 0 ] && [ "$ilox" -gt 0 ] && ilog="$(echo "$i2log,$ilox" | awk -F ',' '{printf("%3.0f\n", $1/$2*100)}')"
[ "$ilog" == "" ] && ilog="  0"
[ "$ilog" -gt 100 ] && ilog=100
if [ ! -z "$ping_time" ] ; then
	echo "ping$ilog%：$ping_time ms ✔️ $ss_server_x"
	[ "$tcping_time" == "0" ] && logger -t "【  ping$ilog%】" "$ping_time ms ✔️ $ss_server_x $ss_name_x"
	[ "$tcping_time" != "0" ] && logger -t "【tcping$ilog%】" "$ping_time ms ✔️ $ss_server_x $ss_name_x"
	[ "$ping_time" -le 250 ] && ping_list_btn="btn-success"
	[ "$ping_time" -gt 250 ] && [ "$ping_time" -le 500 ] && ping_list_btn="btn-warning"
	[ "$ping_time" -gt 500 ] && ping_list_btn="btn-danger"
	if [ "$app_100" == "1" ] ; then
	ping_time2="00000""$ping_txt_list"
	ping_time2="${ping_time2:0-4}"
	else
	ping_time2="00000""$ping_time"
	ping_time2="${ping_time2:0-4}"
	fi
else
	ping_list_btn="btn-danger"
	echo "ping$ilog%：>1000 ms ❌ $ss_server_x"
	logger -t "【  ping$ilog%】" ">1000 ms ❌ $ss_server_x $ss_name_x"
	ping_time=">1000"
	if [ "$app_100" == "1" ] ; then
	ping_time2="00000""$ping_txt_list"
	ping_time2="${ping_time2:0-4}"
	else
	ping_time2="1000"
	fi
	echo "error_""$ss_server_x""_error" >> /tmp/ping_server_error.txt
fi
[ "$mk_ping_txt" == "1" ] && [ -z "$(cat /tmp/link/ping.txt | grep "🔗$ss_server_x=")" ] && echo -n "🔗$ss_server_x=$ping_time🔗" >> /tmp/link/ping.txt
if [ ! -z "$(echo $ping_list | grep -E -o \"btn-.+\ ms\",)" ] ; then
	ping_list=$(echo $ping_list | sed "s@"'"'"$(echo $ping_list | grep -E -o \"btn-.+\ ms\", | cut -d',' -f2 | grep -E -o \".+\" | sed -e "s@"'"'"@@g")"'"'"@"'"'"$ping_time ms"'"'"@g")
	ping_list=$(echo $ping_list | sed "s@"'"'"$(echo $ping_list | grep -E -o \"btn-.+\ ms\", | cut -d',' -f1 | grep -E -o \".+\" | sed -e "s@"'"'"@@g")"'"'"@"'"'"$ping_list_btn"'"'"@g")
else
	ping_list=$(echo $ping_list | sed "s@"'", "", "", "'"@"'", "'"$ping_list_btn"'", "'"$ping_time ms"'", "'"@g")
fi
fi
if [ ! -z "$ping_list" ] ; then
ping_list="$ping_time2""$ping_list"
echo "$ping_list" >> /tmp/allping.js
fi
fi
}


reszUID () {
killall oraynewph oraysl
killall -9 oraynewph oraysl
rm -f /tmp/oraysl.status /etc/PhMain.ini /etc/init.status /etc/storage/PhMain.ini /etc/storage/init.status
ln -sf "/etc/storage/PhMain.ini" "/etc/PhMain.ini"
ln -sf "/etc/storage/init.status" "/etc/init.status"
logger -t "【花生壳内网版】" "重置花生壳绑定, 重新启动"
nvram set phddns_sn=""
nvram set phddns_st=""
nvram set phddns_szUID=""
/tmp/script/_orayd &
}

case "$1" in
1)
  button_1
  ;;
2)
  button_2
  ;;
3)
  button_3
  ;;
cleanss)
  cleanss
  ;;
updatess)
  /tmp/script/_ss updatess &
  ;;
timesystem)
  timesystem
  ;;
serverchan)
  serverchan
  ;;
serverchan_clean)
  serverchan_clean
  ;;
relnmp)
  relnmp
  ;;
mkfs)
  mkfs
  ;;
ping)
  echo "ping"
  ;;
allping)
  check_app_24 "X_allping"
  allping &
  ;;
ss_link_matching)
  check_app_24  "X_allping"
  ss_link_matching &
  ;;
reszUID)
  reszUID
  ;;
esac
