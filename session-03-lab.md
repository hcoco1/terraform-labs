# Session 03 - CMB-TF

## Lab 1 - Variable Validation

Open the `terraform-labs` directory in Visual Studio Code and create a new directory from the terminal:

```shell
mkdir -p session-03/lab-01
cd session-03/lab-01
```

Next, make a new file named `session-03/lab-01/variables.tf` in Visual Studio Code and paste the following code:

```terraform
variable "instance_count" {}
```

In the terminal, run (and enter "Hello" when prompted for `instance_count`):

```shell
terraform init
terraform apply
```

By not declaring a data type, any value can be provided.

Update the `variables.tf` file by replacing it with the following code:

```terraform
variable "instance_count" {
  type = number
}
```

In the terminal, re-run the previous commands and enter "Hello" when prompted for `instance_count`:

```shell
terraform apply
```

This will result in an error because we supplied an input value that is a string.

Perhaps we need to ensure that value is within some limits.

Update the `variables.tf` file by replacing it with the following code:

```terraform
variable "instance_count" {
  type = number

  validation {
    condition     = var.instance_count >= 0 && var.instance_count <= 5
    error_message = "The value instance_count must be a number between 0-5, inclusively."
  }
}
```

In the terminal, re-run the previous commands and enter "6" when prompted for `instance_count`:

```shell
terraform apply
```

This will create an error message "The value instance_count must be a number between 0-5, inclusively." which directs the user back to the value of the variable input.

Re-run it again with a value of "3" when prompted for `instance_count`, and it will run successfully.

Validating bool values is far simpler since there are only two possible values, which are built in.  Using a default is the best practice.  As of Terraform v1.9, validation can reference other identifiers, but it is not included in the current version of the exam.

Add the following variable declaration to the `variables.tf` file:

```terraform
variable "enable_public_ip" {
  default     = false
  description = "Whether to assign a public IP address to the instance (default: false)."
  type        = bool
}
```

String values have many more possibilities, so we can use a list of valid values to restrict the input to a set of possible values.  Add the following variable declaration to the `variables.tf` file:

```terraform
variable "instance_type" {
  default     = "t2.micro"
  description = "The instance type to create in the deployment."
  type        = string

  validation {
    condition     = contains(["t2.micro", "t2.small", "t2.medium"], var.instance_type)
    error_message = "The value instance_type must be one of 't2.micro', 't2.small', or 't2.medium'."
  }
}
```

Validating with collections and structural types is more complex as we have to iterate over each value in the object.  We can use the `alltrue()` function along with a `for` expression to validate each value in the list.  Add the following variable declaration to the `variables.tf` file:

```terraform
variable "instance_names" {
  default     = ["alpha", "beta", "gamma"]
  description = "A list of instance names to create in the deployment."
  type        = list(string)

  validation {
    condition     = alltrue(
      [
        for i in var.instance_names :
        can(
          regex("^[a-z0-9-]+$", i)
        )
      ]
    )
    error_message = "The value instance_names must contain only lowercase letters, numbers, and hyphens."
  }
}
```

## Lab 2 - Deploying with Count

Open the `terraform-labs` directory in Visual Studio Code and create a new directory from the terminal:

```shell
mkdir -p session-03/lab-02
cd session-03/lab-02
```

Create a new file named `session-03/lab-02/variables.tf` in Visual Studio Code and paste the following code:

```terraform
variable "instance_names" {
  default     = ["alpha", "beta", "gamma"]
  description = "A list of instance names to create in the deployment."
  type        = list(string)

  validation {
    condition     = alltrue(
      [
        for i in var.instance_names :
        can(
          regex("^[a-z0-9-]+$", i)
        )
      ]
    )
    error_message = "The value instance_names must contain only lowercase letters, numbers, and hyphens."
  }
}
```

Create a `main.tf` file with the following:

```terraform
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
  count = length(var.instance_names)

  ami           = data.aws_ami.amzn-linux-2023-ami.id
  instance_type = "t2.micro"

  tags = {
    Name = var.instance_names[count.index]
  }
}
```

Create a `outputs.tf` file with the following:

```terraform
output "instance_ids" {
  value = aws_instance.instance.*.id
}
```

In the terminal (Linux/macOS), run (using your access credentials):

```shell
export AWS_ACCESS_KEY_ID="<Your AWS_ACCESS_KEY_ID Here>"
export AWS_SECRET_ACCESS_KEY="<Your AWS_SECRET_ACCESS_KEY Here>"
export AWS_SESSION_TOKEN="<Your AWS_SESSION_TOKEN Here>"
export AWS_REGION="us-east-1"
terraform init
terraform plan -out tfplan
terraform apply tfplan
```

In the PowerShell terminal (Windows), run (using your access credentials):

```powershell
$Env:AWS_ACCESS_KEY_ID = '<Your AWS_ACCESS_KEY_ID Here>'
$Env:AWS_SECRET_ACCESS_KEY = '<Your AWS_SECRET_ACCESS_KEY Here>'
$Env:AWS_SESSION_TOKEN = '<Your AWS_SESSION_TOKEN Here>'
$Env:AWS_REGION = 'us-east-1'
terraform init
terraform plan -out tfplan
terraform apply tfplan
```

This will create three EC2 instances with the names "alpha", "beta", and "gamma".

Suppose we want to eliminate "beta" because users experience errors when using it.  Create a `terraform.tfvars` file with the following:

```terraform
instance_names = ["alpha", "gamma"]
```

In the terminal, run:

```shell
terraform plan
```

This can often create issues for the remaining instances, espeically if we are changing an immutable property.  In this case.  It almost always results in undesirable behavior.

Destroy the instances by running:

```shell
terraform destroy -auto-approve
```

## Lab 3 - Deploying with For Each

Open the `terraform-labs` directory in Visual Studio Code and create a new directory from the terminal:

```shell
mkdir -p session-03/lab-03
cd session-03/lab-03
code .
```

We will be creating the same files with minor variations:

`variables.tf` (no changes):

```terraform
variable "instance_names" {
  default     = ["alpha", "beta", "gamma"]
  description = "A list of instance names to create in the deployment."
  type        = list(string)

  validation {
    condition     = alltrue(
      [
        for i in var.instance_names :
        can(
          regex("^[a-z0-9-]+$", i)
        )
      ]
    )
    error_message = "The value instance_names must contain only lowercase letters, numbers, and hyphens."
  }
}
```

```terraform
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
```

Create a `outputs.tf` file with the following:

```terraform
output "instance_ids" {
  value = [ for k, v in aws_instance.instance : v.id ]
}
```

In the terminal (Linux/macOS), run (using your access credentials):

```shell
export AWS_ACCESS_KEY_ID="<Your AWS_ACCESS_KEY_ID Here>"
export AWS_SECRET_ACCESS_KEY="<Your AWS_SECRET_ACCESS_KEY Here>"
export AWS_SESSION_TOKEN="<Your AWS_SESSION_TOKEN Here>"
export AWS_REGION="us-east-1"
terraform init
terraform plan -out tfplan
terraform apply tfplan
```

In the PowerShell terminal (Windows), run (using your access credentials):

```powershell
$Env:AWS_ACCESS_KEY_ID = '<Your AWS_ACCESS_KEY_ID Here>'
$Env:AWS_SECRET_ACCESS_KEY = '<Your AWS_SECRET_ACCESS_KEY Here>'
$Env:AWS_SESSION_TOKEN = '<Your AWS_SESSION_TOKEN Here>'
$Env:AWS_REGION = 'us-east-1'
terraform init
terraform plan -out tfplan
terraform apply tfplan
```

This will create three EC2 instances with the names "alpha", "beta", and "gamma".

Now, we will eliminate "beta" again, using the same `terraform.tfvars` file:

```terraform
instance_names = ["alpha", "gamma"]
```

In the terminal, run:

```shell
terraform plan
```

Because it is a "named" instance, Terraform doesn't care about the index or order of the list.  It will only impact the instances that we have intended.

Destroy the instances by running:

```shell
terraform destroy -auto-approve
```
