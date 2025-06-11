Great question! If you remove the `MONGO_URI` from your `.env` file (which your Node.js app relies on), you need to ensure your app can **still access the connection string at runtime**. Here’s how to do it securely using **AWS Secrets Manager** without breaking your app:

---

### **Step-by-Step Solution**
#### **1. Modify Your Node.js App to Read `MONGO_URI` from Environment**
Your app likely uses `process.env.MONGO_URI` to connect to MongoDB. Instead of hardcoding it in `.env`, you’ll:
- Fetch it from **Secrets Manager** (best for production), **or**
- Pass it via **ECS task definition’s `secrets`** (simpler, but still secure).

##### **Option A: Directly Use ECS Secrets Injection (Recommended)**
ECS can inject secrets as environment variables. Your app **won’t need changes** if it already reads `process.env.MONGO_URI`.

1. **Store `MONGO_URI` in AWS Secrets Manager**:
   ```bash
   aws secretsmanager create-secret \
     --name "prod/mongodb_uri" \
     --secret-string "mongodb://user:password@host:27017/dbname"

     --secret-string "mongodb://admin:1234@host:27017/dbname"
   ```

2. **Update the ECS Task Definition**:
   ```hcl
   container_definitions = jsonencode([{
     name  = "nodejs-app",
     image = "your-image",
     secrets = [{
       name      = "MONGO_URI",  # Maps to process.env.MONGO_URI
       valueFrom = "arn:aws:secretsmanager:us-east-1:1234567890:secret:prod/mongodb_uri"
     }]
   }])
   ```

   **→ Your app keeps working!** ECS auto-populates `process.env.MONGO_URI` at runtime.

##### **Option B: Fetch Secrets in Your Node.js App (Advanced)**
If you prefer to fetch secrets programmatically (e.g., for caching or fallbacks):
1. Install the AWS SDK:
   ```bash
   npm install @aws-sdk/client-secrets-manager
   ```

2. Add this to your app’s startup (e.g., `app.js`):
   ```javascript
   const { SecretsManagerClient, GetSecretValueCommand } = require("@aws-sdk/client-secrets-manager");

   async function getMongoUri() {
     const client = new SecretsManagerClient({ region: "us-east-1" });
     const response = await client.send(
       new GetSecretValueCommand({ SecretId: "prod/mongodb_uri" })
     );
     return response.SecretString;
   }

   // Usage (ensure this runs before DB connection)
   const MONGO_URI = await getMongoUri();
   mongoose.connect(MONGO_URI);
   ```

---

#### **2. Update Your Dockerfile**
Remove `MONGO_URI` from `.env` and ensure the file is **not copied** into the image:
```dockerfile
FROM node:18
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .  # Ensure .env is in .dockerignore!
EXPOSE 5000
CMD ["node", "server.js"]
```

**Add `.env` to `.dockerignore`**:
```plaintext
.env
node_modules
```

---

#### **3. Deploy with Terraform**
Your Terraform config should:
1. **Grant ECS permissions to Secrets Manager**:
   ```hcl
   resource "aws_iam_role_policy" "ecs_secrets" {
     role   = aws_iam_role.ecs_execution_role.name
     policy = jsonencode({
       Version = "2012-10-17",
       Statement = [{
         Effect   = "Allow",
         Action   = ["secretsmanager:GetSecretValue"],
         Resource = ["arn:aws:secretsmanager:*:1234567890:secret:prod/mongodb_uri*"]
       }]
     })
   }
   ```

2. **Reference the secret in the task definition** (as shown above).

---

### **Key Points**
- **No `.env` in the image**: Secrets are injected at runtime by ECS.
- **No app code changes needed** if using ECS secrets injection (Option A).
- **Security**: Secrets Manager encrypts the URI, audits access, and allows rotation.

---

### **Troubleshooting**
If your app fails to connect:
1. **Check ECS task logs** for errors like `"MongoDB connection failed"`.
2. **Verify the secret ARN** matches in Terraform and ECS.
3. **Test locally** by temporarily passing `MONGO_URI` as an env var:
   ```bash
   docker run -e MONGO_URI="mongodb://..." your-image
   ```

---

### **Final Answer**
Your app will **continue working** because:
1. ECS injects `MONGO_URI` into `process.env` (replacing `.env`).  
2. Your Node.js app still reads `process.env.MONGO_URI` as before.  

This is the **AWS-recommended** way to manage secrets. Let me know if you’d like help testing the migration!

--------------------------------
# generated 20250611

mongodb_secret_arn = "arn:aws:secretsmanager:us-east-1:255945442255:secret:test/mongodb_uri-5c38zg"
mongodb_secret_name = "test/mongodb_uri"

----------------------------------

# FORCE DELETION OF AWS SECRETS IF RECREATING? AWS Secrets Manager retains deleted secrets for 7 days (default recovery window).

aws secretsmanager delete-secret --secret-id prod/mongodb_uri --force-delete-without-recovery