#!/bin/bash
set -euo pipefail

# --- Configuration Variables ---
: "${ACCOUNT_ID:?Need to set ACCOUNT_ID (AWS account id)}"
: "${GITHUB_OWNER:?Need to set GITHUB_OWNER (GitHub owner)}"
: "${GITHUB_REPO:?Need to set GITHUB_REPO (GitHub repository name)}"

ROLE_NAME="GitHubActionsRole"
POLICY_NAME="GitHubActionsComprehensivePolicy"
BUCKET_NAME="my-terraform-state-bucket-yt-rpt-ana-infra"
OIDC_URL="https://token.actions.githubusercontent.com"
OIDC_ARN="arn:aws:iam::${ACCOUNT_ID}:oidc-provider/token.actions.githubusercontent.com"
THUMBPRINT="6938fd4d98bab03faadb97b34396831e3780aea1"
CLIENT_ID="sts.amazonaws.com"

# --- Functions ---

delete_oidc_provider() {
  echo "Attempting to delete OIDC provider with ARN $OIDC_ARN..."
  if aws iam get-open-id-connect-provider --open-id-connect-provider-arn "$OIDC_ARN" &>/dev/null; then
    aws iam delete-open-id-connect-provider --open-id-connect-provider-arn "$OIDC_ARN"
    echo "OIDC provider deleted successfully."
  else
    echo "OIDC provider does not exist. Skipping deletion."
  fi
}

create_oidc_provider() {
  echo "Creating OIDC provider for GitHub Actions..."
  aws iam create-open-id-connect-provider \
    --url "$OIDC_URL" \
    --thumbprint-list "$THUMBPRINT" \
    --client-id-list "$CLIENT_ID"
  echo "OIDC provider created successfully."
}

delete_role_if_exists() {
  if aws iam get-role --role-name "$ROLE_NAME" &>/dev/null; then
    echo "Role $ROLE_NAME exists. Deleting inline policies and then the role..."

    # Delete inline policies
    POLICIES=$(aws iam list-role-policies --role-name "$ROLE_NAME" --query 'PolicyNames' --output text)
    for policy in $POLICIES; do
      echo "Deleting inline policy $policy from role $ROLE_NAME..."
      aws iam delete-role-policy --role-name "$ROLE_NAME" --policy-name "$policy"
    done

    # Detach managed policies if any
    MANAGED_POLICIES=$(aws iam list-attached-role-policies --role-name "$ROLE_NAME" --query 'AttachedPolicies[].PolicyArn' --output text)
    for policyArn in $MANAGED_POLICIES; do
      echo "Detaching managed policy $policyArn from role $ROLE_NAME..."
      aws iam detach-role-policy --role-name "$ROLE_NAME" --policy-arn "$policyArn"
    done

    echo "Deleting role $ROLE_NAME..."
    aws iam delete-role --role-name "$ROLE_NAME"
    echo "Role $ROLE_NAME deleted successfully."
  else
    echo "Role $ROLE_NAME does not exist; no deletion necessary."
  fi
}

create_role() {
  echo "Creating role $ROLE_NAME..."

  TRUST_POLICY=$(cat <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "$OIDC_ARN"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "ForAllValues:StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:${GITHUB_OWNER}/${GITHUB_REPO}:*"
        }
      }
    }
  ]
}
EOF
)

  aws iam create-role --role-name "$ROLE_NAME" \
    --assume-role-policy-document "$TRUST_POLICY"
  echo "Role $ROLE_NAME created successfully."
}

attach_inline_policy() {
  echo "Attaching inline policy $POLICY_NAME to role $ROLE_NAME..."

  # Comprehensive inline policy including all required IAM, S3, EC2, VPC, SSM, logging actions,
  # plus additional IAM permissions: iam:ListInstanceProfilesForRole.
  POLICY_DOCUMENT=$(cat <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowS3StateBucketActions",
      "Effect": "Allow",
      "Action": [
        "s3:CreateBucket",
        "s3:DeleteBucket",
        "s3:ListBucket",
        "s3:GetBucketLocation",
        "s3:GetBucketVersioning",
        "s3:PutBucketVersioning",
        "s3:GetBucketPolicy",
        "s3:PutBucketPolicy",
        "s3:GetBucketPublicAccessBlock",
        "s3:PutBucketPublicAccessBlock",
        "s3:GetEncryptionConfiguration",
        "s3:GetBucketTagging",
        "s3:PutBucketTagging",
        "s3:GetBucketCors",
        "s3:PutBucketCors",
        "s3:GetBucketWebsite",
        "s3:PutBucketWebsite",
        "s3:GetAccelerateConfiguration",
        "s3:GetBucketRequestPayment",
        "s3:PutBucketRequestPayment",
        "s3:PutObject",
        "s3:GetObject",
        "s3:DeleteObject",
        "s3:GetBucketAcl",
        "s3:PutBucketAcl",
        "s3:GetBucketLogging",
        "s3:PutBucketLogging",
        "s3:GetLifecycleConfiguration",
        "s3:PutLifecycleConfiguration"
      ],
      "Resource": "*"
    },
    {
      "Sid": "EC2Permissions",
      "Effect": "Allow",
      "Action": "ec2:*",
      "Resource": "*"
    },
    {
      "Sid": "VPCPermissions",
      "Effect": "Allow",
      "Action": [
        "ec2:CreateVpc",
        "ec2:DeleteVpc",
        "ec2:DescribeVpcs",
        "ec2:CreateSubnet",
        "ec2:DeleteSubnet",
        "ec2:DescribeSubnets",
        "ec2:CreateSecurityGroup",
        "ec2:DeleteSecurityGroup",
        "ec2:DescribeSecurityGroups",
        "ec2:AuthorizeSecurityGroupIngress",
        "ec2:RevokeSecurityGroupIngress"
      ],
      "Resource": "*"
    },
    {
      "Sid": "S3DynamoDBPermissions",
      "Effect": "Allow",
      "Action": [
        "s3:CreateBucket",
        "s3:DeleteBucket",
        "s3:ListBucket",
        "s3:GetBucketTagging",
        "s3:PutBucketTagging",
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject",
        "dynamodb:CreateTable",
        "dynamodb:DeleteTable",
        "dynamodb:DescribeTable",
        "dynamodb:PutItem",
        "dynamodb:GetItem",
        "dynamodb:UpdateItem",
        "dynamodb:DeleteItem"
      ],
      "Resource": "*"
    },
    {
      "Sid": "IAMPermissions",
      "Effect": "Allow",
      "Action": [
        "iam:CreateRole",
        "iam:DeleteRole",
        "iam:AttachRolePolicy",
        "iam:DetachRolePolicy",
        "iam:PassRole",
        "iam:CreateInstanceProfile",
        "iam:DeleteInstanceProfile",
        "iam:AddRoleToInstanceProfile",
        "iam:RemoveRoleFromInstanceProfile",
        "iam:GetRole",
        "iam:ListInstanceProfiles",
        "iam:ListRolePolicies",
        "iam:ListAttachedRolePolicies",
        "iam:GetInstanceProfile",
        "iam:ListInstanceProfilesForRole"
      ],
      "Resource": "*"
    },
    {
      "Sid": "SSMPermissions",
      "Effect": "Allow",
      "Action": "ssm:*",
      "Resource": "*"
    },
    {
      "Sid": "LoggingPermissions",
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "*"
    }
  ]
}
EOF
)

  aws iam put-role-policy \
    --role-name "$ROLE_NAME" \
    --policy-name "$POLICY_NAME" \
    --policy-document "$POLICY_DOCUMENT"
  echo "Inline policy attached successfully."
}

# --- Main Script Execution ---

if [[ "${1:-}" == "--recreate" || "${1:-}" == "-r" ]]; then
  echo "Recreate flag detected. Deleting existing role and OIDC provider if present..."
  delete_role_if_exists
  delete_oidc_provider
fi

create_oidc_provider
create_role
attach_inline_policy

echo "All operations completed successfully."
