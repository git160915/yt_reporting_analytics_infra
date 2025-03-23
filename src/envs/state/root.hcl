locals {
  region = "ap-southeast-2"
  environment = "state"
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite"
  contents  = <<EOF
provider "aws" {
  region = "${local.region}"
}
EOF
}

# No remote_state block here since we are bootstrapping the backend.
