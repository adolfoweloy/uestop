provider "aws" {
  region = "us-east-1"
}

variable "webserver-port" {
  description   = "Webserver port for http"
  type          = number
  default       = 8080
}

variable "webserver-admin-port" {
  description = "Webserver ssh port for admin purposes"
  type        = number
  default     = 22
}

variable "ami-ubuntu" {
  description = "AMI for t2.micro with Ubuntu"
  type        = string
  default     = "ami-0ac80df6eff0e70b5"
}

data "aws_subnet" "uestop-bastion-subnet" {
  id = data.aws_instance.bastion.subnet_id
}

resource "aws_security_group" "uestop-webserver-sg" {
  name = "uestop-webserver-security-group"

  ingress {
    from_port = var.webserver-port
    protocol = "tcp"
    to_port = var.webserver-port
    cidr_blocks = ["0.0.0.0/0"]
  }

  ## enabling the ssh port to be accessed from the bastion's subnet CIDR block
  ingress {
    from_port = var.webserver-admin-port
    protocol = "tcp"
    to_port = var.webserver-admin-port
    cidr_blocks = [data.aws_subnet.uestop-bastion-subnet.cidr_block]
  }

  tags = {
    service = "uestop"
  }
}

resource "aws_security_group" "uestop-webserver-admin-sg" {
  name = "uestop-webserver-security-group-admin"

  ingress {
    from_port = 22
    protocol = "tcp"
    to_port = 22
    cidr_blocks = ["0.0.0.0/0"]
  }

}

## launch configuration is required for an ASG
resource "aws_launch_configuration" "uestop-webserver-launch-config" {
  image_id = "ami-0ac80df6eff0e70b5"
  instance_type = "t2.micro"

  ## creating an implicit dependency to the security group defined above
  security_groups = [aws_security_group.uestop-webserver-sg.id]

  user_data = <<-EOF
              #!/bin/bash
              echo "Hello, World" > index.html
              nohup busybox httpd -f -p ${var.webserver-port} &
              EOF

  // this lifecycle was added because launch config is immutable and by default, terraform tries to replace this with a new resource
  // and it tries to delete this resource in order to replace it. However as it's being referenced by the ASG, it can't
  // delete the resource. This lifecycle attribute allows to create the new resource and updating references to the old
  // to start pointing to the new resource. Then the old is free to be deleted.
  lifecycle {
    create_before_destroy = true
  }
}

# instance to be accessed publicly as a bastion server
resource "aws_instance" "uestop-bastion-server" {
  ami = var.ami-ubuntu
  instance_type = "t2.micro"
  key_name = "aws-in-action-keypair"
  vpc_security_group_ids = [aws_security_group.uestop-webserver-admin-sg.id]

  tags = {
    service = "uestop"
    name    = "uestop-bastion-server"
  }
}

# retrieving data from the bastion declared above
data "aws_instance" "bastion" {
  filter {
    name = "tag:name"
    values = ["uestop-bastion-server"]
  }

  depends_on = ["aws_instance.uestop-bastion-server"]
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

resource "aws_sqs_queue" "uestop-game-std-sqs" {
  name = "game-turn"
  delay_seconds = 0
  max_message_size = 262144
  message_retention_seconds = 86400
  receive_wait_time_seconds = 0

  tags = {
    name    = "uestop-game-std-sqs"
    service = "uestop"
  }
}