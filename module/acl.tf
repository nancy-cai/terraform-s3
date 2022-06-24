resource "aws_s3_bucket_public_access_block" "bucket" {
  bucket = aws_s3_bucket.bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  depends_on = [
    aws_s3_bucket.bucket
  ]
}

resource "aws_s3_bucket_public_access_block" "replication" {
  count    = var.replication-enabled ? 1 : 0
  provider = aws.replication
  bucket   = element(aws_s3_bucket.replication.*.id, 0)

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  depends_on = [
    aws_s3_bucket.replication
  ]
}
