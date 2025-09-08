output "alb_arn" {
    value = aws_lb.wp-lb.arn
    description = "The Application Load Balancer ARN"
  
}

output "alb_dns_name" {
    value = aws_lb.wp-lb.dns_name
    description = "The Application Load Balancer DNS name"
  
}

