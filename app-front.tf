module "app_front" {
  source             = "./modules/s3"
  name               = "app-front-${var.app_name}"
  versioning_enabled = true
}


module "s3_buildndeploy" {
  source            = "./modules/buildndeploy/s3"
  bucket_name       = module.app_front.bucket_id
  environment       = var.environment
  repository_name   = var.static_repository_name
  repository_owner  = var.repository_owner
  repository_branch = var.repository_branch
  github_token      = var.github_token
}


module "hostname_app_front" {
  source      = "./modules/ns"
  app_name    = var.hostname_app_front_default != "" ? var.hostname_app_front_default : var.app_name
  alb_url     = module.app_front.bucket_domain_name
  base_domain = var.base_domain
  is_proxied  = true
}

