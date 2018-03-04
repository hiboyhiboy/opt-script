#!/bin/sh
#copyright by hiboy
source /etc/storage/script/init.sh

speedup_enable=`nvram get app_10`
[ -z $speedup_enable ] && speedup_enable=0 && nvram set app_10=0
if [ "$speedup_enable" != "0" ] ; then
#nvramshow=`nvram showall | grep '=' | grep speedup | awk '{print gensub(/'"'"'/,"'"'"'\"'"'"'\"'"'"'","g",$0);}'| awk '{print gensub(/=/,"='\''",1,$0)"'\'';";}'` && eval $nvramshow
speedup_enable=`nvram get app_10`
[ -z $speedup_enable ] && speedup_enable=0 && nvram set app_10=0
speedup_Info=`nvram get app_11`
[ -z "$speedup_Info" ] && speedup_Info=1 && nvram set app_11=1
check_Qos=`nvram get app_12`
[ -z "$check_Qos" ] && check_Qos="" && nvram set app_12=""
Start_Qos=`nvram get app_13`
[ -z "$Start_Qos" ] && Start_Qos="" && nvram set app_13=""
Heart_Qos=`nvram get app_17`
[ -z "$Heart_Qos" ] && Heart_Qos="" && nvram set app_17=""
Info="$speedup_Info"
[ -z "$Info" ] && Info=1
STATUS="N"
SN=""
fi
speedup_path="/opt/app/speedup/speedup"


if [ ! -z "$(echo $scriptfilepath | grep -v "/tmp/script/" | grep speedup)" ]  && [ ! -s /tmp/script/_app4 ]; then
	mkdir -p /tmp/script
	{ echo '#!/bin/sh' ; echo $scriptfilepath '"$@"' '&' ; } > /tmp/script/_app4
	chmod 777 /tmp/script/_app4
fi

speedup_restart () {

speedup_renum=`nvram get speedup_renum`
relock="/var/lock/speedup_restart.lock"
if [ "$1" = "o" ] ; then
	nvram set speedup_renum="0"
	[ -f $relock ] && rm -f $relock
	return 0
fi
if [ "$1" = "x" ] ; then
	if [ -f $relock ] ; then
		logger -t "【speedup】" "多次尝试启动失败，等待【"`cat $relock`"分钟】后自动尝试重新启动"
		exit 0
	fi
	speedup_renum=${speedup_renum:-"0"}
	speedup_renum=`expr $speedup_renum + 1`
	nvram set speedup_renum="$speedup_renum"
	if [ "$speedup_renum" -gt "2" ] ; then
		I=19
		echo $I > $relock
		logger -t "【speedup】" "多次尝试启动失败，等待【"`cat $relock`"分钟】后自动尝试重新启动"
		while [ $I -gt 0 ]; do
			I=$(($I - 1))
			echo $I > $relock
			sleep 60
			[ "$(nvram get speedup_renum)" = "0" ] && exit 0
			[ $I -lt 0 ] && break
		done
		nvram set speedup_renum="0"
	fi
	[ -f $relock ] && rm -f $relock
fi
nvram set speedup_status=0
eval "$scriptfilepath &"
exit 0
}

speedup_get_status () {

#lan_ipaddr=`nvram get lan_ipaddr`
A_restart=`nvram get speedup_status`
B_restart="$speedup_enable$speedup_Info$check_Qos$Start_Qos$Heart_Qos"
B_restart=`echo -n "$B_restart" | md5sum | sed s/[[:space:]]//g | sed s/-//g`
if [ "$A_restart" != "$B_restart" ] ; then
	nvram set speedup_status=$B_restart
	needed_restart=1
else
	needed_restart=0
fi
}

speedup_check () {

speedup_get_status
if [ "$speedup_enable" != "1" ] && [ "$needed_restart" = "1" ] ; then
	[ ! -z "$(ps -w | grep "$speedup_path" | grep -v grep )" ] && logger -t "【speedup】" "停止 speedup" && speedup_close
	{ kill_ps "$scriptname" exit0; exit 0; }
fi
if [ "$speedup_enable" = "1" ] ; then
	if [ "$needed_restart" = "1" ] ; then
		speedup_close
		speedup_start
	else
		[ -z "$(ps -w | grep "$speedup_path" | grep -v grep )" ] && speedup_restart
	fi
fi
}

speedup_keep () {
logger -t "【speedup】" "守护进程启动"
if [ -s /tmp/script/_opt_script_check ]; then
sed -Ei '/【speedup】|^$/d' /tmp/script/_opt_script_check
cat >> "/tmp/script/_opt_script_check" <<-OSC
	NUM=\`grep "$speedup_path" /tmp/ps | grep -v grep |wc -l\` # 【speedup】
	if [ "\$NUM" -lt "1" ] || [ ! -s "$speedup_path" ] ; then # 【speedup】
		logger -t "【speedup】" "重新启动\$NUM" # 【speedup】
		nvram set speedup_status=00 && eval "$scriptfilepath &" && sed -Ei '/【speedup】|^$/d' /tmp/script/_opt_script_check # 【speedup】
	fi # 【speedup】
OSC
#return
fi
sleep 60
speedup_enable=`nvram get app_10` #speedup_enable
i=1
while [ "$speedup_enable" = "1" ]; do
	NUM=`ps -w | grep "$speedup_path" | grep -v grep |wc -l`
	if [ "$NUM" -lt "1" ] || [ ! -s "$speedup_path" ] || [ "$i" -ge 369 ] ; then
		logger -t "【speedup】" "重新启动$NUM"
		speedup_restart
	fi
sleep 69
i=$((i+1))
speedup_enable=`nvram get app_10` #speedup_enable
done
}

speedup_close () {
sed -Ei '/【speedup】|^$/d' /tmp/script/_opt_script_check
killall speedup
killall -9 speedup
kill_ps "speedup start_path"
kill_ps "/tmp/script/_app4"
kill_ps "_speedup.sh"
kill_ps "$scriptname"
}

speedup_start () {

[ -z "$check_Qos" ] && logger -t "【speedup】" "错误！！！【Check代码】未填写" && sleep 10 && exit
[ -z "$Start_Qos" ] && logger -t "【speedup】" "错误！！！【Start代码】未填写" && sleep 10 && exit

curltest=`which curl`
if [ -z "$curltest" ] || [ ! -s "`which curl`" ] ; then
	logger -t "【speedup】" "找不到 curl ，安装 opt 程序"
	/tmp/script/_mountopt optwget
	#initopt
	curltest=`which curl`
	if [ -z "$curltest" ] || [ ! -s "`which curl`" ] ; then
		logger -t "【speedup】" "找不到 curl ，需要手动安装 opt 后输入[opkg install curl]安装"
		logger -t "【speedup】" "启动失败, 10 秒后自动尝试重新启动" && sleep 10 && speedup_restart x
	else
		speedup_restart o
	fi
fi

update_app
speedup_vv=2017-10-25
speedup_v=$(grep 'speedup_vv=' /etc/storage/script/Sh27_speedup.sh | grep -v 'speedup_v=' | awk -F '=' '{print $2;}')
nvram set speedup_v="$speedup_v"
logger -t "【speedup】" "运行 $speedup_path"
ln -sf /etc/storage/script/Sh27_speedup.sh /opt/app/speedup/speedup
chmod 777 /opt/app/speedup/speedup
eval "$speedup_path" start_path &
sleep 2
[ ! -z "$(ps -w | grep "/opt/app/speedup/speedup" | grep -v grep )" ] && logger -t "【speedup】" "启动成功 $speedup_v " && speedup_restart o
[ -z "$(ps -w | grep "/opt/app/speedup/speedup" | grep -v grep )" ] && logger -t "【speedup】" "启动失败, 注意检查端口是否有冲突,程序是否下载完整,10 秒后自动尝试重新启动" && sleep 10 && speedup_restart x

speedup_get_status
eval "$scriptfilepath keep &"

}

speedup_start_path () {

# 主程序循环
re_STAT="$(eval "$check_Qos" | grep qosListResponse)"

# 获取提速包数量
qos_Info="$(echo "$re_STAT" | awk -F"/qosInfo" '{print NF-1}')"
[ -z "$qos_Info" ] && qos_Info=0
if [[ "$qos_Info"x == "1"x ]]; then
Info=1
fi
if [[ "$qos_Info" -ge 1 ]]; then
# 提速包1
qos_Info_1="$(echo "$re_STAT" | awk -F '/qosInfo' '{print $1}')"
qos_Info_x="$qos_Info_1"
get_info
logger -t "【speedup】" "包【1】 提速状态【$re_STATUS】 提速包名称【$prod_Name】 提速包代码【$prod_Code】 提速包时间【$used_Minutes/$total_Minutes】"
fi
if [[ "$qos_Info" -ge 2 ]]; then
# 提速包2
qos_Info_2="$(echo "$re_STAT" | awk -F '/qosInfo' '{print $2}')"
qos_Info_x="$qos_Info_2"
get_info
logger -t "【speedup】" "包【2】 提速状态【$re_STATUS】 提速包名称【$prod_Name】 提速包代码【$prod_Code】 提速包时间【$used_Minutes/$total_Minutes】"
fi
if [[ "$qos_Info" -ge 3 ]]; then
# 提速包3
qos_Info_3="$(echo "$re_STAT" | awk -F '/qosInfo' '{print $3}')"
qos_Info_x="$qos_Info_3"
get_info
logger -t "【speedup】" "包【3】 提速状态【$re_STATUS】 提速包名称【$prod_Name】 提速包代码【$prod_Code】 提速包时间【$used_Minutes/$total_Minutes】"
fi
if [[ "$qos_Info" -ge 4 ]]; then
# 提速包4
qos_Info_4="$(echo "$re_STAT" | awk -F '/qosInfo' '{print $4}')"
qos_Info_x="$qos_Info_4"
get_info
logger -t "【speedup】" "包【4】 提速状态【$re_STATUS】 提速包名称【$prod_Name】 提速包代码【$prod_Code】 提速包时间【$used_Minutes/$total_Minutes】"
fi
if [[ "$qos_Info" -ge 5 ]]; then
# 提速包5
qos_Info_5="$(echo "$re_STAT" | awk -F '/qosInfo' '{print $5}')"
qos_Info_x="$qos_Info_5"
get_info
logger -t "【speedup】" "包【5】 提速状态【$re_STATUS】 提速包名称【$prod_Name】 提速包代码【$prod_Code】 提速包时间【$used_Minutes/$total_Minutes】"
fi


QOS_Status
logger -t "【speedup】" "包【$Info】 提速状态【$re_STATUS】 重置时间【$remaining_Time】 提速包名称【$prod_Name】 提速包代码【$prod_Code】 提速包时间【$used_Minutes/$total_Minutes】"
#QOS_Start
[ -z "$SN" ] && SN=0
speedup_enable=`nvram get app_10`
[ -z $speedup_enable ] && speedup_enable=0 && nvram set app_10=0
while [[ "$speedup_enable" != 0 ]] 
do
	if [[ "$STATUS"x != "Y"x ]]; then
		logger -t "【speedup】" "STATUS is $STATUS , need to Speedup now"
		QOS_Start
		if [[ -z "$SN" ]]; then
			logger -t "【speedup】" "Start_ERROR!!!"
		else
			logger -t "【speedup】" "Start Speedup, SN: $SN"
			[ ! -z "$Heart_Qos" ] && QOS_Heart
			sleep 57
			QOS_Status
			logger -t "【speedup】" "包【$Info】 提速状态【$re_STATUS】 重置时间【$remaining_Time】 提速包名称【$prod_Name】 提速包代码【$prod_Code】 提速包时间【$used_Minutes/$total_Minutes】"
			if [[ "$STATUS"x == "Y"x ]]; then
				[ ! -z "$Heart_Qos" ] && QOS_Heart
				sleep 57
			fi
		fi
	fi
	QOS_Status
	#logger -t "【speedup】" "包【$Info】 提速状态【$re_STATUS】 重置时间【$remaining_Time】 提速包名称【$prod_Name】 提速包代码【$prod_Code】 提速包时间【$used_Minutes/$total_Minutes】"
	if [[ "$STATUS"x == "Y"x ]]; then
		[ ! -z "$Heart_Qos" ] && QOS_Heart
		sleep 57
	fi
	speedup_enable=`nvram get app_10`
	[ -z $speedup_enable ] && speedup_enable=0 && nvram set app_10=0
done

}

get_info()
{
# 提速包名称
prod_Name="$(echo "$qos_Info_x" | awk -F"\<prodName\>|\<\/prodName\>" '{if($2!="") print $2}')"
# 提速包代码
prod_Code="$(echo "$qos_Info_x" | awk -F"\<prodCode\>|\<\/prodCode\>" '{if($2!="") print $2}')"
# 提速包总时间（分钟）
total_Minutes="$(echo "$qos_Info_x" | awk -F"\<totalMinutes\>|\<\/totalMinutes\>" '{if($2!="") print $2}')"
# 提速包使用时间（分钟）
used_Minutes="$(echo "$qos_Info_x" | awk -F"\<usedMinutes\>|\<\/usedMinutes\>" '{if($2!="") print $2}')"
# 提速状态
re_STATUS="$(echo "$qos_Info_x" | awk -F"\<isSpeedup\>|\<\/isSpeedup\>" '{if($2!="") print $2}')"
# 重置剩余时间
remaining_Time="$(echo "$qos_Info_x" | awk -F"\<remainingTime\>|\<\/remainingTime\>" '{if($2!="") print $2}')"

}

QOS_Status()
{

#Session_Key="$(echo "$check_Qos" | grep -Eo "SessionKey:[ A-Za-z0-9_-]+" | cut -d ':' -f2 | sed -e "s/ //g" )"
#Signa_ture="$(echo "$check_Qos" | grep -Eo "Signature:[ A-Za-z0-9_-]+" | cut -d ':' -f2 | sed -e "s/ //g" )"
#GMT_Date="$(echo "$check_Qos" | grep -Eo "Date:[ A-Za-z0-9_-]+,[ A-Za-z0-9_-]+:[0-9]+:[ A-Za-z0-9_-]+" | awk -F 'Date: ' '{print $2}')"
#family_Id="$(echo "$check_Qos" | grep -Eo "familyId=[0-9]+" | awk -F '=' '{print $2}')"

#check_Qos_x="curl -s -H 'SessionKey: ""$Session_Key""' -H 'Signature: ""$Signa_ture""' -H 'Date: ""$GMT_Date""' -H 'Content-Type: text/xml; charset=utf-8' -H 'Host: api.cloud.189.cn' -H 'User-Agent: Apache-HttpClient/UNAVAILABLE (java 1.4)' 'http://api.cloud.189.cn/family/qos/checkQosAbility.action?familyId=""$family_Id""'"

check_Qos_x="$(echo "$check_Qos"" -s ")"

re_STAT="$(eval "$check_Qos_x" | grep qosListResponse)"

# 获取状态
if [[ "$Info"x == "1"x ]]; then
	# 提速包1
	qos_Info_1="$(echo "$re_STAT" | awk -F '/qosInfo' '{print $1}')"
	qos_Info_x="$qos_Info_1"
fi
if [[ "$Info"x == "2"x ]]; then
	# 提速包2
	qos_Info_2="$(echo "$re_STAT" | awk -F '/qosInfo' '{print $2}')"
	qos_Info_x="$qos_Info_2"
fi
if [[ "$Info"x == "3"x ]]; then
	# 提速包3
	qos_Info_3="$(echo "$re_STAT" | awk -F '/qosInfo' '{print $3}')"
	qos_Info_x="$qos_Info_3"
fi
if [[ "$Info"x == "4"x ]]; then
	# 提速包4
	qos_Info_4="$(echo "$re_STAT" | awk -F '/qosInfo' '{print $4}')"
	qos_Info_x="$qos_Info_4"
fi
if [[ "$Info"x == "5"x ]]; then
	# 提速包5
	qos_Info_5="$(echo "$re_STAT" | awk -F '/qosInfo' '{print $5}')"
	qos_Info_x="$qos_Info_5"
fi

get_info

STATUS=$re_STATUS

sleep 3
}

QOS_Start()
{

#Session_Key="$(echo "$Start_Qos" | grep -Eo "SessionKey:[ A-Za-z0-9_-]+" | cut -d ':' -f2 | sed -e "s/ //g" )"
#Signa_ture="$(echo "$Start_Qos" | grep -Eo "Signature:[ A-Za-z0-9_-]+" | cut -d ':' -f2 | sed -e "s/ //g" )"
#GMT_Date="$(echo "$Start_Qos" | grep -Eo "Date:[ A-Za-z0-9_-]+,[ A-Za-z0-9_-]+:[0-9]+:[ A-Za-z0-9_-]+" | awk -F 'Date: ' '{print $2}')"

#start_Qos_x="curl -s -H 'SessionKey: ""$Session_Key""' -H 'Signature: ""$Signa_ture""' -H 'Date: ""$GMT_Date""' -H 'Content-Type: text/xml; charset=utf-8' -H 'Host: api.cloud.189.cn' -H 'User-Agent: Apache-HttpClient/UNAVAILABLE (java 1.4)' 'http://api.cloud.189.cn/family/qos/startQos.action?prodCode=""$prod_Code""'"

start_Qos_x="$(echo "$Start_Qos"" -s ")"

SN_STAT="$(eval "$start_Qos_x" | grep qosInfo)"

SN="$(echo "$SN_STAT" | awk -F"\<qosSn\>|\<\/qosSn\>" '{if($2!="") print $2}')"

echo `date "+%Y-%m-%d %H:%M:%S"` "Start Speedup, SN: $SN"
sleep 3
}

QOS_Heart()
{

if [ "$SN"x != "x" ] && [ "$SN" != "0" ] ; then
	Heart_Qos_x="$(echo "$Heart_Qos" | sed -e "s|^\(.*qosSn.*\)=[^=]*$|\1=$SN|")"
	Heart_Qos_x="$(echo "$Heart_Qos_x""' -s ")"
	eval "$Heart_Qos_x"

fi

}

initopt () {
optPath=`grep ' /opt ' /proc/mounts | grep tmpfs`
[ ! -z "$optPath" ] && return
if [ ! -z "$(echo $scriptfilepath | grep -v "/opt/etc/init")" ] && [ -s "/opt/etc/init.d/rc.func" ] ; then
	{ echo '#!/bin/sh' ; echo $scriptfilepath '"$@"' '&' ; } > /opt/etc/init.d/$scriptname && chmod 777  /opt/etc/init.d/$scriptname
fi

}

update_app () {

mkdir -p /opt/app/speedup
if [ "$1" = "del" ] ; then
	rm -rf /opt/app/speedup/Advanced_Extensions_speedup.asp
fi

# 加载程序配置页面
if [ ! -f "/opt/app/speedup/Advanced_Extensions_speedup.asp" ] || [ ! -s "/opt/app/speedup/Advanced_Extensions_speedup.asp" ] ; then
	wgetcurl.sh /opt/app/speedup/Advanced_Extensions_speedup.asp "$hiboyfile/Advanced_Extensions_speedupasp" "$hiboyfile2/Advanced_Extensions_speedupasp"
fi
umount /www/Advanced_Extensions_app04.asp
mount --bind /opt/app/speedup/Advanced_Extensions_speedup.asp /www/Advanced_Extensions_app04.asp
# 更新程序启动脚本

[ "$1" = "del" ] && /etc/storage/www_sh/家庭云提速 del &
}

case $ACTION in
start)
	speedup_close
	speedup_check
	;;
check)
	speedup_check
	;;
stop)
	speedup_close
	;;
keep)
	#speedup_check
	speedup_keep
	;;
updateapp4)
	speedup_restart o
	[ "$speedup_enable" = "1" ] && nvram set speedup_status="updatespeedup" && logger -t "【speedup】" "重启" && speedup_restart
	[ "$speedup_enable" != "1" ] && nvram set speedup_v="" && logger -t "【speedup】" "更新" && update_app del
	;;
update_app)
	update_app
	;;
start_path)
	speedup_start_path
	;;
*)
	speedup_check
	;;
esac

