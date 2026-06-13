locals {
  path_base_servicio_normalizado = length(trim(var.path_base_servicio, "/")) > 0 ? "/${trim(var.path_base_servicio, "/")}" : ""
  productos_base_path            = "${local.path_base_servicio_normalizado}/productos"
  logistica_productos_base_url   = "http://${aws_lb.tienda_virtual_load_balancer.dns_name}${local.productos_base_path}"
}

resource "aws_ecs_cluster" "cluster_tienda_virtual_servicios" {
  name = var.nombre_cluster
}

data "aws_vpc" "vpc_por_defecto" {
  default = true
}

data "aws_subnets" "sub_redes_por_defecto" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.vpc_por_defecto.id]
  }
}

data "aws_security_group" "grupo_seguridad_por_defecto" {
  name   = "default"
  vpc_id = data.aws_vpc.vpc_por_defecto.id
}

resource "aws_security_group" "alb_security_group" {
  name        = "${var.nombre_cluster}-alb-sg"
  description = "Permite trafico HTTP/HTTPS hacia el ALB"
  vpc_id      = data.aws_vpc.vpc_por_defecto.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "ecs_security_group" {
  name        = "${var.nombre_cluster}-ecs-sg"
  description = "Permite trafico del ALB a ECS en 8080"
  vpc_id      = data.aws_vpc.vpc_por_defecto.id

  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_security_group.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_cloudwatch_log_group" "ecs_logs_ventas" {
  name              = "/ecs/${var.nombre_servicio_ecs_ventas}"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "ecs_logs_logistica" {
  name              = "/ecs/${var.nombre_servicio_ecs_logistica}"
  retention_in_days = 7
}

resource "aws_ecs_task_definition" "definicion_tarea_ventas" {
  family                   = var.familia_tarea_ventas
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "1024"
  memory                   = "3072"
  execution_role_arn       = var.rol_lab_arn
  task_role_arn            = var.rol_lab_arn

  container_definitions = jsonencode([{
    name      = "tienda-virtual-ventas",
    image     = "${var.id_cuenta_aws}.dkr.ecr.${var.region_aws}.amazonaws.com/${var.nombre_repo_ecr}:${var.tag_imagen_ventas}",
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
        value = var.nombre_base_datos_ventas
      },
      {
        name  = "DB_USER"
        value = var.usuario_base_datos
      },
      {
        name  = "DB_PASSWORD"
        value = var.contrasenha_base_datos
      },
      {
        name  = "LOGISTICA_BASE_URL"
        value = local.logistica_productos_base_url
      },
      {
        name  = "SYNC_QUEUE_URL"
        value = var.queue_url_sync_ventas
      }
    ],
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.ecs_logs_ventas.name
        awslogs-region        = var.region_aws
        awslogs-stream-prefix = "ecs"
      }
    }
  }])
}

resource "aws_ecs_task_definition" "definicion_tarea_logistica" {
  family                   = var.familia_tarea_logistica
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "1024"
  memory                   = "3072"
  execution_role_arn       = var.rol_lab_arn
  task_role_arn            = var.rol_lab_arn

  container_definitions = jsonencode([{
    name      = "tienda-virtual-logistica",
    image     = "${var.id_cuenta_aws}.dkr.ecr.${var.region_aws}.amazonaws.com/${var.nombre_repo_ecr}:${var.tag_imagen_logistica}",
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
        value = var.nombre_base_datos_logistica
      },
      {
        name  = "DB_USER"
        value = var.usuario_base_datos
      },
      {
        name  = "DB_PASSWORD"
        value = var.contrasenha_base_datos
      },
      {
        name  = "SYNC_QUEUE_URL"
        value = var.queue_url_sync_logistica
      }
    ],
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.ecs_logs_logistica.name
        awslogs-region        = var.region_aws
        awslogs-stream-prefix = "ecs"
      }
    }
  }])
}

resource "aws_lb" "tienda_virtual_load_balancer" {
  name               = "tienda-virtual-alb"
  internal           = false
  load_balancer_type = "application"
  subnets            = data.aws_subnets.sub_redes_por_defecto.ids
  security_groups    = [aws_security_group.alb_security_group.id]
}

resource "aws_lb_target_group" "tg_ventas" {
  name        = "tg-tienda-ventas"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = data.aws_vpc.vpc_por_defecto.id
  target_type = "ip"

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200"
  }
}

resource "aws_lb_target_group" "tg_logistica" {
  name        = "tg-tienda-logistica"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = data.aws_vpc.vpc_por_defecto.id
  target_type = "ip"

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200"
  }
}

resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.tienda_virtual_load_balancer.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg_ventas.arn
  }
}

resource "aws_lb_listener_rule" "rule_logistica_productos" {
  listener_arn = aws_lb_listener.http_listener.arn
  priority     = 10

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg_logistica.arn
  }

  condition {
    path_pattern {
      values = [
        local.productos_base_path,
        "${local.productos_base_path}/*"
      ]
    }
  }
}

resource "aws_ecs_service" "servicio_ventas" {
  name            = var.nombre_servicio_ecs_ventas
  cluster         = aws_ecs_cluster.cluster_tienda_virtual_servicios.id
  task_definition = aws_ecs_task_definition.definicion_tarea_ventas.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  load_balancer {
    target_group_arn = aws_lb_target_group.tg_ventas.arn
    container_name   = "tienda-virtual-ventas"
    container_port   = 8080
  }

  network_configuration {
    subnets          = data.aws_subnets.sub_redes_por_defecto.ids
    security_groups  = [aws_security_group.ecs_security_group.id, data.aws_security_group.grupo_seguridad_por_defecto.id]
    assign_public_ip = true
  }

  deployment_controller {
    type = "ECS"
  }

  depends_on = [
    aws_lb_listener.http_listener,
    aws_lb_listener_rule.rule_logistica_productos
  ]
}

resource "aws_ecs_service" "servicio_logistica" {
  name            = var.nombre_servicio_ecs_logistica
  cluster         = aws_ecs_cluster.cluster_tienda_virtual_servicios.id
  task_definition = aws_ecs_task_definition.definicion_tarea_logistica.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  load_balancer {
    target_group_arn = aws_lb_target_group.tg_logistica.arn
    container_name   = "tienda-virtual-logistica"
    container_port   = 8080
  }

  network_configuration {
    subnets          = data.aws_subnets.sub_redes_por_defecto.ids
    security_groups  = [aws_security_group.ecs_security_group.id, data.aws_security_group.grupo_seguridad_por_defecto.id]
    assign_public_ip = true
  }

  deployment_controller {
    type = "ECS"
  }

  depends_on = [
    aws_lb_listener.http_listener,
    aws_lb_listener_rule.rule_logistica_productos
  ]
}

resource "aws_appautoscaling_target" "objetivo_escalamiento_ventas" {
  service_namespace  = "ecs"
  resource_id        = "service/${aws_ecs_cluster.cluster_tienda_virtual_servicios.name}/${aws_ecs_service.servicio_ventas.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  min_capacity       = 1
  max_capacity       = 4
}

resource "aws_appautoscaling_target" "objetivo_escalamiento_logistica" {
  service_namespace  = "ecs"
  resource_id        = "service/${aws_ecs_cluster.cluster_tienda_virtual_servicios.name}/${aws_ecs_service.servicio_logistica.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  min_capacity       = 1
  max_capacity       = 4
}

resource "aws_appautoscaling_policy" "politica_autoescalamiento_ventas" {
  name               = "cpu-utilization-scaling-ventas"
  service_namespace  = "ecs"
  resource_id        = aws_appautoscaling_target.objetivo_escalamiento_ventas.resource_id
  scalable_dimension = aws_appautoscaling_target.objetivo_escalamiento_ventas.scalable_dimension
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

resource "aws_appautoscaling_policy" "politica_autoescalamiento_logistica" {
  name               = "cpu-utilization-scaling-logistica"
  service_namespace  = "ecs"
  resource_id        = aws_appautoscaling_target.objetivo_escalamiento_logistica.resource_id
  scalable_dimension = aws_appautoscaling_target.objetivo_escalamiento_logistica.scalable_dimension
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
