#!/bin/bash
# ============================================================================
# Quick Test - Single Document Classification
# ============================================================================
# Minimal test: upload one document and verify result
# Usage: ./quick_test.sh [invoice|contract|report|other]
# ============================================================================

REGION="eu-central-1"
DOCUMENTS_BUCKET="archiveiq-documents-dev"
RESULTS_BUCKET="archiveiq-results-dev"
DYNAMODB_TABLE="archiveiq-classifications-dev"

# Default to invoice
DOC_TYPE="${1:-invoice}"

if [ ! -f "test_documents/$DOC_TYPE.txt" ]; then
  echo "Document type not found: test_documents/$DOC_TYPE.txt"
  echo "Available types: invoice, contract, report, other"
  exit 1
fi

TIMESTAMP=$(date +%s)
DOC_KEY="test_${DOC_TYPE}_${TIMESTAMP}.txt"

echo "Uploading $DOC_TYPE document ($DOC_KEY)..."
aws s3 cp "test_documents/$DOC_TYPE.txt" "s3://$DOCUMENTS_BUCKET/documents/$DOC_KEY" --region $REGION

echo "Waiting for processing (15 seconds)..."
sleep 15

echo ""
echo "=== DynamoDB Results ==="
aws dynamodb scan --table-name $DYNAMODB_TABLE --region $REGION \
  --filter-expression "begins_with(document_id, :prefix)" \
  --expression-attribute-values "{\":prefix\": {\"S\": \"test_$DOC_TYPE\"}}" \
  --output json | jq '.Items[] | {document_id: .document_id.S, category: .category.S, confidence: .confidence.N, reasoning: .reasoning.S}' | head -1

echo ""
echo "=== S3 Results ==="
aws s3 ls "s3://$RESULTS_BUCKET/documents/" --region $REGION | grep "$DOC_TYPE"

echo ""
echo "=== Download & View Result ==="
RESULT_FILE=$(aws s3 ls "s3://$RESULTS_BUCKET/documents/" --region $REGION | grep "$DOC_TYPE" | awk '{print $NF}' | head -1)
if [ ! -z "$RESULT_FILE" ]; then
  aws s3 cp "s3://$RESULTS_BUCKET/documents/$RESULT_FILE" "/tmp/$RESULT_FILE" --region $REGION
  echo "Result for $RESULT_FILE:"
  jq . "/tmp/$RESULT_FILE"
fi
