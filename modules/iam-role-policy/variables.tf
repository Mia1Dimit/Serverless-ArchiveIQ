variable "role" {
  description = "The name of the IAM role to which the policy should be applied"
  type        = string
}

variable "policy_arn" {
  description = "The ARN of the policy you want to apply"
  type        = string
}
