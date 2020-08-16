## launch configuration for this webserver
module "launch-configuration" {
  source = "../common/launch_config"

  name   = "webserver"
  layer  = "web"
  port   = 8080
}

## security group for the ALB
module "alb_security_group" {
  source = "../common/security-group/inbound-outbound"

  layer = "web"
  name = "server.alb"

  // inbound config
  inbound_port = {
    from = 80
    to   = 80
  }

  // Allow all outbound
  outbound_protocol = "-1"
  outbound_port = {
    from = 0
    to   = 0
  }
}


## creates the ASG
resource "aws_autoscaling_group" "webserver-asg" {
  launch_configuration = module.launch-configuration.name
  vpc_zone_identifier  = module.launch-configuration.subnet-ids

  target_group_arns = [aws_lb_target_group.webserver-tg.arn]
  health_check_type = "ELB"

  min_size = 2
  max_size = 4
}

## creating the ALB
resource "aws_lb" "webserver-lb" {
  name                = "webserver-alb"
  load_balancer_type  = "application"
  subnets             = module.launch-configuration.subnet-ids
  security_groups     = [module.alb_security_group.id]

  tags = {
    service = "uestop"
  }
}

## ALB listener
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.webserver-lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type  = "text/plain"
      message_body  = "404: page not found"
      status_code   = 404
    }
  }
}

resource "aws_lb_target_group" "webserver-tg" {
  name      = "webserver-tg"
  port      = var.webserver-port
  protocol  = "HTTP"
  vpc_id    = module.launch-configuration.vpc-id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 15
    timeout             = 3
    healthy_threshold   = 3
    unhealthy_threshold = 5
  }
}

## this is the resource that ties everything together
resource "aws_lb_listener_rule" "asg" {
  listener_arn = aws_lb_listener.http.arn
  priority = 100

  condition {
    path_pattern {
      values = ["*"]
    }
  }

  action {
    type = "forward"
    target_group_arn = aws_lb_target_group.webserver-tg.arn
  }
}

output "webserver_public_ip" {
  value = aws_lb.webserver-lb.dns_name
}