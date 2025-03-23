locals {
  region      = "ap-southeast-2"
  environment = "integration"
}

remote_state {
  backend = "s3"
  config = {
    bucket         = "my-terraform-state-bucket-yt-rpt-ana-infra"
    key            = "${local.environment}/terraform.tfstate"
    region         = local.region
    encrypt        = true
    dynamodb_table = "terraform-lock"
  }
}
