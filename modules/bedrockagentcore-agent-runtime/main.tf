resource "aws_bedrockagentcore_agent_runtime" "runtime" {
  agent_runtime_name = var.agent_runtime_name
  role_arn           = var.role_arn
  description        = var.description

  agent_runtime_artifact {
    dynamic "container_configuration" {
      for_each = var.container_uri != null ? [var.container_uri] : []
      content {
        container_uri = container_configuration.value
      }
    }

    dynamic "code_configuration" {
      for_each = var.code_configuration != null ? [var.code_configuration] : []
      content {
        entry_point = code_configuration.value.entry_point
        runtime     = code_configuration.value.runtime

        code {
          s3 {
            bucket     = code_configuration.value.s3_bucket
            prefix     = code_configuration.value.s3_prefix
            version_id = code_configuration.value.s3_version_id
          }
        }
      }
    }
  }

  network_configuration {
    network_mode = var.network_mode

    dynamic "network_mode_config" {
      for_each = var.network_mode == "VPC" ? [1] : []
      content {
        security_groups = var.vpc_security_group_ids
        subnets         = var.vpc_subnet_ids
      }
    }
  }

  dynamic "protocol_configuration" {
    for_each = var.server_protocol != null ? [var.server_protocol] : []
    content {
      server_protocol = protocol_configuration.value
    }
  }

  environment_variables = var.environment_variables
  tags                  = local.merged_tags
}