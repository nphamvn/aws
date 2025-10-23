terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }

  backend "s3" {
    bucket = "075313985331-terraform"
    key    = "03-networking/3-vpc-interface-endpoint/terraform.tfstate"
  }
}

provider "aws" {}

data "aws_region" "current" {}

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
}

resource "aws_subnet" "private_subnet" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = false
}

resource "aws_security_group" "endpoint_sg" {
  name        = "endpoint-sg"
  vpc_id      = aws_vpc.main.id
  description = "Allow EC2 in VPC to reach endpoint"

  ingress {
    description = "Allow VPC internal access"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "endpoint-sg"
  }
}

resource "aws_vpc_endpoint" "secretsmanager" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${data.aws_region.current.region}.secretsmanager"
  vpc_endpoint_type = "Interface"

  subnet_ids         = [aws_subnet.private_subnet.id]
  security_group_ids = [aws_security_group.endpoint_sg.id]

  private_dns_enabled = true

  tags = {
    Name = "secretsmanager-endpoint"
  }
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

resource "aws_instance" "private_instance" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.private_subnet.id
  associate_public_ip_address = false
  vpc_security_group_ids      = [aws_security_group.endpoint_sg.id]

  tags = {
    Name = "private-instance"
  }
}
