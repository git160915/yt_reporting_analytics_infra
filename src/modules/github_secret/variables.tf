variable "github_token" {
  type        = string
  description = "GitHub token with repository admin permissions"
}

variable "github_owner" {
  type        = string
  description = "GitHub account or organization owning the repository"
}

variable "repository" {
  type        = string
  description = "The name of the GitHub repository"
}