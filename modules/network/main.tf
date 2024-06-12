# Create a VPC with the specified CIDR block
resource "aws_vpc" "this" {
  cidr_block = var.vpc_cidr

  tags = merge(
    var.common_tags,
    {
      Name = var.common_tags["Project"]
    }
  )
}

# Create public subnets within the VPC for hosting public-facing resources like a Load Balancer
resource "aws_subnet" "public" {
  count = length(var.availability_zones)

  vpc_id                  = aws_vpc.this.id
  cidr_block              = element(var.public_subnets, count.index)
  availability_zone       = element(var.availability_zones, count.index)
  map_public_ip_on_launch = true

  tags = merge(
    var.common_tags,
    {
      Name       = "${var.common_tags["Project"]}-public-${element(var.availability_zones, count.index)}"
      SubnetType = "Public"
    }
  )
}

# Create private subnets within the VPC for hosting internal resources
resource "aws_subnet" "private" {
  count = length(var.availability_zones)

  vpc_id                  = aws_vpc.this.id
  cidr_block              = element(var.private_subnets, count.index)
  availability_zone       = element(var.availability_zones, count.index)
  map_public_ip_on_launch = true

  tags = merge(
    var.common_tags,
    {
      Name       = "${var.common_tags["Project"]}-private-${element(var.availability_zones, count.index)}"
      SubnetType = "public-tigergraph-nodes"
    }
  )
}

# Define a security group within the VPC
# resource "aws_security_group" "this" {
#   vpc_id = aws_vpc.this.id
#   tags   = var.common_tags
# }

resource "aws_security_group" "this" {
  name        = "allow-web-and-ssh"
  description = "Allow web traffic and SSH from anywhere"
  vpc_id      = aws_vpc.this.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTP traffic from anywhere"
  }

  ingress {
    from_port   = 14240
    to_port     = 14240
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow custom app traffic from anywhere"
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow SSH access from anywhere"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }
  tags = var.common_tags
}


# Attach an internet gateway to the VPC, enabling connectivity from the VPC to the internet
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
  tags   = var.common_tags
}

# Allocate an Elastic IP for the NAT Gateway
resource "aws_eip" "this" {
  domain = "vpc"
  tags   = var.common_tags
}

# # Establish a NAT Gateway to allow internet access for instances in the private subnet
# resource "aws_nat_gateway" "this" {
#   allocation_id = aws_eip.this.id
#   subnet_id     = aws_subnet.public[0].id
#   tags          = var.common_tags
# }

# Define a route table for the public subnets, routing traffic through the internet gateway
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  tags   = var.common_tags

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }
}

# Associate the public subnets with the public route table
resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public.*.id)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Define a route table for the private subnets, routing traffic through the internet gateway
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id
  tags   = var.common_tags

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }
}

# Associate the private subnets with the private route table
resource "aws_route_table_association" "private" {
  count          = length(aws_subnet.private.*.id)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}
