output "agent_runtime_id" {
  description = "Unique identifier of the Bedrock AgentCore Agent Runtime"
  value       = aws_bedrockagentcore_agent_runtime.runtime.agent_runtime_id
}

output "agent_runtime_arn" {
  description = "ARN of the Bedrock AgentCore Agent Runtime"
  value       = aws_bedrockagentcore_agent_runtime.runtime.agent_runtime_arn
}

output "agent_runtime_version" {
  description = "Version of the Bedrock AgentCore Agent Runtime"
  value       = aws_bedrockagentcore_agent_runtime.runtime.agent_runtime_version
}

output "workload_identity_arn" {
  description = "Workload identity ARN for the Bedrock AgentCore Agent Runtime"
  value       = try(aws_bedrockagentcore_agent_runtime.runtime.workload_identity_details.workload_identity_arn, null)
}