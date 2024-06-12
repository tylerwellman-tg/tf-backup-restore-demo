# Create an S3 bucket policy to allow the SSMBackupRole access.
resource "aws_s3_bucket_policy" "this" {
  bucket = var.backup_s3_bucket_name

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:PutObject",
          "s3:ListBucket",
          "s3:GetObject",
          "s3:GetBucketLocation"
        ],
        Principal = {
          AWS = aws_iam_role.this.arn
        },
        Resource = [
          "${var.backup_s3_bucket_arn}",
          "${var.backup_s3_bucket_arn}/*"
        ]
      }
    ]
  })
}

# Define an IAM role policy for SSM backup, granting permissions for S3 bucket
resource "aws_iam_role_policy" "this" {
  name = "SSMBackupPolicy"
  role = aws_iam_role.this.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        # Permissions for S3 bucket access
        Action = [
          "s3:PutObject",
          "s3:ListBucket",
          "s3:GetObject",
          "s3:GetBucketLocation"
        ],
        Effect = "Allow",
        Resource = [
          "${var.backup_s3_bucket_arn}",
          "${var.backup_s3_bucket_arn}/*"
        ]
      },
      {
        Action   = "s3:GetObject",
        Effect   = "Allow",
        Resource = "arn:aws:s3:::${var.tigergraph_packages_bucket_name}/*"
      }
    ]
  })
}

# Create an IAM role for EC2 with a policy to assume roles for EC2 and SSM services.
resource "aws_iam_role" "this" {
  name = "SSMRoleForEC2-${var.color}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Principal = {
          Service = [
            "ec2.amazonaws.com",
            "ssm.amazonaws.com"
          ]
        },
        Effect = "Allow",
        Sid    = ""
      }
    ]
  })
}

# Attach the AWS managed policy for AmazonEC2RoleforSSM to the created IAM role.
resource "aws_iam_role_policy_attachment" "this" {
  role       = aws_iam_role.this.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"
}

# Create an instance profile for EC2 instances to allow them to use the specified IAM role.
resource "aws_iam_instance_profile" "this" {
  name = "TigerGraphInstallBackupRestore-${var.color}"
  role = aws_iam_role.this.name
}

# Create a security group with restrictive traffic rules.
resource "aws_security_group" "security_group" {
  name_prefix = "${var.environment_tag}-restrictive-"
  description = "Allow restrictive traffic"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow access from same security group."
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.environment_tag}-restrictive"
  }
}

# Create a public key pair for use with AWS instances.
resource "aws_key_pair" "public_key" {
  key_name_prefix = "${var.environment_tag}-public-key"
  public_key      = var.public_key
}

# Fetch information about subnets based on the VPC ID.
data "aws_subnets" "subnets" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }
}

resource "aws_instance" "node" {
  count                  = var.machine_count
  iam_instance_profile   = aws_iam_instance_profile.this.name
  ami                    = var.ami
  instance_type          = var.instance_type
  key_name               = aws_key_pair.public_key.key_name
  vpc_security_group_ids = [aws_security_group.security_group.id]

  subnet_id = (
    var.az_allocate == null ? var.private_subnet_ids[0] : var.private_subnet_ids[parseint(var.az_allocate[count.index], 10)]
  )

  metadata_options {
    instance_metadata_tags = "enabled"
    http_endpoint          = "enabled"
  }

  root_block_device {
    volume_type           = "gp2"
    volume_size           = var.node_disk_size_gb
    delete_on_termination = true
  }

  tags = {
    Name = "${var.color}-${var.environment_tag}-node-m${count.index + 1}"
  }

  user_data = file("../scripts/user_data.sh")
}

locals {
  formatted_node_ips = [
    for i in range(var.machine_count) : format("\"m%d: %s\"", i + 1, aws_instance.node[i].private_ip)
  ]
}

resource "aws_ssm_document" "this" {
  name          = "install-tigergraph-on-${var.color}-cluster"
  document_type = "Command"

  content = jsonencode({
    schemaVersion = "2.2",
    description   = "Install and Configure TigerGraph",
    parameters    = {},
    mainSteps = [
      {
        action = "aws:runShellScript",
        name   = "installTigerGraph",
        inputs = {
          runCommand = [templatefile("${path.module}/../../scripts/install_tigergraph.sh.tftpl", {
            tigergraph_packages_bucket_name = var.tigergraph_packages_bucket_name,
            tigergraph_package_name = var.tigergraph_package_name,
            license = var.license,
            node_list_json = jsonencode(local.formatted_node_ips),
            private_key = var.private_key
          })]
        }
      }
    ]
  })
}


# Attach the created SSM document to the target EC2 instances, executing it immediately.
resource "aws_ssm_association" "this" {
  depends_on = [aws_instance.node[0]]
  name       = aws_ssm_document.this.name

  targets {
    key    = "InstanceIds"
    values = [aws_instance.node[0].id]
  }
}
