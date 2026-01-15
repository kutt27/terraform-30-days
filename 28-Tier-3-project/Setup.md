## Setup Instructions: Tier-3 Project Deployment

**Prerequisites**

- AWS CLI: Configured with your AWS credentials (aws configure).
- Terraform: Version 1.13 or higher.
- Docker & Docker Hub Account: Required for building and hosting your application images.
- AWS Key Pair: Create an EC2 Key Pair in your target region (e.g., us-east-1).

#### Step 1: Prepare Docker Images
The infrastructure pulls Docker images from Docker Hub. You need to push the application images to your own repository.

Login to Docker Hub:
```bash
docker login
```

Build and Push: Use the provided script to automate the process.

```bash
# Navigate to the root of the project
cd 28-Tier-3-project/terraform-infra/scripts/
# Run the script with your Docker Hub username
./build-and-push.sh your-dockerhub-username
```

This will build the frontend and backend images, tag them, and push them to your Docker Hub profile.

#### Step 2: Configure Terraform Variables

Navigate to the development environment folder and set up your variables.

Move to the Dev environment:

```bash
cd ../environments/dev/
```

Create your variables file:
```bash
cp terraform.tfvars.example terraform.tfvars
```

Update terraform.tfvars: Open the file and update the following REQUIRED fields:
- ssh_key_name: Your AWS Key Pair name (e.g., "my-aws-key").
- allowed_ssh_cidr: Your public IP address for secure SSH access (e.g., "203.0.113.1/32"). As it's a demo, I will be using 0.0.0.0/0.
- frontend_docker_image: Set to "your-dockerhub-username/goal-tracker-frontend:latest".
- backend_docker_image: Set to "your-dockerhub-username/goal-tracker-backend:latest".
- region: The AWS region you want to deploy to (default is us-east-1).

#### Step 3: Deploy Infrastructure

Now, run the Terraform lifecycle commands to provision the resources.

Initialize:
```bash
terraform init
```

Plan: Preview the resources that will be created.
```bash
terraform plan
```

Apply: Deploy the infrastructure to AWS.
```bash
terraform apply
```

Type yes when prompted.

For updating the postgress version, you need to update the variables.tf file in the rds module.

```bash
aws rds describe-db-engine-versions --engine postgres --region ap-south-1 --query 'DBEngineVersions[].EngineVersion' --output table
```

Find the appropriate version and update the variables.tf file in the rds module.

#### Step 4: Access the Application

Once the deployment is complete, Terraform will output several important values:

- Frontend URL: Look for frontend_alb_dns_name in the output. Paste this into your browser to access the Web UI.

Note: It may take 3-5 minutes for health checks to pass and the instances to become "Healthy".

- Bastion Host: Use the bastion_public_ip if you need to SSH into private instances for debugging.
- CloudWatch Logs: You can monitor application logs in the AWS Console under Log Groups:
    - /aws/ec2/dev-goal-tracker/frontend
    - /aws/ec2/dev-goal-tracker/backend

#### Setup ssh key on instances

Login to the bastion host through aws console or your preferred method.

```bash
ssh-keygen -t ed25519 -f ~/.ssh/frontend-ec2 -C "bastion-to-target"
```

Copy the output (starts with ssh-ed25519 AAAAC3Nza..bastion-to-target). Do the same for backend instance.

```bash
ssh-keygen -t ed25519 -f ~/.ssh/backend-ec2 -C "bastion-to-target"
```

ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMdNKakjsaC1AFO1TiDo72LoS5j4bwJqWbcI4RPDwhaD bastion-to-target

Since we can't SSH in yet to add the key, use AWS Systems Manager (SSM) which maybe already enabled in our IAM module.

On the Bastion, get your public key:
```bash
cat ~/.ssh/frontend-ec2.pub
```

(Copy the entire output string starting with ssh-ed25519...)

- Open the AWS Console and go to EC2 ➔ Instances.
- Select a Private Frontend Instance.
- Click Connect at the top.
- Choose the Session Manager tab and click Connect. (This opens a terminal in your browser without needing a key).

Inside that browser terminal, run:
```bash
# 1. Switch to the ubuntu user
sudo su - ubuntu

# 2. Create the .ssh directory if it doesn't exist
mkdir -p ~/.ssh

# 3. Fix the directory permissions
chmod 700 ~/.ssh

# 4. Append the key to the CORRECT file (no dot in filename)
echo "PASTE_YOUR_COPIED_PUBLIC_KEY_HERE" >> ~/.ssh/authorized_keys

# 5. Fix the file permissions
chmod 600 ~/.ssh/authorized_keys
```

Now go back to your Bastion terminal and try again:
bash
ssh -i ~/.ssh/frontend-ec2 ubuntu@<PRIVATE_IP>

#### Cleanup
To avoid ongoing AWS costs when you are finished testing, destroy the resources:

```bash
terraform destroy
```
Type yes when prompted.
