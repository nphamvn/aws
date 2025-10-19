terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
  backend "s3" {
    bucket = "075313985331-terraform"
    key    = "01-iam/terraform.tfstate"
  }
}

provider "aws" {

}

resource "aws_iam_user" "user" {
  name = "terraform-user"
}

resource "aws_iam_access_key" "ak" {
  user = aws_iam_user.user.name
}

provider "aws" {
  alias      = "test_user"
  access_key = aws_iam_access_key.ak.id
  secret_key = aws_iam_access_key.ak.secret
}

check "ping" { // maybe failed on first apply because IAM user is not yet fully propagated
  data "aws_caller_identity" "id" {
    provider = aws.test_user
  }

  assert {
    condition     = data.aws_caller_identity.id.user_id != ""
    error_message = "Unable to connect to AWS with new IAM user credentials"
  }
}