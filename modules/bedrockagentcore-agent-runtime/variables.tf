variable "agent_runtime_name" {
  type        = string
  description = "Name of the Bedrock AgentCore Agent Runtime"
}

variable "role_arn" {
  type        = string
  description = "ARN of the IAM role assumed by the agent runtime"
}

variable "description" {
  type        = string
  description = "Description of the agent runtime"
  default     = null
}

variable "container_uri" {
  type        = string
  description = "ECR container image URI for container-based runtime artifact"
  default     = null
}

variable "code_configuration" {
  type = object({
    entry_point   = list(string)
    runtime       = string
    s3_bucket     = string
    s3_prefix     = string
    s3_version_id = optional(string)
  })
  description = "Code-based runtime artifact configuration. Use instead of container_uri"
  default     = null
}

variable "network_mode" {
  type        = string
  description = "Network mode for the runtime. Valid values: PUBLIC, VPC"
  default     = "PUBLIC"

  validation {
    condition     = contains(["PUBLIC", "VPC"], var.network_mode)
    error_message = "network_mode must be PUBLIC or VPC."
  }
}

variable "vpc_security_group_ids" {
  type        = list(string)
  description = "Security group IDs for VPC mode"
  default     = []
}

variable "vpc_subnet_ids" {
  type        = list(string)
  description = "Subnet IDs for VPC mode"
  default     = []
}

variable "server_protocol" {
  type        = string
  description = "Server protocol. Valid values: HTTP, MCP, A2A, AGUI"
  default     = null

  validation {
    condition     = var.server_protocol == null || contains(["HTTP", "MCP", "A2A", "AGUI"], var.server_protocol)
    error_message = "server_protocol must be null or one of HTTP, MCP, A2A, AGUI."
  }
}

variable "environment_variables" {
  type        = map(string)
  description = "Environment variables to pass to the runtime"
  default     = {}
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
  type        = string
  description = "Name tag for the runtime"
}

variable "purpose" {
  type        = string
  description = "Purpose of the Bedrock AgentCore Agent Runtime"
  default     = "Containerized runtime for AI agents"
}

variable "specifictags" {
  type        = map(string)
  description = "Specific tags for the resource"
  default     = {}
}

locals {
  common_tags = {
    Application_ID   = var.applicationid
    Application_Name = var.applicationname
    Environment      = var.environment
    Name             = var.name
    Module           = "bedrockagentcore-agent-runtime"
    Purpose          = var.purpose
  }
  merged_tags = merge(local.common_tags, var.specifictags)
}