module "production_environment" {
  source           = "../modules/environment"
  domain_name      = var.domain_name
  environment_name = var.environment_name
}