Here's a **clear, step-by-step guide** to connect all the pieces (Node.js Docker image, ECS, and Secrets Manager) in a full-stack setup:

---

### **Architecture Overview**
1. **Terraform Secrets Repo** → Stores MongoDB URI in AWS Secrets Manager.  
2. **Node.js Docker Image** → Reads the URI from Secrets Manager at runtime.  
3. **ECS Terraform Repo** → Deploys the container and grants access to the secret.  

---

### **Step 1: Terraform Secrets Repo (Done)**
Your existing code is correct. After running `terraform apply`:  
- The MongoDB URI is stored securely in Secrets Manager.  
- You get a **secret ARN** (e.g., `arn:aws:secretsmanager:us-east-1:1234567890:secret:prod/mongodb_uri-abc123`).  

---

### **Step 2: Modify Node.js Docker Image**
#### **Option A: Let ECS Inject the Secret (Recommended)**
1. **Remove hardcoded MongoDB URI** from your `Dockerfile` and `.env`.  
2. Ensure your app reads from `process.env.MONGODB_URI`:  
   ```javascript
   // app.js
   mongoose.connect(process.env.MONGODB_URI);
   ```
3. **Rebuild and push the image** to ECR (no code changes needed).

#### **Option B: Fetch Secret Programmatically (Advanced)**
If you need more control (e.g., caching secrets):  
1. Install AWS SDK in your Node.js app:  
   ```bash
   npm install @aws-sdk/client-secrets-manager
   ```
2. Add secret-fetching logic:  
   ```javascript
   const { SecretsManagerClient, GetSecretValueCommand } = require('@aws-sdk/client-secrets-manager');

   async function getMongoUri() {
     const client = new SecretsManagerClient({ region: 'us-east-1' });
     const response = await client.send(
       new GetSecretValueCommand({ 
         SecretId: process.env.MONGODB_SECRET_ARN  // Pass ARN via ECS task definition
       })
     );
     return JSON.parse(response.SecretString).mongodb_uri;
   }

   // Usage
   const MONGO_URI = await getMongoUri();
   mongoose.connect(MONGO_URI);
   ```

---

### **Step 3: ECS Terraform Repo**
#### **Key Components**
1. **Task Definition**: Grants access to the secret and passes it as an env var.  
2. **IAM Role**: Allows ECS to read the secret.  

#### **Example ECS Terraform Code**
```hcl
# main.tf (ECS Repo)
resource "aws_ecs_task_definition" "nodejs_app" {
  family                   = "nodejs-app"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  cpu                      = "512"
  memory                   = "1024"

  container_definitions = jsonencode([{
    name      = "nodejs-app",
    image     = "1234567890.dkr.ecr.us-east-1.amazonaws.com/your-repo:latest",
    essential = true,
    portMappings = [{ containerPort = 5000, hostPort = 5000 }],
    secrets = [{
      name      = "MONGODB_URI",  # Populates process.env.MONGODB_URI
      valueFrom = aws_secretsmanager_secret.mongo_uri.arn
    }]
  }])
}

# IAM Role for ECS to access Secrets Manager
resource "aws_iam_role" "ecs_execution_role" {
  name = "ecs-execution-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "secrets_access" {
  role   = aws_iam_role.ecs_execution_role.name
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect   = "Allow",
      Action   = ["secretsmanager:GetSecretValue"],
      Resource = [aws_secretsmanager_secret.mongo_uri.arn]
    }]
  })
}

# Reference the secret ARN from the Secrets Repo
data "aws_secretsmanager_secret" "mongo_uri" {
  arn = "arn:aws:secretsmanager:us-east-1:1234567890:secret:prod/mongodb_uri-abc123"
}
```

---

### **Step 4: Connect the Dots**
1. **Secrets Repo Outputs ARN**:  
   - After deploying the secrets repo, note the `mongodb_secret_arn` output.  
   - Pass this ARN to your ECS repo (via Terraform remote state or hardcode if needed).  

2. **ECS Task Definition**:  
   - Uses the ARN to inject `MONGODB_URI` into the container.  

3. **Node.js App**:  
   - Reads `process.env.MONGODB_URI` at startup.  

---

### **Workflow Summary**
1. **Secrets Repo**: Stores MongoDB URI.  
2. **Node.js Image**: Expects URI via env var.  
3. **ECS Repo**: Deploys the image and injects the secret.  

---

### **Key Points**
- **No hardcoded secrets** in Docker or Terraform.  
- **Least privilege**: ECS only has access to the specific secret.  
- **Scalable**: Add more secrets (e.g., API keys) the same way.  

Let me know if you'd like help debugging IAM permissions or secret injection!