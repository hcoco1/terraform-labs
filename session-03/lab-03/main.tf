terraform {
  required_version = "~> 1.9"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {}

data "aws_ami" "amzn-linux-2023-ami" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

resource "aws_instance" "instance" {
  for_each = toset(var.instance_names)

  ami           = data.aws_ami.amzn-linux-2023-ami.id
  instance_type = "t2.micro"

  tags = {
    Name = eack.key
  }
}