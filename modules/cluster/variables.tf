variable "environment_tag" {
  type        = string
  description = "The tag name for the environment."
}

variable "region" {
  type        = string
  description = "The region to deploy the cluster in."
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
}

variable "vpc_id" {
  type        = string
  description = "The ID of the VPC where the node's resources reside in."
}

variable "node_disk_size_gb" {
  type        = number
  description = "The size of the disk on the instance in GB."
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
  default     = []
}

variable "private_subnet_ids" {
  description = "List of IDs for the private subnets"
  type        = list(string)
}

variable "color" {
  description = "The color of the cluster for blue-green deployment strategy."
  type        = string
}

variable "bastion_cidr_blocks" {
  type        = list(string)
  description = "The cidr blocks of the bastion host."
}

variable "backup_s3_bucket_name" {
  description = "The name of the S3 bucket that stores TigerGraph backup data."
  type        = string
}

variable "backup_s3_bucket_arn" {
  description = "The ARN of the S3 bucket that stores TigerGraph backup data."
  type        = string
}

variable "tigergraph_packages_bucket_name" {
  description = "The name of the s3 bucket to get TigerGraph Server software packages."
  type        = string
}

variable "tigergraph_package_name" {
  description = "The gzipped file name of the TigerGraph Server software package."
  type        = string
  default     = "tigergraph-3.9.1-offline.tar.gz"
}

variable "bucket_prefix" {
  description = "Prefix to use when creating the S3 bucket."
  type        = string
  default     = "backup"
}

variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
}

variable "license" {
  description = "The license key provided by TigerGraph."
  type        = string
}
