output "eb_cname" {
  value       = aws_elastic_beanstalk_environment.voxinsights_env.cname
  description = "CNAME of the Elastic Beanstalk environment"
}

output "api_gateway_url" {
  value       = "${aws_api_gateway_deployment.voxinsights_api_deployment.invoke_url} (${var.environment})"
  description = "The URL of the API Gateway deployment"
}

output "websocket_url" {
  value       = "${aws_apigatewayv2_stage.websocket_stage.invoke_url} (${var.environment})"
  description = "The URL of the WebSocket API"
}

output "API_GATEWAY_URL" {
  value       = aws_api_gateway_deployment.voxinsights_api_deployment.invoke_url
  description = "The base URL for REST API endpoints"
}

output "WEBSOCKET_URL" {
  value       = aws_apigatewayv2_stage.websocket_stage.invoke_url
  description = "The URL for WebSocket connections"
}

# Add more outputs as needed