locals {
  project_name = "99-cluster"
}

terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
  backend "s3" {
    bucket = "075313985331-terraform"
    key    = "99-eks/terraform.tfstate"
  }
}

provider "aws" {

}

resource "aws_eks_cluster" "cluster" {
  name = local.project_name
  vpc_config {
    subnet_ids = [aws_subnet.private_1.id, aws_subnet.private_2.id]
  }

  role_arn = aws_iam_role.cluster_role.arn

  depends_on = [aws_iam_role_policy_attachment.AmazonEKSClusterPolicy]
}