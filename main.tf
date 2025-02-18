provider "aws" {
  region = "ap-south-1"
}
terraform {
  backend "s3" {
    bucket = "my-terraform-state-bucket-sunil7756"
    key    = "terraform-python/terraform.tfstate"
    region = "ap-south-1"
  }
}
data "aws_route53_zone" "main" {
  name = "cloudwithsunil.xyz"
}
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
}
resource "aws_subnet" "subnet" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "ap-south-1a"
}
resource "aws_route_table" "main" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
}
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.subnet.id
  route_table_id = aws_route_table.main.id
}
resource "aws_security_group" "allow_web" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 22
    to_port     = 22
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

resource "aws_instance" "application" {
  ami           = "ami-00bb6a80f01f03502" # Amazon Linux 2
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.subnet.id
  key_name = "dockernew"
  vpc_security_group_ids = [aws_security_group.allow_web.id]

  user_data = <<-EOF
                #!/bin/bash
                sudo apt update && sudo apt install net-tools
                curl https://get.docker.com/ | bash
                sudo usermod -aG docker ubuntu
                sudo chmod 666 /var/run/docker.sock 
                sudo systemctl start docker
                # Clone the GitHub repository
                sudo apt-get install -y git
                git clone https://github.com/sunil-challagali/voting-app-py.git /home/ubuntu/app
                cd /home/ubuntu/app
                sudo docker build -t my-flask-app:latest .
                sudo docker run -d -p 5000:5000 my-flask-app:latest
                EOF

  tags = {
    Name = "FlaskApp"
  }
}

resource "aws_eip" "app_eip" {
  instance = aws_instance.application.id
}
resource "aws_route53_record" "app_record" {
  zone_id = data.aws_route53_zone.main.zone_id  # Refer to the existing hosted zone resource
  name    = "www.sunilwithcloud.xyz"          # Replace with your subdomain name
  type    = "A"
  ttl     = "300"
  records = [aws_eip.application_eip.public_ip]
}
output "eip_address" {
  value = aws_eip.app_eip.public_ip
}
