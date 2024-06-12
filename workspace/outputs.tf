output "node_public_ips" {
  description = "The public IP addresses of all nodes"
  value = module.cluster_blue.node_public_ips
}

output "node_private_ips" {
  description = "The private IP addresses of all nodes"
  value = module.cluster_blue.node_private_ips
}