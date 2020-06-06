output "network" {
  value = module.network
}

output "s3_bucket_ssl_keys" {
  value = aws_s3_bucket.ssl_keys
}

output "route53_zone_root" {
  value = aws_route53_zone.root
}