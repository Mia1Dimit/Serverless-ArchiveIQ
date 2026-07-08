import json

def handler(payload, context):
    """
    AgentCore Runtime handler.
    Receives document content from Lambda and classifies it using Bedrock Claude.
    
    Args:
        payload: {
            "s3_uri": "s3://bucket/path/file.pdf",
            "content": "Document text content"
        }
        context: Lambda context object
        
    Returns:
        {
            "s3_uri": "s3://bucket/path/file.pdf",
            "category": "INVOICE|CONTRACT|REPORT|OTHER",
            "confidence": 0.0-1.0,
            "reasoning": "Brief explanation",
            "content_preview": "First 500 chars of content"
        }
    """
    # Import boto3 inside handler to avoid slow initialization during module loading
    import boto3
    bedrock = boto3.client("bedrock-runtime", region_name="eu-central-1")
    try:
        s3_uri = payload.get("s3_uri", "")
        content = payload.get("content", "")
        
        if not content:
            return {
                "s3_uri": s3_uri,
                "category": "ERROR",
                "confidence": 0.0,
                "reasoning": "No content provided",
                "content_preview": ""
            }
        
        # Prepare classification prompt
        classification_prompt = f"""You are a document classifier. Analyze the following document content and classify it.

DOCUMENT CONTENT:
{content[:2000]}

Classify this document into ONE of these categories:
- INVOICE: Sales invoices, billing statements
- CONTRACT: Agreements, contracts, terms
- REPORT: Reports, analysis, summaries
- OTHER: Anything else

Respond with ONLY valid JSON (no markdown, no extra text):
{{
    "category": "CATEGORY_NAME",
    "confidence": 0.95,
    "reasoning": "Brief explanation why"
}}"""

        # Invoke Bedrock Claude
        response = bedrock.invoke_model(
            modelId="anthropic.claude-haiku-4-5-20251001-v1:0",
            contentType="application/json",
            accept="application/json",
            body=json.dumps({
                "anthropic_version": "bedrock-2023-06-01",
                "max_tokens": 256,
                "messages": [
                    {
                        "role": "user",
                        "content": classification_prompt
                    }
                ]
            })
        )
        
        # Parse response
        response_body = json.loads(response["body"].read().decode("utf-8"))
        
        # Extract classification from Claude response
        if response_body.get("content") and len(response_body["content"]) > 0:
            response_text = response_body["content"][0]["text"]
            
            # Parse JSON from response
            try:
                clean = response_text.strip().removeprefix("```json").removeprefix("```").removesuffix("```").strip()
                classification = json.loads(clean)
            except json.JSONDecodeError:
                # Fallback if response isn't valid JSON
                classification = {
                    "category": "OTHER",
                    "confidence": 0.5,
                    "reasoning": "Could not parse response"
                }
        else:
            classification = {
                "category": "ERROR",
                "confidence": 0.0,
                "reasoning": "Empty response from model"
            }
        
        # Return structured result
        return {
            "s3_uri": s3_uri,
            "category": classification.get("category", "OTHER"),
            "confidence": float(classification.get("confidence", 0.0)),
            "reasoning": classification.get("reasoning", ""),
            "content_preview": content[:500]
        }
        
    except Exception as e:
        return {
            "s3_uri": payload.get("s3_uri", ""),
            "category": "ERROR",
            "confidence": 0.0,
            "reasoning": f"Classification failed: {str(e)}",
            "content_preview": ""
        }