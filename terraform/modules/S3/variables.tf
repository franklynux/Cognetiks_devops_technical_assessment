variable "bucket_name" {
    description = "s3 bucket name"
    type = string
    default = "django-app-alb-logs"
  
}

variable "region" {
    description = "AWS region"
    type = string
    default = "us-east-1"
}

variable "environment" {
    description = "Deployment environment (e.g., dev, prod)"
    type = string
    default = "dev"
}