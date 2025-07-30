#!/bin/bash
#copyright by hiboy

de_2_base64 () {

if [ -z "$(echo "$1" | awk -F '#' '{print $1}' | grep -Eo [^A-Za-z0-9+/=:_-]+)" ] ; then
# 有些链接会多一层 base64 包裹，链接2次解码
	if [ ! -z "$(echo "$1" | awk -F '#' '{print $2}')" ] ; then
		echo "$(echo -n "$1" | awk -F '#' '{print $1}' | sed -e "s/_/\//g" | sed -e "s/-/\+/g" | sed 's/$/&====/g' | base64 -d)"'#'"$(echo -n "$1" | awk -F '#' '{print $2}')"
	else
		echo "$(echo -n "$1" | sed -e "s/_/\//g" | sed -e "s/-/\+/g" | sed 's/$/&====/g' | base64 -d)"
	fi
else
	echo "$1"
fi

}

is_2_base64() {
	check_base64="$(echo -n "$1" | sed -e "s@://@@g" | awk -F '#' '{print $1}' | grep -Eo [^A-Za-z0-9+/=:_-]+ | tr -d "\n")"
	check_base64="$(echo -n "$check_base64" | wc -c)"
	[ "$check_base64" -eq 0 ]
}

#↪️123🔀🔁➿123↩️


# 处理链接
link_de_protocol () {
[ -z "$link_tmp" ] && link_tmp="$1"
link_tmp=$(echo $link_tmp)
if [ ! -z "$link_tmp" ] ; then
add_0
[ ! -z "$(echo -n $link_tmp | grep -v "[Vv]less://" | grep -v "[Vv]mess://" | grep -Eo "ss://")" ] && link_protocol="ss"
[ ! -z "$(echo -n $link_tmp | grep -Eo "ssr://")" ] && link_protocol="ssr"
[ ! -z "$(echo -n $link_tmp | grep -Eo "[Vv]less://")" ] && link_protocol="vless"
[ ! -z "$(echo -n $link_tmp | grep -Eo "[Vv]mess://")" ] && link_protocol="vmess"
[ ! -z "$(echo -n $link_tmp | grep -Eo "trojan://")" ] && link_protocol="trojan"
# [ ! -z "$(echo -n $link_tmp | grep -Eo "trojan-go://")" ] && link_protocol="trojan"
# 非指定链接返回空值
link_de_m "$2"
fi
if [ ! -z "$link_tmp" ] ; then
[ "$link_protocol" == "ss" ] && de_ss_link
[ "$link_protocol" == "ssr" ] && de_ssr_link
[ "$link_protocol" == "vless" ] && de_vless_link
[ "$link_protocol" == "vmess" ] && de_vmess_link
[ "$link_protocol" == "trojan" ] && de_trojan_link
fi
link_tmp=""
}

# 非指定链接返回空值
link_de_m () {
if [ ! -z "$1" ] && [ -z "$(echo -n $1 | grep -Eo "0""$link_protocol""0")" ] ; then
add_0
link_tmp=""
fi
}

de_ss_link () {
[ -z "$link_tmp" ] && link_tmp="$1"
link_tmp=$(echo $link_tmp)
link="$link_tmp"
[ -z "$(echo -n $link | grep -v "[Vv]less" | grep -v "[Vv]mess" | grep -Eo "ss://")" ] && return 1
add_0
if [ ! -z "$(echo -n "$link" | grep -v "[Vv]less" | grep -v "[Vv]mess" | grep -Eo "ss://")" ] ; then
link_protocol="ss"
fi
link="$(echo "$link" | awk -F 'ss://' '{print $2}')"
link_input="ss://""$link"
# 链接2次解码
link="$(de_2_base64 "$(echo -n $link)")"
#服务器的描述信息
if [ ! -z "$(echo -n "$link" | grep '#')" ] ; then
ss_link_name_url="$(echo -n "$link" | awk -F '#' '{print $2}')"
ss_link_name="$(echo $(printf $(echo -n "$ss_link_name_url" | sed 's/\\/\\\\/g;s/\(%\)\([0-9a-fA-F][0-9a-fA-F]\)/\\x\2/g')) | sed -n '1p')"
link=$(echo -n $link | awk -F '#' '{print $1}')
fi
# 链接2次解码
link="$(de_2_base64 "$(echo -n $link)")"
#不将主机名和端口号解析为Base64URL ss://cmM0LW1kNTpwYXNzd2Q=@192.168.100.1:8888/?plugin=obfs-local%3Bobfs%3Dhttp%3Bobfs-host%3Dwww.bing.com#Example2
#部分信息解析为Base64URL ss://cmM0LW1kNTpwYXNzd2RAMTkyLjE2OC4xMDAuMTo4ODg4Lz9wbHVnaW49b2Jmcy1sb2NhbCUzQm9iZnMlM0RodHRw==#Example2
# 链接2次解码 methodpassword 信息
ss_link_methodpassword=$(echo -n $link | grep -Eo '^[^@]+' | sed -n '1p')
[ -z "$(echo $ss_link_methodpassword | grep ":")" ] && ss_link_methodpassword="$(de_2_base64 "$(echo -n $ss_link_methodpassword)")"
ss_link_usage=$(echo -n $link | grep -Eo '@.+[:]+[0-9]+' | grep -Eo '[^@]+[0-9]+' | sed -n '1p')
ss_link_server=$(echo -n "$ss_link_usage" | grep -Eo ".+:" | grep -Eo '.+[^:]')
[ -z "$ss_link_name" ] && ss_link_name="♯"$(echo -n "$ss_link_server")
ss_link_name="〔$link_protocol〕$ss_link_name"
ss_link_port=$(echo -n "$ss_link_usage" | grep -Eo '.+[:]+[0-9]+' | grep -Eo ":[0-9]+" | grep -Eo '[^:]+' | sed -n '$p')
ss_link_password="$(echo -n "$ss_link_methodpassword" | awk -F ':' '{print $2}')"
ss_link_method=$(echo -n "$ss_link_methodpassword" | awk -F ':' '{print $1}')
ex_params="$(echo -n $link | grep -Eo 'plugin=.+' | sed -n '1p')"
if [ ! -z "$ex_params" ] ; then
	#存在插件
	ex_obfsparam="$(echo -n "$ex_params" | grep -Eo "plugin=[^&#]*" | sed -n '1p'| awk -F 'plugin=' '{print $2}')"
	ex_obfsparam="$(printf $(echo -n $ex_obfsparam | sed 's/\\/\\\\/g;s/\(%\)\([0-9a-fA-F][0-9a-fA-F]\)/\\x\2/g'))"
	ss_link_plugin="$(echo -n "$ex_obfsparam" | grep -Eo "^[^;]+" | sed -n '1p' | grep -Eo '^.+[^;]' | sed -n '1p')"
	ss_link_plugin_opts="$(echo -n "$ex_obfsparam" | grep -Eo ";.+" | grep -Eo "[^;].+" | sed -n '1p')"
fi
link_name="$ss_link_name"
link_server="$ss_link_server"
link_port="$ss_link_port"
link_tmp=""
ss_link_obfs="plain"
ss_link_protocol="origin"

}

de_ssr_link () {
[ -z "$link_tmp" ] && link_tmp="$1"
link_tmp=$(echo $link_tmp)
link="$link_tmp"
[ -z "$(echo -n $link | grep -Eo "ssr://")" ] && return 1
add_0
if [ ! -z "$(echo -n "$link" | grep "ssr://")" ] ; then
link_protocol="ssr"
fi
link="$(echo "$link" | awk -F 'ssr://' '{print $2}')"
link_input="ssr://""$link"
# 链接2次解码
link="$(de_2_base64 "$(echo -n $link)")"
#8.8.8.8:443:auth_aes128_md5:chacha20:tls1.2_ticket_auth:bWJsYW5rMXBvcnQ/?obfsparam=b2ZmaWNlY2RuLm1pY3Jvc29mdC5jb20&protoparam=MTgwODM6aGFwcHkwMzAz&remarks=W-WNleerr-WPo10g5pyA5paw5Z-f5ZCNOiB3ZWJsYW5rLnh5eg&group=5aWH5bm75LmL5peFIFt3ZWJsYW5rLnh5el0&udpport=0&uot=0
#服务器的描述信息
ss_link_usage=$(echo -n $link | grep -Eo '^[^/?]+' | sed -n '1p')
ss_link_server=`echo -n "$ss_link_usage" | grep -Eo '.+[:]+[0-9]+' | grep -Eo ".+:" | grep -Eo '.+[^:]'`
ss_link_port=`echo -n "$ss_link_usage" | grep -Eo '.+[:]+[0-9]+' | grep -Eo ":[0-9]+" | grep -Eo '[^:]+' | sed -n '$p'`
ss_link_usage=$(echo -n "$ss_link_usage" | grep -Eo ':'"$ss_link_port"':.+')
ss_link_password="$(echo -n "$ss_link_usage" | awk -F ':' '{print $6}' | sed -e "s/_/\//g" | sed -e "s/\-/\+/g" | sed 's/$/&====/g' | base64 -d | sed -n '1p')"
ss_link_method=`echo -n "$ss_link_usage" | awk -F ':' '{print $4}'`
ss_link_obfs=`echo -n "$ss_link_usage" | awk -F ':' '{print $5}'` # -o
if [ "$ss_link_obfs"x = "tls1.2_ticket_fastauth"x ] ; then
	ss_link_obfs="tls1.2_ticket_auth"
fi
ss_link_protocol="$(echo -n "$ss_link_usage" | awk -F ':' '{print $3}')" # -O

#设置参数
ex_params=$(echo -n $link | grep -Eo "[/?].+" | sed -n '1p' | grep -Eo '[^/?].+' | sed -n '1p')
ss_link_obfsparam="$(echo -n "$ex_params" | grep -Eo "obfsparam=[^&]*" | sed -n '1p' | awk -F 'obfsparam=' '{print $2}' | sed -e "s/_/\//g" | sed -e "s/\-/\+/g" | sed 's/$/&====/g' | base64 -d | sed -n '1p')"
ss_link_protoparam="$(echo -n "$ex_params" | grep -Eo "protoparam=[^&]*" | sed -n '1p' | awk -F 'protoparam=' '{print $2}' | sed -e "s/_/\//g" | sed -e "s/\-/\+/g" | sed 's/$/&====/g' | base64 -d | sed -n '1p')"
ss_link_name="$(echo -n "$ex_params" | grep -Eo "remarks=[^&]*" | sed -n '1p' | awk -F 'remarks=' '{print $2}' | sed -e "s/_/\//g" | sed -e "s/\-/\+/g" | sed 's/$/&====/g' | base64 -d | sed -n '1p')"
[ -z "$ss_link_name" ] && ss_link_name="♯"$(echo -n "$ss_link_server")
ss_link_name="〔$link_protocol〕$ss_link_name"
link_name="$ss_link_name"
link_server="$ss_link_server"
link_port="$ss_link_port"
link_tmp=""

}

de_vless_link () {
[ -z "$link_tmp" ] && link_tmp="$1"
link_tmp=$(echo $link_tmp)
link="$link_tmp"
[ -z "$(echo -n $link | grep -Eo "[Vv][ml]ess://")" ] && return 1
add_0
if [ ! -z "$(echo -n "$link" | grep "[Vv]less://")" ] ; then
link="$(echo -n "$link" | sed -e "s@Vless://@vless://@g" | awk -F 'vless://' '{print $2}')"
link_protocol="vless"
link_input="vless://""$link"
fi
if [ ! -z "$(echo -n "$link" | grep "[Vv]mess://")" ] ; then
link="$(echo -n "$link" | sed -e "s@Vmess://@vmess://@g" | awk -F 'vmess://' '{print $2}')"
link_protocol="vmess"
link_input="vmess://""$link"
fi
# 链接2次解码
link="$(de_2_base64 "$(echo -n $link)")"
# 详述 https://github.com/XTLS/Xray-core/issues/91# MessAEAD _ VLESS 分享链接标准提
# https://github.com/XTLS/Xray-core/discussions/716# VMessAEAD / VLESS 分享链接标准提案
if [ ! -z "$(echo -n "$link" | grep '#')" ] ; then
vless_link_name_url="$(echo -n "$link" | awk -F '#' '{print $2}')"
vless_link_name="$(echo $(printf $(echo -n "$vless_link_name_url" | sed 's/\\/\\\\/g;s/\(%\)\([0-9a-fA-F][0-9a-fA-F]\)/\\x\2/g')) | sed -n '1p')"
link="$(echo -n $link | awk -F '#' '{print $1}' | sed -n '1p')"
fi
vless_link_uuid_url="$(echo -n $link | grep -Eo '^.+?@' | sed -n '1p' | grep -Eo '^.+[^@]' | sed -n '1p')"
vless_link_uuid="$(echo $(printf $(echo -n "$vless_link_uuid_url" | sed 's/\\/\\\\/g;s/\(%\)\([0-9a-fA-F][0-9a-fA-F]\)/\\x\2/g')) | sed -n '1p')"
vless_link_remote=$(echo -n $link | awk -F "$vless_link_uuid_url@" '{print $2}' | grep -Eo '.+?:[0-9]+?' | sed -n '1p')
vless_link_remote_host=$(echo -n $vless_link_remote | grep -Eo ".+:" | grep -Eo '.+[^:]')
vless_link_remote_port=$(echo -n $vless_link_remote | grep -Eo ":[0-9]+" | grep -Eo '[^:]+' | sed -n '$p')
[ -z "$vless_link_name" ] && vless_link_name="♯"$(echo -n "$vless_link_remote_host")
vless_link_name="〔$link_protocol〕$vless_link_name"
link_name="$vless_link_name"
link_server="$vless_link_remote_host"
link_port="$vless_link_remote_port"
[ "$link_read" == "ping" ] && link_read="" && return
vless_link_specific=$(echo -n $link | grep -Eo "[/?].+" | sed -n '1p' | grep -Eo '[^/?].+' | sed -n '1p')
if [ ! -z "$vless_link_specific" ] ; then

vless_link_type="$(echo -n "$vless_link_specific" | grep -Eo "type=[^&]*" | awk -F 'type=' '{print $2}' | sed -n '1p')"
[ -z "$vless_link_type" ] && vless_link_type="tcp"

vless_link_encryption="$(echo -n "$vless_link_specific" | grep -Eo "encryption=[^&]*" | awk -F 'encryption=' '{print $2}' | sed -n '1p')"
[ "$link_protocol" == "vless" ] && [ -z "$vless_link_encryption" ] && vless_link_encryption="none"
[ "$link_protocol" == "vmess" ] && [ -z "$vless_link_encryption" ] && vless_link_encryption="auto"

vless_link_alterId="$(echo -n "$vless_link_specific" | grep -Eo "alter[Ii]d=[^&]*"  | cut -d '=' -f2 | sed -n '1p')"

vless_link_aid="$(echo -n "$vless_link_specific" | grep -Eo "aid=[^&]*"  | cut -d '=' -f2 | sed -n '1p')"
[ -z "$vless_link_aid" ] && [ ! -z "$vless_link_alterId" ] && vless_link_aid="$vless_link_alterId"

vless_link_security="$(echo -n "$vless_link_specific" | grep -Eo "security=[^&]*"  | cut -d '=' -f2 | sed -n '1p')"
[ -z "$vless_link_security" ] && vless_link_security="none"

vless_link_path_url="$(echo -n "$vless_link_specific" | grep -Eo "path=[^&]*"  | cut -d '=' -f2 | sed -n '1p')"
[ ! -z "$vless_link_path_url" ] && vless_link_path="$(printf $(echo -n $vless_link_path_url | sed 's/\\/\\\\/g;s/\(%\)\([0-9a-fA-F][0-9a-fA-F]\)/\\x\2/g'))"
#[ -z "$vless_link_path" ] && vless_link_path="/"

vless_link_host_url="$(echo -n "$vless_link_specific" | grep -Eo "host=[^&]*"  | cut -d '=' -f2 | sed -n '1p')"
[ ! -z "$vless_link_host_url" ] && vless_link_host="$(printf $(echo -n $vless_link_host_url | sed 's/\\/\\\\/g;s/\(%\)\([0-9a-fA-F][0-9a-fA-F]\)/\\x\2/g'))"
[ "$vless_link_type" == "http" ] && [ -z "$vless_link_host" ] && vless_link_host="$vless_link_remote_host"

vless_link_headerType="$(echo -n "$vless_link_specific" | grep -Eo "header[Tt]ype=[^&]*"  | cut -d '=' -f2 | sed -n '1p')"
[ -z "$vless_link_headerType" ] && vless_link_headerType="none"

vless_link_seed_url="$(echo -n "$vless_link_specific" | grep -Eo "seed=[^&]*"  | cut -d '=' -f2 | sed -n '1p')"
[ ! -z "$vless_link_seed_url" ] && vless_link_seed="$(printf $(echo -n $vless_link_seed_url | sed 's/\\/\\\\/g;s/\(%\)\([0-9a-fA-F][0-9a-fA-F]\)/\\x\2/g'))"

vless_link_quicSecurity="$(echo -n "$vless_link_specific" | grep -Eo "quic[Ss]ecurity=[^&]*"  | cut -d '=' -f2 | sed -n '1p')"
[ -z "$vless_link_quicSecurity" ] && vless_link_quicSecurity="none"

vless_link_key_url="$(echo -n "$vless_link_specific" | grep -Eo "key=[^&]*"  | cut -d '=' -f2 | sed -n '1p')"
[ ! -z "$vless_link_key_url" ] && vless_link_key="$(printf $(echo -n $vless_link_key_url | sed 's/\\/\\\\/g;s/\(%\)\([0-9a-fA-F][0-9a-fA-F]\)/\\x\2/g'))"

vless_link_serviceName="$(echo -n "$vless_link_specific" | grep -Eo "service[Nn]ame=[^&]*"  | cut -d '=' -f2 | sed -n '1p')"
[ ! -z "$vless_link_serviceName" ] && vless_link_serviceName="$(printf $(echo -n $vless_link_serviceName | sed 's/\\/\\\\/g;s/\(%\)\([0-9a-fA-F][0-9a-fA-F]\)/\\x\2/g'))"

vless_link_authority="$(echo -n "$vless_link_specific" | grep -Eo "authority=[^&]*"  | cut -d '=' -f2 | sed -n '1p')"
[ ! -z "$vless_link_authority" ] && vless_link_authority="$(printf $(echo -n $vless_link_authority | sed 's/\\/\\\\/g;s/\(%\)\([0-9a-fA-F][0-9a-fA-F]\)/\\x\2/g'))"

vless_link_mode="$(echo -n "$vless_link_specific" | grep -Eo "mode=[^&]*"  | cut -d '=' -f2 | sed -n '1p')"
[ -z "$vless_link_mode" ] && vless_link_mode="gun"

vless_link_sni="$(echo -n "$vless_link_specific" | grep -Eo "sni=[^&]*"  | cut -d '=' -f2 | sed -n '1p')"
if [ -z "$vless_link_sni" ] ; then
	if [ $(echo "$vless_link_remote_host" | grep -Ec '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$') -ne 0 ] || [ $(echo "$vless_link_remote_host" | grep -c '[:]') -ne 0 ] ; then
		vless_link_sni="$vless_link_host"
	else
		vless_link_sni="$vless_link_remote_host"
	fi
fi

vless_link_alpn_url="$(echo -n "$vless_link_specific" | grep -Eo "alpn=[^&]*"  | cut -d '=' -f2 | sed -n '1p')"
[ ! -z "$vless_link_alpn_url" ] && vless_link_alpn="$(printf $(echo -n $vless_link_alpn_url | sed 's/\\/\\\\/g;s/\(%\)\([0-9a-fA-F][0-9a-fA-F]\)/\\x\2/g'))"

vless_link_allowInsecure="$(echo -n "$vless_link_specific" | grep -Eo "allow[Ii]nsecure=[^&]*"  | cut -d '=' -f2 | sed -n '1p')"

vless_link_flow="$(echo -n "$vless_link_specific" | grep -Eo "flow=[^&]*"  | cut -d '=' -f2 | sed -n '1p')"
vless_link_fp="$(echo -n "$vless_link_specific" | grep -Eo "fp=[^&]*"  | cut -d '=' -f2 | sed -n '1p')"
[ -z "$vless_link_fp" ] && vless_link_fp="chrome"

vless_link_pbk="$(echo -n "$vless_link_specific" | grep -Eo "pbk=[^&]*"  | cut -d '=' -f2 | sed -n '1p')"
vless_link_sid="$(echo -n "$vless_link_specific" | grep -Eo "sid=[^&]*"  | cut -d '=' -f2 | sed -n '1p')"
vless_link_spx="$(echo -n "$vless_link_specific" | grep -Eo "spx=[^&]*"  | cut -d '=' -f2 | sed -n '1p')"
[ ! -z "$vless_link_spx" ] && vless_link_spx="$(printf $(echo -n $vless_link_spx | sed 's/\\/\\\\/g;s/\(%\)\([0-9a-fA-F][0-9a-fA-F]\)/\\x\2/g'))"

fi
link_tmp=""

}

de_vmess_link () {
[ -z "$link_tmp" ] && link_tmp="$1"
link_tmp=$(echo $link_tmp)
link="$link_tmp"
[ -z "$(echo -n $link | grep -Eo "[Vv]mess://")" ] && return 1
add_0
if [ ! -z "$(echo -n "$link" | grep "[Vv]mess://")" ] ; then
link="$(echo -n "$link" | sed -e "s@Vmess://@vmess://@g" | awk -F 'vmess://' '{print $2}')"
link_protocol="vmess"
link_input="vmess://""$link"
fi
# 链接2次解码
link="$(de_2_base64 "$(echo -n $link)")"
# 详述 https://github.com/2dust/v2rayN/wiki/分享链接格式说明(ver-2)
# 实在看不懂这说明，链接大概率不兼容
if [ "$link_read" == "ping" ] ; then
# ping 改用 grep 进行快速解码
link="$(echo $link | tr -d "\ ")"
vless_link_remote_host="$(echo "$link" | grep -Eo "\"add\":[^,]+" | tr -d "\ " | tr -d "\"" | sed -e "s@^add:@@g")"
link_server="$vless_link_remote_host"
if [ ! -z "$vless_link_remote_host" ] ; then
vless_link_name="$(echo "$link" | grep -Eo "\"remark\":[^,]+" | tr -d "\ " | tr -d "\"" | sed -e "s@^remark:@@g")"
[ -z "$vless_link_name" ] && vless_link_name="$(echo "$link" | grep -Eo "\"ps\":[^,]+" | tr -d "\ " | tr -d "\"" | sed -e "s@^ps:@@g")"
[ -z "$vless_link_name" ] && vless_link_name="♯""$vless_link_remote_host"
vless_link_remote_port="$(echo "$link" | grep -Eo "\"port\":[^,]+" | tr -d "\ " | tr -d "\"" | sed -e "s@^port:@@g")"
link_port="$vless_link_remote_port"
link_read="" && return
else
# 使用 vless 分享链接规则
de_vless_link "$link_tmp"
return
fi
fi
link="$(echo $link | jq -c .)"
vless_link_remote_host="$(echo "$link" | jq -r .add | sed 's/[ \t]*//g')"
[ "$vless_link_remote_host" == "null" ] && vless_link_remote_host=""
link_server="$vless_link_remote_host"
if [ ! -z "$vless_link_remote_host" ] ; then
vless_link_name="$(echo "$link" | jq -r .remark | sed 's/[ \t]*//g')"
[ "$vless_link_name" == "null" ] && vless_link_name="$(echo "$link" | jq -r .ps | sed 's/[ \t]*//g')"
[ "$vless_link_name" == "null" ] && vless_link_name=""
[ -z "$vless_link_name" ] && vless_link_name="♯""$vless_link_remote_host"
vless_link_name="〔$link_protocol〕$vless_link_name"
link_name="$vless_link_name"
vless_link_remote_port="$(echo "$link" | jq -r .port | sed 's/[ \t]*//g')"
link_port="$vless_link_remote_port"
[ "$link_read" == "ping" ] && link_read="" && return
vless_link_uuid="$(echo "$link" | jq -r .id | sed 's/[ \t]*//g')"
vless_link_aid="$(echo "$link" | jq -r .aid | sed 's/[ \t]*//g')"
# scy: 加密方式(security),没有时值默认auto
vless_link_encryption="$(echo "$link" | jq -r .scy)"
[ "$vless_link_encryption" == "null" ] && vless_link_encryption=""
[ -z "$vless_link_encryption" ] && vless_link_encryption="auto"
# net: 传输协议(tcp\kcp\ws\h2\quic)
vless_link_type="$(echo "$link" | jq -r .net)"
[ "$vless_link_type" == "null" ] && vless_link_type=""
[ -z "$vless_link_type" ] && vless_link_type="tcp"
# type: 伪装类型(none\http\srtp\utp\wechat-video) *tcp or kcp or QUIC
vless_link_headerType="$(echo "$link" | jq -r .headerType)"
[ "$vless_link_headerType" == "null" ] && vless_link_headerType="$(echo "$link" | jq -r .type)"
vless_link_security="$(echo "$link" | jq -r .tls)"
vless_link_sni="$(echo "$link" | jq -r .sni)"
vless_link_verify_cert="$(echo "$link" | jq -r .verify_cert)"
[ "$vless_link_verify_cert" == "true" ] && vless_link_allowInsecure="false"
[ "$vless_link_verify_cert" == "false" ] && vless_link_allowInsecure="true"

vless_link_v="$(echo "$link" | jq -r .v)"
[ "$vless_link_v" == "null" ] && vless_link_v="0"
if [ "$vless_link_v" == "2" ] ; then
# host: 伪装的域名
vless_link_host="$(echo "$link" | jq -r .host)"
case $vless_link_type in
	quic)
		vless_link_quicSecurity="$(echo "$link" | jq -r .host)"
		[ "$vless_link_quicSecurity" == "null" ] && vless_link_quicSecurity=""
		[ -z "$vless_link_quicSecurity" ] && vless_link_quicSecurity="none"
	;;
esac
# path: path
vless_link_path="$(echo "$link" | jq -r .path)"
case $vless_link_type in
	quic)
		vless_link_key="$(echo "$link" | jq -r .path)"
		[ "$vless_link_key" == "null" ] && vless_link_key=""
		[ "$vless_link_quicSecurity" == "none" ] && vless_link_key=""
	;;
	kcp)
		vless_link_seed="$(echo "$link" | jq -r .path)"
	;;
	grpc)
		vless_link_serviceName="$(echo "$link" | jq -r .path)"
		[ ! -z "$vless_link_serviceName" ] && vless_link_serviceName="$(printf $(echo -n $vless_link_serviceName | sed 's/\\/\\\\/g;s/\(%\)\([0-9a-fA-F][0-9a-fA-F]\)/\\x\2/g'))"
	;;
esac
fi
if [ "$vless_link_v" -lt 2 ] ; then
# 不兼容更旧规则，找不到说明
vless_link_path=""
vless_link_host=""
fi
[ "$vless_link_remote_port" == "null" ] && vless_link_remote_port=""
[ "$vless_link_uuid" == "null" ] && vless_link_uuid=""
[ "$vless_link_aid" == "null" ] && vless_link_aid=""
[ "$vless_link_security" == "null" ] && vless_link_security=""
[ -z "$vless_link_security" ] && vless_link_security="none"
[ "$vless_link_headerType" == "null" ] && vless_link_headerType=""
[ -z "$vless_link_headerType" ] && vless_link_headerType="none"
[ "$vless_link_sni" == "null" ] && vless_link_sni=""
[ "$vless_link_serviceName" == "null" ] && vless_link_serviceName=""
[ "$vless_link_host" == "null" ] && vless_link_host=""
#[ -z "$vless_link_host" ] && vless_link_host="$vless_link_remote_host"
[ "$vless_link_path" == "null" ] && vless_link_path=""
#[ -z "$vless_link_path" ] && vless_link_path="/"

else
# 使用 vless 分享链接规则
de_vless_link "$link_tmp"
fi
link_tmp=""

}

de_trojan_link () {

# 未配置 trojan 客户端，待完成
# trojan://321a@1.0.0.1:123?peer=abc.com#test.%2B
# https://github.com/p4gefau1t/trojan-go/issues/132
[ -z "$link_tmp" ] && link_tmp="$1"
link_tmp=$(echo $link_tmp)
link="$link_tmp"
link_tmp=""
[ -z "$(echo -n $link | grep -Eo "trojan://")" ] && return 1
add_0
if [ ! -z "$(echo -n "$link" | grep "trojan://")" ] ; then
link_protocol="trojan"
fi
link="$(echo "$link" | awk -F 'trojan://' '{print $2}')"
link_input="trojan://""$link"
# 链接2次解码
link="$(de_2_base64 "$(echo -n $link)")"
#服务器的描述信息
if [ ! -z "$(echo -n "$link" | grep '#')" ] ; then
trojan_link_name_url="$(echo -n $link | awk -F '#' '{print $2}')"
trojan_link_name="$(echo $(printf $(echo -n "$trojan_link_name_url" | sed 's/\\/\\\\/g;s/\(%\)\([0-9a-fA-F][0-9a-fA-F]\)/\\x\2/g')) | sed -n '1p')"
link=$(echo -n $link | awk -F '#' '{print $1}')
trojan_link_password_url=$(echo -n $link | grep -Eo '^[^@]+' | sed -n '1p')
trojan_link_password="$(echo $(printf $(echo -n "$trojan_link_password_url" | sed 's/\\/\\\\/g;s/\(%\)\([0-9a-fA-F][0-9a-fA-F]\)/\\x\2/g')) | sed -n '1p')"
trojan_link_usage=$(echo -n $link | grep -Eo '@.+[:]+[0-9]+' | grep -Eo '[^@]+[0-9]+' | sed -n '1p')
if [ ! -z "$trojan_link_usage" ] ; then
	# 含有 :433 端口的情况
	trojan_link_server=$(echo -n "$trojan_link_usage" | grep -Eo ".+:" | grep -Eo '.+[^:]')
	trojan_link_port=$(echo -n "$trojan_link_usage" | grep -Eo '.+[:]+[0-9]+' | grep -Eo ":[0-9]+" | grep -Eo '[^:]+' | sed -n '$p')
else
	# 缺少 :433 端口情况
	trojan_link_server=$(echo -n $link | grep -Eo '@[^#\?]+' | grep -Eo '[^@]+' | sed -n '1p')
	trojan_link_port="443"
fi
[ -z "$trojan_link_name" ] && trojan_link_name="♯"$(echo -n "$trojan_link_server")
trojan_link_name="〔$link_protocol〕$trojan_link_name"
link_name="$trojan_link_name"
link_server="$trojan_link_server"
link_port="$trojan_link_port"
fi

}

add_0 () {
link_protocol=""
link_name=""
link_server=""
link_port=""
link_input=""

ss_link_name=""
ss_link_server=""
ss_link_port=""
ss_link_password=""
ss_link_method=""
ss_link_obfs=""
ss_link_protocol=""
ss_link_obfsparam=""
ss_link_protoparam=""
ss_link_plugin=""
ss_link_plugin_opts=""

vless_link_name=""
vless_link_uuid=""
vless_link_remote_host=""
vless_link_remote_port=""
vless_link_type=""
vless_link_encryption=""
vless_link_alterId=""
vless_link_aid=""
vless_link_security=""
vless_link_path=""
vless_link_host=""
vless_link_headerType=""
vless_link_seed=""
vless_link_quicSecurity=""
vless_link_key=""
vless_link_serviceName=""
vless_link_authority=""
vless_link_mode=""
vless_link_sni=""
vless_link_alpn=""
vless_link_allowInsecure=""
vless_link_flow=""
vless_link_fp=""
vless_link_pbk=""
vless_link_sid=""
vless_link_spx=""

vless_link_v=""
[ -z "$vless_link_v" ] && vless_link_v="0"
[ "$vless_link_v" -lt 1 ] && vless_link_v="0" || { [ "$vless_link_v" -ge 0 ] || vless_link_v="0" ; }

trojan_link_name=""
trojan_link_server=""
trojan_link_port=""
trojan_link_password=""

}

