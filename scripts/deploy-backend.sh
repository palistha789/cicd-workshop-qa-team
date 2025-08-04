#!/bin/bash
set -e	

# Login to AWS ECR
aws ecr get-login-password --region "$AWS_REGION" | docker login --username AWS --password-stdin "$ECR_REGISTRY"

# Extract current branch name from GitHub reference
branch_name="${GITHUB_REF#refs/heads/}"

# Build Docker image
cd backend
docker build -t "$ECR_REGISTRY/$ECR_REPOSITORY:$branch_name-latest" .

# Push image to ECR
docker push "$ECR_REGISTRY/$ECR_REPOSITORY:$branch_name-latest"

# Run remote deployment script via SSM
aws ssm send-command \
  --document-name "AWS-RunShellScript" \
  --targets "[{\"Key\":\"InstanceIds\",\"Values\":[\"$EC2_INSTANCE_ID\"]}]" \
  --parameters "{\"commands\":[\"sudo su - root -c '/root/deployment/deployment_script_teamN-name.sh'\"]}" \
  --region "$AWS_REGION"
