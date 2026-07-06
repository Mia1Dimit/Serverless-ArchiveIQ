# ==============================================================================
# DynamoDB Table - Single-Table Design for SportsTech Platform
# ==============================================================================
# Purpose: NoSQL database for teams, vendors, products, partnerships
# Pattern: Single-table design with composite keys (PK + SK)
# ==============================================================================

resource "aws_dynamodb_table" "table" {
  name         = var.table_name
  billing_mode = var.billing_mode
  hash_key     = var.hash_key
  range_key    = var.range_key

  # Read/Write capacity (only used if billing_mode = PROVISIONED)
  read_capacity  = var.billing_mode == "PROVISIONED" ? var.read_capacity : null
  write_capacity = var.billing_mode == "PROVISIONED" ? var.write_capacity : null

  # Primary key attributes
  attribute {
    name = var.hash_key
    type = "S" # String
  }

  dynamic "attribute" {
    for_each = var.range_key != null ? [var.range_key] : []
    content {
      name = attribute.value
      type = "S"
    }
  }

  # GSI key attributes (dynamically add attributes for all GSI keys)
  dynamic "attribute" {
    for_each = toset([
      for gsi in var.global_secondary_indexes : gsi.hash_key
    ])
    content {
      name = attribute.value
      type = "S"
    }
  }

  dynamic "attribute" {
    for_each = toset(compact([
      for gsi in var.global_secondary_indexes : lookup(gsi, "range_key", null)
    ]))
    content {
      name = attribute.value
      type = "S"
    }
  }

  # Global Secondary Indexes (GSIs)
  dynamic "global_secondary_index" {
    for_each = var.global_secondary_indexes
    content {
      name               = global_secondary_index.value["name"]
      hash_key           = global_secondary_index.value["hash_key"]
      range_key          = lookup(global_secondary_index.value, "range_key", null)
      projection_type    = lookup(global_secondary_index.value, "projection_type", "ALL")
      non_key_attributes = lookup(global_secondary_index.value, "non_key_attributes", null)

      # Capacity for GSI (only if PROVISIONED)
      read_capacity  = var.billing_mode == "PROVISIONED" ? lookup(global_secondary_index.value, "read_capacity", 5) : null
      write_capacity = var.billing_mode == "PROVISIONED" ? lookup(global_secondary_index.value, "write_capacity", 5) : null
    }
  }

  # Point-in-time recovery (backup)
  point_in_time_recovery {
    enabled = var.enable_point_in_time_recovery
  }

  # Encryption at rest
  server_side_encryption {
    enabled     = var.enable_encryption
    kms_key_arn = var.kms_key_arn
  }

  # Time-to-live (TTL) attribute (optional)
  dynamic "ttl" {
    for_each = var.ttl_attribute_name != null ? [1] : []
    content {
      enabled        = true
      attribute_name = var.ttl_attribute_name
    }
  }

  # Streams (for DynamoDB Streams - future Lambda triggers)
  stream_enabled   = var.stream_enabled
  stream_view_type = var.stream_enabled ? var.stream_view_type : null

  # Tags
  tags = merge(
    {
      Name             = var.name
      Environment      = var.environment
      Application_ID   = var.applicationid
      Application_Name = var.applicationname
      Module           = "dynamodb"
      Purpose          = var.purpose
    },
    var.specifictags
  )
}
