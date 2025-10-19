terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
  backend "s3" {
    bucket = "075313985331-terraform"
    key    = "04-ec2-ebs/terraform.tfstate"
  }
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

resource "aws_instance" "instance" {
  ami                         = "ami-070e0d4707168fc07"
  instance_type               = "t2.nano"
  key_name                    = aws_key_pair.ssh.key_name
  associate_public_ip_address = true
  security_groups             = [aws_security_group.all_all_traffic.name]
}

output "ssh_command" {
  value = "ssh -i id ec2-user@${aws_instance.instance.public_ip} -o StrictHostKeyChecking=no"
}

resource "aws_instance" "instance_2" {
  ami                         = "ami-070e0d4707168fc07"
  instance_type               = "t2.nano"
  key_name                    = aws_key_pair.ssh.key_name
  availability_zone           = aws_instance.instance.availability_zone // Ensure both instances are in the same AZ
  associate_public_ip_address = true
  security_groups             = [aws_security_group.all_all_traffic.name]
}

output "ssh_command_2" {
  value = "ssh -i id ec2-user@${aws_instance.instance_2.public_ip} -o StrictHostKeyChecking=no"
}

resource "aws_ebs_volume" "data" {
  availability_zone = aws_instance.instance.availability_zone
  size              = 1
}

resource "aws_volume_attachment" "data_att" {
  instance_id = aws_instance.instance_2.id
  volume_id   = aws_ebs_volume.data.id
  device_name = "/dev/sdf"
}