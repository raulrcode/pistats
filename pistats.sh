#!/bin/bash
# created by https://github.com/raulrcode/

dateFormat="%d.%m.%Y"
timeFormat="%H:%M:%S"
uplinkIpAddress="192.168.1.1"
hostName="$(hostname -f)"
cpuUsageData=$(ps -eo psr,%cpu | awk '
    $1 ~ /^[0-9]+$/ {
        cpu[$1] += $2
        count[$1]++
    }
    END {
        total = 0
        for (i in cpu) {
            total += cpu[i]
            printf "CPU%d: %.2f%% | ", i, cpu[i]
        }
        printf "\n%.2f%%", total / length(cpu)
    }')

cpuAverageUsage=$(echo "$cpuUsageData" | tail -n1)
cpuCoreUsage=$(echo "$cpuUsageData" | sed '$d')
dateTime=$(date +"$dateFormat | $timeFormat")
cpuFreq=$(vcgencmd measure_clock arm)
cpuTemp=$(vcgencmd measure_temp | sed 's/temp=//')
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
Hostname: $hostName
Date: $dateTime
CPU: $cpuGhz    | Load: $cpuAverageUsage | Temp: $cpuTemp
$cpuCoreUsage
RAM: Used $usedRam MB | Total $totalRam MB
Wi-Fi Level: $wifiQuality% | $uplinkStatus
EOF