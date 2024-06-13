# Create the SSM document here
resource "aws_ssm_document" "this" {
  name          = "restore-to-${var.color}-cluster"
  document_type = "Command"

  content = jsonencode({
    schemaVersion = "2.2"
    description   = "Restore TigerGraph"
    parameters    = {}
    mainSteps = [
      {
        action = "aws:runShellScript"
        name   = "backupTigerGraph"
        inputs = {
          runCommand = [templatefile("../scripts/restore.sh.tftpl", {
            bucket_arn = var.bucket_arn,
            backup_tag = var.backup_tag
          })]
        }
    }]
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