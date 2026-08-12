# Made with CHatGPT consulting
variable "instance_type" {
  description = "Choose EC2 type: t3.micro, t3.small, t3.medium"
  type        = string

  validation {
    condition = contains([
      "t3.micro",
      "t3.small",
      "t3.medium"
    ], var.instance_type)

    error_message = "Allowed values: t3.micro, t3.small, t3.medium."
  }
}