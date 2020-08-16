output "ami" {
  description = "AMI for t2.micro with Ubuntu"
  value     = "ami-0ac80df6eff0e70b5"
}

output "type" {
  description = "AWS EC2 instance type"
  value     = "t2.micro"
}

output "keypair" {
  value = "aws-in-action-keypair"
}