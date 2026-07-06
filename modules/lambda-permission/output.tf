output "permission_id" {
  description = "The ID of the Lambda permission"
  value       = aws_lambda_permission.permission.id
}

output "statement_id" {
  description = "The statement ID of the Lambda permission"
  value       = aws_lambda_permission.permission.statement_id
}