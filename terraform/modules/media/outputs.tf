output "bucket_name" {
  description = "Name of the private versioned Ghost media bucket."
  value       = aws_s3_bucket.media.id
}

output "bucket_arn" {
  description = "ARN of the Ghost media bucket used by the ECS task policy."
  value       = aws_s3_bucket.media.arn
}

output "cdn_url" {
  description = "HTTPS base URL Ghost stores for media objects."
  value       = "https://${aws_cloudfront_distribution.media.domain_name}"
}

output "cloudfront_distribution_id" {
  description = "ID of the media CloudFront distribution."
  value       = aws_cloudfront_distribution.media.id
}

output "cloudfront_domain_name" {
  description = "CloudFront hostname used to deliver private Ghost media."
  value       = aws_cloudfront_distribution.media.domain_name
}

