#!/usr/bin/env bash
set -euo pipefail

AWS_REGION="${AWS_REGION:-${TF_VAR_region:-us-east-1}}"
BACKEND_REGION="${BACKEND_REGION:-$AWS_REGION}"
BUCKET="${BUCKET:-}"
LOCKS="${LOCKS:-}"
TF_STATE_KEY="${TF_STATE_KEY:-backend-terraform.tfstate}"
VPC_ID="${VPC_ID:-${TF_VAR_vpc_id:-}}"
PUBLIC_SUBNET_IDS_JSON="${PUBLIC_SUBNET_IDS_JSON:-${TF_VAR_public_subnet_ids:-[]}}"
NOMBRE_SERVICIO="${NOMBRE_SERVICIO:-${TF_VAR_nombre_servicio_ecs:-tienda-virtual-servicio}}"
NOMBRE_LOAD_BALANCER="${NOMBRE_LOAD_BALANCER:-${TF_VAR_nombre_load_balancer:-tienda-virtual-alb}}"
NOMBRE_TARGET_GROUP="${NOMBRE_TARGET_GROUP:-${TF_VAR_nombre_target_group:-tg-tienda-virtual}}"
NOMBRE_EVENT_BUS="${NOMBRE_EVENT_BUS:-${TF_VAR_nombre_event_bus:-ordenes-bus}}"
CREATE_MISSING_PUBLIC_SUBNET_FOR_ALB="${CREATE_MISSING_PUBLIC_SUBNET_FOR_ALB:-${TF_VAR_create_missing_public_subnet_for_alb:-false}}"
ADDITIONAL_PUBLIC_SUBNET_CIDR_BLOCK="${ADDITIONAL_PUBLIC_SUBNET_CIDR_BLOCK:-${TF_VAR_additional_public_subnet_cidr_block:-}}"
ADDITIONAL_PUBLIC_SUBNET_AVAILABILITY_ZONE="${ADDITIONAL_PUBLIC_SUBNET_AVAILABILITY_ZONE:-${TF_VAR_additional_public_subnet_availability_zone:-}}"

section() {
  printf '\n== %s ==\n' "$1"
}

run_json() {
  local description="$1"
  shift
  echo "$description"
  if ! "$@" 2>/tmp/diagnostico_aws_error.log; then
    sed 's/^/  /' /tmp/diagnostico_aws_error.log
  fi
}

section "Identidad AWS"
run_json "Cuenta y usuario/rol activos:" aws sts get-caller-identity --output json
echo "Region de recursos AWS: $AWS_REGION"
echo "Region del backend S3: $BACKEND_REGION"

section "Backend Terraform"
if [ -n "$BUCKET" ]; then
  run_json "Bucket S3 del state ($BUCKET):" aws s3api head-bucket --bucket "$BUCKET" --region "$BACKEND_REGION"
  run_json "Objeto state ($TF_STATE_KEY):" aws s3api head-object --bucket "$BUCKET" --key "$TF_STATE_KEY" --region "$BACKEND_REGION" --output json
else
  echo "BUCKET no está definido."
fi

if [ -n "$LOCKS" ]; then
  run_json "Tabla DynamoDB de locks ($LOCKS):" aws dynamodb describe-table --table-name "$LOCKS" --region "$BACKEND_REGION" --query 'Table.{TableName:TableName,Status:TableStatus,BillingMode:BillingModeSummary.BillingMode}' --output json
else
  echo "LOCKS no está definido."
fi

section "Recursos con nombres conocidos"
LOG_GROUP="/ecs/${NOMBRE_SERVICIO}"
run_json "CloudWatch Log Group ($LOG_GROUP):" aws logs describe-log-groups --log-group-name-prefix "$LOG_GROUP" --region "$AWS_REGION" --query "logGroups[?logGroupName=='$LOG_GROUP']" --output json
run_json "EventBridge Event Bus ($NOMBRE_EVENT_BUS):" aws events describe-event-bus --name "$NOMBRE_EVENT_BUS" --region "$AWS_REGION" --output json
run_json "Target Group ($NOMBRE_TARGET_GROUP):" aws elbv2 describe-target-groups --names "$NOMBRE_TARGET_GROUP" --region "$AWS_REGION" --query 'TargetGroups[].{Name:TargetGroupName,Arn:TargetGroupArn,VpcId:VpcId,Port:Port,Protocol:Protocol}' --output json
run_json "Application Load Balancer ($NOMBRE_LOAD_BALANCER):" aws elbv2 describe-load-balancers --names "$NOMBRE_LOAD_BALANCER" --region "$AWS_REGION" --query 'LoadBalancers[].{Name:LoadBalancerName,Arn:LoadBalancerArn,DNSName:DNSName,VpcId:VpcId,Subnets:AvailabilityZones[].SubnetId}' --output json

section "VPC y subnets"
if [ -z "$VPC_ID" ]; then
  VPC_ID="$(aws ec2 describe-vpcs --filters Name=is-default,Values=true --region "$AWS_REGION" --query 'Vpcs[0].VpcId' --output text 2>/dev/null || true)"
  echo "VPC_ID no estaba definido; VPC por defecto detectada: $VPC_ID"
else
  echo "VPC_ID definido: $VPC_ID"
fi

if [ -n "$VPC_ID" ] && [ "$VPC_ID" != "None" ]; then
  run_json "CIDR de la VPC seleccionada:" aws ec2 describe-vpcs --vpc-ids "$VPC_ID" --region "$AWS_REGION" --query 'Vpcs[].{VpcId:VpcId,CidrBlock:CidrBlock,CidrBlockAssociationSet:CidrBlockAssociationSet[].CidrBlock}' --output json
fi

if ! echo "$PUBLIC_SUBNET_IDS_JSON" | jq -e 'type == "array" and all(.[]; type == "string")' >/dev/null; then
  echo "PUBLIC_SUBNET_IDS_JSON no es una lista JSON de strings: $PUBLIC_SUBNET_IDS_JSON"
  exit 1
fi

mapfile -t SUBNET_IDS < <(echo "$PUBLIC_SUBNET_IDS_JSON" | jq -r '.[]')
if [ "${#SUBNET_IDS[@]}" -eq 0 ] && [ -n "$VPC_ID" ] && [ "$VPC_ID" != "None" ]; then
  mapfile -t SUBNET_IDS < <(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" --region "$AWS_REGION" --query 'Subnets[].SubnetId' --output text | tr '\t' '\n')
fi

if [ "${#SUBNET_IDS[@]}" -eq 0 ]; then
  echo "No se encontraron subnets para diagnosticar."
  exit 0
fi

printf 'Subnets evaluadas:\n'
printf '  %s\n' "${SUBNET_IDS[@]}"

run_json "Detalle de subnets:" aws ec2 describe-subnets --subnet-ids "${SUBNET_IDS[@]}" --region "$AWS_REGION" --query 'Subnets[].{SubnetId:SubnetId,VpcId:VpcId,AZ:AvailabilityZone,MapPublicIpOnLaunch:MapPublicIpOnLaunch,CidrBlock:CidrBlock,AvailableIpAddressCount:AvailableIpAddressCount}' --output json

AZ_COUNT="$(aws ec2 describe-subnets --subnet-ids "${SUBNET_IDS[@]}" --region "$AWS_REGION" --output json | jq '[.Subnets[].AvailabilityZone] | unique | length')"
echo "Cantidad de subnets evaluadas: ${#SUBNET_IDS[@]}"
echo "Cantidad de Availability Zones distintas: $AZ_COUNT"

if [ "${#SUBNET_IDS[@]}" -lt 2 ] || [ "$AZ_COUNT" -lt 2 ]; then
  echo "El ALB no puede crearse con esta selección actual de subnets."
  if [ "$CREATE_MISSING_PUBLIC_SUBNET_FOR_ALB" = "true" ]; then
    echo "CREATE_MISSING_PUBLIC_SUBNET_FOR_ALB=true: Terraform intentará crear una subnet pública adicional si PUBLIC_SUBNET_IDS_JSON está vacío."
    echo "CIDR adicional configurado: ${ADDITIONAL_PUBLIC_SUBNET_CIDR_BLOCK:-<vacío>}"
    echo "AZ adicional configurada: ${ADDITIONAL_PUBLIC_SUBNET_AVAILABILITY_ZONE:-<vacío>}"
    if [ -z "$ADDITIONAL_PUBLIC_SUBNET_CIDR_BLOCK" ] || [ -z "$ADDITIONAL_PUBLIC_SUBNET_AVAILABILITY_ZONE" ]; then
      echo "Faltan ADDITIONAL_PUBLIC_SUBNET_CIDR_BLOCK o ADDITIONAL_PUBLIC_SUBNET_AVAILABILITY_ZONE."
    fi
  else
    echo "Configura PUBLIC_SUBNET_IDS_JSON con al menos dos subnets públicas en AZs distintas o habilita CREATE_MISSING_PUBLIC_SUBNET_FOR_ALB=true con CIDR/AZ adicionales."
  fi
else
  echo "La selección actual cumple el mínimo de subnets/AZs para un ALB."
fi

section "Route tables"
for subnet_id in "${SUBNET_IDS[@]}"; do
  subnet_vpc_id="$(aws ec2 describe-subnets --subnet-ids "$subnet_id" --region "$AWS_REGION" --query 'Subnets[0].VpcId' --output text)"
  route_table_json="$(aws ec2 describe-route-tables --filters "Name=association.subnet-id,Values=$subnet_id" --region "$AWS_REGION" --output json)"
  if [ "$(echo "$route_table_json" | jq '.RouteTables | length')" -eq 0 ]; then
    route_table_json="$(aws ec2 describe-route-tables --filters "Name=vpc-id,Values=$subnet_vpc_id" "Name=association.main,Values=true" --region "$AWS_REGION" --output json)"
  fi
  echo "Subnet $subnet_id:"
  echo "$route_table_json" | jq '[.RouteTables[] | {RouteTableId, Routes: [.Routes[] | {DestinationCidrBlock, GatewayId, NatGatewayId, State}]}]'
  if echo "$route_table_json" | jq -e '.RouteTables[].Routes[]? | select(.DestinationCidrBlock == "0.0.0.0/0" and (.GatewayId // "" | startswith("igw-")))' >/dev/null; then
    echo "  Ruta publica detectada: 0.0.0.0/0 hacia Internet Gateway."
  else
    echo "  No se detectó ruta publica 0.0.0.0/0 hacia Internet Gateway."
  fi
done
