variable "sns_topic_name" {
  description = "Name for the SNS topic"
  type        = string
  default     = "asg-scaling-alerts"
}

variable "email_endpoints" {
  description = "List of email addresses for notifications"
  type        = list(string)
  default     = [chiwando3@outlook.com]
}

variable "asg_name" {
  description = "Name of the Auto Scaling Group to monitor"
  type        = string
}

variable "high_cpu_threshold" {
  description = "CPU threshold for scale out alarm"
  type        = number
  default     = 75
}

variable "low_cpu_threshold" {
  description = "CPU threshold for scale in alarm"
  type        = number
  default     = 25
}

variable "max_instances_threshold" {
  description = "Maximum instances threshold for scaling activity alarm"
  type        = number
  default     = 3
}