locals {
  tg_map = { for tg in var.target_groups : tg.name => tg }
}
