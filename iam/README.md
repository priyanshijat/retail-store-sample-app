# GitHub Actions IAM Setup for ECR Access

This directory contains the IAM configuration for GitHub Actions to securely build and push Docker images to Amazon ECR following AWS security best practices.

## 🔒 Security Best Practices Implemented

### 1. **Principle of Least Privilege**
- Only grants permissions required for ECR operations
- No unnecessary administrative permissions
- Resource-specific ARNs (no wildcards where possible)

### 2. **Resource-Specific Permissions**
- Permissions scoped to specific ECR repositories only:
  - `retail-store-ui`
  - `retail-store-catalog` 
  - `retail-store-cart`
  - `retail-store-orders`
  - `retail-store-checkout`

### 3. **Secure Credential Management**
- Credentials stored in encrypted AWS Systems Manager Parameter Store
- Terraform outputs marked as sensitive
- No hardcoded credentials in code

### 4. **Proper IAM Organization**
- IAM user created in `/ci-cd/` path for organization
- Comprehensive resource tagging
- Clear naming conventions

## 📋 Required Permissions

The IAM policy grants these minimal permissions:

### ECR Authentication
```json
{
  "Action": ["ecr:GetAuthorizationToken"],
  "Resource": "*"
}
```

### ECR Repository Operations
```json
{
  "Action": [
    "ecr:BatchCheckLayerAvailability",
    "ecr:GetDownloadUrlForLayer", 
    "ecr:BatchGetImage",
    "ecr:InitiateLayerUpload",
    "ecr:UploadLayerPart",
    "ecr:CompleteLayerUpload",
    "ecr:PutImage"
  ],
  "Resource": "arn:aws:ecr:region:account:repository/retail-store-*"
}
```

### ECR Repository Management
```json
{
  "Action": [
    "ecr:CreateRepository",
    "ecr:DescribeRepositories",
    "ecr:ListImages",
    "ecr:DescribeImages"
  ],
  "Resource": "arn:aws:ecr:region:account:repository/retail-store-*"
}
```

## 🚀 Quick Deployment

### Prerequisites
- AWS CLI configured with appropriate permissions
- Terraform installed
- Permissions to create IAM users and policies

### Deploy IAM Resources

```bash
# Navigate to IAM directory
cd iam/

# Run deployment script
./deploy-github-actions-iam.sh
```

### Manual Deployment

```bash
# Initialize Terraform
terraform init

# Plan deployment
terraform plan

# Apply configuration
terraform apply
```

## 🔑 GitHub Secrets Setup

After deployment, add these secrets to your GitHub repository:

**Repository → Settings → Secrets and variables → Actions**

| Secret Name | Value | Source |
|-------------|-------|--------|
| `AWS_ACCESS_KEY_ID` | Access Key ID | Terraform output |
| `AWS_SECRET_ACCESS_KEY` | Secret Access Key | Terraform output |
| `AWS_REGION` | Your AWS region | `aws configure get region` |
| `AWS_ACCOUNT_ID` | Your AWS account ID | `aws sts get-caller-identity` |

## 📊 Retrieve Credentials

### From Terraform Output
```bash
# Get access key (sensitive)
terraform output github_actions_access_key_id

# Get secret key (sensitive) 
terraform output github_actions_secret_access_key
```

### From AWS Systems Manager
```bash
# Get access key from SSM
aws ssm get-parameter --name "/ci-cd/github-actions/access-key-id" --with-decryption --query "Parameter.Value" --output text

# Get secret key from SSM
aws ssm get-parameter --name "/ci-cd/github-actions/secret-access-key" --with-decryption --query "Parameter.Value" --output text
```

## 🧪 Testing the Setup

### Test ECR Authentication
```bash
# Set environment variables
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_DEFAULT_REGION="your-region"

# Test ECR login
aws ecr get-login-password --region $AWS_DEFAULT_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com
```

### Test Repository Access
```bash
# List ECR repositories
aws ecr describe-repositories --repository-names retail-store-ui retail-store-catalog retail-store-cart retail-store-orders retail-store-checkout
```

## 🔄 GitHub Actions Workflow Integration

Your GitHub Actions workflow should use these secrets:

```yaml
name: Build and Push to ECR
on:
  push:
    branches: [main, gitops]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: ${{ secrets.AWS_REGION }}
      
      - name: Login to Amazon ECR
        uses: aws-actions/amazon-ecr-login@v2
      
      - name: Build and push Docker image
        run: |
          docker build -t ${{ secrets.AWS_ACCOUNT_ID }}.dkr.ecr.${{ secrets.AWS_REGION }}.amazonaws.com/retail-store-ui:${{ github.sha }} .
          docker push ${{ secrets.AWS_ACCOUNT_ID }}.dkr.ecr.${{ secrets.AWS_REGION }}.amazonaws.com/retail-store-ui:${{ github.sha }}
```

## 🧹 Cleanup

To remove the IAM resources:

```bash
# Destroy Terraform resources
terraform destroy

# Manually delete SSM parameters if needed
aws ssm delete-parameter --name "/ci-cd/github-actions/access-key-id"
aws ssm delete-parameter --name "/ci-cd/github-actions/secret-access-key"
```

## 🔍 Troubleshooting

### Common Issues

1. **Access Denied Errors**
   - Verify IAM policy is attached to user
   - Check resource ARNs match your account/region
   - Ensure ECR repositories exist

2. **Authentication Failures**
   - Verify GitHub secrets are set correctly
   - Check AWS credentials are not expired
   - Confirm region matches ECR repositories

3. **Repository Not Found**
   - ECR repositories are created automatically on first push
   - Verify repository names match the policy

### Debug Commands

```bash
# Check IAM user
aws iam get-user --user-name github-actions-ecr-user

# Check attached policies
aws iam list-attached-user-policies --user-name github-actions-ecr-user

# Check ECR repositories
aws ecr describe-repositories

# Test ECR authentication
aws ecr get-authorization-token
```

## 📚 Additional Resources

- [AWS ECR User Guide](https://docs.aws.amazon.com/AmazonECR/latest/userguide/)
- [GitHub Actions AWS Documentation](https://docs.github.com/en/actions/deployment/deploying-to-your-cloud-provider/deploying-to-amazon-elastic-container-service)
- [AWS IAM Best Practices](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
