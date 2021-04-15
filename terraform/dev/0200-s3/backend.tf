terraform {
  backend "s3" {}

  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  assume_role {
    role_arn = "arn:aws:iam::${local.group_vars_map["account_id"]}:role/${local.all_vars_map["tfrole"]}"
  }
}
