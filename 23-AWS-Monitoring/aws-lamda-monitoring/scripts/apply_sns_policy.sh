#!/bin/bash

# This script helps apply the missing SNS permissions to the terraform-learner user.
# IMPORTANT: This must be run with ADMIN credentials (not the terraform-learner credentials).

USER_NAME="terraform-learner"
POLICY_NAME="TerraformSnsManagement"
POLICY_FILE="scripts/sns_policy.json"

echo "Applying SNS permissions to user: $USER_NAME..."

if [ ! -f "$POLICY_FILE" ]; then
    echo "Error: $POLICY_FILE not found!"
    exit 1
fi

aws iam put-user-policy \
    --user-name "$USER_NAME" \
    --policy-name "$POLICY_NAME" \
    --policy-document "file://$POLICY_FILE"

if [ $? -eq 0 ]; then
    echo "Successfully attached SNS policy to $USER_NAME"
    echo "You can now run 'terraform apply' again."
else
    echo "Failed to apply policy. Please ensure you are running this with Administrative credentials."
fi
