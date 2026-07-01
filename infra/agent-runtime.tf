module "agent-runtime" {
  source   = "../modules/bedrockagentcore-agent-runtime"
  for_each = var.agent_runtime_configurations

  agent_runtime_name = each.value.agent_runtime_name
  role_arn           = each.value.role_arn
  description        = each.value.description

  container_uri          = try(each.value.container_uri, null)
  code_configuration     = try(each.value.code_configuration, null)
  network_mode           = each.value.network_mode
  vpc_security_group_ids = each.value.vpc_security_group_ids
  vpc_subnet_ids         = each.value.vpc_subnet_ids
  server_protocol        = try(each.value.server_protocol, null)
  environment_variables  = each.value.environment_variables
  name                   = try(each.value.name, each.value.agent_runtime_name)

  applicationid   = var.applicationid
  applicationname = var.applicationname
  environment     = var.environment
  specifictags    = {}
}