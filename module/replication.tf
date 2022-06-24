data "aws_iam_policy_document" "assume_role_policy" {
  count = var.replication-enabled ? 1 : 0
  statement {
    effect  = "Allow"
    sid     = ""
    actions = ["sts:AssumeRole"]

    principals {
      type = "Service"

      identifiers = [
        "s3.amazonaws.com",
      ]
    }
  }
}

data "aws_iam_policy_document" "replication" {
  count = var.replication-enabled ? 1 : 0
  statement {
    sid    = "allowReplicationMedia"
    effect = "Allow"
    actions = [
      "s3:GetReplicationConfiguration",
      "s3:ListBucket"
    ]

    resources = [
      aws_s3_bucket.bucket.arn
    ]
  }

  statement {
    sid    = "allowObjectGet"
    effect = "Allow"
    actions = [
      "s3:GetObjectVersionForReplication",
      "s3:GetObjectVersionAcl",
      "s3:GetObjectVersionTagging",
      "s3:GetObjectVersionAcl"
    ]

    resources = [
      "${aws_s3_bucket.bucket.arn}/*"
    ]
  }

  statement {
    sid    = "allowReplicationMediaReplication"
    effect = "Allow"
    actions = [
      "s3:ReplicateObject",
      "s3:ReplicateDelete",
      "s3:ReplicateTags",
      "s3:GetObjectVersionTagging"
    ]

    resources = [
      "${element(aws_s3_bucket.replication.*.arn, 0)}/*"
    ]
  }

  dynamic "statement" {
    for_each = var.replication-kms-encrypted-enabled ? [1] : []
    content {
      sid    = "allowKMSKeyDecryption"
      effect = "Allow"
      actions = [
        "kms:Decrypt"
      ]

      resources = [
        var.replication-source-kms-key-arn
      ]

      condition {
        test     = "StringLike"
        variable = "kms:ViaService"

        values = [
          "s3.${var.replication-source-region}.amazonaws.com"
        ]
      }
      condition {
        test     = "StringLike"
        variable = "kms:EncryptionContext:aws:s3:arn"

        values = [
          "${element(aws_s3_bucket.bucket.*.arn, 0)}/*"
        ]
      }
    }
  }

  dynamic "statement" {
    for_each = var.replication-kms-encrypted-enabled ? [1] : []
    content {
      sid    = "allowKMSKeyEncryption"
      effect = "Allow"
      actions = [
        "kms:Encrypt"
      ]

      resources = [
        var.replication-destination-kms-key-arn
      ]

      condition {
        test     = "StringLike"
        variable = "kms:ViaService"

        values = [
          "s3.${var.replication-destination-region}.amazonaws.com"
        ]
      }
      condition {
        test     = "StringLike"
        variable = "kms:EncryptionContext:aws:s3:arn"

        values = [
          "${element(aws_s3_bucket.replication.*.arn, 0)}/*"
        ]
      }
    }
  }
}

resource "aws_iam_role" "replication" {
  count              = var.replication-enabled ? 1 : 0
  name               = "${var.bucket-prefix}-${var.environment-name}-s3-bucket-replication-role"
  assume_role_policy = element(data.aws_iam_policy_document.assume_role_policy.*.json, 0)
}

resource "aws_iam_role_policy" "replication" {
  count  = var.replication-enabled ? 1 : 0
  name   = "${var.bucket-prefix}-${var.environment-name}-s3-bucket-replication-policy"
  role   = element(aws_iam_role.replication.*.id, 0)
  policy = element(data.aws_iam_policy_document.replication.*.json, 0)
}
