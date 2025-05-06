# main.tf
resource "aws_secretsmanager_secret" "mongo_uri" {
  name        = "prod/mongodb_uri"
}

resource "aws_secretsmanager_secret_version" "mongo_uri" {
  secret_id = aws_secretsmanager_secret.mongo_uri.id
  secret_string = jsonencode({
    mongodb_uri = "mongodb://${var.mongodb_username}:${var.mongodb_password}@${var.mongodb_host}:27017/mydb?authSource=admin"
  })
}

output "mongodb_secret_arn" {
  value       = aws_secretsmanager_secret.mongo_uri.arn
  description = "ARN of the MongoDB secret for ECS task reference"
}