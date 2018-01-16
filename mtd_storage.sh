#!/bin/sh

Builds="/etc/storage/Builds-2018-1-16"
result=0
mtd_part_name="Storage"
mtd_part_dev="/dev/mtdblock5"
mtd_part_size=200000
dir_storage="/etc/storage"
slk="/tmp/.storage_locked"
tmp="/tmp/storage.tar"
tbz="${tmp}.bz2"
hsh="/tmp/hashes/storage_md5"
config_qos="/etc/storage/qos.conf"
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
kmskey="/etc/storage/key"
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
	if [ -n "$mtd_idx" ] && [ $mtd_idx -ge 4 ] ; then
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
	# 删除UI配置文件
	#rm -f $jbls_script $vlmcsdini_script $config_tinyproxy $config_mproxy $shadowsocks_ss_spec_lan $shadowsocks_ss_spec_wan $kcptun_script $SSRconfig_script 
	#rm -f $ngrok_script $frp_script $ddns_script $ad_config_script $adbyby_rules_script $adm_rules_script $koolproxy_rules_list $koolproxy_rules_script
	#rm -f /etc/storage/v2ray_config_script.sh /etc/storage/cow_config_script.sh /etc/storage/meow_config_script.sh /etc/storage/meow_direct_script.sh 
	# rm -f $koolproxy_rules_list $vlmcsdini_script
	
	# 删除UI脚本文件
	#rm -f /etc/storage/v2ray_script.sh /etc/storage/cow_script.sh /etc/storage/meow_script.sh /etc/storage/softether_script.sh
	
	# 删除内部脚本文件
	# rm -f $script0_script $script_script $script1_script $script2_script $script3_script $crontabs_script $kmskey $DNSPOD_script $cloudxns_script $aliddns_script
	# rm -f $serverchan_script $script_start $script_started $script_postf $script_postw $script_inets $script_vpnsc $script_vpncs $script_ezbtn 
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
[ ! -s /etc/storage/qos.conf ] && [ -s /etc_ro/qos.conf ] && cp -f /etc_ro/qos.conf /etc/storage
ln -sf /etc/storage/PhMain.ini /etc/PhMain.ini &
ln -sf /etc/storage/init.status /etc/init.status &
[ ! -s /etc/storage/script/init.sh ] && [ -s /etc_ro/script.tgz ] && tar -xzvf /etc_ro/script.tgz -C /etc/storage/
[ -s /etc/storage/script/init.sh ] && chmod 777 /etc/storage/script -R
[ ! -s /etc/storage/www_sh/menu_title.sh ] && [ -s /etc_ro/www_sh.tgz ] && tar -xzvf /etc_ro/www_sh.tgz -C /etc/storage/
[ -s /etc/storage/www_sh/menu_title.sh ] && chmod 777 /etc/storage/www_sh -R
[ ! -s /etc/storage/bin/daydayup ] && [ -s /etc_ro/daydayup ] && ln -sf /etc_ro/daydayup /etc/storage/bin/daydayup
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
### SMB资源挂载(局域网共享映射，无USB也能挂载储存空间)
### 说明：username=、password=填账号密码，删除代码前面的#启用功能。
#sleep 10
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
/etc/storage/ez_buttons_script.sh 3 &
logger -t "【运行路由器启动后】" "脚本完成"

# Office手动激活CMD命令：

# cd C:\Program Files\Microsoft Office\Office15
# cscript ospp.vbs /sethst:192.168.123.1
# cscript ospp.vbs /act
# cscript ospp.vbs /dstatus

# windows手动激活CMD命令：

# slmgr.vbs /upk
# slmgr.vbs /skms 192.168.123.1
# slmgr.vbs /ipk XXXXX-XXXXX-XXXXX-XXXXX-XXXXX
# slmgr.vbs /ato
# slmgr.vbs /xpr

# key查看
# cat /etc/storage/key


#启动流量监控脚本
mkdir -p /tmp/bwmon
/usr/sbin/bwmon &


# 固件将加入使用情况统计 （感谢bigandy提供）

# 统计系统原因：
# 由于低容量固件（8M）的运行以及开启OPT后，部分程序需要实时从外部网络获取，
# 导致引起不少软件下载服务器或网盘等服务提供者的流量超标。
# 为了固件可以更加稳定运行，我们准备建立自己的软件下载服务器，但在建立下载服务器前，
# 我们希望了解一下固件被使用的情况，因此会加入一些与用户个人隐私无关的数据采集。

# 将会采集的数据内容仅包括如下内容：

# PN: 固件名称，由每次固件编译时候产生一个固定值。
# VER：固件版本，由每次固件编译时候产生一个固定值。
# UUID： 由系统自动生成的Linux UUID，一次性产生，随时可以删除重新产生随机数。
# 重置路由后会清除此ID，然后由系统随机重新生成。
    # 生成方式 nvram set pdcn_uuid=`cat /proc/sys/kernel/random/uuid`，生成后保存在 nvram 里面，
    # 直到路由被重置或者手动删除此id。如果不希望发送此数值，可以删除对应的数据提交脚本中的相应内容。
# OPT：OPT状态，用于得知是否需要下载或者更新 OPT 内容，以统计OPT下载服务所需要的带宽。
# 0：为没有，1，外置存储， 2， 内存虚拟盘

# 提交方式：
# wget 带参数。

# 以上便是所有将会提交到统计服务器的数据内容，如果觉得我们还会提交其他数据，
# 欢迎检查提交数据的脚本源码以及对提交行为进行抓包检查。



# 采集频度：
# 每次路由重新上电开机，也就是重启或者冷启动。
# 原因：路由中第三方程序以及OPT的载入在每次重启后向服务器请求下载，有了这个统计数据，
# 我们才能计算需要一台多少带宽的服务器提供第三方软件下载功能。

# 抵制方式：
# 如果你非常抗拒这种数据的采集行为，可以用以下方法关闭：
# 首次刷入或者重置后，不要联网，进入自定义脚本中，删除对应的采集语句。

# 但我们希望你不要抵制这个采集行为，毕竟需要提供的数据比任何一款软件自动升级的提交内容都要少。
# 这也是作为将来固件检测自动升级的一个标准动作，今后的下载服务器也会通过获取这些数据提供下载服务。

ss_opt_x=`nvram get ss_opt_x`
upanPath=""
[ "$ss_opt_x" = "3" ] && upanPath="`df -m | grep /dev/mmcb | grep "/media" | awk '{print $NF}' | sort -u | awk 'NR==1' `"
[ "$ss_opt_x" = "4" ] && upanPath="`df -m | grep "/dev/sd" | grep "/media" | awk '{print $NF}' | sort -u | awk 'NR==1' `"
[ -z "$upanPath" ] && [ "$ss_opt_x" = "1" ] && upanPath="`df -m | grep /dev/mmcb | grep "/media" | awk '{print $NF}' | sort -u | awk 'NR==1' `"
[ -z "$upanPath" ] && [ "$ss_opt_x" = "1" ] && upanPath="`df -m | grep "/dev/sd" | grep "/media" | awk '{print $NF}' | sort -u | awk 'NR==1' `"
echo "$upanPath"
if [ ! -z "$upanPath" ] ; then 
    #已挂载储存设备
    opt_value="1"
else
    #未挂载储存设备
    opt_value="0"
    [ -s /opt/bin/curl ] && opt_value="2"
fi
echo $opt_value
PN=`grep Web_Title= /www/EN.dict | sed 's/Web_Title=//g'| sed 's/ 无线路由器//g'`
VER=`nvram get firmver_sub`
pdcn_uuid=`nvram get pdcn_uuid`
[ -z $pdcn_uuid ] && pdcn_uuid=`cat /proc/sys/kernel/random/uuid` && nvram set pdcn_uuid=$pdcn_uuid
pdcn_uuid_enable=`nvram get pdcn_uuid_enable`
[ -z "$pdcn_uuid_enable" ] && pdcn_uuid_enable=1 && nvram set pdcn_uuid_enable=1

# 提交统计
if [ "$pdcn_uuid_enable" = "1" ] ; then
wget --no-check-certificate -O /dev/null http://pdcn.cn2k.net:8080/create?pn=$PN\&ver=$VER\&ID=$pdcn_uuid\&opt=$opt_value &
fi

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
#copyright by Emong's Qos update hiboy
/etc/storage/crontabs_script.sh &
export PATH='/etc/storage/bin:/tmp/script:/etc/storage/script:/opt/usr/sbin:/opt/usr/bin:/opt/sbin:/opt/bin:/usr/local/sbin:/usr/sbin:/usr/bin:/sbin:/bin'
export LD_LIBRARY_PATH=/lib:/opt/lib
# qos 功能 0关闭；1启动
qoss=0
# 当在线终端≤2台时取消限速.(路由端1+电脑端1=2台)
qosb=2
# 默认为20M
DOWN=2560
UP=256
[ "$qoss" = "1" ] && logger -t "【QOS】" "最大下载 $DOWN KB/S,最大上传 $UP KB/S"
# IP限速设置
# 未设置的IP带宽减半,如启用adbyby,因7620的CPU瓶颈,宽带峰值50M
# 注意参数之间有空格
# 可选项：删除前面的#可生效
# [KB/S]IP地址 最大下载 下载保证 最大上传 上传保证
cat > "/tmp/qos_ip_limit_DOMAIN.txt" <<-\EOF
#192.168.123.115 2560 100 200 20
192.168.123.2-192.168.123.244 2560 100 100 15



EOF
# 连接数限制
#如果开启该功能后,打开下载软件可能会导致QQ等聊天软件掉线.(因为连接数量会被占光)
# IP地址 TCP连接数 UDP连接数
cat > "/tmp/qos_connlmt_DOMAIN.txt" <<-\EOF
#192.168.123.10 100 100
192.168.123.20-192.168.123.25 100 100


EOF
# 端口优先
# 请勿添加下载应用的端口80、8080等等.由于没有被流量控制和处理优先级,下载应用会占用大量资源导致网络卡
# 协议 端口
cat > "/tmp/qos_port_first_DOMAIN.txt" <<-\EOF
UDP 53
TCP 22
TCP 23
#TCP 443
TCP 1723
#TCP 3389
TCP 3724,1119,1120
TCP 28012,10008,13006,2349,7101:7103
UDP 2349,12000:12175



EOF

load_var() {
    WAN_IF="imq1"
    LAN_IF="imq0"
    WAN_IFT=$(nvram get wan0_ifname_t)
    IPM="iptables -t mangle"
    lan_ip="`nvram get lan_ipaddr`/24"

}

load_modules(){
[ ! -f /tmp/qos-emong-modules ] && {
    modprobe act_connmark    #缺,补621-sched_act_connmark.patch@597
    for module in imq ipt_IMQ ipt_web xt_length xt_hashlimit cls_fw sch_htb sch_sfq sch_red xt_length xt_IMQ ipt_ipp2p xt_dscp xt_DSCP cls_u32 sch_hfsc sch_prio ipt_multiport ipt_CONNMARK ipt_length ipt_hashlimit xt_connlimit xt_connbytes ipt_connlimit em_u32 sch_ingress act_mirred
    do
        modprobe $module
    done
    modprobe imq numdevs=1
    echo >/tmp/qos-emong-modules
    }
}

qos_stop() {
    tc qdisc del dev $WAN_IF root
    tc qdisc del dev $LAN_IF root

    $IPM -F
    $IPM -X UP
    $IPM -X DOWN
    $IPM -X IP_DOWN
    $IPM -X IP_UP
}

qos_start(){

    ip link set imq0 up
    ip link set imq1 up
    tc qdisc add dev $WAN_IF root handle 1: htb
    tc qdisc add dev $LAN_IF root handle 1: htb
    tc class add dev $WAN_IF parent 1: classid 1:2 htb rate $((UP))kbps
    tc class add dev $LAN_IF parent 1: classid 1:2 htb rate $((DOWN))kbps
    
    tc class add dev $WAN_IF parent 1: classid 1:1 htb rate $((UP*95/100))kbps
    tc class add dev $WAN_IF parent 1:1 classid 1:11 htb rate $((UP*5/10))kbps prio 1
    tc class add dev $WAN_IF parent 1:1 classid 1:12 htb rate $((UP*5/10))kbps ceil $((UP*9/10))kbps prio 2
    tc class add dev $WAN_IF parent 1:12 classid 1:121 htb rate $((UP*4/10))kbps ceil $((UP*8/10))kbps prio 1
    tc class add dev $WAN_IF parent 1:12 classid 1:122 htb rate $((UP*1/10))kbps ceil $((UP*4/10))kbps prio 2
    tc class add dev $WAN_IF parent 1:12 classid 1:123 htb rate $((UP*4/10))kbps ceil $((UP*6/10))kbps prio 3
    tc qdisc add dev $WAN_IF parent 1:11 handle 11: sfq perturb 10
    tc qdisc add dev $WAN_IF parent 1:121 handle 121: sfq perturb 10
    tc qdisc add dev $WAN_IF parent 1:122 handle 122: sfq perturb 10
    tc qdisc add dev $WAN_IF parent 1:123 handle 123: sfq perturb 10
    tc filter add dev $WAN_IF parent 1: handle 0x10/0xfff0 fw classid 1:11
    tc filter add dev $WAN_IF parent 1: handle 0x20/0xfff0 fw classid 1:121
    tc filter add dev $WAN_IF parent 1: handle 0x30/0xfff0 fw classid 1:122
    tc filter add dev $WAN_IF parent 1: handle 0x40/0xfff0 fw classid 1:123
    
    tc class add dev $LAN_IF parent 1: classid 1:1 htb rate $((DOWN*95/100))kbps
    tc class add dev $LAN_IF parent 1:1 classid 1:11 htb rate $((DOWN*5/10))kbps prio 1
    tc class add dev $LAN_IF parent 1:1 classid 1:12 htb rate $((DOWN*5/10))kbps ceil $((DOWN*9/10))kbps prio 2
    tc class add dev $LAN_IF parent 1:12 classid 1:121 htb rate $((DOWN*4/10))kbps ceil $((DOWN*8/10))kbps prio 1
    tc class add dev $LAN_IF parent 1:12 classid 1:122 htb rate $((DOWN*1/10))kbps ceil $((DOWN*4/10))kbps prio 10
    tc class add dev $LAN_IF parent 1:12 classid 1:123 htb rate $((DOWN*4/10))kbps ceil $((DOWN*6/10))kbps prio 3
    tc qdisc add dev $LAN_IF parent 1:11 handle 11: sfq perturb 10
    tc qdisc add dev $LAN_IF parent 1:121 handle 121: sfq perturb 10
    tc qdisc add dev $LAN_IF parent 1:122 handle 122: sfq perturb 10
    tc qdisc add dev $LAN_IF parent 1:123 handle 123: sfq perturb 10
    tc filter add dev $LAN_IF parent 1: handle 0x10/0xfff0 fw classid 1:11
    tc filter add dev $LAN_IF parent 1: handle 0x20/0xfff0 fw classid 1:121
    tc filter add dev $LAN_IF parent 1: handle 0x30/0xfff0 fw classid 1:122
    tc filter add dev $LAN_IF parent 1: handle 0x40/0xfff0 fw classid 1:123
    
    $IPM -N UP
    $IPM -N DOWN
    $IPM -N IP_UP
    $IPM -N IP_DOWN
    $IPM -I POSTROUTING -o br0 -j DOWN
    $IPM -I PREROUTING -i br0 -j UP
    $IPM -A DOWN -j IMQ --todev 0
    $IPM -A UP -j IMQ --todev 1
    #$IPM -I DOWN -s $lan_ip -j RETURN
    $IPM -I DOWN -p tcp -m multiport --dports 22,53,445,139 -j RETURN
    $IPM -I DOWN -p icmp -j RETURN
    #$IPM -A DOWN -m length --length :100 -j RETURN
    $IPM -A DOWN -j MARK --set-mark=0x41
    $IPM -A DOWN -m length --length 1024:1500 -j MARK --set-mark=0x31
    $IPM -A DOWN -p tcp -m multiport --dports 21,80,443,3389,8118 -j MARK --set-mark=0x21
    $IPM -A DOWN -m length --length :768 -j MARK --set-mark=0x11
    
    $IPM -A DOWN -j IP_DOWN
    
    #$IPM -I UP -d $lan_ip -j RETURN
    $IPM -I UP -p tcp -m multiport --sports 22,53,445,139 -j RETURN
    $IPM -I UP -p icmp -j RETURN
    #$IPM -A UP -m length --length :80 -j RETURN
    $IPM -A UP -j MARK --set-mark=0x41
    $IPM -A UP -m length --length 1024:1500 -j MARK --set-mark=0x31
    $IPM -A UP -p tcp -m multiport --sports 21,80,443,3389,8118 -j MARK --set-mark=0x21
    $IPM -A UP -m length --length :512 -j MARK --set-mark=0x11
    
    $IPM -A UP -j IP_UP

}

connlmt() {
    $IPM -A FORWARD -p tcp -d $1 -m connlimit --connlimit-above $2 -j DROP
    $IPM -A FORWARD -p udp -d $1 -m connlimit --connlimit-above $3 -j DROP

}

ip_limit() {
conns=$6
[ $((conns)) -lt "6" ] && logger -t "【QOS】" "限速设置[KB/S]IP:$1, 最大下载:$2, 下载保证:$3, 最大上传:$4, 上传保证:$5"
[ $((conns)) -ge "6" ] && logger -t "【QOS】" "连接数限制IP:$1 TCP:$2, UDP:$3"
n=$(echo $1|cut -d '-' -f1|cut -d '.' -f4)
m=$(echo $1|cut -d '-' -f2|cut -d '.' -f4)
NET=$(echo $1|cut -d '.' -f1-3)
while [ $n -le $m ]
do
    ip=$n
    if [ $((conns)) -lt "6" ] ; then
        [ ${#ip} -lt 3 ] && ip=0$ip
        [ ${#ip} -lt 3 ] && ip=0$ip
        var=1
        
        tc class add dev $WAN_IF parent 1:2 classid 1:$var$ip htb rate $5kbps ceil $4kbps
        tc qdisc add dev $WAN_IF parent 1:$var$ip handle $var$ip sfq perturb 10
        tc filter add dev $WAN_IF parent 1: handle 0x$var$ip fw flowid 1:$var$ip
        
        tc class add dev $LAN_IF parent 1:2 classid 1:$var$ip htb rate $3kbps ceil $2kbps
        tc qdisc add dev $LAN_IF parent 1:$var$ip handle $var$ip sfq perturb 10
        tc filter add dev $LAN_IF parent 1: handle 0x$var$ip fw flowid 1:$var$ip
        
        $IPM -A IP_DOWN -d $NET.$n -j MARK --set-mark 0x$var$ip
        $IPM -A IP_UP -s $NET.$n -j MARK --set-mark 0x$var$ip
    else
        connlmt $NET.$n $2 $3
    fi
n=$((n+1))
done

}

port_first() {
logger -t "【QOS】" "端口优先:$1, $2"
$IPM -I DOWN -p $1 -m multiport --dports $2 -j RETURN
$IPM -I UP -p $1 -m multiport --sports $2 -j RETURN

}
tinyproxy_enable=`nvram get tinyproxy_enable`
if [ "$tinyproxy_enable" = "1" ] ; then
    tinyproxy_port=`nvram get tinyproxy_port`
    if [ "$tinyproxy_port" = "1" ] ; then
        tinyproxyport=$(echo `cat /etc/storage/tinyproxy_script.sh | grep -v "^#" | grep -v "ConnectPort" | grep "Port" | sed 's/Port//'`)
        echo "tinyproxyport:$tinyproxyport"
        logger -t "【tinyproxy】" "允许 $tinyproxyport 端口通过防火墙"
        iptables -I INPUT -p tcp --dport $tinyproxyport -j ACCEPT
    fi
fi
mproxy_enable=`nvram get mproxy_enable`
if [ "$mproxy_enable" = "1" ] ; then
    mproxy_port=`nvram get mproxy_port`
    if [ "$mproxy_port" = "1" ] ; then
        mproxyport=$(echo `cat /etc/storage/mproxy_script.sh | grep -v "^#" | grep "mproxy_port=" | sed 's/mproxy_port=//'`)
        echo "mproxyport:$mproxyport"
        logger -t "【mproxy】" "允许 $mproxyport 端口通过防火墙"
        iptables -I INPUT -p tcp --dport $mproxyport -j ACCEPT
    fi
fi
vpnproxy_enable=`nvram get vpnproxy_enable`
if [ "$vpnproxy_enable" = "1" ] ; then
    vpnproxy_wan_port=`nvram get vpnproxy_wan_port`
        echo "vpnproxy_wan_port:$vpnproxy_wan_port"
        logger -t "【vpnproxy】" "允许 $vpnproxy_wan_port 端口通过防火墙"
        iptables -I INPUT -p tcp --dport $vpnproxy_wan_port -j ACCEPT
fi
lnmp_enable=`nvram get lnmp_enable`
default_enable=`nvram get default_enable`
if [ "$default_enable" = "1" ] && [ "$lnmp_enable" = "1" ] ; then
    default_port=`nvram get default_port`
        echo "default_port:$default_port"
        logger -t "【默认主页】" "默认服务网站允许远程访问, 允许 $default_port 端口通过防火墙"
        iptables -I INPUT -p tcp --dport $default_port -j ACCEPT
fi
mysql_enable=`nvram get mysql_enable`
if [ "$mysql_enable" = "1" ] && [ "$lnmp_enable" = "1" ] ; then
        logger -t "【MySQL】" "允许远程访问, 允许 3306 端口通过防火墙"
        iptables -I INPUT -p tcp --dport 3306 -j ACCEPT
fi
kodexplorer_enable=`nvram get kodexplorer_enable`
if [ "$kodexplorer_enable" = "1" ] && [ "$lnmp_enable" = "1" ] ; then
    kodexplorer_port=`nvram get kodexplorer_port`
        echo "kodexplorer_port:$kodexplorer_port"
        logger -t "【芒果云】" "允许远程访问, 允许 $kodexplorer_port 端口通过防火墙"
        iptables -I INPUT -p tcp --dport $kodexplorer_port -j ACCEPT
fi
owncloud_enable=`nvram get owncloud_enable`
if [ "$owncloud_enable" = "1" ] && [ "$lnmp_enable" = "1" ] ; then
    owncloud_port=`nvram get owncloud_port`
        echo "owncloud_port:$owncloud_port"
        logger -t "【OwnCloud私有云】" "允许远程访问, 允许 $owncloud_port 端口通过防火墙"
        iptables -I INPUT -p tcp --dport $owncloud_port -j ACCEPT
fi
phpmyadmin_enable=`nvram get phpmyadmin_enable`
if [ "$phpmyadmin_enable" = "1" ] && [ "$lnmp_enable" = "1" ] ; then
    phpmyadmin_port=`nvram get phpmyadmin_port`
        echo "phpmyadmin_port:$phpmyadmin_port"
        logger -t "【phpMyAdmin】" "允许远程访问, 允许 $phpmyadmin_port 端口通过防火墙"
        iptables -I INPUT -p tcp --dport $phpmyadmin_port -j ACCEPT
fi
wifidog_server_enable=`nvram get wifidog_server_enable`
if [ "$wifidog_server_enable" = "1" ] && [ "$lnmp_enable" = "1" ] ; then
    wifidog_server_port=`nvram get wifidog_server_port`
        echo "wifidog_server_port:$wifidog_server_port"
        logger -t "【wifidog_server】" "允许远程访问, 允许 $wifidog_server_port 端口通过防火墙"
        iptables -I INPUT -p tcp --dport $wifidog_server_port -j ACCEPT
fi
ssserver_enable=`nvram get ssserver_enable`
if [ "$ssserver_enable" = "1" ] ; then
    ssserver_port=`nvram get ssserver_port`
        echo "ssserver_port:$ssserver_port"
        logger -t "【ss-server】" "允许 $ssserver_port 端口通过防火墙"
        iptables -I INPUT -p tcp --dport $ssserver_port -j ACCEPT
        iptables -I INPUT -p udp --dport $ssserver_port -j ACCEPT
fi
shellinabox_enable=`nvram get shellinabox_enable`
shellinabox_wan=`nvram get shellinabox_wan`
if [ "$shellinabox_enable" = "1" ] || [ "$shellinabox_enable" = "2" ] && [ "$shellinabox_wan" = "1" ] ; then
    shellinabox_port=`nvram get shellinabox_port`
        echo "shellinabox_port:$shellinabox_port"
        logger -t "【shellinabox】" "允许 $shellinabox_port 端口通过防火墙"
        iptables -I INPUT -p tcp --dport $shellinabox_port -j ACCEPT
fi
softether_enable=`nvram get softether_enable`
if [ "$softether_enable" = "1" ] ; then
        logger -t "【softether】" "允许 500、4500、1701 udp端口通过防火墙"
        iptables -I INPUT -p udp --destination-port 500 -j ACCEPT
        iptables -I INPUT -p udp --destination-port 4500 -j ACCEPT
        iptables -I INPUT -p udp --destination-port 1701 -j ACCEPT
fi
syncthing_enable=`nvram get syncthing_enable`
syncthing_wan=`nvram get syncthing_wan`
syncthing_wan_port=`nvram get syncthing_wan_port`
if [ "$syncthing_enable" = "1" ] ; then
    logger -t "【syncthing】" "允许 22000 $syncthing_wan_port tcp、21025,21026,21027 udp端口通过防火墙"
    iptables -t filter -I INPUT -p tcp --dport 22000 -j ACCEPT
    iptables -t filter -I INPUT -p udp -m multiport --dports 21025,21026,21027 -j ACCEPT
    if [ "$syncthing_wan" = "1" ] ; then
        logger -t "【syncthing】" "WebGUI 允许 $syncthing_wan_port tcp端口通过防火墙"
        iptables -t filter -I INPUT -p tcp --dport $syncthing_wan_port -j ACCEPT
    fi
fi
if [ "$qoss" = "1" ] && [ -f "/lib/modules/$(uname -r)/kernel/net/netfilter/xt_IMQ.ko" ] ; then
    if [ $(cat /tmp/qos_state) -eq 1 ] ; then
    logger -t "【QOS】" "正在运行"
    exit
    else
    echo 1 >/tmp/qos_state
    fi
    logger -t "【QOS】" "启动 QOS 成功"
    echo 1 >/tmp/qoss_state
    load_var
    load_modules
    qos_stop
    qos_start
    while read line
    do
    c_line=`echo $line |grep -v "#"`
    if [ ! -z "$c_line" ] ; then
        ip_limit $line
    fi
    done < /tmp/qos_ip_limit_DOMAIN.txt
    
    while read line
    do
    c_line=`echo $line |grep -v "#"`
    if [ ! -z "$c_line" ] ; then
        line="$line 4 5 6"
        ip_limit $line
    fi
    done < /tmp/qos_connlmt_DOMAIN.txt
    
    while read line
    do
    c_line=`echo $line |grep -v "#"`
    if [ ! -z "$c_line" ] ; then
        port_first $line
    fi
    done < /tmp/qos_port_first_DOMAIN.txt
    if [ ! -f /tmp/qos_scheduler.lock ] ; then
        /tmp/qos_scheduler.sh $qosb &
    fi
    echo 0 >/tmp/qos_state
else
    logger -t "【QOS】" "QOS 没有开启或闪存不足缺模块"
    echo 0 >/tmp/qoss_state
    ip link set imq0 down
    ip link set imq1 down
fi

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
apauto=0

# AP连接成功条件，【0】 连上AP即可，不检查是否联网；【1】 连上AP并连上Internet互联网。
apauto2=0

# 【0】 联网断线后自动搜寻，大于【10】时则每隔【N】秒搜寻(无线网络会瞬断一下)，直到连上最优先信号。
aptime="0"

# 如搜寻的AP不联网则列入黑名单/tmp/apblack.txt 功能 【0】关闭；【1】启动
# 控制台输入【echo "" > /tmp/apblack.txt】可以清空黑名单
apblack=0

# 自定义分隔符号，默认为【@】，注意:下面配置一同修改
fenge='@'

# 【自动切换中继信号】功能 填写配置参数启动
cat >/tmp/ap2g5g.txt <<-\EOF
# 中继AP配置填写说明：
# 各参数用【@】分割开，如果有多个信号可回车换行继续填写即可(从第一行的参数开始搜寻)【第一行的是最优先信号】
# 搜寻时无线网络会瞬断一下
# 参数说明：
# ①2.4Ghz或5Ghz："2"=【2.4Ghz】"5"=【5Ghz】
# ②无线AP工作模式："0"=【AP（桥接被禁用）】"1"=【WDS桥接（AP被禁用）】"2"=【WDS中继（网桥 + AP）】"3"=【AP-Client（AP被禁用）】"4"=【AP-Client + AP】
# ③无线AP-Client角色： "0"=【LAN bridge】"1"=【WAN (Wireless ISP)】
# ④中继AP 的 SSID："ASUS"
# ⑤中继AP 密码："1234567890"
# ⑥中继AP 的 MAC地址："20:76:90:20:B0:F0"【可以不填，不限大小写】
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
    logger -t "【AP 中继】" "连接守护启动"
    while true; do
        if [ ! -f /tmp/apc.lock ] ; then
            if [[ $(cat /tmp/apauto.lock) == 1 ]] ; then
            #【1】 当中继信号断开时启动自动搜寻
                a2=`iwconfig apcli0 | awk -F'"' '/ESSID/ {print $2}'`
                a5=`iwconfig apclii0 | awk -F'"' '/ESSID/ {print $2}'`
                [ "$a2" = "" -a "$a5" = "" ] && ap=1 || ap=0
                if [ "$ap" = "1" ] ; then
                    logger -t "【AP 中继】" "连接中断，启动自动搜寻"
                    /etc/storage/inet_state_script.sh 0 t &
                fi
            fi
            if [[ $(cat /tmp/apauto.lock) == 0 ]] ; then
            #【2】 Internet互联网断线后自动搜寻
            ping_text=`ping -4 114.114.114.114 -c 1 -w 2 -q`
            ping_time=`echo $ping_text | awk -F '/' '{print $4}'| awk -F '.' '{print $1}'`
            ping_loss=`echo $ping_text | awk -F ', ' '{print $3}' | awk '{print $1}'`
            if [ ! -z "$ping_time" ] ; then
                echo "ping：$ping_time ms 丢包率：$ping_loss"
             else
                echo "ping：失效"
            fi
            if [ ! -z "$ping_time" ] ; then
            echo "online"
            else
                echo "Internet互联网断线后自动搜寻"
                    /etc/storage/inet_state_script.sh 0 t &
                fi
            fi
        fi
        sleep 69
    done
EOF
    chmod 777 "/tmp/sh_apauto.sh"
    echo $apauto > /tmp/apauto.lock
    [ "$1" = "crontabs" ] && /tmp/sh_apauto.sh &
else
    echo "" > /tmp/apauto.lock
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

# 【自动切换中继信号】功能 需要到【无线网络 - 无线桥接】页面配置



. /etc/storage/ap_script.sh
baidu='http://gb.corp.163.com/gb/images/spacer.gif'
aptimes=$1
if [ $((aptimes)) -gt "9" ] ; then
    logger -t "【连接 AP】" "$1秒后, 自动搜寻 ap"
    sleep $1
else
    logger -t "【连接 AP】" "10秒后, 自动搜寻 ap"
    sleep 10
fi
cat /tmp/ap2g5g.txt | grep -v '^#'  | grep -v "^$" > /tmp/ap2g5g
if [ ! -f /tmp/apc.lock ] && [ "$1" != "1" ] && [ -s /tmp/ap2g5g ] ; then
    touch /tmp/apc.lock
    a2=`iwconfig apcli0 | awk -F'"' '/ESSID/ {print $2}'`
    a5=`iwconfig apclii0 | awk -F'"' '/ESSID/ {print $2}'`
    [ "$a2" = "" -a "$a5" = "" ] && ap=1 || ap=0
    if [ "$ap" = "1" ] || [ "$2" = "t" ] && [ -f /tmp/apc.lock ] ; then
        #搜寻开始/tmp/ap2g5g
        while read line
        do
        c_line=`echo $line | grep -v '^#' | grep -v "^$"`
        if [ ! -z "$c_line" ] ; then
            apc=$line
            radio=$(echo $apc | cut -d $fenge -f1)
            
            # ApCli 2.4Ghz
            if [ "$radio" = "2" ] ; then
                rtwlt_mode_x=`nvram get rt_mode_x`
            else
                rtwlt_mode_x=`nvram get wl_mode_x`
            fi
            # [ "$rtwlt_mode_x" = "3" ] || [ "$rtwlt_mode_x" = "4" ] &&
            
            rtwlt_mode_x=$(echo $apc | cut -d $fenge -f2)
            rtwlt_sta_wisp=$(echo $apc | cut -d $fenge -f3)
            rtwlt_sta_ssid=$(echo $apc | cut -d $fenge -f4)
            rtwlt_sta_wpa_psk=$(echo $apc | cut -d $fenge -f5)
            rtwlt_sta_bssid=$(echo $apc | cut -d $fenge -f6 | tr 'A-Z' 'a-z')
            if [ "$radio" = "2" ] ; then
                ap=`iwconfig | grep 'apcli0' | grep ESSID:"$rtwlt_sta_ssid" | wc -l`
                if [ "$ap" = "0" ] ; then
                    ap=`iwconfig |sed -n '/apcli0/,/Rate/{/apcli0/n;/Rate/b;p}' | grep $rtwlt_sta_bssid | tr 'A-Z' 'a-z' | wc -l`
                fi
            else
                ap=`iwconfig | grep 'apclii0' | grep ESSID:"$rtwlt_sta_ssid" | wc -l`
                if [ "$ap" = "0" ] ; then
                    ap=`iwconfig |sed -n '/apclii0/,/Rate/{/apclii0/n;/Rate/b;p}' | grep $rtwlt_sta_bssid | tr 'A-Z' 'a-z' | wc -l`
                fi
            fi
            
            if [ "$ap" = "1" ] ; then
                logger -t "【连接 AP】" "当前是 $rtwlt_sta_ssid, 停止搜寻"
                rm -f /tmp/apc.lock
                if [ $((aptime)) -ge "9" ] ; then
                    /etc/storage/inet_state_script.sh $aptime "t" &
                    sleep 2
                    logger -t "【连接 AP】" "直到连上最优先信号 $(echo $(grep -v '^#' /tmp/ap2g5g | grep -v "^$" | head -1) | cut -d $fenge -f4)"
                fi
                exit
            else
                logger -t "【连接 AP】" "自动搜寻 $rtwlt_sta_ssid"
            fi
            if [ "$radio" = "2" ] ; then
            # ApCli 2.4Ghz
            iwpriv apcli0 set SiteSurvey=1
                if [ ! -z "$rtwlt_sta_bssid" ] ; then
                    logger -t "【连接 AP】" "自动搜寻 $rtwlt_sta_ssid:$rtwlt_sta_bssid"
                    site_survey=$(iwpriv apcli0 get_site_survey | sed -n "/$rtwlt_sta_bssid/p" | tr 'A-Z' 'a-z')
                else
                    site_survey=$(iwpriv apcli0 get_site_survey | sed -n "/$rtwlt_sta_ssid/p" | tr 'A-Z' 'a-z')
                fi
            else
                iwpriv apclii0 set SiteSurvey=1
                if [ ! -z "$rtwlt_sta_bssid" ] ; then
                    logger -t "【连接 AP】" "自动搜寻 $rtwlt_sta_ssid:$rtwlt_sta_bssid"
                    site_survey=$(iwpriv apclii0 get_site_survey | sed -n "/$rtwlt_sta_bssid/p" | tr 'A-Z' 'a-z')
                else
                    site_survey=$(iwpriv apclii0 get_site_survey | sed -n "/$rtwlt_sta_ssid/p" | tr 'A-Z' 'a-z')
                fi
            fi
            if [ -z "$site_survey" ] ; then
                logger -t "【连接 AP】" "没找到 $rtwlt_sta_ssid, 如果含中文请填写正确的MAC地址"
                ap3=1
            fi
            if [ ! -z "$site_survey" ] ; then
                Ch=${site_survey:0:4}
                SSID=${site_survey:4:33}
                BSSID=${site_survey:37:20}
                Security=${site_survey:57:23}
                Signal=${site_survey:80:9}
                WMode=${site_survey:89:7}
                ap3=0
            fi
            if [ "$apblack" = "1" ] ; then
                apblacktxt=$(grep "【SSID:$rtwlt_sta_bssid" /tmp/apblack.txt)
                if [ ! -z $apblacktxt ] ; then
                    logger -t "【连接 AP】" "当前是黑名单 $rtwlt_sta_ssid, 跳过黑名单继续搜寻"
                    ap3=1
                else
                    apblacktxt=$(grep "【SSID:$rtwlt_sta_ssid" /tmp/apblack.txt)
                    if [ ! -z $apblacktxt ] ; then
                        logger -t "【连接 AP】" "当前是黑名单 $rtwlt_sta_ssid, 跳过黑名单继续搜寻"
                        ap3=1
                    fi
                fi
            fi
            if [ "$ap3" != "1" ] ; then
                if [ "$radio" = "2" ] ; then
                    nvram set rt_channel=$Ch
                    iwpriv apcli0 set Channel=$Ch
                else
                    nvram set wl_channel=$Ch
                    iwpriv apclii0 set Channel=$Ch
                fi
                if [[ $(expr $Security : ".*none*") -gt "1" ]] ; then
                    rtwlt_sta_auth_mode="open"
                    rtwlt_sta_wpa_mode="0"
                fi
                if [[ $(expr $Security : ".*1psk*") -gt "1" ]] ; then
                    rtwlt_sta_auth_mode="psk"
                    rtwlt_sta_wpa_mode="1"
                fi
                if [[ $(expr $Security : ".*2psk*") -gt "1" ]] ; then
                    rtwlt_sta_auth_mode="psk"
                    rtwlt_sta_wpa_mode="2"
                fi
                if [[ $(expr $Security : ".*wpapsk*") -gt "1" ]] ; then
                    rtwlt_sta_auth_mode="psk"
                    rtwlt_sta_wpa_mode="1"
                fi
                if [[ $(expr $Security : ".*tkip*") -gt "1" ]] ; then
                    rtwlt_sta_crypto="tkip"
                fi
                if [[ $(expr $Security : ".*aes*") -gt "1" ]] ; then
                    rtwlt_sta_crypto="aes"
                fi
                if [ "$radio" = "2" ] ; then
                    nvram set rt_mode_x=$rtwlt_mode_x
                    nvram set rt_sta_wisp=$rtwlt_sta_wisp
                    nvram set rt_sta_ssid=$rtwlt_sta_ssid
                    nvram set rt_sta_auth_mode=$rtwlt_sta_auth_mode
                    nvram set rt_sta_wpa_mode=$rtwlt_sta_wpa_mode
                    nvram set rt_sta_crypto=$rtwlt_sta_crypto
                    nvram set rt_sta_wpa_psk=$rtwlt_sta_wpa_psk
                    #强制20MHZ
                    nvram set rt_HT_BW=0
                else
                    nvram set wl_mode_x=$rtwlt_mode_x
                    nvram set wl_sta_wisp=$rtwlt_sta_wisp
                    nvram set wl_sta_ssid=$rtwlt_sta_ssid
                    nvram set wl_sta_auth_mode=$rtwlt_sta_auth_mode
                    nvram set wl_sta_wpa_mode=$rtwlt_sta_wpa_mode
                    nvram set wl_sta_crypto=$rtwlt_sta_crypto
                    nvram set wl_sta_wpa_psk=$rtwlt_sta_wpa_psk
                fi
                logger -t "【连接 AP】" "$rtwlt_mode_x $rtwlt_sta_wisp $rtwlt_sta_ssid $rtwlt_sta_auth_mode $rtwlt_sta_wpa_mode $rtwlt_sta_crypto $rtwlt_sta_wpa_psk"
                nvram commit
                #restart_wan
                #sleep 10
                radio2_restart
                #sleep 4
                #if [ "$radio" = "2" ] ; then
                    #iwpriv apcli0 set ApCliEnable=0
                    #iwpriv apcli0 set ApCliAutoConnect=1
                #else
                    #iwpriv apclii0 set ApCliEnable=0
                    #iwpriv apclii0 set ApCliAutoConnect=1
                #fi
                sleep 15
                logger -t "【连接 AP】" "【Ch:$Ch】【SSID:$SSID】【BSSID:$BSSID】"
                logger -t "【连接 AP】" "【Security:$Security】【Signal(%):$Signal】【WMode:$WMode】"
                if [ "$radio" = "2" ] ; then
                    ap=`iwconfig | grep 'apcli0' | grep 'ESSID:""' | wc -l`
                else
                    ap=`iwconfig | grep 'apclii0' | grep 'ESSID:""' | wc -l`
                fi
                if [ "$ap" = "0" ] && [ "$apauto2" = "1" ] ; then
                    ping_text=`ping -4 114.114.114.114 -c 1 -w 2 -q`
                    ping_time=`echo $ping_text | awk -F '/' '{print $4}'| awk -F '.' '{print $1}'`
                    ping_loss=`echo $ping_text | awk -F ', ' '{print $3}' | awk '{print $1}'`
                    if [ ! -z "$ping_time" ] ; then
                        echo "ping：$ping_time ms 丢包率：$ping_loss"
                     else
                        echo "ping：失效"
                    fi
                    if [ ! -z "$ping_time" ] ; then
                        logger -t "【连接 AP】" "$ap 已连接上 $rtwlt_sta_ssid, 成功联网"
                        ap=0
                    else
                        ap=1
                        logger -t "【连接 AP】" "$ap 已连接上 $rtwlt_sta_ssid, 但未联网, 跳过继续搜寻"
                    fi
                fi
                if [ "$ap" = "1" ] ; then
                    logger -t "【连接 AP】" "$ap 无法连接 $rtwlt_sta_ssid"
                else
                    logger -t "【连接 AP】" "$ap 已连接上 $rtwlt_sta_ssid"
                    if [ "$apblack" = "1" ] ; then
                        ping_text=`ping -4 114.114.114.114 -c 1 -w 2 -q`
                        ping_time=`echo $ping_text | awk -F '/' '{print $4}'| awk -F '.' '{print $1}'`
                        ping_loss=`echo $ping_text | awk -F ', ' '{print $3}' | awk '{print $1}'`
                        if [ ! -z "$ping_time" ] ; then
                            echo "ping：$ping_time ms 丢包率：$ping_loss"
                         else
                            echo "ping：失效"
                        fi
                        if [ ! -z "$ping_time" ] ; then
                        echo "online"
                        else
                            apblacktxt="$ap AP不联网列入黑名单:【Ch:$Ch】【SSID:$SSID】【BSSID:$BSSID】【Security:$Security】【Signal(%):$Signal】【WMode:$WMode】"
                            logger -t "【连接 AP】" "$apblacktxt"
                            echo $apblacktxt >> /tmp/apblack.txt
                            rm -f /tmp/apc.lock
                            /etc/storage/inet_state_script.sh 0 "t" &
                            sleep 2
                            logger -t "【连接 AP】" "跳过黑名单继续搜寻, 直到连上最优先信号 $(echo $(grep -v '^#' /tmp/ap2g5g | grep -v "^$" | head -1) | cut -d $fenge -f4)"
                            exit
                        fi
                    fi
                    if [ "$rtwlt_sta_ssid" = $(echo $(grep -v '^#' /tmp/ap2g5g | grep -v "^$" | head -1) | cut -d $fenge -f4) ] ; then
                        logger -t "【连接 AP】" "当前是 $rtwlt_sta_ssid, 停止搜寻"
                        rm -f /tmp/apc.lock
                        logger -t "【连接 AP】" "当前连上最优先信号 $rtwlt_sta_ssid"
                        exit
                    else
                        rm -f /tmp/apc.lock
                        if [ $((aptime)) -ge "9" ] ; then
                            /etc/storage/inet_state_script.sh $aptime "t" &
                            sleep 2
                            logger -t "【连接 AP】" "直到连上最优先信号 $(echo $(grep -v '^#' /tmp/ap2g5g | grep -v "^$" | head -1) | cut -d $fenge -f4)"
                        fi
                        exit
                    fi
                fi
            fi
            sleep 5
        fi
        a2=`iwconfig apcli0 | awk -F'"' '/ESSID/ {print $2}'`
        a5=`iwconfig apclii0 | awk -F'"' '/ESSID/ {print $2}'`
        [ "$a2" = "" -a "$a5" = "" ] && ap=1 || ap=0
        sleep 2
        done < /tmp/ap2g5g
        sleep 60
        rm -f /tmp/apc.lock
        if [ "$ap" = "1" ] || [ "$2" = "t" ] && [ -f /tmp/apc.lock ] ; then
            #搜寻开始/tmp/ap2g5g
            /etc/storage/inet_state_script.sh 0 "t" &
            sleep 2
            logger -t "【连接 AP】" "继续搜寻"
            exit
        fi
        sleep 1
    fi
    rm -f /tmp/apc.lock
    sleep 1
fi
killall sh_apauto.sh
if [ -s /tmp/ap2g5g ] ; then
    /tmp/sh_apauto.sh &
else
    echo "" > /tmp/apauto.lock
fi
logger -t "【连接 AP】" "脚本完成"

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
    if [ -s "/tmp/ip-pre-up" ] ; then
      rm -f /tmp/ip-pre-up
      rm -f /tmp/ip-down
    fi
    rm -f /tmp/vpnc.lock
    logger -t "【VPN 分流】" "ip-down 删除规则完成"
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
	if [ ! -f "$script_ezbtn" ] ; then
		cat > "$script_ezbtn" <<-\EEE
#!/bin/sh
export PATH='/etc/storage/bin:/tmp/script:/etc/storage/script:/opt/usr/sbin:/opt/usr/bin:/opt/sbin:/opt/bin:/usr/local/sbin:/usr/sbin:/usr/bin:/sbin:/bin'
export LD_LIBRARY_PATH=/lib:/opt/lib

### Custom user script
### Called on WPS or FN button pressed
### $1 - button param

[ -x /opt/bin/on_wps.sh ] && /opt/bin/on_wps.sh $1 &
#copyright by hiboy
[ -f /tmp/button_script.lock ] && exit 0
[ "$1" != 3 ] && touch /tmp/button_script.lock
ad=`nvram get button_script_1_s`
[ -z "$ad" ] && { ad="Adbyby" ; nvram set button_script_1_s="Adbyby" ; }
# 按钮名称可自定义
# [ "$ad" = "ADM" ] && nvram set button_script_1_s="ADM"
ss_working_port=`nvram get ss_working_port`
[ $ss_working_port == 1090 ] && ss_info="SS_[1]"
[ $ss_working_port == 1091 ] && ss_info="SS_[2]"
[ ${ss_info:=SS} ] && nvram set button_script_2_s="$ss_info"
case "$1" in
1)
# 按钮①子程序 名称可自定义
button1=`nvram get button_script_1_s`
logger -t "【按钮①】" "$button1"
apply=`nvram get button_script_1`

# 按钮①状态0时执行以下命令
if [ "$apply" = 0 ] ; then
    #nvram set button_script_1="1"
    if [ "$ad" = "ADM" ] ; then
    port=$(iptables -t nat -L | grep 'ports 18309' | wc -l)
    PIDS=$(ps -w | grep "/tmp/7620adm/adm" | grep -v "grep" | wc -l)
    if [ "$port" = 0 ] && [ "$PIDS" = 0 ] ; then
        logger -t "【按钮①】" "添加转发规则, 启动 $ad"
        nvram set adm_status=0
        nvram set adm_enable=1
        nvram commit
        /tmp/script/_ad_m &
    fi
    fi
    if [ "$ad" = "KP" ] ; then
    port=$(iptables -t nat -L | grep 'ports 3000' | wc -l)
    PIDS=$(ps -w | grep "/tmp/7620koolproxy/koolproxy" | grep -v "grep" | wc -l)
    if [ "$port" = 0 ] && [ "$PIDS" = 0 ] ; then
        logger -t "【按钮①】" "添加转发规则, 启动 $ad"
        nvram set koolproxy_status=0
        nvram set koolproxy_enable=1
        nvram commit
        /tmp/script/_kool_proxy &
    fi
    fi
    if [ "$ad" = "Adbyby" ] ; then
    port=$(iptables -t nat -L | grep 'ports 8118' | wc -l)
    PIDS=$(ps -w | grep "/tmp/bin/adbyby" | grep -v "grep" | grep -v "adbybyupdate.sh" | grep -v "adbybyfirst.sh" | wc -l)
    if [ "$port" = 0 ] && [ "$PIDS" = 0 ] ; then
        logger -t "【按钮①】" "添加转发规则, 启动 $ad"
        nvram set adbyby_status=0
        nvram set adbyby_enable=1
        nvram commit
        /tmp/script/_ad_byby &
    fi
    fi
fi
# 按钮①状态1 执行以下命令
if [ "$apply" = 1 ] ; then
    #nvram set button_script_1="0"
    if [ "$ad" = "ADM" ] ; then
    port=$(iptables -t nat -L | grep 'ports 18309' | wc -l)
    PIDS=$(ps -w | grep "/tmp/7620adm/adm" | grep -v "grep" | wc -l)
    if [ "$port" -ge 1 ] || [ "$PIDS" != 0 ] ; then
        logger -t "【按钮①】" "关闭转发规则, 关闭 $ad"
        nvram set adm_status=1
        nvram set adm_enable=0
        nvram commit
        /tmp/script/_ad_m stop &
    fi
    fi
    if [ "$ad" = "KP" ] ; then
    port=$(iptables -t nat -L | grep 'ports 3000' | wc -l)
    PIDS=$(ps -w | grep "/tmp/7620koolproxy/koolproxy" | grep -v "grep" | wc -l)
    if [ "$port" -ge 1 ] || [ "$PIDS" != 0 ] ; then
        logger -t "【按钮①】" "关闭转发规则, 关闭 $ad"
        nvram set koolproxy_status=1
        nvram set koolproxy_enable=0
        nvram commit
        /tmp/script/_kool_proxy &
    fi
    fi
    if [ "$ad" = "Adbyby" ] ; then
    port=$(iptables -t nat -L | grep 'ports 8118' | wc -l)
    PIDS=$(ps -w | grep "/tmp/bin/adbyby" | grep -v "grep" | grep -v "adbybyupdate.sh" | grep -v "adbybyfirst.sh" | wc -l)
    if [ "$port" -ge 1 ] || [ "$PIDS" != 0 ] ; then
        logger -t "【按钮①】" "关闭转发规则, 关闭 $ad"
        nvram set adbyby_status=1
        nvram set adbyby_enable=0
        nvram commit
        /tmp/script/_ad_byby  &
    fi
    fi
fi

rm -f /tmp/button_script.lock
/etc/storage/ez_buttons_script.sh 3 &

  ;;
2)
# 按钮②子程序
button2=`nvram get button_script_2_s`
logger -t "【按钮②】" "$button2"
apply=`nvram get button_script_2`

# 按钮②状态0 执行以下命令
if [ "$apply" = 0 ] ; then
    #nvram set button_script_2="1"
    logger -t "【按钮②】" "开启 shadowsocks 进程"
    nvram set ss_status=0
    nvram set ss_enable=1
    nvram commit
    /tmp/script/_ss &
    nvram set button_script_2="1"
fi
# 按钮②状态1时执行以下命令
if [ "$apply" = 1 ] ; then
    #nvram set button_script_2="0"
    
    PROCESS=$(ps -w | grep "ss-redir" | grep -v "grep")
    logger -t "【按钮②】" "关闭 shadowsocks 进程"
    nvram set ss_status=1
    nvram set ss_enable=0
    nvram commit
    /tmp/script/_ss &
    nvram set button_script_2="0"
fi
rm -f /tmp/button_script.lock
/etc/storage/ez_buttons_script.sh 3 &

  ;;
3)
# 按钮状态检测子程序
sleep 1
if [ "$ad" = "ADM" ] ; then
port=$(iptables -t nat -L | grep 'AD_BYBY_to' | wc -l)
if [ "$port" -ge 1 ] ; then
    nvram set button_script_1="1"
else
    nvram set button_script_1="0"
fi
fi
if [ "$ad" = "KP" ] ; then
port=$(iptables -t nat -L | grep 'AD_BYBY_to' | wc -l)
if [ "$port" -ge 1 ] ; then
    nvram set button_script_1="1"
else
    nvram set button_script_1="0"
fi
fi
if [ "$ad" = "Adbyby" ] ; then
port=$(iptables -t nat -L | grep 'AD_BYBY_to' | wc -l)
if [ "$port" -ge 1 ] ; then
    nvram set button_script_1="1"
else
    nvram set button_script_1="0"
fi
fi
PROCESS=$(ps -w | grep "ss-redir" | grep -v "grep")
if [ -z "$PROCESS" ] ; then
    nvram set button_script_2="0"
else
    nvram set button_script_2="1"
fi


  ;;
cleanss)
# 重置 SS IP 规则文件并重启 SS
logger -t "【按钮③】" "重置 SS IP 规则文件并重启 SS"
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
/tmp/script/_ss &
  ;;
updatess)
/tmp/script/_ss updatess &
  ;;
timesystem)
# 手动设置时间
sleep 1
time_system=`nvram get time_system`
if [ ! -z "$time_system" ] ; then
date -s "$time_system"
nvram set time_system=""
fi
  ;;
serverchan)
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
        logger -t "【微信推送】" "未找到 curl 程序，停止 微信推送。请安装 opt 后输入[opkg install curl]安装"
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
  ;;
serverchan_clean)
# 清空以往接入设备名称
touch /etc/storage/hostname.txt
logger -t "【微信推送】" "清空以往接入设备名称：/etc/storage/hostname.txt"
echo "接入设备名称" > /etc/storage/hostname.txt
  ;;
relnmp)
logger -t "【按钮④】" "重启 LNMP 服务"
sleep 1
nvram set lnmp_status="relnmp"
/etc/storage/crontabs_script.sh &
  ;;
mkfs)
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
    mkfs.ext4 -T largefile $line
done    
logger -t "【mkfs.ext4】" "格式化完成."
} &
  ;;
ping)
rm -f /tmp/button_script.lock
ping1(){
ss_server1=`nvram get ss_server1`
echo $ss_server1
nvram set ping_1_ss=0
#nvram set ping_1_txt="ping：--- ms 丢包率：---"
nvram set ping_1_txt="ping：--- ms"
if [ ! -z "$ss_server1" ] ; then
logger -t "【ping1】" "$ss_server1"
ping_text=`ping -4 $ss_server1 -c 1 -w 2 -q`
ping_time=`echo $ping_text | awk -F '/' '{print $4}'| awk -F '.' '{print $1}'`
ping_loss=`echo $ping_text | awk -F ', ' '{print $3}' | awk '{print $1}'`
echo $ping_time
echo $ping_loss
if [ ! -z "$ping_time" ] ; then
    [ $ping_time -le 250 ] && nvram set ping_1_ss=1
    [ $ping_time -gt 250 ] && nvram set ping_1_ss=2
    [ $ping_time -gt 500 ] && nvram set ping_1_ss=3
    echo "ping1：$ping_time ms 丢包率：$ping_loss"
#    logger -t "【ping1】" "$ping_time ms 丢包率：$ping_loss"
#    nvram set ping_1_txt="ping：$ping_time ms 丢包率：$ping_loss"
    logger -t "【ping1】" "$ping_time ms"
    nvram set ping_1_txt="ping：$ping_time ms"
 else
    nvram set ping_1_ss=3
    echo "失效1"
    logger -t "【ping1】" "失效"
    nvram set ping_1_txt="ping：失效"
fi
fi
}
ping2(){
ss_server2=`nvram get ss_server2`
echo $ss_server2
nvram set ping_2_ss=0
#nvram set ping_2_txt="ping：--- ms 丢包率：---"
nvram set ping_2_txt="ping：--- ms"
if [ ! -z "$ss_server2" ] ; then
logger -t "【ping2】" "$ss_server2"
ping_text=`ping -4 $ss_server2 -c 1 -w 2 -q`
ping_time=`echo $ping_text | awk -F '/' '{print $4}'| awk -F '.' '{print $1}'`
ping_loss=`echo $ping_text | awk -F ', ' '{print $3}' | awk '{print $1}'`
echo $ping_time
echo $ping_loss
if [ ! -z "$ping_time" ] ; then
    [ $ping_time -le 250 ] && nvram set ping_2_ss=1
    [ $ping_time -gt 250 ] && nvram set ping_2_ss=2
    [ $ping_time -gt 500 ] && nvram set ping_2_ss=3
    echo "ping2：$ping_time ms 丢包率：$ping_loss"
#    logger -t "【ping2】" "$ping_time ms 丢包率：$ping_loss"
#    nvram set ping_2_txt="ping：$ping_time ms 丢包率：$ping_loss"
    logger -t "【ping2】" "$ping_time ms"
    nvram set ping_2_txt="ping：$ping_time ms"
else
    nvram set ping_2_ss=3
    echo "2失效"
    logger -t "【ping2】" "失效"
    nvram set ping_2_txt="ping：失效"
fi
fi
}
ping1 &
ping2 &
#sleep 1
  ;;
allping)
rm -f /tmp/button_script.lock
rt_ssnum_x=`nvram get rt_ssnum_x`
for i in 0 $(seq `expr $rt_ssnum_x - 1`)
do
    echo $i;
    nvram set ping_ss_x$i="btn-inverse"
#    nvram set ping_txt_x$i="--- ms 丢包:--%"
    nvram set ping_txt_x$i="--- ms"
rt_ss_server_x=`nvram get rt_ss_server_x$i`
echo $rt_ss_server_x;
if [ ! -z "$rt_ss_server_x" ] ; then
logger -t "【ping_x$i】" "$rt_ss_server_x"
ping_text=`ping -4 $rt_ss_server_x -c 1 -w 2 -q`
ping_time=`echo $ping_text | awk -F '/' '{print $4}'| awk -F '.' '{print $1}'`
ping_loss=`echo $ping_text | awk -F ', ' '{print $3}' | awk '{print $1}'`

if [ ! -z "$ping_time" ] ; then
    [ $ping_time -le 250 ] && `nvram set ping_ss_x$i="btn-success"`
    [ $ping_time -gt 250 ] && `nvram set ping_ss_x$i="btn-warning"`
    [ $ping_time -gt 500 ] && `nvram set ping_ss_x$i="btn-danger"`
    echo "ping_x$i：$ping_time ms 丢包率：$ping_loss"
#    logger -t "【ping_x$i】" "$ping_time ms 丢包率：$ping_loss"
#    nvram set ping_txt_x$i="$ping_time ms 丢包:$ping_loss"
    logger -t "【ping_x$i】" "$ping_time ms"
    nvram set ping_txt_x$i="$ping_time ms"
 else
    `nvram set ping_ss_x$i="btn-danger"`
    echo "失效1"
    logger -t "【ping_x$i】" "失效"
    `nvram set ping_txt_x$i="失效"`
fi
fi
done
  ;;
reszUID)
killall oraynewph oraysl
killall -9 oraynewph oraysl
rm -f /tmp/button_script.lock /tmp/oraysl.status /etc/PhMain.ini /etc/init.status /etc/storage/PhMain.ini /etc/storage/init.status
ln -sf "/etc/storage/PhMain.ini" "/etc/PhMain.ini"
ln -sf "/etc/storage/init.status" "/etc/init.status"
logger -t "【花生壳内网版】" "重置花生壳绑定, 重新启动"
nvram set phddns_sn=""
nvram set phddns_st=""
nvram set phddns_szUID=""
/tmp/script/_orayd &
  ;;
esac
sleep 1
rm -f /tmp/button_script.lock

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

### Max clients limit
max-clients 10

### Internally route client-to-client traffic
client-to-client

### Allow clients with duplicate "Common Name"
;duplicate-cn

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

### If your server certificates with the nsCertType field set to "server"
ns-cert-type server

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
#多次检测断线后自动重启功能 0关闭；1启动
echo "0" > /tmp/reb.lock
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



if [ ! -f "$ad_config_script" ] || [ ! -s "$ad_config_script" ] ; then
	cat > "$ad_config_script" <<-\EEE
# 广告过滤 访问控制功能

# 内网(LAN)访问控制的默认代理转发设置，
#    0  默认值, 常规, 未在以下设定的 内网IP 根据 AD配置工作模式 走 AD
#    1         全局, 未在以下设定的 内网IP 使用全局代理 走 AD
#    2         绕过, 未在以下设定的 内网IP 不使用 AD
AD_LAN_AC_IP=0
nvram set AD_LAN_AC_IP=$AD_LAN_AC_IP
# =========================================================
# 内网(LAN)IP设定行为设置, 格式如 b,192.168.1.23, 多个值使用空格隔开
#   使用 b/g/n 前缀定义主机行为模式, 使用英文逗号与主机 IP 分隔
#   b: 绕过, 此前缀的主机IP 不使用 AD
#   g: 全局, 此前缀的主机IP 忽略 AD配置工作模式 使用全局代理 走 AD
#   n: 常规, 此前缀的主机IP 使用 AD配置工作模式 走 AD
#   s: https, 此前缀的主机IP 使用 AD配置工作模式 https走 AD
#   优先级: 绕过 > 全局 > 常规
# （如多个设置则每一个ip一行,可选项：删除前面的#可生效）
cat > "/tmp/ad_spec_lan_DOMAIN.txt" <<-\EOF
#b,192.168.123.115
#g,192.168.123.116
#n,192.168.123.117
#s,192.168.123.118
#b,099B9A909FD9
#s,099B9A909FD9
#g,A9:CB:3A:5F:1F:C7



EOF
# =========================================================

# adbyby加载第三方adblock规则 0关闭；1启动（可选项：删除前面的#可生效）
#【不建议启用第三方规则,有可能破坏规则导致过滤失效】
nvram set adbyby_adblocks=0
adblocks=`nvram get adbyby_adblocks`
cat > "/tmp/rule_DOMAIN.txt" <<-\EOF
# 【可选多项，会占用内存：删除前面的#可生效，前面添加#停用规则】
# https://easylist-downloads.adblockplus.org/easylistchina.txt



EOF

EEE
	chmod 755 "$ad_config_script"
fi


if [ ! -f "$shadowsocks_ss_spec_lan" ] || [ ! -s "$shadowsocks_ss_spec_lan" ] ; then
	cat > "$shadowsocks_ss_spec_lan" <<-\EEE
#b,192.168.123.115
#g,192.168.123.116
#n,192.168.123.117
#1,192.168.123.118
#2,192.168.123.119
#b,099B9A909FD9
#1,099B9A909FD9
#2,A9:CB:3A:5F:1F:C7


EEE
	chmod 755 "$shadowsocks_ss_spec_lan"
fi


if [ ! -f "$shadowsocks_ss_spec_wan" ] || [ ! -s "$shadowsocks_ss_spec_wan" ] ; then
	cat > "$shadowsocks_ss_spec_wan" <<-\EEE
WAN@raw.githubusercontent.com
#WAN+8.8.8.8
#WAN@www.google.com
#WAN!www.baidu.com
#WAN-223.5.5.5
#WAN-114.114.114.114
WAN!members.3322.org
WAN!www.cloudxns.net
WAN!dnsapi.cn
WAN!api.dnspod.com
WAN!www.ipip.net
WAN!alidns.aliyuncs.com


#以下样板是四个网段分别对应BLZ的美/欧/韩/台服
#WAN+24.105.0.0/18
#WAN+80.239.208.0/20
#WAN+182.162.0.0/16
#WAN+210.242.235.0/24
#以下样板是telegram
#WAN+149.154.160.1/32
#WAN+149.154.160.2/31
#WAN+149.154.160.4/30
#WAN+149.154.160.8/29
#WAN+149.154.160.16/28
#WAN+149.154.160.32/27
#WAN+149.154.160.64/26
#WAN+149.154.160.128/25
#WAN+149.154.161.0/24
#WAN+149.154.162.0/23
#WAN+149.154.164.0/22
#WAN+149.154.168.0/21
#WAN+91.108.4.0/22
#WAN+91.108.56.0/24
#WAN+109.239.140.0/24
#WAN+67.198.55.0/24
#WAN+91.108.56.172
#WAN+149.154.175.50


EEE
	chmod 755 "$shadowsocks_ss_spec_wan"
fi



if [ ! -f "$adbyby_rules_script" ] || [ ! -s "$adbyby_rules_script" ] ; then
	cat > "$adbyby_rules_script" <<-\EEE
!  ------------------------------ ADByby 自定义过滤语法简--------------------------------
!  --------------  规则基于abp规则，并进行了字符替换部分的扩展-----------------------------
!  ABP规则请参考 https://adblockplus.org/zh_CN/filters ，下面为大致摘要
!  "!" 为行注释符，注释行以该符号起始作为一行注释语义，用于规则描述。
!  "*" 为字符通配符，能够匹配0长度或任意长度的字符串，该通配符不能与正则语法混用。
!  "^" 为分隔符，可以是除了字母、数字或者 _ - . % 之外的任何字符。
!  "|" 为管线符号，来表示地址的最前端或最末端
!  "||" 为子域通配符，方便匹配主域名下的所有子域。
!  "~" 为排除标识符，通配符能过滤大多数广告，但同时存在误杀, 可以通过排除标识符修正误杀链接。
!  "##" 为元素选择器标识符，后面跟需要隐藏元素的CSS样式例如 #ad_id  .ad_class
!!  元素隐藏暂不支持全局规则和排除规则
!! 字符替换扩展
!  文本替换选择器标识符，后面跟需要替换的文本数据，格式：$s@模式字符串@替换后的文本@
!  支持通配符*和?
! 参考以下规则格式添加指定过滤网址
! adbyby_list【模式二】指定网址过滤 功能
|http://www.sohu.com/adbyby_list
!百度广告
||cbjs.baidu.com/adbyby
||list.video.baidu.com/adbyby
||nsclick.baidu.com/adbyby
||play.baidu.com/adbyby
||sclick.baidu.com/adbyby
||tieba.baidu.com/adbyby
||baidustatic.com/adbyby
||bdimg.com/adbyby
||bdstatic.com/adbyby
||share.baidu.com/adbyby
||hm.baidu.com/adbyby
!视频广告
||v.baidu.com/adbyby
||1000fr.net/adbyby
||56.com/adbyby
||v-56.com/adbyby
||acfun.com/adbyby
||acfun.tv/adbyby
||baofeng.com/adbyby
||baofeng.net/adbyby
||cntv.cn/adbyby
||hoopchina.com.cn/adbyby
||funshion.com/adbyby
||fun.tv/adbyby
||hitvs.cn/adbyby
||hljtv.com/adbyby
||iqiyi.com/adbyby
||qiyi.com/adbyby
||agn.aty.sohu.com/adbyby
||itc.cn/adbyby
||kankan.com/adbyby
||ku6.com/adbyby
||letv.com/adbyby
||letvcloud.com/adbyby
||letvimg.com/adbyby
||pplive.cn/adbyby
||pps.tv/adbyby
||ppsimg.com/adbyby
||pptv.com/adbyby
||v.qq.com/adbyby
||l.qq.com/adbyby
||video.sina.com.cn/adbyby
||tudou.com/adbyby
||wasu.cn/adbyby
||analytics-union.xunlei.com/adbyby
||kankan.xunlei.com/adbyby
||youku.com/adbyby
||hunantv.com/adbyby
||zimuzu.tv/adbyby_list
! 参考以上规则格式添加指定过滤网址

EEE
	chmod 755 "$adbyby_rules_script"
fi

if [ ! -f "$adm_rules_script" ] || [ ! -s "$adm_rules_script" ] ; then
	cat > "$adm_rules_script" <<-\EEE
[ADM]
!  ------------------------------ 阿呆喵[ADM] 自定义过滤语法简表---------------------------------
!  --------------  规则语法基于ABP规则，并进行了字符替换部分的扩展-----------------------------
! ADM支持绝大多数ABP规则语法, 
! 所以, 你可以装一个ABP浏览器插件, 然后用它来辅助写规则, 把写好的规则导入ADM自定义规则文件中保存即可正常使用了.

!  ABP规则请参考https://adblockplus.org/zh_CN/filters，下面为大致摘要
!  "!" 为行注释符，注释行以该符号起始作为一行注释语义，用于规则描述
!  "*" 为字符通配符，能够匹配0长度或任意长度的字符串。
!  "^" 为分隔符，可以匹配任何单个字符。
!  "|" 为管线符号，来表示地址的最前端或最末端  比如 "|http://"  或  |http://www.abc.com/a.js|  
!  "||" 为子域通配符，方便匹配主域名下的所有子域。比如 "||www.baidu.com"  就可以不要前面的 "http://"
!  "~" 为排除标识符，通配符能过滤大多数广告，但同时存在误杀, 可以通过排除标识符修正误杀链接。
!  "@@" 网址白名单, 例如不拦截此条地址   @@|http://www.baidu.com/js/u.js   或者 @@||www.baidu.com/js/u.js

! ## #@# ##&  这3种为元素插入语法 (在语句末尾加 $B , 可以选择插入css语句在</body>前, 默认为</head>)
!  "##" 为元素选择器标识符，后面跟需要隐藏元素的CSS样式例如 #ad_id  .ad_class
! "#@#" 元素选择器白名单 
! "##&" 为JQuery选择器标识符，后面跟需要隐藏元素的JQuery筛选语法, 如 ##&div:has(p)
!  元素隐藏支持全局规则   ##.ad_text  不需要前面配置域名,对所有页面有效. 简单有效,但误杀会比较多, 慎用.

! 文本替换规则一般人使用较少, 过滤视频规则一般必须使用之;
!  文本替换选择器标识符, 支持通配符*和？，格式："页面C$s@内容A@内容B@"   意思为 <在使用"某正则模式" 在 "页面C"上用"内容A"替换"内容B" >  ; 
! 文本替换方式1:  S@   使用正则匹配替换
! 文本替换方式2:  s@   使用通配符 ?  *  匹配替换  
!  -------------------------------------------------------------------------------------------

!全局白名单
!如果你有其他不想过滤的论坛或者网站类的, 可以在自定义里面仿造上面的规则写一条
!例如 有些人不想过滤 http://www.baidu.com/
!那么可以在user.txt 自定义中加一条规则  @@|http://$domain=.baidu.com|   保存即可

!新增文本替换规则语法测试样例
!样例1 使用正则删除某地方(替换 "<p...</p>" 字符串为 "http://www.admflt.com")
!<p id="lg"><img src="http://www.baidu.com/img/bdlogo.gif" width="270" height="129"></p>
!||www.baidu.com$S@<p.*<\/p>@http://www.admflt.com@
!||kafan.cn$s@<div id="hd">@<div id="hd" style="display:none!important">@

!ADM https黑名单写法;参考规则文件 https_black.txt
!例如
!B:baidu.com
!B:taobao.com



EEE
	chmod 755 "$adm_rules_script"
fi

if [ ! -f "$koolproxy_rules_script" ] || [ ! -s "$koolproxy_rules_script" ] ; then
	cat > "$koolproxy_rules_script" <<-\EEE
!  ******************************* koolproxy 自定义过滤语法简表 *******************************
!  ------------------------ 规则基于adblock规则，并进行了语法部分的扩展 ------------------------
!  ABP规则请参考https://adblockplus.org/zh_CN/filters，下面为大致摘要
!  "!" 为行注释符，注释行以该符号起始作为一行注释语义，用于规则描述
!  "@@" 为白名单符，白名单具有最高优先级，放行过滤的网站，例如:@@||taobao.com
!  ------------------------------------------------------------------------------------------
!  "*" 为字符通配符，能够匹配0长度或任意长度的字符串，该通配符不能与正则语法混用。
!  "^" 为分隔符，可以是除了字母、数字或者 _ - . % 之外的任何字符。
!  "~" 为排除标识符，通配符能过滤大多数广告，但同时存在误杀, 可以通过排除标识符修正误杀链接。
!  注：通配符仅在 url 规则中支持，html 规则中不支持
!  ------------------------------------------------------------------------------------------
!  "|" 为管线符号，来表示地址的最前端或最末端
!  "||" 为子域通配符，方便匹配主域名下的所有子域
!  用法及例子如下：(以下等号表示等价于)
!  ||xx.com          =  http://xx.com || http://*.xx.com
!  ||http://xx.com   =  http://xx.com || http://*.xx.com
!  ||https://xx.com  =  https://xx.com || https://*.xx.com
!  |xx.com           =  http://xx.com
!  |http://xx.com    =  http://xx.com
!  |https://xx.com   =  https://xx.com
!  xx.com            =  http://*xx.com
!  http://xx.com     =  http://*xx.com
!  https://xx.com    =  https://xx.com
!  ------------------------------------------------------------------------------------------
!  支持html规则语法，例如：
!  ||fulldls.com##.tp_reccomend_banner
!  ||torrentzap.com##.tp_reccomend_banner
!  但不支持adblock规则中，逗号合并符写法，例如：
!  fulldls.com,torrentzap.com##.tp_reccomend_banner
!  应该写成推荐样式或以下样式：
!  fulldls.com##.tp_reccomend_banner
!  torrentzap.com##.tp_reccomend_banner
!  ------------------------------------------------------------------------------------------
!  文本替换语法：$s@匹配内容@替换内容@
!  文本替换例子：|http://cdn.pcbeta.js.inimc.com/data/cache/common.js?$s@var $banner = @@
!  重定向语法：$r@匹配内容@替换内容@
!  重定向例子：|http://koolshare.cn$r@http://koolshare.cn/*@http://www.qq.com@
!  注：文本替换语法及重定向语法中的匹配内容不仅支持通配符功能，而且额外支持以下功能
!  支持通配符 * 和 ? ，? 表示单个字符
!  支持全正则匹配，/正则内容/ 表示应用正则匹配
!  正则替换：替换内容支持 $1 $2 这样的符号
!  普通替换：替换内容支持 * 这样的符号，表示把命中的内容复制到替换的内容。（类似 $1 $2，但是 * 号会自动计算数字）
!  ------------------------------------------------------------------------------------------
!  koolporxy支持https过滤功能，但考虑到https过滤的效率问题，目前仅允许非常明确的过滤指令。
!  未来将逐步开放模糊https的相关语法，与普通语法同步，敬请期待。
!  ******************************************************************************************

EEE
	chmod 755 "$koolproxy_rules_script"
fi

if [ ! -f "$koolproxy_rules_list" ] || [ ! -s "$koolproxy_rules_list" ] ; then
	cat > "$koolproxy_rules_list" <<-\EEE
# 【添加为#注释行，会自动忽略】
# 【adbyby规则翻译的koolproxy兼容规则 by <dsyo2008> http://koolshare.cn/thread-83553-1-1.html】
#https://raw.githubusercontent.com/dsyo2008/lazy_for_koolproxy/master/lazy_kp.txt

EEE
	chmod 755 "$koolproxy_rules_list"
fi

if [ ! -f "$FastDick_script" ] || [ ! -s "$FastDick_script" ] ; then
	cat > "$FastDick_script" <<-\EEE
#!/bin/sh
# 迅雷快鸟【2免U盘启动】功能需到【自定义脚本0】配置【FastDicks=2】，并在此输入swjsq_wget.sh文件内容
#【2免U盘启动】需要填写在下方的【迅雷快鸟脚本】，生成脚本两种方法：
# ①插入U盘，配置自定义脚本【1插U盘启动】启动快鸟一次即可自动生成
# ②打开https://github.com/fffonion/Xunlei-FastDick，按照网页的说明在PC上运行脚本，登陆成功后会生成swjsq_wget.sh，把swjsq_wget.sh的内容粘贴此处即可
# 生成后需要到【系统管理】 - 【恢复/导出/上传设置】 - 【路由器内部存储 (/etc/storage)】【写入】保存脚本

EEE
	chmod 755 "$FastDick_script"
fi


if [ ! -f "$ddns_script" ] || [ ! -s "$ddns_script" ] ; then
	cat > "$ddns_script" <<-\EEE
# 获得外网地址
# 自行测试哪个代码能获取正确的IP，删除前面的#可生效
arIpAddress () {
curltest=`which curl`
if [ -z "$curltest" ] || [ ! -s "`which curl`" ] ; then
    wget --no-check-certificate --quiet --output-document=- "http://www.ipip.net" | grep "您当前的IP：" | grep -E -o '([0-9]+\.){3}[0-9]+'
    #wget --no-check-certificate --quiet --output-document=- "http://members.3322.org/dyndns/getip" | grep -E -o '([0-9]+\.){3}[0-9]+'
    #wget --no-check-certificate --quiet --output-document=- "ip.6655.com/ip.aspx" | grep -E -o '([0-9]+\.){3}[0-9]+'
    #wget --no-check-certificate --quiet --output-document=- "ip.3322.net" | grep -E -o '([0-9]+\.){3}[0-9]+'
else
    curl -L -k -s "http://www.ipip.net" | grep "您当前的IP：" | grep -E -o '([0-9]+\.){3}[0-9]+'
    #curl -k -s "http://members.3322.org/dyndns/getip" | grep -E -o '([0-9]+\.){3}[0-9]+'
    #curl -k -s ip.6655.com/ip.aspx | grep -E -o '([0-9]+\.){3}[0-9]+'
    #curl -k -s ip.3322.net | grep -E -o '([0-9]+\.){3}[0-9]+'
fi
}
arIpAddress=$(arIpAddress)
EEE
	chmod 755 "$ddns_script"
fi


if [ ! -f "$ngrok_script" ] || [ ! -s "$ngrok_script" ] ; then
	cat > "$ngrok_script" <<-\EEE
#!/bin/sh
export PATH='/etc/storage/bin:/tmp/script:/etc/storage/script:/opt/usr/sbin:/opt/usr/bin:/opt/sbin:/opt/bin:/usr/local/sbin:/usr/sbin:/usr/bin:/sbin:/bin'
export LD_LIBRARY_PATH=/lib:/opt/lib
killall ngrokc
#启动ngrok功能后会运行以下脚本
#使用方法请查看论坛教程:http://www.right.com.cn/forum/thread-182340-1-1.html
#ngrokc -SER[Shost:服务器域名,Sport:服务器端口,Atoken:服务器密码] -AddTun[Type:协议,Lhost:本地ip,Lport:本地端口,Rport:外网访问端口]
#参数说明
#Shost -服务器服务器地址
#Sport -服务器端口
#Atoken -服务器认证串
#type -协议类型，tcp,http,https
#Lhost -本地地址，如果是本机直接127.0.0.1
#Lport -本地端口
#Sdname -子域名
#Hostname -自定义域名映射 备注：需要做域名解释到服务器地址
#Rport -远程端口，tcp映射的时候，制定端口使用。
#注册 http://www.ngrok.cc/  http://www.qydev.com/
#例子：
#ngrokc -SER[Shost:tunnel.org.cn,Sport:4443] -AddTun[Type:https,Lhost:127.0.0.1,Lport:443,Sdname:test] &
#ngrokc -SER[Shost:ss.ngrok.pw,Sport:4443] -AddTun[Type:tcp,Lhost:192.168.38.1,Lport:80,Rport:5678] &
#ngrokc -SER[Shost:ngrokd.ngrok.com,Sport:443,Atoken:xxxxxxx] -AddTun[Type:tcp,Lhost:127.0.0.1,Lport:80,Rport:11199] &
#ngrokc -SER[Shost:server.ngrok.cc,Sport:4443,Atoken:xxxxxxx] -AddTun[Type:tcp,Lhost:127.0.0.1,Lport:80,Sdname:abcd1234] &
#ngrokc -SER[Shost:server.ngrok.cc,Sport:4443,Atoken:xxxxxxx] -AddTun[Type:tcp,Lhost:127.0.0.1,Lport:80,Hostname:www.abc.com] &



EEE
	chmod 755 "$ngrok_script"
fi



if [ ! -f "$frp_script" ] || [ ! -s "$frp_script" ] ; then
	cat > "$frp_script" <<-\EEE
#!/bin/sh
export PATH='/etc/storage/bin:/tmp/script:/etc/storage/script:/opt/usr/sbin:/opt/usr/bin:/opt/sbin:/opt/bin:/usr/local/sbin:/usr/sbin:/usr/bin:/sbin:/bin'
export LD_LIBRARY_PATH=/lib:/opt/lib
killall frpc frps
mkdir -p /tmp/frp
#启动frp功能后会运行以下脚本
#使用方法请查看论坛教程地址: http://www.right.com.cn/forum/thread-191839-1-1.html
#frp项目地址教程: https://github.com/fatedier/frp/blob/master/README_zh.md
#请自行修改 auth_token 用于对客户端连接进行身份验证
# IP查询： http://119.29.29.29/d?dn=github.com

#客户端配置：
cat > "/tmp/frp/myfrpc.ini" <<-\EOF
[common]
server_addr = 远端frp服务器ip
server_port = 7000
privilege_token = 12345

[web]
privilege_mode = true
remote_port = 6000
type = http
local_ip = 192.168.123.1
local_port = 80
use_gzip = true
#subdomain = test
custom_domains = 你公网访问的域名
#host_header_rewrite = 实际你内网访问的域名，可以供公网的域名不一致，如果一致可以不写
log_file = /dev/null
log_level = info
log_max_days = 3
EOF

#服务端配置：
#请手动配置【外部网络 (WAN) - 端口转发 (UPnP)】开启 WAN 外网端口
cat > "/tmp/frp/myfrps.ini" <<-\EOF
[common]
bind_port = 7000
dashboard_port = 7500
# dashboard 用户名密码可选，默认都为 admin
dashboard_user = admin
dashboard_pwd = admin
vhost_http_port = 88
privilege_mode = true
privilege_token = 12345
#subdomain_host = frps.com
max_pool_count = 50
log_file = /dev/null
log_level = info
log_max_days = 3
EOF

#启动：
frpc_enable=`nvram get frpc_enable`
frpc_enable=${frpc_enable:-"0"}
frps_enable=`nvram get frps_enable`
frps_enable=${frps_enable:-"0"}
if [ "$frpc_enable" = "1" ] ; then
    frpc -c /tmp/frp/myfrpc.ini &
fi
if [ "$frps_enable" = "1" ] ; then
    frps -c /tmp/frp/myfrps.ini &
fi

EEE
	chmod 755 "$frp_script"
fi



if [ ! -f "$SSRconfig_script" ] || [ ! -s "$SSRconfig_script" ] ; then
	cat > "$SSRconfig_script" <<-\EEE
{
    "server": "0.0.0.0",
    "server_ipv6": "::",
    "server_port": 8388,
    "local_address": "127.0.0.1",
    "local_port": 1080,

    "password": "m",
    "timeout": 120,
    "udp_timeout": 60,
    "method": "aes-128-ctr",
    "protocol": "auth_aes128_md5",
    "protocol_param": "",
    "obfs": "tls1.2_ticket_auth_compatible",
    "obfs_param": "",
    "speed_limit_per_con": 0,
    "speed_limit_per_user": 0,

    "dns_ipv6": false,
    "connect_verbose_info": 0,
    "redirect": "",
    "fast_open": false
}
EEE
	chmod 755 "$SSRconfig_script"
fi


if [ ! -f "$serverchan_script" ] || [ ! -s "$serverchan_script" ] ; then
	cat > "$serverchan_script" <<-\EEE
#!/bin/sh
# 此脚本路径：/etc/storage/serverchan_script.sh
# 自定义设置 - 脚本 - 自定义 Crontab 定时任务配置，可自定义启动时间
source /etc/storage/script/init.sh
export PATH='/etc/storage/bin:/tmp/script:/etc/storage/script:/opt/usr/sbin:/opt/usr/bin:/opt/sbin:/opt/bin:/usr/local/sbin:/usr/sbin:/usr/bin:/sbin:/bin'
export LD_LIBRARY_PATH=/lib:/opt/lib
serverchan_enable=`nvram get serverchan_enable`
serverchan_enable=${serverchan_enable:-"0"}
serverchan_sckey=`nvram get serverchan_sckey`
serverchan_notify_1=`nvram get serverchan_notify_1`
serverchan_notify_2=`nvram get serverchan_notify_2`
serverchan_notify_3=`nvram get serverchan_notify_3`
serverchan_notify_4=`nvram get serverchan_notify_4`
mkdir -p /tmp/var
resub=1
# 获得外网地址
    arIpAddress() {
    curltest=`which curl`
    if [ -z "$curltest" ] || [ ! -s "`which curl`" ] ; then
        wget --no-check-certificate --quiet --output-document=- "http://members.3322.org/dyndns/getip"
        #wget --no-check-certificate --quiet --output-document=- "ip.6655.com/ip.aspx"
        #wget --no-check-certificate --quiet --output-document=- "ip.3322.net"
    else
        curl -k -s "http://members.3322.org/dyndns/getip"
        #curl -k -s ip.6655.com/ip.aspx
        #curl -k -s ip.3322.net
    fi
    }
# 读取最近外网地址
    lastIPAddress() {
        local inter="/etc/storage/lastIPAddress"
        cat $inter
    }

while [ "$serverchan_enable" = "1" ];
do
serverchan_enable=`nvram get serverchan_enable`
serverchan_enable=${serverchan_enable:-"0"}
serverchan_sckey=`nvram get serverchan_sckey`
serverchan_notify_1=`nvram get serverchan_notify_1`
serverchan_notify_2=`nvram get serverchan_notify_2`
serverchan_notify_3=`nvram get serverchan_notify_3`
serverchan_notify_4=`nvram get serverchan_notify_4`
curltest=`which curl`
ping_text=`ping -4 114.114.114.114 -c 1 -w 2 -q`
ping_time=`echo $ping_text | awk -F '/' '{print $4}'| awk -F '.' '{print $1}'`
ping_loss=`echo $ping_text | awk -F ', ' '{print $3}' | awk '{print $1}'`
if [ ! -z "$ping_time" ] ; then
    echo "ping：$ping_time ms 丢包率：$ping_loss"
 else
    echo "ping：失效"
fi
if [ ! -z "$ping_time" ] ; then
echo "online"
if [ "$serverchan_notify_1" = "1" ] ; then
    local hostIP=$(arIpAddress)
    local lastIP=$(lastIPAddress)
    if [ "$lastIP" != "$hostIP" ] && [ ! -z "$hostIP" ] ; then
    sleep 60
        local hostIP=$(arIpAddress)
        local lastIP=$(lastIPAddress)
    fi
    if [ "$lastIP" != "$hostIP" ] && [ ! -z "$hostIP" ] ; then
        logger -t "【互联网 IP 变动】" "目前 IP: ${hostIP}"
        logger -t "【互联网 IP 变动】" "上次 IP: ${lastIP}"
        curl -s "http://sc.ftqq.com/$serverchan_sckey.send?text=【PDCN_"`nvram get computer_name`"】互联网IP变动" -d "&desp=${hostIP}" &
        logger -t "【微信推送】" "互联网IP变动:${hostIP}"
        echo -n $hostIP > /etc/storage/lastIPAddress
    fi
fi
if [ "$serverchan_notify_2" = "1" ] ; then
    # 获取接入设备名称
    touch /tmp/var/newhostname.txt
    echo "接入设备名称" > /tmp/var/newhostname.txt
    #cat /tmp/syslog.log | grep 'Found new hostname' | awk '{print $7" "$8}' >> /tmp/var/newhostname.txt
    cat /tmp/static_ip.inf | grep -v "^$" | awk -F "," '{ if ( $6 == 0 ) print "【内网IP："$1"，ＭＡＣ："$2"，名称："$3"】  "}' >> /tmp/var/newhostname.txt
    # 读取以往接入设备名称
    touch /etc/storage/hostname.txt
    [ ! -s /etc/storage/hostname.txt ] && echo "接入设备名称" > /etc/storage/hostname.txt
    # 获取新接入设备名称
    awk 'NR==FNR{a[$0]++} NR>FNR&&a[$0]' /etc/storage/hostname.txt /tmp/var/newhostname.txt > /tmp/var/newhostname相同行.txt
    awk 'NR==FNR{a[$0]++} NR>FNR&&!a[$0]' /tmp/var/newhostname相同行.txt /tmp/var/newhostname.txt > /tmp/var/newhostname不重复.txt
    if [ -s "/tmp/var/newhostname不重复.txt" ] ; then
        content=`cat /tmp/var/newhostname不重复.txt | grep -v "^$"`
        curl -s "http://sc.ftqq.com/$serverchan_sckey.send?text=【PDCN_"`nvram get computer_name`"】新设备加入" -d "&desp=${content}" &
        logger -t "【微信推送】" "PDCN新设备加入:${content}"
        cat /tmp/var/newhostname不重复.txt | grep -v "^$" >> /etc/storage/hostname.txt
    fi
fi
if [ "$serverchan_notify_4" = "1" ] ; then
    # 设备上、下线提醒
    # 获取接入设备名称
    touch /tmp/var/newhostname.txt
    echo "接入设备名称" > /tmp/var/newhostname.txt
    #cat /tmp/syslog.log | grep 'Found new hostname' | awk '{print $7" "$8}' >> /tmp/var/newhostname.txt
    cat /tmp/static_ip.inf | grep -v "^$" | awk -F "," '{ if ( $6 == 0 ) print "【内网IP："$1"，ＭＡＣ："$2"，名称："$3"】  "}' >> /tmp/var/newhostname.txt
    # 读取以往上线设备名称
    touch /etc/storage/hostname_上线.txt
    [ ! -s /etc/storage/hostname_上线.txt ] && echo "接入设备名称" > /etc/storage/hostname_上线.txt
    # 上线
    awk 'NR==FNR{a[$0]++} NR>FNR&&a[$0]' /etc/storage/hostname_上线.txt /tmp/var/newhostname.txt > /tmp/var/newhostname相同行_上线.txt
    awk 'NR==FNR{a[$0]++} NR>FNR&&!a[$0]' /tmp/var/newhostname相同行_上线.txt /tmp/var/newhostname.txt > /tmp/var/newhostname不重复_上线.txt
    if [ -s "/tmp/var/newhostname不重复_上线.txt" ] ; then
        content=`cat /tmp/var/newhostname不重复_上线.txt | grep -v "^$"`
        curl -s "http://sc.ftqq.com/$serverchan_sckey.send?text=【PDCN_"`nvram get computer_name`"】设备【上线】Online" -d "&desp=${content}" &
        logger -t "【微信推送】" "PDCN设备【上线】:${content}"
        cat /tmp/var/newhostname不重复_上线.txt | grep -v "^$" >> /etc/storage/hostname_上线.txt
    fi
    # 下线
    awk 'NR==FNR{a[$0]++} NR>FNR&&!a[$0]' /tmp/var/newhostname.txt /etc/storage/hostname_上线.txt > /tmp/var/newhostname不重复_下线.txt
    if [ -s "/tmp/var/newhostname不重复_下线.txt" ] ; then
        content=`cat /tmp/var/newhostname不重复_下线.txt | grep -v "^$"`
        curl -s "http://sc.ftqq.com/$serverchan_sckey.send?text=【PDCN_"`nvram get computer_name`"】设备【下线】offline" -d "&desp=${content}" &
        logger -t "【微信推送】" "PDCN设备【下线】:${content}"
        cat /tmp/var/newhostname.txt | grep -v "^$" > /etc/storage/hostname_上线.txt
    fi
fi
if [ "$serverchan_notify_3" = "1" ] && [ "$resub" = "1" ] ; then
    # 固件更新提醒
    [ ! -f /tmp/var/osub ] && echo -n `nvram get firmver_sub` > /tmp/var/osub
    rm -f /tmp/var/nsub
    wgetcurl.sh "/tmp/var/nsub" "$hiboyfile/osub" "$hiboyfile2/osub"
    if [ $(cat /tmp/var/osub) != $(cat /tmp/var/nsub) ] && [ -f /tmp/var/nsub ] ; then
        echo -n `nvram get firmver_sub` > /tmp/var/osub
        content="新的固件： `cat /tmp/var/nsub | grep -v "^$"` ，目前旧固件： `cat /tmp/var/osub | grep -v "^$"` "
        logger -t "【微信推送】" "固件 新的更新：${content}"
        curl -s "http://sc.ftqq.com/$serverchan_sckey.send?text=【PDCN_"`nvram get computer_name`"】固件更新提醒" -d "&desp=${content}" &
        echo -n `cat /tmp/var/nsub | grep -v "^$"` > /tmp/var/osub
    fi
fi
    resub=`expr $resub + 1`
    [ "$resub" -gt 360 ] && resub=1
else
echo "Internet down 互联网断线"
resub=1
fi
sleep 60
continue
done

EEE
	chmod 755 "$serverchan_script"
fi



if [ ! -f "$kcptun_script" ] || [ ! -s "$kcptun_script" ] ; then
	cat > "$kcptun_script" <<-\EEE
#!/bin/sh
export PATH='/etc/storage/bin:/tmp/script:/etc/storage/script:/opt/usr/sbin:/opt/usr/bin:/opt/sbin:/opt/bin:/usr/local/sbin:/usr/sbin:/usr/bin:/sbin:/bin'
export LD_LIBRARY_PATH=/lib:/opt/lib
# Kcptun 项目地址：https://github.com/xtaci/kcptun
# 参数填写教程例子：https://github.com/xtaci/kcptun
# Kcptun Server一键安装脚本:https://blog.kuoruan.com/110.html
# kcptun服务端部署教程
# https://blog.kuoruan.com/102.html
# http://www.cmsky.com/kcptun/
# kcptun服务端主程序下载：
# 32位系统：wget --no-check-certificate http://opt.cn2qq.com/opt-file/server_linux_386 && chmod 755 server_linux_*
# 64位系统：wget --no-check-certificate http://opt.cn2qq.com/opt-file/server_linux_amd64 && chmod 755 server_linux_*
# 注意！！由于路由参数默认加上--nocomp，服务端也要加上--nocomp，在两端同时设定以关闭压缩。
# 两端参数必须一致的有:
# datashard
# parityshard
# nocomp
# key
# crypt
#
################################################################
# Kcptun 客户端配置例子
# 服务器地址（服务器自行购买）:111.111.111.111
# 服务器端口:29900
# 加密方式:none
# 监听端口:8388
# 服务器密码:自定义密码
#
# 备注：由于可用参数太多，不一一举例，其他参数可以参考项目主页的介绍。
#
################################################################
# Shadowsocks 客户端配置例子
# 服务端需要部署ss服务，新建SS服务端口：8388
# 配置路由SS服务器地址：127.0.0.1
# 配置路由SS服务器端口：8388
# 正确填写你刚刚新建SS服务端口、密码、加密方式、协议和混淆方式。
#
# 备注：如果其他设备做 Kcptun 客户端，SS服务器地址填写那个设备的内网地址。
# 
################################################################
# 客户端进程数量（守护脚本判断数据，请正确填写）
KCPNUM=1
killall client_linux_mips
#
################################################################
EEE
	chmod 755 "$kcptun_script"
fi


if [ ! -f "$jbls_script" ] || [ ! -s "$jbls_script" ] ; then
	cat > "$jbls_script" <<-\EEE
#!/bin/sh
export PATH='/etc/storage/bin:/tmp/script:/etc/storage/script:/opt/usr/sbin:/opt/usr/bin:/opt/sbin:/opt/bin:/usr/local/sbin:/usr/sbin:/usr/bin:/sbin:/bin'
export LD_LIBRARY_PATH=/lib:/opt/lib

# 感谢bigandy编译和提供： http://www.right.com.cn/forum/forum.php?mod=viewthread&tid=161324&page=672#pid1640158
# jetbrains license server 。
# 进展： Deamon 开发完成，通过了 IDEA， CLION 的验证测试。
# 特点：纯C编写，编译后仅16K大小，不给路由存储增加压力，独立http 服务。
# 适用情况：理论上适用于所有 Jetbrains 产品，但未完全测试。使用环境：padavan 路由hiboay固件，其他固件运行情况未知。

# 使用方法：

# Jetbrains License Server Emulator build Jan 13 2017 13:04:12  

# usage: jblicsvr [option]    
# option:  
  
#  -d             run on daemon mode  
#  -p <port>      port to listen  
#  -s <seconds>   seconds of prolongation period  
#  -u <name>      license to user name  

#  -d 进入守护进程模式  
#  -p httpd侦听端口，默认 1027 ，原作者女友生日  
#  -s license 有效时间（单位：秒），默认约为7天多（607875500），原厂server传递的数值。  
#  -u 授权给谁，默认为ilanyu（原作者）。  
# 彩蛋：http://my.router:1027/version
# http://ip:port/version

# 在线激活方式:注册界面选择授权服务器(license server)，点击多几次“Discover server”（自动发现配置），然后点击“OK” 。
# 或手动填写 http://my.router:1027 或 http://路由ip:1027 ，然后点击“OK” 

sed -Ei '/txt-record=_jetbrains-license-server.lan/d' /etc/storage/dnsmasq/dnsmasq.conf
nvram set lan_domain="lan"
lan_ipaddr=`nvram get lan_ipaddr`
echo "txt-record=_jetbrains-license-server.lan,url=http://$lan_ipaddr:1027" >> /etc/storage/dnsmasq/dnsmasq.conf
killall jblicsvr
jblicsvr -d -p 1027
restart_dhcpd

EEE
	chmod 755 "$jbls_script"
fi


if [ ! -f "$vlmcsdini_script" ] || [ ! -s "$vlmcsdini_script" ] ; then
	cat > "$vlmcsdini_script" <<-\EEE
# Office手动激活命令：

# cd C:\Program Files\Microsoft Office\Office15
# cscript ospp.vbs /sethst:192.168.123.1
# cscript ospp.vbs /act
# cscript ospp.vbs /dstatus

# windows手动激活命令

# slmgr.vbs /upk
# slmgr.vbs /skms 192.168.123.1
# slmgr.vbs /ipk XXXXX-XXXXX-XXXXX-XXXXX-XXXXX
# slmgr.vbs /ato
# slmgr.vbs /xpr

# key查看
# cat /etc/storage/key


#开头的字符号（#）或分号（;）的每一行被视为注释；删除（;）启用指定选项。
#ePID/HwId设置Windows为显式
;Windows = 06401-00206-471-111111-03-1033-9600.0000-3622014 / 01 02 03 04 05 06 07 08

#ePID设置Office2010（包含Visio和Project）为显式
;Office2010 = 06401-00096-199-222222-03-1033-9600.0000-3622014

#ePID/HwId设置Office2013（包含Visio和Project）为显式
;Office2013 = 06401-00206-234-333333-03-1033-9600.0000-3622014 / 01 02 03 04 05 06 07 08

#ePID/HwId设置Office2016（包含Visio和Project）为显式
;Office2016 = 06401-00206-437-444444-03-1033-9600.0000-3622014 / 01 02 03 04 05 06 07 08

# Set ePID/HwId for Windows China Government (Enterprise G/GN) explicitly
;WinChinaGov = 06401-03858-000-555555-03-1033-9600.0000-3622014 / 01 02 03 04 05 06 07 08

#使用兼容的VPN设备创建隐藏的本地IPv4地址
#命令行：-O
#VPN = <VPN适配器名称> [= <IPv4地址>] [/ <CIDR掩码>] [：<DHCP租期>
#使用VPN适配器“KMS镜像”，它的IP地址为192.168.123.100，租期为一天，使整个192.168.128.x成为隐藏的本地IPv4地址。
;VPN = KMS Mirror=192.168.123.100/24:1d

#使用自定义的TCP端口
#命令行：-P
#*** Port命令只有在vlmcsd被编译为使用MS RPC或简单套接字时才有效
#***使用Listen否则
;Port = 1688

#监听所有IPv4地址（默认端口1688）
# Command line: -L
# Does not work with MS RPC or simple sockets, use Port=
;Listen = 0.0.0.0:1688

#监听所有IPv6地址（默认端口1688）
# Command line: -L
;Listen = [::]:1688

#侦听所有私有IP地址，并拒绝来自公共IP地址的请求
# Command line: -o
# PublicIPProtectionLevel = 3

#允许绑定外部IP地址
# Command line: -F0 and -F1
;FreeBind = true

#程序启动时随机ePIDs（只有那些未指定的显式）
# Command line: -r
;RandomizationLevel = 1

#在ePIDs中使用特定区域 (1033 = 美国英语)，即使ePID是随机的
# Command line: -C
;LCID = 1033

#设置最多4个同时工作（分叉进程或线程）
# Command line: -m
;MaxWorkers = 4

#闲置30秒后断开用户
# Command line: -t
;ConnectionTimeout = 30

#每次请求后立即断开客户端
# Command line: -d and -k
;DisconnectClientsImmediately = yes

#写一个pid文件（包含vlmcsd的进程ID的文件）
# Command line: -p
;PidFile = /var/run/vlmcsd.pid

# Load a KMS data file
# Command line: -j
;KmsData = /etc/vlmcsd.kmd

#写日志到/var/log/vlmcsd.log
# Command line: -l (-e and -f also override this directive)
;LogFile = /var/log/vlmcsd.log

#不要在日志中包括日期和时间（默认值为true）
# Command line: -T0 and -T1
;LogDateAndTime = false

#创建详细日志
# Command line: -v and -q
;LogVerbose = true

#将已知产品列入白名单
# Command line: -K0, -K1, -K2, -K3
;WhiteListingLevel = 0

#检查客户端时间是否在系统时间的+/- 4小时之内
# Command line: -c0, -c1
;CheckClientTime = false

# Maintain a list of CMIDs
# Command line: -M0, -M1
;MaintainClients = false

# Start with empty CMID list (Requires MaintainClients = true)
# Command line: -E0, -E1
;StartEmpty = false

#设置激活间隔2小时
# Command line: -A
;ActivationInterval = 2h

#设置更新间隔7天
# Command line: -R
;RenewalInterval = 7d

# Exit vlmcsd if warning of certain level has been reached
# Command line: -x
# 0 = Never
# 1 = Exit, if any listening socket could not be established or TAP error occurs
;ExitLevel = 0

#运行程序的用户为vlmcsduser
# Command line: -u
;user = vlmcsduser

#运行程序的组为vlmcsdgroup
# Command line: -g
;group = vlmcsdgroup 

#禁用或启用RPC的NDR64传输语法（默认启用）
# Command line: -N0 and -N1
;UseNDR64 = true

#禁用或启用RPC的绑定时间特性协商（默认启用）
# Command line: -B0 and -B1
;UseBTFN = true

EEE
	chmod 755 "$vlmcsdini_script"
fi



if [ ! -f "$kmskey" ] ; then
	cat > "$kmskey" <<-\EEE
# Office手动激活命令：

# cd C:\Program Files\Microsoft Office\Office15
# cscript ospp.vbs /sethst:192.168.123.1
# cscript ospp.vbs /act
# cscript ospp.vbs /dstatus

# windows手动激活命令

# slmgr.vbs /upk
# slmgr.vbs /skms 192.168.123.1
# slmgr.vbs /ipk XXXXX-XXXXX-XXXXX-XXXXX-XXXXX
# slmgr.vbs /ato
# slmgr.vbs /xpr


# Office 2016 Professional Plus
# XQNVK-8JYDB-WJ9W3-YJ8YR-WFG99
# Office 2016 Standard
# JNRGM-WHDWX-FJJG3-K47QV-DRTFM
# Project 2016 Professional
# YG9NW-3K39V-2T3HJ-93F3Q-G83KT
# Project 2016 Standard
# GNFHQ-F6YQM-KQDGJ-327XX-KQBVC
# Visio 2016 Professional
# PD3PC-RHNGV-FXJ29-8JK7D-RJRJK
# Visio 2016 Standard
# 7WHWN-4T7MP-G96JF-G33KR-W8GF4
# Access 2016
# GNH9Y-D2J4T-FJHGG-QRVH7-QPFDW
# Excel 2016
# 9C2PK-NWTVB-JMPW8-BFT28-7FTBF
# OneNote 2016
# DR92N-9HTF2-97XKM-XW2WJ-XW3J6
# Outlook 2016
# R69KK-NTPKF-7M3Q4-QYBHW-6MT9B
# PowerPoint 2016
# J7MQP-HNJ4Y-WJ7YM-PFYGF-BY6C6
# Publisher 2016
# F47MM-N3XJP-TQXJ9-BP99D-8K837
# Skype for Business 2016
# 869NQ-FJ69K-466HW-QYCP2-DDBV6
# Word 2016
# WXY84-JN2Q9-RBCCQ-3Q3J3-3PFJ6

# Office 2013 Professional Plus
# YC7DK-G2NP3-2QQC3-J6H88-GVGXT
# Office 2013 Standard
# KBKQT-2NMXY-JJWGP-M62JB-92CD4
# Project 2013 Professional
# FN8TT-7WMH6-2D4X9-M337T-2342K
# Project 2013 Standard
# 6NTH3-CW976-3G3Y2-JK3TX-8QHTT
# Visio 2013 Professional
# C2FG9-N6J68-H8BTJ-BW3QX-RM3B3
# Visio 2013 Standard
# J484Y-4NKBF-W2HMG-DBMJC-PGWR7
# Access 2013
# NG2JY-H4JBT-HQXYP-78QH9-4JM2D
# Excel 2013
# VGPNG-Y7HQW-9RHP7-TKPV3-BG7GB
# InfoPath 2013
# DKT8B-N7VXH-D963P-Q4PHY-F8894
# Lync 2013
# 2MG3G-3BNTT-3MFW9-KDQW3-TCK7R
# OneNote 2013
# TGN6P-8MMBC-37P2F-XHXXK-P34VW
# Outlook 2013
# QPN8Q-BJBTJ-334K3-93TGY-2PMBT
# PowerPoint 2013
# 4NT99-8RJFH-Q2VDH-KYG2C-4RD4F
# Publisher 2013
# PN2WF-29XG2-T9HJ7-JQPJR-FCXK4
# Word 2013
# 6Q7VD-NX8JD-WJ2VH-88V73-4GBJ7
# SharePoint Designer 2013 Retail
# GYJRG-NMYMF-VGBM4-T3QD4-842DW
# Mondo 2013
# 42QTK-RN8M7-J3C4G-BBGYM-88CYV

# Office 2010 Professional Plus
# VYBBJ-TRJPB-QFQRF-QFT4D-H3GVB
# Office 2010 Standard
# V7QKV-4XVVR-XYV4D-F7DFM-8R6BM
# Office 2010 Starter Retail
# VXHHB-W7HBD-7M342-RJ7P8-CHBD6
# Access 2010
# V7Y44-9T38C-R2VJK-666HK-T7DDX
# Excel 2010
# H62QG-HXVKF-PP4HP-66KMR-CW9BM
# SharePoint Workspace 2010 (Groove)
# QYYW6-QP4CB-MBV6G-HYMCJ-4T3J4
# SharePoint Designer 2010 Retail
# H48K6-FB4Y6-P83GH-9J7XG-HDKKX
# InfoPath 2010
# K96W8-67RPQ-62T9Y-J8FQJ-BT37T
# OneNote 2010
# Q4Y4M-RHWJM-PY37F-MTKWH-D3XHX
# Outlook 2010
# 7YDC2-CWM8M-RRTJC-8MDVC-X3DWQ
# PowerPoint 2010
# RC8FX-88JRY-3PF7C-X8P67-P4VTT
# Project 2010 Professional
# YGX6F-PGV49-PGW3J-9BTGG-VHKC6
# Project 2010 Standard
# 4HP3K-88W3F-W2K3D-6677X-F9PGB
# Publisher 2010
# BFK7F-9MYHM-V68C7-DRQ66-83YTP
# Word 2010
# HVHB3-C6FV7-KQX9W-YQG79-CRY7T
# Visio 2010 Premium
# D9DWC-HPYVV-JGF4P-BTWQB-WX8BJ
# Visio 2010 Professional
# 7MCW8-VRQVK-G677T-PDJCM-Q8TCP
# Visio 2010 Standard
# 767HD-QGMWX-8QTDB-9G3R2-KHFGJ
# Office 2010 Home and Business
# D6QFG-VBYP2-XQHM7-J97RH-VVRCK
# Office 2010 Mondo
# YBJTT-JG6MD-V9Q7P-DBKXJ-38W9R
# Office 2010 Mondo
# 7TC2V-WXF6P-TD7RT-BQRXR-B8K32

# Windows 10 Professional
# W269N-WFGWX-YVC9B-4J6C9-T83GX
# Windows 10 Professional N
# MH37W-N47XK-V7XM9-C7227-GCQG9
# Windows 10 Enterprise
# NPPR9-FWDCX-D2C8J-H872K-2YT43
# Windows 10 Enterprise N
# DPH2V-TTNVB-4X9Q3-TJR4H-KHJW4
# Windows 10 Education
# NW6C2-QMPVW-D7KKK-3GKT6-VCFB2
# Windows 10 Education N
# 2WH4N-8QGBV-H22JP-CT43Q-MDWWJ
# Windows 10 Enterprise 2015 LTSB
# WNMTR-4C88C-JK8YV-HQ7T2-76DF9
# Windows 10 Enterprise 2015 LTSB N
# 2F77B-TNFGY-69QQF-B8YKP-D69TJ
# Windows 10 Home
# TX9XD-98N7V-6WMQ6-BX7FG-H8Q99
# Windows 10 Home N
# 3KHY7-WNT83-DGQKR-F7HPR-844BM
# Windows 10 Home Single Language
# 7HNRX-D7KGG-3K4RQ-4WPJ4-YTDFH
# Windows 10 Home Country Specific
# PVMJN-6DFY6-9CCP6-7BKTT-D3WVR

# Windows 8.1 Professional
# GCRJD-8NW9H-F2CDX-CCM8D-9D6T9
# Windows 8.1 Professional N
# HMCNV-VVBFX-7HMBH-CTY9B-B4FXY
# Windows 8.1 Enterprise
# MHF9N-XY6XB-WVXMC-BTDCT-MKKG7
# Windows 8.1 Enterprise N
# TT4HM-HN7YT-62K67-RGRQJ-JFFXW

# Windows Server 2012 R2 Server Standard
# D2N9P-3P6X9-2R39C-7RTCD-MDVJX
# Windows Server 2012 R2 Datacenter
# W3GGN-FT8W3-Y4M27-J84CP-Q3VJ9
# Windows Server 2012 R2 Essentials
# KNC87-3J2TX-XB4WP-VCPJV-M4FWM

# Windows 8.1 Professional WMC
# 789NJ-TQK6T-6XTH8-J39CJ-J8D3P
# Windows 8.1 Core
# M9Q9P-WNJJT-6PXPY-DWX8H-6XWKK
# Windows 8.1 Core N
# 7B9N3-D94CG-YTVHR-QBPX3-RJP64
# Windows 8.1 Core ARM
# XYTND-K6QKT-K2MRH-66RTM-43JKP
# Windows 8.1 Core Single Language
# BB6NG-PQ82V-VRDPW-8XVD2-V8P66
# Windows 8.1 Core Country Specific
# NCTT7-2RGK8-WMHRF-RY7YQ-JTXG3
# Windows Server 2012 R2 Cloud Storage
# 3NPTF-33KPT-GGBPR-YX76B-39KDD
# Windows 8.1 Embedded Industry
# NMMPB-38DD4-R2823-62W8D-VXKJB
# Windows 8.1 Embedded Industry Enterprise
# FNFKF-PWTVT-9RC8H-32HB2-JB34X
# Windows 8.1 Embedded Industry Automotive
# VHXM3-NR6FT-RY6RT-CK882-KW2CJ
# Windows 8.1 Core Connected (with Bing)
# 3PY8R-QHNP9-W7XQD-G6DPH-3J2C9
# Windows 8.1 Core Connected N (with Bing)
# Q6HTR-N24GM-PMJFP-69CD8-2GXKR
# Windows 8.1 Core Connected Single Language (with Bing)
# KF37N-VDV38-GRRTV-XH8X6-6F3BB
# Windows 8.1 Core Connected Country Specific (with Bing)
# R962J-37N87-9VVK2-WJ74P-XTMHR
# Windows 8.1 Professional Student
# MX3RK-9HNGX-K3QKC-6PJ3F-W8D7B
# Windows 8.1 Professional Student N
# TNFGH-2R6PB-8XM3K-QYHX2-J4296

# Windows 8 Professional
# NG4HW-VH26C-733KW-K6F98-J8CK4
# Windows 8 Professional N
# XCVCF-2NXM9-723PB-MHCB7-2RYQQ
# Windows 8 Enterprise
# 32JNW-9KQ84-P47T8-D8GGY-CWCK7
# Windows 8 Enterprise N
# JMNMF-RHW7P-DMY6X-RF3DR-X2BQT
# Windows 8 Core ARM
# DXHJF-N9KQX-MFPVR-GHGQK-Y7RKV
# Windows 8 Professional WMC
# GNBB8-YVD74-QJHX6-27H4K-8QHDG
# Windows 8 Embedded Industry Professional
# RYXVT-BNQG7-VD29F-DBMRY-HT73M
# Windows 8 Embedded Industry Enterprise
# NKB3R-R2F8T-3XCDP-7Q2KW-XWYQ2

# Windows Server 2012 / Windows 8 Core
# BN3D2-R7TKB-3YPBD-8DRP2-27GG4
# Windows Server 2012 N / Windows 8 Core N
# 8N2M2-HWPGY-7PGT9-HGDD8-GVGGY
# Windows Server 2012 Single Language / Windows 8 Core Single Language
# 2WN2H-YGCQR-KFX6K-CD6TF-84YXQ
# Windows Server 2012 Country Specific / Windows 8 Core Country Specific
# 4K36P-JN4VD-GDC6V-KDT89-DYFKP
# Windows Server 2012 Standard
# XC9B7-NBPP2-83J2H-RHMBY-92BT4
# Windows Server 2012 MultiPoint Standard
# HM7DN-YVMH3-46JC3-XYTG7-CYQJJ
# Windows Server 2012 MultiPoint Premium
# XNH6W-2V9GX-RGJ4K-Y8X6F-QGJ2G
# Windows Server 2012 Datacenter
# 48HP8-DN98B-MYWDG-T2DCC-8W83P

# Windows 7 Professional
# FJ82H-XT6CR-J8D7P-XQJJ2-GPDD4
# Windows 7 Professional N
# MRPKT-YTG23-K7D7T-X2JMM-QY7MG
# Windows 7 Professional E
# W82YF-2Q76Y-63HXB-FGJG9-GF7QX
# Windows 7 Enterprise
# 33PXH-7Y6KF-2VJC9-XBBR8-HVTHH
# Windows 7 Enterprise N
# YDRBP-3D83W-TY26F-D46B2-XCKRJ
# Windows 7 Enterprise E
# C29WB-22CC8-VJ326-GHFJW-H9DH4
# Windows 7 Embedded POS Ready
# YBYF6-BHCR3-JPKRB-CDW7B-F9BK4
# Windows 7 Embedded ThinPC
# 73KQT-CD9G6-K7TQG-66MRP-CQ22C
# Windows 7 Embedded Standard OEM
# XGY72-BRBBT-FF8MH-2GG8H-W7KCW

# Windows Server 2008 R2 Web
# 6TPJF-RBVHG-WBW2R-86QPH-6RTM4
# Windows Server 2008 R2 HPC edition
# TT8MH-CG224-D3D7Q-498W2-9QCTX
# Windows Server 2008 R2 Standard
# YC6KT-GKW9T-YTKYR-T4X34-R7VHC
# Windows Server 2008 R2 Enterprise
# 489J6-VHDMP-X63PK-3K798-CPX3Y
# Windows Server 2008 R2 Datacenter
# 74YFP-3QFB3-KQT8W-PMXWJ-7M648
# Windows Server 2008 R2 for Itanium-based Systems
# GT63C-RJFQ3-4GMB6-BRFB9-CB83V

# Windows MultiPoint Server 2010
# 736RG-XDKJK-V34PF-BHK87-J6X3K

# Windows Vista Business
# YFKBB-PQJJV-G996G-VWGXY-2V3X8
# Windows Vista Business N
# HMBQG-8H2RH-C77VX-27R82-VMQBT
# Windows Vista Enterprise
# VKK3X-68KWM-X2YGT-QR4M6-4BWMV
# Windows Vista Enterprise N
# VTC42-BM838-43QHV-84HX6-XJXKV

# Windows Web Server 2008
# WYR28-R7TFJ-3X2YQ-YCY4H-M249D
# Windows Server 2008 Standard
# TM24T-X9RMF-VWXK6-X8JC9-BFGM2
# Windows Server 2008 Standard without Hyper-V
# W7VD6-7JFBR-RX26B-YKQ3Y-6FFFJ
# Windows Server 2008 Enterprise
# YQGMW-MPWTJ-34KDK-48M3W-X4Q6V
# Windows Server 2008 Enterprise without Hyper-V
# 39BXF-X8Q23-P2WWT-38T2F-G3FPG
# Windows Server 2008 HPC (Compute Cluster)
# RCTX3-KWVHP-BR6TB-RB6DM-6X7HP
# Windows Server 2008 Datacenter
# 7M67G-PC374-GR742-YH8V4-TCBY3
# Windows Server 2008 Datacenter without Hyper-V
# 22XQ2-VRXRG-P8D42-K34TD-G3QQC
# Windows Server 2008 for Itanium-Based Systems
# 4DWFP-JF3DJ-B7DTH-78FJB-PDRHK

EEE
	chmod 666 "$kmskey"
fi




# create qos config file
if [ ! -f "$config_qos" ] && [ -f "/lib/modules/$(uname -r)/kernel/net/sched/sch_htb.ko" ] ; then
		cp -f /etc_ro/qos.conf /etc/storage
fi

if [ ! -f "$config_tinyproxy" ] || [ ! -s "$config_tinyproxy" ] ; then
		cat > "$config_tinyproxy" <<-\END
## tinyproxy.conf -- tinyproxy daemon configuration file
## https://github.com/tinyproxy/tinyproxy/blob/master/etc/tinyproxy.conf.in
#User nobody
#Group nobody
Port 9999
#Listen 192.168.0.1 #注释之后可以侦听所有网卡的请求
#Bind 192.168.0.1
Timeout 600
# DefaultErrorFile "/usr/local/share/tinyproxy/default.html"
# StatFile "/usr/local/share/tinyproxy/stats.html"
Logfile "/tmp/syslog.log"
LogLevel Info
PidFile "/var/run/tinyproxy.pid"
MaxClients 100
MinSpareServers 5
MaxSpareServers 20
StartServers 10
MaxRequestsPerChild 0
# Allow 127.0.0.1
ViaProxyName "tinyproxy"
# This is a list of ports allowed by tinyproxy when the CONNECT method
# is used.  To disable the CONNECT method altogether, set the value to 0.
# If no ConnectPort line is found, all ports are allowed (which is not
# very secure.)
#
# The following two ports are used by SSL.
#
ConnectPort 443
ConnectPort 563

END
fi

if [ ! -f "$config_mproxy" ] || [ ! -s "$config_mproxy" ] ; then
		cat > "$config_mproxy" <<-\END
#!/bin/sh
killall -9 mproxy
logger -t "【mproxy】" "运行 mproxy"
# 使用方法：https://github.com/examplecode/mproxy
# 本地监听端口
mproxy_port=8000

# 删除（#）启用指定选项
# 默认作为普通的代理服务器。
mproxy -l $mproxy_port -d &



# 在远程服务器启动mproxy作为远程代理
# 在远程作为加密代传输方式理服务器
# mproxy  -l 8081 -D -d &


# 本地启动 mproxy 作为本地代理，并指定传输方式加密。
# 在本地启动一个mporxy 并指定目上一步在远程部署的服务器地址和端口号。
# mproxy  -l 8080 -h xxx.xxx.xxx.xxx:8081 -E &


END
fi
chmod 777 "$config_mproxy"

func_fill2

if [ ! -f "$Builds" ] ; then
#	强制更新脚本reset
	/sbin/mtd_storage.sh resetsh
	nvram set ss_multiport="22,80,443"
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
    nvram set cloudxns_status=0
    nvram set aliddns_status=0
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
    /etc/storage/ez_buttons_script.sh ping &
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
#0 18 * * * /etc/storage/inet_state_script.sh 12 t

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

# 每1小时重启aliddns 域名解析
#16 */1 * * * nvram set aliddns_status=123 && /tmp/script/_aliddns & #删除开头的#启动命令

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

/etc/storage/ez_buttons_script.sh 3 &
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


cat >/tmp/qos_scheduler.sh <<-\EOF
#!/bin/sh
qosc=$1
echo 0 >/tmp/qos_scheduler.lock
logger -t "【QOS】" "终端在线检查启动"
while [ "1" ];
do
	if [ "$(cat /tmp/qoss_state)" == "0" ] ; then
	logger -t "【QOS】" "终端在线检查暂停"
	rm -f /tmp/qos_scheduler.lock
	exit
	fi
	#qos_t=`cat /proc/net/arp|fgrep -c 0x2`
	qos_t=`cat /tmp/static_ip.num`
	qos_t=`expr $qos_t + 1`
	if [ $((qos_t)) -le $qosc ] ; then
		if [ $(ifconfig |grep -c imq0) -gt 0 ] ; then
		logger -t "【QOS】" "取消限速, 当在线 $qos_t台, 小于或等于 $qosc 台"
			ip link set imq0 down
			ip link set imq1 down
		fi
	else
		if [ $(ifconfig |grep -c imq0) -eq 0 ] ; then
			logger -t "【QOS】" "开始限速, 当在线 $qos_t台, 大于 $qosc 台"
			ip link set imq0 up
			ip link set imq1 up
			sleep 6
			port=$(iptables -t mangle -L | grep 'IMQ: todev 0' | wc -l)
			if [ "$port" = 0 ] ; then
				logger -t "【QOS】" "找不到 QOS 规则, 重新添加"
				/etc/storage/post_iptables_script.sh &
			fi
			
		fi
	fi
	sleep 69
continue
done
EOF
chmod 777 "/tmp/qos_scheduler.sh"

	if [ ! -f "/etc/storage/cow_script.sh" ] || [ ! -s "/etc/storage/cow_script.sh" ] ; then
cat > "/etc/storage/cow_script.sh" <<-\FOF
#!/bin/sh
export PATH='/etc/storage/bin:/tmp/script:/etc/storage/script:/opt/usr/sbin:/opt/usr/bin:/opt/sbin:/opt/bin:/usr/local/sbin:/usr/sbin:/usr/bin:/sbin:/bin'
export LD_LIBRARY_PATH=/lib:/opt/lib
sed -Ei '/UI设置自动生成/d' /etc/storage/cow_config_script.sh
sed -Ei '/^$/d' /etc/storage/cow_config_script.sh
ss_mode_x=`nvram get ss_mode_x`
ss_mode_x=${ss_mode_x:-"0"}
ss_rdd_server=`nvram get ss_server2`
kcptun2_enable=`nvram get kcptun2_enable`
kcptun2_enable=${kcptun2_enable:-"0"}
kcptun2_enable2=`nvram get kcptun2_enable2`
kcptun2_enable2=${kcptun2_enable2:-"0"}
[ "$ss_mode_x" != "0" ] && kcptun2_enable=$kcptun2_enable2
[ "$kcptun2_enable" = "2" ] && ss_rdd_server=""
ss_run_ss_local=`nvram get ss_run_ss_local`
ss_s1_local_port=`nvram get ss_s1_local_port`
ss_s2_local_port=`nvram get ss_s2_local_port`
ss_s1_local_port=${ss_s1_local_port:-"1081"}
ss_s2_local_port=${ss_s2_local_port:-"1082"}
nvram set ss_s1_local_port=$ss_s1_local_port
nvram set ss_s2_local_port=$ss_s2_local_port
lan_ipaddr=`nvram get lan_ipaddr`
sed -Ei "/$lan_ipaddr:$ss_s1_local_port/d" /etc/storage/cow_config_script.sh
sed -Ei "/$lan_ipaddr:$ss_s2_local_port/d" /etc/storage/cow_config_script.sh
if [ "$ss_mode_x" = "3" ] || [ "$ss_run_ss_local" = "1" ] ; then
cat >> "/etc/storage/cow_config_script.sh" <<-EUI
# UI设置自动生成 
proxy = socks5://$lan_ipaddr:$ss_s1_local_port
EUI
if [ ! -z $ss_rdd_server ] ; then
cat >> "/etc/storage/cow_config_script.sh" <<-EUI
# UI设置自动生成 
proxy = socks5://$lan_ipaddr:$ss_s2_local_port
EUI
fi
fi
FOF
chmod 777 "/etc/storage/cow_script.sh"
	fi
	if [ ! -f "/etc/storage/cow_config_script.sh" ] || [ ! -s "/etc/storage/cow_config_script.sh" ] ; then
cat > "/etc/storage/cow_config_script.sh" <<-\COWCON
# 配置文件中 # 开头的行为注释
#
# 代理服务器监听地址，重复多次来指定多个监听地址，语法：
#
#   listen = protocol://[optional@]server_address:server_port
#
# 支持的 protocol 如下：
#
# HTTP (提供 http 代理):
#   listen = http://127.0.0.1:7777
#
#   上面的例子中，cow 生成的 PAC url 为 http://127.0.0.1:7777/pac
#   配置浏览器或系统 HTTP 和 HTTPS 代理时请填入该地址
#   若配置代理时有对所有协议使用该代理的选项，且你不清楚此选项的含义，请勾选
#
# cow (需两个 cow 服务器配合使用):
#   listen = cow://encrypt_method:password@1.2.3.4:5678
#
#   若 1.2.3.4:5678 在国外，位于国内的 cow 配置其为二级代理后，两个 cow 之间可以
#   通过加密连接传输 http 代理流量。目前的加密采用与 shadowsocks 相同的方式。
#
# 其他说明：
# - 若 server_address 为 0.0.0.0，监听本机所有 IP 地址
# - 可以用如下语法指定 PAC 中返回的代理服务器地址（当使用端口映射将 http 代理提供给外网时使用）
#   listen = http://127.0.0.1:7777 1.2.3.4:5678
#
listen = http://0.0.0.0:7777
#
# 日志文件路径，如不指定则输出到 stdout
logFile = /tmp/syslog.log
#
# COW 默认仅对被墙网站使用二级代理
# 下面选项设置为 true 后，所有网站都通过二级代理访问
#alwaysProxy = false
#
# 指定多个二级代理时使用的负载均衡策略，可选策略如下
#
#   backup:  默认策略，优先使用第一个指定的二级代理，其他仅作备份使用
#   hash:    根据请求的 host name，优先使用 hash 到的某一个二级代理
#   latency: 优先选择连接延迟最低的二级代理
#
# 一个二级代理连接失败后会依次尝试其他二级代理
# 失败的二级代理会以一定的概率再次尝试使用，因此恢复后会重新启用
loadBalance = backup
#
#############################
# 指定二级代理
#############################
#
# 二级代理统一使用下列语法指定：
#
#   proxy = protocol://[authinfo@]server:port
#
# 重复使用 proxy 多次指定多个二级代理，backup 策略将按照二级代理出现的顺序来使用
#
# 目前支持的二级代理及配置举例：
#
# SOCKS5:
#   proxy = socks5://127.0.0.1:1080
#
# HTTP:
#   proxy = http://127.0.0.1:8080
#   proxy = http://user:password@127.0.0.1:8080
#
#
# 自动生成ss-local_1.json配置
# 自动生成ss-local_2.json配置
#
#   用户认证信息为可选项
#
# shadowsocks:
#   proxy = ss://encrypt_method:password@1.2.3.4:8388
#   proxy = ss://encrypt_method-auth:password@1.2.3.4:8388
#
#   encrypt_method 添加 -auth 启用 One Time Auth
#   authinfo 中指定加密方法和密码，所有支持的加密方法如下：
#     aes-128-cfb, aes-192-cfb, aes-256-cfb,
#     bf-cfb, cast5-cfb, des-cfb, rc4-md5,
#     chacha20, salsa20, rc4, table
#   推荐使用 aes-128-cfb
#
# cow:
#   proxy = cow://method:passwd@1.2.3.4:4321
#
#   authinfo 与 shadowsocks 相同
#
#
#############################
# 执行 ssh 命令创建 SOCKS5 代理
#############################
#
# 下面的选项可以让 COW 执行 ssh 命令创建本地 SOCKS5 代理，并在 ssh 断开后重连
# COW 会自动使用通过 ssh 命令创建的代理，无需再通过 proxy 选项指定
# 可重复指定多个
#
# 注意这一功能需要系统上已有 ssh 命令，且必须使用 ssh public key authentication
#
# 若指定该选项，COW 将执行以下命令：
#     ssh -n -N -D <local_socks_port> -p <server_ssh_port> <user@server>
# server_ssh_port 端口不指定则默认为 22
# 如果要指定其他 ssh 选项，请修改 ~/.ssh/config
#sshServer = user@server:local_socks_port[:server_ssh_port]
#
#############################
# 认证
#############################
#
# 指定允许的 IP 或者网段。网段仅支持 IPv4，可以指定 IPv6 地址，用逗号分隔多个项
# 使用此选项时别忘了添加 127.0.0.1，否则本机访问也需要认证
#allowedClient = 127.0.0.1, 192.168.1.0/24, 10.0.0.0/8
#
# 要求客户端通过用户名密码认证
# COW 总是先验证 IP 是否在 allowedClient 中，若不在其中再通过用户名密码认证
#userPasswd = username:password
#
# 如需指定多个用户名密码，可在下面选项指定的文件中列出，文件中每行内容如下
#   username:password[:port]
# port 为可选项，若指定，则该用户只能从指定端口连接 COW
# 注意：如有重复用户，COW 会报错退出
#userPasswdFile = /path/to/file
#
# 认证失效时间
# 语法：2h3m4s 表示 2 小时 3 分钟 4 秒
#authTimeout = 2h
#
#############################
# 高级选项
#############################
#
# 将指定的 HTTP error code 认为是被干扰，使用二级代理重试，默认为空
#httpErrorCode =
#
# 最多允许使用多少个 CPU 核
#core = 2
#
# 检测超时时间使用的网站，最好使用能快速访问的站点
estimateTarget = www.163.com
#
# 允许建立隧道连接的端口，多个端口用逗号分隔，可重复多次
# 默认总是允许下列服务的端口: ssh, http, https, rsync, imap, pop, jabber, cvs, git, svn
# 如需允许其他端口，请用该选项添加
# 限制隧道连接的端口可以防止将运行 COW 的服务器上只监听本机 ip 的服务暴露给外部
#tunnelAllowedPort = 80, 443
#
# GFW 会使 DNS 解析超时，也可能返回错误的地址，能连接但是读不到任何内容
# 下面两个值改小一点可以加速检测网站是否被墙，但网络情况差时可能误判
#
# 创建连接超时（语法跟 authTimeout 相同）
#dialTimeout = 5s
# 从服务器读超时
#readTimeout = 5s
#
# 基于 client 是否很快关闭连接来检测 SSL 错误，只对 Chrome 有效
# （Chrome 遇到 SSL 错误会直接关闭连接，而不是让用户选择是否继续）
# 可能将可直连网站误判为被墙网站，当 GFW 进行 SSL 中间人攻击时可以考虑使用
#detectSSLErr = false
#
# 修改 stat/blocked/direct 文件路径，如不指定，默认在配置文件所在目录下
# 执行 cow 的用户需要有对 stat 文件所在目录的写权限才能更新 stat 文件
#statFile = <dir to rc file>/stat
blockedFile = /etc/storage/basedomain.txt
#directFile = <dir to rc file>/direct
#
#
COWCON
chmod 777 "/etc/storage/cow_config_script.sh"
	fi


	if [ ! -f "/etc/storage/meow_script.sh" ] || [ ! -s "/etc/storage/meow_script.sh" ] ; then
cat > "/etc/storage/meow_script.sh" <<-\FOF
#!/bin/sh
source /etc/storage/script/init.sh
export PATH='/etc/storage/bin:/tmp/script:/etc/storage/script:/opt/usr/sbin:/opt/usr/bin:/opt/sbin:/opt/bin:/usr/local/sbin:/usr/sbin:/usr/bin:/sbin:/bin'
export LD_LIBRARY_PATH=/lib:/opt/lib
sed -Ei '/UI设置自动生成/d' /etc/storage/meow_config_script.sh
sed -Ei '/^$/d' /etc/storage/meow_config_script.sh
ss_mode_x=`nvram get ss_mode_x`
ss_mode_x=${ss_mode_x:-"0"}
ss_rdd_server=`nvram get ss_server2`
kcptun2_enable=`nvram get kcptun2_enable`
kcptun2_enable=${kcptun2_enable:-"0"}
kcptun2_enable2=`nvram get kcptun2_enable2`
kcptun2_enable2=${kcptun2_enable2:-"0"}
[ "$ss_mode_x" != "0" ] && kcptun2_enable=$kcptun2_enable2
[ "$kcptun2_enable" = "2" ] && ss_rdd_server=""
ss_run_ss_local=`nvram get ss_run_ss_local`
ss_s1_local_port=`nvram get ss_s1_local_port`
ss_s2_local_port=`nvram get ss_s2_local_port`
ss_s1_local_port=${ss_s1_local_port:-"1081"}
ss_s2_local_port=${ss_s2_local_port:-"1082"}
nvram set ss_s1_local_port=$ss_s1_local_port
nvram set ss_s2_local_port=$ss_s2_local_port
lan_ipaddr=`nvram get lan_ipaddr`
sed -Ei "/$lan_ipaddr:$ss_s1_local_port/d" /etc/storage/meow_config_script.sh
sed -Ei "/$lan_ipaddr:$ss_s2_local_port/d" /etc/storage/meow_config_script.sh
if [ ! -f "/etc/storage/meow_direct_script.sh" ] || [ ! -s "/etc/storage/meow_direct_script.sh" ] ; then
logger -t "【meow】" "找不到 直连列表 下载 $hiboyfile/direct.txt"
wgetcurl.sh /etc/storage/meow_direct_script.sh "$hiboyfile/direct.txt" "$hiboyfile2/direct.txt"
chmod 666 "/etc/storage/meow_direct_script.sh"
fi
if [ "$ss_mode_x" = "3" ] || [ "$ss_run_ss_local" = "1" ] ; then
cat >> "/etc/storage/meow_config_script.sh" <<-EUI
# UI设置自动生成 
proxy = socks5://$lan_ipaddr:$ss_s1_local_port
EUI
if [ ! -z $ss_rdd_server ] ; then
cat >> "/etc/storage/meow_config_script.sh" <<-EUI
# UI设置自动生成 
proxy = socks5://$lan_ipaddr:$ss_s2_local_port
EUI
fi
fi
FOF
chmod 777 "/etc/storage/meow_script.sh"
	fi
	if [ ! -f "/etc/storage/meow_config_script.sh" ] || [ ! -s "/etc/storage/meow_config_script.sh" ] ; then
cat > "/etc/storage/meow_config_script.sh" <<-\MECON
# 配置文件中 # 开头的行为注释
#
# 代理服务器监听地址，重复多次来指定多个监听地址，语法：
#
#   listen = protocol://[optional@]server_address:server_port
#
# 支持的 protocol 如下：
#
# HTTP (提供 http 代理):
#   listen = http://127.0.0.1:4411
#
#   上面的例子中，MEOW 生成的 PAC url 为 http://127.0.0.1:4411/pac
#
# HTTPS (提供 https 代理):
#   listen = https://example.com:443
#   cert = /path/to/cert.pem
#   key = /path/to/key.pem
#
#   上面的例子中，MEOW 生成的 PAC url 为 https://example.com:443/pac
#
# MEOW (需两个 MEOW 服务器配合使用):
#   listen = meow://encrypt_method:password@1.2.3.4:5678
#
#   若 1.2.3.4:5678 在国外，位于国内的 MEOW 配置其为二级代理后，两个 MEOW 之间可以
#   通过加密连接传输 http 代理流量。采用与 shadowsocks 相同的加密方式。
#
# 其他说明：
# - 若 server_address 为 0.0.0.0，监听本机所有 IP 地址
# - 可以用如下语法指定 PAC 中返回的代理服务器地址（当使用端口映射将 http 代理提供给外网时使用）
#   listen = http://127.0.0.1:4411 1.2.3.4:5678
#
listen = http://0.0.0.0:4411
#
#############################
# 通过IP判断是否直连，默认开启
#############################
#judgeByIP = true

# 日志文件路径，如不指定则输出到 stdout
logFile = /tmp/syslog.log
#
# 指定多个二级代理时使用的负载均衡策略，可选策略如下
#
#   backup:  默认策略，优先使用第一个指定的二级代理，其他仅作备份使用
#   hash:    根据请求的 host name，优先使用 hash 到的某一个二级代理
#   latency: 优先选择连接延迟最低的二级代理
#
# 一个二级代理连接失败后会依次尝试其他二级代理
# 失败的二级代理会以一定的概率再次尝试使用，因此恢复后会重新启用
loadBalance = backup
#
#############################
# 指定二级代理
#############################
#
# 二级代理统一使用下列语法指定：
#
#   proxy = protocol://[authinfo@]server:port
#
# 重复使用 proxy 多次指定多个二级代理，backup 策略将按照二级代理出现的顺序来使用
#
# 目前支持的二级代理及配置举例：
#
# SOCKS5:
#   proxy = socks5://127.0.0.1:1080
#
# HTTP:
#   proxy = http://127.0.0.1:8080
#   proxy = http://user:password@127.0.0.1:8080
#
#   用户认证信息为可选项
#
# HTTPS:
#   proxy = https://example.com:8080
#   proxy = https://user:password@example.com:8080
#
#   用户认证信息为可选项
#
# Shadowsocks:
#   proxy = ss://encrypt_method:password@1.2.3.4:8388
#
#   authinfo 中指定加密方法和密码，所有支持的加密方法如下：
#     aes-128-cfb, aes-192-cfb, aes-256-cfb,
#     bf-cfb, cast5-cfb, des-cfb, rc4-md5,
#     chacha20, salsa20, rc4, table
#
# MEOW:
#   proxy = meow://method:passwd@1.2.3.4:4321
#
#   authinfo 与 shadowsocks 相同
#
#
#############################
# 执行 ssh 命令创建 SOCKS5 代理
#############################
#
# 下面的选项可以让 MEOW 执行 ssh 命令创建本地 SOCKS5 代理，并在 ssh 断开后重连
# MEOW 会自动使用通过 ssh 命令创建的代理，无需再通过 proxy 选项指定
# 可重复指定多个
#
# 注意这一功能需要系统上已有 ssh 命令，且必须使用 ssh public key authentication
#
# 若指定该选项，MEOW 将执行以下命令：
#     ssh -n -N -D <local_socks_port> -p <server_ssh_port> <user@server>
# server_ssh_port 端口不指定则默认为 22
# 如果要指定其他 ssh 选项，请修改 ~/.ssh/config
#sshServer = user@server:local_socks_port[:server_ssh_port]
#
#############################
# 认证
#############################
#
# 指定允许的 IP 或者网段。网段仅支持 IPv4，可以指定 IPv6 地址，用逗号分隔多个项
# 使用此选项时别忘了添加 127.0.0.1，否则本机访问也需要认证
#allowedClient = 127.0.0.1, 192.168.1.0/24, 10.0.0.0/8
#
# 要求客户端通过用户名密码认证
# MEOW 总是先验证 IP 是否在 allowedClient 中，若不在其中再通过用户名密码认证
#userPasswd = username:password
#
# 如需指定多个用户名密码，可在下面选项指定的文件中列出，文件中每行内容如下
#   username:password[:port]
# port 为可选项，若指定，则该用户只能从指定端口连接 MEOW
# 注意：如有重复用户，MEOW 会报错退出
#userPasswdFile = /path/to/file
#
# 认证失效时间
# 语法：2h3m4s 表示 2 小时 3 分钟 4 秒
#authTimeout = 2h
#
#############################
# 高级选项
#############################
#
# 将指定的 HTTP error code 认为是被干扰，使用二级代理重试，默认为空
#httpErrorCode =
#
# 最多允许使用多少个 CPU 核
#core = 2
#
# 修改 direct/proxy 文件路径，如不指定，默认在配置文件所在目录下
directFile = /etc/storage/meow_direct_script.sh
proxyFile = /etc/storage/basedomain.txt
MECON
chmod 777 "/etc/storage/meow_config_script.sh"
	fi



	if [ ! -f "/etc/storage/softether_script.sh" ] || [ ! -s "/etc/storage/softether_script.sh" ] ; then
cat > "/etc/storage/softether_script.sh" <<-\FOF
#!/bin/sh
export PATH='/opt/softether:/etc/storage/bin:/tmp/script:/etc/storage/script:/opt/usr/sbin:/opt/usr/bin:/opt/sbin:/opt/bin:/usr/local/sbin:/usr/sbin:/usr/bin:/sbin:/bin'
export LD_LIBRARY_PATH=/lib:/opt/lib
softether_path=`nvram get softether_path`
[ -z $softether_path ] && softether_path=`which vpnserver` && nvram set softether_path=$softether_path
SVC_PATH=$softether_path
[ -f /opt/softether/vpn_server.config ] && [ ! -f /etc/storage/vpn_server.config ] && cp -f /opt/softether/vpn_server.config /etc/storage/vpn_server.config
[ ! -f /etc/storage/vpn_server.config ] && touch /etc/storage/vpn_server.config
ln -sf /etc/storage/vpn_server.config /opt/softether/vpn_server.config
$SVC_PATH start
i=120
until [ ! -z "$tap" ]
do
    i=$(($i-1))
    tap=`ifconfig | grep tap_ | awk '{print $1}'`
    if [ "$i" -lt 1 ];then
        logger -t "【softether】" "错误：不能正确启动 vpnserver!"
        rm -rf /etc/storage/dnsmasq/dnsmasq.d/softether.conf
        restart_dhcpd
        logger -t "【softether】" "错误：不能正确启动 vpnserver!"
        [ -z "`pidof vpnserver`" ] && logger -t "【softether】" "启动失败, 注意检查hamcore.se2、vpncmd、vpnserver是否下载完整,10秒后自动尝试重新启动" && sleep 10 && nvram set softether_status=00 && /tmp/script/_softether &
        exit
    fi
    sleep 1
done

logger -t "【softether】" "正确启动 vpnserver!"
brctl addif br0 $tap
echo interface=tap_vpn > /etc/storage/dnsmasq/dnsmasq.d/softether.conf
restart_dhcpd
mtd_storage.sh save &
FOF
chmod 777 "/etc/storage/softether_script.sh"
	fi



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
source /etc/storage/script/init.sh
[ -f /tmp/script.lock ] && exit 0
touch /tmp/script.lock

. /etc/storage/script0_script.sh
ln -sf "/etc/storage/PhMain.ini" "/etc/PhMain.ini"
ln -sf "/etc/storage/init.status" "/etc/init.status"
rm -f "/opt/etc/init.d/S96sh3.sh"
echo "" > /var/log/shadowsocks_watchdog.log
echo "" > /var/log/Pcap_DNSProxy_watchdog.log
echo "" > /var/log/chinadns_watchdog.log
http_username=`nvram get http_username`
export PATH='/etc/storage/bin:/tmp/script:/etc/storage/script:/opt/usr/sbin:/opt/usr/bin:/opt/sbin:/opt/bin:/usr/local/sbin:/usr/sbin:/usr/bin:/sbin:/bin'
export LD_LIBRARY_PATH=/lib:/opt/lib
sed -Ei '/github|ipip.net|_vlmcs._tcp|txt-record=_jetbrains-license-server.lan|adbyby_host.conf|cflist.conf|accelerated-domains|no-resolv|server=127.0.0.1#8053|dns-forward-max=1000|min-cache-ttl=1800/d' /etc/storage/dnsmasq/dnsmasq.conf
sed -Ei "/\/tmp\/ss\/dnsmasq.d/d" /etc/storage/dnsmasq/dnsmasq.conf
rm -f /tmp/ss/dnsmasq.d/*
killall crond
restart_dhcpd ; sleep 1
[ -f /tmp/menu_title_re ] && /etc/storage/www_sh/menu_title.sh re &
mkdir -p /tmp/script
{ echo '#!/bin/sh' ; echo /etc/storage/script/Sh01_mountopt.sh '"$@"' ; } > /tmp/script/_mountopt
chmod 777 /tmp/script/_mountopt
nvram set ss_internet="0"
/etc/storage/inet_state_script.sh 12 t
/etc/storage/script/Sh??_mento_hust.sh &
ping_text=`ping -4 114.114.114.114 -c 1 -w 2 -q`
ping_time=`echo $ping_text | awk -F '/' '{print $4}'| awk -F '.' '{print $1}'`
ping_loss=`echo $ping_text | awk -F ', ' '{print $3}' | awk '{print $1}'`
if [ ! -z "$ping_time" ] ; then
	echo "ping：$ping_time ms 丢包率：$ping_loss"
 else
	echo "ping：失效"
fi
rb=1
while [ -z "$ping_time" ];
do
logger -t "【自定义脚本】" "等待联网后开始脚本"
sleep 10

ping_text=`ping -4 114.114.114.114 -c 1 -w 2 -q`
ping_time=`echo $ping_text | awk -F '/' '{print $4}'| awk -F '.' '{print $1}'`
ping_loss=`echo $ping_text | awk -F ', ' '{print $3}' | awk '{print $1}'`
if [ ! -z "$ping_time" ] ; then
	echo "ping：$ping_time ms 丢包率：$ping_loss"
 else
	echo "ping：失效"
fi
rb=`expr $rb + 1`
if [ "$rb" -gt 5 ] ; then
	logger -t "【自定义脚本】" "等待联网超时"
	ping_time=200
	break
fi
done
if [[ $(cat /tmp/apauto.lock) == 1 ]] ; then
	killall sh_apauto.sh
	/tmp/sh_apauto.sh &
fi
[ -d /etc/storage/script ] && chmod 777 /etc/storage/script -R
/etc/storage/script/sh_upscript.sh
/etc/storage/www_sh/menu_title.sh upver &
/etc/storage/script/Sh01_mountopt.sh upopt
/etc/storage/script/Sh01_mountopt.sh libmd5_check
/tmp/sh_theme.sh &
run_aria
run_transmission
rm -f /tmp/cron_adb.lock
[ ! -f /etc/storage/PhMain.ini ] && touch /etc/storage/PhMain.ini
[ ! -f /etc/storage/init.status ] && touch /etc/storage/init.status
rm -f /tmp/webui_yes
/etc/storage/script/sh_opt_script_check.sh
chmod 777 /tmp/script -R
touch /tmp/webui_yes
# extend path to /opt
for i in `ls /opt/etc/init.d/_* 2>/dev/null` ; do
	rm -f ${i}
done
for i in `ls /opt/etc/init.d/Sh??_* 2>/dev/null` ; do
	rm -f ${i}
done
# start all services S* in /opt/etc/init.d
for i in `ls /opt/etc/init.d/S??* 2>/dev/null` ; do
	[ ! -x "${i}" ] && continue
	[ ! -f /tmp/webui_yes ] && continue
	${i} start
done
restart_firewall &
rm -f /tmp/script.lock
logger -t "【自定义脚本】" "脚本完成"
EEE
	chmod 755 "$script_script"
fi

}

case "$1" in
load)
    func_get_mtd
    func_mdir
    func_load
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



