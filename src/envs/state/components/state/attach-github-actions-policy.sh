#!/bin/bash
set -euo pipefail

# Variables
ROLE_NAME="GitHubActionsRole"
POLICY_NAME="GitHubActionsStateBucketPolicy"
BUCKET_NAME="my-terraform-state-bucket-yt-rpt-ana-infra"

# Create the policy document with additional permissions, including s3:GetBucketPublicAccessBlock
cat <<EOF > github-actions-policy.json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowStateBucketActions",
      "Effect": "Allow",
      "Action": [
        "s3:ListBucket",
        "s3:GetBucketVersioning",
        "s3:GetBucketPolicy",
        "s3:GetBucketPublicAccessBlock",
        "s3:PutObject",
        "s3:GetObject",
        "s3:DeleteObject"
      ],
      "Resource": [
        "arn:aws:s3:::${BUCKET_NAME}",
        "arn:aws:s3:::${BUCKET_NAME}/*"
      ]
    }
  ]
}
EOF

echo "Policy document created:"
cat github-actions-policy.json

# Attach the inline policy to the role
aws iam put-role-policy \
  --role-name "$ROLE_NAME" \
  --policy-name "$POLICY_NAME" \
  --policy-document file://github-actions-policy.json

echo "Policy '$POLICY_NAME' attached successfully to role '$ROLE_NAME'."
