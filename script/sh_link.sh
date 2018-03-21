#!/bin/sh
#copyright by hiboy
source /etc/storage/script/init.sh

add_ss_link () {
link="$1"
ss_link_methodpassword=$(echo -n $link | sed -n '1p' | sed -e "s/_/\//g" | sed -e "s/-/\+/g" | sed 's/$/&==/g' | base64 -d  | awk -F '@' '{print $1}')
ss_link_usage=$(echo -n $link | sed -n '1p' | sed -e "s/_/\//g" | sed -e "s/-/\+/g" | sed 's/$/&==/g' | base64 -d  | awk -F '@' '{print $2}')

ss_link_name="#"$(echo -n "$ss_link_usage" | cut -d ':' -f1)
ss_link_server=$(echo -n "$ss_link_usage" | cut -d ':' -f1)
ss_link_port=`echo -n "$ss_link_usage" | cut -d ':' -f2 `
ss_link_password=$(echo -n "$ss_link_methodpassword"  | cut -d ':' -f2 )
ss_link_method=`echo -n "$ss_link_methodpassword" | cut -d ':' -f1 `

}

add_ssr_link () {
link="$1"
ex_params="$(echo -n $link | sed -n '1p' | awk -F '/\\?' '{print $2}')"
ex_obfsparam="$(echo "$ex_params" | grep -Eo "obfsparam=[^&]*"  | cut -d '=' -f2 | sed -e "s/_/\//g" | sed -e "s/\-/\+/g" | sed 's/$/&==/g' | base64 -d )";
ex_protoparam="$(echo "$ex_params" | grep -Eo "protoparam=[^&]*"  | cut -d '=' -f2 | sed -e "s/_/\//g" | sed -e "s/\-/\+/g" | sed 's/$/&==/g' | base64 -d )";
ex_remarks="$(echo "$ex_params" | grep -Eo "remarks[^&]*"  | cut -d '=' -f2 | sed -e "s/_/\//g" | sed -e "s/\-/\+/g" | sed 's/$/&==/g' | base64 -d )";
ex_group="$(echo "$ex_params" | grep -Eo "group[^&]*"  | cut -d '=' -f2 | sed -e "s/_/\//g" | sed -e "s/\-/\+/g" | sed 's/$/&==/g' | base64 -d )";

[ ! -z "$ex_remarks" ] && ss_link_name="$(echo "$ex_remarks" | sed -e ":a;N;s/\n/_/g;ta" )"
ss_link_usage="$(echo -n $link | sed -n '1p' | awk -F '/\\?' '{print $1}')"
[ -z "$ex_remarks" ] && ss_link_name="#""`echo -n "$ss_link_usage" | cut -d ':' -f1 `"

ss_link_server=`echo -n "$ss_link_usage" | cut -d ':' -f1 `
ss_link_port=`echo -n "$ss_link_usage" | cut -d ':' -f2 `
ss_link_password=$(echo -n "$ss_link_usage"  | cut -d ':' -f6 | sed -e "s/_/\//g" | sed -e "s/\-/\+/g" | sed 's/$/&==/g' | base64 -d)
ss_link_method=`echo -n "$ss_link_usage" | cut -d ':' -f4 `
ss_link_obfs=`echo -n "$ss_link_usage" | cut -d ':' -f5 ` # -o
ss_link_protocol=`echo -n "$ss_link_usage" | cut -d ':' -f3 ` # -O
[ ! -z "$ex_obfsparam" ] && ss_link_obfsparam=" -g $ex_obfsparam" # -g
[ ! -z "$ex_protoparam" ] && ss_link_protoparam=" -G $ex_protoparam" # -G

}

add_0 () {
ss_link_name=""
ss_link_server=""
ss_link_port=""
ss_link_password=""
ss_link_method=""
ss_link_obfs=""
ss_link_protocol=""
ss_link_obfsparam=""
ss_link_protoparam=""
}


rt_ssnum_x_tmp="`nvram get rt_ssnum_x_tmp`"
[ -z "$rt_ssnum_x_tmp" ] && rt_ssnum_x_tmp="" && nvram set rt_ssnum_x_tmp=""
if [ "$rt_ssnum_x_tmp"x = "del"x ] ; then
	nvram set rt_ssnum_x=0
	nvram set rt_ssnum_x_tmp=0
	nvram commit
	return
fi


ssr_link="`nvram get ssr_link`"
[ -z "$ssr_link" ] && ssr_link="" && nvram set ssr_link=""
A_restart=`nvram get ss_link_status`
B_restart="$ssr_link"
B_restart=`echo -n "$B_restart" | md5sum | sed s/[[:space:]]//g | sed s/-//g`
if [ "$A_restart" != "$B_restart" ] ; then
	nvram set ss_link_status=$B_restart
	if [ -z "$ssr_link" ] ; then
		cru.sh d ss_link_update
		logger -t "【SS】" "停止 SSR 服务器订阅"
		return
	else
		cru.sh a ss_link_update "12 */3 * * * $scriptfilepath uplink &" &
		logger -t "【SS】" "启动 SSR 服务器订阅: $ssr_link"
	fi
fi
if [ -z "$ssr_link" ] ; then
	return
fi
mkdir -p /tmp/ss/link
wgetcurl.sh /tmp/ss/link/0_link.txt "$ssr_link" "$ssr_link" N
if [ ! -s /tmp/ss/link/0_link.txt ] ; then
	rm -f /tmp/ss/link/0_link.txt
	wget --no-check-certificate --user-agent 'Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/53.0.2785.104 Safari/537.36 Core/1.53.3427.400 QQBrowser/9.6.12088.400' -O /tmp/ss/link/0_link.txt "$ssr_link"
fi
if [ ! -s /tmp/ss/link/0_link.txt ] ; then
	logger -t "【SS】" "错误！！SSR 服务器订阅文件下载失败！请检查服务器配置"
fi
sed -e '/^$/d' -i /tmp/ss/link/0_link.txt
sed -e 's/$/&==/g' -i /tmp/ss/link/0_link.txt
sed -e "s/_/\//g" -i /tmp/ss/link/0_link.txt
sed -e "s/\-/\+/g" -i /tmp/ss/link/0_link.txt
cat /tmp/ss/link/0_link.txt | grep -Eo [^A-Za-z0-9+/=]+ | tr -d "\n" > /tmp/ss/link/3_link.txt
if [ -s /tmp/ss/link/3_link.txt ] ; then
	logger -t "【SS】" "警告！！SSR 服务器订阅文件下载包含非 BASE64 编码字符！"
	logger -t "【SS】" "请检查服务器配置和链接："
	logger -t "【SS】" "$ssr_link"
fi
cat /tmp/ss/link/0_link.txt | grep -Eo [A-Za-z0-9+/=]+ | tr -d "\n" > /tmp/ss/link/1_link.txt
base64 -d /tmp/ss/link/1_link.txt > /tmp/ss/link/2_link.txt
sed -e '/^$/d' -i /tmp/ss/link/2_link.txt
sed -e 's/$/&==/g' -i /tmp/ss/link/2_link.txt
sed -e "s/_/\//g" -i /tmp/ss/link/2_link.txt
sed -e "s/\-/\+/g" -i /tmp/ss/link/2_link.txt
echo >> /tmp/ss/link/2_link.txt
rm -f /tmp/ss/link/ssr_link.txt  /tmp/ss/link/ss_link.txt
while read line
do
ssr_line=`echo -n $line | sed -n '1p' | grep 'ssr://'`
if [ ! -z "$ssr_line" ] ; then
	echo  "$ssr_line" | awk -F 'ssr://' '{print $2}' >> /tmp/ss/link/ssr_link.txt

fi
ss_line=`echo -n $line | sed -n '1p' |grep 'ss://'`
if [ ! -z "$ss_line" ] ; then
	echo  "$ss_line" | awk -F 'ss://' '{print $2}' >> /tmp/ss/link/ss_link.txt
fi
done < /tmp/ss/link/2_link.txt

#echo > /tmp/ss/link/c_link.txt
i=0
if [ -f /tmp/ss/link/ssr_link.txt ] ; then
	awk  'BEGIN{FS="\n";}  {cmd=sprintf("echo -n %s|base64 -d", $1);  system(cmd); print "";}' /tmp/ss/link/ssr_link.txt > /tmp/ss/link/ssr_link2.txt
	while read line
	do
	if [ ! -z "$line" ] && [ ! -z /tmp/ss/link/ssr_link2.txt ] ; then
		add_0
		add_ssr_link "$line"
		#echo  $ss_link_name $ss_link_server $ss_link_port $ss_link_password $ss_link_method $ss_link_obfs $ss_link_protocol >> /tmp/ss/link/c_link.txt
		eval "nvram set rt_ss_name_x$i=\"$ss_link_name\""
		eval "nvram set rt_ss_port_x$i=$ss_link_port"
		eval "nvram set rt_ss_password_x$i=\"$ss_link_password\""
		eval "nvram set rt_ss_server_x$i=$ss_link_server"
		eval "nvram set rt_ss_usage_x$i=\"-o $ss_link_obfs -O $ss_link_protocol $ss_link_obfsparam $ss_link_protoparam\""
		eval "nvram set rt_ss_method_x$i=$ss_link_method"
		i=$(( i + 1 ))
	fi
	done < /tmp/ss/link/ssr_link2.txt
fi

if [ -f /tmp/ss/link/ss_link.txt ] ; then
	awk  'BEGIN{FS="\n";}  {cmd=sprintf("echo -n %s|base64 -d", $1);  system(cmd); print "";}' /tmp/ss/link/ss_link.txt > /tmp/ss/link/ss_link2.txt
	while read line
	do
	if [ ! -z "$line" ] && [ ! -z /tmp/ss/link/ss_link2.txt ] ; then
		add_0
		add_ss_link "$line"
		#echo  $ss_link_name $ss_link_server $ss_link_port $ss_link_password $ss_link_method $ss_link_obfs $ss_link_protocol >> /tmp/ss/link/c_link.txt
		eval "nvram set rt_ss_name_x$i=\"$ss_link_name\""
		eval "nvram set rt_ss_port_x$i=$ss_link_port"
		eval "nvram set rt_ss_password_x$i=\"$ss_link_password\""
		eval "nvram set rt_ss_server_x$i=$ss_link_server"
		eval "nvram set rt_ss_method_x$i=$ss_link_method"
		i=$(( i + 1 ))
	fi
	done < /tmp/ss/link/ss_link2.txt
fi

rt_ssnum_x=`nvram get rt_ssnum_x`
[ -z $rt_ssnum_x ] && rt_ssnum_x=0 && nvram set rt_ssnum_x=0
[ $rt_ssnum_x -lt $i ] && nvram set rt_ssnum_x=$i
rm -rf /tmp/ss/link
nvram commit

