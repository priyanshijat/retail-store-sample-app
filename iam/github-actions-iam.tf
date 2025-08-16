# GitHub Actions IAM User for ECR Access
# This follows AWS security best practices with minimal required permissions

# Data source to get current AWS account ID
data "aws_caller_identity" "current" {}

# Data source to get current AWS region
data "aws_region" "current" {}

# IAM User for GitHub Actions
resource "aws_iam_user" "github_actions" {
  name = "github-actions-ecr-user"
  path = "/ci-cd/"

  tags = {
    Purpose     = "GitHub Actions CI/CD"
    Application = "retail-store-sample-app"
    Environment = "ci-cd"
  }
}

# IAM Policy for ECR access
resource "aws_iam_policy" "github_actions_ecr" {
  name        = "GitHubActionsECRPolicy"
  path        = "/ci-cd/"
  description = "Minimal permissions for GitHub Actions to build and push images to ECR"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ECRGetAuthorizationToken"
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken"
        ]
        Resource = "*"
      },
      {
        Sid    = "ECRRepositoryAccess"
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:PutImage"
        ]
        Resource = [
          "arn:aws:ecr:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:repository/retail-store-ui",
          "arn:aws:ecr:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:repository/retail-store-catalog",
          "arn:aws:ecr:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:repository/retail-store-cart",
          "arn:aws:ecr:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:repository/retail-store-orders",
          "arn:aws:ecr:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:repository/retail-store-checkout"
        ]
      },
      {
        Sid    = "ECRRepositoryManagement"
        Effect = "Allow"
        Action = [
          "ecr:CreateRepository",
          "ecr:DescribeRepositories",
          "ecr:ListImages",
          "ecr:DescribeImages"
        ]
        Resource = [
          "arn:aws:ecr:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:repository/retail-store-ui",
          "arn:aws:ecr:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:repository/retail-store-catalog",
          "arn:aws:ecr:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:repository/retail-store-cart",
          "arn:aws:ecr:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:repository/retail-store-orders",
          "arn:aws:ecr:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:repository/retail-store-checkout"
        ]
      }
    ]
  })

  tags = {
    Purpose     = "GitHub Actions CI/CD"
    Application = "retail-store-sample-app"
    Environment = "ci-cd"
  }
}

# Attach policy to user
resource "aws_iam_user_policy_attachment" "github_actions_ecr" {
  user       = aws_iam_user.github_actions.name
  policy_arn = aws_iam_policy.github_actions_ecr.arn
}

# Create access keys for the user
resource "aws_iam_access_key" "github_actions" {
  user = aws_iam_user.github_actions.name

  # Store in AWS Systems Manager Parameter Store for security
  depends_on = [aws_iam_user.github_actions]
}

# Store access key in SSM Parameter Store (encrypted)
resource "aws_ssm_parameter" "github_actions_access_key" {
  name  = "/ci-cd/github-actions/access-key-id"
  type  = "SecureString"
  value = aws_iam_access_key.github_actions.id

  tags = {
    Purpose     = "GitHub Actions CI/CD"
    Application = "retail-store-sample-app"
    Environment = "ci-cd"
  }
}

resource "aws_ssm_parameter" "github_actions_secret_key" {
  name  = "/ci-cd/github-actions/secret-access-key"
  type  = "SecureString"
  value = aws_iam_access_key.github_actions.secret

  tags = {
    Purpose     = "GitHub Actions CI/CD"
    Application = "retail-store-sample-app"
    Environment = "ci-cd"
  }
}

# Outputs
output "github_actions_user_arn" {
  description = "ARN of the GitHub Actions IAM user"
  value       = aws_iam_user.github_actions.arn
}

output "github_actions_access_key_id" {
  description = "Access Key ID for GitHub Actions (also stored in SSM)"
  value       = aws_iam_access_key.github_actions.id
  sensitive   = true
}

output "github_actions_secret_access_key" {
  description = "Secret Access Key for GitHub Actions (also stored in SSM)"
  value       = aws_iam_access_key.github_actions.secret
  sensitive   = true
}

output "ssm_parameter_access_key" {
  description = "SSM Parameter name for access key"
  value       = aws_ssm_parameter.github_actions_access_key.name
}

output "ssm_parameter_secret_key" {
  description = "SSM Parameter name for secret key"
  value       = aws_ssm_parameter.github_actions_secret_key.name
}
