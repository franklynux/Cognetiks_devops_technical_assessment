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

# Output only Private Subnet 3 (index 2)
output "private_subnet_3_id" {

  value = aws_subnet.private-subnets[2].id
  description = "Private Subnet 3 ID"

}

# Output only Private Subnet 4 (index 3)
output "private_subnet_4_id" {
  value = aws_subnet.private-subnets[3].id
  description = "Private Subnet 4 ID"
}