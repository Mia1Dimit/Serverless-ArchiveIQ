locals {
  policies = {
    for item in flatten([
      for ps_key, ps in var.iam_roles : [
        for p_key, pol in ps.policies : {
          key = p_key
          value = {
            role_id = module.aws-iam-role[ps_key].iam_role_id
            name    = pol.name
            policy  = pol.policy
          }
        }
      ]
    ]) : item.key => item.value
  }

  managed_policies = {
    for item in flatten([
      for ps_key, ps in var.iam_roles : [
        for p_key, pol in coalesce(ps.managed_policies, {}) : {
          key = p_key
          value = {
            role       = module.aws-iam-role[ps_key].iam_role_name
            policy_arn = pol.policy_arn
          }
        }
      ]
    ]) : item.key => item.value
  }
}

module "aws-iam-role" {
  for_each = var.iam_roles
  source   = "../modules/iam-role"

  name               = each.value["name"]
  assume_role_policy = file("${path.module}/data/iam_role_policies/${each.value["assume_role_policy"]}")

  specifictags    = {}
  applicationid   = var.applicationid
  environment     = var.environment
  applicationname = var.applicationname
}

module "aws-iam-role-policy" {
  for_each = local.policies
  source   = "../modules/iam-policy"

  name   = each.value["name"]
  role   = each.value["role_id"]
  policy = file("${path.module}/data/iam_role_policies/${each.value["policy"]}")
}

module "aws-iam-role-policy-att" {
  for_each = local.managed_policies
  source   = "../modules/iam-role-policy"

  role       = each.value.role
  policy_arn = each.value.policy_arn
}