resource "aws_acm_certificate" "this" {
  domain_name               = var.domain_names[0]
  subject_alternative_names = slice(var.domain_names, 1, length(var.domain_names))
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    ManagedBy = "Terraform"
  }
}

locals {
  validation_options_by_domain_name = {
    for validation_option in aws_acm_certificate.this.domain_validation_options :
    validation_option.domain_name => validation_option
  }
}

resource "aws_route53_record" "validation_records" {
  depends_on = [aws_acm_certificate.this]
  for_each   = var.zone_ids_by_domain_name

  name    = local.validation_options_by_domain_name[each.key].resource_record_name
  type    = local.validation_options_by_domain_name[each.key].resource_record_type
  zone_id = each.value
  records = [local.validation_options_by_domain_name[each.key].resource_record_value]
  ttl     = 60
}

resource "aws_acm_certificate_validation" "certificate_validation" {
  certificate_arn         = aws_acm_certificate.this.arn
  validation_record_fqdns = values(aws_route53_record.validation_records).*.fqdn
}
