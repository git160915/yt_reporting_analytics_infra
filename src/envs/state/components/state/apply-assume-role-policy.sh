#!/bin/bash
set -euo pipefail

# --- Required Environment Variable ---
: "${ACCOUNT_ID:?Need to set ACCOUNT_ID (AWS account id)}"

# --- Default Values ---
ROLE_NAME=""
TARGET_TYPE=""
TARGET_NAME=""
RECREATE=false
DELETE_ONLY=false

usage() {
  echo "Usage: $0 --role-name ROLE_NAME --target-type [user|group] --target-name TARGET_NAME [--recreate] [--delete-only]"
  exit 1
}

# --- Parse Command Line Arguments ---
while [[ "$#" -gt 0 ]]; do
  case $1 in
    --role-name)
      ROLE_NAME="$2"
      shift ;;
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
      echo "Unknown parameter passed: $1"
      usage ;;
  esac
  shift
done

if [[ -z "$ROLE_NAME" || -z "$TARGET_TYPE" || -z "$TARGET_NAME" ]]; then
  usage
fi

# --- Functions for Deleting Existing Inline Policy ---
delete_policy_for_user() {
  if aws iam list-user-policies --user-name "$TARGET_NAME" --query 'PolicyNames' --output text | grep -qw "Assume${ROLE_NAME}Policy"; then
    echo "Deleting existing inline policy 'Assume${ROLE_NAME}Policy' from user '$TARGET_NAME'..."
    aws iam delete-user-policy --user-name "$TARGET_NAME" --policy-name "Assume${ROLE_NAME}Policy"
  else
    echo "No inline policy 'Assume${ROLE_NAME}Policy' found for user '$TARGET_NAME'."
  fi
}

delete_policy_for_group() {
  if aws iam list-group-policies --group-name "$TARGET_NAME" --query 'PolicyNames' --output text | grep -qw "Assume${ROLE_NAME}Policy"; then
    echo "Deleting existing inline policy 'Assume${ROLE_NAME}Policy' from group '$TARGET_NAME'..."
    aws iam delete-group-policy --group-name "$TARGET_NAME" --policy-name "Assume${ROLE_NAME}Policy"
  else
    echo "No inline policy 'Assume${ROLE_NAME}Policy' found for group '$TARGET_NAME'."
  fi
}

# --- Functions for Creating New Targets ---
create_new_user_if_needed() {
  if aws iam get-user --user-name "$TARGET_NAME" &>/dev/null; then
    echo "IAM user '$TARGET_NAME' already exists."
  else
    echo "Creating IAM user '$TARGET_NAME'..."
    aws iam create-user --user-name "$TARGET_NAME"
    echo "IAM user '$TARGET_NAME' created successfully."
  fi
}

create_new_group_if_needed() {
  if aws iam get-group --group-name "$TARGET_NAME" &>/dev/null; then
    echo "IAM group '$TARGET_NAME' already exists."
  else
    echo "Creating IAM group '$TARGET_NAME'..."
    aws iam create-group --group-name "$TARGET_NAME"
    echo "IAM group '$TARGET_NAME' created successfully."
  fi
}

# --- Main Execution ---
if [[ "$DELETE_ONLY" == true ]]; then
  echo "Delete-only mode enabled. Deleting inline policy from target $TARGET_TYPE: $TARGET_NAME..."
  if [[ "$TARGET_TYPE" == "user" ]]; then
    delete_policy_for_user
  elif [[ "$TARGET_TYPE" == "group" ]]; then
    delete_policy_for_group
  else
    echo "Error: --target-type must be either 'user' or 'group'."
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
elif [[ "$TARGET_TYPE" == "group" ]]; then
  create_new_group_if_needed
else
  echo "Error: --target-type must be either 'user' or 'group'."
  usage
fi

# --- Define the Assume-Role Policy Document ---
ASSUME_POLICY=$(cat <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "sts:AssumeRole",
      "Resource": "arn:aws:iam::${ACCOUNT_ID}:role/${ROLE_NAME}"
    }
  ]
}
EOF
)

# --- Attach the Policy to the Target ---
if [[ "$TARGET_TYPE" == "user" ]]; then
  echo "Attaching assume role policy to IAM user: $TARGET_NAME for role: $ROLE_NAME..."
  aws iam put-user-policy --user-name "$TARGET_NAME" --policy-name "Assume${ROLE_NAME}Policy" --policy-document "$ASSUME_POLICY"
elif [[ "$TARGET_TYPE" == "group" ]]; then
  echo "Attaching assume role policy to IAM group: $TARGET_NAME for role: $ROLE_NAME..."
  aws iam put-group-policy --group-name "$TARGET_NAME" --policy-name "Assume${ROLE_NAME}Policy" --policy-document "$ASSUME_POLICY"
fi

echo "Policy attached successfully."
