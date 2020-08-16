module "instance" {
  source = "../instance"
}

module "security-group" {
  source = "../security-group/inbound"

  port = {
    from = var.port
    to   = var.port
  }

  // this name makes this module (launch config) not reusable.
  name  = var.name
  layer = var.layer
}

## Dynamically retrieving the subnet IDs to be used by the ASG
data "aws_vpc" "vpc-default" {
  default = true
}

data "aws_subnet_ids" "subnet-default" {
  vpc_id = data.aws_vpc.vpc-default.id
}

## launch configuration is required for an ASG
resource "aws_launch_configuration" "launch-config" {
  name          = "${var.name}.lc"
  image_id      = module.instance.ami
  instance_type = module.instance.instance-type

  ## creating an implicit dependency to the security group defined above
  security_groups = [module.security-group.id]

  // TODO - this user data makes launch config not reusable
  user_data = <<-EOF
              #!/bin/bash
              echo "Hello, World" > index.html
              nohup busybox httpd -f -p ${var.port} &
              EOF

  // this lifecycle was added because launch config is immutable and by default, terraform tries to replace this with a new resource
  // and it tries to delete this resource in order to replace it. However as it's being referenced by the ASG, it can't
  // delete the resource. This lifecycle attribute allows to create the new resource and updating references to the old
  // to start pointing to the new resource. Then the old is free to be deleted.
  lifecycle {
    create_before_destroy = true
  }

}

output "name" {
  value = aws_launch_configuration.launch-config.name
}

output "vpc-id" {
  value = data.aws_vpc.vpc-default.id
}

output "subnet-ids" {
  value = data.aws_subnet_ids.subnet-default.ids
}