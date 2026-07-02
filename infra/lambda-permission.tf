module "lambda_permission" {
  source   = "../modules/lambda-permission"
  for_each = var.lambda_permissions

  statement_id  = each.value.statement_id
  action        = each.value.action
  function_name = each.value.function_name
  principal     = each.value.principal
  source_arn    = each.value.source_arn
}
