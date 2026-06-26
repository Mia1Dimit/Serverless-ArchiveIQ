variable "applicationid" {
  description = "Application ID for tagging"
  type        = string
}

variable "applicationname" {
  description = "Application name for tagging"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}


variable "iam_roles" {
  description = "IAM role configurations"
  type = map(object({
    name               = string
    assume_role_policy = string
    specifictags       = optional(map(string), {})
    policies = optional(map(object({
      name   = string
      policy = string
    })), {})
    managed_policies = optional(map(object({
      policy_arn = string
    })), {})
  }))
  default = {}
}

variable "lambda_functions" {
  description = "Lambda function configurations"
  type = map(object({
    name                  = string
    handler               = string
    runtime               = string
    timeout               = optional(number, 30)
    memory_size           = optional(number, 128)
    environment_variables = optional(map(string), {})
    source_dir            = string
    output_path           = string
    vpc_config = optional(object({
      subnet_ids         = list(string)
      security_group_ids = list(string)
    }))
  }))
  default = {}
}
