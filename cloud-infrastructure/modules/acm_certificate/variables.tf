variable "domain_names" {}

variable "zone_ids_by_domain_name" {
  type = map(any)
}
