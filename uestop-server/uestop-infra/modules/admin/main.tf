module "instance" {
  source = "../common/instance"
}

module "security-group" {
  source = "../common/security-group/inbound"

  port = {
    from = 22
    to   = 22
  }

  layer = "admin"
  name = "sg_admin"
}

# instance to be accessed publicly as a bastion server
resource "aws_instance" "uestop-bastion-server" {
  ami                     = module.instance.ami
  key_name                = module.instance.keypair-name
  instance_type           = module.instance.instance-type
  vpc_security_group_ids  = [module.security-group.id]

  tags = {
    service = var.service
    name    = "uestop-bastion-server"
  }
}

data "aws_subnet" "uestop-bastion-subnet" {
  id = data.aws_instance.bastion.subnet_id
}

# retrieving data from the bastion declared above
data "aws_instance" "bastion" {
  filter {
    name = "tag:name"
    values = ["uestop-bastion-server"]
  }

  depends_on = [aws_instance.uestop-bastion-server]
}

