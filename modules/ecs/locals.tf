locals {
  container_map = { for c in var.containers : c.name => c }
}
