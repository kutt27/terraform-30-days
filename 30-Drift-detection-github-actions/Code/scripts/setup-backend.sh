#!/bin/bash
# Script to create S3 buckets for Terraform state management (Dev and Prod)
# Run this once before using the Terraform workflows

set -e

# Configuration
BASE_BUCKET_NAME="${1:-day30-drift-detection-amals}" # Default base name
AWS_REGION="${2:-us-east-1}"
ENVIRONMENTS=("dev" "prod")

echo "=========================================="
echo "Terraform Backend Setup (Multi-Environment)"
echo "=========================================="
echo "Base Name: $BASE_BUCKET_NAME"
echo "Region:    $AWS_REGION"
echo "Envs:      ${ENVIRONMENTS[*]}"
echo "=========================================="

for ENV in "${ENVIRONMENTS[@]}"; do
  BUCKET_NAME="${BASE_BUCKET_NAME}-${ENV}"
  
  echo ""
  echo "--- Setting up environment: $ENV ---"
  echo "Bucket: $BUCKET_NAME"

  # Create S3 bucket
  echo "Creating S3 bucket..."
  if aws s3api head-bucket --bucket "$BUCKET_NAME" 2>/dev/null; then
    echo "⚠️ Bucket $BUCKET_NAME already exists. Skipping creation..."
  else
    aws s3api create-bucket \
      --bucket "$BUCKET_NAME" \
      --region "$AWS_REGION" \
      $(if [ "$AWS_REGION" != "us-east-1" ]; then echo "--create-bucket-configuration LocationConstraint=$AWS_REGION"; fi)
    echo "✅ Bucket created."
  fi

  # Enable versioning
  echo "Enabling versioning..."
  aws s3api put-bucket-versioning \
    --bucket "$BUCKET_NAME" \
    --versioning-configuration Status=Enabled

  # Enable encryption
  echo "Enabling encryption..."
  aws s3api put-bucket-encryption \
    --bucket "$BUCKET_NAME" \
    --server-side-encryption-configuration '{
      "Rules": [{
        "ApplyServerSideEncryptionByDefault": {
          "SSEAlgorithm": "AES256"
        }
      }]
    }'

  # Block public access
  echo "Blocking public access..."
  aws s3api put-public-access-block \
    --bucket "$BUCKET_NAME" \
    --public-access-block-configuration \
      "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"
done

echo ""
echo "=========================================="
echo "✅ All Backend setups complete!"
echo "=========================================="
echo ""
echo "Next Steps:"
echo "1. Verify these names match your .hcl files:"
echo "   - backend-dev.hcl:  ${BASE_BUCKET_NAME}-dev"
echo "   - backend-prod.hcl: ${BASE_BUCKET_NAME}-prod"
echo ""
echo "2. Add AWS Credentials to GitHub Secrets."
echo "3. Create 'dev' and 'prod' Environments in GitHub Settings."
echo "=========================================="
