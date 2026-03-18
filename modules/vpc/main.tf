resource "aws_vpc" "this" {
  cidr_block           = var.cidr_block
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(var.tags, { Name = var.name })
}

resource "aws_internet_gateway" "this" {
  count  = var.enable_public_subnet ? 1 : 0
  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, { Name = "${var.name}-igw" })
}

resource "aws_eip" "nat" {
  count  = var.enable_app_subnet ? 1 : 0
  domain = "vpc"

  tags = merge(var.tags, { Name = "${var.name}-nat-eip" })
}

resource "aws_nat_gateway" "this" {
  count         = var.enable_app_subnet ? 1 : 0
  allocation_id = aws_eip.nat[0].id
  subnet_id     = aws_subnet.this["public-0"].id

  depends_on = [aws_internet_gateway.this]
  tags       = merge(var.tags, { Name = "${var.name}-nat-gw" })
}

locals {
  subnet_definitions = concat(
    var.enable_public_subnet ? [
      for idx, cidr in var.public_subnet_cidrs : {
        type = "public"
        cidr = cidr
        az   = var.azs[idx % length(var.azs)]
      }
    ] : [],
    var.enable_app_subnet ? [
      for idx, cidr in var.app_subnet_cidrs : {
        type = "app"
        cidr = cidr
        az   = var.azs[idx % length(var.azs)]
      }
    ] : [],
    var.enable_data_subnet ? [
      for idx, cidr in var.data_subnet_cidrs : {
        type = "data"
        cidr = cidr
        az   = var.azs[idx % length(var.azs)]
      }
    ] : []
  )
}

resource "aws_subnet" "this" {
  for_each = { for idx, sn in local.subnet_definitions : "${sn.type}-${idx}" => sn }

  vpc_id                  = aws_vpc.this.id
  cidr_block              = each.value.cidr
  availability_zone       = each.value.az
  map_public_ip_on_launch = each.value.type == "public" ? true : false

  tags = merge(
    var.tags,
    {
      Name = "${var.name}-${each.value.type}-${each.key}"
      Tier = each.value.type
    }
  )
}

resource "aws_route_table" "this" {
  # only keep the tiers that are enabled
  for_each = { for tier, enabled in local.tier_enabled : tier => tier if enabled }

  vpc_id = aws_vpc.this.id
  tags = merge(var.tags, {
    Name = "${var.name}-${each.key}-rt"
  })
}

resource "aws_route" "this" {
  for_each = aws_route_table.this["public"] != null ? {
    public = aws_route_table.this["public"]
  } : {}

  route_table_id         = each.value.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this[0].id
}

resource "aws_route" "app_nat" {
  count                  = var.enable_app_subnet && length(aws_nat_gateway.this) > 0 ? 1 : 0
  route_table_id         = aws_route_table.this["app"].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this[0].id
}

resource "aws_route_table_association" "this" {
  for_each = { for k, sn in aws_subnet.this : k => sn }

  route_table_id = aws_route_table.this[each.value.tags["Tier"]].id
  subnet_id      = each.value.id
}

resource "aws_network_acl" "this" {
  for_each = { for tier, enabled in local.tier_enabled : tier => tier if enabled }

  vpc_id = aws_vpc.this.id
  tags = merge(var.tags, {
    Name = "${var.name}-${each.key}-nacl"
  })
}

resource "aws_network_acl_rule" "allow_all_inbound" {
  for_each = aws_network_acl.this

  network_acl_id = each.value.id
  rule_number    = 100
  rule_action    = "allow"
  egress         = false
  protocol       = "-1"
  cidr_block     = "0.0.0.0/0"
}

resource "aws_network_acl_rule" "allow_all_outbound" {
  for_each = aws_network_acl.this

  network_acl_id = each.value.id
  rule_number    = 100
  rule_action    = "allow"
  egress         = true
  protocol       = "-1"
  cidr_block     = "0.0.0.0/0"
}

resource "aws_network_acl_association" "this" {
  for_each = { for k, sn in aws_subnet.this : k => sn }

  network_acl_id = aws_network_acl.this[each.value.tags["Tier"]].id
  subnet_id      = each.value.id
}
