#   - aws_security_group        : Bastion SG (인바운드: 내 IP만 22 허용)
#   - data.aws_ami              : 최신 Ubuntu 24.04 LTS AMI 자동 조회
#   - aws_instance              : Bastion EC2 (user_data로 도구 자동 설치)
#   - aws_iam_instance_profile  : Bastion용 IAM 프로파일 (EKS 접근 권한)
#   - aws_iam_role              : Bastion IAM Role
#   - aws_iam_role_policy_attachment: AmazonEKSClusterPolicy 연결


resource "aws_key_pair" "bastion" {
  key_name   = var.key_name
  public_key = ""

  tags = {
    Name = "team2-key"
    team = "team2"
  }
}

# Bastion 보안그룹 — 규칙 없이 SG만 생성
resource "aws_security_group" "bastion" {
  name        = "${var.project}-bastion-sg"
  description = "Bastion EC2 Security Group"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.project}-bastion-sg"
  }
}

# SSH 인바운드 규칙 분리
resource "aws_security_group_rule" "bastion_ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = var.allowed_ips
  security_group_id = aws_security_group.bastion.id
  description       = "SSH from allowed IPs"
}

# 아웃바운드 규칙 분리
resource "aws_security_group_rule" "bastion_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.bastion.id
  description       = "Allow all outbound traffic"
}

# 최신 Ubuntu 24.04 LTS AMI 자동 조회
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Bastion EC2
resource "aws_instance" "bastion" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = var.public_subnet_id
  key_name                    = aws_key_pair.bastion.key_name
  vpc_security_group_ids      = [aws_security_group.bastion.id]
  iam_instance_profile        = aws_iam_instance_profile.bastion.name
  associate_public_ip_address = true


  # Bastion에 필요한 도구 자동 설치
  # Ubuntu 24.04: apt 저장소에서 awscli 제거됨 -> 공식 바이너리 설치 필요
  # user_data 설치 목록: unzip, curl, jq, AWS CLI v2, kubectl, helm
  user_data = <<-EOF
    #!/bin/bash
    set -e
    apt-get update -y

    # 필수 유틸리티 설치 (unzip 없으면 AWS CLI 압축 해제 불가)
    apt-get install -y unzip curl jq

    # AWS CLI v2 설치 (공식 바이너리)
    # Ubuntu 24.04는 apt 저장소에서 awscli 미제공 -> 아래 공식 방법으로 설치
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" \
      -o "/tmp/awscliv2.zip"
    unzip -q /tmp/awscliv2.zip -d /tmp
    /tmp/aws/install
    rm -rf /tmp/aws /tmp/awscliv2.zip

    # kubectl 설치 (안정 버전 자동 조회)
    KUBECTL_VER=$(curl -L -s https://dl.k8s.io/release/stable.txt)
    curl -LO "https://dl.k8s.io/release/$${KUBECTL_VER}/bin/linux/amd64/kubectl"
    install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
    rm kubectl

    # helm 설치 (ALB Controller 설치용)
    curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

    # 설치 완료 로그
    echo "Bastion 초기화 완료: $(date)" >> /var/log/bastion-init.log
    aws --version >> /var/log/bastion-init.log 2>&1
    kubectl version --client >> /var/log/bastion-init.log 2>&1
    helm version --short >> /var/log/bastion-init.log 2>&1
    EOF

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
    encrypted   = true
  }

  tags = {
    Name = "${var.project}-bastion"
    team = "team2"
  }

  volume_tags = {
    Name = "${var.project}-bastion"
    team = "team2"
  }
}

# Bastion IAM Role — EKS kubeconfig 업데이트용
resource "aws_iam_instance_profile" "bastion" {
  name = "${var.project}-bastion-profile"
  role = aws_iam_role.bastion.name
}

resource "aws_iam_role_policy_attachment" "bastion_ecr_access" {
  role       = aws_iam_role.bastion.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}


resource "aws_iam_role" "bastion" {
  name = "${var.project}-bastion-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

# [수정] 최소 권한의 원칙: 조회 전용 권한만 부여
resource "aws_iam_role_policy" "bastion_eks_access" {
  name = "${var.project}-bastion-eks-access"
  role = aws_iam_role.bastion.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["eks:DescribeCluster", "eks:ListClusters", "eks:DescribeNodegroup", "eks:ListNodegroups"]
      Resource = "*"
    }]
  })
}
