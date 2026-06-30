module "agent-runtime" {
  source = "../modules/bedrockagentcore-agent-runtime"
  for_each = var.agent_runtime_configurations
  agent_runtime_name = each.value.agent_runtime_name
  role_arn           = each.value.role_arn
  description        = each.value.description

  container_uri = each.value.container_uri
  entry_point = each.value.entry_point
  runtime = each.value.runtime
  s3_bucket = each.value.s3_bucket
  s3_prefix = each.value.s3_prefix
  s3_version_id = each.value.s3_version_id
  network_mode = each.value.network_mode
  vpc_security_group_ids = each.value.vpc_security_group_ids
  vpc_subnet_ids = each.value.vpc_subnet_ids
  server_protocol = each.value.server_protocol
  environment_variables = each.value.environment_variables
  
  applicationid   = var.applicationid
  applicationname = var.applicationname
  environment     = var.environment
  specifictags    = {}

}