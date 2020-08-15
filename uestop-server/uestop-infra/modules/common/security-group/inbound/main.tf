resource "aws_security_group" "security-group" {
  name = "${var.name}.sg"

  ingress {
    protocol    = var.protocol
    from_port   = var.port.from
    to_port     = var.port.to
    cidr_blocks = var.cidr_addresses
  }

  tags = {
    service = var.service
    layer   = var.layer
  }
}

output "id" {
  value = aws_security_group.security-group.id
}
