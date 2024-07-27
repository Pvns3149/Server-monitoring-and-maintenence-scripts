#!/bin/bash

#Update existing packages or install new packages
sudo dnf update -y
sudo dnf install -y speedtest-cli sysstat lm_sensors
sudo systemctl enable sysstat
sudo systemctl start sysstat


#Configure sensor
# sudo sensors-detect --auto

# if sensors | grep -q "Adapter"; then
#     SENSORS_DETECTED=true
# else
#     SENSORS_DETECTED=false
# fi

#Get current timestamp
TIMESTAMP=$(date)

#Get CPU usage in percentage
CPU_USE=$(mpstat 2 1| awk '$12 ~ /[0-9.]+/ { print (100 - $12)}')

#Get memory usage in percentage
MEM_USE=$(free | awk 'FNR == 2 {print $3/$2 * 100}')

#Check average response time
PING_HOST="www.google.com"
PING_COUNT=5
AVG_RESPONSE_TIME=$(ping -c $PING_COUNT $PING_HOST | tail -1 | awk -F '/' '{print $5}')

#Get list of current users
ACTIVE_USER=$(who)

#Checks services satus
SVC=("named" "httpd" "postfix" "dovecot" "smb" "sshd" "mariadb" "firewalld") \
SVC_STATUS="\n--------------------------------------------------------------\n"
for i in ${SVC[@]}; do
    SVC_STATUS+="$i: $(systemctl is-active $i)\n $(systemctl status -n 5 --no-pager $i) \n\n\n\n"
done



#Set warning thresholds
CPU_LIMIT=90
MEM_LIMIT=90
TEMP_LIMIT=90
FAN_LIMIT=1000


#Display the results

printf "\n \n \n Timestamp: $TIMESTAMP"
printf "\n CPU Usage: $CPU_USE %%"
printf "\n Memory Usage: $MEM_USE %%"
printf "\n Average Response Time: $AVG_RESPONSE_TIME ms"
printf "\n------------------------------------------------------------------------------------------------------------\n"
printf "\n \n Active Users:"
printf "$ACTIVE_USER"
printf "\n------------------------------------------------------------------------------------------------------------\n"
printf "\n \n"
echo -e "Service Status:\n$SVC_STATUS"

printf $CPU_USE



#Check for errant values and report
if ( $(echo "$CPU_USE > $CPU_LIMIT" | bc -l) ); then
    echo "Warning: high CPU usage!"
fi

if ( $(echo "$MEM_USE > $MEM_LIMIT" | bc -l) ); then
    echo "Warning: high memory usage!"
fi


# if (SENSORS_DETECTED); then
#     #Check CPU temperature and fan if sensors are detected
#     CPU_TEMP=$(sensors| grep "Core")
#     CPU_FAN=$(sensors| grep "fan")
#     echo "\nCPU Temperature: $CPU_TEMP"
#     echo "\nCPU Fan Speeds:"
#     echo "$CPU_FAN"
#     if (( $(echo "$CPU_TEMP > $TEMP_LIMIT" | bc -l) )); then
#         echo "Warning: high CPU temp!"
#     fi
#     while IFS= read -r line; do
#         FAN_SPD=$(echo $line | awk '{print $2}')
#         if (( FAN_SPD < FAN_LIMIT )); then
#             echo "Warning: fan speed low ($line)"
#         fi
#     done <<< "$CPU_FAN"
    
# fi




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
  


