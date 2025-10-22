terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
  backend "s3" {
    bucket = "075313985331-terraform"
    key    = "02-ec2/terraform.tfstate"
  }
}

provider "aws" {

}

locals {
  ami = "ami-070e0d4707168fc07"
}

resource "aws_key_pair" "ssh" {
  public_key = file("id.pub")
}

resource "aws_security_group" "all_all_traffic" {
  ingress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "public" {
  ami                         = local.ami
  instance_type               = "t2.nano"
  key_name                    = aws_key_pair.ssh.key_name
  associate_public_ip_address = true
  security_groups             = [aws_security_group.all_all_traffic.name]

  tags = {
    Name = basename(path.cwd)
  }
}

output "public_ip" {
  value = aws_instance.public.public_ip
}

output "ping_command" {
  value = "ping -c 4 ${aws_instance.public.public_ip}"
}

output "ssh_command" {
  value = "ssh -i id ec2-user@${aws_instance.public.public_ip}"
}