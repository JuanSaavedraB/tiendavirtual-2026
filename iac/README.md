## Ejecución de Terraform en Local

## Inicializar el estado de Terraform

AWS_PROFILE=academy terraform init \
  -backend-config "bucket=tiendavirtual-iac-state" \
  -backend-config "dynamodb_table=terraform-locks" \
  -backend-config "key=backend-terraform.tfstate" \
  -backend-config "region=us-east-1"

El backend se declara como `backend "s3" {}` y se completa durante `terraform init`. Esto evita defaults ocultos. Antes de importar o aplicar, confirma que los valores de GitHub Actions `BUCKET`, `LOCKS`, `TF_STATE_KEY` y `BACKEND_REGION` coincidan con el state original. Si no coinciden, Terraform puede refrescar algunos recursos desde un state y crear otros que ya existen en AWS.

`AWS_REGION` es la región de los recursos. `BACKEND_REGION` es la región del bucket S3 del state. Pueden ser iguales, pero no significan lo mismo.

## Validar el plan de Terraform

AWS_PROFILE=academy terraform validate

## Ejecutar el plan de Terraform

AWS_PROFILE=academy terraform plan --var-file=main.tfvars

## Aplicar el plan de Terraform

AWS_PROFILE=academy terraform apply --var-file=main.tfvars

## Destruir toda la infraestructura creada

AWS_PROFILE=academy terraform destroy --var-file=main.tfvars

## Recuperar recursos existentes en el state

Si los recursos ya existen en AWS pero no están en el state activo, prioriza importarlos al state remoto correcto. No uses `lifecycle` para esto: `ignore_changes` no adopta recursos fuera del state y `prevent_destroy` solo bloquea destrucciones, no resuelve conflictos de creación.

Para el laboratorio, la opción más segura es ejecutar el workflow manual `Importar Recursos Terraform`. Ese workflow:

- configura credenciales AWS,
- inicializa Terraform con el mismo backend remoto que el despliegue,
- importa solo si la dirección no existe en el state,
- no ejecuta `terraform apply`,
- termina con `terraform plan`.

También puedes hacer el import una sola vez desde local, siempre que uses exactamente el mismo backend:

```sh
AWS_PROFILE=academy terraform import \
  --var-file=main.tfvars \
  'module.compute.aws_cloudwatch_log_group.ecs_logs' \
  '/ecs/tienda-virtual-servicio'

AWS_PROFILE=academy terraform import \
  --var-file=main.tfvars \
  'module.compute.aws_lb_target_group.tg_tienda_virtual' \
  "$(AWS_PROFILE=academy aws elbv2 describe-target-groups \
    --names tg-tienda-virtual \
    --query 'TargetGroups[0].TargetGroupArn' \
    --output text)"

AWS_PROFILE=academy terraform import \
  --var-file=main.tfvars \
  'module.compute.aws_lb.tienda_virtual_load_balancer' \
  "$(AWS_PROFILE=academy aws elbv2 describe-load-balancers \
    --names tienda-virtual-alb \
    --query 'LoadBalancers[0].LoadBalancerArn' \
    --output text)"

AWS_PROFILE=academy terraform import \
  --var-file=main.tfvars \
  'module.events.aws_cloudwatch_event_bus.ordenes_bus' \
  'ordenes-bus'
```

Después de importar, ejecuta:

```sh
AWS_PROFILE=academy terraform plan --var-file=main.tfvars
```

El plan no debe intentar crear de nuevo esos recursos. Si muestra cambios destructivos, revisa primero nombres, región, cuenta AWS y backend.

Terraform 1.10 también permite bloques `import {}` declarativos. Son útiles cuando quieres versionar imports temporales, pero en este proyecto académico conviene más el workflow manual porque deja claro el backend activo y evita mezclar imports transitorios con la definición permanente de infraestructura.

## Diagnóstico no destructivo

Ejecuta el workflow manual `Diagnostico Terraform AWS` o el script local:

```sh
AWS_PROFILE=academy \
AWS_REGION=us-east-1 \
BACKEND_REGION=us-east-1 \
BUCKET=tiendavirtual-iac-state \
LOCKS=terraform-locks \
TF_STATE_KEY=backend-terraform.tfstate \
VPC_ID=vpc-xxxxxxxxxxxxxxxxx \
PUBLIC_SUBNET_IDS_JSON='["subnet-aaaaaaaaaaaaaaaaa","subnet-bbbbbbbbbbbbbbbbb"]' \
bash ../scripts/diagnostico_aws.sh
```

El diagnóstico solo lee AWS. Revisa identidad, bucket, objeto state, tabla de locks, log group, event bus, target group, ALB, subnets, AZs, `MapPublicIpOnLaunch` y rutas hacia Internet Gateway.

## Subnets para el ALB

El ALB necesita al menos dos subnets públicas en dos Availability Zones distintas. El módulo `compute` acepta:

- `vpc_id`: VPC existente. Si queda vacío, usa la VPC por defecto.
- `public_subnet_ids`: lista de subnets públicas. Si queda vacía, usa todas las subnets de la VPC seleccionada.
- En GitHub Actions, define `VPC_ID` y `PUBLIC_SUBNET_IDS_JSON` si no quieres depender de la VPC por defecto.

Ejemplo recomendado:

```hcl
vpc_id = "vpc-xxxxxxxxxxxxxxxxx"
public_subnet_ids = [
  "subnet-aaaaaaaaaaaaaaaaa",
  "subnet-bbbbbbbbbbbbbbbbb",
]
```

Valida manualmente que las subnets sean públicas, es decir, que su route table tenga ruta `0.0.0.0/0` hacia un Internet Gateway. Terraform valida cantidad y AZs distintas, pero no reemplaza la revisión de rutas.

### Learner Lab con una sola subnet por defecto

En algunos laboratorios AWS Academy/Learner Lab la VPC por defecto solo tiene una subnet pública. En ese caso el ALB no puede crearse hasta tener otra subnet pública en una AZ distinta.

Opciones evaluadas:

- Opción A: configurar `PUBLIC_SUBNET_IDS_JSON` con dos subnets existentes. Es lo más simple si ya existen.
- Opción B: crear una subnet pública adicional en Terraform cuando la VPC solo tiene una. Es la opción recomendada para este laboratorio porque queda versionada y reproducible.
- Opción C: crear dos subnets públicas gestionadas por Terraform. Es más invasiva y cambia más la red del laboratorio.
- Opción D: crear la subnet manualmente. Funciona, pero deja infraestructura fuera del código.

Para usar la opción B, deja `PUBLIC_SUBNET_IDS_JSON` como `[]` y configura estas variables de GitHub Actions:

```text
CREATE_MISSING_PUBLIC_SUBNET_FOR_ALB=true
ADDITIONAL_PUBLIC_SUBNET_CIDR_BLOCK=172.31.32.0/20
ADDITIONAL_PUBLIC_SUBNET_AVAILABILITY_ZONE=us-east-1b
```

Antes de fijar el CIDR, ejecuta el diagnóstico y revisa los CIDR existentes de la VPC. Si la subnet actual usa `172.31.16.0/20`, `172.31.32.0/20` suele ser una opción razonable en una VPC default `172.31.0.0/16`, pero no debe usarse si ya aparece ocupado. La subnet adicional se crea con `map_public_ip_on_launch = true`, una route table propia y ruta `0.0.0.0/0` hacia el Internet Gateway existente de la VPC.

Si configuras dos subnets existentes en `PUBLIC_SUBNET_IDS_JSON`, Terraform usa esas subnets y no crea la subnet adicional.

## Variables de entrada relevantes

- `id_cuenta_aws`: ID de cuenta AWS.
- `nombre_rol_iam`: nombre del rol IAM para construir `arn:aws:iam::<id_cuenta_aws>:role/<nombre_rol_iam>`.
- `path_base_servicio`: path base que se concatena a la URL del ALB para la Lambda (acepta `api` o `/api`).
- `host_base_datos`: host DNS de MySQL.
- `nombre_base_datos`: nombre de la base de datos MySQL.
- `vpc_id`: VPC existente para ECS y ALB; opcional si usas la VPC por defecto.
- `public_subnet_ids`: subnets públicas para el ALB; deben cubrir al menos dos AZs.
- `create_missing_public_subnet_for_alb`: habilita la creación controlada de una subnet pública adicional para el ALB.
- `additional_public_subnet_cidr_block`: CIDR de esa subnet adicional; debe validarse contra los CIDR existentes.
- `additional_public_subnet_availability_zone`: AZ distinta a la subnet existente, por ejemplo `us-east-1b`.
- `nombre_load_balancer`, `nombre_target_group`, `nombre_event_bus`: nombres de recursos globales/regionales que pueden colisionar si reutilizas cuenta y región entre ambientes.

Con esas variables, Terraform deriva automáticamente:
- `url_base_servicio`: `http://<dns-alb><path_base_servicio>`

En ECS se inyectan estas variables de entorno para Spring Boot:
- `DB_HOST`
- `DB_NAME`
- `DB_USER`
- `DB_PASSWORD`

El mismo `path_base_servicio` también se usa para enrutar API Gateway (por ejemplo: `/api/productos`).
