## Ejecución de Terraform en Local

## Inicializar el estado de Terraform

AWS_PROFILE=academy terraform init -backend-config "bucket=tiendavirtual-iac-state" -backend-config "dynamodb_table=terraform-locks"

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
- `host_base_datos`: host DNS de MySQL.
- `nombre_base_datos`: nombre de la base de datos MySQL.

Con esas variables, Terraform deriva automáticamente:
- `url_base_servicio`: `http://<dns-alb><path_base_servicio>`

En ECS se inyectan estas variables de entorno para Spring Boot:
- `DB_HOST`
- `DB_NAME`
- `DB_USER`
- `DB_PASSWORD`

El mismo `path_base_servicio` también se usa para enrutar API Gateway (por ejemplo: `/api/productos`).
