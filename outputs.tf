output "bucket_name" {
     value = aws_s3_bucket.s3bucket.id
}

output "apiurl" {
  value = aws_api_gateway_stage.api_staging.invoke_url
}