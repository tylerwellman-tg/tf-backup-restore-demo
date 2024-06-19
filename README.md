# tf-backup-restore-demo
The tf-backup-restore-demo repository demonstrates how to replace nodes in a TigerGraph cluster using Terraform and a blue-green deployment model. This ensures minimal downtime and seamless transitions during updates or maintenance.

# Infrastructure
This deployment uses a blue-green model to maintain high availability and reliability. The primary components include:

1. **Backup and Restore Modules:** Handles the backup of the existing TigerGraph data and the restoration onto the new nodes.
1. **Cluster Modules (Blue and Green):** Provisions and manages the TigerGraph clusters in the designated AWS environment.
1. **Network Module:** Configures the necessary networking components, including VPCs and subnets.
1. **Key Pair Module:** Generates and manages SSH key pairs for secure access to instances.
1. **Remote State Module:** Manages Terraform remote state configuration.
1. **S3 Modules:** Manages S3 buckets used for storing TigerGraph backups and packages.

# Repository Structure

This section provides a detailed overview of the repository structure, helping you understand the organization and purpose of each directory and file.

```
.
├── README.md
├── modules
│   ├── backup
│   │   ├── main.tf
│   │   └── variables.tf
│   ├── cluster
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   ├── variables.tf
│   │   └── versions.tf
│   ├── generate_key_pair
│   │   └── main.tf
│   ├── network
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   └── variables.tf
│   ├── remote-state
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   └── variables.tf
│   ├── restore
│   │   ├── main.tf
│   │   └── variables.tf
│   └── s3
│       ├── main.tf
│       ├── output.tf
│       └── variables.tf
├── scripts
│   ├── backup.sh.tftpl
│   ├── generate_key_pair.sh
│   ├── install_tigergraph.sh.tftpl
│   ├── restore.sh.tftpl
│   └── user_data.sh
└── workspace
    ├── main.tf
    ├── outputs.tf
    ├── terraform.tfvars
    └── variables.tf
```

## Root Directory

**README.md:** This file contains the documentation for the repository, including an overview, setup instructions, and detailed descriptions of the inputs, outputs, and modules.

## Modules Directory

The `modules` directory contains subdirectories for each Terraform module used in this project. Each module is responsible for a specific part of the infrastructure.

- **backup:** Manages the backup process for the TigerGraph data.

    main.tf: Core configuration for the backup module.
    variables.tf: Defines the input variables for the backup module.

- **cluster:** Provisions and manages the TigerGraph clusters.

    main.tf: Core configuration for the cluster module.
    outputs.tf: Defines the output variables for the cluster module.
    variables.tf: Defines the input variables for the cluster module.
    versions.tf: Specifies the required provider versions.

- **generate_key_pair:** Generates SSH key pairs for instance access.

    main.tf: Core configuration for the key pair generation module.

- **network:** Configures the network infrastructure, including VPCs and subnets.

    main.tf: Core configuration for the network module.
    outputs.tf: Defines the output variables for the network module.
    variables.tf: Defines the input variables for the network module.

- **remote-state:** Manages Terraform remote state configuration.

    main.tf: Core configuration for the remote state module.
    outputs.tf: Defines the output variables for the remote state module.
    variables.tf: Defines the input variables for the remote state module.

- **restore:** Manages the restoration process of the TigerGraph data.

    main.tf: Core configuration for the restore module.
    variables.tf: Defines the input variables for the restore module.

- **s3:** Manages S3 buckets used for storing TigerGraph backups and packages.

    main.tf: Core configuration for the S3 module.
    output.tf: Defines the output variables for the S3 module.
    variables.tf: Defines the input variables for the S3 module.

## Scripts Directory

The `scripts` directory contains shell scripts and templates used for various setup and management tasks.

- **backup.sh.tftpl:** Template script for performing backups.
- **generate_key_pair.sh:** Script for generating SSH key pairs.
- **install_tigergraph.sh.tftpl:** Template script for installing TigerGraph.
- **restore.sh.tftpl:** Template script for performing restorations.
- **user_data.sh:** Script for configuring instances at launch.

## Workspace Directory

The `workspace` directory contains the main Terraform configuration for deploying the infrastructure.

- **main.tf:** Core configuration for the workspace.
- **outputs.tf:** Defines the output variables for the workspace.
- **terraform.tfvars:** Defines the values for the input variables.
- **variables.tf:** Defines the input variables for the workspace.

# Getting Started

To get started with deploying the TigerGraph cluster replacement using this Terraform configuration, follow the steps below:

## Prerequisites
Ensure you have the following prerequisites installed and configured:
1. Terraform v0.13 or later
1. AWS CLI configured with appropriate permissions
1. Valid TigerGraph license key
1. SSH key pair for instance access

## Steps
1. **Clone the Repository**
1. **Initialize Terraform**
    - `terraform init`
1. **Configure Input Variables:**
    - Review and update the `variables.tf` file or create a `terraform.tfvars` file to set the necessary input variables, such as `ami`, `license`, `private_key`, and `public_key`.
1. **Plan the Deployment:**
    - Generate and review the execution plan to ensure the infrastructure matches your expectations.
    - `terraform plan`
1. **Apply the Deployment:**
    - Apply the Terraform configuration to create the infrastructure.
    - `terraform apply`
1. **Access the Deployed Infrastructure:**
    - Once the deployment is complete, you can access the TigerGraph clusters using the provided IP addresses. Use the SSH key pair to connect to the instances for further configuration or maintenance.

## Providers

| Name | Version |
|------|---------|
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~>5.26.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_backup"></a> [backup](#module\_backup) | ../modules/backup | n/a |
| <a name="module_cluster_blue"></a> [cluster\_blue](#module\_cluster\_blue) | ../modules/cluster | n/a |
| <a name="module_cluster_green"></a> [cluster\_green](#module\_cluster\_green) | ../modules/cluster | n/a |
| <a name="module_generate_key_pair"></a> [generate\_key\_pair](#module\_generate\_key\_pair) | ../modules/generate_key_pair | n/a |
| <a name="module_network"></a> [network](#module\_network) | ../modules/network | n/a |
| <a name="module_remote_state"></a> [remote\_state](#module\_remote\_state) | ../modules/remote-state | n/a |
| <a name="module_restore"></a> [restore](#module\_restore) | ../modules/restore | n/a |
| <a name="module_tigergraph_backups"></a> [tigergraph\_backups](#module\_tigergraph\_backups) | ../modules/s3 | n/a |
| <a name="module_tigergraph_packages"></a> [tigergraph\_packages](#module\_tigergraph\_packages) | ../modules/s3 | n/a |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_ami"></a> [ami](#input\_ami) | The AMI we are using to provision an instance. | `string` | n/a | yes |
| <a name="input_az_allocate"></a> [az\_allocate](#input\_az\_allocate) | Specifies which availability zone the solution belongs too. | `list(string)` | <pre>[<br>  "0",<br>  "0",<br>  "1",<br>  "1"<br>]</pre> | no |
| <a name="input_bastion_cidr_blocks"></a> [bastion\_cidr\_blocks](#input\_bastion\_cidr\_blocks) | The cidr blocks of the bastion host. | `list(string)` | <pre>[<br>  "10.0.1.0/8"<br>]</pre> | no |
| <a name="input_common_tags"></a> [common\_tags](#input\_common\_tags) | Common tags for all resources | `map(string)` | <pre>{<br>  "Environment": "demo",<br>  "ManagedBy": "Terraform",<br>  "Owner": "tse-tyler-wellman",<br>  "Project": "tf-backup-restore-demo"<br>}</pre> | no |
| <a name="input_environment_tag"></a> [environment\_tag](#input\_environment\_tag) | The tag name for the environment. | `string` | `"Demo"` | no |
| <a name="input_instance_type"></a> [instance\_type](#input\_instance\_type) | The instance type we are provisioning. | `string` | `"m5.2xlarge"` | no |
| <a name="input_license"></a> [license](#input\_license) | The license key provided by TigerGraph. | `string` | n/a | yes |
| <a name="input_machine_count"></a> [machine\_count](#input\_machine\_count) | The number of instances to provision. | `number` | `4` | no |
| <a name="input_node_disk_size_gb"></a> [node\_disk\_size\_gb](#input\_node\_disk\_size\_gb) | The size of the disk on the instance in GB. | `number` | `120` | no |
| <a name="input_private_key"></a> [private\_key](#input\_private\_key) | The private key used to SSH into the instance. | `string` | n/a | yes |
| <a name="input_private_subnet_ids"></a> [private\_subnet\_ids](#input\_private\_subnet\_ids) | List of IDs for the private subnets | `list(string)` | <pre>[<br>  ""<br>]</pre> | no |
| <a name="input_public_key"></a> [public\_key](#input\_public\_key) | The public key used for the instance. | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | The region to deploy the cluster in. | `string` | `"us-east-1"` | no |
| <a name="input_tigergraph_package_name"></a> [tigergraph\_package\_name](#input\_tigergraph\_package\_name) | The gzipped file name of the TigerGraph Server software package. | `string` | `"tigergraph-3.9.1-offline.tar.gz"` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | The ID of the VPC where the node's resources reside in. | `string` | `""` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_blue_cluster_private_ips"></a> [blue\_cluster\_private\_ips](#output\_blue\_cluster\_private\_ips) | The private IP addresses of all nodes in the blue cluster |
| <a name="output_blue_cluster_public_ips"></a> [blue\_cluster\_public\_ips](#output\_blue\_cluster\_public\_ips) | The public IP addresses of all nodes in the blue cluster |
| <a name="output_green_cluster_private_ips"></a> [green\_cluster\_private\_ips](#output\_green\_cluster\_private\_ips) | The private IP addresses of all nodes in the green cluster |
| <a name="output_green_cluster_public_ips"></a> [green\_cluster\_public\_ips](#output\_green\_cluster\_public\_ips) | The public IP addresses of all nodes in the green cluster |