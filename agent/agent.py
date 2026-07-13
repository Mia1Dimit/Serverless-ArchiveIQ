import json
import boto3
from bedrock_agentcore.runtime import BedrockAgentCoreApp

app = BedrockAgentCoreApp()
bedrock = boto3.client("bedrock-runtime", region_name="eu-central-1")

@app.entrypoint
def handler(payload):
    s3_uri = payload.get("s3_uri", "")
    content = payload.get("content", "")

    if not content:
        return {"s3_uri": s3_uri, "category": "ERROR", "confidence": 0.0,
                "reasoning": "No content provided", "content_preview": ""}

    prompt = f"""Classify this document into ONE category:
- INVOICE: Sales invoices, billing documents
- CONTRACT: Agreements, legal contracts
- REPORT: Reports, analyses, summaries
- OTHER: Anything else

Document (first 1000 chars):
{content[:1000]}

Respond with ONLY valid JSON:
{{"category": "CATEGORY_NAME", "confidence": 0.95, "reasoning": "why"}}"""

    response = bedrock.invoke_model(
        modelId="anthropic.claude-haiku-4-5-20251001-v1:0",
        contentType="application/json",
        accept="application/json",
        body=json.dumps({
            "anthropic_version": "bedrock-2023-06-01",
            "max_tokens": 256,
            "messages": [{"role": "user", "content": prompt}]
        })
    )

    response_body = json.loads(response["body"].read().decode())
    classification = {"category": "OTHER", "confidence": 0.5, "reasoning": "Could not parse response"}

    if response_body.get("content"):
        text = response_body["content"][0]["text"]
        clean = text.strip().removeprefix("```json").removeprefix("```").removesuffix("```").strip()
        try:
            classification = json.loads(clean)
        except json.JSONDecodeError:
            pass

    return {
        "s3_uri": s3_uri,
        "category": classification.get("category", "OTHER"),
        "confidence": float(classification.get("confidence", 0.0)),
        "reasoning": classification.get("reasoning", ""),
        "content_preview": content[:500]
    }

if __name__ == "__main__":
    app.run()