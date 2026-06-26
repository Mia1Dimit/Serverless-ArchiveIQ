resource "aws_iam_role" "iam_role" {
  name                  = var.name
  assume_role_policy    = var.assume_role_policy
  description           = var.description
  force_detach_policies = var.force_detach_policies
  max_session_duration  = var.max_session_duration
  path                  = var.path
  permissions_boundary  = var.permissions_boundary

  tags = local.merged_tags
}
