# ─────────────────────────────────────────────────────────────
# ghost-production-aws — root module (single environment)
#
# Composes reusable modules from ./modules for network, data, private media
# delivery, and compute resources.
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
  deletion_protection   = !var.allow_data_destruction
}

module "media" {
  source = "./modules/media"

  name_prefix   = local.name_prefix
  force_destroy = var.allow_data_destruction
}

module "compute" {
  source = "./modules/compute"

  depends_on = [module.media]

  name_prefix            = local.name_prefix
  aws_region             = var.aws_region
  application_subnet_ids = module.network.application_subnet_ids
  ecs_security_group_id  = module.network.ecs_security_group_id
  target_group_arn       = module.network.target_group_arn
  ghost_url              = "https://${var.domain_name}"
  ghost_image            = var.ghost_image
  database_secret_arn    = module.data.database_secret_arn
  media_bucket_name      = module.media.bucket_name
  media_bucket_arn       = module.media.bucket_arn
  media_cdn_url          = module.media.cdn_url
}
