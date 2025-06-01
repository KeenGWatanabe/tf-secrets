# give a name to secretsmanager
resource "aws_secretsmanager_secret" "mongodb_uri" {
  name        = "prod/mongodb_uri"
}
# set references for ECS to use the secret
resource "aws_secretsmanager_secret_version" "mongodb_uri" {
  secret_id = aws_secretsmanager_secret.mongodb_uri.id
  secret_string = jsonencode({
    MONGODB_URI = "mongodb+srv://${var.mongodb_username}:${var.mongodb_password}@${var.mongodb_host}/?retryWrites=true&w=majority&appName=${var.mongodb_database}" 
  })
}

resource "aws_cloudwatch_log_group" "ecs_logs" {
  name              = "/ecs/ce-grp-4t-app-service-f48ddcab"  # Match what your ECS task expects
  retention_in_days = 7  # or whatever retention period you want
}

output "mongodb_secret_arn" {
  value       = aws_secretsmanager_secret.mongodb_uri.arn
  description = "ARN of the MongoDB secret for ECS task reference"
}


output "mongodb_secret_name" {
  value       = aws_secretsmanager_secret.mongodb_uri.name  # "prod/mongodb_uri"
  description = "Name of the MongoDB secret"
}