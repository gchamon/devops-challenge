variable "environment_name" {}

variable "domain_name" {}

variable "aws_region" {}

variable "backend_type" {
  default = "remote"
}

variable "ecs_instance_type" {}

variable "project_name" {}

variable "ecs_autoscaling_capacity" {}

variable "ecs_on_demand_base_capacity" {}

variable "backend_config" {
  default = {
    hostname     = "app.terraform.io"
    organization = "devops-challenge"

    workspaces = {
      name = "shared"
    }
  }
}
