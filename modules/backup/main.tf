resource "aws_ssm_document" "this" {
  name          = "backup-${var.color}-cluster"
  document_type = "Command"

  content = jsonencode({
    schemaVersion = "2.2",
    description   = "Backup TigerGraph Cluster and Upload to S3",
    mainSteps = [
      {
        action = "aws:runShellScript",
        name   = "backupTigerGraph",
        inputs = {
          runCommand = [templatefile("${path.module}/../../scripts/backup.sh.tftpl", {
            bucket_arn = var.bucket_arn
          })]
        }
      }
    ]
  })
}

# Associate the SSM document with the target EC2 instance; this will immediately execute the document on the instance
resource "aws_ssm_association" "this" {
  name = aws_ssm_document.this.name

  targets {
    key    = "InstanceIds"
    values = [var.instance_id]
  }
}
