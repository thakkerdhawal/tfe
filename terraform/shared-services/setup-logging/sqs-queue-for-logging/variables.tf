variable "name" {
  description = "Name identifier to be used to create bucket"
  default     = ""
}

variable "logging-dead-letter-queue-arn" {
  description = "ARN of Dead Letter Queue"
  default     = ""
}

variable "global" {
  description = "Boolean to control whether this is regional bucket"
  default     = false
}

variable "default_tags" {
  description = "Default Tags"
  type    = "map"
  default     = {}
}
