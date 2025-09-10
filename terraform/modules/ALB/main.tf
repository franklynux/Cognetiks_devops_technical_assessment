resource "aws_lb" "app_lb" {
  name               = "Django-app-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    =  [var.app-lb-sg_id]
  subnets            = var.public_subnet_ids
  ip_address_type    = "ipv4"
  enable_http2       = true
  idle_timeout       = 60

  enable_deletion_protection = false

  tags = {
    Name = "Django-app-lb"
  }
}

resource "aws_lb_target_group" "app_tg" {
  name     = "Django-app-TG"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  target_type = "instance"

  health_check {
    enabled             = true
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200-399"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
  depends_on = [aws_lb.app_lb]
  deregistration_delay = 150

  tags = {
    Name = "Django-app-tg"
  }
}

resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.app_lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
  depends_on = [aws_lb.app_lb]
}