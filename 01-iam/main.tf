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

resource "aws_iam_policy_attachment" "att" {
  name = "s3-read-only"
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
  users = [ aws_iam_user.user.name ]
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

check "list-s3-buckets" {
  data "aws_s3_bucket" "buckets" {
    provider = aws.test_user
  }

  assert {
    condition     = data.aws_s3_buckets.buckets.ids != null
    error_message = "IAM user unable to list S3 buckets"
  }
}

provider "aws" {
  alias      = "test_user"
  access_key = aws_iam_access_key.ak.id
  secret_key = aws_iam_access_key.ak.secret
}