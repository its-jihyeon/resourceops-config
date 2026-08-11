# ResourceOps - Config

### GitOps 기반 배포 자동화 및 AWS 비용 최적화 추천

> 이 저장소는 멋쟁이사자처럼 AWS 기반 DevOps 엔지니어 과정 팀 프로젝트(6인)의 fork 입니다. <br>
> 본 README는 담당 영역을 중심으로 재작성했습니다. <br>

<br>

원본 저장소
* **App 레포** : [team2-resourceops-app](https://github.com/CLD-05/team2-app)
* **Config 레포** : [team2-resourceops-config](https://github.com/CLD-05/team2-config)

<br>

## 프로젝트 개요

애플리케이션을 GitOps 방식으로 자동 배포하고 Prometheus와 CloudWatch 메트릭을 기반으로 

Kubernetes 리소스 비용 최적화 방향을 제시하는 프로젝트입니다.

<br>

CPU/Memory 요청량과 주요 AWS 컴포넌트 비용을 실시간으로 수집하여 현재 비용과 최적화 추천 비용을 비교 및 시각화하는 것을 핵심 목표로 합니다.

<br>

- 기간 : 2026.05.21 ~ 2026.06.01
- 팀 구성 : 6인
- 담당 : GitOps 기반 CI/CD 파이프라인 설계 및 구축

<br>

## CI/CD 다이어그램

<img width="3572" height="1492" alt="image" src="https://github.com/user-attachments/assets/9b052b9a-d28f-4665-a1a8-89e116be3321" />

<br>
<br>

## 내가 담당한 부분

### CD 파이프라인 구축
- Config Repo 이미지 태그 변경 감지 → EKS 클러스터 자동 동기화
- Kustomize 기반 환경별(dev/prod) 배포 설정 관리
- Prod 환경 selfHeal 적용 (서버 설정 임의 변경 시 자동 복구)
- 관련 코드 : `argocd/`, `apps/resource-ops/`

<br>

**[CI 파이프라인 구축](https://github.com/its-jihyeon/resourceops-app)**

<br>

## 트러블슈팅

### [ArgoCD 초기 배포 시 Namespace 부재 에러]
- 상황 : ArgoCD를 통해 EKS에 애플리케이션 배포를 시도했으나 대상 네임스페이스(resource-ops-dev)가 클러스터에 존재하지 않아 배포 실패 에러 발생
- 원인 분석 : 쿠버네티스는 리소스를 생성할 때 해당 네임스페이스가 미리 존재해야 하지만 초기 클러스터 환경이라 생성된 네임스페이스가 없음을 파악
- 시도한 방법 : kubectl 명령어로 수동 생성하는 대신 자동으로 처리할 수 있는 ArgoCD의 동기화 옵션을 조사
- 최종 해결 : ArgoCD 매니페스트에 syncOptions: - CreateNamespace=true 옵션을 적용하고 Prod 환경에도 선제적으로 반영
- 배운 점 : 네임스페이스 생성 같은 기초 세팅까지 터미널 수동 작업 없이 코드로 자동화하는 완전한 GitOps 파이프라인을 체득

<br>

## 기술 스택

GitHub Actions · ArgoCD · Kustomize · AWS ECR
