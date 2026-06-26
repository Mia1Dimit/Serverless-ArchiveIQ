variable "bucket_name" {
  type = string
}

variable "force_destroy" {
  type        = bool
  default     = false
  description = "Force to delete all object inside the bucket"
}

variable "blockpublicacls" {
  type        = bool
  default     = true
  description = "Amazon S3 should block public ACLs for this bucket"
}

variable "blockpublicpolicy" {
  type        = bool
  default     = false
  description = "Amazon S3 should block public bucket policies for this bucket"
}

variable "ignorepublicacls" {
  type        = bool
  default     = false
  description = "Amazon S3 should ignore public ACLs for this bucket."
}

variable "restrictpublicbuckets" {
  type        = bool
  default     = false
  description = "Amazon S3 should restrict public bucket policies for this bucket"
}

variable "acl" {
  type        = string
  default     = "private"
  description = "The ACL for the S3 bucket (e.g., private, public-read, etc.)"
}

variable "enable_versioning" {
  type        = string
  default     = "Enabled"
  description = "Versioning state of the bucket (Enabled, Disabled, Suspended)"
}

variable "object_ownership" {
  type        = string
  default     = "BucketOwnerEnforced"
  description = "Object ownership setting (BucketOwnerEnforced, BucketOwnerPreferred, ObjectWriter)"
}

variable "rules" {
  description = "Lifecycle rules for the S3 bucket"
  type = map(object({
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
  default = {}
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

variable "name" {
  description = "Name of the S3 bucket"
  type        = string
}

variable "specifictags" {
  type        = map(string)
  description = "Specific tags for the resource"
  default     = {}
}

variable "purpose" {
  type        = string
  description = "Purpose of the S3 bucket"
  default     = "General Storage"
}

locals {
  common_tags = {
    Application_ID   = var.applicationid
    Application_Name = var.applicationname
    Environment      = var.environment
    Name             = var.name
    Module           = "s3-bucket"
    Purpose          = var.purpose
  }
  merged_tags = merge(local.common_tags, var.specifictags)
}