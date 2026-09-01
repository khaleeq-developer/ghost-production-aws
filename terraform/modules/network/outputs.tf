output "vpc_id" {
  description = "ID of the Ghost VPC."
  value       = aws_vpc.main.id
}

output "availability_zones" {
  description = "Availability zones used by the subnets."
  value       = local.availability_zones
}

output "public_subnet_ids" {
  description = "Public subnet IDs used by the ALB and NAT gateway."
  value       = [for key in sort(keys(aws_subnet.public)) : aws_subnet.public[key].id]
}

output "application_subnet_ids" {
  description = "Private application subnet IDs used by ECS Fargate tasks."
  value       = [for key in sort(keys(aws_subnet.application)) : aws_subnet.application[key].id]

  # Do not start Fargate until private-subnet egress is fully routed.
  depends_on = [
    aws_route.application_internet,
    aws_route_table_association.application,
  ]
}

output "database_subnet_ids" {
  description = "Isolated subnet IDs used by RDS."
  value       = [for key in sort(keys(aws_subnet.database)) : aws_subnet.database[key].id]
}

output "alb_arn" {
  description = "ARN of the application load balancer."
  value       = aws_lb.ghost.arn
}

output "alb_dns_name" {
  description = "DNS name of the application load balancer."
  value       = aws_lb.ghost.dns_name
}

output "target_group_arn" {
  description = "ARN of the Ghost target group."
  value       = aws_lb_target_group.ghost.arn

  # ECS must not use the target group before HTTPS associates it to the ALB.
  depends_on = [aws_lb_listener.https]
}

output "nat_gateway_id" {
  description = "ID of the single cost-optimized NAT gateway."
  value       = aws_nat_gateway.application.id
}

output "alb_security_group_id" {
  description = "Security group ID for the ALB."
  value       = aws_security_group.alb.id
}

output "ecs_security_group_id" {
  description = "Security group ID for Ghost ECS tasks."
  value       = aws_security_group.ecs.id
}

output "rds_security_group_id" {
  description = "Security group ID for the MySQL database."
  value       = aws_security_group.rds.id
}
