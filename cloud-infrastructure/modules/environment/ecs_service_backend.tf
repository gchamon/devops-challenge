resource "aws_ecr_repository" "backend" {
  name = "backend"
}

module "ecs_service_backend" {
  source = "../ecs_definition"

  service_name      = "backend"
  cluster_id        = aws_ecs_cluster.default.id
  aws_region        = var.aws_region
  environment       = var.environment_name
  vpc_id            = data.terraform_remote_state.shared.outputs.network.vpc.id
  desired_count     = 2
  url               = var.domain_name
  lb_container_name = "backend"
  lb_container_port = 5000
  lb_listener       = module.load_balancer.https_listener
  load_balancer     = module.load_balancer.load_balancer
  containers = [
    {
      name              = "backend"
      image             = aws_ecr_repository.backend.repository_url
      hard-memory-limit = 128
      soft-memory-limit = 64
      port-mappings = [
        {
          container-port = 5000
        }
      ]
      environment-variables = {
        STORAGE_BUCKET = aws_s3_bucket.state_storage.bucket
      }
    }
  ]
}
