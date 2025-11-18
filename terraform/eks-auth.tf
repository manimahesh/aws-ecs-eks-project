# Kubernetes provider configuration
data "aws_eks_cluster_auth" "main" {
  name = aws_eks_cluster.main.name
}

provider "kubernetes" {
  host                   = aws_eks_cluster.main.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.main.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.main.token
}

# ConfigMap to allow GitHub Actions IAM role to access EKS
resource "kubernetes_config_map_v1_data" "aws_auth" {
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data = {
    mapRoles = yamlencode([
      {
        rolearn  = aws_iam_role.eks_nodes.arn
        username = "system:node:{{EC2PrivateDNSName}}"
        groups = [
          "system:bootstrappers",
          "system:nodes"
        ]
      },
      {
        rolearn  = aws_iam_role.github_actions.arn
        username = "github-actions"
        groups = [
          "system:masters"
        ]
      }
    ])
  }

  force = true

  depends_on = [
    aws_eks_cluster.main,
    aws_eks_node_group.main
  ]
}
