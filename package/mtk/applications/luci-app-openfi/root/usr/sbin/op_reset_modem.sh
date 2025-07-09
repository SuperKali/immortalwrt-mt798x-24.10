#!/bin/sh

state=`uci get openfi.reset.state`

logger -t ">>>reset_modem" "state:$state"

if [ "$state" == "1" ]; then
    echo 1 > /sys/class/gpio/lte_reset/value
fi

