output "sns_topic_arn" {
  description = "ARN of the SNS topic for scaling alerts"
  value       = aws_sns_topic.scaling_alerts.arn
}

output "high_cpu_alarm_name" {
  description = "Name of the high CPU alarm"
  value       = aws_cloudwatch_metric_alarm.high_cpu.alarm_name
}

output "low_cpu_alarm_name" {
  description = "Name of the low CPU alarm"
  value       = aws_cloudwatch_metric_alarm.low_cpu.alarm_name
}