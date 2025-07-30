#!/bin/bash
#copyright by hiboy
source /etc/storage/script/init.sh
mentohust_enable=`nvram get mentohust_enable`
[ -z $mentohust_enable ] && mentohust_enable=0 && nvram set mentohust_enable=0
if [ "$mentohust_enable" != "0" ] ; then
mentohust_path=`nvram get mentohust_path`
[ -z $mentohust_path ] && mentohust_path="/usr/bin/mentohust" && nvram set mentohust_path=$mentohust_path
mentohust_n="$(nvram get mentohust_n)"
[ "$mentohust_n" = "0" ] && mentohust_n="$(nvram get wan0_ifname_t)" && nvram set mentohust_n=$mentohust_n
[ -z $mentohust_n ] && mentohust_n="$(nvram get wan0_ifname_t)" && nvram set mentohust_n=$mentohust_n
mentohust_i=`nvram get mentohust_i`
[ -z $mentohust_i ] && mentohust_i="0.0.0.0" && nvram set mentohust_i=$mentohust_i
mentohust_m=`nvram get mentohust_m`
[ -z $mentohust_m ] && mentohust_m=$(nvram get lan_netmask) && nvram set mentohust_m=$mentohust_m
mentohust_g=`nvram get mentohust_g`
[ -z $mentohust_g ] && mentohust_g="0.0.0.0" && nvram set mentohust_g=$mentohust_g
mentohust_s=`nvram get mentohust_s`
[ -z $mentohust_s ] && mentohust_s="0.0.0.0" && nvram set mentohust_s=$mentohust_s
mentohust_o=`nvram get mentohust_o`
[ -z $mentohust_o ] && mentohust_o="0.0.0.0" && nvram set mentohust_o=$mentohust_o
mentohust_t=`nvram get mentohust_t`
[ -z $mentohust_t ] && mentohust_t="8" && nvram set mentohust_t=$mentohust_t
mentohust_e=`nvram get mentohust_e`
[ -z $mentohust_e ] && mentohust_e="30" && nvram set mentohust_e=$mentohust_e
mentohust_r=`nvram get mentohust_r`
[ -z $mentohust_r ] && mentohust_r="15" && nvram set mentohust_r=$mentohust_r
mentohust_l=`nvram get mentohust_l`
[ -z $mentohust_l ] && mentohust_l="8" && nvram set mentohust_l=$mentohust_l
mentohust_a=`nvram get mentohust_a`
[ -z $mentohust_a ] && mentohust_a="0" && nvram set mentohust_a=$mentohust_a
mentohust_d=`nvram get mentohust_d`
[ -z $mentohust_d ] && mentohust_d="0" && nvram set mentohust_d=$mentohust_d
mentohust_b=`nvram get mentohust_b`
[ -z $mentohust_b ] && mentohust_b="0" && nvram set mentohust_b=$mentohust_b
mentohust_v=`nvram get mentohust_v`
[ -z $mentohust_v ] && mentohust_v="0.00" && nvram set mentohust_v=$mentohust_v
mentohust_c=`nvram get mentohust_c`
[ -z $mentohust_c ] && mentohust_c="dhclinet" && nvram set mentohust_c=$mentohust_c
mentohust_f=`nvram get mentohust_f`
mentohust_u=`nvram get mentohust_u`
mentohust_p=`nvram get mentohust_p`
mentohust_mode=`nvram get mentohust_mode`
mentohust_renum=`nvram get mentohust_renum`
mentohust_renum=${mentohust_renum:-"0"}
cmd_log_enable=`nvram get cmd_log_enable`
cmd_name="MentoHUST"
cmd_log=""
if [ "$cmd_log_enable" = "1" ] || [ "$mentohust_renum" -gt "0" ] ; then
	cmd_log="$cmd_log2"
fi
fi

if [ ! -z "$(echo $scriptfilepath | grep -v "/tmp/script/" | grep mento_hust)" ] && [ ! -s /tmp/script/_mento_hust ] ; then
	mkdir -p /tmp/script
	{ echo '#!/bin/bash' ; echo $scriptfilepath '"$@"' '&' ; } > /tmp/script/_mento_hust
	chmod 777 /tmp/script/_mento_hust
fi

mentohust_restart () {
i_app_restart "$@" -name="mentohust"
}

mentohust_get_status () {

B_restart="$mentohust_enable$mentohust_path$mentohust_u$mentohust_p$mentohust_n$mentohust_i$mentohust_m$mentohust_g$mentohust_s$mentohust_o$mentohust_t$mentohust_e$mentohust_r$mentohust_a$mentohust_d$mentohust_b$mentohust_v$mentohust_f$mentohust_c$mentohust_mode"

i_app_get_status -name="mentohust" -valb="$B_restart"
}

mentohust_check () {

mentohust_get_status
if [ "$mentohust_enable" != "1" ] && [ "$needed_restart" = "1" ] ; then
	[ ! -z "`pidof mentohust`" ] && logger -t "【MentoHUST】" "停止 mentohust" && mentohust_close
	{ kill_ps "$scriptname" exit0; exit 0; }
fi
if [ "$mentohust_enable" = "1" ] ; then
	if [ "$needed_restart" = "1" ] ; then
		#配置有变，重新生成
		rm -f /etc/storage/mentohust.conf
		mentohust_close
		mentohust_start
	else
		[ -z "`pidof mentohust`" ] && mentohust_restart
	fi
fi
}

mentohust_keep () {
i_app_keep -t -name="mentohust" -pidof="$(basename $mentohust_path)" -cpath="$mentohust_path"
i_app_keep -name="mentohust" -pidof="$(basename $mentohust_path)" -cpath="$mentohust_path" &
}

mentohust_close () {
kill_ps "$scriptname keep"
sed -Ei '/【mentohust】|^$/d' /tmp/script/_opt_script_check
killall mentohust
kill_ps "/tmp/script/_mento_hust"
kill_ps "_mento_hust.sh"
kill_ps "$scriptname"
}

mentohust_start () {

#check_webui_yes
i_app_get_cmd_file -name="mentohust" -cmd="$mentohust_path" -cpath="/opt/bin/mentohust" -down1="$hiboyfile/mentohust" -down2="$hiboyfile2/mentohust"
[ -s "$SVC_PATH" ] && [ "$(nvram get mentohust_path)" != "$SVC_PATH" ] && nvram set mentohust_path="$SVC_PATH"
mentohust_path="$SVC_PATH"

logger -t "【MentoHUST】" "运行 $mentohust_path"

#保存配置到文件
if [ ! -f "/etc/storage/mentohust.conf" ] ; then
	$mentohust_path -u$mentohust_u -p$mentohust_p -n$mentohust_n -i$mentohust_i -m$mentohust_m -g$mentohust_g -s$mentohust_s -o$mentohust_o -t$mentohust_t -e$mentohust_e -r$mentohust_r -l$mentohust_l -a$mentohust_a -d$mentohust_d -b$mentohust_b -v$mentohust_v -f$mentohust_f  -c$mentohust_c -w 
	sleep 2
	pids=$(pidof process) && killall process
fi
mentohust_mode=`nvram get mentohust_mode`
if [ "$mentohust_mode" = "0" ] ; then
logger -t "【MentoHUST】" "标准模式"
	eval "$mentohust_path $cmd_log" &
elif [ "$mentohust_mode" = "1" ] ; then
logger -t "【MentoHUST】" "锐捷模式"
	eval "$mentohust_path  -y $cmd_log" &
elif [ "$mentohust_mode" = "2" ] ; then
logger -t "【MentoHUST】" "赛尔模式"
	eval "$mentohust_path -s8.8.8.8 $cmd_log" &
fi
sleep 4
#restart_firewall
#mentohust_get_status
eval "$scriptfilepath keep &"
exit 0
}

case $ACTION in
start)
	mentohust_close
	mentohust_check
	;;
check)
	mentohust_check
	;;
stop)
	mentohust_close
	;;
keep)
	#mentohust_check
	mentohust_keep
	;;
*)
	mentohust_check
	;;
esac

