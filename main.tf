provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "subnet" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"
}

resource "aws_security_group" "allow_web" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "app" {
  ami           = "ami-0c55b159cbfafe1f0" # Amazon Linux 2
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.subnet.id
  security_groups = [aws_security_group.allow_web.name]

  user_data = <<-EOF
                #!/bin/bash
                sudo yum update -y
                sudo yum install docker -y
                sudo service docker start
                sudo usermod -a -G docker ec2-user
                docker run -d -p 5000:5000 my-flask-app:latest
                EOF

  tags = {
    Name = "FlaskApp"
  }
}

resource "aws_eip" "app_eip" {
  instance = aws_instance.app.id
}

output "eip_address" {
  value = aws_eip.app_eip.public_ip
}
