data "aws_vpc" "vpc_por_defecto" {
  default = true
}

data "aws_subnets" "sub_redes_por_defecto" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.vpc_por_defecto.id]
  }
}

data "aws_subnet" "sub_redes_por_defecto" {
  for_each = toset(data.aws_subnets.sub_redes_por_defecto.ids)
  id       = each.value
}

data "aws_security_group" "grupo_seguridad_por_defecto" {
  name   = "default"
  vpc_id = data.aws_vpc.vpc_por_defecto.id
}

locals {
  existing_public_subnet_ids = [
    for subnet_id, subnet in data.aws_subnet.sub_redes_por_defecto :
    subnet_id if subnet.map_public_ip_on_launch
  ]

  existing_public_subnet_availability_zones = [
    for subnet_id, subnet in data.aws_subnet.sub_redes_por_defecto :
    subnet.availability_zone if subnet.map_public_ip_on_launch
  ]

  should_consider_additional_public_subnet = (
    var.create_missing_public_subnet_for_lab ||
    var.create_missing_public_subnet_for_alb
  )

  reused_additional_public_subnet_ids = [
    for subnet_id, subnet in data.aws_subnet.sub_redes_por_defecto :
    subnet_id
    if subnet.map_public_ip_on_launch && subnet.availability_zone == var.additional_public_subnet_availability_zone
  ]

  additional_public_subnet_ids = (
    local.should_consider_additional_public_subnet
    ? aws_subnet.additional_public_subnet_for_lab[*].id
    : slice(local.reused_additional_public_subnet_ids, 0, min(length(local.reused_additional_public_subnet_ids), 1))
  )

  public_subnet_ids = distinct(concat(
    local.existing_public_subnet_ids,
    local.additional_public_subnet_ids
  ))

  public_subnet_availability_zones = distinct(concat(
    local.existing_public_subnet_availability_zones,
    local.should_consider_additional_public_subnet ? [var.additional_public_subnet_availability_zone] : []
  ))
}

resource "aws_subnet" "additional_public_subnet_for_lab" {
  count = local.should_consider_additional_public_subnet ? 1 : 0

  vpc_id                  = data.aws_vpc.vpc_por_defecto.id
  cidr_block              = var.additional_public_subnet_cidr_block
  availability_zone       = var.additional_public_subnet_availability_zone
  map_public_ip_on_launch = true

  tags = {
    Name      = "tienda-virtual-lab-public-${var.additional_public_subnet_availability_zone}"
    ManagedBy = "terraform"
    Purpose   = "learner-lab-second-az"
  }
}
