resource "aws_s3_bucket" "ssl_keys" {
  bucket = "${var.project_name}-ssl-keys"
  acl    = "private"
}

resource "aws_s3_bucket" "development_storage" {
  bucket = "${var.project_name}-development-storage"
  acl    = "private"
}
