output "upload_bucket_name" {
  description = "S3 bucket for uploading images (SOURCE)"
  value       = aws_s3_bucket.upload_bucket.id
}

output "processed_bucket_name" {
  description = "S3 bucket for processed images (DESTINATION)"
  value       = aws_s3_bucket.processed_bucket.id
}

output "lambda_function_name" {
  description = "Lambda function name for image processing"
  value       = aws_lambda_function.image_processor.function_name
}

output "region" {
  description = "AWS Region"
  value       = var.aws_region
}

output "upload_command_example" {
  description = "Example command to upload an image"
  value       = "aws s3 cp your-image.jpg s3://${aws_s3_bucket.upload_bucket.id}/"
}

# API Gateway outputs
output "api_gateway_url" {
  description = "API Gateway URL for direct image uploads"
  value       = "${aws_api_gateway_stage.image_api.invoke_url}/upload"
}

output "api_upload_example" {
  description = "Example curl command to upload via API"
  value       = "curl -X POST -H 'Content-Type: application/json' -d '{\"image\": \"<base64-encoded-image>\"}' ${aws_api_gateway_stage.image_api.invoke_url}/upload"
}

# CloudFront outputs
output "cloudfront_domain" {
  description = "CloudFront distribution domain for cached images"
  value       = aws_cloudfront_distribution.processed_images.domain_name
}

output "cloudfront_url" {
  description = "CloudFront URL for accessing processed images"
  value       = "https://${aws_cloudfront_distribution.processed_images.domain_name}"
}

# SNS outputs
output "sns_topic_arn" {
  description = "SNS topic ARN for processing notifications"
  value       = aws_sns_topic.image_processed.arn
}

output "sns_subscribe_command" {
  description = "Command to subscribe email to notifications"
  value       = "aws sns subscribe --topic-arn ${aws_sns_topic.image_processed.arn} --protocol email --notification-endpoint your-email@example.com"
}
