module "production_environment" {
  source = "../modules/environment"
  domain_name = var.domain_name
}