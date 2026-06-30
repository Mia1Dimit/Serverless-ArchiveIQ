output "bucket_notification_id" {
  description = "The id of the created s3 bucket notification id"
  value       = aws_s3_bucket_notification.bucket_notification.id
}