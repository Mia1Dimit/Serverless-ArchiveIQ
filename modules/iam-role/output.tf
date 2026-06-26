output "iam_role_id" {
  description = "The ID of the role"
  value       = aws_iam_role.iam_role.id
}

output "iam_role_arn" {
  description = "The ARN of the role"
  value       = aws_iam_role.iam_role.arn
}
output "iam_role_create_date" {
  description = "Creation date of the IAM role."
  value       = aws_iam_role.iam_role.create_date
}
output "iam_role_name" {
  description = "The name of the role"
  value       = aws_iam_role.iam_role.name
}
output "iam_role_unique_id" {
  description = "Stable and unique string identifying the role."
  value       = aws_iam_role.iam_role.unique_id
}