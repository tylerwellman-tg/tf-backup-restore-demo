variable "instance_id" {
  description = "The EC2 instance ID to which we will run the restore SSM document."
  type        = string
}

variable "color" {
  description = "The color of the cluster for blue-green deployment strategy."
  type        = string
}

variable "bucket_arn" {
  description = "The ARN of the S3 bucket where backups are stored."
  type        = string
}

variable "backup_tag" {
  description = "The backup tag to identify the backup to be restored."
  type        = string
}

variable "backup_path" {
  description = "The local path where backups will be stored."
  type        = string
  default     = "/home/tigergraph/backups"
}

variable "metadata_path" {
  description = "The local path where metadata will be stored."
  type        = string
  default     = "/home/tigergraph/backups/metadata"
}

variable "sleep_interval" {
  description = "Time in seconds to wait between retries."
  type        = number
  default     = 5
}

variable "max_retries" {
  description = "Maximum number of retries for checking services."
  type        = number
  default     = 36
}
