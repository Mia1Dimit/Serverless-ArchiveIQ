#!/usr/bin/env python3
"""
ArchiveIQ AgentCore Runtime Handler
Document classification via Bedrock Claude API over HTTP

30-second startup limitation: Currently unable to meet AgentCore's 30-second
initialization window with Python. All approaches (frameworks, stdlib, minimal)
exceed timeout. Consider alternative:
- Use container-based runtime instead of Python code
- Use faster startup language (Node.js, Go, etc.)
"""

import json
import threading
from http.server import HTTPServer, BaseHTTPRequestHandler

_bedrock = None

def get_bedrock():
    """Lazily initialize Bedrock client on first request"""
    global _bedrock
    if _bedrock is None:
        import boto3
        _bedrock = boto3.client("bedrock-runtime", region_name="eu-central-1")
    return _bedrock

class RequestHandler(BaseHTTPRequestHandler):
    """HTTP handler for /ping health check and /invocations classification"""
    
    def log_message(self, format, *args):
        pass  # Suppress default logging
    
    def do_GET(self):
        if self.path == "/ping":
            self.send_response(200)
            self.send_header("Content-type", "application/json")
            self.end_headers()
            self.wfile.write(json.dumps({"status": "healthy"}).encode())
        else:
            self.send_error(404)
    
    def do_POST(self):
        if self.path == "/invocations":
            try:
                content_length = int(self.headers.get("Content-Length", 0))
                payload = json.loads(self.rfile.read(content_length).decode())
                result = handle_classification(payload)
                self.send_response(200)
                self.send_header("Content-type", "application/json")
                self.end_headers()
                self.wfile.write(json.dumps(result).encode())
            except Exception as e:
                self.send_response(500)
                self.send_header("Content-type", "application/json")
                self.end_headers()
                self.wfile.write(json.dumps({
                    "error": str(e),
                    "category": "ERROR",
                    "confidence": 0.0,
                    "reasoning": f"Invocation error: {str(e)}"
                }).encode())
        else:
            self.send_error(404)

def handle_classification(payload):
    """Classify document using Bedrock Claude"""
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
        
        # Classification prompt
        prompt = f"""Classify this document into ONE category:
- INVOICE: Sales invoices, billing documents
- CONTRACT: Agreements, legal contracts  
- REPORT: Reports, analyses, summaries
- OTHER: Anything else

Document (first 1000 chars):
{content[:1000]}

Respond with ONLY valid JSON:
{{"category": "CATEGORY_NAME", "confidence": 0.95, "reasoning": "why"}}"""
        
        bedrock = get_bedrock()
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
        classification = {"category": "ERROR", "confidence": 0.0, "reasoning": "Empty"}
        
        if response_body.get("content"):
            response_text = response_body["content"][0]["text"]
            try:
                clean = response_text.strip().removeprefix("```json").removeprefix("```").removesuffix("```").strip()
                classification = json.loads(clean)
            except:
                pass
        
        return {
            "s3_uri": s3_uri,
            "category": classification.get("category", "OTHER"),
            "confidence": float(classification.get("confidence", 0.0)),
            "reasoning": classification.get("reasoning", ""),
            "content_preview": content[:500]
        }
        
    except Exception as e:
        return {
            "s3_uri": payload.get("s3_uri", "") if isinstance(payload, dict) else "",
            "category": "ERROR",
            "confidence": 0.0,
            "reasoning": f"Error: {str(e)}",
            "content_preview": ""
        }

# Start HTTP server in background thread immediately at module load
def start_server():
    server = HTTPServer(("0.0.0.0", 8080), RequestHandler)
    server.serve_forever()

_server_thread = threading.Thread(target=start_server, daemon=False)
_server_thread.start()

if __name__ == "__main__":
    _server_thread.join()
