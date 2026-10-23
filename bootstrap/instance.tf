data "ibm_is_images" "ubuntu" {
  visibility = "public"
  status     = "available"
}

locals {
  ubuntu_names = sort([
    for image in data.ibm_is_images.ubuntu.images : image.name
    if alltrue([
      strcontains(image.name, "ubuntu-24-04"),
      strcontains(image.name, "-amd64-"),
      strcontains(image.name, "minimal"),
    ])
  ])
}

data "ibm_is_image" "ubuntu" {
  name = local.ubuntu_names[length(local.ubuntu_names) - 1]
}

resource "ibm_is_ssh_key" "lab" {
  name           = "${local.name_prefix}-ssh"
  resource_group = data.ibm_resource_group.lab.id
  public_key     = trimspace(var.ssh_public_key)
}

resource "ibm_is_instance" "lab" {
  name           = "${local.name_prefix}-vm"
  resource_group = data.ibm_resource_group.lab.id
  image          = data.ibm_is_image.ubuntu.id
  profile        = var.instance_profile
  vpc            = ibm_is_vpc.lab.id
  zone           = var.zone
  keys           = [ibm_is_ssh_key.lab.id]
  user_data      = file("${path.module}/cloud-init.yaml.tftpl")

  primary_network_interface {
    subnet          = ibm_is_subnet.lab.id
    security_groups = [ibm_is_security_group.lab.id]
  }

  lifecycle {
    precondition {
      condition     = length(local.ubuntu_names) > 0
      error_message = "No public Ubuntu 24.04 amd64 image was found in this region."
    }
  }
}

resource "ibm_is_floating_ip" "lab" {
  name           = "${local.name_prefix}-ip"
  resource_group = data.ibm_resource_group.lab.id
  target         = ibm_is_instance.lab.primary_network_interface[0].id
}
