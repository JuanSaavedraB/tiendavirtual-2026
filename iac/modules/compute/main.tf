resource "aws_ecs_cluster" "cluster_tienda_virtual_servicios" {
  name = var.nombre_cluster

  tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}

resource "aws_ecs_task_definition" "definicion_tarea_tienda_virtual" {
  family                   = var.familia_tarea
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "1024"
  memory                   = "3072"
  execution_role_arn       = var.rol_lab_arn
  task_role_arn            = var.rol_lab_arn

  container_definitions = jsonencode([{
    name      = "tienda-virtual",
    image     = "${var.id_cuenta_aws}.dkr.ecr.${var.region_aws}.amazonaws.com/${var.nombre_repo_ecr}:latest",
    essential = true,
    portMappings = [
      {
        containerPort = 8080,
        protocol      = "tcp"
      }
    ],
    cpu               = 1024,
    memory            = 3072,
    memoryReservation = 1024,
    environment = [
      {
        name  = "DB_HOST"
        value = var.host_base_datos
      },
      {
        name  = "DB_NAME"
        value = var.nombre_base_datos
      },
      {
        name  = "DB_USER"
        value = var.usuario_base_datos
      },
      {
        name  = "DB_PASSWORD"
        value = var.contrasenha_base_datos
      }
    ],
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = "/ecs/${var.nombre_servicio_ecs}"
        awslogs-region        = var.region_aws
        awslogs-stream-prefix = "ecs"
      }
    }
  }])
}

resource "aws_cloudwatch_log_group" "ecs_logs" {
  name              = "/ecs/${var.nombre_servicio_ecs}"
  retention_in_days = 7

  tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}

data "aws_vpc" "vpc_por_defecto" {
  count = var.vpc_id == "" ? 1 : 0

  default = true
}

locals {
  vpc_id_seleccionada = var.vpc_id != "" ? var.vpc_id : data.aws_vpc.vpc_por_defecto[0].id
}

data "aws_subnets" "sub_redes_vpc_seleccionada" {
  filter {
    name   = "vpc-id"
    values = [local.vpc_id_seleccionada]
  }
}

locals {
  subnet_ids_alb = length(var.public_subnet_ids) > 0 ? var.public_subnet_ids : data.aws_subnets.sub_redes_vpc_seleccionada.ids
}

data "aws_subnet" "sub_redes_alb" {
  for_each = toset(local.subnet_ids_alb)

  id = each.value
}

locals {
  alb_availability_zones = distinct([
    for subnet in data.aws_subnet.sub_redes_alb : subnet.availability_zone
  ])
}

data "aws_security_group" "grupo_seguridad_por_defecto" {
  name   = "default"
  vpc_id = local.vpc_id_seleccionada
}

resource "aws_ecs_service" "servicio_tienda_virtual" {
  name            = var.nombre_servicio_ecs
  cluster         = aws_ecs_cluster.cluster_tienda_virtual_servicios.id
  task_definition = aws_ecs_task_definition.definicion_tarea_tienda_virtual.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  load_balancer {
    target_group_arn = aws_lb_target_group.tg_tienda_virtual.arn
    container_name   = "tienda-virtual"
    container_port   = 8080
  }

  network_configuration {
    subnets          = local.subnet_ids_alb
    security_groups  = [data.aws_security_group.grupo_seguridad_por_defecto.id]
    assign_public_ip = true
  }

  deployment_controller {
    type = "ECS"
  }

  depends_on = [
    aws_ecs_task_definition.definicion_tarea_tienda_virtual,
    aws_lb_listener.http_listener
  ]
}

resource "aws_appautoscaling_target" "obetivo_escalamiento_ecs" {
  service_namespace  = "ecs"
  resource_id        = "service/${aws_ecs_cluster.cluster_tienda_virtual_servicios.name}/${aws_ecs_service.servicio_tienda_virtual.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  min_capacity       = 1
  max_capacity       = 4
}

resource "aws_appautoscaling_policy" "politica_de_autoescalamiento_ecs" {
  name               = "cpu-utilization-scaling"
  service_namespace  = "ecs"
  resource_id        = aws_appautoscaling_target.obetivo_escalamiento_ecs.resource_id
  scalable_dimension = aws_appautoscaling_target.obetivo_escalamiento_ecs.scalable_dimension
  policy_type        = "TargetTrackingScaling"

  target_tracking_scaling_policy_configuration {
    target_value = 75.0
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }

    scale_in_cooldown  = 60
    scale_out_cooldown = 60
  }
}

resource "aws_lb" "tienda_virtual_load_balancer" {
  name               = var.nombre_load_balancer
  internal           = false
  load_balancer_type = "application"
  subnets            = local.subnet_ids_alb
  security_groups    = [data.aws_security_group.grupo_seguridad_por_defecto.id]

  tags = {
    Project     = var.project_name
    Environment = var.environment
  }

  lifecycle {
    precondition {
      condition     = length(local.subnet_ids_alb) >= 2
      error_message = "El ALB requiere al menos dos subnets públicas. Define public_subnet_ids con dos o más subnets."
    }

    precondition {
      condition     = length(local.alb_availability_zones) >= 2
      error_message = "El ALB requiere subnets en al menos dos Availability Zones distintas."
    }

    precondition {
      condition = alltrue([
        for subnet in data.aws_subnet.sub_redes_alb : subnet.vpc_id == local.vpc_id_seleccionada
      ])
      error_message = "Todas las subnets del ALB deben pertenecer a la VPC seleccionada."
    }
  }
}

resource "aws_lb_target_group" "tg_tienda_virtual" {
  name        = var.nombre_target_group
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = local.vpc_id_seleccionada
  target_type = "ip"

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200"
  }

  tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}

resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.tienda_virtual_load_balancer.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg_tienda_virtual.arn
  }
}
