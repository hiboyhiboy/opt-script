#!/bin/bash
#copyright by hiboy
export PATH='/etc/storage/bin:/tmp/script:/etc/storage/script:/opt/usr/sbin:/opt/usr/bin:/opt/sbin:/opt/bin:/usr/local/sbin:/usr/sbin:/usr/bin:/sbin:/bin'
export LD_LIBRARY_PATH=/lib:/opt/lib
export QUIC_GO_DISABLE_ECN=true;
export QUIC_GO_DISABLE_GSO=true;
#hiboyfile="https://bitbucket.org/hiboyhiboy/opt-file/raw/master"
#hiboyscript="https://bitbucket.org/hiboyhiboy/opt-script/raw/master"
#hiboyfile2="https://gcore.jsdelivr.net/gh/HiboyHiboy/opt-file"
#hiboyscript2="https://gcore.jsdelivr.net/gh/HiboyHiboy/opt-script"
hiboyfile="https://opt.cn2qq.com/opt-file"
hiboyscript="https://opt.cn2qq.com/opt-script"
#hiboyfile2="https://raw.githubusercontent.com/hiboyhiboy/opt-file/master"
#hiboyscript2="https://raw.githubusercontent.com/hiboyhiboy/opt-script/master"
hiboyfile2="https://testingcf.jsdelivr.net/gh/HiboyHiboy/opt-file"
hiboyscript2="https://testingcf.jsdelivr.net/gh/HiboyHiboy/opt-script"
# --user-agent
user_agent='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36'
ACTION=$1
scriptfilepath=$(cd "$(dirname "$0")"; pwd)/$(basename $0)
#echo $scriptfilepath
scriptpath=$(cd "$(dirname "$0")"; pwd)
#echo $scriptpath
scriptname=$(basename $0)
#echo $scriptname
cmd_log2=' 2>&1 | awk '"'"'{cmd="logger -t '"'"'"'"'"'"'"'"'【'"'"'$cmd_name'"'"'】'"'"'"'"'"' '"'"' "'"'"'"$0"'"'"'"'"'"' "'"'"';";system(cmd)}'"'" 
[ -s /dev/null ] && { rm -f /dev/null ; mknod /dev/null c 1 3 ; chmod 666 /dev/null; }
chmod 755 /etc/storage/*.sh
ulimit -HSn 65536

x_wget_check_timeout_network_x()
{
[ -z "$(which wget)" ] && return
check_tmp="/tmp/check_timeout/$1"
wget --user-agent "$user_agent" -q  -T 3 -t 1 "$ss_link_2" -O /dev/null --spider --server-response
if [ "$?" != "0" ] ; then
	wget --user-agent "$user_agent" -q  -T 3 -t 2 "1.0.0.1" -O /dev/null --spider --server-response
	if [ "$?" == "0" ] ; then
	echo "check2=200" >> $check_tmp
	else
	echo "check2=404" >> $check_tmp
	fi
else
	echo "check2=200" >> $check_tmp
fi
echo "checkB=200" >> $check_tmp
sleep 3
rm -f $check_tmp
}

x_curl_check_timeout_network_x()
{
[ -z "$(which curl)" ] && return
check_tmp="/tmp/check_timeout/$1"
check_code="$(curl -L --connect-timeout 3 --user-agent "$user_agent" -s -w "%{http_code}" "$ss_link_2" -o /dev/null -I)"
if [ "$check_code" != "200" ] ; then
	check_code="$(curl -L --connect-timeout 3 --user-agent "$user_agent" -s -w "%{http_code}" "1.0.0.1" -o /dev/null -I)"
	if [ "$check_code" == "200" ] ; then
	echo "check2=200" >> $check_tmp
	else
	echo "check2=404" >> $check_tmp
	fi
else
	echo "check2=200" >> $check_tmp
fi
echo "checkA=200" >> $check_tmp
sleep 3
rm -f $check_tmp
}

check_timeout_network()
{
mkdir -p /tmp/check_timeout
[ -s /tmp/check_timeout/check ] && source /tmp/check_timeout/check
if [ "$2" == "check" ] || [ "$check2" == "404" ] ; then
rm -f /tmp/check_timeout/check
fi
[ ! -f /tmp/check_timeout/ver_time ] && echo -n "0" > /tmp/check_timeout/ver_time
new_time=$(date "+1%m%d%H%M")
if [ $(($new_time - $(cat /tmp/check_timeout/ver_time))) -ge 3 ] || [ ! -s /tmp/check_timeout/check ] ; then
	echo "$new_time check_timeout_network 开始新的检测"
	echo -n "$new_time" > /tmp/check_timeout/ver_time
else
	echo "$new_time check_timeout_network 间隔少于3分钟直接返回上次检测值 $check2"
	return
fi
ss_link_2=`nvram get ss_link_2`
checkA="404"
checkB="404"
check2="404"

if [ ! -z "$(which curl)" ] ; then
SEED=`tr -cd 0-9 </dev/urandom | head -c 8`
RND_NUM=`echo $SEED 1 100|awk '{srand($1);printf "%d",rand()*10000%($3-$2)+$2}'`
[ "$RND_NUM" -lt 2 ] && RND_NUM="2" || { [ "$RND_NUM" -ge 2 ] || RND_NUM="2" ; }
rm -f /tmp/check_timeout/$RND_NUM
eval 'x_curl_check_timeout_network_x "$RND_NUM"' &
i_timeout=1
while [ "$checkA" == "404" ] ;
do
sleep 1
[ -s /tmp/check_timeout/$RND_NUM ] && source /tmp/check_timeout/$RND_NUM
i_timeout=`expr $i_timeout + 1`
if [ "$i_timeout" -gt 10 ] ; then
echo "【check_timeout_network】 网络连接，超时 10 秒！ $check2"
break
fi
done
[ -s /tmp/check_timeout/$RND_NUM ] && source /tmp/check_timeout/$RND_NUM
rm -f /tmp/check_timeout/$RND_NUM
echo "check2=$check2" > /tmp/check_timeout/check
fi

if [ "$check2" == "404" ] ; then 
SEED=`tr -cd 0-9 </dev/urandom | head -c 8`
RND_NUM=`echo $SEED 1 100|awk '{srand($1);printf "%d",rand()*10000%($3-$2)+$2}'`
[ "$RND_NUM" -lt 3 ] && RND_NUM="3" || { [ "$RND_NUM" -ge 3 ] || RND_NUM="3" ; }
rm -f /tmp/check_timeout/$RND_NUM
eval 'x_wget_check_timeout_network_x "$RND_NUM"' &
i_timeout=1
while [ "$checkB" == "404" ] ;
do
sleep 1
[ -s /tmp/check_timeout/$RND_NUM ] && source /tmp/check_timeout/$RND_NUM
i_timeout=`expr $i_timeout + 1`
if [ "$i_timeout" -gt 10 ] ; then
echo "【check_timeout_network】 网络连接，超时 10 秒！ $check2"
break
fi
done
[ -s /tmp/check_timeout/$RND_NUM ] && source /tmp/check_timeout/$RND_NUM
rm -f /tmp/check_timeout/$RND_NUM
rm -f /tmp/check_timeout/check
echo "check2=$check2" > /tmp/check_timeout/check
fi

}

kill_ps () {

local COMMAND="$1"
if [ ! -z "$COMMAND" ] ; then
	eval $(ps -w | grep "$COMMAND" | grep -v $$ | grep -v grep | awk '{print "kill "$1";";}')
	eval $(ps -w | grep "$COMMAND" | grep -v $$ | grep -v grep | awk '{print "kill -9 "$1";";}')
fi
if [ "$2" == "exit0" ] ; then
	exit 0
fi
}

if [ -z "$(cat /sbin/wgetcurl.sh | grep "/tmp/script/wgetcurl.sh")" ] ; then
mkdir -p /tmp/script
cat > "/tmp/script/wgetcurl.sh" <<-\EEE
#!/bin/bash
export PATH='/etc/storage/bin:/tmp/script:/etc/storage/script:/opt/usr/sbin:/opt/usr/bin:/opt/sbin:/opt/bin:/usr/local/sbin:/usr/sbin:/usr/bin:/sbin:/bin'
export LD_LIBRARY_PATH=/lib:/opt/lib
source /etc/storage/script/init.sh
# /etc/storage/script/init.sh echo ln /tmp/script/wgetcurl.sh
output="$1"
url1="$2"
url2="$3"
check_n="$4"
check_lines="$5"

wget_err=""
curl_err=""

[ -z "$url1" ] && return
[ -z "$url2" ] && url2="$url1"
[ -z "$output" ] && return
rm -f "$output"

download_wait () {
	{ sleep $check_time ; [ -f /tmp/wait/check/$check_time ] && eval $(ps -w | grep "max-redirs" | grep "$check_time" | grep -v $$ | grep -v grep | awk '{print "kill "$1";";}') ;  [ -f /tmp/wait/check/$check_time ] && eval $(ps -w | grep "wget\|-T" | grep "$check_time" | grep -v $$ | grep -v grep | awk '{print "kill "$1";";}') ; } &
}

download_k_wait () {
	eval $(ps -w | grep "sleep $check_time" | grep -v $$ | grep -v grep | awk '{print "kill "$1";";}')
}

download_curl () {
	rm -f "$output"
	curl_path=$*
	echo $check_time > /tmp/wait/check/$check_time
	{ check="`$curl_path --max-redirs $check_time --user-agent "$user_agent" -L -s -w "%{http_code}" -o $output`" ; echo "$check" > /tmp/wait/check/$check_time ; } &
	download_k_wait
	download_wait
	check="$(cat /tmp/wait/check/$check_time)"
	while [ "$check" = "$check_time" ];
	do
	sleep 1
	check="$(cat /tmp/wait/check/$check_time)"
	done
	[ "$check" != "200" ] && { curl_err="$check 错误！" ; rm -f "$output" ; }
}

download_wget () {
	rm -f "$output"
	wget_path=$*
	echo $check_time > /tmp/wait/check/$check_time
	{ $wget_path --user-agent "$user_agent" -O $output -T "$check_time" -t 10 ; [ "$?" == "0" ] && check=200 || check=404 ; echo "$check" > /tmp/wait/check/$check_time ; } &
	download_k_wait
	download_wait
	check="$(cat /tmp/wait/check/$check_time)"
	while [ "$check" = "$check_time" ];
	do
	sleep 1
	check="$(cat /tmp/wait/check/$check_time)"
	done
	[ "$check" != "200" ] && { wget_err="$check 错误！" ; rm -f "$output" ; }
}

if [ ! -s "$output" ] ; then
line_path=`dirname $output`
mkdir -p $line_path
if [ "$check_n" != "N" ] ; then
if hash check_disk_size 2>/dev/null ; then
avail=`check_disk_size $line_path`
if [ "$?" == "0" ] ; then
	echo "$avail M 可用容量:【$line_path】" 
else
	avail=0
	logger -t "【下载】" "错误！提取可用容量失败:【$line_path】" 
fi
[ -z "$avail" ] && avail=0
if [ "$avail" != "0" ] ; then
	echo "$avail M 可用容量:【$line_path】" 
fi
length=0
touch /tmp/check_avail_error.txt
if [ -z "$(grep "$url1" /tmp/check_avail_error.txt)" ] ; then
	if [ -z "$(echo "$url1" | grep "^/")" ] ; then
	length_wget=$(wget  -T 5 -t 3 "$url1" -O /dev/null --spider --server-response 2>&1 | grep "[Cc]ontent-[Ll]ength" | grep -Eo '[0-9]+' | tail -n 1)
	else
	length_wget=$(ls -l "$url1" | awk '{print $5}')
	fi
	[ -z "$length_wget" ] && echo "$url1" >> /tmp/check_avail_error.txt
	if [ -z "$length_wget" ] && [ -z "$(grep "$url2" /tmp/check_avail_error.txt)" ] ; then
		if [ -z "$(echo "$url2" | grep "^/")" ] ; then
		length_wget=$(wget  -T 5 -t 3 "$url2" -O /dev/null --spider --server-response 2>&1 | grep "[Cc]ontent-[Ll]ength" | grep -Eo '[0-9]+' | tail -n 1)
		else
		length_wget=$(ls -l "$url2" | awk '{print $5}')
		fi
		[ -z "$length_wget" ] && echo "$url2" >> /tmp/check_avail_error.txt
	fi
	[ ! -z "$length_wget" ] && length=$(echo $length_wget)
fi
[ -z "$length" ] && length=0
if [ "$length" != "0" ] && [ "$avail" != "0" ] ; then
	length=`expr $length + 512000`
	length=`expr $length / 1048576`
	echo "$length M 文件大小:【$url1】"
	if [ "$length" -gt "$avail" ] ; then
		logger -t "【下载】" "错误！剩余空间不足:【文件大小 $length M】>【$avail M 可用容量】"
		logger -t "【下载】" "跳过 下载【 $output 】"
		return 1
	fi
fi
fi
fi
mkdir -p /tmp/wait/check
check_time="1"$(tr -cd 0-9 </dev/urandom | head -c 3)
if [ -z "$(echo "$url1" | grep "^/")" ] ; then
if [ -s "/opt/bin/curl" ] && [ ! -s "$output" ] ; then
	download_curl /opt/bin/curl $url1
fi
if [ -s "/usr/sbin/curl" ] && [ ! -s "$output" ] ; then
	download_curl /usr/sbin/curl --capath /etc/ssl/certs $url1
fi
if [ -s "/opt/bin/wget" ] && [ ! -s "$output" ] ; then
	download_wget /opt/bin/wget $url1
fi
if [ -s "/usr/bin/wget" ] && [ ! -s "$output" ] ; then
	download_wget /usr/bin/wget $url1
fi
else
cp -f "$url1" "$output"
fi
if [ ! -s "$output" ] ; then
	logger -t "【下载】" "下载失败:【$output】 URL:【$url1】"
	logger -t "【下载】" "重新下载:【$output】 URL:【$url2】"
	if [ -z "$(echo "$url2" | grep "^/")" ] ; then
	if [ -s "/opt/bin/curl" ] && [ ! -s "$output" ] ; then
		download_curl /opt/bin/curl $url2
	fi
	if [ -s "/usr/sbin/curl" ] && [ ! -s "$output" ] ; then
		download_curl /usr/sbin/curl --capath /etc/ssl/certs $url2
	fi
	if [ -s "/opt/bin/wget" ] && [ ! -s "$output" ] ; then
		download_wget /opt/bin/wget $url2
	fi
	if [ -s "/usr/bin/wget" ] && [ ! -s "$output" ] ; then
		download_wget /usr/bin/wget $url2
	fi
	else
	cp -f "$url2" "$output"
	fi
fi
download_k_wait
rm -f /tmp/wait/check/$check_time
if [ ! -s "$output" ] ; then
	logger -t "【下载】" "下载失败:【$output】 URL:【$url2】"
	[ ! -z "$curl_err" ] && logger -t "【下载】" "curl_err ：$check错误！"
	[ ! -z "$wget_err" ] && logger -t "【下载】" "wget_err ：$check错误！"
fi
fi
[ -f "$output" ] && chmod 777 "$output"

EEE
chmod 755 "/tmp/script/wgetcurl.sh"
umount /sbin/wgetcurl.sh
mount --bind /tmp/script/wgetcurl.sh /sbin/wgetcurl.sh
fi

wgetcurl_file () {
if [ ! -s "$1" ] ; then
logger -t "【下载】" "找不到 $1 ，重新下载数据，请稍后"
wgetcurl.sh $*
fi
}

wgetcurl_checkmd5 () {
local output="$1"
local url1="$2"
local url2="$3"
local check_n="$4"
local check_lines="$5"
[ -f "$output" ] && rm -f "$output"
mkdir -p $(dirname "$output")
wgetcurl.sh $output $url1 $url2 $check_n $check_lines
if [ -f "$output" ] ; then
	eval $(md5sum $output | awk '{print "MD5_down="$1;}')
	if [ -d /tmp/AiDisk_00 ] ; then
		mkdir -p /tmp/AiDisk_00/tmp/checkmd5/
		rm -rf /tmp/checkmd5/
		ln -sf /tmp/AiDisk_00/tmp/checkmd5 /tmp/checkmd5
	else
		rm -rf /tmp/checkmd5/
		mkdir -p /tmp/checkmd5/
	fi
	checkmd5tmp=$$
	wgetcurl.sh /tmp/checkmd5/$checkmd5tmp $url1 $url2 $check_n $check_lines
	eval $(md5sum /tmp/checkmd5/$checkmd5tmp | awk '{print "MD5_txt="$1;}')
	rm -f /tmp/checkmd5/$checkmd5tmp
	echo $MD5_down;echo $MD5_txt;
	if [ "$MD5_txt"x = "$MD5_down"x ] ; then
		logger -t "【下载】" "下载【$output】成功，2次下载md5匹配！【$url1】"
	else
		logger -t "【下载】" "下载【$output】错误，2次下载md5不匹配！【$url1】"
		logger -t "【下载】" "删除【$output】文件，麻烦看看哪里问题！"
		rm -f $output
	fi
fi
}

sstp_conf='/etc/storage/app_27.sh'
sstp_set() {
	sstp_set_a="$(echo "$1" | awk -F '=' '{print $1}')"
	sstp_set_b="$(echo "$1" | awk -F '=' '{for(i=2;i<=NF;++i) { if(i==2){sum=$i}else{sum=sum"="$i}}}END{print sum}')"
	(
		flock 527
		if [ ! -z "$(grep -Eo $sstp_set_a=.\+\(\ #\) $sstp_conf)" ] ; then
		sed -e "s@^$sstp_set_a=.\+\(\ #\)@$sstp_set_a='$sstp_set_b' #@g" -i $sstp_conf
		else
		sed -e "s@^$sstp_set_a=.\+@$sstp_set_a='$sstp_set_b' #@g" -i $sstp_conf
		fi
		if [ -z "$(cat $sstp_conf | grep "$sstp_set_a=""'""$sstp_set_b""'"" #")" ] ; then
		echo "$sstp_set_a=""'""$sstp_set_b""'"" #" >> $sstp_conf
		fi
	) 527>/var/lock/sstp_set.lock
}

sstp_get() {
	[ ! -z "$1" ] && eval echo `cat "$sstp_conf" | grep "$1" | awk -F '=' '{for(i=2;i<=NF;++i) { if(i==2){sum=$i}else{sum=sum"="$i}}}END{print sum}'`
}

check_webui_yes () {

if [ ! -f /tmp/webui_yes ] ; then
	logger -t "【webui】" "由于没找到【/tmp/webui_yes】文件，稍等后启动相关设置，如等候时间过长可尝试【重启】或【双清路由】"
	exit 0
fi
}

cut_B_re () {
B_restart="$(echo ${B_restart:0:3}${B_restart:29:3})"
}

ip6_neighbor_get () {
a_ip6=/tmp/ip6_neighbor.tmp
b_ip6=/tmp/ip6_neighbor.log
c_ip6=/tmp/ip6_ifconfig.tmp
touch $a_ip6 $b_ip6 $c_ip6
# 根据网络接口 ip6 提取前2段匹配的 ip6
ifconfig | grep inet6 | grep -E "Global|Link" | grep -v FAILED > $c_ip6
echo "$(awk -F ' ' '\
NR==FNR{\
  split($3, arrtmp, ":");\
  atmp=arrtmp[1]":"arrtmp[2];\
  a[atmp]++;\
}\
NR>FNR{\
  split($0, arrtmp, ":");\
  atmp=arrtmp[1]":"arrtmp[2];\
  if(atmp in a) {\
    print $0;\
  }\
}' $c_ip6 $b_ip6)" > $b_ip6
# [a =>> b] 合并更新 MAC ip6
# 提取 b 文件旧的 MAC ip6
# 合并 a 文件新的 MAC ip6
# 得到 b 文件 MAC 更新的 ip6
ip -f inet6 neighbor show | grep -v FAILED | grep -v INCOMPLETE | grep -v router | grep br0 > $a_ip6
echo "$(awk -F ' ' '\
NR==FNR{\
  split($0, arrtmp, ":");\
  atmp=arrtmp[1]":"arrtmp[2]$5;\
  a[atmp]++;\
}\
NR>FNR{\
  split($0, arrtmp, ":");\
  atmp=arrtmp[1]":"arrtmp[2]$5;\
  if(!(atmp in a)) {\
    print $0;\
  }\
}' $a_ip6 $b_ip6)" > $b_ip6
echo "$(cat $a_ip6)" >> $b_ip6
sed -e '/^$/d' -i $b_ip6

tmp_ip6=/tmp/static_ip.tmp
d_ip6=/tmp/static_ip.inf
e_ip6=/tmp/static_ip6.inf
touch $tmp_ip6 $d_ip6 $e_ip6
cat $d_ip6 | tr '[A-Z]' '[a-z]' | tr ',' ' ' > $tmp_ip6
# 提取 IPv6 广播中继: WAN to LAN 的二级路由客户端
echo "$(awk -F ' ' '\
NR==FNR{\
  atmp=$2;\
  atmp=tolower(atmp);\
  a[atmp]++\
}\
NR>FNR{\
  atmp=$5;\
  if(!(atmp in a)) {\
    print $5;\
  }\
}' $tmp_ip6 $a_ip6)" > $e_ip6
# 数据去重
awk '!a[$0]++' $e_ip6 > $tmp_ip6
sed -e '/^$/d' -i $tmp_ip6
# 构建 MAC 数据
echo "$(awk '{\
  if($0) {\
    a=$0;\
    a=toupper(a);\
    print "----,"a",*,1,0,0";\
  }\
}' $tmp_ip6)" > $e_ip6
sed -e '/^$/d' -i $e_ip6
echo -n "$(cat $e_ip6 | grep "," | wc -l)" > /tmp/static_ip6.num

}

# 查询域名地址
# 参数: 待查询域名
arNslookup() {
name_domain="$(echo "$1" | sed "s/\@\.//g")"
name_domain="$(echo "$name_domain" | sed "s/\*\./""$(tr -cd 0-9 </dev/urandom | head -c 8)""\./g")"
mkdir -p /tmp/arNslookup
rm -f /tmp/arNslookup/$$
curltest=`which curl`
if [ -z "$curltest" ] || [ ! -s "`which curl`" ] ; then
	Address="$(wget -T 5 -t 3 --user-agent "$user_agent" --quiet --output-document=- --header 'accept: application/dns-json' 'https://1.0.0.2/dns-query?name='"$name_domain"'&type=A')"
	if [ $? -eq 0 ] ; then
	echo "$Address" | grep -Eo "data\":\"[^\"]+" | sed "s/data\":\"//g" | sed -n '1p' | grep -E -o '([0-9]+\.){3}[0-9]+' | grep -v '^$' > /tmp/arNslookup/$$
	fi
	if [ ! -s /tmp/arNslookup/$$ ] ; then
	Address="$(wget -T 5 -t 3 --user-agent "$user_agent" --quiet --output-document=- 'http://119.29.29.29/d?dn='"$name_domain"'&type=A')"
	if [ $? -eq 0 ] ; then
	echo "$Address" |  sed s/\;/"\n"/g | sed -n '1p' | grep -E -o '([0-9]+\.){3}[0-9]+' | grep -v '^$' > /tmp/arNslookup/$$
	fi
	fi
else
	Address="$(curl --user-agent "$user_agent" -s -H 'accept: application/dns-json' 'https://1.0.0.2/dns-query?name='"$name_domain"'&type=A')"
	if [ $? -eq 0 ] ; then
	echo "$Address" | grep -Eo "data\":\"[^\"]+" | sed "s/data\":\"//g" | sed -n '1p' | grep -E -o '([0-9]+\.){3}[0-9]+' | grep -v '^$' > /tmp/arNslookup/$$
	fi
	if [ ! -s /tmp/arNslookup/$$ ] ; then
	Address="$(curl --user-agent "$user_agent" -s 'http://119.29.29.29/d?dn='"$name_domain"'&type=A')"
	if [ $? -eq 0 ] ; then
	echo "$Address" |  sed s/\;/"\n"/g | sed -n '1p' | grep -E -o '([0-9]+\.){3}[0-9]+' | grep -v '^$' > /tmp/arNslookup/$$
	fi
	fi
fi

if [ -s /tmp/arNslookup/$$ ] ; then
cat /tmp/arNslookup/$$ | sort -u | grep -v '^$'
else
[ ! -z "$2" ] && dns_lookup_server="$2" || dns_lookup_server="1.0.0.2"
nslookup "$name_domain" "$dns_lookup_server" | tail -n +3 | grep "Address" | awk '{print $3}'| grep -v ":" | sed -n '1p' > /tmp/arNslookup/$$ &
dns_lookup_I=5
while [ ! -s /tmp/arNslookup/$$ ] ; do
		dns_lookup_I=$(($dns_lookup_I - 1))
		[ $dns_lookup_I -lt 0 ] && break
		sleep 1
done
killall nslookup &>/dev/null
if [ -s /tmp/arNslookup/$$ ] ; then
cat /tmp/arNslookup/$$ | sort -u | grep -v '^$'
fi
fi
rm -f /tmp/arNslookup/$$
}

arNslookup6() {
name_domain="$(echo "$1" | sed "s/\@\.//g")"
name_domain="$(echo "$name_domain" | sed "s/\*\./""$(tr -cd 0-9 </dev/urandom | head -c 8)""\./g")"
mkdir -p /tmp/arNslookup
rm -f /tmp/arNslookup/$$
curltest=`which curl`
if [ -z "$curltest" ] || [ ! -s "`which curl`" ] ; then
	Address="$(wget -T 5 -t 3 --user-agent "$user_agent" --quiet --output-document=- --header 'accept: application/dns-json' 'https://1.0.0.2/dns-query?name='"$name_domain"'&type=AAAA')"
	if [ $? -eq 0 ] ; then
	echo "$Address" | grep -Eo "data\":\"[^\"]+" | sed "s/data\":\"//g" | sed -n '1p' | grep  ':' | grep -v '^$' > /tmp/arNslookup/$$
	fi
	if [ ! -s /tmp/arNslookup/$$ ] ; then
	Address="$(wget -T 5 -t 3 --user-agent "$user_agent" --quiet --output-document=- --header 'accept: application/dns-json' 'https://9.9.9.9:5053/dns-query?name='"$name_domain"'&type=AAAA')"
	if [ $? -eq 0 ] ; then
	echo "$Address" | grep -Eo "data\":\"[^\"]+" | sed "s/data\":\"//g" | sed -n '1p' | grep  ':' | grep -v '^$' > /tmp/arNslookup/$$
	fi
	fi
else
	Address="$(curl --user-agent "$user_agent" -s -H 'accept: application/dns-json' 'https://1.0.0.2/dns-query?name='"$name_domain"'&type=AAAA')"
	if [ $? -eq 0 ] ; then
	echo "$Address" | grep -Eo "data\":\"[^\"]+" | sed "s/data\":\"//g" | sed -n '1p' | grep  ':' | grep -v '^$' > /tmp/arNslookup/$$
	fi
	if [ ! -s /tmp/arNslookup/$$ ] ; then
	Address="$(curl --user-agent "$user_agent" -s -H 'accept: application/dns-json' 'https://9.9.9.9:5053/dns-query?name='"$name_domain"'&type=AAAA')"
	if [ $? -eq 0 ] ; then
	echo "$Address" | grep -Eo "data\":\"[^\"]+" | sed "s/data\":\"//g" | sed -n '1p' | grep  ':' | grep -v '^$' > /tmp/arNslookup/$$
	fi
	fi
fi
if [ -s /tmp/arNslookup/$$ ] ; then
	cat /tmp/arNslookup/$$ | sort -u | grep -v '^$'
else
[ ! -z "$2" ] && dns_lookup_server="$2" || dns_lookup_server="1.0.0.2"
nslookup "$name_domain" "$dns_lookup_server" | tail -n +3 | grep "Address" | awk '{print $3}'| grep ":" | sed -n '1p' > /tmp/arNslookup/$$ &
dns_lookup_I=5
while [ ! -s /tmp/arNslookup/$$ ] ; do
		dns_lookup_I=$(($dns_lookup_I - 1))
		[ $dns_lookup_I -lt 0 ] && break
		sleep 1
done
killall nslookup &>/dev/null
if [ -s /tmp/arNslookup/$$ ] ; then
	cat /tmp/arNslookup/$$ | sort -u | grep -v '^$'
fi
fi
rm -f /tmp/arNslookup/$$
}

restart_on_dhcpd() {
local dhcpdpid
dhcpdpid="$(cat /tmp/syslog.log | grep -Eo "dnsmasq\[[0-9]+\]: started" | grep -Eo "[0-9]+" | awk '{print "\\\["$1"\\\]";}'  | tr -d "\n" | sed -e "s#\]\\\#\]|\\\#g")"
[ -n "$dhcpdpid" ] && eval "sed \"/""$dhcpdpid""/d\" -Ei /tmp/syslog.log ; restart_dhcpd"
[ -z "$dhcpdpid" ] && eval "restart_dhcpd"
}

initopt () {
optPath=`grep ' /opt ' /proc/mounts | grep tmpfs`
[ ! -z "$optPath" ] && return
if [ ! -z "$(echo $scriptfilepath | grep -v "/opt/etc/init")" ] && [ -s "/opt/etc/init.d/rc.func" ] ; then
	{ echo '#!/bin/bash' ; echo $scriptfilepath '"$@"' '&' ; } > /opt/etc/init.d/$scriptname && chmod 777  /opt/etc/init.d/$scriptname
fi
}

i_app_get_status () {
local NAME="" VALA="" VALB=""
for i in "$@"; do
  case $i in
    -name=*)
      NAME="${i#*=}"
      shift
      ;;
    -valb=*)
      VALB="${i#*=}"
      shift
      ;;
    *)
      ;;
  esac
done
VALA="$(nvram get ${NAME}_status)"
VALB="$(echo -n "$VALB" | md5sum | sed s/[[:space:]]//g | sed s/-//g)"
VALB="$(echo ${VALB:0:3}${VALB:29:3})"
if [ "$VALA" != "$VALB" ] ; then
	nvram set ${NAME}_status="$VALB"
	needed_restart=1
else
	needed_restart=0
fi
}

i_app_get_cmd_file () {
local NAME="" CMDNAME="" CPATH="" D1PATH="" D2PATH="" RUNH="" MOPT="" TYPE1=""
for i in "$@"; do
  case $i in
    -name=*)
      NAME="${i#*=}"
      shift
      ;;
    -cmd=*)
      CMDNAME="${i#*=}"
      shift
      ;;
    -cpath=*)
      CPATH="${i#*=}"
      shift
      ;;
    -down1=*)
      D1PATH="${i#*=}"
      shift
      ;;
    -down2=*)
      D2PATH="${i#*=}"
      shift
      ;;
    -runh=*)
      RUNH="${i#*=}"
      shift
      ;;
    -mopt=*)
      MOPT="${i#*=}"
      shift
      ;;
    -notrestart)
      TYPE1="notrestart"
      shift
      ;;
    *)
      ;;
  esac
done
[ -z "${RUNH}" ] && RUNH="-h"
[ -z "${MOPT}" ] && MOPT="start"
[ -f "${CMDNAME}" ] && chmod 777 "${CMDNAME}"
SVC_PATH="$(which ${CMDNAME})"
[ ! -s "${SVC_PATH}" ] && SVC_PATH="${CPATH}"
if [ ! -s "${SVC_PATH}" ] ; then
	logger -t "【${NAME}】" "找不到 ${CMDNAME}，安装 opt 程序"
	/etc/storage/script/Sh01_mountopt.sh ${MOPT}
	initopt
	[ -f "${CMDNAME}" ] && chmod 777 "${CMDNAME}"
	SVC_PATH="$(which ${CMDNAME})"
	[ ! -s "${SVC_PATH}" ] && SVC_PATH="${CPATH}"
fi
mkdir -p "$(dirname $SVC_PATH)"
wgetcurl_file "${SVC_PATH}" "${D1PATH}" "${D2PATH}"
chmod 777 "${SVC_PATH}"
[ "${RUNH}" != "x" ] && [[ "$(${SVC_PATH} ${RUNH} 2>&1 | wc -l)" -lt 2 ]] && rm -rf ${SVC_PATH}
if [ ! -s "${SVC_PATH}" ] && [ "$TYPE1" != "notrestart" ] ; then
	logger -t "【${NAME}】" "找不到 ${SVC_PATH} ，需要手动安装 ${SVC_PATH}"
	logger -t "【${NAME}】" "启动失败, 10 秒后自动尝试重新启动" && sleep 10 && eval "${NAME}_restart x"
fi
}

i_app_keep () {
local NAME="" PIDNAME="" PSNAME="" CPATH="" TYPE1=""
for i in "$@"; do
  case $i in
    -name=*)
      NAME="${i#*=}"
      shift
      ;;
    -pidof=*)
      PIDNAME="${i#*=}"
      shift
      ;;
    -ps=*)
      PSNAME="${i#*=}"
      shift
      ;;
    -cpath=*)
      CPATH="${i#*=}"
      shift
      ;;
    -t)
      TYPE1="test"
      shift
      ;;
    *)
      ;;
  esac
done
local TMPSCRIPT="/tmp/script/_opt_script_check"
local COMMAND=""
COMMAND="[ -z \"\`pidof ${PIDNAME}\`\" ]"
[ -z "${CPATH}" ] && CPATH="$(which ${PIDNAME})"
[ ! -z "${CPATH}" ] && COMMAND="${COMMAND} || ""[ ! -s \"${CPATH}\" ]"
[ ! -z "${PSNAME}" ] && COMMAND="${COMMAND} || ""[ \"\$(grep \"${PSNAME}\" /tmp/ps | grep -v grep |wc -l)\" -lt \"1\" ]"
if [ "$TYPE1" = "test" ] ; then
ps -w > /tmp/ps
if $COMMAND; then
	logger -t "【${NAME}】" "${PIDNAME} 启动失败, 注意检查端口是否有冲突,程序是否下载完整,10 秒后自动尝试重新启动" && sleep 10 && eval "${NAME}_restart x"
else
	logger -t "【${NAME}】" "${PIDNAME} 启动成功" && eval "${NAME}_restart o"
fi
[ ! -z "$(ps -w | grep "$(pidof ${PIDNAME})" | grep /opt/)" ] && initopt
return 0
fi
logger -t "【${NAME}】" "${PIDNAME} 守护进程启动"
if [ -s "$TMPSCRIPT" ] ; then
ps -w > /tmp/ps
sed -Ei '/【'"${NAME}"'】|^$/d' "$TMPSCRIPT"
cat >> "$TMPSCRIPT" <<-OSC
if $COMMAND; then # 【${NAME}】
 nvram set ${NAME}_status=00 && logger -t "【${NAME}】" "${PIDNAME} 重新启动！" && eval "$scriptfilepath &" && sed -Ei '/【${NAME}】|^$/d' ${TMPSCRIPT} # 【${NAME}】
fi # 【${NAME}】
OSC
return 0
else
while true; do
	if [ -z "$(pidof ${PIDNAME})" ] ; then
		nvram set ${NAME}_status=00
		logger -t "【${NAME}】" "${PIDNAME} 重新启动！！"
		eval "$scriptfilepath &"
		exit 0
	fi
sleep 123
done
fi
}

i_app_restart () {
local NAME="" TYPE1=""
for i in "$@"; do
  case $i in
    -name=*)
      NAME="${i#*=}"
      shift
      ;;
    o)
      TYPE1="o"
      shift
      ;;
    x)
      TYPE1="x"
      shift
      ;;
    *)
      ;;
  esac
done
relock="/var/lock/${NAME}_restart.lock"
if [ "$TYPE1" = "o" ] ; then
	nvram set ${NAME}_renum="0"
	[ -f $relock ] && rm -f $relock
	return 0
fi
if [ "$TYPE1" = "x" ] ; then
	if [ -f $relock ] ; then
		logger -t "【${NAME}】" "多次尝试启动失败，等待【"`cat $relock`"分钟】后自动尝试重新启动"
		exit 0
	fi
	eval "${NAME}_renum=\${${NAME}_renum:-\"0\"}"
	eval ${NAME}_renum=`eval "expr \$""${NAME}_renum + 1"`
	eval "nvram set ${NAME}_renum=\"\$""${NAME}_renum\""
	if [ "$(eval "echo \"$""${NAME}_renum\"")" -gt "3" ] ; then
		I=19
		echo $I > $relock
		logger -t "【${NAME}】" "多次尝试启动失败，等待【"`cat $relock`"分钟】后自动尝试重新启动"
		while [ $I -gt 0 ]; do
			I=$(($I - 1))
			echo $I > $relock
			sleep 60
			[ "$(nvram get ${NAME}_renum)" = "0" ] && exit 0
			[ $I -lt 0 ] && break
		done
		nvram set ${NAME}_renum="1"
	fi
	[ -f $relock ] && rm -f $relock
fi
nvram set ${NAME}_status=0
eval "$scriptfilepath &"
exit 0
}

