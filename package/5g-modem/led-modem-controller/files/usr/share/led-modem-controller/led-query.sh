#!/bin/sh

set -e

SCRIPT_DIR="/usr/share/led-modem-controller"
CACHE_FILE="/tmp/led_modem_device_cache"

. "$SCRIPT_DIR/common.sh"

find_working_device() {
    load_config

    log_debug "Looking for working device..."
    log_debug "Fallback devices: $FALLBACK_DEVICES"

    local modem_id=$(get_modem_id_from_system)
    log_debug "Detected system modem ID: $modem_id"
    
    load_modem_driver "$modem_id"
    
    if [ -n "$PREFERRED_TTY" ]; then
        log_debug "Testing preferred TTY for $modem_id: $PREFERRED_TTY"
        if test_device_availability "$PREFERRED_TTY"; then
            echo "$PREFERRED_TTY" > "$CACHE_FILE"
            echo "$PREFERRED_TTY"
            return 0
        fi
    fi

    local cached_device=""
    if [ -f "$CACHE_FILE" ]; then
        cached_device=$(cat "$CACHE_FILE" 2>/dev/null)
        log_debug "Cached device: $cached_device"
        if [ -n "$cached_device" ] && test_device_availability "$cached_device"; then
            echo "$cached_device"
            return 0
        fi
    fi

    log_debug "Preferred and cached devices failed, trying fallback devices"
    for device in $FALLBACK_DEVICES; do
        log_debug "Testing fallback device: $device"
        if test_device_availability "$device"; then
            echo "$device" > "$CACHE_FILE"
            echo "$device"
            return 0
        fi
    done

    log_debug "Fallback devices failed, scanning all available devices"
    local available_devices=$(get_available_devices)
    log_debug "Available devices: $available_devices"

    for device in $available_devices; do
        log_debug "Testing available device: $device"
        if test_device_availability "$device"; then
            echo "$device" > "$CACHE_FILE"
            echo "$device"
            return 0
        fi
    done

    log_debug "No working devices found"
    return 1
}

main() {
    local device modem_id

    load_config

    log_debug "Starting main query function"

    device=$(find_working_device)
    if [ -z "$device" ]; then
        echo '{"error": "No working modem device found"}'
        log_error "No working modem device found"
        exit 1
    fi

    log_debug "Found working device: $device"

    modem_id=$(detect_modem_type "$device")
    log_debug "Detected modem type: $modem_id"

    if [ -z "$modem_id" ] || [ "$modem_id" = "unknown" ]; then
        echo '{"error": "Unknown modem type", "device": "'"$(basename "$device")"'"}' >&2
        load_modem_driver "generic"
    else
        if ! load_modem_driver "$modem_id"; then
            log_debug "Using generic driver for modem $modem_id"
        fi
    fi

    log_debug "Querying modem info"
    query_modem_info "$device"
}

case "${1:-query}" in
    "query")
        main
        ;;
    "detect")
        load_config
        echo "=== LED Modem Controller Device Detection ==="
        echo "Checking devices..."

        modem_id=$(get_modem_id_from_system)
        echo "Detected modem ID: $modem_id"
        
        load_modem_driver "$modem_id"
        if [ -n "$PREFERRED_TTY" ]; then
            echo "Preferred TTY: $PREFERRED_TTY"
        fi

        device=$(find_working_device)
        if [ -n "$device" ]; then
            echo "SUCCESS: Found working device"
            echo "Device: $device"
            echo "Type: $modem_id"
            echo "Driver: /usr/share/led-modem-controller/modem/usb/$modem_id"
        else
            echo "ERROR: No working device found"
            echo ""
            echo "Available devices:"
            available=$(get_available_devices)
            if [ -n "$available" ]; then
                for dev in $available; do
                    echo "  $dev (not responding to AT commands)"
                done
            else
                echo "  No ttyUSB/ttyACM devices found"
            fi
            exit 1
        fi
        ;;
    "test")
        load_config
        device="${2:-$(find_working_device)}"
        if [ -n "$device" ]; then
            echo "Testing device: $device"

            if [ ! -c "$device" ]; then
                echo "ERROR: Device does not exist"
                exit 1
            fi

            echo "Device exists: YES"

            if test_device_availability "$device"; then
                echo "Device responds to AT: YES"
                modem_type=$(detect_modem_type "$device")
                echo "Modem type: $modem_type"

                echo "Testing basic query..."
                load_modem_driver "$modem_type"
                query_modem_info "$device"
            else
                echo "Device responds to AT: NO"
                echo "Make sure the device is not in use by other applications"
                exit 1
            fi
        else
            echo "No device specified or found"
            exit 1
        fi
        ;;
    "config")
        load_config
        echo "=== LED Modem Controller Configuration ==="
        
        modem_id=$(get_modem_id_from_system)
        load_modem_driver "$modem_id"
        
        echo "Detected modem: $modem_id"
        if [ -n "$PREFERRED_TTY" ]; then
            echo "Preferred TTY: $PREFERRED_TTY"
        fi
        echo "Fallback devices: $FALLBACK_DEVICES"
        echo "Timeout: ${TIMEOUT}s"
        echo "Debug: $DEBUG"
        echo "Max errors: $MAX_ERRORS"
        echo "Cache timeout: ${CACHE_TIMEOUT}s"
        echo ""
        echo "LED paths:"
        echo "  4G Blue: $LED_4G_BLUE"
        echo "  4G Green: $LED_4G_GREEN"
        echo "  4G Yellow: $LED_4G_YELLOW"
        echo "  5G Blue: $LED_5G_BLUE"
        echo "  5G Yellow: $LED_5G_YELLOW"
        echo ""
        echo "Signal thresholds:"
        echo "  Excellent: $EXCELLENT_RSRP dBm"
        echo "  Good: $GOOD_RSRP dBm"
        ;;
    *)
        echo "Usage: $0 [query|detect|test [device]|config]"
        echo ""
        echo "Commands:"
        echo "  query   - Query modem and return JSON status"
        echo "  detect  - Detect and show working modem device"
        echo "  test    - Test specific device or auto-detect"
        echo "  config  - Show current configuration"
        exit 1
        ;;
esac