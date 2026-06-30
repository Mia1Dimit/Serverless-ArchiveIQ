variable "bucket" {
  description = "The name of the S3 bucket to which to apply notifications."
  type        = string
}

variable "eventbridge" {
  description = "Enables S3 EventBridge notifications for the bucket."
  type        = bool
  default     = false
}

variable "lambda_functions" {
  description = <<EOF
List of Lambda function notification configurations.
Each object supports:
- id
- lambda_function_arn
- events (list)
- filter_prefix (optional)
- filter_suffix (optional)
EOF
  type = list(object({
    id                 = optional(string)
    lambda_function_arn = string
    events              = list(string)
    filter_prefix       = optional(string)
    filter_suffix       = optional(string)
  }))
  default = []
}

variable "queues" {
  description = <<EOF
List of SQS queue notification configurations.
Each object supports:
- id
- queue_arn
- events (list)
- filter_prefix (optional)
- filter_suffix (optional)
EOF
  type = list(object({
    id           = optional(string)
    queue_arn    = string
    events       = list(string)
    filter_prefix = optional(string)
    filter_suffix = optional(string)
  }))
  default = []
}

variable "topics" {
  description = <<EOF
List of SNS topic notification configurations.
Each object supports:
- id
- topic_arn
- events (list)
- filter_prefix (optional)
- filter_suffix (optional)
EOF
  type = list(object({
    id          = optional(string)
    topic_arn   = string
    events      = list(string)
    filter_prefix = optional(string)
    filter_suffix = optional(string)
  }))
  default = []
}
