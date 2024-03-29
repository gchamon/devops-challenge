module "load_balancer" {
  source = "../load_balancer"

  name            = var.environment_name
  certificates    = [module.acm_certificate_domain_current_region.arn]
  subnets         = data.terraform_remote_state.shared.outputs.network.subnets[var.environment_name].*.id
  security_groups = [aws_security_group.load_balancer.id]
}
