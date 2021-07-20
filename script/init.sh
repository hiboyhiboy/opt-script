#!/bin/bash
#copyright by hiboy
export PATH='/etc/storage/bin:/tmp/script:/etc/storage/script:/opt/usr/sbin:/opt/usr/bin:/opt/sbin:/opt/bin:/usr/local/sbin:/usr/sbin:/usr/bin:/sbin:/bin'
export LD_LIBRARY_PATH=/lib:/opt/lib
init_ver=2
#set -x
#hiboyfile="https://bitbucket.org/hiboyhiboy/opt-file/raw/master"
#hiboyscript="https://bitbucket.org/hiboyhiboy/opt-script/raw/master"
#hiboyfile2="https://cdn.jsdelivr.net/gh/HiboyHiboy/opt-file"
#hiboyscript2="https://cdn.jsdelivr.net/gh/HiboyHiboy/opt-script"
hiboyfile="https://opt.cn2qq.com/opt-file"
hiboyscript="https://opt.cn2qq.com/opt-script"
hiboyfile2="https://raw.githubusercontent.com/hiboyhiboy/opt-file/master"
hiboyscript2="https://raw.githubusercontent.com/hiboyhiboy/opt-script/master"
# --user-agent
user_agent='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
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
	wget --user-agent "$user_agent" -q  -T 3 -t 2 "http://www.google.com/" -O /dev/null --spider --server-response
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
	check_code="$(curl -L --connect-timeout 3 --user-agent "$user_agent" -s -w "%{http_code}" "http://www.google.com/" -o /dev/null -I)"
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
new_time=$(date "+%y%m%d%H%M")
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

COMMAND="$1"
if [ ! -z "$COMMAND" ] ; then
	eval $(ps -w | grep "$COMMAND" | grep -v $$ | grep -v grep | awk '{print "kill "$1";";}')
	eval $(ps -w | grep "$COMMAND" | grep -v $$ | grep -v grep | awk '{print "kill -9 "$1";";}')
fi
if [ "$2" == "exit0" ] ; then
	exit 0
fi
}

wgetcurl_file () {
output="$1"
url1="$2"
url2="$3"
check_n="$4"
check_lines="$5"
if [ ! -s "$output" ] ; then
	logger -t "【file】" "找不到 $output ，重新下载数据，请稍后"
	wgetcurl.sh $output $url1 $url2 $check_n $check_lines
	logger -t "【file】" "下载完成 $output"
fi
[ -f "$output" ] && chmod 777 "$output"
}

wgetcurl_checkmd5 () {
output="$1"
url1="$2"
url2="$3"
check_n="$4"
check_lines="$5"
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

check_webui_yes () {

if [ ! -f /tmp/webui_yes ] ; then
	logger -t "【webui】" "由于没找到【/tmp/webui_yes】文件，稍等后启动相关设置，如等候时间过长可尝试【重启】或【双清路由】"
	exit 0
fi
}

cut_B_re () {
B_restart="$(echo ${B_restart:0-5})"
}

cut_C_re () {
C_restart="$(echo ${C_restart:0-5})"
}


