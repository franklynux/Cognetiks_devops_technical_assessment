output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = module.vpc.private_subnet_ids
}

output "bastion_security_group_id" {
  description = "Bastion host security group ID"
  value       = module.networking.bastion-sg_id
}

output "app_security_group_id" {
  description = "Application security group ID"
  value       = module.networking.ec2-sg_id
}

output "bastion_asg_name" {
  description = "Bastion host Auto Scaling Group name"
  value       = module.asg.bastion_asg_name
}

output "rds_endpoint" {
  description = "RDS endpoint URL"
  value = module.rds.rds_endpoint
}