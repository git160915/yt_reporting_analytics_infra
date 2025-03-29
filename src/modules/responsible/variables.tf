/*variable "ami_id" {
  type = string
}*/
variable "instance_type" {
  type = string
}
variable "responsible_subnet_id" {
  type = string
}
variable "security_group_id" {
  type = string
}
variable "instance_profile_name" {
  type = string
}
variable "environment" {
  description = "A prefix to apply to resource names to differentiate environments"
  type        = string
  default     = ""
}
