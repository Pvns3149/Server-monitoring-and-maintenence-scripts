#!/bin/bash

#Update existing packages
sudo dnf update -y

# Install packages if not already installed
if ! command -v speedtest-cli &> /dev/null
then
    echo "speedtest-cli not found, installing..."
    sudo dnf install -y speedtest-cli
fi

if ! command -v sysstat &> /dev/null
then
    echo "sysstat not found, installing..."
    sudo dnf install -y sysstat
    sudo systemctl enable sysstat
    sudo systemctl start sysstat
fi

if ! command -v lm_sensors &> /dev/null
then
    echo "lm_sensors not found, installing..."
    sudo dnf install -y lm_sensors
fi


#Configure sensor
sudo sensors-detect --auto

#Get current timestamp
TIMESTAMP=$(date)

#Get CPU usage in percentage
CPU_USE=$(mpstat 2 1| awk '$12 ~ /[0-9.]+/ { print 100 - $12}')

#Get memory usage in percentage
MEM_USE=$(free | awk 'FNR == 2 {print $3/$2 * 100}')

#Check average response time
TOTAL_TIME=0

for i in $(seq 1 5); do
    START_TIME=$(date +%s%N)
    speedtest-cli --simple &> /dev/null
    END_TIME=$(date +%s%N)
    RESPONSE_TIME=$((END_TIME - START_TIME))
    TOTAL_TIME=$((TOTAL_TIME + RESPONSE_TIME))
done

AVG_RESPONSE_TIME=$((TOTAL_TIME / 5/10000000))

#Get list of current users
ACTIVE_USER=$(who)

#Checks services satus
SVC=("named" "httpd" "postfix" "dovecot" "smb" "sshd" "mariadb" "firewalld") \
SVC_STATUS="\n------------------------------------\n"
for i in ${SVC[@]}; do
    SVC_STATUS+="$i: $(systemctl is-active $i)\n $(systemctl status -n 5 --no-pager $i) \n\n"
done

#Check CPU temperature
CPU_TEMP=$(sensors| grep "Core")

#Check fan
CPU_FAN=$(sensors| grep "fan")

#Display the results
echo "Timestamp: $TIMESTAMP"
echo "CPU Usage: $CPU_USE%"
echo "Memory Usage: $MEM_USE%"
echo "Average Response Time: $AVG_RESPONSE_TIME ms"
echo "\nCPU Temperature: $CPU_TEMP"
echo "\nCPU Fan Speeds:"
echo "$CPU_FAN"
echo "\n\nActive Users:"
echo "$ACTIVE_USER"
echo -e "Service Status:\n$SVC_STATUS"


#Set warning thresholds
CPU_LIMIT=90
MEM_LIMIT=90
TEMP_LIMIT=90
FAN_LIMIT=1000

#Check for errant values and report
if (( $(echo "$CPU_USE > $CPU_LIMIT" | bc -l) )); then
    echo "Warning: high CPU usage!"
fi

if (( $(echo "$MEM_USE > $MEM_LIMIT" | bc -l) )); then
    echo "Warning: high memory usage!"
fi

if (( $(echo "$CPU_TEMP > $TEMP_LIMIT" | bc -l) )); then
    echo "Warning: high CPU temp!"
fi
while IFS= read -r line; do
    FAN_SPD=$(echo $line | awk '{print $2}')
    if (( FAN_SPD < FAN_LIMIT )); then
        echo "Warning: fan speed low ($line)"
    fi
done <<< "$CPU_FAN"






# Get current timestamp
#   TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")
  
#   # Get CPU usage
#   CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1"%"}')
  
#   # Get memory usage
#   MEM_USAGE=$(free -m | awk 'NR==2{printf "Memory Usage: %s/%sMB (%.2f%%)\n", $3,$2,$3*100/$2 }')
  
#   # Get disk usage
#   DISK_USAGE=$(df -h | awk '$NF=="/"{printf "Disk Usage: %d/%dGB (%s)\n", $3,$2,$5}')
  
#   # Print the results
#   echo "$TIMESTAMP"
#   echo "CPU Usage: $CPU_USAGE"
#   echo "$MEM_USAGE"
#   echo "$DISK_USAGE"
#   echo "-----------------------------"
  
#   # Optionally, log the results to a file
#   # echo "$TIMESTAMP CPU: $CPU_USAGE, $MEM_USAGE, $DISK_USAGE" >> /path/to/logfile.log
  


