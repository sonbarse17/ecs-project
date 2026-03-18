output "vpc_id" {
  value = aws_vpc.this.id
}

output "public_subnet_ids" {
  value = [for s in aws_subnet.this : s.id if s.tags["Tier"] == "public"]
}

output "app_subnet_ids" {
  value = [for s in aws_subnet.this : s.id if s.tags["Tier"] == "app"]
}

output "data_subnet_ids" {
  value = [for s in aws_subnet.this : s.id if s.tags["Tier"] == "data"]
}

output "route_table_ids" {
  value = { for k, rt in aws_route_table.this : k => rt.id }
}

output "network_acl_ids" {
  value = { for k, acl in aws_network_acl.this : k => acl.id }
}
