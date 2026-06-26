output "iam_role_policy_id" {
  description = "The ID of the created iam role policy"
  value       = aws_iam_role_policy.iam_role_policy.id
}
output "role" {
  description = "The IAM role name this policy is attached to."
  value       = var.role
}
output "policy_name" {
  description = "The name of the inline policy."
  value       = aws_iam_role_policy.iam_role_policy.name
}