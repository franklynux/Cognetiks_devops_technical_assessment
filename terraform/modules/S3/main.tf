resource "aws_s3_bucket" "bucket" {
  bucket = var.bucket_name
  force_destroy = true  # Allow the bucket to be destroyed even if it contains objects

  tags = {
    Name = var.bucket_name
    Environment = var.environment
  }

}

# S3 bucket for load balancer access logs
resource "aws_s3_bucket" "lb_logs" {
  bucket_prefix = "wordpress-lb-logs"
  force_destroy = true

  tags = {
    Name = "DigitalBoost-WordPress-LB-Logs"  # Updated to reflect the firm's name
  }
}

data "aws_elb_service_account" "main" {}

data "aws_caller_identity" "current" {}

resource "aws_s3_bucket_policy" "lb_logs_policy" {
  bucket = aws_s3_bucket.lb_logs.id

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "${data.aws_elb_service_account.main.arn}"
      },
      "Action": "s3:PutObject",
      "Resource": "arn:aws:s3:::${aws_s3_bucket.lb_logs.id}/*"
    },
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "delivery.logs.amazonaws.com"
      },
      "Action": "s3:PutObject",
      "Resource": "arn:aws:s3:::${aws_s3_bucket.lb_logs.id}/*",
      "Condition": {
        "StringEquals": {
          "s3:x-amz-acl": "bucket-owner-full-control"
        }
      }
    },
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "delivery.logs.amazonaws.com"
      },
      "Action": "s3:GetBucketAcl",
      "Resource": "arn:aws:s3:::${aws_s3_bucket.lb_logs.id}"
    }
  ]
}
POLICY
}