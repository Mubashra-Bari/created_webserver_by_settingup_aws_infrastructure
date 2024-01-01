provider "aws" {}


#VPC
resource "aws_vpc" "my-vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
      Name = "vpc1"
  }
}

#Subnet
resource "aws_subnet" "my-subnet" {
  vpc_id     = aws_vpc.my-vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "ap-south-1a"

  tags = {
    Name = "subnet1"
  }
}

#Internet gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.my-vpc.id
}

#Route table
resource "aws_route_table" "my-route" {
  vpc_id = aws_vpc.my-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  route {
    ipv6_cidr_block        = "::/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "Route1"
  }
}

#Subnet association
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.my-subnet.id
  route_table_id = aws_route_table.my-route.id
}

#Security group
resource "aws_security_group" "allow_web" {
  name        = "allow_web_traffic"
  description = "Allow web inbound traffic"
  vpc_id      = aws_vpc.my-vpc.id

  ingress {
    description      = "HTTPS"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    description      = "HTTP"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    description      = "SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_web"
  }
}

#Network interface
resource "aws_network_interface" "net" {
  subnet_id       = aws_subnet.my-subnet.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.allow_web.id]

}

#Elastic ip
resource "aws_eip" "my-eip" {
  vpc                       = true
  network_interface         = aws_network_interface.net.id
  associate_with_private_ip = "10.0.1.50"
  depends_on                = [aws_internet_gateway.gw]
}

#Instance
resource "aws_instance" "my-server" {
  ami = "ami-0851b76e8b1bce90b"
  instance_type = "t2.micro"
  availability_zone = "ap-south-1a"
  key_name = "terraform-ubuntu-key"

  network_interface {
    device_index = 0
    network_interface_id = aws_network_interface.net.id
  }

  user_data = <<-EOF
              #!/bin/bash
              sudo apt update -y
              sudo apt install apache2 -y
              sudo systemctl start apache2
              sudo bash -c "echo Hi there, its Mubashra welcome to my webserver > /var/www/html/index.html"
              EOF

  tags = {
      Name = "ubuntu-server"
  }
}
