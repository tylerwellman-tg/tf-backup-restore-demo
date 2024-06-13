output "blue_cluster_private_ips" {
  description = "The private IP addresses of all nodes in the blue cluster"
  value = module.cluster_blue.node_private_ips
}

output "green_cluster_private_ips" {
  description = "The private IP addresses of all nodes in the green cluster"
  value = module.cluster_green.node_private_ips
}

output "blue_cluster_public_ips" {
  description = "The public IP addresses of all nodes in the blue cluster"
  value = module.cluster_blue.node_public_ips
}

output "green_cluster_public_ips" {
  description = "The public IP addresses of all nodes in the green cluster"
  value = module.cluster_green.node_public_ips
}
