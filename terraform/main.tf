
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"  # Specifies the AWS provider
      version = "~> 5.0"          # Specifies the version of the AWS provider
    }
  }
}

provider "aws" {
  region = "us-east-1"  # Set the AWS region to us-east-1
}

module "vpc" {
  source = "./modules/vpc"  # Path to the VPC module
}

module "Networking" {
  source = "./modules/Networking"  # Path to the Networking module
  vpc_id = module.vpc.vpc_id  # Pass the VPC ID from the VPC module to the Networking module
}

module "RDS" {
  source = "./modules/RDS"  # Path to the RDS module
  vpc_id = module.vpc.vpc_id  # Pass the VPC ID from the VPC module to the RDS module
  rds_security_group_id = module.Networking.rds_sg_id  # Pass the RDS security group ID from the Networking module to the RDS module
  private_subnet_3_id = module.vpc.private_subnet_3_id
  private_subnet_4_id = module.vpc.private_subnet_4_id
  
}

module "EC2" {
  source = "./modules/EC2"  # Path to the EC2 module
  vpc_id = module.vpc.vpc_id  # Pass the VPC ID from the VPC module to the EC2 module
  ec2_security_group_id = module.Networking.ec2_sg_id  # Pass the EC2 security group ID from the Networking module to the EC2 module
  public_subnet_ids = module.vpc.public_subnet_ids  # Pass the list of public subnet IDs from the VPC module to the EC2 module
  
}