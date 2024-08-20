variable "instance_count" {
  type = number

  validation {
    condition     = var.instance_count >= 0 && var.instance_count <= 5
    error_message = "The value instance_count must be a number between 0-5, inclusively."
  }
}

variable "enable_public_ip" {
  default     = false
  description = "Whether to assign a public IP address to the instance (default: false)."
  type        = bool
}

variable "instance_type" {
  default     = "t2.micro"
  description = "The instance type to create in the deployment."
  type        = string

  validation {
    condition     = contains(["t2.micro", "t2.small", "t2.medium"], var.instance_type)
    error_message = "The value instance_type must be one of 't2.micro', 't2.small', or 't2.medium'."
  }
}

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

