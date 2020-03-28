module "app_front" {
  source             = "./modules/s3"
  name               = "app-front-${var.app_name}"
  versioning_enabled = true
}

module "hostname_app_front" {
  source      = "./modules/ns"
  app_name    = var.hostname_app_front_default != "" ? var.hostname_app_front_default : var.app_name
  alb_url     = module.app_front.bucket_domain_name
  base_domain = var.base_domain
  is_proxied  = true
}
