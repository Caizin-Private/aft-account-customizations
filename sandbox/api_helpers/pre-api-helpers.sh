#!/bin/bash
set -e

echo "Executing Pre-API Helpers"

# ---------------------------------------------------------------------------
# Import pre-existing resources into Terraform state to prevent conflicts.
# This handles accounts where resources were created manually before AFT
# applied this customization.
# ---------------------------------------------------------------------------

ROLE_NAME="Github-Action-Serverless-Role"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# 1. Import IAM role if it exists in AWS but not in Terraform state
if aws iam get-role --role-name "$ROLE_NAME" &>/dev/null; then
  if ! terraform state list | grep -q "aws_iam_role.github_actions"; then
    echo "  Importing IAM role $ROLE_NAME into Terraform state..."
    terraform import aws_iam_role.github_actions "$ROLE_NAME"
  fi
fi

# 2. Import OIDC provider if it exists in AWS but not in Terraform state
OIDC_ARN="arn:aws:iam::${ACCOUNT_ID}:oidc-provider/token.actions.githubusercontent.com"
if aws iam get-open-id-connect-provider --open-id-connect-provider-arn "$OIDC_ARN" &>/dev/null; then
  if ! terraform state list | grep -q "aws_iam_openid_connect_provider.github_actions"; then
    echo "  Importing OIDC provider into Terraform state..."
    terraform import aws_iam_openid_connect_provider.github_actions "$OIDC_ARN"
  fi
fi

# 3. Import AdministratorAccess policy attachment if role exists and policy is attached
if aws iam get-role --role-name "$ROLE_NAME" &>/dev/null; then
  ADMIN_POLICY_ARN="arn:aws:iam::aws:policy/AdministratorAccess"
  ATTACHED=$(aws iam list-attached-role-policies --role-name "$ROLE_NAME" \
    --query "AttachedPolicies[?PolicyArn=='${ADMIN_POLICY_ARN}'].PolicyArn" \
    --output text)
  if [ -n "$ATTACHED" ]; then
    if ! terraform state list | grep -q "aws_iam_role_policy_attachment.github_actions_admin"; then
      echo "  Importing AdministratorAccess policy attachment into Terraform state..."
      terraform import aws_iam_role_policy_attachment.github_actions_admin \
        "${ROLE_NAME}/${ADMIN_POLICY_ARN}"
    fi
  fi
fi

echo "Pre-API Helpers complete."
