provider "aws" {
  region = var.region
}

provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

locals {
  rol_lab_arn                    = "arn:aws:iam::${var.id_cuenta_aws}:role/${var.nombre_rol_iam}"
  path_base_servicio_normalizado = length(trim(var.path_base_servicio, "/")) > 0 ? "/${trim(var.path_base_servicio, "/")}" : ""
  url_base_servicio              = "http://${module.compute.load_balancer_url}${local.path_base_servicio_normalizado}"
}

module "serverless" {
  source            = "./modules/serverless"
  rol_lambda_arn    = local.rol_lab_arn
  url_base_servicio = local.url_base_servicio
}

module "compute" {
  source                 = "./modules/compute"
  nombre_cluster         = var.nombre_cluster_ecs
  familia_tarea          = var.familia_tarea_ecs
  rol_lab_arn            = local.rol_lab_arn
  id_cuenta_aws          = var.id_cuenta_aws
  region_aws             = var.region
  nombre_repo_ecr        = var.nombre_repo_ecr
  host_base_datos        = var.host_base_datos
  nombre_base_datos      = var.nombre_base_datos
  usuario_base_datos     = var.usuario_base_datos
  contrasenha_base_datos = var.contrasenha_base_datos
  nombre_servicio_ecs    = var.nombre_servicio_ecs
}

module "events" {
  source                   = "./modules/events"
  crear_orden_funcion_arn  = module.serverless.crear_orden_funcion_arn
  crear_orden_funcion_name = module.serverless.crear_orden_funcion_name
}

module "api" {
  source             = "./modules/api"
  load_balancer_url  = module.compute.load_balancer_url
  rol_lab_arn        = local.rol_lab_arn
  event_bus_name     = module.events.event_bus_name
  path_base_servicio = local.path_base_servicio_normalizado
}
