output "app_bucket_name" {
  value = aws_s3_bucket.app_bucket.id
}

output "app_bucket_arn" {
  value = aws_s3_bucket.app_bucket.arn
}

output "log_bucket_name" {
  value = aws_s3_bucket.log_bucket.id
}

output "log_bucket_arn" {
  value = aws_s3_bucket.log_bucket.arn
}