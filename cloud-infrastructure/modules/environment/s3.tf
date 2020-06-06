module "s3_bucket_static" {
  source                   = "../website_bucket"
  bucket                   = "${var.domain_name}-website"
  domain_name              = var.domain_name
  origin_access_id_iam_arn = aws_cloudfront_origin_access_identity.main.iam_arn
}