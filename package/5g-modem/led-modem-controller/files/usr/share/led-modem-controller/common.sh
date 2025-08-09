#!/bin/sh

MODEM_LIB_DIR="/usr/share/led-modem-controller"

load_config() {
    FALLBACK_DEVICES=$(uci -q get led-modem-controller.settings.fallback_devices || echo "/dev/ttyUSB1 /dev/ttyUSB2 /dev/ttyUSB3")
    TIMEOUT=$(uci -q get led-modem-controller.settings.timeout || echo "15")
    MAX_ERRORS=$(uci -q get led-modem-controller.settings.max_errors || echo "3")
    CACHE_TIMEOUT=$(uci -q get led-modem-controller.settings.cache_timeout || echo "180")
    DEBUG=$(uci -q get led-modem-controller.settings.debug || echo "0")
    LOG_ENABLED=$(uci -q get led-modem-controller.settings.log_enabled || echo "1")
    
    LED_4G_BLUE=$(uci -q get led-modem-controller.leds.led_4g_blue || echo "/sys/class/leds/wt:4g:blue")
    LED_4G_GREEN=$(uci -q get led-modem-controller.leds.led_4g_green || echo "/sys/class/leds/wt:4g:green")
    LED_4G_YELLOW=$(uci -q get led-modem-controller.leds.led_4g_yellow || echo "/sys/class/leds/wt:4g:yellow")
    LED_5G_BLUE=$(uci -q get led-modem-controller.leds.led_5g_blue || echo "/sys/class/leds/wt:5g:blue")
    LED_5G_YELLOW=$(uci -q get led-modem-controller.leds.led_5g_yellow || echo "/sys/class/leds/wt:5g:yellow")
    
    EXCELLENT_RSRP=$(uci -q get led-modem-controller.signal.excellent_rsrp || echo "-80")
    GOOD_RSRP=$(uci -q get led-modem-controller.signal.good_rsrp || echo "-89")
}

sms_tool_query() {
    local cmd="$1"
    local device="$2"
    local timeout="${3:-5}"
    
    if [ ! -c "$device" ]; then
        log_debug "Device $device not found"
        return 1
    fi
    
    log_debug "Running: sms_tool -d $device at \"$cmd\" (timeout: ${timeout}s)"
    
    if command -v timeout >/dev/null 2>&1; then
        timeout "$timeout" sms_tool -d "$device" at "$cmd" 2>/dev/null
    else
        sms_tool -d "$device" at "$cmd" 2>/dev/null
    fi
}

detect_modem_type() {
    local device="$1"
    local vendor_id product_id
    
    log_debug "Detecting modem type for $device"
    
    local tty_name=$(basename "$device")
    local dev_path="/sys/class/tty/$tty_name/device"
    
    if [ -e "$dev_path" ]; then
        local usb_device_path=$(readlink -f "$dev_path")
        while [ -n "$usb_device_path" ] && [ "$usb_device_path" != "/" ]; do
            if [ -f "$usb_device_path/idVendor" ] && [ -f "$usb_device_path/idProduct" ]; then
                vendor_id=$(cat "$usb_device_path/idVendor" 2>/dev/null)
                product_id=$(cat "$usb_device_path/idProduct" 2>/dev/null)
                if [ -n "$vendor_id" ] && [ -n "$product_id" ]; then
                    echo "${vendor_id}${product_id}"
                    log_debug "Detected USB ID: ${vendor_id}${product_id}"
                    return 0
                fi
            fi
            usb_device_path=$(dirname "$usb_device_path")
        done
    fi
    
    log_debug "USB ID detection failed, using generic driver"
    echo "generic"
}

get_modem_id_from_system() {
    local vendor_id product_id
    
    for dev_path in /sys/class/tty/ttyUSB*/device /sys/class/tty/ttyACM*/device; do
        [ -e "$dev_path" ] || continue
        
        local usb_device_path=$(readlink -f "$dev_path")
        while [ -n "$usb_device_path" ] && [ "$usb_device_path" != "/" ]; do
            if [ -f "$usb_device_path/idVendor" ] && [ -f "$usb_device_path/idProduct" ]; then
                vendor_id=$(cat "$usb_device_path/idVendor" 2>/dev/null)
                product_id=$(cat "$usb_device_path/idProduct" 2>/dev/null)
                if [ -n "$vendor_id" ] && [ -n "$product_id" ]; then
                    echo "${vendor_id}${product_id}"
                    return 0
                fi
            fi
            usb_device_path=$(dirname "$usb_device_path")
        done
    done
    
    echo "generic"
}

load_modem_driver() {
    local modem_id="$1"
    local modem_file="$MODEM_LIB_DIR/modem/usb/$modem_id"
    
    log_debug "Loading driver: $modem_file"
    
    PREFERRED_TTY=""
    
    if [ -f "$modem_file" ]; then
        . "$modem_file"
        log_debug "Loaded specific driver for $modem_id"
        log_debug "Preferred TTY: $PREFERRED_TTY"
        return 0
    else
        . "$MODEM_LIB_DIR/modem/usb/generic"
        log_debug "Loaded generic driver"
        return 1
    fi
}

get_available_devices() {
    local devices=""
    
    for dev in /dev/ttyUSB* /dev/ttyACM* /dev/cdc-wdm*; do
        if [ -c "$dev" ]; then
            devices="$devices $dev"
        fi
    done
    
    echo "$devices" | xargs
}

test_device_availability() {
    local device="$1"
    
    log_debug "Testing device: $device"
    
    if [ ! -c "$device" ]; then
        log_debug "Device $device does not exist"
        return 1
    fi
    
    local test_response=$(sms_tool_query "ATI" "$device" 3)
    local result=$?
    
    log_debug "ATI command result: $result"
    log_debug "ATI response: $test_response"
    
    if [ $result -eq 0 ] && [ -n "$test_response" ] && ! echo "$test_response" | grep -q "ERROR"; then
        log_debug "Device $device is working"
        return 0
    else
        log_debug "Device $device is not responding"
        return 1
    fi
}

log_debug() {
    if [ "$DEBUG" = "1" ]; then
        echo "[DEBUG $(date '+%H:%M:%S')] $*" >> "/tmp/led_debug.log"
        echo "[DEBUG] $*" >&2
    fi
}

log_info() {
    echo "INFO: $*"
    if [ "$LOG_ENABLED" = "1" ]; then
        echo "[$(date '+%H:%M:%S')] $*" >> "/tmp/led_controller.log"
    fi
}

log_error() {
    echo "ERROR: $*" >&2
    if [ "$LOG_ENABLED" = "1" ]; then
        echo "[$(date '+%H:%M:%S')] ERROR: $*" >> "/tmp/led_controller.log"
    fi
    if [ "$DEBUG" = "1" ]; then
        log_debug "ERROR: $*"
    fi
}

log_status() {
    if [ "$LOG_ENABLED" = "1" ]; then
        echo "[$(date '+%H:%M:%S')] $*" >> "/tmp/led_controller.log"
    fi
    if [ "$DEBUG" = "1" ]; then
        echo "[DEBUG] $*" >&2
    fi
}