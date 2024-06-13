output "instance_id" {
  value       = aws_instance.node[*].id
  description = "The instance id(s) of the node(s). Output is used for the ALB."
}

output "private_ip" {
  value       = aws_instance.node[*].private_ip
  description = "The private ip(s) of the node(s)."
}

output "instance_zone" {
  value       = aws_instance.node[*].availability_zone
  description = "List of the availability zones each instance belongs too."
}

output "document_name_install" {
  value       = aws_ssm_document.this.name
  description = "The name of the SSM document that installs TigerGraph."
}

output "iam_instance_profile" {
  value       = aws_iam_instance_profile.this.name
  description = "The name of the iam instance profile that the cluster will use for iam permissions."
}

# Outputs the private IP addresses of all nodes with descriptive keys (optional)
output "node_private_ips" {
  description = "The private IP addresses of all nodes"
  value = {
    for idx, instance in aws_instance.node :
    format("m%d", idx + 1) => instance.private_ip
  }
}

# Outputs the public IP addresses of all nodes with descriptive keys (optional)
output "node_public_ips" {
  description = "The public IP addresses of all nodes"
  value = {
    for idx, instance in aws_instance.node :
    format("m%d", idx + 1) => instance.public_ip
  }
}
