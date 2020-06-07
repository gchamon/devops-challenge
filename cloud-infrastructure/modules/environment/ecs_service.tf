module "ecs_service_backend" {
  source = "../ecs_definition"

  service_name      = "nginx"
  cluster_id        = aws_ecs_cluster.default.id
  aws_region        = var.aws_region
  environment       = var.environment_name
  vpc_id            = data.terraform_remote_state.shared.outputs.network.vpc.id
  desired_count     = 2
  url               = var.domain_name
  lb_container_name = "backend"
  lb_container_port = 80
  lb_listener       = module.load_balancer.https_listener
  load_balancer     = module.load_balancer.load_balancer
  containers = [
    {
      name              = "backend"
      image             = "nginx"
      hard-memory-limit = 128
      soft-memory-limit = 64
      port-mappings = [
        {
          container-port = 80
        }
      ]
    }
  ]
}