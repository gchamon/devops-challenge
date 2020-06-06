module "production_environment" {
  source = "../modules/environment"

  aws_region       = var.aws_region
  domain_name      = var.domain_name
  environment_name = var.environment_name
  project_name     = var.project_name

  ecs_instance_type           = "t2.micro"
  ecs_on_demand_base_capacity = 2
  ecs_autoscaling_capacity = {
    min     = 1
    max     = 2
    desired = 2
  }
}