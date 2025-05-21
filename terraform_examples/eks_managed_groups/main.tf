locals {
  # replace to your AWS account number 
  aws_account = "123456789123"
  # replace to your AWS region name 
  region = "us-east-1"
  # change to desired eks name
  eks_name = "satori-cluster"
  # EKS version
  cluster_version = "1.32"
  # Provide your VPC ID
  vpc_id = "vpc-1a1a1a1a1a1a1a1"
  # Provide 3 Subnet IDs .Should be 3 private |subnets in 3 diffrent Zones for HA
  private_subnet_ids = ["subnet-2b2b2b2b2b2b2b", "subnet-3c3c3c3c3c3c3c3c", "subnet-4e4e4e4e4e4e4e4e4e"]

  # additional resource reservation for EKS nodes 
  eks_default_node_config = <<-EOT
          ---
          apiVersion: node.eks.aws/v1alpha1
          kind: NodeConfig
          spec:
            kubelet:
              config:
                kubeReserved:
                  cpu: 100m
                  memory: 850Mi
                systemReserved:
                  cpu: 100m
                  memory: 300Mi
                evictionHard:
                  memory.available: 400Mi
        EOT
  # instance type
  instance_types = ["m6i.large"]
  tags = {
    eks = local.eks_name
  }
}



provider "aws" {
  region              = local.region
  allowed_account_ids = [local.aws_account]
}


################################################################################
# EKS Module
################################################################################
# See all possbile paramateres for that module here https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/latest
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.36.0"

  eks_managed_node_groups = {
    # Default node group - as provided by AWS EKS
    node_group_0 = {
      subnet_ids = [local.private_subnet_ids[0]]
    }
    node_group_1 = {
      subnet_ids = try([local.private_subnet_ids[1]], [local.private_subnet_ids[0]])
    }
    node_group_2 = {
      subnet_ids = try([local.private_subnet_ids[2]], [local.private_subnet_ids[0]])
    }
  }
  cluster_name                             = local.eks_name
  cluster_version                          = local.cluster_version
  cluster_endpoint_public_access           = true
  cluster_endpoint_private_access          = true
  authentication_mode                      = "API_AND_CONFIG_MAP"
  enable_cluster_creator_admin_permissions = true
  enable_irsa                              = true

  cluster_addons = {
    coredns = {
      most_recent = true
      tags        = {}
    }
    kube-proxy = {
      most_recent = true
      tags        = {}
    }
    vpc-cni = {
      most_recent              = true
      before_compute           = true
      service_account_role_arn = module.vpc_cni_irsa.iam_role_arn
      tags                     = {}
      configuration_values = jsonencode({
        env = {
          # don't reserve too many IP addresses
          # Reference docs https://docs.aws.amazon.com/eks/latest/userguide/cni-increase-ip-addresses.html
          ENABLE_PREFIX_DELEGATION = "true"
          WARM_PREFIX_TARGET       = "1"
        }
      })
    }
    aws-ebs-csi-driver = {
      most_recent              = true
      service_account_role_arn = module.vpc_csi_ebs_irsa.iam_role_arn
      tags                     = {}
      configuration_values = jsonencode({
        "defaultStorageClass" : { "enabled" : true }
      })
    }
    eks-node-monitoring-agent = {
      most_recent = true
      tags        = {}
    }
  }




  vpc_id     = local.vpc_id
  subnet_ids = local.private_subnet_ids


  eks_managed_node_group_defaults = {
    ami_type                   = "AL2023_x86_64_STANDARD"
    instance_types             = local.instance_types
    disk_size                  = 50
    tags                       = local.tags
    ebs_optimized              = true
    labels                     = {}
    enable_bootstrap_user_data = false
    node_repair_config = {
      enabled = true
    }
    metadata_options = {
      http_endpoint               = "enabled"
      http_tokens                 = "required"
      http_put_response_hop_limit = 2
    }
    create_launch_template     = true
    min_size                   = 1
    max_size                   = 3
    desired_size               = 1
    iam_role_attach_cni_policy = false
    use_name_prefix            = true
    cloudinit_pre_nodeadm = [
      {
        content_type = "application/node.eks.aws"
        content      = local.eks_default_node_config
      }
    ]

    block_device_mappings = {
      xvda = {
        device_name = "/dev/xvda"
        ebs = {
          delete_on_termination = true
          encrypted             = true
          volume_size           = 50
          volume_type           = "gp3"
        }
      }
    }

  }


}


################################################################################
# IAM role for CNI plugin
################################################################################

module "vpc_cni_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name_prefix      = "VPC-CNI-IRSA"
  attach_vpc_cni_policy = true
  vpc_cni_enable_ipv4   = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-node"]
    }
  }

  tags = local.tags
}

################################################################################
# IAM role for CSI EBS addon driver
################################################################################
module "vpc_csi_ebs_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name_prefix      = "CSI-EBS-IRSA"
  attach_ebs_csi_policy = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
    }
  }
  tags = local.tags

}


################################################################################
# Optional resoruce for DAC and AWS ingeration features
################################################################################
################################################################################
# DAC Role trusting policy
################################################################################
data "aws_iam_policy_document" "dac_role_assume_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [module.eks.oidc_provider_arn]
    }
    condition {
      test     = "StringLike"
      variable = "${replace(module.eks.oidc_provider_arn, "/^(.*provider/)/", "")}:sub"
      values   = ["system:serviceaccount:satori-runtime:*"]
    }
  }
}
################################################################################
# Optional resoruce for DAC and AWS ingeration features
################################################################################
################################################################################
# DAC Role permission policy
################################################################################
resource "aws_iam_policy" "assume_dac_service_role_policy" {
  name        = "${local.eks_name}-AssumeDACServiceRole"
  path        = "/"
  description = "AssumeCrossAccountRoles"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "sts:AssumeRole"
      ],
      "Resource": [
        "arn:aws:iam::*:role/${local.eks_name}-service-role"
      ]
    }
  ]
}
EOF
}

################################################################################
# Optional resoruce for DAC and AWS ingeration features
################################################################################
################################################################################
# DAC IAM Role 
################################################################################
resource "aws_iam_role" "dac_role" {
  name                = "${local.eks_name}-role"
  path                = "/"
  assume_role_policy  = data.aws_iam_policy_document.dac_role_assume_policy.json
  managed_policy_arns = [aws_iam_policy.assume_dac_service_role_policy.arn]
  description         = "Role used by Satori DAC to call cloud APIs"

  tags = local.tags
}
