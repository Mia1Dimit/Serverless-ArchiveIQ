variable "function_name" {
  description = "The name of the Lambda function."
  type        = string
}

variable "role_arn" {
  description = "The ARN of the IAM role that Lambda assumes when it executes the function."
  type        = string
}

variable "handler" {
  description = "The function entrypoint in your code."
  type        = string
  default     = null
}

variable "runtime" {
  description = "The runtime environment for the Lambda function."
  type        = string
}

variable "source_dir" {
  description = "Path to the source directory of the Lambda function."
  type        = string
  default     = null
}

variable "s3_bucket" {
  description = "S3 bucket where the deployment package is stored."
  type        = string
  default     = null
}

variable "s3_key" {
  description = "S3 key of an object containing the deployment package."
  type        = string
  default     = null
}

variable "s3_object_version" {
  description = "Object version containing the Lambda code."
  type        = string
  default     = null
}

variable "output_path" {
  description = "Path to the output zip file of the Lambda function."
  type        = string
  default     = null
}

variable "memory_size" {
  description = "Amount of memory in MB your Lambda function can use at runtime."
  type        = number
  default     = 128
}

variable "package_type" {
  description = "Lambda deployment package type. Valid values are 'Zip' and 'Image'. Defaults to 'Zip'."
  type        = string
  default     = null
}

variable "timeout" {
  description = "The amount of time your Lambda Function has to run in seconds."
  type        = number
  default     = 3
}

variable "description" {
  description = "Description of what your Lambda Function does."
  type        = string
  default     = ""
}

variable "publish" {
  description = "Whether to publish creation/change as a new Lambda Function Version."
  type        = bool
  default     = false
}

variable "environment_variables" {
  description = "Environment variables to pass to the function."
  type        = map(string)
  default     = {}
}

variable "layers" {
  description = "List of Lambda Layer Version ARNs."
  type        = list(string)
  default     = []
}

variable "tracing_config" {
  description = <<-EOT
    Tracing configuration for the Lambda function (X-Ray).
    Optional.
    - mode: Active | PassThrough
  EOT
  type = object({
    mode = string
  })
  default = null
}

variable "architectures" {
  description = "Instruction set architecture for your Lambda function. Valid values are [\"x86_64\"] and [\"arm64\"]. Default is [\"x86_64\"]. Removing this attribute, function's architecture stay the same"
  type        = list(string)
  default     = ["x86_64"]
}

variable "file_system_config" {
  description = <<-EOT
    Configuration block for EFS file system access.
    Must contain:
      - arn: ARN of the EFS Access Point
      - local_mount_path: The path inside the Lambda environment where the file system is mounted
  EOT
  type = object({
    arn              = string
    local_mount_path = string
  })
  default = null
}

variable "image_uri" {
  description = "URI of a container image in ECR (for Lambda Image support). Exactly one of filename, image_uri, or s3_bucket must be specified"
  type        = string
  default     = null
}

variable "image_config" {
  description = <<-EOT
    Configuration for the Lambda function's image.
    Optional fields:
      - entry_point: list(string)
      - command: list(string)
      - working_directory: string
  EOT
  type = object({
    entry_point       = optional(list(string))
    command           = optional(list(string))
    working_directory = optional(string)
  })
  default = null
}

variable "logging_config" {
  description = <<-EOT
    Logging configuration for the Lambda function.
    - application_log_level: for JSON structured logs, choose the detail level of the logs your application sends to CloudWatch when using supported logging libraries
    - log_format:  select between Text and structured JSON format for your function's logs
    - log_group: the CloudWatch log group your function sends logs to
    - system_log_level: for JSON structured logs, choose the detail level of the Lambda platform event logs sent to CloudWatch, such as ERROR, DEBUG, or INFO
  EOT
  type = object({
    application_log_level = string
    log_format            = string
    log_group             = string
    system_log_level      = string
  })
  default = null
}

variable "vpc_config" {
  description = <<-EOT
    VPC configuration for the Lambda function.
    Optional.
    - subnet_ids: List of subnet IDs.
    - security_group_ids: List of security group IDs.
  EOT
  type = object({
    subnet_ids         = list(string)
    security_group_ids = list(string)
  })
  default = null
}

variable "ephemeral_storage" {
  description = "Configuration for the Lambda function's ephemeral storage in MB."
  type = object({
    size = number
  })
  default = {
    size = 512
  }
}

locals {
  common_tags = {
    Application_ID    = var.applicationid
    Application_Name  = var.applicationname
    Environment       = var.environment
    Name              = var.function_name
  }
  merged_tags = merge(local.common_tags, var.specifictags)
}

variable "specifictags" {
  type        = map(string)
  description = "Specific tags for the resource"
}

variable "environment" {
  type        = string
  description = "Environment Tag"
}

variable "applicationid" {
  type        = string
  description = "Application_ID Tag"
}

variable "applicationname" {
  type        = string
  description = "Application_Name Tag"
}
