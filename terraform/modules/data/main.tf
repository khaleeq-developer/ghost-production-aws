resource "random_password" "database" {
  length           = 32
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "aws_db_subnet_group" "ghost" {
  name_prefix = "${var.name_prefix}-db-"
  description = "Isolated database subnets for Ghost"
  subnet_ids  = var.database_subnet_ids

  tags = {
    Name = "${var.name_prefix}-db-subnets"
  }
}

resource "aws_db_instance" "ghost" {
  identifier_prefix = "ghost-"

  engine         = "mysql"
  engine_version = "8.0"
  instance_class = var.instance_class

  allocated_storage     = var.allocated_storage
  max_allocated_storage = 50
  storage_type          = "gp3"
  storage_encrypted     = true

  db_name  = var.database_name
  username = var.database_username
  password = random_password.database.result
  port     = 3306

  db_subnet_group_name   = aws_db_subnet_group.ghost.name
  vpc_security_group_ids = [var.rds_security_group_id]
  publicly_accessible    = false
  multi_az               = false

  backup_retention_period = var.backup_retention_days
  backup_window           = "03:00-04:00"
  maintenance_window      = "sun:04:00-sun:05:00"

  auto_minor_version_upgrade = true
  apply_immediately          = true
  copy_tags_to_snapshot      = true

  # Sandbox stack: tear down without a final snapshot. The apply role has no
  # rds:CreateDBSnapshot permission, so a snapshot attempt would fail anyway.
  deletion_protection = var.deletion_protection
  skip_final_snapshot = true

  tags = {
    Name = "${var.name_prefix}-mysql"
  }
}

resource "aws_secretsmanager_secret" "database" {
  name_prefix             = "${var.name_prefix}-database-"
  description             = "Ghost MySQL connection fields"
  recovery_window_in_days = 0

  tags = {
    Name = "${var.name_prefix}-database-secret"
  }
}

resource "aws_secretsmanager_secret_version" "database" {
  secret_id = aws_secretsmanager_secret.database.id

  secret_string = jsonencode({
    host     = aws_db_instance.ghost.address
    port     = aws_db_instance.ghost.port
    database = var.database_name
    username = var.database_username
    password = random_password.database.result
  })
}
