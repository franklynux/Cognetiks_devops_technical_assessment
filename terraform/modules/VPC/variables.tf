# Variables for VPC module configuration

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "vpc_name" {
  description = "Name for the VPC"
  type        = string
  default     = "Django_app_vpc"
}

variable "public_subnet_count" {
  description = "Number of public subnets"
  type        = number
  default     = 2
}

variable "private_subnet_count" {
  description = "Number of private subnets"
  type        = number
  default     = 4
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
}

variable "required_az_count" {
  description = "Minimum number of availability zones required"
  type        = number
  default     = 2
}

variable "availability_zones" {
  description = "List of availability zones to use (optional - will auto-select if not provided)"
  type        = list(string)
  default     = []
}

variable "max_azs" {
  description = "Maximum number of availability zones to use"
  type        = number
  default     = 3
}

variable "database_subnet_count" {
  description = "Number of database subnets"
  type        = number
  default     = 2
}

variable "database_subnet_cidrs" {
  description = "CIDR blocks for database subnets"
  type        = list(string)
  default     = ["10.0.20.0/24", "10.0.21.0/24"]
}