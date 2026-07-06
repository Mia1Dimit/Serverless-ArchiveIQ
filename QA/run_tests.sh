#!/bin/bash
# ============================================================================
# ArchiveIQ End-to-End Test Suite
# ============================================================================
# This script tests the complete document classification pipeline:
# 1. Upload document to S3 (documents bucket)
# 2. Lambda processes and invokes AgentCore
# 3. Results written to S3 (results bucket) and DynamoDB
# ============================================================================

set -e

REGION="eu-central-1"
DOCUMENTS_BUCKET="archiveiq-documents-dev"
RESULTS_BUCKET="archiveiq-results-dev"
DYNAMODB_TABLE="archiveiq-classifications-dev"
LAMBDA_FUNCTION="archiveiq-document-processor-dev"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}========== ArchiveIQ E2E Test Suite ==========${NC}"
echo "Region: $REGION"
echo "Timestamp: $(date)"
echo ""

# ============================================================================
# Test 1: Verify AWS Credentials & Access
# ============================================================================
echo -e "${YELLOW}[TEST 1] Verifying AWS credentials...${NC}"
aws sts get-caller-identity --region $REGION > /dev/null 2>&1 && \
  echo -e "${GREEN}✓ AWS credentials valid${NC}" || \
  { echo -e "${RED}✗ AWS credentials failed${NC}"; exit 1; }
echo ""

# ============================================================================
# Test 2: Verify Infrastructure Exists
# ============================================================================
echo -e "${YELLOW}[TEST 2] Verifying infrastructure...${NC}"

# Check S3 buckets
aws s3api head-bucket --bucket $DOCUMENTS_BUCKET --region $REGION > /dev/null 2>&1 && \
  echo -e "${GREEN}✓ Documents bucket exists${NC}" || \
  { echo -e "${RED}✗ Documents bucket not found${NC}"; exit 1; }

aws s3api head-bucket --bucket $RESULTS_BUCKET --region $REGION > /dev/null 2>&1 && \
  echo -e "${GREEN}✓ Results bucket exists${NC}" || \
  { echo -e "${RED}✗ Results bucket not found${NC}"; exit 1; }

# Check Lambda function
aws lambda get-function --function-name $LAMBDA_FUNCTION --region $REGION > /dev/null 2>&1 && \
  echo -e "${GREEN}✓ Lambda function exists${NC}" || \
  { echo -e "${RED}✗ Lambda function not found${NC}"; exit 1; }

# Check DynamoDB table
aws dynamodb describe-table --table-name $DYNAMODB_TABLE --region $REGION > /dev/null 2>&1 && \
  echo -e "${GREEN}✓ DynamoDB table exists${NC}" || \
  { echo -e "${RED}✗ DynamoDB table not found${NC}"; exit 1; }

echo ""

# ============================================================================
# Test 3: Upload Test Documents
# ============================================================================
echo -e "${YELLOW}[TEST 3] Uploading test documents...${NC}"

TIMESTAMP=$(date +%s)
TESTS_PASSED=0
TESTS_FAILED=0

# Invoice test
echo "Uploading INVOICE document..."
aws s3 cp QA/test_documents/invoice.txt "s3://$DOCUMENTS_BUCKET/documents/test_invoice_$TIMESTAMP.txt" --region $REGION && \
  { echo -e "${GREEN}✓ Invoice uploaded${NC}"; TESTS_PASSED=$((TESTS_PASSED+1)); } || \
  { echo -e "${RED}✗ Invoice upload failed${NC}"; TESTS_FAILED=$((TESTS_FAILED+1)); }

# Contract test
echo "Uploading CONTRACT document..."
aws s3 cp QA/test_documents/contract.txt "s3://$DOCUMENTS_BUCKET/documents/test_contract_$TIMESTAMP.txt" --region $REGION && \
  { echo -e "${GREEN}✓ Contract uploaded${NC}"; TESTS_PASSED=$((TESTS_PASSED+1)); } || \
  { echo -e "${RED}✗ Contract upload failed${NC}"; TESTS_FAILED=$((TESTS_FAILED+1)); }

# Report test
echo "Uploading REPORT document..."
aws s3 cp QA/test_documents/report.txt "s3://$DOCUMENTS_BUCKET/documents/test_report_$TIMESTAMP.txt" --region $REGION && \
  { echo -e "${GREEN}✓ Report uploaded${NC}"; TESTS_PASSED=$((TESTS_PASSED+1)); } || \
  { echo -e "${RED}✗ Report upload failed${NC}"; TESTS_FAILED=$((TESTS_FAILED+1)); }

echo ""

# ============================================================================
# Test 4: Wait for Lambda Processing
# ============================================================================
echo -e "${YELLOW}[TEST 4] Waiting for Lambda processing (15 seconds)...${NC}"
sleep 15
echo -e "${GREEN}✓ Processing window elapsed${NC}"
echo ""

# ============================================================================
# Test 5: Verify DynamoDB Entries
# ============================================================================
echo -e "${YELLOW}[TEST 5] Checking DynamoDB for classifications...${NC}"

DYNAMODB_ITEMS=$(aws dynamodb scan --table-name $DYNAMODB_TABLE --region $REGION --output json)
ITEM_COUNT=$(echo "$DYNAMODB_ITEMS" | jq '.Items | length')

if [ "$ITEM_COUNT" -gt 0 ]; then
  echo -e "${GREEN}✓ Found $ITEM_COUNT classification(s) in DynamoDB${NC}"
  echo "$DYNAMODB_ITEMS" | jq '.Items[] | {document_id: .document_id.S, category: .category.S, confidence: .confidence.N}' | head -20
  TESTS_PASSED=$((TESTS_PASSED+1))
else
  echo -e "${RED}✗ No classifications found in DynamoDB${NC}"
  TESTS_FAILED=$((TESTS_FAILED+1))
fi
echo ""

# ============================================================================
# Test 6: Verify S3 Results
# ============================================================================
echo -e "${YELLOW}[TEST 6] Checking S3 results bucket...${NC}"

RESULTS=$(aws s3api list-objects-v2 --bucket $RESULTS_BUCKET --prefix "documents/" --region $REGION --output json)
RESULT_COUNT=$(echo "$RESULTS" | jq '.Contents | length')

if [ "$RESULT_COUNT" -gt 0 ]; then
  echo -e "${GREEN}✓ Found $RESULT_COUNT result file(s) in S3${NC}"
  echo "$RESULTS" | jq '.Contents[] | {key: .Key, size: .Size, modified: .LastModified}' | head -10
  TESTS_PASSED=$((TESTS_PASSED+1))
else
  echo -e "${RED}✗ No results found in S3${NC}"
  TESTS_FAILED=$((TESTS_FAILED+1))
fi
echo ""

# ============================================================================
# Test 7: Check Lambda CloudWatch Logs
# ============================================================================
echo -e "${YELLOW}[TEST 7] Checking Lambda CloudWatch logs...${NC}"

LOGS=$(aws logs tail "/aws/lambda/$LAMBDA_FUNCTION" --region $REGION --since 15m --max-items 20 2>/dev/null || echo "")

if [ -z "$LOGS" ]; then
  echo -e "${YELLOW}⚠ No recent logs found (Lambda may not have invoked yet)${NC}"
  TESTS_FAILED=$((TESTS_FAILED+1))
else
  echo -e "${GREEN}✓ Found Lambda logs:${NC}"
  echo "$LOGS" | tail -10
  TESTS_PASSED=$((TESTS_PASSED+1))
fi
echo ""

# ============================================================================
# Summary
# ============================================================================
echo -e "${YELLOW}========== Test Summary ==========${NC}"
echo -e "${GREEN}Passed: $TESTS_PASSED${NC}"
echo -e "${RED}Failed: $TESTS_FAILED${NC}"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
  echo -e "${GREEN}✓ All tests passed!${NC}"
  exit 0
else
  echo -e "${RED}✗ Some tests failed. Check logs above.${NC}"
  exit 1
fi
