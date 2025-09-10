variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "django-app"
}

variable "key_name" {
  description = "EC2 Key Pair name"
  type        = string
  default     = "demo-key"
}

variable "notification_email" {
  description = "Email for notifications"
  type        = string
  default     = "admin@example.com"
}