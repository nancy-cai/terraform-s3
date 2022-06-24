
output "bucket-name" {
  value = aws_s3_bucket.bucket.id
}

output "bucket-arn" {
  value = aws_s3_bucket.bucket.arn
}

output "replication-bucket-arn" {
  value = var.replication-enabled ? element(aws_s3_bucket.replication.*.arn,0) : null
}
