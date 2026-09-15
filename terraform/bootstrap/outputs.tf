output "state_bucket" {
  description = "S3 bucket used by the main Terraform root for remote state."
  value       = aws_s3_bucket.state.id
}

output "github_actions_plan_role_arn" {
  description = "GitHub repository variable value for speculative Terraform plans."
  value       = module.cicd.plan_role_arn
}

output "github_actions_apply_role_arn" {
  description = "GitHub repository variable value for protected production applies."
  value       = module.cicd.apply_role_arn
}
