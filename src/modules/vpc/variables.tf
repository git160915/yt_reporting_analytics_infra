variable "cidr_block" {
  description = "CIDR block for the VPC"
  type        = string
}
variable "vpc_name" {
  description = "The name to assign to the VPC."
  type        = string
}
variable "subnet_name" {
  description = "The name to assign to the Subnet."
  type        = string
}
