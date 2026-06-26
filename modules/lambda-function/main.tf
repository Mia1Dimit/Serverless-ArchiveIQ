
### Gestione automatica dei Security Groups associati alle subnets
data "aws_subnet" "subnets_by_id" {
  for_each = var.vpc_config != null ? toset(var.vpc_config.subnet_ids) : toset([])

  id = each.value
}

data "aws_security_group" "linked_sg" {
  for_each = toset(local.ecs_sg_names_from_tags)
  
  filter {
    name   = "tag:Name"
    values = [each.key]
  }
}

locals {
  ecs_sg_names_from_tags = distinct(compact([
    for s in data.aws_subnet.subnets_by_id : lookup(s.tags, "Linked_sg", null)
  ]))
  final_sg_list = [for sg in data.aws_security_group.linked_sg : sg.id]
}
###

### Creare un file zip del codice sorgente 
data "archive_file" "lambda_zip" {
  count = var.source_dir != null ? 1 : 0
  
  type        = "zip"
  source_dir  = var.source_dir    # Points to backend/src
  output_path = var.output_path   # /tmp/vendors-api.zip
  excludes    = ["__pycache__", "*.pyc", ".git"]
}

resource "aws_lambda_function" "lambda_function" {
  function_name = var.function_name
  role          = var.role_arn
  handler       = var.handler
  runtime       = var.runtime

  filename          = var.source_dir != null ? data.archive_file.lambda_zip[0].output_path : null
  s3_bucket         = var.s3_bucket
  s3_key            = var.s3_key
  s3_object_version = var.s3_object_version
  image_uri         = var.image_uri

  source_code_hash = var.source_dir != null ? data.archive_file.lambda_zip[0].output_base64sha256 : null

  memory_size  = var.memory_size
  package_type = var.package_type
  timeout      = var.timeout
  description  = var.description
  publish      = var.publish

  architectures = var.architectures
  layers        = var.layers

  environment {
    variables = var.environment_variables
  }

  dynamic "file_system_config" {
    for_each = var.file_system_config != null ? [1] : []
    content {
      arn              = var.file_system_config.arn
      local_mount_path = var.file_system_config.local_mount_path
    }
  }

  dynamic "image_config" {
    for_each = var.image_config != null ? [1] : []
    content {
      entry_point       = var.image_config.entry_point
      command           = var.image_config.command
      working_directory = var.image_config.working_directory
    }
  }

  dynamic "logging_config" {
    for_each = var.logging_config != null ? [1] : []
    content {
      application_log_level = var.logging_config.application_log_level
      log_format            = var.logging_config.log_format
      log_group             = var.logging_config.log_group
      system_log_level      = var.logging_config.system_log_level
    }
  }

  dynamic "tracing_config" {
    for_each = var.tracing_config != null ? [1] : []
    content {
      mode = var.tracing_config.mode
    }
  }

  dynamic "vpc_config" {
    for_each = var.vpc_config != null ? [1] : []
    content {
      subnet_ids         = var.vpc_config.subnet_ids
      security_group_ids = distinct(concat(lookup(var.vpc_config, "security_group_ids", []), local.final_sg_list))
    }
  }

  dynamic "ephemeral_storage" {
    for_each = var.ephemeral_storage != null ? [1] : []
    content {
      size = var.ephemeral_storage.size
    }
  }

  tags = local.merged_tags

  lifecycle { ignore_changes = [timeout, image_uri] }

}

