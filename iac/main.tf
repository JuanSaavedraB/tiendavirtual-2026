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

module "database" {
  source                    = "./modules/database"
  nombre_instancia_rds      = var.nombre_instancia_rds
  usuario_base_datos        = var.usuario_base_datos
  contrasenha_base_datos    = var.contrasenha_base_datos
  nombre_base_datos_inicial = var.nombre_base_datos_inicial_rds
  ddl_script_path           = "${path.root}/../backend-ventas/src/main/resources/sql/base-datos-ddl.sql"
  dml_script_path           = "${path.root}/../backend-ventas/src/main/resources/sql/base-datos-dml.sql"
  rds_instance_class        = var.rds_instance_class
  rds_allocated_storage     = var.rds_allocated_storage
  rds_max_allocated_storage = var.rds_max_allocated_storage
  rds_engine_version        = var.rds_engine_version
  rds_publicly_accessible   = var.rds_publicly_accessible
}

module "serverless" {
  source                     = "./modules/serverless"
  rol_lambda_arn             = local.rol_lab_arn
  url_base_servicio          = local.url_base_servicio
  host_base_datos            = module.database.rds_endpoint
  puerto_base_datos          = module.database.rds_port
  usuario_base_datos         = var.usuario_base_datos
  contrasenha_base_datos     = var.contrasenha_base_datos
  esquema_tiendavirtual      = var.esquema_tiendavirtual
  nombre_cola_sync_ventas    = "ventas-sync-queue"
  nombre_cola_sync_logistica = "logistica-sync-queue"
}

module "compute" {
  source                        = "./modules/compute"
  nombre_cluster                = var.nombre_cluster_ecs
  familia_tarea_ventas          = var.familia_tarea_ecs_ventas
  familia_tarea_logistica       = var.familia_tarea_ecs_logistica
  rol_lab_arn                   = local.rol_lab_arn
  id_cuenta_aws                 = var.id_cuenta_aws
  region_aws                    = var.region
  nombre_repo_ecr               = var.nombre_repo_ecr
  tag_imagen_ventas             = var.tag_imagen_ventas
  tag_imagen_logistica          = var.tag_imagen_logistica
  host_base_datos               = module.database.rds_endpoint
  nombre_base_datos_ventas      = var.esquema_ventas
  nombre_base_datos_logistica   = var.esquema_logistica
  usuario_base_datos            = var.usuario_base_datos
  contrasenha_base_datos        = var.contrasenha_base_datos
  nombre_servicio_ecs_ventas    = var.nombre_servicio_ecs_ventas
  nombre_servicio_ecs_logistica = var.nombre_servicio_ecs_logistica
  queue_url_sync_ventas         = module.serverless.ventas_sync_queue_url
  queue_url_sync_logistica      = module.serverless.logistica_sync_queue_url
  path_base_servicio            = local.path_base_servicio_normalizado
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
