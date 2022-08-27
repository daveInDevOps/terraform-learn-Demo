provider "aws" {
  region = "us-east-1"
}

variable "vpc_cidr_block" {

}

variable "subnet_cidr_block" {

}

variable "availability_zone" {

}

variable "env_prefix" {

}

variable "instance_type" {

}




resource "aws_vpc" "myapp-vpc" {
  cidr_block = var.vpc_cidr_block
  tags = {
    Name : "${var.env_prefix}-vpc"

  }
}


resource "aws_subnet" "myapp-subnet" {
  vpc_id            = aws_vpc.myapp-vpc.id
  cidr_block        = var.subnet_cidr_block
  availability_zone = var.availability_zone
  tags = {
    Name : "${var.env_prefix}-subnet"
  }
}


resource "aws_internet_gateway" "myapp-igw" {
  vpc_id = aws_vpc.myapp-vpc.id

  tags = {
    Name = "${var.env_prefix}-igw"

  }
}

resource "aws_route_table" "myapp-route-table" {
  vpc_id = aws_vpc.myapp-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.myapp-igw.id
  }

  tags = {
    Name = "${var.env_prefix}-rt"

  }
}

resource "aws_route_table_association" "assoc-rtb-subnet" {
  subnet_id      = aws_subnet.myapp-subnet.id
  route_table_id = aws_route_table.myapp-route-table.id
}


resource "aws_security_group" "myapp-sg" {
  name   = "myapp-sg"
  vpc_id = aws_vpc.myapp-vpc.id


  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "${var.env_prefix}-sg"

  }
}

data "aws_ami" "latest-linux-image" {
  most_recent = true
  owners      = ["137112412989"]
  filter {
    name   = "name"
    values = ["amzn2-ami-kernel-*-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

output "aws_ami_id" {
  value = data.aws_ami.latest-linux-image.id
}

resource "aws_instance" "myapp-server" {
  ami                         = data.aws_ami.latest-linux-image.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.myapp-subnet.id
  vpc_security_group_ids      = [aws_security_group.myapp-sg.id]
  availability_zone           = var.availability_zone
  associate_public_ip_address = true

}





