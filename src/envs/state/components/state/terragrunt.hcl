include {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../../modules/state"
}

inputs = {
  bucket_name = "my-terraform-state-bucket-yt-rpt-ana-infra"
  table_name  = "terraform-lock"
  environment = "state"
}
