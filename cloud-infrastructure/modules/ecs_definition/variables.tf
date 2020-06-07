variable "cluster_id" {}

variable "service_name" {}

variable "lb_container_name" {}

variable "lb_container_port" {}

variable "sticky_sessions_duration" {
  default = 86400
}
variable "sticky_sessions" {
  default = false
}

variable "lb_protocol" {
  default = "HTTP"
}

variable "host_port" {
  default = null
}

variable "containers" {}

variable "url" {}

variable "path_pattern" {
  default = "/*"
}

variable "aws_region" {}

variable "environment" {}

variable "vpc_id" {}

variable "desired_count" {
  default = 1
}

variable "command" {
  default = []
}

variable "slow_start" { default = 0 }

variable "grace_period" { default = 0 }

variable "health_check" {
  default = {}
}

variable "deployment_max_percent" {
  default = 200
}
variable "deployment_min_percent" {
  default = 50
}

variable "lb_listener" {}

variable "load_balancer" {}
