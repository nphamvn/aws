terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.16.0"
    }
  }
}

provider "aws" {
  region  = "ap-northeast-1"
  profile = "personal_2"
}

##################################################
# VPC
##################################################
resource "aws_vpc" "vpc" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = "10.0.1.0/24"
}

resource "aws_internet_gateway" "ig" {

}

resource "aws_internet_gateway_attachment" "ig_attachment" {
  internet_gateway_id = aws_internet_gateway.ig.id
  vpc_id              = aws_vpc.vpc.id
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.ig.id
  }
}

resource "aws_route_table_association" "public" {
  route_table_id = aws_route_table.public.id
  subnet_id      = aws_subnet.public.id
}

resource "aws_security_group" "allow_icmp" {
  vpc_id = aws_vpc.vpc.id
  ingress {
    protocol    = "icmp"
    from_port   = -1
    to_port     = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
}

##################################################
# EC2
##################################################
resource "aws_instance" "public" {
  ami                         = "ami-070e0d4707168fc07"
  instance_type               = "t2.nano"
  subnet_id                   = aws_subnet.public.id
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.allow_icmp.id]
}

###################################################
# Outputs
###################################################
output "instance_public_ip" {
  value = aws_instance.public.public_ip
}