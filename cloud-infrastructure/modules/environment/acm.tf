module "acm_certificate_domain_us_east_1" {
  source = "../acm_certificate"

  aws_region         = "us-east-1"
  domain_names       = [var.domain_name]
  create_dns_records = true
  zone_ids_by_domain_name = {
    (var.domain_name) = data.terraform_remote_state.shared.outputs.route53_zone_root.id
  }
}

module "acm_certificate_domain_current_region" {
  source = "../acm_certificate"

  aws_region         = var.aws_region
  domain_names       = [var.domain_name]
  create_dns_records = false
  zone_ids_by_domain_name = {
    (var.domain_name) = data.terraform_remote_state.shared.outputs.route53_zone_root.id
  }
}
