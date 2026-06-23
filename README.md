# Redemption EKS Infrastructure

This repository contains production-grade infrastructure and deployment artifacts for the Redemption microservice on AWS EKS.

## Structure

- `infra/terraform/` - Terraform modules for VPC, EKS, monitoring, and cluster resources.
- `k8s/base/redemption/` - Kubernetes manifests for the Redemption API.
- `helm/redemption/` - Helm chart for the Redemption application.
- `.github/workflows/` - CI/CD GitHub Actions workflows.
- `observability/` - Observability configuration and dashboards.
- `docs/` - Architecture and operational docs.

## Deploy

1. Configure AWS credentials and any required secrets.
2. Run `terraform init` in `infra/terraform`.
3. Run `terraform apply` to create VPC and EKS resources.
4. Deploy the Helm chart or use Argo CD to sync the `redemption-api` app.

## Architecture & Security Highlights

- **Zero-Downtime Deployments:** Baseline deployment keeps at least 3 pods available and utilizes rolling updates with Kubernetes readiness/liveness/startup probes.
- **Security Context:** Dockerfile drops root privileges by running as a non-root user (`USER nobody`).
- **DevSecOps Pipeline:** GitHub Actions CI includes:
  - OpenID Connect (OIDC) integration for secure AWS authentication.
  - `tfsec` static analysis to scan Terraform for security misconfigurations.
  - `Trivy` container vulnerability scanning.
  - Immutable image tagging via Git commit SHAs.
- **GitOps:** Continuous Delivery is handled natively through Argo CD, syncing manifests directly from the repository.
- **Observability:** Automated setup of Prometheus and Grafana into the `monitoring` namespace.
- **Private Topology:** EKS is provisioned with a private control plane endpoint.
