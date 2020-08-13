module "infra" {
  source = "../common"

  security-group = {
    port = 22
    name = "sg_admin_uestop"
  }
}

# instance to be accessed publicly as a bastion server
resource "aws_instance" "uestop-bastion-server" {
  ami                     = module.infra.ami
  key_name                = module.infra.keypair-name
  instance_type           = module.infra.instance-type
  vpc_security_group_ids  = [module.infra.security-group-id]

  tags = {
    service = "uestop"
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

