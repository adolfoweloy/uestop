resource "aws_security_group" "security-group" {
  name = "${var.name}.sg"

  ingress {
    protocol    = var.inbound_protocol
    from_port   = var.inbound_port.from
    to_port     = var.inbound_port.to
    cidr_blocks = var.inbound_cidr_addresses
  }

  egress {
    protocol    = var.outbound_protocol
    from_port   = var.outbound_port.from
    to_port     = var.outbound_port.to
    cidr_blocks = var.outbound_cidr_addresses
  }

  tags = {
    service = var.service
    layer   = var.layer
  }
}

output "id" {
  value = aws_security_group.security-group.id
}
