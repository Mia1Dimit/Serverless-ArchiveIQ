resource "aws_lambda_permission" "allow_s3" {
  for_each = var.lambda_functions

  statement_id  = "AllowExecutionFromS3"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda_function[each.key].lambda_function_name
  principal     = "s3.amazonaws.com"
  source_arn    = "arn:aws:s3:::archiveiq-documents-dev"

  depends_on = [module.lambda_function]
}
