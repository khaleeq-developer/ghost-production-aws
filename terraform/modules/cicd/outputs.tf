output "plan_role_arn" {
  description = "ARN of the GitHub Actions role used only for same-repository pull-request plans."
  value       = aws_iam_role.plan.arn
}

output "apply_role_arn" {
  description = "ARN of the GitHub Actions role used only by the protected production environment."
  value       = aws_iam_role.apply.arn
}
