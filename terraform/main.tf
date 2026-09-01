# ─────────────────────────────────────────────────────────────
# ghost-production-aws — root module (single environment)
#
# Composes reusable modules from ./modules. Stage 1 adds network, data, and
# compute. Later stages add durable media, edge security, and operations.
# ─────────────────────────────────────────────────────────────

locals {
  name_prefix = var.project
}

module "network" {
  source = "./modules/network"

  name_prefix              = local.name_prefix
  vpc_cidr                 = var.vpc_cidr
  public_subnet_cidrs      = var.public_subnet_cidrs
  application_subnet_cidrs = var.application_subnet_cidrs
  database_subnet_cidrs    = var.database_subnet_cidrs
  acm_certificate_arn      = var.acm_certificate_arn
}

module "data" {
  source = "./modules/data"

  name_prefix           = local.name_prefix
  database_subnet_ids   = module.network.database_subnet_ids
  rds_security_group_id = module.network.rds_security_group_id
}

module "compute" {
  source = "./modules/compute"

  name_prefix            = local.name_prefix
  aws_region             = var.aws_region
  application_subnet_ids = module.network.application_subnet_ids
  ecs_security_group_id  = module.network.ecs_security_group_id
  target_group_arn       = module.network.target_group_arn
  ghost_url              = "https://${var.domain_name}"
  database_secret_arn    = module.data.database_secret_arn
}
