output "s3_bucket_name" {
  description = "The name of the S3 bucket for the Terraform remote backend"
  value       = module.remote_state.s3_bucket_name
}

output "dynamodb_table_name" {
  description = "The name of the DynamoDB table for Terraform state-locking"
  value       = module.remote_state.dynamodb_table_name
}