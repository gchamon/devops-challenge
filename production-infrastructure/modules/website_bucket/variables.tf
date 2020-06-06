variable "bucket" {}

variable "origin_access_id_iam_arn" {}

variable "domain_name" {}

variable "index_document" {
  default = "index.html"
}

variable "error_document" {
  default = "error.html"
}

variable "path_pattern" {
  default = null
}