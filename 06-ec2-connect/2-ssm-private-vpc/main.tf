terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }

  backend "s3" {
    bucket = "075313985331-terraform"
    key    = "06-ec2-connect/2-ssm-private-vpc/terraform.tfstate"
  }
}

provider "aws" {}

data "aws_region" "current" {}

resource "aws_vpc" "vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "ssm-private-vpc"
  }
}

resource "aws_subnet" "subnet" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = false

  tags = {
    Name = "ssm-private-subnet"
  }
}

resource "aws_iam_role" "ssm_ec2_role" {
  name = "EC2RoleForSSM"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "ec2.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.ssm_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ssm_profile" {
  name = "EC2InstanceProfileForSSM"
  role = aws_iam_role.ssm_ec2_role.name
}

resource "aws_security_group" "ssm_sg" {
  vpc_id = aws_vpc.vpc.id
  name   = "ssm-instance-sg"

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ssm-instance-sg"
  }
}

resource "aws_security_group" "endpoint_sg" {
  vpc_id = aws_vpc.vpc.id
  name   = "ssm-endpoint-sg"

  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.ssm_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ssm-endpoint-sg"
  }
}

locals {
  endpoints = [
    "ssm",
    "ssmmessages",
    "ec2messages"
  ]
}

resource "aws_vpc_endpoint" "vpc_endpoint" {
  for_each = toset(local.endpoints)

  vpc_id              = aws_vpc.vpc.id
  service_name        = "com.amazonaws.${data.aws_region.current.region}.${each.key}"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.subnet.id]
  security_group_ids  = [aws_security_group.endpoint_sg.id]
  private_dns_enabled = true

  tags = {
    Name = "ssm-${each.key}-endpoint"
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

resource "aws_instance" "ssm_demo" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.subnet.id
  vpc_security_group_ids = [aws_security_group.ssm_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.ssm_profile.name

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  tags = {
    Name = "ssm-private-instance"
  }
}

output "instance_id" {
  value = aws_instance.ssm_demo.id
}

output "start_session_command" {
  value = "aws ssm start-session --target ${aws_instance.ssm_demo.id}"
}