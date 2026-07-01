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

variable "s3s" {
  type = map(object({
    name                  = string
    blockpublicacls       = bool
    blockpublicpolicy     = bool
    ignorepublicacls      = bool
    restrictpublicbuckets = bool
    environment           = string
    enable_versioning     = string
    rules = map(object({
      id     = string
      status = string
      expiration = optional(map(object({
        date = optional(string)
        days = optional(number)
      })))
      transition = optional(map(object({
        date          = optional(string)
        days          = optional(number)
        storage_class = string
      })))
      filters = optional(map(object({
        prefix                   = optional(string)
        object_size_greater_than = optional(number)
        object_size_less_than    = optional(number)
      })))
    }))
    notifications = map(object({
      lambda_function = list(object({
        id                 = optional(string)
        lambda_function_arn = string
        events              = list(string)
        filter_prefix       = optional(string)
        filter_suffix       = optional(string)
      }))
    }))
    replication_role = optional(string)
    replication_rules = list(object({
      id       = optional(string)
      status   = string
      destination = object({
        bucket = string
      })
    }))
    specifictags          = map(string)
  }))
}

variable "agent_runtime_configurations" {
  description = "Bedrock AgentCore Agent Runtime configurations"
  type = map(object({
    agent_runtime_name = string
    role_arn           = string
    description        = optional(string, "")
    container_uri      = optional(string)
    code_configuration = optional(object({
      entry_point   = list(string)
      runtime       = string
      s3_bucket     = string
      s3_prefix     = string
      s3_version_id = optional(string)
    }))
    network_mode           = optional(string, "PUBLIC")
    vpc_security_group_ids = optional(list(string), [])
    vpc_subnet_ids         = optional(list(string), [])
    server_protocol        = optional(string)
    environment_variables  = optional(map(string), {})
    name                   = optional(string)
  }))
  default = {}
}
