module "lambda_function" {
  source   = "../modules/lambda-function"
  for_each = var.lambda_functions

  function_name         = each.value.name
  role_arn              = module.aws-iam-role["lambda_execution"].iam_role_arn
  handler               = each.value.handler
  runtime               = each.value.runtime
  timeout               = each.value.timeout
  memory_size           = each.value.memory_size
  environment_variables = each.value.environment_variables
  vpc_config            = each.value.vpc_config
  source_dir            = each.value.source_dir
  output_path           = each.value.output_path

  applicationid   = var.applicationid
  applicationname = var.applicationname
  environment     = var.environment
  specifictags    = {}

  depends_on = [module.aws-iam-role]
}
