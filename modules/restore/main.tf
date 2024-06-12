# Create the SSM document here
resource "aws_ssm_document" "this" {
  name          = "restore-to-${var.color}-cluster"
  document_type = "Command"

  content = jsonencode({
    schemaVersion = "2.2"
    description   = "Restore TigerGraph"
    parameters    = {}
    mainSteps = [
      {
        action = "aws:runShellScript"
        name   = "backupTigerGraph"
        inputs = {
          runCommand = [<<EOF

#!/bin/bash
# Set strict mode for better error handling
set -euo pipefail

# Configuration variables
BACKUP_PATH="/home/tigergraph/backups"
SLEEP_INTERVAL=5  # Time in seconds to wait between retries
MAX_RETRIES=36
RESTORE_S3_BUCKET="${var.bucket_arn}"
BACKUP_TAG="${var.backup_tag}"

# Ensure BACKUP_TAG is provided
if [[ -z "$BACKUP_TAG" ]]; then
    echo "Error: BACKUP_TAG environment variable is not set. Please set it to the directory you want to sync from S3."
    exit 1
fi

# Extract bucket name from ARN
RESTORE_S3_BUCKET_NAME=$(echo "$RESTORE_S3_BUCKET" | awk -F':' '{print $NF}')

# Function to log messages with timestamp
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# Function to run commands as the tigergraph user with the correct environment
run_as_tigergraph() {
    sudo -i -u tigergraph bash -c "$1"
}

# Function to create directory with proper permissions
create_directory() {
    local dir_path=$1
    mkdir -p "$dir_path"
    chown -R tigergraph:tigergraph "$dir_path"
}

# Function to check services status
check_services() {
    log "Checking service status..."
    local retries=0

    while (( retries < MAX_RETRIES )); do
        local output
        output=$(run_as_tigergraph "gadmin status")
        local all_services_online=true

        while IFS= read -r line; do
            if [[ "$line" =~ \| && ! "$line" =~ "Service Name" ]]; then
                local service_name service_status
                service_name=$(echo "$line" | awk -F'|' '{print $2}' | xargs)
                service_status=$(echo "$line" | awk -F'|' '{print $3}' | xargs)

                if [[ "$service_status" != "Online" ]]; then
                    if [[ "$service_status" == "Warmup" && ( "$service_name" == "GPE" || "$service_name" == "GSE" ) ]]; then
                        log "$service_name is in Warmup state, which is expected."
                    else
                        all_services_online=false
                        log "ERROR: $service_name is not fully online, current status: $service_status."
                    fi
                fi
            fi
        done <<< "$output"

        if [[ $all_services_online == true ]]; then
            log "All services are online or in expected Warmup state. Proceeding with the restore process."
            return 0
        else
            log "Not all services are online. Retrying in $SLEEP_INTERVAL seconds... (Attempt $((retries + 1))/$MAX_RETRIES)"
            sleep $SLEEP_INTERVAL
        fi
        ((retries++))
    done

    log "Services did not reach the expected state after $MAX_RETRIES attempts."
    return 1
}

# Function to download the backup and metadata files from S3
download_backup_and_metadata() {
    local s3_path="s3://$RESTORE_S3_BUCKET_NAME/$BACKUP_TAG/"
    local local_path="$BACKUP_PATH/$BACKUP_TAG"

    log "Creating local backup directory: $local_path"
    create_directory "$local_path"

    log "Downloading backup files from S3"
    aws s3 cp "$s3_path" "$local_path" --recursive --exclude "*" --include "*.tar.lz4" --include "*.json"

    # Log the directory structure to help debug issues with file paths
    log "Backup directory structure after S3 copy:"
    find "$local_path" -print
}

# Function to restore the backup
restore_backup() {
    local backup_tag=$1
    local backup_path="$BACKUP_PATH/$backup_tag"
    local metadata_file

    # Find the metadata file in the backup directory
    metadata_file=$(find "$backup_path" -type f -name "*.json" | head -n 1)

    if [[ -z "$metadata_file" ]]; then
        log "ERROR: Metadata file not found in $backup_path"
        exit 1
    fi

    log "Starting restore process from backup tag: $backup_tag with metadata file: $metadata_file"
    run_as_tigergraph "gadmin backup restore --meta=$metadata_file"
    log "Restore process completed successfully."

    log "Restarting TigerGraph services..."
    run_as_tigergraph "gadmin restart all -y"
}

# Function to validate services after restore
validate_services() {
    log "Validating services after restore..."
    if check_services; then
        log "TigerGraph services are running and restore is verified."
    else
        log "Failed to validate TigerGraph services after restore."
        exit 1
    fi
}

# Function to get graph stats
get_graph_stats() {
    local output_tag=$1
    local output_dir="$BACKUP_PATH/$output_tag"
    create_directory "$output_dir"

    local vertex_count=0
    local edge_count=0
    local output
    output=$(run_as_tigergraph "gstatusgraph")

    while IFS= read -r line; do
        if [[ "$line" =~ Vertex\ count ]]; then
            local v_count e_count
            v_count=$(echo "$line" | awk -F'Vertex count:' '{print $2}' | awk -F',' '{print $1}' | xargs)
            e_count=$(echo "$line" | awk -F'Edge count:' '{print $2}' | awk -F',' '{print $1}' | xargs)
            ((vertex_count+=v_count))
            ((edge_count+=e_count))
        fi
    done <<< "$output"

    log "Vertex Count: $vertex_count"
    log "Edge Count: $edge_count"

    # Save the counts to a JSON file in the output directory
    cat <<EOF_validation > "$output_dir/gstatusgraph_validation.json"
{
    "vertex_count": $vertex_count,
    "edge_count": $edge_count
}
EOF_validation
}

# Function to compare graph stats
compare_graph_stats() {
    local backup_tag=$1
    local backup_stats="$BACKUP_PATH/$backup_tag/gstatusgraph_validation.json"
    local restore_stats_dir="$BACKUP_PATH/$backup_tag/restore_validation"
    local restore_stats="$restore_stats_dir/gstatusgraph_validation.json"

    log "Fetching current graph stats for comparison..."
    get_graph_stats "restore_validation"

    if diff "$backup_stats" "$restore_stats"; then
        log "Graph stats match the backup validation."
    else
        log "Graph stats do not match the backup validation. Please check the differences."
        diff "$backup_stats" "$restore_stats"
        exit 1
    fi
}

# Main script execution
main() {
    log "Configuring backup settings and restarting services..."
    run_as_tigergraph "gadmin config set 'System.Backup.Local.Enable' 'true'"
    run_as_tigergraph "gadmin config set 'System.Backup.Local.Path' '$BACKUP_PATH'"
    run_as_tigergraph "gadmin config apply -y"
    run_as_tigergraph "gadmin restart all -y"

    log "Starting the restore process..."
    download_backup_and_metadata
    restore_backup "$BACKUP_TAG"
    validate_services

    log "Comparing graph stats between backup and restore..."
    compare_graph_stats "$BACKUP_TAG"

    log "Restore operations completed successfully."
}

# Run the main function
main



EOF
          ]
        }
    }]
  })
}

# Associate the SSM document with the target EC2 instance; this will immediately execute the document on the instance
resource "aws_ssm_association" "this" {
  name = aws_ssm_document.this.name

  targets {
    key    = "InstanceIds"
    values = [var.instance_id]
  }
}