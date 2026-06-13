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
- `create_missing_public_subnet_for_lab`: crea una subnet publica adicional si la VPC default del AWS Learner Lab solo cubre una AZ.
- `additional_public_subnet_cidr_block`: CIDR de la subnet publica adicional. Debe estar dentro del CIDR de la VPC y no solaparse con subnets existentes.
- `additional_public_subnet_availability_zone`: AZ donde se crea la subnet publica adicional.
- `create_missing_public_subnet_for_alb`: variable antigua conservada por compatibilidad. Esta deprecada; usar `create_missing_public_subnet_for_lab`.

Con esas variables, Terraform deriva automáticamente:
- `url_base_servicio`: `http://<dns-alb><path_base_servicio>`

Además, Terraform inicializa la base de datos ejecutando:
- `backend-ventas/src/main/resources/sql/base-datos-ddl.sql`
- `backend-ventas/src/main/resources/sql/base-datos-dml.sql`

Defaults relevantes para sandbox:
- DB identifier: `tiendavirtual`
- Usuario administrador: `admin`
- RDS publicly accessible: `true`
- Subnet adicional de laboratorio: `172.31.32.0/20` en `us-east-1b`

Para AWS Learner Lab configurar estas variables de GitHub Actions cuando la VPC default solo tenga una subnet util:

- `CREATE_MISSING_PUBLIC_SUBNET_FOR_LAB=true`
- `ADDITIONAL_PUBLIC_SUBNET_CIDR_BLOCK=172.31.32.0/20`
- `ADDITIONAL_PUBLIC_SUBNET_AVAILABILITY_ZONE=us-east-1b`

Antes de aplicar, ejecutar el workflow **Diagnosticar e Importar Infraestructura AWS**. Ese workflow muestra la VPC, CIDR, subnets existentes, AZs cubiertas, subnets que usaran ALB/RDS y posibles conflictos de CIDR. Tambien importa recursos que pudieron quedar creados por un apply fallido.

Luego ejecutar **Plan Terraform Infraestructura AWS** y revisar que:

- ALB tenga subnets en al menos dos AZs.
- RDS DB subnet group tenga subnets en al menos dos AZs.
- No aparezcan recreaciones inesperadas de recursos ya existentes.

Para produccion, RDS deberia moverse a subnets privadas. En este laboratorio usa las mismas subnets publicas compartidas por ALB/ECS para cumplir la cobertura minima de AZs en AWS Academy.

En ECS se inyectan estas variables de entorno para Spring Boot:
- `DB_HOST`
- `DB_NAME`
- `DB_USER`
- `DB_PASSWORD`
- `LOGISTICA_BASE_URL` (solo en ventas)

El mismo `path_base_servicio` también se usa para enrutar API Gateway (por ejemplo: `/api/productos`).
