output "zone_name" {
  value = var.url
}

output "path_pattern" {
  value = var.path_pattern
}

output "target_group" {
  value = aws_lb_target_group.this
}

output "log_group" {
  value = aws_cloudwatch_log_group.this
}

output "task_definition" {
  value = aws_ecs_task_definition.this
}

output "name" {
  value = var.service_name
}

output "lb_container_name" {
  value = var.lb_container_name
}

output "lb_container_port" {
  value = var.lb_container_port
}

output "cluster_id" {
  value = var.cluster_id
}

output "desired_count" {
  value = var.desired_count
}

output "grace_period" {
  value = var.grace_period
}

output "deployment_max_percent" {
  value = var.deployment_max_percent
}

output "deployment_min_percent" {
  value = var.deployment_min_percent
}
