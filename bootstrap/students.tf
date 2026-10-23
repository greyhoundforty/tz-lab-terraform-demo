data "ibm_is_instance" "student" {
  for_each = toset(var.student_instances)
  name     = each.value
}

data "ibm_is_instance_network_interface" "primary" {
  for_each = toset(var.student_instances)

  instance_name          = each.value
  network_interface_name = data.ibm_is_instance.student[each.key].primary_network_interface[0].name
}

locals {
  floating_ips = {
    for name, nic in data.ibm_is_instance_network_interface.primary :
    name => try(nic.floating_ips[0].address, "")
  }
}

resource "random_password" "guac" {
  for_each = toset(var.student_instances)

  length  = 16
  special = false
}

resource "terraform_data" "guac_password" {
  for_each = toset(var.student_instances)

  triggers_replace = [
    random_password.guac[each.key].result,
    local.floating_ips[each.key],
  ]

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    environment = {
      GUAC_PASSWORD = random_password.guac[each.key].result
      GUAC_HOST     = local.floating_ips[each.key]
      SSH_KEY       = pathexpand(var.ssh_private_key_file)
    }
    command = <<-EOT
      set -eu
      test -n "$GUAC_HOST"
      scp -i "$SSH_KEY" -o BatchMode=yes -o StrictHostKeyChecking=accept-new \
        "${path.module}/set-guac-password.py" "ubuntu@$GUAC_HOST:/tmp/set-guac-password.py"
      printf '%s' "$GUAC_PASSWORD" | ssh -i "$SSH_KEY" -o BatchMode=yes -o StrictHostKeyChecking=accept-new \
        "ubuntu@$GUAC_HOST" "sudo python3 /tmp/set-guac-password.py && sudo rm -f /tmp/set-guac-password.py"
    EOT
  }

  lifecycle {
    precondition {
      condition     = local.floating_ips[each.key] != ""
      error_message = "Virtual server ${each.key} has no floating IP. Guacamole is reached through that address."
    }
  }
}

resource "local_file" "student_access" {
  filename        = "${path.module}/student-access.csv"
  file_permission = "0600"

  content = join("", [
    "instance,floating_ip,username,password\n",
    join("", [
      for name in var.student_instances :
      "${name},${local.floating_ips[name]},student,${random_password.guac[name].result}\n"
    ]),
  ])

  depends_on = [terraform_data.guac_password]
}
