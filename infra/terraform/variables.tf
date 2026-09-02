variable "aws_region" {
  description = "AWS region for all resources."
  type        = string
  default     = "us-east-1"
}

variable "name" {
  description = "Short lowercase resource prefix."
  type        = string
  default     = "covenant-radar"
}

variable "environment" {
  description = "Deployment environment tag."
  type        = string
  default     = "dev"
}

variable "app_instance_type" {
  description = "EC2 instance type for the FastAPI application."
  type        = string
  default     = "t3.small"
}

variable "app_desired_capacity" {
  type    = number
  default = 1
}

variable "app_max_size" {
  type    = number
  default = 2
}

variable "app_bootstrap_command" {
  description = "Required idempotent shell command that places the release in /opt/covenant-radar and installs dependencies. Do not include secrets."
  type        = string
  sensitive   = true
}

variable "app_start_command" {
  description = "Command run by systemd from /opt/covenant-radar after bootstrap."
  type        = string
  default     = "/opt/covenant-radar/.venv/bin/python -m radarctl serve"
}

variable "db_instance_class" {
  description = "Single-AZ RDS PostgreSQL class for the development baseline."
  type        = string
  default     = "db.t4g.micro"
}

variable "db_allocated_storage_gb" {
  type    = number
  default = 20
}

variable "alert_email" {
  description = "Optional email destination for CloudWatch alarms; leave blank to omit email notifications."
  type        = string
  default     = ""
}

variable "github_repository" {
  description = "GitHub owner/repository allowed to assume the deployment role from the development environment."
  type        = string
  default     = "amazonplaygroundaws-hub/AI_friday"
}

variable "allowed_admin_cidrs" {
  description = "Optional CIDRs permitted to SSH for break-glass only. Prefer SSM Session Manager."
  type        = list(string)
  default     = []
}
