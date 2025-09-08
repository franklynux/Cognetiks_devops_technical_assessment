# SNS Topic for scaling notifications
resource "aws_sns_topic" "scaling_alerts" {
  name = var.sns_topic_name
  tags = {
    Name = var.sns_topic_name
  }
}

# SNS Topic subscription
resource "aws_sns_topic_subscription" "email_notification" {
  count     = length(var.email_endpoints)
  topic_arn = aws_sns_topic.scaling_alerts.arn
  protocol  = "email"
  endpoint  = var.email_endpoints[count.index]
}

# CloudWatch Alarm for High CPU (Scale Out)
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "${var.asg_name}-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/AutoScaling"
  period              = "300"
  statistic           = "Average"
  threshold           = var.high_cpu_threshold
  alarm_description   = "High CPU utilization - scaling out"
  alarm_actions       = [aws_sns_topic.scaling_alerts.arn]

  dimensions = {
    AutoScalingGroupName = var.asg_name
  }
}

# CloudWatch Alarm for Low CPU (Scale In)
resource "aws_cloudwatch_metric_alarm" "low_cpu" {
  alarm_name          = "${var.asg_name}-low-cpu"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/AutoScaling"
  period              = "300"
  statistic           = "Average"
  threshold           = var.low_cpu_threshold
  alarm_description   = "Low CPU utilization - scaling in"
  alarm_actions       = [aws_sns_topic.scaling_alerts.arn]

  dimensions = {
    AutoScalingGroupName = var.asg_name
  }
}

# CloudWatch Alarm for ASG scaling activities
resource "aws_cloudwatch_metric_alarm" "scaling_activity" {
  alarm_name          = "${var.asg_name}-scaling-activity"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "GroupTotalInstances"
  namespace           = "AWS/AutoScaling"
  period              = "60"
  statistic           = "Maximum"
  threshold           = var.max_instances_threshold
  alarm_description   = "ASG scaling activity detected"
  alarm_actions       = [aws_sns_topic.scaling_alerts.arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    AutoScalingGroupName = var.asg_name
  }
}