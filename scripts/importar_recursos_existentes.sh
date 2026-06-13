#!/usr/bin/env bash
set -euo pipefail

AWS_REGION="${AWS_REGION:-us-east-1}"
IAC_DIR="${IAC_DIR:-iac}"

cd "${IAC_DIR}"

export TF_VAR_id_cuenta_aws="${TF_VAR_id_cuenta_aws:-${AWS_ACCOUNT_ID:-000000000000}}"
export TF_VAR_nombre_rol_iam="${TF_VAR_nombre_rol_iam:-${NOMBRE_ROL_IAM:-LabRole}}"
export TF_VAR_contrasenha_base_datos="${TF_VAR_contrasenha_base_datos:-dummy-password-for-import}"
export TF_VAR_create_missing_public_subnet_for_lab="${TF_VAR_create_missing_public_subnet_for_lab:-${CREATE_MISSING_PUBLIC_SUBNET_FOR_LAB:-false}}"
export TF_VAR_additional_public_subnet_cidr_block="${TF_VAR_additional_public_subnet_cidr_block:-${ADDITIONAL_PUBLIC_SUBNET_CIDR_BLOCK:-172.31.32.0/20}}"
export TF_VAR_additional_public_subnet_availability_zone="${TF_VAR_additional_public_subnet_availability_zone:-${ADDITIONAL_PUBLIC_SUBNET_AVAILABILITY_ZONE:-us-east-1b}}"

state_has() {
  terraform state show "$1" >/dev/null 2>&1
}

tf_import_if_missing() {
  local address="$1"
  local import_id="$2"

  if [[ -z "${import_id}" || "${import_id}" == "None" || "${import_id}" == "null" ]]; then
    echo "SKIP ${address}: recurso no encontrado en AWS"
    return 0
  fi

  if state_has "${address}"; then
    echo "OK   ${address}: ya existe en state"
    return 0
  fi

  echo "IMPORT ${address} <- ${import_id}"
  local import_output
  if import_output="$(terraform import -input=false "${address}" "${import_id}" 2>&1)"; then
    printf '%s\n' "${import_output}"
    return 0
  fi

  if printf '%s\n' "${import_output}" | grep -q "Resource already managed by Terraform"; then
    echo "OK   ${address}: Terraform ya lo gestiona; se omite import"
    return 0
  fi

  printf '%s\n' "${import_output}" >&2
  return 1
}

aws_text() {
  aws "$@" --region "${AWS_REGION}" --output text
}

api_id="$(aws_text apigatewayv2 get-apis --query 'Items[?Name==`tienda-virtual-api`].ApiId | [0]' || true)"
tf_import_if_missing "module.api.aws_apigatewayv2_api.http_api" "${api_id}"
if [[ -n "${api_id}" && "${api_id}" != "None" ]]; then
  tf_import_if_missing "module.api.aws_apigatewayv2_stage.default_stage" "${api_id}/\$default"
fi

event_bus_name="$(aws_text events describe-event-bus --name ordenes-bus --query 'Name' 2>/dev/null || true)"
crear_orden_rule="$(aws_text events describe-rule --event-bus-name ordenes-bus --name crear-orden --query 'Name' 2>/dev/null || true)"
actualizar_orden_rule="$(aws_text events describe-rule --event-bus-name ordenes-bus --name actualizar-orden --query 'Name' 2>/dev/null || true)"
tf_import_if_missing "module.events.aws_cloudwatch_event_bus.ordenes_bus" "${event_bus_name}"
if [[ -n "${crear_orden_rule}" && "${crear_orden_rule}" != "None" ]]; then
  tf_import_if_missing "module.events.aws_cloudwatch_event_rule.crear_orden" "ordenes-bus/crear-orden"
else
  echo "SKIP module.events.aws_cloudwatch_event_rule.crear_orden: recurso no encontrado en AWS"
fi
if [[ -n "${actualizar_orden_rule}" && "${actualizar_orden_rule}" != "None" ]]; then
  tf_import_if_missing "module.events.aws_cloudwatch_event_rule.actualizar_orden" "ordenes-bus/actualizar-orden"
else
  echo "SKIP module.events.aws_cloudwatch_event_rule.actualizar_orden: recurso no encontrado en AWS"
fi

cluster_arn="$(aws_text ecs describe-clusters --clusters tienda-virtual-cluster --query 'clusters[0].clusterArn' || true)"
tf_import_if_missing "module.compute.aws_ecs_cluster.cluster_tienda_virtual_servicios" "${cluster_arn}"

alb_sg_id="$(aws_text ec2 describe-security-groups --filters Name=group-name,Values=tienda-virtual-cluster-alb-sg --query 'SecurityGroups[0].GroupId' || true)"
ecs_sg_id="$(aws_text ec2 describe-security-groups --filters Name=group-name,Values=tienda-virtual-cluster-ecs-sg --query 'SecurityGroups[0].GroupId' || true)"
tf_import_if_missing "module.compute.aws_security_group.alb_security_group" "${alb_sg_id}"
tf_import_if_missing "module.compute.aws_security_group.ecs_security_group" "${ecs_sg_id}"

tg_ventas_arn="$(aws_text elbv2 describe-target-groups --names tg-tienda-ventas --query 'TargetGroups[0].TargetGroupArn' || true)"
tg_logistica_arn="$(aws_text elbv2 describe-target-groups --names tg-tienda-logistica --query 'TargetGroups[0].TargetGroupArn' || true)"
tf_import_if_missing "module.compute.aws_lb_target_group.tg_ventas" "${tg_ventas_arn}"
tf_import_if_missing "module.compute.aws_lb_target_group.tg_logistica" "${tg_logistica_arn}"

ventas_log_group="$(aws_text logs describe-log-groups --log-group-name-prefix /ecs/servicio-ventas --query 'logGroups[?logGroupName==`/ecs/servicio-ventas`].logGroupName | [0]' || true)"
logistica_log_group="$(aws_text logs describe-log-groups --log-group-name-prefix /ecs/servicio-logistica --query 'logGroups[?logGroupName==`/ecs/servicio-logistica`].logGroupName | [0]' || true)"
tf_import_if_missing "module.compute.aws_cloudwatch_log_group.ecs_logs_ventas" "${ventas_log_group}"
tf_import_if_missing "module.compute.aws_cloudwatch_log_group.ecs_logs_logistica" "${logistica_log_group}"

ventas_queue_url="$(aws_text sqs get-queue-url --queue-name ventas-sync-queue.fifo --query 'QueueUrl' || true)"
logistica_queue_url="$(aws_text sqs get-queue-url --queue-name logistica-sync-queue.fifo --query 'QueueUrl' || true)"
ventas_dlq_url="$(aws_text sqs get-queue-url --queue-name ventas-sync-queue-dlq.fifo --query 'QueueUrl' || true)"
logistica_dlq_url="$(aws_text sqs get-queue-url --queue-name logistica-sync-queue-dlq.fifo --query 'QueueUrl' || true)"

tf_import_if_missing "module.serverless.aws_sqs_queue.ventas_sync_queue" "${ventas_queue_url}"
tf_import_if_missing "module.serverless.aws_sqs_queue.logistica_sync_queue" "${logistica_queue_url}"
tf_import_if_missing "module.serverless.aws_sqs_queue.ventas_sync_dlq" "${ventas_dlq_url}"
tf_import_if_missing "module.serverless.aws_sqs_queue.logistica_sync_dlq" "${logistica_dlq_url}"
tf_import_if_missing "module.serverless.aws_sqs_queue_policy.ventas_sync_queue_policy" "${ventas_queue_url}"
tf_import_if_missing "module.serverless.aws_sqs_queue_policy.logistica_sync_queue_policy" "${logistica_queue_url}"

echo "Importacion idempotente terminada."
