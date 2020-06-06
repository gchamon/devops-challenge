variable "ssh_keys_bucket" {
  type    = string
}

variable "rsa_bits" {
  type    = number
  default = 4096
}

variable "key_name" {
  type = string
}

variable "enable" {
  default = true
}