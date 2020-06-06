module "network" {
  source = "../modules/network"

  cidr_prefix = "10.0"
  aws_region  = var.aws_region
  vpc_name    = "devops-challenge"
}
