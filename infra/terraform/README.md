# Covenant Radar AWS infrastructure

This Terraform configuration creates the scalable AWS application tier in `us-east-1` and reuses the AWS account's **default VPC** and its existing default subnets. It creates no VPC, subnet, route table, or internet gateway.

```text
Application Load Balancer (public HTTP, existing default-VPC subnets)
        |
        v
Auto Scaling Group (one to two EC2 instances)
        |                     |
        v                     v
RDS PostgreSQL (private)   Private S3 documents bucket
```

Cloudflare is not part of this development configuration. Terraform outputs the direct Application Load Balancer URL.

## Before applying

1. Install Terraform and configure AWS credentials for the target account.
2. Copy `terraform.tfvars.example` to `terraform.tfvars` and set `app_bootstrap_command` to the command that fetches/builds the application release. Do not put repository tokens in this file; use a deployment artifact, Systems Manager Parameter Store, or an instance role. The starter template intentionally exits instead of inventing a private-repository credential.
3. Run `terraform init`, then `terraform plan` and `terraform apply`.
4. Use the `application_url` output for a direct HTTP smoke test. It must contain synthetic data and test credentials only.
5. Add an S3 document-store adapter to the application before using this infrastructure; the current code's local filesystem store is not shared across ASG instances. Run the database migration and deterministic demo seed once via an EC2 instance/SSM. Do not seed in ASG user-data: every replacement instance would race to seed the shared database.

## Automated deployments from GitHub

After the first `terraform apply`, copy the `github_deploy_role_arn` and `release_bucket` outputs into GitHub repository **Variables** named `AWS_DEPLOY_ROLE_ARN` and `AWS_RELEASE_BUCKET`. The included `.github/workflows/deploy-aws.yml` then runs on each push to `main`.

The workflow packages the repository, uploads a versioned release to the private release bucket, and invokes Systems Manager Run Command against application instances one at a time. Each instance installs the release, runs the Alembic migration idempotently, and restarts the systemd application service. GitHub authenticates through short-lived OpenID Connect credentials; no AWS access key is stored in GitHub.

The initial EC2 launch still requires a valid `app_bootstrap_command` because a release must exist before a new instance can download it. Configure a durable release-bootstrap mechanism before allowing the ASG to replace the first instance.

## Cost and scaling defaults

The default is one `t3.small` instance and one single-AZ `db.t4g.micro` database. The ASG can add only one extra instance. This is a development baseline, not production HA. An ALB and RDS are always-on costs. There is intentionally no NAT gateway: application instances use existing default-VPC subnets but accept traffic only from the ALB security group; RDS has no public endpoint and remains reachable only from application instances.

Use a remote, encrypted Terraform state backend before teamwork or production use. Local state is used only to keep this first setup simple.
