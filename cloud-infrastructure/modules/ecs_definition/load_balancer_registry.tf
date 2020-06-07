locals {
  default_health_check = {
    path                = "/"
    port                = "traffic-port"
    healthy_threshold   = 3
    unhealthy_threshold = 5
    timeout             = 120
    timeout             = 5
    interval            = 160
    interval            = 60
    matcher             = 200
  }
  health_check = merge(local.default_health_check, var.health_check)
}

resource "aws_lb_target_group" "this" {
  name       = "${var.environment}-${var.service_name}"
  port       = var.lb_container_port
  protocol   = var.lb_protocol
  vpc_id     = var.vpc_id
  slow_start = var.slow_start

  stickiness {
    type            = "lb_cookie"
    cookie_duration = var.sticky_sessions_duration
    enabled         = var.sticky_sessions
  }

  health_check {
    enabled             = true
    path                = local.health_check.path
    port                = local.health_check.port
    healthy_threshold   = local.health_check.healthy_threshold
    unhealthy_threshold = local.health_check.unhealthy_threshold
    timeout             = local.health_check.timeout
    interval            = local.health_check.interval
    matcher             = local.health_check.matcher
  }
}

resource "aws_lb_listener_rule" "this" {
  listener_arn = var.lb_listener.arn

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }

  condition {
    host_header {
      values = [var.url]
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}
