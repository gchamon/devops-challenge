resource "aws_lb" "this" {
  name               = var.name
  internal           = var.internal
  load_balancer_type = var.load_balancer_type
  security_groups    = var.security_groups
  subnets            = var.subnets
  idle_timeout       = var.idle_timeout
  ip_address_type    = "ipv4"

  enable_deletion_protection = var.enable_deletion_protection

  dynamic "access_logs" {
    for_each = range(
      var.access_logs != null
      ? 1
      : 0
    )

    content {
      bucket  = var.access_logs.bucket
      prefix  = var.access_logs.prefix
      enabled = var.access_logs.enabled
    }
  }

  dynamic "subnet_mapping" {
    for_each = var.subnet_mapping
    content {
      subnet_id     = subnet_mapping.value.subnet_id
      allocation_id = subnet_mapping.value.allocation_id
    }
  }
}

resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.this.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = 443
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "https_listener" {
  load_balancer_arn = aws_lb.this.arn
  port              = 443
  protocol          = "HTTPS"
  certificate_arn   = var.certificates.0

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Not found"
      status_code  = 404
    }
  }
}

locals {
  https_listener_rules = {
    for rule_index in range(length(var.https_listener_rules)) :
    join(
      "_",
      concat(
        [var.https_listener_rules[rule_index].action.type],
        flatten([for condition in var.https_listener_rules[rule_index].conditions : flatten([condition.type, condition.values])])
      )
    ) => merge({ priority = 1000 + rule_index }, var.https_listener_rules[rule_index])
  }
}

resource "aws_lb_listener_rule" "https_rules" {
  for_each = local.https_listener_rules

  listener_arn = aws_lb_listener.https_listener.arn
  priority     = each.value.priority

  action {
    type = each.value.action.type

    target_group_arn = lookup(each.value.action, "target_group_arn", null)

    dynamic "redirect" {
      for_each = range(
        each.value.action.type == "redirect"
        ? 1
        : 0
      )

      content {
        host        = lookup(each.value.action, "host", "#{host}")
        path        = lookup(each.value.action, "path", "/#{path}")
        port        = lookup(each.value.action, "port", "#{port}")
        protocol    = lookup(each.value.action, "protocol", "#{protocol}")
        query       = lookup(each.value.action, "query", "#{query}")
        status_code = lookup(each.value.action, "status_code", "HTTP_301")
      }
    }

    dynamic "fixed_response" {
      for_each = range(
        each.value.action.type == "fixed-response"
        ? 1
        : 0
      )

      content {
        content_type = lookup(each.value.action, "content_type")
        message_body = lookup(each.value.action, "message_body")
        status_code  = lookup(each.value.action, "status_code")
      }
    }
  }

  dynamic "condition" {
    for_each = [
      for condition in each.value.conditions :
      condition
      if condition.type == "host-header"
    ]

    content {
      host_header {
        values = condition.value.values
      }
    }
  }

  dynamic "condition" {
    for_each = [
      for condition in each.value.conditions :
      condition
      if condition.type == "path-pattern"
    ]

    content {
      path_pattern {
        values = condition.value.values
      }
    }
  }
}

locals {
  certificates_to_register = slice(var.certificates, 1, length(var.certificates))
}

resource "aws_lb_listener_certificate" "certificates" {
  count = length(local.certificates_to_register)

  certificate_arn = local.certificates_to_register[count.index]
  listener_arn    = aws_lb_listener.https_listener.arn
}
