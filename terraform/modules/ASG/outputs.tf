output "asg_name" {
  description = "Name of the Auto Scaling Group"
  value       = aws_autoscaling_group.app_asg.name
}

output "asg_arn" {
  description = "ARN of the Auto Scaling Group"
  value       = aws_autoscaling_group.app_asg.arn
}

output "bastion_asg_name" {
  description = "Name of the bastion Auto Scaling Group"
  value       = aws_autoscaling_group.bastion_asg.name
}