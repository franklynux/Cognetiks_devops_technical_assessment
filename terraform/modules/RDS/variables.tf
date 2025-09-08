variable "db_name" {
    description = "The name of the database to create"
    type = string
    default = "mydatabase"

}

variable "engine_version" {
    description = "The version of the database engine"
    type = string
    default = "12.7"
}

variable "instance_class" {
    description = "The instance type of the RDS instance"
    type = string
    default = "db.t3.micro"
  
}

variable "storage_type" {
    description = "The storage type for the RDS instance"
    type = string
    default = "gp2"
}

variable "allocated_storage" {
    description = "The allocated storage in gigabytes"
    type = number
    default = 20
}

variable "engine" {
    description = "The database engine to use"
    type = string
    default = "postgres"
}

variable "username" {
    description = "The username for the database"
    type = string
    default = "adminuser"
}

variable "password" {
    description = "The password for the database"
    type = string
    default = "adminpassword"
}

variable "rds_security_group_id" {
    description = "The security group ID to associate with the RDS instance"
    type = string
}   

variable "vpc_id" {
    description = "The VPC ID where the RDS instance will be deployed"
    type = string
}

variable "db_name" {
    description = "The name of the database to create"
    type = string
    default = "django_app_db"
}

variable "environment" {
    description = "Deployment environment (e.g., dev, prod)"
    type = string
    default = "dev"
}

variable "parameter_group_name" {
    description = "The name of the DB parameter group to associate"
    type = string
    default = "default.postgres12"
  
}

variable "private_subnet_3_id" {
    description = "The ID of the third private subnet"
    type = string
}

variable "private_subnet_4_id" {
    description = "The ID of the fourth private subnet"
    type = string
}
