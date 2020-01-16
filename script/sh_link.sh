#!/bin/sh
#copyright by hiboy
source /etc/storage/script/init.sh

# 🔐📐|📐🔐
if [ -z "$( grep "🔐📐" /www/link_d.js )" ] ; then
name_base64=0
else
name_base64=1
fi

base64encode () {
# 转码
if [ "$name_base64" == 0 ] ; then
echo -n "$1"
else
# 转换base64
echo -n "🔐📐$(echo -n "$1" | sed ":a;N;s/\n//g;ta" | base64 | sed -e "s/\//_/g" | sed -e "s/\+/-/g" | sed 's/&==//g' | sed ":a;N;s/\n//g;ta")📐🔐"
fi
}

get_emoji () {

if [ "$name_base64" == 0 ] ; then
echo -n "$1" \
 | sed -e 's@#@♯@g' \
 | sed -e 's@\r@_@g' \
 | sed -e 's@\n@_@g' \
 | sed -e 's@,@，@g' \
 | sed -e 's@+@➕@g' \
 | sed -e 's@=@＝@g' \
 | sed -e 's@|@丨@g' \
 | sed -e "s@%@％@g" \
 | sed -e "s@\^@∧@g" \
 | sed -e 's@/@／@g' \
 | sed -e 's@\\@＼@g' \
 | sed -e "s@<@《@g" \
 | sed -e "s@>@》@g" \
 | sed -e 's@;@；@g' \
 | sed -e 's@`@▪️@g' \
 | sed -e 's@:@：@g' \
 | sed -e 's@!@❗️@g' \
 | sed -e 's@*@﹡@g' \
 | sed -e 's@?@❓@g' \
 | sed -e 's@\$@💲@g' \
 | sed -e 's@(@（@g' \
 | sed -e 's@)@）@g' \
 | sed -e 's@{@『@g' \
 | sed -e 's@}@』@g' \
 | sed -e 's@\[@【@g' \
 | sed -e 's@\]@】@g' \
 | sed -e 's@&@﹠@g' \
 | sed -e "s@'@▫️@g" \
 | sed -e 's@"@”@g'
 
# | sed -e 's@ @_@g'
else
echo -n "$1"
fi
}

add_ss_link () {
link="$1"
if [ ! -z "$(echo -n "$link" | grep '#')" ] ; then
ss_link_name_url=$(echo -n $link | awk -F '#' '{print $2}')
ss_link_name="$(get_emoji "$(printf $(echo -n $ss_link_name_url | sed 's/\\/\\\\/g;s/\(%\)\([0-9a-fA-F][0-9a-fA-F]\)/\\x\2/g'))"| sed -n '1p')"
link=$(echo -n $link | awk -F '#' '{print $1}')
fi
if [ ! -z "$(echo -n "$link" | grep '@')" ] ; then
	#不将主机名和端口号解析为Base64URL ss://cmM0LW1kNTpwYXNzd2Q=@192.168.100.1:8888/?plugin=obfs-local%3Bobfs%3Dhttp#Example2
	link3=$(echo -n $link | sed -n '1p' | awk -F '@' '{print $1}' | sed -e "s/_/\//g" | sed -e "s/-/\+/g" | sed 's/$/&==/g' | base64 -d )
	link4=$(echo -n $link | sed -n '1p' | awk -F '@' '{print $2}')
	link2="$link3""@""$link4"
else
	#部分信息解析为Base64URL ss://cmM0LW1kNTpwYXNzd2RAMTkyLjE2OC4xMDAuMTo4ODg4Lz9wbHVnaW49b2Jmcy1sb2NhbCUzQm9iZnMlM0RodHRw==#Example2
	link2=$(echo -n $link | sed -n '1p' | sed -e "s/_/\//g" | sed -e "s/-/\+/g" | sed 's/$/&==/g' | base64 -d)
	
fi
ex_params="$(echo -n $link2 | sed -n '1p' | awk -F '/\\?' '{print $2}')"
if [ ! -z "$ex_params" ] ; then
	#存在插件
	ex_obfsparam="$(echo -n "$ex_params" | grep -Eo "plugin=[^&]*"  | cut -d '=' -f2)";
	ex_obfsparam=$(printf $(echo -n $ex_obfsparam | sed 's/\\/\\\\/g;s/\(%\)\([0-9a-fA-F][0-9a-fA-F]\)/\\x\2/g'))
	ss_link_plugin_opts=" -O origin -o plain --plugin ""$(echo -n "$ex_obfsparam" |  sed -e 's@;@ --plugin-opts @')"
	link2="$(echo -n $link2 | sed -n '1p' | awk -F '/\\?' '{print $1}')"
else
	ss_link_plugin_opts=" -O origin -o plain "
fi

ss_link_methodpassword=$(echo -n $link2 | sed -n '1p' | awk -F '@' '{print $1}')
ss_link_usage=$(echo -n $link2 | sed -n '1p' | awk -F '@' '{print $2}')

[ -z "$ss_link_name" ] && ss_link_name="♯"$(echo -n "$ss_link_usage" | cut -d ':' -f1)
ss_link_name="$(echo "$ss_link_name"| sed -n '1p')"
ss_link_server=$(echo -n "$ss_link_usage" | cut -d ':' -f1)
ss_link_port=`echo -n "$ss_link_usage" | cut -d ':' -f2 `
ss_link_password=$(echo -n "$ss_link_methodpassword"  | cut -d ':' -f2 )
ss_link_method=`echo -n "$ss_link_methodpassword" | cut -d ':' -f1 `

}

add_ssr_link () {
link="$1"
ex_params="$(echo -n $link | sed -n '1p' | awk -F '/\\?' '{print $2}')"
ex_obfsparam="$(echo -n "$ex_params" | grep -Eo "obfsparam=[^&]*"  | cut -d '=' -f2 | sed -e "s/_/\//g" | sed -e "s/\-/\+/g" | sed 's/$/&==/g' | base64 -d )"
ex_protoparam="$(echo -n "$ex_params" | grep -Eo "protoparam=[^&]*"  | cut -d '=' -f2 | sed -e "s/_/\//g" | sed -e "s/\-/\+/g" | sed 's/$/&==/g' | base64 -d )"
ex_remarks="$(echo -n "$ex_params" | grep -Eo "remarks[^&]*"  | cut -d '=' -f2 | sed -e "s/_/\//g" | sed -e "s/\-/\+/g" | sed 's/$/&==/g' | base64 -d )"
#ex_group="$(echo -n "$ex_params" | grep -Eo "group[^&]*"  | cut -d '=' -f2 | sed -e "s/_/\//g" | sed -e "s/\-/\+/g" | sed 's/$/&==/g' | base64 -d )"

[ ! -z "$ex_remarks" ] && ss_link_name="$(get_emoji "$(echo -n "$ex_remarks" | sed -e ":a;N;s/\n/_/g;ta" )")"
ss_link_usage="$(echo -n $link | sed -n '1p' | awk -F '/\\?' '{print $1}')"
[ -z "$ex_remarks" ] && ss_link_name="♯""`echo -n "$ss_link_usage" | cut -d ':' -f1 `"
ss_link_name="$(echo "$ss_link_name"| sed -n '1p')"

ss_link_server=`echo -n "$ss_link_usage" | cut -d ':' -f1 `
ss_link_port=`echo -n "$ss_link_usage" | cut -d ':' -f2 `
ss_link_password=$(echo -n "$ss_link_usage"  | cut -d ':' -f6 | sed -e "s/_/\//g" | sed -e "s/\-/\+/g" | sed 's/$/&==/g' | base64 -d)
ss_link_method=`echo -n "$ss_link_usage" | cut -d ':' -f4 `
ss_link_obfs=`echo -n "$ss_link_usage" | cut -d ':' -f5 ` # -o
if [ "$ss_link_obfs"x = "tls1.2_ticket_fastauth"x ] ; then
	ss_link_obfs="tls1.2_ticket_auth"
fi
ss_link_protocol="$(echo -n "$ss_link_usage" | cut -d ':' -f3)" # -O
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
ss_link_plugin_opts=""
}

clear_link () {

logger -t "【SS】" "服务器订阅：清空上次订阅节点配置"
# 自定义节点配置靠前保存
mkdir -p /tmp/ss/link
ss_x=`nvram get rt_ssnum_x`
ss_x=$(( ss_x - 1 ))
# 导出节点配置
ss_s=/tmp/ss/link/daochu_1.txt
echo -n "" > $ss_s
for ss_1i in $(seq 0 $ss_x)
do
    echo rt_ss_name_x$ss_1i=$(nvram get rt_ss_name_x$ss_1i) >> $ss_s
    echo rt_ss_port_x$ss_1i=$(nvram get rt_ss_port_x$ss_1i) >> $ss_s
    echo rt_ss_password_x$ss_1i=$(nvram get rt_ss_password_x$ss_1i) >> $ss_s
    echo rt_ss_server_x$ss_1i=$(nvram get rt_ss_server_x$ss_1i) >> $ss_s
    echo rt_ss_usage_x$ss_1i=$(nvram get rt_ss_usage_x$ss_1i) >> $ss_s
    echo rt_ss_method_x$ss_1i=$(nvram get rt_ss_method_x$ss_1i) >> $ss_s
done
# 删除🔗订阅连接
cat /tmp/ss/link/daochu_1.txt | sort -u | grep -v "^$" > /tmp/ss/link/daochu_2.txt
grep "🔗" /tmp/ss/link/daochu_2.txt | cut -d '=' -f1 | awk -F '_x' '{print $2}' | sort -u > /tmp/ss/link/daochu_3.txt
if [ ! -s /tmp/ss/link/daochu_3.txt ] ; then
    echo "不含订阅连接"
    rm -rf /tmp/ss/link
    return
fi
while read line
do
    sed -Ei "/rt_ss_name_x$line=|rt_ss_port_x$line=|rt_ss_password_x$line=|rt_ss_server_x$line=|rt_ss_usage_x$line=|rt_ss_method_x$line=/d" /tmp/ss/link/daochu_2.txt
done < /tmp/ss/link/daochu_3.txt
# 重排序
ss_s=/tmp/ss/link/daochu_2.txt
for ss_1i in $(seq 0 $ss_x)
do
    for ss_2ii in $(seq $ss_1i $ss_x)
    do
        ss_3iii=0
        if [ ! -z "$(grep "rt_ss_name_x$ss_2ii=" $ss_s)" ] ; then
            sed -Ei s/rt_ss_name_x$ss_2ii=/rt_ss_name_x$ss_1i=/g $ss_s
            sed -Ei s/rt_ss_port_x$ss_2ii=/rt_ss_port_x$ss_1i=/g $ss_s
            sed -Ei s/rt_ss_password_x$ss_2ii=/rt_ss_password_x$ss_1i=/g $ss_s
            sed -Ei s/rt_ss_server_x$ss_2ii=/rt_ss_server_x$ss_1i=/g $ss_s
            sed -Ei s/rt_ss_usage_x$ss_2ii=/rt_ss_usage_x$ss_1i=/g $ss_s
            sed -Ei s/rt_ss_method_x$ss_2ii=/rt_ss_method_x$ss_1i=/g $ss_s
            ss_3iii=1
        fi
        if [ "$ss_3iii"x == "1x" ] ; then
            break
        fi
    done
done
# 提取运行命令
while read line
do
    ss_a="$(echo $line  | grep -Eo  'rt_ss_.*=' | awk -F '=' '{print $1}')"
    ss_b="$(echo $line | awk -F $ss_a'=' '{print $2}' )"
    eval "nvram set $ss_a=\"\$ss_b\""
done < /tmp/ss/link/daochu_2.txt
# 保存有效节点数量
rt_ssnum_x=$(grep rt_ss_name_x /tmp/ss/link/daochu_2.txt | wc -l)
[ -z $rt_ssnum_x ] && rt_ssnum_x="0"
nvram set rt_ssnum_x=$rt_ssnum_x
# 写入空白记录 nvram unset 
ss_x=`nvram get rt_ssnum_x`
ss_x=$(( ss_x - 1 ))
# 导出节点配置
nvram showall | grep '=' | grep rt_ss_ | sed 's/^/nvram unset /' | sort -u > /tmp/ss/link/daochu_1.txt
# 删除非订阅连接
cat /tmp/ss/link/daochu_1.txt | sort -u | grep -v "^$" > /tmp/ss/link/daochu_2.txt
seq 0 $ss_x | awk '{print "_x"$0"="}' > /tmp/ss/link/daochu_3.txt
while read line
do
    sed -Ei "/rt_ss_name$line|rt_ss_port$line|rt_ss_password$line|rt_ss_server$line|rt_ss_usage$line|rt_ss_method$line/d" /tmp/ss/link/daochu_2.txt
done < /tmp/ss/link/daochu_3.txt
#sed -Ei "/$(cat /tmp/ss/link/daochu_3.txt | sed ":a;N;s/\n/|/g;ta")/d" /tmp/ss/link/daochu_2.txt
# 提取运行命令
cat /tmp/ss/link/daochu_2.txt | sort -u | awk -F '=' '{print $1}' > /tmp/ss/link/daochu_4.txt
[ -s /tmp/ss/link/daochu_4.txt ] && source /tmp/ss/link/daochu_4.txt
rm -rf /tmp/ss/link
}

do_link () {
if [ -z  "$(echo "$ssr_link_i" | grep 'http:\/\/')""$(echo "$ssr_link_i" | grep 'https:\/\/')" ]  ; then
	logger -t "【SS】" "$ssr_link_i"
	logger -t "【SS】" "错误！！SSR 服务器订阅文件下载地址不含http(s)://！请检查下载地址"
	return
fi
mkdir -p /tmp/ss/link
#logger -t "【SS】" "订阅文件下载: $ssr_link_i"
rm -f /tmp/ss/link/0_link.txt
wgetcurl.sh /tmp/ss/link/0_link.txt "$ssr_link_i" "$ssr_link_i" N
if [ ! -s /tmp/ss/link/0_link.txt ] ; then
	rm -f /tmp/ss/link/0_link.txt
	wget -T 5 -t 3 --user-agent "$user_agent" -O /tmp/ss/link/0_link.txt "$ssr_link_i"
fi
if [ ! -s /tmp/ss/link/0_link.txt ] ; then
	rm -f /tmp/ss/link/0_link.txt
	curl -L --user-agent "$user_agent" -o /tmp/ss/link/0_link.txt "$ssr_link_i"
fi
if [ ! -s /tmp/ss/link/0_link.txt ] ; then
	logger -t "【SS】" "$ssr_link_i"
	logger -t "【SS】" "错误！！SSR 服务器订阅文件下载失败！请检查下载地址"
	return
fi
dos2unix /tmp/ss/link/0_link.txt
sed -e 's@\r@@g' -i /tmp/ss/link/0_link.txt
sed -e '/^$/d' -i /tmp/ss/link/0_link.txt
sed -e 's/$/&==/g' -i /tmp/ss/link/0_link.txt
sed -e "s/_/\//g" -i /tmp/ss/link/0_link.txt
sed -e "s/\-/\+/g" -i /tmp/ss/link/0_link.txt
cat /tmp/ss/link/0_link.txt | grep -Eo [^A-Za-z0-9+/=]+ | tr -d "\n" > /tmp/ss/link/3_link.txt
if [ -s /tmp/ss/link/3_link.txt ] ; then
	logger -t "【SS】" "警告！！SSR 服务器订阅文件下载包含非 BASE64 编码字符！"
	logger -t "【SS】" "请检查服务器配置和链接："
	logger -t "【SS】" "$ssr_link_i"
	return
fi
# 开始解码订阅节点配置
cat /tmp/ss/link/0_link.txt | grep -Eo [A-Za-z0-9+/=]+ | tr -d "\n" > /tmp/ss/link/1_link.txt
base64 -d /tmp/ss/link/1_link.txt > /tmp/ss/link/2_link.txt
dos2unix /tmp/ss/link/2_link.txt
sed -e 's@\r@@g' -i /tmp/ss/link/2_link.txt
sed -e  's@vmess://@\nvmess:://@g' -i /tmp/ss/link/2_link.txt
sed -e  's@ssr://@\nssr://@g' -i /tmp/ss/link/2_link.txt
sed -e  's@ss://@\nss://@g' -i /tmp/ss/link/2_link.txt
sed -e  's@vmess:://@vmess://@g' -i /tmp/ss/link/2_link.txt
sed -e '/^$/d' -i /tmp/ss/link/2_link.txt
echo >> /tmp/ss/link/2_link.txt
rm -f /tmp/ss/link/ssr_link.txt  /tmp/ss/link/ss_link.txt
while read line
do
ssr_line=`echo -n $line | sed -n '1p' | grep 'ssr://'`
if [ ! -z "$ssr_line" ] ; then
	echo  "$ssr_line" | awk -F 'ssr://' '{print $2}' >> /tmp/ss/link/ssr_link.txt
fi
ss_line=`echo -n $line | sed -n '1p' |grep '^ss://'`
if [ ! -z "$ss_line" ] ; then
	echo  "$ss_line" | awk -F 'ss://' '{print $2}' >> /tmp/ss/link/ss_link.txt
fi
done < /tmp/ss/link/2_link.txt

#echo > /tmp/ss/link/c_link.txt

do_i=`nvram get rt_ssnum_x`
if [ -f /tmp/ss/link/ssr_link.txt ] ; then
	sed -e 's/$/&==/g' -i /tmp/ss/link/ssr_link.txt
	sed -e "s/_/\//g" -i /tmp/ss/link/ssr_link.txt
	sed -e "s/\-/\+/g" -i /tmp/ss/link/ssr_link.txt
	awk  'BEGIN{FS="\n";}  {cmd=sprintf("echo -n %s|base64 -d", $1);  system(cmd); print "";}' /tmp/ss/link/ssr_link.txt > /tmp/ss/link/ssr_link2.txt
	while read line
	do
	if [ ! -z "$line" ] ; then
		add_0
		add_ssr_link "$line"
		#echo  $ss_link_name $ss_link_server $ss_link_port $ss_link_password $ss_link_method $ss_link_obfs $ss_link_protocol >> /tmp/ss/link/c_link.txt
		if [ ! -f /www/link/link.js ] ; then
			eval "nvram set rt_ss_name_x$do_i=\"🔗$ss_link_name\""
			eval "nvram set rt_ss_port_x$do_i=$ss_link_port"
			eval "nvram set rt_ss_password_x$do_i=\"$ss_link_password\""
			eval "nvram set rt_ss_server_x$do_i=$ss_link_server"
			eval "nvram set rt_ss_usage_x$do_i=\"-o $ss_link_obfs -O $ss_link_protocol $ss_link_obfsparam $ss_link_protoparam\""
			eval "nvram set rt_ss_method_x$do_i=$ss_link_method"
			do_i=$(( do_i + 1 ))
		else
			link_echo=""
			link_echo="$link_echo"'["🔗'"$(base64encode "$ss_link_name")"'", '
			link_echo="$link_echo"'"'"$ss_link_server"'", '
			link_echo="$link_echo"'"'"$ss_link_port"'", '
			link_echo="$link_echo"'"'"$(base64encode "$ss_link_password")"'", '
			link_echo="$link_echo"'"'"$ss_link_method"'", '
			link_echo="$link_echo"'"", '
			link_echo="$link_echo"'"", '
			#link_echo="$link_echo"'"-o '"$ss_link_obfs"' -O '"$ss_link_protocol $ss_link_obfsparam $ss_link_protoparam"'", '
			link_echo="$link_echo"'"'"$(base64encode "-o $ss_link_obfs -O $ss_link_protocol $ss_link_obfsparam $ss_link_protoparam")"'", '
			#SS:-o plain -O origin  
			if [ "$ss_link_obfs" == "plain" ] && [ "$ss_link_protocol" == "origin" ] ; then
			link_echo="$link_echo"'"ss"], '
			else
			link_echo="$link_echo"'"ssr"], '
			fi
			echo "$link_echo" >> /www/link/link.js
			sed -Ei '/\[\]\]|dellink_ss|^$/d' /www/link/link.js
			echo '[]]' >> /www/link/link.js
		fi
	fi
	done < /tmp/ss/link/ssr_link2.txt
fi

if [ -f /tmp/ss/link/ss_link.txt ] ; then
	#awk  'BEGIN{FS="\n";}  {cmd=sprintf("echo -n %s|base64 -d", $1);  system(cmd); print "";}' /tmp/ss/link/ss_link.txt > /tmp/ss/link/ss_link2.txt
	while read line
	do
	if [ ! -z "$line" ] ; then
		add_0
		add_ss_link "$line"
		#echo  $ss_link_name $ss_link_server $ss_link_port $ss_link_password $ss_link_method $ss_link_obfs $ss_link_protocol >> /tmp/ss/link/c_link.txt
		if [ ! -f /www/link/link.js ] ; then
			eval "nvram set rt_ss_name_x$do_i=\"🔗$ss_link_name\""
			eval "nvram set rt_ss_port_x$do_i=$ss_link_port"
			eval "nvram set rt_ss_password_x$do_i=\"$ss_link_password\""
			eval "nvram set rt_ss_server_x$do_i=$ss_link_server"
			eval "nvram set rt_ss_method_x$do_i=$ss_link_method"
			eval "nvram set rt_ss_usage_x$do_i=\"$ss_link_plugin_opts\""
			do_i=$(( do_i + 1 ))
		else
			link_echo=""
			link_echo="$link_echo"'["'"🔗$(base64encode "$ss_link_name")"'", '
			link_echo="$link_echo"'"'"$ss_link_server"'", '
			link_echo="$link_echo"'"'"$ss_link_port"'", '
			link_echo="$link_echo"'"'"$(base64encode "$ss_link_password")"'", '
			link_echo="$link_echo"'"'"$ss_link_method"'", '
			link_echo="$link_echo"'"", '
			link_echo="$link_echo"'"", '
			link_echo="$link_echo"'"'"$(base64encode "$ss_link_plugin_opts")"'", '
			link_echo="$link_echo"'"ss"], '
			echo "$link_echo" >> /www/link/link.js
			sed -Ei '/\[\]\]|dellink_ss|^$/d' /www/link/link.js
			echo '[]]' >> /www/link/link.js
		fi
	fi
	done < /tmp/ss/link/ss_link.txt
fi
[ -f /www/link/link.js ] && { sed -Ei '/\[\]\]|^$/d' /www/link/link.js ; echo -n '[]]' >> /www/link/link.js ; }
if [ ! -f /www/link/link.js ] ; then
# 保存有效节点数量
rt_ssnum_x=`nvram get rt_ssnum_x`
[ -z $rt_ssnum_x ] && rt_ssnum_x=0 && nvram set rt_ssnum_x=0
[ $rt_ssnum_x -lt $do_i ] && nvram set rt_ssnum_x=$do_i
nvram commit
fi
rm -rf /tmp/ss/link
}

start_link () {

rt_ssnum_x=$(nvram get rt_ssnum_x)
[ -z $rt_ssnum_x ] && rt_ssnum_x="0"
[ $rt_ssnum_x -lt 0 ] && rt_ssnum_x="0" || { [ $rt_ssnum_x -gt 0 ] || rt_ssnum_x="0" ; }
nvram set rt_ssnum_x=$rt_ssnum_x

rt_ssnum_x_tmp="`nvram get rt_ssnum_x_tmp`"
if [ "$rt_ssnum_x_tmp" = "clean" ] ; then
	shlinksh=$$
	eval $(ps -w | grep "sh_link.sh" | grep -v grep | grep -v "$shlinksh" | awk '{print "kill -9 "$1";";}')
	rm -f /www/link/link.js
	echo "var ACL2List = [[], " > /www/link/link.js
	echo '["🔗显示测试，请重新更新订阅", "192.168.123.1", "8888", "passwd", "aes-128-gcm", "btn-success", "11 ms", " -O origin -o plain ", "ss"],' >> /www/link/link.js
	echo '[]]' >> /www/link/link.js
	nvram set rt_ssnum_x_tmp=0
	nvram commit
	logger -t "【SS】" "完成重置订阅文件，请重新更新订阅"
	rm -f /tmp/link_matching/link_matching.txt
	exit
fi

rt_ssnum_x_tmp="`nvram get rt_ssnum_x_tmp`"
if [ "$rt_ssnum_x_tmp" = "del" ] ; then
	shlinksh=$$
	eval $(ps -w | grep "sh_link.sh" | grep -v grep | grep -v "$shlinksh" | awk '{print "kill -9 "$1";";}')
	#echo -n '' > /www/link/link.js
	sed -Ei '/🔗|dellink_ss|^$/d' /www/link/link.js
	clear_link
	nvram set rt_ssnum_x_tmp=0
	nvram commit
	logger -t "【SS】" "完成清空上次订阅节点配置 请按【F5】刷新 web 查看"
	rm -f /tmp/link_matching/link_matching.txt
	exit
fi

ssr_link="`nvram get ssr_link`"
ss_link_up=`nvram get ss_link_up`
ss_link_ping=`nvram get ss_link_ping`
app_99="$(nvram get app_99)"
if [ "$app_99" == 1 ] ; then
	ss_link_ping=0
	nvram set ss_link_ping=0
fi
A_restart="$(nvram get ss_link_status)"
#B_restart="$ssr_link"
B_restart=`echo -n "$ssr_link" | md5sum | sed s/[[:space:]]//g | sed s/-//g`
if [ "$A_restart" != "$B_restart" ] ; then
nvram set ss_link_status=$B_restart
	if [ -z "$ssr_link" ] ; then
		cru.sh d ss_link_update
		logger -t "【SS】" "停止 SS 服务器订阅"
		return
	else
		if [ "$ss_link_up" != 1 ] ; then
			cru.sh a ss_link_update "12 */6 * * * $scriptfilepath uplink &" &
			logger -t "【SS】" "启动 SS 服务器订阅，添加计划任务 (Crontab)，每6小时更新"
		else
			cru.sh d ss_link_update
		fi
	fi
fi
if [ -z "$ssr_link" ] ; then
	return
fi
shlinksh=$$
eval $(ps -w | grep "sh_link.sh" | grep -v grep | grep -v "$shlinksh" | awk '{print "kill -9 "$1";";}')

if [ ! -f /www/link/link.js ] ; then
	# 清空上次订阅节点配置
	clear_link
else
	logger -t "【SS】" "服务器订阅：开始更新"
fi
ssr_link="$(echo "$ssr_link" | tr , \  | sed 's@  @ @g' | sed 's@  @ @g' | sed 's@^ @@g' | sed 's@ $@@g' )"
ssr_link_i=""
if [ -f /www/link/link.js ]  ; then
[ ! -s /www/link/link.js ] &&  { rm -f /www/link/link.js ; echo "var ACL2List = [[], " > /www/link/link.js ; echo '[]]' >> /www/link/link.js ; }
[ "$(sed -n 1p /www/link/link.js)" != "var ACL2List = [[], " ] && { rm -f /www/link/link.js ; echo "var ACL2List = [[], " > /www/link/link.js ; echo '[]]' >> /www/link/link.js ; }
sed -Ei '/🔗|dellink_ss|^$/d' /www/link/link.js
rm -f /tmp/link_matching/link_matching.txt
fi
if [ ! -z "$(echo "$ssr_link" | awk -F ' ' '{print $2}')" ] ; then
	for ssr_link_ii in $ssr_link
	do
		ssr_link_i="$ssr_link_ii"
		do_link
	done
else
	ssr_link_i="$ssr_link"
	do_link
fi
if [ -f /www/link/link.js ]  ; then
sed -Ei '/\[\]\]|dellink_ss|^$/d' /www/link/link.js
echo '[]]' >> /www/link/link.js
fi
logger -t "【SS】" "服务器订阅：更新完成"
if [ "$ss_link_ping" != 1 ] ; then
	/etc/storage/script/sh_ezscript.sh allping
else
	echo "🔗$ss_link_name：停止ping订阅节点"
fi

}

check_link () {
mkdir -p /etc/storage/link
touch /etc/storage/link/link.js
if [ -f /www/link/link.js ] && [ ! -s /www/link/link.js ] ; then
# 使用 /etc/storage/link 保存订阅节点
logger -t "【SS】" "服务器订阅：由原来 NVRAM 保存节点配置，转为使用 /etc/storage/link 保存订阅节点"
# 清空上次订阅节点配置
clear_link
nvram commit
fi
# 初始化 /etc/storage/link/link.js
if [ -f /www/link/link.js ] && [ ! -s /www/link/link.js ] ; then
	rm -f /www/link/link.js
	echo "var ACL2List = [[], " > /www/link/link.js
	echo '[]]' >> /www/link/link.js
fi
if [ -f /www/link/link.js ] && [ "$(sed -n 1p /www/link/link.js)" != "var ACL2List = [[], " ] ; then
	rm -f /www/link/link.js
	echo "var ACL2List = [[], " > /www/link/link.js
	echo '[]]' >> /www/link/link.js
fi
}

addlink_ss () {


rt_ss_name_x_0="$(base64encode "$(nvram get rt_ss_name_x_0)")"
rt_ss_server_x_0="$(nvram get rt_ss_server_x_0)"
rt_ss_port_x_0="$(nvram get rt_ss_port_x_0)"
rt_ss_password_x_0="$(base64encode "$(nvram get rt_ss_password_x_0)")"
rt_ss_method_x_0="$(nvram get rt_ss_method_x_0)"
rt_ss_usage_x_0="$(base64encode "$(nvram get rt_ss_usage_x_0)")"
ss_type_x_0="$(nvram get ss_type_x_0)"


[ ! -s /www/link/link.js ] && { rm -f /www/link/link.js ; echo "var ACL2List = [[], " > /www/link/link.js ; }
sed -Ei '/\[\]\]|dellink_ss|^$/d' /www/link/link.js
echo '["'"$rt_ss_name_x_0"'", "'"$rt_ss_server_x_0"'", "'"$rt_ss_port_x_0"'", "'"$rt_ss_password_x_0"'", "'"$rt_ss_method_x_0"'", "", "", "'"$rt_ss_usage_x_0"'", "'"$ss_type_x_0"'"], ' >> /www/link/link.js
echo '[]]' >> /www/link/link.js
}

dellink_ss () {

shift
shift
while [ $# != 0 ]
do
del_x="$1"
del_x="$(echo "$del_x" | tr -d '_' | tr -d ' ')"
[ "$del_x" -lt 1 ] && del_x="0" || { [ "$del_x" -gt 0 ] || del_x="0" ; }
if [ "$del_x" -gt 1 ] ; then
	if [ -z "$(sed -n "$del_x"p /www/link/link.js | grep "\[\"🔗")" ] ; then
		sed -i "$del_x""c dellink_ss" /www/link/link.js
	else
		sed -i "$del_x"'{N;s/🔗//}' /www/link/link.js
	fi
fi
shift
done
sed -Ei '/\[\]\]|dellink_ss|^$/d' /www/link/link.js
echo '[]]' >> /www/link/link.js
}

case $ACTION in
addlink)
	check_link
	logger -t "【SS】" "addlink： $2"
	[ "$2" = "ss" ] || [ "$2" = "ssr" ]  && { [ -f /www/link/link.js ] && addlink_ss $@ ; }
	;;
dellink)
	check_link
	logger -t "【SS】" "dellink： $@"
	[ "$2" = "ss" ] || [ "$2" = "ssr" ]  && { [ -f /www/link/link.js ] && dellink_ss $@ ; }
	;;
stop)
	check_link
	shlinksh=$$
	eval $(ps -w | grep "sh_link.sh" | grep -v grep | grep -v "$shlinksh" | awk '{print "kill -9 "$1";";}')
	;;
start)
	check_link
	start_link
	;;
start_nvram)
	rm -f /etc/storage/link/link.js
	check_link
	start_link
	;;
check)
	check_link
	;;
clear_link)
	clear_link
	nvram set rt_ssnum_x_tmp=clean
	start_link
	;;
*)
	check_link
	start_link
	;;
esac


