variable "domain_names" {}

variable "aws_region" {}

variable "zone_ids_by_domain_name" {
  type = map(any)
}
