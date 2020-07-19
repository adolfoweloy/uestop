provider "aws" {
  region = "us-east-1"
}

resource "aws_security_group" "uestop-webserver-sg" {
  name = "uestop-webserver-security-group"

  ingress {
    from_port = 8080
    protocol = "tcp"
    to_port = 8080
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    service = "uestop"
  }
}

resource "aws_instance" "uestop-webserver-ec2" {
  ami = "ami-0ac80df6eff0e70b5"
  instance_type = "t2.micro"

  ## creating an implicit dependency to the security group defined above
  vpc_security_group_ids = [aws_security_group.uestop-webserver-sg.id]

  user_data = <<-EOF
              #!/bin/bash
              echo "Hello, World" > index.html
              nohup busybox httpd -f -p 8080 &
              EOF

  tags = {
    name    = "ec2-uestop-webserver"
    service = "uestop"
  }
}

resource "aws_sqs_queue" "uestop-game-std-sqs" {
  name = "game-turn"
  delay_seconds = 0
  max_message_size = 262144
  message_retention_seconds = 86400
  receive_wait_time_seconds = 0

  tags = {
    name    = "uestop-game-std-sqs"
    service = "uestop"
  }
}