output "ami" {
  description = "AMI for t2.micro with Ubuntu"
  value     = "ami-0ac80df6eff0e70b5"
}

output "instance-type" {
  description = "AWS EC2 instance type"
  value     = "t2.micro"
}

output "keypair-name" {
  value = "aws-in-action-keypair"
}