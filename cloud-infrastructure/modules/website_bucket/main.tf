resource "aws_s3_bucket" "this" {
  bucket = var.bucket
  acl    = "private"

  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "PublicAccess",
            "Effect": "Allow",
            "Principal": {
                "AWS": "${var.origin_access_id_iam_arn}"
            },
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::${var.bucket}/*"
        }
    ]
}
POLICY

  website {
    index_document = var.index_document
    error_document = var.error_document
    routing_rules = (
      var.path_pattern == null
      ? null
      : jsonencode(
        [{
          Condition = {
            KeyPrefixEquals = var.path_pattern
          }
          Redirect = {
            ReplaceKeyPrefixWith = ""
          }
        }]
      )
    )
  }

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "HEAD"]
    allowed_origins = ["https://${var.domain_name}"]
  }

  tags = {
    ManagedBy = "Terraform"
  }
}
