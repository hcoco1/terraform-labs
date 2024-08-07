# Session 02 - CMB-TF

## Lab 1 - Terraform Modules

Open the `terraform-labs` directory in Visual Studio Code and create a new directory from the terminal:

```shell
mkdir -p session-02/lab-01
cd session-02/lab-01
```

Next, make a new file named `session-02/lab-01/main.tf` in Visual Studio Code and paste the following code:

```terraform
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
```

Next, create a `variables.tf` file with the following contents:

```terraform
variable "bucket_base_name" {
  default     = "session2-bucket"
  type        = string
  description = "Suffix for resource names"
}
```

Set environment variables (change to your values; you must run this again any time you create a new terminal session).  In the terminal, run:

```shell
export AWS_ACCESS_KEY_ID="REPLACE_WITH_YOUR_ACCESS_KEY_ID"
export AWS_SECRET_ACCESS_KEY="REPLACE_WITH_YOUR_SECRET_ACCESS_KEY"
export AWS_SESSION_TOKEN="REPLACE_WITH_YOUR_SESSION_KEY"
export AWS_REGION="us-east-1"
```

```powershell
$Env:AWS_ACCESS_KEY_ID = 'REPLACE_WITH_YOUR_ACCESS_KEY_ID'
$Env:AWS_SECRET_ACCESS_KEY = 'REPLACE_WITH_YOUR_SECRET_ACCESS_KEY'
$Env:AWS_REGION = 'us-east-1'
```

In the terminal, run:

```shell
terraform init
terraform plan -out=tfplan
terraform apply tfplan
ls
cat terraform.tfstate
terraform state list
terraform state show random_string.random
terraform apply -replace=random_string.random
terraform state show random_string.random
```

Add the following to `session-02/lab-01/main.tf`:

```terraform
module "state_lock" {
  source  = "terraform-aws-modules/dynamodb-table/aws"
  version = "~> 4.0"

  name           = join("-", [var.bucket_base_name, random_string.random.result])
  hash_key       = "LockID"
  billing_mode   = "PROVISIONED
  read_capacity  = 1
  write_capacity = 1

  attributes = [
    {
      name = "LockID"
      type = "S"
    }
  ]
}
```

Create a new file named `session-02/lab-01/outputs.tf` in Visual Studio Code and paste the following code:

```terraform
output "bucket_name" {
  value = module.bucket.s3_bucket_id
}

output "dynamodb_table_name" {
  value = module.state_lock.dynamodb_table_id
}
```

In the terminal, run:

```shell
terraform init
terraform plan -out=tfplan
terraform apply tfplan
terraform state list
```

Review resources.

Cleanup your resources to avoid cost accrual.

```shell
terraform destroy -auto-approve
```

## Lab 2 - Terraform State

Open the `terraform-labs` directory in Visual Studio Code and create a new directory from the terminal:

```shell
mkdir -p session-02/lab-02
cd session-02/lab-02
```

We will be redeploying the code from lab-01. Create a new file named `session-02/lab-02/main.tf` in Visual Studio Code and paste the following code:

```terraform
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
```

Likewise, create a new file named `session-02/lab-02/variables.tf` in Visual Studio Code and paste the following code:

```terraform
variable "bucket_base_name" {
  default     = "session2-bucket"
  type        = string
  description = "Suffix for resource names"
}
```

Finally, create a new file named `session-02/lab-02/outputs.tf` in Visual Studio Code and paste the following code:

```terraform
output "bucket_name" {
  value = module.bucket.s3_bucket_id
}

output "dynamodb_table_name" {
  value = module.state_lock.dynamodb_table_id
}
```

Run the following from the terminal (ensure to set your AWS environment variables, if necessary):

```shell
terraform apply -auto-approve
```

Update the file named `session-02/lab-02/main.tf` by inserting the `backend` block below as situated between the `terraform` block and the `provider` block (Ensure to replace the bucket and key with your values):

```terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "REPLACE_WITH_YOUR_BUCKET_NAME"
    key            = "terraform.tfstate"
    dynamodb_table = "REPLACE_WITH_YOUR_KEY_NAME"
  }
}

provider "aws" {}
```

Now we must run `terraform init` in order to move the state.  Then we can remove the state and run another apply.  In the terminal, run:

```shell
terraform init
rm terraform.tfstate*
terraform apply
```

Since we have created some Terraform inception where we have the state for the code that creates the S3 bucket that holds the remote state, we have to move the state back to local before we can destroy our resources.  Update the file named `session-02/lab-02/main.tf` by commenting the `backend` block below:

```terraform
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }

  # backend "s3" {
  #   bucket = "REPLACE_WITH_YOUR_BUCKET_NAME"
  #   key    = "REPLACE_WITH_YOUR_KEY_NAME"
  #   dynamodb_table = "dyntbl_terraform.tfstate"
  # }
}

provider "aws" {}
```

Now we must run `terraform init` again in order to move the state.  Then we can remove the state and run another apply.  In the terminal, run:

```shell
terraform init -migrate-state
terraform apply
```

There should be a `terraform.tfstate` file locally, again.

NOTE: Moving state locally is a common pattern for moving state from one remote backend type to another as many are not support to shift directly from one to another.

Cleanup your resources to avoid cost accrual.  Go into your S3 bucket and empty the contents from the portal or via the AWS CLI.

From the terminal, run:

```shell
terraform destroy -auto-approve
```

## Lab 3 - Providers with Multi-Accounts (Demo)

If you wish to practice, you will require an AWS Organization be setup with multiple accounts.  Otherwise, you can follow along with the demo.

Open the `terraform-labs` directory in Visual Studio Code and create a new directory from the terminal:

```shell
mkdir -p session-02/lab-03
cd session-02/lab-03
```

Next, make a new file named `session-02/lab-03/main.tf` in Visual Studio Code and paste the following code:

```terraform
terraform {
  required_version = "~> 1.8"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  cidr = "10.42.0.0/16"
  private_subnet_names = ["private-1a", "private-1b", "private-1c"]
}
```

From the terminal, run the follow:

```shell
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

Create a role in your Shared Services account to authenticate and grant your IAM user permissions to assume the role.

Update the file `session-02/lab-03/main.tf` by replacing it with the following code:

```terraform
terraform {
  required_version = "~> 1.8"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {}

provider "aws" {
  alias = "transit"

  assume_role {
    role_arn = var.transit_vpc_role_arn
  }
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  cidr                 = "10.42.0.0/16"
  private_subnet_names = ["private-1a", "private-1b", "private-1c"]
}

module "transit" {
  providers = {
    aws = aws.transit
  }

  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  cidr                 = "10.10.0.0/16"
  public_subnet_names  = ["public-1a", "public-1b", "public-1c"]
  private_subnet_names = ["private-1a", "private-1b", "private-1c"]
}

resource "aws_vpc_peering_connection" "transit" {
  provider = aws.transit

  vpc_id      = module.transit.vpc_id
  peer_vpc_id = module.vpc.vpc_id

  auto_accept = true
}
```

Create a new file named `session-02/lab-03/variables.tf` in Visual Studio Code and paste the following code (Ensuring that you replace the role ARN with your own):

```terraform
variable "transit_vpc_role_arn" {
  default = "REPLACE WITH YOUR ROLE ARN"
  type    = string
}
```

Run the following from the terminal:

```shell
terraform plan -out=tfplan
terraform apply tfplan
```

Review the resources created.

Cleanup your resources to avoid cost accrual.

```shell
terraform destroy -auto-approve
```