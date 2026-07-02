# ==============================================================================
# DynamoDB Module Outputs
# ==============================================================================
# Outputs expose table attributes for use by other modules (Lambda, etc.)
# ==============================================================================

output "table_name" {
  description = "Name of the DynamoDB table"
  value       = aws_dynamodb_table.table.name
}

output "table_arn" {
  description = "ARN of the DynamoDB table"
  value       = aws_dynamodb_table.table.arn
}

output "table_id" {
  description = "ID of the DynamoDB table (same as name)"
  value       = aws_dynamodb_table.table.id
}

output "stream_arn" {
  description = "ARN of the DynamoDB Stream (if enabled)"
  value       = aws_dynamodb_table.table.stream_arn
}

output "stream_label" {
  description = "Timestamp of the DynamoDB Stream (if enabled)"
  value       = aws_dynamodb_table.table.stream_label
}

output "hash_key" {
  description = "Partition key (hash key) attribute name"
  value       = aws_dynamodb_table.table.hash_key
}

output "range_key" {
  description = "Sort key (range key) attribute name"
  value       = aws_dynamodb_table.table.range_key
}
