################################################################################
# IAM role for ELB controller
################################################################################
module "lb_controller_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name                              = "${local.eks_name}-lb-cotroller-role"
  attach_load_balancer_controller_policy = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-load-balancer-controller"]
    }
  }
  tags = local.tags
}

################################################################################
# IAM role for cluster autoscaler
################################################################################
module "cluster_autoscaler_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name                        = "${local.eks_name}-cluster-autoscaler-role"
  attach_cluster_autoscaler_policy = true
  cluster_autoscaler_cluster_names = [local.eks_name]

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:cluster-autoscaler"]
    }
  }
  tags = local.tags
}

################################################################################
# Deploy  ELB controller
################################################################################

resource "helm_release" "aws_load_balancer_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  version    = "1.5.5"
  namespace  = "kube-system"


  set {
    name  = "clusterName"
    value = local.eks_name
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.lb_controller_irsa.iam_role_arn
  }
}

################################################################################
# Deploy metrics server
################################################################################
resource "helm_release" "metrics_server" {
  name       = "metrics-server"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  namespace  = "kube-system"
}


################################################################################
# Deploy   cluster autoscaler
################################################################################
resource "helm_release" "cluster_autoscaler" {
  name       = "cluster-autoscaler"
  repository = "https://kubernetes.github.io/autoscaler"
  chart      = "cluster-autoscaler"
  version    = "9.29.1"
  namespace  = "kube-system"


  values = [
    "${file("${path.module}/cluster-autoscaler.yaml")}"
  ]


  set {
    name  = "autoDiscovery.clusterName"
    value = local.eks_name
  }
  set {
    name  = "awsRegion"
    value = local.region
  }
  set {
    name  = "rbac.serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.cluster_autoscaler_irsa.iam_role_arn
  }
}