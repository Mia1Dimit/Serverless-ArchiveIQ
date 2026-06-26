variable "name" {
  description = "Friendly name of the role. If omitted, Terraform will assign a random, unique name."
  type        = string
  default     = null
}

variable "assume_role_policy" {
  description = "Policy that grants an entity permission to assume the role."
  type        = string
}
variable "description" {
  description = "Description of the role."
  type        = string
  default = null
}

variable "force_detach_policies" {
  description = "Whether to force detaching any policies the role has before destroying it."
  type        = bool
  default     = false
}
variable "max_session_duration" {
  description = "Maximum session duration (in seconds) that you want to set for the specified role. If you do not specify a value for this setting, the default maximum of one hour is applied. This setting can have a value from 1 hour to 12 hours."
  type        = number
  default     = null
}
variable "path" {
  description = "Path to the role."
  type        = string
  default     = null
}
variable "permissions_boundary" {
  description = "ARN of the policy that is used to set the permissions boundary for the role."
  type        = string
  default     = null
}
locals {
  common_tags = {
    Application_Group = var.applicationgroup
    Application_ID    = var.applicationid
    Application_Name  = var.applicationname
    Environment       = var.environment
    Name              = var.name
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