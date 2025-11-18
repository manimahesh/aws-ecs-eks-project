# Fix for GitHub Actions Authentication Error

## Problem
GitHub Actions fails with error: `error: You must be logged in to the server (the server has asked for the client to provide credentials)`

## Root Cause
The GitHub Actions IAM role doesn't have permission to access the EKS cluster's Kubernetes API. The EKS cluster uses AWS IAM authentication, and the role needs to be added to the `aws-auth` ConfigMap in the `kube-system` namespace.

## Solution Applied

### 1. Updated Terraform Configuration

**File: [terraform/main.tf](terraform/main.tf)**
- Added Kubernetes provider to the required providers

**File: [terraform/eks-auth.tf](terraform/eks-auth.tf)** (NEW)
- Created Kubernetes provider configuration
- Added `kubernetes_config_map_v1_data` resource to manage the `aws-auth` ConfigMap
- Grants the GitHub Actions IAM role `system:masters` permissions to deploy to the cluster

### 2. How to Apply the Fix

If you've already deployed the infrastructure:

```bash
cd terraform

# Reinitialize Terraform to download the Kubernetes provider
terraform init -upgrade

# Apply the changes
terraform apply
```

This will:
1. Install the Kubernetes provider
2. Create/update the `aws-auth` ConfigMap in EKS
3. Grant the GitHub Actions role access to the cluster

### 3. Verify the Fix

After applying, check that the ConfigMap was created:

```bash
# Configure kubectl
aws eks update-kubeconfig --region us-west-2 --name vulnerable-app-demo

# View the aws-auth ConfigMap
kubectl get configmap aws-auth -n kube-system -o yaml
```

You should see both the node role and the GitHub Actions role listed.

### 4. Retry GitHub Actions

Once Terraform has been applied:
1. Go to your GitHub repository
2. Navigate to Actions
3. Click on "Build and Deploy to EKS"
4. Click "Run workflow" to trigger manually
5. The deployment should now succeed

## What Changed

The `aws-auth` ConfigMap now includes two roles:

1. **EKS Node Role** - Allows EC2 instances to join the cluster as nodes
2. **GitHub Actions Role** - Allows the CI/CD pipeline to deploy applications

Both roles are necessary for the cluster to function properly.

## Alternative Manual Fix

If you prefer not to use Terraform for this, you can manually update the ConfigMap:

```bash
kubectl edit configmap aws-auth -n kube-system
```

Add this to the `mapRoles` section (replace with your actual GitHub Actions role ARN):

```yaml
- rolearn: arn:aws:iam::YOUR_ACCOUNT_ID:role/vulnerable-app-demo-github-actions
  username: github-actions
  groups:
    - system:masters
```

## Security Note

The GitHub Actions role is granted `system:masters` permissions for simplicity in this demo. In production:
- Create a dedicated Kubernetes role with minimal permissions
- Use Kubernetes RBAC to limit what the CI/CD pipeline can do
- Consider using different roles for different namespaces
