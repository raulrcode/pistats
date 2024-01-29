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
    local model=$1

    if [ -n "$(echo "$model" | grep -i "Raspberry Pi 4\|Raspberry Pi 5")" ]; then
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
    elif [ -n "$(echo "$model" | grep -i "Raspberry Pi 3\|Raspberry Pi Zero")" ]; then
        cpuUsageData=$(ps -eo psr,%cpu | awk '
            $1 ~ /^[0-9]+$/ {
                cpu[$1] += $2
                count[$1]++
            }
            END {
                total = 0
                for (i in cpu) {
                    avg = cpu[i] / count[i]
                    total += avg
                    printf "CPU%d: %.2f%% | ", i, avg
                }
                printf "\n%.2f%%", total / length(cpu)
            }')
    else
        echo "Unsupported Raspberry Pi model: $model"
        exit 1
    fi

    echo "$cpuUsageData"
}

get_cpu_stats() {
    local model=$(grep -i "Model" /proc/cpuinfo | awk -F ': ' '{print $2}' | tr -s ' ' | sed 's/^ //')
    cpuUsageData=$(get_cpu_usage "$model")
    cpuFreq=$(vcgencmd measure_clock arm | awk -F= '{printf "%.2f GHz", $2 / 1000000000}')
    cpuTemp=$(vcgencmd measure_temp | sed 's/temp=//')
    cpuAverageUsage=$(echo "$cpuUsageData" | tail -n1)
    cpuCoreUsage=$(echo "$cpuUsageData" | sed '$d')
}

check_uplink() {
    if ping -c 1 -W 1 "$uplinkIpAddress" > /dev/null 2>&1; then
        uplinkStatus="Uplink: UP"
    else
        uplinkStatus="Uplink: ERROR DOWN"
    fi
}

get_ram_usage
get_cpu_stats
check_uplink

cat <<EOF
Hostname: $hostName
Date: $dateTime
CPU: $cpuFreq | Load: $cpuAverageUsage | Temp: $cpuTemp
$cpuCoreUsage
RAM: Used $usedRam MB | Total $totalRam MB | Load: $ramLoad%
Wi-Fi Level: $wifiQuality% | $uplinkStatus
EOF