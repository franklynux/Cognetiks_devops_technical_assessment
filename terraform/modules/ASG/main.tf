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




