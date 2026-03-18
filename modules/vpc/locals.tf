locals {
  tier_enabled = {
    public = var.enable_public_subnet
    app    = var.enable_app_subnet
    data   = var.enable_data_subnet
  }
}
