# Redemption AWS EKS Architecture

## Goals

- Global business-critical availability
- Zero downtime for flash sale traffic spikes
- Automated scaling and recovery
- Strong security and least-privilege access

## Architecture Summary

- EKS cluster deployed across 3 AZs in a single region.
- Managed VPC with public subnets for ALB and private subnets for worker nodes.
- Private EKS API endpoint with VPC endpoints for AWS services.
- AWS ALB ingress using AWS Load Balancer Controller.
- Managed Aurora Multi-AZ and ElastiCache Redis external state.
- SQS FIFO for buffering high-concurrency request processing.
- Prometheus and Grafana for metrics, Fluent Bit for logs, OpenTelemetry/X-Ray for tracing.

## Key Components

- `infra/terraform/modules/vpc` - VPC network, NAT, subnets, and endpoints.
- `infra/terraform/modules/eks` - EKS cluster, node groups, IAM roles, and addons.
- `k8s/base/redemption` - Service account, deployment, HPA, PDB, network policy, and ingress.
- `helm/redemption` - Parameterized Helm chart for app deployment.
- `.github/workflows` - CI build and Argo CD deploy pipelines.

## Availability and Resilience

- AZ redundancy with 3 private and 3 public subnets.
- Deployment configured with rolling updates to avoid downtime.
- HPA and Karpenter recommendation for elastic 10x scaling.
- PodDisruptionBudget ensures at least 2 pods remain available during maintenance.
