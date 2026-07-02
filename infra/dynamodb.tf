module "dynamodb" {
  source   = "../modules/dynamodb"
  for_each = var.dynamodb_tables

  table_name   = each.value.table_name
  hash_key     = each.value.hash_key
  range_key    = each.value.range_key
  billing_mode = each.value.billing_mode

  global_secondary_indexes      = each.value.global_secondary_indexes
  enable_point_in_time_recovery = each.value.enable_point_in_time_recovery

  applicationid   = var.applicationid
  applicationname = var.applicationname
  environment     = var.environment
  name            = each.key
}
