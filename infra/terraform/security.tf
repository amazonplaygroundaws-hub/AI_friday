resource "aws_security_group" "alb" {
  name        = "${var.name}-${var.environment}-alb"
  description = "Public HTTP entry point for synthetic-data development only."
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "HTTP redirects to HTTPS after TLS is enabled"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "app" {
  name        = "${var.name}-${var.environment}-app"
  description = "Application instances; only ALB can reach the web service."
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port       = 8000
    to_port         = 8000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  dynamic "ingress" {
    for_each = var.allowed_admin_cidrs
    content {
      description = "Temporary break-glass SSH"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = [ingress.value]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "database" {
  name        = "${var.name}-${var.environment}-database"
  description = "PostgreSQL reachable only by application instances."
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }
}
