
output "app-lb-sg_id" {
    value = aws_security_group.app-lb-sg.id
    description = "The security group ID for the Application Load Balancer"

}

output "rds-sg_id" {
    value = aws_security_group.rds-sg.id
    description = "The security group ID for the RDS instance"
  
}

output "ec2-sg_id" {
    value = aws_security_group.ec2-sg.id
    description = "The security group ID for the EC2 instances"
  
}

