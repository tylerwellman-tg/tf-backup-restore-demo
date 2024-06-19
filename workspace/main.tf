terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>5.26.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.23.0"
    }
  }

  # Store terraform state in S3 bucket
  backend "s3" {
    bucket         = "terraform-state-20240612155609612300000001"
    key            = "terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state"
  }
}

provider "aws" {
  region = "us-east-1"
}

# Create S3 bucket and DynamoDB table to support terraform state locking and consistency checking
module "remote_state" {
  source = "../modules/remote-state"

  common_tags = var.common_tags
}

# Create network
module "network" {
  source = "../modules/network"

  common_tags        = var.common_tags
  vpc_cidr           = "10.0.0.0/16"
  availability_zones = ["us-east-1a", "us-east-1b"]
  public_subnets     = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets    = ["10.0.3.0/24", "10.0.4.0/24"]
}

# Generate a key pair locally to ssh into bastion host ec2 instance
## This module runs a script locally (on the machine running Terraform) not on the resource
## This is for demonstration purposes; always use best practices when handling keys
module "generate_key_pair" {
  source = "../modules/generate_key_pair"
}

module "tigergraph_packages" {
  source        = "../modules/s3"
  bucket_prefix = "tigergraph-packages-"
}

module "tigergraph_backups" {
  source        = "../modules/s3"
  bucket_prefix = "tigergraph-backups-"
}

module "cluster_blue" {
  source                          = "../modules/cluster"
  color                           = "blue"
  environment_tag                 = var.common_tags.Environment
  region                          = var.region
  machine_count                   = var.machine_count
  ami                             = var.ami
  instance_type                   = var.instance_type
  vpc_id                          = module.network.vpc_id
  node_disk_size_gb               = var.node_disk_size_gb
  public_key                      = var.public_key
  private_key                     = var.private_key
  az_allocate                     = var.az_allocate
  private_subnet_ids              = module.network.public_subnet_ids # For simplicaity, we are putting the cluster in a public subnet in this demo
  backup_s3_bucket_name           = module.tigergraph_backups.bucket_name
  backup_s3_bucket_arn            = module.tigergraph_backups.bucket_arn
  license                         = var.license
  tigergraph_packages_bucket_name = module.tigergraph_packages.bucket_name
  tigergraph_package_name         = var.tigergraph_package_name
  common_tags                     = var.common_tags
  bastion_cidr_blocks             = var.bastion_cidr_blocks
}

module "backup" {
  source      = "../modules/backup"
  color       = "blue"
  instance_id = module.cluster_blue.instance_id[0]
  bucket_arn  = module.tigergraph_backups.bucket_arn
}

module "cluster_green" {
  source                          = "../modules/cluster"
  color                           = "green"
  environment_tag                 = var.common_tags.Environment
  region                          = var.region
  machine_count                   = var.machine_count
  ami                             = var.ami
  instance_type                   = var.instance_type
  vpc_id                          = module.network.vpc_id
  node_disk_size_gb               = var.node_disk_size_gb
  public_key                      = var.public_key
  private_key                     = var.private_key
  az_allocate                     = var.az_allocate
  private_subnet_ids              = module.network.public_subnet_ids # For simplicaity, we are putting the cluster in a public subnet in this demo
  backup_s3_bucket_name           = module.tigergraph_backups.bucket_name
  backup_s3_bucket_arn            = module.tigergraph_backups.bucket_arn
  license                         = var.license
  tigergraph_packages_bucket_name = module.tigergraph_packages.bucket_name
  tigergraph_package_name         = var.tigergraph_package_name
  common_tags                     = var.common_tags
  bastion_cidr_blocks             = var.bastion_cidr_blocks
}

module "restore" {
  source      = "../modules/restore"
  color       = "green"
  instance_id = module.cluster_green.instance_id[0]
  bucket_arn  = module.tigergraph_backups.bucket_arn
  backup_tag  = "weekly-2024-06-19T193126"
}