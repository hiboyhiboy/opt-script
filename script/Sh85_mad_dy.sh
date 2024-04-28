#!/bin/bash
#copyright by hiboy
source /etc/storage/script/init.sh
maddy_enable=`nvram get app_145`
[ -z $maddy_enable ] && maddy_enable=0 && nvram set app_145=0

if [ "$maddy_enable" != "0" ] ; then

maddy_renum=`nvram get maddy_renum`
maddy_renum=${maddy_renum:-"0"}

cmd_log_enable=`nvram get cmd_log_enable`
cmd_name="maddy"
cmd_log=""
if [ "$cmd_log_enable" = "1" ] || [ "$maddy_renum" -gt "0" ] ; then
	cmd_log="$cmd_log2"
fi

fi

if [ ! -z "$(echo $scriptfilepath | grep -v "/tmp/script/" | grep mad_dy)" ] && [ ! -s /tmp/script/_app28 ] ; then
	mkdir -p /tmp/script
	{ echo '#!/bin/bash' ; echo $scriptfilepath '"$@"' '&' ; } > /tmp/script/_app28
	chmod 777 /tmp/script/_app28
fi

maddy_restart () {
i_app_restart "$@" -name="maddy"
}

maddy_get_status () {

B_restart="$maddy_enable$(cat /etc/storage/app_37.sh | grep -v '^#' | grep -v '^$')"

i_app_get_status -name="maddy" -valb="$B_restart"
}

maddy_check () {

maddy_get_status
if [ "$maddy_enable" != "1" ] && [ "$needed_restart" = "1" ] ; then
	[ ! -z "`pidof maddy`" ] && logger -t "【maddy】" "停止 maddy" && maddy_close
	{ kill_ps "$scriptname" exit0; exit 0; }
fi
if [ "$maddy_enable" = "1" ] ; then
	if [ "$needed_restart" = "1" ] ; then
		maddy_close
		maddy_start
	else
		[ "$maddy_enable" = "1" ] && [ -z "`pidof maddy`" ] && maddy_restart
	fi
fi
}

maddy_keep () {
i_app_keep -name="maddy" -pidof="maddy" -cpath="/opt/maddy/maddy" &
}

maddy_close () {
sed -Ei '/【maddy】|^$/d' /tmp/script/_opt_script_check
killall maddy
kill_ps "/tmp/script/_app28"
kill_ps "_mad_dy.sh"
kill_ps "$scriptname"
}

maddy_start () {
check_webui_yes
i_app_get_cmd_file -name="maddy" -cmd="/opt/maddy/maddy" -cpath="/opt/maddy/maddy" -down1="$hiboyfile/maddy" -down2="$hiboyfile2/maddy" -runh="--help"
maddy_v=`/opt/maddy/maddy version | awk -F ' ' '{print $1;}' | head -n1`
[ "$(nvram get maddy_v)" != "$maddy_v" ] && nvram set maddy_v="$maddy_v"
chmod 777 "$SVC_PATH"
logger -t "【maddy】" "设置域名证书"
cp -f /etc/storage/https/server.crt /opt/maddy/certs/certificate.crt
cp -f /etc/storage/https/server.key /opt/maddy/certs/private.key
rm -f /opt/maddy/maddy.conf
cat /etc/storage/app_37.sh >> /opt/maddy/maddy.conf
echo "" >> /opt/maddy/maddy.conf

hash su 2>/dev/null && su_x="1"
hash su 2>/dev/null || su_x="0"
if [ "$su_x" = "1" ] ; then
	logger -t "【maddy】" "使用非root用户运行 maddy"
	addgroup -g 1456 maddy
	adduser -G maddy -u 1456 maddy -D -S -H -s /bin/false
	#sed -Ei s/1456:1456/0:1456/g /etc/passwd
	su_cmd="su maddy -s /bin/sh -c "
	chown -R maddy:maddy /opt/maddy 
fi

logger -t "【maddy】" "运行 $SVC_PATH"
su_cmd2="/opt/maddy/maddy --config /opt/maddy/maddy.conf  run" # --debug
cd /opt/maddy
eval "$su_cmd" '"cmd_name=maddy && '"$su_cmd2"' $cmd_log2"' &
sleep 3
i_app_keep -t -name="maddy" -pidof="maddy" -cpath="/opt/maddy/maddy"

#maddy_get_status
eval "$scriptfilepath keep &"
exit 0
}

initconfig () {

app_37="/etc/storage/app_37.sh"
if [ -z "$(cat "$app_37" | grep /etc/storage/app_37.sh)" ] ; then
	rm -f "$app_37"
fi
if [ ! -f "$app_37" ] || [ ! -s "$app_37" ] ; then
	cat > "$app_37" <<-\EEE
# 此脚本路径：/etc/storage/app_37.sh
## Maddy Mail Server - default configuration file (2022-06-18)
# Suitable for small-scale deployments. Uses its own format for local users DB,
# should be managed via maddy subcommands.
#
# See tutorials at https://maddy.email for guidance on typical
# configuration changes.

# ----------------------------------------------------------------------------
# Base variables

$(hostname) = example.com
$(primary_domain) = example.com
$(local_domains) = $(primary_domain)

#tls off
tls file /opt/maddy/certs/certificate.crt /opt/maddy/certs/private.key

# ----------------------------------------------------------------------------
# Local storage & authentication

# pass_table provides local hashed passwords storage for authentication of
# users. It can be configured to use any "table" module, in default
# configuration a table in SQLite DB is used.
# Table can be replaced to use e.g. a file for passwords. Or pass_table module
# can be replaced altogether to use some external source of credentials (e.g.
# PAM, /etc/shadow file).
#
# If table module supports it (sql_table does) - credentials can be managed
# using 'maddy creds' command.

auth.pass_table local_authdb {
    table sql_table {
        driver sqlite3
        dsn credentials.db
        table_name passwords
    }
}

# imapsql module stores all indexes and metadata necessary for IMAP using a
# relational database. It is used by IMAP endpoint for mailbox access and
# also by SMTP & Submission endpoints for delivery of local messages.
#
# IMAP accounts, mailboxes and all message metadata can be inspected using
# imap-* subcommands of maddy.

storage.imapsql local_mailboxes {
    driver sqlite3
    dsn imapsql.db
}

# ----------------------------------------------------------------------------
# SMTP endpoints + message routing

hostname $(hostname)

table.chain local_rewrites {
    optional_step regexp "(.+)\+(.+)@(.+)" "$1@$3"
    optional_step static {
        entry postmaster postmaster@$(primary_domain)
    }
    optional_step file /opt/maddy/aliases
}

msgpipeline local_routing {
    # Insert handling for special-purpose local domains here.
    # e.g.
    # destination lists.example.org {
    #     deliver_to lmtp tcp://127.0.0.1:8024
    # }

    destination postmaster $(local_domains) {
        modify {
            replace_rcpt &local_rewrites
        }

        deliver_to &local_mailboxes
    }

    default_destination {
        reject 550 5.1.1 "User doesn't exist"
    }
}

# tcp://0.0.0.0:25
smtp tcp://0.0.0.0:10025 {
    limits {
        # Up to 20 msgs/sec across max. 10 SMTP connections.
        all rate 20 1s
        all concurrency 10
    }

    dmarc yes
    check {
        require_mx_record
        dkim
        spf
    }

    source $(local_domains) {
        reject 501 5.1.8 "Use Submission for outgoing SMTP"
    }
    default_source {
        destination postmaster $(local_domains) {
            deliver_to &local_routing
        }
        default_destination {
            reject 550 5.1.1 "User doesn't exist"
        }
    }
}

# tcp://0.0.0.0:587  tls://0.0.0.0:465
submission tcp://0.0.0.0:10587  tls://0.0.0.0:10465 {
    limits {
        # Up to 50 msgs/sec across any amount of SMTP connections.
        all rate 50 1s
    }

    auth &local_authdb

    source $(local_domains) {
        check {
            authorize_sender {
                prepare_email &local_rewrites
                user_to_email identity
            }
        }

        destination postmaster $(local_domains) {
            deliver_to &local_routing
        }
        default_destination {
            modify {
                dkim $(primary_domain) $(local_domains) default
            }
            deliver_to &remote_queue
        }
    }
    default_source {
        reject 501 5.1.8 "Non-local sender domain"
    }
}

target.remote outbound_delivery {
    limits {
        # Up to 20 msgs/sec across max. 10 SMTP connections
        # for each recipient domain.
        destination rate 20 1s
        destination concurrency 10
    }
    mx_auth {
        dane
        mtasts {
            cache fs
            fs_dir mtasts_cache/
        }
        local_policy {
            min_tls_level encrypted
            min_mx_level none
        }
    }
}

target.queue remote_queue {
    target &outbound_delivery

    autogenerated_msg_domain $(primary_domain)
    bounce {
        destination postmaster $(local_domains) {
            deliver_to &local_routing
        }
        default_destination {
            reject 550 5.0.0 "Refusing to send DSNs to non-local addresses"
        }
    }
}

# ----------------------------------------------------------------------------
# IMAP endpoints
# tcp://0.0.0.0:143  tls://0.0.0.0:993
imap tcp://0.0.0.0:10143  tls://0.0.0.0:10993 {
    auth &local_authdb
    storage &local_mailboxes
}

EEE
	chmod 755 "$app_37"
fi

}

initconfig

update_app () {

mkdir -p /opt/app/maddy
if [ "$1" = "del" ] ; then
	rm -rf /opt/app/maddy/Advanced_Extensions_maddy.asp
	rm -rf /opt/maddy/maddy
fi

initconfig

# 加载程序配置页面
if [ ! -f "/opt/app/maddy/Advanced_Extensions_maddy.asp" ] || [ ! -s "/opt/app/maddy/Advanced_Extensions_maddy.asp" ] ; then
	wgetcurl.sh /opt/app/maddy/Advanced_Extensions_maddy.asp "$hiboyfile/Advanced_Extensions_maddyasp" "$hiboyfile2/Advanced_Extensions_maddyasp"
fi
umount /www/Advanced_Extensions_app28.asp
mount --bind /opt/app/maddy/Advanced_Extensions_maddy.asp /www/Advanced_Extensions_app28.asp
# 更新程序启动脚本

[ "$1" = "del" ] && /etc/storage/www_sh/maddy del &
}

case $ACTION in
start)
	maddy_close
	maddy_check
	;;
check)
	maddy_check
	;;
stop)
	maddy_close
	;;
updateapp28)
	maddy_restart o
	[ "$maddy_enable" = "1" ] && nvram set maddy_status="updatemaddy" && logger -t "【maddy】" "重启" && maddy_restart
	[ "$maddy_enable" != "1" ] && nvram set maddy_v="" && logger -t "【maddy】" "更新" && update_app del
	;;
update_app)
	update_app
	;;
keep)
	#maddy_check
	maddy_keep
	;;
*)
	maddy_check
	;;
esac

