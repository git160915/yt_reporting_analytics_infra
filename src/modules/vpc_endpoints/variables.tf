variable "vpc_id" {
  description = "The ID of the VPC where the endpoints will be created"
  type        = string
}

variable "subnet_ids" {
  description = "A list of subnet IDs where the endpoints should be deployed"
  type        = list(string)
}

variable "vpc_endpoint_sg_ids" {
  description = "A list of security group IDs to attach to the VPC endpoints"
  type        = list(string)
}

variable "region" {
  description = "The AWS region"
  type        = string
}

variable "environment" {
  description = "A prefix to apply to resource names to differentiate environments"
  type        = string
  default     = ""
}
