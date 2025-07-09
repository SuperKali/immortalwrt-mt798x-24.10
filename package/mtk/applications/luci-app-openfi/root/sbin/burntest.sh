#!/bin/sh

if [ -f /var/run/burntest_pid ]
then
    pid=`cat /var/run/burntest_pid`
    kill -9 $pid
fi
echo $$ > /var/run/burntest_pid

index=0
echo `uptime` > /etc/burntest_start

echo timer > /sys/class/leds/wifi/trigger
echo 200 > /sys/class/leds/wifi/delay_off
echo 200 > /sys/class/leds/wifi/delay_on

while true; do
	while [ $index -ne 5 ]; do
		coremark
		let index+=1
		echo "$index"
	done

	index=0
	echo `uptime` > /etc/burntest_end
done
