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

locals {
  existing_subnets_by_az = {
    for subnet_id, subnet in data.aws_subnet.sub_redes_por_defecto :
    subnet.availability_zone => {
      id                      = subnet_id
      cidr_block              = subnet.cidr_block
      map_public_ip_on_launch = subnet.map_public_ip_on_launch
    }...
  }

  existing_distinct_azs              = sort(keys(local.existing_subnets_by_az))
  existing_subnet_ids_by_distinct_az = [for az in local.existing_distinct_azs : local.existing_subnets_by_az[az][0].id]
  needs_additional_public_subnet     = length(local.existing_distinct_azs) < 2
  create_additional_public_subnet    = var.create_missing_public_subnet_for_lab && local.needs_additional_public_subnet
  shared_public_subnet_ids           = concat(local.existing_subnet_ids_by_distinct_az, aws_subnet.publica_adicional_lab[*].id)
  shared_public_subnet_availability_zones = concat(
    local.existing_distinct_azs,
    local.create_additional_public_subnet ? [var.additional_public_subnet_availability_zone] : []
  )
}

resource "aws_subnet" "publica_adicional_lab" {
  count                   = local.create_additional_public_subnet ? 1 : 0
  vpc_id                  = data.aws_vpc.vpc_por_defecto.id
  cidr_block              = var.additional_public_subnet_cidr_block
  availability_zone       = var.additional_public_subnet_availability_zone
  map_public_ip_on_launch = true

  tags = {
    Name      = "tiendavirtual-lab-public-additional"
    ManagedBy = "terraform"
    Purpose   = "ALB-RDS-AZ-coverage"
  }

  lifecycle {
    precondition {
      condition     = !contains(local.existing_distinct_azs, var.additional_public_subnet_availability_zone)
      error_message = "additional_public_subnet_availability_zone debe ser distinta a las AZs ya cubiertas por subnets existentes."
    }
  }
}

resource "terraform_data" "validar_cobertura_subnets" {
  input = local.shared_public_subnet_availability_zones

  lifecycle {
    precondition {
      condition     = length(distinct(local.shared_public_subnet_availability_zones)) >= 2
      error_message = "ALB y RDS requieren subnets en al menos 2 AZs. Active create_missing_public_subnet_for_lab o agregue subnets reales en otra AZ."
    }
  }
}
