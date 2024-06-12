variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
}

variable "availability_zones" {
  description = "A list of availability zones in the region."
  type        = list(string)
}

variable "public_subnets" {
  description = "A list of public subnet CIDRs."
  type        = list(string)
}

variable "private_subnets" {
  description = "A list of private subnet CIDRs."
  type        = list(string)
}
