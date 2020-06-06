locals {
  null_key_pair = {
    key_name    = null
    fingerprint = null
  }
  key_pair = concat(aws_key_pair.this, [local.null_key_pair])[0]
}

resource "tls_private_key" "this" {
  count     = var.enable == true ? 1 : 0
  algorithm = "RSA"
  rsa_bits  = var.rsa_bits
}

resource "aws_key_pair" "this" {
  count      = var.enable == true ? 1 : 0
  public_key = tls_private_key.this.0.public_key_openssh
  key_name   = var.key_name
}

resource "aws_s3_bucket_object" "private_key" {
  count   = var.enable == true ? 1 : 0
  bucket  = var.ssh_keys_bucket
  key     = "${var.key_name}.pem"
  content = tls_private_key.this.0.private_key_pem
}