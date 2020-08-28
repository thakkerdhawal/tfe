#### Terraform Output ####
output "sqs_queue_arn" {
  value       = "${aws_sqs_queue.logging-sqs-queue.arn}"
}


