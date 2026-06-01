# team-config

ResourceOps의 설정 레포지토리입니다.

## 역할

- Kubernetes Manifest 관리
- Terraform Infrastructure 관리
- ArgoCD GitOps 배포 관리
- 환경(dev/prod) Overlay 관리

## 디렉토리 구조

```bash
apps/
 └── resource-app/
     ├── base/
     └── overlays/

argocd/
infra/
monitoring/
 └── values.yaml
