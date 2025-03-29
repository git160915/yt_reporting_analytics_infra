variable "cidr_block" {
  description = "CIDR block for the VPC"
  type        = string
}
variable "environment" {
  description = "A prefix to apply to resource names to differentiate environments"
  type        = string
  default     = ""
}
