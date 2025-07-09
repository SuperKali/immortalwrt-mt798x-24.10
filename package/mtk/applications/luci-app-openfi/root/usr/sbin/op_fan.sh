#!/bin/sh

if [ -f /var/run/fan_pid ]; then
    pid=`cat /var/run/fan_pid`
    kill -9 $pid
fi
echo $$ > /var/run/fan_pid

# for openfi 6c, pwm frequency need to be 25KHz, and mt7981 don't support polarity, so when duty_cycle is lower, fan will run faster
# init pwm0
echo 0 > /sys/class/pwm/pwmchip0/export
echo 40000 > /sys/class/pwm/pwmchip0/pwm0/period
echo 40000 > /sys/class/pwm/pwmchip0/pwm0/duty_cycle
echo 1 > /sys/class/pwm/pwmchip0/pwm0/enable

# init pwm1
echo 1 > /sys/class/pwm/pwmchip0/export
echo 40000 > /sys/class/pwm/pwmchip0/pwm1/period
echo 40000 > /sys/class/pwm/pwmchip0/pwm1/duty_cycle
echo 1 > /sys/class/pwm/pwmchip0/pwm1/enable
fan_level=`uci get openfi.fan.level`
fan_level=${fan_level:="0"}

fanSleep=10
fanStart=0
fanStop=0

usage() {
	echo "This script is for check device temperature and control fan"
	echo "usage: $0 cpu_high cpu_low wifi_high wifi_low modem_high modem_low period"
	echo "e.g. $0 65 60 65 60 45 40 10"
	echo "or $0 to use default settings"
	exit 1
}

checkInput() {
	expr $1 + 0 &>/dev/null
	[ $? -ne 0 ] && { echo "Temperature must be integer!"; usage; }
	[ $1 -lt 30 ] && { echo "Temperature must be great than 30!"; usage; }
}

if [ $# -eq 0 ]; then
	cpu_high=`uci get openfi.fan.cpu_temp_high`
	cpu_low=`uci get openfi.fan.cpu_temp_low`
	wifi_high=`uci get openfi.fan.wifi_temp_high`
	wifi_low=`uci get openfi.fan.wifi_temp_low`
	modem_high=`uci get openfi.fan.modem_temp_high`
	modem_low=`uci get openfi.fan.modem_temp_low`
	period=`uci get openfi.fan.period`

	cpu_high=${cpu_high:="65"}
	cpu_low=${cpu_low:="55"}
	wifi_high=${wifi_high:="65"}
	wifi_low=${wifi_low:="55"}
	modem_high=${modem_high:="45"}
	modem_low=${modem_low:="38"}
	fanSleep=${period:="10"}
elif [ $# -eq 7 ]; then
	checkInput $1
	checkInput $2
	checkInput $3
	checkInput $4
	checkInput $5
	checkInput $6

	cpu_high=$1
	cpu_low=$2

	wifi_high=$3
	wifi_low=$4

	modem_high=$5
	modem_low=$6

	fanSleep=$7
else
	usage
	exit 1
fi

temp_cpu=`cat /sys/class/thermal/thermal_zone0/temp | cut -c 1-2`
temp_wifi=`iwpriv ra0 stat |grep CurrentTemperature | awk -F '= ' '{print$2}'`
temp_modem=`ubus call modem_ctrl base_info |grep "°C" |  tr -cd '0-9\n'`
temp_modem=${temp_modem:="0"}

echo "Start:			cpu:$cpu_high	wifi:$wifi_high	modem:$modem_high"
echo "Stop:			cpu:$cpu_low	wifi:$wifi_low	modem:$modem_low"
logger -t ">>>FAN" "CurrentTemperature:	cpu:$temp_cpu	wifi:$temp_wifi	modem:$temp_modem"

while true; do
	# check temperature of cpu, wifi, modem
	temp_cpu=`cat /sys/class/thermal/thermal_zone0/temp | cut -c 1-2`
	temp_wifi=`iwpriv ra0 stat |grep CurrentTemperature | awk -F '= ' '{print$2}'`
	temp_modem=`ubus call modem_ctrl base_info |grep "°C" |  tr -cd '0-9\n'`
	temp_modem=${temp_modem:="0"}

	# echo "temp_cpu:$temp_cpu temp_wifi:$temp_wifi temp_modem:$temp_modem"

	if [ "$temp_cpu" -ge "$cpu_high" -o "$temp_wifi" -ge "$wifi_high" -o "$temp_modem" -ge "$modem_high" ]; then
		fanStart=`expr $fanStart + 1`
		if [ "$fanStart" -le "1" ]; then
			# echo "Start the fan:	cpu:$temp_cpu	wifi:$temp_wifi	modem:$temp_modem"
			logger -t ">>>FAN" "Start:	cpu:$temp_cpu	wifi:$temp_wifi	modem:$temp_modem"
			fanStop=0
		fi

		if [ $fan_level -eq "0" ]; then
			echo 23000 > /sys/class/pwm/pwmchip0/pwm0/duty_cycle
			echo 23000 > /sys/class/pwm/pwmchip0/pwm1/duty_cycle
		elif [ $fan_level -eq "1" ]; then
			echo 18000 > /sys/class/pwm/pwmchip0/pwm0/duty_cycle
			echo 18000 > /sys/class/pwm/pwmchip0/pwm1/duty_cycle
		else
			echo 0 > /sys/class/pwm/pwmchip0/pwm0/duty_cycle
			echo 0 > /sys/class/pwm/pwmchip0/pwm1/duty_cycle
		fi
	elif [ "$temp_cpu" -le "$cpu_low" -a "$temp_wifi" -le "$wifi_low" -a "$temp_modem" -le "$modem_low" ]; then
		fanStop=`expr $fanStop + 1`
		if [ "$fanStop" -le "1" ]; then
			# echo "Stop the fan:	cpu:$temp_cpu	wifi:$temp_wifi	modem:$temp_modem"
			logger -t ">>>FAN" "Stop:	cpu:$temp_cpu	wifi:$temp_wifi	modem:$temp_modem"
			fanStart=0
		fi
		echo 40000 > /sys/class/pwm/pwmchip0/pwm0/duty_cycle
		echo 40000 > /sys/class/pwm/pwmchip0/pwm1/duty_cycle
	fi

	sleep $fanSleep
done
