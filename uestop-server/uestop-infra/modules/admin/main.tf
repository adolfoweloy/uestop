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

  inbound_port = {
    from = local.port
    to   = local.port
  }

  outbound_port = {
    from = 0
    to   = 0
  }
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

