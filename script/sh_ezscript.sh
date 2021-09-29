#!/bin/bash
#copyright by hiboy
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
if [ ! -z "$(echo $scriptfilepath | grep -v "/tmp/script/" | grep _ezscript)" ]  && [ ! -s /tmp/script/_ezscript ]; then
	mkdir -p /tmp/script
	{ echo '#!/bin/bash' ; echo $scriptfilepath '"$@"' '&' ; } > /tmp/script/_ezscript
	chmod 777 /tmp/script/_ezscript
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

getAPSite () {
radio_x=$1
[ -z "$radio_x" ] && radio_x="2g"
if [ "$radio_x" = "2g" ] ; then
radio_main="$(nvram get radio2_main)"
[ -z "$radio_main" ] && radio_main="ra0"
echo 'wds_aplist = [' > /tmp/APSite2g.txt
fi
if [ "$radio_x" = "5g" ] ; then
radio_main="$(nvram get radio5_main)"
[ -z "$radio_main" ] && radio_main="rai0"
echo 'wds_aplist = [' > /tmp/APSite5g.txt
fi
logger -t "【刷新无线信号列表】" "scan $radio_x $radio_main"
iwpriv $radio_main set SiteSurvey=1
sleep 1
wds_aplist="$(iwpriv $radio_main get_site_survey)"
[ ! -z "$(echo "$wds_aplist"| grep "get_site_survey:No BssInfo")" ] && sleep 2 && wds_aplist="$(iwpriv $radio_main get_site_survey)"
[ ! -z "$(echo "$wds_aplist"| grep "get_site_survey:No BssInfo")" ] && sleep 3 && wds_aplist="$(iwpriv $radio_main get_site_survey)"
retxt=""
i_1="0"
echo "$wds_aplist" | while read aplist_n; do
if [ "$i_1" != "0" ] ; then
if [ "$i_1" = "1" ] ; then
ap_ch_ac="$(awk -v a="$aplist_n" -v b="Ch" 'BEGIN{print index(a,b)}')"
ap_ch_b="$(echo "$aplist_n" | grep -Eo "Ch *" | sed -n '1p')"
ap_ch_bc="$(echo """$ap_ch_b" | wc -c)"
ap_ch_bc=`expr $ap_ch_bc - 1`
ap_ch_c=`expr $ap_ch_ac + $ap_ch_bc - 1`
ap_ssid_ac="$(awk -v a="$aplist_n" -v b="SSID" 'BEGIN{print index(a,b)}')"
ap_ssid_b="$(echo "$aplist_n" | grep -Eo "SSID *" | sed -n '1p')"
ap_ssid_bc="$(echo """$ap_ssid_b" | wc -c)"
ap_ssid_bc=`expr $ap_ssid_bc - 1`
ap_ssid_c=`expr $ap_ssid_ac + $ap_ssid_bc - 1`
ap_bssid_ac="$(awk -v a="$aplist_n" -v b="BSSID" 'BEGIN{print index(a,b)}')"
ap_bssid_b="$(echo "$aplist_n" | grep -Eo "BSSID *" | sed -n '1p')"
ap_bssid_bc="$(echo """$ap_bssid_b" | wc -c)"
ap_bssid_bc=`expr $ap_bssid_bc - 1`
ap_bssid_c=`expr $ap_bssid_ac + $ap_bssid_bc - 1`
ap_security_ac="$(awk -v a="$aplist_n" -v b="Security" 'BEGIN{print index(a,b)}')"
ap_security_b="$(echo "$aplist_n" | grep -Eo "Security *" | sed -n '1p')"
ap_security_bc="$(echo """$ap_security_b" | wc -c)"
ap_security_bc=`expr $ap_security_bc - 1`
ap_security_c=`expr $ap_security_ac + $ap_security_bc - 1`
ap_signal_ac="$(awk -v a="$aplist_n" -v b="Signal" 'BEGIN{print index(a,b)}')"
ap_signal_b="Signal(%)"
ap_signal_bc="$(echo """$ap_signal_b" | wc -c)"
ap_signal_bc=`expr $ap_signal_bc - 1`
ap_signal_c=`expr $ap_signal_ac + $ap_signal_bc - 1`
ap_wmode_ac="$(awk -v a="$aplist_n" -v b="W-Mode" 'BEGIN{print index(a,b)}')"
ap_wmode_b="$(echo "$aplist_n" | grep -Eo "W-Mode *" | sed -n '1p')"
ap_wmode_bc="$(echo """$ap_wmode_b" | wc -c)"
ap_wmode_bc=`expr $ap_wmode_bc - 1`
ap_wmode_c=`expr $ap_wmode_ac + $ap_wmode_bc - 1`
i_1=`expr $i_1 + 1`
continue
fi
if [ "$i_1" != "2" ] ; then
[ "$radio_x" = "2g" ] && echo "," >> /tmp/APSite2g.txt
[ "$radio_x" = "5g" ] && echo "," >> /tmp/APSite5g.txt
fi
retxt='["'"$(echo "$aplist_n" | cut -b "$ap_ch_ac-$ap_ch_c")"'", "'"$(echo "$aplist_n" | cut -b "$ap_ssid_ac-$ap_ssid_c")"'", "'"$(echo "$aplist_n" | cut -b "$ap_bssid_ac-$ap_bssid_c")"'", "'"$(echo "$aplist_n" | cut -b "$ap_security_ac-$ap_security_c")"'", "'"$(echo "$aplist_n" | cut -b "$ap_signal_ac-$ap_signal_c")"'", "'"$(echo "$aplist_n" | cut -b "$ap_wmode_ac-$ap_wmode_c")"'"]'
echo "$retxt"
[ "$radio_x" = "2g" ] && echo -n "$retxt" >> /tmp/APSite2g.txt
[ "$radio_x" = "5g" ] && echo -n "$retxt" >> /tmp/APSite5g.txt
fi
i_1=`expr $i_1 + 1`
done
[ "$radio_x" = "2g" ] && echo "]" >> /tmp/APSite2g.txt
[ "$radio_x" = "5g" ] && echo "]" >> /tmp/APSite5g.txt
if [ "$radio_x" = "2g" ] ; then
umount /www/wds_aplist_2g.asp
touch /tmp/APSite2g.txt
mount --bind /tmp/APSite2g.txt /www/wds_aplist_2g.asp
fi
if [ "$radio_x" = "5g" ] ; then
umount /www/wds_aplist.asp
touch /tmp/APSite5g.txt
mount --bind /tmp/APSite5g.txt /www/wds_aplist.asp
fi
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
reszUID)
  reszUID
  ;;
getAPSite2g)
  getAPSite "2g"
  ;;
getAPSite5g)
  getAPSite "5g"
  ;;
esac
