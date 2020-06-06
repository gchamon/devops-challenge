resource "aws_route53_record" "lb_alias" {
  name    = var.url
  type    = "A"
  zone_id = var.main_zone.id

  alias {
    evaluate_target_health = true
    name                   = var.load_balancer.dns_name
    zone_id                = var.load_balancer.zone_id
  }
}
