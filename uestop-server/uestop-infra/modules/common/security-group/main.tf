resource "aws_security_group" "security-group" {
  name = "${var.name}-sgroup"

  tags = {
    service = var.service
    layer   = var.layer
  }
}

output "id" {
  value = aws_security_group.security-group.id
}
