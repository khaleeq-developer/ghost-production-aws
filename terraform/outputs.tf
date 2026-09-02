output "alb_dns_name" {
  description = "Public ALB hostname to use as the target of the manual Cloudflare CNAME."
  value       = module.network.alb_dns_name
}

output "ghost_url" {
  description = "Canonical HTTPS URL configured for Ghost."
  value       = "https://${var.domain_name}"
}

output "ecs_cluster_name" {
  description = "ECS cluster name used by operational commands."
  value       = module.compute.cluster_name
}

output "ecs_service_name" {
  description = "ECS service name used by operational commands."
  value       = module.compute.service_name
}

output "ghost_log_group_name" {
  description = "CloudWatch log group containing Ghost container logs."
  value       = module.compute.log_group_name
}

output "ghost_target_group_arn" {
  description = "ALB target-group ARN used for health checks."
  value       = module.network.target_group_arn
}

output "database_endpoint" {
  description = "RDS endpoint for connectivity troubleshooting."
  value       = module.data.database_endpoint
}

output "media_bucket_name" {
  description = "Private versioned S3 bucket containing Ghost uploads."
  value       = module.media.bucket_name
}

output "media_cdn_url" {
  description = "CloudFront HTTPS base URL used for Ghost media."
  value       = module.media.cdn_url
}

output "media_cloudfront_distribution_id" {
  description = "CloudFront distribution ID used for media operations."
  value       = module.media.cloudfront_distribution_id
}
