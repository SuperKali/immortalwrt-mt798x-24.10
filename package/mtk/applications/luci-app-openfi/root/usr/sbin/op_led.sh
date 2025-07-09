#!/bin/sh

func=`uci get openfi.switch.func`
led=`uci get openfi.switch.led`

internet_status="0"
wifi_status="0"

logger -t ">>>op_led" "func:$func"

internet_on()
{
	echo none > /sys/class/leds/internet/trigger
	echo 1 > /sys/class/leds/internet/brightness

	internet_status="1"
}

internet_blink()
{
	echo timer > /sys/class/leds/internet/trigger
	echo 1000 > /sys/class/leds/internet/delay_off
	echo 1000 > /sys/class/leds/internet/delay_on

	internet_status="2"
}

check_wifi()
{
	wifi1=`uci get wireless.MT7981_1_1.disabled`
	wifi2=`uci get wireless.MT7981_1_2.disabled`

	if [ "$wifi1" == "1" -a "$wifi2" == "1" ]; then
		if [ "$wifi_status" != "1" ]; then
			echo none > /sys/class/leds/wifi/trigger
			echo 0 > /sys/class/leds/wifi/brightness

			wifi_status="1"
		fi
	elif [ "$wifi_status" != "2" ]; then
		echo none > /sys/class/leds/wifi/trigger
		echo 1 > /sys/class/leds/wifi/brightness

		wifi_status="2"
	fi
}

check_internet()
{
	internet=`ping -W 1 -c 1 www.baidu.com`

	if [ "$?" == "0" ]; then
		if [ "$internet_status" != "1" ]; then
			internet_on
		fi
	else
		internet=`ping -W 1 -c 1 114.114.114.114`
		if [ "$?" == "0" ]; then
			if [ "$internet_status" != "1" ]; then
				internet_on
			fi
		else
			internet=`ping -W 1 -c 1 1.1.1.1`
			if [ "$?" == "0" ]; then
				if [ "$internet_status" != "1" ]; then
					internet_on
				fi
			else
				internet=`ping -W 1 -c 1 www.microsoft.com`
				if [ "$?" == "0" ]; then
					if [ "$internet_status" != "1" ]; then
						internet_on
					fi
				elif [ "$internet_status" != "2" ]; then
					internet_blink
				fi
			fi
		fi
	fi
}

while true; do
	switch=`cat /sys/kernel/debug/gpio | grep func | grep hi`

	if [ "$func" == "3" ]; then
		if [ -z "$switch" ]; then
			check_internet
			check_wifi
		else
			internet_status="0"
			wifi_status="0"
		fi
	else
		if [ $led == "1" ]; then
			check_internet
			check_wifi
		elif [ $led == "0" ]; then
			internet_status="0"
			wifi_status="0"
		fi
	fi

	sleep 5
done

