variable "name" {
  description = "The name of the IAM policy. If omitted, Terraform will assign a random, unique name."
  type        = string
}

variable "name_prefix" {
  description = "Creates a unique name beginning with the specified prefix. Conflicts with name."
  type        = string
  default     = null
}

variable "role" {
  description = "The IAM role name to which this policy should be attached."
  type        = string
}

variable "policy" {
  description = "The inline policy document. This is a JSON formatted string. For more information about building IAM policy documents with Terraform"
  type = string
}