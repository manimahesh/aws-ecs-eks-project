# Vulnerable Application Demo - AWS EKS Deployment

## WARNING

This project is designed for **EDUCATIONAL PURPOSES ONLY** to demonstrate the risks of using vulnerable open-source packages in applications. This application intentionally contains known security vulnerabilities and should:

- **NEVER** be deployed in a production environment
- **NEVER** be used with real user data
- **ONLY** be used in isolated, controlled environments for security training
- Be properly secured and isolated from any production networks

## Project Overview

This project demonstrates a complete CI/CD pipeline that deploys a deliberately vulnerable Node.js application to AWS EKS (Elastic Kubernetes Service). It showcases:

- A simple "Hello World" web application with intentionally outdated and vulnerable dependencies
- Containerization using Docker
- AWS infrastructure provisioning using Terraform
- Automated deployment via GitHub Actions with OIDC authentication
- Container registry management using Amazon ECR
- Kubernetes orchestration on Amazon EKS

## Architecture

```
GitHub Repository
    ↓
GitHub Actions (OIDC Auth)
    ↓
Build Docker Image → Push to Amazon ECR
    ↓
Deploy to Amazon EKS
    ↓
LoadBalancer Service → Application Pods
```

## Vulnerable Dependencies

This project intentionally includes the following vulnerable packages:

- `express@4.17.1` - Outdated version with known vulnerabilities
- `lodash@4.17.15` - Contains prototype pollution vulnerabilities
- `minimist@1.2.0` - Prototype pollution vulnerability
- `axios@0.21.1` - Server-Side Request Forgery (SSRF) vulnerability
- `debug@2.6.8` - Regular Expression Denial of Service (ReDoS)
- `ejs@2.7.4` - Remote Code Execution (RCE) vulnerability
- `mustache@3.0.0` - Prototype pollution vulnerability

**These vulnerabilities are intentional for educational demonstration.**

## Prerequisites

Before you begin, ensure you have the following installed:

- [AWS CLI](https://aws.amazon.com/cli/) v2.x
- [Terraform](https://www.terraform.io/downloads) >= 1.0
- [kubectl](https://kubernetes.io/docs/tasks/tools/) >= 1.28
- [Git](https://git-scm.com/)
- An AWS account with appropriate permissions
- A GitHub account

## Setup Instructions

### 1. Clone the Repository

```bash
git clone https://github.com/YOUR_USERNAME/aws-ecs-eks-project.git
cd aws-ecs-eks-project
```

### 2. Configure Terraform Variables

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` and update the following values:

```hcl
github_org  = "your-github-username"
github_repo = "aws-ecs-eks-project"
aws_region  = "us-east-1"  # Change to your preferred region
```

### 3. Deploy Infrastructure with Terraform

```bash
# Initialize Terraform
terraform init

# Review the execution plan
terraform plan

# Apply the configuration
terraform apply
```

This will create:
- VPC with public and private subnets across 2 availability zones
- NAT Gateways and Internet Gateway
- EKS cluster with managed node group
- ECR repository for container images
- IAM roles and policies for GitHub Actions OIDC
- All necessary security groups and networking

**Note:** The infrastructure creation takes approximately 15-20 minutes.

### 4. Configure GitHub Secrets

After Terraform completes, note the output value for `github_actions_role_arn`. Add this to your GitHub repository secrets:

1. Go to your GitHub repository
2. Navigate to Settings → Secrets and variables → Actions
3. Click "New repository secret"
4. Name: `AWS_ROLE_ARN`
5. Value: The ARN from Terraform output (e.g., `arn:aws:iam::123456789012:role/vulnerable-app-demo-github-actions`)

### 5. Update GitHub Actions Workflow

If you changed the default values in `terraform.tfvars`, update the environment variables in `.github/workflows/deploy.yml`:

```yaml
env:
  AWS_REGION: us-east-1  # Match your terraform.tfvars
  EKS_CLUSTER_NAME: vulnerable-app-demo  # Match your terraform.tfvars
  ECR_REPOSITORY: vulnerable-app-demo  # Match your terraform.tfvars
```

### 6. Push to GitHub and Deploy

```bash
git add .
git commit -m "Initial commit with vulnerable app demo"
git push origin main
```

The GitHub Actions workflow will automatically:
1. Authenticate with AWS using OIDC
2. Build the Docker image
3. Push the image to ECR
4. Deploy to EKS
5. Run a security scan (informational only)

### 7. Access the Application

After deployment completes, get the LoadBalancer URL:

```bash
# Configure kubectl
aws eks update-kubeconfig --region us-east-1 --name vulnerable-app-demo

# Get the service URL
kubectl get svc vulnerable-app-service -n vulnerable-demo
```

Look for the `EXTERNAL-IP` column. The application will be available at `http://<EXTERNAL-IP>`.

## Terraform Outputs

After applying Terraform, you'll have access to these outputs:

```bash
terraform output
```

Key outputs:
- `cluster_name` - EKS cluster name
- `cluster_endpoint` - EKS API endpoint
- `ecr_repository_url` - ECR repository URL
- `github_actions_role_arn` - IAM role ARN for GitHub Actions
- `configure_kubectl` - Command to configure kubectl

## Manual Deployment (Optional)

If you prefer to deploy manually without GitHub Actions:

```bash
# Build and tag the image
docker build -t vulnerable-app-demo .

# Authenticate to ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <ECR_REPOSITORY_URL>

# Tag and push
docker tag vulnerable-app-demo:latest <ECR_REPOSITORY_URL>:latest
docker push <ECR_REPOSITORY_URL>:latest

# Configure kubectl
aws eks update-kubeconfig --region us-east-1 --name vulnerable-app-demo

# Deploy to Kubernetes
kubectl apply -f k8s/namespace.yaml
sed "s|IMAGE_PLACEHOLDER|<ECR_REPOSITORY_URL>:latest|g" k8s/deployment.yaml | kubectl apply -f -
kubectl apply -f k8s/service.yaml
```

## Monitoring and Verification

### Check Deployment Status

```bash
kubectl get pods -n vulnerable-demo
kubectl get svc -n vulnerable-demo
kubectl logs -f deployment/vulnerable-app -n vulnerable-demo
```

### View Security Scan Results

GitHub Actions includes a Trivy security scan that will display vulnerabilities:

1. Go to your GitHub repository
2. Click on "Actions"
3. Select the latest workflow run
4. Expand the "Run security scan" step

You should see multiple HIGH and CRITICAL vulnerabilities listed.

## Security Scan Examples

You can run security scans locally:

```bash
# Using npm audit
npm audit

# Using Snyk (requires Snyk account)
npx snyk test

# Using Trivy on the Docker image
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  aquasec/trivy image vulnerable-app-demo:latest
```

## Educational Use Cases

This project can be used to demonstrate:

1. **Vulnerability Scanning**: Show how tools like npm audit, Snyk, or Trivy detect vulnerable dependencies
2. **Supply Chain Security**: Demonstrate the importance of keeping dependencies up to date
3. **CI/CD Security**: Show how to integrate security scanning into deployment pipelines
4. **Container Security**: Demonstrate image scanning and vulnerability management
5. **AWS Security**: Show proper use of IAM roles, OIDC, and least privilege
6. **Kubernetes Security**: Demonstrate resource limits, health checks, and network policies

## Cleanup

To avoid AWS charges, destroy all resources when done:

```bash
# Delete Kubernetes resources first
kubectl delete namespace vulnerable-demo

# Wait for LoadBalancer to be deleted (check AWS Console)
# This is important to avoid Terraform errors

# Destroy Terraform infrastructure
cd terraform
terraform destroy
```

**Note:** Ensure the LoadBalancer is fully deleted before running `terraform destroy`, otherwise you may encounter VPC deletion errors.

## Project Structure

```
.
├── app.js                      # Node.js Express application
├── package.json                # Dependencies (intentionally vulnerable)
├── Dockerfile                  # Container image definition
├── public/
│   └── index.html             # Simple HTML frontend
├── .github/
│   └── workflows/
│       └── deploy.yml         # GitHub Actions CI/CD pipeline
├── terraform/
│   ├── main.tf                # Terraform main configuration
│   ├── variables.tf           # Input variables
│   ├── outputs.tf             # Output values
│   ├── vpc.tf                 # VPC and networking
│   ├── eks.tf                 # EKS cluster configuration
│   ├── ecr.tf                 # ECR repository
│   └── iam-oidc.tf           # IAM roles and OIDC provider
├── k8s/
│   ├── namespace.yaml         # Kubernetes namespace
│   ├── deployment.yaml        # Application deployment
│   └── service.yaml           # LoadBalancer service
└── README.md                  # This file
```

## Troubleshooting

### GitHub Actions fails to authenticate

- Ensure the `AWS_ROLE_ARN` secret is correctly set
- Verify the OIDC provider was created in AWS
- Check that the IAM role trust policy matches your GitHub org/repo

### kubectl cannot connect to cluster

```bash
# Reconfigure kubectl
aws eks update-kubeconfig --region us-east-1 --name vulnerable-app-demo

# Verify connection
kubectl get nodes
```

### LoadBalancer stuck in pending

- Check AWS Load Balancer Controller is working
- Verify security groups allow traffic
- Check VPC has internet gateway properly configured

### Terraform destroy fails

- Ensure all Kubernetes resources are deleted first
- Manually delete the LoadBalancer from AWS Console
- Check for any remaining resources in the VPC

## Security Best Practices (For Production)

While this project intentionally violates security best practices, here's what you should do in real applications:

1. **Keep Dependencies Updated**: Regularly update all dependencies
2. **Use Dependency Scanning**: Integrate tools like Dependabot, Snyk, or npm audit
3. **Container Scanning**: Scan all container images before deployment
4. **Least Privilege**: Use minimal IAM permissions
5. **Network Policies**: Implement Kubernetes network policies
6. **Secrets Management**: Use AWS Secrets Manager or Parameter Store
7. **Monitoring**: Implement comprehensive logging and monitoring
8. **Regular Audits**: Perform regular security audits and penetration testing

## Resources

- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [Snyk Vulnerability Database](https://snyk.io/vuln/)
- [AWS EKS Best Practices](https://aws.github.io/aws-eks-best-practices/)
- [Kubernetes Security](https://kubernetes.io/docs/concepts/security/)

## License

MIT License - See LICENSE file for details

## Disclaimer

This project is provided for educational purposes only. The maintainers are not responsible for any misuse or damage caused by this project. Always ensure you have proper authorization before conducting security testing.
