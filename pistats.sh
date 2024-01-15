#!/bin/bash
# created by https://github.com/raulrcode/

dateFormat="%d.%m.%Y"
timeFormat="%H:%M:%S"
uplinkIpAddress="192.168.1.1"
cpuUsage=$(top -bn2 | grep '%Cpu' | tail -1 | grep -P '(....|...) id,' | awk '{printf "%.2f%%", 100-($8/4)}')
dateTime=$(date +"$dateFormat | $timeFormat")
cpuFreq=$(vcgencmd measure_clock arm)
cpuTemp=$(vcgencmd measure_temp | sed 's/temp=/Temp: /')
wifiQuality=$(iwconfig wlan0 | awk -F= '/Link Quality/{gsub("Signal level=", "", $2); split($2, arr, "/"); printf "%.0f", (arr[1]/arr[2])*100}')
totalRam="$(free -m | awk 'NR==2 {print $2}')"
usedRam="$(free -m | awk 'NR==2 {print $3}')"
# Extract the clock frequency in Hertz from the output
clock_frequency_hertz=$(echo "$cpuFreq" | cut -d= -f2)

# Convert Hertz to GHz
clock_frequency_ghz=$(echo "scale=9; $clock_frequency_hertz / 1000000000" | bc)

# Format the result to display 2 decimal places
cpuGhz=$(printf "%.2f GHz" "$clock_frequency_ghz")

# Function to check the uplink status
uplinkStatus=""
check_uplink() {
    if ping -c 1 -W 1 "$uplinkIpAddress" > /dev/null 2>&1; then
        uplinkStatus="Uplink: UP"
    else
        uplinkStatus="Uplink: ERROR DOWN"
    fi
}
check_uplink

# Print the stats
cat <<EOF
Date: $dateTime
CPU: $cpuGhz    | Load: $cpuUsage | $cpuTemp
RAM: Used $usedRam MB | Total $totalRam MB
Wi-Fi Level: $wifiQuality% | $uplinkStatus
EOF