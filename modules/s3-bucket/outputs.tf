output "s3-id" {
  value = aws_s3_bucket.bucket_s3.id
}

output "s3-arn" {
  value = aws_s3_bucket.bucket_s3.arn
}

output "bucket_regional_domain_name" {
  description = "The bucket region-specific domain name"
  value       = aws_s3_bucket.bucket_s3.bucket_regional_domain_name
}