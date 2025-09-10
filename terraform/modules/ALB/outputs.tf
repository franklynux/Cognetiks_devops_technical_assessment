output "alb_arn" {
    value = aws_lb.app_lb.arn
    description = "The Application Load Balancer ARN"
}

output "alb_dns_name" {
    value = aws_lb.app_lb.dns_name
    description = "The Application Load Balancer DNS name"
}

output "target_group_arn" {
    value = aws_lb_target_group.app_tg.arn
    description = "The Target Group ARN"
}

