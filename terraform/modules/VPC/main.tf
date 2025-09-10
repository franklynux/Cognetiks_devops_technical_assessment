resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name = var.vpc_name
  }
}

# Get list of Availability Zones in a Region
data "aws_availability_zones" "AZs" {
    state = "available"  # Filter for available availability zones
    filter {
      name   = "opt-in-status"
      values = ["opt-in-not-required"]  # Only include zones that do not require opt-in
    }
}

# Flexible AZ selection logic
locals {
  # Use provided AZs or auto-select from available ones
  selected_azs = length(var.availability_zones) > 0 ? var.availability_zones : slice(data.aws_availability_zones.AZs.names, 0, min(length(data.aws_availability_zones.AZs.names), var.max_azs))
}

# Validate that there are at least 2 AZs available
resource "terraform_data" "az_validation" {
  lifecycle {
    precondition {
      condition     = length(local.selected_azs) >= var.required_az_count
      error_message = "Need at least ${var.required_az_count} availability zones. Selected: ${length(local.selected_azs)}"
    }
  }
}

# Create Public Subnets
resource "aws_subnet" "public_subnets" {
  count                   = var.public_subnet_count
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = local.selected_azs[count.index % length(local.selected_azs)]
  map_public_ip_on_launch = true
  tags = {
    Name = "public_subnet_${count.index + 1}"
  }
}

# Create an Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "Django_igw"
  }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id
    tags = {
        Name = "public_rt"
    }
}

# Create a route in the public route table to direct internet-bound traffic to the Internet Gateway
resource "aws_route" "igw_route" {
  route_table_id         = aws_route_table.public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
  depends_on = [aws_internet_gateway.igw]  # Ensure the internet gateway is created first
}

resource "aws_route_table_association" "public_rt_assoc" {
  count          = var.public_subnet_count
  subnet_id      = aws_subnet.public_subnets[count.index].id
  route_table_id = aws_route_table.public_rt.id
}



# Create Private Subnets
resource "aws_subnet" "private_subnets" {
  count                   = var.private_subnet_count
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.private_subnet_cidrs[count.index]
  availability_zone       = local.selected_azs[count.index % length(local.selected_azs)]
  map_public_ip_on_launch = false
  tags = {
    Name = "private_subnet_${count.index + 1}"
  }
}

# Create a NAT Gateway in the first public subnet
resource "aws_nat_gateway" "private_natGW_1" {
  allocation_id = aws_eip.nat_eip_1.id
  subnet_id    = aws_subnet.public_subnets[0].id  # Use public subnet
  tags = {
    Name = "private_natGW_1"
  }
}

# Create an Elastic IP for the NAT Gateway 1
resource "aws_eip" "nat_eip_1" {
  domain = "vpc"  # Specify that the Elastic IP is for a VPC
  tags = {
    Name = "nat_eip_1"
  }
}


# Create a NAT Gateway in the second public subnet
resource "aws_nat_gateway" "private_natGW_2" {
  allocation_id = aws_eip.nat_eip_2.id
  subnet_id    = aws_subnet.public_subnets[1].id  # Use public subnet
  tags = {
    Name = "private_natGW_2"
  }
}

# Create an Elastic IP for the NAT Gateway 2
resource "aws_eip" "nat_eip_2" {
  domain = "vpc"  # Specify that the Elastic IP is for a VPC
  tags = {
    Name = "nat_eip_2"
  }
}

# Create Route Tables for Private Subnets
resource "aws_route_table" "private_rt_1" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "private_rt_1"
  }
}

resource "aws_route_table" "private_rt_2" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "private_rt_2"
  }
}

# Create Routes for Private Route Tables to use NAT Gateways
resource "aws_route" "nat_route_1" {
  route_table_id         = aws_route_table.private_rt_1.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.private_natGW_1.id
  depends_on = [aws_internet_gateway.igw]  # Ensure the internet gateway is created first
}

resource "aws_route" "nat_route_2" {
  route_table_id         = aws_route_table.private_rt_2.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.private_natGW_2.id
  depends_on = [aws_internet_gateway.igw]  # Ensure the internet gateway is created first
}   

# Associate Private Subnets with their respective Route Tables
resource "aws_route_table_association" "private_rt_assoc" {
  count          = var.private_subnet_count
  subnet_id      = aws_subnet.private_subnets[count.index].id
  route_table_id = count.index % 2 == 0 ? aws_route_table.private_rt_1.id : aws_route_table.private_rt_2.id
}

# Database Subnets (isolated for security, no internet access)
resource "aws_subnet" "database_subnets" {
  count             = var.database_subnet_count
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.database_subnet_cidrs[count.index]
  availability_zone = local.selected_azs[count.index % length(local.selected_azs)]
  map_public_ip_on_launch = false
  tags = {
    Name = "database_subnet_${count.index + 1}"
  }
}

# Route table for database subnets (local VPC traffic only)
resource "aws_route_table" "database_rt" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "database_rt"
  }
}

# Associate Database Subnets with database route table
resource "aws_route_table_association" "database_rt_assoc" {
  count          = var.database_subnet_count
  subnet_id      = aws_subnet.database_subnets[count.index].id
  route_table_id = aws_route_table.database_rt.id
}