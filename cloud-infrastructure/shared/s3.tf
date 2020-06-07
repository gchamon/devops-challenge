resource "aws_s3_bucket" "ssl_keys" {
  bucket = "${var.project_name}-ssl-keys"
  acl    = "private"
}
