locals {
  tags = ["lab:jump-host"]
  jump_host = {
    private_ip  = module.jump_vsi.list[0].ipv4_address
    floating_ip = module.jump_vsi.fip_list[0].floating_ip
    subnet_cidr = module.vpc.subnet_zone_list[0].cidr
  }
}

module "resource_group" {
  source  = "terraform-ibm-modules/resource-group/ibm"
  version = "1.6.1"

  resource_group_name = "${var.prefix}-rg"
}

resource "ibm_is_ssh_key" "jump" {
  name           = "${var.prefix}-jump"
  public_key     = var.ssh_public_key
  resource_group = module.resource_group.resource_group_id
  tags           = local.tags
}

module "image" {
  source  = "terraform-ibm-modules/common-utilities/ibm//modules/vsi-image-selector"
  version = "1.9.0"

  architecture             = "amd64"
  operating_system         = "ubuntu"
  operating_system_version = "24-04"
}

module "vpc" {
  source  = "terraform-ibm-modules/landing-zone-vpc/ibm"
  version = "10.1.1"

  name              = "jump"
  prefix            = var.prefix
  region            = var.region
  resource_group_id = module.resource_group.resource_group_id
  resource_tags     = local.tags

  # One subnet. The floating IP carries SSH inbound and internet outbound,
  # so this stack does not create public gateways.
  use_public_gateways = {
    zone-1 = false
    zone-2 = false
    zone-3 = false
  }

  network_acls = [
    {
      name                         = "lab-acl"
      add_ibm_cloud_internal_rules = true
      add_vpc_connectivity_rules   = true
      prepend_ibm_rules            = true
      rules = [
        {
          name        = "allow-ssh-inbound"
          action      = "allow"
          direction   = "inbound"
          source      = var.ssh_source_cidr
          destination = var.subnet_cidr
          protocol    = "tcp"
          port_min    = 22
          port_max    = 22
        },
        {
          name        = "allow-return-traffic"
          action      = "allow"
          direction   = "inbound"
          source      = "0.0.0.0/0"
          destination = var.subnet_cidr
          protocol    = "tcp"
          port_min    = 1024
          port_max    = 65535
        },
        {
          name        = "allow-outbound"
          action      = "allow"
          direction   = "outbound"
          source      = var.subnet_cidr
          destination = "0.0.0.0/0"
          protocol    = "all"
        }
      ]
    }
  ]

  subnets = {
    zone-1 = [
      {
        name           = "jump"
        cidr           = var.subnet_cidr
        public_gateway = false
        acl_name       = "lab-acl"
      }
    ]
  }
}

module "jump_vsi" {
  source  = "terraform-ibm-modules/landing-zone-vsi/ibm"
  version = "8.2.2"

  prefix             = var.prefix
  resource_group_id  = module.resource_group.resource_group_id
  vpc_id             = module.vpc.vpc_id
  image_id           = module.image.latest_image_id
  machine_type       = var.machine_type
  vsi_per_subnet     = 1
  ssh_key_ids        = [ibm_is_ssh_key.jump.id]
  enable_floating_ip = true
  resource_tags      = local.tags
  user_data = templatefile("${path.module}/cloud-init.yaml.tftpl", {
    terraform_version = var.terraform_version
  })

  subnets = [
    for subnet in module.vpc.subnet_zone_list : {
      name = subnet.name
      id   = subnet.id
      zone = subnet.zone
      cidr = subnet.cidr
    }
  ]

  # The created group is the only group on the interface. Security groups are
  # stateful, so the outbound rule covers return traffic for SSH and installs.
  create_security_group = true
  security_group = {
    name = "${var.prefix}-jump"
    rules = [
      {
        name      = "allow-ssh"
        direction = "inbound"
        source    = var.ssh_source_cidr
        protocol  = "tcp"
        port_min  = 22
        port_max  = 22
      },
      {
        name      = "allow-outbound"
        direction = "outbound"
        source    = "0.0.0.0/0"
        protocol  = "all"
      }
    ]
  }
}
