
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
  source = "./modules/VPC"
  max_azs = 2
}

module "networking" {
  source = "./modules/Networking"
  vpc_id = module.vpc.vpc_id
}

module "asg" {
  source = "./modules/ASG"
  vpc_security_group_ids = [module.networking.ec2-sg_id]
  public_subnet_ids = module.vpc.public_subnet_ids
  bastion_security_group_id = module.networking.bastion-sg_id
  private_subnet_ids = [module.vpc.private_subnet_ids[0], module.vpc.private_subnet_ids[1]]
  target_group_arn = module.alb.target_group_arn
  key_name = var.key_name
}

module "alb" {
  source = "./modules/ALB"
  vpc_id = module.vpc.vpc_id
  app-lb-sg_id = module.networking.app-lb-sg_id
  public_subnet_ids = module.vpc.public_subnet_ids
}

module "rds" {
  source = "./modules/RDS"
  vpc_id = module.vpc.vpc_id
  rds_security_group_id = module.networking.rds-sg_id
  database_subnet_ids = module.vpc.database_subnet_ids
}

module "s3" {
  source = "./modules/S3"
}

module "cloudwatch" {
  source = "./modules/cloudwatch"
  asg_name = module.asg.asg_name
  email_endpoints = [var.notification_email]
}