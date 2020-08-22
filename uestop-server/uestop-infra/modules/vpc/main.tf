## still working in progress
## do not use this module

resource "aws_vpc" "uestop-vpc" {
  cidr_block = "10.0.0.0/16",
  enable_dns_hostnames = true

  tags = {
    service = var.service
  }
}

resource "aws_internet_gateway" "uestop-ig" {
  // when creating the internet gateway you don't need to declare an intermediate resource like in cloud formation
  vpc_id = aws_vpc.uestop-vpc.id
  tags = {
    service = var.service
  }
}
########################################################################################################################
# public subnet for bastion
resource "aws_subnet" "subnet-public-ssh-bastion" {
  cidr_block = "10.0.1.0/24"
  vpc_id = aws_vpc.uestop-vpc.id
  availability_zone = "us-east-1a"
}
## defining the route table
resource "aws_route_table" "route-table-public-ssh-bastion" {
  vpc_id = aws_vpc.uestop-vpc.id
}
resource "aws_route_table_association" "route-table-association-public-ssh-bastion" {
  route_table_id = aws_route_table.route-table-public-ssh-bastion.id
  subnet_id = aws_subnet.subnet-public-ssh-bastion.id
}
resource "aws_route" "route-public-ssh-bastion-internet" {
  route_table_id = aws_route_table.route-table-public-ssh-bastion.id
  gateway_id = aws_internet_gateway.uestop-ig.id
  destination_cidr_block = "0.0.0.0/0"
}
## defining the ACL
resource "aws_network_acl" "network-acl-public-ssh-bastion" {
  vpc_id = aws_vpc.uestop-vpc.id

  // CloudFormation requires the usage of an intermediate resource to associate the subnet
  subnet_id = aws_subnet.subnet-public-ssh-bastion.id

  ingress {
    rule_no     = 100
    protocol    = "tcp" // the author of the book I was reading set protocol number expecting everybody to know it :(
    from_port   = 22
    to_port     = 22
    action      = "allow"
    cidr_block  = "0.0.0.0/0"
  }

  ingress {
    rule_no     = 200,
    protocol    = "tcp"
    from_port   = 1024
    to_port     = 65535
    action      = "allow"
    cidr_block  = "10.0.0.0/16"
  }

  egress {
    rule_no     = 100
    action      = "allow"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_block  = "10.0.0.0/16"
  }

  egress {
    rule_no     = 200
    action      = "allow"
    from_port   = 1024
    to_port     = 65535
    protocol    = "tcp"
    cidr_block  = "0.0.0.0/0"
  }
}

########################################################################################################################
# private apache web server

resource "aws_subnet" "subnet-private-apache" {
  cidr_block        = "10.0.3.0/24"
  vpc_id            = aws_vpc.uestop-vpc.id
  availability_zone = "us-east-1a"
}
## defining the route table
resource "aws_route_table" "subnet-private-apache-route-table" {
  vpc_id = aws_vpc.uestop-vpc.id
}
resource "aws_route_table_association" "route-table-association-private-apache" {
  route_table_id  = aws_route_table.subnet-private-apache-route-table.id
  subnet_id       = aws_subnet.subnet-private-apache.id
}

########################################################################################################################
# NAT subnet + instance

resource "aws_subnet" "nat-subnet" {
  vpc_id            = aws_vpc.uestop-vpc.id
  cidr_block        = "10.0.0.0/24"
  availability_zone = "us-east-1a"
}
resource "aws_route_table" "nat-route-table" {
  vpc_id = aws_vpc.uestop-vpc.id
}
resource "aws_route_table_association" "nat-route-table-assoc" {
  route_table_id  = aws_route_table.nat-route-table.id
  subnet_id       = aws_subnet.nat-subnet.id
}
resource "aws_route" "nat-route" {
  route_table_id          = aws_route_table.nat-route-table.id
  gateway_id              = aws_internet_gateway.uestop-ig.id
  destination_cidr_block  = "0.0.0.0/0"
}
resource "aws_network_interface" "nat-network-interface" {
  subnet_id = aws_subnet.nat-subnet.id
}
resource "aws_instance" "nat-instance" {
  // to find a NAT ami just run the following little command:
  //
  // aws ec2 describe-images --filter Name="owner-alias",Values="amazon" \
  // --filter Name="name",Values="amzn-ami-vpc-nat-2018.03*" \
  // --query "Images[*].[ImageId,Name,CreationDate]"
  ami                 = "ami-01ef31f9f39c5aaed"
  instance_type       = "t2.micro"
  key_name            = "aws-in-action-keypair"
  subnet_id           = aws_subnet.nat-subnet.id
  source_dest_check   = false
}