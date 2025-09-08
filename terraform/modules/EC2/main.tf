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