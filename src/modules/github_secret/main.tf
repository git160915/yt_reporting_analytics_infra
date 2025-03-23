terraform {
  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 5.0"
    }
  }
}

provider "github" {
  token = var.github_token
  owner = var.github_owner
}

resource "github_actions_secret" "aws_region" {
  repository      = var.repository
  secret_name     = "AWS_REGION"
  plaintext_value = "ap-southeast-2"
}
