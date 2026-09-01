output "database_endpoint" {
  description = "RDS endpoint including its port."
  value       = aws_db_instance.ghost.endpoint
}

output "database_host" {
  description = "RDS hostname without its port."
  value       = aws_db_instance.ghost.address
}

output "database_port" {
  description = "MySQL listener port."
  value       = aws_db_instance.ghost.port
}

output "database_name" {
  description = "MySQL database name used by Ghost."
  value       = var.database_name
}

output "database_username" {
  description = "MySQL username used by Ghost. This is not the password."
  value       = var.database_username
}

output "database_secret_arn" {
  description = "ARN of the Secrets Manager secret containing all connection fields."
  value       = aws_secretsmanager_secret.database.arn

  depends_on = [aws_secretsmanager_secret_version.database]
}
