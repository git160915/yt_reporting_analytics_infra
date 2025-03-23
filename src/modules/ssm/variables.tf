variable "ec2_ssm_role_name" {
  description = "The name of the IAM role for SSM."
  type        = string
}

variable "ec2_ssm_instance_profile_name" {
  description = "The name of the instance profile for SSM."
  type        = string
}