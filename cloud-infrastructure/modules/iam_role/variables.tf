variable "name" {}

variable "assume_role_policy_service" {
  default = "ec2.amazonaws.com"
}

variable "policies_arn" {
  type    = list(string)
  default = []
}

variable "policies_json" {
  default = []
}
