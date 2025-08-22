# give a name to secretsmanager
resource "aws_secretsmanager_secret" "mongodb_uri" {
  name        = "code/mongodb_uri"
}

# set references for ECS to use the secret
resource "aws_secretsmanager_secret_version" "mongodb_uri" {
  secret_id = aws_secretsmanager_secret.mongodb_uri.id
  secret_string = jsonencode({
    MONGODB_URI = "mongodb+srv://user:1234@tasks.hqybvw0.mongodb.net/?retryWrites=true&w=majority&appName=tasks"
    #MONGODB_URI = "mongodb+srv://${var.mongodb_username}:${var.mongodb_password}@${var.mongodb_host}/?retryWrites=true&w=majority&appName=${var.mongodb_database}" 
  })
}

# Output the secret ARN and name for reference in ECS task definitions

output "mongodb_secret_arn" {
  value       = aws_secretsmanager_secret.mongodb_uri.arn
  description = "ARN of the MongoDB secret for ECS task reference"
}


output "mongodb_secret_name" {
  value       = aws_secretsmanager_secret.mongodb_uri.name  # "test/mongodb_uri"
  description = "Name of the MongoDB secret"
}
