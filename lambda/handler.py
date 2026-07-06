import json
import logging
import os
from datetime import datetime, timezone, timedelta
from urllib.parse import unquote_plus

import boto3

logger = logging.getLogger()
logger.setLevel(logging.INFO)

s3 = boto3.client("s3")
dynamodb = boto3.resource("dynamodb")
agentcore = boto3.client("bedrock-agentcore", region_name=os.environ.get("REGION", "eu-central-1"))

AGENTCORE_RUNTIME_ARN = os.environ["AGENTCORE_RUNTIME_ARN"]
RESULTS_BUCKET = os.environ["RESULTS_BUCKET"]
DYNAMODB_TABLE = os.environ["DYNAMODB_TABLE"]
MAX_CONTENT_CHARS = int(os.environ.get("MAX_CONTENT_CHARS", "2000"))


def handler(event, context):
    records = event.get("Records", [])
    results = []

    for record in records:
        result = process_record(record)
        results.append(result)

    logger.info("Processed %d record(s)", len(results))
    return {"statusCode": 200, "body": json.dumps(results)}


def process_record(record):
    bucket = record["s3"]["bucket"]["name"]
    key = unquote_plus(record["s3"]["object"]["key"])
    s3_uri = f"s3://{bucket}/{key}"

    logger.info("Processing: %s", s3_uri)

    try:
        # 1. Read document from S3
        content = read_s3_object(bucket, key)

        # 2. Invoke AgentCore Runtime
        classification = invoke_agentcore(s3_uri, content)

        # 3. Write result JSON to results S3 bucket
        result_key = f"{key}.json"
        result_uri = f"s3://{RESULTS_BUCKET}/{result_key}"
        write_result_to_s3(result_key, classification)

        # 4. Write metadata record to DynamoDB
        write_to_dynamodb(
            document_id=key,
            s3_uri=s3_uri,
            result_uri=result_uri,
            classification=classification,
            status="SUCCESS",
        )

        logger.info("Successfully classified %s as %s", key, classification.get("category"))
        return {"document_id": key, "status": "SUCCESS", "category": classification.get("category")}

    except Exception as e:
        logger.exception("Failed to process %s: %s", key, str(e))

        write_to_dynamodb(
            document_id=key,
            s3_uri=s3_uri,
            result_uri=None,
            classification={"category": "ERROR", "confidence": 0.0, "reasoning": str(e)},
            status="ERROR",
        )

        return {"document_id": key, "status": "ERROR", "error": str(e)}


def read_s3_object(bucket, key):
    response = s3.get_object(Bucket=bucket, Key=key)
    content = response["Body"].read().decode("utf-8", errors="ignore")
    return content[:MAX_CONTENT_CHARS]


def invoke_agentcore(s3_uri, content):
    payload = json.dumps({"s3_uri": s3_uri, "content": content})

    response = agentcore.invoke_agent_runtime(
        agentRuntimeArn=AGENTCORE_RUNTIME_ARN,
        body=payload,
        contentType="application/json",
        accept="application/json",
    )

    response_body = response["body"].read().decode("utf-8")
    return json.loads(response_body)


def write_result_to_s3(result_key, classification):
    s3.put_object(
        Bucket=RESULTS_BUCKET,
        Key=result_key,
        Body=json.dumps(classification, indent=2),
        ContentType="application/json",
    )


def write_to_dynamodb(document_id, s3_uri, result_uri, classification, status):
    table = dynamodb.Table(DYNAMODB_TABLE)

    # Calculate TTL: 30 days from now in Unix timestamp
    expires_at = int((datetime.now(timezone.utc) + timedelta(days=30)).timestamp())

    item = {
        "document_id": document_id,
        "s3_uri": s3_uri,
        "category": classification.get("category", "UNKNOWN"),
        "confidence": str(classification.get("confidence", 0.0)),
        "reasoning": classification.get("reasoning", ""),
        "classified_at": datetime.now(timezone.utc).isoformat(),
        "status": status,
        "expires_at": expires_at,
    }

    if result_uri:
        item["result_uri"] = result_uri

    table.put_item(Item=item)
