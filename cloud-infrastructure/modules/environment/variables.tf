variable "environment_name" {}

variable "domain_name" {}

variable "backend_type" {
  default = "remote"
}

variable "backend_config" {
  default = {
    hostname     = "app.terraform.io"
    organization = "devops-challenge"

    workspaces = {
      name = "shared"
    }
  }
}
