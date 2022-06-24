locals {
  common-tags = merge({ "Environment" : var.environment-name }, var.common-tags)
  enable-versioning = var.replication-enabled ? true : var.enable-versioning
}
provider "aws" {
  alias = "replication"
}

resource "aws_s3_bucket" "log" {
  bucket = "logs.${var.bucket-prefix}.${var.base-domain}"
  acl    = "log-delivery-write"

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = var.replication-enabled ? "AES256" : "aws:kms"
      }
    }
  }

  lifecycle_rule {
    id      = "expire"
    enabled = true

    expiration {
      days = var.logs-expiration
    }
  }
  force_destroy = var.force-destroy-s3-buckets

  tags = local.common-tags
}

resource "aws_s3_bucket" "bucket" {
  bucket = "${var.bucket-prefix}.${var.base-domain}"
  policy = length(var.aws-principles-object-readwrite) > 0 || length(var.aws-principles-bucket-object) > 0 ? data.aws_iam_policy_document.s3-bucket-policy.json : null

  logging {
    target_bucket = aws_s3_bucket.log.id
  }

  versioning {
    enabled = local.enable-versioning
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = var.replication-enabled ? "AES256" : "aws:kms"
      }
    }
  }

  dynamic "replication_configuration" {
    for_each = var.replication-enabled ? [1] : []
    content {
      role = element(aws_iam_role.replication.*.arn, 0)

      rules {
        priority = 0
        filter {}
        id                               = "replicate-${var.bucket-prefix}"
        status                           = "Enabled"
        delete_marker_replication_status = var.enable-delete-markers-replication ? "Enabled" : null

        dynamic "source_selection_criteria" {
          for_each = var.replication-kms-encrypted-enabled ? [1] : []
          content {
            sse_kms_encrypted_objects {
              enabled = true
            }
          }
        }

        destination {
          bucket        = element(aws_s3_bucket.replication.*.arn, 0)
          storage_class = "STANDARD"
          replica_kms_key_id = var.replication-kms-encrypted-enabled ? var.replication-destination-kms-key-arn : null
        }
      }
    }
  }

  dynamic "lifecycle_rule" {
    for_each = local.enable-versioning && var.lifecycle-enabled ? [1] : []
    content {
      id = "expire-objects"
      enabled  = true
      expiration {
        days = var.objects-expiration
      }
      noncurrent_version_expiration {
        days = var.objects-expiration
      } 
    }
  }

  depends_on = [
    aws_s3_bucket.log
  ]

  force_destroy = var.force-destroy-s3-buckets
  tags          = local.common-tags
}

resource "aws_s3_bucket" "replication-log" {
  count    = var.replication-enabled ? 1 : 0
  provider = aws.replication
  bucket   = "replica.logs.${var.bucket-prefix}.${var.base-domain}"
  acl      = "log-delivery-write"

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  lifecycle_rule {
    id      = "expire"
    enabled = true

    expiration {
      days = var.logs-expiration
    }
  }
  force_destroy = var.force-destroy-s3-buckets
  tags          = local.common-tags
}

resource "aws_s3_bucket" "replication" {
  count    = var.replication-enabled ? 1 : 0
  provider = aws.replication
  bucket   = "replica.${var.bucket-prefix}.${var.base-domain}"
  policy   = length(var.aws-principles-object-readwrite) > 0 ? element(data.aws_iam_policy_document.s3-bucket-policy-replication.*.json, 0) : null


  versioning {
    enabled = var.replication-enabled ? true : var.enable-versioning
  }

  logging {
    target_bucket = element(aws_s3_bucket.replication-log.*.id, 0)
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  dynamic "lifecycle_rule" {
    for_each = local.enable-versioning && var.lifecycle-enabled ? [1] : []
    content {
      id = "expire-objects"
      enabled  = true
      expiration {
        days = var.objects-expiration
      }
      noncurrent_version_expiration {
        days = var.objects-expiration
      } 
    }
  }

  depends_on = [
    aws_s3_bucket.replication-log
  ]

  force_destroy = var.force-destroy-s3-buckets
  tags          = local.common-tags
}
