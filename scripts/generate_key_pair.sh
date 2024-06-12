#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status
set -e

# Function to print error message and exit
error_exit() {
    echo "$1" 1>&2
    exit 1
}

# Generate a temporary key pair without a password
ssh-keygen -t rsa -b 4096 -f key -m 'PEM' -N "" || error_exit "Error generating key pair."

# Ensure the local key directory exists
mkdir -p ./.ssh/keys/ || error_exit "Error creating the keys directory."

# Move and rename each key to the local key directory
mv key ./.ssh/keys/private_key.pem || error_exit "Error moving private key."
mv key.pub ./.ssh/keys/public_key.pub || error_exit "Error moving public key."

# Set appropriate permissions for the local keys
chmod 400 ./.ssh/keys/private_key.pem ./.ssh/keys/public_key.pub || error_exit "Error setting permissions on the keys."

echo "Keys generated and stored successfully to: $(pwd)/.ssh/keys/"