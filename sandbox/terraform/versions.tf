terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

provider "aws" {
  alias  = "ap_south_1"
  region = "ap-south-1"
  assume_role {
    role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/AWSAFTExecution"
  }
  default_tags {
    tags = {
      managed_by = "AFT"
    }
  }
}
