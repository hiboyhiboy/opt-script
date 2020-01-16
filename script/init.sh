#!/bin/sh
#copyright by hiboy
export PATH='/etc/storage/bin:/tmp/script:/etc/storage/script:/opt/usr/sbin:/opt/usr/bin:/opt/sbin:/opt/bin:/usr/local/sbin:/usr/sbin:/usr/bin:/sbin:/bin'
export LD_LIBRARY_PATH=/lib:/opt/lib
init_ver=2
#set -x
#hiboyfile="https://bitbucket.org/hiboyhiboy/opt-file/raw/master"
#hiboyscript="https://bitbucket.org/hiboyhiboy/opt-script/raw/master"
hiboyfile="https://opt.cn2qq.com/opt-file"
hiboyscript="https://opt.cn2qq.com/opt-script"
hiboyfile2="https://raw.githubusercontent.com/hiboyhiboy/opt-file/master"
hiboyscript2="https://raw.githubusercontent.com/hiboyhiboy/opt-script/master"
# --user-agent
user_agent='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/78.0.3904.108 Safari/537.36'
ACTION=$1
scriptfilepath=$(cd "$(dirname "$0")"; pwd)/$(basename $0)
#echo $scriptfilepath
scriptpath=$(cd "$(dirname "$0")"; pwd)
#echo $scriptpath
scriptname=$(basename $0)
#echo $scriptname
cmd_log2=' 2>&1 | awk '"'"'{cmd="logger -t '"'"'"'"'"'"'"'"'【'"'"'$cmd_name'"'"'】'"'"'"'"'"' '"'"' "'"'"'"$0"'"'"'"'"'"' "'"'"';";system(cmd)}'"'" 
chmod 755 /etc/storage/*.sh
ulimit -HSn 65536

x_check_timeout_network_x()
{
[ -z "$(which check_network)" ] && return
check_tmp="/tmp/check_timeout/$1"
[ "$2" == "1" ] && ss_link_3="3" 
[ "$2" == "2" ] && ss_link_3="0"
check_network "$ss_link_3"
if [ "$?" != "0" ] ; then
	check_network "$ss_link_3"
	[ "$?" == "0" ] && echo "check$2=200" >> $check_tmp || echo "check$2=404" >> $check_tmp
else
	echo "check$2=200" >> $check_tmp
fi
re_txt=`expr $2 + 2`
echo "check$re_txt=200" >> $check_tmp
sleep 8
rm -f $check_tmp
}

x_wget_check_timeout_network_x()
{
[ -z "$(which wget)" ] && return
check_tmp="/tmp/check_timeout/$1"
[ "$2" == "1" ] && ss_link_3="$ss_link_1" 
[ "$2" == "2" ] && ss_link_3="$ss_link_2"
wget --user-agent "$user_agent" -q  -T 3 -t 1 "$ss_link_3" -O /dev/null
if [ "$?" != "0" ] ; then
	wget --user-agent "$user_agent" -q  -T 3 -t 2 "$ss_link_3" -O /dev/null
	[ "$?" == "0" ] && echo "check$2=200" >> $check_tmp || echo "check$2=404" >> $check_tmp
else
	echo "check$2=200" >> $check_tmp
fi
re_txt=`expr $2 + 2`
echo "check$re_txt=200" >> $check_tmp
sleep 8
rm -f $check_tmp
}

x_curl_check_timeout_network_x()
{
[ -z "$(which curl)" ] && return
check_tmp="/tmp/check_timeout/$1"
[ "$2" == "2" ] && ss_link_3="$ss_link_2"
sleep 1
[ "$2" == "1" ] && ss_link_3="$ss_link_1" 
check_code="$(curl -L --connect-timeout 3 --user-agent "$user_agent" -s -w "%{http_code}" "$ss_link_3" -o /dev/null)"
if [ "$check_code" != "200" ] ; then
	check_code="$(curl -L --connect-timeout 3 --user-agent "$user_agent" -s -w "%{http_code}" "$ss_link_3" -o /dev/null)"
	[ "$check_code" == "200" ] && echo "check$2=200" >> $check_tmp || echo "check$2=404" >> $check_tmp
else
	echo "check$2=200" >> $check_tmp
fi
re_txt=`expr $2 + 2`
echo "check$re_txt=200" >> $check_tmp
sleep 8
rm -f $check_tmp
}

check_timeout_network()
{
mkdir -p /tmp/check_timeout
[ "$2" == "check" ] && rm -f /tmp/check_timeout/check
[ ! -f /tmp/check_timeout/ver_time ] && echo -n "0" > /tmp/check_timeout/ver_time
if [ $(($(date "+%y%m%d%H%M") - $(cat /tmp/check_timeout/ver_time))) -ge 1 ] || [ ! -s /tmp/check_timeout/check ] ; then
	echo "check_timeout_network 开始新的检测"
	echo -n "$(date "+%y%m%d%H%M")" > /tmp/check_timeout/ver_time
else
	echo "check_timeout_network 间隔少于1分钟直接返回上次检测值"
	[ -s /tmp/check_timeout/check ] && source /tmp/check_timeout/check
	return
fi
check1="404"
check2="404"
check3="404"
check4="404"
if [ "$1" != "wget_check" ] ; then
SEED=`tr -cd 0-9 </dev/urandom | head -c 8`
RND_NUM=`echo $SEED 1 100|awk '{srand($1);printf "%d",rand()*10000%($3-$2)+$2}'`
[ "$RND_NUM" -lt 1 ] && RND_NUM="1" || { [ "$RND_NUM" -gt 1 ] || RND_NUM="1" ; }
rm -f /tmp/check_timeout/$RND_NUM
eval 'x_check_timeout_network_x "$RND_NUM" "2"' &
sleep 1
eval 'x_check_timeout_network_x "$RND_NUM" "1"' &
i_timeout=1
while [ "$check3" == "404" ] || [ "$check4" == "404" ] ;
do
sleep 1
[ -s /tmp/check_timeout/$RND_NUM ] && source /tmp/check_timeout/$RND_NUM
i_timeout=`expr $i_timeout + 1`
if [ "$i_timeout" -gt 10 ] ; then
#logger -t "【check_timeout_network】" "网络连接，超时 10 秒！ $check1 $check2"
echo "【check_timeout_network】 网络连接，超时 10 秒！ $check1 $check2"
break
fi
done
[ -s /tmp/check_timeout/$RND_NUM ] && source /tmp/check_timeout/$RND_NUM
rm -f /tmp/check_timeout/$RND_NUM
fi

if [ ! -z "$(which curl)" ] ; then 
if [ "$check1" == "404" ] || [ "$check2" == "404" ] ; then 
SEED=`tr -cd 0-9 </dev/urandom | head -c 8`
RND_NUM=`echo $SEED 1 100|awk '{srand($1);printf "%d",rand()*10000%($3-$2)+$2}'`
[ "$RND_NUM" -lt 1 ] && RND_NUM="1" || { [ "$RND_NUM" -gt 1 ] || RND_NUM="1" ; }
rm -f /tmp/check_timeout/$RND_NUM
check1="404"
check2="404"
check3="404"
check4="404"
eval 'x_curl_check_timeout_network_x "$RND_NUM" "2"' &
sleep 1
eval 'x_curl_check_timeout_network_x "$RND_NUM" "1"' &
i_timeout=1
while [ "$check3" == "404" ] || [ "$check4" == "404" ] ;
do
sleep 1
[ -s /tmp/check_timeout/$RND_NUM ] && source /tmp/check_timeout/$RND_NUM
i_timeout=`expr $i_timeout + 1`
if [ "$i_timeout" -gt 10 ] ; then
#logger -t "【check_timeout_network】" "网络连接，超时 10 秒！ $check1 $check2"
echo "【check_timeout_network】 网络连接，超时 10 秒！ $check1 $check2"
break
fi
done
[ -s /tmp/check_timeout/$RND_NUM ] && source /tmp/check_timeout/$RND_NUM
rm -f /tmp/check_timeout/$RND_NUM
fi
fi

if [ "$check1" == "404" ] || [ "$check2" == "404" ] ; then 
SEED=`tr -cd 0-9 </dev/urandom | head -c 8`
RND_NUM=`echo $SEED 1 100|awk '{srand($1);printf "%d",rand()*10000%($3-$2)+$2}'`
[ "$RND_NUM" -lt 1 ] && RND_NUM="1" || { [ "$RND_NUM" -gt 1 ] || RND_NUM="1" ; }
rm -f /tmp/check_timeout/$RND_NUM
check1="404"
check2="404"
check3="404"
check4="404"
eval 'x_wget_check_timeout_network_x "$RND_NUM" "1"' &
eval 'x_wget_check_timeout_network_x "$RND_NUM" "2"' &
i_timeout=1
while [ "$check3" == "404" ] || [ "$check4" == "404" ] ;
do
sleep 1
[ -s /tmp/check_timeout/$RND_NUM ] && source /tmp/check_timeout/$RND_NUM
i_timeout=`expr $i_timeout + 1`
if [ "$i_timeout" -gt 10 ] ; then
#logger -t "【check_timeout_network】" "网络连接，超时 10 秒！ $check1 $check2"
echo "【check_timeout_network】 网络连接，超时 10 秒！ $check1 $check2"
break
fi
done
[ -s /tmp/check_timeout/$RND_NUM ] && source /tmp/check_timeout/$RND_NUM
rm -f /tmp/check_timeout/$RND_NUM
rm -f /tmp/check_timeout/check
echo "check1=$check1" > /tmp/check_timeout/check
echo "check2=$check2" >> /tmp/check_timeout/check
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
wgetcurl.sh $output $url1 $url2 $check_n $check_lines
if [ -f "$output" ] ; then
	eval $(md5sum $output | awk '{print "MD5_down="$1;}')
	mkdir -p /tmp/checkmd5/
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

