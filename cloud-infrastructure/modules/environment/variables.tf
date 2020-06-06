variable "environment_name" {}

variable "domain_name" {}

variable "aws_region" {}

variable "backend_type" {
  default = "remote"
}

variable "project_name" {}

variable "backend_config" {
  default = {
    hostname     = "app.terraform.io"
    organization = "devops-challenge"

    workspaces = {
      name = "shared"
    }
  }
}
