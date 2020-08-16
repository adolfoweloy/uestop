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

module "application-load-balancer" {
  source    = "../common/alb"

  lb_port   = 80
  app_port  = local.port
  name      = "webserver"
}

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
