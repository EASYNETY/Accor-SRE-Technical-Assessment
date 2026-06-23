# Architecture Diagram Description

## Diagram components

- VPC with 3 public subnets and 3 private subnets across 3 AZs.
- Internet Gateway and NAT Gateways for outbound access.
- AWS ALB in public subnets receiving HTTPS traffic.
- AWS EKS cluster in private subnets with worker nodes across AZs.
- `redemption-api` pods behind an ALB target group.
- External services: Amazon Aurora Multi-AZ, ElastiCache Redis cluster, Amazon SQS FIFO, AWS Secrets Manager/SSM.
- Observability: Prometheus/Grafana, Fluent Bit shipping logs, OpenTelemetry/X-Ray.

## Data flow

1. Client traffic enters ALB.
2. ALB routes requests to `redemption-api` pods.
3. Pods authenticate to AWS services using IRSA.
4. Application reads secrets from Secrets Manager and writes metrics/logs to CloudWatch/OpenSearch.
5. During spike, HPA scales pods and Karpenter scales nodes.
6. Queue-based buffering with SQS prevents DB overload.

## Suggested diagram layout

- Top: External users and public internet.
- Middle: ALB + EKS control plane + private worker pods.
- Bottom: Data plane services (Aurora, Redis, SQS).
- Side: Observability stack and monitoring services.
