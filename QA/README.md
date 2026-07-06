# ArchiveIQ QA - Test Suite

Automated testing for the ArchiveIQ document classification pipeline.

## Prerequisites

- AWS CLI v2.x configured with credentials for account 577638377042
- bash shell (Linux/Mac) or WSL2 (Windows)
- jq for JSON parsing
- Infrastructure deployed (S3 buckets, Lambda, DynamoDB, AgentCore runtime)

## Quick Start

```bash
# Make test script executable
chmod +x run_tests.sh

# Run all tests
./run_tests.sh
```

## Test Suite

### Test 1: AWS Credentials Verification
- Verifies AWS CLI is configured and authenticated
- Checks caller identity matches expected AWS account

### Test 2: Infrastructure Validation
- Verifies S3 buckets exist (documents, results)
- Verifies Lambda function exists
- Verifies DynamoDB table exists
- **MUST PASS** before proceeding with other tests

### Test 3: Document Upload
- Uploads 4 sample test documents to S3 documents bucket:
  - `invoice.txt` → Expected classification: INVOICE
  - `contract.txt` → Expected classification: CONTRACT
  - `report.txt` → Expected classification: REPORT
  - `other.txt` → Expected classification: OTHER

### Test 4: Lambda Processing
- Waits 15 seconds for S3 event → Lambda invocation → AgentCore classification
- Timing accounts for event propagation, cold start, and AgentCore runtime

### Test 5: DynamoDB Verification
- Scans DynamoDB table for classification results
- Displays document_id, category, and confidence for each result
- **Should show 3+ items** (one per uploaded document)

### Test 6: S3 Results Verification
- Lists result JSON files in results bucket
- **Should show 3+ files** (one per uploaded document)

### Test 7: CloudWatch Logs Review
- Retrieves recent Lambda execution logs
- Shows errors, execution time, and classification results

## Test Documents

Located in `QA/test_documents/`:

### invoice.txt
- Category: INVOICE
- Contains invoice number, date, amount, payment terms
- Real-world invoice document

### contract.txt
- Category: CONTRACT
- Service agreement with standard legal clauses
- Signature blocks and terms

### report.txt
- Category: REPORT
- Quarterly business performance report
- Metrics, analysis, and outlook

### other.txt
- Category: OTHER
- Email/miscellaneous communication
- Not a formal financial/legal document

## Expected Results

**All tests pass when:**
- Infrastructure exists and is accessible
- Each uploaded document triggers Lambda invocation
- AgentCore returns classification (INVOICE|CONTRACT|REPORT|OTHER)
- Results appear in DynamoDB within 15 seconds
- Result JSON files appear in S3 results bucket
- CloudWatch logs show successful execution

**Success Criteria:**
- Test 1: PASS (AWS access verified)
- Test 2: PASS (all infrastructure present)
- Test 3: PASS (3 documents uploaded)
- Test 4: PASS (processing window elapsed)
- Test 5: PASS (3+ DynamoDB items)
- Test 6: PASS (3+ S3 result files)
- Test 7: PASS (recent CloudWatch logs)

## Troubleshooting

### No DynamoDB items or S3 results
1. Check Lambda was invoked: `aws lambda get-function-concurrency --function-name archiveiq-document-processor-dev --region eu-central-1`
2. Check Lambda logs: `aws logs tail /aws/lambda/archiveiq-document-processor-dev --region eu-central-1 --since 5m`
3. Verify S3 event notification: `aws s3api get-bucket-notification-configuration --bucket archiveiq-documents-dev --region eu-central-1`

### Lambda execution errors
- Check AgentCore runtime is deployed: `aws bedrock-agentcore get-agent-runtime --agent-runtime-identifier archiveiq_agent_classifier_dev --region eu-central-1`
- Verify Lambda IAM role has permissions for AgentCore: `aws iam get-role-policy --role-name archiveiq-lambda-execution-dev --policy-name --region eu-central-1`
- Check Lambda environment variables: `aws lambda get-function-configuration --function-name archiveiq-document-processor-dev --region eu-central-1`

### Slow results
- AgentCore runtime may be cold-starting (first invocation)
- Increase wait time in Test 4 from 15s to 30s for slower environments
- CloudWatch logs will show runtime initialization time

## Manual Testing Commands

```bash
# Upload a single document
aws s3 cp test_documents/invoice.txt s3://archiveiq-documents-dev/documents/my-invoice.txt --region eu-central-1

# Check DynamoDB results
aws dynamodb scan --table-name archiveiq-classifications-dev --region eu-central-1 --output table

# Get latest Lambda logs
aws logs tail /aws/lambda/archiveiq-document-processor-dev --follow --region eu-central-1

# Download a result JSON
aws s3 cp s3://archiveiq-results-dev/documents/my-invoice.json ./my-invoice.json --region eu-central-1
cat my-invoice.json | jq .

# Check S3 notification configuration
aws s3api get-bucket-notification-configuration --bucket archiveiq-documents-dev --region eu-central-1
```

## Cleanup

Remove test data after testing:

```bash
# Empty documents bucket
aws s3 rm s3://archiveiq-documents-dev/documents/ --recursive --region eu-central-1

# Empty results bucket
aws s3 rm s3://archiveiq-results-dev/documents/ --recursive --region eu-central-1

# Clear DynamoDB (optional - data auto-expires after 30 days)
aws dynamodb delete-table --table-name archiveiq-classifications-dev --region eu-central-1
```

## Performance Expectations

| Metric | Expected | Notes |
|--------|----------|-------|
| Document Upload | <1s | S3 PutObject |
| Lambda Invocation | <2s | Event propagation + cold start |
| AgentCore Classification | 2-5s | Bedrock API latency |
| Result in S3 | <15s | Total E2E time |
| Result in DynamoDB | <15s | Total E2E time |
| CloudWatch logs | <5s | After execution |

## Continuous Integration

To integrate with GitHub Actions:

```yaml
- name: Run QA Tests
  run: |
    cd QA
    chmod +x run_tests.sh
    ./run_tests.sh
  env:
    AWS_REGION: eu-central-1
    AWS_DEFAULT_REGION: eu-central-1
```

---

**Last Updated:** July 6, 2026  
**Author:** ArchiveIQ Team
