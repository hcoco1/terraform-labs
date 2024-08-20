# Session 04 - CMB-TF

## Lab 1 - Nested For Expressions

Open the `terraform-labs` directory in Visual Studio Code and create a new directory from the terminal:

```shell
mkdir -p session-04/labs
cd session-04/labs
code .
```

Next, make a new file named `session-04/labs/main.tf` in Visual Studio Code and paste the following code:

```terraform
locals {
  aws_iam_saml_provider_arn = "arn:aws:iam::123456789012:saml-provider/hcp-terraform"
  organization              = "acme"
  accounts = {
    shared = {
      organizational_unit = "Shared Services"
      components = {
        network = {
          resources = ["vpc", "subnet", "route_table", "internet_gateway"]
        }
        frontend = {
          resources = ["elb", "instance"]
        }
        backend = {
          resources = ["rds"]
        }
      }
    }
  }
}

output "original_data" {
  value = local.accounts
}
```

In the terminal, run:

```shell
terraform init
terraform apply -auto-approve
```

This exercise is setting the stage for integrations with HCP Terraform and AWS Landing Zones.  We will need to establish authentication capabilities for various workspaces and run phases in the future.  We need iterate over everything and get one list of role identities.

Update the `main.tf` file add the following code:

```terraform
locals {
  modified_accounts = {
    for k, v in local.accounts : k => v
  }
}

output "modified_data" {
  value = local.accounts
}
```

In the terminal, run: `terraform apply -auto-approve:`

This `modified_data` and `original_data` are the same.  We need to iterate over the nested maps and combine them.

Replace our last `locals` and `output` blocks in the `main.tf` file with the following code:

```terraform
locals {
  iam_roles = [
    for k, v in local.accounts : {
      for ki, vi in v.components :
      "${k}-${ki}" => {
        vi
      }
    }
  ]
}

output "modified_data" {
  value = local.iam_roles
}
```

We are on the right track, but we have a map inside a list.  We need to flatten the data structure.  Replace the last `locals` and `output` blocks in the `main.tf` file with the following code:

```terraform
locals {
  iam_roles = merge(flatten([
    for k, v in local.accounts : {
      for ki, vi in v.components :
      "${k}-${ki}" => vi
    }
  ])...)
}

output "modified_data" {
  value = local.iam_roles
}
```

In the terminal, run: `terraform apply -auto-approve`

Now, `local.iam_roles` is a map that we can use with `for_each` to create `aws_iam_role` resources.

However, for each of the roles, we need to create an authentication policy.  Update the `main.tf` file replacing the last `locals` and `output` blocks with the following code:

```terraform
locals {
  iam_roles = merge(flatten([
    for k, v in local.accounts : {
      for ki, vi in v.components :
      "${k}-${ki}" => vi
    }
  ])...)
}

output "iam_roles" {
  value = local.iam_roles
}

locals {
  iam_role_policies = merge(flatten([
    for k, v in local.accounts : [
      for kc, vc in v.components : {
        for run_phase in ["plan", "apply"] :
        "${k}-${kc}-${run_phase}" => {
          name      = "tfc-${k}-${kc}-role"
          effect    = "Allow"
          principal = local.aws_iam_saml_provider_arn
          action    = "sts:AssumeRoleWithWebIdentity"
          audience  = "app.terraform.io"
          subject = join(":", [
            "organization", local.organization,
            "project", k,
            "workspace", "${k}-${kc}",
            "run_phase", run_phase
          ])
        }
      }
    ]
  ])...)
}

output "modified_data" {
  value = local.iam_role_policies
}
```

In the terminal, run: `terraform apply -auto-approve`

We now have `local.iam_roles` for creating the IAM roles and `local.iam_role_policies` for creating the IAM role policies for each role.

Notice the various functions that we used within the code to assist with manipulating the data structure:

* `merge()`
* `flatten()`
* `join()`

## Lab 2 - Simplifying with Functions

Nested loops are difficult to read and we have to accommodate the different levels of scope for the temporary variables.  If we can find some way to reduce the nested loops, our code will be easier to read and maintain.

Update the last `locals` and `output` blocks in the `main.tf` file with the following code:

```terraform
locals {
  iam_role_policies = merge(flatten([
    for k, v in local.accounts : {
      for i in setproduct(keys(v.components), ["plan", "apply"]) :
      join("-", flatten([k, i])) => {
        name      = "tfc-${k}-${i[0]}-role"
        effect    = "Allow"
        principal = local.aws_iam_saml_provider_arn
        action    = "sts:AssumeRoleWithWebIdentity"
        audience  = "app.terraform.io"
        subject = join(":", [
          "organization", local.organization,
          "project", k,
          "workspace", "${k}-${i[0]}",
          "run_phase", i[1]
        ])
      }
    }
  ])...)
}

output "modified_data" {
  value = local.iam_role_policies
}
```

In the terminal, run: `terraform apply -auto-approve`

Notice that our `modified_data` is still the same, but we have eliminated one level of nesting in our functions.  We used the `setproduct()` function to create a Cartesian product of the keys of the `v.components` map and the list `["plan", "apply"]`.  This returns a list containing each component key and each run phase.


## Lab 3 - Using the `for` Expression

We now want to validate our data set by turning our original data structure into variables.  Update the `main.tf` file with the following code:

```terraform
variable "accounts" {
  default = {
    shared = {
      organizational_unit = "Shared Services"
      components = {
        network = {
          resources = ["vpc", "subnet", "route_table", "internet_gateway"]
        }
        frontend = {
          resources = ["elb", "instance"]
        }
        backend = {
          resources = ["rds"]
        }
      }
    }
  }
  description = "Account configuration."
  type = map(object({
    organizational_unit = string
    components = map(object({
      resources = list(string)
    }))
  }))
}

locals {
  aws_iam_saml_provider_arn = "arn:aws:iam::123456789012:saml-provider/hcp-terraform"
  organization              = "acme"
}

output "original_data" {
  value = var.accounts
}

locals {
  iam_roles = merge(flatten([
    for k, v in var.accounts : {
      for ki, vi in v.components :
      "${k}-${ki}" => vi
    }
  ])...)
}

output "iam_roles" {
  value = local.iam_roles
}

locals {
  iam_role_policies = merge(flatten([
    for k, v in var.accounts : {
      for i in setproduct(keys(v.components), ["plan", "apply"]) :
      join("-", flatten([k, i])) => {
        name      = "tfc-${k}-${i[0]}-role"
        effect    = "Allow"
        principal = local.aws_iam_saml_provider_arn
        action    = "sts:AssumeRoleWithWebIdentity"
        audience  = "app.terraform.io"
        subject = join(":", [
          "organization", local.organization,
          "project", k,
          "workspace", "${k}-${i[0]}",
          "run_phase", i[1]
        ])
      }
    }
  ])...)
}

output "modified_data" {
  value = local.iam_role_policies
}
```

In the terminal, run: `terraform apply -auto-approve`

You can see that we have the same results as before.  Now we want to ensure that all of the resources defined within the `components` are within a valid set.

Update the `variable` block in the `main.tf` file with the following code:

```terraform
variable "accounts" {
  default = {
    shared = {
      organizational_unit = "Shared Services"
      components = {
        network = {
          resources = ["vpc", "subnet", "route_table", "internet_gateway"]
        }
        frontend = {
          resources = ["elb", "instance"]
        }
        backend = {
          resources = ["rds"]
        }
      }
    }
    other = {
      organizational_unit = "Shared Services"
      components = {
        network = {
          resources = ["vpc", "subnet", "route_table", "internet_gateway"]
        }
        frontend = {
          resources = ["elb", "instance"]
        }
        backend = {
          resources = ["rds"]
        }
      }
    }
  }
  description = "Account configuration."
  type = map(object({
    organizational_unit = string
    components = map(object({
      resources = list(string)
    }))
  }))

  validation {
    condition = alltrue(flatten([
      for k, v in var.accounts : [
        for kc, vc in v.components : [
          for i in vc.resources : contains(
            [
              "vpc",
              "subnet",
              "route_table",
              "internet_gateway",
              "elb",
              "instance",
              "rds"
            ],
            i
          )
        ]
      ]
    ]))
    error_message = "Component resources must be one of the following: vpc, subnet, route_table, internet_gateway, elb, instance, rds."
  }
}

locals {
  aws_iam_saml_provider_arn = "arn:aws:iam::123456789012:saml-provider/hcp-terraform"
  organization              = "acme"
}

output "original_data" {
  value = var.accounts
}

locals {
  iam_roles = merge(flatten([
    for k, v in var.accounts : {
      for ki, vi in v.components :
      "${k}-${ki}" => vi
    }
  ])...)
}

output "iam_roles" {
  value = local.iam_roles
}

locals {
  iam_role_policies = merge(flatten([
    for k, v in var.accounts : {
      for i in setproduct(keys(v.components), ["plan", "apply"]) :
      join("-", flatten([k, i])) => {
        name      = "tfc-${k}-${i[0]}-role"
        effect    = "Allow"
        principal = local.aws_iam_saml_provider_arn
        action    = "sts:AssumeRoleWithWebIdentity"
        audience  = "app.terraform.io"
        subject = join(":", [
          "organization", local.organization,
          "project", k,
          "workspace", "${k}-${i[0]}",
          "run_phase", i[1]
        ])
      }
    }
  ])...)
}

output "modified_data" {
  value = local.iam_role_policies
}
```

In the terminal, run: `terraform apply -auto-approve`

Everything runs as expected.  Now, let's remove "rds" on line 52 and run it again.

Our validation failed, but our error message was not updated.

Thanks to Cross-Object References in Terraform v1.9, we can store that list separately and reference it.  Update the `variable` block in the `main.tf` file with the following code:

```terraform
locals {
  valid_resources = [
    "vpc",
    "subnet",
    "route_table",
    "internet_gateway",
    "elb",
    "instance",
    "rds",
  ]
}

variable "accounts" {
  default = {
    shared = {
      organizational_unit = "Shared Services"
      components = {
        network = {
          resources = ["vpc", "subnet", "route_table", "internet_gateway"]
        }
        frontend = {
          resources = ["elb", "instance"]
        }
        backend = {
          resources = ["rds"]
        }
      }
    }
    other = {
      organizational_unit = "Shared Services"
      components = {
        network = {
          resources = ["vpc", "subnet", "route_table", "internet_gateway"]
        }
        frontend = {
          resources = ["elb", "instance"]
        }
        backend = {
          resources = ["rds"]
        }
      }
    }
  }
  description = "Account configuration."
  type = map(object({
    organizational_unit = string
    components = map(object({
      resources = list(string)
    }))
  }))

  validation {
    condition = alltrue(flatten([
      for k, v in var.accounts : [
        for kc, vc in v.components : [
          for i in vc.resources : contains(
            local.valid_resources,
            i
          )
        ]
      ]
    ]))
    error_message = "Component resources must be one of the following: ${join(", ", local.valid_resources)}"
  }
}
```

In the terminal, run: `terraform apply -auto-approve`

We see that things function as expected.  Now we will remove "rds" from the `valid_resources` list and run it again.

We get a validation failure and our error message is updated.
