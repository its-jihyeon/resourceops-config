# 생성 리소스:
#   - module.ebs_csi_irsa       : EBS CSI Driver용 IRSA Role
#     -> ebs-csi-controller-sa ServiceAccount에 EBS 관리 권한 부여
#   - module.alb_controller_irsa: ALB Controller용 IRSA Role
#     -> aws-load-balancer-controller SA에 ALB 생성/관리 권한 부여
#   - module.eks                : EKS 클러스터 + 노드 그룹
#     -> cluster_endpoint_public_access = false (실무 표준 — API 서버 외부 차단)
#     -> Bastion SG에서만 443 접근 허용
#     -> 애드온: vpc-cni, coredns, kube-proxy, aws-ebs-csi-driver

# EBS CSI Driver IRSA
module "ebs_csi_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.48"

  role_name             = "${var.cluster_name}-ebs-csi-driver"
  attach_ebs_csi_policy = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
    }
  }
  tags = { team = "team2" }
}

# ALB Controller IRSA
module "alb_controller_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.48"

  role_name                              = "${var.cluster_name}-alb-controller"
  attach_load_balancer_controller_policy = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-load-balancer-controller"]
    }
  }
  tags = { team = "team2" }
}

# EKS 클러스터
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.31"

  cluster_name    = var.cluster_name
  cluster_version = "1.35"
  vpc_id          = var.vpc_id
  subnet_ids      = var.private_subnet_ids

  # 실무 설정 — API 서버 퍼블릭 접근 차단
  cluster_endpoint_public_access  = false
  cluster_endpoint_private_access = true

  access_entries = {
    bastion = {
      principal_arn = var.bastion_role_arn

      policy_associations = {
        admin = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
  }


  cluster_addons = {
    vpc-cni = {
      most_recent = true
    }
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    aws-ebs-csi-driver = {
      most_recent              = true
      service_account_role_arn = module.ebs_csi_irsa.iam_role_arn
    }
  }

  eks_managed_node_groups = {
    general = {
      instance_types = [var.node_instance_type]
      ami_type       = "AL2023_x86_64_STANDARD"
      min_size       = var.node_min
      max_size       = var.node_max
      desired_size   = var.node_desired
      disk_size      = 30

      labels = {
        role = "general"
      }

      # Cluster Autoscaler 자동 탐지 태그
      tags = {
        "k8s.io/cluster-autoscaler/enabled"             = "true"
        "k8s.io/cluster-autoscaler/${var.cluster_name}" = "owned"
        team                                            = "team2"
      }
    }
  }


  enable_cluster_creator_admin_permissions = true

  tags = {
    ManagedBy = "terraform"
    team      = "team2"
  }
}

# ESO용 SSM Parameter Read Policy (사용자 정의)
resource "aws_iam_policy" "eso" {
  name        = "${var.cluster_name}-eso-policy"
  description = "External Secrets Operator: SSM Parameter Read + KMS Decrypt"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath",
          "ssm:DescribeParameters"
        ]
        Resource = "arn:aws:ssm:${var.aws_region}:*:parameter/${var.cluster_name}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt"
        ]
        Resource = "arn:aws:kms:${var.aws_region}:*:key/*"
      }
    ]
  })
}

# ESO IRSA
module "eso_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.48"

  role_name = "${var.cluster_name}-eso"
  role_policy_arns = {
    eso = aws_iam_policy.eso.arn
  }

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["external-secrets:external-secrets-sa"]
    }
  }
}


# CloudWatch Reader IRSA
module "cloudwatch_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.48"

  role_name = "${var.cluster_name}-cloudwatch-reader"
  role_policy_arns = {
    cloudwatch = aws_iam_policy.cloudwatch_reader.arn
  }

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["resource-ops-dev:resource-app-sa"]
    }
  }
  tags = { team = "team2" }
}

resource "aws_iam_policy" "cloudwatch_reader" {
  name        = "${var.cluster_name}-cloudwatch-reader-policy"
  description = "CloudWatch GetMetricStatistics for resource optimization"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["cloudwatch:GetMetricStatistics"]
      Resource = "*"
    }]
  })

  tags = { team = "team2" }
}
