locals {
  port = 8080
}

module "instance" {
  source = "../common/instance"
}

module "webserver-security-group" {
  source = "../common/security-group"

  layer = "web"
  name = "webserver"

  inbound_port = {
    from = local.port
    to   = local.port
  }

  outbound_port = {
    from = 0
    to   = 0
  }
}


## Defines how the ASG will launch new instances
resource "aws_launch_configuration" "webserver-launch-config" {
  image_id        = module.instance.ami
  instance_type   = module.instance.type
  security_groups = [module.webserver-security-group.id]

  user_data = <<-EOF
              #!/bin/bash
              echo "Hello, World" > index.html
              nohup busybox httpd -f -p ${local.port} &
              EOF

  // this allows the ASG to point to the new launch configuration resource before deleting the current version.
  // it's not possible to delete the current without changing the pointers while this is being used by the ASG.
  lifecycle {
    create_before_destroy = true
  }
}

## creates the ASG
resource "aws_autoscaling_group" "webserver-asg" {
  launch_configuration  = aws_launch_configuration.webserver-launch-config.name
  vpc_zone_identifier   = module.instance.vpc-id

  target_group_arns = [aws_lb_target_group.webserver-target-group.arn]
  health_check_type = "ELB"

  min_size = 2
  max_size = 4

}

## security group for the LB
module "lb-security-group" {
  source = "../common/security-group"

  layer = "web"
  name = "webserver-lb"

  inbound_port = {
    from = 80
    to   = 80
  }

  outbound_port = {
    from = 0
    to   = 0
  }
}

## creating the ALB
resource "aws_lb" "webserver-lb" {
  name                = "webserver-lb"
  load_balancer_type  = "application"
  subnets             = module.instance.subnet-ids
  security_groups     = [module.lb-security-group.id]

  lifecycle {
    create_before_destroy = true
  }
}

## ALB listener
resource "aws_lb_listener" "webserver-http" {
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

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_target_group" "webserver-target-group" {
  name      = "webserver-asg"
  port      = var.webserver-port
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
  listener_arn  = aws_lb_listener.webserver-http.arn
  priority      = 100

  condition {
    path_pattern {
      values = ["*"]
    }
  }

  action {
    type = "forward"
    target_group_arn = aws_lb_target_group.webserver-target-group.arn
  }
}

output "webserver_public_ip" {
  value = aws_lb.webserver-lb.dns_name
}