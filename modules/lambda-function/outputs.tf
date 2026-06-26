output "lambda_function_id" {
  description = "The ID of the created lambda function"
  value       = aws_lambda_function.lambda_function.id
}

output "lambda_function_name" {
  description = "The name of the created lambda function"
  value       = aws_lambda_function.lambda_function.function_name
}

output "lambda_function_arn" {
  description = "The ARN of the created lambda function"
  value       = aws_lambda_function.lambda_function.arn
}

output "lambda_function_invoke_arn" {
  description = "ARN to use for API Gateway integration"
  value       = aws_lambda_function.lambda_function.invoke_arn
}

output "lambda_function_qualified_arn" {
  description = "ARN with version"
  value       = aws_lambda_function.lambda_function.qualified_arn
}