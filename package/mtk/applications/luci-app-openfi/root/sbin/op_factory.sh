#!/bin/sh

lan_ip="192.168.21.100"
wan_ip="192.168.6.1"
files="/tmp/mfg_result"

rm $files
touch $files

ping_lan() {
	echo "ping lan"
	if ping -c 1 -W 1 $lan_ip > /dev/null; then
		echo -e "\"lan\":\"Pass\"," >> $files
	else
		echo -e "\"lan\":\"Fail\"," >> $files
	fi
}

check_lan() {
	echo "test lan"
	speed=`cat /sys/class/net/eth1/speed`

	if [ "$speed" == "1000" ]; then
		echo -e "\"lan\":\"Pass\"," >> $files
	else
		echo -e "\"lan\":\"Fail\"," >> $files
	fi
}

ping_wan() {
	echo "ping wan"
	if ping -c 1 -W 3 $wan_ip > /dev/null; then
		echo -e "\"wan\":\"Pass\"," >> $files
	else
		echo -e "\"wan\":\"Fail\"," >> $files
	fi
}

test_sd() {
	echo "test sd"
	sd=`lsusb | grep "05e3:0761"`

	if [ -n "$sd" ]; then
		echo -e "\"sd\":\"Pass\"," >> $files
	else
		echo -e "\"sd\":\"Fail\"," >> $files
	fi
}

test_usb() {
	echo "test usb"
	USB1=`mount | grep sda | sed 's/^\/dev.*\/mnt/\/mnt/g' | sed 's/\ type.*$//g'`
	USB2=`mount | grep sdb | sed 's/^\/dev.*\/mnt/\/mnt/g' | sed 's/\ type.*$//g'`
	sd=`lsusb | grep "05e3:0761"`

	# Check if the USB storage devices are mounted, if two device were found, one should be usb flash
	# if only one device was found, check if it is a sd card, otherwise it is a usb flash
	if [ -n "$USB1" -a -n "$USB2" ]; then
        echo -e "\"usb\":\"Pass\"," >> $files
	elif [ -n "$USB1" -o -n "$USB2" ]; then
		if [ -z "$sd" ]; then
			echo -e "\"usb\":\"Pass\"," >> $files
		else
			echo -e "\"usb\":\"Fail\"," >> $files
		fi
    else
        echo -e "\"usb\":\"Fail\"," >> $files
    fi
}

test_reset() {
	echo "test reset"
	if [ ! -f "/tmp/reset_times" ] ; then
		echo -e "\"reset\":\"Fail\"," >> $files
		return
	fi

	reset_times=`cat /tmp/reset_times`

	if [ $reset_times != "0" ]; then
		echo -e "\"reset\":\"Pass\"," >> $files
	else
		echo -e "\"reset\":\"Fail\"," >> $files
	fi
}

test_switch() {
	echo "test Switch"
        if [ ! -f "/tmp/switch_times" ] ; then 
                echo -e "\"switch\":\"Fail\"," >> $files
		return
        fi                                          
                                           
        switch_times=`cat /tmp/switch_times`
            
        if [ $switch_times != "0" ]; then
                echo -e "\"switch\":\"Pass\"" >> $files
        else
                echo -e "\"switch\":\"Fail\"" >> $files
        fi 
}

if [ $# == 0 ]; then
	echo "{" > $files
	
	#ping_lan
	check_lan
	#ping_wan
	test_sd
	test_usb
	test_reset
	test_switch
	
	echo "}" >> $files

elif [ $# == 1 ]; then
	if [ "$1" == "lan" ]; then
		ping_lan
	elif [ "$1" == "wan" ]; then
		ping_wan
	elif [ "$1" == "sd" ]; then
		test_sd
	elif [ "$1" == "usb" ]; then
		test_usb
	elif [ "$1" == "reset" ]; then
		test_reset
	elif [ "$1" == "switch" ]; then
		test_switch
	else
		echo "Usage:\
			./test.sh [OPTION] \
			OPTION: \
			lan		ping $lan_ip with lan \
			wan		ping $wan_ip with wan \
			sd		check if sd card is exist \
			usb		check if usb flash disk is exist \
			reset		check if the reset key is pressed \
			switch		check if the switch key is moved \
			"
	fi
fi
