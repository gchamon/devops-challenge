variable "source_policies_json" {
  type        = list(string)
  description = "List of JSON IAM policy documents.<br/><br/><b>Limits:</b><br/>* List size max 30<br/> * Statement can be overriden by the statement with the same sid from the latest policy."
  default     = []

  //  validation {
  //    condition     = length(var.source_policies_json) > 30
  //    error_message = "Module currently supports up to 30 documents."
  //  }
}

variable "name" {}

variable "description" {
  default = null
}

variable "path" {
  default = "/"
}

variable "create_policy_resource" {
  default = true
}
