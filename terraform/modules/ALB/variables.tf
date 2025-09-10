variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "app-lb-sg_id" {
  description = "Security group ID for the ALB"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs"
  type        = list(string)
}