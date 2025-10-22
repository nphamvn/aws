terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
  backend "s3" {
    bucket = "075313985331-terraform"
    key    = "05-ec2-image-builder/terraform.tfstate"
  }
}

provider "aws" {

}

resource "aws_imagebuilder_image_pipeline" "pipeline" {
  name                             = "MyWebServerImagePipeline"
  image_recipe_arn                 = aws_imagebuilder_image_recipe.image_recipe.arn
  infrastructure_configuration_arn = aws_imagebuilder_infrastructure_configuration.infra.arn
}

resource "aws_imagebuilder_image_recipe" "image_recipe" {
  name         = "MyWebServer"
  version      = "1.0.0"
  parent_image = "arn:aws:imagebuilder:ap-northeast-1:aws:image/amazon-linux-2023-x86/x.x.x"
  component {
    component_arn = aws_imagebuilder_component.InstallNginx.arn
  }
}

resource "aws_imagebuilder_component" "InstallNginx" {
  name     = "InstallNginx"
  version  = "1.0.0"
  platform = "Linux"
  data     = yamlencode(yamldecode(file("install-nginx.yaml")))
}

resource "aws_imagebuilder_infrastructure_configuration" "infra" {
  name                  = "ImageBuilderInfra"
  instance_profile_name = aws_iam_instance_profile.instance_profile.name
}

resource "aws_iam_instance_profile" "instance_profile" {
  role = aws_iam_role.role.name
}

resource "aws_iam_role" "role" {
  name = "EC2InstanceProfileForImageBuilder"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "EC2InstanceProfileForImageBuilder" {
  role       = aws_iam_role.role.name
  policy_arn = "arn:aws:iam::aws:policy/EC2InstanceProfileForImageBuilder"
}

resource "aws_iam_role_policy_attachment" "EC2InstanceProfileForImageBuilderECRContainerBuilds" {
  role       = aws_iam_role.role.name
  policy_arn = "arn:aws:iam::aws:policy/EC2InstanceProfileForImageBuilderECRContainerBuilds"
}

resource "aws_iam_role_policy_attachment" "AmazonSSMManagedInstanceCore" {
  role       = aws_iam_role.role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}