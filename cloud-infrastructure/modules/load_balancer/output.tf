output "load_balancer" {
  value = aws_lb.this
}

output "http_listener" {
  value = aws_lb_listener.http_listener
}

output "https_listener" {
  value = aws_lb_listener.https_listener
}

output "listener_rules" {
  value = aws_lb_listener_rule.https_rules
}
