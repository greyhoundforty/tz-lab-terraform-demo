resource "random_id" "lab" {
  byte_length = 2

  keepers = {
    prefix = var.prefix
  }
}

locals {
  # Held in state, so plan and apply keep using it. A new state draws a new suffix.
  name_prefix = "${var.prefix}-${random_id.lab.hex}"
}
