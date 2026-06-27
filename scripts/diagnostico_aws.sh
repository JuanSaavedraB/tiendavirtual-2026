#!/usr/bin/env bash
set -euo pipefail

AWS_REGION="${AWS_REGION:-${TF_VAR_region:-us-east-1}}"
CREATE_MISSING_PUBLIC_SUBNET_FOR_LAB="${CREATE_MISSING_PUBLIC_SUBNET_FOR_LAB:-${TF_VAR_create_missing_public_subnet_for_lab:-false}}"
ADDITIONAL_PUBLIC_SUBNET_CIDR_BLOCK="${ADDITIONAL_PUBLIC_SUBNET_CIDR_BLOCK:-${TF_VAR_additional_public_subnet_cidr_block:-172.31.32.0/20}}"
ADDITIONAL_PUBLIC_SUBNET_AVAILABILITY_ZONE="${ADDITIONAL_PUBLIC_SUBNET_AVAILABILITY_ZONE:-${TF_VAR_additional_public_subnet_availability_zone:-us-east-1b}}"

echo "== Variables esperadas de GitHub Actions =="
echo "CREATE_MISSING_PUBLIC_SUBNET_FOR_LAB=${CREATE_MISSING_PUBLIC_SUBNET_FOR_LAB}"
echo "ADDITIONAL_PUBLIC_SUBNET_CIDR_BLOCK=${ADDITIONAL_PUBLIC_SUBNET_CIDR_BLOCK}"
echo "ADDITIONAL_PUBLIC_SUBNET_AVAILABILITY_ZONE=${ADDITIONAL_PUBLIC_SUBNET_AVAILABILITY_ZONE}"
echo "TF_VAR_create_missing_public_subnet_for_lab=${TF_VAR_create_missing_public_subnet_for_lab:-<no definido>}"
echo "TF_VAR_additional_public_subnet_cidr_block=${TF_VAR_additional_public_subnet_cidr_block:-<no definido>}"
echo "TF_VAR_additional_public_subnet_availability_zone=${TF_VAR_additional_public_subnet_availability_zone:-<no definido>}"
echo

VPC_ID="$(aws ec2 describe-vpcs \
  --region "$AWS_REGION" \
  --filters Name=is-default,Values=true \
  --query 'Vpcs[0].VpcId' \
  --output text)"

if [[ -z "$VPC_ID" || "$VPC_ID" == "None" ]]; then
  echo "ERROR: No se encontro VPC default en ${AWS_REGION}."
  exit 1
fi

VPC_CIDR="$(aws ec2 describe-vpcs \
  --region "$AWS_REGION" \
  --vpc-ids "$VPC_ID" \
  --query 'Vpcs[0].CidrBlock' \
  --output text)"

echo "== VPC seleccionada =="
echo "VPC_ID=${VPC_ID}"
echo "VPC_CIDR=${VPC_CIDR}"
echo

echo "== Subnets existentes =="
aws ec2 describe-subnets \
  --region "$AWS_REGION" \
  --filters "Name=vpc-id,Values=${VPC_ID}" \
  --query 'Subnets[].{SubnetId:SubnetId,AZ:AvailabilityZone,CIDR:CidrBlock,MapPublicIpOnLaunch:MapPublicIpOnLaunch}' \
  --output table
echo

mapfile -t PUBLIC_SUBNET_LINES < <(aws ec2 describe-subnets \
  --region "$AWS_REGION" \
  --filters "Name=vpc-id,Values=${VPC_ID}" "Name=map-public-ip-on-launch,Values=true" \
  --query 'Subnets[].join(`|`, [SubnetId, AvailabilityZone, CidrBlock])' \
  --output text | tr '\t' '\n' | sed '/^$/d')

declare -a FINAL_SUBNET_IDS=()
declare -a FINAL_AZS=()
declare -a FINAL_RDS_SUBNET_IDS=()
declare -a FINAL_RDS_AZS=()

for line in "${PUBLIC_SUBNET_LINES[@]}"; do
  subnet_id="${line%%|*}"
  rest="${line#*|}"
  az="${rest%%|*}"
  FINAL_SUBNET_IDS+=("$subnet_id")
  FINAL_AZS+=("$az")
  FINAL_RDS_SUBNET_IDS+=("$subnet_id")
  FINAL_RDS_AZS+=("$az")
done

has_additional_az="false"
for az in "${FINAL_AZS[@]}"; do
  if [[ "$az" == "$ADDITIONAL_PUBLIC_SUBNET_AVAILABILITY_ZONE" ]]; then
    has_additional_az="true"
  fi
done

if [[ "$CREATE_MISSING_PUBLIC_SUBNET_FOR_LAB" == "true" && "$has_additional_az" != "true" ]]; then
  FINAL_SUBNET_IDS+=("<terraform creara subnet: ${ADDITIONAL_PUBLIC_SUBNET_CIDR_BLOCK}>")
  FINAL_AZS+=("$ADDITIONAL_PUBLIC_SUBNET_AVAILABILITY_ZONE")
  FINAL_RDS_SUBNET_IDS+=("<terraform creara subnet: ${ADDITIONAL_PUBLIC_SUBNET_CIDR_BLOCK}>")
  FINAL_RDS_AZS+=("$ADDITIONAL_PUBLIC_SUBNET_AVAILABILITY_ZONE")
fi

unique_azs="$(printf '%s\n' "${FINAL_AZS[@]}" | sed '/^$/d' | sort -u | wc -l | tr -d ' ')"

echo "== Diagnostico de AZs =="
if [[ "$unique_azs" -lt 2 ]]; then
  echo "Se detecta solo una AZ final. ALB y RDS fallaran si no se crea/reutiliza una subnet adicional."
else
  echo "Se detectan ${unique_azs} AZs finales para ALB y RDS."
fi
echo "Crear subnet adicional para lab: ${CREATE_MISSING_PUBLIC_SUBNET_FOR_LAB}"
echo

echo "== Subnets finales para ALB =="
printf 'IDs: %s\n' "${FINAL_SUBNET_IDS[*]:-<ninguna>}"
printf 'AZs: %s\n' "${FINAL_AZS[*]:-<ninguna>}"
echo

echo "== Subnets finales para RDS =="
printf 'IDs: %s\n' "${FINAL_RDS_SUBNET_IDS[*]:-<ninguna>}"
printf 'AZs: %s\n' "${FINAL_RDS_AZS[*]:-<ninguna>}"
