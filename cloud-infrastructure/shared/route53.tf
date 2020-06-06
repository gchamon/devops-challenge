resource "aws_route53_delegation_set" "root" {}

resource "aws_route53_zone" "root" {
  name = var.zone_name
  delegation_set_id = aws_route53_delegation_set.root.id
}
