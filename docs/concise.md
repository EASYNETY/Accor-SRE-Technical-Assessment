# Redemption Architecture Executive Summary

## 1. Executive Summary
This document outlines the architectural decisions, operational strategies, and team delegation plan for "The Redemption," a business-critical point-deduction microservice on AWS. The design prioritizes zero-downtime, rapid elasticity during 10x traffic spikes (Flash Sales), and strict security boundaries using Infrastructure-as-Code (Terraform) and Kubernetes.

## 2. Architectural Decisions & Scalability Strategy
To meet the rigorous availability and scaling constraints, the architecture leverages managed AWS services and Kubernetes-native scaling mechanisms:

*   **Compute & Architecture:** The microservice is containerized and hosted on Amazon EKS. The EKS cluster spans three Availability Zones (AZs) in a single region to survive localized outages. An AWS Application Load Balancer (ALB) serves as the ingress point, routing traffic intelligently to healthy pods.
*   **Handling 10x Flash Sales:** 
    *   **Application Tier:** A Horizontal Pod Autoscaler (HPA) monitors CPU and Memory metrics, automatically scaling the `redemption-api` deployment when utilization crosses 70%.
    *   **Infrastructure Tier:** Karpenter (or AWS Cluster Autoscaler) detects pending pods and rapidly provisions right-sized EC2 instances to meet the surge, scaling back down when traffic subsides to optimize costs.
*   **State Buffering:** To prevent database connection exhaustion during flash sales, incoming deduction requests are buffered through an Amazon SQS FIFO queue before being asynchronously committed to the multi-AZ Aurora PostgreSQL database.

## 3. Security & Networking
The infrastructure embodies "Defense in Depth" and "Least Privilege":
*   **Network Isolation:** Worker nodes and databases reside exclusively in private subnets with no direct internet ingress. EKS API endpoint access is restricted.
*   **Least Privilege:** Broad EC2 instance profiles are avoided. Instead, IAM Roles for Service Accounts (IRSA) grants the `redemption-api` pods granular, exact permissions (e.g., specific SQS queue access).
*   **Encryption & Traffic Flow:** Data is encrypted at rest using AWS KMS. Ingress traffic is strictly controlled by Kubernetes Network Policies, ensuring the database can only be queried by authorized application pods.

## 4. Reliability & Observability
*   **Self-Healing:** Kubernetes liveness and readiness probes automatically restart unhealthy containers. A PodDisruptionBudget (PDB) guarantees a minimum number of replicas remain available during voluntary disruptions or cluster upgrades.
*   **Metrics & Tracing:** The `monitoring` namespace houses a fully automated Prometheus and Grafana stack, providing real-time dashboards for queue depth, pod resource usage, and API latency. OpenTelemetry is recommended for distributed tracing to identify bottlenecks during high load.

## 5. Architectural Trade-offs
*   **EKS vs. Serverless (Fargate/Lambda):** While serverless removes node management, EKS on EC2 was chosen for lower latency at high scale and absolute control over network routing and ingress, which is vital during intense flash sales.
*   **Asynchronous Processing:** Using SQS introduces eventual consistency. The user's point balance may take a few seconds to update during extreme spikes, traded off against the guarantee that the database won't crash and cause a total service failure.

## 6. Day 2 Operations & Team Delegation
To minimize operational toil, all deployments are managed via GitOps (ArgoCD) and Infrastructure-as-Code. 

**Implementation Task Assignment (3 Engineers):**

*   **Senior Engineer (Lead):** 
    *   *Focus:* Architecture, Security, and IaC Foundation.
    *   *Tasks:* Develop the core Terraform modules (VPC, EKS, IAM), establish the OIDC provider for IRSA, and define the overall network security boundaries. Responsible for reviewing junior engineers' pull requests.
*   **Junior Engineer 1 (Application & Deployment):**
    *   *Focus:* Kubernetes Manifests and CI/CD.
    *   *Tasks:* Containerize the `redemption-api` (Dockerfile), write Kubernetes Deployments, Services, and Ingress rules. Set up the GitHub Actions pipeline for automated image building and ArgoCD synchronization.
*   **Junior Engineer 2 (Observability & Scaling):**
    *   *Focus:* Reliability and Monitoring.
    *   *Tasks:* Implement the Horizontal Pod Autoscaler (HPA) and PodDisruptionBudget (PDB). Deploy the Prometheus/Grafana stack using Helm, and configure dashboards/alerts for high CPU utilization or queue depth buildup.
