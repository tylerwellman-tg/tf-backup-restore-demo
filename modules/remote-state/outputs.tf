output "s3_bucket_name" {
  description = "The name of the S3 bucket for the Terraform remote backend"
  value       = aws_s3_bucket.this.bucket
}

output "dynamodb_table_name" {
  description = "The name of the DynamoDB table for Terraform state-locking"
  value       = aws_dynamodb_table.this.name
}
