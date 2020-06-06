output "arn" {
  value = aws_acm_certificate.certificate.arn
}

output "certificate" {
  value = aws_acm_certificate.certificate
}
