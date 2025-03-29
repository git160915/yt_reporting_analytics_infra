#!/bin/bash
set -euo pipefail

# --- Required Environment Variables ---
: "${ACCOUNT_ID:?Need to set ACCOUNT_ID (AWS account id)}"
REGION="${AWS_REGION:-ap-southeast-2}"

# --- Default Values ---
DEFAULT_USER_NAME="StateReaderUser"
POLICY_NAME="StateReaderPolicy"
BUCKET_NAME="my-terraform-state-bucket-yt-rpt-ana-infra"
TABLE_NAME="terraform-lock"

# --- Parameters ---
# --target-type: "user" or "group"
# --target-name: name of the IAM user or group
# --recreate: if passed, delete existing inline policy before attaching
# --delete-only: if passed, only delete the inline policy
TARGET_TYPE=""
TARGET_NAME=""
RECREATE=false
DELETE_ONLY=false

usage() {
  echo "Usage: $0 --target-type user|group --target-name NAME [--recreate] [--delete-only]"
  exit 1
}

while [[ "$#" -gt 0 ]]; do
  case $1 in
    --target-type)
      TARGET_TYPE="$2"
      shift ;;
    --target-name)
      TARGET_NAME="$2"
      shift ;;
    --recreate)
      RECREATE=true ;;
    --delete-only)
      DELETE_ONLY=true ;;
    *)
      echo "Unknown parameter: $1"
      usage ;;
  esac
  shift
done

if [[ -z "$TARGET_TYPE" || -z "$TARGET_NAME" ]]; then
  echo "No target specified. Defaulting to IAM user: $DEFAULT_USER_NAME"
  TARGET_TYPE="user"
  TARGET_NAME="$DEFAULT_USER_NAME"
fi

# --- Define the inline policy document for read-only access to state resources ---
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
        "s3:PutLifecycleConfiguration",
        "s3:GetReplicationConfiguration",
        "s3:GetBucketObjectLockConfiguration"
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

# --- Functions ---

# Delete inline policy from a user if it exists.
function delete_policy_for_user() {
  if aws iam list-user-policies --user-name "$TARGET_NAME" --query 'PolicyNames' --output text | grep -qw "$POLICY_NAME"; then
    echo "Deleting inline policy '$POLICY_NAME' from user '$TARGET_NAME'..."
    aws iam delete-user-policy --user-name "$TARGET_NAME" --policy-name "$POLICY_NAME"
  else
    echo "No inline policy '$POLICY_NAME' found for user '$TARGET_NAME'."
  fi
}

# Delete inline policy from a group if it exists.
function delete_policy_for_group() {
  if aws iam list-group-policies --group-name "$TARGET_NAME" --query 'PolicyNames' --output text | grep -qw "$POLICY_NAME"; then
    echo "Deleting inline policy '$POLICY_NAME' from group '$TARGET_NAME'..."
    aws iam delete-group-policy --group-name "$TARGET_NAME" --policy-name "$POLICY_NAME"
  else
    echo "No inline policy '$POLICY_NAME' found for group '$TARGET_NAME'."
  fi
}

# Create a new IAM user if needed.
function create_new_user_if_needed() {
  if aws iam get-user --user-name "$TARGET_NAME" &>/dev/null; then
    echo "IAM user '$TARGET_NAME' already exists."
  else
    echo "Creating IAM user '$TARGET_NAME'..."
    aws iam create-user --user-name "$TARGET_NAME"
    echo "IAM user '$TARGET_NAME' created successfully."
  fi
}

# Create a new IAM group if needed.
function create_new_group_if_needed() {
  if aws iam get-group --group-name "$TARGET_NAME" &>/dev/null; then
    echo "IAM group '$TARGET_NAME' already exists."
  else
    echo "Creating IAM group '$TARGET_NAME'..."
    aws iam create-group --group-name "$TARGET_NAME"
    echo "IAM group '$TARGET_NAME' created successfully."
  fi
}

# Attach the inline policy to a user.
function attach_policy_to_user() {
  echo "Attaching inline policy '$POLICY_NAME' to IAM user '$TARGET_NAME'..."
  aws iam put-user-policy --user-name "$TARGET_NAME" --policy-name "$POLICY_NAME" --policy-document "$POLICY_DOCUMENT"
  echo "Policy attached successfully to user '$TARGET_NAME'."
}

# Attach the inline policy to a group.
function attach_policy_to_group() {
  echo "Attaching inline policy '$POLICY_NAME' to IAM group '$TARGET_NAME'..."
  aws iam put-group-policy --group-name "$TARGET_NAME" --policy-name "$POLICY_NAME" --policy-document "$POLICY_DOCUMENT"
  echo "Policy attached successfully to group '$TARGET_NAME'."
}

# --- Main Execution ---

if [[ "$DELETE_ONLY" == true ]]; then
  echo "Delete-only mode enabled. Deleting inline policy from target $TARGET_TYPE: $TARGET_NAME..."
  if [[ "$TARGET_TYPE" == "user" ]]; then
    delete_policy_for_user
  elif [[ "$TARGET_TYPE" == "group" ]]; then
    delete_policy_for_group
  else
    echo "Error: Unknown target type '$TARGET_TYPE'. Must be 'user' or 'group'."
    usage
  fi
  echo "Delete-only operation completed."
  exit 0
fi

if [[ "$RECREATE" == true ]]; then
  echo "Recreate flag is set. Deleting existing inline policy from target $TARGET_TYPE: $TARGET_NAME..."
  if [[ "$TARGET_TYPE" == "user" ]]; then
    delete_policy_for_user
  elif [[ "$TARGET_TYPE" == "group" ]]; then
    delete_policy_for_group
  fi
fi

if [[ "$TARGET_TYPE" == "user" ]]; then
  create_new_user_if_needed
  attach_policy_to_user
elif [[ "$TARGET_TYPE" == "group" ]]; then
  create_new_group_if_needed
  attach_policy_to_group
else
  echo "Error: --target-type must be 'user' or 'group'."
  usage
fi

echo "Operation completed successfully."
