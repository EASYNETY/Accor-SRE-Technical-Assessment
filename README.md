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

### Prerequisites
- AWS CLI installed and configured.
- `terraform.exe` (provided in the root directory for Windows, or use your own Terraform installation).
- `helm` installed for managing charts.

### Exact Steps Used for Deployment

1. **Helm Repository Setup:**
   Add necessary Helm repositories before running Terraform to ensure the observability stack can be deployed:
   ```bash
   helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
   helm repo add grafana https://grafana.github.io/helm-charts
   helm repo update
   ```

2. **Provision Infrastructure with Terraform:**
   Navigate to the terraform directory:
   ```bash
   cd infra/terraform
   ```
   
   Initialize the Terraform working directory:
   ```bash
   ..\..\terraform.exe init
   ```
   
   Generate an execution plan:
   ```bash
   ..\..\terraform.exe plan -out=tfplan
   ```
   
   Apply the execution plan:
   ```bash
   ..\..\terraform.exe apply "tfplan"
   ```

3. **Accessing the Cluster:**
   After successful deployment, update your kubeconfig to interact with the new EKS cluster:
   ```bash
   aws eks update-kubeconfig --region eu-west-1 --name redemption-eks-cluster
   ```

4. **Deploy the Application (Helm):**
   Deploy the Redemption API Helm chart to the cluster:
   ```bash
   cd ../../helm
   helm upgrade --install redemption-api ./redemption -n default
   ```

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
