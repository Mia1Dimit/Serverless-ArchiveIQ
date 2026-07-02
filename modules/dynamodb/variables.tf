# ==============================================================================
# DynamoDB Module Variables
# ==============================================================================
# Pattern: Module variables are GENERIC (like npm registry package)
# Defaults are minimal - let infrastructure layer provide project defaults
# ==============================================================================

# -----------------------------------------------------------------------------
# Required Variables (No Defaults)
# -----------------------------------------------------------------------------

variable "table_name" {
  type        = string
  description = "Name of the DynamoDB table (must be globally unique in account/region)"
}

variable "hash_key" {
  type        = string
  description = "Partition key attribute name"
}

variable "range_key" {
  type        = string
  description = "Sort key attribute name (optional)"
  default     = null
}

variable "environment" {
  type        = string
  description = "Environment tag (dev, staging, prod)"
}

variable "applicationid" {
  type        = string
  description = "Application ID tag"
}

variable "applicationname" {
  type        = string
  description = "Application name tag"
}

variable "name" {
  type        = string
  description = "Logical name for this table (used in tags)"
}

# -----------------------------------------------------------------------------
# Optional Variables (Module Defaults - Generic)
# -----------------------------------------------------------------------------

variable "billing_mode" {
  type        = string
  description = "Billing mode: PAY_PER_REQUEST (on-demand) or PROVISIONED"
  default     = "PAY_PER_REQUEST"  # Recommended for dev/learning
}

variable "read_capacity" {
  type        = number
  description = "Read capacity units (only used if billing_mode = PROVISIONED)"
  default     = 5
}

variable "write_capacity" {
  type        = number
  description = "Write capacity units (only used if billing_mode = PROVISIONED)"
  default     = 5
}

variable "global_secondary_indexes" {
  type = list(object({
    name               = string
    hash_key           = string
    range_key          = optional(string)
    projection_type    = optional(string)
    non_key_attributes = optional(list(string))
    read_capacity      = optional(number)
    write_capacity     = optional(number)
  }))
  description = "List of Global Secondary Indexes (GSIs)"
  default     = []
}

variable "enable_point_in_time_recovery" {
  type        = bool
  description = "Enable continuous backups (point-in-time recovery)"
  default     = false  # Costs extra, enable in production
}

variable "enable_encryption" {
  type        = bool
  description = "Enable server-side encryption at rest"
  default     = true  # Security best practice
}

variable "kms_key_arn" {
  type        = string
  description = "ARN of KMS key for encryption (null = AWS-owned key)"
  default     = null
}

variable "ttl_attribute_name" {
  type        = string
  description = "Attribute name for TTL (time-to-live) - null to disable"
  default     = null
}

variable "stream_enabled" {
  type        = bool
  description = "Enable DynamoDB Streams (for Lambda triggers)"
  default     = false
}

variable "stream_view_type" {
  type        = string
  description = "Stream view type: KEYS_ONLY, NEW_IMAGE, OLD_IMAGE, NEW_AND_OLD_IMAGES"
  default     = "NEW_AND_OLD_IMAGES"
}

variable "purpose" {
  type        = string
  description = "Purpose of the table"
  default     = "General NoSQL Database"
}

variable "specifictags" {
  type        = map(string)
  description = "Specific tags for this resource"
  default     = {}
}
