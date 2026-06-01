# 1. VPC 모듈 (별도 모듈 존재 가정)
module "vpc" {
  source = "./modules/vpc"

  # 프로젝트 공통 정보
  project      = var.project
  cluster_name = "${var.project}-cluster"

  # 네트워크 설계
  vpc_cidr      = "10.0.0.0/16"
  azs           = ["ap-northeast-2a", "ap-northeast-2c"]
  public_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_cidrs = ["10.0.3.0/24", "10.0.4.0/24"]
  db_cidrs      = ["10.0.5.0/24", "10.0.6.0/24"]
}

# 2. GitHub OIDC 모듈
module "oidc" {
  source      = "./modules/github-oidc"
  github_org  = var.github_org
  github_repo = var.github_repo
}

# 3. Bastion 모듈
module "bastion" {
  source           = "./modules/bastion"
  project          = var.project
  vpc_id           = module.vpc.vpc_id
  public_subnet_id = module.vpc.public_subnet_ids[0]
  allowed_ips      = var.allowed_ips
}

# 4. EKS 모듈
module "eks" {
  source             = "./modules/eks"
  cluster_name       = "${var.project}-cluster"
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  bastion_role_arn   = module.bastion.role_arn
}

module "ecr" {
  source       = "./modules/ecr"
  project      = var.project
  repositories = var.ecr_repositories
}

module "rds" {
  source                     = "./modules/rds"
  project                    = var.project
  vpc_id                     = module.vpc.vpc_id
  db_subnet_ids              = module.vpc.db_subnet_ids
  eks_node_security_group_id = module.eks.node_security_group_id
}

# EKS 보안그룹에 Bastion 접근 규칙 추가 (Root에서 관리)
resource "aws_security_group_rule" "bastion_to_eks" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = module.eks.cluster_security_group_id
  source_security_group_id = module.bastion.security_group_id
}
