#!/usr/bin/env bash

# Global Variables
BASE_DIRECTORY="/home/ec2-user"
INSTALLATION_DIR="$BASE_DIRECTORY/tigergraph-installation"
LOG_FILE="/var/log/tigergraph_install.log"
PRIVATE_KEY_PATH="/home/ec2-user/.ssh/private_key.pem"

# Passed Variables
S3_BUCKET="${tigergraph_packages_bucket_name}"
PACKAGE_NAME="${tigergraph_package_name}"
LICENSE="${license}"
NODE_IPS="${node_ips}"

# Function to print error message and exit
error_exit() {
    echo "ERROR: $1" 1>&2
    echo "ERROR: $1" >> $LOG_FILE
    exit 1
}

# Ensure the script is running as root or with sudo
ensure_root() {
    if [[ $EUID -ne 0 ]]; then
        error_exit "This script must be run as root"
    fi
}

# Wait for the user data script to complete
wait_for_user_data() {
    while [ ! -f $BASE_DIRECTORY/user_data_script_complete ]; do
        echo "Waiting for user data script to complete..." >> $LOG_FILE
        sleep 5
    done
}

# Create necessary directories and set permissions
create_directories() {
    echo "Creating necessary directories..." >> $LOG_FILE
    # Create installation directory if it doesn't exist
    if [ ! -d "$INSTALLATION_DIR" ]; then
        mkdir -p "$INSTALLATION_DIR"
        chown ec2-user:ec2-user "$INSTALLATION_DIR"
        echo "Created and set ownership for $INSTALLATION_DIR" >> $LOG_FILE
    fi

    # Ensure the log directory and file are writable
    if [ ! -d "$(dirname "$LOG_FILE")" ]; then
        mkdir -p "$(dirname "$LOG_FILE")"
    fi
    touch "$LOG_FILE"
    chown ec2-user:ec2-user "$LOG_FILE"
    chmod 664 "$LOG_FILE"
    echo "Ensured $LOG_FILE is writable" >> $LOG_FILE
}

# Download TigerGraph package from S3
download_tigergraph() {
    echo "Downloading TigerGraph package..." >> $LOG_FILE
    if ! aws s3 cp s3://$S3_BUCKET/$PACKAGE_NAME $BASE_DIRECTORY/tigergraph-package.tar.gz; then
        error_exit "Failed to download TigerGraph package"
    fi
    echo "Downloaded TigerGraph package successfully." >> $LOG_FILE
}

# Extract the downloaded package
extract_package() {
    local tarfile="$BASE_DIRECTORY/tigergraph-package.tar.gz"

    echo "Extracting TigerGraph package..." >> $LOG_FILE

    if [ ! -f "$tarfile" ]; then
        error_exit "Package file not found"
    fi

    if ! tar -xzf "$tarfile" -C $BASE_DIRECTORY > /dev/null; then
        error_exit "Failed to extract package"
    fi

    local extracted_dir=$(tar -tf "$tarfile" | grep / | head -1 | cut -f1 -d"/")
    if [ -d "$BASE_DIRECTORY/$extracted_dir" ]; then
        mv "$BASE_DIRECTORY/$extracted_dir" "$INSTALLATION_DIR"
    else
        error_exit "Extracted directory not found"
    fi

    echo "Extracted and renamed TigerGraph package successfully." >> $LOG_FILE

    chown -R ec2-user:ec2-user $INSTALLATION_DIR
    echo "Ownership of tigergraph-installation set to ec2-user" >> $LOG_FILE
}

# Configure TigerGraph
configure_tigergraph() {
    local private_key_path="$PRIVATE_KEY_PATH"
    local extracted_dir=$(tar -tf "$BASE_DIRECTORY/tigergraph-package.tar.gz" | grep / | head -1 | cut -f1 -d"/")

    echo "Configuring TigerGraph..." >> $LOG_FILE

    cat > $INSTALLATION_DIR/$extracted_dir/install_conf.json <<EOT
{
  "BasicConfig": {
    "TigerGraph": {
      "Username": "tigergraph",
      "Password": "tigergraph",
      "SSHPort": 22,
      "PrivateKeyFile": "$private_key_path",
      "PublicKeyFile": ""
    },
    "RootDir": {
      "AppRoot": "/home/tigergraph/tigergraph/app",
      "DataRoot": "/home/tigergraph/tigergraph/data",
      "LogRoot": "/home/tigergraph/tigergraph/log",
      "TempRoot": "/home/tigergraph/tigergraph/tmp"
    },
    "License": "$LICENSE",
    "NodeList": $(echo "$NODE_IPS" | jq -c '[.[] | {Node: .}]')
  },
  "AdvancedConfig": {
    "ClusterConfig": {
      "LoginConfig": {
        "SudoUser": "ec2-user",
        "Method": "K",
        "P": "sudoUserPassword",
        "K": "$private_key_path"
      },
      "ReplicationFactor": 2
    }
  }
}
EOT

    # Debugging: Output the JSON to the log file
    echo "Generated install_conf.json:" >> $LOG_FILE
    cat $INSTALLATION_DIR/$extracted_dir/install_conf.json >> $LOG_FILE

    echo "Configured TigerGraph successfully." >> $LOG_FILE
}

# Install TigerGraph
install_tigergraph() {
    local extracted_dir=$(tar -tf "$BASE_DIRECTORY/tigergraph-package.tar.gz" | grep / | head -1 | cut -f1 -d"/")
    
    echo "Installing TigerGraph..." >> $LOG_FILE

    cd $INSTALLATION_DIR

    echo "Listing directory structure before running install.sh:" >> $LOG_FILE
    ls -R $INSTALLATION_DIR >> $LOG_FILE

    if [ -f $INSTALLATION_DIR/$extracted_dir/install.sh ]; then
        if ! sudo bash $INSTALLATION_DIR/$extracted_dir/install.sh -n >> $LOG_FILE 2>&1; then
            error_exit "Installation failed, check $LOG_FILE for details"
        fi
    else
        error_exit "Installation script not found in $INSTALLATION_DIR"
    fi

    if ! sudo chmod o+rx "$(pwd)" > /dev/null; then
        error_exit "Failed to change permissions"
    fi

    echo "Installed TigerGraph successfully." >> $LOG_FILE

    echo "Switching user to tigergraph..." >> $LOG_FILE
    sudo -u tigergraph /bin/bash <<'EOF_TIGERGRAPH'
    set -e

    LOG_FILE="/var/log/tigergraph_install.log"

    export PATH=/home/tigergraph/tigergraph/app/cmd/:$PATH

    echo "Restarting TigerGraph services..." >> $LOG_FILE
    if ! gadmin restart all -y > /dev/null; then
        error_exit "Failed to restart TigerGraph service"
    fi

    echo "Checking TigerGraph services status..." >> $LOG_FILE
    if ! gadmin status -v > /dev/null; then
        error_exit "Failed to check gadmin status"
    fi

    echo "TigerGraph services restarted and verified successfully." >> $LOG_FILE

EOF_TIGERGRAPH
}

# Main script execution
ensure_root
create_directories
wait_for_user_data
download_tigergraph
extract_package
configure_tigergraph
install_tigergraph

echo "Script execution completed successfully." >> $LOG_FILE
