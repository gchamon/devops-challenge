# load balancer variables
variable "name" {
  type = string
}

variable "internal" {
  type    = bool
  default = false
}

variable "load_balancer_type" {
  default = "application"
}

variable "security_groups" {
  type = list(string)
}

variable "subnets" {
  type = list(string)
}

variable "idle_timeout" {
  type    = number
  default = 60
}

variable "access_logs" {
  default = null
}

variable "subnet_mapping" {
  type    = list(map(any))
  default = []
}

variable "enable_deletion_protection" {
  type    = bool
  default = true
}

# listeners
variable "https_listener_rules" {
  default = []
}

variable "certificates" {}
