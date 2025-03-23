include {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../../modules/responsible"
}

dependencies {
  paths = [
    "../vpc",
    "../security",
    "../ssm"
  ]
}

inputs = {
  ami_id                = "ami-0c02fb55956c7d316"
  instance_type         = "t2.micro"
  responsible_subnet_id = dependency.vpc.outputs.responsible_subnet_id
  security_group_id     = dependency.security.outputs.sg_id
  instance_profile_name = dependency.ssm.outputs.ssm_instance_profile
}
