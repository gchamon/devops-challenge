module "acm_certificate_domain" {
  source = "../acm_certificate"

  domain_names = [var.domain_name]
  zone_ids_by_domain_name = {
    (var.domain_name) = data.terraform_remote_state.shared.outputs.route53_zone_root.id
  }
}
