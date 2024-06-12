# Create an s3 bucket for remote backend
resource "aws_s3_bucket" "this" {
  bucket_prefix = "terraform-state-"

  tags = var.common_tags

  lifecycle {
    prevent_destroy = true
  }
}

# Apply server-side encryption by default
resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.bucket

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Enable versioning on s3 bucket
resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.bucket

  versioning_configuration {
    status = "Enabled"
  }
}

# Create dynamodb table for state-locking
resource "aws_dynamodb_table" "this" {
  name           = "terraform-state"
  read_capacity  = 5
  write_capacity = 5
  hash_key       = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  lifecycle {
    prevent_destroy = true
  }
}