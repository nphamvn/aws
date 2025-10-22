terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
  backend "s3" {
    bucket = "075313985331-terraform"
    key    = "06-ec2-connect/1-ssm-public-vpc/terraform.tfstate"
  }
}

provider "aws" {

}

data "aws_vpc" "default" {
  default = true
}

resource "aws_iam_role" "ssm_ec2_role" {
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
  role = aws_iam_role.ssm_ec2_role.name
}

resource "aws_security_group" "ssm_sg" {
  vpc_id = data.aws_vpc.default.id

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "ssm_demo" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t3.micro"
  vpc_security_group_ids = [aws_security_group.ssm_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.ssm_profile.name

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  tags = {
    Name = "ssm-demo"
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

resource "aws_cloudwatch_log_group" "ssm_sessions" {
  name = "/aws/ssm/session-logs"
}

resource "aws_ssm_document" "session_preferences" {
  name          = "My-SSM-SessionManagerRunShell"
  document_type = "Session"
  content = jsonencode({
    schemaVersion = "1.0",
    //description   = "Enable CloudWatch logging for SSM sessions",
    sessionType   = "Standard_Stream",
    inputs = {
      cloudWatchLogGroupName = aws_cloudwatch_log_group.ssm_sessions.name
      //cloudWatchEncryptionEnabled = false
      //s3BucketName                = null
      //s3EncryptionEnabled         = false
      //runAsEnabled                = true
      //runAsDefaultUser            = "ec2-user" # hoặc "ssm-user" nếu bạn muốn giữ mặc định
      //idleSessionTimeout          = "20"
    }
  })
}

