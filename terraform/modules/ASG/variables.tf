variable "name_prefix" {
    type =  string
    default =  "Django-App"
}

variable "key_name" {
    type =  string
    default =  "demo-key"
}

variable "vpc_security_group_ids" {
    type = list(string)
    description = "security group id"
  
}

variable "instance_type" {
    type =  string
    default =  "t2.micro"
}
  
variable "desired_capacity" {

    type =  number
    default =  2
}

variable "max_size" {

    type =  number
    default =  3
  
}

variable "min_size" {
    type =  number
    default =  1
}

variable "public_subnet_ids" {
    type = list(string)
    description = "List of public subnet IDs for bastion host"
}

variable "bastion_security_group_id" {
    type = string
    description = "Security group ID for bastion host from Networking module"
}

variable "private_subnet_ids" {
    type = list(string)
    description = "List of private subnet IDs for Django app instances"
}

variable "target_group_arn" {
    type = string
    description = "Target group ARN for ALB"
}