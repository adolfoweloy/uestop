locals {
  port = 22
}

module "instance" {
  source = "../common/instance"
}

module "admin-security-group" {
  source = "../common/security-group"

  layer = "web"
  name = "admin"
}

resource "aws_security_group_rule" "ssh-ingress" {
  type = "ingress"
  from_port = local.port
  to_port = local.port
  protocol = "tcp"
  security_group_id = module.admin-security-group.id
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "ssh-egress" {
  type = "egress"
  from_port = 0
  to_port = 0
  protocol = "tcp"
  security_group_id = module.admin-security-group.id
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "icmp-ingress" {
  type = "ingress"
  protocol = "icmp"
  from_port = -1
  to_port = -1
  security_group_id = module.admin-security-group.id
  cidr_blocks = ["0.0.0.0/0"]
}

# instance to be accessed publicly as a bastion server
resource "aws_instance" "uestop-bastion-server" {
  ami                     = module.instance.ami
  key_name                = module.instance.keypair
  instance_type           = module.instance.type
  vpc_security_group_ids  = [module.admin-security-group.id]

  tags = {
    service = "uestop"
    name    = "bastion-server"
  }

  lifecycle {
    create_before_destroy = true
  }
}

output "admin-security-group-id" {
  value = module.admin-security-group.id
}

data "aws_subnet" "uestop-bastion-subnet" {
  id = data.aws_instance.bastion.subnet_id
}

# retrieving data from the bastion declared above
data "aws_instance" "bastion" {
  filter {
    name = "tag:name"
    values = ["bastion-server"]
  }

  depends_on = [aws_instance.uestop-bastion-server]
}

output "bastion_host_public_name" {
  value = aws_instance.uestop-bastion-server.public_ip
}