terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

provider "aws" {

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
  ami                         = "ami-070e0d4707168fc07"
  instance_type               = "t2.nano"
  key_name                    = aws_key_pair.ssh.key_name
  associate_public_ip_address = true
  security_groups             = [aws_security_group.all_all_traffic.name]
}

output "ssh_command" {
  value = "ssh -i id ec2-user@${aws_instance.public.public_ip}"
}