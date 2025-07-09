#!/bin/sh

func=`uci get openfi.switch.func`
lan=`uci get openfi.switch.lan`
power=`uci get openfi.switch.power`
led=`uci get openfi.switch.led`

# swich low: led on, lan, 5G on; high: led off, wan, 5G off
switch=`cat /sys/kernel/debug/gpio | grep func | grep hi`

logger -t ">>>op_switch" "func:$func switch:$switch"

led_on()
{
	echo 1 > /sys/class/leds/internet/brightness
	echo 1 > /sys/class/leds/system/brightness
	echo 1 > /sys/class/leds/wifi/brightness
}

led_off()
{
	echo 0 > /sys/class/leds/internet/brightness
	echo 0 > /sys/class/leds/system/brightness
	echo 0 > /sys/class/leds/wifi/brightness
}

lan_to_wan()
{
	port=`uci get network.@device[0].ports`

	if [ "$port" == "eth0" ]; then
		return 0
	fi

	uci set network.@device[0].ports="eth0"
	uci set network.wan.device="eth1"
	uci set network.wan6.device="eth1"
	uci commit
	/etc/init.d/network restart
}

wan_to_lan()
{
	port=`uci get network.@device[0].ports`

	if [ "$port" == "eth1" ]; then
		return 0
	fi

	uci set network.@device[0].ports="eth1"
	uci set network.wan.device="eth0"
	uci set network.wan6.device="eth0"
	uci commit
	/etc/init.d/network restart
}

modem_on()
{
	echo 0 > /sys/class/gpio/lte_power/value
}

modem_off()
{
	echo 1 > /sys/class/gpio/lte_power/value
}

if [ $# -eq "1" ] && [ $1 == "on" ]; then
	if [ "$func" == "1" ]; then
		wan_to_lan
	elif [ "$func" == "2" ]; then
		modem_on
	elif [ "$func" == "3" ]; then
		led_on
	fi
elif [ $# -eq "1" ] && [ $1 == "off" ]; then
	if [ "$func" == "1" ]; then
		lan_to_wan
	elif [ "$func" == "2" ]; then
		modem_off
	elif [ "$func" == "3" ]; then
		led_off
	fi
else
	if [ -z "$switch" ]; then
		if [ "$func" == "1" ]; then
			if [ "$power" == "1" ]; then
				modem_on
			elif [ "$power" == "0" ]; then
				modem_off
			fi

			if [ "$led" == "1" ]; then
				led_on
			elif [ "$led" == "0" ]; then
				led_off
			fi

			wan_to_lan
		elif [ "$func" == "2" ]; then
			if [ "$lan" == "1" ]; then
				wan_to_lan
			elif [ "$lan" == "0" ]; then
				lan_to_wan
			fi

			if [ "$led" == "1" ]; then
				led_on
			elif [ "$led" == "0" ]; then
				led_off
			fi

			modem_on
		elif [ "$func" == "3" ]; then
			if [ "$lan" == "1" ]; then
				wan_to_lan
			elif [ "$lan" == "0" ]; then
				lan_to_wan
			fi

			if [ "$power" == "1" ]; then
				modem_on
			elif [ "$power" == "0" ]; then
				modem_off
			fi

			led_on
		else
			if [ "$lan" == "1" ]; then
				wan_to_lan
			elif [ "$lan" == "0" ]; then
				lan_to_wan
			fi

			if [ "$power" == "1" ]; then
				modem_on
			elif [ "$power" == "0" ]; then
				modem_off
			fi

			if [ "$led" == "1" ]; then
				led_on
			elif [ "$led" == "0" ]; then
				led_off
			fi
		fi
	else
		if [ "$func" == "1" ]; then
			if [ "$power" == "1" ]; then
				modem_on
			elif [ "$power" == "0" ]; then
				modem_off
			fi

			if [ "$led" == "1" ]; then
				led_on
			elif [ "$led" == "0" ]; then
				led_off
			fi

			lan_to_wan
		elif [ "$func" == "2" ]; then
			if [ "$lan" == "1" ]; then
				wan_to_lan
			elif [ "$lan" == "0" ]; then
				lan_to_wan
			fi

			if [ "$led" == "1" ]; then
				led_on
			elif [ "$led" == "0" ]; then
				led_off
			fi

			modem_off
		elif [ "$func" == "3" ]; then
			if [ "$lan" == "1" ]; then
				wan_to_lan
			elif [ "$lan" == "0" ]; then
				lan_to_wan
			fi

			if [ "$power" == "1" ]; then
				modem_on
			elif [ "$power" == "0" ]; then
				modem_off
			fi

			led_off
		else
			if [ "$lan" == "1" ]; then
				wan_to_lan
			elif [ "$lan" == "0" ]; then
				lan_to_wan
			fi

			if [ "$power" == "1" ]; then
				modem_on
			elif [ "$power" == "0" ]; then
				modem_off
			fi

			if [ "$led" == "1" ]; then
				led_on
			elif [ "$led" == "0" ]; then
				led_off
			fi
		fi
	fi
fi
