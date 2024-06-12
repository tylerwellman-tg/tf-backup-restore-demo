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