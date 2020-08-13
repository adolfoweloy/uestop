locals {
  port = 8080
}

module "infra" {
  source = "../common"

  security-group = {
    port = local.port
    name = "uestop-webserver-security-group"
  }
}

## launch configuration is required for an ASG
resource "aws_launch_configuration" "uestop-webserver-launch-config" {
  image_id      = module.infra.ami
  instance_type = module.infra.instance-type

  ## creating an implicit dependency to the security group defined above
  security_groups = [module.infra.security-group-id]

  user_data = <<-EOF
              #!/bin/bash
              echo "Hello, World" > index.html
              nohup busybox httpd -f -p ${local.port} &
              EOF

  // this lifecycle was added because launch config is immutable and by default, terraform tries to replace this with a new resource
  // and it tries to delete this resource in order to replace it. However as it's being referenced by the ASG, it can't
  // delete the resource. This lifecycle attribute allows to create the new resource and updating references to the old
  // to start pointing to the new resource. Then the old is free to be deleted.
  lifecycle {
    create_before_destroy = true
  }
}

## Dynamically retrieving the subnet IDs to be used by the ASG
data "aws_vpc" "vpc-default" {
  default = true
}

data "aws_subnet_ids" "subnet-default" {
  vpc_id = data.aws_vpc.vpc-default.id
}

## creates the ASG
resource "aws_autoscaling_group" "uestop-webserver-asg" {
  launch_configuration = aws_launch_configuration.uestop-webserver-launch-config.name
  vpc_zone_identifier = data.aws_subnet_ids.subnet-default.ids

  target_group_arns = [aws_lb_target_group.asg.arn]
  health_check_type = "ELB"

  min_size = 2
  max_size = 4

}

## security group for the LB
resource "aws_security_group" "alb" {
  name = "uestop-loadbalancer-sg"

  ingress {
    from_port = 80
    protocol = "tcp"
    to_port = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    protocol = "-1"
    to_port = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

## creating the ALB
resource "aws_lb" "uestop-webserver-lb" {
  name                = "webserver-lb"
  load_balancer_type  = "application"
  subnets             = data.aws_subnet_ids.subnet-default.ids
  security_groups     = [aws_security_group.alb.id]
}

## ALB listener
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.uestop-webserver-lb.arn
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

resource "aws_lb_target_group" "asg" {
  name = "webserver-asg"
  port = var.webserver-port
  protocol = "HTTP"
  vpc_id = data.aws_vpc.vpc-default.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 15
    timeout             = 3
    healthy_threshold   = 2
    unhealthy_threshold = 2
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
    target_group_arn = aws_lb_target_group.asg.arn
  }
}

output "webserver_public_ip" {
  value = aws_lb.uestop-webserver-lb.dns_name
}