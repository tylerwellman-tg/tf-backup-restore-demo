variable "bucket_arn" {
  description = "The arn of the bucket for storing backup data."
  type        = string
}

variable "color" {
  description = "The color of the cluster for blue-green deployment strategy."
  type        = string
}

variable "instance_id" {
  description = "The instance id of the node(s)."
  type        = string
}

# variable "secret" {
#   description = "The name of the secret storing iam access key id and iam secret access key."
#   type        = string
# }

# variable "bucket_prefix" {
#   description = "Prefix to use when creating the S3 bucket."
#   type        = string
#   default     = "backup"
# }