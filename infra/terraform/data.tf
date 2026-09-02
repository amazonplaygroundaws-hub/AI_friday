resource "aws_s3_bucket" "documents" {
  bucket_prefix = "${var.name}-${var.environment}-documents-"
}

resource "aws_s3_bucket_public_access_block" "documents" {
  bucket                  = aws_s3_bucket.documents.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "documents" {
  bucket = aws_s3_bucket.documents.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "documents" {
  bucket = aws_s3_bucket.documents.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_db_instance" "postgres" {
  identifier                   = "${var.name}-${var.environment}"
  engine                       = "postgres"
  engine_version               = "17"
  instance_class               = var.db_instance_class
  allocated_storage            = var.db_allocated_storage_gb
  max_allocated_storage        = 100
  storage_type                 = "gp3"
  storage_encrypted            = true
  db_name                      = "covenant_radar"
  username                     = "covenant_radar"
  manage_master_user_password  = true
  multi_az                     = false
  publicly_accessible          = false
  db_subnet_group_name         = aws_db_subnet_group.main.name
  vpc_security_group_ids       = [aws_security_group.database.id]
  backup_retention_period      = 7
  deletion_protection          = false
  skip_final_snapshot          = true
  auto_minor_version_upgrade   = true
  performance_insights_enabled = false
}
