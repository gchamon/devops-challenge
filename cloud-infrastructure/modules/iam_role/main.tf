resource "aws_iam_role" "this" {
  name = var.name

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "${var.assume_role_policy_service}"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_instance_profile" "this" {
  name = var.name
  role = aws_iam_role.this.name
}

resource "aws_iam_role_policy_attachment" "attachments" {
  count = length(var.policies_arn)

  policy_arn = var.policies_arn[count.index]
  role       = aws_iam_role.this.name
}

module "iam_aggregated_policy" {
  source = "../iam_aggregated_policy"

  name                 = "${replace(title(replace(var.name, "-", " ")), " ", "")}RoleAggregatedPolicy"
  source_policies_json = var.policies_json
  description          = "Permissions policy for role ${var.name}"
  path                 = "/roles/"
}

resource "aws_iam_role_policy_attachment" "aggregated_policy" {
  count = length(var.policies_json)

  role       = aws_iam_role.this.name
  policy_arn = module.iam_aggregated_policy.policy.arn
}
