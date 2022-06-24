locals {
  bucket-arn  = "arn:aws:s3:::${var.bucket-prefix}.${var.base-domain}"
  replica-arn = "arn:aws:s3:::replica.${var.bucket-prefix}.${var.base-domain}"
}

data "aws_iam_policy_document" "s3-bucket-policy" {
  dynamic "statement" {
    for_each = length(var.aws-principles-object-readwrite) > 0 ? [1]: []
    content {
      sid    = "AllowObjectReadWrite"
      effect = "Allow"

      principals {
        type        = "AWS"
        identifiers = var.aws-principles-object-readwrite
      }

      actions = [
        "s3:*Object*"
      ]

      resources = [
        "${local.bucket-arn}/*"
      ]
    }
  }

  dynamic "statement" {
    for_each = length(var.aws-principles-object-readwrite) > 0 ? [1]: []
    content {
      sid    = "AllowListBucket"
      effect = "Allow"

      principals {
        type        = "AWS"
        identifiers = var.aws-principles-object-readwrite
      }

      actions = [
        "s3:ListBucket"
      ]

      resources = [
        local.bucket-arn
      ]
    }
  }

  dynamic "statement" {
      for_each = (length(setunion(var.aws-principles-bucket-object,var.canonical-principles-bucket-object)) > 0 ? [1]: [])
      content {
        sid = "AllowObjectReadWriteAndBucketRead"

        effect = "Allow"

        actions = [
          "s3:*Object*",
          "s3:GetBucketPolicy",
          "s3:ListBucket",
          "s3:GetBucketAcl",
          "s3:GetBucketLocation",
          "s3:GetBucketVersioning",
          "s3:ListMultipartUploadParts",
          "s3:ListBucketMultipartUploads"
        ]

        resources = [
          "${local.bucket-arn}/*",
          local.bucket-arn
        ]

        dynamic "principals" {
          for_each = (length(var.aws-principles-bucket-object) > 0 ? [1] : [])
          content {
            type = "AWS"
            identifiers = var.aws-principles-bucket-object
          }
        }

        dynamic "principals" {
          for_each = (length(var.canonical-principles-bucket-object) > 0 ? [1] : [])
          content {
            type = "CanonicalUser"
            identifiers = var.canonical-principles-bucket-object
          }
        }
      }
    }

}

data "aws_iam_policy_document" "s3-bucket-policy-replication" {
  count    = var.replication-enabled ? 1 : 0
  provider = aws.replication

  statement {
    sid    = "AllowObjectReadWrite"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = var.aws-principles-object-readwrite
    }

    actions = [
      "s3:*Object*"
    ]

    resources = [
      "${local.replica-arn}/*"
    ]
  }
  statement {
    sid    = "AllowListBucket"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = var.aws-principles-object-readwrite
    }

    actions = [
      "s3:ListBucket"
    ]

    resources = [
      local.replica-arn
    ]
  }
}
