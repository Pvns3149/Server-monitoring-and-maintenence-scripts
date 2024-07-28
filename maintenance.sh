#!/bin/bash

# Configurations are as follows:
# Further configure log rotate file settings at /etc/logrotate.conf
# add files to backup on line 56 and customise backup destination on line 59


# Ensure package exists for log rotation
printf "\nInstalling necessary packages and updating packages"
printf "\n-------------------------------------------------------------\n"
sudo dnf -y install logrotate

# Update all system packages
printf "\n-------------------------------------------------------------\n\n"
printf "Updating system packages...\n\n"
sudo dnf update -y

# Clean unused cahces and packages
printf "\n-------------------------------------------------------------\n\n"
printf "Cleaning package cache...\n\n"
sudo dnf clean all
printf "\n-------------------------------------------------------------\n\n"
printf "Removing unused packages... \n\n\n"
sudo dnf autoremove -y
printf "\n-------------------------------------------------------------\n\n"


# Function to rotate logfiles
rotate_logs(){

    echo "Rotating log files..."
    if logrotate /etc/logrotate.conf 2> /tmp/logrotate_error.log; then
        echo "Log rotation completed."
    else
        echo "Log rotation failed."
        echo "Error details:"
        cat /tmp/logrotate_error.log
    fi

}


# Check if user wants to rotate logs 
read -p "Do you want to rotate logs? (y/n): " CHOICE
if [[ "$CHOICE" == "y" || "$CHOICE" == "Y" ]]; then
     rotate_logs
fi

printf "\n-------------------------------------------------------------\n\n"

#Check if user wants to backup system
read -p "Do you want to backup the system? (y/n) (Must have executed the file as root): " CHOICE
if [[ "$CHOICE" == "y" || "$CHOICE" == "Y" ]]; then
    #Backup files
    # Directories to backup
    DIRS_TO_BACKUP="/var/log"

 # Backup destination
    BACKUP_DEST="/backup/sysback"

   # Create backup directory if it doesn't exist
    mkdir -p $BACKUP_DEST
    
   

 

    # Create timestamp and backup file
    TIMESTAMP=$(date +"%Y%m%d%_H%M%S")
    BACKUP_FILE="$BACKUP_DEST/backup_$TIMESTAMP.tar.gz"

    # Create the backup
    if tar -czvf $BACKUP_FILE $DIRS_TO_BACKUP;then
        echo "Backup completed successfully. Backup file: $BACKUP_FILE"
    else
        echo "Backup failed."
    fi
    
fi


#Optionally reboot services
while true; do
    #ask user for target system or exit
    printf "\n-------------------------------------------------------------\n\n"
    read -p "Do you want to check specific service uptime? If yes, enter service name. Else enter n :" SRV_NAME
    if [[ "$SRV_NAME" == "n" || "$SRV_NAME" == "N" ]]; then
        printf "\nContinuing with system maintenance..."
        break
    else
        #display service uptime 
        printf "\nChecking last restarted timestamp for $SRV_NAME...\n"
        systemctl show "$SRV_NAME" --property=ActiveEnterTimestamp

        #ask if user wants to reboot the service
        read -p "Do you want to reboot the service? (y/n): " CHOICE
        if [[ "$CHOICE" == "y" || "$CHOICE" == "Y" ]]; then
            printf "\nRebooting the service...\n"
            sudo systemctl restart "$SRV_NAME"

            #show current status of the service to ensure its running
            echo "$(systemctl is-active $SRV_NAME)\n $(systemctl status -n 5 --no-pager $SRV_NAME)"
        fi
    fi
done



# Check system uptime
printf "\n\nSystem uptime: "
uptime
# Optionally reboot the system
read -p "Do you want to reboot the system? (y/n): " CHOICE
if [[ "$CHOICE" == "y" || "$CHOICE" == "Y" ]]; then
    echo "Rebooting the system..."
    sudo reboot
fi

echo "Maintenance tasks completed."