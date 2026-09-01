output "cluster_name" {
  description = "Name of the ECS cluster."
  value       = aws_ecs_cluster.ghost.name
}

output "service_name" {
  description = "Name of the Ghost ECS service."
  value       = aws_ecs_service.ghost.name
}

output "task_definition_arn" {
  description = "ARN of the active Ghost task definition."
  value       = aws_ecs_task_definition.ghost.arn
}

output "log_group_name" {
  description = "CloudWatch Logs group receiving Ghost container logs."
  value       = aws_cloudwatch_log_group.ghost.name
}
