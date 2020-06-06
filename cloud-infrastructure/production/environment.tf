module "production_environment" {
  source           = "../modules/environment"

  aws_region       = var.aws_region
  domain_name      = var.domain_name
  environment_name = var.environment_name
}