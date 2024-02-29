#!/bin/bash
# created by https://github.com/raulrcode/

dateFormat="%d.%m.%Y"
timeFormat="%H:%M:%S"
dateTime=$(date +"$dateFormat | $timeFormat")
uplinkIpAddress="1.1.1.1"
hostName="$(hostname -f)"
wifiQuality=$(iwconfig wlan0 | awk -F= '/Link Quality/{gsub("Signal level=", "", $2); split($2, arr, "/"); printf "%.0f", (arr[1]/arr[2])*100}')

get_ram_usage() {
    totalRam="$(free -m | awk 'NR==2 {print $2}')"
    usedRam="$(free -m | awk 'NR==2 {print $3}')"
    ramLoad=$(awk "BEGIN {printf \"%.0f\", ($usedRam / $totalRam) * 100}")
}

get_cpu_usage() {
    mpstat -P ALL 1 1
}

get_cpu_stats() {
    local cpuUsageData=$(get_cpu_usage)
    model=$(grep "Model" /proc/cpuinfo | awk -F ': ' '{print $2}' | tr -s ' ' | sed 's/^ //')
    cpuFreq=$(vcgencmd measure_clock arm | awk -F= '{printf "%.2f GHz", $2 / 1000000000}')
    cpuTemp=$(vcgencmd measure_temp | sed 's/temp=//')
    cpuAverageUsage=$(echo "$cpuUsageData" | awk '$2 == "all" && $NF != "=" {printf "%.2f%%", 100 - $NF; exit}')
    cpuCoreUsage=$(echo "$cpuUsageData" | awk '/^Average:/{next} $2 ~ /^[0-9]+$/ && $NF != "=" {printf "CPU%s: %.2f%% | ", $2, 100 - $NF}' | awk '{print}')
}

get_storage_usage() {
    storageUsage=$(df -h / | tail -n 1 | awk '{print "Used:", $3, "| Total:", $2, "| Free:", $4}')
}

check_uplink() {
    if ping -c 1 -W 1 "$uplinkIpAddress" > /dev/null 2>&1; then
        uplinkStatus="ONLINE"
    else
        uplinkStatus="OFFLINE"
    fi
}

get_ram_usage
get_cpu_stats
get_storage_usage
check_uplink

cat <<EOF
Model: $model | Hostname: $hostName
Date: $dateTime
CPU: $cpuFreq | Load: $cpuAverageUsage | Temp: $cpuTemp
$cpuCoreUsage
RAM: Used $usedRam MB | Total $totalRam MB | Load: $ramLoad%
Storage: $storageUsage
Wi-Fi Level: $wifiQuality% | Uplink: $uplinkStatus
EOF