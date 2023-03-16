resource "aws_s3_bucket" "s3bucket" {
  bucket = "imageapilambda2023"
  #region = "eu-west-1"
}

resource "aws_lambda_layer_version" "pillow_layer" {
  filename                 = "python.zip"
  layer_name               = "pillowlib"
  compatible_architectures = ["x86_64"]
  compatible_runtimes      = ["python3.9"]
}

resource "aws_iam_role_policy" "lambda_s3_policy" {
  name   = "lambda-policy"
  role   = aws_iam_role.lambda_s3_role.id
  policy = file("iampolicy/policy_lambda.json")
}

resource "aws_iam_role" "lambda_s3_role" {
  name               = "lambda_s3_role"
  assume_role_policy = file("iampolicy/role_lambda.json")
}

data "archive_file" "code" {
  type        = "zip"
  source_file = "lambda_function.py"
  output_path = "lambda_function.zip"
}

data "aws_lambda_layer_version" "pillow" {
  depends_on = [aws_lambda_layer_version.pillow_layer]
  layer_name = aws_lambda_layer_version.pillow_layer.layer_name

}

resource "aws_lambda_function" "image_compressor" {
  filename      = "lambda_function.zip"
  function_name = var.func_name
  handler       = "lambda_function.lambda_handler"
  role          = aws_iam_role.lambda_s3_role.arn
  runtime       = var.runtime
  timeout       = var.timeout
  architectures = ["x86_64"]
  layers        = [data.aws_lambda_layer_version.pillow.arn]
}

resource "aws_lambda_permission" "api_permission" {
  depends_on    = [aws_api_gateway_rest_api.resize_api]
  #statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  principal     = "apigateway.amazonaws.com"
  function_name = aws_lambda_function.image_compressor.function_name
}

