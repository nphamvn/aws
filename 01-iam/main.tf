terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
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

check "ping" {
  data "aws_caller_identity" "id" {
    provider = aws.test_user
  }

  assert {
    condition     = data.aws_caller_identity.id.account_id != ""
    error_message = "Unable to connect to AWS with new IAM user credentials"
  }
}

provider "aws" {
  alias      = "test_user"
  access_key = aws_iam_access_key.ak.id
  secret_key = aws_iam_access_key.ak.secret
}