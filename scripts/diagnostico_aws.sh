#!/usr/bin/env bash
set -euo pipefail

AWS_REGION="${AWS_REGION:-us-east-1}"
CREATE_MISSING_PUBLIC_SUBNET_FOR_LAB="${CREATE_MISSING_PUBLIC_SUBNET_FOR_LAB:-false}"
ADDITIONAL_PUBLIC_SUBNET_CIDR_BLOCK="${ADDITIONAL_PUBLIC_SUBNET_CIDR_BLOCK:-172.31.32.0/20}"
ADDITIONAL_PUBLIC_SUBNET_AVAILABILITY_ZONE="${ADDITIONAL_PUBLIC_SUBNET_AVAILABILITY_ZONE:-us-east-1b}"

echo "Region: ${AWS_REGION}"
echo "CREATE_MISSING_PUBLIC_SUBNET_FOR_LAB=${CREATE_MISSING_PUBLIC_SUBNET_FOR_LAB}"
echo "ADDITIONAL_PUBLIC_SUBNET_CIDR_BLOCK=${ADDITIONAL_PUBLIC_SUBNET_CIDR_BLOCK}"
echo "ADDITIONAL_PUBLIC_SUBNET_AVAILABILITY_ZONE=${ADDITIONAL_PUBLIC_SUBNET_AVAILABILITY_ZONE}"

vpc_id="$(aws ec2 describe-vpcs \
  --region "${AWS_REGION}" \
  --filters Name=is-default,Values=true \
  --query 'Vpcs[0].VpcId' \
  --output text)"

if [[ -z "${vpc_id}" || "${vpc_id}" == "None" ]]; then
  echo "No se encontro VPC default en ${AWS_REGION}" >&2
  exit 1
fi

vpc_cidr="$(aws ec2 describe-vpcs \
  --region "${AWS_REGION}" \
  --vpc-ids "${vpc_id}" \
  --query 'Vpcs[0].CidrBlock' \
  --output text)"

echo "VPC seleccionada: ${vpc_id}"
echo "CIDR VPC: ${vpc_cidr}"
echo
echo "Subnets existentes:"
aws ec2 describe-subnets \
  --region "${AWS_REGION}" \
  --filters Name=vpc-id,Values="${vpc_id}" \
  --query 'Subnets[].{SubnetId:SubnetId,AZ:AvailabilityZone,CIDR:CidrBlock,MapPublicIpOnLaunch:MapPublicIpOnLaunch}' \
  --output table

subnets_json="$(aws ec2 describe-subnets \
  --region "${AWS_REGION}" \
  --filters Name=vpc-id,Values="${vpc_id}" \
  --query 'Subnets[].{SubnetId:SubnetId,AZ:AvailabilityZone,CIDR:CidrBlock,MapPublicIpOnLaunch:MapPublicIpOnLaunch}' \
  --output json)"

az_count="$(printf '%s' "${subnets_json}" | jq -r '.[].AZ' | sort -u | wc -l | tr -d ' ')"
echo "AZs cubiertas por subnets existentes: ${az_count}"

echo
echo "Subnets que usaria Terraform para ALB/RDS antes de crear subnet adicional:"
printf '%s' "${subnets_json}" | jq -r '
  sort_by(.AZ)
  | group_by(.AZ)
  | map(.[0])
  | .[0:2]
  | (["SubnetId","AZ","CIDR","MapPublicIpOnLaunch"] | @tsv),
    (.[] | [.SubnetId, .AZ, .CIDR, (.MapPublicIpOnLaunch|tostring)] | @tsv)
' | column -t

if [[ "${az_count}" -ge 2 ]]; then
  echo
  echo "Resultado: ya hay al menos 2 AZs. No se requiere subnet adicional."
  exit 0
fi

echo
echo "Resultado: solo hay ${az_count} AZ cubierta. ALB y RDS fallaran sin una subnet adicional."
if [[ "${CREATE_MISSING_PUBLIC_SUBNET_FOR_LAB}" != "true" ]]; then
  echo "CREATE_MISSING_PUBLIC_SUBNET_FOR_LAB no esta activo."
  exit 0
fi

echo "Terraform intentara crear una subnet adicional en ${ADDITIONAL_PUBLIC_SUBNET_AVAILABILITY_ZONE} con CIDR ${ADDITIONAL_PUBLIC_SUBNET_CIDR_BLOCK}."
python3 - "${vpc_cidr}" "${ADDITIONAL_PUBLIC_SUBNET_CIDR_BLOCK}" "${subnets_json}" <<'PY'
import ipaddress
import json
import sys

vpc = ipaddress.ip_network(sys.argv[1])
candidate = ipaddress.ip_network(sys.argv[2])
subnets = json.loads(sys.argv[3])

print(f"CIDR adicional dentro de VPC: {candidate.subnet_of(vpc)}")
overlaps = [s for s in subnets if candidate.overlaps(ipaddress.ip_network(s["CIDR"]))]
if overlaps:
    print("Conflictos de CIDR detectados:")
    for subnet in overlaps:
        print(f"- {subnet['SubnetId']} {subnet['AZ']} {subnet['CIDR']}")
    sys.exit(1)

print("Conflictos de CIDR detectados: ninguno")
PY
