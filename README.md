# Serverless ArchiveIQ

**Event-driven serverless platform for AI-powered document classification using AWS Bedrock AgentCore.**

Enterprise-grade infrastructure for automated document processing with full CI/CD automation, cost tracking, and compliance controls.

---

## Executive Summary

ArchiveIQ is a production-ready serverless application that classifies documents into categories (INVOICE, CONTRACT, REPORT, OTHER) using AWS Bedrock's Claude AI. The system is designed with infrastructure-as-code best practices, automated deployments, and comprehensive monitoring.

**Current Status**: ✅ Development environment deployed and tested  
**AWS Account**: `577638377042`  
**Primary Region**: `eu-central-1` (Bedrock availability)  
**Infrastructure Version**: Terraform 1.8.5+

---

## Architecture Overview

### Event-Driven Workflow
```
Document Upload → S3 Event → Lambda → Bedrock AgentCore → DynamoDB + S3 Results
```

### Core AWS Services

| Service | Purpose | Configuration | Owner |
|---------|---------|---|---|
| **S3** | Document ingestion & results archival | `archiveiq-documents-dev` bucket, versioning enabled | Platform |
| **Lambda** | Event processor & AgentCore orchestrator | 180s timeout, retry logic with exponential backoff | Platform |
| **Bedrock AgentCore** | AI model runtime for classification | Claude Haiku 4.5, PUBLIC network mode | Data Science |
| **DynamoDB** | Classification metadata storage | 30-day TTL for auto-cleanup | Platform |
| **IAM** | Least-privilege access control | Separate roles for Lambda and AgentCore | Security |
| **CloudWatch** | Logs & monitoring | All Lambda invocations logged | Platform |

### Regional Strategy

| Region | Purpose | Resources |
|--------|---------|-----------|
| `eu-central-1` | **Primary** (compute & AI) | Lambda, S3 (documents), Bedrock AgentCore, DynamoDB |
| `eu-west-1` | **State backend** | Terraform S3 bucket (`tfstates-577638377042-eu-west-1-an`), DynamoDB lock table |

---

## CI/CD Pipeline

### GitHub Actions Workflow (`terraform.yml`)

**Trigger Events:**
- Pull Request to `main` (branches `infra/**`, `modules/**`, `environments/**`)
- Push to `main` (same paths)
- Manual trigger via `workflow_dispatch`

### PR Checks (Plan Stage)
1. **Terraform Format Validation** - Enforces consistent code style
2. **Terraform Validate** - Syntax & provider compatibility checks
3. **Agent Build** - Compiles Python agent package for aarch64 (ARM64)
4. **Terraform Plan** - Generates execution plan with Infracost diff
5. **PR Comment** - Posts plan summary for review

**Artifacts**: Plan file + text export (5-day retention)

### Main Branch (Apply Stage)
1. **Agent Build & Deployment** 
   - Compiles agent to aarch64 binary
   - Uploads zip to S3: `archiveiq-agentcore-runtime-dev/agent/archiveiq-agent.zip`
   - Updates Bedrock AgentCore runtime via `bedrock-agentcore-control`
2. **Terraform Apply** - Auto-applies validated infrastructure changes
3. **State Locking** - Uses DynamoDB for concurrent operation safety (5m lock timeout)

**Concurrency Control**: Only one terraform operation per branch at a time

---

## Infrastructure as Code (IaC)

### Terraform Structure

```
infra/
  ├── terraform.tf              # AWS provider config (eu-central-1, v6.4)
  ├── backend.tf                # S3 + DynamoDB state backend
  ├── variables.tf              # Input variable schema
  ├── iam.tf                    # IAM role instantiation
  ├── s3.tf                     # S3 bucket instantiation
  ├── agent-runtime.tf          # Bedrock AgentCore runtime
  ├── lambda-function.tf        # Lambda instantiation
  ├── lambda-permission.tf      # S3 → Lambda trigger permissions
  ├── dynamodb.tf               # DynamoDB table definition
  ├── data/iam_role_policies/   # JSON policy documents
  │   ├── lambda-assume-role-policy.json
  │   ├── lambda-execution-policy.json
  │   ├── bedrock-agent-runtime-assume-role-policy.json
  │   └── bedrock-agent-runtime-policy.json
  └── modules/                  # Reusable modules
      ├── iam-role/
      ├── iam-policy/
      ├── iam-role-policy/
      ├── lambda-function/
      ├── bedrockagentcore-agent-runtime/
      ├── s3-bucket/
      ├── s3-bucket-notification/
      └── dynamodb/

environments/
  └── dev.tfvars                # Development variable values
  └── (staging.tfvars, prod.tfvars available for expansion)
```

### Modular Design
- **Terraform Modules**: Reusable components for IAM, Lambda, S3, DynamoDB, Bedrock
- **Policy as Code**: JSON policies version-controlled in `data/` directory
- **Environment Separation**: `dev.tfvars` supports future staging/prod environments
- **Default Tags**: All resources tagged with `managed_by = "Terraform"`

### State Management
- **Backend**: S3 bucket in `eu-west-1` with DynamoDB state lock
- **Locking**: Prevents concurrent modifications
- **Versioning**: S3 versioning enabled for state history

---

## Security & IAM

### Lambda Execution Role (`lambda_execution`)
**Trust**: `lambda.amazonaws.com`  
**Permissions**:
- S3: GetObject, PutObject, ListBucket (all buckets)
- DynamoDB: GetItem, PutItem, UpdateItem, Query, Scan (all tables)
- Bedrock: InvokeAgent
- CloudWatch Logs: CreateLogGroup, CreateLogStream, PutLogEvents

### Bedrock AgentCore Runtime Role (`bedrock_agent_runtime`)
**Trust**: `bedrock.amazonaws.com`  
**Permissions**:
- Bedrock: InvokeModel, InvokeModelWithResponseStream
- S3: Full access (knowledge base documents, results)
- DynamoDB: Full access (agent state/results)
- CloudWatch Logs: Full access

**Security Controls**:
- ✅ Least-privilege roles (minimal scoped permissions)
- ✅ Separate roles per service
- ✅ S3 public access blocked (all 4 settings disabled)
- ✅ Bucket ownership controls enforced (BucketOwnerEnforced)
- ✅ Versioning enabled on document buckets
- ✅ No hardcoded credentials (IAM roles only)

---

## Deployment & Operations

### Prerequisites
```bash
Terraform  1.8.5+
Python     3.12
AWS CLI    v2
AWS Creds  (env vars: AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY)
```

### Quick Deploy

```bash
cd infra
terraform init \
  -backend-config="bucket=tfstates-577638377042-eu-west-1-an" \
  -backend-config="key=serverless-archiveiq/dev/terraform.tfstate" \
  -backend-config="region=eu-west-1" \
  -backend-config="dynamodb_table=tfstates-ddb-tfstatelock"

terraform apply -var-file=../environments/dev.tfvars
```

### Testing
```bash
cd QA
bash quick_test.sh invoice        # Single document test
bash run_tests.sh                 # Full suite (INVOICE, CONTRACT, REPORT, OTHER)
```

### Local Development
1. Create feature branch: `git checkout -b feature/my-feature`
2. Make changes to `infra/`, `agent/`, or `lambda/`
3. Test changes: Run quick_test.sh or local terraform plan
4. Push and create PR
5. Merge to main after approval (auto-deploys via GitHub Actions)

---

## Cost Management

### Infracost Integration
- **Automated Diff**: PR comments show estimated cost impact
- **Plan Review**: Team reviews cost before merge
- **Tracking**: Infracost API tracks historical spend (`secrets.INFRACOST_API_KEY`)

### Estimated Monthly Costs (Dev)
- **Lambda**: ~$0.20 (1M free tier + minimal invocations)
- **Bedrock**: ~$0.50 (pay-per-token for Claude Haiku)
- **DynamoDB**: ~$1.25 (on-demand, 30-day TTL auto-cleanup)
- **S3**: ~$0.02 (minimal storage + versioning)
- **Total**: <$5/month for dev environment

---

## Monitoring & Observability

### Logging
- **Lambda Logs**: CloudWatch Logs group auto-created
- **AgentCore Logs**: Bedrock logs to CloudWatch
- **Retention**: 30 days (configurable)

### Recommended Alerts (TODO)
- Lambda error rate > 5%
- AgentCore timeout events
- DynamoDB throttling
- S3 bucket size growth

### Metrics
- Lambda duration (p50, p95, p99)
- AgentCore classification latency
- Document processing throughput
- Cost per document classified

---

## Roadmap & Known Limitations

### Known Constraints
- **Bedrock Init Latency**: PUBLIC mode takes 30+ seconds (AWS hard limit)
- **Cold Starts**: First 5 minutes requires retry logic; subsequent calls <5s
- **Region Lock**: eu-central-1 only (Bedrock region availability)
- **Batch Size**: Currently 1 document per Lambda invocation (future: batch processing)

### Future Enhancements
- [ ] Staging & production environments (`staging.tfvars`, `prod.tfvars`)
- [ ] API Gateway for results retrieval
- [ ] CloudWatch dashboards & alarms
- [ ] Document chunking for larger files (>2000 chars)
- [ ] Batch processing (SQS → Lambda)
- [ ] VPC endpoints for private connectivity
- [ ] Custom metrics dashboard
- [ ] Disaster recovery / multi-region failover

---

## Project Structure

```
├── agent/                           # Bedrock AgentCore runtime
│   ├── agent.py                    # Classification handler (Claude Haiku 4.5)
│   ├── requirements.txt             # Dependencies (boto3, bedrock-agentcore)
│   └── archiveiq-agent.zip         # Build artifact (auto-generated by CI/CD)
├── lambda/                          # Lambda function
│   └── handler.py                  # S3 event processor, retry orchestrator
├── infra/                           # Terraform infrastructure
│   ├── terraform.tf                # AWS provider & version constraints
│   ├── backend.tf                  # State backend config
│   ├── variables.tf                # Input schemas
│   ├── iam.tf                      # IAM roles/policies
│   ├── s3.tf                       # S3 buckets
│   ├── dynamodb.tf                 # DynamoDB tables
│   ├── lambda-function.tf          # Lambda resource
│   ├── lambda-permission.tf        # S3 → Lambda trigger
│   ├── agent-runtime.tf            # Bedrock AgentCore runtime
│   ├── data/iam_role_policies/     # JSON policy documents
│   └── modules/                    # Reusable IaC modules
├── modules/                         # Shared Terraform modules (can be versioned separately)
├── environments/                    # Environment-specific variables
│   └── dev.tfvars                  # Development variables
├── .github/workflows/               # CI/CD pipeline
│   └── terraform.yml               # GitHub Actions workflow
├── QA/                              # Testing suite
│   ├── quick_test.sh               # Single-doc test
│   ├── run_tests.sh                # Full test suite
│   └── test_documents/             # Sample documents
├── PROJECT_SETUP.md                # Detailed setup reference
└── README.md                        # This file
```

---

## Development Workflow

### Making Infrastructure Changes

1. **Create Feature Branch**
   ```bash
   git checkout -b feature/add-api-gateway
   ```

2. **Modify Terraform**
   ```bash
   # Edit infra/ or modules/
   terraform -chdir=infra fmt
   terraform -chdir=infra validate
   terraform -chdir=infra plan -var-file=../environments/dev.tfvars
   ```

3. **Push & Create PR**
   ```bash
   git push origin feature/add-api-gateway
   ```
   → GitHub Actions runs plan, validates, posts Infracost diff

4. **Merge to Main**
   → GitHub Actions auto-applies changes, builds & deploys agent

5. **Monitor Deployment**
   ```bash
   aws cloudformation describe-stack-events --stack-name archiveiq-dev
   # or check CloudWatch logs for Lambda/Bedrock
   ```

### Adding New Environments (Staging/Prod)

1. Create `environments/staging.tfvars` with new variable values
2. Update CI/CD workflow to support multiple environments
3. Create separate Bedrock AgentCore runtime per environment
4. Update terraform state key: `serverless-archiveiq/staging/terraform.tfstate`

---

## Support & Escalations

- **Infrastructure Issues**: Check CloudWatch Logs, terraform state consistency
- **Agent Classification Errors**: Review CloudWatch logs for prompt/model issues
- **AWS Service Limits**: Monitor EC2 limits, API throttling, DynamoDB capacity
- **Cost Overruns**: Review Infracost reports, optimize Lambda concurrency/DynamoDB capacity

---

## Documentation References

- [PROJECT_SETUP.md](PROJECT_SETUP.md) — Detailed architecture & setup steps
- [AWS Bedrock AgentCore Docs](https://docs.aws.amazon.com/bedrock/latest/userguide/agents.html)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [GitHub Actions Best Practices](https://docs.github.com/en/actions/learn-github-actions/workflow-syntax-for-github-actions)  
✅ AgentCore runtime with deferred imports  
✅ Lambda with 3-retry backoff strategy  
⚠️ AgentCore 30s initialization limit requires mitigation