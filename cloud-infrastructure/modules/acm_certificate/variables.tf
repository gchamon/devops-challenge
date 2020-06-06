variable "domain_names" {}

variable "aws_region" {}

variable "create_dns_records" {
  default = true
}

variable "zone_ids_by_domain_name" {
  type = map(any)
}
