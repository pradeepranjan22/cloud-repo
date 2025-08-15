# cloud-repo
Control Tower Landing Zone (IaC) — A Comprehensive Guide for Cloud Solutions Architects 🚀

Purpose: This document serves as a comprehensive, end-to-end technical reference for establishing a production-ready AWS Landing Zone. The implementation is based on AWS Control Tower and is managed entirely through Infrastructure as Code (IaC) using Terraform. Designed for storage in a version control system (like Git) and for collaborative platforms (like Confluence), it includes architectural best practices, a detailed repository structure, a modern GitOps workflow with ArgoCD, operational runbooks, and key considerations for interview scenarios.

Table of Contents

1. Overview & Goals
2. Architecture (Conceptual)
3. Assumptions & Prerequisites
4. Recommended Tools & Versions
5. Repo Structure (Detailed)
6. Terraform Modules & Key Resources
7. Bootstrap (Management Account) — Declarative Steps
8. Deployment Workflow — Step-by-Step
9. Networking (Hub & Spoke) — IaC
10. Security Tooling — IaC
11. Account Vending — Account Factory for Terraform (AFT)
12. CI/CD (GitOps) — A Dual-Pipeline Approach
13. Variables, Secrets & Backends
14. Testing, Validation & Rollback
15. Costs & Estimation Guidance
16. Operational Runbook & Checklist
17. Troubleshooting & FAQ
18. Appendix: Example Terraform Snippets & Templates

1. Overview & Goals
   
Goal: To architect and implement a secure, scalable, and fully automated AWS Landing Zone that serves as the standardized foundation for all production workloads. The objective is to establish a governance and security framework from the outset, enabling development teams to innovate securely and at scale while minimizing operational overhead.

Key Deliverables:

A multi-account structure with clear Organizational Unit (OU) separation to enforce logical isolation.

Centralized logging and security monitoring to ensure a clear audit trail and proactive threat detection.

A robust, hub-and-spoke network topology that simplifies network management and provides centralized traffic control.

Automated account provisioning via Account Factory for Terraform (AFT) to streamline the onboarding of new teams and projects.

A modern GitOps pipeline that strictly separates infrastructure deployment from application deployment using ArgoCD for enhanced control and security.

Outcomes: A production-ready cloud environment that enforces security guardrails from day one, minimizes operational overhead, and provides a solid foundation for deploying diverse workloads.

2. Architecture (Conceptual)
The architecture is built upon a hierarchical structure within AWS Organizations. This logical separation is a cornerstone of a well-architected framework, ensuring governance, isolation, and simplified billing.

AWS Organization Root (Management Account)
│
├─ Security OU
│   ├─ Log Archive Account (Centralized logging for CloudTrail and AWS Config)
│   └─ Security Tooling Account (Centralized security monitoring with GuardDuty and Security Hub)
│
├─ Infrastructure OU
│   ├─ Network Account (Hosts the Transit Gateway and a hub VPC)
│   └─ DevOps Account (Hosts the ArgoCD Kubernetes cluster and CI pipeline runners)
│
└─ Workloads OU
    ├─ Prod OU -> Production Accounts (for mission-critical applications)
    ├─ Dev OU -> Development Accounts (for application development and testing)
    └─ Sandbox OU -> Sandbox Accounts (for experimentation and research)

Key Architectural Flows:

Centralized Logging: All AWS service logs (e.g., CloudTrail, VPC Flow Logs) are aggregated into a highly-secured S3 bucket in the Log Archive account.

Centralized Security: Security services are configured to report their findings to the Security Tooling account, providing a single pane of glass for security posture management.

Hub-and-Spoke Networking: The TGW in the Network account acts as a central hub, enabling secure and scalable connectivity between VPCs in different workload accounts (the "spokes").

GitOps for Applications: ArgoCD, running in the DevOps account, continuously pulls application manifests from a Git repository and deploys them to Amazon EKS clusters in the workload accounts.

3. Assumptions & Prerequisites
A single AWS Management Account with administrative and billing access.

A registered domain for generating unique email addresses for new accounts.

Terraform v1.4+ and AWS provider v5.x+ are installed in the CI runner.

Two dedicated Git repositories: one for infrastructure (infrastructure-repo) and another for application manifests (application-repo).

A CI runner (e.g., GitHub Actions, GitLab CI) with an IAM OIDC provider to securely assume roles.

The necessary IAM permissions to create foundational AWS resources.

4. Recommended Tools & Versions
IaC: Terraform v1.4+

AWS Provider: v5.x+

Account Vending: Account Factory for Terraform (AFT)

Application CD: ArgoCD

CI Runner: GitHub Actions, GitLab CI, or Jenkins

CLI: AWS CLI v2

Optional Testing: Terratest (Go)

5. Repo Structure (Detailed)
A dual-repository model provides a clean separation of responsibilities, preventing "GitOps" for applications from interfering with "CI/CD" for infrastructure.

infrastructure-repo: For all Terraform configurations.
landing-zone/
├── 0-bootstrap/         # S3 backend, DynamoDB locks, initial IAM roles
├── 1-control-tower/     # Control Tower deployment and OU definitions
├── 2-networking/        # Transit Gateway, Hub & Spoke VPCs
├── 3-security/          # GuardDuty, Security Hub, CloudTrail config
├── 4-eks/               # EKS cluster provisioning with IRSA
├── 5-aft/               # Account Factory for Terraform definitions
├── modules/             # Reusable Terraform modules
├── pipeline/            # CI/CD pipeline definitions
└── README.md
application-repo: For Kubernetes manifests and ArgoCD configurations.
apps-gitops/
├── projects/            # ArgoCD AppProject resources for RBAC
├── applications/        # ArgoCD Application resources linking Git to clusters
├── charts/              # Helm charts for microservices
├── manifests/           # Environment-specific Kubernetes manifests
└── README.md
6. Terraform Modules & Key Resources
Core Modules:

modules/ou: Creates OUs and manages attachments.

modules/scp: Defines and attaches Service Control Policies (SCPs).

modules/vpc: A reusable module for creating hub and spoke VPCs.

modules/security-tools: Configures organization-wide security services.

modules/eks: Provisions a secure EKS cluster with IAM Roles for Service Accounts (IRSA) enabled for fine-grained access control.

Key AWS Resources:

aws_controltower_landing_zone: The primary resource for deploying Control Tower.

aws_organizations_policy: Used to attach and manage SCPs.

aws_eks_cluster, aws_eks_node_group: Resources for managing EKS clusters.

aws_iam_openid_connect_provider: A crucial resource for enabling IRSA.

7. Bootstrap (Management Account) — Declarative Steps
This phase sets up the core components in the Management Account.

Objective: Establish a secure backend for Terraform state, enable AWS Organizations, and create the initial IAM roles that the CI pipeline will assume.

Terraform Backend: Create an S3 bucket for state files and a DynamoDB table for state locking.

Enable AWS Organizations: Use the aws_organizations_organization resource.

IAM Roles: Create a terraform-deployer IAM role with a trust policy that allows your CI runner to assume it.

8. Deployment Workflow — Step-by-Step
The deployment of the landing zone is a sequential, multi-stage process managed by a CI/CD pipeline. Each step builds on the previous one.

Stage 0: Bootstrap:

Action: Manually execute terraform apply on the 0-bootstrap/ workspace from a local machine or a trusted CI environment.

Outcome: The S3 bucket for Terraform state and the DynamoDB table for locks are created in the Management Account.

Stage 1: Foundational Services:

Action: The CI/CD pipeline, triggered by a commit to 1-control-tower/, assumes the terraform-deployer role. It runs terraform init, plan, and apply to enable Control Tower.

Outcome: The core OU structure (Security, Infrastructure, Workloads) and the foundational accounts (Log Archive, Audit) are provisioned.

Stage 2: Network Infrastructure:

Action: A commit to 2-networking/ triggers the pipeline to deploy the Transit Gateway and hub VPC in the Network Account.

Outcome: A secure, scalable network hub is established, ready to connect workload VPCs.

Stage 3: Centralized Security:

Action: A pipeline run for 3-security/ enables and configures centralized security services like GuardDuty, Security Hub, and CloudTrail.

Outcome: Security and compliance monitoring is active across the organization.

Stage 4: EKS and DevOps Tools:

Action: The pipeline executes the 4-eks/ workspace to provision a dedicated EKS cluster in the DevOps account. This is the cluster where ArgoCD will be installed.

Outcome: The EKS cluster is ready to host the ArgoCD controller.

Stage 5: Account Vending (AFT):

Action: The AFT workspace is configured to manage new account requests.

Outcome: A standardized, automated process for creating new accounts is now live, ensuring consistency and governance from the moment an account is created.

9. Networking (Hub & Spoke) — IaC
Objective: Configure a scalable network topology by deploying a Transit Gateway and managing VPCs.

Hub VPC: Use the modules/vpc to create a hub VPC in the Network account.

Transit Gateway: Deploy the TGW and configure it to accept attachments from other accounts.

Spoke VPCs: For each workload account, use the modules/vpc to create a spoke VPC with a non-overlapping CIDR block.

TGW Attachments: Manage cross-account TGW attachments and routing tables using aws_ec2_transit_gateway_vpc_attachment and related resources.

10. Security Tooling — IaC
Objective: Enable and centralize the organization's security services.

CloudTrail: Deploy an organization-wide trail using is_organization_trail = true that delivers logs to the Log Archive S3 bucket.

GuardDuty: Enable GuardDuty in all accounts and configure the Security Tooling account as the administrator.

Security Hub: Enable Security Hub and configure the Security Tooling account as the organization administrator.

AWS Config: Set up a configuration aggregator in the Log Archive account to collect compliance data from all accounts.

11. Account Vending — Account Factory for Terraform (AFT)
Objective: To automate the provisioning of new AWS accounts in a consistent, repeatable manner.

AFT Pattern: AFT uses a Git repository as the source of truth for account definitions. When a new account is defined in Git, AFT automatically provisions the account via Control Tower and applies a baseline of resources, such as a VPC, IAM roles, and basic security configurations.

12. CI/CD (GitOps) — A Dual-Pipeline Approach
This section is crucial for high-level interviews. It demonstrates a clear understanding of modern, secure, and scalable deployment strategies.

Infrastructure Pipeline (Push-based):

Purpose: Manages the underlying AWS infrastructure.

Trigger: A pull request or merge to the infrastructure-repo.

Process: A CI runner runs terraform plan to validate changes. Upon approval, it runs terraform apply, which provisions or updates the AWS resources.

Application Pipeline (Pull-based with ArgoCD):

Purpose: Deploys and manages applications on the EKS clusters.

Process: ArgoCD runs as a Kubernetes controller, continuously monitoring the application-repo for changes.

Reconciliation: When a change is detected, ArgoCD automatically pulls the new manifests and applies them to the target EKS cluster, ensuring the live state always matches the desired state in Git. This includes self-healing, where ArgoCD will revert any unauthorized manual changes to the cluster.

Security: ArgoCD uses IRSA to securely authenticate with target clusters, eliminating the need for hardcoded credentials.

13. Variables, Secrets & Backends
Variables: All configuration values that change between environments (e.g., account IDs, region names, environment tags) are externalized in .tfvars files.

Secrets: Crucially, secrets are never stored in Git. For infrastructure, secrets are fetched from AWS Secrets Manager at runtime. For applications, an External Secrets Operator on the EKS cluster syncs secrets from Secrets Manager into Kubernetes secrets.

Backends: Terraform state is stored in a versioned S3 bucket with state locking managed by a DynamoDB table.

14. Testing, Validation & Rollback
Testing:

Terraform: Use terraform fmt and terraform validate in the CI pipeline.

Applications: Use linting and schema validation tools for Kubernetes manifests.

Validation: The terraform plan output serves as a change manifest for review and approval. The ArgoCD UI provides a clear, visual diff of pending changes before a sync.

Rollback: The declarative nature of both Terraform and ArgoCD simplifies rollbacks. Reverting to a previous commit in the relevant Git repository is the primary and most reliable rollback mechanism.

15. Costs & Estimation Guidance
A responsible Cloud Solutions Architect must consider cost.

Initial Costs: Focus on the services enabled by Control Tower (e.g., S3 storage for logs, DynamoDB), the TGW, and the dedicated EKS cluster for ArgoCD.

Ongoing Costs: Monitor TGW data processing charges, S3 storage growth, and the usage of EKS worker nodes.

Optimization: Implement S3 lifecycle policies for logs and use cost allocation tags to track spending by team or project.

16. Operational Runbook & Checklist
Daily Checks:

Review the ArgoCD UI for any OutOfSync applications.

Check for critical security findings in Security Hub.

Verify the status of the infrastructure and application pipelines.

Incident Response: The runbook should detail procedures for responding to security alerts and infrastructure-level issues.

Change Management: All changes to both infrastructure and applications must follow a Git-based change management process.

17. Troubleshooting & FAQ
Terraform Issues: Common issues include state conflicts, provider version mismatches, and access denied errors.

ArgoCD Issues: Troubleshoot by examining the ArgoCD UI for sync failures, checking pod logs, and verifying IAM permissions for IRSA.

General: Address common questions about account customization, cross-account access patterns, and service integrations.

18. Appendix: Example Terraform Snippets & Templates
This section should include concrete examples of code for key components:

A backend.tf file.

A main.tf for deploying Control Tower.

An example of a reusable VPC module.

A template for an EKS cluster with IRSA configured.

Example ArgoCD Application and AppProject manifests.
