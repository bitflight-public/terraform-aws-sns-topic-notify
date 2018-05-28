variable "sns_topic_arns" {
  description = "The SNS topic arns to update"
  type        = "list"
}

variable "trigger_hash" {
  description = "A value that can be changed to trigger the notification of the SNS topic"
  default     = "none"
}
