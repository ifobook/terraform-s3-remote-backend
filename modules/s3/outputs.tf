output "bucket_name" {
  description = "Remote state bucket name"
  value       = aws_s3_bucket.state.id
}

output "bucket_arn" {
  description = "Remote state bucket ARN"
  value       = aws_s3_bucket.state.arn
}
