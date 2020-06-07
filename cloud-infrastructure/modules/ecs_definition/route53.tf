resource "aws_route53_record" "lb_alias" {
  count = range(
    var.zone_id == null
    ? 0
    : 1
  )
  name    = var.url
  type    = "A"
  zone_id = var.zone_id

  alias {
    evaluate_target_health = true
    name                   = var.load_balancer.dns_name
    zone_id                = var.load_balancer.zone_id
  }
}
