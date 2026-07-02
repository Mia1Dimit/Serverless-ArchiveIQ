resource "aws_lambda_permission" "permission" {
  statement_id  = var.statement_id
  action        = var.action
  function_name = var.function_name
  principal     = var.principal
  source_arn    = var.source_arn
  function_url_auth_type = var.function_url_auth_type
}