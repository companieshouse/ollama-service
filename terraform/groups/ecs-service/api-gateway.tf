resource "aws_api_gateway_rest_api" "ollama_api" {
  name        = "${local.service_name}-${var.environment}"
  description = "API Gateway for ${local.service_name}"
}

# VPC Link for internal ALB connectivity
resource "aws_api_gateway_vpc_link" "ollama_vpc_link" {
  name        = "${local.service_name}-${var.environment}-vpc-link"
  description = "VPC Link for ${local.service_name}"
  target_arns = [data.aws_lb.rand_lb.arn]
}

resource "aws_api_gateway_resource" "ollama_resource" {
  rest_api_id = aws_api_gateway_rest_api.ollama_api.id
  parent_id   = aws_api_gateway_rest_api.ollama_api.root_resource_id
  path_part   = "ollama-service"
}

resource "aws_api_gateway_resource" "ollama_proxy" {
  rest_api_id = aws_api_gateway_rest_api.ollama_api.id
  parent_id   = aws_api_gateway_resource.ollama_resource.id
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "ollama_proxy_method" {
  rest_api_id      = aws_api_gateway_rest_api.ollama_api.id
  resource_id      = aws_api_gateway_resource.ollama_proxy.id
  http_method      = "ANY"
  authorization    = "NONE"

  request_parameters = {
    "method.request.path.proxy" = true
  }
}

resource "aws_api_gateway_integration" "ollama_integration" {
  rest_api_id             = aws_api_gateway_rest_api.ollama_api.id
  resource_id             = aws_api_gateway_resource.ollama_proxy.id
  http_method             = aws_api_gateway_method.ollama_proxy_method.http_method
  integration_http_method = "ANY"
  type                    = "HTTP_PROXY"
  connection_type         = "VPC_LINK"
  connection_id           = aws_api_gateway_vpc_link.ollama_vpc_link.id
  uri                     = "http://${data.aws_lb.rand_lb.dns_name}/{proxy}"

  request_parameters = {
    "integration.request.path.proxy" = "method.request.path.proxy"
  }
}

# Health check endpoint
resource "aws_api_gateway_method" "health_method" {
  rest_api_id      = aws_api_gateway_rest_api.ollama_api.id
  resource_id      = aws_api_gateway_resource.ollama_resource.id
  http_method      = "GET"
  authorization    = "NONE"
}

resource "aws_api_gateway_integration" "health_integration" {
  rest_api_id             = aws_api_gateway_rest_api.ollama_api.id
  resource_id             = aws_api_gateway_resource.ollama_resource.id
  http_method             = aws_api_gateway_method.health_method.http_method
  integration_http_method = "GET"
  type                    = "HTTP_PROXY"
  connection_type         = "VPC_LINK"
  connection_id           = aws_api_gateway_vpc_link.ollama_vpc_link.id
  uri                     = "http://${data.aws_lb.rand_lb.dns_name}/api/tags"
}

resource "aws_api_gateway_deployment" "ollama_deployment" {
  depends_on = [
    aws_api_gateway_integration.ollama_integration,
    aws_api_gateway_integration.health_integration
  ]

  rest_api_id = aws_api_gateway_rest_api.ollama_api.id

  lifecycle {
    create_before_destroy = true
  }
}

# Create a separate stage resource instead of using the deprecated stage_name attribute
resource "aws_api_gateway_stage" "ollama_stage" {
  deployment_id = aws_api_gateway_deployment.ollama_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.ollama_api.id
  stage_name    = var.environment
}

output "api_gateway_url" {
  value       = "${aws_api_gateway_stage.ollama_stage.invoke_url}/ollama-service"
  description = "URL of the API Gateway endpoint for Ollama service"
}