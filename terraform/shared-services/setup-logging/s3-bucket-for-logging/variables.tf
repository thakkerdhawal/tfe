variable "enabled" {
  description = "Boolean to control whether to create this bucket"
  default     = true
}

variable "global" {
  description = "Boolean to control whether this is regional bucket"
  default     = false
}


variable "name" {
  description = "Name identifier to be used to create bucket"
  default     = ""
}

variable "account_alias" {
  description = "AWS accounts alias"
  default     = ""
}

variable "default_tags" {
  description = "Default Tags"
  type    = "map"
  default     = {}
}

variable "s3-bucket-policy-doc" {
  description = "Bucket policy for shared-service bucket"
  default     = ""
}

variable "logging-sqs-queue-arn" {
  description = "Queue ARN for notification"
  default     = ""
}
