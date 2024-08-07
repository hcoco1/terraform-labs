terraform {
  required_version = "~> 1.8"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

resource "random_string" "random" {
  length  = 5
  special = false
  upper   = false
}

module "bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 4.1"

  bucket = join("-", [var.bucket_base_name, random_string.random.result])
  versioning = {
    enabled = true
  }
}

module "state_lock" {
  source  = "terraform-aws-modules/dynamodb-table/aws"
  version = "~> 4.0"

  name           = join("-", [var.bucket_base_name, random_string.random.result])
  hash_key       = "LockID"
  billing_mode   = "PROVISIONED"
  read_capacity  = 1
  write_capacity = 1

  attributes = [
    {
      name = "LockID"
      type = "S"
    }
  ]
}
