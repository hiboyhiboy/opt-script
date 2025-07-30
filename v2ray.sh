#!/bin/bash
# https://github.com/v2ray/v2ray-core/releases
# https://github.com/v2fly/v2ray-core/releases
export PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
#version=v4.34.0

[ ! -z "$( alias | grep 'alias cp=')" ] &&  unalias cp
[ ! -z "$( alias | grep 'alias mv=')" ] &&  unalias mv
[ ! -z "$( alias | grep 'alias rm=')" ] &&  unalias rm

SYSTEMCTL_CMD=$(command -v systemctl)
SERVICE_CMD=$(command -v service)

#Check Root
[ $(id -u) != "0" ] && { echo "${CFAILURE}Error: You must be root to run this script${CEND}"; exit 1; }

#Check OS
if [ -f /etc/redhat-release ];then
		OS='CentOS'
	elif [ ! -z "`cat /etc/issue | grep bian`" ];then
		OS='Debian'
	elif [ ! -z "`cat /etc/issue | grep Ubuntu`" ];then
		OS='Ubuntu'
	elif [ ! -z "`cat /etc/issue | grep CentOS`" ];then
		OS='CentOS'
	else
		echo "Not support OS, Please reinstall OS and retry!"
		exit 1
fi


# Get Public IP address
ipc=$(ip addr | egrep -o '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | egrep -v "^192\.168|^172\.1[6-9]\.|^172\.2[0-9]\.|^172\.3[0-2]\.|^10\.|^127\.|^255\.|^0\." | head -n 1)
if [[ "$IP" = "" ]]; then
	ipc=$(wget -qO- -t1 -T2 ipv4.icanhazip.com)
fi

uuid=$(cat /proc/sys/kernel/random/uuid)

function Install(){
#Install Basic Packages
echo '安装基本软件包，请稍候！​'
if [[ ${OS} == 'CentOS' ]];then
	yum install curl wget unzip ntp ntpdate -y
else
	apt-get update
	apt-get install curl unzip ntp wget ntpdate -y
fi

#Set DNS
echo "nameserver 8.8.8.8" > /etc/resolv.conf
echo "nameserver 8.8.4.4" >> /etc/resolv.conf


#Update NTP settings
rm -rf /etc/localtime
ln -s /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
ntpdate us.pool.ntp.org

#Disable SELinux
if [ -s /etc/selinux/config ] && grep 'SELINUX=enforcing' /etc/selinux/config; then
	sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
	setenforce 0
fi

#Run Install
cd /root

curl -L  -k https://opt.cn2qq.com/opt-script/go.sh > /root/go.sh 
if [ ! -s /root/go.sh ]; then
	rm -f /root/go.sh
	wget --no-check-certificate https://opt.cn2qq.com/opt-script/go.sh
fi
chmod +x "/root/go.sh"
echo "V2Ray 安装 $version"
/root/go.sh # --version $version
rm -f /root/v2ray_server_json
ln -sf /etc/v2ray /root/v2ray_server_json
echo "安装完成"

}

function remove_v2ray(){
echo '删除 V2ray 请稍候！'

cd /root

curl -L  -k https://opt.cn2qq.com/opt-script/go.sh > /root/go.sh 
if [ ! -s /root/go.sh ]; then
	rm -f /root/go.sh
	wget --no-check-certificate https://opt.cn2qq.com/opt-script/go.sh
fi
chmod +x "/root/go.sh"
/root/go.sh --remove

echo '删除 V2ray 完成！'

}

function up_v2ray(){

if [ -n "${SYSTEMCTL_CMD}" ] && [ -f "/lib/systemd/system/v2ray.service" ] || [ -f "/etc/systemd/system/v2ray.service" ]; then
	killall keey.sh
	${SYSTEMCTL_CMD} stop v2ray
	systemctl disable v2ray.service
fi
if [ -n "${SERVICE_CMD}" ] && [ -f "/etc/init.d/v2ray" ]; then
	killall keey.sh
	${SERVICE_CMD} v2ray stop
fi

curl -L -s -k https://opt.cn2qq.com/opt-script/go.sh > /root/go.sh 
if [ ! -s /root/go.sh ]; then
	rm -f /root/go.sh
	wget --no-check-certificate https://opt.cn2qq.com/opt-script/go.sh
fi
chmod +x "/root/go.sh"
echo "V2Ray 安装 $version"
/root/go.sh # --version $version
echo "安装完成"
ntpdate us.pool.ntp.org &
if [ -f "/etc/v2ray/config.back0" ]; then
	cp -f /etc/v2ray/config.back0 /etc/v2ray/config.json
	if [ -n "${SYSTEMCTL_CMD}" ] && [ -f "/lib/systemd/system/v2ray.service" ] || [ -f "/etc/systemd/system/v2ray.service" ]; then
		echo "Restarting V2Ray service."
		systemctl enable v2ray.service
		${SYSTEMCTL_CMD} start v2ray
	elif [ -n "${SERVICE_CMD}" ] && [ -f "/etc/init.d/v2ray" ]; then
		echo "Restarting V2Ray service."
		${SERVICE_CMD} v2ray start
	fi
	echo '##########################################################################'
	rm -f /root/v2ray_config.pb
	#/usr/bin/v2ray/v2ctl config < /root/config.json > /root/v2ray_config.pb
	#[ ! -z "$(cat /root/v2ray_config.pb | grep "v2ctl config config.json c1.json c2.json")" ] && /usr/bin/v2ray/v2ctl config /root/config.json > /root/v2ray_config.pb
	#[ -f /root/v2ray_config.pb ] && echo "已经生成 pb 配置文件 /root/v2ray_config.pb"
	echo '##########################################################################'
	exit
else
	echo "未完成配置生成，请继续配置"
fi
}

echo 'V2Ray 输入数字继续一键安装'
while :; do echo
	read -p "输入数字继续（【新安装或重新生成配置】请输入1，【更新V2Ray】请输入0，【删除V2Ray】请输入3）:" up_vv
	if [[ ! $up_vv =~ ^[0-1]$ ]]; then
		if [[ $up_vv == 3 ]]; then
			remove_v2ray
			exit
		fi
		echo "${CWARNING}输入错误! 请输入正确的数字!${CEND}"
	else
		break
	fi
done
echo ''
if [[ $up_vv == '0' ]];then
up_v2ray
fi
#clear
echo 'V2Ray 一键安装|配置脚本 Author：Kirito && 雨落无声'

echo ''
echo '此脚本会关闭iptables防火墙（可选项），切勿用于生产环境！'

while :; do echo
	read -p "输入用户等级（自用请输入1，共享请输入0）:" level
	if [[ ! $level =~ ^[0-1]$ ]]; then
		echo "${CWARNING}输入错误! 请输入正确的数字!${CEND}"
	else
		break
	fi
done

echo ''
SEED=`tr -cd 0-9 </dev/urandom | head -c 8`
mainport_x=`echo $SEED 31000 33000|awk '{srand($1);printf "%d",rand()*10000%($3-$2)+$2}'`
#32000

read -p "输入主要端口（默认：$mainport_x ）:" mainport
[ -z "$mainport" ] && mainport=$mainport_x

echo ''

read -p "是否启用HTTP伪装?（默认开启y） [y/n]:" ifhttpheader
[ -z "$ifhttpheader" ] && ifhttpheader='y'
if [[ $ifhttpheader == 'y' ]];then
	httpheader=',
    "streamSettings": {
      "sockopt": {
        "mark": 255
      },
      "network": "tcp",
      "tcpSettings": {
        "connectionReuse": true,
        "header": {
          "type": "http",
          "request": {
            "version": "1.1",
            "method": "GET",
            "path": ["/"],
            "headers": {
              "Host": ["www.163.com", "www.sogou.com"],
              "User-Agent": [
                "Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/74.0.3729.169 Safari/537.36",
                        "Mozilla/5.0 (iPhone; CPU iPhone OS 12_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/69.0.3497.91 Mobile/15E148 Safari/605.1"
              ],
              "Accept-Encoding": ["gzip, deflate"],
              "Connection": ["keep-alive"],
              "Pragma": "no-cache"
            }
          },
          "response": {
            "version": "1.1",
            "status": "200",
            "reason": "OK",
            "headers": {
              "Content-Type": ["application/octet-stream", "application/x-msdownload", "text/html", "application/x-shockwave-flash"],
              "Transfer-Encoding": ["chunked"],
              "Connection": ["keep-alive"],
              "Pragma": "no-cache"
            }
          }
        }
      }
    }'
else
	httpheader=',
    "streamSettings": {
      "sockopt": {
        "mark": 255
      }
    }'
	read -p "是否启用mKCP协议?（默认开启y） [y/n]:" ifmkcp
	[ -z "$ifmkcp" ] && ifmkcp='y'
	if [[ $ifmkcp == 'y' ]];then
		httpheader=''
		mkcp=',
    "streamSettings": {
      "sockopt": {
        "mark": 255
      },
      "network": "kcp"
    }'
	else
		mkcp=''
	fi
fi

echo ''

read -p "是否启用动态端口?（默认开启y） [y/n]:" ifdynamicport
[ -z "$ifdynamicport" ] && ifdynamicport='y'
if [[ $ifdynamicport == 'y' ]];then
	subport1_x=$(($mainport_x + 1))
	#32001
	read -p "输入数据端口起点（默认：$subport1_x ）:" subport1
	[ -z "$subport1" ] && subport1=$subport1_x

	subport2_x=$(($mainport_x + 1500))
	#32500
	read -p "输入数据端口终点（默认：$subport2_x ）:" subport2
	[ -z "$subport2" ] && subport2=$subport2_x

	SEED=`tr -cd 0-9 </dev/urandom | head -c 8`
	portnum_x=`echo $SEED 8 15|awk '{srand($1);printf "%d",rand()*10000%($3-$2)+$2}'`
	#10
	read -p "输入每次开放端口数（默认：$portnum_x ）:" portnum
	[ -z "$portnum" ] && portnum=$portnum_x

	SEED=`tr -cd 0-9 </dev/urandom | head -c 8`
	porttime_x=`echo $SEED 4 7|awk '{srand($1);printf "%d",rand()*10000%($3-$2)+$2}'`
	#5
	read -p "输入端口变更时间（单位：分钟）（默认：$porttime_x ）:" porttime
	[ -z "$porttime" ] && porttime=$porttime_x
	detour=",
    \"detour\": {
      \"to\": \"detour\"
    }"
	dynamicport=",{
    //inboundDetour
    \"protocol\": \"vmess\",
    \"port\": \"$subport1-$subport2\",
    \"tag\": \"detour\",
    \"settings\": {},
    \"allocate\": {
      \"strategy\": \"random\",
      \"concurrency\": $portnum,
      \"refresh\": $porttime
    }${mkcp}${httpheader}
  }"
else
	detour=''
	dynamicport=''
fi

echo ''

read -p "是否启用 Mux.Cool?（默认开启y） [y/n]:" ifmux
[ -z "$ifmux" ] && ifmux='y'
if [[ $ifmux == 'y' ]];then
	mux=',
    "mux": {
      "enabled": true
    }'
else
	mux=""
fi

while :; do echo
	echo '1. HTTP代理（默认1）'
	echo '2. Socks代理'
	read -p "请选择客户端代理类型: " chooseproxytype
	[ -z "$chooseproxytype" ] && chooseproxytype=1
	if [[ ! $chooseproxytype =~ ^[1-2]$ ]]; then
		echo '输入错误，请输入正确的数字！'
	else
		break
	fi
done

if [[ $chooseproxytype == 1 ]];then
  proxytype='http'
else
  proxytype='socks'
fi









#CheckIfInstalled
if [ ! -f "/usr/bin/v2ray/v2ray" ]; then
	Install
fi


read -p "是否关闭iptables防火墙?（默认关闭y） [y/n]:" ifoffiptables
[ -z "$ifoffiptables" ] && ifoffiptables='y'
if [[ $ifoffiptables == 'y' ]];then
	#Disable iptables
	iptables -P INPUT ACCEPT
	iptables -P FORWARD ACCEPT
	iptables -P OUTPUT ACCEPT
	iptables -F
else
	if [[ $ifdynamicport == 'y' ]];then
		#$subport1:$subport2
		iptables -I INPUT -p tcp --dport $subport1:$subport2 -j ACCEPT
		iptables -I FORWARD -p tcp --dport $subport1:$subport2 -j ACCEPT
		iptables -I OUTPUT -p tcp --dport $subport1:$subport2 -j ACCEPT
		iptables -I INPUT -p tcp --sport $subport1:$subport2 -j ACCEPT
		iptables -I FORWARD -p tcp --sport $subport1:$subport2 -j ACCEPT
		iptables -I OUTPUT -p tcp --sport $subport1:$subport2 -j ACCEPT
	fi
	if [ ! -z "$mainport" ];then
		#$mainport
		iptables -I INPUT -p tcp --dport $mainport -j ACCEPT
		iptables -I FORWARD -p tcp --dport $mainport -j ACCEPT
		iptables -I OUTPUT -p tcp --dport $mainport -j ACCEPT
		iptables -I INPUT -p tcp --sport $mainport -j ACCEPT
		iptables -I FORWARD -p tcp --sport $mainport -j ACCEPT
		iptables -I OUTPUT -p tcp --sport $mainport -j ACCEPT
	fi
fi

if [ -n "${SYSTEMCTL_CMD}" ] && [ -f "/lib/systemd/system/v2ray.service" ] || [ -f "/etc/systemd/system/v2ray.service" ]; then
	killall keey.sh
	${SYSTEMCTL_CMD} stop v2ray
	systemctl disable v2ray.service
fi
	if [ -n "${SERVICE_CMD}" ] && [ -f "/etc/init.d/v2ray" ]; then
	killall keey.sh
	${SERVICE_CMD} v2ray stop
fi
#Configure Server
#service v2ray stop
rm -rf config
cat << EOF > config
{"log" : {
    "error": "/var/log/v2ray/error.log",
    "loglevel": "warning"
  },
  "inbounds":[
  {
    "port": $mainport,
    "protocol": "vmess",
    "settings": {
        "clients": [
            {
                "id": "$uuid",
                "level": $level,
                "alterId": 32
            }
        ]
    }${mkcp}${httpheader}${detour}
  }${dynamicport}
  ],
  "outbounds":[
  {
    "protocol": "freedom",
    "settings": {}
  },{
  //outboundDetour
      "protocol": "blackhole",
      "settings": {},
      "tag": "blocked"
  }
  ],
  "routing": {
    "strategy": "rules",
    "settings": {
      "rules": [
        {
          "outboundTag": "blocked",
          "type": "field",
          "ip": [
            "geoip:private"
          ]
        }
      ]
    }
  }
}
EOF
rm -rf /etc/v2ray/config.back
mv -f /etc/v2ray/config.json /etc/v2ray/config.back
mv -f config /etc/v2ray/config.json
cp -f /etc/v2ray/config.json /etc/v2ray/config.back0


read -p "输入客户端（路由）的 IP 地址（默认：192.168.123.1 ）:" ipip
[ -z "$ipip" ] && ipip='192.168.123.1'

read -p "输入客户端（路由）的 本地代理 端口（默认：1088 ）:" ip_port
[ -z "$ip_port" ] && ip_port='1088'

read -p "输入客户端（路由）的 透明代理 端口（默认：1099 ）:" ip_door
[ -z "$ip_door" ] && ip_door='1099'
# 客户端配置
rm /root/config.json
cat << EOF > /root/config.json
{
  "log": {
    "error": "/tmp/syslog.log",
    "loglevel": "warning"
  },
  "inbounds":[
    {
      "port": $ip_port,
      "listen": "$ipip",
      "protocol": "$proxytype",
      "settings": {
        "auth": "noauth",
        "udp": true,
        "ip": "$ipip"
      },
      "streamSettings": {
        "sockopt": {
          "mark": 255
        }
      }
    },{
    //inboundDetour
      "port": "$ip_door",
      "listen": "0.0.0.0",
      "protocol": "dokodemo-door",
      "settings": {
        "network": "tcp,udp",
        "timeout": 30,
        "followRedirect": true
      }
    }
  ],
  "outbounds":[
  {
    "protocol": "vmess",
    "settings": {
      "vnext": [
        {
          "address": "$ipc",
          "port": $mainport,
          "users": [
            {
              "id": "$uuid",
              "alterId": 32
            }
          ]
        }
      ]
    }${mkcp}${httpheader}${mux}
  },{
  //outboundDetour
    "protocol": "freedom",
    "settings": {},
    "tag": "direct",
    "streamSettings": {
      "sockopt": {
        "mark": 255
      }
    }
  },{
  //outboundDetour
    "protocol": "blackhole",
    "settings": {},
    "tag": "blocked"
 }
  ],
  "dns": {
    "servers": [
      "8.8.8.8",
      "8.8.4.4",
      "localhost"
    ]
  },
  "routing": {
    "strategy": "rules",
    "settings": {
      "rules": [
        {
          "type": "field",
          "ip": [
            "127.0.0.0/8",
            "::1/128"
          ],
          "outboundTag": "blocked"
        },
        {
          "type": "field",
          "domain": [
            "baidu.com",
            "qq.com",
            "geosite:cn"
          ],
          "outboundTag": "direct"
        },
        {
          "type": "field",
          "ip": [
            "geoip:private",
            "geoip:cn",
            "100.100.100.100/32",
            "188.188.188.188/32",
            "110.110.110.110/32"
          ],
          "outboundTag": "direct"
        }
      ]
    }
  }
}

EOF


ntpdate us.pool.ntp.org &
if [ -n "${SYSTEMCTL_CMD}" ] && [ -f "/lib/systemd/system/v2ray.service" ] || [ -f "/etc/systemd/system/v2ray.service" ]; then
	echo "Restarting V2Ray service."
	systemctl enable v2ray.service
	${SYSTEMCTL_CMD} start v2ray
elif [ -n "${SERVICE_CMD}" ] && [ -f "/etc/init.d/v2ray" ]; then
	echo "Restarting V2Ray service."
	${SERVICE_CMD} v2ray start
fi

#service v2ray start
#clear
#INstall Success
echo 'Telegram Group: https://t.me/functionclub'
echo 'Github: https://github.com/FunctionClub'
echo '教程地址：https://github.com/FunctionClub/V2ray-Bash/blob/master/README.md'
echo '##########################################################################'
echo '配置完成，客户端配置文件在 /root/config.json'
echo '配置完成，客户端配置文件在 /root/config.json'
echo '配置完成，客户端配置文件在 /root/config.json'
echo ''
echo "程序主端口：$mainport"
echo "UUID: $uuid"
echo 'cat /root/config.json'
echo "打开 /root/config.json 复制里面的内容到路由的 v2ray 配置文件"
echo '##########################################################################'
rm -f /root/v2ray_config.pb
#/usr/bin/v2ray/v2ctl config < /root/config.json > /root/v2ray_config.pb
#[ ! -z "$(cat /root/v2ray_config.pb | grep "v2ctl config config.json c1.json c2.json")" ] && /usr/bin/v2ray/v2ctl config /root/config.json > /root/v2ray_config.pb
#[ -f /root/v2ray_config.pb ] && echo "已经生成 pb 配置文件 /root/v2ray_config.pb"
echo '##########################################################################'


