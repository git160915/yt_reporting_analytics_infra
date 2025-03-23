terraform {
  source = "../../../modules/github_secret"
}

inputs = {
  github_token = get_env("GITHUB_TOKEN_YT_REPORTING_ANALYTICS_INFRA", "")        # Preferably, pass this via environment variable or secrets
  github_owner = "git160915"
  repository   = "yt_reporting_analytics_infra"
}
