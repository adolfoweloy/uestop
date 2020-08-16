## security group for the LB
module "instance" {
  source = "../instance"
}

module "lb-security-group" {
  source = "../security-group"

  layer = "web"
  name = "webserver-lb"

  inbound_port = {
    from = var.lb_port
    to   = var.lb_port
  }

  outbound_port = {
    from = 0
    to   = 0
  }
}

## creating the ALB
resource "aws_lb" "load-balancer" {
  name                = "${var.name}-lb"
  load_balancer_type  = "application"
  subnets             = module.instance.subnet-ids
  security_groups     = [module.lb-security-group.id]

  lifecycle {
    create_before_destroy = true
  }
}

## ALB listener
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.load-balancer.arn
  port              = var.lb_port
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type  = "text/plain"
      message_body  = "404: page not found"
      status_code   = 404
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_target_group" "target-group" {
  name      = "${var.name}-tg"
  port      = var.app_port
  protocol  = "HTTP"
  vpc_id    = module.instance.vpc-id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 15
    timeout             = 3
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  lifecycle {
    create_before_destroy = true
  }
}

## this is the resource that ties everything together
## that is to forward requests that come to the LB to the target group
resource "aws_lb_listener_rule" "asg" {
  listener_arn  = aws_lb_listener.http.arn
  priority      = 100

  condition {
    path_pattern {
      values = ["*"]
    }
  }

  action {
    type = "forward"
    target_group_arn = aws_lb_target_group.target-group.arn
  }
}

output "webserver_public_ip" {
  value = aws_lb.load-balancer.dns_name
}

output "target-group-arn" {
  value = aws_lb_target_group.target-group.arn
}