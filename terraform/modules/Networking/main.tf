
# Security group for the Application Load Balancer
resource "aws_security_group" "app-lb-sg" {
    name = "Django-app-lb-SG"
    vpc_id = var.vpc_id
    description = "Security group for the Application Load Balancer"
    tags = {
      Name = "Django-app-lb-SG"
    }
}

# Allow inbound HTTP traffic on port 80 from anywhere
resource "aws_security_group_rule" "allow_HTTP_inbound" {
    type = "ingress"
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    security_group_id = aws_security_group.app-lb-sg.id
}

# Allow inbound HTTPS traffic on port 443 from anywhere
resource "aws_security_group_rule" "allow_HTTPS_inbound" {
    type = "ingress"
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    security_group_id = aws_security_group.app-lb-sg.id
}

# Allow all outbound traffic
resource "aws_security_group_rule" "allow_all_outbound" {
    type = "egress"
    from_port = 0
    to_port = 0
    protocol = "-1"  # -1 means all protocols
    cidr_blocks = ["0.0.0.0/0"]
    security_group_id = aws_security_group.app-lb-sg.id
}

# Security group for the RDS instance
resource "aws_security_group" "rds-sg" {
    name = "Django-RDS-SG"
    vpc_id = var.vpc_id
    description = "Security group for the RDS instance"
    tags = {
      Name = "Django-RDS-SG"
    }
}

# Allow inbound PostgreSQL traffic on port 5432 from the Application Load Balancer security group
resource "aws_security_group_rule" "allow_postgres_from_alb" {
    type = "ingress"
    from_port = 5432
    to_port = 5432
    protocol = "tcp"
    source_security_group_id = aws_security_group.app-lb-sg.id
    security_group_id = aws_security_group.rds-sg.id
}

# Allow all outbound traffic
resource "aws_security_group_rule" "allow_all_outbound_rds" {
    type = "egress"
    from_port = 0
    to_port = 0
    protocol = "-1"  # -1 means all protocols
    cidr_blocks = ["0.0.0.0/0"]
    security_group_id = aws_security_group.rds-sg.id
}

# Security group for the Django app servers (EC2 instances)
resource "aws_security_group" "ec2-sg" {  
    name = "Django-App-SG"
    vpc_id = var.vpc_id
    description = "Security group for the EC2 instances"
    tags = {
      Name = "Django-App-SG"
    }
}

# Allow inbound HTTP traffic on port 80 from the Application Load Balancer security group
resource "aws_security_group_rule" "allow_http_from_alb" {  
    type = "ingress"
    from_port = 80
    to_port = 80
    protocol = "tcp"
    source_security_group_id = aws_security_group.app-lb-sg.id
    security_group_id = aws_security_group.ec2-sg.id
}

# Allow inbound HTTPS traffic on port 443 from the Application Load Balancer security group
resource "aws_security_group_rule" "allow_https_from_alb" {  
    type = "ingress"
    from_port = 443
    to_port = 443
    protocol = "tcp"
    source_security_group_id = aws_security_group.app-lb-sg.id
    security_group_id = aws_security_group.ec2-sg.id
}

# Allow all outbound traffic
resource "aws_security_group_rule" "allow_all_outbound_ec2" {
    type = "egress"
    from_port = 0
    to_port = 0
    protocol = "-1"  # -1 means all protocols
    cidr_blocks = ["0.0.0.0/0"] # Allow outbound traffic to anywhere
    security_group_id = aws_security_group.ec2-sg.id
}

# Security group for the Bastion Host
resource "aws_security_group" "bastion-sg" {
    name = "Bastion-Host-SG"
    vpc_id = var.vpc_id
    description = "Security group for the Bastion Host"
    tags = {
      Name = "Bastion-Host-SG"
    }
}

# Allow inbound SSH traffic on port 22 from anywhere
resource "aws_security_group_rule" "allow_ssh_inbound" {
    type = "ingress"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    security_group_id = aws_security_group.bastion-sg.id
}

# Allow all outbound traffic
resource "aws_security_group_rule" "allow_all_outbound_bastion" {
    type = "egress"
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    security_group_id = aws_security_group.bastion-sg.id
}