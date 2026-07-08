# Serverless ArchiveIQ

Serverless document classification system using AWS Lambda and Bedrock AgentCore.

## Overview

ArchiveIQ automatically classifies documents into categories (INVOICE, CONTRACT, REPORT, OTHER) using AI-powered analysis. Documents are uploaded to S3, processed by Lambda, classified via Bedrock AgentCore, and results are stored in DynamoDB and S3.

## Architecture

- **S3**: Document input bucket with Lambda event notifications
- **Lambda**: Processes S3 events, invokes AgentCore runtime with retry logic (180s timeout)
- **Bedrock AgentCore**: AI runtime for document classification (PUBLIC mode)
- **DynamoDB**: Stores classification metadata with TTL (30-day expiration)
- **IAM**: Least-privilege roles with proper trust policies

## Quick Start

### Prerequisites
- AWS Account (eu-central-1)
- Terraform 1.8.5+
- Python 3.12
- AWS CLI

### Deploy

```bash
cd infra
terraform init -reconfigure \
  -backend-config="bucket=tfstates-577638377042-eu-west-1-an" \
  -backend-config="key=serverless-archiveiq/dev/terraform.tfstate" \
  -backend-config="region=eu-west-1" \
  -backend-config="dynamodb_table=tfstates-ddb-tfstatelock"

terraform apply -var-file=../environments/dev.tfvars
```

### Test

```bash
cd QA
bash quick_test.sh invoice   # Single document test
bash run_tests.sh            # Full test suite (4 document types)
```

## Project Structure

```
├── agent/                 # Bedrock AgentCore runtime
│   ├── agent.py          # Classification handler
│   ├── requirements.txt   # Dependencies
│   └── build.py          # Build & upload to S3
├── lambda/               # Lambda function
│   └── handler.py        # S3 event processor with retry logic
├── infra/                # Terraform infrastructure
│   ├── terraform.tf      # Provider & backend config
│   ├── variables.tf      # Input schemas
│   ├── *.tf              # Resource definitions
│   └── modules/          # Reusable Terraform modules
├── environments/         # Environment configurations
│   └── dev.tfvars        # Development variable values
├── .github/workflows/    # CI/CD pipeline
│   └── terraform.yml     # Plan on PR, apply on main
└── QA/                   # Testing suite
    ├── quick_test.sh     # Single document test
    ├── run_tests.sh      # Full test suite
    └── test_documents/   # Sample documents
```

## Key Features

- **Automatic Retries**: 3 attempts with exponential backoff (5s, 30s) for cold starts
- **Extended Timeout**: 180s Lambda timeout accommodates AgentCore initialization
- **Auto-cleanup**: DynamoDB TTL expires classifications after 30 days
- **IAM Least Privilege**: Separate roles (Lambda, AgentCore) with minimal permissions
- **Terraform Modules**: Reusable modules from Terraform-modules repository
- **GitHub Actions CI/CD**: Validates and auto-deploys infrastructure

## Known Limitations

- **AgentCore Init Timeout**: PUBLIC mode takes 30+ seconds (AWS hard limit)
- **Cold Starts**: First ~5 min requires retries; subsequent calls are fast
- **Region**: eu-central-1 only (Bedrock availability)

## Development

1. Branch: `git checkout -b feature/my-feature`
2. Test: `cd QA && bash quick_test.sh invoice`
3. Build agent: `cd agent && python build.py`
4. Deploy: `cd infra && terraform apply -var-file=../environments/dev.tfvars`

## CI/CD

GitHub Actions (`terraform.yml`):
- **PR**: Runs terraform plan, validate, and Infracost diff
- **Main**: Builds agent package and auto-applies terraform

## Status

✅ Infrastructure deployed and tested  
✅ AgentCore runtime with deferred imports  
✅ Lambda with 3-retry backoff strategy  
⚠️ AgentCore 30s initialization limit requires mitigation