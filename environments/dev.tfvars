applicationname = "archiveiq"
applicationid   = "003"
environment     = "dev"

# IAM Roles: Lambda Execution + Bedrock Agent Runtime
iam_roles = { 
  lambda_execution = {
    name               = "archiveiq-lambda-execution-dev"
    assume_role_policy = "lambda-assume-role-policy.json"
    specifictags = {
      Purpose = "Lambda document processor"
    }
    policies = {
      lambda_exec = {
        name   = "archiveiq-lambda-execution-policy-dev"
        policy = "lambda-execution-policy.json"
      }
    }
    managed_policies = {}
  }

  bedrock_agent_runtime = {
    name               = "archiveiq-bedrock-agent-runtime-dev"
    assume_role_policy = "bedrock-agent-runtime-assume-role-policy.json"
    specifictags = {
      Purpose = "Bedrock agent execution"
    }
    policies = {
      bedrock_agent = {
        name   = "archiveiq-bedrock-agent-policy-dev"
        policy = "bedrock-agent-runtime-policy.json"
      }
    }
    managed_policies = {}
  }
}

# S3 Buckets: Document archive with Lambda notifications
s3s = {
  documents = {
    name                  = "archiveiq-documents-dev"
    blockpublicacls       = true
    blockpublicpolicy     = true
    ignorepublicacls      = true
    restrictpublicbuckets = true
    environment           = "dev"
    enable_versioning     = "Enabled"
    rules                 = {}
    notifications = {/*
      lambda_events = {
        lambda_function = [
          {
            id                  = "document-processor"
            lambda_function_arn = "arn:aws:lambda:eu-west-1:ACCOUNT_ID:function:document-processor"
            events              = ["s3:ObjectCreated:*"]
            filter_prefix       = "uploads/"
            filter_suffix       = ""
          }
        ]
      }
    */}
    replication_role  = null
    replication_rules = []
    specifictags = {
      Purpose = "Document archive for AI analysis"
    }
  }
}

# Lambda Functions: Document Processor
lambda_functions = {}

# Bedrock Agent Runtime: Will be configured after agent is created in AWS console or code
agent_runtime_configurations = {}

