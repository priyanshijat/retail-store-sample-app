#!/bin/bash

# Deploy GitHub Actions IAM User and Policy
# This script creates the necessary IAM resources for GitHub Actions ECR access

set -e

echo "🚀 Deploying GitHub Actions IAM resources..."

# Check if AWS CLI is configured
if ! aws sts get-caller-identity &>/dev/null; then
    echo "❌ AWS CLI not configured. Please run 'aws configure' first."
    exit 1
fi

# Get current directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Initialize Terraform
echo "📦 Initializing Terraform..."
cd "$SCRIPT_DIR"
terraform init

# Plan the deployment
echo "📋 Planning Terraform deployment..."
terraform plan -out=tfplan

# Apply the deployment
echo "🔧 Applying Terraform configuration..."
terraform apply tfplan

# Get the outputs
echo "📄 Getting credentials..."
ACCESS_KEY_ID=$(terraform output -raw github_actions_access_key_id)
SECRET_ACCESS_KEY=$(terraform output -raw github_actions_secret_access_key)
USER_ARN=$(terraform output -raw github_actions_user_arn)

echo ""
echo "✅ GitHub Actions IAM resources created successfully!"
echo ""
echo "📋 Add these secrets to your GitHub repository:"
echo "   Repository → Settings → Secrets and variables → Actions"
echo ""
echo "🔑 Required GitHub Secrets:"
echo "   AWS_ACCESS_KEY_ID: $ACCESS_KEY_ID"
echo "   AWS_SECRET_ACCESS_KEY: [HIDDEN - Check Terraform output or SSM]"
echo "   AWS_REGION: $(aws configure get region)"
echo "   AWS_ACCOUNT_ID: $(aws sts get-caller-identity --query Account --output text)"
echo ""
echo "🔐 Security Note:"
echo "   - Credentials are also stored in AWS Systems Manager Parameter Store"
echo "   - Access Key ID: /ci-cd/github-actions/access-key-id"
echo "   - Secret Access Key: /ci-cd/github-actions/secret-access-key"
echo ""
echo "👤 IAM User ARN: $USER_ARN"
echo ""
echo "🎯 Next Steps:"
echo "   1. Add the secrets to your GitHub repository"
echo "   2. Test the GitHub Actions workflow"
echo "   3. Monitor ECR repositories for successful image pushes"

# Clean up plan file
rm -f tfplan

echo ""
echo "🔒 Security Best Practices Applied:"
echo "   ✅ Minimal required permissions (principle of least privilege)"
echo "   ✅ Resource-specific ARNs (no wildcard permissions)"
echo "   ✅ Credentials stored in encrypted SSM parameters"
echo "   ✅ Proper IAM user path (/ci-cd/)"
echo "   ✅ Comprehensive resource tagging"
