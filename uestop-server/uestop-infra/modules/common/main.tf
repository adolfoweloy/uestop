resource "aws_security_group" "security-group" {
  name = var.security-group.name

  ingress {
    from_port   = var.security-group.port
    protocol    = "tcp"
    to_port     = var.security-group.port
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    service = "uestop"
    layer   = "web"
  }
}

output "security-group-id" {
  value = aws_security_group.security-group.id
}
