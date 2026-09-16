# ─────────────────────────────────────────────────────────────
# ghost-production-aws — root module (single environment)
#
# Composes reusable AWS modules from ./modules for network, data, and compute.
# Persistent state and CI/CD identity live in ./bootstrap. Cloudflare R2 media
# remains externally managed.
# ─────────────────────────────────────────────────────────────

locals {
  name_prefix  = var.project
  r2_endpoint  = "https://${var.cloudflare_account_id}.r2.cloudflarestorage.com"
  r2_media_url = "https://${var.r2_media_hostname}"
}

module "network" {
  source = "./modules/network"

  name_prefix              = local.name_prefix
  acm_certificate_arn      = var.acm_certificate_arn
  vpc_cidr                 = var.vpc_cidr
  public_subnet_cidrs      = var.public_subnet_cidrs
  application_subnet_cidrs = var.application_subnet_cidrs
  database_subnet_cidrs    = var.database_subnet_cidrs
}

module "data" {
  source = "./modules/data"

  name_prefix           = local.name_prefix
  database_subnet_ids   = module.network.database_subnet_ids
  rds_security_group_id = module.network.rds_security_group_id
  deletion_protection   = !var.allow_data_destruction
}

module "compute" {
  source = "./modules/compute"

  name_prefix                  = local.name_prefix
  aws_region                   = var.aws_region
  application_subnet_ids       = module.network.application_subnet_ids
  ecs_security_group_id        = module.network.ecs_security_group_id
  target_group_arn             = module.network.target_group_arn
  ghost_url                    = "https://${var.domain_name}"
  ghost_image                  = var.ghost_image
  database_secret_arn          = module.data.database_secret_arn
  media_bucket_name            = var.r2_bucket_name
  media_endpoint               = local.r2_endpoint
  media_url                    = local.r2_media_url
  media_credentials_secret_arn = var.r2_credentials_secret_arn
}
