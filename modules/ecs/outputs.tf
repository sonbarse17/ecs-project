output "cluster_id" {
  description = "ECS cluster ARN"
  value       = aws_ecs_cluster.this.id
}

output "service_arns" {
  description = "Map of container name to ECS service ARN"
  value       = { for k, svc in aws_ecs_service.this : k => svc.id }
}

output "task_definition_arns" {
  description = "Map of container name to task definition ARN"
  value       = { for k, td in aws_ecs_task_definition.this : k => td.arn }
}

output "tasks_security_group_id" {
  description = "Security group ID attached to ECS tasks"
  value       = aws_security_group.tasks.id
}
