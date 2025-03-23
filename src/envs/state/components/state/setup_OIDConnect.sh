#!/bin/bash
# create-oidc-provider.sh
# This script creates an OpenID Connect provider in AWS IAM for GitHub Actions.

set -euo pipefail

# Variables
OIDC_URL="https://token.actions.githubusercontent.com"
# GitHub's OIDC thumbprint (recommended by GitHub)
THUMBPRINT="6938fd4d98bab03faadb97b34396831e3780aea1"
CLIENT_ID="sts.amazonaws.com"

echo "Creating OpenID Connect provider for GitHub Actions..."
aws iam create-open-id-connect-provider \
  --url "$OIDC_URL" \
  --thumbprint-list "$THUMBPRINT" \
  --client-id-list "$CLIENT_ID"

echo "OpenID Connect provider created successfully."
