variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default = {
    Owner     = "tse-tyler-wellman"
    Project   = "tf-backup-restore-demo"
    ManagedBy = "Terraform"
  }
}

variable "region" {
  type        = string
  description = "The region to deploy the cluster in."
  default     = "us-east-1"
}