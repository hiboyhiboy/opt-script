#!/bin/sh
#copyright by hiboy
export PATH='/etc/storage/bin:/tmp/script:/etc/storage/script:/opt/usr/sbin:/opt/usr/bin:/opt/sbin:/opt/bin:/usr/local/sbin:/usr/sbin:/usr/bin:/sbin:/bin'
export LD_LIBRARY_PATH=/lib:/opt/lib
#set -x
#hiboyfile="https://bitbucket.org/hiboyhiboy/opt-file/raw/master"
#hiboyscript="https://bitbucket.org/hiboyhiboy/opt-script/raw/master"
hiboyfile="https://opt.cn2qq.com/opt-file"
hiboyscript="https://opt.cn2qq.com/opt-script"
hiboyfile2="https://raw.githubusercontent.com/hiboyhiboy/opt-file/master"
hiboyscript2="https://raw.githubusercontent.com/hiboyhiboy/opt-script/master"
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


wgetcurl_checkmd5 () {
output="$1"
url1="$2"
url2="$3"
check_n="$4"
check_lines="$5"
wgetcurl.sh $output $url1 $url2 $check_n $check_lines
if [ -s "$output" ] ; then
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
