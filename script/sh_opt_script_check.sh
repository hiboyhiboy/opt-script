#!/bin/sh
#copyright by hiboy
source /etc/storage/script/init.sh

if [ ! -z "$(echo $scriptfilepath | grep -v "/tmp/script/" | grep opt_script_check)" ]  && [ ! -s /tmp/script/_opt_script_check ]; then
	mkdir -p /tmp/script
	ln -sf $scriptfilepath /tmp/script/_opt_script_check
	chmod 777 /tmp/script/_opt_script_check
fi

ps - w > /tmp/ps



