data "aws_ami" "ubuntu" {
    most_recent = true  # Get the most recent AMI
    owners      = ["099720109477"] # Canonical

    filter {
        name   = "name"
        values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]  # Filter for Ubuntu Jammy AMIs
    }

    filter {
        name   = "virtualization-type"
        values = ["hvm"]  # Filter for HVM virtualization type
    }

    filter {
        name   = "root-device-type"
        values = ["ebs"]  # Filter for EBS root device type
    }
}

resource "aws_launch_template" "app_asg_launch_template" {
    name_prefix = var.name_prefix
    image_id = data.aws_ami.ubuntu.id
    instance_type = var.instance_type
    key_name = var.key_name
    vpc_security_group_ids = var.vpc_security_group_ids
    user_data = filebase64("${path.module}/bin/django_app.sh") 

    tag_specifications {
        resource_type = "instance"
        tags = {
            Name = var.name_prefix
        }
    }

    iam_instance_profile {
    name = aws_iam_instance_profile.ec2_profile.name  # IAM instance profile for the EC2 instance
 }

    block_device_mappings {
    device_name = "/dev/sda1"  # Device name for the root volume
    ebs {
      volume_size = 10  # Size of the root volume in GB
      volume_type = "gp2"  # General Purpose SSD
    }
  }

}

resource "aws_autoscaling_group" "app_asg" {
    desired_capacity = var.desired_capacity
    max_size = var.max_size
    min_size = var.min_size
    force_delete = true
    vpc_zone_identifier = var.private_subnet_ids
    target_group_arns = [var.target_group_arn]
    health_check_type = "ELB"
    health_check_grace_period = 300
    
    launch_template {
        id = aws_launch_template.app_asg_launch_template.id
        version = aws_launch_template.app_asg_launch_template.latest_version
    }

    tag {
        key = "Name"
        value = var.name_prefix
        propagate_at_launch = true
    }
}       

resource "aws_autoscaling_policy" "target_tracking" {
    name = "app-asg-target-tracking"
    policy_type = "TargetTrackingScaling"
    autoscaling_group_name = aws_autoscaling_group.app_asg.name
    target_tracking_configuration {
        predefined_metric_specification {
            predefined_metric_type = "ASGAverageCPUUtilization"
        }
        target_value = 70.0
    }
}

# Bastion Host Launch Template
resource "aws_launch_template" "bastion_launch_template" {
    name_prefix   = "bastion-"
    image_id      = data.aws_ami.ubuntu.id
    instance_type = "t2.micro"
    key_name      = var.key_name
    vpc_security_group_ids = [var.bastion_security_group_id]

    tag_specifications {
        resource_type = "instance"
        tags = {
            Name = "bastion-host"
        }
    }
}

# Bastion Host Auto Scaling Group
resource "aws_autoscaling_group" "bastion_asg" {
    name                = "bastion-asg"
    vpc_zone_identifier = var.public_subnet_ids
    desired_capacity    = 1
    max_size           = 2
    min_size           = 1
    health_check_type  = "EC2"

    launch_template {
        id      = aws_launch_template.bastion_launch_template.id
        version = aws_launch_template.bastion_launch_template.latest_version
    }

    tag {
        key                 = "Name"
        value               = "bastion-host"
        propagate_at_launch = true
    }
}


# Create IAM role for EC2 instances
resource "aws_iam_role" "django_app_ec2_role" {
  name = "django_app_role_for_ssm_access"  # Name of the IAM role

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"  # Allow EC2 to assume this role
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"  # Principal service
        }
      }
    ]
  })
}

# Attach SSM read-only access policy to the role
resource "aws_iam_role_policy_attachment" "ssm_policy" {
  role       = aws_iam_role.django_app_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMReadOnlyAccess"
}

# Create an instance profile for the role
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "django_app_profile_ssm_access_${random_string.suffix.result}"
  role = aws_iam_role.django_app_ec2_role.name
}

# Generate a random suffix for the instance profile
resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}


