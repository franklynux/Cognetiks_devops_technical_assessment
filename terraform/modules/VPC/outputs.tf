output "vpc_id" {
    value = aws_vpc.main.id
    description = "VPC ID"
}

output "public_subnet_ids" {   
    value = aws_subnet.public_subnets[*].id
    description = "List of Public Subnet IDs"
}

output "private_subnet_ids" {
    value = aws_subnet.private_subnets[*].id
    description = "List of Private Subnet IDs"
}

output "availability_zones" {
  value = data.aws_availability_zones.AZs.names
}

output "database_subnet_ids" {
  value = aws_subnet.database_subnets[*].id
  description = "List of Database Subnet IDs"
}