#!/bin/sh
#copyright by hiboy
source /etc/storage/script/init.sh

# 按钮名称可自定义
ad=`nvram get button_script_1_s`
[ -z "$ad" ] && ad="Adbyby" && nvram set button_script_1_s="Adbyby"
ss=`nvram get button_script_2_s`
[ -z "$ss" ] && ss="SS_[1]" && nvram set button_script_2_s="SS_[1]"

transocks_enable=`nvram get app_27`
[ -z $transocks_enable ] && transocks_enable=0 && nvram set app_27=0
[ "$transocks_enable" != "0" ] && [ "$ss" != "Tsocks" ] && ss="Tsocks" && nvram set button_script_2_s="Tsocks"

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
		[ $ss_working_port == 1090 ] && ss_info="SS_[1]"
		[ $ss_working_port == 1091 ] && ss_info="SS_[2]"
		[ ${ss_info:=SS_[1]} ] && [ "$ss" != "$ss_info" ] && { ss="$ss_info" ; nvram set button_script_2_s="$ss"; }
	fi
	if [ "$ss_mode_x" = 3 ]  ; then
		[ "$ss" != "SS" ] && { ss="SS" ; nvram set button_script_2_s="$ss"; }
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
	/tmp/script/_ad_m &
fi
if [ "$apply" = 1 ] && [ "$port" -ge 1 ] || [ "$PIDS" != 0 ] ; then
	logger -t "【按钮①】" "关闭转发规则, 关闭 $ad"
	nvram set adm_status=1
	nvram set adm_enable=0
	/tmp/script/_ad_m stop &
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
	/tmp/script/_kool_proxy &
fi
if [ "$apply" = 1 ] && [ "$port" -ge 1 ] || [ "$PIDS" != 0 ] ; then
	logger -t "【按钮①】" "关闭转发规则, 关闭 $ad"
	nvram set koolproxy_status=1
	nvram set koolproxy_enable=0
	/tmp/script/_kool_proxy &
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
	/tmp/script/_ad_byby &
fi
if [ "$apply" = 1 ] && [ "$port" -ge 1 ] || [ "$PIDS" != 0 ] ; then
	logger -t "【按钮①】" "关闭转发规则, 关闭 $ad"
	nvram set adbyby_status=1
	nvram set adbyby_enable=0
	/tmp/script/_ad_byby  &
fi
fi

button_3 &

}

button_2 () {

# 按钮②子程序
button2=`nvram get button_script_2_s`
logger -t "【按钮②】" "$button2"
apply=`nvram get button_script_2`

if [ "$ss" = "SS_[1]" ] || [ "$ss" = "SS_[2]" ] ; then
if [ ! -s /tmp/script/_ss ] ; then
	logger -t "【按钮②】" "请稍等 SS 脚本初始化！"
	return
fi
# 按钮②状态0 执行以下命令
if [ "$apply" = 0 ] ; then
	logger -t "【按钮②】" "开启 shadowsocks 进程"
	nvram set ss_status=0
	nvram set ss_enable=1
	/tmp/script/_ss &
	nvram set button_script_2="1"
fi
# 按钮②状态1时执行以下命令
if [ "$apply" = 1 ] ; then
	logger -t "【按钮②】" "关闭 shadowsocks 进程"
	nvram set ss_status=1
	nvram set ss_enable=0
	/tmp/script/_ss &
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
	/tmp/script/_v2ray &
	nvram set button_script_2="1"
fi
# 按钮②状态1时执行以下命令
if [ "$apply" = 1 ] ; then
	logger -t "【按钮②】" "关闭 v2ray 进程"
	nvram set v2ray_status=1
	nvram set v2ray_enable=0
	/tmp/script/_v2ray &
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
	/tmp/script/_app10 &
	nvram set button_script_2="1"
fi
# 按钮②状态1时执行以下命令
if [ "$apply" = 1 ] ; then
	logger -t "【按钮②】" "关闭 transocks 进程"
	nvram set transocks_status=1
	nvram set app_27=0
	/tmp/script/_app10 &
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
	/tmp/script/_app18 &
	nvram set button_script_2="1"
fi
# 按钮②状态1时执行以下命令
if [ "$apply" = 1 ] ; then
	logger -t "【按钮②】" "关闭 clash 进程"
	nvram set clash_status=1
	nvram set app_88=0
	/tmp/script/_app18 &
	nvram set button_script_2="0"
fi
fi

button_3 &

}

button_3 () {

# 按钮状态检测子程序
sleep 1
port=$(iptables -t nat -L | grep 'AD_BYBY_to' | wc -l)
if [ "$port" -ge 1 ] ; then
	nvram set button_script_1="1"
else
	nvram set button_script_1="0"
fi
PROCESS=""
if [ "$ss" = "SS_[1]" ] || [ "$ss" = "SS_[2]" ] ; then
	PROCESS=$(ps -w | grep "ss-redir" | grep -v "grep")
elif [ "$ss" = "SS" ] ; then
	PROCESS=$(ps -w | grep "ss-local" | grep -v "grep")
elif [ "$ss" = "V2Ray" ] ; then
	PROCESS=$(pidof v2ray)
elif [ "$ss" = "Tsocks" ] ; then
	PROCESS=$(pidof transocks)
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
logger -t "【按钮】" "重置 SS IP 规则文件并重启 SS"
/tmp/script/_ss stop
rm -f /tmp/ss/dnsmasq.d/*
restart_dhcpd
rm -rf /etc/storage/china_ip_list.txt /etc/storage/basedomain.txt /tmp/ss/*
[ ! -f /etc/storage/china_ip_list.txt ] && tar -xzvf /etc_ro/china_ip_list.tgz -C /tmp && ln -sf /tmp/china_ip_list.txt /etc/storage/china_ip_list.txt
[ ! -f /etc/storage/basedomain.txt ] && tar -xzvf /etc_ro/basedomain.tgz -C /tmp && ln -sf /tmp/basedomain.txt /etc/storage/basedomain.txt
nvram set ss_status="cleanss"
nvram set kcptun_status="cleanss"
	rm -f /opt/bin/ss-redir /opt/bin/ssr-redir /opt/bin/ss-local /opt/bin/ssr-local /opt/bin/obfs-local
	rm -f /opt/bin/ss0-redir /opt/bin/ssr0-redir /opt/bin/ss0-local /opt/bin/ssr0-local
	rm -f /opt/bin/pdnsd /opt/bin/dnsproxy
sleep 5
/tmp/script/_ss &
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
/tmp/script/_mountopt optwget
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
	/tmp/script/_mountopt start
if [[ "$(jq -h 2>&1 | wc -l)" -lt 2 ]] ; then
	logger -t "【jq_check】" "找不到 jq，下载 jq程序"
	wgetcurl.sh /opt/bin/jq "$hiboyfile/jq" "$hiboyfile2/jq"
	chmod 755 "/opt/bin/jq"
if [[ "$(jq -h 2>&1 | wc -l)" -lt 2 ]] ; then
	logger -t "【jq_check】" "找不到 jq，安装 opt 程序"
	rm -f /opt/bin/jq
	/tmp/script/_mountopt optwget
if [[ "$(jq -h 2>&1 | wc -l)" -lt 2 ]] ; then
	opkg update
	opkg install jq
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

[ ! -f /www/link/link.js ] && logger -t "【自动选用节点】" "错误！找不到 /www/link/link.js" && return 1
if [[ "$(jq -h 2>&1 | wc -l)" -lt 2 ]] ; then
jq_check
if [[ "$(jq -h 2>&1 | wc -l)" -lt 2 ]] ; then
	return 1
fi
fi
# 排序节点
mkdir /tmp/link_matching -p
if [ ! -f /tmp/link_matching/link_matching.txt ] || [ ! -s /tmp/link_matching/link_matching.txt ] ; then
match="$(nvram get app_95)"
mismatch="$(nvram get app_96)"
[ ! -z "$match" ] && grep $match /www/link/link.js > /tmp/link_matching/0.txt
[ -z "$match" ] && cat /www/link/link.js > /tmp/link_matching/0.txt
echo -n "" > /tmp/link_matching/1.txt
while read line
do
[ ! -z "$mismatch" ] && line3="$(echo "$line" | grep -E .+'",' | cut -d',' -f1 | grep $match | grep -v $mismatch )"
[ -z "$mismatch" ] && line3="$(echo "$line" | grep -E .+'",' | cut -d',' -f1 | grep $match )"
[ -z "$match" ] && line3="line3"
line4="line4"
if [ ! -z "$line3" ] ; then
line2="$(echo "$line" | grep -Eo '"btn-success","'[0-9]+' ms"' | grep -Eo [0-9]+ )"
[ ! -z "$line2" ] && line2="0000""$line2" && echo -n "$(echo ${line2: 0-4})" >> /tmp/link_matching/1.txt && line4=""
line2="$(echo "$line" | grep -Eo '"btn-warning","'[0-9]+' ms"' | grep -Eo [0-9]+ )"
[ ! -z "$line2" ] && line2="0000""$line2" && echo -n "$(echo ${line2: 0-4})" >> /tmp/link_matching/1.txt && line4=""
line2="$(echo "$line" | grep -Eo '"btn-danger",">1000 ms"' | grep -Eo [0-9]+ )"
[ ! -z "$line2" ] && line2="0000""$line2" && echo -n "$(echo ${line2: 0-4})" >> /tmp/link_matching/1.txt && line4=""
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
app_97=$(echo $line| jq --compact-output --raw-output 'getpath([0])')
ss_server=$(echo $line| jq --compact-output --raw-output 'getpath([1])')
ss_server_port=$(echo $line| jq --compact-output --raw-output 'getpath([2])')
ss_key=$(echo $line| jq --compact-output --raw-output 'getpath([3])')
ss_method=$(echo $line| jq --compact-output --raw-output 'getpath([4])')
ss_usage=$(echo $line| jq --compact-output --raw-output 'getpath([7])')
sed -i $i_matching's/^/已经自动选用节点/' /tmp/link_matching/link_matching.txt
nvram set app_97="$app_97"
nvram set ss_server="$ss_server"
nvram set ss_server_port="$ss_server_port"
nvram set ss_key="$ss_key"
nvram set ss_method="$ss_method"
nvram set ss_usage="$ss_usage"
# 重启SS
eval "Sh15_ss.sh &"
break
fi
i_matching=`expr $i_matching + 1`
done < /tmp/link_matching/link_matching.txt

}

allping () {

[ ! -f /www/link/link.js ] && logger -t "【ping】" "错误！找不到 /www/link/link.js" && return 1
if [[ "$(jq -h 2>&1 | wc -l)" -lt 2 ]] ; then
jq_check
if [[ "$(jq -h 2>&1 | wc -l)" -lt 2 ]] ; then
	return 1
fi
fi
logger -t "【ping】" "开始 ping"
echo "" > /tmp/ping_server_error.txt
rm -f /tmp/link_matching/link_matching.txt
i_ping=2
while read line
do
ilox="$(grep -v '\[\]\]'  /www/link/link.js | grep -v "ACL2List = " |wc -l)"
if [ -z "$(echo "$line" | grep "ACL2List = ")" ] && [ -z "$(echo "$line" | grep '\[\]\]')" ] ; then
ping_list="$(echo $line | sed -e 's/],/]/g' )"
ss_server_x=$(echo $ping_list| jq --compact-output --raw-output 'getpath([1])')
if [ ! -z "$ss_server_x" ] ; then
ilog="$(expr $i_ping \* 100 / $ilox \* 100 / 100)"
[ "$ilog" -gt 100 ] && ilog=100
ss_name_x=$(echo $ping_list| jq --compact-output --raw-output 'getpath([0])')
if [ ! -z "$(grep "error_""$ss_server_x""_error" /tmp/ping_server_error.txt)" ] ; then
ping_text=""
else
ping_text=`ping -4 $ss_server_x -c 1 -w 1 -q`
fi
ping_time=`echo $ping_text | awk -F '/' '{print $4}'| awk -F '.' '{print $1}'`
ping_loss=`echo $ping_text | awk -F ', ' '{print $3}' | awk '{print $1}'`
if [ ! -z "$ping_time" ] ; then
	[ "$ping_time" -le 250 ] && ping_list=$(echo $ping_list| jq --compact-output --raw-output 'setpath([5];"btn-success")')
	[ "$ping_time" -gt 250 ] && [ "$ping_time" -le 500 ] && ping_list=$(echo $ping_list| jq --compact-output --raw-output 'setpath([5];"btn-warning")')
	[ "$ping_time" -gt 500 ] && ping_list=$(echo $ping_list| jq --compact-output --raw-output 'setpath([5];"btn-danger")')
	echo "ping_$ilog%：$ping_time ms ✔️ $ss_server_x"
	logger -t "【ping_$ilog%】" "$ss_name_x"
	logger -t "【ping_$ilog%】" "$ping_time ms ✔️ $ss_server_x"
	ping_list=$(echo $ping_list| jq --compact-output --raw-output 'setpath([6];"'"$ping_time"' ms")')
else
	ping_list=$(echo $ping_list| jq --compact-output --raw-output 'setpath([5];"btn-danger")')
	echo "ping_$ilog%：>1000 ms ❌ $ss_server_x"
	logger -t "【ping_$ilog%】" "$ss_name_x"
	logger -t "【ping_$ilog%】" ">1000 ms ❌ $ss_server_x"
	ping_list=$(echo $ping_list| jq --compact-output --raw-output 'setpath([6];">1000 ms")')
	echo "error_""$ss_server_x""_error" >> /tmp/ping_server_error.txt
fi
if [ ! -z "$ping_list" ] ; then
sed -i "$i_ping"'s/^.*$/'"$ping_list"", "'/' /www/link/link.js
fi
fi
i_ping=`expr $i_ping + 1`
fi
done < /www/link/link.js
logger -t "【ping】" "完成 ping 请按【F5】刷新 web 查看 ping"
app_99="$(nvram get app_99)"
if [ "$app_99" == 1 ] ; then
logger -t "【ping】" "服务器订阅：更新后自动选用节点 /tmp/link_matching/link_matching.txt"
/etc/storage/script/sh_ezscript.sh ss_link_matching & 
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
  allping &
  ;;
ss_link_matching)
  ss_link_matching &
  ;;
reszUID)
  reszUID
  ;;
esac
