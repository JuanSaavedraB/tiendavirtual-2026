## Ejecución de Terraform en Local

## Inicializar el estado de Terraform

AWS_PROFILE=academy terraform init -backend-config "bucket=tiendavirtual-iac-state" -backend-config "dynamodb_table=terraform-locks"

## Compilar Lambdas antes de plan/apply

cd ../serverless/tiendavirtual/packages/funciones/crear-orden && npm install && npm run build
cd ../merger && npm install && npm run build

## Validar el plan de Terraform

AWS_PROFILE=academy terraform validate

## Ejecutar el plan de Terraform

AWS_PROFILE=academy terraform plan --var-file=main.tfvars

## Aplicar el plan de Terraform

AWS_PROFILE=academy terraform apply --var-file=main.tfvars

## Destruir toda la infraestructura creada

AWS_PROFILE=academy terraform destroy --var-file=main.tfvars

## Variables de entrada relevantes

- `id_cuenta_aws`: ID de cuenta AWS.
- `nombre_rol_iam`: nombre del rol IAM para construir `arn:aws:iam::<id_cuenta_aws>:role/<nombre_rol_iam>`.
- `path_base_servicio`: path base que se concatena a la URL del ALB para la Lambda (acepta `api` o `/api`).
- `nombre_instancia_rds`: identificador de la instancia RDS MySQL.
- `esquema_ventas`, `esquema_logistica`, `esquema_tiendavirtual`: esquemas definidos en la misma instancia RDS.
- `familia_tarea_ecs_ventas`, `familia_tarea_ecs_logistica`: familias de tarea para microservicios.
- `nombre_repo_ecr`: repositorio ECR compartido.
- `tag_imagen_ventas`, `tag_imagen_logistica`: tags de imagen para cada microservicio.
- `nombre_servicio_ecs_ventas`, `nombre_servicio_ecs_logistica`: servicios ECS separados.

Con esas variables, Terraform deriva automáticamente:
- `url_base_servicio`: `http://<dns-alb><path_base_servicio>`

Además, Terraform inicializa la base de datos ejecutando:
- `backend-ventas/src/main/resources/sql/base-datos-ddl.sql`
- `backend-ventas/src/main/resources/sql/base-datos-dml.sql`

Defaults relevantes para sandbox:
- DB identifier: `tiendavirtual`
- Usuario administrador: `admin`
- RDS publicly accessible: `true`

En ECS se inyectan estas variables de entorno para Spring Boot:
- `DB_HOST`
- `DB_NAME`
- `DB_USER`
- `DB_PASSWORD`
- `LOGISTICA_BASE_URL` (solo en ventas)

El mismo `path_base_servicio` también se usa para enrutar API Gateway (por ejemplo: `/api/productos`).
