module "acm_certificate" {
  source = "../acm_certificate"
  domain_names = [var.domain_name]
  zone_ids_by_domain_name = {
    (var.domain_name) =
  }
}