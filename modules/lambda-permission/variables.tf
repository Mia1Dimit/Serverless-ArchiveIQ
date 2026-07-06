variable "statement_id" {
  type        = string
  default     = ""
  description = "The statement ID for the Lambda permission."
}

variable "action" {
  type        = string
  default     = "lambda:InvokeFunction"
  description = "The action that the principal can use on the Lambda function."
}

variable "function_name" {
  type        = string
  description = "The name of the Lambda function."
}

variable "principal" {
  type        = string
  description = "The AWS service or account that is allowed to invoke the Lambda function."
}

variable "source_arn" {
  type        = string
  description = "The ARN of the resource that is allowed to invoke the Lambda function."
}

variable "function_url_auth_type" {
  type        = string
  default     = null
  description = "The type of authentication for the Lambda function URL. Valid values are 'NONE' and 'AWS_IAM'."
}
