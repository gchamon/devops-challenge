output "network" {
  value = module.network
}

output "s3_bucket_ssl_keys" {
  value = aws_s3_bucket.ssl_keys
}

output "route53_zone_root" {
  value = aws_route53_zone.root
}

output "route53_delegation_set" {
  value = aws_route53_delegation_set.root
}

resource "null_resource" "refresh_output" {}
