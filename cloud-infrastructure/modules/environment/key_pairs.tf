module "key_pair_ecs_cluster" {
  source = "../key_pair"

  key_name = "${var.environment_name}-ecs"
  ssh_keys_bucket = data.terraform_remote_state.shared.outputs.s3_bucket_ssl_keys.bucket
}