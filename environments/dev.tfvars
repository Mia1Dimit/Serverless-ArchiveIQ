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
    notifications = {
      lambda_events = {
        lambda_function = [
          {
            id                  = "document-processor"
            lambda_function_arn = "arn:aws:lambda:eu-central-1:577638377042:function:archiveiq-document-processor-dev"
            events              = ["s3:ObjectCreated:*"]
            filter_prefix       = "documents/"
          }
        ]
      }
    }
    replication_role  = null
    replication_rules = []
    specifictags = {
      Purpose = "Document archive for AI analysis"
    }
  }
  agentcore_runtime = {
    name                  = "archiveiq-agentcore-runtime-dev"
    blockpublicacls       = true
    blockpublicpolicy     = true
    ignorepublicacls      = true
    restrictpublicbuckets = true
    environment           = "dev"
    enable_versioning     = "Enabled"
    rules                 = {}
    notifications = {
      lambda_events = {
        lambda_function = []
      }
    }
    replication_role  = null
    replication_rules = []
    specifictags = {
      Purpose = "AgentCore Runtime code artifacts"
    }
  }
  results = {
    name                  = "archiveiq-results-dev"
    blockpublicacls       = true
    blockpublicpolicy     = true
    ignorepublicacls      = true
    restrictpublicbuckets = true
    environment           = "dev"
    enable_versioning     = "Disabled"
    rules                 = {}
    notifications = {
      lambda_events = {
        lambda_function = []
      }
    }
    replication_role  = null
    replication_rules = []
    specifictags = {
      Purpose = "Classification results output"
    }
  }
}

# Lambda Functions: Document Processor
lambda_functions = {
  document_processor = {
    name        = "archiveiq-document-processor-dev"
    handler     = "handler.handler"
    runtime     = "python3.12"
    timeout     = 120
    memory_size = 256
    source_dir  = "../lambda"
    output_path = "/tmp/archiveiq-document-processor-dev.zip"
    environment_variables = {
      AGENTCORE_RUNTIME_ARN = "arn:aws:bedrock-agentcore:eu-central-1:577638377042:runtime/archiveiq_agentcore_runtime_dev-sXcrbz9HlW"
      RESULTS_BUCKET        = "archiveiq-results-dev"
      DYNAMODB_TABLE        = "archiveiq-classifications-dev"
      REGION                = "eu-central-1"
      MAX_CONTENT_CHARS     = "2000"
    }
  }
}

# DynamoDB Tables
dynamodb_tables = {
  classifications = {
    table_name   = "archiveiq-classifications-dev"
    hash_key     = "document_id"
    billing_mode = "PAY_PER_REQUEST"
    global_secondary_indexes = [
      {
        name            = "category-index"
        hash_key        = "category"
        projection_type = "ALL"
      }
    ]
    enable_point_in_time_recovery = false
    ttl_attribute_name            = "expires_at"
  }
}

# Lambda Permissions: S3 → Lambda trigger
lambda_permissions = {
  s3_document_processor = {
    function_name = "archiveiq-document-processor-dev"
    statement_id  = "AllowS3ToInvoke"
    principal     = "s3.amazonaws.com"
    source_arn    = "arn:aws:s3:::archiveiq-documents-dev"
  }
}

# Bedrock Agent Runtime: PUBLIC mode minimizes networking costs while
# keeping IAM-based access controls and private data stores.
agent_runtime_configurations = {
  document_classifier = {
    agent_runtime_name = "archiveiq_agent_classifier_dev"
    role_arn           = "arn:aws:iam::577638377042:role/archiveiq-bedrock-agent-runtime-dev"
    description        = "ArchiveIQ document classification runtime"

    code_configuration = {
      entry_point = ["agent.handler"]
      runtime     = "PYTHON_3_12"
      s3_bucket   = "archiveiq-agentcore-runtime-dev"
      s3_prefix   = "agent/archiveiq-agent.zip"
    }

    network_mode    = "PUBLIC"
    server_protocol = "HTTP"
    environment_variables = {
      LOG_LEVEL = "INFO"
    }
  }
}

