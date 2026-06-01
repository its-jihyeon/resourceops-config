# Platform Prerequisites

Application overlays depend on AWS Load Balancer Controller Gateway API support
and External Secrets Operator.

## Gateway API and ALB Controller

AWS Load Balancer Controller must be version 2.14.0 or newer for ALB-backed
`HTTPRoute` support. Install the required CRDs before applying the application:

```bash
kubectl apply --server-side=true -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.5.0/standard-install.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/refs/heads/main/config/crd/gateway/gateway-crds.yaml
```

Install the controller using the IRSA role output from Terraform and
`aws-load-balancer-controller/values.example.yaml`, then apply the shared class:

```bash
kubectl apply -k platform/gateway-api
```

The application creates an internet-facing ALB through `Gateway`,
`LoadBalancerConfiguration`, `TargetGroupConfiguration`, and `HTTPRoute`.
Targets use VPC CNI pod IPs and the health check path
`/actuator/health/readiness`.

## External Secrets Operator

Install ESO with the `external-secrets-sa` service account and the
`eso_role_arn` Terraform output, using `external-secrets/values.example.yaml`.
The shared store uses the ESO controller IRSA identity to read SSM Parameter
Store:

```bash
kubectl apply -k platform/external-secrets
```

Create SecureString parameters matching the deployment environment:

```text
/team2-project-cluster/resource-ops/dev/SPRING_DATASOURCE_URL
/team2-project-cluster/resource-ops/dev/SPRING_DATASOURCE_USERNAME
/team2-project-cluster/resource-ops/dev/SPRING_DATASOURCE_PASSWORD
```

Use `/prod/` instead of `/dev/` for the production overlay.

## Render and Verify

```bash
kubectl kustomize apps/resource-ops/overlays/dev
kubectl apply -k apps/resource-ops/overlays/dev
kubectl -n resource-ops-dev get deploy,pod,service,externalsecret,gateway,httproute
kubectl -n resource-ops-dev get gateway resource-app-gateway -o jsonpath='{.status.addresses[0].value}'
```
