resource "aws_route53_record" "domain" {
  name    = var.domain_name
  zone_id = data.terraform_remote_state.shared.outputs.route53_zone_root.zone_id
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.main.domain_name
    zone_id                = aws_cloudfront_distribution.main.hosted_zone_id
    evaluate_target_health = false
  }
}