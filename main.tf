locals {
  parameter_name = "/${var.namespace}/${var.stage}/${var.name}/Terraform-SNS-Trigger-Hash"
}

resource "aws_ssm_parameter" "default" {
  name        = "${local.parameter_name}"
  description = "Force an SNS event via cloudwatch and Parameter Store for ${module.label.id}"
  type        = "String"
  value       = "${var.trigger_hash}"
  tags        = "${var.tags}"
  depends_on  = ["aws_cloudwatch_event_rule.default"]
}

resource "aws_cloudwatch_event_rule" "default" {
  name        = "${module.label.id}-sns-notify"
  description = "Force an SNS event via cloudwatch and Parameter Store for ${module.label.id}"

  event_pattern = <<PATTERN
{
  "source": [
    "aws.ssm"
  ],
  "detail-type": [
    "Parameter Store Change"
  ],
  "detail": {
    "operation": ["Update", "Create"],
    "name": ["${local.parameter_name}"]
  }
}
PATTERN
}

resource "aws_cloudwatch_event_target" "sns" {
  count      = "${length(var.sns_topic_arns)}"
  rule       = "${aws_cloudwatch_event_rule.default.name}"
  target_id  = "SendToSNS"
  arn        = "${element(var.sns_topic_arns, count.index)}"
  depends_on = ["aws_cloudwatch_event_rule.default"]
}

output "parameter_name" {
  value = "${local.parameter_name}"
}

output "trigger_hash" {
  value = "${var.trigger_hash}"
}
