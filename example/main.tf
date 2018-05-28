### For connecting and provisioning
variable "region" {
  default = "ap-southeast-2"
}

variable "aws_access_key" {
  default = ""
}

variable "aws_secret_key" {
  default = ""
}

provider "aws" {
  region     = "${var.region}"
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"

  #version    = "> 1.18.0"

  # Make it faster by skipping something
  skip_get_ec2_platforms      = true
  skip_metadata_api_check     = true
  skip_region_validation      = true
  skip_credentials_validation = true
  skip_requesting_account_id  = true
}

data "aws_caller_identity" "default" {}

resource "aws_sns_topic" "default" {
  name_prefix = "Automation-Trigger"
}

resource "random_string" "unique" {
  length  = 7
  special = false
  lower   = true
  upper   = false
  number  = false
}

module "notify" {
  source         = "../"
  namespace      = "cp"
  stage          = "staging"
  name           = "lambda-trigger-automation"
  sns_topic_arns = ["${aws_sns_topic.default.arn}"]
  trigger_hash   = "${random_string.unique.result}"
}

resource "aws_sns_topic_policy" "default" {
  arn = "${aws_sns_topic.default.arn}"

  policy = "${data.aws_iam_policy_document.sns_topic_policy.json}"
}

data "aws_iam_policy_document" "sns_topic_policy" {
  policy_id = "__default_policy_ID"

  statement {
    sid = "__default_statement_ID"
    actions = [
      "SNS:Subscribe",
      "SNS:SetTopicAttributes",
      "SNS:RemovePermission",
      "SNS:Receive",
      "SNS:Publish",
      "SNS:ListSubscriptionsByTopic",
      "SNS:GetTopicAttributes",
      "SNS:DeleteTopic",
      "SNS:AddPermission",
    ]

    effect    = "Allow"
    resources = ["${aws_sns_topic.default.arn}"]

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceOwner"

      values = [
        "arn:aws:iam::${data.aws_caller_identity.default.account_id}:root",
      ]
    }
  }

  statement {
    sid = "Allow CloudwatchEvents"
    actions   = ["sns:Publish"]
    resources = ["${aws_sns_topic.default.arn}"]

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }
  }
}

output "sns_topics" {
  value = "${aws_sns_topic.default.arn}"
}

output "parameter_name" {
  value = "${module.notify.parameter_name}"
}

output "trigger_hash" {
  value = "${random_string.unique.result}"
}
