data "terraform_remote_state" "shared" {
  backend = var.backend_type
  config = var.backend_config
}
