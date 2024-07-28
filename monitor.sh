#!/bin/bash

#Note: This script is intended to be run as root for maximum functionality but can be run as sudo user. 
#If the user is not root, the generated logfile will  not be saved
#Log file will be saved in /var/log/Monitor_logs




#Update existing packages or install new packages
printf "Installing necessary packages and updating packages\n"
sudo dnf update -y
printf "\n-------------------------------------------------------------\n"
sudo dnf install -y speedtest-cli sysstat lm_sensors
printf "\n-------------------------------------------------------------\n"
sudo systemctl enable sysstat
sudo systemctl start sysstat
printf "\n-------------------------------------------------------------\n\n"


#Check if fan speed and CPU temp sensors are detected and set boolean variable
yes | sudo sensors-detect --auto
SENSORS_DETECTED=false
if sensors | grep -q "fan"; then
    SENSORS_DETECTED=true
fi
if sensors | grep -q "Core"; then
    SENSORS_DETECTED=true
fi

#Get current timestamp
TIMESTAMP=$(date)

#Get CPU idleness value
CPU_OUT=$(mpstat 2 1| awk '$12 ~ /[0-9.]+/ { print (100 - $12)}')
# Extract the second number (CPU percentage)
CPU_USE=$(echo $CPU_OUT | awk '{print $2}')


#Get memory usage in percentage
MEM_USE=$(free | awk 'FNR == 2 {print $3/$2 * 100}')


#Check remaining disk space
DSK_SPC=$(df -h)


#Check average response time
PING_HOST="www.google.com"
PING_COUNT=5
AVG_RESPONSE_TIME=$(ping -c $PING_COUNT $PING_HOST | tail -1 | awk -F '/' '{print $5}')


#Get list of current users
ACTIVE_USER=$(who)


#Checks services status based on user input
printf "\n-------------------------------------------------------------\n\n"
read -p "Enter individual service names you would like to check separated by spaces: " -a SVC
SVC_STATUS="\n--------------------------------------------------------------\n"
for i in ${SVC[@]}; do
    SVC_STATUS+="$i: $(systemctl is-active $i)\n $(systemctl status -n 5 --no-pager $i) \n\n\n--------------------------------------------------------------\n\n\n"
done



#Set warning thresholds
CPU_LIMIT=90
MEM_LIMIT=90
TEMP_LIMIT=90
FAN_LIMIT=1000

#ensure log directory exists and set filename
LOG_DIR="/var/log/Monitor_logs"
mkdir -p "$LOG_DIR"

#Display the results and save to log file
{
    printf "\n \n \n Timestamp: $TIMESTAMP"
    printf "\n CPU Usage: $CPU_USE %%"
    printf "\n Memory Usage: $MEM_USE %%"
    printf "\n-------------------------------------------------------------\n"
    printf "\n Disk Space: $DSK_SPC"
    printf "\n-------------------------------------------------------------\n"
    printf "\n Average Response Time: $AVG_RESPONSE_TIME ms"
    printf "\n-------------------------------------------------------------\n"
    printf "\nActive Users:\n"
    printf "$ACTIVE_USER"
    printf "\n-------------------------------------------------------------\n\n"
    echo -e "Service Status:\n$SVC_STATUS"

#CPU temp and fan speed check kept seperate since VMs may not have requied sensors and some sensors may not be compatible with package

    if [ "$SENSORS_DETECTED" = true ]; then
        #Check CPU temperature and fan if sensors are detected
        CPU_TEMP=$(sensors| grep "Core")
        CPU_FAN=$(sensors| grep "fan")

        printf "\nCPU Temperature: $CPU_TEMP"
        printf "\nCPU Fan Speeds:"
        echo "$CPU_FAN"

        #test safety conditions
        if (( $(echo "$CPU_TEMP > $TEMP_LIMIT" | bc -l) )); then
            echo "Warning: high CPU temp!"
        fi
        while IFS= read -r line; do
            FAN_SPD=$(echo $line | awk '{print $2}')
            if (( $(echo "$FAN_SPD > $FAN_LIMIT" | bc -l) )); then
                echo "Warning: fan speed low ($line)"
            fi
        done <<< "$CPU_FAN"
        
    fi


    #Continue safety checks
    if (( $(echo "$CPU_USE > $CPU_LIMIT" | bc -l) )); then
        echo "Warning: high CPU usage!"
    fi

    if (( $(echo "$MEM_USE > $MEM_LIMIT" | bc -l) )); then
        echo "Warning: memory almost full!"
    fi


    #Save output to log file and display on terminal. Also change log file edit permissions
} | tee -a "$LOG_DIR/$(date +'%Y%m%d %H:%M:%S')_monitor.log"
sudo chown root:root $LOG_DIR/*.log
