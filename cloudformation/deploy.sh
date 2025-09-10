#!/bin/bash

# CloudFormation Deployment Script for Django Application Infrastructure

set -e

# Configuration
STACK_NAME="django-app-infrastructure"
TEMPLATE_FILE="main-template.yaml"
PARAMETERS_FILE="parameters.json"
REGION="us-east-1"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    log_error "AWS CLI is not installed. Please install it first."
    exit 1
fi

# Check if AWS credentials are configured
if ! aws sts get-caller-identity &> /dev/null; then
    log_error "AWS credentials not configured. Please run 'aws configure' first."
    exit 1
fi

# Validate template
log_info "Validating CloudFormation template..."
aws cloudformation validate-template \
    --template-body file://$TEMPLATE_FILE \
    --region $REGION

if [ $? -eq 0 ]; then
    log_info "Template validation successful"
else
    log_error "Template validation failed"
    exit 1
fi

# Check if stack exists
STACK_EXISTS=$(aws cloudformation describe-stacks \
    --stack-name $STACK_NAME \
    --region $REGION \
    --query 'Stacks[0].StackStatus' \
    --output text 2>/dev/null || echo "DOES_NOT_EXIST")

if [ "$STACK_EXISTS" != "DOES_NOT_EXIST" ]; then
    log_warn "Stack $STACK_NAME already exists with status: $STACK_EXISTS"
    read -p "Do you want to update the existing stack? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        ACTION="update"
    else
        log_info "Deployment cancelled"
        exit 0
    fi
else
    ACTION="create"
fi

# Deploy stack
if [ "$ACTION" == "create" ]; then
    log_info "Creating CloudFormation stack: $STACK_NAME"
    aws cloudformation create-stack \
        --stack-name $STACK_NAME \
        --template-body file://$TEMPLATE_FILE \
        --parameters file://$PARAMETERS_FILE \
        --capabilities CAPABILITY_IAM \
        --region $REGION \
        --tags Key=Project,Value=DjangoApp Key=Environment,Value=Production
else
    log_info "Updating CloudFormation stack: $STACK_NAME"
    aws cloudformation update-stack \
        --stack-name $STACK_NAME \
        --template-body file://$TEMPLATE_FILE \
        --parameters file://$PARAMETERS_FILE \
        --capabilities CAPABILITY_IAM \
        --region $REGION
fi

# Wait for stack operation to complete
log_info "Waiting for stack operation to complete..."
if [ "$ACTION" == "create" ]; then
    aws cloudformation wait stack-create-complete \
        --stack-name $STACK_NAME \
        --region $REGION
else
    aws cloudformation wait stack-update-complete \
        --stack-name $STACK_NAME \
        --region $REGION
fi

# Check final status
FINAL_STATUS=$(aws cloudformation describe-stacks \
    --stack-name $STACK_NAME \
    --region $REGION \
    --query 'Stacks[0].StackStatus' \
    --output text)

if [[ "$FINAL_STATUS" == *"COMPLETE"* ]]; then
    log_info "Stack operation completed successfully!"
    
    # Display outputs
    log_info "Stack Outputs:"
    aws cloudformation describe-stacks \
        --stack-name $STACK_NAME \
        --region $REGION \
        --query 'Stacks[0].Outputs[*].[OutputKey,OutputValue]' \
        --output table
        
    # Get ALB DNS name
    ALB_DNS=$(aws cloudformation describe-stacks \
        --stack-name $STACK_NAME \
        --region $REGION \
        --query 'Stacks[0].Outputs[?OutputKey==`ALBDNSName`].OutputValue' \
        --output text)
    
    log_info "Application will be available at: http://$ALB_DNS"
    log_info "Note: It may take a few minutes for the application to be fully ready."
    
else
    log_error "Stack operation failed with status: $FINAL_STATUS"
    
    # Show stack events for debugging
    log_info "Recent stack events:"
    aws cloudformation describe-stack-events \
        --stack-name $STACK_NAME \
        --region $REGION \
        --query 'StackEvents[0:10].[Timestamp,ResourceStatus,ResourceType,LogicalResourceId,ResourceStatusReason]' \
        --output table
    
    exit 1
fi