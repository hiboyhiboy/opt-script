#!/bin/sh

Builds="/etc/storage/Builds-2021-10-15"
result=0
mtd_part_name="Storage"
mtd_part_dev="/dev/mtdblock5"
mtd_part_size=720896
dir_storage="/etc/storage"
slk="/tmp/.storage_locked"
tmp="/tmp/storage.tar"
tbz="${tmp}.bz2"
hsh="/tmp/hashes/storage_md5"
config_tinyproxy="/etc/storage/tinyproxy_script.sh"
config_mproxy="/etc/storage/mproxy_script.sh"
script0_script="/etc/storage/script0_script.sh"
script_script="/etc/storage/script_script.sh"
script1_script="/etc/storage/script1_script.sh"
script2_script="/etc/storage/script2_script.sh"
script3_script="/etc/storage/script3_script.sh"
adbyby_rules_script="/etc/storage/adbyby_rules_script.sh"
adm_rules_script="/etc/storage/adm_rules_script.sh"
koolproxy_rules_script="/etc/storage/koolproxy_rules_script.sh"
koolproxy_rules_list="/etc/storage/koolproxy_rules_list.sh"
shadowsocks_config_script="/etc/storage/shadowsocks_config_script.sh"
shadowsocks_ss_spec_lan="/etc/storage/shadowsocks_ss_spec_lan.sh"
shadowsocks_ss_spec_wan="/etc/storage/shadowsocks_ss_spec_wan.sh"
ad_config_script="/etc/storage/ad_config_script.sh"
FastDick_script="/etc/storage/FastDick_script.sh"
crontabs_script="/etc/storage/crontabs_script.sh"
jbls_script="/etc/storage/jbls_script.sh"
vlmcsdini_script="/etc/storage/vlmcsdini_script.sh"
DNSPOD_script="/etc/storage/DNSPOD_script.sh"
cloudxns_script="/etc/storage/cloudxns_script.sh"
aliddns_script="/etc/storage/aliddns_script.sh"
ddns_script="/etc/storage/ddns_script.sh"
ngrok_script="/etc/storage/ngrok_script.sh"
frp_script="/etc/storage/frp_script.sh"
kcptun_script="/etc/storage/kcptun_script.sh"
serverchan_script="/etc/storage/serverchan_script.sh"
SSRconfig_script="/etc/storage/SSRconfig_script.sh"
ap_script="/etc/storage/ap_script.sh"

script_start="$dir_storage/start_script.sh"
script_started="$dir_storage/started_script.sh"
script_shutd="$dir_storage/shutdown_script.sh"
script_postf="$dir_storage/post_iptables_script.sh"
script_postw="$dir_storage/post_wan_script.sh"
script_inets="$dir_storage/inet_state_script.sh"
script_vpnsc="$dir_storage/vpns_client_script.sh"
script_vpncs="$dir_storage/vpnc_server_script.sh"
script_ezbtn="$dir_storage/ez_buttons_script.sh"

func_get_mtd()
{
	local mtd_part mtd_char mtd_idx mtd_hex
	mtd_part=`cat /proc/mtd | grep \"$mtd_part_name\"`
	mtd_char=`echo $mtd_part | cut -d':' -f1`
	mtd_hex=`echo $mtd_part | cut -d' ' -f2`
	mtd_idx=`echo $mtd_char | cut -c4-5`
	if [ -n "$mtd_idx" ] && [ $mtd_idx -ge 3 ] ; then
		mtd_part_dev="/dev/mtdblock${mtd_idx}"
		mtd_part_size=`echo $((0x$mtd_hex))`
	else
		logger -t "Storage" "Cannot find MTD partition: $mtd_part_name"
		exit 1
	fi
}

func_mdir()
{
	[ ! -d "$dir_storage" ] && mkdir -p -m 755 $dir_storage
}

func_stop_apps()
{
	killall -q rstats
	[ $? -eq 0 ] && sleep 1
}

func_start_apps()
{
	/sbin/rstats
}

func_load()
{
	local fsz

	bzcat $mtd_part_dev > $tmp 2>/dev/null
	fsz=`stat -c %s $tmp 2>/dev/null`
	if [ -n "$fsz" ] && [ $fsz -gt 0 ] ; then
		md5sum $tmp > $hsh
		tar xf $tmp -C $dir_storage 2>/dev/null
	else
		result=1
		rm -f $hsh
		logger -t "Storage load" "Invalid storage data in MTD partition: $mtd_part_dev"
	fi
	rm -f $tmp
	rm -f $slk
}

func_tarb()
{
	rm -f $tmp
	cd $dir_storage
	find * -print0 | xargs -0 touch -c -h -t 201001010000.00
	find * ! -type d -print0 | sort -z | xargs -0 tar -cf $tmp 2>/dev/null
	cd - >>/dev/null
	if [ ! -f "$tmp" ] ; then
		logger -t "Storage" "Cannot create tarball file: $tmp"
		exit 1
	fi
}

func_save()
{
	local fsz

	echo "Save storage files to MTD partition \"$mtd_part_dev\""
	rm -f $tbz
	md5sum -c -s $hsh 2>/dev/null
	if [ $? -eq 0 ] ; then
		echo "Storage hash is not changed, skip write to MTD partition. Exit."
		rm -f $tmp
		return 0
	fi
	md5sum $tmp > $hsh
	bzip2 -9 $tmp 2>/dev/null
	fsz=`stat -c %s $tbz 2>/dev/null`
	if [ -n "$fsz" ] && [ $fsz -ge 16 ] && [ $fsz -le $mtd_part_size ] ; then
		mtd_write write $tbz $mtd_part_name
		if [ $? -eq 0 ] ; then
			echo "Done."
		else
			result=1
			echo "Error! MTD write FAILED"
			logger -t "Storage save" "Error write to MTD partition: $mtd_part_dev"
		fi
	else
		result=1
		echo "Error! Invalid storage final data size: $fsz"
		logger -t "Storage save" "Invalid storage final data size: $fsz"
		[ $fsz -gt $mtd_part_size ] && logger -t "Storage save" "Storage using data size: $fsz > flash partition size: $mtd_part_size"
	fi
	rm -f $tmp
	rm -f $tbz
}

func_backup()
{
	rm -f $tbz
	bzip2 -9 $tmp 2>/dev/null
	if [ $? -ne 0 ] ; then
		result=1
		logger -t "Storage backup" "Cannot create BZ2 file!"
	fi
	rm -f $tmp
}

func_restore()
{
	local fsz tmp_storage

	[ ! -f "$tbz" ] && exit 1

	fsz=`stat -c %s $tbz 2>/dev/null`
	if [ -z "$fsz" ] || [ $fsz -lt 16 ] || [ $fsz -gt $mtd_part_size ] ; then
		result=1
		rm -f $tbz
		logger -t "Storage restore" "Invalid BZ2 file size: $fsz"
		return 1
	fi

	tmp_storage="/tmp/storage"
	rm -rf $tmp_storage
	mkdir -p -m 755 $tmp_storage
	tar xjf $tbz -C $tmp_storage 2>/dev/null
	if [ $? -ne 0 ] ; then
		result=1
		rm -f $tbz
		rm -rf $tmp_storage
		logger -t "Storage restore" "Unable to extract BZ2 file: $tbz"
		return 1
	fi
	if [ ! -f "$tmp_storage/start_script.sh" ] ; then
		result=1
		rm -f $tbz
		rm -rf $tmp_storage
		logger -t "Storage restore" "Invalid content of BZ2 file: $tbz"
		return 1
	fi

	func_stop_apps

	rm -f $slk
	rm -f $tbz
	rm -rf $dir_storage
	mkdir -p -m 755 $dir_storage
	cp -rf $tmp_storage /etc
	rm -rf $tmp_storage

	func_start_apps
}

func_erase()
{
	mtd_write erase $mtd_part_name
	if [ $? -eq 0 ] ; then
		rm -f $hsh
		rm -rf $dir_storage
		mkdir -p -m 755 $dir_storage
		touch "$slk"
	else
		result=1
	fi
}

func_reset()
{
	rm -f $slk
	rm -rf $dir_storage
	mkdir -p -m 755 $dir_storage
}

func_resetsh()
{
	rm -f $slk
	rm -f /etc/storage/Builds-*

	if [ -z "$(grep /etc/storage/script_script.sh /etc/storage/started_script.sh)" ] ; then
		logger -t "【mtd_storage.sh】" "由于【/etc/storage/started_script.sh】缺少关键启动命令：【/etc/storage/script_script.sh】，重置全部脚本！"
		#删除UI配置文件
		rm -f $jbls_script $vlmcsdini_script $config_tinyproxy $config_mproxy $shadowsocks_ss_spec_lan $shadowsocks_ss_spec_wan $kcptun_script $SSRconfig_script 
		rm -f $ngrok_script $frp_script $ddns_script $ad_config_script $adbyby_rules_script $adm_rules_script $koolproxy_rules_list $koolproxy_rules_script
		rm -f /etc/storage/v2ray_config_script.sh /etc/storage/cow_config_script.sh /etc/storage/meow_config_script.sh /etc/storage/meow_direct_script.sh 
		rm -f $koolproxy_rules_list $vlmcsdini_script
		
		#删除UI脚本文件
		rm -f /etc/storage/v2ray_script.sh /etc/storage/cow_script.sh /etc/storage/meow_script.sh /etc/storage/softether_script.sh
		
		#删除内部脚本文件
		rm -f $script0_script $script_script $script1_script $script2_script $script3_script $crontabs_script $DNSPOD_script $cloudxns_script $aliddns_script
		rm -f $serverchan_script $script_start $script_started $script_postf $script_postw $script_inets $script_vpnsc $script_vpncs $script_ezbtn 
	fi

	# 删除/etc/storage/ez_buttons_script.sh转为内部更新
	[ ! -z "$(grep button_script_2_s /etc/storage/ez_buttons_script.sh)" ] && rm -f /etc/storage/ez_buttons_script.sh

	rm -f /opt/bin/ss-redir /opt/bin/ssr-redir /opt/bin/ss-local /opt/bin/ssr-local /opt/bin/obfs-local
	rm -f /opt/bin/ss0-redir /opt/bin/ssr0-redir /opt/bin/ss0-local /opt/bin/ssr0-local
	rm -f $script_script
	mkdir -p -m 755 $dir_storage
	rm -f /etc/storage/china_ip_list.txt /etc/storage/basedomain.txt
	[ ! -f /etc/storage/china_ip_list.txt ] && tar -xzvf /etc_ro/china_ip_list.tgz -C /tmp && ln -sf /tmp/china_ip_list.txt /etc/storage/china_ip_list.txt
	[ ! -f /etc/storage/basedomain.txt ] && tar -xzvf /etc_ro/basedomain.tgz -C /tmp && ln -sf /tmp/basedomain.txt /etc/storage/basedomain.txt
	
	# 解压覆盖脚本
	tar -xzvf /etc_ro/script.tgz -C /etc/storage/
	tar -xzvf /etc_ro/www_sh.tgz -C /etc/storage/
	# 重置菜单
	sleep 1
	#eval /etc/storage/www_sh/menu_title.sh re
	touch /tmp/menu_title_re
	touch /tmp/www_asp_re

}

func_fill()
{
	mkdir -p -m 777 "/etc/storage/lib"
	mkdir -p -m 777 "/etc/storage/bin"
	mkdir -p -m 777 "/etc/storage/tinyproxy"

	dir_httpssl="$dir_storage/https"
	dir_dnsmasq="$dir_storage/dnsmasq"
	dir_ovpnsvr="$dir_storage/openvpn/server"
	dir_ovpncli="$dir_storage/openvpn/client"
	dir_sswan="$dir_storage/strongswan"
	dir_sswan_crt="$dir_sswan/ipsec.d"
	dir_inadyn="$dir_storage/inadyn"
	dir_crond="$dir_storage/cron/crontabs"
	dir_wlan="$dir_storage/wlan"
{
[ ! -s /etc/storage/china_ip_list.txt ] && [ -s /etc_ro/china_ip_list.tgz ] && { tar -xzvf /etc_ro/china_ip_list.tgz -C /tmp ; ln -sf /tmp/china_ip_list.txt /etc/storage/china_ip_list.txt ; }
[ ! -s /etc/storage/basedomain.txt ] && [ -s /etc_ro/basedomain.tgz ] && { tar -xzvf /etc_ro/basedomain.tgz -C /tmp ; ln -sf /tmp/basedomain.txt /etc/storage/basedomain.txt ; }
ln -sf /etc/storage/PhMain.ini /etc/PhMain.ini &
ln -sf /etc/storage/init.status /etc/init.status &
[ ! -s /etc/storage/script/init.sh ] && [ -s /etc_ro/script.tgz ] && tar -xzvf /etc_ro/script.tgz -C /etc/storage/
[ -s /etc/storage/script/init.sh ] && chmod 777 /etc/storage/script -R
[ ! -s /etc/storage/www_sh/menu_title.sh ] && [ -s /etc_ro/www_sh.tgz ] && tar -xzvf /etc_ro/www_sh.tgz -C /etc/storage/
[ -s /etc/storage/www_sh/menu_title.sh ] && chmod 777 /etc/storage/www_sh -R
#[ ! -s /etc/storage/bin/daydayup ] && [ -s /etc_ro/daydayup ] && ln -sf /etc_ro/daydayup /etc/storage/bin/daydayup
} &
	user_hosts="$dir_dnsmasq/hosts"
	user_dnsmasq_conf="$dir_dnsmasq/dnsmasq.conf"
	user_dnsmasq_serv="$dir_dnsmasq/dnsmasq.servers"
	user_ovpnsvr_conf="$dir_ovpnsvr/server.conf"
	user_ovpncli_conf="$dir_ovpncli/client.conf"
	user_inadyn_conf="$dir_inadyn/inadyn.conf"
	user_sswan_conf="$dir_sswan/strongswan.conf"
	user_sswan_ipsec_conf="$dir_sswan/ipsec.conf"
	user_sswan_secrets="$dir_sswan/ipsec.secrets"

	# create crond dir
	[ ! -d "$dir_crond" ] && mkdir -p -m 730 "$dir_crond"

	# create https dir
	[ ! -d "$dir_httpssl" ] && mkdir -p -m 700 "$dir_httpssl"

	# create start script
	if [ ! -f "$script_start" ] ; then
		reset_ss.sh -a
	fi

	# create started script
	if [ ! -f "$script_started" ] ; then
		cat > "$script_started" <<-\EEE
#!/bin/sh

### Custom user script
### Called after router started and network is ready

### Example - load ipset modules
modprobe ip_set
modprobe ip_set_hash_ip
modprobe ip_set_hash_net
modprobe ip_set_bitmap_ip
modprobe ip_set_list_set
modprobe xt_set

/etc/storage/www_sh/menu_title.sh &

#confdir=`grep "/tmp/ss/dnsmasq.d" /etc/storage/dnsmasq/dnsmasq.conf | sed 's/.*\=//g'`
#if [ -z "$confdir" ] ; then 
    confdir="/tmp/ss/dnsmasq.d"
#fi
[ ! -d "$confdir" ] && mkdir -p $confdir
# SMB资源挂载(局域网共享映射，无USB也能挂载储存空间)
# 说明：【192.168.123.66】为共享服务器的IP，【nas】为共享文件夹名称
# 说明：username=、password=填账号密码，删除代码前面的#启用功能。
#sleep 10
#modprobe -q ext4
#modprobe des_generic
#modprobe cifs CIFSMaxBufSize=64512
#mkdir -p /media/cifs
#mount -t cifs //192.168.123.66/nas /media/cifs -o username=user,password=pass,dynperm,nounix,noserverino,file_mode=0777,dir_mode=0777

sleep 5
stop_ftpsamba
sleep 3
#mdev -s
# 挂载SD卡
for mmc_mount in `/usr/bin/find  /dev -name 'mmcblk[0-9]*' | awk '{print $1}'`
do
[ ! -z "$(df -m | grep $mmc_mount )" ] && continue
mmc_mount=$(basename $mmc_mount | awk '{print $1}')
echo $mmc_mount
device_name=`echo ${mmc_mount:6:1}`
partno=`echo ${mmc_mount:8:1}`
[ -z "$partno" ] && partno=1
/sbin/automount.sh $mmc_mount AiCard_$device_name$partno
done

# 挂载存储设备
for sd_mount in `/usr/bin/find  /dev -name 'sd[a-z]*' | awk '{print $1}'`
do
[ ! -z "$(df -m | grep $sd_mount )" ] && continue
sd_mount=$(basename $sd_mount | awk '{print $1}')
echo $sd_mount
device_name=`echo ${sd_mount:2:1}`
partno=`echo ${sd_mount:3:1}`
[ -z "$partno" ] && partno=1
/sbin/automount.sh $sd_mount AiDisk_$device_name$partno
done
sleep 3
run_ftpsamba
sleep 3

### 运行脚本1
/etc/storage/script_script.sh
/etc/storage/script/sh_ezscript.sh 3 & #更新按钮状态
logger -t "【运行路由器启动后】" "脚本完成"


#启动流量监控脚本
mkdir -p /tmp/bwmon
/usr/sbin/bwmon &

EEE
		chmod 755 "$script_started"
	fi

	# create shutdown script
	if [ ! -f "$script_shutd" ] ; then
		cat > "$script_shutd" <<-\EEE
#!/bin/sh

### Custom user script
### Called before router shutdown
### $1 - action (0: reboot, 1: halt, 2: power-off)

EEE
		chmod 755 "$script_shutd"
	fi

	# create post-iptables script
	if [ ! -f "$script_postf" ] ; then
		cat > "$script_postf" <<-\EEE
#!/bin/sh
/etc/storage/crontabs_script.sh &
export PATH='/etc/storage/bin:/tmp/script:/etc/storage/script:/opt/usr/sbin:/opt/usr/bin:/opt/sbin:/opt/bin:/usr/local/sbin:/usr/sbin:/usr/bin:/sbin:/bin'
export LD_LIBRARY_PATH=/lib:/opt/lib

logger -t "【防火墙规则】" "脚本完成"

EEE
		chmod 755 "$script_postf"
	fi


	if [ ! -f "$ap_script" ] || [ ! -s "$ap_script" ] ; then
	cat > "$ap_script" <<-\EEE
#!/bin/sh
#/etc/storage/ap_script.sh
#copyright by hiboy

# AP中继连接守护功能。【0】 Internet互联网断线后自动搜寻；【1】 当中继信号断开时启动自动搜寻。
nvram set ap_check=0

# AP连接成功条件，【0】 连上AP即可，不检查是否联网；【1】 连上AP并连上Internet互联网。
nvram set ap_inet_check=0

# 【0】 自动搜寻AP，成功连接后停止搜寻；大于等于【10】时则每隔【N】秒搜寻(无线网络会瞬断一下)，直到连上最优先信号。
nvram set ap_time_check=0

# 如搜寻的AP不联网则列入黑名单/tmp/apblack.txt 功能 【0】关闭；【1】启动
# 控制台输入【echo "" > /tmp/apblack.txt】可以清空黑名单
nvram set ap_black=0

# 自定义分隔符号，默认为【@】，注意:下面配置一同修改
nvram set ap_fenge='@'

# 搜寻AP排序设置【0】从第一行开始（第一行的是最优先信号）；【1】不分顺序自动连接最强信号
nvram set ap_rule=0

# 【自动切换中继信号】功能 填写配置参数启动
cat >/tmp/ap2g5g.txt <<-\EOF
# 中继AP配置填写说明：
# 各参数用【@】分割开，如果有多个信号可回车换行继续填写即可(从第一行的参数开始搜寻)【第一行的是最优先信号】
# 搜寻时无线网络会瞬断一下
# 参数说明：
# ①2.4Ghz或5Ghz："2"=【2.4Ghz】"5"=【5Ghz】
# ②无线AP工作模式："0"=【AP（桥接被禁用）】"3"=【AP-Client（AP被禁用）】"4"=【AP-Client + AP】（不支持WDS）
# ③无线AP-Client角色： "0"=【LAN bridge】"1"=【WAN (Wireless ISP)】
# ④中继AP 的 SSID："ASUS"
# ⑤中继AP 密码："1234567890"
# ⑥中继AP 的 MAC地址："20:76:90:20:B0:F0"【SSID有中文时需填写，不限大小写】
# 下面是信号填写例子：（删除前面的#可生效）
#2@4@1@ASUS@1234567890
#2@4@1@ASUS_中文@1234567890@34:bd:f9:1f:d2:b1
#2@4@1@ASUS3@1234567890@34:bd:f9:1f:d2:b0


EOF
cat /tmp/ap2g5g.txt | grep -v '^#'  | grep -v "^$" > /tmp/ap2g5g
killall sh_apauto.sh
if [ -s /tmp/ap2g5g ] ; then
cat >/tmp/sh_apauto.sh <<-\EOF
#!/bin/sh
[ "$1" = "crontabs" ] && sleep 15
logger -t "【AP 中继】" "连接守护启动"
while [ -s /tmp/ap2g5g ]; do
radio2_apcli=`nvram get radio2_apcli`
[ -z $radio2_apcli ] && radio2_apcli="apcli0"
radio5_apcli=`nvram get radio5_apcli`
[ -z $radio5_apcli ] && radio5_apcli="apclii0"
  ap_check=`nvram get ap_check`
  if [[ "$ap_check" == 1 ]] && [ ! -f /tmp/apc.lock ] ; then
  #【1】 当中继信号断开时启动自动搜寻
  a2=`iwconfig $radio2_apcli | awk -F'"' '/ESSID/ {print $2}'`
  sleep 1
  a5=`iwconfig $radio5_apcli | awk -F'"' '/ESSID/ {print $2}'`
  sleep 1
  [ "$a2" = "" -a "$a5" = "" ] && ap=1 || ap=0
  if [ "$ap" = "1" ] ; then
    logger -t "【AP 中继】" "连接中断，启动自动搜寻"
    sh_ezscript.sh connAPSite_scan &
    sleep 10
  fi
  fi
  ap_time_check="$(nvram get ap_time_check)"
  if [ "$ap_time_check" -ge 9 ] && [ ! -f /tmp/apc.lock ] ; then
    ap_fenge="$(nvram get ap_fenge)"
    rtwlt_sta_ssid_1=$(echo $(grep -v '^#' /tmp/ap2g5g | grep -v "^$" | head -1) | cut -d $ap_fenge -f4)
    rtwlt_sta_bssid_1=$(echo $(grep -v '^#' /tmp/ap2g5g | grep -v "^$" | head -1) | cut -d $ap_fenge -f6 | tr 'A-Z' 'a-z')
    [ "$(echo $(grep -v '^#' /tmp/ap2g5g | grep -v "^$" | head -1) | cut -d $ap_fenge -f1)" = "5" ] && radio2_apcli="$radio5_apcli"
    rtwlt_sta_ssid="$(iwconfig $radio2_apcli | grep ESSID: | awk -F'"' '/ESSID/ {print $2}')"
    sleep 1
    rtwlt_sta_bssid="$(iwconfig $radio2_apcli |sed -n '/'$radio2_apcli'/,/Rate/{/'$radio2_apcli'/n;/Rate/b;p}' | tr 'A-Z' 'a-z'  | awk -F'point:' '/point/ {print $2}')"
    sleep 1
    rtwlt_sta_bssid="$(echo $rtwlt_sta_bssid)"
    [ ! -z "$rtwlt_sta_ssid_1" ] && [ ! -z "$rtwlt_sta_ssid" ] && [ "$rtwlt_sta_ssid_1" == "$rtwlt_sta_ssid" ] && ap_time_check=0
    [ ! -z "$rtwlt_sta_bssid_1" ] && [ ! -z "$rtwlt_sta_bssid" ] && [ "$rtwlt_sta_bssid_1" == "$rtwlt_sta_bssid" ] && ap_time_check=0
    if [ "$ap_time_check" -ge 9 ] && [ ! -f /tmp/apc.lock ] ; then
    logger -t "【连接 AP】" "$ap_time_check 秒后,自动搜寻 ap ,直到连上最优先信号 $rtwlt_sta_ssid_1 "
    sleep $ap_time_check
    sh_ezscript.sh connAPSite_scan &
    sleep 10
    fi
  fi
  if [[ "$ap_check" == 0 ]] && [ ! -f /tmp/apc.lock ] ; then
    #【2】 Internet互联网断线后自动搜寻
    ping_text=`ping -4 223.5.5.5 -c 1 -w 4 -q`
    ping_time=`echo $ping_text | awk -F '/' '{print $4}'| awk -F '.' '{print $1}'`
    ping_loss=`echo $ping_text | awk -F ', ' '{print $3}' | awk '{print $1}'`
    if [ ! -z "$ping_time" ] ; then
    echo "online"
    else
    echo "Internet互联网断线后自动搜寻"
    sh_ezscript.sh connAPSite_scan &
    sleep 10
    fi
  fi
  sleep 63
  cat /tmp/ap2g5g.txt | grep -v '^#'  | grep -v "^$" > /tmp/ap2g5g
done
EOF
  chmod 777 "/tmp/sh_apauto.sh"
  [ -z "$(ps -w | grep sh_apauto.sh | grep -v grep)" ] && /tmp/sh_apauto.sh $1 &
fi

EEE
		chmod 755 "$ap_script"
	fi


	# create inet-state script
	if [ ! -f "$script_inets" ] || [ ! -s "$script_inets" ] ; then
		cat > "$script_inets" <<-\EEE
#!/bin/sh
#/etc/storage/inet_state_script.sh
### Custom user script
### Called on Internet status changed
### $1 - Internet status (0/1)
### $2 - elapsed time (s) from previous state
#copyright by hiboy
logger -t "【网络检测】" "互联网状态:$1, 经过时间:$2s."

EEE
		chmod 755 "$script_inets"
	fi

	# create vpn server action script
	if [ ! -f "$script_vpnsc" ] ; then
		cat > "$script_vpnsc" <<EOF
#!/bin/sh

### Custom user script
### Called after remote peer connected/disconnected to internal VPN server
### \$1 - peer action (up/down)
### \$2 - peer interface name (e.g. ppp10)
### \$3 - peer local IP address
### \$4 - peer remote IP address
### \$5 - peer name

peer_if="\$2"
peer_ip="\$4"
peer_name="\$5"

### example: add static route to private LAN subnet behind a remote peer

func_ipup()
{
#  if [ "\$peer_name" == "dmitry" ] ; then
#    route add -net 192.168.5.0 netmask 255.255.255.0 dev \$peer_if
#  elif [ "\$peer_name" == "victoria" ] ; then
#    route add -net 192.168.8.0 netmask 255.255.255.0 dev \$peer_if
#  fi
   return 0
}

func_ipdown()
{
#  if [ "\$peer_name" == "dmitry" ] ; then
#    route del -net 192.168.5.0 netmask 255.255.255.0 dev \$peer_if
#  elif [ "\$peer_name" == "victoria" ] ; then
#    route del -net 192.168.8.0 netmask 255.255.255.0 dev \$peer_if
#  fi
   return 0
}

case "\$1" in
up)
  func_ipup
  ;;
down)
  func_ipdown
  ;;
esac

EOF
		chmod 755 "$script_vpnsc"
	fi

	# create vpn client action script
	if [ ! -f "$script_vpncs" ] ; then
		cat > "$script_vpncs" <<-\EEE
#!/bin/sh
source /etc/storage/script/init.sh
### Custom user script
### Called after internal VPN client connected/disconnected to remote VPN server
### $1        - action (up/down)
### $IFNAME   - tunnel interface name (e.g. ppp5 or tun0)
### $IPLOCAL  - tunnel local IP address
### $IPREMOTE - tunnel remote IP address
### $DNS1     - peer DNS1
### $DNS2     - peer DNS2
#copyright by hiboy
# VPN国内外自动分流功能 0关闭；1启动
vpns=`nvram get vpnc_fw_enable`

# VPN线路流向选择 0出国；1回国
vpnc_fw_rules=`nvram get vpnc_fw_rules`

#confdir=`grep "/tmp/ss/dnsmasq.d" /etc/storage/dnsmasq/dnsmasq.conf | sed 's/.*\=//g'`
#if [ -z "$confdir" ] ; then 
    confdir="/tmp/ss/dnsmasq.d"
#fi
[ ! -d "$confdir" ] && mkdir -p $confdir
restart_dhcpd
# private LAN subnet behind a remote server (example)
peer_lan="192.168.9.0"
peer_msk="255.255.255.0"

### example: add static route to private LAN subnet behind a remote server

func_ipup()
{
#  route add -net $peer_lan netmask $peer_msk gw $IPREMOTE dev $IFNAME
  if [ "$vpns" = "1" ] ; then
    [ -f /tmp/vpnc.lock ] && logger -t "【VPN 分流】" "等待45秒开始脚本"
    I=45
    while [ -f /tmp/vpnc.lock ]; do
            I=$(($I - 1))
            [ $I -lt 0 ] && break
            sleep 1
    done
    touch /tmp/vpnc.lock
    logger -t "【VPN 分流】" "下载并运行 ip-pre-up 添加规则"
    if [ ! -s "/tmp/ip-pre-up" ] ; then
        wgetcurl.sh /tmp/ip-pre-up "$hiboyfile/ip-pre-up" "$hiboyfile2/ip-pre-up"
    fi
    if [ ! -s "/tmp/ip-pre-up" ] ; then
        wgetcurl.sh /tmp/ip-pre-up "$hiboyfile/ip-pre-up" "$hiboyfile2/ip-pre-up"
    fi
    chmod 777 "/tmp/ip-pre-up"
        if [ "$vpnc_fw_rules" = "1" ] ; then
            /tmp/ip-pre-up $IPREMOTE
        else
            /tmp/ip-pre-up
        fi
    if [ ! -s "/tmp/ip-down" ] ; then
        wgetcurl.sh /tmp/ip-down "$hiboyfile/ip-down" "$hiboyfile2/ip-down"
      chmod 777 "/tmp/ip-down"
    fi
    if [ ! -s "/tmp/ip-down" ] ; then
        wgetcurl.sh /tmp/ip-down "$hiboyfile/ip-down" "$hiboyfile2/ip-down"
    fi
    rm -f /tmp/vpnc.lock
    logger -t "【VPN 分流】" "ip-pre-up 添加规则完成"
  else
    rm -f /tmp/vpnc.lock
  fi
  return 0
}

func_ipdown()
{
#  route del -net $peer_lan netmask $peer_msk gw $IPREMOTE dev $IFNAME
  if [ "$vpns" = "1" ] ; then
    [ -f /tmp/vpnc.lock ] && logger -t "【VPN 分流】" "等待45秒开始脚本"
    I=45
    while [ -f /tmp/vpnc.lock ]; do
            I=$(($I - 1))
            [ $I -lt 0 ] && break
            sleep 1
    done
    touch /tmp/vpnc.lock
    logger -t "【VPN 分流】" "下载并运行 ip-down 删除规则"
    if [ ! -s "/tmp/ip-down" ] ; then
        wgetcurl.sh /tmp/ip-down "$hiboyfile/ip-down" "$hiboyfile2/ip-down"
    fi
    if [ ! -s "/tmp/ip-down" ] ; then
        wgetcurl.sh /tmp/ip-down "$hiboyfile/ip-down" "$hiboyfile2/ip-down"
    fi
    chmod 777 "/tmp/ip-down"
    /tmp/ip-down
    #if [ -s "/tmp/ip-pre-up" ] ; then
    #  rm -f /tmp/ip-pre-up
    #  rm -f /tmp/ip-down
    #fi
    rm -f /tmp/vpnc.lock
    #logger -t "【VPN 分流】" "ip-down 删除规则完成"
  else
    rm -f /tmp/vpnc.lock
  fi
  return 0
}

logger -t "【VPN客户端脚本】" "$IFNAME $1"

case "$1" in
up)
  func_ipup
  ;;
down)
  func_ipdown
  ;;
esac

EEE
		chmod 755 "$script_vpncs"
	fi



	# create Ez-Buttons script
	if [ ! -f "$script_ezbtn" ] || [ ! -s "$script_ezbtn" ] ; then
		cat > "$script_ezbtn" <<-\EEE
#!/bin/sh

### Custom user script
### Called on WPS or FN button pressed
### $1 - button param

[ -x /opt/bin/on_wps.sh ] && /opt/bin/on_wps.sh $1 &

EEE
		chmod 755 "$script_ezbtn"
	fi

	# create user dnsmasq.conf
	[ ! -d "$dir_dnsmasq" ] && mkdir -p -m 755 "$dir_dnsmasq"
	for i in dnsmasq.conf hosts ; do
		[ -f "$dir_storage/$i" ] && mv -n "$dir_storage/$i" "$dir_dnsmasq"
	done
	if [ ! -f "$user_dnsmasq_conf" ] ; then
		cat > "$user_dnsmasq_conf" <<EOF
# Custom user conf file for dnsmasq
# Please add needed params only!

### Web Proxy Automatic Discovery (WPAD)
dhcp-option=252,"\n"

### Set the limit on DHCP leases, the default is 150
#dhcp-lease-max=150

### Add local-only domains, queries are answered from hosts or DHCP only
#local=/router/localdomain/

### Examples:

### Enable built-in TFTP server
#enable-tftp

### Set the root directory for files available via TFTP.
#tftp-root=/opt/srv/tftp

### Make the TFTP server more secure
#tftp-secure

### Set the boot filename for netboot/PXE
#dhcp-boot=pxelinux.0

# 过滤 IPv6（AAAA）查询请求
#filter-aaaa

EOF
		chmod 644 "$user_dnsmasq_conf"
	fi

	# create user dns servers
	if [ ! -f "$user_dnsmasq_serv" ] ; then
		cat > "$user_dnsmasq_serv" <<EOF
# Custom user servers file for dnsmasq
# Example:
# 特定域名的自定义DNS设置例子:
#server=/mit.ru/izmuroma.ru/10.25.11.30
server=/update.adbyby.com/180.76.76.76#53



EOF
		chmod 644 "$user_dnsmasq_serv"
	fi

	# create user inadyn.conf"
	[ ! -d "$dir_inadyn" ] && mkdir -p -m 755 "$dir_inadyn"
	if [ ! -f "$user_inadyn_conf" ] ; then
		cat > "$user_inadyn_conf" <<EOF
# Custom user conf file for inadyn DDNS client
# Please add only new custom system!

### Example for twoDNS.de:

#system custom@http_srv_basic_auth
#  ssl
#  checkip-url checkip.two-dns.de /
#  server-name update.twodns.de
#  server-url /update\?hostname=
#  username account
#  password secret
#  alias example.dd-dns.de

EOF
		chmod 644 "$user_inadyn_conf"
	fi

	# create user hosts
	if [ ! -f "$user_hosts" ] || [ ! -s "$user_hosts" ] ; then
		cat > "$user_hosts" <<EOF
# Custom user hosts file
# Example:
# 192.168.123.100        Boo

EOF
		chmod 644 "$user_hosts"
	fi

	# create user AP confs
	[ ! -d "$dir_wlan" ] && mkdir -p -m 755 "$dir_wlan"
	if [ ! -f "$dir_wlan/AP.dat" ] ; then
		cat > "$dir_wlan/AP.dat" <<EOF
# Custom user AP conf file

EOF
		chmod 644 "$dir_wlan/AP.dat"
	fi

	if [ ! -f "$dir_wlan/AP_5G.dat" ] ; then
		cat > "$dir_wlan/AP_5G.dat" <<EOF
# Custom user AP conf file

EOF
		chmod 644 "$dir_wlan/AP_5G.dat"
	fi

	# create openvpn files
	if [ -x /usr/sbin/openvpn ] ; then
		[ ! -d "$dir_ovpncli" ] && mkdir -p -m 700 "$dir_ovpncli"
		[ ! -d "$dir_ovpnsvr" ] && mkdir -p -m 700 "$dir_ovpnsvr"
		dir_ovpn="$dir_storage/openvpn"
		for i in ca.crt dh1024.pem server.crt server.key server.conf ta.key ; do
			[ -f "$dir_ovpn/$i" ] && mv -n "$dir_ovpn/$i" "$dir_ovpnsvr"
		done
		if [ ! -f "$user_ovpnsvr_conf" ] ; then
			cat > "$user_ovpnsvr_conf" <<EOF
# Custom user conf file for OpenVPN server
# Please add needed params only!

### Negotiable Crypto Parameters
ncp-disable

### Max clients limit
max-clients 10

### Internally route client-to-client traffic
client-to-client

### Allow clients with duplicate "Common Name"
;duplicate-cn

### Legacy LZO adaptive compression
;comp-lzo adaptive
;push "comp-lzo adaptive"

### Keepalive and timeout
keepalive 10 60

### Process priority level (0..19)
nice 3

### Syslog verbose level
verb 0
mute 10

EOF
			chmod 644 "$user_ovpnsvr_conf"
		fi

		if [ ! -f "$user_ovpncli_conf" ] ; then
			cat > "$user_ovpncli_conf" <<EOF
# Custom user conf file for OpenVPN client
# Please add needed params only!

### Negotiable Crypto Parameters
ncp-disable

### If your server certificates with the nsCertType field set to "server"
remote-cert-tls server

### Process priority level (0..19)
nice 0

### Syslog verbose level
verb 0
mute 10

EOF
			chmod 644 "$user_ovpncli_conf"
		fi
	fi

	# create strongswan files
	if [ -x /usr/sbin/ipsec ] ; then
		[ ! -d "$dir_sswan" ] && mkdir -p -m 700 "$dir_sswan"
		[ ! -d "$dir_sswan_crt" ] && mkdir -p -m 700 "$dir_sswan_crt"
		[ ! -d "$dir_sswan_crt/cacerts" ] && mkdir -p -m 700 "$dir_sswan_crt/cacerts"
		[ ! -d "$dir_sswan_crt/certs" ] && mkdir -p -m 700 "$dir_sswan_crt/certs"
		[ ! -d "$dir_sswan_crt/private" ] && mkdir -p -m 700 "$dir_sswan_crt/private"

		if [ ! -f "$user_sswan_conf" ] ; then
			cat > "$user_sswan_conf" <<EOF
### strongswan.conf - user strongswan configuration file

EOF
			chmod 644 "$user_sswan_conf"
		fi
		if [ ! -f "$user_sswan_ipsec_conf" ] ; then
			cat > "$user_sswan_ipsec_conf" <<EOF
### ipsec.conf - user strongswan IPsec configuration file

EOF
			chmod 644 "$user_sswan_ipsec_conf"
		fi
		if [ ! -f "$user_sswan_secrets" ] ; then
			cat > "$user_sswan_secrets" <<EOF
### ipsec.secrets - user strongswan IPsec secrets file

EOF
			chmod 644 "$user_sswan_secrets"
		fi
	fi

if [ ! -f "$script0_script" ] ; then
	cat > "$script0_script" <<-\EEE
#!/bin/sh
#copyright by hiboy
[ -f /tmp/script0.lock ] && exit 0
touch /tmp/script0.lock
#脚本修改日期：2017-11-29
#↓↓↓功能详细设置(应用设置重启后生效，不能断电重启，要点击右上角重启按钮)↓↓↓
source /etc/storage/script/init.sh

# 迅雷快鸟 功能
#【2免U盘启动】需要填写【迅雷快鸟脚本】，生成脚本两种方法：
# 方法①：插入U盘，配置自定义脚本【1插U盘启动】启动快鸟一次即可自动生成
# 方法②：打开https://github.com/fffonion/Xunlei-FastDick，按照网页的说明在PC上运行脚本，登陆成功后会生成swjsq_wget.sh，把swjsq_wget.sh的内容粘贴此处即可
# 生成后需要到【系统管理】 - 【恢复/导出/上传设置】 - 【路由器内部存储 (/etc/storage)】【写入】保存脚本

# DDNS(删除#/tmp/sh_ddns.sh前面的#即可启动命令)
killall sh_ddns.sh
# 如何在路由器中设置花生壳服务
# http://service.oray.com/question/868.html
#/tmp/sh_ddns.sh /tmp/orayddns.log 'http://您的花生壳帐号:您的帐号密码@ddns.oray.com/ph/update?hostname=你的ddns域名' &
#/tmp/sh_ddns.sh /tmp/3322ddns.log 'http://DDNS用户名:DDNS密码@members.3322.org/dyndns/update?hostname=你的ddns域名' &

#↑↑↑功能详细设置↑↑↑

logger -t "【自定义脚本0】" "脚本完成"
rm -f /tmp/script0.lock

EEE
	chmod 755 "$script0_script"
fi





func_fill2

if [ ! -f "$Builds" ] ; then
#	强制更新脚本reset
	/sbin/mtd_storage.sh resetsh
fi

}




func_fill2()
{

	# create post-wan script
	if [ ! -f "$script_postw" ] ; then
		cat > "$script_postw" <<-\EEE
#!/bin/sh

### Custom user script
### Called after internal WAN up/down action
### $1 - WAN action (up/down)
### $2 - WAN interface name (e.g. eth3 or ppp0)
### $3 - WAN IPv4 address
logger  "运行后 WAN 状态:" "WAN 状态:【$1】, WAN 接口:【$2】, WAN IP:【$3】"

if [ $1 == "up" ] ; then
    sleep 30
    /etc/storage/crontabs_script.sh up &
fi

EEE
		chmod 755 "$script_postw"
	fi



if [ ! -f "$crontabs_script" ] ; then
	cat > "$crontabs_script" <<-\EEE
#!/bin/sh
#copyright by hiboy
export PATH='/etc/storage/bin:/tmp/script:/etc/storage/script:/opt/usr/sbin:/opt/usr/bin:/opt/sbin:/opt/bin:/usr/local/sbin:/usr/sbin:/usr/bin:/sbin:/bin'
export LD_LIBRARY_PATH=/lib:/opt/lib

#copyright by hiboy
if [ $1 == "up" ] ; then
    nvram set dnspod_status=0
    nvram set dns_com_pod_status=0
    nvram set cloudflare_status=0
    nvram set cloudxns_status=0
    nvram set aliddns_status=0
    nvram set qcloud_status=0
    nvram set ngrok_status=0
    nvram set kcptun_status=0
    nvram set tinyproxy_status=0
    nvram set mproxy_status=0
    #nvram set lnmp_status=0
    nvram set vpnproxy_status=0
    nvram set mentohust_status=0
    nvram set ss_status=0
    nvram set FastDicks_status=0
    nvram set display_status=0
    nvram set ssserver_status=0
    nvram set ssrserver_status=0
    nvram set wifidog_status=0
    nvram set frp_status=0
    nvram set serverchan_status=0
    nvram set softether_status=0
    nvram set cow_status=0
    nvram set meow_status=0
    nvram set ddnsto_status=0
fi

if [ -f /tmp/webui_yes ] ; then
    /etc/storage/script0_script.sh
    chmod 777 /etc/storage/script -R
    logger -t "【WebUI】" "UI 开关遍历状态监测"
    killall menu_title.sh 
    [ -f /etc/storage/www_sh/menu_title.sh ] && /etc/storage/www_sh/menu_title.sh 
    # start all services Sh??_* in /etc/storage/script
    for i in `ls /etc/storage/script/Sh??_* 2>/dev/null` ; do
        [ ! -x "${i}" ] && continue
        [ ! -f /tmp/webui_yes ] && continue
        eval ${i}
    done
    /tmp/sh_theme.sh &
else
    logger -t "【WebUI】" "稍等后启动相关设置"
fi
[ -f /tmp/crontabs.lock ] && exit 0
touch /tmp/crontabs.lock
http_username=`nvram get http_username`
cat > "/tmp/crontabs_DOMAIN.txt" <<-\EOF
# 基本格式 : 
# 0　　*　　*　　*　　*　　command 
# 分　时　日　月　周　命令 
# 在以上各个字段中，还可以使用以下特殊字符：
# 第一个数字（分钟）不能为*
# 星号（*）：代表所有可能的值，例如month字段如果是星号，则表示在满足其它字段的制约条件后每月都执行该命令操作。
# 逗号（,）：可以用逗号隔开的值指定一个列表范围，例如，“1,2,5,7,8,9”
# 中杠（-）：可以用整数之间的中杠表示一个整数范围，例如“2-6”表示“2,3,4,5,6”
# 正斜线（/）：可以用正斜线指定时间的间隔频率，例如“0-23/2”表示每两小时执行一次。同时正斜线可以和星号一起使用，例如*/10，如果用在minute字段，表示每十分钟执行一次。
 #删除开头的#启动命令 ：自定义设置 - 脚本 - 自定义 Crontab 定时任务配置
# 定时运行脚本规则 (删除前面的#即可启动命令)

# 每天的三点半重启
#30 3 * * * reboot & #删除开头的#启动命令
# 每星期一的三点半重启
#30 3 * * 1 reboot & #删除开头的#启动命令

# 下午6点定自动切换中继信号脚本【自动搜寻信道、自动搜寻信号】
#0 18 * * * /etc/storage/script/sh_ezscript.sh connAPSite_scan

# 凌晨2点定时关网：
#0 2 * * * stop_wan #删除开头的#启动命令

# 早上8点定时开网（重启wan口）：
#0 8 * * * restart_wan #删除开头的#启动命令

# 每天的一点【切换WAN模式】和【重启wan口】
#0 1 * * * /tmp/sh_wan_wips.sh wan & #删除开头的#启动命令
# 每天的十点切换wifi中继模式
#0 10 * * * /tmp/sh_wan_wips.sh wips & #删除开头的#启动命令

# 每6小时重启迅雷快鸟
#15 */6 * * * [ "`nvram get FastDick_enable`" = "1" ] && nvram set FastDicks_status=00 && /tmp/script/_Fast_Dick & #删除开头的#启动命令

# 每3小时重启迅雷下载
#5 */3 * * * [[ $(ps -w | grep "/xunlei/lib/" | grep -v "grep" | wc -l) == 3 ]] && killall EmbedThunderManager & #删除开头的#启动命令

# 每1小时重启花生壳内网版
#10 */1 * * * [ "`nvram get phddns`" = "1" ] && killall oraynewph && killall oraysl & #删除开头的#启动命令

# 每1小时重启DNSPod 域名解析
#13 */1 * * * nvram set dnspod_status=123 && /tmp/script/_dnspod & #删除开头的#启动命令

# 每1小时重启CloudXNS 域名解析
#16 */1 * * * nvram set cloudxns_status=123 && /tmp/script/_cloudxns & #删除开头的#启动命令

# 每1小时重启Cloudflare 域名解析
#16 */1 * * * nvram set cloudflare_status=123 && /tmp/script/_cloudflare & #删除开头的#启动命令

# 每1小时重启aliddns 域名解析
#16 */1 * * * nvram set aliddns_status=123 && /tmp/script/_aliddns & #删除开头的#启动命令

# 每1小时重启aliddns 域名解析
#16 */1 * * * nvram set qcloud_status=123 && /tmp/script/_qcloud & #删除开头的#启动命令

# 早上8点开启微信推送：
#0 8 * * * nvram set serverchan_enable=1 && nvram set serverchan_status=0 && /tmp/script/_server_chan & #删除开头的#启动命令

# 晚上10点关闭微信推送：
#0 22 * * * nvram set serverchan_enable=0 && nvram set serverchan_status=0 && /tmp/script/_server_chan & #删除开头的#启动命令

# 这里只能修改以上命令，如需自定义命令去【 系统管理 - 服务 - 计划任务 (Crontab)】设置


EOF
chmod 777 "/tmp/crontabs_DOMAIN.txt"

reboot_mode=`nvram get reboot_mode`
if [ "$reboot_mode" = "1" ] ; then
    reboot_hour=`nvram get reboot_hour`
    reboot_hour=`expr $reboot_hour + 0 `
    [ "$reboot_hour" -gt 23 ] && reboot_hour=23 && nvram set reboot_hour=$reboot_hour
    [ "$reboot_hour" -le 0 ] && reboot_hour=0 && nvram set reboot_hour=$reboot_hour
    reboot_minute=`nvram get reboot_minute`
    reboot_minute=`expr $reboot_minute + 0 `
    [ "$reboot_minute" -gt 59 ] && reboot_minute=59 && nvram set reboot_minute=$reboot_minute
    [ "$reboot_minute" -le 0 ] && reboot_minute=0 && nvram set reboot_minute=$reboot_minute
    echo "$reboot_minute $reboot_hour * * * reboot #删除开头的#启动命令" >> /tmp/crontabs_DOMAIN.txt
fi

if [ -z "`grep '删除开头的#启动命令' /etc/storage/cron/crontabs/$http_username`" ] ; then
echo "" > /etc/storage/cron/crontabs/$http_username
else
sed -Ei '/删除开头的/d' /etc/storage/cron/crontabs/$http_username
fi
grep '删除开头的' /tmp/crontabs_DOMAIN.txt | grep -v '^#' | sort -u | grep -v "^$" > /tmp/crontabs_DOMAIN2.txt
grep '删除开头的' /tmp/crontabs_DOMAIN2.txt | grep -v '^#' | sort -u | grep -v "^$" > /tmp/crontabs_DOMAIN.txt
grep -v '^#' /etc/storage/cron/crontabs/$http_username | sort -u | grep -v "^$" >> /tmp/crontabs_DOMAIN.txt
grep -v '^#' /tmp/crontabs_DOMAIN.txt | sort -u | grep -v "^$" > /etc/storage/cron/crontabs/$http_username
cat > "/tmp/sh_wan_wips.sh" <<-\EOF
#!/bin/sh
logger -t "【WAN、WIFI中继开关】" "切换模式:$1"
restartwan()
{
logger -t "【WAN、WIFI中继开关】" "重新链接 WAN"
restart_wan
sleep 10
logger -t "【WAN、WIFI中继开关】" "重新启动 2.4G WIFI"
radio2_restart
}
case "$1" in
wan)
#无线AP工作模式："0"=【AP（桥接被禁用）】"1"=【WDS桥接（AP被禁用）】"2"=【WDS中继（网桥 + AP）】"3"=【AP-Client（AP被禁用）】"4"=【AP-Client + AP】
nvram set rt_mode_x=0
nvram commit
restartwan

  ;;
wips)
#无线AP工作模式："0"=【AP（桥接被禁用）】"1"=【WDS桥接（AP被禁用）】"2"=【WDS中继（网桥 + AP）】"3"=【AP-Client（AP被禁用）】"4"=【AP-Client + AP】
nvram set rt_mode_x=4
nvram commit
restartwan

  ;;
esac

EOF
chmod 777 "/tmp/sh_wan_wips.sh"

[ "$upscript_enable" = "1" ] && cru.sh a upscript_update "1 1 * * * /etc/storage/script/sh_upscript.sh &" &
[ "$upscript_enable" != "1" ] && cru.sh d upscript_update &

/etc/storage/ap_script.sh crontabs &
rm -f /tmp/crontabs.lock

EEE
	chmod 755 "$crontabs_script"
fi

### 创建子程序脚本
cat > "/tmp/sh_theme.sh" <<-\EEF
#!/bin/sh
source /etc/storage/script/init.sh
export PATH='/etc/storage/bin:/tmp/script:/etc/storage/script:/opt/usr/sbin:/opt/usr/bin:/opt/sbin:/opt/bin:/usr/local/sbin:/usr/sbin:/usr/bin:/sbin:/bin'
export LD_LIBRARY_PATH=/lib:/opt/lib

theme_enable=`nvram get theme_enable`
[ -z $theme_enable ] && theme_enable=0 && nvram set theme_enable=$theme_enable
A_restart=`nvram get theme_status`
B_restart="$theme_enable"
#B_restart=`echo -n "$B_restart" | md5sum | sed s/[[:space:]]//g | sed s/-//g`
B_restart=`echo -n "$B_restart"`
if [ "$A_restart" != "$B_restart" ] ; then
	nvram set theme_status=$B_restart
	needed_restart=1
else
	needed_restart=0
fi
if [ "$theme_enable" = "0" ] && [ "$needed_restart" = "1" ] ; then
logger -t "【主题界面】" "停止下载主题包"
fi
SVC_PATH="/opt/share/www/custom/f.js"
if [ "$theme_enable" != "0" ] && [ ! -f "$SVC_PATH" ] ; then
	needed_restart=1
fi
if [ "$theme_enable" != "0" ] && [ "$needed_restart" = "1" ] ; then
rm -f $SVC_PATH
logger -t "【主题界面】" "部署主题风格包"
if [ ! -f "$SVC_PATH" ] ; then
	/tmp/script/_mountopt start
fi
if [ ! -f "$SVC_PATH" ] ; then
	mkdir -p /opt/share/www/custom
	rm -f $SVC_PATH
	if [ ! -f "$SVC_PATH" ] ; then
		logger -t "【主题界面】" "主题风格包下载 $theme_enable"
		rm -f /opt/share/www/custom/theme.tgz
		[ "$theme_enable" = "1" ] && wgetcurl.sh /opt/share/www/custom/theme.tgz "$hiboyfile/theme-big.tgz" "$hiboyfile2/theme-big.tgz"
		[ "$theme_enable" = "2" ] && wgetcurl.sh /opt/share/www/custom/theme.tgz "$hiboyfile/theme-lit.tgz" "$hiboyfile2/theme-lit.tgz"
		tar -xzvf /opt/share/www/custom/theme.tgz -C /opt/share/www/custom
		if [ ! -s "$SVC_PATH" ] ; then
			logger -t "【主题界面】" "解压不正常:/opt/share/www/custom"
			#nvram set theme_status=00
			exit 1
		fi
		rm -f /opt/share/www/custom/theme.tgz
	fi
fi
fi
sync;echo 3 > /proc/sys/vm/drop_caches
EEF
chmod 777 "/tmp/sh_theme.sh"

cat > "/tmp/sh_ddns.sh" <<-\EOF
#!/bin/sh
flie=$1
url=$2
logger -t "【DDNS】" "更新 IP 地址-$flie"
while [ "1" ];
do
[ -f "$flie" ] && sleep 66
[ -f "$flie" ] && rm -f $flie
wgetcurl.sh $flie $url $url N
sleep 666
continue
done
EOF
chmod 777 "/tmp/sh_ddns.sh"



cat > "/tmp/sh_adblock_hosts.sh" <<-\EOFH
#!/bin/sh
sleep 20
confdir=/tmp/ss/dnsmasq.d
ss_sub4=`nvram get ss_sub4`
mkdir /tmp/ss -p
	# adblock hosts广告过滤规则
	#处理最基础的广告域名替换为127.0.0.1 感谢 phrnet 的原帖：http://www.right.com.cn/forum/thread-184121-1-4.html
if [ "$ss_sub4" = "1" ] ; then
	wgetcurl.sh /tmp/ss/tmp_adhost.txt http://c.nnjsx.cn/GL/dnsmasq/update/adblock/malwaredomainlist.txt http://c.nnjsx.cn/GL/dnsmasq/update/adblock/malwaredomainlist.txt N
	cat /tmp/ss/tmp_adhost.txt | grep 127.0.0.1 | sed 's/127.0.0.1  //g' | dos2unix > /tmp/ss/adhost.txt
	wgetcurl.sh /tmp/ss/tmp_adhost.txt http://c.nnjsx.cn/GL/dnsmasq/update/adblock/yhosts.txt http://c.nnjsx.cn/GL/dnsmasq/update/adblock/yhosts.txt N
	cat /tmp/ss/tmp_adhost.txt | grep 127.0.0.1 | sed 's/127.0.0.1 //g' | dos2unix >> /tmp/ss/adhost.txt
	wgetcurl.sh /tmp/ss/tmp_adhost.txt http://c.nnjsx.cn/GL/dnsmasq/update/adblock/easylistchina.txt http://c.nnjsx.cn/GL/dnsmasq/update/adblock/easylistchina.txt N
	cat /tmp/ss/tmp_adhost.txt | grep 127.0.0.1 | sed 's/address=\///g; s/\/127.0.0.1//g' | dos2unix >> /tmp/ss/adhost.txt
	cat /tmp/ss/adhost.txt | sort -u | sed '/^[0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+$/d; s/^/address=\//; s/$/\/127.0.0.1/' > $confdir/r.adhost.conf
	rm -rf /tmp/ss/tmp_adhost.txt
	sed -Ei "/conf-dir=\/tmp\/ss\/dnsmasq.d/d" /etc/storage/dnsmasq/dnsmasq.conf
	[ ! -z "$confdir" ] && echo "conf-dir=$confdir" >> /etc/storage/dnsmasq/dnsmasq.conf
else
	rm -f $confdir/r.adhost.conf
fi
	logger -t "【Adblock hosts】" "规则： `sed -n '$=' $confdir/r.adhost.conf | sed s/[[:space:]]//g ` 行"
	nvram set adhosts="ad hosts规则： `sed -n '$=' $confdir/r.adhost.conf | sed s/[[:space:]]//g ` 行"
restart_dhcpd
EOFH
chmod 755 "/tmp/sh_adblock_hosts.sh"



if [ ! -f "$script_script" ] ; then
	cat > "$script_script" <<-\EEE
#!/bin/sh
#copyright by hiboy
#/etc/storage/script/sh_0_script.sh
#/etc/storage/script_script.sh
source /etc/storage/script/init.sh
source /etc/storage/script/sh_0_script.sh
EEE
	chmod 755 "$script_script"
fi

}

func_flock()
{

st=$1
st2=$(expr "$st" + 5)
date "+%s" > $sfl
(
	sleep 1
	flock 333
	expr_time
	[ $ctime -lt 0 ] && return 1
	expr_time
	[ $ctime -gt 0 ] && sleep $st
	while [ $ctime -lt $st2 ]; do 
		sleep 1
		expr_time
		if [ $ctime -ge $st ] ; then
			date "+%s0" > $sfl
			[ -f "$slk" ] && return 1
			touch "$slk"
			logger -t "【mtd_storage.sh】" "保存 /etc/storage/ 内容到闪存！请勿关机"
			/sbin/mtd_storage.sh save_2
			rm -f $slk
			logger -t "【mtd_storage.sh】" "保存 /etc/storage/ 内容到闪存！执行完成"
			return 0
		fi
	done

) 333>/var/lock/storage_flock.lock

}

atime=0
btime=0
ctime=0
sfl="/tmp/.storage_flock_locked"
expr_time()
{
atime=$(cat $sfl)
atime=`echo ${atime:5}`
btime=$(date "+%s")
btime=`echo ${btime:5}`
ctime=$(expr "$btime" - "$atime")
}


case "$1" in
load)
    func_get_mtd
    func_mdir
    func_load
    ;;
save_flock)
    func_mdir
    func_fill
    func_flock 3 &
    ;;
save_2)
    func_get_mtd
    func_mdir
    func_tarb
    func_save
    ;;
save)
    [ -f "$slk" ] && exit 1
    func_get_mtd
    func_mdir
    func_tarb
    func_save
    ;;
backup)
    func_get_mtd
    func_mdir
    func_tarb
    func_backup
    ;;
restore)
    func_get_mtd
    func_restore
    ;;
erase)
    func_get_mtd
    func_erase
    ;;
reset)
    func_stop_apps
    func_reset
    echo "Builds" > $Builds
    func_fill
    func_start_apps
    ;;
resetsh)
    func_resetsh
    echo "Builds" > $Builds
    func_fill
    ;;
fill)
    func_mdir
    func_fill
    ;;
*)
    echo "Usage: $0 {load|save|backup|restore|erase|reset|fill}"
    exit 1
    ;;
esac

exit $result


