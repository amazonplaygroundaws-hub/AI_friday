output "application_url" {
  description = "Direct development URL. It is HTTP only; use synthetic data and test credentials."
  value       = "http://${aws_lb.app.dns_name}"
}

output "documents_bucket" {
  value = aws_s3_bucket.documents.bucket
}

output "release_bucket" {
  description = "Set this value as the GitHub repository variable AWS_RELEASE_BUCKET."
  value       = aws_s3_bucket.releases.bucket
}

output "github_deploy_role_arn" {
  description = "Set this value as the GitHub repository variable AWS_DEPLOY_ROLE_ARN."
  value       = aws_iam_role.github_deploy.arn
}

output "rds_endpoint" {
  value = aws_db_instance.postgres.address
}
