## security group for the LB
module "instance" {
  source = "../instance"
}

## configuring security group
module "lb-security-group" {
  source = "../security-group"

  layer = "web"
  name = "webserver-lb"
}

resource "aws_security_group_rule" "http-ingress" {
  from_port = var.lb_port
  to_port = var.lb_port
  protocol = "tcp"
  security_group_id = module.lb-security-group.id
  type = "ingress"
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "http-egress" {
  from_port = 0
  to_port = 0
  protocol = "-1"
  security_group_id = module.lb-security-group.id
  type = "egress"
  cidr_blocks = ["0.0.0.0/0"]
}

## creating the application Load Balancer
resource "aws_lb" "load-balancer" {
  name                = "${var.name}-lb"
  load_balancer_type  = "application"
  subnets             = module.instance.subnet-ids
  security_groups     = [module.lb-security-group.id]
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
}

resource "aws_lb_target_group" "target-group" {
  name = "${var.name}-tg"
  port = var.app_port
  protocol = "HTTP"
  vpc_id = module.instance.vpc-id

  health_check {
    path = "/"
    protocol = "HTTP"
    matcher = "200"
    interval = 15
    timeout = 3
    healthy_threshold = 2
    unhealthy_threshold = 2
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