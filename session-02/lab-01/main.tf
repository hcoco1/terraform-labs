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

