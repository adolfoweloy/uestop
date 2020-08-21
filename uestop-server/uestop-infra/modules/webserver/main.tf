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
}

##########################################################################
## security group to allow access to http from the internet
##########################################################################

resource "aws_security_group_rule" "http-ingress" {
  from_port = local.port
  protocol = "tcp"
  security_group_id = module.webserver-security-group.id
  to_port = local.port
  type = "ingress"
  cidr_blocks = ["0.0.0.0/0"]
}

##########################################################################
## configures security group to allow ssh from bastion's security group
##########################################################################

resource "aws_security_group_rule" "admin-ingress" {
  from_port = 22
  protocol = "tcp"
  security_group_id = module.webserver-security-group.id
  to_port = 22
  type = "ingress"
  source_security_group_id = var.admin-security-group-id
}

##########################################################################
## adding load balancer module
##########################################################################

module "application-load-balancer" {
  source    = "../common/alb"

  lb_port   = 80
  app_port  = local.port
  name      = "webserver"
}

##########################################################################
## adding support for autoscaling (which already contains instance
##########################################################################

module "autoscaling" {
  source = "../common/autoscaling"

  security_groups   = [module.webserver-security-group.id]
  target_group_arns = [module.application-load-balancer.target-group-arn]

  user_data = <<-EOF
      #!/bin/bash
      echo "Hello, World" > index.html
      nohup busybox httpd -f -p ${local.port} &
      EOF
}

output "webserver-dns" {
  value = module.application-load-balancer.webserver_public_ip
}
