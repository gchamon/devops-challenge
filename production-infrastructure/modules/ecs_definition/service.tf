locals {
  volumes = flatten([for c in var.containers : lookup(c, "volumes", [])])
  container-defaults = {
    cpu                   = 0
    soft-memory-limit     = 128
    hard-memory-limit     = 128
    port-mapping-protocol = "tcp"
  }
}

resource "aws_cloudwatch_log_group" "this" {
  name              = "${var.environment}-${var.service_name}"
  retention_in_days = 1
}

resource "aws_ecs_task_definition" "this" {
  family                   = "${var.service_name}-definition"
  requires_compatibilities = ["EC2"]
  network_mode             = "bridge"

  dynamic "volume" {
    for_each = local.volumes
    content {
      name = volume.value.volume_name
      host_path = volume.value.host_path
    }
  }

  container_definitions = jsonencode(
    yamldecode(
      templatefile(
        "${path.module}/container-definitions.yaml.tmpl",
        {
          aws-region         = var.aws_region
          log-group          = aws_cloudwatch_log_group.this.name
          containers         = var.containers
          container-defaults = local.container-defaults
        }
      )
    )
  )

  tags = {
    environment = var.environment
  }
}

resource "aws_ecs_service" "this" {
  depends_on = [aws_lb_listener_rule.this]

  name                               = var.service_name
  cluster                            = var.cluster_id
  task_definition                    = aws_ecs_task_definition.this.arn
  desired_count                      = var.desired_count
  health_check_grace_period_seconds  = var.grace_period
  deployment_maximum_percent         = var.deployment_max_percent
  deployment_minimum_healthy_percent = var.deployment_min_percent

  ordered_placement_strategy {
    field = "instanceId"
    type  = "spread"
  }

  ordered_placement_strategy {
    field = "attribute:ecs.availability-zone"
    type  = "spread"
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.this.arn
    container_name   = var.lb_container_name
    container_port   = var.lb_container_port
  }
}
