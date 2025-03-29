variable "vpc_id" {
  description = "The VPC ID to create the security group in."
  type        = string
}

variable "environment" {
  description = "A prefix to apply to resource names to differentiate environments"
  type        = string
  default     = ""
}
