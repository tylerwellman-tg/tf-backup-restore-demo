#!/usr/bin/env bash

set -e

LOG_FILE="/var/log/user_data.log"
exec > >(tee -a $LOG_FILE | logger -t user-data -s 2>/dev/console) 2>&1

echo "Starting user data script" > $LOG_FILE

PRIVATE_KEY_PATH="/home/ec2-user/.ssh/private_key.pem"

# Ensure the .ssh directory exists
mkdir -p /home/ec2-user/.ssh
echo "Created .ssh directory" >> $LOG_FILE

# Write the private key to the file
echo "${base64encode(var.private_key)}" | base64 --decode > $PRIVATE_KEY_PATH
chown ec2-user:ec2-user $PRIVATE_KEY_PATH
chmod 400 $PRIVATE_KEY_PATH
echo "Private key set up" >> $LOG_FILE

# Adding debug log before yum commands
echo "Starting yum update..." >> $LOG_FILE
RETRIES=5
until sudo yum update -y || [ $RETRIES -le 0 ]; do
  echo "Retrying yum update... attempts left: $RETRIES" >> $LOG_FILE
  RETRIES=$((RETRIES - 1))
  sleep 10
done
echo "Completed yum update" >> $LOG_FILE

# Adding debug log before yum install commands
echo "Starting yum install..." >> $LOG_FILE
RETRIES=5
until sudo yum install -y tar curl cronie iproute util-linux net-tools nmap-ncat coreutils openssh-clients openssh-server sshpass jq || [ $RETRIES -le 0 ]; do
  echo "Retrying yum install... attempts left: $RETRIES" >> $LOG_FILE
  RETRIES=$((RETRIES - 1))
  sleep 10
done
echo "Completed yum install" >> $LOG_FILE

# Adding debug log before yum upgrade commands
echo "Starting yum upgrade..." >> $LOG_FILE
RETRIES=5
until sudo yum upgrade -y || [ $RETRIES -le 0 ]; do
  echo "Retrying yum upgrade... attempts left: $RETRIES" >> $LOG_FILE
  RETRIES=$((RETRIES - 1))
  sleep 10
done
echo "Completed yum upgrade" >> $LOG_FILE

# Adding debug log for yum install unzip
echo "Installing unzip..." >> $LOG_FILE
RETRIES=5
until sudo yum install -y unzip || [ $RETRIES -le 0 ]; do
  echo "Retrying yum install unzip... attempts left: $RETRIES" >> $LOG_FILE
  RETRIES=$((RETRIES - 1))
  sleep 10
done
echo "Yum commands completed" >> $LOG_FILE

# Create watermark file to signal that user_data script has finished running
echo "Creating watermark file..." >> $LOG_FILE
touch /home/ec2-user/user_data_script_complete
echo "User data script complete" >> $LOG_FILE