module "iam_role_ecs_agent" {
  source = "../iam_role"

  name = replace(title("${var.environment_name} ECSAgent"), " ", "")

  policies_arn = [
    "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
  ]
}

module "iam_role_ecs_backend_task" {
  source = "../iam_role"

  name          = replace(title("${var.environment_name} ECS backend task"), " ", "")
  create_policy = true

  policy_json = <<JSON
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:GetObject",
        "s3:HeadBucket",
        "s3:PutObject"
      ],
      "Effect": "Allow",
      "Resource": "${aws_s3_bucket.state_storage.arn}/*"
    }
  ]
}
JSON
}
