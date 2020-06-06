locals {
  ## Workaround for this issue https://github.com/hashicorp/terraform/issues/11210
  source_documents = concat(["null"], var.source_policies_json)

  policies = [
    length(local.source_documents) > 1 ? element(local.source_documents, 1) : data.aws_iam_policy_document.empty.json,
    length(local.source_documents) > 2 ? element(local.source_documents, 2) : data.aws_iam_policy_document.empty.json,
    length(local.source_documents) > 3 ? element(local.source_documents, 3) : data.aws_iam_policy_document.empty.json,
    length(local.source_documents) > 4 ? element(local.source_documents, 4) : data.aws_iam_policy_document.empty.json,
    length(local.source_documents) > 5 ? element(local.source_documents, 5) : data.aws_iam_policy_document.empty.json,
    length(local.source_documents) > 6 ? element(local.source_documents, 6) : data.aws_iam_policy_document.empty.json,
    length(local.source_documents) > 7 ? element(local.source_documents, 7) : data.aws_iam_policy_document.empty.json,
    length(local.source_documents) > 8 ? element(local.source_documents, 8) : data.aws_iam_policy_document.empty.json,
    length(local.source_documents) > 9 ? element(local.source_documents, 9) : data.aws_iam_policy_document.empty.json,
    length(local.source_documents) > 10 ? element(local.source_documents, 10) : data.aws_iam_policy_document.empty.json,
    length(local.source_documents) > 11 ? element(local.source_documents, 11) : data.aws_iam_policy_document.empty.json,
    length(local.source_documents) > 12 ? element(local.source_documents, 12) : data.aws_iam_policy_document.empty.json,
    length(local.source_documents) > 13 ? element(local.source_documents, 13) : data.aws_iam_policy_document.empty.json,
    length(local.source_documents) > 14 ? element(local.source_documents, 14) : data.aws_iam_policy_document.empty.json,
    length(local.source_documents) > 15 ? element(local.source_documents, 15) : data.aws_iam_policy_document.empty.json,
    length(local.source_documents) > 16 ? element(local.source_documents, 16) : data.aws_iam_policy_document.empty.json,
    length(local.source_documents) > 17 ? element(local.source_documents, 17) : data.aws_iam_policy_document.empty.json,
    length(local.source_documents) > 18 ? element(local.source_documents, 18) : data.aws_iam_policy_document.empty.json,
    length(local.source_documents) > 19 ? element(local.source_documents, 19) : data.aws_iam_policy_document.empty.json,
    length(local.source_documents) > 20 ? element(local.source_documents, 20) : data.aws_iam_policy_document.empty.json,
    length(local.source_documents) > 21 ? element(local.source_documents, 21) : data.aws_iam_policy_document.empty.json,
    length(local.source_documents) > 22 ? element(local.source_documents, 22) : data.aws_iam_policy_document.empty.json,
    length(local.source_documents) > 23 ? element(local.source_documents, 23) : data.aws_iam_policy_document.empty.json,
    length(local.source_documents) > 24 ? element(local.source_documents, 24) : data.aws_iam_policy_document.empty.json,
    length(local.source_documents) > 25 ? element(local.source_documents, 25) : data.aws_iam_policy_document.empty.json,
    length(local.source_documents) > 26 ? element(local.source_documents, 26) : data.aws_iam_policy_document.empty.json,
    length(local.source_documents) > 27 ? element(local.source_documents, 27) : data.aws_iam_policy_document.empty.json,
    length(local.source_documents) > 28 ? element(local.source_documents, 28) : data.aws_iam_policy_document.empty.json,
    length(local.source_documents) > 29 ? element(local.source_documents, 29) : data.aws_iam_policy_document.empty.json,
    length(local.source_documents) > 30 ? element(local.source_documents, 30) : data.aws_iam_policy_document.empty.json
  ]

  null_policy = {
    name   = null
    arn    = null
    policy = null
  }

  policy = concat(aws_iam_policy.this.*, [local.null_policy])[0]
}

data "aws_iam_policy_document" "empty" {}

data "aws_iam_policy_document" "zero" {
  source_json   = data.aws_iam_policy_document.empty.json
  override_json = element(local.policies, 0)
}

data "aws_iam_policy_document" "one" {
  source_json   = data.aws_iam_policy_document.zero.json
  override_json = element(local.policies, 1)
}

data "aws_iam_policy_document" "two" {
  source_json   = data.aws_iam_policy_document.one.json
  override_json = element(local.policies, 2)
}

data "aws_iam_policy_document" "three" {
  source_json   = data.aws_iam_policy_document.two.json
  override_json = element(local.policies, 3)
}

data "aws_iam_policy_document" "four" {
  source_json   = data.aws_iam_policy_document.three.json
  override_json = element(local.policies, 4)
}

data "aws_iam_policy_document" "five" {
  source_json   = data.aws_iam_policy_document.four.json
  override_json = element(local.policies, 5)
}

data "aws_iam_policy_document" "six" {
  source_json   = data.aws_iam_policy_document.five.json
  override_json = element(local.policies, 6)
}

data "aws_iam_policy_document" "seven" {
  source_json   = data.aws_iam_policy_document.six.json
  override_json = element(local.policies, 7)
}

data "aws_iam_policy_document" "eight" {
  source_json   = data.aws_iam_policy_document.seven.json
  override_json = element(local.policies, 8)
}

data "aws_iam_policy_document" "nine" {
  source_json   = data.aws_iam_policy_document.eight.json
  override_json = element(local.policies, 9)
}

data "aws_iam_policy_document" "ten" {
  source_json   = data.aws_iam_policy_document.nine.json
  override_json = element(local.policies, 10)
}

data "aws_iam_policy_document" "eleven" {
  source_json   = data.aws_iam_policy_document.ten.json
  override_json = element(local.policies, 11)
}

data "aws_iam_policy_document" "twelve" {
  source_json   = data.aws_iam_policy_document.eleven.json
  override_json = element(local.policies, 12)
}

data "aws_iam_policy_document" "thirteen" {
  source_json   = data.aws_iam_policy_document.twelve.json
  override_json = element(local.policies, 13)
}

data "aws_iam_policy_document" "fourteen" {
  source_json   = data.aws_iam_policy_document.thirteen.json
  override_json = element(local.policies, 14)
}

data "aws_iam_policy_document" "fifteen" {
  source_json   = data.aws_iam_policy_document.fourteen.json
  override_json = element(local.policies, 15)
}

data "aws_iam_policy_document" "sixteen" {
  source_json   = data.aws_iam_policy_document.fifteen.json
  override_json = element(local.policies, 16)
}

data "aws_iam_policy_document" "seventeen" {
  source_json   = data.aws_iam_policy_document.sixteen.json
  override_json = element(local.policies, 17)
}

data "aws_iam_policy_document" "eighteen" {
  source_json   = data.aws_iam_policy_document.seventeen.json
  override_json = element(local.policies, 18)
}

data "aws_iam_policy_document" "nineteen" {
  source_json   = data.aws_iam_policy_document.eighteen.json
  override_json = element(local.policies, 19)
}

data "aws_iam_policy_document" "twenty" {
  source_json   = data.aws_iam_policy_document.nineteen.json
  override_json = element(local.policies, 20)
}

data "aws_iam_policy_document" "twenty_one" {
  source_json   = data.aws_iam_policy_document.twenty.json
  override_json = element(local.policies, 21)
}

data "aws_iam_policy_document" "twenty_two" {
  source_json   = data.aws_iam_policy_document.twenty_one.json
  override_json = element(local.policies, 22)
}

data "aws_iam_policy_document" "twenty_three" {
  source_json   = data.aws_iam_policy_document.twenty_two.json
  override_json = element(local.policies, 23)
}

data "aws_iam_policy_document" "twenty_four" {
  source_json   = data.aws_iam_policy_document.twenty_three.json
  override_json = element(local.policies, 24)
}

data "aws_iam_policy_document" "twenty_five" {
  source_json   = data.aws_iam_policy_document.twenty_four.json
  override_json = element(local.policies, 25)
}

data "aws_iam_policy_document" "twenty_six" {
  source_json   = data.aws_iam_policy_document.twenty_five.json
  override_json = element(local.policies, 26)
}

data "aws_iam_policy_document" "twenty_seven" {
  source_json   = data.aws_iam_policy_document.twenty_six.json
  override_json = element(local.policies, 27)
}

data "aws_iam_policy_document" "twenty_eight" {
  source_json   = data.aws_iam_policy_document.twenty_seven.json
  override_json = element(local.policies, 28)
}

data "aws_iam_policy_document" "twenty_nine" {
  source_json   = data.aws_iam_policy_document.twenty_eight.json
  override_json = element(local.policies, 29)
}

data "aws_iam_policy_document" "default" {
  source_json = data.aws_iam_policy_document.twenty_nine.json
}

resource "aws_iam_policy" "this" {
  count = (
    (var.create_policy_resource == true) && (length(var.source_policies_json) == 0)
    ? 0
    : 1
  )

  name        = var.name
  policy      = data.aws_iam_policy_document.default.json
  description = var.description
  path        = var.path
}
