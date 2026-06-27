#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IAC_DIR="${ROOT_DIR}/iac"
AWS_REGION="${AWS_REGION:-${TF_VAR_region:-us-east-1}}"
PATH_BASE_SERVICIO="${PATH_BASE_SERVICIO:-${TF_VAR_path_base_servicio:-api}}"
ADDITIONAL_PUBLIC_SUBNET_CIDR_BLOCK="${ADDITIONAL_PUBLIC_SUBNET_CIDR_BLOCK:-${TF_VAR_additional_public_subnet_cidr_block:-172.31.32.0/20}}"
ADDITIONAL_PUBLIC_SUBNET_AVAILABILITY_ZONE="${ADDITIONAL_PUBLIC_SUBNET_AVAILABILITY_ZONE:-${TF_VAR_additional_public_subnet_availability_zone:-us-east-1b}}"
PATH_BASE_SERVICIO="${PATH_BASE_SERVICIO#/}"
PATH_BASE_SERVICIO="${PATH_BASE_SERVICIO%/}"
ROUTE_PREFIX="/${PATH_BASE_SERVICIO}"

state_has() {
  terraform -chdir="$IAC_DIR" state show "$1" >/dev/null 2>&1
}

import_if_needed() {
  local address="$1"
  local import_id="$2"

  if [[ -z "$import_id" || "$import_id" == "None" || "$import_id" == "null" || "$import_id" == *"/None" || "$import_id" == *"/null" ]]; then
    echo "SKIP ${address}: no existe en AWS."
    return 0
  fi

  if state_has "$address"; then
    echo "SKIP ${address}: ya esta en el state."
    return 0
  fi

  echo "IMPORT ${address} <- ${import_id}"
  if ! terraform -chdir="$IAC_DIR" import "$address" "$import_id"; then
    if state_has "$address"; then
      echo "SKIP ${address}: quedo administrado por Terraform."
      return 0
    fi
    echo "ERROR importando ${address}."
    return 1
  fi
}

query_text() {
  aws "$@" --region "$AWS_REGION" --output text 2>/dev/null || true
}

vpc_id="$(query_text ec2 describe-vpcs --filters Name=is-default,Values=true --query 'Vpcs[0].VpcId')"

if [[ -n "$vpc_id" && "$vpc_id" != "None" ]]; then
  additional_subnet_id="$(query_text ec2 describe-subnets \
    --filters "Name=vpc-id,Values=${vpc_id}" "Name=availability-zone,Values=${ADDITIONAL_PUBLIC_SUBNET_AVAILABILITY_ZONE}" "Name=cidr-block,Values=${ADDITIONAL_PUBLIC_SUBNET_CIDR_BLOCK}" \
    --query 'Subnets[0].SubnetId')"
  import_if_needed "module.networking.aws_subnet.additional_public_subnet_for_lab[0]" "$additional_subnet_id"

  alb_sg_id="$(query_text ec2 describe-security-groups --filters "Name=vpc-id,Values=${vpc_id}" "Name=group-name,Values=tienda-virtual-cluster-alb-sg" --query 'SecurityGroups[0].GroupId')"
  import_if_needed "module.compute.aws_security_group.alb_security_group" "$alb_sg_id"

  ecs_sg_id="$(query_text ec2 describe-security-groups --filters "Name=vpc-id,Values=${vpc_id}" "Name=group-name,Values=tienda-virtual-cluster-ecs-sg" --query 'SecurityGroups[0].GroupId')"
  import_if_needed "module.compute.aws_security_group.ecs_security_group" "$ecs_sg_id"
fi

ecs_cluster_name="tienda-virtual-cluster"
ecs_cluster_status="$(query_text ecs describe-clusters --clusters "$ecs_cluster_name" --query 'clusters[0].status')"
if [[ "$ecs_cluster_status" == "ACTIVE" ]]; then
  import_if_needed "module.compute.aws_ecs_cluster.cluster_tienda_virtual_servicios" "$ecs_cluster_name"
else
  echo "SKIP module.compute.aws_ecs_cluster.cluster_tienda_virtual_servicios: no existe en AWS."
fi

ventas_service_name="$(query_text ecs describe-services --cluster "$ecs_cluster_name" --services servicio-ventas --query 'services[0].serviceName')"
logistica_service_name="$(query_text ecs describe-services --cluster "$ecs_cluster_name" --services servicio-logistica --query 'services[0].serviceName')"
if [[ "$ventas_service_name" == "servicio-ventas" ]]; then
  import_if_needed "module.compute.aws_ecs_service.servicio_ventas" "${ecs_cluster_name}/${ventas_service_name}"
else
  echo "SKIP module.compute.aws_ecs_service.servicio_ventas: no existe en AWS."
fi
if [[ "$logistica_service_name" == "servicio-logistica" ]]; then
  import_if_needed "module.compute.aws_ecs_service.servicio_logistica" "${ecs_cluster_name}/${logistica_service_name}"
else
  echo "SKIP module.compute.aws_ecs_service.servicio_logistica: no existe en AWS."
fi

import_if_needed "module.compute.aws_cloudwatch_log_group.ecs_logs_ventas" "$(query_text logs describe-log-groups --log-group-name-prefix /ecs/servicio-ventas --query 'logGroups[?logGroupName==`/ecs/servicio-ventas`].logGroupName | [0]')"
import_if_needed "module.compute.aws_cloudwatch_log_group.ecs_logs_logistica" "$(query_text logs describe-log-groups --log-group-name-prefix /ecs/servicio-logistica --query 'logGroups[?logGroupName==`/ecs/servicio-logistica`].logGroupName | [0]')"

alb_arn="$(query_text elbv2 describe-load-balancers --names tienda-virtual-alb --query 'LoadBalancers[0].LoadBalancerArn')"
import_if_needed "module.compute.aws_lb.tienda_virtual_load_balancer" "$alb_arn"

tg_ventas_arn="$(query_text elbv2 describe-target-groups --names tg-tienda-ventas --query 'TargetGroups[0].TargetGroupArn')"
tg_logistica_arn="$(query_text elbv2 describe-target-groups --names tg-tienda-logistica --query 'TargetGroups[0].TargetGroupArn')"
import_if_needed "module.compute.aws_lb_target_group.tg_ventas" "$tg_ventas_arn"
import_if_needed "module.compute.aws_lb_target_group.tg_logistica" "$tg_logistica_arn"

if [[ -n "$alb_arn" && "$alb_arn" != "None" ]]; then
  listener_arn="$(query_text elbv2 describe-listeners --load-balancer-arn "$alb_arn" --query 'Listeners[?Port==`80`].ListenerArn | [0]')"
  import_if_needed "module.compute.aws_lb_listener.http_listener" "$listener_arn"

  rule_arn="$(query_text elbv2 describe-rules --listener-arn "$listener_arn" --query 'Rules[?Priority==`10`].RuleArn | [0]')"
  import_if_needed "module.compute.aws_lb_listener_rule.rule_logistica_productos" "$rule_arn"
fi

db_subnet_group_name="$(query_text rds describe-db-subnet-groups --db-subnet-group-name tiendavirtual-subnet-group --query 'DBSubnetGroups[0].DBSubnetGroupName')"
import_if_needed "module.database.aws_db_subnet_group.rds_subnet_group" "$db_subnet_group_name"

db_instance_id="$(query_text rds describe-db-instances --db-instance-identifier tiendavirtual --query 'DBInstances[0].DBInstanceIdentifier')"
import_if_needed "module.database.aws_db_instance.tienda_virtual_mysql" "$db_instance_id"

for queue in ventas-sync-queue-dlq.fifo logistica-sync-queue-dlq.fifo ventas-sync-queue.fifo logistica-sync-queue.fifo; do
  queue_url="$(aws sqs get-queue-url --region "$AWS_REGION" --queue-name "$queue" --query 'QueueUrl' --output text 2>/dev/null || true)"
  case "$queue" in
    ventas-sync-queue-dlq.fifo) address="module.serverless.aws_sqs_queue.ventas_sync_dlq" ;;
    logistica-sync-queue-dlq.fifo) address="module.serverless.aws_sqs_queue.logistica_sync_dlq" ;;
    ventas-sync-queue.fifo) address="module.serverless.aws_sqs_queue.ventas_sync_queue" ;;
    logistica-sync-queue.fifo) address="module.serverless.aws_sqs_queue.logistica_sync_queue" ;;
  esac
  import_if_needed "$address" "$queue_url"
done

ventas_queue_url="$(aws sqs get-queue-url --region "$AWS_REGION" --queue-name ventas-sync-queue.fifo --query 'QueueUrl' --output text 2>/dev/null || true)"
logistica_queue_url="$(aws sqs get-queue-url --region "$AWS_REGION" --queue-name logistica-sync-queue.fifo --query 'QueueUrl' --output text 2>/dev/null || true)"
import_if_needed "module.serverless.aws_sqs_queue_policy.ventas_sync_queue_policy" "$ventas_queue_url"
import_if_needed "module.serverless.aws_sqs_queue_policy.logistica_sync_queue_policy" "$logistica_queue_url"

import_if_needed "module.serverless.aws_lambda_function.crear_orden" "$(query_text lambda get-function --function-name crear-orden --query 'Configuration.FunctionName')"
import_if_needed "module.serverless.aws_lambda_function.merger_sync" "$(query_text lambda get-function --function-name merger-sync-tiendavirtual --query 'Configuration.FunctionName')"

crear_orden_arn="$(query_text lambda get-function --function-name crear-orden --query 'Configuration.FunctionArn')"
merger_arn="$(query_text lambda get-function --function-name merger-sync-tiendavirtual --query 'Configuration.FunctionArn')"
if [[ -n "$merger_arn" && "$merger_arn" != "None" ]]; then
  ventas_queue_arn="$(query_text sqs get-queue-attributes --queue-url "$ventas_queue_url" --attribute-names QueueArn --query 'Attributes.QueueArn')"
  logistica_queue_arn="$(query_text sqs get-queue-attributes --queue-url "$logistica_queue_url" --attribute-names QueueArn --query 'Attributes.QueueArn')"
  import_if_needed "module.serverless.aws_lambda_event_source_mapping.merger_desde_ventas" "$(query_text lambda list-event-source-mappings --function-name "$merger_arn" --event-source-arn "$ventas_queue_arn" --query 'EventSourceMappings[0].UUID')"
  import_if_needed "module.serverless.aws_lambda_event_source_mapping.merger_desde_logistica" "$(query_text lambda list-event-source-mappings --function-name "$merger_arn" --event-source-arn "$logistica_queue_arn" --query 'EventSourceMappings[0].UUID')"
fi

api_id="$(query_text apigatewayv2 get-apis --query 'Items[?Name==`tienda-virtual-api`].ApiId | [0]')"
import_if_needed "module.api.aws_apigatewayv2_api.http_api" "$api_id"
if [[ -n "$api_id" && "$api_id" != "None" ]]; then
  import_if_needed "module.api.aws_apigatewayv2_stage.default_stage" "${api_id}/\$default"

  import_route() {
    local address="$1"
    local route_key="$2"
    local route_id
    route_id="$(query_text apigatewayv2 get-routes --api-id "$api_id" --query "Items[?RouteKey=='${route_key}'].RouteId | [0]")"
    import_if_needed "$address" "${api_id}/${route_id}"
  }

  import_integration_from_route() {
    local address="$1"
    local route_key="$2"
    local route_id target integration_id

    route_id="$(query_text apigatewayv2 get-routes --api-id "$api_id" --query "Items[?RouteKey=='${route_key}'].RouteId | [0]")"
    if [[ -z "$route_id" || "$route_id" == "None" ]]; then
      echo "SKIP ${address}: no se encontro ruta ${route_key}."
      return 0
    fi

    target="$(query_text apigatewayv2 get-route --api-id "$api_id" --route-id "$route_id" --query 'Target')"
    integration_id="${target#integrations/}"
    import_if_needed "$address" "${api_id}/${integration_id}"
  }

  import_integration_from_route "module.api.aws_apigatewayv2_integration.productos_integration_get_all" "GET ${ROUTE_PREFIX}/productos"
  import_integration_from_route "module.api.aws_apigatewayv2_integration.productos_integration" "GET ${ROUTE_PREFIX}/productos/{proxy+}"
  import_integration_from_route "module.api.aws_apigatewayv2_integration.clientes_integration_get_all" "GET ${ROUTE_PREFIX}/clientes"
  import_integration_from_route "module.api.aws_apigatewayv2_integration.clientes_integration" "GET ${ROUTE_PREFIX}/clientes/{proxy+}"
  import_integration_from_route "module.api.aws_apigatewayv2_integration.carritos_integration_get_all" "GET ${ROUTE_PREFIX}/carritos"
  import_integration_from_route "module.api.aws_apigatewayv2_integration.carritos_integration" "GET ${ROUTE_PREFIX}/carritos/{proxy+}"
  import_integration_from_route "module.api.aws_apigatewayv2_integration.ordenes_integration_get_all" "GET ${ROUTE_PREFIX}/ordenes"
  import_integration_from_route "module.api.aws_apigatewayv2_integration.ordenes_integration" "GET ${ROUTE_PREFIX}/ordenes/{proxy+}"
  import_integration_from_route "module.api.aws_apigatewayv2_integration.eventbridge_integration_crear_orden" "POST ${ROUTE_PREFIX}/ordenes"
  import_integration_from_route "module.api.aws_apigatewayv2_integration.eventbridge_integration_actualizar_orden" "PUT ${ROUTE_PREFIX}/ordenes/{proxy+}"

  import_route "module.api.aws_apigatewayv2_route.ordenes_post" "POST ${ROUTE_PREFIX}/ordenes"
  import_route "module.api.aws_apigatewayv2_route.ordenes_put" "PUT ${ROUTE_PREFIX}/ordenes/{proxy+}"
  import_route "module.api.aws_apigatewayv2_route.clientes_get_all" "GET ${ROUTE_PREFIX}/clientes"
  import_route "module.api.aws_apigatewayv2_route.clientes_get_proxy" "GET ${ROUTE_PREFIX}/clientes/{proxy+}"
  import_route "module.api.aws_apigatewayv2_route.clientes_post" "POST ${ROUTE_PREFIX}/clientes"
  import_route "module.api.aws_apigatewayv2_route.clientes_put_proxy" "PUT ${ROUTE_PREFIX}/clientes/{proxy+}"
  import_route "module.api.aws_apigatewayv2_route.clientes_delete_proxy" "DELETE ${ROUTE_PREFIX}/clientes/{proxy+}"
  import_route "module.api.aws_apigatewayv2_route.producto_get_all" "GET ${ROUTE_PREFIX}/productos"
  import_route "module.api.aws_apigatewayv2_route.producto_get_proxy" "GET ${ROUTE_PREFIX}/productos/{proxy+}"
  import_route "module.api.aws_apigatewayv2_route.producto_post" "POST ${ROUTE_PREFIX}/productos"
  import_route "module.api.aws_apigatewayv2_route.producto_put_proxy" "PUT ${ROUTE_PREFIX}/productos/{proxy+}"
  import_route "module.api.aws_apigatewayv2_route.producto_delete_proxy" "DELETE ${ROUTE_PREFIX}/productos/{proxy+}"
  import_route "module.api.aws_apigatewayv2_route.carritos_get_all" "GET ${ROUTE_PREFIX}/carritos"
  import_route "module.api.aws_apigatewayv2_route.carritos_get_proxy" "GET ${ROUTE_PREFIX}/carritos/{proxy+}"
  import_route "module.api.aws_apigatewayv2_route.carritos_post" "POST ${ROUTE_PREFIX}/carritos/{proxy+}"
  import_route "module.api.aws_apigatewayv2_route.carritos_put_proxy" "PUT ${ROUTE_PREFIX}/carritos/{proxy+}"
  import_route "module.api.aws_apigatewayv2_route.carritos_delete_proxy" "DELETE ${ROUTE_PREFIX}/carritos/{proxy+}"
  import_route "module.api.aws_apigatewayv2_route.ordenes_get_all" "GET ${ROUTE_PREFIX}/ordenes"
  import_route "module.api.aws_apigatewayv2_route.ordenes_get_proxy" "GET ${ROUTE_PREFIX}/ordenes/{proxy+}"
fi

event_bus_name="$(query_text events describe-event-bus --name ordenes-bus --query 'Name')"
import_if_needed "module.events.aws_cloudwatch_event_bus.ordenes_bus" "$event_bus_name"
import_if_needed "module.events.aws_cloudwatch_event_rule.crear_orden" "ordenes-bus/crear-orden"
import_if_needed "module.events.aws_cloudwatch_event_rule.actualizar_orden" "ordenes-bus/actualizar-orden"

if [[ -n "$crear_orden_arn" && "$crear_orden_arn" != "None" ]]; then
  import_if_needed "module.events.aws_cloudwatch_event_target.target_lambda_crear_orden" "ordenes-bus/crear-orden/crear-orden-lambda"
  import_if_needed "module.events.aws_cloudwatch_event_target.target_lambda_actualizar_orden" "ordenes-bus/actualizar-orden/actualizar-orden-lambda"
  import_if_needed "module.events.aws_lambda_permission.allow_eventbridge" "crear-orden/AllowExecutionFromEventBridge"
  import_if_needed "module.events.aws_lambda_permission.allow_eventbridge_actualizar_orden" "crear-orden/AllowExecutionFromEventBridgeActualizarOrden"
fi
