variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default = {
    Owner       = "tse-tyler-wellman"
    Project     = "tf-backup-restore-demo"
    ManagedBy   = "Terraform"
    Environment = "demo"
  }
}

variable "region" {
  type        = string
  description = "The region to deploy the cluster in."
  default     = "us-east-1"
}

variable "environment_tag" {
  type        = string
  description = "The tag name for the environment."
  default     = "Demo"
}

variable "machine_count" {
  type        = number
  description = "The number of instances to provision."
  default     = 4
}

variable "ami" {
  type        = string
  description = "The AMI we are using to provision an instance."
}

variable "instance_type" {
  type        = string
  description = "The instance type we are provisioning."
  default     = "m5.2xlarge"
}

variable "vpc_id" {
  type        = string
  description = "The ID of the VPC where the node's resources reside in."
  default     = ""
}

variable "node_disk_size_gb" {
  type        = number
  description = "The size of the disk on the instance in GB."
  default     = 120
}

variable "public_key" {
  type        = string
  description = "The public key used for the instance."
}

variable "private_key" {
  description = "The private key used to SSH into the instance."
  type        = string
  sensitive   = true
}

variable "az_allocate" {
  type        = list(string)
  description = "Specifies which availability zone the solution belongs too."
  default     = ["0", "0", "1", "1"]
}

variable "private_subnet_ids" {
  description = "List of IDs for the private subnets"
  type        = list(string)
  default     = [""]
}

variable "license" {
  description = "The license key provided by TigerGraph."
  type        = string
}

variable "tigergraph_package_name" {
  description = "The gzipped file name of the TigerGraph Server software package."
  type        = string
  default     = "tigergraph-3.9.1-offline.tar.gz"
}

variable "bastion_cidr_blocks" {
  type        = list(string)
  description = "The cidr blocks of the bastion host."
  default     = ["10.0.1.0/8"]
}