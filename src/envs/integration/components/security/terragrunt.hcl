include {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../../modules/security"
}

dependencies {
  paths = ["../vpc"]
}

inputs = {
  vpc_id = dependency.vpc.outputs.vpc_id
}
