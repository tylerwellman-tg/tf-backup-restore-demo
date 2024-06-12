# Create an S3 bucket to store TigerGraph Server software packages.
resource "aws_s3_bucket" "this" {
  bucket_prefix = var.bucket_prefix
}