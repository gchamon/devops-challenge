output "role" {
  value = aws_iam_role.this
}

output "policies" {
  value = var.policies_arn
}

output "policy_attachments" {
  value = aws_iam_role_policy_attachment.attachments
}

output "instance_profile" {
  value = aws_iam_instance_profile.this
}
