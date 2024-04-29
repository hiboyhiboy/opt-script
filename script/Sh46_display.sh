#!/bin/bash
#copyright by hiboy
source /etc/storage/script/init.sh
display_enable=`nvram get display_enable`
[ -z $display_enable ] && display_enable=0 && nvram set display_enable=0
if [ "$display_enable" != "0" ] ; then

display_weather=`nvram get display_weather`
display_aqidata=`nvram get display_aqidata`

if [ -z "$display_weather" ] ; then 
display_weather="2151330"
nvram set display_weather="2151330"

fi
if [ -z "$display_aqidata" ] ; then 
display_aqidata="beijing"
nvram set display_aqidata="beijing"
fi

display_renum=`nvram get display_renum`
display_renum=${display_renum:-"0"}
cmd_log_enable=`nvram get cmd_log_enable`
cmd_name="相框显示"
cmd_log=""
if [ "$cmd_log_enable" = "1" ] || [ "$display_renum" -gt "0" ] ; then
	cmd_log="$cmd_log2"
fi

fi

if [ ! -z "$(echo $scriptfilepath | grep -v "/tmp/script/" | grep display)" ] && [ ! -s /tmp/script/_display ] ; then
	mkdir -p /tmp/script
	{ echo '#!/bin/bash' ; echo $scriptfilepath '"$@"' '&' ; } > /tmp/script/_display
	chmod 777 /tmp/script/_display
fi

display_restart () {
i_app_restart "$@" -name="display"
}

display_get_status () {

[ ! -f /etc/storage/display_lcd4linux_script.sh ] && touch /etc/storage/display_lcd4linux_script.sh
B_restart="$display_enable$display_weather$display_aqidata$(cat /etc/storage/display_lcd4linux_script.sh | grep -v '^#' | grep -v '^$')"

i_app_get_status -name="display" -valb="$B_restart"
}

display_check () {

display_get_status
if [ "$display_enable" != "1" ] && [ "$needed_restart" = "1" ] ; then
	[ ! -z "`pidof lcd4linux`" ] && logger -t "【相框显示】" "停止 lcd4linux" && display_close
	{ kill_ps "$scriptname" exit0; exit 0; }
fi
if [ "$display_enable" = "1" ] ; then
	if [ "$needed_restart" = "1" ] ; then
		display_close
		display_start
	else
		[ -z "`pidof lcd4linux`" ] || [ ! -s "`which lcd4linux`" ] && display_restart
	fi
fi
}

display_keep () {
eval $(ps -w | grep "$scriptfilepath getweather" | grep -v grep | awk '{print "kill "$1";";}')
eval "$scriptfilepath getweather &"
eval $(ps -w | grep "$scriptfilepath getaqidata" | grep -v grep | awk '{print "kill "$1";";}')
eval "$scriptfilepath getaqidata &"
i_app_keep -name="display" -pidof="lcd4linux" &
runx="1"
while true; do
display_enable=`nvram get display_enable`
[ "$display_enable" != "1" ] && exit
	if [ -z "`pidof lcd4linux`" ] || [ ! -s "`which lcd4linux`" ] && [ ! -s /tmp/script/_opt_script_check ] ; then
		logger -t "【相框显示】" "重新启动"
		display_restart
	fi
sleep 180
runx=`expr $runx + 1`
if [ "$runx" -eq 10 ] && [ "`nvram get display_enable`" = "1" ] ; then
	# 每半小时获取天气信息
	eval $(ps -w | grep "$scriptfilepath getweather" | grep -v grep | awk '{print "kill "$1";";}')
	eval "$scriptfilepath getweather &"
fi
if [ "$runx" -eq 20 ] && [ "`nvram get display_enable`" = "1" ] ; then
	# 每1小时获取AQI数据和数据绘图
	runx=1
	eval $(ps -w | grep "$scriptfilepath getaqidata" | grep -v grep | awk '{print "kill "$1";";}')
	eval "$scriptfilepath getaqidata &"
fi
done

}

display_close () {
kill_ps "$scriptname keep"
sed -Ei '/【相框显示】|^$/d' /tmp/script/_opt_script_check
sed -Ei '/【display】|^$/d' /tmp/script/_opt_script_check
killall lcd4linux getaqidata getweather displaykeep.sh
kill_ps "/tmp/script/_display"
kill_ps "_display.sh"
kill_ps "$scriptname"
}

display_start () {
check_webui_yes
ss_opt_x=`nvram get ss_opt_x`
upanPath=""
[ "$ss_opt_x" = "3" ] && upanPath="`df -m | grep /dev/mmcb | grep -E "$(echo $(/usr/bin/find /dev/ -name 'mmcb*') | sed -e 's@/dev/ /dev/@/dev/@g' | sed -e 's@ @|@g')" | grep "/media" | awk '{print $NF}' | sort -u | awk 'NR==1' `"
[ "$ss_opt_x" = "4" ] && upanPath="`df -m | grep /dev/sd | grep -E "$(echo $(/usr/bin/find /dev/ -name 'sd*') | sed -e 's@/dev/ /dev/@/dev/@g' | sed -e 's@ @|@g')" | grep "/media" | awk '{print $NF}' | sort -u | awk 'NR==1' `"
[ -z "$upanPath" ] && [ "$ss_opt_x" = "1" ] && upanPath="`df -m | grep /dev/mmcb | grep -E "$(echo $(/usr/bin/find /dev/ -name 'mmcb*') | sed -e 's@/dev/ /dev/@/dev/@g' | sed -e 's@ @|@g')" | grep "/media" | awk '{print $NF}' | sort -u | awk 'NR==1' `"
[ -z "$upanPath" ] && [ "$ss_opt_x" = "1" ] && upanPath="`df -m | grep /dev/sd | grep -E "$(echo $(/usr/bin/find /dev/ -name 'sd*') | sed -e 's@/dev/ /dev/@/dev/@g' | sed -e 's@ @|@g')" | grep "/media" | awk '{print $NF}' | sort -u | awk 'NR==1' `"
if [ "$ss_opt_x" = "5" ] ; then
	# 指定目录
	opt_cifs_dir=`nvram get opt_cifs_dir`
	if [ -d $opt_cifs_dir ] ; then
		upanPath="$opt_cifs_dir"
	else
		logger -t "【opt】" "错误！未找到指定目录 $opt_cifs_dir"
	fi
fi
if [ "$ss_opt_x" = "6" ] ; then
	opt_cifs_2_dir=`nvram get opt_cifs_2_dir`
	# 远程共享
	if mountpoint -q "$opt_cifs_2_dir" && [ -d "$opt_cifs_2_dir" ] ; then
		upanPath="$opt_cifs_2_dir"
	else
		logger -t "【opt】" "错误！未找到指定远程共享目录 $opt_cifs_2_dir"
	fi
fi
echo "$upanPath"
if [ -z "$upanPath" ] ; then 
	logger -t "【相框显示】" "未挂载储存设备, 请重新检查配置、目录，10 秒后自动尝试重新启动"
	sleep 10
	display_restart x
	exit 0
fi

cp -f /etc/storage/display_lcd4linux_script.sh /tmp/lcd4linux.conf
SVC_PATH=/opt/bin/lcd4linux
chmod 777 "$SVC_PATH"
if [ ! -s "$SVC_PATH" ] ; then
	logger -t "【相框显示】" "找不到 $SVC_PATH，安装 opt full 程序"
	/etc/storage/script/Sh01_mountopt.sh opt_full_wget
fi
[[ "$(lcd4linux -h 2>&1 | wc -l)" -lt 2 ]] && /etc/storage/script/Sh01_mountopt.sh libmd5_check
if [ ! -s "$SVC_PATH" ] ; then
	logger -t "【相框显示】" "找不到 $SVC_PATH ，需要手动安装 $SVC_PATH"
	logger -t "【相框显示】" "启动失败, 10 秒后自动尝试重新启动" && sleep 10 && display_restart x
fi
if [ ! -s "/opt/lcd4linux/lcd4linux.conf" ] || [ ! -s "/opt/lcd4linux/scripts/drawchart2.py" ] ; then
	lcd1="$hiboyfile/lcd2.tgz"
	logger -t "【相框显示】" "下载LCD文件 $lcd1"
	wgetcurl.sh "/opt/lcd.tgz" "$hiboyfile/lcd2.tgz" "$hiboyfile2/lcd2.tgz"
	untar.sh "/opt/lcd.tgz" "/opt/" "/opt/bin/lcd4linux"
	cp -f /opt/lcd4linux/lcd4linux.conf /etc/storage/display_lcd4linux_script.sh
fi
if [ ! -s "/etc/storage/display_lcd4linux_script.sh" ] ; then
	cp -f /opt/lcd4linux/lcd4linux.conf /etc/storage/display_lcd4linux_script.sh
fi
if [ ! -s "/etc/storage/display_lcd4linux_script.sh" ] ; then
	logger -t "【相框显示】" "缺少 /etc/storage/display_lcd4linux_script.sh 文件, 启动失败"
	logger -t "【相框显示】" "停止程序, 10 秒后自动尝试重新启动" && sleep 10 && display_restart x
fi
# 修改显示空间
ss_opt_x=`nvram get ss_opt_x`
upanPath=""
[ "$ss_opt_x" = "3" ] && upanPath="`df -m | grep /dev/mmcb | grep -E "$(echo $(/usr/bin/find /dev/ -name 'mmcb*') | sed -e 's@/dev/ /dev/@/dev/@g' | sed -e 's@ @|@g')" | grep "/media" | awk '{print $NF}' | sort -u | awk 'NR==1' `"
[ "$ss_opt_x" = "4" ] && upanPath="`df -m | grep /dev/sd | grep -E "$(echo $(/usr/bin/find /dev/ -name 'sd*') | sed -e 's@/dev/ /dev/@/dev/@g' | sed -e 's@ @|@g')" | grep "/media" | awk '{print $NF}' | sort -u | awk 'NR==1' `"
[ -z "$upanPath" ] && [ "$ss_opt_x" = "1" ] && upanPath="`df -m | grep /dev/mmcb | grep -E "$(echo $(/usr/bin/find /dev/ -name 'mmcb*') | sed -e 's@/dev/ /dev/@/dev/@g' | sed -e 's@ @|@g')" | grep "/media" | awk '{print $NF}' | sort -u | awk 'NR==1' `"
[ -z "$upanPath" ] && [ "$ss_opt_x" = "1" ] && upanPath="`df -m | grep /dev/sd | grep -E "$(echo $(/usr/bin/find /dev/ -name 'sd*') | sed -e 's@/dev/ /dev/@/dev/@g' | sed -e 's@ @|@g')" | grep "/media" | awk '{print $NF}' | sort -u | awk 'NR==1' `"
if [ "$ss_opt_x" = "5" ] ; then
	# 指定目录
	opt_cifs_dir=`nvram get opt_cifs_dir`
	if [ -d $opt_cifs_dir ] ; then
		upanPath="$opt_cifs_dir"
	else
		logger -t "【opt】" "错误！未找到指定目录 $opt_cifs_dir"
	fi
fi
if [ "$ss_opt_x" = "6" ] ; then
	opt_cifs_2_dir=`nvram get opt_cifs_2_dir`
	# 远程共享
	if mountpoint -q "$opt_cifs_2_dir" && [ -d "$opt_cifs_2_dir" ] ; then
		upanPath="$opt_cifs_2_dir"
	else
		logger -t "【opt】" "错误！未找到指定远程共享目录 $opt_cifs_2_dir"
	fi
fi
echo "$upanPath"
if [ ! -z "$upanPath" ] ; then
	upanPath2="SpaceDir  \'\/media\/$upanPath\' #显示空间"
else
	upanPath2="SpaceDir  \'\/tmp\' #显示空间"
fi

sed -e "s/SpaceDir\ \ .*/$upanPath2/" -i /etc/storage/display_lcd4linux_script.sh
cp -f /etc/storage/display_lcd4linux_script.sh /tmp/lcd4linux.conf
chmod 600 /tmp/lcd4linux.conf
chmod 777 /opt/bin/lcd4linux
sleep 5
logger -t "【相框显示】" "运行 lcd4linux"
cd /opt/bin/
export LD_LIBRARY_PATH=/opt/lib
eval "lcd4linux -f /tmp/lcd4linux.conf $cmd_log" &
export LD_LIBRARY_PATH=/lib:/opt/lib
logger -t "【相框显示】" "开始显示数据"
sleep 4
i_app_keep -t -name="display" -pidof="lcd4linux"
initopt
display_get_status
eval "$scriptfilepath keep &"
exit 0
}

getweather () {

# 天气数据下载失败，停止获取
return 
mkdir -p /opt/lcd4linux/tmp/
#http://weather.yahoo.com/2146704
#The location parameter needs to be a WOEID. 
#To find your WOEID, browse or search for your city from the Weather home page. 
#The WOEID is in the URL for the forecast page for that city. You can also get 
#the WOEID by entering your zip code on the home page. For example, if you search 
#for Los Angeles on the Weather home page, the forecast page for that city is 
#http://weather.yahoo.com/united-states/california/los-angeles-2146704/. 
#The WOEID is 2146704.
#changping2151334
#beijing 2151330

#wget -O /opt/lcd4linux/tmp/weather "http://xml.weather.yahoo.com/forecastrss?w=$display_weather&u=c"
#获取天气信息
yahooweb='https://query.yahooapis.com/v1/public/yql?q=SELECT%20*%20FROM%20weather.forecast%20WHERE%20woeid%3D"'$display_weather'"%20and%20u%3D"c"%20%7C%20truncate(count%3D1)&diagnostics=true&env=store%3A%2F%2Fdatatables.org%2Falltableswithkeys'
echo $yahooweb
rm -f /opt/lcd4linux/tmp/weatherweb
#wget -O /opt/lcd4linux/tmp/weatherweb $yahooweb
wgetcurl.sh /opt/lcd4linux/tmp/weatherweb "$yahooweb" "$yahooweb" N
if [ -s /opt/lcd4linux/tmp/weatherweb ] ; then
	cat /opt/lcd4linux/tmp/weatherweb | grep '<yweather' | awk -F'<yweather' '{ \
		{L1="<yweather"$3; L2="<yweather"$2; L3="<yweather"$4; L4="<yweather"$5; L5="<yweather"$6; L6="<yweather"$7; L7="<yweather"$8; L8="<yweather"$9}} \
		END \
		{ printf "%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n", \
		L1,L2,L3,L4,L5,L6,L7,L8}' \
		> /opt/lcd4linux/tmp/weather
	if [ ! -s /opt/lcd4linux/tmp/weather ] ; then
		logger -t "【相框显示】" "获取天气信息错误！请检查链接："
		logger -t "【相框显示】" "$yahooweb"
		return 1
	fi
	logger -t "【相框显示】" "获取天气信息"
	cat /opt/lcd4linux/tmp/weather | grep '<yweather' | awk -F'"' '{C1++;}{ \
		{if (substr($1, 11, 8)=="location") L1=$4} \
		{if (substr($1, 11, 4)=="wind") {L81=$4; L82=$6; L83=$8; \
		{if($6=="0") L84="N"} {if($6=="90") L84="E"} {if($6=="180") L84="S"} {if($6=="270") L84="W"} {if(("01"<$6)&&($6<90)) L84="EN"} {if(("90"<$6)&&($6<180)) L84="ES"} {if(("180"<$6)&&($6<"270")) L84="WS"} {if(("270"<$6)&&($6<"360")) L84="WN"}}} \
		{if (substr($1, 11, 10)=="atmosphere") { L91=$4; L92=$10; L93=$6; \
		{if($8=="0") L94="S"} {if($8=="1") L94="R"} {if($8=="2") L94="F"}}} \
		{if (substr($1, 11, 9)=="astronomy") {LA1=$4; LA2=$6}} \
		{if (substr($1, 11, 9)=="condition") {L2=$4; L3=$8"c"}} \
		{if (substr($1, 11, 8)=="forecast") {if (C1==7) {L4=$4;L5=$12"cdu"$10"c"}}} \
		{if (substr($1, 11, 8)=="forecast") {if (C1==8) {L6=$4;L7=$12"cdu"$10"c"}}}} \
		END \
		{ while (length(L3) < 4) {L3="n"L3}; while (length(L5) < 10) {L5="n"L5}; while (length(L7) < 10) {L7="n"L7}; \
		i=index(LA1,":");Xss=substr(LA1,0,1) substr(LA1, i+1, 2); \
		i=index(LA2,":");Xse=substr(LA2,0,1) substr(LA2, i+1, 2); \
		printf "%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\042\040%s\n%skm/h\n%s%%\n%skm\n%smb\n%s\n%s\n%s\n%s\n%s\n", \
		L1,L2,L3,L4,L5,L6,L7,L81,L82,L84,L83,L91,L92,L93,L94,LA1,LA2,Xss,Xse}' \
                > /opt/lcd4linux/data/weather
	cat /opt/lcd4linux/tmp/weather | grep '<lastBuildDate>' | awk -F'<lastBuildDate>' '{ \
		{L1=(substr($2, 6, 20))}} \
		END \
		{ printf "%s\n", \
		L1}' \
		>> /opt/lcd4linux/data/weather
fi

}

getaqidata () {

mkdir -p /opt/lcd4linux/tmp/
#获取AQI数据和数据绘图。http://www.aqicn.org
rm -f /opt/lcd4linux/tmp/aqicn
aqicnorg="http://feed.aqicn.org/feed/$display_aqidata/en/feed.v1.json"
#wget -c -O /opt/lcd4linux/tmp/aqicn "http://feed.aqicn.org/feed/$display_aqidata/en/feed.v1.json" --user-agent "$user_agent"
wgetcurl.sh /opt/lcd4linux/tmp/aqicn "$aqicnorg" "$aqicnorg" N
if [ ! -s /opt/lcd4linux/tmp/aqicn ] ; then
	logger -t "【相框显示】" "获取AQI数据错误！请检查链接："
	logger -t "【相框显示】" "$aqicnorg"
	return 1
fi
logger -t "【相框显示】" "获取AQI数据和数据绘图"

timeh=`date +%H`
mkdir -p /opt/lcd4linux/tmp/aqii
#记录小于24个需要补零
touch /opt/lcd4linux/tmp/aqii/apm25
FFS=`cat /opt/lcd4linux/tmp/aqii/apm25 |grep ";" |awk -F "" '{for(i=1;i<=NF;++i) if($i==";") ++sum}END{print sum}'`
if [ "$FFS" -lt 24 ] || [ ! -s /opt/lcd4linux/tmp/aqii/apm25 ] ; then
echo -ne ";;;;;;;;;;;;;;;;;;;;;;;;"> /opt/lcd4linux/tmp/aqii/apm25
fi
touch /opt/lcd4linux/tmp/aqii/apm10
FFS=`cat /opt/lcd4linux/tmp/aqii/apm10 |grep ";" |awk -F "" '{for(i=1;i<=NF;++i) if($i==";") ++sum}END{print sum}'`
if [ "$FFS" -lt 24 ] || [ ! -s /opt/lcd4linux/tmp/aqii/apm10 ] ; then
echo -ne ";;;;;;;;;;;;;;;;;;;;;;;;"> /opt/lcd4linux/tmp/aqii/apm10
fi
touch /opt/lcd4linux/tmp/aqii/aso2
FFS=`cat /opt/lcd4linux/tmp/aqii/aso2 |grep ";" |awk -F "" '{for(i=1;i<=NF;++i) if($i==";") ++sum}END{print sum}'`
if [ "$FFS" -lt 24 ] || [ ! -s /opt/lcd4linux/tmp/aqii/aso2 ] ; then
echo -ne ";;;;;;;;;;;;;;;;;;;;;;;;"> /opt/lcd4linux/tmp/aqii/aso2
fi
touch /opt/lcd4linux/tmp/aqii/ano2
FFS=`cat /opt/lcd4linux/tmp/aqii/ano2 |grep ";" |awk -F "" '{for(i=1;i<=NF;++i) if($i==";") ++sum}END{print sum}'`
if [ "$FFS" -lt 24 ] || [ ! -s /opt/lcd4linux/tmp/aqii/ano2 ] ; then
echo -ne ";;;;;;;;;;;;;;;;;;;;;;;;"> /opt/lcd4linux/tmp/aqii/ano2
fi
touch /opt/lcd4linux/tmp/aqii/ao3
FFS=`cat /opt/lcd4linux/tmp/aqii/ao3 |grep ";" |awk -F "" '{for(i=1;i<=NF;++i) if($i==";") ++sum}END{print sum}'`
if [ "$FFS" -lt 24 ] || [ ! -s /opt/lcd4linux/tmp/aqii/ao3 ] ; then
echo -ne ";;;;;;;;;;;;;;;;;;;;;;;;"> /opt/lcd4linux/tmp/aqii/ao3
fi
touch /opt/lcd4linux/tmp/aqii/aco
FFS=`cat /opt/lcd4linux/tmp/aqii/aco |grep ";" |awk -F "" '{for(i=1;i<=NF;++i) if($i==";") ++sum}END{print sum}'`
if [ "$FFS" -lt 24 ] || [ ! -s /opt/lcd4linux/tmp/aqii/aco ] ; then
echo -ne ";;;;;;;;;;;;;;;;;;;;;;;;"> /opt/lcd4linux/tmp/aqii/aco
fi
touch /opt/lcd4linux/tmp/aqii/atime
FFS=`cat /opt/lcd4linux/tmp/aqii/atime |grep ";" |awk -F "" '{for(i=1;i<=NF;++i) if($i==";") ++sum}END{print sum}'`
if [ "$FFS" -lt 24 ] || [ ! -s /opt/lcd4linux/tmp/aqii/atime ] ; then
echo -ne ";;;;;;;;;;;;;;;;;;;;;;;;"> /opt/lcd4linux/tmp/aqii/atime
fi

#pm25
aqicn=`cat /opt/lcd4linux/tmp/aqicn`
aqicn=`echo ${aqicn#*pm25\"\:\{\"val\"\:}`
#重新构建AQI记录
echo -ne ${aqicn%%,\"date*}";">> /opt/lcd4linux/tmp/aqii/apm25;
FFS=`cat /opt/lcd4linux/tmp/aqii/apm25 |grep ";" |awk -F "" '{for(i=1;i<=NF;++i) if($i==";") ++sum}END{print sum}'`
if [ "$FFS" -gt 25 ] ; then
#大于24个记录时删除旧记录
aqicn=`cat /opt/lcd4linux/tmp/aqii/apm25`
echo ${aqicn#*;}> /opt/lcd4linux/tmp/aqii/apm25
fi
sed -Ei s/[[:space:]]//g /opt/lcd4linux/tmp/aqii/apm25
#pm10
aqicn=`cat /opt/lcd4linux/tmp/aqicn`
aqicn=`echo ${aqicn#*pm10\"\:\{\"val\"\:}`
#重新构建AQI记录
echo -ne ${aqicn%%,\"date*}";" >> /opt/lcd4linux/tmp/aqii/apm10;
FFS=`cat /opt/lcd4linux/tmp/aqii/apm10 |grep ";" |awk -F "" '{for(i=1;i<=NF;++i) if($i==";") ++sum}END{print sum}'`
if [ "$FFS" -gt 25 ] ; then
#大于24个记录时删除旧记录
aqicn=`cat /opt/lcd4linux/tmp/aqii/apm10`
echo ${aqicn#*;} > /opt/lcd4linux/tmp/aqii/apm10
fi
sed -Ei s/[[:space:]]//g /opt/lcd4linux/tmp/aqii/apm10
#so2
aqicn=`cat /opt/lcd4linux/tmp/aqicn`
aqicn=`echo ${aqicn#*so2\"\:\{\"val\"\:}`
#重新构建AQI记录
echo -ne ${aqicn%%,\"date*}";" >> /opt/lcd4linux/tmp/aqii/aso2;
FFS=`cat /opt/lcd4linux/tmp/aqii/aso2 |grep ";" |awk -F "" '{for(i=1;i<=NF;++i) if($i==";") ++sum}END{print sum}'`
if [ "$FFS" -gt 25 ] ; then
#大于24个记录时删除旧记录
aqicn=`cat /opt/lcd4linux/tmp/aqii/aso2`
echo ${aqicn#*;} > /opt/lcd4linux/tmp/aqii/aso2
fi
sed -Ei s/[[:space:]]//g /opt/lcd4linux/tmp/aqii/aso2
#no2
aqicn=`cat /opt/lcd4linux/tmp/aqicn`
aqicn=`echo ${aqicn#*no2\"\:\{\"val\"\:}`
#重新构建AQI记录
echo -ne ${aqicn%%,\"date*}";" >> /opt/lcd4linux/tmp/aqii/ano2;
FFS=`cat /opt/lcd4linux/tmp/aqii/ano2 |grep ";" |awk -F "" '{for(i=1;i<=NF;++i) if($i==";") ++sum}END{print sum}'`
if [ "$FFS" -gt 25 ] ; then
#大于24个记录时删除旧记录
aqicn=`cat /opt/lcd4linux/tmp/aqii/ano2`
echo ${aqicn#*;} > /opt/lcd4linux/tmp/aqii/ano2
fi
sed -Ei s/[[:space:]]//g /opt/lcd4linux/tmp/aqii/ano2
#o3
aqicn=`cat /opt/lcd4linux/tmp/aqicn`
aqicn=`echo ${aqicn#*o3\"\:\{\"val\"\:}`
#重新构建AQI记录
echo -ne ${aqicn%%,\"date*}";" >> /opt/lcd4linux/tmp/aqii/ao3;
FFS=`cat /opt/lcd4linux/tmp/aqii/ao3 |grep ";" |awk -F "" '{for(i=1;i<=NF;++i) if($i==";") ++sum}END{print sum}'`
if [ "$FFS" -gt 25 ] ; then
#大于24个记录时删除旧记录
aqicn=`cat /opt/lcd4linux/tmp/aqii/ao3`
echo ${aqicn#*;} > /opt/lcd4linux/tmp/aqii/ao3
fi
sed -Ei s/[[:space:]]//g /opt/lcd4linux/tmp/aqii/ao3
#co
aqicn=`cat /opt/lcd4linux/tmp/aqicn`
aqicn=`echo ${aqicn#*co\"\:\{\"val\"\:}`
#重新构建AQI记录
echo -ne ${aqicn%%,\"date*}";" >> /opt/lcd4linux/tmp/aqii/aco;
FFS=`cat /opt/lcd4linux/tmp/aqii/aco |grep ";" |awk -F "" '{for(i=1;i<=NF;++i) if($i==";") ++sum}END{print sum}'`
if [ "$FFS" -gt 25 ] ; then
#大于24个记录时删除旧记录
aqicn=`cat /opt/lcd4linux/tmp/aqii/aco`
echo ${aqicn#*;} > /opt/lcd4linux/tmp/aqii/aco
fi
sed -Ei s/[[:space:]]//g /opt/lcd4linux/tmp/aqii/aco
#tmie
aqicn="`date "+%Y-%m-%d %H:%M:%S"`"
#重新构建AQI记录
echo -ne $aqicn";" >> /opt/lcd4linux/tmp/aqii/atime;
FFS=`cat /opt/lcd4linux/tmp/aqii/atime |grep ";" |awk -F "" '{for(i=1;i<=NF;++i) if($i==";") ++sum}END{print sum}'`
if [ "$FFS" -gt 25 ] ; then
#大于24个记录时删除旧记录
aqicn=`cat /opt/lcd4linux/tmp/aqii/atime`
echo ${aqicn#*;} > /opt/lcd4linux/tmp/aqii/atime
fi
sed -Ei s/[[:space:]]/-/g /opt/lcd4linux/tmp/aqii/atime
#生成数据
cat /opt/lcd4linux/tmp/aqii/apm25  > /opt/lcd4linux/tmp/aqi
echo "" >> /opt/lcd4linux/tmp/aqi
cat /opt/lcd4linux/tmp/aqii/apm10  >> /opt/lcd4linux/tmp/aqi
echo "" >> /opt/lcd4linux/tmp/aqi
cat /opt/lcd4linux/tmp/aqii/aso2  >> /opt/lcd4linux/tmp/aqi
echo "" >> /opt/lcd4linux/tmp/aqi
cat /opt/lcd4linux/tmp/aqii/ano2  >> /opt/lcd4linux/tmp/aqi
echo "" >> /opt/lcd4linux/tmp/aqi
cat /opt/lcd4linux/tmp/aqii/ao3  >> /opt/lcd4linux/tmp/aqi
echo "" >> /opt/lcd4linux/tmp/aqi
cat /opt/lcd4linux/tmp/aqii/aco  >> /opt/lcd4linux/tmp/aqi
echo "" >> /opt/lcd4linux/tmp/aqi
cat /opt/lcd4linux/tmp/aqii/atime  >> /opt/lcd4linux/tmp/aqi
echo "" >> /opt/lcd4linux/tmp/atime


#分类污染物24小时数据获取并计算出AQI和相应颜色数据写入到指定文件中供显示和绘图；

#aqicn.org直接获取AQI指数，不用计算

cat /opt/lcd4linux/tmp/aqi| awk -F";" '{for (i=2;i<=NF;i++) \
{ \
  {if (NR==1) AQIpm25[i-2]=$i+0}  \
  {if (NR==2) AQIpm10[i-2]=$i+0}  \
  {if (NR==3) AQIso2[i-2]=$i+0}  \
  {if (NR==4) AQIno2[i-2]=$i+0}  \
  {if (NR==5) AQIo3[i-2]=$i+0}  \
  {if (NR==6) AQIco[i-2]=$i+0}}  \
 } END { \
  {if (AQIpm25[23]==0) AQIpm25[23]=AQIpm25[22]} \
  {if (AQIpm10[23]==0) AQIpm10[23]=AQIpm10[22]} \
  {if (AQIso2[23]==0) AQIso2[23]=AQIso2[22]} \
  {if (AQIo3[23]==0) AQIo3[23]=AQIo3[22]} \
  {if (AQIno2[23]==0) AQIno2[23]=AQIno2[22]} \
  {if (AQIco[23]==0) AQIco[23]=AQIco[22]} \
  {for (i=0;i<=23;i++) { \
    sMain="pm25";cAQI=AQIpm25[i];\
    if (cAQI<AQIpm10[i]) {sMain="pm10";cAQI=AQIpm10[i];}; \
    if (cAQI<AQIso2[i]) {sMain="so2";cAQI=AQIso2[i];}; \
    if (cAQI<AQIno2[i]) {sMain="no2";cAQI=AQIno2[i];}; \
    if (cAQI<AQIo3[i]) {sMain="o3";cAQI=AQIo3[i];}; \
    if (cAQI<AQIco[i]) {sMain="co";cAQI=AQIco[i];}; \
    cAqi[i]=cAQI;cR=0;cG=0;cB=0;cAqi[i]=cAqi[i]+0;\
    if (cAQI<50) {aLevel=1;cR=255/50*cAQI;cG=228+(255-228)/50*cAQI;cB=0} \
    else if (cAQI<100) {aLevel=2;cR=255;cG=255-(255-126)/50*(cAQI-50);cB=0} \
    else if (cAQI<150) {aLevel=3;cR=255;cG=126-126/50*(cAQI-100);cB=0} \
    else if (cAQI<200) {aLevel=4;cR=255-(255-153)/50*(cAQI-150);cG=0;cB=76/100*(cAQI-150)} \
    else if (cAQI<300) {aLevel=5;cR=153-(153-126)/100*(cAQI-200);cG=0;cB=76-(76-35)/100*(cAQI-200)} \
    else {aLevel=6;cR=126-(126-90)/300*(cAQI-300);cG=0;cB=35-(35-15)/300*(cAQI-300)}; \
    rColor[i]=cR;gColor[i]=cG;bColor[i]=cB;\
    } \
  } \
{aAqi=sprintf("%d",cAQI); while (length(aAqi) < 3) {aAqi="n"aAqi}; \
  printf "%s\n%s\n%d\n",sMain,aAqi,aLevel; \
  for (i=0;i<=23;i++) printf "%d\n",cAqi[i]; \
  for (i=0;i<=23;i++) printf "%d,%d,%d,\n",rColor[i],gColor[i],bColor[i]; } \
}' >/opt/lcd4linux/data/aqi



#python绘图
python /opt/lcd4linux/scripts/drawchart2.py &

}

case $ACTION in
start)
	display_close
	display_check
	;;
check)
	display_check
	;;
stop)
	display_close
	;;
keep)
	#display_check
	display_keep
	;;
getweather)
	getweather
	;;
getaqidata)
	getaqidata
	;;
redisplay)
	display_restart o
	display_restart
	;;
*)
	display_check
	;;
esac

