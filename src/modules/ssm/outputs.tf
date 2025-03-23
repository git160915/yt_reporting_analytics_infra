output "ssm_instance_profile" {
  value = aws_iam_instance_profile.ssm_profile.name
}

output "ssm_role_arn" {
  value = aws_iam_role.ssm_role.arn
}
