locals {
  database_name     = "api"
  database_user     = "postgre"
  database_password = random_password.database_password.result
  pg_ssm_parameters = {
    database_name = {
      name        = "database_name"
      description = "Database name"
      value       = local.database_name
    },
    username = {
      name        = "username/master"
      description = "Database name"
      value       = local.database_user
    },
    password = {
      name        = "password/master"
      description = "Database password"
      value       = local.database_password
    },
    address = {
      name        = "address/master"
      description = "Database address"
      value       = aws_db_instance.default.0.address
    },
    port = {
      name        = "port/master"
      description = "Database port"
      value       = aws_db_instance.default.0.port
    }
  }
}

resource "aws_ssm_parameter" "pg" {
  for_each    = local.pg_ssm_parameters
  name        = "/${var.env_long}/database/${each.key}"
  description = each.value.description
  type        = "SecureString"
  value       = each.value.value
  tags        = local.tags
}




resource "aws_db_instance" "default" {
  count                           = var.create_database ? 1 : 0
  allocated_storage               = 8
  engine                          = "postgres"
  engine_version                  = "13.4"
  instance_class                  = "db.t3.micro"
  identifier                      = "${var.env_long}-postgre"
  name                            = local.database_name
  username                        = local.database_user
  password                        = local.database_password
  db_subnet_group_name            = aws_db_subnet_group.database.name
  skip_final_snapshot             = true
  vpc_security_group_ids          = [aws_security_group.postgre_db_sg.id]
  multi_az                        = true
  maintenance_window              = "Mon:03:00-Mon:05:00"
  backup_window                   = "00:00-03:00"
  backup_retention_period         = 2
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]
  tags                            = local.tags
}



resource "aws_security_group" "postgre_db_sg" {
  name        = "${var.env_short}-postgre-security-group-${var.shared_region}"
  description = "PostgreSQL security group"
  vpc_id      = module.vpc.0.vpc_id

  //TODO: Use 443 port and HTTPS
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [module.vpc.0.vpc_cidr_block]
  }
  tags = merge(local.tags,
  { "Name" : "${var.env_short}-postgre" })

}


resource "random_password" "database_password" {
  length  = 16
  special = false
  number  = true
}

resource "aws_db_subnet_group" "database" {
  name       = "database"
  subnet_ids = module.vpc.0.database_subnets

  tags = merge(local.tags, {
    Name = "${var.env_long} subnet group",
  })
}
