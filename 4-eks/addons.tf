# Cluster Autoscaler
resource "helm_release" "cluster_autoscaler" {
  count      = var.enable_cluster_autoscaler ? 1 : 0
  name       = "cluster-autoscaler"
  repository = "https://kubernetes.github.io/autoscaler"
  chart      = "cluster-autoscaler"
  namespace  = "kube-system"

  values = [<<EOT
autoDiscovery:
  clusterName: ${var.cluster_name}
awsRegion: ${var.region}
rbac:
  serviceAccount:
    create: true
    name: cluster-autoscaler
EOT
  ]
}

# AWS Load Balancer Controller
resource "helm_release" "aws_lb_controller" {
  count      = var.enable_aws_lb_controller ? 1 : 0
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"

  values = [<<EOT
clusterName: ${var.cluster_name}
serviceAccount:
  create: true
  name: aws-load-balancer-controller
EOT
  ]
}