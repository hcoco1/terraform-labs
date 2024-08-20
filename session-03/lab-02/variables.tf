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