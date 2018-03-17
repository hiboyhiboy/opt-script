#!/bin/sh

Builds="/etc/storage/Builds-2018-3-18"
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
		rm -f $script0_script $script_script $script1_script $script2_script $script3_script $crontabs_script $kmskey $DNSPOD_script $cloudxns_script $aliddns_script
		rm -f $serverchan_script $script_start $script_started $script_postf $script_postw $script_inets $script_vpnsc $script_vpncs $script_ezbtn 
	fi

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




# create qos config file
if [ ! -f "$config_qos" ] && [ -f "/lib/modules/$(uname -r)/kernel/net/sched/sch_htb.ko" ] ; then
		cp -f /etc_ro/qos.conf /etc/storage
fi

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
touch /tmp/script_script_yes
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
sleep 8

ping_text=`ping -4 114.114.114.114 -c 1 -w 2 -q`
ping_time=`echo $ping_text | awk -F '/' '{print $4}'| awk -F '.' '{print $1}'`
ping_loss=`echo $ping_text | awk -F ', ' '{print $3}' | awk '{print $1}'`
if [ ! -z "$ping_time" ] ; then
	echo "ping：$ping_time ms 丢包率：$ping_loss"
 else
	echo "ping：失效"
fi
rb=`expr $rb + 1`
if [ "$rb" -gt 3 ] ; then
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



