#!/usr/bin/env bash
set -euo pipefail

BUCKET_NAME=${1:-redemption-terraform-state}
DYNAMO_TABLE=${2:-redemption-terraform-lock}
REGION=${AWS_DEFAULT_REGION:-${3:-us-east-1}}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if ! command -v aws >/dev/null 2>&1; then
  echo "AWS CLI not found in PATH. Install AWS CLI v2 and retry." >&2
  exit 1
fi

echo "Creating S3 bucket '$BUCKET_NAME' in region '$REGION'..."
if [ "$REGION" = "us-east-1" ]; then
  aws s3api create-bucket --bucket "$BUCKET_NAME" --region "$REGION" || true
else
  aws s3api create-bucket --bucket "$BUCKET_NAME" --region "$REGION" --create-bucket-configuration LocationConstraint=$REGION || true
fi

echo "Enabling versioning..."
aws s3api put-bucket-versioning --bucket "$BUCKET_NAME" --versioning-configuration '{"Status":"Enabled"}'

echo "Enabling server-side encryption (AES256)..."
aws s3api put-bucket-encryption --bucket "$BUCKET_NAME" --server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'

echo "Creating DynamoDB table '$DYNAMO_TABLE' for Terraform state locking..."
aws dynamodb create-table --table-name "$DYNAMO_TABLE" --attribute-definitions AttributeName=LockID,AttributeType=S --key-schema AttributeName=LockID,KeyType=HASH --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 --region "$REGION" || true

echo "Backend bootstrap complete."

# Attempt terraform init -reconfigure
if command -v terraform >/dev/null 2>&1; then
  TF_CMD=terraform
elif [ -x "$SCRIPT_DIR/terraform.exe" ]; then
  TF_CMD="$SCRIPT_DIR/terraform.exe"
elif [ -x "$SCRIPT_DIR/../terraform.exe" ]; then
  TF_CMD="$SCRIPT_DIR/../terraform.exe"
else
  TF_CMD=""
fi

if [ -n "$TF_CMD" ]; then
  echo "Running '$TF_CMD init -reconfigure' in infra/terraform..."
  (cd "$SCRIPT_DIR/infra/terraform" && "$TF_CMD" init -reconfigure)
  echo "If init succeeded, run plan/apply as needed."
else
  echo "Terraform binary not found. Run init manually with the terraform executable." >&2
fi
