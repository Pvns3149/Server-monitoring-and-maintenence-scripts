#!/bin/bash

#configurations are as follows
#configure log rotate files at /etc/logrotate.d/logrotate.conf after first run
#configure logs to rotate at line 64

rotate_logs(){
    # Rotate files
    echo "Rotating log files..."
    sudo logrotate -f /etc/logrotate.d/logrotate.conf
    sudo logrotate -f /etc/logrotate.d/httpd
}

# Ensure package exists for log rotation
sudo dnf -y install logrotate

# Update all system packages
echo "Updating system packages..."
sudo dnf update -y

# Clean unused cahces and packages
echo "Cleaning package cache..."
sudo dnf clean all
printf "Removing unused packages... \n\n\n"
sudo dnf autoremove -y

# Check if user wants to rotate logs ?
read -p "Do you want to rotate logs? (y/n): " CHOICE
if [[ "$CHOICE" == "y" || "$CHOICE" == "Y" ]]; then

    # Check if logrotate config file exists
    LOGROTATE_CONF="/etc/logrotate.d/logrotate.conf"
    if [ -f "$LOGROTATE_CONF" ]; then
        echo "Logrotate configuration file already exists at $LOGROTATE_CONF."
        rotate_logs
    
    
    else

        # Create logrotate config file
        LOGROTATE_CONF="/etc/logrotate.d/logrotate.conf"
        echo "Creating logrotate configuration file at $LOGROTATE_CONF..."
        sudo tee $LOGROTATE_CONF > /dev/null <<EOL

        #file can be updated to include configurations to rotate logs for other services in the same format
        "/home/Puvan/Documents/Monitoring/*.log" {
            daily
            rotate 1
            compress
            missingok
            notifempty
            create 0640 root root
            postrotate
            endscript
        }
        "/var/log/httpd/*.log" {
            daily
            rotate 1
            compress
            missingok
            notifempty
            create 0640 root root
            postrotate
                systemctl reload httpd
            endscript
        }
EOL 
        rotate_logs
    fi


    
    
fi

#Check if user wants to backup system
read -p "Do you want to backup the system? (y/n) (Must have executed the file as root): " CHOICE
if [[ "$CHOICE" == "y" || "$CHOICE" == "Y" ]]; then
    #Backup files
    # Directories to backup
    DIRS_TO_BACKUP="/var/log"

    # Backup destination
    BACKUP_DEST="/backup"

    # Create backup directory if it doesn't exist
    mkdir -p $BACKUP_DEST

    # Create timestamp and backup file
    TIMESTAMP=$(date +"%Y%m%d%_H%M%S")
    BACKUP_FILE="$BACKUP_DEST/backup_$TIMESTAMP.tar.gz"

    # Create the backup
    tar -czvf $BACKUP_FILE $DIRS_TO_BACKUP
    echo "Backup completed successfully. Backup file: $BACKUP_FILE"
fi


#Optionally reboot services
while true; do
    #ask user for target system or exit
    read -p "Do you want to check specific service uptime? If yes, enter service name. Else enter n :" SRV_NAME
    if [[ "$SRV_NAME" == "n" || "$SRV_NAME" == "N" ]]; then
        echo "Continuing with system maintenance..."
        break
    else
        #display service uptime 
        echo "Checking last restarted timestamp for $SRV_NAME..."
        systemctl show "$SRV_NAME" --property=ActiveEnterTimestamp

        #ask if user wants to reboot the service
        read -p "Do you want to reboot the service? (y/n): " CHOICE
        if [[ "$CHOICE" == "y" || "$CHOICE" == "Y" ]]; then
            echo "Rebooting the service..."
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