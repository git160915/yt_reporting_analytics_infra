output "bucket_arns" {
  value = { for k, b in aws_s3_bucket.this : k => b.arn }
}

output "bucket_names" {
  value = { for k, b in aws_s3_bucket.this : k => b.bucket }
}
