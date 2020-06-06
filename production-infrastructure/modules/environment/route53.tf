resource "aws_route53_record" "domain" {
  name = var.domain_name
  type = "A"
}