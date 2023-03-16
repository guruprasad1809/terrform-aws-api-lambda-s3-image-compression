resource "aws_api_gateway_rest_api" "resize_api" {
  depends_on = [aws_lambda_function.image_compressor]
  name       = "resize-image-api"
  description = "THis API Invokes Lambda to Fetch a compressed Image"
  endpoint_configuration {
    types = ["REGIONAL"]
  }
  binary_media_types = ["*/*"]
}

resource "aws_api_gateway_resource" "api_resource" {
  depends_on  = [aws_api_gateway_rest_api.resize_api]
  rest_api_id = aws_api_gateway_rest_api.resize_api.id
  parent_id   = aws_api_gateway_rest_api.resize_api.root_resource_id
  path_part   = "{bucket}"                      # bucket is the path parameter | Enter bucket name in the url
    
}

resource "aws_api_gateway_method" "get" {
  rest_api_id = aws_api_gateway_rest_api.resize_api.id
  resource_id = aws_api_gateway_resource.api_resource.id
  http_method = "GET"
  authorization = "NONE"

  request_parameters = {
    "method.request.querystring.file" = true      # file is the input for query string parameter
  }
}

resource "aws_api_gateway_request_validator" "req_validator" {
  name                        = "file"
  rest_api_id                 = aws_api_gateway_rest_api.resize_api.id
  validate_request_body       = true
  validate_request_parameters = true
}

resource "aws_api_gateway_integration" "lambda" {
  rest_api_id = aws_api_gateway_rest_api.resize_api.id
  resource_id = aws_api_gateway_resource.api_resource.id
  http_method = aws_api_gateway_method.get.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri = aws_lambda_function.image_compressor.invoke_arn
}

resource "aws_api_gateway_deployment" "deploy_api" {
  rest_api_id =   aws_api_gateway_rest_api.resize_api.id
  
  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.api_resource.id,
      aws_api_gateway_method.get.id,
      aws_api_gateway_integration.lambda.id
    ]))
  }
  
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "api_staging" {
  deployment_id =   aws_api_gateway_deployment.deploy_api.id
  rest_api_id = aws_api_gateway_rest_api.resize_api.id
  stage_name = "test"
}